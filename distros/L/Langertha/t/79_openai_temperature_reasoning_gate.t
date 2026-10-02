#!/usr/bin/env perl
# ABSTRACT: k155 OpenAI reasoning-model temperature gate -- effort-aware drop+carp
#           on the chat (OpenAICompatible) and responses (ResponsesCompatible) wires.

# k155, live-verified 2026-09-17 against real OpenAI /v1/chat/completions: a
# reasoning model 400s on a non-default temperature ("Unsupported value:
# 'temperature' does not support 0.7 with this model. Only the default (1) value
# is supported.") whenever reasoning is active -- explicit low/medium/high AND the
# no-effort path (the model's server-side default effort applies). effort=none
# (where the model accepts it) returns 200, and temperature=1 (the wire default)
# is always accepted. So Langertha drops a non-default temperature and carps
# exactly when the resolved reasoning effort != none, and passes it through
# otherwise -- temperature=1 always, and any temperature once reasoning is off.
#
# Mechanism: Role::OpenAICompatible / Role::ResponsesCompatible::_temperature_kwargs
# (supports('temperature') gate + control-beats-attribute), delegating to the
# per-model, effort-aware predicate Engine::OpenAI::_temperature_rejected_by_reasoning
# (inherited by OpenAIResponses; reads Langertha::Reasoning::Profile READ-ONLY).
#
# Sabotage-verifiable: revert the predicate and the drop assertions flip to
# "kept"; remove the $temp != 1 guard in _temperature_kwargs and the temperature=1
# no-carp assertions flip; drop the effort_accepted_on('none') consult and the
# gpt-6 effort=none assertion flips.

use strict;
use warnings;

use Test2::Bundle::More;
use JSON::MaybeXS;

use Langertha::Engine::OpenAI;
use Langertha::Engine::OpenAIResponses;

my $json = JSON::MaybeXS->new->canonical(1)->utf8(1);

# Build a chat body from $engine while capturing any carp warning; %args are the
# chat_request %extra (e.g. controls => {...}). Returns ( $decoded_body, $carped ).
sub probe {
  my ( $engine, %args ) = @_;
  my @warns;
  local $SIG{__WARN__} = sub { push @warns, $_[0] };
  my $body = $json->decode(
    $engine->chat_request( $engine->chat_messages('p'), %args )->content
  );
  my $carped = ( grep { /dropping temperature/ } @warns ) ? 1 : 0;
  return ( $body, $carped );
}

# Same, via the streaming request builder -- the gate must place identically on
# chat_stream_request (both wire roles route it through _temperature_kwargs too).
sub probe_stream {
  my ( $engine, %args ) = @_;
  my @warns;
  local $SIG{__WARN__} = sub { push @warns, $_[0] };
  my $body = $json->decode(
    $engine->chat_stream_request( $engine->chat_messages('p'), %args )->content
  );
  my $carped = ( grep { /dropping temperature/ } @warns ) ? 1 : 0;
  return ( $body, $carped );
}

sub openai     { Langertha::Engine::OpenAI->new( api_key => 'k', @_ ) }
sub responses  { Langertha::Engine::OpenAIResponses->new( api_key => 'k', @_ ) }

# The two wires that share the gate. Both models are reasoning models that accept
# reasoning_effort=none (so the effort=none escape is exercisable on each).
my @wires = (
  { name => 'chat',      build => \&openai,    model => 'gpt-5.6-terra' },
  { name => 'responses', build => \&responses, model => 'gpt-5.5-pro'   },
);

