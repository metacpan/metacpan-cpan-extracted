#!/usr/bin/env perl
# ABSTRACT: Per-engine capability-exclusion croak (karr #142) — Cerebras/Groq tools+response_format

# karr #142: a boolean capability flag cannot express a MUTUAL EXCLUSION
# between two capabilities in one request. Two providers reject a body that
# combines tools and a structured-output response_format with an opaque HTTP
# 400 (no body). chat_f/chat_stream_realtime_f consult a per-engine hook
# (_check_capability_exclusions, default no-op) that turns the known provider
# 400 into a clear LOCAL croak naming the engine and the conflicting fields.
#
#   Cerebras: tools + response_format (json_object OR json_schema) -> croak.
#   Groq: tools + response_format (json_object OR json_schema) -> croak (k184
#         live-verified 2026-09-19: Groq 400s json mode + tools for either type,
#         same message). Groq Structured Outputs additionally exclude streaming:
#         response_format json_schema on the streaming path croaks regardless of
#         tools, while json_object without tools is not refused by the guard.
#
# All cases are MOCKED — no live API calls. The mock also makes the sabotage
# check hermetic: removing a guard lets the request reach the mock (returning a
# canned body on the non-streaming path, or dying on the missing streaming
# header) instead of a real provider, and the exclusion-message assertions then
# turn red because the croak no longer fires.

use strict;
use warnings;

use Test2::Bundle::More;
use JSON::MaybeXS;

use lib 't/lib';
use Test::MockAsyncHTTP;

use Langertha::Engine::Cerebras;
use Langertha::Engine::Groq;
use Langertha::Engine::OpenAI;

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
# a guard is removed (sabotage check stays offline).
sub mock {
  return Test::MockAsyncHTTP->new( responses => [
    Test::MockAsyncHTTP->mock_json_response({
      model   => 'gpt-oss-120b',
      choices => [{ message => { role => 'assistant', content => 'ok' } }],
    }),
  ]);
}

sub cerebras {
  return Langertha::Engine::Cerebras->new(
    api_key     => 'apikey',
    model       => 'gpt-oss-120b',
    _async_http => mock(),
    @_,
  );
}

sub groq {
  return Langertha::Engine::Groq->new(
    api_key     => 'apikey',
    model       => 'gpt-oss-120b',
    _async_http => mock(),
    @_,
  );
}

# Run a coderef that returns a Future and report ($ok, $err).
sub run {
  my ($code) = @_;
  my $ok = eval { $code->()->get; 1 };
  return ( $ok, $@ );
}

# ======================================================================
# Cerebras — tools + response_format (either type) is rejected
# ======================================================================

# --- Cerebras: tools + json_object -> croak -------------------------------
{
  my ( $ok, $err ) = run( sub { cerebras()->chat_f(
    messages        => ['weather?'],
    tools           => [$TOOL],
    response_format => $JSON_OBJECT_RF,
  ) });
  ok( !$ok, 'Cerebras: tools + response_format json_object croaks in chat_f' );
  like( $err, qr/Cerebras/, 'Cerebras json_object croak names the engine' );
  like( $err, qr/tools and response_format/,
    'Cerebras json_object croak names both conflicting fields' );
  like( $err, qr/400/, 'Cerebras json_object croak says the provider rejects it (400)' );
}

# --- Cerebras: tools + json_schema -> croak -------------------------------
{
  my ( $ok, $err ) = run( sub { cerebras()->chat_f(
    messages        => ['weather?'],
    tools           => [$TOOL],
    response_format => $JSON_SCHEMA_RF,
  ) });
  ok( !$ok, 'Cerebras: tools + response_format json_schema croaks in chat_f' );
  like( $err, qr/Cerebras/, 'Cerebras json_schema croak names the engine' );
}

# --- Cerebras: forced named tool_choice (no tools array) + rf -> croak ----
# The tool signal is "tools OR a forced tool_choice" — a forced named
# tool_choice trips the guard too.
{
  my ( $ok, $err ) = run( sub { cerebras()->chat_f(
    messages        => ['weather?'],
    tool_choice     => { type => 'tool', name => 'get_weather' },
    response_format => $JSON_OBJECT_RF,
  ) });
  ok( !$ok, 'Cerebras: forced tool_choice + response_format croaks in chat_f' );
  like( $err, qr/Cerebras/, 'Cerebras forced-tool_choice croak names the engine' );
}

# --- Cerebras: streaming path also croaks ---------------------------------
{
  my ( $ok, $err ) = run( sub { cerebras()->chat_stream_realtime_f(
    messages        => ['weather?'],
    tools           => [$TOOL],
    response_format => $JSON_SCHEMA_RF,
  ) });
  ok( !$ok, 'Cerebras: tools + response_format croaks on the streaming path' );
  like( $err, qr/Cerebras/, 'Cerebras streaming croak names the engine' );
  like( $err, qr/tools and response_format/,
    'Cerebras streaming croak names both conflicting fields' );
}

