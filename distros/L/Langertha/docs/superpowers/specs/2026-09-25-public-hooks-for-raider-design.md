# Public hooks for langertha-raider (karr k190 + k192)

Date: 2026-09-25 · Status: design (revised after review) · Tickets: k190, k192 · Related: ADR 0026, ADR 0027 · Recorded as ADR 0028

## Problem

langertha-raider (sibling dist, `requires 'Langertha'`) reaches into three kinds of
core privates and re-implements usage parsing three times. Core must offer small public
names for exactly what raider needs, without depending on raider (ADR 0026) and without
promising an IO::Async loop (IO::Async is only a `recommends` since k188 / ADR 0027).

## Inventory (langertha-raider @ f39ad50, read-only)

Line numbers drifted from the ticket text (858/1560/1738/1916/2091 → below).

### `_async_http` (Role::AsyncHTTP)

| Site | Call | Needs |
|---|---|---|
| `lib/Langertha/Raider.pm:859` (`compress_history_f`) | `$engine->_async_http->do_request(request => $request)` | send a prepared `HTTP::Request`, get `Future<HTTP::Response>` |
| `lib/Langertha/Raider.pm:1733` (`raid_f` loop) | `$engine->_async_http->do_request(request => $request)` | same; checks `is_success` itself |
| `lib/Langertha/Raider.pm:1555` (`_ensure_inline_mcp`) | `$self->engine->_async_http->loop->add($mcp)` | **an IO::Async loop** to add a `Net::Async::MCP` notifier to |
| `lib/Langertha/Raider.pm:1911` (`raid_f`, self-tool `wait`) | `$engine->_async_http->loop` then `->delay_future(after => N)` | **a timer** |
| `lib/Langertha/Raider.pm:2086` (`respond_f` continuation, `wait`) | same as 1911 | **a timer** |

Raider tests mock the private too: `t/86_raider_self_tools.t:568,759,935`,
`t/87_raider_plugins.t:312` (a mock `_async_http` exposing `loop`).

### `_langfuse_timestamp` (Role::Langfuse)

`lib/Langertha/Raider.pm:1718, 1763, 1821, 1858, 1925, 1951, 1987, 2000, 2129` — nine calls, all
producing `start_time` / `end_time` for `$engine->langfuse_span(...)` /
`langfuse_update_span`. Needs: "now" in the Langfuse ISO-8601 millisecond `Z` format.

### Hand-rolled provider usage parsing

| Site | Shape read | Returns |
|---|---|---|
| `lib/Langertha/Raider.pm:831` `_extract_prompt_tokens` | `usage.{prompt_tokens // input_tokens}`, Gemini `usageMetadata.promptTokenCount` | prompt tokens or `undef` when no usage |
| `lib/Langertha/Raider.pm:1084` `_langfuse_usage` | `usage.{prompt,completion,total}_tokens // input/output`, Gemini `usageMetadata.{prompt,candidates,total}TokenCount` | `{input,output,total}` or `undef` |
| `lib/Langertha/Raider/Plugin/Trace.pm:136` `_extract_usage` | `usage` or `response.usage`, same key pairs | `{prompt,completion,total}` or `undef` |

All three operate on the raw decoded body (`$engine->parse_response($http_response)`),
not on a `Langertha::Response`. Trace only sees `$data` (plugin hook), no engine.

### Other siblings

- **langertha-knarr** (@ 93dbcef): no calls to any engine private (`_async_http`,
  `_async_loop`, `_langfuse_timestamp`); its own `->_` calls are on its own objects.
- **langertha-skeid** (@ 4c8f3ef): no engine-private calls. It parses usage itself
  (`Skeid/Proxy.pm:752`, `Skeid.pm:800`, `Protocol/Ollama/Stream.pm:78`) but on proxied
  wire payloads, with its own cache/cost logic — out of scope here. Its `metrics.normalize` /
  `estimate_cost` go through `Usage->from_response`, so figures for Gemini, Ollama-native and
  `response.usage` bodies change from 0 to real counts (see Changes).

## What core already has

- `Langertha::Usage` (value object) with `from_hash` (OpenAI/Anthropic/Ollama/Responses
  spellings, cache counts) and `from_response` (a `Langertha::Response` or a HashRef with
  a `usage` key; always returns a Usage, zeros when absent).
- It does **not** understand Gemini's camelCase `usageMetadata` (the Gemini engine
  translates it in `chat_response` before `from_hash`), Ollama-native top-level
  `prompt_eval_count`/`eval_count` in a raw body, or a `response.usage` envelope; and it
  cannot say "the body reported no usage" (raider needs that: it must not overwrite
  `_last_prompt_tokens` / send a zero Langfuse usage).

## Design (minimal)

