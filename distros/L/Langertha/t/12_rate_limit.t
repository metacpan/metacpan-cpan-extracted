#!/usr/bin/env perl
# ABSTRACT: Test rate limit extraction from HTTP response headers

use strict;
use warnings;

use Test2::Bundle::More;
use JSON::MaybeXS;
use HTTP::Response;
use Path::Tiny qw( path );

use Langertha::RateLimit;
use Langertha::Response;
use Langertha::Engine::OpenAI;
use Langertha::Engine::Anthropic;
use Langertha::Engine::vLLM;
use Langertha::Engine::Ollama;

my $json = JSON::MaybeXS->new->canonical(1)->utf8(1);

# karr k137. The two header-parsing parts below (2 and 3) are fed VERBATIM
# response headers from the providers that actually emit rate-limit headers:
# one live 200 per wire family, captured 2026-09-17 through these same engines
# (OpenAI gpt-4o-mini, Anthropic claude-haiku-4-5). They replace the
# hand-written header sets those parts used to build, which is k101's point: a
# payload written to fit the parser only ever proves the parser agrees with
# itself. k101 captured AKI.IO, but AKI sends no rate-limit headers at all
# (asserted in t/28_aki_fixtures.t), so it could not close this gap.
#
# The captures are verbatim except: LWP's locally-invented client-* pseudo
# headers and OpenAI's __cf_bm set-cookie are dropped (they never came off the
# wire / are a live session token), and four account identifiers keep their
# header NAME but get a placeholder value (anthropic-organization-id,
# anthropic-workspace-id, openai-organization, openai-project). Nothing
# matching the rate-limit prefixes is touched.
#
# Parts 5, 6 and 13 are driven by the captures too. What stays synthesized is
# only what a capture cannot show: a bucket counting down across two responses,
# a header name outside the ones this account's traffic carries, a reset header
# a healthy provider never omits, and a proxy in front of a self-hosted server
# (Part 7). Each says so where it stands. Parts 1 and 9-12 build
# Langertha::RateLimit objects directly and never touch HTTP headers at all.

my $data_dir = path(__FILE__)->parent->child('data');

# Builds the HTTP::Response the engine sees from a captured pair: body bytes
# verbatim via slurp_raw (no decode + re-encode), headers from the sibling
# <name>.headers.json. Convention follows t/28_aki_fixtures.t.
sub fixture_http {
  my ( $name ) = @_;
  my $headers = $json->decode( $data_dir->child("$name.headers.json")->slurp_raw );
  my $http    = HTTP::Response->new(200, 'OK');
  $http->header( $_ => $headers->{$_} ) for sort keys %$headers;
  $http->content( $data_dir->child("$name.json")->slurp_raw );
  return $http;
}

# ======================================================================
# Part 1: RateLimit data class
# ======================================================================

{
  my $rl = Langertha::RateLimit->new(
    requests_limit     => 100,
    requests_remaining => 95,
    requests_reset     => '5s',
    tokens_limit       => 40000,
    tokens_remaining   => 39500,
    tokens_reset       => '10s',
    raw                => { 'x-ratelimit-limit-requests' => '100' },
  );
  is($rl->requests_limit, 100, 'RateLimit requests_limit');
  is($rl->requests_remaining, 95, 'RateLimit requests_remaining');
  is($rl->requests_reset, '5s', 'RateLimit requests_reset');
  is($rl->tokens_limit, 40000, 'RateLimit tokens_limit');
  is($rl->tokens_remaining, 39500, 'RateLimit tokens_remaining');
  is($rl->tokens_reset, '10s', 'RateLimit tokens_reset');
  is(ref $rl->raw, 'HASH', 'RateLimit raw is HashRef');

  my $hash = $rl->to_hash;
  is($hash->{requests_limit}, 100, 'to_hash requests_limit');
  is($hash->{tokens_remaining}, 39500, 'to_hash tokens_remaining');
  ok(exists $hash->{raw}, 'to_hash includes raw');
}

