#!/usr/bin/env perl
# ABSTRACT: Test engine base class hierarchy and role composition

use strict;
use warnings;

use Test2::Bundle::More;
use JSON::MaybeXS;

my $json = JSON::MaybeXS->new->canonical(1)->utf8(1);

# ======================================================================
# Part 1: Inheritance chain verification
# ======================================================================

# --- Remote base class ---

use Langertha::Engine::Remote;

ok(Langertha::Engine::Remote->isa('Moose::Object'), 'Remote isa Moose::Object');
ok(Langertha::Engine::Remote->does('Langertha::Role::JSON'), 'Remote does JSON');
ok(Langertha::Engine::Remote->does('Langertha::Role::HTTP'), 'Remote does HTTP');

# url is required on Remote
eval { Langertha::Engine::Remote->new() };
like($@, qr/url/, 'Remote requires url');

# --- OpenAIBase inherits Remote ---

use Langertha::Engine::OpenAIBase;

ok(Langertha::Engine::OpenAIBase->isa('Langertha::Engine::Remote'), 'OpenAIBase isa Remote');
ok(Langertha::Engine::OpenAIBase->does('Langertha::Role::JSON'), 'OpenAIBase inherits JSON from Remote');
ok(Langertha::Engine::OpenAIBase->does('Langertha::Role::HTTP'), 'OpenAIBase inherits HTTP from Remote');
ok(Langertha::Engine::OpenAIBase->does('Langertha::Role::OpenAICompatible'), 'OpenAIBase does OpenAICompatible');
ok(Langertha::Engine::OpenAIBase->does('Langertha::Role::OpenAPI'), 'OpenAIBase does OpenAPI');
ok(Langertha::Engine::OpenAIBase->does('Langertha::Role::Models'), 'OpenAIBase does Models');
ok(Langertha::Engine::OpenAIBase->does('Langertha::Role::Temperature'), 'OpenAIBase does Temperature');
ok(Langertha::Engine::OpenAIBase->does('Langertha::Role::ResponseSize'), 'OpenAIBase does ResponseSize');
ok(Langertha::Engine::OpenAIBase->does('Langertha::Role::SystemPrompt'), 'OpenAIBase does SystemPrompt');
ok(Langertha::Engine::OpenAIBase->does('Langertha::Role::Streaming'), 'OpenAIBase does Streaming');
ok(Langertha::Engine::OpenAIBase->does('Langertha::Role::Chat'), 'OpenAIBase does Chat');

# url still required (inherited from Remote)
eval { Langertha::Engine::OpenAIBase->new() };
like($@, qr/url/, 'OpenAIBase requires url');

# default_model croaks (must be overridden)
{
  my $base = Langertha::Engine::OpenAIBase->new(url => 'http://test.invalid');
  eval { $base->default_model };
  like($@, qr/requires model/, 'OpenAIBase default_model croaks');
}

# --- AnthropicBase inherits Remote ---

use Langertha::Engine::AnthropicBase;

ok(Langertha::Engine::AnthropicBase->isa('Langertha::Engine::Remote'), 'AnthropicBase isa Remote');
ok(Langertha::Engine::AnthropicBase->does('Langertha::Role::Models'), 'AnthropicBase does Models');
ok(Langertha::Engine::AnthropicBase->does('Langertha::Role::Chat'), 'AnthropicBase does Chat');
ok(Langertha::Engine::AnthropicBase->does('Langertha::Role::Streaming'), 'AnthropicBase does Streaming');
ok(Langertha::Engine::AnthropicBase->does('Langertha::Role::Tools'), 'AnthropicBase does Tools');
ok(!Langertha::Engine::AnthropicBase->does('Langertha::Role::OpenAICompatible'), 'AnthropicBase does NOT OpenAICompatible');

{
  my $base = Langertha::Engine::AnthropicBase->new(url => 'http://test.invalid', api_key => 'test-key');
  eval { $base->default_model };
  like($@, qr/requires model/, 'AnthropicBase default_model croaks');
}

# ======================================================================
# Part 2: Non-OpenAI engines (extend Remote directly)
# ======================================================================

# --- Anthropic ---

use Langertha::Engine::Anthropic;

