#!/usr/bin/env perl
# ABSTRACT: Per-request response_format must reach the wire on Anthropic, Ollama and Gemini

# karr #45: AnthropicBase::_translate_response_format and Ollama::chat_request
# read only the engine attribute and never looked at %extra, so a per-request
# response_format handed in via chat_f stayed untranslated. On Anthropic it then
# leaked onto the Messages wire as a top-level response_format (HTTP 400); on
# Ollama it was a silent no-op. Precedence is per-request beats per-engine.
#
# karr #48: Gemini::chat_request had the identical defect — a per-request
# response_format landed as a top-level "response_format" on the generateContent
# body while generationConfig.responseJsonSchema stayed empty.

use strict;
use warnings;

use Test2::Bundle::More;
use JSON::MaybeXS;
use HTTP::Response;

use Langertha::Engine::Anthropic;
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

# k182: the first-party output_config.format validator rejects an open schema
# (additionalProperties other than false 400s), so a caller schema that omits
# additionalProperties is normalized to closed on the native path. These are the
# closed forms the wire now carries.
my $CLOSED_SCHEMA       = { %$SCHEMA,       additionalProperties => JSON->false };
my $CLOSED_OTHER_SCHEMA = { %$OTHER_SCHEMA, additionalProperties => JSON->false };

# k183: additionalProperties may be a SCHEMA (a dictionary/map value type), not a
# boolean. Closing the schema must keep it as a subschema and recurse into it,
# never clobber it to false (that would destroy map semantics). `labels` is a
# map<string,string>; `configs` is a map<string,object> whose value object is
# itself closed on the way down; the enclosing object, which omits
# additionalProperties, is still closed to false.
my $MAP_SCHEMA = {
  type       => 'object',
  properties => {
    labels  => { type => 'object', additionalProperties => { type => 'string' } },
    configs => {
      type                 => 'object',
      additionalProperties => {
        type       => 'object',
        properties => { enabled => { type => 'boolean' } },
      },
    },
  },
};
my $CLOSED_MAP_SCHEMA = {
  type                 => 'object',
  additionalProperties => JSON->false,
  properties           => {
    labels  => { type => 'object', additionalProperties => { type => 'string' } },
    configs => {
      type                 => 'object',
      additionalProperties => {
        type                 => 'object',
        additionalProperties => JSON->false,
        properties           => { enabled => { type => 'boolean' } },
      },
    },
  },
};

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

sub wire {
  my ( $engine, %extra ) = @_;
  return $json->decode(
    $engine->chat_request( $engine->chat_messages('testprompt'), %extra )->content
  );
}

# --- Anthropic: per-request json_schema (NATIVE output_config.format) ----
# k133 / ADR 0005 amendment: the first-party Claude Messages API has native
# structured output. Engine::Anthropic emits it as output_config.format instead
# of the legacy synthesized-tool + forced tool_choice rewrite — no tools,
# no tool_choice, no 400 on Fable/Mythos 5.1 (which reject forced tool use).
# k182: the caller's $SCHEMA omits additionalProperties, which the first-party
# validator rejects (open schema -> HTTP 400), so the schema is normalized to
# closed (additionalProperties:false) on the way to the wire — normalize the
# wire quirk rather than gatekeep. Sabotage check: revert _native_structured_output
# to 0 and these go red (tools/tool_choice reappear, output_config.format vanishes).
{
  my $data = wire( anthropic(), response_format => {
    type        => 'json_schema',
    json_schema => { name => 'extract', description => 'extractor', schema => $SCHEMA },
  });

  ok( !exists $data->{response_format},
    'Anthropic: per-request response_format is consumed, not passed to the wire' );
  is_deeply( $data->{output_config}{format}, { type => 'json_schema', schema => $CLOSED_SCHEMA },
    'Anthropic: per-request json_schema becomes native output_config.format, normalized closed' );
  ok( !exists $data->{tools} && !exists $data->{tool_choice},
    'Anthropic: native structured output injects no synthesized tool / tool_choice' );
}

