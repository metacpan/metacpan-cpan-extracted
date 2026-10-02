#!/usr/bin/env perl
# ABSTRACT: k133/k135 Anthropic wire drift — model-scoped temperature + forced-tool
#           corrections, thinking.display, native structured-output routing.

# k133: native structured output (output_config.format, exercised in
# t/77_response_format_*) plus the per-model correction that clears the
# forced-tool caps on Fable/Mythos 5.1 so chat_f auto-routes a forced named tool
# through the native path instead of a tool_choice the model 400s on.
# k135: temperature is deprecated on the Messages API and 400s on a growing set
# of models (Opus 4.7+ and the 5-series); and thinking.display now defaults to
# "omitted", leaving $response->thinking empty unless the caller asks for
# "summarized" via the new thinking_display knob.
#
# Every assertion below is sabotage-verifiable: the model_capability_corrections
# table on Engine::Anthropic, the supports('temperature') gate in
# AnthropicCompatible, and the thinking_display serializer in
# Langertha::Reasoning each have a comment saying which assertions go red when
# they are reverted.

use strict;
use warnings;

use Test2::Bundle::More;
use JSON::MaybeXS;

use Langertha::Engine::Anthropic;

my $json = JSON::MaybeXS->new->canonical(1)->utf8(1);

sub engine {
  return Langertha::Engine::Anthropic->new(
    api_key => 'k', response_size => 128, @_,
  );
}

sub body {
  my ( $model, %extra ) = @_;
  my $e = engine( model => $model );
  return $json->decode( $e->chat_request( $e->chat_messages('p'), %extra )->content );
}

# ( $result, \@carps ) for $code: the "dropping temperature" carps it raised
# are collected (the drop is loud, ADR 0025 k214 Update), anything else is
# passed on.
sub with_temperature_drops {
  my ($code) = @_;
  my @drops;
  local $SIG{__WARN__} = sub {
    return push @drops, $_[0] if $_[0] =~ /dropping temperature/;
    warn @_;
  };
  my $result = $code->();
  return ( $result, \@drops );
}

# ---------------------------------------------------------------------------
# k135 point 1: temperature capability is per-MODEL.
#   The verified 400-set (broader than the ticket's Opus 4.7/4.8): Opus 4.7,
#   Opus 4.8, Opus 5, Sonnet 5, Fable 5(.1), Mythos 5(.1). Still allowed on
#   Opus 4.6 / Sonnet 4.6 / Haiku 4.5 and the retired 3.5 line.
# Sabotage: drop a qr// temperature row from model_capability_corrections and
#   its `ok !supports` below flips to true.
# ---------------------------------------------------------------------------
for my $m (qw(
  claude-opus-4-7 claude-opus-4-8 claude-opus-4-8-20260514 claude-opus-5
  claude-sonnet-5 claude-fable-5 claude-fable-5-1 claude-mythos-5 claude-mythos-5-1
)) {
  ok !engine( model => $m )->supports('temperature'),
    "temperature capability cleared for $m (Messages API 400s on non-default)";
}

for my $m (qw(
  claude-opus-4-6 claude-sonnet-4-6 claude-haiku-4-5 claude-3-5-sonnet-20240620
)) {
  ok engine( model => $m )->supports('temperature'),
    "temperature capability kept for $m (still accepts sampling params)";
}

# The registry is genuinely model-scoped: two models of one engine disagree.
isnt !!engine( model => 'claude-opus-4-8' )->supports('temperature'),
     !!engine( model => 'claude-opus-4-6' )->supports('temperature'),
  'same engine, different model => different temperature capability';

# ---------------------------------------------------------------------------
# k135 point 1: the capability gate keeps temperature off the wire — from the
# engine attribute AND from a per-request control — for a model that rejects it,
# while a model that accepts it still emits it.
# Sabotage: remove the supports('temperature') guard in _temperature_kwargs and
#   temperature reappears on opus-4-8 here.
# ---------------------------------------------------------------------------
{
  my $suppressed = body( 'claude-opus-4-8', );
  # attribute path
  my $e = engine( model => 'claude-opus-4-8', temperature => 0.5 );
  my ( $attr, $attr_drops ) = with_temperature_drops( sub {
    $json->decode( $e->chat_request( $e->chat_messages('p') )->content ) } );
  ok !exists $attr->{temperature},
    'opus-4-8: engine-attribute temperature is suppressed on the wire';
  is scalar @$attr_drops, 1, 'opus-4-8: the attribute drop carps';
  like $attr_drops->[0],
    qr/\ALangertha::Engine::Anthropic: dropping temperature=0\.5 -- model 'claude-opus-4-8' does not take a temperature/,
    'opus-4-8: the carp names the engine, the value and the model';

  my ( $per_req, $per_req_drops ) = with_temperature_drops( sub {
    body( 'claude-opus-4-8', controls => { temperature => 0.9 } ) } );
  ok !exists $per_req->{temperature},
    'opus-4-8: per-request temperature control is suppressed too';
  is scalar @$per_req_drops, 1, 'opus-4-8: the per-request drop carps';
  like $per_req_drops->[0], qr/dropping temperature=0\.9 -- model 'claude-opus-4-8'/,
    'opus-4-8: the carp names the per-request value';

  my $kept = do {
    my $k = engine( model => 'claude-3-5-sonnet-20240620', temperature => 0.5 );
    $json->decode( $k->chat_request( $k->chat_messages('p') )->content );
  };
  is $kept->{temperature}, 0.5,
    'claude-3-5-sonnet: temperature still reaches the wire (allowed model)';
}