ok(Langertha::Engine::Anthropic->isa('Langertha::Engine::Remote'), 'Anthropic isa Remote');
ok(Langertha::Engine::Anthropic->isa('Langertha::Engine::AnthropicBase'), 'Anthropic isa AnthropicBase');
ok(!Langertha::Engine::Anthropic->isa('Langertha::Engine::OpenAIBase'), 'Anthropic is NOT OpenAIBase');
ok(Langertha::Engine::Anthropic->does('Langertha::Role::Chat'), 'Anthropic does Chat');
ok(Langertha::Engine::Anthropic->does('Langertha::Role::Streaming'), 'Anthropic does Streaming');
ok(Langertha::Engine::Anthropic->does('Langertha::Role::Tools'), 'Anthropic does Tools');
ok(!Langertha::Engine::Anthropic->does('Langertha::Role::OpenAICompatible'), 'Anthropic does NOT OpenAICompatible');

{
  my $a = Langertha::Engine::Anthropic->new(api_key => 'test-key');
  is($a->url, 'https://api.anthropic.com', 'Anthropic url defaults correctly');
  is($a->default_model, 'claude-sonnet-4-6', 'Anthropic default_model');
  my $req = $a->chat('hello');
  is($req->header('x-api-key'), 'test-key', 'Anthropic uses x-api-key header');
  is($req->header('content-type'), 'application/json', 'Anthropic sets content-type');
  like($req->uri, qr{/v1/messages$}, 'Anthropic chat endpoint');
}

# --- Gemini ---

use Langertha::Engine::Gemini;

ok(Langertha::Engine::Gemini->isa('Langertha::Engine::Remote'), 'Gemini isa Remote');
ok(!Langertha::Engine::Gemini->isa('Langertha::Engine::OpenAIBase'), 'Gemini is NOT OpenAIBase');
ok(Langertha::Engine::Gemini->does('Langertha::Role::Chat'), 'Gemini does Chat');
ok(Langertha::Engine::Gemini->does('Langertha::Role::Tools'), 'Gemini does Tools');

{
  my $g = Langertha::Engine::Gemini->new(api_key => 'test-key');
  is($g->url, 'https://generativelanguage.googleapis.com', 'Gemini url defaults correctly');
  is($g->default_model, 'gemini-2.5-flash', 'Gemini default_model');
  my $req = $g->chat('hello');
  like($req->uri, qr{/v1beta/models/gemini-2\.5-flash:generateContent}, 'Gemini chat endpoint');
  like($req->uri, qr{key=test-key}, 'Gemini api_key in URL');
}

# --- Ollama ---

use Langertha::Engine::Ollama;

ok(Langertha::Engine::Ollama->isa('Langertha::Engine::Remote'), 'Ollama isa Remote');
ok(!Langertha::Engine::Ollama->isa('Langertha::Engine::OpenAIBase'), 'Ollama is NOT OpenAIBase');
ok(Langertha::Engine::Ollama->does('Langertha::Role::Chat'), 'Ollama does Chat');
ok(Langertha::Engine::Ollama->does('Langertha::Role::Embedding'), 'Ollama does Embedding');
ok(Langertha::Engine::Ollama->does('Langertha::Role::Tools'), 'Ollama does Tools');
ok(Langertha::Engine::Ollama->does('Langertha::Role::OpenAPI'), 'Ollama does OpenAPI');

{
  # url is required (local server, no default)
  eval { Langertha::Engine::Ollama->new(model => 'test') };
  like($@, qr/url/, 'Ollama requires url');

  my $o = Langertha::Engine::Ollama->new(url => 'http://test.invalid:11434', model => 'llama3.3');
  is($o->default_model, 'llama3.3', 'Ollama model set');
  my $req = $o->chat('hello');
  like($req->uri, qr{/api/chat$}, 'Ollama uses native /api/chat endpoint');
}

# --- LMStudio ---

use Langertha::Engine::LMStudio;

ok(Langertha::Engine::LMStudio->isa('Langertha::Engine::Remote'), 'LMStudio isa Remote');
ok(!Langertha::Engine::LMStudio->isa('Langertha::Engine::OpenAIBase'), 'LMStudio is NOT OpenAIBase');
ok(Langertha::Engine::LMStudio->does('Langertha::Role::Models'), 'LMStudio does Models');
ok(Langertha::Engine::LMStudio->does('Langertha::Role::OpenAPI'), 'LMStudio does OpenAPI');
ok(Langertha::Engine::LMStudio->does('Langertha::Role::Chat'), 'LMStudio does Chat');
ok(Langertha::Engine::LMStudio->does('Langertha::Role::Streaming'), 'LMStudio does Streaming');
ok(Langertha::Engine::LMStudio->does('Langertha::Role::Temperature'), 'LMStudio does Temperature');
ok(Langertha::Engine::LMStudio->does('Langertha::Role::ResponseSize'), 'LMStudio does ResponseSize');
ok(Langertha::Engine::LMStudio->does('Langertha::Role::ContextSize'), 'LMStudio does ContextSize');