# RateLimit with no values
{
  my $rl = Langertha::RateLimit->new;
  is($rl->requests_limit, undef, 'empty RateLimit requests_limit is undef');
  is($rl->tokens_remaining, undef, 'empty RateLimit tokens_remaining is undef');
  my $hash = $rl->to_hash;
  ok(!exists $hash->{requests_limit}, 'to_hash omits undef fields');
  ok(exists $hash->{raw}, 'to_hash always includes raw');
}

# ======================================================================
# Part 2: OpenAI-style x-ratelimit-* header parsing — real capture
# ======================================================================
# Verbatim headers from a live OpenAI 200 (see the provenance note above).
# What the hand-written version could not have produced: the reset headers are
# `12ms` and `0s`, not the tidy `12s`/`6s` a test author invents. Both matter —
# `12ms` is a sub-second Go duration, and `0s` is a defined ZERO that must
# survive as 0 rather than collapsing into undef the way a false value does
# under a truthiness test.

{
  my $openai = Langertha::Engine::OpenAI->new(
    api_key => 'testkey',
    model   => 'gpt-4o-mini',
  );

  my $resp = $openai->chat_response( fixture_http('openai_chat_response') );
  isa_ok($resp, 'Langertha::Response');
  # The capture is a real chat completion, not a stub built around the headers.
  is("$resp", 'OK!', 'content from the captured message');
  is($resp->model, 'gpt-4o-mini-2024-07-18', 'model from the wire (the dated snapshot id)');

  # Engine should have rate limit stored
  ok($openai->has_rate_limit, 'OpenAI engine has_rate_limit after response');
  my $rl = $openai->rate_limit;
  isa_ok($rl, 'Langertha::RateLimit');
  is($rl->requests_limit, 5000, 'OpenAI requests_limit parsed');
  is($rl->requests_remaining, 4999, 'OpenAI requests_remaining parsed');
  is($rl->requests_reset, '12ms', 'OpenAI requests_reset kept verbatim (non-breaking)');
  is($rl->tokens_limit, 4000000, 'OpenAI tokens_limit parsed');
  is($rl->tokens_remaining, 3999996, 'OpenAI tokens_remaining parsed');
  is($rl->tokens_reset, '0s', 'OpenAI tokens_reset kept verbatim (non-breaking)');
  is($rl->raw->{'x-ratelimit-limit-requests'}, '5000', 'OpenAI raw headers preserved');
  is(scalar keys %{ $rl->raw }, 6,
    'raw carries exactly the six x-ratelimit-* headers this response shipped');

  # Go-duration reset -> *_reset_after (seconds), *_reset_at derived lazily.
  is($rl->requests_reset_after, 0.012, 'OpenAI requests_reset_after parsed from a sub-second Go duration');
  is($rl->tokens_reset_after, 0, 'OpenAI tokens_reset_after is a real 0, not undef');
  ok(defined $rl->tokens_reset_after, 'a zero duration stays defined (0 is a value, not a missing header)');
  isa_ok($rl->requests_reset_at, 'Langertha::Moment');
  is($rl->tokens_reset_at->epoch, $rl->received->epoch,
    'OpenAI tokens_reset_at = received for a 0s reset');
  cmp_ok($rl->requests_reset_at->epoch, '>=', $rl->received->epoch,
    'OpenAI requests_reset_at derived from received + duration');
}

# A header OUTSIDE the six names the OpenAI reader picks out: the "project
# tokens" bucket. The capture above does not carry one (this account's
# responses ship exactly six), so the prefix-match superset keeps its
# hand-written case — it asserts what the reader does with a name it does not
# know, which no single real response can demonstrate.
{
  my $openai = Langertha::Engine::OpenAI->new(
    api_key => 'testkey',
    model   => 'gpt-4o-mini',
  );

  my $http = fixture_http('openai_chat_response');
  $http->header('x-ratelimit-limit-project-tokens' => '60000');

  $openai->chat_response($http);
  is($openai->rate_limit->raw->{'x-ratelimit-limit-project-tokens'}, '60000',
    'OpenAI raw superset: x-ratelimit-limit-project-tokens survives (old reader dropped it)');
}