# ---------------------------------------------------------------------------
# k133 point 2: forced tool use (tool_choice `any` / named `tool`) 400s on
#   Fable 5.1 and Mythos 5.1 ONLY — their 5.0 siblings still allow it. The
#   correction clears tool_choice_named + tool_choice_any there; auto/none stay.
# Sabotage: drop the fable-5-1 / mythos-5-1 rows and these flip.
# ---------------------------------------------------------------------------
for my $m (qw( claude-fable-5-1 claude-mythos-5-1 )) {
  my $e = engine( model => $m );
  ok !$e->supports('tool_choice_named'), "$m clears tool_choice_named (forced tool 400s)";
  ok !$e->supports('tool_choice_any'),   "$m clears tool_choice_any (forced tool 400s)";
  ok  $e->supports('tool_choice_auto'),  "$m keeps tool_choice_auto";
  ok  $e->supports('tool_choice_none'),  "$m keeps tool_choice_none";
  # The keystone precondition: chat_f auto-routes a forced named tool through
  # response_format (native output_config.format) exactly when
  # !tool_choice_named && response_format_json_schema. Both hold here, so a
  # forced tool becomes native structured output instead of a 400.
  ok  $e->supports('response_format_json_schema'),
    "$m keeps response_format_json_schema (native structured-output route stays open)";
}

# The 5.0 siblings are unaffected — the correction is selective on the ".1".
for my $m (qw( claude-fable-5 claude-mythos-5 )) {
  my $e = engine( model => $m );
  ok $e->supports('tool_choice_named'), "$m keeps tool_choice_named (forced tool allowed)";
  ok $e->supports('tool_choice_any'),   "$m keeps tool_choice_any";
}

# ---------------------------------------------------------------------------
# k135 point 2: thinking.display. Default wire is "omitted" -> empty
#   $response->thinking; the thinking_display knob emits thinking.display so a
#   caller can ask for "summarized".
# Sabotage: remove the display branch in Langertha::Reasoning::to_anthropic and
#   the display assertions go red.
# ---------------------------------------------------------------------------
{
  # effort + display -> both fields present.
  my $d = body( 'claude-opus-4-8', controls => { reasoning_effort => 'high', thinking_display => 'summarized' } );
  is_deeply $d->{thinking}, { type => 'adaptive', display => 'summarized' },
    'opus-4-8: thinking_display emits thinking.display alongside type:adaptive';
  is $d->{output_config}{effort}, 'high', 'opus-4-8: effort still lands under output_config';

  # No display knob -> no display key (default, unchanged behaviour).
  my $plain = body( 'claude-opus-4-8', controls => { reasoning_effort => 'high' } );
  ok !exists $plain->{thinking}{display},
    'opus-4-8: no display key when thinking_display is unset (wire default omitted)';

  # display-only (no effort) still turns summaries on via a thinking block.
  my $only = do {
    my $e = engine( model => 'claude-opus-4-8', thinking_display => 'summarized' );
    $json->decode( $e->chat_request( $e->chat_messages('p') )->content );
  };
  is_deeply $only->{thinking}, { type => 'adaptive', display => 'summarized' },
    'opus-4-8: thinking_display alone emits an adaptive thinking block with display';
  ok !exists $only->{output_config},
    'opus-4-8: display-only request emits no output_config (no effort set)';

  # Fable-class models never carry a thinking block (type:disabled 400s), so
  # display cannot ride on one there — documented limitation.
  my $fable = body( 'claude-fable-5-1', controls => { reasoning_effort => 'high', thinking_display => 'summarized' } );
  ok !exists $fable->{thinking},
    'fable-5-1: no thinking block, so no display (fable-class always-on thinking)';
  is $fable->{output_config}{effort}, 'high',
    'fable-5-1: effort still lands under output_config';
}

done_testing;