{
  my $lm = Langertha::Engine::LMStudio->new(model => 'test-model');
  is($lm->url, 'http://localhost:1234', 'LMStudio url defaults correctly');
  is($lm->default_model, 'default', 'LMStudio default_model');
  is($lm->api_key, undef, 'LMStudio api_key is undef when not configured');

  my $req = $lm->chat('hello');
  like($req->uri, qr{/api/v1/chat$}, 'LMStudio chat endpoint');
  is($req->header('Authorization'), undef, 'LMStudio no Authorization header by default');
  ok($lm->can_operation('chat'), 'LMStudio supports OpenAPI operation chat');
  ok($lm->can_operation('listModels'), 'LMStudio supports OpenAPI operation listModels');

  my $body = $json->decode($req->content);
  is($body->{model}, 'test-model', 'LMStudio request has model');
  is($body->{input}, 'hello', 'LMStudio request maps message to input');

  my $oai = $lm->openai;
  ok($oai->isa('Langertha::Engine::LMStudioOpenAI'), 'LMStudio->openai returns LMStudioOpenAI engine');
  is($oai->url, 'http://localhost:1234/v1', 'LMStudio->openai uses /v1 endpoint');
  is($oai->model, 'test-model', 'LMStudio->openai carries model');
  is($oai->api_key, 'lmstudio', 'LMStudio->openai defaults api_key to lmstudio');

  my $anth = $lm->anthropic;
  ok($anth->isa('Langertha::Engine::LMStudioAnthropic'), 'LMStudio->anthropic returns LMStudioAnthropic engine');
  is($anth->url, 'http://localhost:1234', 'LMStudio->anthropic keeps base URL');
  is($anth->model, 'test-model', 'LMStudio->anthropic carries model');
}

{
  local $ENV{LANGERTHA_LMSTUDIO_API_KEY} = 'env-key-12345';
  my $lm = Langertha::Engine::LMStudio->new(model => 'test-model');
  is($lm->api_key, 'env-key-12345', 'LMStudio reads api_key from LANGERTHA_LMSTUDIO_API_KEY');
  my $req = $lm->chat('hello');
  is($req->header('Authorization'), 'Bearer env-key-12345', 'LMStudio sets Bearer header when api_key configured');

  my $oai = $lm->openai;
  is($oai->api_key, 'env-key-12345', 'LMStudio->openai carries api_key');

  my $anth = $lm->anthropic;
  is($anth->api_key, 'env-key-12345', 'LMStudio->anthropic carries api_key');
}

{
  my $lm = Langertha::Engine::LMStudio->new(
    model => 'test-model',
    system_prompt => 'You are test',
    context_size => 4096,
    response_size => 333,
    temperature => 0.1,
  );
  my $req = $lm->chat('hello');
  my $body = $json->decode($req->content);
  is($body->{system_prompt}, 'You are test', 'LMStudio sends system_prompt');
  is($body->{context_length}, 4096, 'LMStudio maps context_size to context_length');
  is($body->{max_output_tokens}, 333, 'LMStudio maps response_size to max_output_tokens');
  is($body->{temperature}, 0.1, 'LMStudio passes temperature');
}

# --- LMStudioOpenAI ---

use Langertha::Engine::LMStudioOpenAI;

ok(Langertha::Engine::LMStudioOpenAI->isa('Langertha::Engine::OpenAIBase'), 'LMStudioOpenAI isa OpenAIBase');
ok(Langertha::Engine::LMStudioOpenAI->isa('Langertha::Engine::Remote'), 'LMStudioOpenAI isa Remote');
ok(Langertha::Engine::LMStudioOpenAI->does('Langertha::Role::Embedding'), 'LMStudioOpenAI does Embedding');
ok(Langertha::Engine::LMStudioOpenAI->does('Langertha::Role::Tools'), 'LMStudioOpenAI does Tools');

{
  my $lm = Langertha::Engine::LMStudioOpenAI->new(model => 'test-model');
  is($lm->url, 'http://localhost:1234/v1', 'LMStudioOpenAI url defaults correctly');
  is($lm->default_model, 'default', 'LMStudioOpenAI default_model');
  is($lm->api_key, 'lmstudio', 'LMStudioOpenAI api_key defaults to lmstudio');
  my $req = $lm->chat('hello');
  like($req->uri, qr{/chat/completions$}, 'LMStudioOpenAI uses /chat/completions');
  is($req->header('Authorization'), 'Bearer lmstudio', 'LMStudioOpenAI sets default bearer header');
}

