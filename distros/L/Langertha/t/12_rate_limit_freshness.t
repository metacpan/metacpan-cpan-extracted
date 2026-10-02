#!/usr/bin/env perl
# ABSTRACT: Engine and Response rate_limit describe the latest response, including error responses

use strict;
use warnings;

use Test2::Bundle::More;
use FindBin;
use lib "$FindBin::Bin/lib";

BEGIN {
  eval { require Future::AsyncAwait; 1 }
    or plan skip_all => 'Requires Future::AsyncAwait';
}

use HTTP::Date ();
use HTTP::Response;
use JSON::MaybeXS;
use LWP::UserAgent;
use Test::MockAsyncHTTP;
use Test::MockMCP;
use Langertha::Chat;
use Langertha::RateLimit;
use Langertha::Request::SyncHTTP;
use Langertha::Engine::Anthropic;
use Langertha::Engine::Groq;
use Langertha::Engine::OpenAI;

# karr k300. Two ways the engine's rate_limit lied about the response a caller
# just got:
#
# 1. A response with no rate-limit headers left the previous response's
#    RateLimit on the engine, and simple_chat / chat_f cloned that stale
#    object onto the new Response. Response.rate_limit must describe the
#    response it sits on, so a response without headers clears it.
# 2. Error responses croaked before the headers were read. A 429 is exactly
#    the response whose remaining = 0, reset and retry-after a caller needs to
#    back off, so the engine takes them before the croak, on the sync path and
#    on every async path (chat_f, simple_chat_f, chat_with_tools_f, streaming),
#    with the same result on every backend (ADR 0027 parity).
#
# retry-after is a duration (ADR 0022 Update): RateLimit->retry_after gives the
# seconds whether the wire sent delta-seconds or an HTTP-date.

my $json = JSON::MaybeXS->new( utf8 => 1, canonical => 1 );

my %LIMITED_HEADERS = (
  'x-ratelimit-limit-requests'     => '100',
  'x-ratelimit-remaining-requests' => '0',
  'x-ratelimit-reset-requests'     => '7.66s',
  'retry-after'                    => '8',
);
my %OK_HEADERS = (
  'x-ratelimit-limit-requests'     => '100',
  'x-ratelimit-remaining-requests' => '100',
  'x-ratelimit-reset-requests'     => '1s',
);
my $ERROR_BODY = $json->encode({ error => { message => 'Rate limit reached', type => 'requests' } });
my $OK_BODY = $json->encode({
  id => 'chatcmpl-1', object => 'chat.completion', model => 'gpt-test',
  choices => [ { index => 0, message => { role => 'assistant', content => 'Hello' }, finish_reason => 'stop' } ],
});

sub http_limited {
  my $res = HTTP::Response->new( 429, 'Too Many Requests',
    [ 'Content-Type' => 'application/json', %LIMITED_HEADERS ], $ERROR_BODY );
  return $res;
}
sub http_ok {
  my (%headers) = @_;
  return HTTP::Response->new( 200, 'OK', [ 'Content-Type' => 'application/json', %headers ], $OK_BODY );
}

sub assert_limited {
  my ( $engine, $label ) = @_;
  ok( $engine->has_rate_limit, "$label: engine has the 429's rate limit" );
  my $rl = $engine->rate_limit or return;
  is( $rl->requests_remaining, 0, "$label: requests_remaining is the 429's 0, not the last success's 100" );
  is( $rl->requests_reset_after, 7.66, "$label: reset from the 429" );
  is( $rl->retry_after, 8, "$label: retry_after from the 429" );
}

# ======================================================================
# RateLimit->retry_after: a duration in seconds from either wire form
# ======================================================================

subtest 'retry_after from delta-seconds' => sub {
  my $rl = Langertha::RateLimit->new( raw => { 'retry-after' => '8' } );
  is( $rl->retry_after, 8, 'delta-seconds read as seconds' );
  is( $rl->to_hash->{retry_after}, 8, 'to_hash carries retry_after' );
  is( $rl->TO_JSON->{retry_after}, 8, 'TO_JSON carries retry_after' );
  is( Langertha::RateLimit->new( raw => { 'retry-after' => ' 0 ' } )->retry_after, 0,
    'a zero stays a defined 0' );
  is( Langertha::RateLimit->new( raw => { 'retry-after' => '1.5' } )->retry_after, 1.5,
    'a fractional value is accepted as seconds' );
};

