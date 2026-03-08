# Langertha::Knarr — CLAUDE.md

## Overview

Knarr is an LLM proxy that accepts requests in OpenAI, Anthropic, or Ollama format, routes them to any Langertha backend engine, and traces everything via Langfuse.

## Build System

Uses `[@Author::GETTY]` Dist::Zilla plugin bundle.

```bash
dzil test           # Build and test
prove -l t/         # Run tests directly
prove -lv t/10-config.t  # Single test, verbose
```

## Architecture

### Request Flow

```
Client → [OpenAI|Anthropic|Ollama format] → Knarr Proxy → Router → Langertha Engine → Backend
                                               ↓
                                          Langfuse Tracing
```

### Module Structure

- **Langertha::Knarr** — Mojolicious app builder, route wiring
- **Langertha::Knarr::Config** — YAML config loader, validation, env scanning
- **Langertha::Knarr::Router** — Model → Engine routing with caching + auto-discovery
- **Langertha::Knarr::Tracing** — Langfuse trace/generation per request
- **Langertha::Knarr::Proxy::OpenAI** — `/v1/chat/completions`, `/v1/models`, `/v1/embeddings`
- **Langertha::Knarr::Proxy::Anthropic** — `/v1/messages`
- **Langertha::Knarr::Proxy::Ollama** — `/api/chat`, `/api/tags`, `/api/ps`
- **Langertha::Knarr::CLI** — MooX::Cmd entry point
- **Langertha::Knarr::CLI::Cmd::Start** — `knarr start`
- **Langertha::Knarr::CLI::Cmd::Models** — `knarr models`
- **Langertha::Knarr::CLI::Cmd::Check** — `knarr check`
- **Langertha::Knarr::CLI::Cmd::Init** — `knarr init` (env scanning, config generation)
- **Langertha::Knarr::CLI::Cmd::Container** — `knarr container` (auto-start from ENV, Docker mode)

### Three Streaming Formats

| Format | Protocol | End Marker |
|--------|----------|------------|
| OpenAI | SSE | `data: [DONE]` |
| Anthropic | SSE | `event: message_stop` |
| Ollama | NDJSON | `{"done": true}` |

## OOP Framework

Moo (not Moose). CLI uses MooX::Cmd + MooX::Options.

## Config Format

Default: listens on 127.0.0.1:8080 (OpenAI/Anthropic) + 127.0.0.1:11434 (Ollama).
vLLM default port 8000 can be added.

```yaml
listen:
  - "127.0.0.1:8080"
  - "127.0.0.1:11434"
  # - "127.0.0.1:8000"  # vLLM port
models:
  gpt-4o:
    engine: OpenAI
  local:
    engine: OllamaOpenAI
    url: http://localhost:11434/v1
default:
  engine: OpenAI
auto_discover: true
passthrough:
  anthropic: https://api.anthropic.com
  openai: https://api.openai.com
```

### Passthrough Mode

Passthrough is the default: requests go directly to upstream APIs using the
client's own API key. Models with explicit config are routed via Langertha
engines instead. Enabled by default in container mode. Config: `passthrough: true`
or per-format with URLs.

## Testing

```bash
prove -l t/         # All tests
prove -lv t/10-config.t   # Config tests
prove -lv t/50-integration.t  # Integration with Test::Mojo
```

## CLI

```bash
knarr start                           # Start proxy (requires config file)
knarr start --port 9090               # Custom port
knarr container                       # Auto-start from ENV (Docker mode)
knarr models                          # List models
knarr models --format json            # JSON output
knarr check                           # Validate config
knarr init                            # Generate config from env
knarr init -e .env -e .env.local      # Scan .env files
```
