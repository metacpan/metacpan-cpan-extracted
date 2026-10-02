#!/usr/bin/env perl
# ABSTRACT: Byte-identity proof for Engine::Remote::generation_kwargs_for (karr #98)

use strict;
use warnings;

use Test2::Bundle::More;
use JSON::MaybeXS;

use Langertha::Engine::OpenAI;
use Langertha::Engine::Anthropic;

# karr #98 / ADR 0015 Decision 3: the wire-agnostic generation-parameter
# emission (reasoning_kwargs_for, prompt_cache_kwargs_for) is moved into
# Langertha::Engine::Remote::generation_kwargs_for, and both dialect
# envelopes (Role::OpenAICompatible, Role::AnthropicCompatible) call it
# instead of repeating the can-guarded sibling calls. The refactor must be
# observably a no-op on the wire: the JSON request body before and after
# must be byte-identical, on every combination of attribute / per-request
# control we exercise below. The karr #88 pattern (URL string pinning in
# t/46_gemini_endpoint_seam.t) uses raw string equality; for JSON request
# bodies the order-independent form is canonical encoding, which is what
# JSON::MaybeXS->canonical(1) produces.

my $canon = JSON::MaybeXS->new->canonical(1)->utf8(1);

# Capture the body bytes of a chat_request call as a canonical string.
sub body {
  my ( $engine, %extra ) = @_;
  my $req = $engine->chat_request( [ { role => 'user', content => 'hi' } ], %extra );
  return $canon->encode( $canon->decode( $req->content ) );
}

# Same, but for the streaming request.
sub stream_body {
  my ( $engine, %extra ) = @_;
  my $req = $engine->chat_stream_request( [ { role => 'user', content => 'hi' } ], %extra );
  return $canon->encode( $canon->decode( $req->content ) );
}

# --- OpenAI non-streaming scenarios (karr #98 + karr #88 pattern) ---

my $oai_bare = Langertha::Engine::OpenAI->new( api_key => 'k', model => 'gpt-4o-mini' );
is( body($oai_bare),
  q({"messages":[{"content":"hi","role":"user"}],"model":"gpt-4o-mini","stream":false}),
  'OpenAI bare body: no reasoning, no cache, no temperature' );

my $oai_temp = Langertha::Engine::OpenAI->new( api_key => 'k', model => 'gpt-4o-mini', temperature => 0.5 );
is( body($oai_temp),
  q({"messages":[{"content":"hi","role":"user"}],"model":"gpt-4o-mini","stream":false,"temperature":0.5}),
  'OpenAI body: temperature only' );

my $oai_re = Langertha::Engine::OpenAI->new( api_key => 'k', model => 'gpt-4o-mini', reasoning_effort => 'high' );
is( body($oai_re),
  q({"messages":[{"content":"hi","role":"user"}],"model":"gpt-4o-mini","reasoning_effort":"high","stream":false}),
  'OpenAI body: reasoning only (via helper)' );

my $oai_cache = Langertha::Engine::OpenAI->new( api_key => 'k', model => 'gpt-4o-mini', prompt_cache_key => 'my-key' );
is( body($oai_cache),
  q({"messages":[{"content":"hi","role":"user"}],"model":"gpt-4o-mini","prompt_cache_key":"my-key","stream":false}),
  'OpenAI body: prompt_cache_key only (via helper)' );

my $oai_all = Langertha::Engine::OpenAI->new(
  api_key         => 'k',
  model           => 'gpt-4o-mini',
  temperature     => 0.5,
  reasoning_effort => 'high',
  prompt_cache_key => 'my-key',
);
is( body($oai_all),
  q({"messages":[{"content":"hi","role":"user"}],"model":"gpt-4o-mini","prompt_cache_key":"my-key","reasoning_effort":"high","stream":false,"temperature":0.5}),
  'OpenAI body: temperature + reasoning + cache (all via helper)' );

my $oai_rf = Langertha::Engine::OpenAI->new(
  api_key        => 'k',
  model          => 'gpt-4o-mini',
  response_format => { type => 'json_object' },
);
is( body($oai_rf),
  q({"messages":[{"content":"hi","role":"user"}],"model":"gpt-4o-mini","response_format":{"type":"json_object"},"stream":false}),
  'OpenAI body: response_format stays inline (not in helper)' );

# Per-request controls beat attributes on a per-key basis; seed stays
# inline at its original place, reasoning/cache emit via the helper.
is( body( $oai_bare, controls => { temperature => 0.7, seed => 42, reasoning_effort => 'medium' } ),
  q({"messages":[{"content":"hi","role":"user"}],"model":"gpt-4o-mini","reasoning_effort":"medium","seed":42,"stream":false,"temperature":0.7}),
  'OpenAI body: per-request controls (temperature + seed + reasoning); seed keeps its inline position' );

# --- Anthropic non-streaming scenarios ---

my $ant_bare = Langertha::Engine::Anthropic->new(
  api_key => 'k', model => 'claude-3-5-sonnet-20240620', response_size => 2048,
);
is( body($ant_bare),
  q({"max_tokens":2048,"messages":[{"content":"hi","role":"user"}],"model":"claude-3-5-sonnet-20240620"}),
  'Anthropic bare body: no reasoning, no cache, no temperature' );

