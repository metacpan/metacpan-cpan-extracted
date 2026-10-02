#!/usr/bin/env perl
# ABSTRACT: Per-request response_format must reach the streaming wire on Anthropic, Ollama and Gemini

# karr #52: chat_stream_request ignored response_format in all three engines —
# an engine-attribute response_format was silently dropped on streaming, and a
# per-request one would have leaked as a top-level field once #42
# (chat_stream_realtime_f with %opts) opened the pass-through path.
#
# Gemini and Ollama now translate response_format to their native wire form
# (generationConfig.responseJsonSchema / format) exactly like chat_request, with
# per-request beating the engine attribute and the key deleted from the extras.
#
# Anthropic-family engines have no native response_format and no streaming
# counterpart to the chat_response tool_use lift (ADR 0005 paragraph 2), so
# chat_stream_request consumes the key and croaks instead of leaking it (HTTP
# 400) or silently streaming unstructured text.

use strict;
use warnings;

use Test2::Bundle::More;
use JSON::MaybeXS;

use Langertha::Engine::Anthropic;
use Langertha::Engine::LMStudioAnthropic;
use Langertha::Engine::Ollama;
use Langertha::Engine::Gemini;

my $json = JSON::MaybeXS->new->canonical(1)->utf8(1);

my $SCHEMA = {
  type       => 'object',
  properties => { city => { type => 'string' } },
  required   => ['city'],
};
my $OTHER_SCHEMA = {
  type       => 'object',
  properties => { country => { type => 'string' } },
};

# k182: the first-party output_config.format validator rejects an open schema, so
# a caller schema that omits additionalProperties is normalized to closed on the
# native streaming path too. These are the closed forms the wire now carries.
my $CLOSED_SCHEMA       = { %$SCHEMA,       additionalProperties => JSON->false };
my $CLOSED_OTHER_SCHEMA = { %$OTHER_SCHEMA, additionalProperties => JSON->false };

sub anthropic {
  return Langertha::Engine::Anthropic->new(
    api_key       => 'apikey',
    model         => 'claude-x',
    response_size => 256,
    @_,
  );
}

sub ollama {
  return Langertha::Engine::Ollama->new(
    url   => 'http://test.url:12345',
    model => 'model',
    @_,
  );
}

sub gemini {
  return Langertha::Engine::Gemini->new(
    api_key => 'apikey',
    model   => 'gemini-3-flash-preview',
    @_,
  );
}

sub stream_wire {
  my ( $engine, %extra ) = @_;
  return $json->decode(
    $engine->chat_stream_request( $engine->chat_messages('testprompt'), %extra )->content
  );
}

# --- Anthropic (native): streaming structured output goes native, streams -
# k133: with native structured output (output_config.format) there is no
# synthesized tool_use to lift, so the JSON streams as ordinary text deltas.
# Engine::Anthropic therefore emits output_config.format on the stream instead
# of croaking. k182: the caller's open $SCHEMA is normalized to closed here too.
# Sabotage check: revert _native_structured_output to 0 and this reverts to the
# shim croak below.
{
  my $data = stream_wire( anthropic(), response_format => {
    type        => 'json_schema',
    json_schema => { name => 'extract', description => 'extractor', schema => $SCHEMA },
  });

  ok( !exists $data->{response_format},
    'Anthropic: streaming response_format is consumed, not passed to the wire' );
  is_deeply( $data->{output_config}{format}, { type => 'json_schema', schema => $CLOSED_SCHEMA },
    'Anthropic: streaming json_schema becomes native output_config.format, normalized closed' );
  is( $data->{stream}, JSON->true, 'Anthropic: structured stream still streams' );
  ok( !exists $data->{tools} && !exists $data->{tool_choice},
    'Anthropic: native structured stream injects no synthesized tool' );
}

# --- Anthropic (native): streaming json_object is refused ------------------
# k182: a bare json_object has no native free-form form (output_config.format
# needs a closed schema) and the synthesized-tool fallback has no streaming lift,
# so first-party Engine::Anthropic consumes the key and croaks rather than 400 on
# the wire or stream unstructured text — mirroring the shim behavior below.
{
  my $ok = eval {
    anthropic()->chat_stream_request( anthropic()->chat_messages('p'),
      response_format => { type => 'json_object' } );
    1;
  };
  ok( !$ok, 'Anthropic: streaming json_object croaks' );
  like( $@, qr/cannot stream a json_object response_format/,
    'Anthropic: croak names the json_object streaming limitation' );
  like( $@, qr/chat_f\/chat_request/,
    'Anthropic: croak points at the non-streaming structured-output path' );
}

# --- Anthropic (native): engine-attribute response_format streams too -----
{
  my $engine = anthropic( response_format => {
    type        => 'json_schema',
    json_schema => { name => 'engine_level', schema => $OTHER_SCHEMA },
  });
  my $data = stream_wire($engine);
  is_deeply( $data->{output_config}{format}, { type => 'json_schema', schema => $CLOSED_OTHER_SCHEMA },
    'Anthropic: engine-attribute response_format streams as native output_config.format' );
}

# --- Anthropic (shim): streaming structured output is still refused -------
# The legacy /anthropic shim engines have no native form and no streaming lift
# for the synthesized-tool rewrite, so they consume the key and croak rather
# than leak it (HTTP 400) or stream unstructured text (karr #52).
{
  my $shim = Langertha::Engine::LMStudioAnthropic->new(
    url => 'http://test.url:12345', model => 'model', response_size => 256,
  );
  my $ok = eval { $shim->chat_stream_request( $shim->chat_messages('p'), response_format => {
    type        => 'json_schema',
    json_schema => { name => 'extract', schema => $SCHEMA },
  }); 1 };
  ok( !$ok, 'Anthropic shim: streaming json_schema croaks' );
  like( $@, qr/cannot stream response_format/,
    'Anthropic shim: croak names the streaming limitation' );
  like( $@, qr/chat_f\/chat_request/,
    'Anthropic shim: croak points at the non-streaming structured-output path' );
}

