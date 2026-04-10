---
name: langertha
description: Langertha LLM framework — Engine creation, Raider autonomous agents, MCP tool integration, plugin system
---

<oneliner>
Langertha is a Perl LLM framework with provider-agnostic engines, autonomous Raider agents, MCP tool integration, and a plugin pipeline. Use Future::AsyncAwait for async operations.
</oneliner>

<engines>
## Engine Creation

```perl
# Anthropic
use Langertha::Engine::Anthropic;
my $claude = Langertha::Engine::Anthropic->new(
    api_key       => $ENV{ANTHROPIC_API_KEY},
    model         => 'claude-sonnet-4-6',
    system_prompt => 'You are helpful.',
);

# OpenAI
use Langertha::Engine::OpenAI;
my $gpt = Langertha::Engine::OpenAI->new(
    api_key => $ENV{OPENAI_API_KEY},
    model   => 'gpt-4o',
);

# OpenAI-compatible (Ollama, vLLM, etc.)
my $local = Langertha::Engine::OllamaOpenAI->new(
    url   => 'http://localhost:11434/v1',
    model => 'llama3',
);

# Proxy (HI pattern — proxy handles model routing)
my $proxy = Langertha::Engine::OpenAI->new(
    url     => 'http://127.0.0.1:5000/api/v1',
    model   => $model_key,
    api_key => 'proxy',
);
```

### Available Engine Families

| Base | Engines |
|------|---------|
| AnthropicBase | Anthropic, MiniMax, LMStudioAnthropic |
| OpenAIBase | OpenAI, DeepSeek, Groq, Mistral, Cerebras, OpenRouter, Replicate, HuggingFace, Perplexity, OllamaOpenAI, vLLM, SGLang, LlamaCpp, AKIOpenAI |
| Other | Gemini (Google), Ollama (native), AKI (EU) |
</engines>

<simple-chat>
## Simple Chat

```perl
# Synchronous
my $response = $engine->simple_chat('What is Perl?');
print $response;  # Stringifies to content

# Async
use Future::AsyncAwait;
my $response = await $engine->simple_chat_f('Tell me a story.');
say $response->model;              # Model name
say $response->prompt_tokens;      # Token usage
say $response->completion_tokens;
say $response->thinking;           # Chain-of-thought (if available)
```

`Langertha::Response` overloads `""` so it works in string contexts.
</simple-chat>

<tool-calling>
## Tool Calling with MCP

### Step 1: Create MCP Server with tools

```perl
use MCP::Server;

my $server = MCP::Server->new(name => 'my-tools', version => '1.0');

$server->tool(
    name        => 'search_files',
    description => 'Search for files matching a pattern',
    input_schema => {
        type       => 'object',
        properties => {
            pattern => { type => 'string', description => 'Glob pattern' },
            path    => { type => 'string', description => 'Directory to search' },
        },
        required => ['pattern'],
    },
    code => sub {
        my ($tool, $args) = @_;
        # $tool is MCP::Tool instance (NOT your class)
        my @files = glob("$args->{path}/$args->{pattern}");
        return $tool->text_result(join("\n", @files));
        # Error: $tool->text_result("Not found", 1);  # is_error=1
    },
);
```

### Step 2: Create MCP client

```perl
use IO::Async::Loop;
use Net::Async::MCP;

my $loop = IO::Async::Loop->new;
my $mcp = Net::Async::MCP->new(server => $server);
$loop->add($mcp);
await $mcp->initialize;
```

### Step 3: Engine with MCP

```perl
my $engine = Langertha::Engine::Anthropic->new(
    api_key     => $ENV{ANTHROPIC_API_KEY},
    model       => 'claude-sonnet-4-6',
    mcp_servers => [$mcp],  # Pass MCP server(s)
);

# One-shot tool calling
my $response = await $engine->chat_with_tools_f('Find all .pm files in lib/');
say $response;
```
</tool-calling>

