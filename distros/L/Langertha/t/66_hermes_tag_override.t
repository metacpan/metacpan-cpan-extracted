#!/usr/bin/env perl
# ABSTRACT: the tool-transport capability flags follow the resolved tool_wire_format
use strict;
use warnings;

use Test2::Bundle::More;
use lib 't/lib';

use JSON::MaybeXS;
use Langertha::Engine::NousResearch;
use Test::MockAsyncHTTP;

# karr k251 (ADR 0002, step (b) of the k238 design): tool_wire_format has an
# init_arg, so NousResearch->new(tool_wire_format => 'openai') puts the tools
# natively on the body. Role::HermesTools' layer-2 rule used to delete the
# native flags because the role was composed, whatever the tag said: supports()
# lied (tools_native=0, tool_choice_named=0, tools_hermes=1), and chat_f
# rewrote a forced tool to json_schema + synthetic ToolCall (ADR 0005) and put
# a Hermes <schema> prompt in front, although the wire takes a native forced
# tool. The flags now follow the tag: hermes clears the native flags, any
# other tag clears tools_hermes.
#
# This file is the CONSTRUCTOR-override direction: the init_arg wins over the
# builder. Since k238 (ADR 0033) landed the model-aware builder, the base model
# here is a Hermes slug, whose builder would give 'hermes' -- so forcing
# 'openai' is a real override, not a no-op. The BUILDER-derived per-model
# direction is t/66_nousresearch_model_wire.t.

my $json   = JSON::MaybeXS->new( utf8 => 1, canonical => 1 );
my $schema = { type => 'object', properties => { a => { type => 'number' } }, required => ['a'] };
my $tool   = { name => 'add', description => 'Add', inputSchema => $schema };
my $reply  = { choices => [ { message => { role => 'assistant', content => 'ok' }, finish_reason => 'stop' } ] };

sub nous {
  my (@args) = @_;
  my $mock = Test::MockAsyncHTTP->new( responses => [ Test::MockAsyncHTTP->mock_json_response($reply) ] );
  my $engine = Langertha::Engine::NousResearch->new(
    api_key => 'k', model => 'Hermes-4-70B', _async_http => $mock, @args );
  return ( $engine, $mock );
}

# The decoded body chat_f sent.
sub sent_body {
  my ( $engine, $mock, %args ) = @_;
  my @warnings;
  local $SIG{__WARN__} = sub { push @warnings, @_ };
  my $response = $engine->chat_f( messages => ['hi'], %args )->get;
  ok( defined $response, 'chat_f answered' );
  my ($request) = $mock->requests;
  return ( $json->decode( $request->content ), $response, \@warnings );
}

subtest 'tool_wire_format => openai: native flags, no hermes flag' => sub {
  my ($engine) = nous( tool_wire_format => 'openai' );
  is( $engine->tool_wire_format, 'openai', 'the constructor tag wins over the builder' );
  my $caps = $engine->engine_capabilities;
  ok( $caps->{$_}, "claims $_ (the wire takes the native field)" )
    for qw( tools_native tool_choice_auto tool_choice_any tool_choice_none tool_choice_named );
  ok( !$caps->{tools_hermes}, 'no tools_hermes (the tools are not in the prompt)' );
  ok( $engine->supports('tool_choice_named'), 'supports() agrees' );
};

subtest 'tool_wire_format => openai: chat_f sends tools and the forced choice natively' => sub {
  my ( $engine, $mock ) = nous( tool_wire_format => 'openai' );
  my ( $body, $response, $warnings ) = sent_body( $engine, $mock,
    tools => [$tool], tool_choice => { type => 'tool', name => 'add' } );
  is( ref $body->{tools}, 'ARRAY', 'tools on the body' );
  is( $body->{tools}[0]{function}{name}, 'add', 'in the openai shape' );
  is_deeply( $body->{tool_choice}, { type => 'function', function => { name => 'add' } },
    'the forced tool is a native tool_choice' );
  ok( !exists $body->{response_format}, 'no ADR 0005 json_schema rewrite' );
  ok( !( grep { $_->{role} eq 'system' } @{ $body->{messages} } ),
    'no Hermes tool or schema system prompt' );
  ok( !( grep { $_->has_tool_calls } $response ), 'no synthetic ToolCall on a plain reply' );
  is_deeply( $warnings, [], 'no hermes carp' );
};

subtest 'default NousResearch stays on the hermes wire' => sub {
  my ( $engine, $mock ) = nous();
  is( $engine->tool_wire_format, 'hermes', 'the builder gives hermes' );
  my $caps = $engine->engine_capabilities;
  ok( $caps->{tools_hermes}, 'tools_hermes' );
  ok( !$caps->{$_}, "no $_" ) for qw( tools_native tool_choice_any tool_choice_named parallel_tool_use );
  my ( $body, $response ) = sent_body( $engine, $mock,
    tools => [$tool], tool_choice => { type => 'tool', name => 'add' } );
  ok( !exists $body->{tools},       'no tools body key' );
  ok( !exists $body->{tool_choice}, 'no tool_choice body key' );
  is( $body->{response_format}{type}, 'json_schema', 'the forced tool takes the ADR 0005 rewrite' );
  like( $body->{messages}[0]{content}, qr/<schema>/, 'with the Hermes schema prompt' );
};

done_testing;
