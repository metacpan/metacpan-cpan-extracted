#!/usr/bin/env perl
# ABSTRACT: The capability registry carries discriminating info (per-model + per-engine) — k138

use strict;
use warnings;

use Test2::Bundle::More;

use Langertha::Engine::OpenAI;
use Langertha::Engine::DeepSeek;
use Langertha::Engine::MiniMax;
use Langertha::Engine::Moonshot;
use Langertha::Engine::Scaleway;
use Langertha::Engine::OllamaOpenAI;
use Langertha::Engine::LlamaCpp;
use Langertha::Engine::SGLang;
use Langertha::Engine::Hetzner;

# This test encodes the CORE complaint of k138: on the tool / structured-output
# axis the capability registry used to be one identical flag row repeated across
# ~17 OpenAI-dialect engines, ~11 of them wrong. ADR 0002's amendment adds a
# per-MODEL correction layer (Langertha::Role::Capabilities::model_capability_corrections)
# on top of the engine-WIDE `around engine_capabilities` escape hatch. Every
# assertion below is sabotage-verifiable: remove the correction it names (the
# per-model table or the engine's around) and the assertion goes red.

# ---------------------------------------------------------------------------
# 1. Per-MODEL discrimination inside ONE engine — the keystone of k138.
#    Moonshot (Kimi, OpenAI wire): kimi-k3 always thinks, so a forced *named*
#    tool 400s, but `required`/any is fine; the K2.x line rejects `required`,
#    so `any` is gone there while named stays. Same engine, opposite rows.
#    Also exercises both matcher forms: 'kimi-k3' (exact) vs qr/\Akimi-k2\./.
# ---------------------------------------------------------------------------
my $k3  = Langertha::Engine::Moonshot->new( api_key => 'x' );                        # default kimi-k3
my $k26 = Langertha::Engine::Moonshot->new( api_key => 'x', model => 'kimi-k2.6' );
my $k27 = Langertha::Engine::Moonshot->new( api_key => 'x', model => 'kimi-k2.7-code' );

ok !$k3->supports('tool_choice_named'), 'kimi-k3 clears tool_choice_named (thinking forbids forced tool)';
ok  $k3->supports('tool_choice_any'),   'kimi-k3 keeps tool_choice_any';
ok  $k3->supports('tool_choice_auto'),  'kimi-k3 keeps tool_choice_auto';

ok  $k26->supports('tool_choice_named'), 'kimi-k2.6 keeps tool_choice_named';
ok !$k26->supports('tool_choice_any'),   'kimi-k2.6 clears tool_choice_any (no `required`)';
ok  $k27->supports('tool_choice_named'), 'kimi-k2.7-code keeps tool_choice_named';
ok !$k27->supports('tool_choice_any'),   'kimi-k2.7-code clears tool_choice_any (regex matcher)';

# The registry is genuinely model-scoped now: two models of one engine disagree.
isnt !!$k3->supports('tool_choice_named'), !!$k26->supports('tool_choice_named'),
  'same engine, different model => different tool_choice_named (per-MODEL registry)';
isnt !!$k3->supports('tool_choice_any'), !!$k26->supports('tool_choice_any'),
  'same engine, different model => different tool_choice_any';

# The matcher is selective: an unknown Kimi model falls through to the base row.
my $kx = Langertha::Engine::Moonshot->new( api_key => 'x', model => 'kimi-future-99' );
ok $kx->supports('tool_choice_named'), 'unknown kimi model keeps role-derived tool_choice_named (no match)';
ok $kx->supports('tool_choice_any'),   'unknown kimi model keeps role-derived tool_choice_any (no match)';

# ---------------------------------------------------------------------------
# 2. Cross-engine discrimination — the flat identical row is broken.
# ---------------------------------------------------------------------------
my $openai   = Langertha::Engine::OpenAI->new( api_key => 'x' );
my $deepseek = Langertha::Engine::DeepSeek->new( api_key => 'x' );
my $ollama   = Langertha::Engine::OllamaOpenAI->new( url => 'http://x/v1', model => 'llama3' );

ok  $openai->supports('response_format_json_schema'),   'openai keeps response_format_json_schema';
ok !$deepseek->supports('response_format_json_schema'), 'deepseek clears response_format_json_schema (enum has none)';
ok  $deepseek->supports('response_format_json_object'), 'deepseek keeps response_format_json_object';

