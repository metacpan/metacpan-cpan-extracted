#!/usr/bin/env perl
# ABSTRACT: Canonical per-request controls (karr #46) land on the right wire per engine family

# karr #46: chat_f normalized only messages/tools/tool_choice; everything else
# was spread as raw target-wire kwargs, so the same call was correct,
# ineffective, or a 400 depending on engine family (temperature/max_tokens on
# Ollama silently lost under options, response_format a 400 on Anthropic, seed
# only honored where the engine happened to advertise it). chat_f now extracts
# a canonical control set (temperature, max_tokens, response_format, seed,
# parallel_tool_use, reasoning_effort, thinking_budget, prompt_cache,
# prompt_cache_ttl, prompt_cache_key, plus the runtime knobs prefix_cache_salt,
# cache_prompt, n_cache_reuse, id_slot, priority,
# return_cached_tokens_details, extra_key) into a `controls` hash that each
# engine's chat_request consumes and places via the same value objects the
# engine attributes use. Unknown keys still pass straight through.

use strict;
use warnings;

use Test2::Bundle::More;
use JSON::MaybeXS;
use HTTP::Response;

use lib 't/lib';
use Test::MockAsyncHTTP;

use Langertha::Engine::OpenAI;
use Langertha::Engine::Anthropic;
use Langertha::Engine::Ollama;
use Langertha::Engine::Gemini;
use Langertha::Engine::vLLM;

my $json = JSON::MaybeXS->new->canonical(1)->utf8(1);

my $SCHEMA = {
  type       => 'object',
  properties => { city => { type => 'string' } },
  required   => ['city'],
};

sub openai {
  return Langertha::Engine::OpenAI->new(
    api_key => 'apikey',
    model   => 'gpt-4o-mini',
    @_,
  );
}

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

sub vllm {
  return Langertha::Engine::vLLM->new(
    url   => 'http://test.url:12345/v1',
    model => 'model',
    @_,
  );
}

# Simulate what chat_f does: canonical controls arrive under `controls`.
sub wire {
  my ( $engine, %extra ) = @_;
  return $json->decode(
    $engine->chat_request( $engine->chat_messages('testprompt'), %extra )->content
  );
}

# Same, but the streaming request builder — control placement must match.
sub wire_stream {
  my ( $engine, %extra ) = @_;
  return $json->decode(
    $engine->chat_stream_request( $engine->chat_messages('testprompt'), %extra )->content
  );
}

# --- _extract_controls: canonical keys out, unknown keys stay -------------
{
  my $engine = openai();
  my %opts = (
    temperature      => 0.3,
    max_tokens       => 100,
    response_format  => { type => 'json_object' },
    seed             => 42,
    parallel_tool_use => 0,
    reasoning_effort => 'high',
    thinking_budget  => 1000,
    prompt_cache     => 1,
    prompt_cache_ttl => 300,
    prompt_cache_key => 'k',
    custom_extra     => 'still-here',
  );
  my $controls = $engine->_extract_controls(\%opts);

  is_deeply( $controls, {
    temperature       => 0.3,
    max_tokens        => 100,
    response_format   => { type => 'json_object' },
    seed              => 42,
    parallel_tool_use => 0,
    reasoning_effort  => 'high',
    thinking_budget   => 1000,
    prompt_cache      => 1,
    prompt_cache_ttl  => 300,
    prompt_cache_key  => 'k',
  }, '_extract_controls pulls every canonical control out of %opts' );
  is_deeply( \%opts, { custom_extra => 'still-here' },
    '_extract_controls leaves unknown keys in %opts' );
}

# --- OpenAI-compatible: controls land top-level ---------------------------
{
  my $data = wire( openai(), controls => {
    temperature      => 0.3,
    max_tokens       => 100,
    seed             => 42,
    reasoning_effort => 'high',
    response_format  => { type => 'json_object' },
  });

  is( $data->{temperature}, 0.3, 'OpenAI: temperature control lands top-level' );
  is( $data->{max_tokens}, 100, 'OpenAI: max_tokens control lands top-level' );
  is( $data->{seed}, 42, 'OpenAI: seed control lands top-level' );
  is( $data->{reasoning_effort}, 'high',
    'OpenAI: reasoning_effort control lands top-level via Langertha::Reasoning' );
  is_deeply( $data->{response_format}, { type => 'json_object' },
    'OpenAI: response_format control lands top-level' );
  ok( !exists $data->{controls}, 'OpenAI: controls hash is consumed, not leaked' );
}

