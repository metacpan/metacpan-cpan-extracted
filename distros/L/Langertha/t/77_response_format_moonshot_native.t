#!/usr/bin/env perl
# ABSTRACT: MoonshotAnthropic sends native output_config.format on kimi-k3, the synthetic tool elsewhere (karr k218)

use strict;
use warnings;

use Test2::Bundle::More;
use JSON::MaybeXS;

use Langertha::Engine::MoonshotAnthropic;
use Langertha::Engine::Anthropic;
use Langertha::Manifest::Builder;

# karr k218 / ADR 0005 (k218 Update): Kimi's Messages API documents
# output_config.format {type: json_schema, schema} for kimi-k3 ("the model
# outputs JSON that strictly follows the given JSON Schema"), next to
# output_config.effort. MoonshotAnthropic took the /anthropic-shim rewrite for
# every model instead: a synthetic tool plus a forced named tool_choice (a
# forced named tool is incompatible with K3's always-on thinking on the chat
# face) and no streaming. On kimi-k3 it now takes the first-party native path;
# the K2.x line is undocumented on this face and keeps the synthetic tool. The
# endpoint stays a shim: its manifest dialect is still anthropic-compat.
# Advisor 2026-09-25, docs/api/messages.md, documentation only, not live.

my $json = JSON::MaybeXS->new->canonical(1)->utf8(1);
my $SCHEMA = { type => 'object', properties => { city => { type => 'string' } }, required => ['city'] };
my $CLOSED = { %$SCHEMA, additionalProperties => JSON->false };
my $RF     = { type => 'json_schema', json_schema => { name => 'city', schema => $SCHEMA } };

sub body {
  my ( $builder, %args ) = @_;
  my $controls = delete $args{controls} // {};
  my $engine = Langertha::Engine::MoonshotAnthropic->new( api_key => 'k', %args );
  return $json->decode( $engine->$builder(
    [ { role => 'user', content => 'hi' } ], controls => $controls )->content );
}

# --- kimi-k3: native ---
for my $builder (qw( chat_request chat_stream_request )) {
  my $got = eval { body( $builder, response_format => $RF ) };
  ok( $got, "kimi-k3 $builder: json_schema builds (no shim croak)" ) or diag $@;
  is_deeply( $got->{output_config}, { format => { type => 'json_schema', schema => $CLOSED } },
    "kimi-k3 $builder: native output_config.format, schema closed" );
  ok( !exists $got->{tools} && !exists $got->{tool_choice},
    "kimi-k3 $builder: no synthetic tool, no forced tool_choice" );
}
is_deeply( body( 'chat_request', controls => { response_format => $RF } )->{output_config},
  { format => { type => 'json_schema', schema => $CLOSED } }, 'kimi-k3: a per-request response_format goes native' );
is_deeply( body( 'chat_request', reasoning_effort => 'high', response_format => $RF )->{output_config},
  { effort => 'high', format => { type => 'json_schema', schema => $CLOSED } },
  'kimi-k3: effort and format share output_config' );

# A bare json_object has no native form (the Messages API format is json_schema
# only), so it keeps the synthetic tool on kimi-k3 too -- unchanged.
my $obj = body( 'chat_request', response_format => { type => 'json_object' } );
ok( !exists $obj->{output_config}, 'kimi-k3 json_object: no output_config.format' );
is( $obj->{tools}[0]{name}, '__langertha_response_format__', 'kimi-k3 json_object: synthetic tool' );

# Streaming a json_object croaks on kimi-k3 as on first-party Anthropic, with a
# message that does not claim to be first-party Claude (review M5).
{
  my $err = eval { body( 'chat_stream_request', response_format => { type => 'json_object' } ); 1 } ? '' : $@;
  like( $err, qr/cannot stream a json_object response_format: the Messages endpoint has no native free-form JSON/,
    'kimi-k3 streaming json_object: endpoint-neutral croak' );
  unlike( $err, qr/Claude/, 'kimi-k3 streaming json_object: croak does not name Claude' );
}

# --- K2.x: the shim rewrite ---
for my $model (qw( kimi-k2.6 kimi-k2.7-code )) {
  my $got = body( 'chat_request', model => $model, response_format => $RF );
  ok( !exists $got->{output_config}, "$model: no output_config.format" );
  is( $got->{tools}[0]{name}, 'city', "$model: synthetic tool" );
  is_deeply( $got->{tool_choice}, { type => 'tool', name => 'city' }, "$model: forced tool_choice" );
  ok( !eval { body( 'chat_stream_request', model => $model, response_format => $RF ); 1 },
    "$model: streaming a response_format still croaks (no lift)" );
}

# --- the manifest dialect is the endpoint's, not the model's ---
is( Langertha::Manifest::Builder->dialect_for_engine(
      Langertha::Engine::MoonshotAnthropic->new( api_key => 'k' ) ),
  'anthropic-compat', 'MoonshotAnthropic on kimi-k3 is still an anthropic-compat endpoint' );
is( Langertha::Manifest::Builder->dialect_for_engine(
      Langertha::Engine::Anthropic->new( api_key => 'k' ) ),
  'anthropic', 'first-party Anthropic stays anthropic' );

done_testing;