### 1. `$engine->async_request_f($request, %opts)` — Role::AsyncHTTP (k190)

```perl
async sub async_request_f {
  my ($self, $request, %opts) = @_;
  return await $self->_async_http->do_request(request => $request, %opts);
}
```

The public face of the ADR 0027 `do_request` contract: `Future<HTTP::Response>`, 4xx/5xx
**resolve** (caller checks `is_success`), `%opts` passes through (`on_header` for
streaming). HTTP error statuses resolve on all three backends (injected, Net::Async::HTTP,
SyncHTTP). Transport-level failures do not behave the same way (ADR 0027): Net::Async::HTTP
fails the future, while SyncHTTP resolves it with LWP's synthesized 500, so callers always
check `is_success`. It deliberately returns a response, not the backend object, so nothing
beyond `do_request` is exposed. `_async_http` stays the injection seam, unchanged.

### 2. Loop access (k192) — choice **(a): `$engine->async_loop`, a `Maybe[loop]`** (revised)

What raider uses the loop for: (i) `loop->add` of a `Net::Async::MCP` notifier,
(ii) `delay_future` for the `wait` self-tool.

The first draft chose (b), where raider brings its own loop via the `IO::Async::Loop->new`
singleton. Review reproduced a silent hang under (b). When the backend runs on a foreign loop
(an injected client, or `_async_loop => $loop` passed at construction), the raid awaits
futures from two loops, and the outer `->get` drives only one of them. The orchestrator ruled (a).

`async_loop` returns the active backend's loop: the injected client's loop if it
`->can('loop')`, the loop the default Net::Async::HTTP backend was added to, or `undef` for the
sync fallback or a client without a loop. Core still promises no loop. Raider uses
`$engine->async_loop // IO::Async::Loop->new`, which is correct in the foreign-loop case with
no extra configuration. Recorded as ADR 0028.

### 3. `$engine->langfuse_timestamp` — Role::Langfuse (k190)

Public method, same output as today (`YYYY-MM-DDTHH:MM:SS.mmmZ`, UTC). `_langfuse_timestamp`
remains and delegates to it; internal callers unchanged.

### 4. Normalized usage from a raw body — `Langertha::Usage` (k190)

Extend what exists:

- `from_hash` additionally reads Gemini's camelCase spellings: `promptTokenCount`,
  `candidatesTokenCount`, `totalTokenCount` (value-object inbound door, ADR 0018).
  Existing keys win; cache counts for Gemini are not mapped (Gemini's Response path
  exposes them as `cached_content_token_count`, left as is).
- New class method `Langertha::Usage->from_raw($data)`: locates the usage block in a
  raw decoded provider body — `usage` (OpenAI / Anthropic / Responses / Perplexity),
  `usageMetadata` (Gemini), `response.usage` (Responses event envelope), or top-level
  `prompt_eval_count`/`eval_count` (Ollama native) — and returns a `Langertha::Usage`,
  or **`undef` when the body reports no usage**.
- `from_response` HashRef branch delegates to `from_raw`, falling back to the previous
  behaviour (`from_hash($data->{usage} || {})`), so it still always returns a Usage.
  Every body with a `usage` key gives the same result as before. Bodies without one that carry
  `usageMetadata`, Ollama top-level counts or `response.usage` now yield real counts instead of
  zeros, which skeid's cost figures notice (see Changes).

Raider then replaces its three parsers with `Langertha::Usage->from_raw($data)` and reads
`input_tokens` / `output_tokens` / `total_tokens`.

## Out of scope

- No rename/removal of `_async_http`, `_async_loop`, `_langfuse_timestamp` (raider migrates
  later in its own repo).
- No engine-level `response_usage` hook: AKI native (`prompt_length` /
  `num_generated_tokens`) stays engine-scoped in `chat_response`; raider does not see it
  today either. Candidate follow-up if a caller needs it.
- No `to_langfuse_format`; raider maps three accessors.
- No change to knarr/skeid.

## Tests (TDD, contract raider relies on)

- `async_request_f`: resolves with the backend's `HTTP::Response` for an injected client;
  passes `request` + `on_header` through; a 4xx resolves (not fails); works on SyncHTTP.
- `langfuse_timestamp`: format regex, UTC, private alias returns the same shape.
- `Usage->from_raw`: each shape (OpenAI, Anthropic, Gemini, Ollama native, Responses,
  `response.usage`), `undef` for no usage / non-hash; `from_hash` Gemini keys;
  `from_response` unchanged for old inputs and now understands Gemini bodies.
- `async_loop`: `undef` for the sync fallback and a loop-less client. With Net::Async::HTTP
  installed: the default backend's loop, an injected client's foreign loop, the
  `_async_loop` constructor argument, and a timer on it that completes in a chain driven by the
  backend loop, with no hang.
