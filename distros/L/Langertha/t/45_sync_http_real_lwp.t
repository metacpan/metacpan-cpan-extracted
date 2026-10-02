#!/usr/bin/env perl
# ABSTRACT: SyncHTTP over a real LWP against a local daemon; sync/async parity for streaming + errors
use strict; use warnings;
use Test2::Bundle::More;
use FindBin;
use lib "$FindBin::Bin/lib";

BEGIN {
  plan skip_all => 'fork-based HTTP::Daemon test not supported on Windows' if $^O eq 'MSWin32';
  eval { require Future::AsyncAwait; 1 }
    or plan skip_all => 'Requires Future::AsyncAwait';
}

use HTTP::Request;
use HTTP::Response;
use JSON::MaybeXS;
use LWP::UserAgent;
use Test::LocalHTTPDaemon;
use Langertha::Request::SyncHTTP;
use Langertha::Engine::OpenAI;

my $json = JSON::MaybeXS->new( utf8 => 1, canonical => 1 );

# Deltas are sent as separate HTTP chunks with a pause in between, so a client
# that streams sees them arrive one by one, and one that buffers sees one blob.
my @DELTAS    = ( 'Hel', 'lo ', 'world' );
my $PAUSE     = 0.2;
my $ERROR_BODY = $json->encode({ error => { message => 'Incorrect API key provided', type => 'invalid_request_error' } });

sub sse_events {
  return (
    ( map { 'data: ' . $json->encode({ choices => [ { index => 0, delta => { content => $_ } } ] }) . "\n\n" } @DELTAS ),
    'data: ' . $json->encode({ choices => [ { index => 0, delta => {}, finish_reason => 'stop' } ] }) . "\n\n",
    "data: [DONE]\n\n",
  );
}

sub sse_stream {
  my @events = sse_events();
  my $first = 1;
  return HTTP::Response->new( 200, 'OK', [ 'Content-Type' => 'text/event-stream' ], sub {
    select( undef, undef, undef, $PAUSE ) unless $first;
    $first = 0;
    return shift(@events) // '';
  });
}

my $server = Test::LocalHTTPDaemon->start(sub {
  my ($request) = @_;
  my $path = $request->uri->path;
  if ( $path =~ m{^/unauth/} ) {
    return HTTP::Response->new( 401, 'Unauthorized', [ 'Content-Type' => 'application/json' ], $ERROR_BODY );
  }
  if ( $path =~ m{^/burst/} ) {
    # The whole SSE body in one Content-Length response: a die in the chunk
    # callback fires once, and no further chunks arrive later on a shared
    # IO::Async loop to rethrow into an unrelated ->get.
    return HTTP::Response->new( 200, 'OK', [ 'Content-Type' => 'text/event-stream' ], join( '', sse_events() ) );
  }
  if ( $path =~ m{^/stall/} ) {
    # First event, then silence past the client's read timeout.
    my @events = ( ( sse_events() )[0] );
    my $sent = 0;
    return HTTP::Response->new( 200, 'OK', [ 'Content-Type' => 'text/event-stream' ], sub {
      sleep 3 if $sent++;
      return shift(@events) // '';
    });
  }
  if ( $path =~ m{^/ok/} ) {
    my $body = eval { $json->decode( $request->content ) } || {};
    return sse_stream() if $body->{stream};
    return HTTP::Response->new( 200, 'OK', [ 'Content-Type' => 'application/json' ], $json->encode({
      id => 'chatcmpl-1', object => 'chat.completion', model => 'gpt-test',
      choices => [ { index => 0, message => { role => 'assistant', content => 'Hello world' }, finish_reason => 'stop' } ],
    }));
  }
  return HTTP::Response->new( 404, 'Not Found', [ 'Content-Type' => 'text/plain' ], 'no route' );
});
my $base = $server->url;

# A closed port for the connection-error case.
my $dead_url = do {
  require IO::Socket::INET;
  my $sock = IO::Socket::INET->new( LocalAddr => '127.0.0.1', LocalPort => 0, Listen => 1 ) or die $!;
  my $port = $sock->sockport;
  close $sock;
  "http://127.0.0.1:$port";
};

sub sync_client { Langertha::Request::SyncHTTP->new( user_agent => LWP::UserAgent->new( timeout => 10 ) ) }