# ======================================================================
# Part 3: Anthropic anthropic-ratelimit-* header parsing — real capture
# ======================================================================
# Verbatim headers from a live Anthropic 200 (see the provenance note above).
# The wire ships TWELVE anthropic-ratelimit-* headers, four of them buckets the
# reader deliberately does not lift onto named attributes (input-tokens /
# output-tokens) — they exist only in `raw`, and this is the evidence that they
# are really sent rather than an assumption the old hand-written set encoded.
# All four reset stamps are the same RFC 3339 instant.

{
  my $anthropic = Langertha::Engine::Anthropic->new(
    api_key => 'testkey',
    model   => 'claude-haiku-4-5-20251001',
  );

  my $resp = $anthropic->chat_response( fixture_http('anthropic_chat_response') );
  isa_ok($resp, 'Langertha::Response');
  # The capture is a real message response, not a stub built around the headers.
  is("$resp", 'OK', 'content from the captured text block');
  is($resp->model, 'claude-haiku-4-5-20251001', 'model from the wire');
  is($resp->finish_reason, 'end_turn', 'finish_reason from stop_reason');

  ok($anthropic->has_rate_limit, 'Anthropic engine has_rate_limit');
  my $rl = $anthropic->rate_limit;
  isa_ok($rl, 'Langertha::RateLimit');
  is($rl->requests_limit, 10000, 'Anthropic requests_limit parsed');
  is($rl->requests_remaining, 9999, 'Anthropic requests_remaining parsed');
  is($rl->requests_reset, '2026-09-17T18:21:21Z', 'Anthropic requests_reset kept verbatim (non-breaking)');
  is($rl->tokens_limit, 12000000, 'Anthropic tokens_limit parsed');
  is($rl->tokens_remaining, 12000000, 'Anthropic tokens_remaining parsed');
  # The extras the wire really sends, kept in raw rather than on attributes.
  is(scalar keys %{ $rl->raw }, 12,
    'raw carries all twelve anthropic-ratelimit-* headers this response shipped');
  is($rl->raw->{'anthropic-ratelimit-input-tokens-limit'}, '10000000', 'Anthropic raw includes input-tokens-limit');
  is($rl->raw->{'anthropic-ratelimit-output-tokens-limit'}, '2000000', 'Anthropic raw includes output-tokens-limit');
  is($rl->raw->{'anthropic-ratelimit-input-tokens-reset'}, '2026-09-17T18:21:21Z',
    'Anthropic raw includes the per-bucket input-tokens reset instant');

  # RFC 3339 reset -> *_reset_at (instant), *_reset_after derived lazily.
  isa_ok($rl->requests_reset_at, 'Langertha::Moment');
  my $req_at = $rl->requests_reset_at;
  is("$req_at", '2026-09-17T18:21:21Z', 'Anthropic requests_reset_at round-trips the RFC 3339 instant');
  ok(defined $rl->requests_reset_after, 'Anthropic requests_reset_after derived from instant - received');
  # `received` is the replay moment, so the derived duration is large and
  # negative against a captured stamp. Only the RELATION is meaningful here.
  my $expected_after = $rl->requests_reset_at->epoch - $rl->received->epoch;
  ok(abs($rl->requests_reset_after - $expected_after) < 1,
    'Anthropic requests_reset_after ~= reset_at - received (sub-second of received aside)');
  isa_ok($rl->tokens_reset_at, 'Langertha::Moment');
  ok(defined $rl->tokens_reset_after, 'Anthropic tokens_reset_after derived');
}

