#!/usr/bin/env perl
# ABSTRACT: Test chat request generation for all engines

use strict;
use warnings;

use Test2::Bundle::More;
use JSON::MaybeXS;

use Langertha::Engine::AKI;
use Langertha::Engine::Anthropic;
use Langertha::Engine::Groq;
use Langertha::Engine::Ollama;
use Langertha::Engine::OpenAI;

my $json = JSON::MaybeXS->new->canonical(1)->utf8(1);

plan(48);

my $ollama_testurl = 'http://test.url:12345';
my $ollama = Langertha::Engine::Ollama->new(
  url => $ollama_testurl,
  model => 'model',
  system_prompt => 'systemprompt',
  context_size => 4096,
  temperature => 0.5,
);
my $ollama_request = $ollama->chat('testprompt');
is($ollama_request->uri, $ollama_testurl.'/api/chat', 'Ollama request uri is correct');
is($ollama_request->method, 'POST', 'Ollama request method is correct');
is($ollama_request->header('Content-Type'), 'application/json; charset=utf-8', 'Ollama request JSON Content Type is set');
my $ollama_data = $json->decode($ollama_request->content);
is_deeply($ollama_data, {
  messages => [{
    content => "systemprompt", role => "system",
  },{
    content => "testprompt", role => "user",
  }],
  model => "model",
  options => {
    temperature => 0.5,
    num_ctx => 4096,
  },
  stream => JSON->false,
}, 'Ollama request body is correct');

my $openai = Langertha::Engine::OpenAI->new(
  api_key => 'apikey',
  model => 'gpt-4o-mini',
  system_prompt => 'systemprompt',
  temperature => 0.5,
);
my $openai_request = $openai->chat('testprompt');
is($openai_request->uri, 'https://api.openai.com/v1/chat/completions', 'OpenAI request uri is correct');
is($openai_request->method, 'POST', 'OpenAI request method is correct');
is($openai_request->header('Authorization'), 'Bearer apikey', 'OpenAI request Authorization header is correct');
is($openai_request->header('Content-Type'), 'application/json; charset=utf-8', 'OpenAI request JSON Content Type is set');
my $openai_data = $json->decode($openai_request->content);
is_deeply($openai_data, {
  messages => [{
    content => "systemprompt", role => "system",
  },{
    content => "testprompt", role => "user",
  }],
  model => "gpt-4o-mini",
  stream => JSON->false,
  temperature => 0.5,
}, 'OpenAI request body is correct');

my $anthropic = Langertha::Engine::Anthropic->new(
  api_key => 'apikey',
  model => 'claude-3-5-sonnet-20240620',
  system_prompt => 'systemprompt',
  api_version => '2024-02-04',
  response_size => 2048,
  temperature => 0.5,
);
my $anthropic_request = $anthropic->chat('testprompt');
is($anthropic_request->uri, 'https://api.anthropic.com/v1/messages', 'Anthropic request uri is correct');
is($anthropic_request->method, 'POST', 'Anthropic request method is correct');
is($anthropic_request->header('X-Api-Key'), 'apikey', 'Anthropic request X-Api-Key header is correct');
is($anthropic_request->header('Anthropic-Version'), '2024-02-04', 'Anthropic request Anthropic Version header is correct');
my $anthropic_data = $json->decode($anthropic_request->content);
is_deeply($anthropic_data, {
  max_tokens => 2048,
  temperature => 0.5,
  messages => [{
    content => 'testprompt',
    role => 'user',
  }],
  system => 'systemprompt',
  model => 'claude-3-5-sonnet-20240620',
}, 'Anthropic request body is correct');

# These are local-server expectations: an Ollama Cloud key in the environment
# would add a Bearer header (see t/13_ollama_auth.t).
delete local $ENV{LANGERTHA_OLLAMA_API_KEY};

my $ollama_openai_testurl = 'http://test.openai.url:12345';
my $ollama_for_openai = Langertha::Engine::Ollama->new(
  url => $ollama_openai_testurl,
  model => 'model',
  system_prompt => 'systemprompt',
  temperature => 0.5,
);
my $ollama_openai = $ollama_for_openai->openai;
my $ollama_openai_request = $ollama_openai->chat('testprompt');
is($ollama_openai_request->uri, $ollama_openai_testurl.'/v1/chat/completions', 'Ollama OpenAI request uri is correct');
is($ollama_openai_request->method, 'POST', 'Ollama OpenAI request method is correct');
is($ollama_openai_request->header('Authorization'), undef, 'Ollama OpenAI request has no Authorization header (local server)');
is($ollama_openai_request->header('Content-Type'), 'application/json; charset=utf-8', 'Ollama OpenAI request JSON Content Type is set');
my $ollama_openai_data = $json->decode($ollama_openai_request->content);
is_deeply($ollama_openai_data, {
  messages => [{
    content => "systemprompt", role => "system",
  },{
    content => "testprompt", role => "user",
  }],
  model => "model",
  stream => JSON->false,
  temperature => 0.5,
}, 'Ollama OpenAI request body is correct');

my $groq = Langertha::Engine::Groq->new(
  api_key => 'apikey',
  model => 'gemma2-9b-it',
  system_prompt => 'systemprompt',
);
my $groq_request = $groq->chat('testprompt');
is($groq_request->uri, 'https://api.groq.com/openai/v1/chat/completions', 'Groq request uri is correct');
is($groq_request->method, 'POST', 'OpenAI request method is correct');
is($groq_request->header('Authorization'), 'Bearer apikey', 'Groq request Authorization header is correct');
is($groq_request->header('Content-Type'), 'application/json; charset=utf-8', 'Groq request JSON Content Type is set');
my $groq_data = $json->decode($groq_request->content);
is_deeply($groq_data, {
  messages => [{
    content => "systemprompt", role => "system",
  },{
    content => "testprompt", role => "user",
  }],
  model => "gemma2-9b-it",
  stream => JSON->false,
}, 'Groq request body is correct');

