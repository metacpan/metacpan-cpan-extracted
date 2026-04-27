#!/usr/bin/env perl
# ABSTRACT: Live integration test for MCP tool calling against real APIs

use strict;
use warnings;

use Test2::Bundle::More;
use JSON::MaybeXS;

BEGIN {
  my @available;
  push @available, 'anthropic' if $ENV{TEST_LANGERTHA_ANTHROPIC_API_KEY};
  push @available, 'openai'    if $ENV{TEST_LANGERTHA_OPENAI_API_KEY};
  push @available, 'gemini'    if $ENV{TEST_LANGERTHA_GEMINI_API_KEY};
  push @available, 'groq'      if $ENV{TEST_LANGERTHA_GROQ_API_KEY};
  push @available, 'mistral'   if $ENV{TEST_LANGERTHA_MISTRAL_API_KEY};
  push @available, 'deepseek'    if $ENV{TEST_LANGERTHA_DEEPSEEK_API_KEY};
  push @available, 'minimax'     if $ENV{TEST_LANGERTHA_MINIMAX_API_KEY};
  # Perplexity does not support tool calling
  push @available, 'nousresearch' if $ENV{TEST_LANGERTHA_NOUSRESEARCH_API_KEY};
  push @available, 'cerebras'    if $ENV{TEST_LANGERTHA_CEREBRAS_API_KEY};
  push @available, 'openrouter'  if $ENV{TEST_LANGERTHA_OPENROUTER_API_KEY};
  push @available, 'replicate'   if $ENV{TEST_LANGERTHA_REPLICATE_API_KEY};
  push @available, 'huggingface' if $ENV{TEST_LANGERTHA_HUGGINGFACE_API_KEY};
  push @available, 'aki'        if $ENV{TEST_LANGERTHA_AKI_API_KEY};
  push @available, 'tsystems'    if $ENV{TEST_LANGERTHA_TSYSTEMS_API_KEY};
  push @available, 'scaleway'    if $ENV{TEST_LANGERTHA_SCALEWAY_API_KEY};
  push @available, 'ollama'      if $ENV{TEST_LANGERTHA_OLLAMA_URL};
  push @available, 'vllm'      if $ENV{TEST_LANGERTHA_VLLM_URL} && $ENV{TEST_LANGERTHA_VLLM_TOOL_CALL_PARSER};
  unless (@available) {
    plan skip_all => 'No TEST_LANGERTHA_* env vars set';
  }
  eval {
    require IO::Async::Loop;
    require Future::AsyncAwait;
    require Net::Async::MCP;
    require MCP::Server;
    require MCP::Tool;
    1;
  } or plan skip_all => 'Requires IO::Async, Net::Async::MCP, and MCP modules';
}

use IO::Async::Loop;
use Future::AsyncAwait;
use Net::Async::MCP;
use MCP::Server;
use MCP::Tool;

# --- Build a test MCP server with deterministic tools ---

my $server = MCP::Server->new(name => 'test', version => '1.0');

$server->tool(
  name        => 'add',
  description => 'Add two numbers together and return the result',
  input_schema => {
    type       => 'object',
    properties => {
      a => { type => 'number', description => 'First number' },
      b => { type => 'number', description => 'Second number' },
    },
    required => ['a', 'b'],
  },
  code => sub {
    my ($self, $args) = @_;
    my $result = $args->{a} + $args->{b};
    return $self->text_result("$result");
  },
);

$server->tool(
  name        => 'get_secret_code',
  description => 'Returns the secret code for the given room name. You MUST call this tool to get the code, do not guess.',
  input_schema => {
    type       => 'object',
    properties => {
      room => { type => 'string', description => 'The room name to look up' },
    },
    required => ['room'],
  },
  code => sub {
    my ($self, $args) = @_;
    return $self->text_result("XYLOPHONE-42");
  },
);

my $loop = IO::Async::Loop->new;
my $mcp = Net::Async::MCP->new(server => $server);
$loop->add($mcp);

