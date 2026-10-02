#!/usr/bin/env perl
# ABSTRACT: Replay verbatim AKI.IO server captures through the real chat_response paths

use strict;
use warnings;

use Test2::Bundle::More;
use JSON::MaybeXS;
use HTTP::Response;
use Path::Tiny qw( path );

use Langertha::Engine::AKI;
use Langertha::Engine::Remote;
use Langertha::Engine::AKIOpenAI;
use Langertha::Engine::AKIAnthropic;

# karr k101. Every other chat_response unit test in this distribution builds
# its payload by hand, and a hand-written payload is written to fit
# Langertha::Response rather than to match the wire — that is how karr #92
# stayed invisible in main for months. The five files replayed here are
# verbatim response bytes from AKI.IO, captured 2026-09-01 by sending the
# requests THROUGH these same engines, so the constructor is fed exactly what
# a real server sends. Convention follows the Ollama block in t/70_response.t:
# slurp_raw into the HTTP body (no decode + re-encode), chat_response inside an
# eval, then ok(defined ...) — NOT ok(...), because a tool-call-only Response
# has empty content and stringifies false.
#
# Three engines share this file on purpose: the same provider answers on three
# wires, and the value of the captures is the comparison between them.

my $data_dir = path(__FILE__)->parent->child('data');
my $json     = JSON::MaybeXS->new->canonical(1)->utf8(1);

# Builds the HTTP::Response chat_response sees: body bytes verbatim from the
# capture, headers from the sibling <name>.headers.json (also captured, so the
# rate-limit path is fed real server headers instead of hand-written ones).
sub fixture_http {
  my ( $name ) = @_;
  my $body    = $data_dir->child("$name.json")->slurp_raw;
  my $headers = $json->decode( $data_dir->child("$name.headers.json")->slurp_raw );
  my $http    = HTTP::Response->new(200, 'OK');
  $http->header( $_ => $headers->{$_} ) for sort keys %$headers;
  $http->content($body);
  return $http;
}

# --- 1. AKIOpenAI plain chat -> Role::OpenAICompatible::chat_response ---
# The path ~25 engines share, and until this capture it had no real fixture at
# all. Carries created, prompt_tokens_details.cached_tokens, service_tier,
# refusal and annotations — none of which a hand-written payload bothers with.

subtest 'AKIOpenAI plain chat (Role::OpenAICompatible)' => sub {
  my $engine = Langertha::Engine::AKIOpenAI->new(
    api_key => 'testkey',
    model   => 'llama3-chat-8b',
  );
  my $resp = eval { $engine->chat_response( fixture_http('akiopenai_chat_response') ) };
  ok(defined $resp, 'Response constructed, no type-constraint croak') or diag($@);

  SKIP: {
    skip 'no Response to inspect', 10 unless defined $resp;
    isa_ok($resp, 'Langertha::Response');
    is("$resp", 'OK. How can I assist you today?', 'content from the captured message');
    is($resp->id, 'chatcmpl-186922be-29c5-479e-be59-ffe91d0b0db3-6c3c', 'id from the wire');
    is($resp->model, 'llama3-chat-8b', 'model from the wire');
    is($resp->finish_reason, 'stop', 'finish_reason from choices[0]');
    # ADR 0017: created is a Langertha::Moment; the OpenAI wire ships epoch Int.
    is(0 + $resp->created, 1788290649, 'created numifies to Unix seconds');
    is($resp->prompt_tokens, 65, 'prompt_tokens from usage');
    is($resp->completion_tokens, 10, 'completion_tokens from usage');
    # karr k125's engine-agnostic accessor, fed here from the OpenAI shape's
    # usage.prompt_tokens_details.cached_tokens.
    is($resp->cached_tokens, 64, 'cached_tokens from prompt_tokens_details');
    ok(!$resp->has_tool_calls, 'plain chat carries no tool_calls');
  }
};

# --- 2. AKIAnthropic plain chat -> Role::AnthropicCompatible::chat_response ---
# Same provider, same model, same prompt as fixture 1 — so the two files are a
# controlled comparison of the two envelopes. Note what the Anthropic wire does
# NOT carry: no `created`, and its cache count is named differently.

