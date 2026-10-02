#!/usr/bin/env perl
# ABSTRACT: k214 Kimi fixes temperature server-side; a dropped caller temperature carps on both wire roles

use strict;
use warnings;

use Test2::Bundle::More;
use JSON::MaybeXS;

use Langertha::Engine::Moonshot;
use Langertha::Engine::MoonshotAnthropic;
use Langertha::Engine::Anthropic;

# karr k214 / ADR 0025 (k214 Update), ADR 0019: every current Kimi chat id fixes
# temperature server-side and answers any other value with HTTP 400
# ("invalid temperature: only 1 is allowed for this model"; kimi-k2.6 without
# thinking accepts only 0.6). The rejection does not depend on reasoning effort,
# so it is a static per-model clear on BOTH Moonshot faces, not ADR 0025's
# effort-aware predicate, and the value 1 is NOT safe to send (k2.6 non-thinking
# 400s on it) -- temperature never reaches the wire on a Kimi id. Advisor
# 2026-09-25, documentation + third-party error reports, not live-verified.
#
# The drop used to be silent, on Kimi and on Claude Opus 4.7+ (k138) alike. Both
# _temperature_kwargs gates now carp when a caller-set, non-default temperature
# is dropped because the model does not take it; temperature=1 is dropped
# without a carp (it is every such model's fixed/default value -- noise).

my $json = JSON::MaybeXS->new->canonical(1)->utf8(1);

# ( $decoded_body, $carped ) for $engine->$builder with the given controls.
sub probe {
  my ( $engine, $builder, %controls ) = @_;
  my @warns;
  local $SIG{__WARN__} = sub { push @warns, $_[0] };
  my $body = $json->decode( $engine->$builder(
    [ { role => 'user', content => 'hi' } ], controls => {%controls} )->content );
  my $carped = ( grep { /dropping temperature/ } @warns ) ? 1 : 0;
  return ( $body, $carped );
}

my @KIMI = qw( kimi-k3 kimi-k2.6 kimi-k2.7-code kimi-k2.7-code-highspeed kimi-k2-thinking );

for my $class (qw( Langertha::Engine::Moonshot Langertha::Engine::MoonshotAnthropic )) {
  ( my $face = $class ) =~ s/.*:://;
  for my $model (@KIMI) {
    my $label = "$face $model";
    ok( !$class->new( api_key => 'k', model => $model )->supports('temperature'),
      "$label: temperature capability cleared (fixed server-side)" );
    for my $builder (qw( chat_request chat_stream_request )) {
      # Attribute and per-request control alike; 1 is dropped too.
      for my $temp ( 0.7, 1, 0.6 ) {
        my ( $body, $carped ) = probe(
          $class->new( api_key => 'k', model => $model, temperature => $temp ), $builder );
        ok( !exists $body->{temperature}, "$label $builder: attribute temperature=$temp not sent" );
        is( $carped, $temp == 1 ? 0 : 1,
          "$label $builder: temperature=$temp " . ( $temp == 1 ? 'dropped silently' : 'drop carps' ) );
      }
      my ( $body, $carped ) = probe(
        $class->new( api_key => 'k', model => $model ), $builder, temperature => 0.7 );
      ok( !exists $body->{temperature}, "$label $builder: per-request temperature not sent" );
      ok( $carped, "$label $builder: per-request drop carps" );
    }
  }
  # (?!\d) guard: kimi-k30 is an unknown id and keeps the caller's temperature.
  my ( $body, $carped ) = probe(
    $class->new( api_key => 'k', model => 'kimi-k30', temperature => 0.7 ), 'chat_request' );
  is( $body->{temperature}, 0.7, "$face kimi-k30: unknown id keeps temperature" );
  ok( !$carped, "$face kimi-k30: no carp" );
}

# The carp lives in the shared Anthropic gate, so the silent Opus 4.7+ drop
# (k138 clear) now carps too; an accepting model keeps its value without one.
{
  my ( $body, $carped ) = probe(
    Langertha::Engine::Anthropic->new( api_key => 'k', model => 'claude-opus-4-8', temperature => 0.5 ),
    'chat_request' );
  ok( !exists $body->{temperature}, 'claude-opus-4-8: temperature still dropped' );
  ok( $carped, 'claude-opus-4-8: the drop now carps (was silent)' );

  ( $body, $carped ) = probe(
    Langertha::Engine::Anthropic->new( api_key => 'k', model => 'claude-opus-4-8', temperature => 1 ),
    'chat_request' );
  ok( !exists $body->{temperature} && !$carped, 'claude-opus-4-8: temperature=1 dropped without a carp' );

  ( $body, $carped ) = probe(
    Langertha::Engine::Anthropic->new( api_key => 'k', model => 'claude-opus-4-6', temperature => 0.5 ),
    'chat_request' );
  is( $body->{temperature}, 0.5, 'claude-opus-4-6: temperature kept' );
  ok( !$carped, 'claude-opus-4-6: no carp' );
}

