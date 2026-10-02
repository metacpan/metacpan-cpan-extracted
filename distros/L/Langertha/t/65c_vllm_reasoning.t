#!/usr/bin/env perl
# ABSTRACT: vLLM reasoning_effort wire dispatch (karr #77)

use strict;
use warnings;

use Test2::Bundle::More;
use JSON::MaybeXS;

use Langertha::Engine::vLLM;

my $json = JSON::MaybeXS->new->canonical(1)->utf8(1);

plan(10);

# --- Default model is 'default' (single-model vLLM server) ---
is(
  Langertha::Engine::vLLM->new(url => 'http://x')->default_model,
  'default',
  'vLLM default_model is default',
);

# --- reasoning_wire_format is openai (ADR 0009) ---
is(
  Langertha::Engine::vLLM->new(url => 'http://x')->reasoning_wire_format,
  'openai',
  'vLLM reasoning_wire_format is openai',
);

# --- reasoning_effort is advertised as supported ---
ok(
  Langertha::Engine::vLLM->new(url => 'http://x')->supports('reasoning_effort'),
  'vLLM advertises reasoning_effort capability',
);

# --- chat body carries reasoning_effort at the top level ---
for my $effort (qw(low medium high)) {
  my $e   = Langertha::Engine::vLLM->new(
    url             => 'http://x',
    reasoning_effort => $effort,
  );
  my $body = $json->decode($e->chat('hi')->content);
  is(
    $body->{reasoning_effort}, $effort,
    "vLLM emits flat reasoning_effort=$effort on the body",
  );
}

# --- reasoning_effort undef => not emitted ---
{
  my $e   = Langertha::Engine::vLLM->new(url => 'http://x');
  my $body = $json->decode($e->chat('hi')->content);
  ok(
    !exists $body->{reasoning_effort},
    'vLLM does NOT emit reasoning_effort when not set (no enable_thinking leakage)',
  );
}

# --- thinking_budget is NOT supported on the openai wire ---
ok(
  !Langertha::Engine::vLLM->new(url => 'http://x')->supports('thinking_budget'),
  'vLLM does NOT advertise thinking_budget (openai wire only carries reasoning_effort)',
);

# --- VLLMHook-style vllm_xargs override is honoured on the sub-engine ---
{
  require Langertha::Engine::VLLMHook;
  my $e = Langertha::Engine::VLLMHook->new(
    url        => 'http://x',
    vllm_xargs => { chat_template_kwargs => { enable_thinking => JSON::MaybeXS->new->true } },
  );
  my $body = $json->decode($e->chat('hi')->content);
  ok(
    exists $body->{vllm_xargs},
    'VLLMHook injects vllm_xargs (escape hatch for non-OpenAI reasoning knobs)',
  );
  ok(
    exists $body->{vllm_xargs}{chat_template_kwargs},
    'VLLMHook carries chat_template_kwargs through to the wire',
  );
  # DeepSeek-R1 / QwQ users wire enable_thinking=true via vllm_xargs when
  # they want to disable reasoning (per vLLM docs, reasoning_effort=none maps
  # to enable_thinking=false; some vLLM builds don't honour the none value).
}
