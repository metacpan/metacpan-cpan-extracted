#!/usr/bin/env perl
# ABSTRACT: an aborted stream on a keep-alive connection takes no other request down, and the engine reuses its connections
use strict; use warnings;
use Test2::Bundle::More;
use FindBin;
use lib "$FindBin::Bin/lib";

BEGIN {
  plan skip_all => 'fork-based HTTP::Daemon test not supported on Windows' if $^O eq 'MSWin32';
  eval { require Future::AsyncAwait; 1 }
    or plan skip_all => 'Requires Future::AsyncAwait';
  eval { require Net::Async::HTTP; require IO::Async::Loop; 1 }
    or plan skip_all => 'Requires Net::Async::HTTP and IO::Async (the async backend under test)';
}

use Future;
use HTTP::Response;
use JSON::MaybeXS;
use Test::LocalHTTPDaemon;
use Langertha::Engine::OpenAI;

# Real providers keep connections alive, and Net::Async::HTTP reuses them. Once
# it knows a connection speaks HTTP/1.1 it used to pipeline every further
# request on the same engine onto it, behind a stream that may run for minutes.
# Aborting that stream (the caller cancels, or chunk_callback dies, karr k194)
# closes the connection, and every request pipelined behind it failed with
# "Connection closed" although nothing was wrong with it. Langertha now builds
# its client with pipeline => 0: a queued request waits for a connection of
# its own instead (karr k199, ADR 0027). The shared daemon mode sends
# "Connection: close", which hides all of this, so these run keep-alive.

my $json = JSON::MaybeXS->new( utf8 => 1, canonical => 1 );

sub sse_event { 'data: ' . $json->encode({ choices => [ { index => 0, delta => { content => $_[0] } } ] }) . "\n\n" }

my $server = Test::LocalHTTPDaemon->start( sub {
  my ($request) = @_;
  my @events = ( ( map { sse_event($_) } 'Hel', 'lo ', 'world' ), "data: [DONE]\n\n" );
  my $sent   = 0;
  return HTTP::Response->new( 200, 'OK', [ 'Content-Type' => 'text/event-stream' ], sub {
    return '' unless @events;
    select( undef, undef, undef, 0.05 ) if $sent++;
    return shift @events;
  });
}, keep_alive => 1 );

my $loop = IO::Async::Loop->new;

sub engine {
  return Langertha::Engine::OpenAI->new(
    api_key => 'test-key', model => 'gpt-test', url => $server->url . '/v1' );
}

sub stream_f {
  my ( $engine, $chunk_callback ) = @_;
  return $engine->chat_stream_realtime_f(
    messages => [ { role => 'user', content => 'hi' } ],
    ( $chunk_callback ? ( chunk_callback => $chunk_callback ) : () ),
  );
}

sub drive {
  my @futures = @_;
  my $timeout = $loop->delay_future( after => 15 );
  return eval { $loop->await( Future->wait_any( Future->wait_all(@futures), $timeout ) ); 1 } ? '' : $@;
}

sub outcome {
  my ($future) = @_;
  return 'pending'                           unless $future->is_ready;
  return 'cancelled'                         if $future->is_cancelled;
  return 'failed: ' . ( $future->failure )[0] if $future->is_failed;
  return 'done: ' . ( $future->get )[0];
}

# Put a keep-alive HTTP/1.1 connection into the pool first, the way an engine
# that has already talked to its provider has one.
sub warm_engine {
  my $engine = engine();
  my $warm   = stream_f($engine);
  drive($warm);
  is( outcome($warm), 'done: Hello world', 'warm-up request over keep-alive' );
  return $engine;
}

# Net::Async::HTTP hands queued requests to a connection when its current one
# finishes; on a connection known to be HTTP/1.1 it hands over all of them at
# once, pipelined. So: one plain request first, then the one that is aborted,
# then its siblings, all on one engine.
subtest 'chunk_callback dies on a stream with concurrent requests queued behind it' => sub {
  my $engine   = engine();
  my $first    = stream_f($engine);
  my $dying    = stream_f( $engine, sub { die "user abort\n" } );
  my @siblings = map { stream_f($engine) } 1 .. 2;

  is( drive( $first, $dying, @siblings ), '', 'no exception escaped the event loop' );
  is( outcome($first), 'done: Hello world', 'the request before it completed' );
  is( outcome($dying), "failed: user abort\n", 'the aborted stream failed with its own exception' );
  is( outcome( $siblings[$_] ), 'done: Hello world', "queued request @{[ $_ + 1 ]} behind it still completed" )
    for 0 .. $#siblings;
};

subtest 'caller cancels a stream with concurrent requests queued behind it' => sub {
  my $engine = engine();
  my $first  = stream_f($engine);
  my $cancelled;
  # Cancel from outside the read handler, as a caller would, once it streams.
  $cancelled = stream_f( $engine, sub { $loop->later( sub { $cancelled->cancel } ) } );
  my @siblings = map { stream_f($engine) } 1 .. 2;

  is( drive( $first, $cancelled, @siblings ), '', 'no exception escaped the event loop' );
  is( outcome($first), 'done: Hello world', 'the request before it completed' );
  is( outcome($cancelled), 'cancelled', 'the stream was cancelled mid-transfer' );
  is( outcome( $siblings[$_] ), 'done: Hello world', "queued request @{[ $_ + 1 ]} behind it still completed" )
    for 0 .. $#siblings;
};

# The other direction (karr k203): a caller gives up on a request that is only
# queued behind a running stream. Without pipelining it holds no connection
# yet, so cancelling it must not touch the stream in front of it. Same shape
# as above: when the first request finishes, a pipelining client would put the
# stream and the queued request behind it on one connection, and cancelling a
# pipelined request closes that connection under the stream.
subtest 'caller cancels a queued request while a stream is running' => sub {
  my $engine = engine();
  my $first  = stream_f($engine);
  my $queued;
  my $running = stream_f( $engine, sub { $loop->later( sub { $queued->cancel unless $queued->is_ready } ) } );
  $queued = stream_f($engine);

  is( drive( $first, $running, $queued ), '', 'no exception escaped the event loop' );
  is( outcome($first), 'done: Hello world', 'the request before them completed' );
  is( outcome($running), 'done: Hello world', 'the running stream completed unharmed' );
  is( outcome($queued), 'cancelled', 'the queued request was cancelled' );
};

subtest 'after an aborted stream the engine opens one new connection and keeps reusing it' => sub {
  my $engine = warm_engine();
  my $before = $server->connection_count;

  my $dying = stream_f( $engine, sub { die "user abort\n" } );
  drive($dying);
  is( outcome($dying), "failed: user abort\n", 'the stream was aborted' );

  for my $n ( 1 .. 3 ) {
    my $next = stream_f($engine);
    drive($next);
    is( outcome($next), 'done: Hello world', "sequential request $n after the abort completed" );
  }
  # The abort closed the warm connection; the three requests after it share
  # exactly one new keep-alive connection.
  is( $server->connection_count - $before, 1, 'the requests after the abort reused one new connection' );
};

done_testing;