# A header outside the twelve the capture carries: the Priority-Tier bucket,
# which this account's traffic does not get. Hand-written for the same reason as
# the OpenAI project-tokens case above — it asserts the prefix-match superset,
# not what one provider happened to send.
{
  my $anthropic = Langertha::Engine::Anthropic->new(
    api_key => 'testkey',
    model   => 'claude-haiku-4-5-20251001',
  );

  my $http = fixture_http('anthropic_chat_response');
  $http->header('anthropic-priority-input-tokens-limit' => '12345');

  $anthropic->chat_response($http);
  is($anthropic->rate_limit->raw->{'anthropic-priority-input-tokens-limit'}, '12345',
    'Anthropic raw superset: anthropic-priority-* survives (old reader dropped it)');
}

# ======================================================================
# Part 4: No headers => no rate_limit (local engines)
# ======================================================================

{
  my $ollama = Langertha::Engine::Ollama->new(
    url   => 'http://test.invalid:11434',
    model => 'llama3.3',
  );

  my $http = HTTP::Response->new(200, 'OK');
  $http->content($json->encode({
    model   => 'llama3.3:latest',
    message => { role => 'assistant', content => 'Hello' },
    done    => JSON->true,
    done_reason => 'stop',
  }));
  $http->header('Content-Type' => 'application/json');

  $ollama->chat_response($http);
  ok(!$ollama->has_rate_limit, 'Ollama has no rate_limit (no headers)');
}

# ======================================================================
# Part 5: Rate limit attached to Response via simple_chat flow
# ======================================================================

{
  my $openai = Langertha::Engine::OpenAI->new(
    api_key => 'testkey',
    model   => 'gpt-4o-mini',
  );

  # Simulate what simple_chat does: parse_response + clone_with, driven by the
  # captured response so the delegated numbers are the ones OpenAI really sent.
  my $resp = $openai->chat_response( fixture_http('openai_chat_response') );
  ok($openai->has_rate_limit, 'engine has rate_limit before clone');

  my $cloned = $resp->clone_with(rate_limit => $openai->rate_limit);
  ok($cloned->has_rate_limit, 'cloned Response has rate_limit');
  is($cloned->requests_remaining, 4999, 'Response requests_remaining via delegation');
  is($cloned->tokens_remaining, 3999996, 'Response tokens_remaining via delegation');
  is("$cloned", 'OK!', 'cloned Response still stringifies correctly');
  is($cloned->id, 'chatcmpl-EPAzxeR3IRAp0uRmCxwdHEgcEX42s', 'cloned Response preserves id');
}

# ======================================================================
# Part 6: Engine stores latest rate_limit (updates on each response)
# ======================================================================

{
  my $openai = Langertha::Engine::OpenAI->new(
    api_key => 'testkey',
    model   => 'gpt-4o-mini',
  );

  ok(!$openai->has_rate_limit, 'fresh engine has no rate_limit');

  # Two responses from the same captured exchange: the second is the capture
  # with the one header a second request would actually move. Counting down is
  # the only part of this that has to be synthesized — a single capture cannot
  # show a sequence.
  $openai->chat_response( fixture_http('openai_chat_response') );
  is($openai->rate_limit->requests_remaining, 4999, 'first response: 4999 remaining');

  my $http2 = fixture_http('openai_chat_response');
  $http2->header('x-ratelimit-remaining-requests' => '4998');
  $openai->chat_response($http2);
  is($openai->rate_limit->requests_remaining, 4998, 'second response: 4998 remaining (updated)');
}

# ======================================================================
# Part 7: vLLM with custom rate limit headers
# ======================================================================