{
  local $ENV{LANGERTHA_LMSTUDIO_API_KEY} = 'env-key-12345';
  my $lm = Langertha::Engine::LMStudioOpenAI->new(model => 'test-model');
  is($lm->api_key, 'env-key-12345', 'LMStudioOpenAI reads api_key from LANGERTHA_LMSTUDIO_API_KEY');
}

# --- LMStudioAnthropic ---

use Langertha::Engine::LMStudioAnthropic;

ok(Langertha::Engine::LMStudioAnthropic->isa('Langertha::Engine::AnthropicBase'), 'LMStudioAnthropic isa AnthropicBase');
ok(Langertha::Engine::LMStudioAnthropic->isa('Langertha::Engine::Remote'), 'LMStudioAnthropic isa Remote');
ok(!Langertha::Engine::LMStudioAnthropic->isa('Langertha::Engine::OpenAIBase'), 'LMStudioAnthropic is NOT OpenAIBase');
ok(Langertha::Engine::LMStudioAnthropic->does('Langertha::Role::Chat'), 'LMStudioAnthropic does Chat');
ok(Langertha::Engine::LMStudioAnthropic->does('Langertha::Role::Streaming'), 'LMStudioAnthropic does Streaming');
ok(Langertha::Engine::LMStudioAnthropic->does('Langertha::Role::Tools'), 'LMStudioAnthropic does Tools');

{
  my $lm = Langertha::Engine::LMStudioAnthropic->new(model => 'test-model');
  is($lm->url, 'http://localhost:1234', 'LMStudioAnthropic url defaults correctly');
  is($lm->api_key, 'lmstudio', 'LMStudioAnthropic api_key defaults to lmstudio');
  is($lm->default_model, 'default', 'LMStudioAnthropic default_model');

  my $req = $lm->chat('hello');
  like($req->uri, qr{/v1/messages$}, 'LMStudioAnthropic uses Anthropic messages endpoint');
  is($req->header('x-api-key'), 'lmstudio', 'LMStudioAnthropic sets x-api-key');
  is($req->header('anthropic-version'), '2023-06-01', 'LMStudioAnthropic sets anthropic-version');
}

{
  local $ENV{LANGERTHA_LMSTUDIO_API_KEY} = 'env-key-12345';
  my $lm = Langertha::Engine::LMStudioAnthropic->new(model => 'test-model');
  is($lm->api_key, 'env-key-12345', 'LMStudioAnthropic reads api_key from LANGERTHA_LMSTUDIO_API_KEY');
}

# --- AKI ---

use Langertha::Engine::AKI;

ok(Langertha::Engine::AKI->isa('Langertha::Engine::Remote'), 'AKI isa Remote');
ok(!Langertha::Engine::AKI->isa('Langertha::Engine::OpenAIBase'), 'AKI is NOT OpenAIBase');
ok(Langertha::Engine::AKI->does('Langertha::Role::Chat'), 'AKI does Chat');
ok(!Langertha::Engine::AKI->does('Langertha::Role::OpenAICompatible'), 'AKI does NOT OpenAICompatible');

{
  my $a = Langertha::Engine::AKI->new(api_key => 'test-key');
  is($a->url, 'https://aki.io', 'AKI url defaults correctly');
  is($a->default_model, 'llama3_8b_chat', 'AKI default_model');
}

# ======================================================================
# Part 3: OpenAI-compatible cloud engines (extend OpenAIBase + url default)
# ======================================================================

