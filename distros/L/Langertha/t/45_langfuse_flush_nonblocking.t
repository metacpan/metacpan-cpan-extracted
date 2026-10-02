#!/usr/bin/env perl
# ABSTRACT: Langfuse flushes never stall a chat or the event loop; 207 errors and chunking
use strict;
use warnings;
use Test2::Bundle::More;
use lib 't/lib';

BEGIN {
  plan skip_all => 'fork-based HTTP::Daemon test not supported on Windows' if $^O eq 'MSWin32';
  eval { require Net::Async::HTTP; require IO::Async::Loop; require IO::Async::Timer::Periodic; 1 }
    or plan skip_all => 'Requires Net::Async::HTTP and IO::Async (the async backend under test)';
}

use IO::Socket::INET;
use HTTP::Response;
use JSON::MaybeXS;
use LWP::UserAgent;
use Time::HiRes qw( time );
use Test::LocalHTTPDaemon;
use Langertha::Chat;
use Langertha::Engine::OpenAI;
use Langertha::Request::SyncHTTP;

# karr k303: both Langfuse flushes used a bare LWP::UserAgent (180s default
# timeout), and Plugin::Langfuse ran that blocking flush inside its async
# hooks when auto_flush was set. A Langfuse that accepts the connection and
# never answers therefore held every chat iteration for up to 180s and froze
# the whole IO::Async loop that knarr / skeid / raider serve everything else
# from. Now: auto_flush starts the flush on the engine's async backend and
# returns at once (the future is retained on the plugin), every flush is
# bounded by a short timeout, a timeout stops the rest of the flush instead of
# waiting it out per chunk, batches go out in chunks, and Langfuse's
# 207 Multi-Status per-event errors are reported instead of silently lost.

my $json = JSON::MaybeXS->new( utf8 => 1, canonical => 1 );

# Accepts connections (the kernel completes the handshake) and never answers.
my $hang = IO::Socket::INET->new( Listen => 50, LocalAddr => '127.0.0.1', LocalPort => 0,
  Proto => 'tcp', ReuseAddr => 1 ) or die "listen: $!";
my $hang_url = 'http://127.0.0.1:' . $hang->sockport;