subtest 'retry_after from an HTTP-date, measured from received' => sub {
  my $received = Langertha::Moment->from_epoch(1_800_000_000);
  my $date = HTTP::Date::time2str( 1_800_000_000 + 30 );
  my $rl = Langertha::RateLimit->new( received => $received, raw => { 'retry-after' => $date } );
  is( $rl->retry_after, 30, "HTTP-date $date is 30s after received" );

  my $past = Langertha::RateLimit->new( received => $received,
    raw => { 'retry-after' => HTTP::Date::time2str( 1_800_000_000 - 30 ) } );
  is( $past->retry_after, 0, 'a date already passed means retry now (0), not a negative wait' );
};

subtest 'retry_after is undef when absent or unreadable' => sub {
  my $none = Langertha::RateLimit->new( raw => { 'x-ratelimit-remaining-requests' => '5' } );
  is( $none->retry_after, undef, 'no retry-after header: undef, no invented default' );
  ok( !exists $none->to_hash->{retry_after}, 'to_hash omits it' );
  is( Langertha::RateLimit->new( raw => { 'retry-after' => 'soon' } )->retry_after, undef,
    'an unreadable value stays undef (raw keeps it)' );
};

# ======================================================================
# Sync: parse_response / chat_response
# ======================================================================

subtest 'sync: a response without headers clears the previous rate limit' => sub {
  my $groq = Langertha::Engine::Groq->new( api_key => 'k', model => 'm' );
  $groq->chat_response( http_ok(%OK_HEADERS) );
  is( $groq->rate_limit->requests_remaining, 100, 'first response sets the rate limit' );
  $groq->chat_response( http_ok() );
  ok( !$groq->has_rate_limit, 'second response without headers leaves no rate limit' );
  is( $groq->rate_limit, undef, 'rate_limit is undef, not the first response\'s' );
};

subtest 'sync: a 429 updates the rate limit before the croak' => sub {
  my $groq = Langertha::Engine::Groq->new( api_key => 'k', model => 'm' );
  $groq->chat_response( http_ok(%OK_HEADERS) );
  my $ok = eval { $groq->chat_response( http_limited() ); 1 };
  ok( !$ok, 'the 429 croaks' );
  like( $@, qr/\ALangertha::Engine::Groq request failed: 429 Too Many Requests \(retry after 8s\) - /,
    'croak names the retry-after seconds' );
  assert_limited( $groq, 'sync Groq' );
};

subtest 'sync: an Anthropic 429 with an HTTP-date retry-after' => sub {
  my $claude = Langertha::Engine::Anthropic->new( api_key => 'k', model => 'm' );
  my $res = HTTP::Response->new( 429, 'Too Many Requests', [
    'Content-Type' => 'application/json',
    'anthropic-ratelimit-requests-remaining' => '0',
    'retry-after' => HTTP::Date::time2str( time + 3600 ),
  ], '{"type":"error"}' );
  eval { $claude->chat_response($res) };
  like( $@, qr/request failed: 429 Too Many Requests \(retry after [0-9.]+s\) - /, 'croak names the retry-after' );
  is( $claude->rate_limit->requests_remaining, 0, 'Anthropic engine took the 429 headers' );
  cmp_ok( $claude->rate_limit->retry_after, '>', 3500, 'retry_after measured from the HTTP-date' );
};

subtest 'sync: an error without headers clears the rate limit too' => sub {
  my $groq = Langertha::Engine::Groq->new( api_key => 'k', model => 'm' );
  $groq->chat_response( http_ok(%OK_HEADERS) );
  eval { $groq->chat_response( HTTP::Response->new( 500, 'Internal Server Error', [], 'boom' ) ) };
  like( $@, qr/request failed: 500 Internal Server Error - boom at /, 'no retry note without the header' );
  ok( !$groq->has_rate_limit, 'the 500 carried no rate limit, so none is reported' );
};

# ======================================================================
# Mocked async: chat_f, simple_chat_f, chat_with_tools_f, Langertha::Chat
# ======================================================================

sub mock_engine {
  my (@responses) = @_;
  return Langertha::Engine::Groq->new( api_key => 'k', model => 'm',
    _async_http => Test::MockAsyncHTTP->new( responses => \@responses ) );
}