subtest 'AKIAnthropic plain chat (Role::AnthropicCompatible)' => sub {
  my $engine = Langertha::Engine::AKIAnthropic->new(
    api_key => 'testkey',
    model   => 'llama3-chat-8b',
  );
  my $resp = eval { $engine->chat_response( fixture_http('akianthropic_chat_response') ) };
  ok(defined $resp, 'Response constructed, no type-constraint croak') or diag($@);

  SKIP: {
    skip 'no Response to inspect', 9 unless defined $resp;
    isa_ok($resp, 'Langertha::Response');
    is("$resp", 'OK. How can I assist you today?', 'content joined from the text blocks');
    is($resp->id, 'eb25c19a-f6a7-47a1-942e-81f621217adf-97a4', 'id from the wire');
    is($resp->model, 'llama3-chat-8b', 'model from the wire');
    is($resp->finish_reason, 'end_turn', 'finish_reason from stop_reason');
    ok(!$resp->has_created, 'Anthropic envelope reports no timestamp (unlike the OpenAI shim)');
    is($resp->prompt_tokens, 65, 'prompt_tokens from usage.input_tokens');
    is($resp->completion_tokens, 10, 'completion_tokens from usage.output_tokens');
    # karr k125: cache_read_input_tokens lifts onto the same accessor the
    # OpenAI shape fills — and both shims report 64 for this prompt.
    is($resp->cached_tokens, 64, 'cache_read_input_tokens lifts onto cached_tokens (karr k125)');
  }
};

# --- 3. Engine::AKI native chat_response ---
# The native wire names everything differently: job_id, prompt_length,
# num_generated_tokens, num_cached_tokens, and durations already in SECONDS.

subtest 'Engine::AKI native chat (karr k126)' => sub {
  my $engine = Langertha::Engine::AKI->new( api_key => 'testkey' );
  my $resp = eval { $engine->chat_response( fixture_http('aki_chat_response') ) };
  ok(defined $resp, 'Response constructed, no type-constraint croak') or diag($@);

  SKIP: {
    skip 'no Response to inspect', 9 unless defined $resp;
    isa_ok($resp, 'Langertha::Response');
    is("$resp", 'OK.', 'content from the native text field');
    is($resp->id, '0f6aaeff-f431-45d6-99c8-5f3b67c4f344-d9fa', 'job_id maps to Response.id');
    is($resp->model, 'Llama-3.1-8B-Instruct', 'model_name maps to Response.model');
    # The native counts disagree with the OpenAI shim for the same prompt
    # (38/3/16 here vs 65/10/64 in fixture 1) — same provider, same words.
    is($resp->prompt_tokens, 38, 'prompt_length maps to prompt_tokens');
    is($resp->completion_tokens, 3, 'num_generated_tokens maps to completion_tokens');
    is($resp->cached_tokens, 16, 'num_cached_tokens maps to cached_tokens');
    # karr k126: AKI durations are seconds, Ollama's total_duration is
    # nanoseconds. Emitting total_seconds/compute_seconds and dropping the raw
    # key is what keeps the two engines from colliding by a factor of 1e9.
    is($resp->total_seconds, 0.428, 'total_duration surfaces as total_seconds');
    is($resp->timing->{compute_seconds}, 0.419, 'compute_duration surfaces as compute_seconds');
    ok(!exists $resp->timing->{total_duration},
      'raw total_duration key is not emitted (Ollama-ns collision, karr k126)');
  }
};

# --- 4. AKIOpenAI native tool call ---
# This capture is the karr k102 probe itself: llama3-chat-8b, one model AKI's
# own table rates only "Basic Support", answering a native OpenAI tools array
# with a native tool_calls block. It is the evidence
# behind dropping Role::HermesTools from this engine.

