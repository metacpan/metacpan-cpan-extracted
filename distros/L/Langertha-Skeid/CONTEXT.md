# Skeid Routing, Metering & Key Resolution

The vocabulary Skeid is written in. Exists because three strands meet in one process and each
brings a word the others already use for something else: **routing** (which upstream serves
this request), **metering** (what did it cost and who owes it), and **key resolution** (how a
secret reaches a request without ever touching disk). Use these words in code, tests, tickets
and ADRs. A fourth strand, the **MCP gateway**, borrows identity, key resolution and metering
and deliberately none of routing.

## Language

### Topology and routing

**Node**:
One upstream LLM endpoint — url + model + engine id + weight + max_conns + health + tags, as
declared in the YAML config or pushed through the admin API. The unit of routing.
_Avoid_: server, instance, backend, provider.

**Node file** (`node_files`):
A second YAML file of **Nodes** that someone other than the config's author writes — a GPU
manager publishing where its models run (ADR 0031). The main config names it together with its
constraints (allowed URL hosts, `api_key_env` pattern, `api_key_ref`, kinds); a node that breaks
one is **rejected** by position and rule, the rest of the file loads. It contributes nodes only.
_Avoid_: include, overlay, secondary config.

**Trust** (`trust: internal | external`):
Whether a **Node** is the deployment's own infrastructure (internal) or someone else's, a
provider's (external, the default) — ADR 0032. An external node gets an allowlist of client
headers and must have its own key; an internal node gets the client's headers minus address and
cookies and may take the client's credential through. For a **Node file** the main config's
entry sets it.
_Avoid_: trust zone, private/public node, local node.

**Engine ID**:
The Langertha engine that defines a node's *upstream* wire dialect (`openai`, `vllm`,
`sglang`, `anthropic`, `ollama`, …). A property of the node, never of the client.
_Avoid_: provider, vendor, driver, type.

**Model**:
The model name a client asks for and a node advertises. The primary routing key; a node with
no model matches any model.
_Avoid_: engine, deployment.

**Tag**:
A label on a node (`local`, `gb10`, `cloud`, `groq`) that policy and tiers group by. Grouping is
always by tag, never by node id — ids name machines, tags name properties, and policy is written
about properties. A **selector** lists the tags a node must carry, all of them.
_Avoid_: label, group, class, pool.

**Alias**:
A client-facing model name defined as an ordered list of **tiers**. This is how a made-up
product name and "that cloud is the fallback for this model" become one mechanism. A model with
no alias is not special-cased — it resolves to a single implicit tier.
_Avoid_: virtual model, mapping, route.

**Tier**:
One step of an alias: a tag selector, the model to ask those nodes for, and how long to wait
for capacity before falling through to the next. Ordering encodes preference — cheapest or
closest first.
_Avoid_: fallback, priority, level.

**Served model** vs **requested model**:
The name a node is asked for, versus the name the client used. They differ whenever an alias is
involved. Cost is priced on the served model; a customer is billed for the requested one. Usage
events carry both, and neither may be dropped in favour of "the model".
_Avoid_: bare "model" anywhere an alias could be in play.