# --- OpenAI-compatible: parallel_tool_use -> parallel_tool_calls ----------
{
  my $data = wire( openai(), controls => { parallel_tool_use => 0 },
    tools => [ { type => 'function', function => { name => 'f', parameters => { type => 'object' } } } ] );

  is( $data->{parallel_tool_calls}, JSON->false,
    'OpenAI: parallel_tool_use=0 control becomes parallel_tool_calls=false' );

  my $on = wire( openai(), controls => { parallel_tool_use => 1 },
    tools => [ { type => 'function', function => { name => 'f', parameters => { type => 'object' } } } ] );
  is( $on->{parallel_tool_calls}, JSON->true,
    'OpenAI: parallel_tool_use=1 control becomes parallel_tool_calls=true' );
}

# --- OpenAI-compatible: per-request control beats engine attribute --------
{
  my $engine = openai( temperature => 0.9, response_size => 500 );
  my $data = wire( $engine, controls => { temperature => 0.1, max_tokens => 77 } );

  is( $data->{temperature}, 0.1, 'OpenAI: per-request temperature beats the attribute' );
  is( $data->{max_tokens}, 77, 'OpenAI: per-request max_tokens beats response_size' );
}

# --- OpenAI gpt-5.x / gpt-6: completion length uses max_completion_tokens --
# The gpt-5.x and gpt-6 lines are reasoning models: they dropped max_tokens
# (HTTP 400, deprecated and not compatible with reasoning models), so the only
# accepted completion-length key is max_completion_tokens. Non-reasoning models
# (gpt-4.x / gpt-4o) keep max_tokens (karr #55, #157).
{
  my $gpt5_control = wire( openai( model => 'gpt-5.1' ), controls => { max_tokens => 100 } );
  is( $gpt5_control->{max_completion_tokens}, 100,
    'OpenAI gpt-5.x: max_tokens control lands as max_completion_tokens' );
  ok( !exists $gpt5_control->{max_tokens},
    'OpenAI gpt-5.x: no max_tokens key on the wire' );

  my $gpt5_attr = wire( openai( model => 'gpt-5.6-terra', response_size => 500 ) );
  is( $gpt5_attr->{max_completion_tokens}, 500,
    'OpenAI gpt-5.x: response_size lands as max_completion_tokens' );

  # gpt-6-astra is a reasoning model like gpt-5.x; the anchored prefix must
  # cover gpt-6 too or the request 400s on max_tokens (karr #157).
  my $gpt6_control = wire( openai( model => 'gpt-6-astra' ), controls => { max_tokens => 100 } );
  is( $gpt6_control->{max_completion_tokens}, 100,
    'OpenAI gpt-6-astra: max_tokens control lands as max_completion_tokens' );
  ok( !exists $gpt6_control->{max_tokens},
    'OpenAI gpt-6-astra: no max_tokens key on the wire' );

  my $gpt6_attr = wire( openai( model => 'gpt-6-astra', response_size => 500 ) );
  is( $gpt6_attr->{max_completion_tokens}, 500,
    'OpenAI gpt-6-astra: response_size lands as max_completion_tokens' );

  my $gpt4 = wire( openai( model => 'gpt-4o', response_size => 500 ) );
  is( $gpt4->{max_tokens}, 500, 'OpenAI gpt-4o: response_size still lands as max_tokens' );
  ok( !exists $gpt4->{max_completion_tokens},
    'OpenAI gpt-4o: no max_completion_tokens key on the wire' );
}

# --- OpenAI-compatible: unknown keys still pass through --------------------
{
  my $data = wire( openai(), controls => { temperature => 0.3 }, custom_extra => 'x' );
  is( $data->{custom_extra}, 'x', 'OpenAI: unknown key still passes straight through' );
}

