#!/usr/bin/env perl
# ABSTRACT: Model-scoped capability-exclusion seam + serving-stack scope (karr #148 / #184)

# The tools + structured-output response_format mutual exclusion routes through a
# per-MODEL seam (Langertha::Role::Chat::model_capability_exclusions), but the
# conflict is a property of the serving STACK, not of the gpt-oss model:
#
#   (1) Groq and Cerebras enforce it across every model they serve, each via its
#       own all-models (qr//) override — so the SAME model (gpt-oss-120b) is
#       refused there but not elsewhere (see the Groq/Cerebras blocks below).
#   (2) AKI serves gpt-oss-120b with tools + a json_schema response_format at
#       HTTP 200 (live-verified 2026-09-19, karr #184), so there is NO shared
#       gpt-oss rule on Langertha::Engine::OpenAIBase. The AKIOpenAI / TSystems
#       defaults and the OpenRouter / HuggingFace / Replicate routes therefore
#       do NOT croak on tools + json_schema — the request reaches the wire
#       carrying both fields.
#
# All cases are MOCKED — no live API calls. Sabotage check: put a shared
# qr/gpt-oss/ rule back on OpenAIBase and the aggregator/default requests below
# stop reaching the mock (the false-positive croak returns), turning their
# no-croak / wire-body assertions red.

use strict;
use warnings;

use Test2::Bundle::More;
use JSON::MaybeXS;

use lib 't/lib';
use Test::MockAsyncHTTP;

use Langertha::Engine::TSystems;
use Langertha::Engine::AKIOpenAI;
use Langertha::Engine::OpenRouter;
use Langertha::Engine::HuggingFace;
use Langertha::Engine::Cerebras;
use Langertha::Engine::Groq;

my $json = JSON::MaybeXS->new->canonical(1)->utf8(1);

my $SCHEMA = {
  type       => 'object',
  properties => { city => { type => 'string' } },
  required   => ['city'],
};

my $TOOL = {
  type     => 'function',
  function => {
    name        => 'get_weather',
    description => 'Get the weather for a city',
    parameters  => $SCHEMA,
  },
};

my $JSON_SCHEMA_RF = {
  type        => 'json_schema',
  json_schema => { name => 'extract', schema => $SCHEMA },
};
my $JSON_OBJECT_RF = { type => 'json_object' };

# A fresh mock per engine so the request never reaches a real provider even if
# a rule is removed (sabotage check stays offline).
sub mock {
  return Test::MockAsyncHTTP->new( responses => [
    Test::MockAsyncHTTP->mock_json_response({
      model   => 'gpt-oss-120b',
      choices => [{ message => { role => 'assistant', content => 'ok' } }],
    }),
  ]);
}

# Run a coderef that returns a Future and report ($ok, $err).
sub run {
  my ($code) = @_;
  my $ok = eval { $code->()->get; 1 };
  return ( $ok, $@ );
}

# ======================================================================
# AGGREGATOR-DEFAULT — TSystems and AKIOpenAI DEFAULT to gpt-oss-120b. There is
# no shared gpt-oss rule on OpenAIBase, so neither engine croaks on tools +
# json_schema: the request reaches the wire carrying both fields. AKI serves
# exactly this at HTTP 200 (live 2026-09-19, karr #184); TSystems is not
# live-testable but shares the same OpenAI dialect.
# ======================================================================
for my $case (
  [ 'TSystems'  => sub { Langertha::Engine::TSystems->new(@_) } ],
  [ 'AKIOpenAI' => sub { Langertha::Engine::AKIOpenAI->new(@_) } ],
) {
  my ( $name, $ctor ) = @$case;

  # Default model (gpt-oss-120b) + tools + json_schema -> NO croak; both fields
  # reach the wire.
  {
    my $engine = $ctor->( api_key => 'apikey', _async_http => mock() );
    is( $engine->chat_model, 'gpt-oss-120b',
      "$name default model is gpt-oss-120b (the aggregator default)" );
    my ( $ok, $err ) = run( sub { $engine->chat_f(
      messages        => ['weather?'],
      tools           => [$TOOL],
      response_format => $JSON_SCHEMA_RF,
    ) });
    ok( $ok, "$name (default gpt-oss-120b): tools + json_schema does NOT croak (no shared rule)" )
      or diag $err;
    is( $engine->_async_http->request_count, 1,
      "$name: the tools + json_schema request reached the transport" );
    my ($req) = $engine->_async_http->requests;
    my $body  = $json->decode( $req->content );
    ok( $body->{tools}, "$name: tools sent on the wire" );
    is( $body->{response_format}{type}, 'json_schema',
      "$name: json_schema response_format sent on the wire alongside tools" );
  }

  # A non-default sibling model on the same engine also reaches the wire (no
  # engine-scoped rule here either).
  {
    my $engine = $ctor->( api_key => 'apikey', model => 'llama-3.3-70b', _async_http => mock() );
    my ( $ok, $err ) = run( sub { $engine->chat_f(
      messages        => ['weather?'],
      tools           => [$TOOL],
      response_format => $JSON_SCHEMA_RF,
    ) });
    ok( $ok, "$name (llama-3.3-70b sibling): tools + json_schema does NOT croak" )
      or diag $err;
    is( $engine->_async_http->request_count, 1,
      "$name: the sibling-model request reached the transport" );
  }

  # tools + json_object also reaches the wire (json_object was never gated on
  # the aggregators; Cerebras's stricter json_object refusal is Cerebras-only).
  {
    my $engine = $ctor->( api_key => 'apikey', _async_http => mock() );
    my ( $ok, $err ) = run( sub { $engine->chat_f(
      messages        => ['weather?'],
      tools           => [$TOOL],
      response_format => $JSON_OBJECT_RF,
    ) });
    ok( $ok, "$name (gpt-oss-120b): tools + json_object does NOT croak" )
      or diag $err;
    is( $engine->_async_http->request_count, 1,
      "$name: the json_object request reached the transport" );
  }
}

