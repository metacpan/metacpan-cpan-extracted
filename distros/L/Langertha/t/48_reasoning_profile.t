#!/usr/bin/env perl
# ABSTRACT: Characterization matrix locking Langertha::Reasoning wire output (karr k173)

# Golden-master matrix for the reasoning-profile refactor (karr k173 Phase 1).
# Captured BEFORE the internal Profile extraction and asserted to stay
# byte-identical THROUGH it. Every (model, effort/budget) -> wire kwargs pair
# below is the output the value object produces TODAY, tested on each model's
# NATURAL wire (the wire the model's engine actually speaks) — the cross-wire
# combinations an engine never issues are deliberately not pinned.
#
# Phase 1.5 (karr k176) has applied the OpenAI per-wire 'max' split: the gpt-6
# and gpt-5.6 generations drop reasoning_effort=max on the Chat Completions
# (openai) wire while keeping reasoning.effort=max on the Responses wire.
# Live-confirmed 2026-09-16 on gpt-5.6-terra: chat reasoning_effort=max -> HTTP
# 400 ("Supported values are: 'none', 'low', 'medium', 'high', and 'xhigh'."),
# responses reasoning.effort=max -> HTTP 200. gpt-6 is doc-sourced (advisor Azure
# mirror). A { openai => ..., responses => ... } ladder cell pins each divergence.

use strict;
use warnings;

use Test2::Bundle::More;
use JSON::MaybeXS qw( is_bool );

use Langertha::Reasoning;

# Read the exact kwargs the value object emits for a wire, as a hashref.
sub kw {
  my ( $fmt, %args ) = @_;
  return { Langertha::Reasoning->new(%args)->to($fmt) };
}

my @EFFORTS = qw( none minimal low medium high xhigh max );

# ---------------------------------------------------------------------------
# openai + responses wires: model-gated ladder. A scalar cell is shared by both
# wires; a { openai => ..., responses => ... } cell pins a per-wire divergence
# (karr k176: 'max' is Responses-only for gpt-6 / gpt-5.6). undef = the effort
# was clamped away (empty kwargs).
# ---------------------------------------------------------------------------
my %OPENAI_LADDER = (
  'gpt-6-astra'   => { none => undef, minimal => undef, low => 'low', medium => 'medium', high => 'high', xhigh => 'xhigh', max => { openai => undef, responses => 'max' } },
  'gpt-5.6-terra' => { none => 'none', minimal => undef, low => 'low', medium => 'medium', high => 'high', xhigh => 'xhigh', max => { openai => undef, responses => 'max' } },
  'gpt-5.5'       => { none => 'none', minimal => undef, low => 'low', medium => 'medium', high => 'high', xhigh => 'xhigh', max => undef },
  'gpt-5'         => { none => undef, minimal => 'minimal', low => 'low', medium => 'medium', high => 'high', xhigh => undef, max => undef },
  # gpt-5.1 is gated (karr k174, doc-sourced): base drops minimal/xhigh/max,
  # codex-max re-adds xhigh (still no max). Both wires identical, so scalar cells.
  'gpt-5.1'           => { none => 'none', minimal => undef, low => 'low', medium => 'medium', high => 'high', xhigh => undef, max => undef },
  'gpt-5.1-codex-max' => { none => 'none', minimal => undef, low => 'low', medium => 'medium', high => 'high', xhigh => 'xhigh', max => undef },
);

for my $model ( sort keys %OPENAI_LADDER ) {
  for my $effort ( @EFFORTS ) {
    my $cell = $OPENAI_LADDER{$model}{$effort};
    my ( $want_chat, $want_resp ) = ref $cell eq 'HASH'
      ? ( $cell->{openai}, $cell->{responses} )
      : ( $cell, $cell );
    my $chat = kw( 'openai',    effort => $effort, model => $model );
    my $resp = kw( 'responses', effort => $effort, model => $model );

    if ( defined $want_chat ) {
      is_deeply( $chat, { reasoning_effort => $want_chat },
        "openai:    $model + $effort -> reasoning_effort=$want_chat" );
    }
    else {
      is_deeply( $chat, {}, "openai:    $model + $effort -> DROP" );
    }
    if ( defined $want_resp ) {
      is_deeply( $resp, { reasoning => { effort => $want_resp } },
        "responses: $model + $effort -> reasoning.effort=$want_resp" );
    }
    else {
      is_deeply( $resp, {}, "responses: $model + $effort -> DROP" );
    }
  }
}

