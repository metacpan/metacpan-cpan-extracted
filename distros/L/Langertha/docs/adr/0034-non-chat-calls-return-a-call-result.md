# ADR 0034 — Non-chat calls get their metadata through a separate `Langertha::CallResult`, not `Langertha::Response`

- Status: accepted
- Date: 2026-09-26
- Tags: response, usage, rate-limit, timing, embedding, transcription, imagegen, value-objects
- Cross-links: ADR 0003, ADR 0011, ADR 0022, ADR 0028, ADR 0031
- karr: k314 (from k292)

## Context

`simple_embedding`, `simple_transcription` and `simple_image` (and their `_f` variants since
k292) return bare values: a vector, the transcript text, the list of image objects. Everything
else the HTTP response said was dropped: OpenAI embeddings' `usage`, the token `usage` of GPT
image models and of `gpt-transcribe`, the answering `model`, the rate limit headers of that
response, and how long the call took. A caller could not account for, price or back off from a
non-chat call, and the Langfuse generations for embeddings and images (k304) had no usage to
report.

Chat already carries all of this on `Langertha::Response` (`usage`, `rate_limit`, `model`,
`timing` / `total_seconds`, ADRs 0011, 0022). The bare return values are public API and are
used as values (a vector is stored, an image list is iterated), so changing their type was not
an option. `simple_transcription_result` already exists and returns the parsed answer as a
HashRef; its type is public too.

## Decision

1. **A separate value class, `Langertha::CallResult`**, with `value` (exactly what the bare
   method returns), `usage` (`Langertha::Usage`), `rate_limit` (`Langertha::RateLimit`),
   `model`, `total_seconds` and `raw` (the decoded body when it is JSON). All but `value` are
   optional and have `has_*` predicates.

   It is **not** `Langertha::Response`, because that class is chat-shaped: it stringifies to
   `content`, `tool_calls` is its single source of truth for emitted calls (ADR 0003), and it
   has `thinking`, `finish_reason`, `citations`, `created`. A vector or an image list has none
   of those; putting one into `content` or leaving every chat field empty would make the class
   mean two things. It is also not under `Langertha::Result::*` — that namespace is the
   reserved stub of the Raider result (ADR 0026).

2. **New opt-in methods, bare methods unchanged**: `simple_embedding_result(_f)`,
   `simple_image_result(_f)`, and `simple_transcription_call(_f)`. Transcription takes a
   different name because `simple_transcription_result` already exists with a HashRef return.
   Each builds the same request as its bare method, sends it through the same backend
   (`user_agent`, or `_async_do_request_f` for `_f`, ADR 0027), and parses it with the
   request's own `response_call`, so the value and the error text are identical to the bare
   method's.

3. **Where each field comes from**:
   - `usage` through `Usage->from_raw` on the decoded body (ADR 0028's public door), so every
     spelling it normalizes counts (`usage`, `usageMetadata`, Ollama's `prompt_eval_count`).
     A duration-billed transcription (`usage.type = "duration"`) gets **no** `Usage` — zero
     tokens would misstate it; its `seconds` stay in `raw`.
   - `rate_limit` is the engine's `rate_limit` right after parsing, i.e. the one recorded from
     this response (nothing can run between the response and its parse, also on the async
     path).
   - `model` is the body's `model` when present, else the requested model (a `model` in
     `%extra` counts).
   - `total_seconds` is client-measured from sending to receiving, as ADR 0011's
     engine-agnostic `total_seconds`. No engine-native stage keys yet (Ollama's embed
     `total_duration` stays in `raw`).

## Consequences

- Non-chat calls can be priced and rate-limited like chat calls, without a breaking change.
- The body is decoded twice (once by the engine's parser, once for `raw` / `usage`); for large
  batch embeddings this is a measurable but small cost, accepted to keep every engine parser
  untouched.
- `Langertha::Embedder` / `Langertha::ImageGen` do not get `*_result` passthroughs yet: their
  model override and plugin after-hooks (which may replace the value) make it more than a
  passthrough. `Plugin::Langfuse` embedding / image generations (k304) can build on
  `CallResult` later.

## Update (k320 — the wrappers get `*_result`, and the after-hooks see the `CallResult`)

The last consequence above is resolved. `Langertha::Embedder` has
`simple_embedding_result(_f)` and `Langertha::ImageGen` has `simple_image_result(_f)`. They
run the same before-hooks and the same overrides as the bare methods, call the engine's
`*_result(_f)` (so `Role::Embedding::simple_embedding_result(_f)` now takes an optional
`%extra` like `simple_image_result`, which is how the Embedder's `model` override reaches the
request and the result's requested model), then run the after-hooks on the value.

**Hook contract.** `plugin_after_embedding` and `plugin_after_image_gen` get the call's
`CallResult` as an **optional third argument**, only on the `*_result` path; the bare path
still calls them with two. Every hook in the chain sees the same `CallResult` (its `value` is
the engine's value before any hook), while the value itself is piped hook to hook as before.
An argument instead of a plugin attribute, because the metadata belongs to one call: an
attribute on a plugin shared by several hosts or overlapping `_f` calls would race, and a hook
written for two arguments keeps working unchanged.

**Immutability.** When the hooks return a different value, the wrapper returns
`$call_result->with_value($new)`: a new `CallResult` with that value and every other
attribute copied. When they return the engine's own value (same reference), the engine's
`CallResult` is returned as is.

`Plugin::Langfuse` uses the third argument: embedding and image generations called through
`*_result` record the answering `model`, the token `usage` (with cost when `pricing` has a
rule) and `total_seconds` (in the generation's `metadata`; Langfuse has no duration field
besides start/end time). The bare path records what it did before.
