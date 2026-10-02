---
name: skeid-protocols
description: Load when working on the protocols Skeid speaks — OpenAI, Anthropic and Ollama client formats, translation upstream, SSE streaming, tool calls, header and auth forwarding.
user-invocable: false
allowed-tools: Read, Grep, Glob, Edit, Write, Bash
---

Everything about the wire. Terms (**API format**, **Engine ID**, **Translation**, **Upstream**,
**SSE relay**) are defined in `CONTEXT.md`.

## The one-hub rule

Skeid speaks three **API formats** to clients but makes exactly one kind of upstream call:
OpenAI `POST {node.url}/chat/completions` (or `/embeddings`). Every other format is translated
in and out. Consequences that are not negotiable:

- A format-specific field name (`system`, `tool_use`, `prompt_eval_count`, …) may appear only
  inside that format's translation functions. Never in routing, usage, or the upstream call.
- Adding an **API format** means: one request translator, one response translator, one route,
  one `api_format` string in the usage meta. It does not mean a second upstream code path.
- The upstream call is engine-agnostic. vLLM, SGLang, Ollama-in-OpenAI-mode and OpenAI itself
  all take the same body; the **Engine ID** is metadata for accounting and eligibility, not a
  branch in the request builder.

## Client edge

| API format | Routes | Streaming |
|---|---|---|
| OpenAI | `POST /v1/chat/completions`, `POST /v1/embeddings`, `GET /v1/models` | yes, SSE relay |
| Anthropic | `POST /v1/messages` | yes — OpenAI SSE re-chunked into Anthropic events (`Protocol::Anthropic::Stream`) |
| Ollama | `POST /api/chat`, `POST /api/generate`, `GET /api/tags`, `GET /api/ps` | yes — NDJSON (`Protocol::Ollama::Stream`, `shape => 'generate'` for `/api/generate`) |

`GET /health` is unauthenticated and cheap; `/skeid/*` is the admin surface (skill
`skeid-core`). `GET /.well-known/langertha.json` serves the per-key provider manifest (ADR 0015).

