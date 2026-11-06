#!/usr/bin/env perl
# ABSTRACT: thinking_enabled across engines, layers and wires -- the k382 review-fix coverage

use strict;
use warnings;

use Test2::Bundle::More;
use JSON::MaybeXS;
use JSON::PP ();

use lib 't/lib';
use Test::MockAsyncHTTP;

use Langertha::Reasoning;
use Langertha::Engine::LlamaCpp;
use Langertha::Engine::OpenAI;
use Langertha::Engine::Gemini;
use Langertha::Engine::DeepSeek;
use Langertha::Engine::Ollama;

# karr k382 (review fixes): the tri-state thinking_enabled switch is one concern
# with reasoning_effort, resolved per layer (a per-request value for either
# replaces both engine attributes; only a same-layer contradiction croaks, at
# the engine constructor or at request build). Where a wire has no form for it
# the switch is dropped with a carp, once per engine, never a croak: Gemini 2.5
# takes a budget (no off switch beside one), DeepSeek V4 and Ollama GPT-OSS have
# no level-free on-switch. DeepSeek V3.x spells it thinking.type, llama.cpp as a
# real-boolean chat_template_kwargs.enable_thinking, OpenAI's ADR 0025
# temperature gate reads an off switch as effort none. It is a canonical chat_f
# control and must never reach the wire raw. Wire shapes of the non-llama.cpp
# engines are documentation-derived (advisor), not live-verified.

my $json = JSON::MaybeXS->new->canonical(1)->utf8(1);

sub raw {
  my ( $engine, $builder, %extra ) = @_;
  return $engine->$builder( $engine->chat_messages('hi'), %extra )->content;
}

# ( decoded body, number of carps, raw text ) for one request build
sub probe {
  my ( $engine, $builder, %extra ) = @_;
  my @warns;
  local $SIG{__WARN__} = sub { push @warns, $_[0] };
  my $text = raw( $engine, $builder, %extra );
  return ( $json->decode($text), scalar(@warns), $text );
}

sub llama    { Langertha::Engine::LlamaCpp->new( url => 'http://localhost:1/v1', @_ ) }
sub openai   { Langertha::Engine::OpenAI->new( api_key => 'k', url => 'http://localhost:1/v1', @_ ) }
sub gem25    { Langertha::Engine::Gemini->new( api_key => 'k', model => 'gemini-2.5-flash', @_ ) }
sub deepseek { Langertha::Engine::DeepSeek->new( api_key => 'k', @_ ) }
sub ollama   { Langertha::Engine::Ollama->new( url => 'http://localhost:1', @_ ) }

# --- 1. Gemini 2.5: a budget layer plus a per-request off switch ---
{
  my ( $b, $carps, $text ) = probe( gem25( thinking_budget => 512 ), 'chat_request',
    controls => { thinking_enabled => 0 } );
  like( $text, qr/"thinkingBudget":512/, 'Gemini 2.5 budget 512 + per-request thinking_enabled 0: budget still sent' );
  is( $carps, 1, '... with a carp, and no croak' );
}

# --- 2. Gemini 2.5: engine off switch alone ---
{
  my $e = gem25( thinking_enabled => 0 );
  my @warns;
  local $SIG{__WARN__} = sub { push @warns, $_[0] };
  my $one = raw( $e, 'chat_request' );
  my $two = raw( $e, 'chat_request' );
  unlike( $one . $two, qr/thinking/i, 'Gemini 2.5 engine thinking_enabled 0 alone: nothing reasoning-related sent' );
  is( scalar(@warns), 1, '... exactly one carp across two requests' );
}

# --- 3. DeepSeek V3.2: thinking.type ---
{
  my $model = 'deepseek-v3.2';
  my @cases = (
    [ 'effort none',        { reasoning_effort => 'none' }, 'disabled' ],
    [ 'thinking_enabled 0', { thinking_enabled => 0 },      'disabled' ],
    [ 'thinking_enabled 1', { thinking_enabled => 1 },      'enabled'  ],
    [ 'effort high',        { reasoning_effort => 'high' }, 'enabled'  ],
  );
  for my $case (@cases) {
    my ( $label, $attrs, $type ) = @$case;
    my ($b) = probe( deepseek( model => $model, %$attrs ), 'chat_request' );
    is_deeply( $b->{thinking}, { type => $type }, "DeepSeek $model $label: thinking.type $type" );
    my ($c) = probe( deepseek( model => $model ), 'chat_request', controls => $attrs );
    is_deeply( $c->{thinking}, { type => $type }, "DeepSeek $model per-request $label: thinking.type $type" );
  }
}