# --- Cerebras: tools alone -> NO croak (over-fire guard) ------------------
{
  my $engine = cerebras();
  my ( $ok, $err ) = run( sub { $engine->chat_f(
    messages => ['weather?'],
    tools    => [$TOOL],
  ) });
  ok( $ok, 'Cerebras: tools without response_format does NOT croak' )
    or diag $err;
  is( $engine->_async_http->request_count, 1,
    'Cerebras: tools-only request reached the transport' );
}

# --- Cerebras: response_format alone -> NO croak (over-fire guard) --------
{
  my $engine = cerebras();
  my ( $ok, $err ) = run( sub { $engine->chat_f(
    messages        => ['weather?'],
    response_format => $JSON_SCHEMA_RF,
  ) });
  ok( $ok, 'Cerebras: response_format without tools does NOT croak' )
    or diag $err;
  is( $engine->_async_http->request_count, 1,
    'Cerebras: response_format-only request reached the transport' );
}

# --- Cerebras: empty tools => [] + response_format -> NO croak (k169) ------
# An empty tools array sends ZERO tools on the wire, so it must not trip the
# exclusion the way a populated array does. Only a non-empty tools array (or a
# forced named tool_choice) counts as "tools requested".
{
  my $engine = cerebras();
  my ( $ok, $err ) = run( sub { $engine->chat_f(
    messages        => ['weather?'],
    tools           => [],
    response_format => $JSON_SCHEMA_RF,
  ) });
  ok( $ok, 'Cerebras: empty tools => [] + response_format does NOT croak (k169)' )
    or diag $err;
  is( $engine->_async_http->request_count, 1,
    'Cerebras: empty-tools request reached the transport' );
}

# ======================================================================
# Groq — tools + JSON response_format (either type) + json_schema streaming
# ======================================================================

# --- Groq: tools + json_schema -> croak -----------------------------------
{
  my ( $ok, $err ) = run( sub { groq()->chat_f(
    messages        => ['weather?'],
    tools           => [$TOOL],
    response_format => $JSON_SCHEMA_RF,
  ) });
  ok( !$ok, 'Groq: tools + response_format json_schema croaks in chat_f' );
  like( $err, qr/Groq/, 'Groq json_schema+tools croak names the engine' );
  like( $err, qr/tools with a JSON response_format/,
    'Groq json_schema+tools croak names both conflicting fields' );
  like( $err, qr/400/, 'Groq json_schema+tools croak says the provider rejects it (400)' );
}

# --- Groq: tools + json_object -> croak (k184) ----------------------------
# Live-verified 2026-09-19: Groq 400s json mode + tools for BOTH json_object and
# json_schema with the same message, so the tools branch refuses either type
# (not json_schema-only). Sabotage check: narrow the tools branch back to
# json_schema-only and this goes green (the request reaches the mock instead).
{
  my $engine = groq();
  my ( $ok, $err ) = run( sub { $engine->chat_f(
    messages        => ['weather?'],
    tools           => [$TOOL],
    response_format => $JSON_OBJECT_RF,
  ) });
  ok( !$ok, 'Groq: tools + response_format json_object croaks (k184)' );
  like( $err, qr/Groq/, 'Groq json_object+tools croak names the engine' );
  like( $err, qr/tool/, 'Groq json_object+tools croak names the tool conflict' );
  is( $engine->_async_http->request_count, 0,
    'Groq: json_object+tools request never reached the transport' );
}

# --- Groq: empty tools => [] + json_schema -> NO croak (k169) -------------
# json_schema alone (no tools) is a valid Groq non-streaming request; an empty
# tools array is no tools, so the exclusion must not fire.
{
  my $engine = groq();
  my ( $ok, $err ) = run( sub { $engine->chat_f(
    messages        => ['weather?'],
    tools           => [],
    response_format => $JSON_SCHEMA_RF,
  ) });
  ok( $ok, 'Groq: empty tools => [] + json_schema does NOT croak (k169)' )
    or diag $err;
  is( $engine->_async_http->request_count, 1,
    'Groq: empty-tools json_schema request reached the transport' );
}

# --- Groq: json_schema + streaming -> croak (regardless of tools) ---------
{
  my ( $ok, $err ) = run( sub { groq()->chat_stream_realtime_f(
    messages        => ['weather?'],
    response_format => $JSON_SCHEMA_RF,
  ) });
  ok( !$ok, 'Groq: response_format json_schema croaks on the streaming path (no tools)' );
  like( $err, qr/Groq/, 'Groq streaming croak names the engine' );
  like( $err, qr/json_schema with streaming/,
    'Groq streaming croak names the streaming exclusion' );
  like( $err, qr/400/, 'Groq streaming croak says the provider rejects it (400)' );
}