my $server = Test::LocalHTTPDaemon->start( sub {
  my ($request) = @_;
  my $path = $request->uri->path;
  if ( $path =~ m{/chat/completions\z} ) {
    return HTTP::Response->new( 200, 'OK', [ 'Content-Type' => 'application/json' ],
      $json->encode({ id => 'x', object => 'chat.completion', created => 1, model => 'm-served',
        usage => { prompt_tokens => 3, completion_tokens => 2, total_tokens => 5 },
        choices => [ { index => 0, finish_reason => 'stop',
          message => { role => 'assistant', content => 'ok' } } ] }) );
  }
  my $batch = $json->decode( $request->content )->{batch};
  my @ids   = map { $_->{id} } @$batch;
  if ( $path =~ m{\A/partial/} ) {        # Langfuse accepts the request, rejects two events
    return HTTP::Response->new( 207, 'Multi-Status', [ 'Content-Type' => 'application/json' ],
      $json->encode({
        successes => [ map { { id => $_, status => 201 } } @ids[ 2 .. $#ids ] ],
        errors    => [ map { { id => $_, status => 400, message => 'Invalid request data' } } @ids[ 0, 1 ] ],
      }) );
  }
  # /echo/: all accepted; the body tells the test how many events arrived
  return HTTP::Response->new( 207, 'Multi-Status', [ 'Content-Type' => 'application/json' ],
    $json->encode({ successes => [ map { { id => $_, status => 201 } } @ids ], errors => [] }) );
} );
my $base = $server->url;

my $loop = IO::Async::Loop->new;
my $ticks = 0;
my $ticker = IO::Async::Timer::Periodic->new( interval => 0.05, on_tick => sub { $ticks++ } );
$loop->add($ticker);
$ticker->start;

sub warnings_of {
  my ($code) = @_;
  my @warnings;
  local $SIG{__WARN__} = sub { push @warnings, $_[0] };
  my @result = $code->();
  return ( \@warnings, @result );
}

sub async_engine {
  return Langertha::Engine::OpenAI->new(
    api_key => 'k', url => "$base/v1", model => 'm', _async_loop => $loop, @_ );
}

sub langfuse_args { ( public_key => 'pk-lf', secret_key => 'sk-lf', @_ ) }

subtest 'plugin auto_flush to a silent Langfuse: the chat returns at once, the loop keeps running' => sub {
  my $chat = Langertha::Chat->new(
    engine  => async_engine(),
    plugins => [ Langfuse => { langfuse_args( url => $hang_url, auto_flush => 1, flush_timeout => 2 ) } ],
  );
  my ($lf) = @{ $chat->plugin_instances };

  my $t0 = time;
  my $f  = $chat->simple_chat_f('hi');
  $loop->await($f);
  my $chat_secs = time - $t0;
  is( "" . $f->get, 'ok', 'chat answered' );
  cmp_ok( $chat_secs, "<", 2, "chat_f did not wait out flush_timeout (${chat_secs}s)" );
  is( scalar keys %{ $lf->_pending_flushes }, 1, 'the in-flight flush is retained on the plugin' );
  is( scalar @{ $lf->_batch }, 0, 'its events left the batch' );

  my $ticks_before = $ticks;
  $t0 = time;
  my ( $warnings ) = warnings_of( sub { $loop->await( $lf->flush_f ) } );
  my $wait_secs = time - $t0;
  cmp_ok( $wait_secs, '<', 6, "the silent flush gave up after flush_timeout (${wait_secs}s)" );
  cmp_ok( $ticks - $ticks_before, '>=', 10, 'the loop kept ticking meanwhile' );
  is( scalar keys %{ $lf->_pending_flushes }, 0, 'the pending flush was released when it ended' );
  is( scalar @$warnings, 1, 'one warning' );
  like( $warnings->[0], qr/\ALangfuse ingestion failed: 500 .*\(3 event\(s\) lost\)/,
    'the timeout is warned about, the future did not fail' );
};

subtest 'plugin flush (sync) waits for an in-flight auto_flush, bounded by flush_timeout' => sub {
  my $chat = Langertha::Chat->new(
    engine  => async_engine(),
    plugins => [ Langfuse => { langfuse_args( url => $hang_url, auto_flush => 1, flush_timeout => 1 ) } ],
  );
  my ($lf) = @{ $chat->plugin_instances };
  my $f = $chat->simple_chat_f('hi');
  $loop->await($f);
  is( scalar keys %{ $lf->_pending_flushes }, 1, 'auto_flush in flight' );
  my $t0 = time;
  my ( $warnings ) = warnings_of( sub { $lf->flush } );
  my $secs = time - $t0;
  cmp_ok( $secs, '<', 3, "flush returned after the in-flight request timed out (${secs}s)" );
  is( scalar keys %{ $lf->_pending_flushes }, 0, 'nothing left in flight' );
  like( $warnings->[0] // '', qr/Langfuse ingestion failed: 500/, 'its failure was warned about' );
};

subtest 'sync fallback: auto_flush to a silent Langfuse delays the chat by flush_timeout at most' => sub {
  my $engine = async_engine(
    _async_http => Langertha::Request::SyncHTTP->new( user_agent => LWP::UserAgent->new( timeout => 180 ) ) );
  my $chat = Langertha::Chat->new(
    engine  => $engine,
    plugins => [ Langfuse => { langfuse_args( url => $hang_url, auto_flush => 1, flush_timeout => 1 ) } ],
  );
  my $t0 = time;
  my ( $warnings, $response ) = warnings_of( sub { $chat->simple_chat_f('hi')->get } );
  my $secs = time - $t0;
  is( "$response", 'ok', 'chat answered' );
  cmp_ok( $secs, '<', 4, "bounded by flush_timeout, not the engine's 180s agent (${secs}s)" );
  like( $warnings->[0] // '', qr/Langfuse ingestion failed: 500/, 'failure warned' );
};

subtest 'engine langfuse_flush_f to a silent Langfuse resolves within langfuse_timeout' => sub {
  my $engine = async_engine( langfuse_public_key => 'pk', langfuse_secret_key => 'sk',
    langfuse_url => $hang_url, langfuse_timeout => 1 );
  $engine->langfuse_trace( name => "t$_" ) for 1 .. 250;

  my $ticks_before = $ticks;
  my $t0 = time;
  my $f  = $engine->langfuse_flush_f;
  my ( $warnings ) = warnings_of( sub { $loop->await($f) } );
  my $secs = time - $t0;
  ok( $f->is_done, 'the future resolved, it did not fail' );
  cmp_ok( $secs, '<', 2.5, "one timeout, not one per chunk (${secs}s)" );
  cmp_ok( $ticks - $ticks_before, '>=', 10, 'the loop kept ticking meanwhile' );
  is( scalar @{ $engine->_langfuse_batch }, 0, 'batch cleared' );
  is( scalar @$warnings, 2, 'two warnings' );
  like( $warnings->[0], qr/Langfuse ingestion failed: 500 .*\(100 event\(s\) lost\)/, 'first chunk lost' );
  like( $warnings->[1], qr/dropping 150 more event\(s\)/, 'the rest is dropped instead of waited out' );
};

subtest 'sync langfuse_flush to a silent Langfuse returns within langfuse_timeout' => sub {
  my $engine = async_engine( langfuse_public_key => 'pk', langfuse_secret_key => 'sk',
    langfuse_url => $hang_url, langfuse_timeout => 1 );
  $engine->langfuse_trace( name => 'x' );
  my $t0 = time;
  my ( $warnings, $response ) = warnings_of( sub { $engine->langfuse_flush } );
  my $secs = time - $t0;
  cmp_ok( $secs, '<', 4, "not LWP's 180s default (${secs}s)" );
  is( $response->code, 500, 'returns the failed response' );
  like( $warnings->[0], qr/Langfuse ingestion failed/, 'warned, did not die' );
};

subtest '207 Multi-Status: rejected events are warned about with counts' => sub {
  for my $mode (qw( sync async )) {
    my $engine = async_engine( langfuse_public_key => 'pk', langfuse_secret_key => 'sk',
      langfuse_url => "$base/partial" );
    $engine->langfuse_trace( name => "t$_" ) for 1 .. 5;
    my ( $warnings ) = warnings_of( sub {
      $mode eq 'sync' ? $engine->langfuse_flush : $loop->await( $engine->langfuse_flush_f );
    } );
    is( scalar @$warnings, 1, "$mode: one warning" );
    like( $warnings->[0], qr/\ALangfuse ingestion: 2 of 5 event\(s\) rejected \(first: 400 Invalid request data\)/,
      "$mode: counts and the first error" );
  }

  my $chat = Langertha::Chat->new(
    engine  => async_engine(),
    plugins => [ Langfuse => { langfuse_args( url => "$base/partial" ) } ],
  );
  my ($lf) = @{ $chat->plugin_instances };
  $lf->create_trace( name => "t$_" ) for 1 .. 4;
  my ( $warnings ) = warnings_of( sub { $lf->flush } );
  like( $warnings->[0] // '', qr/2 of 4 event\(s\) rejected/, 'plugin flush reports 207 errors too' );
};

subtest 'a large batch goes out in chunks of flush_batch_size' => sub {
  my $engine = async_engine( langfuse_public_key => 'pk', langfuse_secret_key => 'sk',
    langfuse_url => "$base/echo" );
  $engine->langfuse_trace( name => "t$_" ) for 1 .. 250;
  my $f = $engine->langfuse_flush_f;
  $loop->await($f);
  my @sizes = map { scalar @{ $json->decode( $_->content )->{successes} } } $f->get;
  is_deeply( \@sizes, [ 100, 100, 50 ], 'engine: three requests of at most 100 events' );

  my $chat = Langertha::Chat->new(
    engine  => async_engine(),
    plugins => [ Langfuse => { langfuse_args( url => "$base/echo", flush_batch_size => 4 ) } ],
  );
  my ($lf) = @{ $chat->plugin_instances };
  $lf->create_trace( name => "t$_" ) for 1 .. 10;
  my $pf = $lf->flush_f;
  $loop->await($pf);
  @sizes = map { scalar @{ $json->decode( $_->content )->{successes} } } $pf->get;
  is_deeply( \@sizes, [ 4, 4, 2 ], 'plugin: flush_batch_size honored' );
  is( scalar @{ $lf->_batch }, 0, 'plugin batch cleared' );
};

done_testing;