**Catch-all** (`routing.catch_all`):
The model an unknown model name is routed to, one per kind of route (`chat`, `embeddings`); the
kind comes from the route, never from the name (ADR 0033). A name is unknown when it is neither
an alias nor the model of a chat-kind node. A **bent** request is from there an ordinary request
for the target: the key's policy judges the target, and the usage event carries the target as
**routed model** (`routed_model`) beside the requested and the served model. Off unless
configured; not a name, so no model list shows it.
_Avoid_: default model, wildcard alias, fallback (that is a tier's job).

**Route key**:
The `model|engine` tuple — extended by the selector's tags and the key's denied tags when there
are any — under which one weighted round-robin cursor lives. Two different route keys never
share a cursor.
_Avoid_: session, channel, pool.

**Routing**:
Choosing which node serves a request: weighted round-robin across the eligible nodes.
Load balancing is one routing strategy, not the concept.
_Avoid_: load balancing, dispatch, scheduling.

**Eligibility**:
Static fitness — the node matches the requested model and engine, carries every tag of the
tier's selector and none of the key's **denied tags**, and is flagged healthy. Says nothing
about whether it can take the request *now*.
_Avoid_: availability (that is the dynamic half).

**Admission**:
Dynamic fitness — an eligible node has a free slot. Both the local guardrail (`inflight <
max_conns`; `max_conns <= 0` means unlimited) and the node's **capacity reading**, if there is
a current one, have to allow it. Routing picks among eligible nodes; admission decides whether
the pick stands.
_Avoid_: rate limiting, throttling, quota.

**Inflight**:
Per-node count of started-but-unfinished requests, raised by `request.start` and lowered by
`request.finish`. What *this process* sent — exact for one Skeid in front of one node, and an
undercount the moment anything else shares it.
_Avoid_: load, queue depth, connections.

**Worker share**:
This process's slice of a node's `max_conns` — the configured value divided by the number of
processes sharing the node: the `--workers N` prefork workers of this process, times the
`frontend_count` separate Skeid hosts in front of the node (ADR 0010, ADR 0012). The two
divisors multiply and the split is static; `max_conns` names what the *node* may take, the share
is what one process may send. A capacity probe reads the node's real occupancy and makes the
divisor redundant where it exists.
_Avoid_: quota, limit, per-worker max_conns.

**Shared inflight scoreboard** (proposed, ADR 0014 — not implemented):
A shared-memory table of each prefork worker's **Inflight** per node, so the workers of one
host admit against the node's whole `max_conns` instead of a static **Worker share**. Replaces
only the worker divisor, never the frontend divisor, and never widens what a probe narrows.
_Avoid_: shared counter (the rejected multi-writer design), lock table.

**Capacity probe**:
How a node's real occupancy is found: `inflight` (default), `ratelimit` (read off responses
already in hand), `prometheus` (polled from vLLM/SGLang metrics), `registry` (polled from a
downstream Skeid's **Registry snapshot**), or `custom`. Never runs on the request path.
_Avoid_: health check, monitor, scraper.

**Registry snapshot**:
What a downstream Skeid publishes about its own nodes for a fronting Skeid to read, signed and
short-lived (ADR 0017): per node `inflight`, `max_conns`, health, recent errors and any current
**Capacity reading**. The fronting tier reads it with the `registry` **Capacity probe** and
never adds it to its own **Inflight**. It is operational telemetry and never carries a **Key
reference**, a **Customer key ID** or a **Usage event**. Off unless `registry.enabled`.
_Avoid_: heartbeat, gossip, service discovery, metrics (that word means the usage/ops counters).

**Capacity reading**:
What a probe reported — `used`, `limit`, an optional `retry_after`, when it was taken, and
which probe took it. Expires after `capacity_max_age_ms`, because a stale reading is worse than
none. May only ever *narrow* what `max_conns` allows. When two sources report on one node, the
tighter reading wins while it is current: while it carries a pending **Backoff**, or is younger
than the longer of the two sources' poll intervals (ADR 0017).
_Avoid_: metrics (that word means the usage/ops counters), load average.

**Backoff** (`retry_after`):
A node is not to be sent anything until a moment in the future — what a provider's `429` or
`Retry-After` means. Distinct from **Saturation**: nothing of ours is outstanding, so waiting
for a slot would not help. It never touches **Health**.
_Avoid_: cooldown, circuit breaker, ban.

**Saturation**:
Every eligible node refuses **Admission**. Within a tier the request waits that tier's
`wait_ms` (an alias-less model: `route_wait_timeout_ms`) and then falls through; once every
tier is exhausted and one of them had an eligible node, the client gets `429
rate_limit_error`. Distinct from *no eligible node* in any tier, which is an immediate `503
model_not_found`.
_Avoid_: overload, backpressure, queueing.

**Key rate** (`rate` of a policy):
A request budget per customer key — `per_s` with `burst` and/or `per_min`, token buckets in
memory per process, divided like `max_conns`. Over it a request is refused `429` with
`Retry-After` before **Routing**, and recorded as a **Usage event** with `error_type`
`key_rate_limited`. Not **Admission**: admission is about a node's slots, the key rate about one
caller's pace.
_Avoid_: throttle, quota (a quota is an amount over a period, billed).

**Health**:
An operator-set flag on a node (`set_node_health`, admin API), not a probe result. A **capacity
probe** may poll a node, but only ever for **Admission**; an unreachable node stays "healthy"
until someone says otherwise.
_Avoid_: liveness, readiness, up/down.

### Protocols

**API format** (client protocol):
The dialect the *client* speaks to Skeid: OpenAI (`/v1/chat/completions`, `/v1/embeddings`,
`/v1/models`, and the **Relayed routes** `/v1/audio/transcriptions`, `/v1/audio/translations`
and `/v1/rerank` with its alias `/rerank`; docling's `/v1/convert/file` and `/v1/convert/source`
are relayed too, under their own paths, see **Node kind**),
Anthropic (`/v1/messages`), Ollama (`/api/chat`, `/api/generate`, `/api/embed`, `/api/embeddings`, `/api/tags`, `/api/ps`). A property of the request. Code, config (`manifest.faces`) and ADRs call one API
format's set of routes a **face** — "the Anthropic face".
_Avoid_: engine, provider, frontend API.

**Translation**:
Mapping a non-OpenAI client request into the OpenAI request Skeid forwards upstream, and the
upstream response back into the client's format. One direction pair per API format, and the
only place a format-specific field name may appear.
_Avoid_: adapter, shim, conversion layer.

**Relayed route**:
A route of the OpenAI **API format** that is not a chat call and has one client dialect only —
audio transcription and translation, rerank, and document conversion (docling's own paths). Its request goes to the node's endpoint of the
same name in its own shape (a multipart form, part for part; a rerank body, field for field) and
the answer comes back as the node gave it; there is nothing to translate from or into, so no
**Translation** (ADR 0021). Routing, **Policy**, **Admission** and the **Usage event** are those
of every other route; only the served model is written into the request. The one exception is a
node with a **Rerank format**.
_Avoid_: passthrough (says nothing about routing and metering still applying), proxy route.

**Node kind** (`kind`):
A **Node** option saying what the node serves: `chat` (the default, every node there was: chat
completions and embeddings, matched by `model`) or `documents` (a docling-serve node). The
documents routes plan over nodes of kind `documents` and only them; chat routes, `/v1/models` and
the manifest see chat nodes only. A documents request has no `model`: it is authorised and
reported under the fixed **Routing key** `documents`, which a **Policy**'s `models` grants (ADR
0028).
_Avoid_: type, role, capability, service.

**Routing key**:
The name a request is planned, authorised and reported under, where a chat request has its
`model`. For the documents routes it is the constant `documents`: a **Policy** lists it in
`models`, an alias of that name tiers the documents nodes, the **Usage event** carries it as
`model`. It is not a model name and no node carries it.
_Avoid_: model name (a documents node serves no model), route name, service name.

**Node key header** (`api_key_header`):
A **Node** option naming the header the node's key is sent in, raw, instead of `Authorization:
Bearer` — `X-Api-Key` for docling-serve. The key source and the dropping of the client's own
credentials are unchanged.
_Avoid_: auth scheme, key name (that is `api_key_ref`).

**Realtime route** (`GET /v1/realtime`):
The **Relayed route** that is a WebSocket: live transcription over OpenAI's realtime protocol,
upgraded from a handshake that is routed, admitted and authenticated like a request and then
relayed frame for frame to the node's `/realtime` in the node's own events (ADR 0029). The node
is opened first, so a node that refuses is an HTTP `502` and not a socket that closed. Skeid
reads the `model` of the query (required) and of every client frame, to hold the **Session** to
the model the key's **Policy** granted; it translates nothing, in either dialect.
_Avoid_: realtime API (too wide: conversation, audio out and tools are not served), streaming
transcription (that is the SSE of the audio routes), socket route.

**Session**:
One open realtime WebSocket from handshake to close. It holds one slot of its **Node** for its
whole life — `request.start` at the handshake, `request.finish` exactly once when it ends, from
either side or a limit — so `max_conns` of a realtime node counts concurrent sessions, and it is
metered as one **Usage event** written at close: its length and the summed usage of its
transcriptions. The one thing in Skeid that is not one request and one answer.
_Avoid_: connection (that is the TCP stream; a session is more than one frame exchange and has
a model, a slot and a bill), stream, call.

**Rerank format** (`rerank_format`):
A **Node** option naming the dialect its rerank endpoint speaks when that is not the one clients
speak. Absent for a node that is relayed (vLLM, infinity, Jina, Cohere); `tei` for Hugging Face
text-embeddings-inference, whose request and answer Skeid translates on the *upstream* side —
the only translation that does not sit at the client edge, and not a **Translation** in the
sense above: the client's **API format** does not change.
_Avoid_: engine (the **Engine ID** never changes the call), rerank engine, backend type.

**Upstream**:
The node side of a request. The client side is the *client* or *caller* — never "backend".
_Avoid_: backend, origin, remote.

**SSE relay**:
On the OpenAI **API format** streaming responses pass through byte-for-byte; Skeid parses the
chunks only to accumulate usage and content size. The Anthropic and Ollama formats stream too:
there the upstream OpenAI SSE is re-chunked by a stream translator (Anthropic events, Ollama
NDJSON) — the relay-plus-**Translation** case. Every stream is metered and priced from the
verbatim upstream usage frame, like a non-streamed request (skeid #41). A **Relayed route**
streams the same way, byte-for-byte, whichever event dialect its node speaks.
_Avoid_: proxying, piping (too vague about the parse-but-don't-modify contract).

**TTFT**:
Time to first token — request received to first content byte written to the client. The
latency number that matters for a proxy; distinct from **duration**, the whole-request time
that lands in the usage event.
_Avoid_: latency (unqualified), response time.

### MCP gateway

**Route table**:
The list in `Langertha::Skeid::Proxy->route_table` that both registers every route of the app
and feeds the **API description**: one entry per route, with the bridge it sits behind and what
the document says about it (ADR 0025). A route without an entry is a defect the test suite
catches.
_Avoid_: router config, route list, endpoint registry.

**API description**:
The OpenAPI 3.1 document `GET /openapi.json`: the client routes this configuration enables, the
`client_auth` bearer scheme, model names in examples taken from `/v1/models`. The admin routes are
a second document, `GET /skeid/openapi.json`, behind the admin key.
_Avoid_: swagger file, API docs (the **Swagger UI** is its viewer, not the description).

**Swagger UI**:
The optional browser viewer of the **API description** at `/docs`, off unless
`openapi.swagger_ui`. Not shipped: fetched once from the pinned swagger-ui-dist release on the
first request, verified by digest and cached in `openapi.cache_dir` (ADR 0025).
_Avoid_: docs page, vendored UI.

**MCP server**:
An upstream that speaks MCP, declared under a name in the config's `mcp.servers` (ADR 0022).
Not a **Node**: it serves no **Model**, is never routed to, admitted, probed or priced, and has
no **Health**. A customer reaches it by its name, `/mcp/<name>`, and only when it is assigned.
_Avoid_: node, backend, tool server, plugin, connector.

**MCP assignment** (`keys:` of a server):
The **Customer key IDs** an **MCP server** is for, written on the server's entry as key ids or
**Customer names** and resolved at config load. A third decision beside **Client
authentication** (whether a key comes in) and **Policy** (which models and nodes it reaches):
which MCP servers it has. A server that is not assigned to a key does not exist for that key —
the answer is the `404` of an unknown name, never a **Refusal**.
_Avoid_: grant (the manifest's word), permission, policy, subscription, access list.

**MCP relay**:
Passing a request to an assigned **MCP server** and its answer back without reading either:
method, body bytes and a fixed set of headers up, status, headers and body or event stream
down. One step past a **Relayed route**, which still reads `model` to route by — here there is
no field Skeid reads and nothing it routes. No tool lists are merged; one name is one server.
_Avoid_: translation, aggregation, MCP proxy (says nothing about the assignment), bridge.

**Local MCP server** (`transport: stdio`):
An entry describing an MCP server that runs on the customer's own machine. Skeid neither
starts nor reaches it; the entry is a hint in the listing (`command`, `args`, `env`) and has no
`/mcp/<name>` route.
_Avoid_: stdio node, managed server, hosted server.

**MCP listing** (`GET /v1/mcp/servers`):
What one customer key is told about its **MCP assignments**: per server the name, transport,
description and either the public URL or the local command. Never an upstream URL, a **Key
reference** or a static header.
_Avoid_: catalog, registry (that word means the snapshot), discovery document.

### Metering

**Usage event**:
One record per forwarded request — or per **Session**, written when it closes (ADR 0029): identity, node, model, status, duration, tokens, cost, and
where a route counts something else, its own usage unit (**Audio seconds**, **Documents**,
**Pages**). The
billing unit
and the reason Skeid exists between a client and a node.
_Avoid_: log line, metric, sample.

**Finish reason** (`finish_reason`):
How an answer ended, on its **Usage event**: `stop`, `length`, `content_filter`, `tool_calls`,
`error` (any failed request) or `other`; absent where the answer has none (embeddings, audio).
Beside it `ttft_ms` (time to the first token, streams only) and `correlation_id` (the caller's
own id from a configured header) — the usage contract a platform reads (skeid k121).
_Avoid_: stop reason (Anthropic's wire name), status.

**Audio seconds** (`audio_seconds`):
The seconds of audio a node says it worked on, on the **Usage event** of an audio **Relayed
route**. The first **usage unit** that is not a token count: an optional event field recorded
as the node reports it, absent when the node reports none — not measured, which is never `0`.
Recorded, not priced (ADR 0021).
_Avoid_: duration (that is the request's wall time, `duration_ms`), audio length, minutes.

**Documents** (`documents`):
How many documents a rerank or documents request carried, on the **Usage event** of a request
the node answered (for a conversion: the files or sources of the request). Unlike **Audio seconds** Skeid counts it itself, off the request, so it does not depend
on what the node reports; a failed request has no such field. Recorded, not priced. A reranker's
tokens are not a unit of their own: they are input tokens, wherever the node reports them.
_Avoid_: texts (TEI's word for them), passages, search units (Cohere's billing unit, not
recorded), results (what comes back, cut to `top_n`).

**Pages** (`pages`):
The page count of a converted document, on the **Usage event** of a documents request: the unit
a conversion is billed by. Read off `document.json_content.pages` of a JSON answer of at most
8 MiB; absent for a zip, a larger answer, an answer without `json_content` and a format without
pages — not measured, which is never `0`. Recorded, not priced (ADR 0028).
_Avoid_: sheets, documents (the request's inputs, a different count), page_count.

**Usage store**:
The pluggable sink for usage events — `jsonlog` (recommended), `sqlite`, `postgresql`, or a
caller-supplied callback. Swapping it must never change what an event *means*.
_Avoid_: database, logger, backend (that word is taken by the store's own `backend` key,
which names the driver, not the concept).

**Node metrics**:
In-memory per-node counters (started / ok / error / duration total) for operational visibility.
Volatile, never billed, lost on restart. Not a usage event.
_Avoid_: usage, stats, telemetry.

**Metrics normalization**:
Turning whatever token counts an upstream reports into input / output / total, plus the
**cached tokens**. Cost is priced from `model_pricing` at record time and stored on the event,
so a later price change never rewrites history. A stream is normalized from its verbatim
upstream usage block, the same call as a non-streamed answer.
_Avoid_: parsing, mapping.

**Cached tokens** (`cached_tokens`, `cache_write_tokens`):
The input tokens a provider served from, or wrote into, its prompt cache, as it reports them.
Recorded on the usage event beside the token counts and priced at the model's
`cached_input_per_million` / `cache_write_per_million` into `cost_cache_read_usd` /
`cost_cache_write_usd`, both part of `cost_total_usd` (ADR 0013).
_Avoid_: cache hits, discounted tokens.

### Keys and identity

**Key broker**:
The contract that resolves a key reference into a secret, in memory, at the moment it is
needed. `KeyBroker::OpenBao` is the implementation; the interface is what code depends on.
_Avoid_: vault client, secret manager, key store.

**Key reference** (`api_key_ref`):
An opaque path that *names* a secret (`secret/skeid/remote/openai`), on a **Node** or an **MCP
server**. Config, ticket text and log lines may carry a key reference; they may never carry
what it resolves to.
_Avoid_: key path, secret name, key id (that word means the caller).

**Customer key ID** (`api_key_id`):
The caller's identity, derived from the API key they presented: `k_` plus the key's full SHA-1
hex (ADR 0016; `skeid keyid` prints it), or `anonymous`. It selects whose usage this is *and*
which routing policy applies; it is not itself a credential. A pre-ADR 0016 short id
(`k_` + 12 hex) in the config still matches by prefix. A client-supplied `x-skeid-key-id` names
it only where `trust_key_id_header` says something in front of Skeid already authenticated the
caller.
_Avoid_: API key, user, tenant, account.

**Customer name** (`names:`):
A readable label the config maps to a **Customer key ID**, so `keys:` entries can be written as
`alice` instead of a digest (ADR 0011). Resolved to the id at config load and erased; it is
never an identity on the request path.
_Avoid_: username, account name, key alias.

**Client authentication** (`client_auth:`):
The optional allowlist of **Customer key IDs** that may use the client routes (ADR 0020). With
it, a missing key or a key whose id is not listed is answered `401` before anything is routed or
metered; without it Skeid identifies callers but lets every key in. It decides *whether* a key
comes in, never *what* it reaches — that stays the **Policy**.
_Avoid_: login, access control, key check, refusal (that word means the policy's 403).

**Customer source** (`customer_source:`):
A database relation another application owns — typically a view — that lists active
**Customer key IDs**, one row each, with an optional label, **Policy** profile name and model
list (ADR 0026). Skeid fetches it in a child process, never on the request path, and merges it
into the file's config at reload: its ids join **Client authentication**, its profiles must
exist in the file, and the file wins for any id it names. A row present means the key is active;
revoking is removing the row.
_Avoid_: customer database, key store, key sync.

**Source snapshot**:
The rows of the last successful fetch of the **Customer source**, held in memory per process.
Every **Config reload** merges it; a snapshot whose digest changed triggers one, an unchanged
one does nothing. It stays in force while fetches fail (or until `max_stale_s`), and is dropped
when the section leaves the file. Before the first successful fetch there is none, and no
source key is let in (fail-closed).
_Avoid_: cache, customer list.

**Provider manifest**:
The `/.well-known/langertha.json` document telling one customer key which endpoints, faces and
models it may use (ADR 0015). Opt-in per key (`keys: <id>: {manifest: {models: [...]}}`),
bounded by that key's **Policy**, resolved at config load; unauthenticated callers get 401,
never a public catalog.
_Avoid_: catalog, discovery document, model list.

**Policy**:
What a customer key may reach: an optional list of models it may ask for, and the node tags it
may not be served from. Named profiles are the standard setups; a key takes one, optionally
overriding single fields, or takes the default.
_Avoid_: plan, tier (that word means a step in an alias), quota, permission set.

**Denied tag** (`deny_tags`):
A tag a key's policy forbids. Filters node *selection*, not merely the plan — so a denial
holds however the request is spelled.
_Avoid_: blocklist, excluded tag.

**Refusal**:
The answer when a policy does not grant what was asked: `403`, `permission_error`. Distinct
from saturation (`429`) and from nothing being able to serve the model (`503`) — the three
tell a client three different things to do.
_Avoid_: rejection, denial (as a status).

**Admin API key**:
The single shared secret gating `/skeid/*` control-plane routes. Never a customer identity,
never an upstream credential.
_Avoid_: master key, root token.

**Registry read key**:
A bearer secret that opens exactly one route, a downstream Skeid's **Registry snapshot**
(`registry.read_key_env`, skeid #49), so a fronting tier can poll without holding the **Admin
API key**. Authorizes reading, not believing: the snapshot's signature decides that.
_Avoid_: read-only admin key, registry token.

**AppRole token lifecycle**:
Container boots with `role_id`/`secret_id` → logs in → holds the token in memory → renews on a
timer. Renewal failure kills the process so the container restarts with a fresh login. The
absence of an on-disk token is the feature.
_Avoid_: session, login cache.

### Control surface

**Function dispatch** (`call_function`):
Skeid's internal command surface — `route.state`, `route.next`, `request.start`,
`request.finish`, `usage.record`, … Every dispatch also triggers a config staleness check.
_Avoid_: API, RPC, tool call (that means an LLM tool call here).

**Config reload**:
The YAML config (or a `config_loader`) is re-read on function dispatch when its mtime changed
or the loader is due; an unchanged result is a no-op. A reload is all or nothing: a failing one
keeps the previous config in force and is retried with a back-off. A successful one leaves the
running config equal to the file — a section removed from it is cleared — except that a
removed usage store stays in force until restart (ADR 0004). With a **Customer source** the
config is the file plus the **Source snapshot**, and a new snapshot triggers a reload from the
fetcher's callback. Node inventory is live
state; the file is one of its sources, the admin API is the other — and a changed `nodes:`
section replaces whatever the admin API pushed.
_Avoid_: hot reload, restart, refresh.

## Relationships

- A **Node** carries exactly one **Engine ID** and at most one **Model**; **Routing** groups
  nodes by **Route key**, never by node id.
- **Eligibility** is computed from config state; **Admission** from **Inflight** and any current
  **Capacity reading**. A request is routed only when both hold — that is why `route.next` and
  `request.start` are two calls and the second may fail after the first succeeded.
- **Saturation** is a property of the eligible set, not of a node: one busy node is not
  saturation if a sibling can take the request.
- A **Capacity probe** narrows **Admission** and never **Health**. A rate-limited or full node
  is busy, not broken — and an error-driven health flag would have nothing to flip it back.
- A **Usage event** is written once per forwarded request, after `request.finish`, whatever the
  outcome — errors are billable events too, with `ok = 0`.
- `request.finish` has four outcomes: ok, error, **aborted** (the client left) and **rejected**
  (400, 404, 413, 422: the client's to fix; 401/403/429 stay errors). Aborted and rejected are
  counted apart and never reach `errors_in_window` or `last_failure_at` (ADR 0024).
- **Node metrics** and **Usage events** count the same requests and are never reconciled: one
  is volatile operations data, the other is durable billing data. Don't derive one from the
  other.
- The **Key broker** is consulted per request for the chosen node's `api_key_ref`, answering
  from its in-memory cache when it can. A **Customer key ID** is never looked up: it is a digest
  of the presented key. Nothing is cached to disk, and only the **Key reference** — never the
  resolved value — appears in config, logs, or usage events.
- A **Policy** attaches to a **Customer key ID**, and that id is derived from what the caller
  presented. Anything a client can set freely must never name it: the policy would be advice,
  not a boundary.
- **Client authentication** comes before everything else on a client route: a key it turns away
  is `401` and never reaches **Policy**, **Routing**, `request.start` or a **Usage event**. A
  key it lets in is still bound by its **Policy** — being on the list grants no model and no
  node.
- A **Policy** narrows **Eligibility**, never **Admission**. A denied node is not a busy node,
  so a policy failure is a **Refusal**, and running out of permitted capacity stays a 429 —
  falling through to a denied node "because everything else is full" is the failure this
  distinction exists to prevent.
- An **MCP server** takes from the request path exactly three things: the **Customer key ID**
  (through **Client authentication** and its own **MCP assignment**), the **Key broker** for
  its own upstream key, and one **Usage event** per relayed request (`api_format: mcp`, no
  model, no node). It takes nothing of **Routing**: no **Eligibility**, no **Admission**, no
  **Inflight**.
- The client's key is never an **MCP server**'s credential. A node that names no key source
  forwards the client's `Authorization`; an MCP server that names none is called without one.
- An **MCP assignment** is checked after **Client authentication** and is independent of
  **Policy**: a key's models say nothing about its MCP servers, and the other way round.
- **API format** governs the client edge, **Engine ID** the upstream edge. A request can enter
  as Anthropic and leave as OpenAI; that crossing is **Translation** and it happens in exactly
  one place. A **Relayed route** makes no crossing: it enters and leaves in the same shape —
  unless its node has a **Rerank format**, which is a crossing on the upstream side.

## Example dialogue

> **Dev:** "All three nodes for `gpt-4o-mini` are busy. Do I mark them unhealthy so routing
> skips them?"
> **Owner:** "No — busy is **Admission**, unhealthy is **Health**. Health is an operator
> statement about a node; **Inflight** is what capacity looks like right now. Flipping health
> on load would make a transient full queue look like an outage, and nothing would flip it
> back."
> **Dev:** "So the client just gets a 503?"
> **Owner:** "It gets nothing yet — that is **Saturation**, so it waits up to
> `route_wait_timeout_ms` and then gets a 429. A 503 means no **eligible** node exists at all,
> which is a config or model-name problem, not a load problem. Two different failures, two
> different fixes, so they must never share a status code."

## Flagged ambiguities

- **"engine"** was used for three things: the Langertha engine class, a node's upstream
  dialect, and the client's request format. Resolved: **Engine ID** is the upstream dialect
  only; the client edge is **API format**. Config keys keep the name `engine` for the node
  field — that one is correct.
- **"key"** covers five unrelated things: **Customer key ID** (identity), the upstream
  provider secret behind a **Key reference**, the **Admin API key** (gate), the **Registry
  read key** (one-route gate), and the **Route key** (cursor bucket). Never write bare "key" in new code; take the qualified name.
- **"health"** currently only ever changes by hand. ADR 0009 settles the narrow case: a
  provider's `429` adjusts a capacity probe and a backoff timer, never the health flag — a
  rate-limited node is busy, not broken. Whether repeated *errors* should demote a node is
  still open, and still needs its own ADR before an error handler writes to that flag.
- **"model"** becomes two things once aliases exist (ADR 0008): the name a client asks for and
  the name a node serves. Where both can appear — usage events, reports, log lines — they are
  **requested model** and **served model**. Bare "model" is only safe where no alias layer is
  involved.
- **"relay"** now covers four things: the **SSE relay** of a chat stream (bytes passed on,
  read along for usage), a **Relayed route** (a non-chat route of the OpenAI face: routed by
  `model`, not translated), the **Realtime route**'s frames (a **Relayed route** that is a
  **Session**: both ways, the client's decoded to hold it to its model) and the **MCP relay**
  (nothing read, nothing routed). The first three serve a **Node**; the last never does. MCP is not a **face** either: its events carry
  `api_format: mcp` because that is what the client spoke, but there is no **Translation** and
  no manifest endpoint for it.
- **"registry"** names two things: the Skeid-to-Skeid **Registry snapshot** (`registry:` config,
  `Langertha::Skeid::Registry`, ADR 0017), and — in ADR 0011 and `key_id_for_name` — the
  `names:` section. The bare word means the snapshot; the other is the **Customer name** map.
- **"backend"** appears both as the usage-store driver name (`backend: postgresql`, correct)
  and colloquially for an upstream node (wrong). Upstream side is **Node**.