# --- Groq: json_object on the streaming path ------------------------------
# k184: the tools branch refuses json_object + tools regardless of path, so a
# streaming request carrying tools is refused before transport. But the streaming
# branch itself stays json_schema-only, so json_object WITHOUT tools is NOT
# refused by the exclusion guard on the streaming path (it fails downstream on
# the mock's missing streaming header, not with an exclusion croak).
{
  my ( $ok, $err ) = run( sub { groq()->chat_stream_realtime_f(
    messages        => ['weather?'],
    tools           => [$TOOL],
    response_format => $JSON_OBJECT_RF,
  ) });
  ok( !$ok, 'Groq: json_object + tools croaks on the streaming path too (k184 tools rule)' );
  like( $err, qr/Groq/, 'Groq json_object+tools streaming croak names the engine' );
  like( $err, qr/tool/, 'Groq json_object+tools streaming croak names the tool conflict' );

  my ( $ok2, $err2 ) = run( sub { groq()->chat_stream_realtime_f(
    messages        => ['weather?'],
    response_format => $JSON_OBJECT_RF,
  ) });
  ok( !$ok2, 'Groq: json_object streaming (no tools) still fails on the mock transport' );
  unlike( $err2, qr/Structured Outputs|json_schema|json mode/,
    'Groq: json_object streaming without tools is NOT refused by the exclusion guard' );
}

# ======================================================================
# Scope is EXACTLY Cerebras + Groq — a sibling that advertises both
# tools_native and response_format_json_schema (OpenAI) inherits the base
# no-op hook and must NOT croak on tools + json_schema.
# ======================================================================
{
  my $engine = Langertha::Engine::OpenAI->new(
    api_key     => 'apikey',
    model       => 'gpt-4o-mini',
    _async_http => mock(),
  );
  can_ok( $engine, '_check_capability_exclusions' );
  my ( $ok, $err ) = run( sub { $engine->chat_f(
    messages        => ['weather?'],
    tools           => [$TOOL],
    response_format => $JSON_SCHEMA_RF,
  ) });
  ok( $ok, 'OpenAI: tools + response_format json_schema does NOT croak (base no-op)' )
    or diag $err;
}

# ======================================================================
# karr k249: the guard sees the EFFECTIVE response_format -- the per-request
# value, else the engine attribute (Role::ResponseFormat) -- with the same
# precedence the OpenAICompatible request builder uses to put it on the wire.
# An engine-level response_format used to reach the wire next to the tools
# unguarded, so Groq/Cerebras answered with the opaque 400 the rule exists
# to replace.
# ======================================================================
{
  my $mock = mock();
  my $engine = Langertha::Engine::Groq->new(
    api_key => 'apikey', model => 'llama-3.3-70b-versatile',
    response_format => $JSON_OBJECT_RF, _async_http => $mock,
  );
  my ( $ok, $err ) = run( sub { $engine->chat_f(
    messages => ['weather?'], tools => [$TOOL],
  ) });
  ok( !$ok, 'Groq: engine-level json_object + per-request tools croaks (k249)' );
  like( $err, qr/cannot combine tools with a JSON response_format/,
    'Groq engine-level croak is the exclusion' );
  is( $mock->request_count, 0, 'Groq engine-level: nothing reached the wire' );
}
{
  my ( $ok, $err ) = run( sub { groq( response_format => $JSON_SCHEMA_RF )
    ->chat_stream_realtime_f( messages => ['weather?'] ) });
  ok( !$ok, 'Groq streaming: engine-level json_schema croaks (k249)' );
  like( $err, qr/cannot combine response_format json_schema with streaming/,
    'Groq engine-level streaming croak is the exclusion' );
}
{
  my $mock = mock();
  my ( $ok, $err ) = run( sub { Langertha::Engine::Cerebras->new(
    api_key => 'apikey', model => 'gpt-oss-120b',
    response_format => $JSON_SCHEMA_RF, _async_http => $mock,
  )->chat_f( messages => ['weather?'], tools => [$TOOL] ) });
  ok( !$ok, 'Cerebras: engine-level json_schema + per-request tools croaks (k249)' );
  like( $err, qr/tools and response_format/, 'Cerebras engine-level croak is the exclusion' );
  is( $mock->request_count, 0, 'Cerebras engine-level: nothing reached the wire' );
}
# The per-request value wins over the engine attribute, on the wire and in the
# guard alike: a per-request text format lifts the engine json_object ...
{
  my $mock = mock();
  my ( $ok, $err ) = run( sub { groq( response_format => $JSON_OBJECT_RF, _async_http => $mock )
    ->chat_f( messages => ['weather?'], tools => [$TOOL],
      response_format => { type => 'text' } ) });
  ok( $ok, 'Groq: per-request text overrides engine-level json_object, no croak (k249)' )
    or diag $err;
  my ($req) = $mock->requests;
  is( $req && $json->decode( $req->content )->{response_format}{type}, 'text',
    '  the per-request response_format is the one on the wire' );
}
# ... and a per-request json_object is refused even when the engine holds text.
{
  my ( $ok, $err ) = run( sub { groq( response_format => { type => 'text' } )
    ->chat_f( messages => ['weather?'], tools => [$TOOL],
      response_format => $JSON_OBJECT_RF ) });
  ok( !$ok, 'Groq: per-request json_object beats engine-level text and croaks (k249)' );
  like( $err, qr/cannot combine tools/, '  croak is the exclusion' );
}

done_testing;
