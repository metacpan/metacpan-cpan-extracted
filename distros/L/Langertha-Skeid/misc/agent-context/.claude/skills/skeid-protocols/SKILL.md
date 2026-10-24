---
name: skeid-protocols
description: Load when working on the protocols Skeid speaks — OpenAI, Anthropic and Ollama client formats, translation upstream, SSE streaming, tool calls, header and auth forwarding.
user-invocable: false
allowed-tools: Read, Grep, Glob, Edit, Write, Bash
---

Everything about the wire. Terms (**API format**, **Engine ID**, **Translation**, **Upstream**,
**SSE relay**) are defined in `CONTEXT.md`. The relayed routes (audio, rerank, realtime) and the MCP
gateway: skill `skeid-relay-routes`.

## The one-hub rule

Skeid speaks three **API formats** to clients but makes exactly one kind of upstream call:
OpenAI `POST {node.url}/chat/completions` (or `/embeddings`). Every other format is translated in
and out. Not negotiable:

- A format-specific field name (`system`, `tool_use`, `prompt_eval_count`, …) appears only inside
  that format's translation functions. Never in routing, usage, or the upstream call.
- A new **API format** = one request translator, one response translator, one route, one
  `api_format` string in the usage meta. Never a second upstream code path.
- The upstream call is engine-agnostic: vLLM, SGLang, Ollama-in-OpenAI-mode and OpenAI take the
  same body; the **Engine ID** is metadata for accounting and eligibility, not a branch in the
  request builder.
- A non-chat route of the OpenAI face (audio, rerank) is **relayed** to the node's endpoint of
  the same name, not translated into the chat call (ADR 0021) — a second path and body shape,
  not a second proxy function. Documents (`/v1/convert/*`, docling) follow the same rule with no
  `model`: planned over nodes of `kind: documents` under the routing key `documents` (skill
  `skeid-relay-routes`).
  The realtime route (`GET /v1/realtime`, ADR 0029) is the one that is a *session*: a WebSocket
  relayed in the node's own events, one slot and one usage event for its whole length.

## Client edge

| API format | Routes | Streaming |
|---|---|---|
| OpenAI | `POST /v1/chat/completions`, `POST /v1/embeddings`, `GET /v1/models` | yes, SSE relay |
| OpenAI, relayed (ADR 0021) | `POST /v1/audio/transcriptions`, `POST /v1/audio/translations` | yes, SSE relay in the node's own event dialect |
| OpenAI, relayed (ADR 0021) | `POST /v1/rerank`, `POST /rerank` (one route) | no |
| OpenAI, relayed session (ADR 0029) | `GET /v1/realtime` (WebSocket upgrade; `model` in the query) | yes — frames both ways, the node's own events |
| Anthropic | `POST /v1/messages` | yes — OpenAI SSE re-chunked into Anthropic events (`Protocol::Anthropic::Stream`) |
| Ollama | `POST /api/chat`, `POST /api/generate`, `GET /api/tags`, `GET /api/ps` | yes — NDJSON (`Protocol::Ollama::Stream`, `shape => 'generate'` for `/api/generate`) |
| API description, not a face (ADR 0025) | `GET /openapi.json` (client routes the config enables, behind the client gate), `GET /skeid/openapi.json` (admin key), `GET /docs` + `/docs/*` (Swagger UI, `openapi.swagger_ui`, fetched on first use and cached, else 404) | no |
| Relayed, docling's own paths (ADR 0028) | `POST /v1/convert/file`, `POST /v1/convert/source` (sync only) | no — JSON or zip answer as the node gave it |
| MCP gateway, not a face (ADR 0022) | `POST|GET|DELETE /mcp/<name>[/<path>]`, `GET /v1/mcp/servers` | yes — whatever the MCP server sends, unbuffered |

- Embeddings take the chat path (`_begin_route_async`): nodes of one model share load with health,
  `max_conns`, capacity readings, aliases and tiers; one request = one slot whatever its batch
  size; the answer is relayed byte for byte, `usage.prompt_tokens` / `total_tokens` metered as
  input tokens. No Ollama `/api/embed`. `t/70-embeddings-nodes.t`.
- `GET /health` is unauthenticated and cheap (also with `client_auth`); `/skeid/*` is the admin
  surface (skill `skeid-core`). `GET /.well-known/langertha.json` serves the per-key provider
  manifest (ADR 0015).