# karr k220: the third wire role, Role::ResponsesCompatible, dropped a
# capability-cleared temperature silently (its supports() check ran before the
# carp). No engine on the responses wire clears temperature today, so the test
# engines clear it with a layer-3 row (ADR 0019) -- the same shape a future
# per-model clear on OpenAIResponses / XAI Responses / Perplexity would take.
# The three gates must stay at parity: same carp, same frequency (an engine
# attribute once per engine instance, a per-request value every request; karr
# k247), 1 quiet. The message names the remedy ("unset temperature to silence this").
{
  package Test::K220::Responses;
  use Moose;
  extends 'Langertha::Engine::OpenAIResponses';
  sub model_capability_corrections { ( 'cleared-model' => { temperature => 0 } ) }
  __PACKAGE__->meta->make_immutable;

  package Test::K220::Perplexity;
  use Moose;
  extends 'Langertha::Engine::Perplexity';
  sub model_capability_corrections { ( qr/\A/ => { temperature => 0 } ) }
  __PACKAGE__->meta->make_immutable;
}

for my $class (qw( Test::K220::Responses Test::K220::Perplexity )) {
  my @builders = $class->new( api_key => 'k' )->supports('streaming')
    ? qw( chat_request chat_stream_request ) : qw( chat_request );
  my $model = $class =~ /Perplexity/ ? 'sonar' : 'cleared-model';
  ok( !$class->new( api_key => 'k', model => $model )->supports('temperature'),
    "$class: temperature cleared by the test row" );
  for my $builder (@builders) {
    for my $temp ( 0.7, 1 ) {
      my ( $body, $carped ) = probe(
        $class->new( api_key => 'k', model => $model, temperature => $temp ), $builder );
      ok( !exists $body->{temperature}, "$class $builder: temperature=$temp not sent" );
      is( $carped, $temp == 1 ? 0 : 1,
        "$class $builder: temperature=$temp " . ( $temp == 1 ? 'dropped silently' : 'drop carps' ) );
    }
    my ( $body, $carped ) = probe(
      $class->new( api_key => 'k', model => $model ), $builder, temperature => 0.7 );
    ok( !exists $body->{temperature} && $carped, "$class $builder: per-request drop carps" );
  }
  # Same frequency as the other gates (karr k247): the engine attribute is the
  # same on every request, so it carps once per engine instance; a per-request
  # value carps on every request.
  my $engine = $class->new( api_key => 'k', model => $model, temperature => 0.7 );
  my ( undef, $first )  = probe( $engine, 'chat_request' );
  my ( undef, $second ) = probe( $engine, 'chat_request' );
  ok( $first && !$second, "$class: engine attribute carps once per engine" );
  $engine = $class->new( api_key => 'k', model => $model );
  ( undef, $first )  = probe( $engine, 'chat_request', temperature => 0.7 );
  ( undef, $second ) = probe( $engine, 'chat_request', temperature => 0.7 );
  ok( $first && $second, "$class: per-request value carps on every request" );
}

# Same message on all three wire roles, and it names the remedy (k220 polish).
{
  my @msgs;
  for my $engine (
    Langertha::Engine::Moonshot->new( api_key => 'k', model => 'kimi-k3', temperature => 0.7 ),
    Langertha::Engine::MoonshotAnthropic->new( api_key => 'k', model => 'kimi-k3', temperature => 0.7 ),
    Test::K220::Responses->new( api_key => 'k', model => 'cleared-model', temperature => 0.7 ),
  ) {
    my @warns;
    local $SIG{__WARN__} = sub { push @warns, $_[0] };
    $engine->chat_request( [ { role => 'user', content => 'hi' } ] );
    my ($w) = grep { /dropping temperature/ } @warns;
    ( my $text = $w // '' ) =~ s/\A\S+: //;    # strip the class name
    $text =~ s/ at \S+ line \d+\.?\n?\z//;
    $text =~ s/model '[^']*'/model 'M'/;
    push @msgs, $text;
  }
  like( $msgs[0], qr/unset temperature to silence this/, 'carp names the remedy' );
  is( $msgs[1], $msgs[0], 'Anthropic wire carps the same message as the OpenAI wire' );
  is( $msgs[2], $msgs[0], 'Responses wire carps the same message as the OpenAI wire' );
}

done_testing;