{
  my $vllm = Langertha::Engine::vLLM->new(
    url => 'http://test.invalid:8000/v1',
  );

  my $http = HTTP::Response->new(200, 'OK');
  $http->content($json->encode({
    id      => 'vllm-test',
    model   => 'default',
    choices => [{ message => { content => 'Hi' }, finish_reason => 'stop' }],
  }));
  $http->header('Content-Type' => 'application/json');
  # Hand-written on purpose: vLLM serves no rate-limit headers itself, so there
  # is nothing to capture. These are what a gateway in front of it would add.
  $http->header('x-ratelimit-limit-requests' => '60');
  $http->header('x-ratelimit-remaining-requests' => '58');

  $vllm->chat_response($http);
  ok($vllm->has_rate_limit, 'vLLM with proxy rate limit headers');
  is($vllm->rate_limit->requests_limit, 60, 'vLLM requests_limit');
  is($vllm->rate_limit->requests_remaining, 58, 'vLLM requests_remaining');
  is($vllm->rate_limit->tokens_limit, undef, 'vLLM tokens_limit undef (not set)');
}

# No rate limit headers on vLLM
{
  my $vllm = Langertha::Engine::vLLM->new(
    url => 'http://test.invalid:8000/v1',
  );

  my $http = HTTP::Response->new(200, 'OK');
  $http->content($json->encode({
    id      => 'vllm-test2',
    model   => 'default',
    choices => [{ message => { content => 'Hi' }, finish_reason => 'stop' }],
  }));
  $http->header('Content-Type' => 'application/json');

  $vllm->chat_response($http);
  ok(!$vllm->has_rate_limit, 'vLLM without rate limit headers has no rate_limit');
}

# ======================================================================
# Part 8: Response without rate_limit (delegation returns undef)
# ======================================================================

{
  my $resp = Langertha::Response->new(content => 'plain response');
  ok(!$resp->has_rate_limit, 'plain Response has no rate_limit');
  is($resp->requests_remaining, undef, 'requests_remaining undef without rate_limit');
  is($resp->tokens_remaining, undef, 'tokens_remaining undef without rate_limit');
}

# ======================================================================
# Part 9: Typed reset split — duration only, *_reset_at derived
# ======================================================================

{
  # A whole-second `received` makes the derivation exact and clock-independent.
  my $received = Langertha::Moment->from_wire('2026-01-01T00:00:00Z');
  my $rl = Langertha::RateLimit->new(
    received             => $received,
    requests_reset_after => 12,
    tokens_reset_after   => 179.56,
  );

  is($rl->requests_reset_after, 12, 'duration-only: requests_reset_after kept as sent');
  isa_ok($rl->requests_reset_at, 'Langertha::Moment');
  is($rl->requests_reset_at->epoch, $received->epoch + 12,
    'duration-only: requests_reset_at = received + 12s');
  # 179.56s = 2m59.56s -> sub-second preserved in the derived instant.
  is($rl->tokens_reset_at->epoch, $received->epoch + 179,
    'duration-only: tokens_reset_at whole-second part = received + 179s');
  is($rl->tokens_reset_at->nanosecond, 560_000_000,
    'duration-only: fractional second preserved in derived tokens_reset_at');

  # to_hash serializes the typed halves; reset_at as a plain epoch number
  # (matching Response.created), received stays out of the serialized view.
  my $hash = $rl->to_hash;
  is($hash->{requests_reset_after}, 12, 'to_hash: requests_reset_after in seconds');
  is($hash->{requests_reset_at}, $received->epoch + 12, 'to_hash: requests_reset_at as epoch number');
  ok(!exists $hash->{received}, 'to_hash omits the received derivation anchor');
}

# ======================================================================
# Part 10: Typed reset split — instant only, *_reset_after derived
# ======================================================================

{
  my $received = Langertha::Moment->from_wire('2026-01-01T00:00:00Z');
  my $rl = Langertha::RateLimit->new(
    received          => $received,
    requests_reset_at => Langertha::Moment->from_wire('2026-01-01T00:05:00Z'),
  );

  isa_ok($rl->requests_reset_at, 'Langertha::Moment');
  is($rl->requests_reset_after, 300, 'instant-only: requests_reset_after = reset_at - received (300s)');
  is($rl->tokens_reset_at, undef, 'instant-only: untouched token bucket reset_at stays undef');
  is($rl->tokens_reset_after, undef, 'instant-only: untouched token bucket reset_after stays undef');
}