Streams on every face are metered and priced like non-streamed requests (the verbatim upstream
usage frame goes through `metrics.normalize`, skeid #41); images are translated to OpenAI
`image_url` parts on the Anthropic and Ollama faces (skeid #42/#43).

## Translation

`Langertha::Skeid::Protocol::Anthropic`
- request → OpenAI: `system` (string or block array) becomes a leading system message; content
  blocks fold to text, except that `image` blocks (base64 or url source) make an OpenAI content
  array with `image_url` parts in client order — a Files API image is a `400`; `tool_use`
  blocks become `tool_calls` on an assistant message; `tool_result` blocks become their own
  `role => 'tool'` message with `tool_call_id`, their images lifted into one user message after
  the tool messages; `tools` and `tool_choice` go through `Langertha::Tool->from_list` /
  `Langertha::ToolChoice->from_hash` and out via `->to_openai`. A provider built-in tool
  (`web_search_*`, `bash_*`, …) is a `400`, never forwarded.
- response → Anthropic: content becomes a `text` block, tool calls become `tool_use` blocks via
  `Langertha::ToolCall->to_anthropic_block`, `finish_reason` maps `tool_calls → tool_use` (also
  `stop` when tool calls are present), `length → max_tokens`, everything else → `end_turn`,
  usage becomes `input_tokens` / `output_tokens`.

`Langertha::Skeid::Protocol::Ollama`
- request → OpenAI: `options.temperature` / `options.num_predict` lift to `temperature` /
  `max_tokens`; `format` becomes `response_format` (`json_object`, or `json_schema` named
  `ollama_format`); a message's raw base64 `images` become `data:` `image_url` parts typed by
  magic bytes; tool round-trips are translated to OpenAI shape. `/api/generate`
  (`generate_request_to_openai`) turns `system` + `prompt` into one chat conversation.
- response → Ollama: `message.content`, optional `message.tool_calls` via `->to_ollama`,
  `done` as JSON `true` (not `1`, which typed clients reject), `done_reason` from
  `finish_reason`, token counts as `prompt_eval_count` / `eval_count`; `/api/generate` answers
  in generate's shape (`response`, …).
- `/api/tags` synthesises a model list from the node inventory; `/api/ps` is a stub `[]`.

Errors take the client's shape too: `_render_error` reads the stash key `skeid.error_format`
(set by the `/v1/messages` route and the `/api` block) and renders the Anthropic envelope, the
Ollama `{"error": "<string>"}`, or the OpenAI error object. Each face's manifest capability list
lives with its translator (`manifest_endpoint`; OpenAI's in `Langertha::Skeid::Protocol`).

**Tool calls are Langertha's job, not Skeid's.** `Langertha::Tool`, `Langertha::ToolCall`,
`Langertha::ToolChoice` own every format's tool shape, including recovering Hermes-style
`<tool_call>{…}</tool_call>` blocks out of plain text
(`ToolCall->extract_hermes_from_text`). Never hand-roll a parser here — extend Langertha
instead, and pin the new `Langertha` version in `cpanfile`.

## Upstream call

`_endpoint_url_for_node($base, $path)` — appends `/v1` unless the node url already ends in
`/v1`. A node url is a base, never a full endpoint.

`_forward_headers` passes the client's headers through minus the hop-by-hop set
(`connection`, `keep-alive`, `proxy-authenticate`, `proxy-authorization`, `te`, `trailer`,
`transfer-encoding`, `upgrade`) and `host`, `content-length`, `accept-encoding`.
`_inject_node_auth_async` then overrides `Authorization`:

1. **KeyBroker**, if the node has `api_key_ref` — resolved per request through `key_async`
   (in-memory cache, coalesced misses; never `resolve_key` on the request path).
2. **`api_key_env`** fallback — key from that environment variable.
3. Neither **configured** → the client's own `Authorization` survives (pass-through
   deployments).

When a key is injected, the client's `Authorization` and `x-api-key` are dropped first — in
any spelling (`_drop_client_credentials`; Mojolicious hands `X-Api-Key` on as the client wrote
it, and an exact-case delete forwards it beside the node's key) — so an Anthropic-style client
can never leak its own key upstream. A resolve failure warns — with the reference, never the key or
a vault response body — and falls through to `api_key_env`.

**A configured key source that yields no key fails closed.** Broker error or cached failure, no
broker at all (a failed OpenBao login at boot), variable unset or empty, or a node that left
the inventory after it was selected (its key source is unknown): the callback gets a reason, and both callers answer through `_refuse_unkeyed_node` — no upstream call,
`request.finish` with `ok => 0`, one failed usage event, `503 upstream_key_unavailable` in the
face's error shape. The pass-through is for a node that names *no* key source; taking it for a
node whose key went missing sends the customer's key to the provider. The reason (reference,
variable name) goes to the log and the usage event, not to the client. `t/61-node-key-fail-closed.t`
fails if the pass-through comes back.

## Caller identity

The **Customer key ID** is derived from the key the caller presented (`Authorization` bearer,
else `x-api-key`): `k_` plus its full SHA-1 hex (`Langertha::Skeid->key_id_for_key`, ADR 0016),
or `anonymous`. A legacy 12-hex id in the config still matches by prefix. The raw key is never
stored, logged, or reported — the hash exists precisely so metering works without keeping it.

`x-skeid-key-id` (or `x-api-key-id`) overrides that **only** when
`routing.trust_key_id_header` is set, for deployments that authenticate callers before Skeid
sees them. Do not make it the default and do not add a second way in: the routing policy of
ADR 0008 hangs off this id, so anything a client can set freely turns permissions into a
suggestion. `t/26-key-policies.t` fails if that check goes away.

`x-request-id` is honoured if present, otherwise a `req_<ms>_<rand>` id is generated.

## Streaming mechanics

`_proxy_openai_stream` serves every face. The upstream body is read raw
(`Proxy::RelayContent`, so an unchunked `text/event-stream` is not swallowed by Mojolicious's
own SSE parser); `data: {…}` lines are parsed — across read boundaries — for content size and
the verbatim `usage` block, then one usage event is written on completion. Without a
translator the bytes are relayed as they came; with one (`Protocol::*::Stream`) each parsed
chunk goes through `->delta` and the client gets the translator's framing and content type.
Rules:

- Never rewrite a chunk on the OpenAI face. The relay is byte-transparent; anything else breaks
  client parsers and makes TTFT unmeasurable.
- `content-length`, `transfer-encoding` and `content-encoding` are stripped from the relayed
  headers (a translated stream also drops `content-type`); `x-skeid-node` is added.
- Chunks go out through a drain queue, not one `write_chunk` per read — a dynamic response
  with no drain callback ends when its queue empties.
- Headers are sent on the first chunk. On a translated face an upstream error status before
  that is a plain HTTP error in the client's shape; after it the failure travels in-band (an
  Anthropic `error` event, an Ollama error line) and the stream is `ok = 0`, as is a body cut
  short of its own framing. Every path calls `request.finish` exactly once.
- Anthropic and Ollama streams are sent upstream with `stream_options.include_usage`; the
  OpenAI face forwards the client's body as is. Missing usage is expected, not an error: the
  event is written with zeroed tokens.

## Engine IDs

`supported_engine_ids` is discovered from the installed `Langertha` distribution, with a
compiled-in fallback list. `normalize_engine_id` lowercases and strips separators, so
`OpenAI-Base` and `openaibase` are the same id. An unknown engine id on a node is not fatal —
it only ever gates eligibility and lands in the usage event.

## Testing protocols

`Test::Mojo` against `Langertha::Skeid::Proxy->build_app(skeid => $skeid)` with a fake upstream
mounted in the same app (a second Mojolicious route the node url points at). Assert on the
translated *shape*, not on a golden JSON blob: a test that pins every field of an upstream
response fails on the next harmless field addition and tells you nothing about the contract.