# --- Anthropic: a response_format the engine would ignore stays a no-op ---
# An unknown type has no native form either, so it is consumed and dropped.
{
  my $data = stream_wire( anthropic(), response_format => { type => 'text' } );

  ok( !exists $data->{response_format},
    'Anthropic: non-honored response_format is consumed, not passed to the wire' );
  ok( !exists $data->{output_config},
    'Anthropic: non-honored response_format sets no output_config.format' );
  is( $data->{stream}, JSON->true, 'Anthropic: stream request still streams' );
  ok( !exists $data->{tools} && !exists $data->{tool_choice},
    'Anthropic: no synthesized tool is injected for a non-honored response_format' );
}

# --- Anthropic: plain streaming is unaffected -----------------------------
{
  my $data = stream_wire( anthropic() );

  is( $data->{stream}, JSON->true, 'Anthropic: plain stream request streams' );
  ok( !exists $data->{response_format},
    'Anthropic: no response_format key on a plain stream request' );
}

# --- Ollama: per-request json_schema -------------------------------------
{
  my $data = stream_wire( ollama(), response_format => {
    type        => 'json_schema',
    json_schema => { name => 'extract', schema => $SCHEMA },
  });

  ok( !exists $data->{response_format},
    'Ollama: per-request response_format is consumed, not passed to the wire' );
  is_deeply( $data->{format}, $SCHEMA,
    'Ollama: per-request json_schema becomes the format schema' );
  is( $data->{stream}, JSON->true, 'Ollama: stream request still streams' );
}

# --- Ollama: per-request json_object -------------------------------------
{
  my $data = stream_wire( ollama(), response_format => { type => 'json_object' } );

  ok( !exists $data->{response_format},
    'Ollama: per-request json_object is consumed, not passed to the wire' );
  is( $data->{format}, 'json', 'Ollama: per-request json_object becomes format=json' );
}

# --- Ollama: per-request beats engine attribute and json_format ----------
{
  my $engine = ollama(
    json_format     => 1,
    response_format => { type => 'json_object' },
  );
  my $data = stream_wire( $engine, response_format => {
    type        => 'json_schema',
    json_schema => { name => 'extract', schema => $SCHEMA },
  });

  is_deeply( $data->{format}, $SCHEMA,
    'Ollama: per-request response_format wins over engine attribute and json_format' );
}

# --- Ollama: engine attribute alone still works ---------------------------
{
  my $data = stream_wire( ollama( response_format => {
    type        => 'json_schema',
    json_schema => { name => 'engine_level', schema => $OTHER_SCHEMA },
  }));

  is_deeply( $data->{format}, $OTHER_SCHEMA,
    'Ollama: engine-attribute response_format still translates on streaming' );

  my $legacy = stream_wire( ollama( json_format => 1 ) );
  is( $legacy->{format}, 'json', 'Ollama: legacy json_format attribute still works on streaming' );
}

# --- Gemini: per-request json_schema -------------------------------------
{
  my $data = stream_wire( gemini(), response_format => {
    type        => 'json_schema',
    json_schema => { name => 'extract', schema => $SCHEMA },
  });

  ok( !exists $data->{response_format},
    'Gemini: per-request response_format is consumed, not passed to the wire' );
  is_deeply( $data->{generationConfig}{responseJsonSchema}, $SCHEMA,
    'Gemini: per-request json_schema becomes generationConfig.responseJsonSchema' );
  ok( !exists $data->{generationConfig}{responseSchema},
    'Gemini: deprecated responseSchema is not emitted (k140)' );
  is( $data->{generationConfig}{responseMimeType}, 'application/json',
    'Gemini: per-request json_schema sets responseMimeType' );
}

# --- Gemini: per-request json_object -------------------------------------
{
  my $data = stream_wire( gemini(), response_format => { type => 'json_object' } );

  ok( !exists $data->{response_format},
    'Gemini: per-request json_object is consumed, not passed to the wire' );
  is( $data->{generationConfig}{responseMimeType}, 'application/json',
    'Gemini: per-request json_object sets responseMimeType' );
  ok( !exists $data->{generationConfig}{responseJsonSchema},
    'Gemini: json_object leaves responseJsonSchema unset' );
}

# --- Gemini: per-request beats the engine attribute ----------------------
{
  my $engine = gemini( response_format => {
    type        => 'json_schema',
    json_schema => { name => 'engine_level', schema => $OTHER_SCHEMA },
  });
  my $data = stream_wire( $engine, response_format => {
    type        => 'json_schema',
    json_schema => { name => 'per_request', schema => $SCHEMA },
  });

  is_deeply( $data->{generationConfig}{responseJsonSchema}, $SCHEMA,
    'Gemini: per-request response_format wins over the engine attribute on streaming' );
}

# --- Gemini: engine attribute alone still works --------------------------
{
  my $data = stream_wire( gemini( response_format => {
    type        => 'json_schema',
    json_schema => { name => 'engine_level', schema => $OTHER_SCHEMA },
  }));

  is_deeply( $data->{generationConfig}{responseJsonSchema}, $OTHER_SCHEMA,
    'Gemini: engine-attribute response_format still translates on streaming' );
}

done_testing;