sub stream_through {
  my ( $client, $url, %opts ) = @_;
  my %seen = ( headers => [], data => [], ends => 0 );
  my $future = $client->do_request(
    request   => HTTP::Request->new( POST => $url, [ 'Content-Type' => 'application/json' ], '{"stream":true}' ),
    on_header => sub {
      my ($response) = @_;
      push @{ $seen{headers} }, $response;
      return sub {
        my ($data) = @_;
        unless ( defined $data ) { $seen{ends}++; return }
        die "user abort\n" if $opts{die_on_chunk};
        push @{ $seen{data} }, $data;
      };
    },
  );
  return ( $future, \%seen );
}

# ---------------------------------------------------------------------------
# SyncHTTP unit, real LWP
# ---------------------------------------------------------------------------

subtest 'SyncHTTP streams a 200 incrementally over real LWP' => sub {
  my ( $future, $seen ) = stream_through( sync_client(), "$base/ok/v1/chat/completions" );
  ok( $future->is_ready, 'future already complete' );
  ok( $future->is_done, 'future resolved' );
  is( scalar @{ $seen->{headers} }, 1, 'on_header called exactly once' );
  is( $seen->{headers}[0]->code, 200, 'on_header got the 200 response' );
  cmp_ok( scalar @{ $seen->{data} }, '>', 1, 'body arrived in more than one chunk (LWP streams per read)' );
  like( join( '', @{ $seen->{data} } ), qr/"content":"world".*\[DONE\]/s, 'whole SSE body delivered' );
  is( $seen->{ends}, 1, 'end-of-body undef signalled once' );
};

subtest 'I1: SyncHTTP calls on_header for a non-2xx (LWP never fires the content callback)' => sub {
  my ( $future, $seen ) = stream_through( sync_client(), "$base/unauth/v1/chat/completions" );
  ok( $future->is_done, '4xx resolves the future (contract), does not fail it' );
  is( $future->get->code, 401, 'resolves to the 401 response' );
  is( scalar @{ $seen->{headers} }, 1, 'on_header called once' );
  is( $seen->{headers}[0]->code, 401, 'on_header got the 401 response' );
  is( join( '', @{ $seen->{data} } ), $ERROR_BODY, 'error body handed to the chunk-sub, as Net::Async::HTTP does' );
  is( $seen->{ends}, 1, 'end-of-body undef signalled once' );
};

subtest 'I1: SyncHTTP calls on_header on a connection error' => sub {
  my ( $future, $seen ) = stream_through( sync_client(), "$dead_url/v1/chat/completions" );
  ok( $future->is_done, 'future resolved with LWP\'s internal error response' );
  is( scalar @{ $seen->{headers} }, 1, 'on_header called once' );
  ok( !$seen->{headers}[0]->is_success, 'on_header response is not a success' );
};

subtest 'I2: a die in the chunk-sub fails the future (no silent truncation)' => sub {
  my ( $future, $seen ) = stream_through( sync_client(), "$base/burst/v1/chat/completions", die_on_chunk => 1 );
  ok( $future->is_ready, 'future is ready' );
  ok( $future->is_failed, 'future failed instead of resolving the truncated stream' );
  is( ( $future->failure )[0], "user abort\n", 'original exception propagated' );
  is( $seen->{ends}, 0, 'no end-of-body signal after an aborted stream' );
};

subtest 'I2: LWP aborting mid-body (read timeout, X-Died) fails the future' => sub {
  my $client = Langertha::Request::SyncHTTP->new( user_agent => LWP::UserAgent->new( timeout => 1 ) );
  my ( $future, $seen ) = stream_through( $client, "$base/stall/v1/chat/completions" );
  ok( $future->is_failed, 'future failed' );
  like( ( $future->failure )[0], qr/timeout/i, 'LWP abort reason propagated' );
  cmp_ok( scalar @{ $seen->{data} }, '>=', 1, 'the chunk before the stall was delivered' );
  is( $seen->{ends}, 0, 'no end-of-body signal after an aborted stream' );
};

# ---------------------------------------------------------------------------
# End to end through chat_stream_realtime_f / chat_f, sync vs async
# ---------------------------------------------------------------------------

my $have_async = eval { require Net::Async::HTTP; require IO::Async::Loop; 1 };

sub engine {
  my ( $backend, $prefix ) = @_;
  return Langertha::Engine::OpenAI->new(
    api_key => 'test-key',
    model   => 'gpt-test',
    url     => "$base/$prefix/v1",
    ( $backend eq 'sync' ? ( _async_http => sync_client() ) : () ),
  );
}