subtest 'AKIOpenAI native tool call (karr k102 probe capture)' => sub {
  my $engine = Langertha::Engine::AKIOpenAI->new(
    api_key => 'testkey',
    model   => 'llama3-chat-8b',
  );
  my $resp = eval { $engine->chat_response( fixture_http('akiopenai_tool_call_response') ) };
  ok(defined $resp, 'Response constructed, no type-constraint croak') or diag($@);

  SKIP: {
    skip 'no Response to inspect', 13 unless defined $resp;
    isa_ok($resp, 'Langertha::Response');
    is("$resp", '', 'tool-call-only reply stringifies to empty content');
    is($resp->id, 'chatcmpl-22abd180-d3e6-40fb-a278-87a44e93d306-8744', 'id from the wire');
    is($resp->model, 'llama3-chat-8b', 'model from the wire');
    # The wire says 'stop' next to a tool call; the dialect reports
    # 'tool_calls' and keeps the wire value on raw (karr k248).
    is($resp->finish_reason, 'tool_calls', 'finish_reason normalized to tool_calls');
    is($resp->raw->{choices}[0]{finish_reason}, 'stop', 'wire finish_reason kept on raw');
    is(0 + $resp->created, 1788290624, 'created numifies to Unix seconds');
    is($resp->prompt_tokens, 227, 'prompt_tokens from usage');
    is($resp->completion_tokens, 23, 'completion_tokens from usage');
    is($resp->cached_tokens, 128, 'cached_tokens from prompt_tokens_details');

    is(scalar @{ $resp->tool_calls }, 1, 'one tool call on Response.tool_calls (ADR 0003)');
    my $tc = $resp->tool_call('add');
    is($tc->id, 'call_9c176c2b6041471da6177c00', 'tool call id from the wire');
    is_deeply($tc->arguments, { a => 7, b => 15 },
      'arguments survive the OpenAI JSON-string encoding (karr k124)');
  }

  # llama3-chat-8b emits no chain-of-thought, so this capture carries no
  # `reasoning` key and the karr k127 lift is a no-op here. The lift itself is
  # covered by t/27_akiopenai_requests.t; asserted so a future capture that
  # DOES reason cannot silently change the meaning of this file.
  SKIP: {
    skip 'no Response to inspect', 2 unless defined $resp;
    ok(!exists $resp->raw->{choices}[0]{message}{reasoning},
      'this capture carries no reasoning key');
    ok(!$resp->has_thinking, 'and no thinking is invented for it');
  }
};

# --- 5. AKIAnthropic native tool call — the karr k124 gate ---
# AKI's /anthropic shim ships tool_use `input` as a JSON *string*, where real
# Anthropic ships an object. from_anthropic used to fall back to {} for that,
# silently losing every argument while keeping id and name intact. These are
# the bytes that proved it.

subtest 'AKIAnthropic native tool call (karr k124 gate)' => sub {
  my $engine = Langertha::Engine::AKIAnthropic->new(
    api_key => 'testkey',
    model   => 'llama3-chat-8b',
  );
  my $http = fixture_http('akianthropic_tool_call_response');
  my $resp = eval { $engine->chat_response($http) };
  ok(defined $resp, 'Response constructed, no type-constraint croak') or diag($@);

  # The premise of this fixture: input really is an unparsed string on the wire.
  my $raw_block = $json->decode( $http->content )->{content}[0];
  is($raw_block->{type}, 'tool_use', 'captured block is a tool_use block');
  ok(!ref $raw_block->{input}, 'captured tool_use input is a JSON string, not an object');

  SKIP: {
    skip 'no Response to inspect', 9 unless defined $resp;
    isa_ok($resp, 'Langertha::Response');
    is("$resp", '', 'tool-call-only reply stringifies to empty content');
    is($resp->id, '3be23acc-aa93-42da-b324-b7e64d98aa91-aa33', 'id from the wire');
    is($resp->model, 'llama3-chat-8b', 'model from the wire');
    is($resp->finish_reason, 'tool_use', 'finish_reason from stop_reason');
    is($resp->cached_tokens, 128, 'cache_read_input_tokens lifts onto cached_tokens');

    is(scalar @{ $resp->tool_calls }, 1, 'one tool call on Response.tool_calls (ADR 0003)');
    my $tc = $resp->tool_call('add');
    is($tc->id, 'call_3b2b39e1c113404aa75ff88f', 'tool call id from the wire');
    is_deeply($tc->arguments, { a => 7, b => 15 },
      'JSON-string input is decoded, not swallowed as {} (karr k124)');
  }

  # llama3-chat-8b emits no thinking block here either; the Anthropic envelope
  # would carry one as a content block if it did.
  SKIP: {
    skip 'no Response to inspect', 1 unless defined $resp;
    ok(!$resp->has_thinking, 'no thinking block in this capture');
  }
};

# --- 6. AKIOpenAI image input on qwen3.6 — the karr k271 probe ---
# The evidence behind AKIOpenAI's image_input claim for the qwen3.6 family:
# an 8x8 solid-red base64 PNG went out as an image_url part and the model
# named the color. Captured 2026-09-25 through the engine's own request
# builder; LWP's local client-* headers stripped, nothing else touched. If the
# claim is ever widened or dropped, this is the capture it rests on.

