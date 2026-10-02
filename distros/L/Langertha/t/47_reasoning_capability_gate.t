#!/usr/bin/env perl
# ABSTRACT: Reasoning emission follows the capability registry, byte-identically (karr #204)

use strict;
use warnings;

use Test2::Bundle::More;
use JSON::MaybeXS;
use Path::Tiny;
use Module::Runtime qw( require_module );

# karr #204 / ADR 0009 (k204 Update): "this engine takes no reasoning control"
# is stated once, in the capability registry, and Role::ReasoningEffort's
# reasoning_kwargs_for drops the whole concern when the engine advertises
# neither reasoning_effort nor thinking_budget. That retired the per-engine
# empty reasoning_kwargs_for stubs on MiniMax and Moonshot. The move must be
# a no-op on the wire: the golden table below was captured from the stub-based
# code before the change and pins every engine that composes the role, across
# representative models and every reasoning setting, as the canonical request
# body (or the croak it raised). Gemini 2.5 is the case that shaped the gate:
# it clears reasoning_effort per model yet still takes thinkingBudget, and its
# effort croak (ADR 0023) must stay loud rather than turn into a silent drop.
#
# Regenerate only for a reviewed, intended wire change:
#   LANGERTHA_REGEN_REASONING_GOLDEN=1 prove -l t/47_reasoning_capability_gate.t

my $canon  = JSON::MaybeXS->new->canonical(1)->utf8(1);
my $golden = path('t/data/reasoning_capability_gate_bodies.json');

# The foreign-engine rows with a bare MiniMax / Kimi id (vLLM MiniMax-M3 and
# kimi-k2.6, AKIAnthropic kimi-k2.7-code, OpenAIResponses MiniMax-M3) pin that
# the thinking-toggle Profile rows stay invisible off the engines that opt in
# (karr k209 review I1): one per reasoning wire the toggle serializes on, plus
# responses.
my %ENGINES = (
  AKIAnthropic      => [ undef, 'kimi-k2.7-code' ],
  AKIOpenAI         => [ undef ],
  Anthropic         => [ undef, 'claude-opus-4-8', 'claude-fable-5-1' ],
  Cerebras          => [ undef ],
  DeepSeek          => [ undef, 'deepseek-v4-pro', 'deepseek-v3.2' ],
  Gemini            => [ undef, 'gemini-2.5-flash', 'gemini-2.0-flash', 'gemini-3-pro-preview' ],
  Groq              => [ 'openai/gpt-oss-120b' ],
  Hetzner           => [ undef ],
  HuggingFace       => [ 'Qwen/Qwen3-32B' ],
  LlamaCpp          => [ undef ],
  LMStudioAnthropic => [ undef ],
  LMStudioOpenAI    => [ undef ],
  MiniMax           => [ undef, 'MiniMax-M2.7' ],
  MiniMaxAnthropic  => [ undef, 'MiniMax-M2.7' ],
  Mistral           => [ undef ],
  Moonshot          => [ undef, 'kimi-k2.6' ],
  MoonshotAnthropic => [ undef, 'kimi-k2.6', 'kimi-k2.7-code' ],
  NousResearch      => [ undef ],
  OllamaOpenAI      => [ 'qwen3' ],
  OpenAI            => [ undef, 'gpt-6-astra', 'gpt-5.5-pro', 'gpt-4o-mini' ],
  OpenAIResponses   => [ undef, 'gpt-5.5-pro', 'MiniMax-M3' ],
  OpenRouter        => [ 'openai/gpt-5.6' ],
  Perplexity        => [ undef ],
  Replicate         => [ 'meta/llama-3-8b' ],
  SGLang            => [ undef ],
  Scaleway          => [ undef ],
  TSystems          => [ undef ],
  VLLMHook          => [ undef ],
  XAI               => [ undef ],
  vLLM              => [ undef, 'MiniMax-M3', 'kimi-k2.6' ],
);

# name => [ constructor args, per-request controls ]
my %SETTINGS = (
  bare              => [ {}, {} ],
  ( map { ( "effort_$_" => [ { reasoning_effort => $_ }, {} ] ) }
      qw( none minimal low medium high xhigh max ) ),
  budget            => [ { thinking_budget => 1024 }, {} ],
  display           => [ { thinking_display => 'summarized' }, {} ],
  control_effort    => [ {}, { reasoning_effort => 'high' } ],
  control_budget    => [ {}, { thinking_budget => 2048 } ],
  control_beats_attr => [ { reasoning_effort => 'low' }, { reasoning_effort => 'high' } ],
);

sub outcome {
  my ( $code ) = @_;
  my $out = eval { $code->() };
  return $out if defined $out;
  my $err = "$@";
  $err =~ s/ at (?:constructor |\S+ line \d).*//s;
  return "CROAK: $err";
}