- Streams on every face are metered and priced like non-streamed requests (verbatim upstream
  usage frame through `metrics.normalize`, skeid #41); images become OpenAI `image_url` parts on
  the Anthropic and Ollama faces (skeid #42/#43).

## Translation

`Langertha::Skeid::Protocol::Anthropic`
- request → OpenAI: `system` (string or block array) becomes a leading system message, joined by
  any `role: system` messages before the first turn. A later `role: system` message (Claude Code
  mid-conversation system) is never a system message and never moved into the leading one (prefix
  caching): wrapped in `<system-reminder>` it is appended to the preceding user message, else
  prepended to the next one, else its own user message — never between `tool_calls` and their
  `tool` messages (k100).
- Content blocks fold to text, except `image` blocks (base64 or url source) → OpenAI content array
  with `image_url` parts in client order; a Files API image is a `400`. `tool_use` blocks →
  `tool_calls` on an assistant message; `tool_result` blocks → their own `role => 'tool'` message
  with `tool_call_id`, their images lifted into one user message after the tool messages.
  `tools` / `tool_choice` go through `Langertha::Tool->from_list` /
  `Langertha::ToolChoice->from_hash` and out via `->to_openai`. A provider built-in tool
  (`web_search_*`, `bash_*`, …) is a `400`, never forwarded.
- response → Anthropic: content → `text` block, tool calls → `tool_use` blocks via
  `Langertha::ToolCall->to_anthropic_block`; `finish_reason` `tool_calls → tool_use` (also `stop`
  when tool calls are present), `length → max_tokens`, else `end_turn`; usage → `input_tokens` /
  `output_tokens`.

`Langertha::Skeid::Protocol::Ollama`
- request → OpenAI: `options.temperature` / `options.num_predict` → `temperature` /
  `max_tokens`; `format` → `response_format` (`json_object`, or `json_schema` named
  `ollama_format`); raw base64 `images` → `data:` `image_url` parts typed by magic bytes; tool
  round-trips translated to OpenAI shape. `/api/generate` (`generate_request_to_openai`) turns
  `system` + `prompt` into one chat conversation.
- response → Ollama: `message.content`, optional `message.tool_calls` via `->to_ollama`, `done` as
  JSON `true` (not `1` — typed clients reject it), `done_reason` from `finish_reason`, token
  counts as `prompt_eval_count` / `eval_count`; `/api/generate` answers in generate's shape
  (`response`, …).
- `/api/tags` synthesises a model list from the node inventory; `/api/ps` is a stub `[]`.

Errors take the client's shape: `_render_error` reads stash key `skeid.error_format` (set by the
`/v1/messages` route and the `/api` block) and renders the Anthropic envelope, Ollama's
`{"error": "<string>"}`, or the OpenAI error object. Each face's manifest capability list lives
with its translator (`manifest_endpoint`; OpenAI's in `Langertha::Skeid::Protocol`).

**Tool calls are Langertha's job, not Skeid's.** `Langertha::Tool`, `Langertha::ToolCall`,
`Langertha::ToolChoice` own every format's tool shape, including Hermes-style
`<tool_call>{…}</tool_call>` recovery from plain text (`ToolCall->extract_hermes_from_text`).
Never hand-roll a parser here — extend Langertha and pin the new `Langertha` version in
`cpanfile`.

## Upstream call

`POST {node.url}/chat/completions` or `/embeddings`; a relayed route posts to its own path; a
`rerank_format: tei` node is called at its server root (`_root_url_for_node`).
`_endpoint_url_for_node($base, $path)` appends `/v1` unless the node url already ends in `/v1`.
A node url is a base, never a full endpoint.

`_forward_headers` passes the client's headers minus the hop-by-hop set (`connection`,
`keep-alive`, `proxy-authenticate`, `proxy-authorization`, `te`, `trailer`, `transfer-encoding`,
`upgrade`) and `host`, `content-length`, `accept-encoding`. `_inject_node_auth_async` then
overrides `Authorization`:

1. **KeyBroker**, if the node has `api_key_ref` — per request through `key_async` (in-memory
   cache, coalesced misses; never `resolve_key` on the request path).
2. **`api_key_env`** fallback — key from that environment variable.
3. Neither **configured** → the client's own `Authorization` survives (pass-through deployments).

A node with `api_key_header` (docling's `X-Api-Key`) gets the raw key in that header instead of
`Authorization: Bearer`; dropping the client's credentials and the fail-closed rule are the same.
- When a key is injected, the client's `Authorization` and `x-api-key` are dropped first, in any
  spelling (`_drop_client_credentials`; Mojolicious hands `X-Api-Key` on as written, and an
  exact-case delete forwards it beside the node's key) — an Anthropic-style client never leaks
  its key upstream.
- A resolve failure warns with the reference — never the key or a vault response body — and falls
  through to `api_key_env`.
- **A configured key source that yields no key fails closed.** Broker error or cached failure, no
  broker at all (failed OpenBao login at boot), variable unset or empty, or a node that left the
  inventory after selection: the callback gets a reason, both callers answer through
  `_refuse_unkeyed_node` — no upstream call, `request.finish` with `ok => 0`, one failed usage
  event, `503 upstream_key_unavailable` in the face's error shape. Pass-through is only for a node
  naming *no* key source; taking it for a node whose key went missing sends the customer's key to
  the provider. The reason (reference, variable name) goes to log and usage event, not to the
  client. `t/61-node-key-fail-closed.t` fails if the pass-through comes back.

## Caller identity

- **Customer key ID** derives from the presented key (`Authorization` bearer, else `x-api-key`):
  `k_` + full SHA-1 hex (`Langertha::Skeid->key_id_for_key`, ADR 0016), or `anonymous`. A legacy
  12-hex id in the config still matches by prefix. The raw key is never stored, logged or
  reported — the hash exists so metering works without keeping it.
- `x-skeid-key-id` (or `x-api-key-id`) overrides **only** when `routing.trust_key_id_header` is
  set (callers authenticated before Skeid). Never the default, never a second way in: the ADR 0008
  routing policy hangs off this id, so a client-settable id turns permissions into a suggestion.
  `t/26-key-policies.t` fails if that check goes away.
- **A key can also arrive in the subprotocol** (`Sec-WebSocket-Protocol:
  openai-insecure-api-key.<key>`, a browser's WebSocket cannot set a header): only on
  `/v1/realtime`, only when neither `Authorization` nor `x-api-key` is present, never answered,
  logged or forwarded (`_extract_request_api_key`; skill `skeid-relay-routes`).
- **Client authentication** (`client_auth:`, ADR 0020) is the only place a key is refused for
  *who* it is: every client route's `under` bridge (`_authorize_client`) reloads the config, then
  answers `401` + `WWW-Authenticate` in the face's dialect to an id not on the list — before body
  parsing, `request.start`, broker, upstream or usage event. A new client route goes behind its
  face's bridge, or it is an open door. `/health` and `/skeid/*` stay outside.
  `t/67-client-auth.t`. The MCP routes call the same gate from their own bridge.
- `x-request-id` is honoured if present, else a `req_<ms>_<rand>` id is generated.

## Streaming mechanics

`_proxy_openai_stream` serves every face. The upstream body is read raw (`Proxy::RelayContent`, so
an unchunked `text/event-stream` is not swallowed by Mojolicious's SSE parser); `data: {…}` lines
are parsed across read boundaries for content size and the verbatim `usage` block; one usage event
on completion. Without a translator the bytes are relayed as they came; with one
(`Protocol::*::Stream`) each parsed chunk goes through `->delta` and the client gets the
translator's framing and content type.

- Never rewrite a chunk on the OpenAI face. The relay is byte-transparent; anything else breaks
  client parsers and makes TTFT unmeasurable.
- `content-length`, `transfer-encoding`, `content-encoding` are stripped from relayed headers (a
  translated stream also drops `content-type`); `x-skeid-node` is added.
- Chunks go out through a drain queue, not one `write_chunk` per read — a dynamic response with no
  drain callback ends when its queue empties.
- Headers go out on the first chunk. On a translated face an upstream error status before that is
  a plain HTTP error in the client's shape; after it the failure travels in-band (Anthropic
  `error` event, Ollama error line) and the stream is `ok = 0`, as is a body cut short of its own
  framing. Every path calls `request.finish` exactly once.
- Anthropic and Ollama streams go upstream with `stream_options.include_usage`; the OpenAI face
  forwards the client's body as is. Missing usage is expected: the event gets zeroed tokens.

## Engine IDs

`supported_engine_ids` is discovered from the installed `Langertha`, with a compiled-in fallback
list. `normalize_engine_id` lowercases and strips separators (`OpenAI-Base` = `openaibase`). An
unknown engine id on a node is not fatal — it only gates eligibility and lands in the usage event.

## Testing protocols

`Test::Mojo` against `Langertha::Skeid::Proxy->build_app(skeid => $skeid)` with a fake upstream
mounted in the same app (a second Mojolicious route the node url points at). Assert the
translated *shape*, not a golden JSON blob — pinning every upstream field fails on the next
harmless addition and says nothing about the contract.