# Helper: verify an OpenAIBase engine with api_key + url default
sub test_openai_cloud_engine {
  my (%p) = @_;
  my $class = $p{class};
  my $expected_url = $p{url};
  my $expected_model = $p{model};
  my $env_var = $p{env_var};
  my $has_tools = $p{has_tools} // 1;
  my $has_embedding = $p{has_embedding} // 0;
  my $has_transcription = $p{has_transcription} // 0;
  my $has_response_format = $p{has_response_format} // 0;
  my $name = $p{name};

  # Inheritance
  ok($class->isa('Langertha::Engine::OpenAIBase'), "$name isa OpenAIBase");
  ok($class->isa('Langertha::Engine::Remote'), "$name isa Remote");
  ok($class->does('Langertha::Role::OpenAICompatible'), "$name does OpenAICompatible");
  ok($class->does('Langertha::Role::Chat'), "$name does Chat");
  ok($class->does('Langertha::Role::Streaming'), "$name does Streaming");

  # Conditional roles
  if ($has_tools) {
    ok($class->does('Langertha::Role::Tools'), "$name does Tools");
  } else {
    ok(!$class->does('Langertha::Role::Tools'), "$name does NOT Tools");
  }
  if ($has_embedding) {
    ok($class->does('Langertha::Role::Embedding'), "$name does Embedding");
  }
  if ($has_transcription) {
    ok($class->does('Langertha::Role::Transcription'), "$name does Transcription");
  }
  if ($has_response_format) {
    ok($class->does('Langertha::Role::ResponseFormat'), "$name does ResponseFormat");
  }

  # Instantiation + url default
  my $engine = $class->new(api_key => 'test-key', model => 'test-model');
  is($engine->url, $expected_url, "$name url default correct");

  # api_key from env
  {
    local $ENV{$env_var} = 'env-key-12345';
    my $e2 = $class->new(model => 'test-model');
    is($e2->api_key, 'env-key-12345', "$name reads api_key from $env_var");
  }

  # Chat request generation
  my $req = $engine->chat('test prompt');
  is($req->method, 'POST', "$name chat request is POST");
  like($req->uri, qr{/chat/completions$}, "$name chat endpoint is /chat/completions");
  is($req->header('Authorization'), 'Bearer test-key', "$name sets Authorization header");

  my $body = $json->decode($req->content);
  is($body->{model}, 'test-model', "$name request has correct model");
  is($body->{messages}[0]{role}, 'user', "$name request has user message");
  is($body->{messages}[0]{content}, 'test prompt', "$name request has correct content");
}

# --- OpenAI ---

use Langertha::Engine::OpenAI;

test_openai_cloud_engine(
  class => 'Langertha::Engine::OpenAI',
  name => 'OpenAI',
  url => 'https://api.openai.com/v1',
  model => 'gpt-4o-mini',
  env_var => 'LANGERTHA_OPENAI_API_KEY',
  has_tools => 1,
  has_embedding => 1,
  has_transcription => 1,
  has_response_format => 1,
);
is(Langertha::Engine::OpenAI->new(api_key => 'k')->default_model, 'gpt-4o-mini', 'OpenAI default_model');

# --- DeepSeek ---

use Langertha::Engine::DeepSeek;

test_openai_cloud_engine(
  class => 'Langertha::Engine::DeepSeek',
  name => 'DeepSeek',
  url => 'https://api.deepseek.com',
  model => 'deepseek-chat',
  env_var => 'LANGERTHA_DEEPSEEK_API_KEY',
  has_tools => 1,
  has_response_format => 1,
);
is(Langertha::Engine::DeepSeek->new(api_key => 'k')->default_model, 'deepseek-chat', 'DeepSeek default_model');

# --- Groq ---

use Langertha::Engine::Groq;

test_openai_cloud_engine(
  class => 'Langertha::Engine::Groq',
  name => 'Groq',
  url => 'https://api.groq.com/openai/v1',
  model => 'llama3.1-8b-versatile',
  env_var => 'LANGERTHA_GROQ_API_KEY',
  has_tools => 1,
  has_transcription => 1,
  has_response_format => 1,
);

# --- Perplexity (NO tools!) ---

use Langertha::Engine::Perplexity;

test_openai_cloud_engine(
  class => 'Langertha::Engine::Perplexity',
  name => 'Perplexity',
  url => 'https://api.perplexity.ai',
  model => 'sonar',
  env_var => 'LANGERTHA_PERPLEXITY_API_KEY',
  has_tools => 0,
);
is(Langertha::Engine::Perplexity->new(api_key => 'k')->default_model, 'sonar', 'Perplexity default_model');

# --- Mistral ---

use Langertha::Engine::Mistral;

test_openai_cloud_engine(
  class => 'Langertha::Engine::Mistral',
  name => 'Mistral',
  url => 'https://api.mistral.ai',
  model => 'mistral-small-latest',
  env_var => 'LANGERTHA_MISTRAL_API_KEY',
  has_tools => 1,
  has_embedding => 1,
  has_response_format => 1,
);
is(Langertha::Engine::Mistral->new(api_key => 'k')->default_model, 'mistral-small-latest', 'Mistral default_model');

# --- MiniMax ---

use Langertha::Engine::MiniMax;

