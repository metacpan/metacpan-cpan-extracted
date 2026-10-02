#!/usr/bin/env perl
# ABSTRACT: MiniMax-M3 on chat/completions maps reasoning_effort onto its binary thinking toggle (karr k209)

use strict;
use warnings;

use Test2::Bundle::More;
use JSON::MaybeXS;

use Langertha::Engine::MiniMax;
use Langertha::Engine::MiniMaxAnthropic;
use Langertha::Reasoning::Profile;
use Langertha::Role::ReasoningEffort;

# karr k209 part 1 / ADRs 0023, 0019 (k209 Updates): MiniMax-M3 on
# /v1/chat/completions takes thinking:{type: disabled|adaptive} (default
# adaptive) and no effort field. Engine::MiniMax cleared reasoning_effort
# engine-wide, so reasoning_effort => 'none' could not turn thinking off. The
# mapping is MiniMax's own (its /v1/responses reasoning.effort): none -> off,
# any other level -> adaptive; the level ladder collapses to a binary, every
# level gives the same depth. M2.x cannot turn thinking off ("disabled is
# accepted but thinking remains on"), so reasoning_effort stays cleared there.
# The per-model truth is a thinking-toggle Reasoning::Profile row, serialized by
# Langertha::Reasoning; MiniMax needs no engine reasoning_kwargs_for override, so
# the role's k204 gate stays in force. Advisor 2026-09-25, from MiniMax's
# documentation (openapi-chat-openai.json), not live-verified.

my $json = JSON::MaybeXS->new->canonical(1);
my @LEVELS = qw( minimal low medium high xhigh max );

sub body {
  my ( $class, $builder, %args ) = @_;
  my $controls = delete $args{controls} // {};
  my $engine = $class->new( api_key => 'k', %args );
  return $json->decode( $engine->$builder(
    [ { role => 'user', content => 'hi' } ], controls => $controls )->content );
}

# --- MiniMax-M3 on chat/completions ---
my $m3 = Langertha::Engine::MiniMax->new( api_key => 'k' );
is( $m3->chat_model, 'MiniMax-M3', 'MiniMax default model is M3' );
ok( $m3->supports('reasoning_effort'), 'MiniMax-M3 advertises reasoning_effort (layer 3 re-enables it)' );
for my $builder (qw( chat_request chat_stream_request )) {
  my $off = body( 'Langertha::Engine::MiniMax', $builder, reasoning_effort => 'none' );
  is_deeply( $off->{thinking}, { type => 'disabled' }, "M3 $builder 'none': thinking disabled" );
  ok( !exists $off->{reasoning_effort}, "M3 $builder 'none': no reasoning_effort field" );
  for my $effort (@LEVELS) {
    my $on = body( 'Langertha::Engine::MiniMax', $builder, reasoning_effort => $effort );
    is_deeply( $on->{thinking}, { type => 'adaptive' }, "M3 $builder '$effort': thinking adaptive" );
    ok( !exists $on->{reasoning_effort}, "M3 $builder '$effort': no reasoning_effort field" );
  }
  ok( !exists body( 'Langertha::Engine::MiniMax', $builder )->{thinking},
    "M3 $builder: no reasoning control, no thinking field (server default)" );
}
is_deeply( body( 'Langertha::Engine::MiniMax', 'chat_request',
    reasoning_effort => 'high', controls => { reasoning_effort => 'none' } )->{thinking},
  { type => 'disabled' }, 'M3: a per-request control beats the attribute' );

# --- M2.x and unknown ids stay cleared ---
for my $model (qw( MiniMax-M2.7 MiniMax-M2.5-highspeed MiniMax-M2 MiniMax-M30 MiniMax-M4 )) {
  my $engine = Langertha::Engine::MiniMax->new( api_key => 'k', model => $model );
  ok( !$engine->supports('reasoning_effort'), "MiniMax $model: reasoning_effort cleared" );
  my $got = body( 'Langertha::Engine::MiniMax', 'chat_request', model => $model, reasoning_effort => 'none' );
  ok( !exists $got->{thinking} && !exists $got->{reasoning_effort}, "MiniMax $model: no reasoning field" );
}

# The catch-all clear holds without a model id too (review M8): an empty
# chat_model is matched as '' and must not fall back to the role default.
{
  my $engine = Langertha::Engine::MiniMax->new( api_key => 'k', model => '' );
  ok( !$engine->supports('reasoning_effort'), "MiniMax model '': reasoning_effort cleared" );
  my $got = body( 'Langertha::Engine::MiniMax', 'chat_request', model => '', reasoning_effort => 'high' );
  ok( !exists $got->{thinking} && !exists $got->{reasoning_effort}, "MiniMax model '': no reasoning field" );
}

# --- the k204 gate is the role's, not an engine override ---
is( Langertha::Engine::MiniMax->can('reasoning_kwargs_for'),
  Langertha::Role::ReasoningEffort->can('reasoning_kwargs_for'),
  'MiniMax uses the role reasoning_kwargs_for (k204 gate intact)' );
{
  package Test::K209::MiniMaxNoReasoning;
  use Moose;
  extends 'Langertha::Engine::MiniMax';
  sub model_capability_corrections { () }
  around engine_capabilities => sub {
    my ( $orig, $self, @rest ) = @_;
    my $caps = $self->$orig(@rest);
    delete $caps->{reasoning_effort};
    return $caps;
  };
  __PACKAGE__->meta->make_immutable;
}
is_deeply( [ Test::K209::MiniMaxNoReasoning->new( api_key => 'k', reasoning_effort => 'none' )
    ->reasoning_kwargs_for ], [], 'M3 with reasoning_effort cleared sends no thinking toggle' );

# --- MiniMaxAnthropic reads the same rows: explicit off on M3 ---
is_deeply( body( 'Langertha::Engine::MiniMaxAnthropic', 'chat_request', reasoning_effort => 'none' )->{thinking},
  { type => 'disabled' }, 'MiniMaxAnthropic M3 none: explicit thinking disabled' );
is_deeply( body( 'Langertha::Engine::MiniMaxAnthropic', 'chat_request', reasoning_effort => 'minimal' )->{thinking},
  { type => 'adaptive' }, 'MiniMaxAnthropic M3 minimal: adaptive (any level turns thinking on)' );
ok( !exists body( 'Langertha::Engine::MiniMaxAnthropic', 'chat_request',
    model => 'MiniMax-M2.7', reasoning_effort => 'none' )->{thinking},
  'MiniMaxAnthropic M2.7 none: cannot disable, field omitted' );

# --- the Profile rows ---
my $p3 = Langertha::Reasoning::Profile->for_model('MiniMax-M3');
is( $p3->control, 'boolean', 'M3 profile: boolean control' );
ok( $p3->can_disable, 'M3 profile: can disable' );
is( $p3->disable_form, 'thinking_disabled', 'M3 profile: off is thinking {type: disabled}' );
is( $p3->thinking_on, 'adaptive', 'M3 profile: on is thinking {type: adaptive}' );
my $p2 = Langertha::Reasoning::Profile->for_model('MiniMax-M2.7');
is( $p2->control, 'boolean', 'M2.7 profile: boolean control' );
ok( !$p2->can_disable, 'M2.7 profile: cannot disable' );
ok( !Langertha::Reasoning::Profile->for_model('MiniMax-M30')->has_thinking_on,
  'MiniMax-M30: unknown id, no toggle row' );

done_testing;
