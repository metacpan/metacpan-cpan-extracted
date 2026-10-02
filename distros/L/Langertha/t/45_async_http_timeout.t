#!/usr/bin/env perl
# ABSTRACT: user_agent_timeout bounds requests on the Net::Async::HTTP backend (total, or stall when streaming)
use strict;
use warnings;
use Test2::Bundle::More;
use lib 't/lib';

BEGIN {
  plan skip_all => 'fork-based HTTP::Daemon test not supported on Windows' if $^O eq 'MSWin32';
  eval { require Net::Async::HTTP; require IO::Async::Loop; 1 }
    or plan skip_all => 'Requires Net::Async::HTTP and IO::Async (the async backend under test)';
}

use Future;
use IO::Socket::INET;
use HTTP::Request;
use HTTP::Response;
use JSON::MaybeXS;
use LWP::UserAgent;
use Time::HiRes qw( time );
use Test::LocalHTTPDaemon;
use Langertha::Chat;
use Langertha::Request::SyncHTTP;
use Langertha::Engine::OpenAI;

# karr k278 (ADR 0027): user_agent_timeout only reached the LWP user agent, so
# on the Net::Async::HTTP backend a provider that accepts and never answers
# (or stops mid-stream) left the chat Future pending forever -- inside the
# event loop knarr/skeid/raider serve everything else from. When it is set it
# now bounds the async request too: a non-streaming request fails after N
# seconds in total; a stream fails after N seconds without a byte (a long but
# steady stream is legitimate and must not be cut off). k373: the healthy-server
# subtests use 2-3s timeouts (stall 2s, steady 3s with 0.5s gaps) because a 1s
# limit raced a slow first byte from the local daemon on a loaded machine; only
# the deliberately hanging subtests keep 1s. The failure names the
# engine and the URL (query dropped, it may carry a key). Unset keeps the old
# behavior (no timeout), and the sync LWP path is untouched.

my $json = JSON::MaybeXS->new( utf8 => 1, canonical => 1 );

# Accepts connections (the kernel completes the handshake) and never answers.
my $hang = IO::Socket::INET->new( Listen => 5, LocalAddr => '127.0.0.1', LocalPort => 0,
  Proto => 'tcp', ReuseAddr => 1 ) or die "listen: $!";
my $hang_base = 'http://127.0.0.1:' . $hang->sockport;

sub sse_event { 'data: ' . $json->encode({ choices => [ { index => 0, delta => { content => $_[0] } } ] }) . "\n\n" }
my @DONE = (
  'data: ' . $json->encode({ choices => [ { index => 0, delta => {}, finish_reason => 'stop' } ] }) . "\n\n",
  "data: [DONE]\n\n",
);

# keep_alive: every connection gets its own child, so a stalling stream does
# not pin the daemon for the next subtest.
my $server = Test::LocalHTTPDaemon->start( sub {
  my ($request) = @_;
  my ($route) = $request->uri->path =~ m{^/([^/]+)/};
  my @events;
  my $pause;
  if ( $route eq 'stall' ) {            # one chunk, then silence
    @events = ( sse_event('first'), 'STALL', sse_event('never'), @DONE );
  }
  elsif ( $route eq 'steady' ) {        # 7 chunks 0.5s apart: 4s in total, never more than 0.5s silent
    @events = ( ( map { sse_event("c$_") } 1 .. 7 ), @DONE );
    $pause  = 0.5;
  }
  else {
    return HTTP::Response->new( 200, 'OK', [ 'Content-Type' => 'application/json' ],
      $json->encode({ id => 'x', object => 'chat.completion', created => 1, model => 'm',
        choices => [ { index => 0, finish_reason => 'stop',
          message => { role => 'assistant', content => 'ok' } } ] }) );
  }
  my $sent = 0;
  return HTTP::Response->new( 200, 'OK', [ 'Content-Type' => 'text/event-stream' ], sub {
    return '' unless @events;
    my $next = shift @events;
    if ( $next eq 'STALL' ) { sleep 20; $next = shift @events }
    Time::HiRes::sleep($pause) if $pause && $sent++;
    return $next;
  } );
}, keep_alive => 1 );
my $base = $server->url;