sub capture {
  my %got;
  for my $short ( sort keys %ENGINES ) {
    my $class = "Langertha::Engine::$short";
    require_module($class);
    for my $model ( @{ $ENGINES{$short} } ) {
      for my $setting ( sort keys %SETTINGS ) {
        my ( $attrs, $controls ) = @{ $SETTINGS{$setting} };
        my $key = join '|', $short, $model // 'default', $setting;
        my $engine;
        my $built = outcome( sub {
          $engine = $class->new(
            api_key => 'k', url => 'http://localhost:1/v1',
            ( defined $model ? ( model => $model ) : () ), %$attrs,
          );
          '';
        } );
        if ( length $built ) { $got{$key} = $built; next }
        for my $kind ( qw( chat_request chat_stream_request ) ) {
          next unless $engine->can($kind);
          $got{"$key|$kind"} = outcome( sub {
            my $req = $engine->$kind(
              [ { role => 'user', content => 'hi' } ], controls => {%$controls} );
            $canon->encode( $canon->decode( $req->content ) );
          } );
        }
      }
    }
  }
  return \%got;
}

my $got = capture();

if ( $ENV{LANGERTHA_REGEN_REASONING_GOLDEN} ) {
  $golden->spew_raw( JSON::MaybeXS->new->canonical(1)->pretty(1)->utf8(1)->encode($got) );
  diag "wrote " . scalar( keys %$got ) . " rows to $golden";
}

my $want = $canon->decode( $golden->slurp_raw );
is_deeply( [ sort keys %$got ], [ sort keys %$want ], 'the golden table covers the same engine x model x setting rows' );
for my $key ( sort keys %$want ) {
  is( $got->{$key}, $want->{$key}, "byte-identical: $key" );
}

# --- Intent, independent of the golden table ---

# The engines that clear reasoning_effort per model -- MiniMax's M2.x line
# (karr k209: only M3 takes the thinking toggle) and Moonshot's K2.x line
# (layer 3 since karr k207; kimi-k2.6 alone re-asserted as the toggle in k219,
# so kimi-k2.7-code is the cleared case) -- send no reasoning field, and no
# longer carry a stub to make that true.
for my $case ( [ 'MiniMax', 'MiniMax-M2.7' ], [ 'Moonshot', 'kimi-k2.7-code' ] ) {
  my ( $short, $model ) = @$case;
  my $class = "Langertha::Engine::$short";
  my $label = $short . ( $model ? " $model" : '' );
  my $engine = $class->new( api_key => 'k', reasoning_effort => 'high',
    ( $model ? ( model => $model ) : () ) );
  ok( !$engine->supports('reasoning_effort'), "$label does not advertise reasoning_effort" );
  is_deeply( [ $engine->reasoning_kwargs_for( reasoning_effort => 'max' ) ], [],
    "$label emits no reasoning kwargs (attribute + per-request control)" );
  is( $class->can('reasoning_kwargs_for'),
    Langertha::Role::ReasoningEffort->can('reasoning_kwargs_for'),
    "$label uses the role's reasoning_kwargs_for, not an engine stub" );
}

# The wire follows the flag, both ways: a subclass that re-asserts
# reasoning_effort on MiniMax emits it, and an OpenAI-dialect subclass that
# clears it stops emitting without writing a stub.
{
  package Test::K204::MiniMaxReasons;
  use Moose;
  extends 'Langertha::Engine::MiniMax';
  around engine_capabilities => sub {
    my ( $orig, $self, @rest ) = @_;
    return { %{ $self->$orig(@rest) }, reasoning_effort => 1 };
  };
  __PACKAGE__->meta->make_immutable;

  package Test::K204::OpenAINoReasoning;
  use Moose;
  extends 'Langertha::Engine::OpenAI';
  around engine_capabilities => sub {
    my ( $orig, $self, @rest ) = @_;
    my $caps = $self->$orig(@rest);
    delete $caps->{reasoning_effort};
    return $caps;
  };
  __PACKAGE__->meta->make_immutable;
}

# MiniMax-M2.7 is a thinking-toggle Profile row (karr k209), so the re-asserted
# flag reaches the wire as its thinking toggle.
is_deeply( [ Test::K204::MiniMaxReasons->new( api_key => 'k', model => 'MiniMax-M2.7',
    reasoning_effort => 'high' )->reasoning_kwargs_for ],
  [ thinking => { type => 'adaptive' } ],
  'a MiniMax subclass that advertises reasoning_effort emits it (no stub in the way)' );
is_deeply( [ Test::K204::OpenAINoReasoning->new( api_key => 'k', reasoning_effort => 'high' )->reasoning_kwargs_for ],
  [], 'an engine that clears reasoning_effort (and has no thinking_budget) stops emitting' );

# Gemini 2.5 clears reasoning_effort but advertises thinking_budget: the
# concern stays live, so the budget flows and effort keeps its loud croak.
my $g25 = Langertha::Engine::Gemini->new( api_key => 'k', model => 'gemini-2.5-flash' );
ok( !$g25->supports('reasoning_effort') && $g25->supports('thinking_budget'),
  'gemini-2.5: reasoning_effort cleared, thinking_budget advertised' );
is_deeply( [ $g25->reasoning_kwargs_for( thinking_budget => 1024 ) ],
  [ thinkingConfig => { thinkingBudget => 1024 } ], 'gemini-2.5: thinking_budget still reaches the wire' );
like( ( eval { $g25->reasoning_kwargs_for( reasoning_effort => 'high' ); 1 } ? '' : $@ ),
  qr/'effort' is not valid on Gemini 2\.5/, 'gemini-2.5: effort still croaks, not dropped silently' );

done_testing;
