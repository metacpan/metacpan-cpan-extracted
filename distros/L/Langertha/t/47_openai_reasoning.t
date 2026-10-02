#!/usr/bin/env perl
# ABSTRACT: OpenAI model-gated reasoning_effort clamp, Chat vs Responses symmetry (karr k140)

use strict;
use warnings;

use Test2::Bundle::More;
use JSON::MaybeXS;

use Langertha::Reasoning;
use Langertha::Engine::OpenAI;
use Langertha::Engine::OpenAIResponses;

my $json = JSON::MaybeXS->new->canonical(1)->utf8(1);

# What each OpenAI wire emits for (model, effort), read straight off the value
# object: undef means the effort was clamped away, otherwise the passed value.
sub emit_openai {
  my ( $model, $effort ) = @_;
  my %kw = Langertha::Reasoning->new( effort => $effort, model => $model )->to('openai');
  return exists $kw{reasoning_effort} ? $kw{reasoning_effort} : undef;
}
sub emit_responses {
  my ( $model, $effort ) = @_;
  my %kw = Langertha::Reasoning->new( effort => $effort, model => $model )->to('responses');
  return exists $kw{reasoning} ? $kw{reasoning}{effort} : undef;
}

my @EFFORTS = qw( none minimal low medium high xhigh max );

# Advisor-verified per-model ladders (karr k140, 2026-09-01; gpt-6-astra k151,
# 2026-09-14). A scalar cell (1 = accepted, 0 = clamped away) is shared by both
# OpenAI wires; a { chat => B, resp => B } cell pins a per-wire divergence. The
# generations do NOT overlap on the extremes: gpt-6-astra rejects BOTH none (HTTP
# 400) and minimal (unsupported) while keeping low..max; gpt-5.6/gpt-5.5 have
# none/xhigh(/max) but no minimal; legacy gpt-5 has minimal but no none/xhigh/max.
# gpt-5.1 is gated (karr k174, doc-sourced): base drops minimal/xhigh/max,
# gpt-5.1-codex-max re-adds xhigh (still no max); the remaining unlisted id
# (gpt-4o-mini) keeps the whole normalized enum.
#
# karr k176 (live-confirmed 2026-09-16 on gpt-5.6-terra): 'max' is Responses-only
# for the gpt-6 and gpt-5.6 generations — Chat Completions reasoning_effort=max ->
# HTTP 400 ("Supported values are: 'none', 'low', 'medium', 'high', and 'xhigh'."),
# Responses reasoning.effort=max -> HTTP 200. So their max cell diverges per wire
# (chat DROP, resp keep); gpt-6 is doc-sourced (advisor Azure mirror).
my %EXPECT = (
  'gpt-6-astra'   => { none => 0, minimal => 0, low => 1, medium => 1, high => 1, xhigh => 1, max => { chat => 0, resp => 1 } },
  'gpt-5.6-terra' => { none => 1, minimal => 0, low => 1, medium => 1, high => 1, xhigh => 1, max => { chat => 0, resp => 1 } },
  'gpt-5.6'       => { none => 1, minimal => 0, low => 1, medium => 1, high => 1, xhigh => 1, max => { chat => 0, resp => 1 } },
  'gpt-5.6-luna'  => { none => 1, minimal => 0, low => 1, medium => 1, high => 1, xhigh => 1, max => { chat => 0, resp => 1 } },
  'gpt-5.5'       => { none => 1, minimal => 0, low => 1, medium => 1, high => 1, xhigh => 1, max => 0 },
  'gpt-5.5-pro'   => { none => 1, minimal => 0, low => 1, medium => 1, high => 1, xhigh => 1, max => 0 },
  'gpt-5'         => { none => 0, minimal => 1, low => 1, medium => 1, high => 1, xhigh => 0, max => 0 },
  'gpt-5-mini'    => { none => 0, minimal => 1, low => 1, medium => 1, high => 1, xhigh => 0, max => 0 },
  'gpt-5.1'           => { none => 1, minimal => 0, low => 1, medium => 1, high => 1, xhigh => 0, max => 0 },
  'gpt-5.1-codex-max' => { none => 1, minimal => 0, low => 1, medium => 1, high => 1, xhigh => 1, max => 0 },
  'gpt-4o-mini'   => { none => 1, minimal => 1, low => 1, medium => 1, high => 1, xhigh => 1, max => 1 },
);

