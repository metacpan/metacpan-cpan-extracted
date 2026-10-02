#!/usr/bin/env perl
# ABSTRACT: Retry-After on every engine, retry-after-ms preferred, and one error text on every backend

use strict;
use warnings;

use Test2::Bundle::More;
use FindBin;
use lib "$FindBin::Bin/lib";

BEGIN {
  eval { require Future::AsyncAwait; 1 }
    or plan skip_all => 'Requires Future::AsyncAwait';
}

use HTTP::Response;
use JSON::MaybeXS;
use LWP::UserAgent;
use Test::MockAsyncHTTP;
use Langertha::Chat;
use Langertha::RateLimit;
use Langertha::Request::SyncHTTP;
use Langertha::Engine::AKI;
use Langertha::Engine::Anthropic;
use Langertha::Engine::Gemini;
use Langertha::Engine::Groq;
use Langertha::Engine::LMStudio;
use Langertha::Engine::Ollama;

# karr k312, follow-ups to k300 (ADR 0022 Update):
#
# 1. Engines without a dialect rate-limit parser (Gemini, Ollama native, AKI
#    native, LM Studio native) recorded no rate limit at all, so a 429/503 that
#    said Retry-After left the caller nothing to back off from. The base parser
#    now records retry_after (and raw) whenever the response sends one — no
#    per-engine parsers.
# 2. retry-after-ms (Azure OpenAI, openai-python's first choice) is the more
#    precise answer: it wins over Retry-After, both stay in raw, and the error
#    message says the same number retry_after does.
# 3. A caller must not have to know which backend ran the request to read its
#    error: async chat_f / simple_chat_f / streaming fail with exactly the text
#    the sync croak has, provider body included (ADR 0027 parity).

my $json = JSON::MaybeXS->new( utf8 => 1, canonical => 1 );
my $ERROR_BODY = $json->encode({ error => { message => 'Rate limit reached', type => 'requests' } });

# The error text without the " at FILE line N." a die/croak appends: that part
# names the Perl frame, not the failure.
sub message_of {
  my ($err) = @_;
  $err = "$err";
  $err =~ s/ at \S+ line \d+\.?\n\z//;
  return $err;
}

sub http_error {
  my ( $code, $reason, %headers ) = @_;
  return HTTP::Response->new( $code, $reason,
    [ 'Content-Type' => 'application/json', %headers ], $ERROR_BODY );
}

# ======================================================================
# 1. Base parser: Retry-After without provider rate-limit headers
# ======================================================================

my %NATIVE = (
  Gemini   => sub { Langertha::Engine::Gemini->new( api_key => 'k', model => 'm' ) },
  Ollama   => sub { Langertha::Engine::Ollama->new( url => 'http://localhost:11434', model => 'm' ) },
  AKI      => sub { Langertha::Engine::AKI->new( api_key => 'k', model => 'm' ) },
  LMStudio => sub { Langertha::Engine::LMStudio->new( url => 'http://localhost:1234', model => 'm' ) },
);

for my $name ( sort keys %NATIVE ) {
  subtest "$name native: a 429 with Retry-After records retry_after" => sub {
    my $engine = $NATIVE{$name}->();
    my $ok = eval { $engine->chat_response( http_error( 429, 'Too Many Requests', 'Retry-After' => '5' ) ); 1 };
    ok( !$ok, 'the 429 croaks' );
    like( $@, qr/ request failed: 429 Too Many Requests \(retry after 5s\) - /, 'croak names the wait' );
    ok( $engine->has_rate_limit, 'the engine has a rate limit from the 429' );
    my $rl = $engine->rate_limit or return;
    is( $rl->retry_after, 5, 'retry_after from Retry-After' );
    is( $rl->raw->{'retry-after'}, '5', 'raw keeps the header verbatim' );
    is( $rl->requests_remaining, undef, 'no bucket invented' );

    eval { $engine->chat_response( http_error( 503, 'Service Unavailable', 'retry-after-ms' => '1500' ) ) };
    is( $engine->rate_limit && $engine->rate_limit->retry_after, 1.5, 'a 503 with only retry-after-ms: 1.5s' );

    eval { $engine->chat_response( http_error( 500, 'Internal Server Error' ) ) };
    ok( !$engine->has_rate_limit, 'a response without either header records none' );
  };
}

# ======================================================================
# 2. retry-after-ms wins over Retry-After
# ======================================================================

subtest 'RateLimit->retry_after prefers retry-after-ms' => sub {
  is( Langertha::RateLimit->new( raw => { 'retry-after-ms' => '1500', 'retry-after' => '2' } )->retry_after,
    1.5, 'both sent: the ms value / 1000' );
  is( Langertha::RateLimit->new( raw => { 'retry-after-ms' => '250' } )->retry_after,
    0.25, 'ms alone' );
  is( Langertha::RateLimit->new( raw => { 'retry-after-ms' => 'soon', 'retry-after' => '2' } )->retry_after,
    2, 'an unreadable ms value falls back to Retry-After' );
  is( Langertha::RateLimit->new( raw => { 'retry-after' => '2' } )->retry_after, 2, 'Retry-After alone as before' );
};

