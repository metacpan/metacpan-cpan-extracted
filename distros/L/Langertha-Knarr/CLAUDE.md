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
Client → [OpenAI|Anthropic|Ollama format] → Knarr Proxy
                                               │
                                    ┌──────────┴──────────┐
                                    │                     │
                              Model configured?      Passthrough
                                    │                     │
                              Router → Engine        Raw HTTP 1:1
                                    │                     │
                              Langfuse Tracing       Langfuse Tracing
```

Unconfigured models go through **raw passthrough** — all HTTP bytes (headers,
body, SSE chunks) are piped 1:1 to the upstream API. This preserves tool_use,
usage data, cache_control, and all protocol-specific metadata.

### Module Structure

- **Langertha::Knarr** — IO::Async server, dispatch, raw passthrough
- **Langertha::Knarr::Config** — YAML config loader, validation, env scanning
- **Langertha::Knarr::Router** — Model → Engine routing with caching + auto-discovery
- **Langertha::Knarr::Request** — Normalized request value object (protocol, messages, tools, tool_choice, response_format, …)
- **Langertha::Knarr::Response** — Normalized response value object (content, model, usage, tool_calls, finish_reason); `coerce()` upgrades any legacy shape
- **Langertha::Knarr::Stream** — Async chunk iterator; `from_list`, `from_callback` constructors
- **Langertha::Knarr::Tracing** — Langfuse trace/generation per request (async flush via Net::Async::HTTP)
- **Langertha::Knarr::RequestLog** — JSONL per-request logging
- **Langertha::Knarr::Protocol::OpenAI** — `/v1/chat/completions`, `/v1/models`
- **Langertha::Knarr::Protocol::Anthropic** — `/v1/messages`
- **Langertha::Knarr::Protocol::Ollama** — `/api/chat`, `/api/generate`, `/api/tags`, `/api/version`
- **Langertha::Knarr::Protocol::A2A** — Google Agent2Agent JSON-RPC
- **Langertha::Knarr::Protocol::ACP** — BeeAI/Linux Foundation ACP
- **Langertha::Knarr::Protocol::AGUI** — CopilotKit AG-UI
- **Langertha::Knarr::Handler** — Moose role for all handlers
- **Langertha::Knarr::Handler::Router** — Model routing, passthrough fallback
- **Langertha::Knarr::Handler::Passthrough** — Raw HTTP forwarding to upstream APIs
- **Langertha::Knarr::Handler::Tracing** — Langfuse decorator (wraps any handler)
- **Langertha::Knarr::Handler::RequestLog** — JSONL logging decorator
- **Langertha::Knarr::Handler::Engine** — Single Langertha engine handler
- **Langertha::Knarr::Handler::Raider** — Per-session Langertha::Raider
- **Langertha::Knarr::Handler::Code** — Coderef handler (tests/fakes)
- **Langertha::Knarr::Handler::A2AClient** — Remote A2A agent consumer
- **Langertha::Knarr::Handler::ACPClient** — Remote ACP agent consumer
- **Langertha::Knarr::CLI** — MooX::Cmd entry point
- **Langertha::Knarr::CLI::Cmd::Start** — `knarr start` (also `--from-env` for Docker)
- **Langertha::Knarr::CLI::Cmd::Models** — `knarr models`
- **Langertha::Knarr::CLI::Cmd::Check** — `knarr check`
- **Langertha::Knarr::CLI::Cmd::Init** — `knarr init` (env scanning, config generation)

### Streaming Formats

| Format | Protocol | End Marker |
|--------|----------|------------|
| OpenAI | SSE | `data: [DONE]` |
| Anthropic | SSE | `event: message_stop` |
| Ollama | NDJSON | `{"done": true}` |

## OOP Framework

- **Moose**: Knarr.pm, Handler role, all Handler::* modules, Protocol::* modules, Request, Response, Session, Stream
- **Moo**: CLI, Config, Router, Tracing, RequestLog

CLI uses MooX::Cmd + MooX::Options.

## Config Format

Default host `0.0.0.0`, ports 8080 + 11434.

```yaml
listen:
  - "0.0.0.0:8080"
  - "0.0.0.0:11434"
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

Passthrough is the default: unconfigured models go directly to upstream APIs
using the client's own API key and headers (piped 1:1 as raw bytes). Models
with explicit config are routed via Langertha engines instead. Both paths
get Langfuse tracing.

Config: `passthrough: true` or per-format with URLs.

## Testing

```bash
prove -l t/         # All tests
prove -lv t/10-config.t   # Config tests
```

## CLI

```bash
knarr start                                # Start with ./knarr.yaml
knarr start -c production.yaml             # Custom config
knarr start --from-env                     # Auto-detect config from ENV
knarr start --from-env -p 8080 -p 11434   # ENV config, custom ports
knarr start -p 9090                        # Single port
knarr models                               # List models
knarr models --format json                 # JSON output
knarr check                                # Validate config
knarr init                                 # Generate config from env
knarr init -e .env -e .env.local           # Scan .env files
```

## Environment

- `KNARR_DEBUG=1` — Enable verbose logging (same as `--verbose`)