ok  $openai->supports('tool_choice_named'), 'openai keeps tool_choice_named';
ok !$ollama->supports('tool_choice_named'), 'ollama /v1 clears tool_choice_named (tool_choice unsupported, SILENT)';
ok !$ollama->supports('tool_choice_auto'),  'ollama /v1 clears tool_choice_auto';
ok  $ollama->supports('tools_native'),      'ollama /v1 keeps tools_native (the tools array works)';

# ---------------------------------------------------------------------------
# 3. Engine-wide corrections (the `around` escape hatch) — spot checks.
# ---------------------------------------------------------------------------
my $minimax = Langertha::Engine::MiniMax->new( api_key => 'x' );
ok  $minimax->supports('tools_native'),                 'minimax keeps tools_native (function calling)';
ok !$minimax->supports('tool_choice_named'),            'minimax clears tool_choice_named (absent from schema)';
ok !$minimax->supports('response_format_json_schema'),  'minimax clears response_format_json_schema';
ok !$minimax->supports('parallel_tool_use'),            'minimax clears parallel_tool_use';

my $llama = Langertha::Engine::LlamaCpp->new( url => 'http://x/v1' );
ok !$llama->supports('tool_choice_named'), 'llama.cpp clears tool_choice_named (object silently -> auto)';
ok  $llama->supports('tool_choice_auto'),  'llama.cpp keeps tool_choice_auto (string form parses)';

my $sglang = Langertha::Engine::SGLang->new( url => 'http://x/v1' );
# k244: protocol.py types tool_choice as auto|required|none|named (default
# auto) and serving_chat honors none; the docs list only required/named because
# those need the grammar backend. Clearing auto/none (k138) was an under-claim.
ok  $sglang->supports('tool_choice_auto'),  'sglang keeps tool_choice_auto (protocol.py Literal, k244)';
ok  $sglang->supports('tool_choice_none'),  'sglang keeps tool_choice_none (serving_chat skips parsing, k244)';
ok  $sglang->supports('tool_choice_any'),   'sglang keeps tool_choice_any (wire required)';
ok !$sglang->supports('prompt_cache_key'),  'sglang still clears prompt_cache_key (k200)';
ok  $sglang->supports('tool_choice_named'), 'sglang keeps tool_choice_named (grammar-backed)';

my $hetzner = Langertha::Engine::Hetzner->new( api_key => 'x' );
ok !$hetzner->supports('tools_native'),                'hetzner clears tools_native (undocumented/experimental)';
ok !$hetzner->supports('response_format_json_schema'), 'hetzner clears response_format_json_schema';
ok !$hetzner->supports('parallel_tool_use'),           'hetzner clears parallel_tool_use';

# Scaleway: the deliberate NON-correction (k138 conflict resolution). The k138
# matrix flagged tool_choice_any, but canonical `any` serializes to wire
# `required` (Langertha::ToolChoice), which Scaleway's none|auto|required enum
# accepts — so the flag is correct and stays. The two genuine mismatches clear.
my $scw = Langertha::Engine::Scaleway->new( api_key => 'x' );
ok !$scw->supports('parallel_tool_use'),          'scaleway clears parallel_tool_use (inert on wire, SILENT)';
ok !$scw->supports('response_format_json_object'),'scaleway clears deprecated response_format_json_object';
ok  $scw->supports('tool_choice_any'),            'scaleway KEEPS tool_choice_any (canonical any -> wire required)';
ok  $scw->supports('response_format_json_schema'),'scaleway keeps response_format_json_schema';

# ---------------------------------------------------------------------------
# 4. The registry now carries DISCRIMINATING information (the ticket's headline).
#    Collect the tool/structured-output signature of the fleet and prove it is
#    no longer one identical row. Reverting the corrections collapses this to 1.
# ---------------------------------------------------------------------------
my @axis = qw(
  tools_native tool_choice_auto tool_choice_any tool_choice_none tool_choice_named
  response_format_json_object response_format_json_schema parallel_tool_use
);
my $sig = sub {
  my ($engine) = @_;
  return join ',', map { $_ . '=' . ( $engine->supports($_) ? 1 : 0 ) } @axis;
};

my %rows;
$rows{ $sig->($_) }++
  for ( $openai, $deepseek, $minimax, $ollama, $llama, $sglang, $hetzner, $scw, $k3, $k26 );

cmp_ok scalar keys %rows, '>=', 5,
  'the tool/structured-output axis carries discriminating info (was ONE identical row across the fleet — k138)';

done_testing;