for my $w (@wires) {
  my ( $name, $build, $model ) = ( $w->{name}, $w->{build}, $w->{model} );

  # 1) effort != none + temp != 1 -> dropped + carp. (matrix A/G)
  {
    my ( $b, $c ) = probe(
      $build->( model => $model, temperature => 0.7, reasoning_effort => 'medium' ) );
    ok( !exists $b->{temperature},
      "$name: temperature dropped when reasoning is active (effort=medium)" );
    ok( $c, "$name: carp fired on the drop" );
  }

  # 2) effort = none + temp != 1 -> passed, silently. (matrix B, the control case)
  {
    my ( $b, $c ) = probe(
      $build->( model => $model, temperature => 0.7, reasoning_effort => 'none' ) );
    is( $b->{temperature}, 0.7,
      "$name: temperature kept when reasoning is disabled (effort=none)" );
    ok( !$c, "$name: no carp when temperature is kept" );
  }

  # 3) effort != none + temp = 1 -> passed, silently (temp=1 is the wire default,
  #    accepted even under active reasoning -- matrix F). No noise warning.
  {
    my ( $b, $c ) = probe(
      $build->( model => $model, temperature => 1, reasoning_effort => 'medium' ) );
    is( $b->{temperature}, 1,
      "$name: temperature=1 passes through even under active reasoning" );
    ok( !$c, "$name: no carp for temperature=1 (dropping the default is noise)" );
  }

  # 4) NO effort in the body + temp != 1 -> dropped + carp. THE actual bug
  #    (matrix E): the model's server-side default effort (medium) applies, so a
  #    gate that only saw an explicitly-set reasoning_effort would miss this.
  {
    my ( $b, $c ) = probe( $build->( model => $model, temperature => 0.7 ) );
    ok( !exists $b->{temperature},
      "$name: temperature dropped on the no-effort default path (model default reasoning applies)" );
    ok( $c, "$name: carp fired on the default-path drop" );
  }

  # 5) The per-request temperature control is gated too, not just the attribute.
  {
    my ( $b, $c ) = probe(
      $build->( model => $model, reasoning_effort => 'high' ),
      controls => { temperature => 0.2 } );
    ok( !exists $b->{temperature},
      "$name: per-request temperature control dropped under active reasoning" );
    ok( $c, "$name: carp fired for the per-request temperature control" );
  }

  # 6) The streaming request builder places the gate identically: dropped under
  #    active reasoning, kept when reasoning is disabled.
  {
    my ( $b_drop, $c_drop ) = probe_stream(
      $build->( model => $model, temperature => 0.7, reasoning_effort => 'medium' ) );
    ok( !exists $b_drop->{temperature},
      "$name (stream): temperature dropped under active reasoning" );
    ok( $c_drop, "$name (stream): carp fired on the drop" );

    my ( $b_keep ) = probe_stream(
      $build->( model => $model, temperature => 0.7, reasoning_effort => 'none' ) );
    is( $b_keep->{temperature}, 0.7,
      "$name (stream): temperature kept when reasoning is disabled" );
  }
}

# --- per-request effort beats the engine attribute (chat wire) ---------------
# The resolved effort is what the gate reads, so a per-request reasoning_effort
# control flips the outcome regardless of the engine attribute.
{
  my ( $b ) = probe(
    openai( model => 'gpt-5.6-terra', temperature => 0.7, reasoning_effort => 'medium' ),
    controls => { reasoning_effort => 'none' } );
  is( $b->{temperature}, 0.7,
    'per-request reasoning_effort=none beats engine attr medium -> temperature kept' );

  my ( $b2, $c2 ) = probe(
    openai( model => 'gpt-5.6-terra', temperature => 0.7, reasoning_effort => 'none' ),
    controls => { reasoning_effort => 'medium' } );
  ok( !exists $b2->{temperature},
    'per-request reasoning_effort=medium beats engine attr none -> temperature dropped' );
  ok( $c2, 'carp fired on the control-beats-attr drop' );
}

# --- the model list only marks which models HAVE reasoning -------------------
# Non-reasoning OpenAI models keep temperature even with a reasoning_effort set
# (the field is a no-op there); the gate never fires.
{
  my ( $b, $c ) = probe(
    openai( model => 'gpt-4o-mini', temperature => 0.7, reasoning_effort => 'high' ) );
  is( $b->{temperature}, 0.7, 'gpt-4o-mini: non-reasoning model keeps temperature' );
  ok( !$c, 'gpt-4o-mini: no carp (not a reasoning model)' );
}