# MiniMax uses Anthropic-compatible API (extends Anthropic, not OpenAIBase)
ok(Langertha::Engine::MiniMax->isa('Langertha::Engine::AnthropicBase'), 'MiniMax isa AnthropicBase');
ok(Langertha::Engine::MiniMax->isa('Langertha::Engine::Remote'), 'MiniMax isa Remote');
ok(!Langertha::Engine::MiniMax->isa('Langertha::Engine::OpenAIBase'), 'MiniMax is NOT OpenAIBase');
ok(Langertha::Engine::MiniMax->does('Langertha::Role::Chat'), 'MiniMax does Chat');
ok(Langertha::Engine::MiniMax->does('Langertha::Role::Streaming'), 'MiniMax does Streaming');
ok(Langertha::Engine::MiniMax->does('Langertha::Role::Tools'), 'MiniMax does Tools');
ok(Langertha::Engine::MiniMax->does('Langertha::Role::StaticModels'), 'MiniMax does StaticModels');
{
  my $m = Langertha::Engine::MiniMax->new(api_key => 'test-key');
  is($m->url, 'https://api.minimax.io/anthropic', 'MiniMax url default correct');
  is($m->default_model, 'MiniMax-M2.5', 'MiniMax default_model');

  local $ENV{LANGERTHA_MINIMAX_API_KEY} = 'env-key-12345';
  my $m2 = Langertha::Engine::MiniMax->new;
  is($m2->api_key, 'env-key-12345', 'MiniMax reads api_key from LANGERTHA_MINIMAX_API_KEY');

  my $req = $m->chat('test prompt');
  is($req->method, 'POST', 'MiniMax chat request is POST');
  like($req->uri, qr{/v1/messages$}, 'MiniMax chat endpoint is /v1/messages');
  is($req->header('x-api-key'), 'test-key', 'MiniMax uses x-api-key header');
}

# --- NousResearch ---

use Langertha::Engine::NousResearch;

test_openai_cloud_engine(
  class => 'Langertha::Engine::NousResearch',
  name => 'NousResearch',
  url => 'https://inference-api.nousresearch.com/v1',
  model => 'Hermes-4-70B',
  env_var => 'LANGERTHA_NOUSRESEARCH_API_KEY',
  has_tools => 1,
);
is(Langertha::Engine::NousResearch->new(api_key => 'k')->default_model, 'Hermes-4-70B', 'NousResearch default_model');
{
  my $nous = Langertha::Engine::NousResearch->new(api_key => 'k');
  ok($nous->does('Langertha::Role::HermesTools'), 'NousResearch uses HermesTools');
}

# --- AKIOpenAI ---

use Langertha::Engine::AKIOpenAI;

test_openai_cloud_engine(
  class => 'Langertha::Engine::AKIOpenAI',
  name => 'AKIOpenAI',
  url => 'https://aki.io/v1',
  model => 'llama3_8b_chat',
  env_var => 'LANGERTHA_AKI_API_KEY',
  has_tools => 1,
);
is(Langertha::Engine::AKIOpenAI->new(api_key => 'k')->default_model, 'llama3-chat-8b', 'AKIOpenAI default_model');

# ======================================================================
# Part 4: OpenAI-compatible local engines (extend OpenAIBase, url required)
# ======================================================================

# --- OllamaOpenAI ---

use Langertha::Engine::OllamaOpenAI;

ok(Langertha::Engine::OllamaOpenAI->isa('Langertha::Engine::OpenAIBase'), 'OllamaOpenAI isa OpenAIBase');
ok(Langertha::Engine::OllamaOpenAI->does('Langertha::Role::Embedding'), 'OllamaOpenAI does Embedding');
ok(Langertha::Engine::OllamaOpenAI->does('Langertha::Role::Tools'), 'OllamaOpenAI does Tools');

{
  # url required, no default
  eval { Langertha::Engine::OllamaOpenAI->new(model => 'test') };
  like($@, qr/url/, 'OllamaOpenAI requires url');

  my $o = Langertha::Engine::OllamaOpenAI->new(url => 'http://test.invalid:11434/v1', model => 'llama3.3');
  # No api_key needed for local
  is($o->api_key, undef, 'OllamaOpenAI api_key is undef (local)');
  my $req = $o->chat('hello');
  is($req->header('Authorization'), undef, 'OllamaOpenAI no Authorization header');
  like($req->uri, qr{/chat/completions$}, 'OllamaOpenAI uses /chat/completions');
}

# --- vLLM ---

use Langertha::Engine::vLLM;

ok(Langertha::Engine::vLLM->isa('Langertha::Engine::OpenAIBase'), 'vLLM isa OpenAIBase');
ok(Langertha::Engine::vLLM->does('Langertha::Role::Tools'), 'vLLM does Tools');

