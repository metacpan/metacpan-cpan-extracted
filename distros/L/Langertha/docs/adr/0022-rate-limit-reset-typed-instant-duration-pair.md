# ADR 0022 — RateLimit reset is a typed instant/duration pair reconciled lazily against a `received` anchor

- Status: accepted
- Date: 2026-09-14
- Tags: response, value-objects, rate-limit, observability, time

## Context

`Langertha::RateLimit` normalizes the rate-limit headers every engine family
returns. Its reset fields — `requests_reset` and `tokens_reset` — were
`Maybe[Str]`, and their own POD admitted the shape "varies by provider
(seconds, RFC 3339 timestamp, or epoch)." One attribute held whatever the
provider's header said, and a consumer could not tell which kind it had
received without already knowing which provider answered.

This is the same untyped-wire-value problem `Response.created` had before
ADR 0017 — but with a twist that ADR 0017's Future work called out explicitly
(karr **#121**):

> Same untyped-wire-value shape as the old `created`, but the shapes are not all
> the same *kind*: a bare `60` is a duration, and `from_wire` would turn it into
> an instant in 1970. Any fix has to decide "when" vs "in how long" first —
> `Langertha::Moment` is not a drop-in there.

So `Langertha::Moment` (ADR 0017) is a necessary part of the fix but not the
whole of it. A single value object cannot absorb this seam the way it absorbed
`created`, because the wire does not spell one canonical quantity two ways — it
spells **two different kinds of quantity**, and the provider chooses which:

| Provider(s) | reset header | kind | verbatim example |
|---|---|---|---|
| OpenAI family (`Role::OpenAICompatible`) | `x-ratelimit-reset-{requests,tokens}` | **duration** — a Go `time.Duration` string | `1s`, `6m0s`, `2m59.56s`, `250ms` |
| Anthropic (`Role::AnthropicCompatible`) | `anthropic-ratelimit-{requests,tokens}-reset` | **instant** — RFC 3339 | (docs give none; "RFC 3339 format") |
| Mistral, xAI, DeepSeek, Gemini, Hetzner, every self-hosted server | — | **nothing** | absent |

Two more facts the advisor pass (langertha-llm-advisor, docs read 2026-09-01,
no live calls) established, both of which shape the decision:

1. The OpenAI-family duration is **not** bare seconds. It is a Go
   `time.Duration.String()` value, which is compound (`6m0s`), sub-second
   (`250ms`, `35ms`), and fractional (`7.66s`). A naive `^\d+s$` reader breaks
   on Groq's own documented example and on every Scaleway response.
2. `raw` did not hold what its POD claimed. Both readers enumerated a fixed
   list of header names and discarded everything else *before* building `raw`,
   so headers that exist today were lost entirely: OpenAI's
   `x-ratelimit-*-project-tokens`, Anthropic's `anthropic-priority-*` /
   `anthropic-fast-*`, Cerebras's window-in-the-name
   `x-ratelimit-reset-requests-day`, and every Mistral header (whose names
   carry a `-minute` suffix and match neither list).

Nothing croaked today — `Maybe[Str]` accepts every shape — so this is a
seam-consistency change, not a latent bug like GH #3 was for `created`. The
cost was paid by consumers, not by the framework.

## Decision

### 1. Each reset bucket splits into a typed instant and a typed duration, both `Maybe`

```perl
requests_reset_at     Maybe[Langertha::Moment]   # WHEN         (ADR 0017 value object)
requests_reset_after  Maybe[Num]                 # IN HOW LONG, seconds (may be fractional)
tokens_reset_at       Maybe[Langertha::Moment]
tokens_reset_after    Maybe[Num]
```

The parser populates **only the half the wire actually spoke**:
`Role::OpenAICompatible::_parse_rate_limit_headers` runs the Go-duration string
through `RateLimit::_parse_go_duration` and sets `*_reset_after`;
`Role::AnthropicCompatible::_parse_rate_limit_headers` runs the RFC 3339 string
through `Langertha::Moment->from_wire` (ADR 0017's one lenient inbound door) and
sets `*_reset_at`. Deciding "when" vs "in how long" *before* choosing a type is
the whole point ADR 0017 deferred here: an instant and a duration are different
kinds, and forcing both through `from_wire` would turn a bare `60` into an
instant in 1970 — wrong, not merely lossy.

### 2. A `received` anchor, and lazy bidirectional derivation of the missing half

```perl
received  Langertha::Moment   # stamped by the header reader at parse time; default now_utc
```

The half the wire did not send is derived from the one it did, against
`received`, and **only on demand**:

- `*_reset_at` (lazy builder) = `received->plus_seconds/plus_nanoseconds(*_reset_after)`
  when only the duration was sent (`_reset_at_from`).
- `*_reset_after` (lazy builder) = `received->delta_nanoseconds(*_reset_at) / 1e9`
  when only the instant was sent (`_reset_after_from`).

`received` is worth having on its own: it is the only thing that makes an
Anthropic RFC 3339 reset actionable without asking the caller to trust its own
clock against Anthropic's.

Two guards make the lazy derivation correct and non-recursive, and both are
load-bearing:

- **The sibling predicate is the recursion guard.** Each builder opens with
  `return undef unless $self->has_requests_reset_after` (or the mirror). A
  bucket the wire never spoke has *neither* half set, so neither builder ever
  triggers the other — there is no mutual recursion, and the empty bucket stays
  `undef` on both sides.
- **`undef` when neither was sent, and no default is invented.** Absence is the
  **expected** path here, not an error: most providers send no reset header at
  all. A rate limit is not something the framework may guess; an invented
  `reset_after => 60` would be a fabricated fact about the provider's window.

This is the same normalized-plus-native split as ADR 0011 (`timing`) and
ADR 0017 (`created` + `raw`), applied to a third response-side observability
surface — but with a shape neither predecessor has: the wire speaks **one of
two kinds**, the framework exposes **both typed halves**, and the anchor makes
the two mutually derivable.

### 3. A Go `time.Duration` parser that never guesses

`RateLimit::_parse_go_duration` sums a `time.Duration.String()` value into
fractional seconds, handling compound (`6m0s`, `1h2m3s`), sub-second (`250ms`)
and fractional (`7.66s`) forms, and the `µs` micro-unit written as either
`\x{b5}s` or `\x{3bc}s` (normalized to `us`). It does a **whole-string** shape
check first (`\A-?(?:<number><unit>)+\z`) and returns `undef` for anything that
is not exactly that shape — a bare number, an RFC 3339 stamp, an epoch. It never
guesses at a shape that is not a Go duration.

### 4. `raw` becomes a prefix-matched superset, collected once

`RateLimit::_collect_headers` is the single source of truth for `raw`. It keeps
every response header matching
`/^(x-ratelimit-|anthropic-ratelimit-|anthropic-priority-|anthropic-fast-|ratelimitbysize-)/i`
plus `retry-after`, keyed by lower-cased name — a strict superset of the fields
the normalized attributes cover. Both dialect readers call it, then normalize
the known subset out of the result. This is the precondition for everything
above: "keep the raw header value" only means something once the header
actually reaches `raw`, and it is what lets a consumer recover the shapes the
normalizer deliberately does *not* model (see the keeps below).

### Deliberate keeps

- **The verbatim `requests_reset` / `tokens_reset` strings stay, `Maybe[Str]`,
  as back-compat.** They return the header exactly as sent and are re-POD'd as
  the raw pointer to the typed pair. Nothing that reads them breaks; the
  ticket's stated cost ("consumers cannot tell which shape they got") is paid
  off by the new attributes, not by mutating the old ones. Removing them is a
  separate, later decision.
- **We decline the ambiguous bare-number magnitude heuristic.** The advisor's
  API sketch included a third parser branch that guessed a bare number by size
  (`>= 1e12` → epoch-ms, `>= 1e9` → epoch-s, else seconds) for Cerebras's
  undocumented fractional seconds and OpenRouter's unofficial epoch-ms. That
  branch was **not** implemented: both its target wires are unconfirmed against
  first-party docs, and guessing an instant-vs-duration by magnitude is exactly
  the "wrong, not merely lossy" failure mode this ADR exists to avoid. The
  string still lands in `raw` for a caller who knows their provider; the
  framework does not invent a kind it cannot read.
- **`received` is a derivation anchor, not a rate-limit field.** `to_hash`
  excludes it (it is reachable via its accessor); it does not belong in every
  serialized view of a rate-limited response.
- **`TO_JSON` still excludes `raw`.** The wider `raw` superset must not leak
  into traces — that privacy exclusion is a decision `RateLimit`'s POD already
  records, and widening `raw` is precisely why re-stating it matters. `to_hash`
  numifies the `*_reset_at` moments to a plain epoch (their `0+` overload),
  exactly as `Response.created` is emitted (ADR 0017 decision 4).

## Rationale

The shape follows from one observation: **the wire chooses the kind, so the
framework must carry both kinds and reconcile them.** A single field cannot be
typed without erasing the distinction the provider drew; two untyped fields
push the distinction onto the consumer, which is the status quo this change
removes. Two typed halves plus an anchor is the smallest model that lets a
caller ask either question ("when does it reset", "how long until it resets")
and get a typed answer regardless of which half the provider spoke.

Deriving lazily rather than eagerly keeps the constructor honest: a bucket the
wire never described has no derived value put into it, so `has_*_reset_at` /
`has_*_reset_after` mean "the framework can answer this", not "the framework
guessed this". The sibling-predicate recursion guard is what makes that safe
without a separate "which half is authoritative" flag — the presence of the
*other* half is the flag.

Declining the magnitude heuristic is the same instinct as ADR 0017's
`from_wire` reject list (bare `2026` stays rejected) and ADR 0011's refusal to
paper over the sync/async TTFT gap: where the wire is undocumented or
ambiguous, the framework says `undef` and keeps the bytes in `raw` rather than
manufacturing a normalized value it cannot stand behind.

## Consequences

- **Callers get a typed reset on both dialects, and a derived counterpart for
  free.** An Anthropic RFC 3339 reset now also answers `*_reset_after`; an
  OpenAI-family Go-duration reset now also answers `*_reset_at` — each computed
  against `received`, each `undef` when the provider sent nothing.
- **`raw` is now a true superset and loses nothing.** Provider extras that carry
  a window in the name (Groq's per-day request bucket, Cerebras's
  `-requests-day`) or a shape the normalizer does not model (Anthropic
  `anthropic-priority-*` / `anthropic-fast-*`, Mistral's `-minute` names)
  survive there. This is a strict superset of the old behavior.
- **Non-breaking.** A caller reading only `requests_remaining` / `tokens_remaining`
  sees no change; `requests_reset` / `tokens_reset` still return the verbatim
  string. `t/12_rate_limit.t` grew from 52 to 102 subtests covering the split,
  both derivations, the raw superset, the no-reset (no-invented-default) path,
  and the Go-duration parser edge cases.
- **Two `_seconds`-shaped values now exist on the response side that are *not*
  in `timing`.** `*_reset_after` is seconds, like ADR 0011's `_seconds` keys,
  but it lives on `RateLimit`, not in the `timing` HashRef, and it is a
  "time until" rather than an elapsed measurement — the suffix rule of ADR 0011
  (Update / karr k126) governs the `timing` namespace only and does not reach
  here.
- **Real captured rate-limit headers are still owed.** The coverage is mocked;
  live header fixtures across the engine families remain a separate, blocked
  follow-up (karr k137).
- **Cross-links.** **ADR 0017** — `Langertha::Moment` and its `from_wire`
  inbound door, reused here for the instant half; this ADR is the "when vs in
  how long" decision ADR 0017's Future work deferred. **ADR 0011** — the
  response-side timing seam this parallels (normalized value on the object,
  native form under `raw`), and whose route/observability policy this extends to
  a third surface. **ADR 0001** — the value object owns inbound parsing; the
  Go-duration and RFC 3339 parses live on `RateLimit` / `Moment`, not in the
  engines. **ADR 0004** — `raw` as the unmodeled dump a consumer may reach into
  when the framework deliberately does not model a shape (the declined
  bare-number heuristic). `CONTEXT.md`'s "Response-side observability (sibling
  seams)" section is the vocabulary companion — this reset pair is a natural
  third sibling there alongside `timing` and `Moment`.

## Update (k300 — `retry_after`, and the rate limit always describes the latest response)

**`retry_after` is a duration, not a third reset pair.** `Retry-After` was already in the
`raw` superset (decision 4) but had no typed reading. It answers one question — "how long
until I may retry" — so it gets only the duration half: `retry_after` (`Maybe[Num]`
seconds), a lazy builder over `raw->{'retry-after'}`. The wire speaks it in two forms
(RFC 9110): delta-seconds, taken as is (a fractional value is accepted, normalize don't
gatekeep), and an HTTP-date, measured from `received` exactly as decision 2 measures an
Anthropic instant, and clamped at `0` — a date already passed means "retry now", not a
negative wait. Anything else is `undef` and stays in `raw`; no default is invented
(decision 2's rule). No `retry_at` instant is added: nobody asked for one, and
`received + retry_after` is one line for a caller who wants it. `to_hash` / `TO_JSON`
carry `retry_after` when defined. `RateLimit::_parse_retry_after` is the one parser; the
error messages use it too (`… request failed: 429 Too Many Requests (retry after 8s)`).
`HTTP::Date` (already installed with `HTTP::Message`) is now a direct `requires`.

**The engine's rate limit is the latest response's, error or not.** Two lies are
removed. (1) A response without rate-limit headers used to leave the previous
response's `RateLimit` on the engine, and `simple_chat` / `chat_f` cloned that stale
object onto the new `Response`; `Engine::Remote::_update_rate_limit` now stores
whatever the parse returns, so no headers means `undef` and `Response.rate_limit`
describes the response it sits on. (2) Error responses croaked before the headers were
read, so after a 429 — the one response whose remaining = 0, resets and `retry-after`
matter — `engine->rate_limit` still showed the last success. Now every path records the
rate limit before it croaks or fails its future: `parse_response` and
`execute_streaming_request` (sync), `chat_f` / `simple_chat_f`, `chat_with_tools_f`,
`Langertha::Chat`'s async paths, and `chat_stream_realtime_f` (which never recorded one
at all; it takes the headers once the transfer ends, not inside `on_header`, which may
run in the event loop's read handler). Same result on every backend of ADR 0027 —
`t/12_rate_limit_freshness.t` covers the mocked client, the sync LWP shim and
`Net::Async::HTTP` against a local daemon.

**Addendum (k312).** (a) *No per-engine parsers.* Gemini, Ollama native, AKI native and
LM Studio native document no rate-limit headers, so they keep none — but
`Engine::Remote::_parse_rate_limit_headers`, the base every engine without a dialect
parser falls back to, now returns a `RateLimit` carrying only `retry_after` and `raw`
when a response sends `Retry-After` or `retry-after-ms` (any engine that starts sending
one is covered). Gemini's `RetryInfo.retryDelay` lives in the 429 *body* and stays out of
scope. (b) *`retry-after-ms` wins.* It is Azure OpenAI's header (not in OpenAI's own
table; openai-python reads it first): `_collect_headers` keeps it in `raw` next to
`retry-after`, and `RateLimit::_resolve_retry_after` — the one resolver, behind both
`retry_after` and the error note — takes a numeric ms value / 1000, else `Retry-After`
as above. (c) *One error text.* `Role::HTTP::_request_failed_message` builds
`<engine> <what> failed: <status> (retry after Ns) - <body>`; the sync croaks and the async
dies of `chat_f`, `simple_chat_f`, `chat_with_tools_f`, `Langertha::Chat` and
`chat_stream_realtime_f` all use it, so the text no longer depends on the backend (ADR
0027). The async stream keeps a non-2xx body for that message instead of feeding it to
the stream parser. `t/12_rate_limit_retry_after.t` compares the texts across the mocked
client, LWP, the sync shim and `Net::Async::HTTP`.

**Update (k356).** Addendum (a) is narrowed: it rules out parsers for engines that
*send no* rate-limit headers, not a parser for one provider that does. Perplexity's Agent
API sends `x-ratelimit-limit` / `-remaining` / `-reset` / `-used` with no `-requests` /
`-tokens` suffix, so `Engine::Perplexity` reads them in an `around
_parse_rate_limit_headers` (one provider's spelling → the engine, ADR 0018). The mapping
rests on the k232 header captures, not docs: `-reset` is an epoch-seconds *instant*
(0–1 s after each capture's own `Date`), so it fills `requests_reset_at`; `used=1` after
one request makes it the requests bucket; `-used` stays in `raw`. It is deliberately not a
shared parser: the same unsuffixed names mean epoch-*ms* on OpenRouter and delta-seconds
in the IETF RateLimit draft, and this ADR declines guessing the kind by magnitude. Without
any of the three headers the engine falls back to the Remote `Retry-After` path.
`t/68_perplexity_function_tools.t` replays all six captures and guards that
`OpenAIResponses` ignores the unsuffixed names.

## Future work

- **karr k137** — capture real rate-limit response headers across the engine
  families and replace the mocked coverage with fixtures; blocked and tracked
  separately.