subtest 'chat_f: a response without headers carries no rate limit' => sub {
  my $groq = mock_engine( http_ok(%OK_HEADERS), http_ok() );
  my $first = $groq->chat_f( messages => ['hi'] )->get;
  is( $first->rate_limit->requests_remaining, 100, 'first Response carries its rate limit' );
  my $second = $groq->chat_f( messages => ['hi'] )->get;
  ok( !$second->has_rate_limit, 'second Response has no rate limit of its own and gets none' );
  ok( !$groq->has_rate_limit, 'engine rate limit cleared' );
};

subtest 'chat_f / simple_chat_f: a 429 updates the rate limit before the die' => sub {
  for my $method (qw( chat_f simple_chat_f )) {
    my $groq = mock_engine( http_ok(%OK_HEADERS), http_limited() );
    $groq->chat_f( messages => ['hi'] )->get;
    my $ok = eval {
      ( $method eq 'chat_f' ? $groq->chat_f( messages => ['hi'] ) : $groq->simple_chat_f('hi') )->get;
      1;
    };
    ok( !$ok, "$method: the 429 fails" );
    like( $@, qr/request failed: 429 Too Many Requests \(retry after 8s\)/, "$method: error names the retry-after" );
    assert_limited( $groq, $method );
  }
};

subtest 'chat_with_tools_f: a 429 updates the rate limit before the die' => sub {
  my $groq = Langertha::Engine::Groq->new( api_key => 'k', model => 'm',
    _async_http => Test::MockAsyncHTTP->new( responses => [ http_limited() ] ),
    mcp_servers => [ Test::MockMCP->new( tools => [ {
      name => 'noop', description => 'no-op', input_schema => { type => 'object', properties => {} },
      code => sub { $_[0]->text_result('ok') },
    } ] ) ] );
  my $ok = eval { $groq->chat_with_tools_f('hi')->get; 1 };
  ok( !$ok, 'the 429 fails' );
  like( $@, qr/tool chat request failed: 429 Too Many Requests \(retry after 8s\)/, 'error names the retry-after' );
  assert_limited( $groq, 'chat_with_tools_f' );
};

subtest 'Langertha::Chat simple_chat_f: a 429 updates the engine before the die' => sub {
  my $groq = mock_engine( http_limited() );
  my $chat = Langertha::Chat->new( engine => $groq );
  my $ok = eval { $chat->simple_chat_f('hi')->get; 1 };
  ok( !$ok, 'the 429 fails' );
  like( $@, qr/request failed: 429 Too Many Requests \(retry after 8s\)/, 'error names the retry-after' );
  assert_limited( $groq, 'Langertha::Chat' );
};

# ======================================================================
# Real transport: LWP (sync simple_chat, SyncHTTP shim) and Net::Async::HTTP
# ======================================================================