# gpt-5-chat is the non-reasoning member of the gpt-5 line -> excluded from the
# gate (the (?!-chat) carve-out).
{
  my ( $b, $c ) = probe(
    openai( model => 'gpt-5-chat-latest', temperature => 0.7 ) );
  is( $b->{temperature}, 0.7,
    'gpt-5-chat-latest: excluded from the reasoning gate, keeps temperature' );
  ok( !$c, 'gpt-5-chat-latest: no carp' );
}

# o-series reasoning models are covered by the gate too.
{
  my ( $b, $c ) = probe( openai( model => 'o3', temperature => 0.5 ) );
  ok( !exists $b->{temperature},
    'o3: o-series reasoning model drops a non-default temperature (default effort)' );
  ok( $c, 'o3: carp fired' );
}

# --- gpt-6 cannot be disabled: effort=none is dropped server-side ------------
# gpt-6 does not accept reasoning_effort=none (Reasoning::Profile: its accepted
# levels are low..max). A caller passing 'none' gets it dropped and the default
# reasoning still applies, so temperature stays rejected. This is the read-only
# Profile consult (effort_accepted_on) doing its job -- distinct from gpt-5.x,
# where effort=none genuinely turns reasoning off.
{
  my ( $b, $c ) = probe(
    openai( model => 'gpt-6-astra', temperature => 0.7, reasoning_effort => 'none' ) );
  ok( !exists $b->{temperature},
    'gpt-6-astra: effort=none is not accepted, reasoning stays on -> temperature still dropped' );
  ok( $c, 'gpt-6-astra: carp fired (effort=none does not disable gpt-6 reasoning)' );
}

# --- k185: the no-effort default path is per-model, via Reasoning::Profile ----
# The model's server-side default effort decides the no-effort path. Most
# reasoning models default to a reasoning level (temperature dropped), but the
# gpt-5.1/5.2/5.4 line defaults to reasoning-OFF (reasoning_tokens=0 with no
# effort), so a non-default temperature is honored there. Live-verified
# 2026-09-19. Before k185 the no-effort branch returned 1 for every model matched
# by the reasoning-model regex, wrongly dropping temperature on 5.1/5.2/5.4.
#
# Sabotage check: make the no-effort branch of _temperature_rejected_by_reasoning
# return 1 unconditionally (the pre-k185 bug), or clear a profile's
# default_reasoning_off, and the "kept" assertions below flip to dropped.

# Default reasoning OFF -> temperature kept on the no-effort path, no carp.
for my $model (qw( gpt-5.1 gpt-5.1-codex-max gpt-5.2 gpt-5.4 )) {
  my ( $b, $c ) = probe( openai( model => $model, temperature => 0.7 ) );
  is( $b->{temperature}, 0.7,
    "$model: no-effort server default is reasoning-off, temperature kept" );
  ok( !$c, "$model: no carp (temperature honored on the default path)" );
}

# Default reasoning ON -> temperature dropped on the no-effort path, carp fires.
for my $model (qw( o4-mini gpt-5 gpt-5.5 gpt-5.6 gpt-6-astra )) {
  my ( $b, $c ) = probe( openai( model => $model, temperature => 0.7 ) );
  ok( !exists $b->{temperature},
    "$model: no-effort server default is reasoning-on, temperature dropped" );
  ok( $c, "$model: carp fired on the default-path drop" );
}

# A default-reasoning-off model still drops temperature once an explicit effort
# turns reasoning back on (matrix: gpt-5.1 + effort=low -> 400).
{
  my ( $b, $c ) = probe(
    openai( model => 'gpt-5.1', temperature => 0.7, reasoning_effort => 'low' ) );
  ok( !exists $b->{temperature},
    'gpt-5.1: explicit effort=low turns reasoning on -> temperature dropped' );
  ok( $c, 'gpt-5.1: carp fired for the explicit-effort drop' );
}

# effort=none on a default-reasoning-off model that accepts none keeps temperature.
{
  my ( $b, $c ) = probe(
    openai( model => 'gpt-5.1', temperature => 0.7, reasoning_effort => 'none' ) );
  is( $b->{temperature}, 0.7,
    'gpt-5.1: effort=none (accepted) keeps temperature' );
  ok( !$c, 'gpt-5.1: no carp when reasoning is disabled via effort=none' );
}

done_testing;