sub run_stream {
  my ( $backend, $prefix, %opts ) = @_;
  my @callbacks;
  my @result = eval {
    engine( $backend, $prefix )->chat_stream_realtime_f(
      messages       => [ { role => 'user', content => 'hi' } ],
      chunk_callback => sub {
        die "user abort\n" if $opts{die_on_chunk};
        push @callbacks, $_[0]->content;
      },
    )->get;
  };
  return { error => $@, result => \@result, callbacks => \@callbacks };
}

sub run_chat_f {
  my ( $backend, $prefix ) = @_;
  my $response = eval {
    engine( $backend, $prefix )->chat_f( messages => [ { role => 'user', content => 'hi' } ] )->get;
  };
  return { error => $@, response => $response };
}

my @backends = ( 'sync', ( $have_async ? 'async' : () ) );
diag('Net::Async::HTTP not installed: async half of the parity checks skipped') unless $have_async;

subtest 'sync streaming end to end through chat_stream_realtime_f' => sub {
  my $run = run_stream( 'sync', 'ok' );
  is( $run->{error}, '', 'no error' );
  my ( $content, $chunks, $timing ) = @{ $run->{result} };
  is( $content, 'Hello world', 'aggregated content' );
  is_deeply( [ grep { length } @{ $run->{callbacks} } ], [@DELTAS], 'chunk_callback fired per delta, in order' );
  ok( defined $timing->{ttft_seconds}, 'ttft recorded' );
  cmp_ok( $timing->{ttft_seconds}, '<', $timing->{total_seconds} - $PAUSE,
    'first token arrived well before the stream ended (incremental, not buffered)' );
};

for my $backend (@backends) {
  subtest "I1 via chat_stream_realtime_f on 401 ($backend)" => sub {
    my $run = run_stream( $backend, 'unauth' );
    like( $run->{error}, qr/^Langertha::Engine::OpenAI streaming request failed: 401 Unauthorized /,
      'fails with the streaming-request-failed status line' );
  };
}

SKIP: {
  skip 'Net::Async::HTTP not installed', 3 unless $have_async;

  subtest 'parity: streaming 200 — sync and async aggregate identically' => sub {
    my $sync  = run_stream( 'sync', 'ok' );
    my $async = run_stream( 'async', 'ok' );
    is( $sync->{error}, '', 'sync ok' );
    is( $async->{error}, '', 'async ok' );
    is( $sync->{result}[0], $async->{result}[0], 'same aggregated content' );
    is_deeply( $sync->{callbacks}, $async->{callbacks}, 'same chunk_callback sequence' );
    is( scalar @{ $sync->{result}[1] }, scalar @{ $async->{result}[1] }, 'same chunk count' );
  };

  subtest 'parity: streaming 4xx with a body — identical error' => sub {
    is( run_stream( 'sync', 'unauth' )->{error}, run_stream( 'async', 'unauth' )->{error},
      'same croak text on both backends' );
  };

  subtest 'parity: chat_f 4xx with a body — identical error; 200 identical response' => sub {
    my $sync  = run_chat_f( 'sync', 'unauth' );
    my $async = run_chat_f( 'async', 'unauth' );
    like( $sync->{error}, qr/^Langertha::Engine::OpenAI request failed: 401 Unauthorized /, 'sync error text' );
    is( $sync->{error}, $async->{error}, 'same croak text on both backends' );

    my $sync_ok  = run_chat_f( 'sync', 'ok' );
    my $async_ok = run_chat_f( 'async', 'ok' );
    is( "$sync_ok->{response}", 'Hello world', 'sync content' );
    is( "$sync_ok->{response}", "$async_ok->{response}", 'same content' );
    is( $sync_ok->{response}->model, $async_ok->{response}->model, 'same model' );
    is( scalar @{ $sync_ok->{response}->tool_calls // [] }, scalar @{ $async_ok->{response}->tool_calls // [] },
      'same tool_calls' );
  };
}

# Last: an aborted stream leaves the async client's connection mid-body.
for my $backend (@backends) {
  subtest "I2 via chat_stream_realtime_f, chunk_callback dies ($backend)" => sub {
    my $run = run_stream( $backend, 'burst', die_on_chunk => 1 );
    is( $run->{error}, "user abort\n", 'the chunk_callback exception propagates' );
  };
}

done_testing;