# No model on the openai wire: full-enum passthrough (unrecognized id keeps all).
is_deeply( kw( 'openai', effort => 'max' ), { reasoning_effort => 'max' },
  'openai: no model keeps the full enum (max passes through)' );

# ---------------------------------------------------------------------------
# anthropic wire: fixed effort set low|medium|high|xhigh|max + adaptive thinking
# block; Fable-class models carry effort but never a thinking block.
# ---------------------------------------------------------------------------
{
  my %ADAPTIVE = ( none => undef, minimal => undef,
    low => 'low', medium => 'medium', high => 'high', xhigh => 'xhigh', max => 'max' );
  for my $effort ( @EFFORTS ) {
    my $got  = kw( 'anthropic', effort => $effort, model => 'claude-opus-4-8' );
    my $eff  = $ADAPTIVE{$effort};
    my $want = defined $eff
      ? { output_config => { effort => $eff }, thinking => { type => 'adaptive' } }
      : {};
    is_deeply( $got, $want, "anthropic: claude-opus-4-8 + $effort" );

    my $fab  = kw( 'anthropic', effort => $effort, model => 'claude-fable-5-1' );
    my $fwant = defined $eff ? { output_config => { effort => $eff } } : {};
    is_deeply( $fab, $fwant, "anthropic: claude-fable-5-1 + $effort (no thinking block)" );
  }

  # thinking_display rides on the adaptive block (and turns it on alone).
  is_deeply(
    kw( 'anthropic', effort => 'high', thinking_display => 'summarized', model => 'claude-opus-4-8' ),
    { output_config => { effort => 'high' }, thinking => { type => 'adaptive', display => 'summarized' } },
    'anthropic: effort + display -> both fields' );
  is_deeply(
    kw( 'anthropic', thinking_display => 'summarized', model => 'claude-opus-4-8' ),
    { thinking => { type => 'adaptive', display => 'summarized' } },
    'anthropic: display-only turns on an adaptive block, no output_config' );
  # Fable-class: display cannot ride (no thinking block at all).
  is_deeply(
    kw( 'anthropic', effort => 'high', thinking_display => 'summarized', model => 'claude-fable-5-1' ),
    { output_config => { effort => 'high' } },
    'anthropic: fable-class drops display (no thinking block)' );
}

# ---------------------------------------------------------------------------
# anthropic wire, per-model effort vocabulary (karr k177). Claude 4.6
# (opus/sonnet) accepts low|medium|high|max but NOT xhigh — Anthropic's effort
# doc lists 4.6 under `max`, not under `xhigh` (advisor-verified 2026-09-16,
# platform.claude.com; doc-sourced, not live-probed). Claude 4.7+/5 keep the
# full low|medium|high|xhigh|max. On xhigh the 4.6 models drop
# output_config.effort — and its thinking block, since no effort/display remains;
# every other accepted effort emits the adaptive block unchanged.
# ---------------------------------------------------------------------------
{
  my %CLAUDE_46 = ( none => undef, minimal => undef,
    low => 'low', medium => 'medium', high => 'high', xhigh => undef, max => 'max' );
  for my $model (qw( claude-opus-4-6 claude-sonnet-4-6 )) {
    for my $effort ( @EFFORTS ) {
      my $got  = kw( 'anthropic', effort => $effort, model => $model );
      my $eff  = $CLAUDE_46{$effort};
      my $want = defined $eff
        ? { output_config => { effort => $eff }, thinking => { type => 'adaptive' } }
        : {};
      is_deeply( $got, $want, "anthropic: $model + $effort (4.6 accepts no xhigh)" );
    }
  }

  # The more-specific 4.6 profile must not narrow the generic Claude 4.7+/5
  # family — they still emit xhigh (unchanged behaviour).
  for my $model (qw( claude-opus-4-8 claude-sonnet-5 )) {
    is_deeply(
      kw( 'anthropic', effort => 'xhigh', model => $model ),
      { output_config => { effort => 'xhigh' }, thinking => { type => 'adaptive' } },
      "anthropic: $model + xhigh still emitted (generic claude keeps full set)" );
  }
}

