---
name: skeid-relay-routes
description: Use when working on Skeid routes that are relayed rather than translated — /v1/audio transcriptions and translations, /v1/rerank including rerank_format tei, uploads and multipart forms, the realtime WebSocket session at /v1/realtime with its realtime config section, and the MCP gateway under /mcp/<name> with its mcp config section.
user-invocable: false
allowed-tools: Read, Grep, Glob, Edit, Write, Bash
---

Builds on `skeid-protocols` (one-hub rule, `_forward_headers`, key injection, client auth,
streaming relay) and `skeid-core` (nodes, admission, usage). Terms are defined in `CONTEXT.md`.

## Relayed routes (audio)

A route of the OpenAI face that is not a chat call is **relayed, not translated** (ADR 0021):
`/v1/audio/transcriptions` and `/v1/audio/translations` go to `{node.url}/audio/...` as the
multipart form the client sent; the node's answer (JSON, `verbose_json`, `text`, `srt`, `vtt`,
SSE) comes back untouched. `Langertha::Skeid::Protocol::Audio` owns that wire — form fields,
upstream parts, where an answer reports usage; its names (`transcript.text.delta`,
`usage.type: duration`) appear nowhere else.

- No second proxy function. `_proxy_openai_json_async` / `_proxy_openai_stream` take an optional
  `$relay` hash: `request` (builds the upstream transaction), `units` (usage units off the
  answer), `delta_text` (stream frame text for `content_bytes`). A new relayed route brings a
  `$relay`, never a copy of the relay.