for my $model ( sort keys %EXPECT ) {
  for my $effort ( @EFFORTS ) {
    my $cell = $EXPECT{$model}{$effort};
    my ( $chat_ok, $resp_ok ) = ref $cell eq 'HASH'
      ? ( $cell->{chat}, $cell->{resp} )
      : ( $cell, $cell );
    my $want_chat = $chat_ok ? $effort : undef;
    my $want_resp = $resp_ok ? $effort : undef;

    is( emit_openai( $model, $effort ), $want_chat,
      "openai:    $model + $effort -> " . ( $want_chat // 'DROP' ) );
    is( emit_responses( $model, $effort ), $want_resp,
      "responses: $model + $effort -> " . ( $want_resp // 'DROP' ) );
  }
}

# --- Engine-level: the k176 per-wire max split -----------------------------

# k176 (live-confirmed 2026-09-16 on gpt-5.6-terra): the Chat Completions wire
# 400s on reasoning_effort=max ("'reasoning_effort' does not support 'max' with
# this model. Supported values are: 'none', 'low', 'medium', 'high', and
# 'xhigh'.") while the Responses wire accepts reasoning.effort=max (HTTP 200).
# The default OpenAI (Chat Completions) engine model is gpt-5.6-terra, so max is
# now DROPPED on the chat wire — a targeted per-wire clamp, not the old blanket
# max-drop (k140), and it leaves the Responses wire (next block) untouched.
{
  my $engine = Langertha::Engine::OpenAI->new( api_key => 'k', reasoning_effort => 'max' );
  my $body = $json->decode( $engine->chat('hi')->content );
  is( $body->{model}, 'gpt-5.6-terra', 'OpenAI default model is gpt-5.6-terra' );
  ok( !exists $body->{reasoning_effort},
    'gpt-5.6-terra drops reasoning_effort=max on the Chat wire (k176: chat 400s on max)' );
}

# Same model on the Responses wire keeps max — the divergence is per wire, not a
# blanket clamp (resp_body builds via Langertha::Engine::OpenAIResponses below).
{
  my $body = resp_body( model => 'gpt-5.6-terra', reasoning_effort => 'max' );
  is_deeply( $body->{reasoning}, { effort => 'max' },
    'gpt-5.6-terra keeps reasoning.effort=max on the Responses wire (k176)' );
}

# Drift 1b: `minimal` is the legacy spelling; gpt-5.6-terra rejects it, so it
# must be clamped away rather than passed straight through.
{
  my $engine = Langertha::Engine::OpenAI->new( api_key => 'k', reasoning_effort => 'minimal' );
  my $body = $json->decode( $engine->chat('hi')->content );
  ok( !exists $body->{reasoning_effort},
    'gpt-5.6-terra drops minimal (not on the gpt-5.6 ladder)' );
}

# The Responses engine (gpt-5.5-pro) now clamps identically to Chat Completions:
# it drops max and minimal, keeps high. Before k140 to_responses clamped nothing.
sub resp_body {
  my ( %args ) = @_;
  my $engine = Langertha::Engine::OpenAIResponses->new( api_key => 'k', %args );
  return $json->decode( $engine->chat_request([ { role => 'user', content => 'hi' } ])->content );
}
{
  my $body = resp_body( model => 'gpt-5.5-pro', reasoning_effort => 'max' );
  ok( !exists $body->{reasoning}, 'gpt-5.5-pro (Responses) drops max (not on gpt-5.5 ladder)' );
}
{
  my $body = resp_body( model => 'gpt-5.5-pro', reasoning_effort => 'high' );
  is_deeply( $body->{reasoning}, { effort => 'high' }, 'gpt-5.5-pro (Responses) keeps high' );
}
{
  my $body = resp_body( model => 'gpt-5.5-pro', reasoning_effort => 'minimal' );
  ok( !exists $body->{reasoning}, 'gpt-5.5-pro (Responses) drops minimal' );
}

done_testing;