my $aki = Langertha::Engine::AKI->new(
  api_key => 'akikey',
  model => 'llama3_8b_chat',
  system_prompt => 'systemprompt',
  temperature => 0.5,
);
my $aki_request = $aki->chat('testprompt');
is($aki_request->uri, 'https://aki.io/api/call/llama3_8b_chat', 'Aki request uri is correct');
is($aki_request->method, 'POST', 'Aki request method is correct');
is($aki_request->header('Content-Type'), 'application/json; charset=utf-8', 'Aki request JSON Content Type is set');
my $aki_data = $json->decode($aki_request->content);
# chat_context is a JSON string per AKI API convention
is($aki_data->{key}, 'akikey', 'Aki request has key in body');
is($aki_data->{temperature}, 0.5, 'Aki request has temperature');
is($aki_data->{wait_for_result}, JSON->true, 'Aki request has wait_for_result');
ok(!ref $aki_data->{chat_context}, 'Aki chat_context is a JSON string');
is_deeply($json->decode($aki_data->{chat_context}), [{
  content => "systemprompt", role => "system",
},{
  content => "testprompt", role => "user",
}], 'Aki chat_context decodes correctly');

# --- reasoning_effort wire translation (karr #16, slice 1) ---

# OpenAI: flat reasoning_effort string
my $openai_re = Langertha::Engine::OpenAI->new(
  api_key => 'apikey',
  model => 'gpt-5.1',
  reasoning_effort => 'high',
);
my $openai_re_data = $json->decode($openai_re->chat('testprompt')->content);
is($openai_re_data->{reasoning_effort}, 'high', 'OpenAI emits flat reasoning_effort');
ok(!exists $openai_data->{reasoning_effort}, 'OpenAI omits reasoning_effort when unset');

# Anthropic: output_config.effort + thinking:{type:adaptive}; NO top-level effort
my $anthropic_re = Langertha::Engine::Anthropic->new(
  api_key => 'apikey',
  model => 'claude-opus-4-8',
  reasoning_effort => 'high',
);
my $anthropic_re_data = $json->decode($anthropic_re->chat('testprompt')->content);
is_deeply($anthropic_re_data->{output_config}, { effort => 'high' },
  'Anthropic emits output_config.effort');
is_deeply($anthropic_re_data->{thinking}, { type => 'adaptive' },
  'Anthropic emits thinking:{type:adaptive}');
ok(!exists $anthropic_re_data->{effort},
  'Anthropic regression: old top-level effort key is gone');
ok(!exists $anthropic_data->{output_config}, 'Anthropic omits output_config when unset');
ok(!exists $anthropic_data->{thinking}, 'Anthropic omits thinking when unset');

# Back-compat: effort => 'high' constructor lands on the new nested shape
my $anthropic_alias = Langertha::Engine::Anthropic->new(
  api_key => 'apikey',
  model => 'claude-opus-4-8',
  effort => 'high',
);
is($anthropic_alias->reasoning_effort, 'high', 'effort seeds reasoning_effort');
my $anthropic_alias_data = $json->decode($anthropic_alias->chat('testprompt')->content);
is_deeply($anthropic_alias_data->{output_config}, { effort => 'high' },
  'effort alias produces output_config.effort');
is_deeply($anthropic_alias_data->{thinking}, { type => 'adaptive' },
  'effort alias produces thinking:{type:adaptive}');
ok(!exists $anthropic_alias_data->{effort},
  'effort alias does not emit the old top-level effort key');

# --- prompt caching wire translation (karr #16, slice 2) ---

# Anthropic: top-level cache_control:{type:ephemeral} when prompt_cache is on
my $anthropic_pc = Langertha::Engine::Anthropic->new(
  api_key => 'apikey',
  model => 'claude-opus-4-8',
  prompt_cache => 1,
);
my $anthropic_pc_data = $json->decode($anthropic_pc->chat('testprompt')->content);
is_deeply($anthropic_pc_data->{cache_control}, { type => 'ephemeral' },
  'Anthropic emits top-level cache_control:{type:ephemeral}');

# Anthropic: ttl is added when set
my $anthropic_pc_ttl = Langertha::Engine::Anthropic->new(
  api_key => 'apikey',
  model => 'claude-opus-4-8',
  prompt_cache => 1,
  prompt_cache_ttl => '1h',
);
my $anthropic_pc_ttl_data = $json->decode($anthropic_pc_ttl->chat('testprompt')->content);
is_deeply($anthropic_pc_ttl_data->{cache_control}, { type => 'ephemeral', ttl => '1h' },
  'Anthropic cache_control carries ttl when set');

# Anthropic: no cache_control when prompt_cache is unset
ok(!exists $anthropic_data->{cache_control}, 'Anthropic omits cache_control when unset');

# OpenAI: flat prompt_cache_key when set
my $openai_pc = Langertha::Engine::OpenAI->new(
  api_key => 'apikey',
  model => 'gpt-4o-mini',
  prompt_cache_key => 'route-x',
);
my $openai_pc_data = $json->decode($openai_pc->chat('testprompt')->content);
is($openai_pc_data->{prompt_cache_key}, 'route-x', 'OpenAI emits flat prompt_cache_key');

# OpenAI: no prompt_cache_key when unset
ok(!exists $openai_data->{prompt_cache_key}, 'OpenAI omits prompt_cache_key when unset');

done_testing;
