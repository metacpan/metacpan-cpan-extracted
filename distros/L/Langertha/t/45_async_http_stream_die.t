#!/usr/bin/env perl
# ABSTRACT: a die in the streaming chunk callback fails that request's future on Net::Async::HTTP, not the event loop
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
use Time::HiRes ();
use HTTP::Response;
use JSON::MaybeXS;
use LWP::UserAgent;
use Test::LocalHTTPDaemon;
use Langertha::Request::SyncHTTP;
use Langertha::Engine::OpenAI;

# On the Net::Async::HTTP backend the chunk callback runs inside the IO::Async
# loop's read handler. A die there (a malformed stream line, or the user's
# chunk_callback) used to unwind out of the loop into whatever happened to be
# driving it: the request's own future stayed pending, and in an application
# that runs one loop for everything, unrelated work died with it. The sync
# shim has always failed the request future instead. (karr k194, ADR 0027)
#
# Net::Async::HTTP parses the body out of its read buffer, so what is still
# buffered when the die happens decides what an abort has to cope with. Every
# case runs in three framings:
#   paced          chunked, one event per read (a pause between chunks)
#   chunked-burst  chunked, the whole response in one read
#   length-burst   Content-Length, the whole response in one read
# and each one checks that the same engine (same client, same loop) serves a
# following request.

my $json = JSON::MaybeXS->new( utf8 => 1, canonical => 1 );
my @DELTAS = ( 'Hel', 'lo ', 'world' );
my $CRLF   = "\r\n";

sub sse_event { 'data: ' . $json->encode({ choices => [ { index => 0, delta => { content => $_[0] } } ] }) . "\n\n" }

# The user message picks the body: 'malformed' puts an unparseable line after
# the first event, anything else streams the three deltas.
sub sse_events {
  my ($kind) = @_;
  my @done = (
    'data: ' . $json->encode({ choices => [ { index => 0, delta => {}, finish_reason => 'stop' } ] }) . "\n\n",
    "data: [DONE]\n\n",
  );
  return ( sse_event('Hel'), "data: {not json\n\n", sse_event('lo '), @done ) if $kind eq 'malformed';
  return ( ( map { sse_event('x') } 1 .. 40 ), @done ) if $kind eq 'long';
  return ( ( map { sse_event($_) } @DELTAS ), @done );
}

my $RAW_HEAD = "HTTP/1.1 200 OK${CRLF}Content-Type: text/event-stream${CRLF}Connection: close${CRLF}";