SKIP: {
  skip 'fork-based HTTP::Daemon test not supported on Windows', 1 if $^O eq 'MSWin32';
  require Test::LocalHTTPDaemon;

  my $server = Test::LocalHTTPDaemon->start(sub {
    my ($request) = @_;
    my $path = $request->uri->path;
    my $body = eval { $json->decode( $request->content ) } || {};
    return http_limited() if $path =~ m{^/limited/};
    my %headers = $path =~ m{^/ok/} ? %OK_HEADERS : ();
    if ( $body->{stream} ) {
      return HTTP::Response->new( 200, 'OK', [ 'Content-Type' => 'text/event-stream', %headers ], join '',
        'data: ' . $json->encode({ choices => [ { index => 0, delta => { content => 'Hello' } } ] }) . "\n\n",
        'data: ' . $json->encode({ choices => [ { index => 0, delta => {}, finish_reason => 'stop' } ] }) . "\n\n",
        "data: [DONE]\n\n" );
    }
    return http_ok(%headers);
  });
  my $base = $server->url;

  my $have_async = eval { require Net::Async::HTTP; require IO::Async::Loop; 1 };
  diag('Net::Async::HTTP not installed: async backend skipped') unless $have_async;
  my @backends = ( 'sync', ( $have_async ? 'async' : () ) );

  # A fresh engine per route; a test seeds a stale rate limit on it through
  # _last_rate_limit to stand for an earlier successful response.
  my $engine_for = sub {
    my ( $backend, $prefix ) = @_;
    return Langertha::Engine::Groq->new( api_key => 'k', model => 'm', url => "$base/$prefix/v1",
      ( $backend eq 'sync'
        ? ( _async_http => Langertha::Request::SyncHTTP->new( user_agent => LWP::UserAgent->new( timeout => 10 ) ) )
        : () ) );
  };
  subtest 'real transport' => sub {
    for my $backend (@backends) {
      subtest "chat_f 429 ($backend)" => sub {
        my $groq = $engine_for->( $backend, 'ok' );
        $groq->chat_f( messages => ['hi'] )->get;
        is( $groq->rate_limit->requests_remaining, 100, 'warm-up set the rate limit' );
        my $limited = $engine_for->( $backend, 'limited' );
        $limited->_last_rate_limit($groq->rate_limit);   # as if it had answered first
        my $ok = eval { $limited->chat_f( messages => ['hi'] )->get; 1 };
        ok( !$ok, 'the 429 fails' );
        like( $@, qr/\ALangertha::Engine::Groq request failed: 429 Too Many Requests \(retry after 8s\)/,
          'error names the retry-after' );
        assert_limited( $limited, "chat_f $backend" );
      };

      subtest "chat_f without headers clears ($backend)" => sub {
        my $groq = $engine_for->( $backend, 'bare' );
        $groq->_last_rate_limit(Langertha::RateLimit->new( requests_remaining => 100 ));
        my $response = $groq->chat_f( messages => ['hi'] )->get;
        is( "$response", 'Hello', 'the call succeeded' );
        ok( !$response->has_rate_limit, 'Response carries no stale rate limit' );
        ok( !$groq->has_rate_limit, 'engine rate limit cleared' );
      };

      subtest "chat_stream_realtime_f takes the rate limit ($backend)" => sub {
        my $groq = $engine_for->( $backend, 'ok' );
        my ($content) = $groq->chat_stream_realtime_f( messages => ['hi'] )->get;
        is( $content, 'Hello', 'the stream succeeded' );
        is( $groq->rate_limit && $groq->rate_limit->requests_remaining, 100,
          'a streamed response updates the rate limit' );

        my $bare = $engine_for->( $backend, 'bare' );
        $bare->_last_rate_limit(Langertha::RateLimit->new( requests_remaining => 100 ));
        $bare->chat_stream_realtime_f( messages => ['hi'] )->get;
        ok( !$bare->has_rate_limit, 'a streamed response without headers clears it' );

        my $limited = $engine_for->( $backend, 'limited' );
        $limited->_last_rate_limit(Langertha::RateLimit->new( requests_remaining => 100 ));
        my $ok = eval { $limited->chat_stream_realtime_f( messages => ['hi'] )->get; 1 };
        ok( !$ok, 'the streamed 429 fails' );
        like( $@, qr/\ALangertha::Engine::Groq streaming request failed: 429 Too Many Requests \(retry after 8s\)/,
          'error names the retry-after' );
        assert_limited( $limited, "chat_stream_realtime_f $backend" );
      };
    }

    subtest 'sync simple_chat and simple_chat_stream over LWP' => sub {
      my $limited = Langertha::Engine::Groq->new( api_key => 'k', model => 'm', url => "$base/limited/v1" );
      $limited->_last_rate_limit(Langertha::RateLimit->new( requests_remaining => 100 ));
      eval { $limited->simple_chat('hi') };
      like( $@, qr/request failed: 429 Too Many Requests \(retry after 8s\)/, 'simple_chat croak names retry-after' );
      assert_limited( $limited, 'simple_chat' );

      my $bare = Langertha::Engine::Groq->new( api_key => 'k', model => 'm', url => "$base/bare/v1" );
      $bare->_last_rate_limit(Langertha::RateLimit->new( requests_remaining => 100 ));
      my $response = $bare->simple_chat('hi');
      ok( !$response->has_rate_limit, 'simple_chat Response carries no stale rate limit' );

      my $stream = Langertha::Engine::Groq->new( api_key => 'k', model => 'm', url => "$base/ok/v1" );
      $stream->simple_chat_stream( sub { }, 'hi' );
      is( $stream->rate_limit && $stream->rate_limit->requests_remaining, 100,
        'sync streaming updates the rate limit' );

      my $stream_limited = Langertha::Engine::Groq->new( api_key => 'k', model => 'm', url => "$base/limited/v1" );
      eval { $stream_limited->simple_chat_stream( sub { }, 'hi' ) };
      like( $@, qr/streaming request failed: 429 Too Many Requests \(retry after 8s\)/, 'sync stream croak names retry-after' );
      assert_limited( $stream_limited, 'simple_chat_stream' );
    };
  };
}

done_testing;
