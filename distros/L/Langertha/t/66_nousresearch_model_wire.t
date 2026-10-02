#!/usr/bin/env perl
# ABSTRACT: NousResearch derives tool_wire_format per model; hermes is the named exception
use strict;
use warnings;

use Test2::Bundle::More;
use lib 't/lib';

use JSON::MaybeXS;
use Langertha::Engine::NousResearch;
use Test::MockAsyncHTTP;

# karr k238 (ADR 0033, amends 0001/0002/0019): NousResearch is an
# OpenAI-compatible gateway fronting ~341 models. Only Hermes models want the
# hermes wire (tools ride the system prompt, <tool_call> tags are lifted onto
# Response.tool_calls -- the robust choice given upstream hermes-agent#741,
# where Hermes-4 intermittently leaks tool calls as XML even with native
# calling). Every non-Hermes slug (anthropic/..., openai/..., ...) routes to a
# real backend that wants NATIVE OpenAI tools. So the tag is model-scoped:
# hermes when the model is a Hermes model (the named exception), openai for the
# 280+ non-Hermes slugs and any unknown new one (the safer default). The tag is
# resolved once per instance from chat_model; the init_arg override still wins.

my $json   = JSON::MaybeXS->new( utf8 => 1, canonical => 1 );
my $schema = { type => 'object', properties => { a => { type => 'number' } }, required => ['a'] };
my $tool   = { name => 'add', description => 'Add', inputSchema => $schema };
my $reply  = { choices => [ { message => { role => 'assistant', content => 'ok' }, finish_reason => 'stop' } ] };

sub engine {
  my (@args) = @_;
  return Langertha::Engine::NousResearch->new( api_key => 'k', @args );
}

# ($engine, $mock): the engine sends its next request through the mock.
sub engine_mock {
  my (@args) = @_;
  my $mock = Test::MockAsyncHTTP->new( responses => [ Test::MockAsyncHTTP->mock_json_response($reply) ] );
  return ( engine( _async_http => $mock, @args ), $mock );
}

subtest 'the builder derives hermes for Hermes models' => sub {
  # Every current served Hermes slug, plus the nousresearch/ prefix, lowercase
  # and the legacy Nous-Hermes-2 belt-and-suspanders form.
  for my $model (
    'Hermes-4-70B', 'Hermes-4-405B', 'Hermes-4-14B', 'Hermes-4.3-36B',
    'Hermes-3-Llama-3.1-70B', 'DeepHermes-3-Llama-3-8B-Preview',
    'nousresearch/Hermes-4-70B', 'hermes-4-70b', 'Nous-Hermes-2-Mixtral-8x7B-DPO',
  ) {
    is( engine( model => $model )->tool_wire_format, 'hermes', "$model -> hermes" );
  }
};

subtest 'the builder derives openai for non-Hermes slugs' => sub {
  # Real backends behind the gateway want native OpenAI tools; an unknown new
  # slug falls through here too, which is the safer default.
  for my $model (
    'anthropic/claude-sonnet-4.6', 'openai/gpt-5.5-pro', 'google/gemini-3-pro-preview',
    'deepseek/deepseek-v4-pro', 'meta-llama/llama-3.3-70b', 'some-brand-new-model',
  ) {
    is( engine( model => $model )->tool_wire_format, 'openai', "$model -> openai" );
  }
};

subtest 'no model -> the default Hermes-4-70B is a Hermes model' => sub {
  # engine_capabilities / supports is read without a model in the suite; the
  # tag must resolve to the default without croaking, and stay hermes.
  my $engine = engine();
  is( $engine->chat_model, 'Hermes-4-70B', 'chat_model defaults to default_model' );
  is( $engine->tool_wire_format, 'hermes', 'the default model keeps the hermes wire' );
};

subtest 'capability flags follow the derived tag' => sub {
  my $hermes = engine( model => 'Hermes-4-70B' )->engine_capabilities;
  ok( $hermes->{tools_hermes}, 'Hermes slug: tools_hermes' );
  ok( !$hermes->{$_}, "Hermes slug: no $_" )
    for qw( tools_native tool_choice_any tool_choice_named parallel_tool_use );

  my $claude = engine( model => 'anthropic/claude-sonnet-4.6' );
  my $caps = $claude->engine_capabilities;
  ok( $caps->{$_}, "claude slug: claims $_" )
    for qw( tools_native tool_choice_auto tool_choice_any tool_choice_none tool_choice_named parallel_tool_use );
  ok( !$caps->{tools_hermes}, 'claude slug: no tools_hermes' );
  ok( $claude->supports('tool_choice_named'), 'claude slug: supports() agrees' );
};

subtest 'the init_arg override short-circuits the builder both ways' => sub {
  my $forced_openai = engine( model => 'Hermes-4-70B', tool_wire_format => 'openai' );
  is( $forced_openai->tool_wire_format, 'openai', 'openai forced on a Hermes slug wins over the builder' );
  ok( $forced_openai->engine_capabilities->{tools_native}, '... and the native flags follow' );
  ok( !$forced_openai->engine_capabilities->{tools_hermes}, '... losing tools_hermes' );

  my $forced_hermes = engine( model => 'anthropic/claude-sonnet-4.6', tool_wire_format => 'hermes' );
  is( $forced_hermes->tool_wire_format, 'hermes', 'hermes forced on a non-Hermes slug wins over the builder' );
  ok( $forced_hermes->engine_capabilities->{tools_hermes}, '... and tools_hermes follows' );
  ok( !$forced_hermes->engine_capabilities->{tools_native}, '... losing the native flags' );
};