# ======================================================================
# AGGREGATOR-ROUTE — a passthrough aggregator reaches gpt-oss through a
# `provider/gpt-oss-...` id. With no shared gpt-oss rule, the routed request
# reaches the wire carrying tools + json_schema, exactly as a non-gpt-oss route
# does.
# ======================================================================
for my $case (
  [ 'OpenRouter'  => sub { Langertha::Engine::OpenRouter->new(@_) } ],
  [ 'HuggingFace' => sub { Langertha::Engine::HuggingFace->new(@_) } ],
) {
  my ( $name, $ctor ) = @$case;

  {
    my $engine = $ctor->( api_key => 'apikey', model => 'openai/gpt-oss-120b', _async_http => mock() );
    my ( $ok, $err ) = run( sub { $engine->chat_f(
      messages        => ['weather?'],
      tools           => [$TOOL],
      response_format => $JSON_SCHEMA_RF,
    ) });
    ok( $ok, "$name (route openai/gpt-oss-120b): tools + json_schema does NOT croak (no shared rule)" )
      or diag $err;
    is( $engine->_async_http->request_count, 1,
      "$name: the routed request reached the transport" );
    my ($req) = $engine->_async_http->requests;
    my $body  = $json->decode( $req->content );
    ok( $body->{tools}, "$name: tools sent on the wire for the gpt-oss route" );
    is( $body->{response_format}{type}, 'json_schema',
      "$name: json_schema response_format sent on the wire alongside tools" );
  }

  {
    my $engine = $ctor->( api_key => 'apikey', model => 'meta-llama/llama-3.3-70b-instruct', _async_http => mock() );
    my ( $ok, $err ) = run( sub { $engine->chat_f(
      messages        => ['weather?'],
      tools           => [$TOOL],
      response_format => $JSON_SCHEMA_RF,
    ) });
    ok( $ok, "$name (route meta-llama/...): tools + json_schema does NOT croak" )
      or diag $err;
    is( $engine->_async_http->request_count, 1,
      "$name: the non-gpt-oss routed request reached the transport" );
  }
}

# ======================================================================
# ENGINE contrast on json_object: the SAME model (gpt-oss-120b) is refused with
# json_object + tools on Cerebras (its engine-wide platform rule) but NOT on
# TSystems (no engine rule there). Proves the exclusion is a serving-stack
# property carried per-engine, not a property of the gpt-oss model.
# ======================================================================
{
  my $cerebras = Langertha::Engine::Cerebras->new(
    api_key => 'apikey', model => 'gpt-oss-120b', _async_http => mock() );
  my ( $ok, $err ) = run( sub { $cerebras->chat_f(
    messages        => ['weather?'],
    tools           => [$TOOL],
    response_format => $JSON_OBJECT_RF,
  ) });
  ok( !$ok, 'Cerebras (gpt-oss-120b): tools + json_object still croaks (stricter platform rule, migrated)' );
  like( $err, qr/Cerebras/, 'Cerebras json_object croak names the engine' );
  like( $err, qr/tools and response_format/, 'Cerebras json_object croak names both fields' );

  my $tsi = Langertha::Engine::TSystems->new(
    api_key => 'apikey', model => 'gpt-oss-120b', _async_http => mock() );
  my ( $ok2, $err2 ) = run( sub { $tsi->chat_f(
    messages        => ['weather?'],
    tools           => [$TOOL],
    response_format => $JSON_OBJECT_RF,
  ) });
  ok( $ok2, 'TSystems (gpt-oss-120b): tools + json_object does NOT croak (no engine-scoped rule on TSystems)' )
    or diag $err2;
}

