# Knarr — Langertha LLM Proxy

```
         .  *  .
        . _/|_ .          KNARR
     .  /|    |\ .        Langertha LLM Proxy
   ~~~~~|______|~~~~~
   ~~ ~~~~~~~~~~~~~ ~~    Cargo transport for your LLM calls
   ~~~~~~~~~~~~~~~~~~~~
```

An LLM proxy that routes requests from any client to any backend — with
automatic [Langfuse](https://langfuse.com) tracing for every call.

Set your API key, start the container, done. All requests are traced.

## Getting Started

```bash
docker run -e ANTHROPIC_API_KEY -p 8080:8080 raudssus/langertha-knarr
```

Now point Claude Code at it:

```bash
ANTHROPIC_BASE_URL=http://localhost:8080 claude
```

That's it. Claude Code sends requests to Knarr, Knarr forwards them to
Anthropic using your API key (**passthrough mode**). Add Langfuse keys and
every request gets traced automatically.

### How it works

Knarr runs in **passthrough mode** by default: requests that don't match a
configured model are forwarded to the upstream API (Anthropic, OpenAI)
using the client's own API key. No key duplication, no configuration needed.

```
Claude Code                                    Anthropic API
    │                                               ▲
    │  ANTHROPIC_BASE_URL=http://localhost:8080      │
    ▼                                               │
  Knarr ──────── passthrough ──────────────────────►│
    │                                               │
    └── Langfuse trace (auto)
```

For explicit routing (e.g., send "gpt-4o" requests to OpenAI, "cheap" to
Groq), configure models in a YAML file or let Knarr auto-detect from
environment variables.

### More examples

```bash
# OpenAI Python SDK
OPENAI_BASE_URL=http://localhost:8080/v1 python my_app.py

# curl
curl http://localhost:8080/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -d '{"model":"gpt-4o-mini","messages":[{"role":"user","content":"Hello"}]}'

# Ollama clients (Open WebUI, etc.)
OLLAMA_HOST=http://localhost:11434 open-webui
```

Knarr listens on:

- **Port 8080** — OpenAI + Anthropic API (passthrough + routing)
- **Port 11434** — Ollama API (routing only)
- **Health** — http://localhost:8080/health

## Windows

Use [WSL2](https://learn.microsoft.com/en-us/windows/wsl/install) — all
commands work as-is inside a WSL terminal:

```bash
wsl
docker run --env-file .env -p 8080:8080 -p 11434:11434 raudssus/langertha-knarr
```

Or with [Docker Desktop](https://www.docker.com/products/docker-desktop/)
from PowerShell:

```powershell
docker run --env-file .env -p 8080:8080 -p 11434:11434 raudssus/langertha-knarr
```

The `--env-file .env` approach works identically on Linux, macOS, and
Windows. Create your `.env` file once, run the same command everywhere.

## Using a .env File

Create a `.env` file with your API keys (see `.env.example`):

```bash
# .env
OPENAI_API_KEY=sk-...
ANTHROPIC_API_KEY=sk-ant-...
LANGFUSE_PUBLIC_KEY=pk-lf-...
LANGFUSE_SECRET_KEY=sk-lf-...
```

Then run with `--env-file`:

```bash
docker run --env-file .env -p 8080:8080 -p 11434:11434 raudssus/langertha-knarr
```

Knarr reads the file, detects which providers have keys, configures them
with sensible default models, and starts serving.

## Docker Compose

The included `docker-compose.yml` starts Knarr with Langfuse tracing
out of the box:

```bash
cp .env.example .env
# Edit .env — add your API keys and Langfuse keys
docker compose up
```

This starts:

| Service | Port | Description |
|---------|------|-------------|
| Knarr | 8080, 11434 | LLM Proxy |
| Langfuse | 3000 | Tracing Dashboard |
| PostgreSQL | — | Langfuse storage |

The `docker-compose.yml` automatically loads `.env` and connects Knarr to
the Langfuse instance. Open http://localhost:3000 for the dashboard — every
LLM call through Knarr is traced with model, input, output, latency, and
token usage.

### Minimal Docker Compose (without Langfuse)

If you don't need tracing:

```yaml
services:
  knarr:
    image: raudssus/langertha-knarr
    ports:
      - "8080:8080"
      - "11434:11434"
    env_file: .env
```

## Multiple Providers

Set multiple API keys — Knarr configures all of them automatically:

```bash
docker run --env-file .env -p 8080:8080 -p 11434:11434 raudssus/langertha-knarr
```

```
[knarr] Knarr LLM Proxy starting in container mode...
[knarr]
[knarr] Config: auto-detecting from environment variables
[knarr] Engines: 3 provider(s) configured
[knarr]
[knarr]   anthropic => Anthropic / claude-sonnet-4-6 (key from $ANTHROPIC_API_KEY)
[knarr]   groq => Groq / llama-3.3-70b-versatile (key from $GROQ_API_KEY)
[knarr]   openai => OpenAI / gpt-4o-mini (key from $OPENAI_API_KEY)
[knarr]
[knarr] Auto-discover: enabled (will query provider model lists)
[knarr] Default engine: OpenAI
[knarr] Langfuse: disabled (set LANGFUSE_PUBLIC_KEY + LANGFUSE_SECRET_KEY to enable)
[knarr] Proxy auth: open (set KNARR_API_KEY to require authentication)
```

Each provider gets a default model:

| Provider | Default Model | ENV Variable |
|----------|---------------|--------------|
| OpenAI | gpt-4o-mini | `OPENAI_API_KEY` |
| Anthropic | claude-sonnet-4-6 | `ANTHROPIC_API_KEY` |
| Groq | llama-3.3-70b-versatile | `GROQ_API_KEY` |
| Mistral | mistral-large-latest | `MISTRAL_API_KEY` |
| DeepSeek | deepseek-chat | `DEEPSEEK_API_KEY` |
| MiniMax | MiniMax-M2.1 | `MINIMAX_API_KEY` |
| Gemini | gemini-2.0-flash | `GEMINI_API_KEY` |
| OpenRouter | openai/gpt-4o-mini | `OPENROUTER_API_KEY` |
| Perplexity | sonar | `PERPLEXITY_API_KEY` |
| Cerebras | llama-3.3-70b | `CEREBRAS_API_KEY` |

With auto-discover enabled (default), Knarr queries each provider's model
list — so you can use any model they offer, not just the defaults.

## Langfuse Tracing

Knarr traces every request automatically when Langfuse credentials are set.
Add these to your `.env`:

```bash
LANGFUSE_PUBLIC_KEY=pk-lf-...
LANGFUSE_SECRET_KEY=sk-lf-...
```

That's it. Every proxy request creates:

- **Trace** with model name, engine type, API format, and full input/output
- **Generation** with start/end time, token usage, and model information
- **Error tracking** when backend calls fail
- Tag `knarr` on all traces

### Langfuse Cloud

Just set the keys — Langfuse Cloud (`https://cloud.langfuse.com`) is the
default:

```bash
# .env
OPENAI_API_KEY=sk-...
LANGFUSE_PUBLIC_KEY=pk-lf-...
LANGFUSE_SECRET_KEY=sk-lf-...
```

### Self-Hosted Langfuse

Use `docker compose up` for a local Langfuse stack, or point at your own:

```bash
# .env
LANGFUSE_PUBLIC_KEY=pk-lf-...
LANGFUSE_SECRET_KEY=sk-lf-...
LANGFUSE_URL=http://my-langfuse-server:3000
```

## Proxy Authentication

Protect your proxy with an API key:

```bash
# .env
KNARR_API_KEY=my-secret-proxy-key
```

Clients must send `Authorization: Bearer my-secret-proxy-key` or
`x-api-key: my-secret-proxy-key`. The `/health` endpoint is always open.

## API Formats

Knarr accepts three API formats and routes them to any Langertha backend:

### OpenAI (Port 8080)

```bash
curl http://localhost:8080/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"model":"gpt-4o-mini","messages":[{"role":"user","content":"Hello"}]}'

curl http://localhost:8080/v1/models
```

### Anthropic (Port 8080)

```bash
curl http://localhost:8080/v1/messages \
  -H "Content-Type: application/json" \
  -d '{"model":"claude-sonnet-4-6","messages":[{"role":"user","content":"Hello"}],"max_tokens":1024}'
```

### Ollama (Port 11434)

```bash
curl http://localhost:11434/api/chat \
  -d '{"model":"gpt-4o-mini","messages":[{"role":"user","content":"Hello"}]}'

curl http://localhost:11434/api/tags
```

All formats support streaming — SSE for OpenAI/Anthropic, NDJSON for Ollama.

## Use Cases

### Claude Code through any backend

```bash
docker run --env-file .env -p 8080:8080 raudssus/langertha-knarr

# In another terminal:
ANTHROPIC_BASE_URL=http://localhost:8080 claude
```

Every Claude Code request gets traced in Langfuse.

### Ollama clients with cloud models

Use cloud LLMs from any Ollama-compatible client like
[Open WebUI](https://github.com/open-webui/open-webui):

```bash
docker run --env-file .env -p 11434:11434 raudssus/langertha-knarr

# Open WebUI connects to port 11434, thinks it's Ollama,
# but requests go to cloud providers through Knarr
```

### Local + Cloud hybrid

Mount a config file for custom routing:

```yaml
# knarr.yaml
models:
  llama3.2:
    engine: OllamaOpenAI
    url: http://host.docker.internal:11434/v1
    model: llama3.2
  gpt-4o:
    engine: OpenAI
default:
  engine: OllamaOpenAI
  url: http://host.docker.internal:11434/v1
```

```bash
docker run --env-file .env \
  -v ./knarr.yaml:/etc/knarr/config.yaml \
  -p 8080:8080 -p 11434:11434 \
  raudssus/langertha-knarr start -c /etc/knarr/config.yaml
```

## Using a Config File

For more control than auto-detection, create a `knarr.yaml`:

```yaml
listen:
  - "127.0.0.1:8080"
  - "127.0.0.1:11434"

models:
  gpt-4o:
    engine: OpenAI

  gpt-4o-mini:
    engine: OpenAI
    model: gpt-4o-mini

  claude-sonnet:
    engine: Anthropic
    model: claude-sonnet-4-6
    api_key: ${ANTHROPIC_API_KEY}

  local-llama:
    engine: OllamaOpenAI
    url: http://localhost:11434/v1
    model: llama3.2

  deepseek:
    engine: DeepSeek
    model: deepseek-chat

default:
  engine: OpenAI

auto_discover: true

# Passthrough: requests go directly to upstream APIs
# The client's own API key is used — no duplication needed
# Models with explicit config above are routed via Langertha,
# everything else passes through transparently
passthrough:
  anthropic: https://api.anthropic.com
  openai: https://api.openai.com
  # Or point at a custom upstream:
  # anthropic: https://my-anthropic-cache.internal

# proxy_api_key: your-secret

# langfuse:
#   url: http://localhost:3000
#   public_key: pk-lf-...
#   secret_key: sk-lf-...
```

Config values support `${ENV_VAR}` interpolation — variables are resolved
at startup.

### Passthrough Mode

Passthrough is the default behavior: requests go directly to the upstream
API (Anthropic, OpenAI) using the client's own API key. No key duplication,
no model configuration needed. Knarr just sits in the middle and traces.

If you also configure explicit model routing (the `models:` section), those
specific models are handled by Langertha engines. Everything else still
passes through.

**Enabled by default** in container mode. In a config file:

```yaml
# Enable with default upstream URLs
passthrough: true

# Or per format with custom upstreams
passthrough:
  anthropic: https://api.anthropic.com
  openai: https://my-openai-mirror.internal
```

Claude Code example — no Knarr API key needed, your existing key works:

```bash
docker run -p 8080:8080 raudssus/langertha-knarr
ANTHROPIC_BASE_URL=http://localhost:8080 claude
```

### Generating a Config

Knarr can generate a config from your environment:

```bash
# Via Docker — pass your env vars through
docker run --rm --env-file .env raudssus/langertha-knarr init > knarr.yaml

# Or pass all API keys from your current shell
docker run --rm \
  $(env | grep -E '_(API_KEY|API_TOKEN)=|^LANGFUSE_' | sed 's/^/-e /') \
  raudssus/langertha-knarr init > knarr.yaml
```

Then mount it:

```bash
docker run --env-file .env \
  -v ./knarr.yaml:/etc/knarr/config.yaml \
  -p 8080:8080 -p 11434:11434 \
  raudssus/langertha-knarr start -c /etc/knarr/config.yaml
```

## All Environment Variables

### API Keys

| Variable | Provider |
|----------|----------|
| `OPENAI_API_KEY` | OpenAI |
| `ANTHROPIC_API_KEY` | Anthropic |
| `GROQ_API_KEY` | Groq |
| `MISTRAL_API_KEY` | Mistral |
| `DEEPSEEK_API_KEY` | DeepSeek |
| `MINIMAX_API_KEY` | MiniMax |
| `GEMINI_API_KEY` | Gemini |
| `OPENROUTER_API_KEY` | OpenRouter |
| `PERPLEXITY_API_KEY` | Perplexity |
| `CEREBRAS_API_KEY` | Cerebras |
| `REPLICATE_API_TOKEN` | Replicate |
| `HUGGINGFACE_API_KEY` | HuggingFace |

`LANGERTHA_`-prefixed variants (e.g., `LANGERTHA_OPENAI_API_KEY`) take
priority over bare names.

### Langfuse

| Variable | Description | Default |
|----------|-------------|---------|
| `LANGFUSE_PUBLIC_KEY` | Public key (`pk-lf-...`) | — |
| `LANGFUSE_SECRET_KEY` | Secret key (`sk-lf-...`) | — |
| `LANGFUSE_URL` | Server URL | `https://cloud.langfuse.com` |

### Proxy

| Variable | Description | Default |
|----------|-------------|---------|
| `KNARR_API_KEY` | Require client authentication | — (open) |

## CLI Reference

```
knarr                     Show help
knarr container           Auto-start from ENV (Docker default)
knarr start               Start with config file (./knarr.yaml)
knarr start -p 9090       Custom port
knarr start -c prod.yaml  Custom config
knarr init                Generate config from environment
knarr init -e .env        Include .env file in scan
knarr models              List configured models
knarr models --format json
knarr check               Validate config file
```

## Installing as a Perl Module

Knarr is also a standard CPAN distribution:

```bash
cpanm Langertha::Knarr
```

Then use the `knarr` CLI directly:

```bash
export OPENAI_API_KEY=sk-...
knarr init > knarr.yaml
knarr start
```

### Using Knarr Programmatically

```perl
use Langertha::Knarr;
use Langertha::Knarr::Config;

# Build from YAML config
my $config = Langertha::Knarr::Config->new(file => 'knarr.yaml');
my $app    = Langertha::Knarr->build_app(config => $config);

# Or build from environment (like container mode)
my $config = Langertha::Knarr::Config->from_env;
my $app    = Langertha::Knarr->build_app(config => $config);

# $app is a Mojolicious app — embed, test, or run as you like
use Mojo::Server::Daemon;
Mojo::Server::Daemon->new(
  app    => $app,
  listen => ['http://127.0.0.1:8080'],
)->run;
```

### Using the Config and Router Independently

```perl
use Langertha::Knarr::Config;
use Langertha::Knarr::Router;

my $config = Langertha::Knarr::Config->new(file => 'knarr.yaml');
my $router = Langertha::Knarr::Router->new(config => $config);

# Resolve a model name to a Langertha engine
my ($engine, $model) = $router->resolve('gpt-4o-mini');
# $engine is a Langertha::Engine::OpenAI (or whatever the config maps to)
# $model is the resolved model name

my $response = $engine->simple_chat(
  { role => 'user', content => 'Hello!' },
);
```

## Built With

- [Langertha](https://metacpan.org/pod/Langertha) — Perl LLM framework with 22+ engine backends
- [Mojolicious](https://mojolicious.org/) — Real-time web framework for Perl
- [Langfuse](https://langfuse.com) — Open source LLM observability

## License

This software is copyright (c) 2026 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