subtest 'request-building: a Hermes slug renders the tools into the system prompt' => sub {
  my ( $engine, $mock ) = engine_mock( model => 'Hermes-4-70B' );
  my $response = $engine->chat_f( messages => ['hi'], tools => [$tool],
    tool_choice => { type => 'tool', name => 'add' } )->get;
  ok( defined $response, 'chat_f answered' );
  my $body = $json->decode( ( $mock->requests )[0]->content );
  ok( !exists $body->{tools},       'no tools body key' );
  ok( !exists $body->{tool_choice}, 'no tool_choice body key' );
  is( $body->{messages}[0]{role}, 'system', 'the tools ride a leading system message' );
  # tool_choice_named is cleared on hermes, so the forced tool takes the ADR
  # 0005 json_schema rewrite, with the schema in the Hermes <schema> prompt.
  is( $body->{response_format}{type}, 'json_schema', 'the forced tool takes the json_schema rewrite' );
  like( $body->{messages}[0]{content}, qr/<schema>/, 'with the Hermes schema prompt' );
};

subtest 'request-building: a non-Hermes slug sends native tools and a named tool_choice' => sub {
  my ( $engine, $mock ) = engine_mock( model => 'anthropic/claude-sonnet-4.6' );
  my @warnings;
  local $SIG{__WARN__} = sub { push @warnings, @_ };
  my $response = $engine->chat_f( messages => ['hi'], tools => [$tool],
    tool_choice => { type => 'tool', name => 'add' } )->get;
  ok( defined $response, 'chat_f answered' );
  my $body = $json->decode( ( $mock->requests )[0]->content );
  is( ref $body->{tools}, 'ARRAY', 'tools on the body' );
  is( $body->{tools}[0]{function}{name}, 'add', 'in the openai shape' );
  is_deeply( $body->{tool_choice}, { type => 'function', function => { name => 'add' } },
    'the forced tool is a native tool_choice' );
  ok( !exists $body->{response_format}, 'no ADR 0005 json_schema rewrite' );
  ok( !( grep { $_->{role} eq 'system' } @{ $body->{messages} } ), 'no Hermes tool or schema system prompt' );
  ok( !( grep { $_->has_tool_calls } $response ), 'no synthetic ToolCall on a plain reply' );
  is_deeply( \@warnings, [], 'no hermes carp' );
};

# --- step (d): the reasoning system-prompt gate ------------------------------

# The Nous reasoning prompt is a Hermes-model feature. It is gated on the same
# "is this a Hermes model" predicate as the tool wire, not on the tool
# transport: forcing tool_wire_format => 'openai' on a real Hermes model must
# not silently kill reasoning.
sub system_texts {
  my ($engine) = @_;
  return [ map { $_->{content} } grep { $_->{role} eq 'system' } @{ $engine->chat_messages('Hi') } ];
}

subtest 'reasoning => 1 is honored on a Hermes model' => sub {
  my $engine = engine( model => 'Hermes-4-70B', reasoning => 1 );
  my @warnings;
  local $SIG{__WARN__} = sub { push @warnings, @_ };
  is_deeply( system_texts($engine), [ $engine->reasoning_prompt ], 'the reasoning prompt leads' );
  is_deeply( \@warnings, [], 'no carp on a Hermes model' );
};

subtest 'reasoning => 1 carps and is ignored on a non-Hermes model' => sub {
  my $engine = engine( model => 'anthropic/claude-sonnet-4.6', reasoning => 1 );
  my @warnings;
  local $SIG{__WARN__} = sub { push @warnings, @_ };
  is_deeply( system_texts($engine), [], 'no reasoning prompt is sent' );
  is( scalar( grep { /reasoning/i } @warnings ), 1, 'exactly one reasoning carp' );
  like( $warnings[0] // '', qr/reasoning/i, 'the carp names reasoning' );
  like( $warnings[0] // '', qr/Hermes/i, 'and says it is a Hermes-model feature' );
};

subtest 'reasoning is decoupled from the tool transport (forced openai keeps reasoning)' => sub {
  # A user who forces the openai tool wire on a genuine Hermes model still
  # wants the reasoning prompt: the gate is _is_hermes_model, not the tag.
  my $engine = engine( model => 'Hermes-4-70B', reasoning => 1, tool_wire_format => 'openai' );
  my @warnings;
  local $SIG{__WARN__} = sub { push @warnings, @_ };
  is( $engine->tool_wire_format, 'openai', 'the tool wire is forced to openai' );
  is_deeply( system_texts($engine), [ $engine->reasoning_prompt ], 'the reasoning prompt still leads' );
  is_deeply( \@warnings, [], 'no carp: it is still a Hermes model' );
};

done_testing;
