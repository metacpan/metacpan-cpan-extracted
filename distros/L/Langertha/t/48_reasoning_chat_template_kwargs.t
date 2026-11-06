#!/usr/bin/env perl
# ABSTRACT: reasoning_effort / thinking_enabled map onto chat_template_kwargs.enable_thinking (karr k382)

use strict;
use warnings;

use Test2::Bundle::More;
use JSON::MaybeXS;
use JSON::PP ();

use Langertha::Reasoning;
use Langertha::Engine::LlamaCpp;
use Langertha::Engine::SGLang;
use Langertha::Engine::vLLM;
use Langertha::Engine::OpenAI;

# karr k382 / ADR 0004: llama.cpp, SGLang and generic OpenAI-compatible servers
# switch thinking on and off only through the top-level chat_template_kwargs
# {enable_thinking: bool} request field, not through reasoning_effort alone.
# Without a modelled path callers had no way to reach it (ADR 0004 forbids an
# extra_body side-channel). The new reasoning_wire_format tag
# `chat_template_kwargs` serializes effort `none` to enable_thinking=false (and
# no reasoning_effort), any other level to enable_thinking=true plus the
# top-level reasoning_effort; the tri-state `thinking_enabled` toggle reaches
# the same field without an effort level. enable_thinking must be a REAL JSON
# boolean: the servers' Jinja templates test its truthiness and the string
# "false" is truthy. vLLM keeps its server-side mapping (unchanged). Advisor
# verdict: contradictions croak only within one layer; a caller-supplied
# chat_template_kwargs is merged, caller keys win.

my $json = JSON::MaybeXS->new->canonical(1)->utf8(1);
my $TAG  = 'chat_template_kwargs';

sub raw_request {
  my ( $engine, $builder, %extra ) = @_;
  return $engine->$builder( [ { role => 'user', content => 'hi' } ], %extra )->content;
}

sub body {
  my ( $engine, $builder, %extra ) = @_;
  return $json->decode( raw_request( $engine, $builder, %extra ) );
}

sub llama  { Langertha::Engine::LlamaCpp->new( url => 'http://localhost:1/v1', @_ ) }
sub sglang { Langertha::Engine::SGLang->new( url => 'http://localhost:1/v1', @_ ) }
sub vllm   { Langertha::Engine::vLLM->new( url => 'http://localhost:1/v1', @_ ) }
sub openai { Langertha::Engine::OpenAI->new( url => 'http://localhost:1/v1', api_key => 'k', @_ ) }

sub capture_warnings {
  my ($code) = @_;
  my @warnings;
  local $SIG{__WARN__} = sub { push @warnings, @_ };
  $code->();
  return @warnings;
}

# --- the value object serializer ---
{
  my %kw = Langertha::Reasoning->new( effort => 'none' )->to($TAG);
  is_deeply( [ sort keys %kw ], ['chat_template_kwargs'], 'none: only chat_template_kwargs (no reasoning_effort)' );
  is( $json->encode( \%kw ), '{"chat_template_kwargs":{"enable_thinking":false}}', 'none: enable_thinking is a JSON false' );

  for my $effort (qw( low medium high xhigh )) {
    my %on = Langertha::Reasoning->new( effort => $effort )->to($TAG);
    is( $json->encode( \%on ),
      qq({"chat_template_kwargs":{"enable_thinking":true},"reasoning_effort":"$effort"}),
      "$effort: enable_thinking true + reasoning_effort sent unclamped" );
  }

  is( $json->encode( { Langertha::Reasoning->new( thinking_enabled => 0 )->to($TAG) } ),
    '{"chat_template_kwargs":{"enable_thinking":false}}', 'thinking_enabled 0 alone: enable_thinking false, no effort' );
  is( $json->encode( { Langertha::Reasoning->new( thinking_enabled => 1 )->to($TAG) } ),
    '{"chat_template_kwargs":{"enable_thinking":true}}', 'thinking_enabled 1 alone: enable_thinking true, no effort' );
  is_deeply( { Langertha::Reasoning->new->to($TAG) }, {}, 'nothing set: nothing emitted' );

  is( $json->encode( { Langertha::Reasoning->new( effort => 'none',  thinking_enabled => 0 )->to($TAG) } ),
    '{"chat_template_kwargs":{"enable_thinking":false}}', 'consistent 0 + none is fine' );
  is( $json->encode( { Langertha::Reasoning->new( effort => 'high', thinking_enabled => 1 )->to($TAG) } ),
    '{"chat_template_kwargs":{"enable_thinking":true},"reasoning_effort":"high"}', 'consistent 1 + high is fine' );

  ok( !eval { Langertha::Reasoning->new( effort => 'low', thinking_enabled => 0 ); 1 },
    'same layer: thinking_enabled 0 with effort low croaks' );
  ok( !eval { Langertha::Reasoning->new( effort => 'none', thinking_enabled => 1 ); 1 },
    'same layer: thinking_enabled 1 with effort none croaks' );
}