# --- 4. DeepSeek V4 ---
{
  my ($off) = probe( deepseek( thinking_enabled => 0 ), 'chat_request' );
  is( $off->{reasoning_effort}, 'none', 'DeepSeek V4 thinking_enabled 0: reasoning_effort none' );
  ok( !exists $off->{thinking}, '... and no thinking object' );
  my ( $on, $carps ) = probe( deepseek( thinking_enabled => 1 ), 'chat_request' );
  ok( !exists $on->{reasoning_effort} && !exists $on->{thinking}, 'DeepSeek V4 thinking_enabled 1: nothing sent' );
  is( $carps, 1, '... with one carp' );
}

# --- 4b. DeepSeek: a same-layer contradiction croaks, a cross-layer one does not ---
for my $model (qw( deepseek-flash deepseek-v3.2 )) {
  my $contradiction = qr/thinking_enabled => [01] contradicts effort '\w+'/;
  for my $pair ( { reasoning_effort => 'high', thinking_enabled => 0 },
                 { reasoning_effort => 'none', thinking_enabled => 1 } ) {
    my $label = "$model per-request effort $pair->{reasoning_effort} + thinking_enabled $pair->{thinking_enabled}";
    my $ok = eval { raw( deepseek( model => $model ), 'chat_request', controls => $pair ); 1 };
    ok( !$ok, "DeepSeek $label: croaks" );
    like( $@, $contradiction, '... naming the contradiction' );
  }
  my ( $b, $carps ) = probe( deepseek( model => $model, reasoning_effort => 'high' ), 'chat_request',
    controls => { thinking_enabled => 0 } );
  my $off = $model eq 'deepseek-v3.2'
    ? ( ( $b->{thinking} // {} )->{type} // '' ) eq 'disabled'
    : ( $b->{reasoning_effort} // '' ) eq 'none';
  ok( $off, "DeepSeek $model engine high + per-request thinking_enabled 0: no croak, thinking off" );
}
ok( !eval { deepseek( reasoning_effort => 'high', thinking_enabled => 0 ); 1 },
  'DeepSeek new: reasoning_effort high + thinking_enabled 0 croaks at construction' );
like( $@, qr/contradicts effort/, '... naming the contradiction' );

# --- 4c. Anthropic: constructor contradictions (list-form args; the HashRef form
#         hits the unrelated Role::Langfuse BUILDARGS bug, card k387) ---
{
  require Langertha::Engine::Anthropic;
  my $contradiction = qr/thinking_enabled => [01] contradicts effort '\w+'/;
  for my $pair ( [ high => 0 ], [ none => 1 ] ) {
    my ( $effort, $switch ) = @$pair;
    ok( !eval { Langertha::Engine::Anthropic->new( api_key => 'k', effort => $effort, thinking_enabled => $switch ); 1 },
      "Anthropic new: effort $effort + thinking_enabled $switch croaks" );
    like( $@, $contradiction, '... naming the contradiction' );
  }
  for my $pair ( [ high => 1 ], [ none => 0 ] ) {
    my ( $effort, $switch ) = @$pair;
    ok( eval { Langertha::Engine::Anthropic->new( api_key => 'k', effort => $effort, thinking_enabled => $switch ); 1 },
      "Anthropic new: effort $effort + thinking_enabled $switch constructs" );
  }
}

# --- 5. undef per-request values keep the engine's ---
{
  my ($b) = probe( llama( reasoning_effort => 'high' ), 'chat_request',
    controls => { reasoning_effort => undef, effort => undef, thinking_enabled => undef } );
  is( $b->{reasoning_effort}, 'high', 'undef per-request controls: engine effort high stays' );
  is_deeply( $b->{chat_template_kwargs}, { enable_thinking => JSON::PP::true }, '... and thinking stays on' );
  my ($c) = probe( llama( thinking_enabled => 0 ), 'chat_request',
    controls => { thinking_enabled => undef } );
  is_deeply( $c->{chat_template_kwargs}, { enable_thinking => JSON::PP::false }, 'undef thinking_enabled keeps the engine off switch' );
}

# --- 6. constructor contradictions croak at new ---
for my $case ( [ LlamaCpp => \&llama ], [ OpenAI => \&openai ] ) {
  my ( $name, $make ) = @$case;
  ok( !eval { $make->( thinking_enabled => 1, reasoning_effort => 'none' ); 1 }, "$name new: thinking_enabled 1 + effort none croaks" );
  ok( !eval { $make->( thinking_enabled => 0, reasoning_effort => 'low' ); 1 }, "$name new: thinking_enabled 0 + effort low croaks" );
  ok( eval { $make->( thinking_enabled => 0, reasoning_effort => 'none' ); 1 }, "$name new: 0 + none is fine" );
}

# --- 7. Ollama native, per-request controls ---
for my $builder (qw( chat_request chat_stream_request )) {
  my $q = ollama( model => 'qwen3:8b' );
  my ($off) = probe( $q, $builder, controls => { thinking_enabled => 0 } );
  ok( JSON::PP::is_bool( $off->{think} ) && !$off->{think}, "qwen3 $builder thinking_enabled 0: think false" );
  my ($on) = probe( $q, $builder, controls => { thinking_enabled => 1 } );
  ok( JSON::PP::is_bool( $on->{think} ) && $on->{think}, "qwen3 $builder thinking_enabled 1: think true" );

  my $g = ollama( model => 'gpt-oss:20b' );
  my ($goff) = probe( $g, $builder, controls => { thinking_enabled => 0 } );
  is( $goff->{think}, 'low', "gpt-oss $builder thinking_enabled 0: think \"low\" (the floor)" );
  my ( $gon, $carps ) = probe( ollama( model => 'gpt-oss:20b' ), $builder, controls => { thinking_enabled => 1 } );
  ok( !exists $gon->{think}, "gpt-oss $builder thinking_enabled 1: no think" );
  is( $carps, 1, '... and one carp' );

  ok( !eval { raw( $q, $builder, controls => { thinking_enabled => 0, reasoning_effort => 'low' } ); 1 },
    "Ollama $builder: contradicting pair croaks" );
}

# --- 8. caller chat_template_kwargs edge values ---
{
  my ( $b, undef, $text ) = probe( llama( reasoning_effort => 'none' ), 'chat_request', chat_template_kwargs => undef );
  is_deeply( $b->{chat_template_kwargs}, { enable_thinking => JSON::PP::false }, 'caller undef: ours is sent' );
  unlike( $text, qr/"chat_template_kwargs":null/, '... never null' );
  my ($s) = probe( llama( reasoning_effort => 'none' ), 'chat_request', chat_template_kwargs => 'custom' );
  is( $s->{chat_template_kwargs}, 'custom', 'caller string value replaces ours whole' );
}

# --- 9. Reasoning on a budget model ---
{
  my $r = eval { Langertha::Reasoning->new( model => 'gemini-2.5-pro', thinking_enabled => 0 ) };
  ok( $r, 'gemini-2.5-pro thinking_enabled 0 constructs' );
  ok( !$r->has_effort, '... with no effort' );
  ok( $r->drops_thinking_enabled_on('gemini'), '... drops on gemini' );
  ok( !$r->drops_thinking_enabled_on('chat_template_kwargs'), '... but not on chat_template_kwargs' );
}

# --- (a) carp exactly once over three requests ---
{
  my $e = openai( thinking_enabled => 1 );
  my @warns;
  local $SIG{__WARN__} = sub { push @warns, $_[0] };
  raw( $e, 'chat_request' ) for 1 .. 3;
  is( scalar(@warns), 1, 'thinking_enabled 1 on a plain OpenAI engine: exactly one carp over three requests' );
}

# --- (b) end to end through chat_f: a canonical control, never raw on the wire ---
{
  my $mock = Test::MockAsyncHTTP->new( responses => [
    Test::MockAsyncHTTP->mock_json_response({
      model   => 'default',
      choices => [ { index => 0, finish_reason => 'stop', message => { role => 'assistant', content => 'ok' } } ],
    }),
  ] );
  my $engine = llama( reasoning_effort => 'high', _async_http => $mock );
  my $response = $engine->chat_f( messages => ['hi'], thinking_enabled => 0 )->get;
  is( $response->content, 'ok', 'chat_f returns the response' );
  my ($request) = $mock->requests;
  my $body = $json->decode( $request->content );
  is_deeply( $body->{chat_template_kwargs}, { enable_thinking => JSON::PP::false }, 'chat_f: engine high + thinking_enabled 0 control: thinking off' );
  ok( !exists $body->{reasoning_effort}, '... no reasoning_effort' );
  ok( !exists $body->{thinking_enabled}, '... thinking_enabled not raw on the wire' );
  ok( !exists $body->{controls}, '... controls hash never reaches the wire' );
}

# --- (c) OpenAI temperature gate: the off switch is effort none ---
{
  my @warns;
  local $SIG{__WARN__} = sub { push @warns, $_[0] };
  my ($engine_off) = probe( openai( model => 'gpt-5.5', temperature => 0.7, thinking_enabled => 0 ), 'chat_request' );
  is( $engine_off->{temperature}, 0.7, 'gpt-5.5 engine thinking_enabled 0: temperature kept (like effort none)' );
  my ($ctrl_off) = probe( openai( model => 'gpt-5.5', temperature => 0.7 ), 'chat_request',
    controls => { thinking_enabled => 0 } );
  is( $ctrl_off->{temperature}, 0.7, 'gpt-5.5 per-request thinking_enabled 0: temperature kept' );
  ok( !grep( { /dropping temperature/ } @warns ), '... no temperature carp' );
  my ($default) = probe( openai( model => 'gpt-5.5', temperature => 0.7 ), 'chat_request' );
  ok( !exists $default->{temperature}, 'gpt-5.5 with no reasoning control: temperature still dropped (discriminates)' );
}

done_testing;