my $prompt = 'What is 7 plus 15? Use the add tool to calculate this. Answer with just the number.';
my $secret_prompt = 'What is the secret code for room "lobby"? Use the get_secret_code tool. Reply with just the code.';

async sub test_engine {
  my ($name, $engine) = @_;
  my $response = await $engine->chat_with_tools_f($prompt);
  like($response, qr/22/, "$name: tool calling returned correct result (22)");
  diag "$name response: $response";
}

async sub test_engine_secret {
  my ($name, $engine) = @_;
  my $response = await $engine->chat_with_tools_f($secret_prompt);
  like($response, qr/XYLOPHONE-42/, "$name: secret code tool returned correct result");
  diag "$name secret response: $response";
}

async sub run_tests {
  await $mcp->initialize;

  my $tools = await $mcp->list_tools;
  is(scalar @$tools, 2, 'MCP server has 2 tools');

  # --- Anthropic ---
  if ($ENV{TEST_LANGERTHA_ANTHROPIC_API_KEY}) {
    require Langertha::Engine::Anthropic;
    eval {
      await test_engine('Anthropic', Langertha::Engine::Anthropic->new(
        api_key => $ENV{TEST_LANGERTHA_ANTHROPIC_API_KEY},
        model => 'claude-sonnet-4-6', mcp_servers => [$mcp],
      ));
    };
    diag "Anthropic error: $@" if $@;
  }

  # --- OpenAI ---
  if ($ENV{TEST_LANGERTHA_OPENAI_API_KEY}) {
    require Langertha::Engine::OpenAI;
    eval {
      await test_engine('OpenAI', Langertha::Engine::OpenAI->new(
        api_key => $ENV{TEST_LANGERTHA_OPENAI_API_KEY},
        model => 'gpt-4o-mini', mcp_servers => [$mcp],
      ));
    };
    diag "OpenAI error: $@" if $@;
  }

  # --- Gemini ---
  if ($ENV{TEST_LANGERTHA_GEMINI_API_KEY}) {
    require Langertha::Engine::Gemini;
    eval {
      await test_engine('Gemini', Langertha::Engine::Gemini->new(
        api_key => $ENV{TEST_LANGERTHA_GEMINI_API_KEY},
        model => 'gemini-2.5-flash', mcp_servers => [$mcp],
      ));
    };
    diag "Gemini error: $@" if $@;
  }

  # --- Groq ---
  if ($ENV{TEST_LANGERTHA_GROQ_API_KEY}) {
    require Langertha::Engine::Groq;
    eval {
      await test_engine('Groq', Langertha::Engine::Groq->new(
        api_key => $ENV{TEST_LANGERTHA_GROQ_API_KEY},
        model => 'moonshotai/kimi-k2-instruct', mcp_servers => [$mcp],
      ));
    };
    diag "Groq error: $@" if $@;
  }

  # --- Mistral ---
  if ($ENV{TEST_LANGERTHA_MISTRAL_API_KEY}) {
    require Langertha::Engine::Mistral;
    eval {
      await test_engine('Mistral', Langertha::Engine::Mistral->new(
        api_key => $ENV{TEST_LANGERTHA_MISTRAL_API_KEY},
        model => 'mistral-small-latest', mcp_servers => [$mcp],
      ));
    };
    diag "Mistral error: $@" if $@;
  }

  # --- DeepSeek ---
  if ($ENV{TEST_LANGERTHA_DEEPSEEK_API_KEY}) {
    require Langertha::Engine::DeepSeek;
    eval {
      await test_engine('DeepSeek', Langertha::Engine::DeepSeek->new(
        api_key => $ENV{TEST_LANGERTHA_DEEPSEEK_API_KEY},
        model => 'deepseek-chat', mcp_servers => [$mcp],
      ));
    };
    diag "DeepSeek error: $@" if $@;
  }

  # --- MiniMax ---
  if ($ENV{TEST_LANGERTHA_MINIMAX_API_KEY}) {
    require Langertha::Engine::MiniMax;
    eval {
      await test_engine('MiniMax', Langertha::Engine::MiniMax->new(
        api_key => $ENV{TEST_LANGERTHA_MINIMAX_API_KEY},
        mcp_servers => [$mcp],
      ));
    };
    diag "MiniMax error: $@" if $@;
  }

  # --- Perplexity ---
  # Note: Perplexity does not support tool calling as of Feb 2026
  # Skipped in tool calling test

  # --- NousResearch ---
  if ($ENV{TEST_LANGERTHA_NOUSRESEARCH_API_KEY}) {
    require Langertha::Engine::NousResearch;
    eval {
      await test_engine('NousResearch', Langertha::Engine::NousResearch->new(
        api_key => $ENV{TEST_LANGERTHA_NOUSRESEARCH_API_KEY},
        model => 'Hermes-4-70B', mcp_servers => [$mcp],
      ));
    };
    diag "NousResearch error: $@" if $@;
  }

  # --- Cerebras ---
  if ($ENV{TEST_LANGERTHA_CEREBRAS_API_KEY}) {
    require Langertha::Engine::Cerebras;
    eval {
      await test_engine('Cerebras', Langertha::Engine::Cerebras->new(
        api_key => $ENV{TEST_LANGERTHA_CEREBRAS_API_KEY},
        model => 'llama3.1-8b',
        mcp_servers => [$mcp],
      ));
    };
    diag "Cerebras error: $@" if $@;
  }

  # --- OpenRouter ---
  if ($ENV{TEST_LANGERTHA_OPENROUTER_API_KEY}) {
    require Langertha::Engine::OpenRouter;
    my $or_model = $ENV{TEST_LANGERTHA_OPENROUTER_MODEL} || 'meta-llama/llama-3.3-70b-instruct:free';
    eval {
      await test_engine("OpenRouter/$or_model", Langertha::Engine::OpenRouter->new(
        api_key => $ENV{TEST_LANGERTHA_OPENROUTER_API_KEY},
        model => $or_model, mcp_servers => [$mcp],
      ));
    };
    diag "OpenRouter/$or_model error: $@" if $@;
  }

  # --- Replicate ---
  if ($ENV{TEST_LANGERTHA_REPLICATE_API_KEY}) {
    require Langertha::Engine::Replicate;
    my $rep_model = $ENV{TEST_LANGERTHA_REPLICATE_MODEL} || 'meta/llama-4-maverick';
    eval {
      await test_engine("Replicate/$rep_model", Langertha::Engine::Replicate->new(
        api_key => $ENV{TEST_LANGERTHA_REPLICATE_API_KEY},
        model => $rep_model, mcp_servers => [$mcp],
      ));
    };
    diag "Replicate/$rep_model error: $@" if $@;
  }

  # --- HuggingFace ---
  if ($ENV{TEST_LANGERTHA_HUGGINGFACE_API_KEY}) {
    require Langertha::Engine::HuggingFace;
    my $hf_model = $ENV{TEST_LANGERTHA_HUGGINGFACE_MODEL} || 'Qwen/Qwen2.5-7B-Instruct';
    eval {
      await test_engine("HuggingFace/$hf_model", Langertha::Engine::HuggingFace->new(
        api_key => $ENV{TEST_LANGERTHA_HUGGINGFACE_API_KEY},
        model => $hf_model, mcp_servers => [$mcp],
      ));
    };
    diag "HuggingFace/$hf_model error: $@" if $@;
  }

  # --- vLLM ---
  # Requires server started with: --enable-auto-tool-choice --tool-call-parser <parser>
  # Set TEST_LANGERTHA_VLLM_TOOL_CALL_PARSER to indicate tool calling is available
  if ($ENV{TEST_LANGERTHA_VLLM_URL} && $ENV{TEST_LANGERTHA_VLLM_TOOL_CALL_PARSER}) {
    require Langertha::Engine::vLLM;
    my $model = $ENV{TEST_LANGERTHA_VLLM_MODEL}
      or die "TEST_LANGERTHA_VLLM_MODEL required when TEST_LANGERTHA_VLLM_URL is set";
    diag "vLLM tool_call_parser: $ENV{TEST_LANGERTHA_VLLM_TOOL_CALL_PARSER}";
    eval {
      await test_engine("vLLM/$model", Langertha::Engine::vLLM->new(
        url => $ENV{TEST_LANGERTHA_VLLM_URL},
        model => $model, mcp_servers => [$mcp],
      ));
    };
    diag "vLLM/$model error: $@" if $@;
  }

  # --- TSystems ---
  if ($ENV{TEST_LANGERTHA_TSYSTEMS_API_KEY}) {
    require Langertha::Engine::TSystems;
    eval {
      await test_engine('TSystems', Langertha::Engine::TSystems->new(
        api_key => $ENV{TEST_LANGERTHA_TSYSTEMS_API_KEY},
        model => 'gpt-oss-120b', mcp_servers => [$mcp],
      ));
    };
    diag "TSystems error: $@" if $@;
  }

  # --- Scaleway ---
  if ($ENV{TEST_LANGERTHA_SCALEWAY_API_KEY}) {
    require Langertha::Engine::Scaleway;
    eval {
      await test_engine('Scaleway', Langertha::Engine::Scaleway->new(
        api_key => $ENV{TEST_LANGERTHA_SCALEWAY_API_KEY},
        model => 'llama-3.1-8b-instruct', mcp_servers => [$mcp],
      ));
    };
    diag "Scaleway error: $@" if $@;
  }

  # --- AKI.IO (via OpenAI-compatible API, HermesTools) ---
  if ($ENV{TEST_LANGERTHA_AKI_API_KEY}) {
    require Langertha::Engine::AKIOpenAI;
    my $aki_model = $ENV{TEST_LANGERTHA_AKI_OPENAI_MODEL} || 'qwen3-chat';
    eval {
      await test_engine_secret("AKIOpenAI/$aki_model", Langertha::Engine::AKIOpenAI->new(
        api_key => $ENV{TEST_LANGERTHA_AKI_API_KEY},
        model => $aki_model, mcp_servers => [$mcp],
      ));
    };
    diag "AKIOpenAI/$aki_model error: $@" if $@;
  }

  # --- AKI.IO (native API, HermesTools) ---
  if ($ENV{TEST_LANGERTHA_AKI_API_KEY}) {
    require Langertha::Engine::AKI;
    my $aki_model = $ENV{TEST_LANGERTHA_AKI_NATIVE_MODEL} || 'qwen3_chat';
    eval {
      await test_engine_secret("AKI-native/$aki_model", Langertha::Engine::AKI->new(
        api_key => $ENV{TEST_LANGERTHA_AKI_API_KEY},
        model => $aki_model, mcp_servers => [$mcp],
      ));
    };
    diag "AKI-native/$aki_model error: $@" if $@;
  }

  # --- Ollama ---
  if ($ENV{TEST_LANGERTHA_OLLAMA_URL}) {
    require Langertha::Engine::Ollama;
    my @ollama_models = $ENV{TEST_LANGERTHA_OLLAMA_MODELS}
      ? split(/,/, $ENV{TEST_LANGERTHA_OLLAMA_MODELS})
      : ($ENV{TEST_LANGERTHA_OLLAMA_MODEL} || 'qwen3:8b');
    for my $model (@ollama_models) {
      eval {
        await test_engine("Ollama/$model", Langertha::Engine::Ollama->new(
          url => $ENV{TEST_LANGERTHA_OLLAMA_URL},
          model => $model, mcp_servers => [$mcp],
        ));
      };
      diag "Ollama/$model error: $@" if $@;
    }
  }
}

run_tests()->get;

done_testing;