my $ant_temp = Langertha::Engine::Anthropic->new(
  api_key => 'k', model => 'claude-3-5-sonnet-20240620', response_size => 2048, temperature => 0.5,
);
is( body($ant_temp),
  q({"max_tokens":2048,"messages":[{"content":"hi","role":"user"}],"model":"claude-3-5-sonnet-20240620","temperature":0.5}),
  'Anthropic body: temperature only' );

my $ant_re = Langertha::Engine::Anthropic->new(
  api_key => 'k', model => 'claude-3-5-sonnet-20240620', response_size => 2048, reasoning_effort => 'high',
);
is( body($ant_re),
  q({"max_tokens":2048,"messages":[{"content":"hi","role":"user"}],"model":"claude-3-5-sonnet-20240620","output_config":{"effort":"high"},"thinking":{"type":"adaptive"}}),
  'Anthropic body: reasoning only (via helper)' );

my $ant_cache = Langertha::Engine::Anthropic->new(
  api_key => 'k', model => 'claude-3-5-sonnet-20240620', response_size => 2048, prompt_cache => 1,
);
is( body($ant_cache),
  q({"cache_control":{"type":"ephemeral"},"max_tokens":2048,"messages":[{"content":"hi","role":"user"}],"model":"claude-3-5-sonnet-20240620"}),
  'Anthropic body: prompt_cache only (via helper)' );

my $ant_all = Langertha::Engine::Anthropic->new(
  api_key => 'k', model => 'claude-3-5-sonnet-20240620', response_size => 2048,
  temperature => 0.5, reasoning_effort => 'high', prompt_cache => 1,
);
is( body($ant_all),
  q({"cache_control":{"type":"ephemeral"},"max_tokens":2048,"messages":[{"content":"hi","role":"user"}],"model":"claude-3-5-sonnet-20240620","output_config":{"effort":"high"},"temperature":0.5,"thinking":{"type":"adaptive"}}),
  'Anthropic body: temperature + reasoning + cache (all via helper)' );

my $ant_geo = Langertha::Engine::Anthropic->new(
  api_key => 'k', model => 'claude-3-5-sonnet-20240620', response_size => 2048, inference_geo => 'us',
);
is( body($ant_geo),
  q({"inference_geo":"us","max_tokens":2048,"messages":[{"content":"hi","role":"user"}],"model":"claude-3-5-sonnet-20240620"}),
  'Anthropic body: inference_geo stays inline (not in helper)' );

is( body( $ant_bare, controls => { temperature => 0.7, reasoning_effort => 'medium', prompt_cache => 1 } ),
  q({"cache_control":{"type":"ephemeral"},"max_tokens":2048,"messages":[{"content":"hi","role":"user"}],"model":"claude-3-5-sonnet-20240620","output_config":{"effort":"medium"},"temperature":0.7,"thinking":{"type":"adaptive"}}),
  'Anthropic body: per-request controls (temperature + reasoning + cache)' );

# --- Streaming parity: same helper, same byte order ---

is( stream_body($oai_bare),
  q({"messages":[{"content":"hi","role":"user"}],"model":"gpt-4o-mini","stream":true}),
  'OpenAI streaming bare body' );

is( stream_body($oai_all),
  q({"messages":[{"content":"hi","role":"user"}],"model":"gpt-4o-mini","prompt_cache_key":"my-key","reasoning_effort":"high","stream":true,"temperature":0.5}),
  'OpenAI streaming body: all params via helper' );

is( stream_body($ant_bare),
  q({"max_tokens":2048,"messages":[{"content":"hi","role":"user"}],"model":"claude-3-5-sonnet-20240620","stream":true}),
  'Anthropic streaming bare body' );

is( stream_body($ant_all),
  q({"cache_control":{"type":"ephemeral"},"max_tokens":2048,"messages":[{"content":"hi","role":"user"}],"model":"claude-3-5-sonnet-20240620","output_config":{"effort":"high"},"stream":true,"temperature":0.5,"thinking":{"type":"adaptive"}}),
  'Anthropic streaming body: all params via helper' );

# --- Helper unit test: the can-guards still defend when a role is absent ---

# Role::ReasoningEffort is composed on OpenAIBase, so the helper returns
# its kwargs here. Empty result when nothing is set.
my @kw = $oai_bare->generation_kwargs_for;
is( scalar(@kw), 0, 'OpenAI bare: helper returns empty list when nothing is set' );

@kw = $oai_re->generation_kwargs_for(reasoning_effort => 'high');
is_deeply( { @kw }, { reasoning_effort => 'high' },
  'OpenAI helper: reasoning_effort control passes through' );

@kw = $oai_cache->generation_kwargs_for(prompt_cache_key => 'k');
is_deeply( { @kw }, { prompt_cache_key => 'k' },
  'OpenAI helper: prompt_cache_key control passes through' );

# Anthropic with prompt_cache emits cache_control via the helper.
@kw = $ant_cache->generation_kwargs_for(prompt_cache => 1);
is_deeply( { @kw }, { cache_control => { type => 'ephemeral' } },
  'Anthropic helper: prompt_cache control passes through to cache_control' );

done_testing;