{
  # url required, no default
  eval { Langertha::Engine::vLLM->new() };
  like($@, qr/url/, 'vLLM requires url');

  my $v = Langertha::Engine::vLLM->new(url => 'http://test.invalid:8000/v1');
  is($v->model, 'default', 'vLLM model defaults to default');
  is($v->api_key, undef, 'vLLM api_key is undef (local)');
  my $req = $v->chat('hello');
  is($req->header('Authorization'), undef, 'vLLM no Authorization header');
  like($req->uri, qr{/chat/completions$}, 'vLLM uses /chat/completions');
}

# ======================================================================
# Part 5: Whisper (extends OpenAI, not OpenAIBase)
# ======================================================================

use Langertha::Engine::Whisper;

ok(Langertha::Engine::Whisper->isa('Langertha::Engine::OpenAI'), 'Whisper isa OpenAI');
ok(Langertha::Engine::Whisper->isa('Langertha::Engine::OpenAIBase'), 'Whisper isa OpenAIBase (via OpenAI)');
ok(Langertha::Engine::Whisper->isa('Langertha::Engine::Remote'), 'Whisper isa Remote (via chain)');

{
  my $w = Langertha::Engine::Whisper->new(url => 'http://test.invalid:9000');
  is($w->url, 'http://test.invalid:9000', 'Whisper url can be set explicitly');
  is($w->api_key, 'whisper', 'Whisper api_key defaults to whisper');
}

# ======================================================================
# Part 5b: New engines (Phase 3)
# ======================================================================

# --- Cerebras (cloud) ---

use Langertha::Engine::Cerebras;

test_openai_cloud_engine(
  class => 'Langertha::Engine::Cerebras',
  name => 'Cerebras',
  url => 'https://api.cerebras.ai/v1',
  model => 'llama3.1-8b',
  env_var => 'LANGERTHA_CEREBRAS_API_KEY',
  has_tools => 1,
);
is(Langertha::Engine::Cerebras->new(api_key => 'k')->default_model, 'llama3.1-8b', 'Cerebras default_model');

# --- OpenRouter (cloud, meta-provider) ---

use Langertha::Engine::OpenRouter;

ok(Langertha::Engine::OpenRouter->isa('Langertha::Engine::OpenAIBase'), 'OpenRouter isa OpenAIBase');
ok(Langertha::Engine::OpenRouter->does('Langertha::Role::Tools'), 'OpenRouter does Tools');
{
  my $or = Langertha::Engine::OpenRouter->new(api_key => 'test-key', model => 'anthropic/claude-sonnet-4-6');
  is($or->url, 'https://openrouter.ai/api/v1', 'OpenRouter url default correct');
  my $req = $or->chat('hello');
  is($req->header('Authorization'), 'Bearer test-key', 'OpenRouter sets Authorization header');
  like($req->uri, qr{/chat/completions$}, 'OpenRouter chat endpoint');
  my $body = $json->decode($req->content);
  is($body->{model}, 'anthropic/claude-sonnet-4-6', 'OpenRouter request has provider/model format');
}
{
  # model is required (meta-provider, no sensible default)
  my $or = Langertha::Engine::OpenRouter->new(api_key => 'k');
  eval { $or->default_model };
  like($@, qr/requires model/, 'OpenRouter default_model croaks');
}
{
  local $ENV{LANGERTHA_OPENROUTER_API_KEY} = 'env-key-12345';
  my $or = Langertha::Engine::OpenRouter->new(model => 'test');
  is($or->api_key, 'env-key-12345', 'OpenRouter reads api_key from LANGERTHA_OPENROUTER_API_KEY');
}

# --- Replicate (cloud) ---

use Langertha::Engine::Replicate;

ok(Langertha::Engine::Replicate->isa('Langertha::Engine::OpenAIBase'), 'Replicate isa OpenAIBase');
ok(Langertha::Engine::Replicate->does('Langertha::Role::Tools'), 'Replicate does Tools');
{
  my $r = Langertha::Engine::Replicate->new(api_key => 'test-key', model => 'meta/llama-4-maverick');
  is($r->url, 'https://api.replicate.com/v1', 'Replicate url default correct');
  my $req = $r->chat('hello');
  is($req->header('Authorization'), 'Bearer test-key', 'Replicate sets Authorization header');
  like($req->uri, qr{/chat/completions$}, 'Replicate chat endpoint');
  my $body = $json->decode($req->content);
  is($body->{model}, 'meta/llama-4-maverick', 'Replicate request has owner/model format');
}
{
  # model is required
  my $r = Langertha::Engine::Replicate->new(api_key => 'k');
  eval { $r->default_model };
  like($@, qr/requires model/, 'Replicate default_model croaks');
}
{
  local $ENV{LANGERTHA_REPLICATE_API_KEY} = 'env-key-12345';
  my $r = Langertha::Engine::Replicate->new(model => 'test');
  is($r->api_key, 'env-key-12345', 'Replicate reads api_key from LANGERTHA_REPLICATE_API_KEY');
}