# --- engine defaults and the real-boolean wire ---
for my $case ( [ LlamaCpp => \&llama ], [ SGLang => \&sglang ] ) {
  my ( $name, $make ) = @$case;
  is( $make->()->reasoning_wire_format, $TAG, "$name defaults to reasoning_wire_format $TAG" );
  for my $builder (qw( chat_request chat_stream_request )) {
    my $raw = raw_request( $make->( reasoning_effort => 'none' ), $builder );
    like( $raw, qr/"chat_template_kwargs":\{"enable_thinking":false\}/, "$name $builder none: JSON false in the raw body" );
    my $off = $json->decode($raw);
    ok( JSON::PP::is_bool( $off->{chat_template_kwargs}{enable_thinking} ), "$name $builder none: decoded value is a boolean" );
    ok( !exists $off->{reasoning_effort}, "$name $builder none: no reasoning_effort" );

    my $on_raw = raw_request( $make->( reasoning_effort => 'high' ), $builder );
    like( $on_raw, qr/"enable_thinking":true/, "$name $builder high: JSON true in the raw body" );
    my $on = $json->decode($on_raw);
    ok( JSON::PP::is_bool( $on->{chat_template_kwargs}{enable_thinking} ), "$name $builder high: decoded value is a boolean" );
    is( $on->{reasoning_effort}, 'high', "$name $builder high: top-level reasoning_effort sent" );

    my $none = body( $make->(), $builder );
    ok( !exists $none->{chat_template_kwargs} && !exists $none->{reasoning_effort},
      "$name $builder: nothing set sends nothing" );

    my $tog = $make->( thinking_enabled => 0 );
    ok( $tog->has_thinking_enabled, "$name has_thinking_enabled true once set" );
    my $t = body( $tog, $builder );
    like( raw_request( $tog, $builder ), qr/"enable_thinking":false/, "$name $builder thinking_enabled 0: JSON false" );
    ok( !exists $t->{reasoning_effort}, "$name $builder thinking_enabled 0: no reasoning_effort" );
    like( raw_request( $make->( thinking_enabled => 1 ), $builder ), qr/"enable_thinking":true/,
      "$name $builder thinking_enabled 1: JSON true" );
  }
  ok( !$make->()->has_thinking_enabled, "$name: has_thinking_enabled false by default" );
}

# --- layering: per-request beats engine, contradictions only within one layer ---
{
  my $b = body( llama( reasoning_effort => 'high' ), 'chat_request', controls => { thinking_enabled => 0 } );
  is_deeply( $b->{chat_template_kwargs}, { enable_thinking => JSON::PP::false },
    'engine effort high + per-request thinking_enabled 0: thinking off' );
  ok( !exists $b->{reasoning_effort}, '... and no reasoning_effort' );

  my $c = body( llama( thinking_enabled => 0 ), 'chat_request', controls => { reasoning_effort => 'low' } );
  is_deeply( $c->{chat_template_kwargs}, { enable_thinking => JSON::PP::true },
    'engine thinking_enabled 0 + per-request effort low: thinking on' );
  is( $c->{reasoning_effort}, 'low', '... with effort low' );

  ok( !eval { raw_request( llama( thinking_enabled => 0, reasoning_effort => 'low' ), 'chat_request' ); 1 },
    'engine attributes: thinking_enabled 0 + effort low croaks at request build' );
  ok( !eval { raw_request( llama( thinking_enabled => 1, reasoning_effort => 'none' ), 'chat_request' ); 1 },
    'engine attributes: thinking_enabled 1 + effort none croaks at request build' );
  ok( eval { raw_request( llama( thinking_enabled => 0, reasoning_effort => 'none' ), 'chat_request' ); 1 },
    'engine attributes: 0 + none does not croak' );
  ok( eval { raw_request( llama( thinking_enabled => 1, reasoning_effort => 'high' ), 'chat_request' ); 1 },
    'engine attributes: 1 + high does not croak' );
}