# ======================================================================
# GROQ platform rule (karr #184): Groq 400s a JSON response_format combined with
# tools -- BOTH json_object and json_schema, with the same "json mode cannot be
# combined with tool/function calling" message (live-verified 2026-09-19). Its
# qr// all-models override REPLACES the inherited gpt-oss json_schema-only rule,
# so unlike the aggregators above, Groq refuses json_object + tools too. A
# json_object request WITHOUT tools still reaches the wire.
#
# Sabotage check: narrow the has_tools branch of
# _exclude_json_schema_with_tools_or_streaming back to json_schema-only and the
# "json_object + tools croaks" assertion goes red (the request reaches the mock).
# ======================================================================
{
  # json_schema + tools -> croak (unchanged behavior).
  my $g1 = Langertha::Engine::Groq->new(
    api_key => 'apikey', model => 'llama-3.3-70b-versatile', _async_http => mock() );
  my ( $ok1, $err1 ) = run( sub { $g1->chat_f(
    messages        => ['weather?'],
    tools           => [$TOOL],
    response_format => $JSON_SCHEMA_RF,
  ) });
  ok( !$ok1, 'Groq: tools + json_schema still croaks' );
  like( $err1, qr/Groq/, 'Groq json_schema croak names the engine' );
  is( $g1->_async_http->request_count, 0,
    'Groq: the json_schema + tools request never reached the transport' );

  # json_object + tools -> croak (the #184 fix: Groq 400s json mode + tools too).
  my $g2 = Langertha::Engine::Groq->new(
    api_key => 'apikey', model => 'llama-3.3-70b-versatile', _async_http => mock() );
  my ( $ok2, $err2 ) = run( sub { $g2->chat_f(
    messages        => ['weather?'],
    tools           => [$TOOL],
    response_format => $JSON_OBJECT_RF,
  ) });
  ok( !$ok2, 'Groq: tools + json_object now croaks (Groq rejects json mode + tools, #184)' );
  like( $err2, qr/Groq/, 'Groq json_object croak names the engine' );
  like( $err2, qr/tool/, 'Groq json_object croak mentions the tool conflict' );
  is( $g2->_async_http->request_count, 0,
    'Groq: the json_object + tools request never reached the transport' );

  # json_object WITHOUT tools -> passes through (the rule only fires with tools).
  my $g3 = Langertha::Engine::Groq->new(
    api_key => 'apikey', model => 'llama-3.3-70b-versatile', _async_http => mock() );
  my ( $ok3, $err3 ) = run( sub { $g3->chat_f(
    messages        => ['weather?'],
    response_format => $JSON_OBJECT_RF,
  ) });
  ok( $ok3, 'Groq: json_object WITHOUT tools does NOT croak' ) or diag $err3;
  is( $g3->_async_http->request_count, 1,
    'Groq: the json_object-only request reached the transport' );
}

# ======================================================================
# EMPTY chat_model (karr k223): the exclusion walker matches an empty chat_model
# as '' exactly like model_capability_corrections does (ADR 0019 k209 Update),
# so the Groq / Cerebras all-models qr// rule still holds for model => ''. Before
# k223 the walker skipped an empty id and the request reached the provider,
# which 400s the combination anyway.
# ======================================================================
for my $class (qw( Langertha::Engine::Groq Langertha::Engine::Cerebras )) {
  my $engine = $class->new( api_key => 'apikey', model => '', _async_http => mock() );
  is( $engine->chat_model, '', "$class: model => '' leaves chat_model empty" );
  my ( $ok, $err ) = run( sub { $engine->chat_f(
    messages        => ['weather?'],
    tools           => [$TOOL],
    response_format => $JSON_SCHEMA_RF,
  ) });
  ok( !$ok, "$class (model ''): tools + json_schema croaks, the qr// rule matches ''" );
  is( $engine->_async_http->request_count, 0,
    "$class (model ''): the request never reached the transport" );
}

done_testing;