subtest 'dialect parsers collect retry-after-ms and use it' => sub {
  my $groq = Langertha::Engine::Groq->new( api_key => 'k', model => 'm' );
  eval { $groq->chat_response( http_error( 429, 'Too Many Requests',
    'x-ratelimit-remaining-requests' => '0', 'retry-after' => '2', 'retry-after-ms' => '1500' ) ) };
  like( $@, qr/request failed: 429 Too Many Requests \(retry after 1\.5s\) - /,
    'the message uses the same value as retry_after' );
  is( $groq->rate_limit->retry_after, 1.5, 'retry_after is the ms value' );
  is_deeply( [ @{ $groq->rate_limit->raw }{qw( retry-after retry-after-ms )} ], [ '2', '1500' ],
    'raw keeps both headers' );

  my $only_ms = Langertha::Engine::Groq->new( api_key => 'k', model => 'm' );
  eval { $only_ms->chat_response( http_error( 429, 'Too Many Requests', 'retry-after-ms' => '250' ) ) };
  like( $@, qr/\(retry after 0\.25s\)/, 'sub-second wait is not rounded away' );
  is( $only_ms->rate_limit && $only_ms->rate_limit->retry_after, 0.25, 'a response with only retry-after-ms has a rate limit' );

  my $claude = Langertha::Engine::Anthropic->new( api_key => 'k', model => 'm' );
  eval { $claude->chat_response( http_error( 429, 'Too Many Requests', 'retry-after-ms' => '3000' ) ) };
  is( $claude->rate_limit && $claude->rate_limit->retry_after, 3, 'Anthropic dialect too' );
};

# ======================================================================
# 3. Error text parity: async (mocked) against the sync croak
# ======================================================================

sub limited { http_error( 429, 'Too Many Requests', 'retry-after' => '2', 'retry-after-ms' => '1500' ) }

sub sync_message {
  my ($engine) = @_;
  eval { $engine->chat_response( limited() ) };
  return message_of($@);
}

subtest 'mocked async chat_f / simple_chat_f / Langertha::Chat: same text as the sync croak' => sub {
  my $expected = sync_message( Langertha::Engine::Groq->new( api_key => 'k', model => 'm' ) );
  is( $expected, "Langertha::Engine::Groq request failed: 429 Too Many Requests (retry after 1.5s) - $ERROR_BODY",
    'the sync croak text' );
  my %call = (
    chat_f        => sub { $_[0]->chat_f( messages => ['hi'] ) },
    simple_chat_f => sub { $_[0]->simple_chat_f('hi') },
    'Langertha::Chat simple_chat_f' => sub { Langertha::Chat->new( engine => $_[0] )->simple_chat_f('hi') },
  );
  for my $label ( sort keys %call ) {
    my $groq = Langertha::Engine::Groq->new( api_key => 'k', model => 'm',
      _async_http => Test::MockAsyncHTTP->new( responses => [ limited() ] ) );
    my $ok = eval { $call{$label}->($groq)->get; 1 };
    ok( !$ok, "$label fails" );
    is( message_of($@), $expected, "$label: identical error text" );
  }

  my $gemini = Langertha::Engine::Gemini->new( api_key => 'k', model => 'm',
    _async_http => Test::MockAsyncHTTP->new( responses => [ limited() ] ) );
  eval { $gemini->chat_f( messages => ['hi'] )->get };
  is( message_of($@), sync_message( Langertha::Engine::Gemini->new( api_key => 'k', model => 'm' ) ),
    'a native engine: identical too' );
};

# ======================================================================
# 3. Error text parity at the real transport: LWP, SyncHTTP, Net::Async::HTTP
# ======================================================================

SKIP: {
  skip 'fork-based HTTP::Daemon test not supported on Windows', 1 if $^O eq 'MSWin32';
  require Test::LocalHTTPDaemon;

  my $server = Test::LocalHTTPDaemon->start(sub { limited() });
  my $url = $server->url . '/v1';

  my $have_async = eval { require Net::Async::HTTP; require IO::Async::Loop; 1 };
  diag('Net::Async::HTTP not installed: async backend skipped') unless $have_async;

  my $engine = sub {
    my ($backend) = @_;
    return Langertha::Engine::Groq->new( api_key => 'k', model => 'm', url => $url,
      ( $backend eq 'synchttp'
        ? ( _async_http => Langertha::Request::SyncHTTP->new( user_agent => LWP::UserAgent->new( timeout => 10 ) ) )
        : () ) );
  };

  subtest 'real transport: every backend fails with the sync croak text' => sub {
    eval { $engine->('lwp')->simple_chat('hi') };
    my $chat_expected = message_of($@);
    is( $chat_expected, "Langertha::Engine::Groq request failed: 429 Too Many Requests (retry after 1.5s) - $ERROR_BODY",
      'sync simple_chat croak text' );
    eval { $engine->('lwp')->simple_chat_stream( sub { }, 'hi' ) };
    my $stream_expected = message_of($@);
    is( $stream_expected,
      "Langertha::Engine::Groq streaming request failed: 429 Too Many Requests (retry after 1.5s) - $ERROR_BODY",
      'sync simple_chat_stream croak text' );

    for my $backend ( 'synchttp', ( $have_async ? 'async' : () ) ) {
      eval { $engine->($backend)->chat_f( messages => ['hi'] )->get };
      is( message_of($@), $chat_expected, "chat_f ($backend): identical error text" );
      eval { $engine->($backend)->simple_chat_f('hi')->get };
      is( message_of($@), $chat_expected, "simple_chat_f ($backend): identical error text" );
      my $streamer = $engine->($backend);
      eval { $streamer->chat_stream_realtime_f( messages => ['hi'] )->get };
      is( message_of($@), $stream_expected, "chat_stream_realtime_f ($backend): identical error text" );
      is( $streamer->rate_limit && $streamer->rate_limit->retry_after, 1.5,
        "chat_stream_realtime_f ($backend): rate limit recorded" );
    }
  };
}

done_testing;