# --- HuggingFace (cloud, meta-provider) ---

use Langertha::Engine::HuggingFace;

ok(Langertha::Engine::HuggingFace->isa('Langertha::Engine::OpenAIBase'), 'HuggingFace isa OpenAIBase');
ok(Langertha::Engine::HuggingFace->does('Langertha::Role::Tools'), 'HuggingFace does Tools');
{
  my $hf = Langertha::Engine::HuggingFace->new(api_key => 'test-key', model => 'Qwen/Qwen2.5-7B-Instruct');
  is($hf->url, 'https://router.huggingface.co/v1', 'HuggingFace url default correct');
  my $req = $hf->chat('hello');
  is($req->header('Authorization'), 'Bearer test-key', 'HuggingFace sets Authorization header');
  like($req->uri, qr{/chat/completions$}, 'HuggingFace chat endpoint');
  my $body = $json->decode($req->content);
  is($body->{model}, 'Qwen/Qwen2.5-7B-Instruct', 'HuggingFace request has org/model format');
}
{
  # model is required (meta-provider, no sensible default)
  my $hf = Langertha::Engine::HuggingFace->new(api_key => 'k');
  eval { $hf->default_model };
  like($@, qr/requires model/, 'HuggingFace default_model croaks');
}
{
  local $ENV{LANGERTHA_HUGGINGFACE_API_KEY} = 'env-key-12345';
  my $hf = Langertha::Engine::HuggingFace->new(model => 'test');
  is($hf->api_key, 'env-key-12345', 'HuggingFace reads api_key from LANGERTHA_HUGGINGFACE_API_KEY');
}

# --- LlamaCpp (local, like vLLM) ---

use Langertha::Engine::LlamaCpp;

ok(Langertha::Engine::LlamaCpp->isa('Langertha::Engine::OpenAIBase'), 'LlamaCpp isa OpenAIBase');
ok(Langertha::Engine::LlamaCpp->does('Langertha::Role::Embedding'), 'LlamaCpp does Embedding');
ok(Langertha::Engine::LlamaCpp->does('Langertha::Role::Tools'), 'LlamaCpp does Tools');
{
  # url required (local server)
  eval { Langertha::Engine::LlamaCpp->new() };
  like($@, qr/url/, 'LlamaCpp requires url');

  my $l = Langertha::Engine::LlamaCpp->new(url => 'http://test.invalid:8080/v1');
  is($l->model, 'default', 'LlamaCpp model defaults to default');
  is($l->api_key, undef, 'LlamaCpp api_key is undef (local)');
  my $req = $l->chat('hello');
  is($req->header('Authorization'), undef, 'LlamaCpp no Authorization header');
  like($req->uri, qr{/chat/completions$}, 'LlamaCpp uses /chat/completions');
}

# ======================================================================
# Part 6: Cross-cutting concerns
# ======================================================================

# All Remote descendants share JSON + HTTP
for my $class (qw(
  Langertha::Engine::Anthropic
  Langertha::Engine::Gemini
  Langertha::Engine::Ollama
  Langertha::Engine::AKI
  Langertha::Engine::OpenAI
  Langertha::Engine::DeepSeek
  Langertha::Engine::Groq
  Langertha::Engine::Perplexity
  Langertha::Engine::Mistral
  Langertha::Engine::MiniMax
  Langertha::Engine::NousResearch
  Langertha::Engine::AKIOpenAI
  Langertha::Engine::OllamaOpenAI
  Langertha::Engine::vLLM
  Langertha::Engine::Whisper
  Langertha::Engine::Cerebras
  Langertha::Engine::OpenRouter
  Langertha::Engine::Replicate
  Langertha::Engine::HuggingFace
  Langertha::Engine::LlamaCpp
  Langertha::Engine::LMStudio
  Langertha::Engine::LMStudioOpenAI
  Langertha::Engine::LMStudioAnthropic
)) {
  ok($class->isa('Langertha::Engine::Remote'), "$class isa Remote");
  ok($class->does('Langertha::Role::JSON'), "$class does JSON (via Remote)");
  ok($class->does('Langertha::Role::HTTP'), "$class does HTTP (via Remote)");
}

done_testing;