my $loop = IO::Async::Loop->new;

# Record the options every backend request is sent with.
my @nahttp_args;
my @sync_args;
{
  no warnings 'redefine';
  my $na = \&Net::Async::HTTP::do_request;
  *Net::Async::HTTP::do_request = sub { my ( $self, %args ) = @_; push @nahttp_args, \%args; goto &$na };
  my $sy = \&Langertha::Request::SyncHTTP::do_request;
  *Langertha::Request::SyncHTTP::do_request = sub { my ( $self, %args ) = @_; push @sync_args, \%args; goto &$sy };
}

sub engine {
  my ( $url, %args ) = @_;
  return Langertha::Engine::OpenAI->new( api_key => 'sk-secret-test-key', model => 'gpt-test',
    url => $url, %args );
}

# Drives $f on the loop, but never longer than $max seconds (a regression
# reports a failure instead of hanging the suite).
sub run_capped {
  my ( $f, $max ) = @_;
  my $cap = $loop->delay_future( after => $max );
  $loop->await( Future->wait_any( $f->without_cancel, $cap ) );
  $cap->cancel unless $cap->is_ready;
  return $f;
}

sub failure_of { my ($f) = @_; return $f->is_failed ? scalar $f->failure : '' }

subtest 'non-streaming chat_f against a server that never answers fails after N seconds' => sub {
  my $e = engine( "$hang_base/v1", user_agent_timeout => 1 );
  ok $e->_async_http->isa('Net::Async::HTTP'), 'engine runs on the Net::Async::HTTP backend';
  @nahttp_args = ();
  my $t0 = time;
  my $f  = $e->chat_f( messages => [ { role => 'user', content => 'hi' } ] );
  run_capped( $f, 10 );
  my $took = time - $t0;
  ok $f->is_failed, 'chat_f fails instead of hanging';
  is failure_of($f),
    "Langertha::Engine::OpenAI: request to $hang_base/v1/chat/completions timed out after 1s\n",
    '... with the engine, the URL and the timeout in the message';
  is( ( $f->is_failed ? ( $f->failure )[1] : undef ), 'timeout', '... category timeout' );
  unlike failure_of($f), qr/sk-secret/, '... and no secret';
  ok $took >= 0.9 && $took < 5, "... after about the configured second (took ${\ sprintf '%.2f', $took }s)";
  is $nahttp_args[0]{timeout}, 1, '... sent as a total timeout';
  ok !exists $nahttp_args[0]{stall_timeout}, '... not as a stall timeout';
};

subtest 'Langertha::Chat simple_chat_f goes through the same timeout' => sub {
  my $chat = Langertha::Chat->new( engine => engine( "$hang_base/v1", user_agent_timeout => 1 ) );
  my $f = $chat->simple_chat_f('hi');
  run_capped( $f, 10 );
  like failure_of($f), qr/\ALangertha::Engine::OpenAI: request to \Q$hang_base\E\/v1\/chat\/completions timed out after 1s$/,
    'the wrapper fails with the same message';
};

subtest 'a stream that sends one chunk and then stalls fails as a stall' => sub {
  my $e = engine( "$base/stall/v1", user_agent_timeout => 2 );
  @nahttp_args = ();
  my @seen;
  my $t0 = time;
  my $f  = $e->chat_stream_realtime_f( messages => [ { role => 'user', content => 'hi' } ],
    chunk_callback => sub { push @seen, $_[0]->content } );
  run_capped( $f, 10 );
  my $took = time - $t0;
  ok $f->is_failed, 'the stream fails instead of hanging';
  like failure_of($f),
    qr/\ALangertha::Engine::OpenAI: streaming request to \Q$base\E\/stall\/v1\/chat\/completions timed out after 2s without data \(Stalled while receiving [^)]+\)\n\z/,
    '... named a stall, with engine, URL and timeout';
  is( ( $f->is_failed ? ( $f->failure )[1] : undef ), 'stall_timeout', '... category stall_timeout' );
  is_deeply \@seen, ['first'], '... after delivering the chunk that did arrive';
  ok $took >= 1.9 && $took < 8, "... about the timeout after the last byte (took ${\ sprintf '%.2f', $took }s)";
  is $nahttp_args[0]{stall_timeout}, 2, '... sent as a stall timeout';
  ok !exists $nahttp_args[0]{timeout}, '... not as a total timeout';
};