<raider>
## Raider — Autonomous Agent

```perl
use Langertha::Raider;

my $raider = Langertha::Raider->new(
    engine         => $engine,        # With MCP servers
    mission        => 'You are a code reviewer.',
    max_iterations => 10,             # Max tool rounds per raid
    # Optional:
    max_context_tokens         => 4000,
    context_compress_threshold => 0.75,
    compression_engine         => $cheap_model,
    raider_mcp                 => 1,   # Enable self-tools (ask_user, pause, abort)
    plugins                    => ['Langfuse'],
);

# Raid (autonomous tool-calling loop)
my $result = await $raider->raid_f('Review lib/App.pm');

# Result handling
say $result;                # Stringified response
say $result->is_question;   # Agent asked a question
say $result->is_abort;      # Agent aborted

# Continue conversation (has context from previous raids)
my $r2 = await $raider->raid_f('Now suggest improvements.');

# Respond to question
if ($result->is_question) {
    my $next = await $raider->respond_f('Yes, go ahead.');
}

# History management
$raider->add_history('user', $content);  # Replay from DB
$raider->clear_history;                  # Reset

# Metrics
my $m = $raider->metrics;
say "Iterations: $m->{iterations}";
say "Tool calls: $m->{tool_calls}";
```

### Raid Loop (simplified)

1. Auto-compress history if context threshold exceeded
2. Gather tools from MCP servers + inline tools + self-tools
3. Build conversation: mission + history + new messages
4. Call LLM with tools
5. If tool calls: execute via MCP, add results to conversation, loop
6. If no tool calls: extract final text, persist to history, return result
7. Max iterations safety limit
</raider>

<plugins>
## Plugin System

```perl
package Langertha::Plugin::MyGuardrails;
use Langertha qw( Plugin );

async sub plugin_before_tool_call {
    my ($self, $name, $input) = @_;
    return if $name eq 'dangerous_tool';  # Skip tool
    return ($name, $input);               # Allow tool
}

async sub plugin_after_raid {
    my ($self, $result) = @_;
    return $result;  # Transform result
}

__PACKAGE__->meta->make_immutable;

# Usage
my $raider = Langertha::Raider->new(
    engine  => $engine,
    plugins => ['MyGuardrails', 'Langfuse'],
);
```

### Plugin Hooks (all async sub)

| Hook | Purpose |
|------|---------|
| `plugin_before_raid(@messages)` | Transform input |
| `plugin_build_conversation(@conv)` | Transform assembled conversation |
| `plugin_before_llm_call(@conv, $iter)` | Transform before each LLM call |
| `plugin_after_llm_response($data, $iter)` | Inspect LLM response |
| `plugin_before_tool_call($name, $input)` | Allow/block tool (empty = skip) |
| `plugin_after_tool_call($name, $input, $result)` | Transform tool result |
| `plugin_after_raid($result)` | Transform final result |
</plugins>

<roles>
## Composable Roles

Engines compose feature roles:

| Role | Feature |
|------|---------|
| `Langertha::Role::Chat` | `simple_chat`, `simple_chat_f` |
| `Langertha::Role::Tools` | `chat_with_tools_f` (MCP loop) |
| `Langertha::Role::Streaming` | SSE/NDJSON streaming |
| `Langertha::Role::Embedding` | Vector embeddings |
| `Langertha::Role::Transcription` | Audio-to-text |
| `Langertha::Role::ImageGeneration` | Image generation |
| `Langertha::Role::SystemPrompt` | System prompt management |
| `Langertha::Role::Temperature` | Generation parameters |
| `Langertha::Role::ResponseFormat` | JSON mode / structured output |
| `Langertha::Role::Models` | Model listing |
| `Langertha::Role::Langfuse` | Observability |
| `Langertha::Role::HermesTools` | XML tag tool calling |
| `Langertha::Role::ThinkTag` | Chain-of-thought filtering |
</roles>