my $server = Test::LocalHTTPDaemon->start(sub {
  my ($request) = @_;
  my ($framing) = $request->uri->path =~ m{^/([^/]+)/};
  my $body      = eval { $json->decode( $request->content ) } || {};
  my @events    = sse_events( $body->{messages}[-1]{content} // '' );

  if ( $framing eq 'paced' ) {
    my $sent = 0;
    return HTTP::Response->new( 200, 'OK', [ 'Content-Type' => 'text/event-stream' ], sub {
      return '' unless @events;
      select( undef, undef, undef, 0.05 ) if $sent++;
      return shift @events;
    });
  }
  if ( $framing eq 'chunked-burst' ) {
    return $RAW_HEAD . "Transfer-Encoding: chunked${CRLF}${CRLF}"
      . join( '', map { sprintf( '%x', length ) . $CRLF . $_ . $CRLF } @events ) . "0${CRLF}${CRLF}";
  }
  if ( $framing eq 'length-burst' ) {
    my $content = join '', @events;
    return $RAW_HEAD . 'Content-Length: ' . length($content) . "${CRLF}${CRLF}" . $content;
  }
  return HTTP::Response->new( 404, 'Not Found', [ 'Content-Type' => 'text/plain' ], 'no route' );
});
my $base = $server->url;

sub engine {
  my ( $framing, %args ) = @_;
  return Langertha::Engine::OpenAI->new(
    api_key => 'test-key',
    model   => 'gpt-test',
    url     => "$base/$framing/v1",
    %args,
  );
}

sub stream_f {
  my ( $engine, $chunk_callback, $message ) = @_;
  return $engine->chat_stream_realtime_f(
    messages => [ { role => 'user', content => $message // 'hi' } ],
    ( $chunk_callback ? ( chunk_callback => $chunk_callback ) : () ),
  );
}

my $loop = IO::Async::Loop->new;

# Drive the shared loop until every future is ready (or a safety timeout
# fires). Returns whatever escaped the loop, '' when nothing did.
sub drive {
  my @futures = @_;
  my $all     = Future->wait_all(@futures);
  my $timeout = $loop->delay_future( after => 15 );
  my $escaped = eval { $loop->await( Future->wait_any( $all, $timeout ) ); 1 } ? '' : $@;
  return $escaped;
}

sub follow_up_ok {
  my ( $engine, $what ) = @_;
  my $next = stream_f($engine);
  is( drive($next), '', "$what: a following request on the same engine runs without an escaped exception" );
  ok( $next->is_done, "$what: the following request completed" )
    or diag( $next->is_failed ? 'failed: ' . ( $next->failure )[0] : 'still pending' );
  is( $next->is_done ? ( $next->get )[0] : undef, 'Hello world', "$what: it streamed its full content" );
}

for my $framing (qw( paced chunked-burst length-burst )) {
  subtest "$framing: user chunk_callback dies" => sub {
    my $engine = engine($framing);
    ok( $engine->_async_http->isa('Net::Async::HTTP'), 'engine runs on the Net::Async::HTTP backend' );
    is( $engine->_async_loop, $loop, 'engine shares the process loop' );

    my $calls     = 0;
    my $dying     = stream_f( $engine, sub { $calls++; die "user abort\n" } );
    my $bystander = stream_f( engine($framing) );

    is( drive( $dying, $bystander ), '', 'no exception escaped the event loop' );
    ok( $dying->is_failed, 'the dying request future failed' );
    is( $dying->is_failed ? ( $dying->failure )[0] : undef, "user abort\n", 'with the original exception' );
    is( $calls, 1, 'chunk_callback was not called again after it died' );
    ok( $bystander->is_done, 'a concurrent request from another engine on the same loop completed' );
    is( $bystander->is_done ? ( $bystander->get )[0] : undef, 'Hello world', 'with its full content' );

    follow_up_ok( $engine, 'after the chunk_callback die' );
  };

  subtest "$framing: malformed stream line" => sub {
    my $engine = engine($framing);
    my $seen   = [];
    my $future = stream_f( $engine, sub { push @$seen, $_[0]->content }, 'malformed' );

    is( drive($future), '', 'no exception escaped the event loop' );
    ok( $future->is_failed, 'the request future failed' );
    my $async_error = $future->is_failed ? ( $future->failure )[0] : '';
    like( $async_error, qr/\S/, 'with the parser exception' );
    # The parser handles each read's lines together, so whether 'Hel' (before
    # the bad line) is delivered depends on the framing; what follows it never is.
    ok( !( grep { $_ eq 'lo ' } @$seen ), 'no chunk after the malformed line was delivered' );

    my $sync = stream_f( engine( $framing,
      _async_http => Langertha::Request::SyncHTTP->new( user_agent => LWP::UserAgent->new( timeout => 10 ) ) ),
      undef, 'malformed' );
    ok( $sync->is_failed, 'the sync shim fails the same request' );
    is( $async_error, $sync->is_failed ? ( $sync->failure )[0] : undef, 'same exception on both backends' );

    follow_up_ok( $engine, 'after the malformed line' );
  };
}

subtest 'caller cancels a stream mid-transfer: the transfer stops, the engine serves the next request' => sub {
  my $engine = engine('paced');
  my $calls  = 0;
  my $future = stream_f( $engine, sub { $calls++ } );
  $loop->await( $loop->delay_future( after => 0.08 ) );   # the paced stream runs ~0.2s
  ok( !$future->is_ready, 'still streaming' );
  $future->cancel;
  ok( $future->is_cancelled, 'the stream future is cancelled' );
  my $at_cancel = $calls;
  $loop->await( $loop->delay_future( after => 0.3 ) );    # past the end of the stream
  is( $calls, $at_cancel, 'no chunk reached chunk_callback after the cancel' );
  follow_up_ok( $engine, 'after the cancel' );
};

# Last, because the single-threaded daemon keeps pacing out the rest of the
# stream after the client has gone: a long paced stream (40 events, 2s) whose
# first chunk dies must fail at once, i.e. the transfer is cancelled rather
# than drained to the end.
subtest 'paced long stream: the transfer is stopped, not drained' => sub {
  my $engine = engine('paced');
  my $t0     = [ Time::HiRes::gettimeofday() ];
  my $dying  = stream_f( $engine, sub { die "user abort\n" }, 'long' );
  is( drive($dying), '', 'no exception escaped the event loop' );
  is( $dying->is_failed ? ( $dying->failure )[0] : undef, "user abort\n", 'failed with the original exception' );
  cmp_ok( Time::HiRes::tv_interval($t0), '<', 1, 'well before the 2s stream would have ended' );
};

done_testing;