# ---------------------------------------------------------------------------
# gemini wire (effort path): thinkingConfig.thinkingLevel, per-family clamp.
# ---------------------------------------------------------------------------
my %GEMINI_LEVEL = (
  'gemini-3-pro-preview' => { none => 'low', minimal => 'low', low => 'low', medium => 'low',    high => 'high', xhigh => 'high', max => 'high' },
  'gemini-3.7-flash'     => { none => 'low', minimal => 'low', low => 'low', medium => 'medium', high => 'high', xhigh => 'high', max => 'high' },
  'gemini-3.6-flash'     => { none => 'minimal', minimal => 'minimal', low => 'low', medium => 'medium', high => 'high', xhigh => 'high', max => 'high' },
  # Non-gemini-3 model: universally-accepted binary low|high collapse.
  'gemini-2.0-flash'     => { none => 'low', minimal => 'low', low => 'low', medium => 'low',    high => 'high', xhigh => 'high', max => 'high' },
);

for my $model ( sort keys %GEMINI_LEVEL ) {
  for my $effort ( @EFFORTS ) {
    my $want = $GEMINI_LEVEL{$model}{$effort};
    is_deeply( kw( 'gemini', effort => $effort, model => $model ),
      { thinkingConfig => { thinkingLevel => $want } },
      "gemini: $model + $effort -> thinkingLevel=$want" );
  }
}

# No model on the gemini wire: same binary collapse as a non-gemini-3 model.
is_deeply( kw( 'gemini', effort => 'medium' ),
  { thinkingConfig => { thinkingLevel => 'low' } },
  'gemini: no model medium -> low (binary fallback)' );
is_deeply( kw( 'gemini', effort => 'max' ),
  { thinkingConfig => { thinkingLevel => 'high' } },
  'gemini: no model max -> high (binary fallback)' );

# ---------------------------------------------------------------------------
# gemini wire (budget path): thinkingConfig.thinkingBudget passes the integer
# through verbatim (no Phase-1 clamping).
# ---------------------------------------------------------------------------
is_deeply( kw( 'gemini', thinking_budget => 2048, model => 'gemini-2.5-pro' ),
  { thinkingConfig => { thinkingBudget => 2048 } },
  'gemini: gemini-2.5-pro thinking_budget=2048 passes through' );
is_deeply( kw( 'gemini', thinking_budget => 512, model => 'gemini-2.5-flash' ),
  { thinkingConfig => { thinkingBudget => 512 } },
  'gemini: gemini-2.5-flash thinking_budget=512 passes through' );

# ---------------------------------------------------------------------------
# ollama wire (karr k175). GPT-OSS takes graded level STRINGS on Ollama's think
# knob (low<medium<high<max) and ALWAYS reasons — there is no "off": think:false is
# ignored, so 'none' maps to the floor 'low'. Every other model takes only the
# model-agnostic boolean (any effort -> on, none -> off), UNCHANGED. Live-probed
# 2026-09-17 via ollama.com gpt-oss:20b.
# ---------------------------------------------------------------------------
{
  # GPT-OSS: effort -> level string, across the model-id spellings. none/minimal
  # collapse to 'low' (no off), xhigh/max to 'max'; medium/high pass through.
  my %OSS_LEVEL = ( none => 'low', minimal => 'low', low => 'low',
    medium => 'medium', high => 'high', xhigh => 'max', max => 'max' );
  for my $model (qw( gpt-oss gpt-oss:20b gpt-oss:120b )) {
    for my $effort ( @EFFORTS ) {
      my $want = $OSS_LEVEL{$effort};
      is_deeply( kw( 'ollama', effort => $effort, model => $model ),
        { think => $want },
        "ollama: $model + $effort -> think=\"$want\" (level string, gpt-oss has no off)" );
    }
  }

  # Non-gpt-oss: the boolean collapse, UNCHANGED. think must be a real JSON
  # boolean (true/false), never the string level.
  for my $model (qw( llama3.3 qwen3:8b )) {
    my $on = kw( 'ollama', effort => 'high', model => $model );
    ok( is_bool( $on->{think} ), "ollama: $model + high -> think is a JSON boolean" );
    ok( $on->{think}, "ollama: $model + high -> think is true" );
    my $off = kw( 'ollama', effort => 'none', model => $model );
    ok( is_bool( $off->{think} ), "ollama: $model + none -> think is a JSON boolean" );
    ok( !$off->{think}, "ollama: $model + none -> think is false" );
  }

  is_deeply( kw( 'ollama' ), {}, 'ollama: no effort -> nothing emitted' );

  # The Engine::Ollama direct construction path (bypasses Role::ReasoningEffort,
  # builds the value object straight from model + effort) flows through the same
  # Profile and yields the level string for gpt-oss.
  is_deeply(
    { Langertha::Reasoning->new( model => 'gpt-oss:20b', effort => 'high' )->to('ollama') },
    { think => 'high' },
    'ollama: direct Engine::Ollama path (gpt-oss:20b + high) -> think="high"' );
}