- Skeid reads `model` (exactly once, else `400`; routes and applies the key's policy by it) and
  `stream` (last one decides; on for pydantic's truth set `1 true on yes t y`). It writes `model`
  only when a tier serves another one. Everything else passes as sent — unknown and repeated
  fields, the client's part order and boundary.
- **Two parsers, one form.** The node parses the form again. Whatever a node could read as the
  `model` field must count as one in `form_fields`, or a key routes by one model and is served
  another. Loosen that parser, never tighten it; `name*` is refused.
- The upload is not copied: parts above 256 KiB are file assets, and `upstream_parts` hands the
  same asset to the user agent's `multipart` generator. `$part->asset->slurp` on the file is the
  regression (`t/68` counts it).
- Upload limit = `uploads.max_bytes` (default 26214400, 25 MiB), set per request by `_limit_upload` on the request content's
  `body` event (head parsed, body unread). Declared too large, or refused by `client_auth`: limit
  set to 1, the parser stops, the route (or the gate) answers `413` / `401` without the body. A
  new upload route must be known to `_limit_upload`, or it runs under the server's 16 MiB.
- `Expect` is dropped from an upload's upstream headers: a node's `100 Continue` makes
  Mojo::UserAgent start a fresh response object while the stream relay listens on the old one.
- Usage: tokens through `metrics.normalize` when reported; `audio_seconds` from `usage.seconds`
  (`usage.type` = `duration`), else top-level `duration`, else **absent** — never `0`. Not priced.
- Nothing is injected into the form (`stream_include_usage` is the client's to send).

## Relayed route: rerank

`POST /v1/rerank` and `POST /rerank` are one handler (`_handle_openai_rerank`); the event's
`endpoint` is `/v1/rerank` for both. `Langertha::Skeid::Protocol::Rerank` owns the wire — `query`,
`documents`, `top_n`, `return_documents`, TEI's `texts` / `return_text` / `score`,
`x-compute-tokens`, `meta.tokens` appear nowhere else.

- Before a node is picked, `request_problem` answers `400` for: a body that is no JSON object, a
  `model` that is not a non-empty string, a `query` that is not a string, `documents` that is not
  a non-empty array. No slot, no event. What a document may be is the node's to say.
- **Default: relayed.** The body goes to `{node.url}/rerank` re-encoded with `model` = served
  model and every other field as sent; the answer comes back byte for byte
  (`_render_upstream_response`). vLLM, infinity (`--url-prefix /v1`), Jina, Cohere. Do not
  normalise what they do differently (`document` as `{text}` vs a plain string, vLLM returning
  documents unasked). Re-encoding is deliberate: one `model` reaches the node, the one Skeid
  routed by — never pass the client's bytes through.
- **`rerank_format: tei` on the node: translated on the upstream side** (ADR 0021 Update; the only
  translation not at the client edge). `POST <node url without /v1>/rerank` with
  `{query, texts, return_text?, truncate?}`; the bare array becomes
  `{model: served, results: [{index, relevance_score, document: {text}?}], usage: {total_tokens}?}`,
  sorted by score, cut to `top_n` (absent / `null` / `0` = all). A node option, never an `engine`
  branch. A new upstream dialect is a row in `Protocol::Rerank`'s `%FORMAT`.
- The dialect is known only after admission. A request a TEI node cannot take (a document that is
  not a string or `{text: string}`, a bad `top_n`) throws a `Protocol::Refusal` from
  `request_to_upstream`; the handler answers through `_refuse_unsendable_request`:
  `request.finish`, one failed event (`400`, `invalid_request_error`), no upstream call.
- `$relay` keys rerank added, both called with `($payload, $res)`: `usage` (returns the usage
  block to meter, or nothing — instead of pricing the body's own `usage`) and `answer` (response
  translator for a node with a format; a `die` is the `translation_error` path, `500`). `units`
  gets `$res` as second argument too.
- Usage: `documents` = documents in the request, on the event of a request the node answered 2xx,
  absent otherwise; recorded, not priced. Tokens are **input** tokens (`prompt_tokens` = total,
  `completion_tokens` 0) so `input_per_million` prices them, read from `usage.prompt_tokens`, else
  `usage.total_tokens`, else `meta.tokens.input_tokens` (Cohere); for `tei` from the
  `x-compute-tokens` header only. infinity counts characters unless `lengths_via_tokenize`. No
  `search_units`, no streaming, no `/v2/rerank`.
- `t/69-rerank.t`; 26 mutations of the logic were checked to fail it.

## Relayed route: documents (docling-serve)

`POST /v1/convert/file` (multipart) and `POST /v1/convert/source` (JSON, base64 files) under
docling's own paths (ADR 0028). `Langertha::Skeid::Protocol::Documents` owns the wire — field
names, `json_content.pages`, `callbacks`, `http_sources` appear nowhere else. Handler
`_handle_documents`, reusing `_begin_route_async` (with `kind => 'documents'`),
`_proxy_openai_json_async` with a `$relay`, `_render_upstream_response`; no second relay.

- **No model.** Planned over nodes of `kind: documents`, authorised under the routing key
  `documents` (a policy's `models`; else `403`), event `model` = `documents`, `api_format: docling`.
  Chat nodes never serve it and it never reaches chat nodes (skill `skeid-routing`).
- **Remote sources are a `400` before admission** (no slot, no event) unless
  `documents.allow_remote_sources`: `http_sources`, `callbacks` (liberal names: case, white space,
  `[]`, a file part named so, `name*` refused; in JSON a key named twice is refused whichever wins,
  also by its raw bytes), `target` not `inbody`/`zip`, a `sources` entry that is not an inline
  file. The text names the field, never the value. A new address-taking docling field is an entry
  in `Protocol::Documents`.
- Form: `upstream_parts($content, {})` — nothing to rewrite. Source body: decoded once
  (`$req->json`), written again as `json =>`; CPU on the loop grows with the body, which is why
  big files belong on `/v1/convert/file`.
- Limit `uploads.documents_max_bytes` (default 104857600, 100 MiB) through the `%UPLOAD_ROUTE` table that
  `_limit_upload` reads; both routes get the early `413` / `401`. A new upload route is an entry
  there.
- `$relay` keys used: `request` (form only), `units`, `usage` returning nothing (no tokens), and
  **`max_parse_bytes`** (new): `_proxy_openai_json_async` leaves an answer larger than that
  undecoded, so `units` sees no payload. Documents sets 8 MiB.
- Usage: `documents` = file parts / source entries of the request, on a 2xx answer only; `pages` =
  `document.json_content.pages` (hash keys or array length; `json_content` may be a string), only
  from a successful JSON answer of at most 8 MiB; absent for a zip, `null`, a format without pages
  (empty) — never `0`. Recorded, not priced.
- An upstream 4xx/5xx takes the existing error path (`upstream_error`, the node's message), as on
  every relayed route; a conversion `status: failure` inside a 200 is the node's to judge.
- Not offered: the `/async` calls, status polling, results, the WebSocket (ADR 0028: task affinity
  needs its own ADR, stateless `<node>.<task>` id).
- `t/88-documents-convert.t`.

## Relayed route: realtime (a session)

`GET /v1/realtime` upgraded to a WebSocket, relayed to `{node.url}/realtime` as a **session**
(ADR 0029, k95). It is a relayed route that is not one request and one answer, so it brings no
`$relay` and does not go through `_proxy_openai_*`: `_handle_openai_realtime` (handshake, in
`Proxy.pm`) and `Langertha::Skeid::Proxy::Realtime` (the relay). `Protocol::Realtime` owns the
wire — `intent`, `openai-insecure-api-key.`, `session.update`, `transcription_session.update`,
`…input_audio_transcription.delta` / `.completed` appear nowhere else.

- **Handshake = a request**, upgrade last. Order: client gate (`$openai` bridge, `401`, never a
  socket) → `model` in the query, exactly once (`400`; `intent=transcription` alone is a `400`) →
  `_begin_route_async` (`403`/`503`/`429`, `route_wait` before the upgrade) → node key
  (`_inject_node_auth_async`, fail closed `503`) → **open the node's WebSocket first** →
  `with_protocols('realtime')` + `$c->rendered(101)` → `start_session`. A node that refuses is
  `502`, slot given back, one failed event. A client that leaves while the node is opened: the
  handshake transaction (not the WebSocket one — `$c->tx->handshake`) closes; `_begin_route_async`
  and the handler both listen on it.
- **The node's handshake headers are not `_forward_headers` as is**: `Sec-WebSocket-*` (the
  subprotocol list carries a browser's key), `Origin`, `Cookie` are removed after it. The node
  gets its own key and no subprotocol. Do not forward them back in.
- **The key in a subprotocol** (`openai-insecure-api-key.<key>`) is read by
  `_extract_request_api_key` at the lowest priority and **for this route's path only**, so the
  client gate and the key id see it. It is never answered (`realtime` or none), logged or
  forwarded. `t/90-realtime-handshake.t` greps answer, node headers, log and event for it.
- **Frames.** Every client text frame is JSON-decoded (`Protocol::Realtime->client_frame`),
  never substring-filtered; every string `model` anywhere in it is compared: the handshake's
  → served model written in, any other → `error` event to the client, frame **not forwarded**,
  session goes on. What is forwarded is the decoded document encoded again (so Skeid and the node
  read one thing). Not an object, or a binary frame → close `1003`. Node frames: relayed as the
  bytes they came in, read for `.completed` usage / `.delta` text / `error`. Both dialects
  (beta, GA) relayed unchanged — translate nothing.
- **Ends once**: `_end` runs the finish callback (`request.finish`, one usage event) and then
  closes what is still open. Client close frame = ok whatever the code; no close frame = `499
  client_abort`; node close other than 1000/1001, or error event then close = `502`; `1009` from
  the client = `413`; `1003` = `400`. `1005`/`1006`/`1015` never go on the wire (client went →
  node `1000`; node died → client `1011`).
- **Bounds** (`realtime:`, read when a session opens, hot): `max_message_bytes` (default 1048576,
  1 MiB) is the transaction's own limit per session (`1009`); `max_queued_bytes` (default 4194304,
  4 MiB) counts bytes sent and not yet drained per direction (`1013`); `idle_timeout` (300) and
  `max_session_seconds` (3600) are timers
  (`Mojo::IOLoop->timer`, ADR 0005). The user agent's `inactivity_timeout` (300) would cut an
  idle upstream socket, so the session sets both streams' timeout itself; `request_timeout` does
  not cut an established WebSocket (checked).
- **Slot**: one per session, held until it closes: a realtime node is a node of its own and its
  `max_conns` means concurrent sessions; `max_conns >= workers`, each worker admits its share
  (ADR 0010) and a session stays on the worker that accepted it. No scoreboard.
- **Usage**: one event per session at close. Tokens = the `.completed` `usage` blocks **summed**
  (`add_usage`; not `_merge_usage`, that is for running totals), `audio_seconds` from
  `type: duration` blocks, `content_bytes` from the deltas — each absent when not seen, never
  `0`. Priced through `_stream_metrics`.
- **Graceful stop**: `Mojo::IOLoop->singleton->on(finish)` (what a prefork worker emits on
  `SIGQUIT`) → `shutdown` closes sessions `1001` first. A killed worker loses the events in flight.
- Fixtures in `t/data/realtime/` are synthetic (hand-written after OpenAI's guide); what vLLM and
  speaches really send and accept is **not verified** — see the README there. `t/lib/RealtimeHarness.pm`
  is the shared fake node and raw client. `t/90-realtime-*.t`; 10 mutations were checked red.

## MCP gateway

`/mcp/<name>` relays MCP Streamable HTTP to an **MCP server** assigned to the presented key;
`Langertha::Skeid::Protocol::MCP` owns the wire. Skeid reads nothing of MCP. It is **not** a
relayed route in ADR 0021's sense and does not go through `_begin_route_async` or
`_proxy_openai_*`: no node, so no `request.start` / `request.finish`, no capacity headers, no usage
frame. `_relay_mcp` is its own function.

Config (skeid k103, ADR 0022):

```yaml
mcp: { public_url, servers: { name: { url, description, api_key_ref, api_key_env, headers, keys } } }
```

- `_load_mcp` resolves it after the policies into `mcp_servers` (name → entry with a `keys` id
  set) and `mcp_public_url`, both in `@CONFIG_STATE`. An **MCP server** is not a **Node**: no
  routing, no admission, no health, no probe. `mcp_server_for_key($name, $id)` answers undef for an
  unknown name and for another key's server alike. A server's `keys:` and `client_auth.keys` share
  `_key_id_set` (entry check, error by position, short-id prefix).
- Strict section: unknown keys, keys of the other transport (`stdio` vs `streamable-http`), a URL
  with userinfo and a credential under `headers:` fail the load.

Request path:

- Bridge `_authorize_mcp_client`, in this order: reload; no `mcp:` section → `reply->not_found`
  (the unknown path it was, **before** the client gate); `_authorize_client`; no key → `401` even
  without `client_auth`.
- `404 not_found`, one body, for an unknown name, another key's server, a `stdio` entry and a
  sub-path with a `.`/`..` segment or a backslash (`upstream_url` returns nothing). Never tell these
  apart in an answer.
- Up: method, body bytes (`$c->req->body`), `Content-Type`, `Accept`, `Last-Event-ID`, every
  `Mcp-*` header — an allowlist (`request_headers`), not `_forward_headers`. Then the server's
  static `headers`, then `Authorization: Bearer` from `_upstream_key_async` (the broker / env
  lookup `_inject_node_auth_async` uses too). A named key source without a key: `503`, no call. No
  key source: no `Authorization` at all — the client's is never passed through.
- Down: the response is opened on the first `read` (upstream headers parsed) and flushed with an
  argument-less `$c->write_chunk`, then every chunk is written as read. An answer without a body
  (`202`) never emits `read` and is rendered in the completion callback. Hop-by-hop headers,
  `Content-Length` and `Content-Encoding` are not copied.
- Upstream `401` → `502 upstream_error` + error log (`upstream_unauthorized` on the event); an
  upstream `3xx` likewise (`upstream_redirect`; no redirect is followed, `Location` never relayed).
  Every other status is the server's, `404` for an expired session included.
- Usage event: `api_format: mcp`, `endpoint: /mcp/<name>`, no model/node/tokens. An opened event
  stream is recorded under its status however it ends; a plain answer the client abandons is
  `499 client_abort`.
- `t/72-mcp-gateway.t`; 14 mutations of the logic were checked to fail it.