# --- Anthropic: controls land on the Messages wire ------------------------
{
  my $data = wire( anthropic(), controls => {
    temperature      => 0.3,
    max_tokens       => 100,
    reasoning_effort => 'high',
  });

  is( $data->{temperature}, 0.3, 'Anthropic: temperature control lands top-level' );
  is( $data->{max_tokens}, 100, 'Anthropic: max_tokens control lands top-level' );
  is_deeply( $data->{output_config}, { effort => 'high' },
    'Anthropic: reasoning_effort control lands as output_config.effort' );
  is_deeply( $data->{thinking}, { type => 'adaptive' },
    'Anthropic: reasoning_effort control lands as thinking:{type:adaptive}' );
  ok( !exists $data->{controls}, 'Anthropic: controls hash is consumed, not leaked' );
}

# --- Anthropic: parallel_tool_use -> tool_choice.disable_parallel_tool_use
{
  my $data = wire( anthropic(), controls => { parallel_tool_use => 1 },
    tools => [ { name => 'f', input_schema => { type => 'object' } } ] );

  is( $data->{tool_choice}{disable_parallel_tool_use}, JSON->false,
    'Anthropic: parallel_tool_use=1 control -> disable_parallel_tool_use=false' );

  my $off = wire( anthropic(), controls => { parallel_tool_use => 0 },
    tools => [ { name => 'f', input_schema => { type => 'object' } } ] );
  is( $off->{tool_choice}{disable_parallel_tool_use}, JSON->true,
    'Anthropic: parallel_tool_use=0 control -> disable_parallel_tool_use=true' );
}

# --- Anthropic: response_format control routes through native output_config
# k133: Engine::Anthropic has native structured output, so a response_format
# control lands as output_config.format, not a synthesized forced tool.
{
  my $data = wire( anthropic(), controls => {
    response_format => {
      type        => 'json_schema',
      json_schema => { name => 'extract', schema => $SCHEMA },
    },
  });

  ok( !exists $data->{response_format},
    'Anthropic: response_format control is consumed, not passed to the wire' );
  is_deeply( $data->{output_config}{format},
    { type => 'json_schema', schema => { %$SCHEMA, additionalProperties => JSON->false } },
    'Anthropic: response_format control lands as native output_config.format (normalized closed, k182)' );
  ok( !exists $data->{tools} && !exists $data->{tool_choice},
    'Anthropic: native structured output injects no synthesized tool' );
}

# --- Anthropic: unknown keys still pass through ----------------------------
{
  my $data = wire( anthropic(), controls => { temperature => 0.3 }, custom_extra => 'x' );
  is( $data->{custom_extra}, 'x', 'Anthropic: unknown key still passes straight through' );
}

# --- Ollama: most controls land under options; `think` is TOP-LEVEL --------
# reasoning_effort -> the top-level `think` field, NOT options.think: Ollama
# silently ignores options.think (live-probed 2026-09-17 via ollama.com
# gpt-oss:20b — `think` under options does not grade; k175).
{
  my $data = wire( ollama(), controls => {
    temperature      => 0.3,
    max_tokens       => 100,
    seed             => 42,
    reasoning_effort => 'high',
  });

  is( $data->{options}{temperature}, 0.3,
    'Ollama: temperature control lands under options (not top-level)' );
  ok( !exists $data->{temperature}, 'Ollama: no top-level temperature leak' );
  is( $data->{options}{num_predict}, 100,
    'Ollama: max_tokens control lands as options.num_predict (not top-level)' );
  ok( !exists $data->{max_tokens}, 'Ollama: no top-level max_tokens leak' );
  is( $data->{options}{seed}, 42, 'Ollama: seed control lands under options' );
  is( $data->{think}, JSON->true,
    'Ollama: reasoning_effort control lands as TOP-LEVEL think (not options.think)' );
  ok( !exists $data->{options}{think},
    'Ollama: think does NOT leak into options (options.think is ignored by Ollama)' );
  ok( !exists $data->{controls}, 'Ollama: controls hash is consumed, not leaked' );
}

# --- Ollama: reasoning_effort=none turns top-level think off ---------------
{
  my $data = wire( ollama(), controls => { reasoning_effort => 'none' } );
  is( $data->{think}, JSON->false,
    'Ollama: reasoning_effort=none control -> top-level think=false' );
  ok( !exists $data->{options}{think}, 'Ollama: no options.think leak on none' );
}