# ---------------------------------------------------------------------------
# Self-hosted Qwen3.x reasoning family on the openai (Chat Completions) wire
# (karr k79/k180). The loaded model's chat template — not the vLLM/SGLang/
# llama.cpp server — fixes the vocabulary: Qwen3.x reasoning accepts
# none|low|medium|xhigh and REJECTS high|minimal, so those two efforts DROP
# before they can 400 the server. Live-probed 2026-09-17 on a cortex vLLM
# server: Qwen/Qwen3.8-27B-FP8 -> "Unexpected reasoning effort high. Supported
# types are xhigh (default), medium, and low." Matched with or without the
# HuggingFace org prefix.
# ---------------------------------------------------------------------------
{
  my %QWEN = ( none => 'none', minimal => undef, low => 'low',
    medium => 'medium', high => undef, xhigh => 'xhigh', max => undef );
  for my $model (qw( Qwen/Qwen3.8-27B-FP8 qwen3.8-27b-fp8 Qwen/Qwen3.5-32B )) {
    for my $effort ( @EFFORTS ) {
      my $want = $QWEN{$effort};
      my $got  = kw( 'openai', effort => $effort, model => $model );
      if ( defined $want ) {
        is_deeply( $got, { reasoning_effort => $want },
          "openai: $model + $effort -> reasoning_effort=$want (Qwen3.x self-hosted)" );
      }
      else {
        is_deeply( $got, {},
          "openai: $model + $effort -> DROP (Qwen3.x rejects high|minimal)" );
      }
    }
  }

  # Unknown self-hosted models are NOT gated — every effort is forwarded raw so
  # an unknown chat template is never second-guessed (k180). Qwen3-32B (no dot)
  # is deliberately outside the Qwen3.x family match and stays a passthrough.
  for my $model (qw( Qwen/Qwen3-32B some-random-vllm-model mistral-7b-instruct )) {
    for my $effort (qw( minimal high max )) {
      is_deeply( kw( 'openai', effort => $effort, model => $model ),
        { reasoning_effort => $effort },
        "openai: $model + $effort -> passthrough (unknown self-hosted, raw)" );
    }
  }
}

# ---------------------------------------------------------------------------
# BUILD wire-truth gates: exactly one native control per generation.
# ---------------------------------------------------------------------------
like( eval { Langertha::Reasoning->new( effort => 'high', thinking_budget => 2048, model => 'gemini-3.5-flash' ); 1 } ? '' : $@,
  qr/mutually exclusive/i, 'BUILD: effort + thinking_budget croaks (mutually exclusive)' );
like( eval { Langertha::Reasoning->new( thinking_budget => 2048, model => 'claude-opus-4-8' ); 1 } ? '' : $@,
  qr/only valid on Gemini 2\.5/i, 'BUILD: thinking_budget on a non-Gemini-2.5 model croaks' );
like( eval { Langertha::Reasoning->new( thinking_budget => 2048, model => 'gemini-3.5-flash' ); 1 } ? '' : $@,
  qr/only valid on Gemini 2\.5/i, 'BUILD: thinking_budget on Gemini 3 croaks' );
like( eval { Langertha::Reasoning->new( effort => 'high', model => 'gemini-2.5-pro' ); 1 } ? '' : $@,
  qr/not valid on Gemini 2\.5/i, 'BUILD: effort on Gemini 2.5 croaks' );

done_testing;