# --- vLLM unchanged, generic OpenAI opt-in ---
{
  is( vllm()->reasoning_wire_format, 'openai', 'vLLM keeps reasoning_wire_format openai' );
  my $v = body( vllm( reasoning_effort => 'none' ), 'chat_request' );
  is( $v->{reasoning_effort}, 'none', 'vLLM none: top-level reasoning_effort none still sent' );
  ok( !exists $v->{chat_template_kwargs}, 'vLLM none: no chat_template_kwargs' );

  my $plain = body( openai( reasoning_effort => 'high' ), 'chat_request' );
  ok( !exists $plain->{chat_template_kwargs}, 'generic OpenAI without opt-in: no chat_template_kwargs' );
  is( $plain->{reasoning_effort}, 'high', 'generic OpenAI without opt-in: openai behavior unchanged' );

  my $opt = openai( reasoning_wire_format => $TAG, reasoning_effort => 'none' );
  is( $opt->reasoning_wire_format, $TAG, 'generic OpenAI opt-in sets the tag' );
  my $raw = raw_request( $opt, 'chat_request' );
  like( $raw, qr/"chat_template_kwargs":\{"enable_thinking":false\}/, 'generic OpenAI opt-in none: JSON false' );
  ok( !exists $json->decode($raw)->{reasoning_effort}, 'generic OpenAI opt-in none: no reasoning_effort' );
  my $on = body( openai( reasoning_wire_format => $TAG, reasoning_effort => 'medium' ), 'chat_request' );
  is_deeply( $on->{chat_template_kwargs}, { enable_thinking => JSON::PP::true }, 'generic OpenAI opt-in medium: enable_thinking true' );
  is( $on->{reasoning_effort}, 'medium', 'generic OpenAI opt-in medium: reasoning_effort sent' );
}

# --- merge with a caller's chat_template_kwargs ---
for my $builder (qw( chat_request chat_stream_request )) {
  my $m = body( llama( reasoning_effort => 'none' ), $builder,
    chat_template_kwargs => { thinking => JSON::PP::false, foo => 1 } );
  is_deeply( $m->{chat_template_kwargs},
    { enable_thinking => JSON::PP::false, thinking => JSON::PP::false, foo => 1 },
    "$builder merge: reasoning key and caller keys all present" );

  my $w = body( llama( reasoning_effort => 'none' ), $builder,
    chat_template_kwargs => { enable_thinking => JSON::PP::true } );
  is_deeply( $w->{chat_template_kwargs}, { enable_thinking => JSON::PP::true },
    "$builder merge: caller key wins on collision" );

  my $p = body( llama(), $builder, chat_template_kwargs => { foo => 1, bar => 'x' } );
  is_deeply( $p->{chat_template_kwargs}, { foo => 1, bar => 'x' },
    "$builder: caller's hash passes unchanged without reasoning" );
}

# --- thinking_enabled on the openai wire: nothing sent, a warning, no croak ---
for my $builder (qw( chat_request chat_stream_request )) {
  my $b;
  my @warnings = capture_warnings( sub {
    $b = body( openai( thinking_enabled => 1 ), $builder );
  } );
  ok( scalar(@warnings) >= 1, "$builder: thinking_enabled 1 on the openai wire warns" );
  ok( !exists $b->{chat_template_kwargs} && !exists $b->{reasoning_effort},
    "$builder: ... and sends nothing reasoning-related" );
}

done_testing;