subtest 'a slow but steady stream longer than N seconds in total does not time out' => sub {
  my $e = engine( "$base/steady/v1", user_agent_timeout => 3 );
  my $t0 = time;
  my $f  = $e->chat_stream_realtime_f( messages => [ { role => 'user', content => 'hi' } ] );
  run_capped( $f, 15 );
  my $took = time - $t0;
  ok $f->is_done, 'the stream completes' or diag failure_of($f);
  is( ( $f->is_done ? ( $f->get )[0] : undef ), 'c1c2c3c4c5c6c7', '... with all its content' );
  ok $took > 3.3, "... although it took longer than the timeout in total (${\ sprintf '%.2f', $took }s)";
};

subtest 'without user_agent_timeout nothing changes: no timeout on the async backend' => sub {
  my $e = engine("$hang_base/v1");
  @nahttp_args = ();
  my $f = $e->chat_f( messages => [ { role => 'user', content => 'hi' } ] );
  run_capped( $f, 1.5 );
  ok !$f->is_ready, 'still pending after 1.5s against a server that never answers';
  $f->cancel;
  ok !exists $nahttp_args[0]{timeout} && !exists $nahttp_args[0]{stall_timeout},
    '... no timeout option was passed to Net::Async::HTTP';
};

subtest 'async_request_f (public hook) honors it too, and never leaks the query' => sub {
  my $e = engine( "$hang_base/v1", user_agent_timeout => 1 );
  my $req = HTTP::Request->new( GET => "http://user:pw\@127.0.0.1:" . $hang->sockport . "/v1beta/models?key=sekrit" );
  my $f = $e->async_request_f($req);
  run_capped( $f, 10 );
  is failure_of($f),
    "Langertha::Engine::OpenAI: request to $hang_base/v1beta/models timed out after 1s\n",
    'fails with the query and userinfo stripped from the URL';

  @nahttp_args = ();
  my $own = $e->async_request_f( HTTP::Request->new( GET => "$hang_base/x" ), timeout => 3 );
  is $nahttp_args[0]{timeout}, 3, "a caller's own timeout option wins";
  $own->cancel;
};

subtest 'a transport error is passed through, not rewritten' => sub {
  my $e = engine( "$base/steady/v1", user_agent_timeout => 1 );
  my $f = $e->async_request_f( HTTP::Request->new( GET => 'http://127.0.0.1:1/x' ) );
  run_capped( $f, 10 );
  ok $f->is_failed, 'connection refused still fails';
  unlike failure_of($f), qr/timed out/, '... with the socket error, not a timeout message';
};

subtest 'sync LWP fallback is unchanged' => sub {
  my $ua = LWP::UserAgent->new( timeout => 1 );
  my $e  = engine( "$hang_base/v1", user_agent_timeout => 1, user_agent => $ua,
    _async_http => Langertha::Request::SyncHTTP->new( user_agent => $ua ) );
  @sync_args = ();
  my $f = $e->chat_f( messages => [ { role => 'user', content => 'hi' } ] );
  ok $f->is_failed, "LWP's own timeout fails the request";
  like failure_of($f), qr/request failed: 500 read timeout/, '... as before (500 read timeout)';
  ok !exists $sync_args[0]{timeout} && !exists $sync_args[0]{stall_timeout},
    '... no timeout option is passed to the shim';
};

done_testing;