# --- Ollama: think placement holds on BOTH request paths + gpt-oss levels --
# The chat (chat_request) and stream (chat_stream_request) builders must place
# `think` identically at top level. gpt-oss takes a graded level STRING (k175);
# it too rides top-level, never under options. Live-probed 2026-09-17 via
# ollama.com gpt-oss:20b.
{
  for my $path ( [ chat => \&wire ], [ stream => \&wire_stream ] ) {
    my ( $name, $build ) = @$path;

    my $b = $build->( ollama(), controls => { reasoning_effort => 'high' } );
    is( $b->{think}, JSON->true,
      "Ollama $name: boolean model reasoning_effort=high -> top-level think=true" );
    ok( !exists $b->{options}{think},
      "Ollama $name: boolean model leaves options.think unset" );

    my $g = $build->( ollama( model => 'gpt-oss:20b' ),
      controls => { reasoning_effort => 'high' } );
    is( $g->{think}, 'high',
      "Ollama $name: gpt-oss reasoning_effort=high -> top-level think=\"high\" (level string)" );
    ok( !exists $g->{options}{think},
      "Ollama $name: gpt-oss leaves options.think unset" );
  }
}

# --- Ollama: response_format control -> format ----------------------------
{
  my $data = wire( ollama(), controls => {
    response_format => {
      type        => 'json_schema',
      json_schema => { name => 'extract', schema => $SCHEMA },
    },
  });

  ok( !exists $data->{response_format},
    'Ollama: response_format control is consumed, not passed to the wire' );
  is_deeply( $data->{format}, $SCHEMA,
    'Ollama: response_format control becomes the format schema' );
}

# --- Ollama: per-request control beats engine attribute -------------------
{
  my $engine = ollama( temperature => 0.9, response_size => 500 );
  my $data = wire( $engine, controls => { temperature => 0.1, max_tokens => 77 } );

  is( $data->{options}{temperature}, 0.1,
    'Ollama: per-request temperature beats the attribute' );
  is( $data->{options}{num_predict}, 77,
    'Ollama: per-request max_tokens beats response_size' );
}

# --- Ollama: unknown keys still pass through -------------------------------
{
  my $data = wire( ollama(), controls => { temperature => 0.3 }, custom_extra => 'x' );
  is( $data->{custom_extra}, 'x', 'Ollama: unknown key still passes straight through' );
}

# --- Gemini: controls land under generationConfig -------------------------
{
  my $data = wire( gemini(), controls => {
    temperature      => 0.3,
    max_tokens       => 100,
    reasoning_effort => 'high',
  });

  is( $data->{generationConfig}{temperature}, 0.3,
    'Gemini: temperature control lands under generationConfig' );
  is( $data->{generationConfig}{maxOutputTokens}, 100,
    'Gemini: max_tokens control lands as generationConfig.maxOutputTokens' );
  is_deeply( $data->{generationConfig}{thinkingConfig}, { thinkingLevel => 'high' },
    'Gemini: reasoning_effort control lands as thinkingConfig.thinkingLevel' );
  ok( !exists $data->{controls}, 'Gemini: controls hash is consumed, not leaked' );
}

# --- Gemini: response_format control -> generationConfig.responseJsonSchema -
{
  my $data = wire( gemini(), controls => {
    response_format => {
      type        => 'json_schema',
      json_schema => { name => 'extract', schema => $SCHEMA },
    },
  });

  ok( !exists $data->{response_format},
    'Gemini: response_format control is consumed, not passed to the wire' );
  is_deeply( $data->{generationConfig}{responseJsonSchema}, $SCHEMA,
    'Gemini: response_format control becomes generationConfig.responseJsonSchema' );
  ok( !exists $data->{generationConfig}{responseSchema},
    'Gemini: deprecated responseSchema is not emitted (k140)' );
}

# --- Gemini: unknown keys still pass through -------------------------------
{
  my $data = wire( gemini(), controls => { temperature => 0.3 }, custom_extra => 'x' );
  is( $data->{custom_extra}, 'x', 'Gemini: unknown key still passes straight through' );
}