subtest 'AKIOpenAI qwen3.6 image answer (karr k271 probe capture)' => sub {
  my $engine = Langertha::Engine::AKIOpenAI->new(
    api_key => 'testkey',
    model   => 'qwen3.6-chat-35b',
  );
  ok($engine->supports('image_input'), 'qwen3.6-chat-35b claims image_input');
  my $resp = eval { $engine->chat_response( fixture_http('akiopenai_qwen36_image_response') ) };
  ok(defined $resp, 'Response constructed, no type-constraint croak') or diag($@);

  SKIP: {
    skip 'no Response to inspect', 6 unless defined $resp;
    is("$resp", 'Red', 'the model named the color of the image');
    is($resp->model, 'qwen3.6-chat-35b', 'the probed model answered, no substitution');
    is($resp->finish_reason, 'stop', 'finished normally');
    like($resp->thinking, qr/solid, uniform block of color/,
      'its reasoning describes the image, so the answer is not a guess from the text');
    is($resp->prompt_tokens, 116, 'prompt_tokens from usage');
    ok(!$engine->has_rate_limit, 'no rate-limit headers on this capture either');
  }
};

# --- 7. AKIOpenAI image input on gemma4 / qwen3.8 — the karr k272 probe ---
# The follow-up probe that widened the claim: the same 8x8 solid-red PNG and
# the same prompt, max_tokens 2048, one call per model. Both named the color
# and reasoned about the image, so their families are claimed. Captured
# 2026-09-25 the same way as the k271 capture (client-* headers stripped).

my @K272_CAPTURES = (
  [ akiopenai_gemma4_image_response => 'gemma4-chat-26b',
    qr/solid square of color.*bright red/s, 309 ],
  [ akiopenai_qwen38_image_response => 'qwen3.8-27b',
    qr/uniform field of red/, 154 ],
);

for my $capture (@K272_CAPTURES) {
  my ( $fixture, $model, $reasoning_re, $prompt_tokens ) = @$capture;
  subtest "AKIOpenAI $model image answer (karr k272 probe capture)" => sub {
    my $engine = Langertha::Engine::AKIOpenAI->new(
      api_key => 'testkey',
      model   => $model,
    );
    ok($engine->supports('image_input'), "$model claims image_input");
    my $resp = eval { $engine->chat_response( fixture_http($fixture) ) };
    ok(defined $resp, 'Response constructed, no type-constraint croak') or diag($@);

    SKIP: {
      skip 'no Response to inspect', 6 unless defined $resp;
      is("$resp", 'Red', 'the model named the color of the image');
      is($resp->model, $model, 'the probed model answered, no substitution');
      is($resp->finish_reason, 'stop', 'finished normally');
      like($resp->thinking, $reasoning_re,
        'its reasoning describes the image, so the answer is not a guess from the text');
      is($resp->prompt_tokens, $prompt_tokens, 'prompt_tokens from usage');
      ok(!$engine->has_rate_limit, 'no rate-limit headers on this capture either');
    }
  };
}

# --- Captured response headers ---
# t/12_rate_limit.t hand-writes every rate-limit header it tests. These headers
# were captured alongside the bodies and run through the engines' real
# _parse_rate_limit_headers, and they record a fact about AKI.IO: it ships no
# x-ratelimit-* / anthropic-ratelimit-* headers on either shim, so
# has_rate_limit stays false after a real 200. A future AKI capture that DOES
# carry them fails here rather than passing unnoticed.
#
# Engine::AKI native is left out on purpose: Remote's default
# _parse_rate_limit_headers reads only Retry-After / retry-after-ms (k312), so
# the same assertion would hold with or without x-ratelimit-* headers and
# prove nothing.

subtest 'AKI.IO sends no rate-limit headers on either shim' => sub {
  my %engine = (
    akiopenai_chat_response    => Langertha::Engine::AKIOpenAI->new(
      api_key => 'testkey', model => 'llama3-chat-8b' ),
    akianthropic_chat_response => Langertha::Engine::AKIAnthropic->new(
      api_key => 'testkey', model => 'llama3-chat-8b' ),
  );
  for my $name ( sort keys %engine ) {
    my $engine = $engine{$name};
    isnt($engine->can('_parse_rate_limit_headers'),
      Langertha::Engine::Remote->can('_parse_rate_limit_headers'),
      "$name: engine overrides the no-op header parser");
    $engine->chat_response( fixture_http($name) );
    ok(!$engine->has_rate_limit, "$name: no rate_limit parsed from the captured headers");
  }
};

done_testing;