# --- Anthropic: per-request json_object (synthesized-tool path) -----------
# k182: a bare json_object has no schema and output_config.format has no native
# free-form JSON form (an open-object schema 400s, a closed empty object means
# only {}), so first-party Engine::Anthropic routes json_object through the same
# synthesized-tool + forced tool_choice path the /anthropic shims use — a tool
# input_schema is not strict, so the open object passes. Sabotage check: route
# json_object back through output_config.format and this goes red.
{
  my $data = wire( anthropic(), response_format => { type => 'json_object' } );

  ok( !exists $data->{response_format},
    'Anthropic: per-request json_object is consumed, not passed to the wire' );
  ok( !exists $data->{output_config},
    'Anthropic: json_object gets no native output_config.format (no free-form form)' );
  is( scalar @{ $data->{tools} // [] }, 1,
    'Anthropic: json_object injects exactly one synthesized tool' );
  is( $data->{tools}[0]{input_schema}{additionalProperties}, JSON->true,
    'Anthropic: the synthesized json_object tool carries an open input_schema' );
  is( $data->{tool_choice}{type}, 'tool',
    'Anthropic: json_object forces the synthesized tool (model supports forced tool use)' );
  is( $data->{tool_choice}{name}, $data->{tools}[0]{name},
    'Anthropic: the forced tool_choice names the synthesized tool' );
}

# --- Anthropic: json_object degrades to auto where forced tool use 400s ---
# k182 caveat: claude-fable-5-1 / claude-mythos-5-1 reject a forced tool_choice
# (k133 point 2 clears tool_choice_named there). json_object has no clean native
# form on those models either, so it degrades to tool_choice `auto` — best effort,
# never a 400. chat_response lifts the tool_use only if the model chooses to emit it.
for my $model (qw( claude-fable-5-1 claude-mythos-5-1 )) {
  my $data = wire( anthropic( model => $model ), response_format => { type => 'json_object' } );

  ok( !exists $data->{output_config},
    "$model: json_object still gets no native output_config.format" );
  is( scalar @{ $data->{tools} // [] }, 1,
    "$model: json_object still injects the synthesized tool" );
  is_deeply( $data->{tool_choice}, { type => 'auto' },
    "$model: json_object degrades to tool_choice auto (forced tool use 400s)" );
}

# --- Anthropic: output_config.effort and .format MERGE, never clobber -----
# k133 point 3: Langertha::Reasoning::to_anthropic already owns output_config
# for reasoning effort. Native structured output must fold format INTO that
# hash, not replace it. Sabotage check: make _merge_output_config_format
# overwrite instead of merge and effort disappears here.
{
  my $data = wire(
    anthropic( reasoning_effort => 'high' ),
    response_format => {
      type        => 'json_schema',
      json_schema => { name => 'extract', schema => $SCHEMA },
    },
  );

  is( $data->{output_config}{effort}, 'high',
    'Anthropic: output_config.effort survives alongside .format (merged, not clobbered)' );
  is_deeply( $data->{output_config}{format}, { type => 'json_schema', schema => $CLOSED_SCHEMA },
    'Anthropic: output_config.format is present alongside .effort' );
}

# --- Anthropic: per-request beats the engine attribute ------------------
{
  my $engine = anthropic( response_format => {
    type        => 'json_schema',
    json_schema => { name => 'engine_level', schema => $OTHER_SCHEMA },
  });
  my $data = wire( $engine, response_format => {
    type        => 'json_schema',
    json_schema => { name => 'per_request', schema => $SCHEMA },
  });

  is_deeply( $data->{output_config}{format}, { type => 'json_schema', schema => $CLOSED_SCHEMA },
    'Anthropic: per-request response_format wins over the engine attribute' );
}

# --- Anthropic: engine attribute alone still works ----------------------
{
  my $data = wire( anthropic( response_format => {
    type        => 'json_schema',
    json_schema => { name => 'engine_level', schema => $OTHER_SCHEMA },
  }));

  is_deeply( $data->{output_config}{format}, { type => 'json_schema', schema => $CLOSED_OTHER_SCHEMA },
    'Anthropic: engine-attribute response_format still translates to output_config.format' );
}

# --- Anthropic: a caller-supplied CLOSED json_schema is honored natively --
# k182: a schema the caller already closed (additionalProperties:false) is
# native-valid, so it rides output_config.format unchanged and never touches the
# tool path. Normalization is idempotent — it must not re-open or mangle it.
{
  my $data = wire( anthropic(), response_format => {
    type        => 'json_schema',
    json_schema => { name => 'extract', schema => $CLOSED_SCHEMA },
  });

  is_deeply( $data->{output_config}{format}, { type => 'json_schema', schema => $CLOSED_SCHEMA },
    'Anthropic: an already-closed json_schema stays native and unchanged' );
  ok( !exists $data->{tools} && !exists $data->{tool_choice},
    'Anthropic: a closed json_schema needs no synthesized tool' );
}

# --- Anthropic: additionalProperties-as-schema (map) is preserved, recursed --
# k183: an additionalProperties that is a schema HashRef (a dictionary/map value
# type) must survive closing as a subschema, not be clobbered to false. The map's
# value schema is recursed (a map<string,object> value object gets closed too),
# while an enclosing object that omits additionalProperties is still closed.
# Sabotage check: revert _close_schema to `$out{additionalProperties} = false if
# !exists || $out{additionalProperties}` and the map's additionalProperties turns
# to false, turning this red.
{
  my $data = wire( anthropic(), response_format => {
    type        => 'json_schema',
    json_schema => { name => 'extract', schema => $MAP_SCHEMA },
  });

  is_deeply( $data->{output_config}{format}, { type => 'json_schema', schema => $CLOSED_MAP_SCHEMA },
    'Anthropic: additionalProperties-as-schema (map) is kept and recursed, not clobbered to false' );
}

# --- Anthropic: the native structured payload arrives as Response.content -
# ADR 0005 paragraph 3 asks every structured-output path to land the payload
# the same way. Native structured output emits the JSON as an ordinary text
# block, so chat_response's existing text join puts it in Response.content with
# no tool_use lift needed (like Gemini's responseJsonSchema below).
{
  my $engine  = anthropic();
  my $request = $engine->chat_request( $engine->chat_messages('testprompt'),
    response_format => {
      type        => 'json_schema',
      json_schema => { name => 'extract', schema => $SCHEMA },
    },
  );

  my $http = HTTP::Response->new( 200, 'OK', [ 'Content-Type' => 'application/json' ],
    $json->encode({
      id      => 'msg_1',
      model   => 'claude-x',
      content => [ {
        type => 'text',
        text => '{"city":"Wiesbaden"}',
      } ],
    })
  );

  my $response = $request->response_call->($http);
  my $structured = eval { $json->decode( $response->content ) };
  is_deeply( $structured, { city => 'Wiesbaden' },
    'Anthropic: native structured output arrives as Response.content JSON' );
}

# --- Ollama: per-request json_schema ------------------------------------
{
  my $data = wire( ollama(), response_format => {
    type        => 'json_schema',
    json_schema => { name => 'extract', schema => $SCHEMA },
  });

  ok( !exists $data->{response_format},
    'Ollama: per-request response_format is consumed, not passed to the wire' );
  is_deeply( $data->{format}, $SCHEMA,
    'Ollama: per-request json_schema becomes the format schema' );
}

# --- Ollama: per-request json_object ------------------------------------
{
  my $data = wire( ollama(), response_format => { type => 'json_object' } );

  ok( !exists $data->{response_format},
    'Ollama: per-request json_object is consumed, not passed to the wire' );
  is( $data->{format}, 'json', 'Ollama: per-request json_object becomes format=json' );
}

# --- Ollama: per-request beats engine attribute and json_format ---------
{
  my $engine = ollama(
    json_format     => 1,
    response_format => { type => 'json_object' },
  );
  my $data = wire( $engine, response_format => {
    type        => 'json_schema',
    json_schema => { name => 'extract', schema => $SCHEMA },
  });

  is_deeply( $data->{format}, $SCHEMA,
    'Ollama: per-request response_format wins over engine attribute and json_format' );
}

# --- Ollama: engine attribute alone still works -------------------------
{
  my $data = wire( ollama( response_format => {
    type        => 'json_schema',
    json_schema => { name => 'engine_level', schema => $OTHER_SCHEMA },
  }));

  is_deeply( $data->{format}, $OTHER_SCHEMA,
    'Ollama: engine-attribute response_format still translates' );

  my $legacy = wire( ollama( json_format => 1 ) );
  is( $legacy->{format}, 'json', 'Ollama: legacy json_format attribute still works' );
}

# --- Gemini: per-request json_schema ------------------------------------
{
  my $data = wire( gemini(), response_format => {
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

# --- Gemini: per-request json_object ------------------------------------
{
  my $data = wire( gemini(), response_format => { type => 'json_object' } );

  ok( !exists $data->{response_format},
    'Gemini: per-request json_object is consumed, not passed to the wire' );
  is( $data->{generationConfig}{responseMimeType}, 'application/json',
    'Gemini: per-request json_object sets responseMimeType' );
  ok( !exists $data->{generationConfig}{responseJsonSchema},
    'Gemini: json_object leaves responseJsonSchema unset' );
}

# --- Gemini: per-request beats the engine attribute ---------------------
{
  my $engine = gemini( response_format => {
    type        => 'json_schema',
    json_schema => { name => 'engine_level', schema => $OTHER_SCHEMA },
  });
  my $data = wire( $engine, response_format => {
    type        => 'json_schema',
    json_schema => { name => 'per_request', schema => $SCHEMA },
  });

  is_deeply( $data->{generationConfig}{responseJsonSchema}, $SCHEMA,
    'Gemini: per-request response_format wins over the engine attribute' );
}

# --- Gemini: engine attribute alone still works -------------------------
{
  my $data = wire( gemini( response_format => {
    type        => 'json_schema',
    json_schema => { name => 'engine_level', schema => $OTHER_SCHEMA },
  }));

  is_deeply( $data->{generationConfig}{responseJsonSchema}, $OTHER_SCHEMA,
    'Gemini: engine-attribute response_format still translates' );
}

# --- Gemini: the structured payload converges on Response.content -------
# ADR 0005 paragraph 3 asks every structured-output path to land the payload
# the same way. Gemini needs no counterpart to the Anthropic tool_use lift:
# responseJsonSchema makes the model emit the JSON as an ordinary text part, so
# chat_response's existing text join already puts it in Response.content.
{
  my $engine  = gemini();
  my $request = $engine->chat_request( $engine->chat_messages('testprompt'),
    response_format => {
      type        => 'json_schema',
      json_schema => { name => 'extract', schema => $SCHEMA },
    },
  );

  my $http = HTTP::Response->new( 200, 'OK', [ 'Content-Type' => 'application/json' ],
    $json->encode({
      modelVersion => 'gemini-3-flash-preview',
      candidates   => [ {
        finishReason => 'STOP',
        content      => { role => 'model', parts => [
          { text => '{"city":"Wiesbaden"}' },
        ] },
      } ],
    })
  );

  my $response = $request->response_call->($http);
  my $structured = eval { $json->decode( $response->content ) };
  is_deeply( $structured, { city => 'Wiesbaden' },
    'Gemini: per-request structured output arrives as Response.content JSON' );
}

done_testing;