# --- End-to-end: chat_f extracts controls and they reach the wire ----------
# Ollama is the discriminating engine: temperature/max_tokens/seed spread as
# raw extras would land top-level (silently ignored by the API), so this test
# only passes when chat_f routes them through the controls channel into
# options.
{
  my $mock = Test::MockAsyncHTTP->new( responses => [
    Test::MockAsyncHTTP->mock_json_response({
      model       => 'model',
      message     => { role => 'assistant', content => 'hello' },
      done_reason => 'stop',
      done        => JSON->true,
    }),
  ]);

  my $engine = ollama( _async_http => $mock );

  my $future = $engine->chat_f(
    messages         => ['hi'],
    temperature      => 0.3,
    max_tokens       => 100,
    seed             => 42,
    reasoning_effort => 'high',
    custom_extra     => 'x',
  );
  my $response = $future->get;

  is( $response->content, 'hello', 'chat_f returns the response' );
  is( $mock->request_count, 1, 'chat_f made exactly one request' );

  my ($request) = $mock->requests;
  my $body = $json->decode( $request->content );
  is( $body->{options}{temperature}, 0.3,
    'chat_f: temperature control reached options.temperature' );
  is( $body->{options}{num_predict}, 100,
    'chat_f: max_tokens control reached options.num_predict' );
  is( $body->{options}{seed}, 42, 'chat_f: seed control reached options.seed' );
  is( $body->{think}, JSON->true,
    'chat_f: reasoning_effort control reached TOP-LEVEL think (not options.think)' );
  ok( !exists $body->{options}{think},
    'chat_f: think does not leak into options' );
  ok( !exists $body->{temperature} && !exists $body->{max_tokens}
    && !exists $body->{seed} && !exists $body->{reasoning_effort},
    'chat_f: no canonical control leaked top-level (raw-extra path not used)' );
  is( $body->{custom_extra}, 'x', 'chat_f: unknown key still passes straight through' );
  ok( !exists $body->{controls}, 'chat_f: controls hash never reaches the wire' );
}

# --- End-to-end: vLLM knob controls reach the wire via the controls channel --
# vLLM is the discriminating engine for runtime knobs: prefix_cache_salt is a
# canonical control that must be translated to the wire name cache_salt. If it
# were left in %opts as a raw extra it would land top-level as
# 'prefix_cache_salt' (wrong wire name). The raw-extra escape hatch
# (chat_f(cache_salt => 'x')) must still pass through unchanged.
{
  my $mock = Test::MockAsyncHTTP->new( responses => [
    Test::MockAsyncHTTP->mock_json_response({
      choices => [{
        message => { role => 'assistant', content => 'hello' },
      }],
    }),
  ]);

  my $engine = vllm( _async_http => $mock );

  my $future = $engine->chat_f( prefix_cache_salt => 'x' );
  my $response = $future->get;

  is( $response->content, 'hello', 'vLLM chat_f returns the response' );
  is( $mock->request_count, 1, 'vLLM chat_f made exactly one request' );

  my ($request) = $mock->requests;
  my $body = $json->decode( $request->content );
  is( $body->{cache_salt}, 'x',
    'chat_f: prefix_cache_salt control lands top-level as cache_salt' );
  ok( !exists $body->{prefix_cache_salt},
    'chat_f: canonical knob name never leaks to the wire' );
  ok( !exists $body->{controls}, 'chat_f: controls hash never reaches the wire' );

  # Raw-extra escape hatch: cache_salt is not a canonical control, so it stays
  # in %opts and passes straight through under its own wire name.
  my $mock2 = Test::MockAsyncHTTP->new( responses => [
    Test::MockAsyncHTTP->mock_json_response({
      choices => [{
        message => { role => 'assistant', content => 'hello' },
      }],
    }),
  ]);
  my $engine2 = vllm( _async_http => $mock2 );

  my $future2 = $engine2->chat_f( cache_salt => 'y' );
  $future2->get;

  my ($request2) = $mock2->requests;
  my $body2 = $json->decode( $request2->content );
  is( $body2->{cache_salt}, 'y',
    'chat_f: raw cache_salt extra passes through top-level unchanged' );
  ok( !exists $body2->{controls}, 'chat_f: raw-extra path leaks no controls hash' );
}

done_testing;