# ======================================================================
# Part 11: No reset header — both halves stay undef, no invented default
# ======================================================================

{
  my $rl = Langertha::RateLimit->new(
    received           => Langertha::Moment->from_wire('2026-01-01T00:00:00Z'),
    requests_remaining => 5,
  );
  is($rl->requests_reset_at, undef, 'no-reset: requests_reset_at undef (no default invented)');
  is($rl->requests_reset_after, undef, 'no-reset: requests_reset_after undef');
  is($rl->tokens_reset_at, undef, 'no-reset: tokens_reset_at undef');
  is($rl->tokens_reset_after, undef, 'no-reset: tokens_reset_after undef');
  is($rl->requests_reset, undef, 'no-reset: verbatim requests_reset undef');

  my $hash = $rl->to_hash;
  ok(!exists $hash->{requests_reset_at}, 'no-reset: to_hash omits undef requests_reset_at');
  ok(!exists $hash->{requests_reset_after}, 'no-reset: to_hash omits undef requests_reset_after');
}

# ======================================================================
# Part 12: Go time.Duration parser edge cases
# ======================================================================

{
  my %ok = (
    '1s'        => 1,
    '3s'        => 3,
    '6m0s'      => 360,     # compound, trailing zero-second unit
    '2m59.56s'  => 179.56,  # compound + fractional seconds
    '7.66s'     => 7.66,    # fractional
    '250ms'     => 0.25,    # sub-second milliseconds
    '35ms'      => 0.035,
    '20ms'      => 0.02,
    '1h2m3s'    => 3723,    # hours+minutes+seconds
  );
  for my $str (sort keys %ok) {
    my $got = Langertha::RateLimit::_parse_go_duration($str);
    ok(defined $got && abs($got - $ok{$str}) < 1e-9,
      "Go-duration '$str' -> $ok{$str}");
  }

  # Not a Go duration -> undef (never guess).
  is(Langertha::RateLimit::_parse_go_duration('60'), undef,
    'Go-duration parser rejects a bare number (no guessing seconds)');
  is(Langertha::RateLimit::_parse_go_duration('2026-02-27T12:00:00Z'), undef,
    'Go-duration parser rejects an RFC 3339 instant');
  is(Langertha::RateLimit::_parse_go_duration('garbage'), undef,
    'Go-duration parser rejects junk');
  is(Langertha::RateLimit::_parse_go_duration(''), undef,
    'Go-duration parser rejects empty string');
  is(Langertha::RateLimit::_parse_go_duration(undef), undef,
    'Go-duration parser rejects undef');
}

# ======================================================================
# Part 13: OpenAI response with limit/remaining but NO reset header
# ======================================================================

{
  my $openai = Langertha::Engine::OpenAI->new(
    api_key => 'testkey',
    model   => 'gpt-4o-mini',
  );

  # The captured response minus its reset headers. OpenAI itself always sends
  # them, so this case cannot be captured — but stripping them from real bytes
  # keeps everything else about the response honest.
  my $http = fixture_http('openai_chat_response');
  $http->remove_header('x-ratelimit-reset-requests');
  $http->remove_header('x-ratelimit-reset-tokens');

  $openai->chat_response($http);
  ok($openai->has_rate_limit, 'OpenAI has rate_limit from limit/remaining alone');
  my $rl = $openai->rate_limit;
  is($rl->requests_reset, undef, 'no reset header: verbatim requests_reset undef');
  is($rl->requests_reset_after, undef, 'no reset header: requests_reset_after undef');
  is($rl->requests_reset_at, undef, 'no reset header: requests_reset_at undef (nothing invented)');
}

done_testing;
