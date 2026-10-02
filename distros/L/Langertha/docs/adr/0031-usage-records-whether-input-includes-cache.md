# ADR 0031 — `Usage.input_tokens` keeps the wire's meaning; `input_includes_cache` records it, and `Pricing` prices each token once

- Status: accepted
- Date: 2026-09-25
- Tags: usage, pricing, cost, prompt-cache, value-objects
- Cross-links: ADR 0018, ADR 0028
- karr: k263 (for skeid k28)

## Context

`Langertha::Pricing->cost_for` priced `Usage.input_tokens` at the rule's input rate and
nothing else. Pricing prompt-cache reads and writes at their own rates needs to know whether
`cached_tokens` / `cache_write_tokens` are already part of `input_tokens`, and the wires
disagree:

| Wire | cache counts | part of the input count? | evidence |
|---|---|---|---|
| OpenAI Chat (and compatibles) | `prompt_tokens_details.{cached,cache_write}_tokens` | yes | `akiopenai_chat_response`: 65 prompt, 64 cached |
| Open-Responses (OpenAI, Perplexity) | `input_tokens_details.*` | yes | `responses_web_search`: 8542 in, 4394 written; `perplexity_agent_search`: 4071 in, 4068 written |
| Gemini | `cachedContentTokenCount` | yes | Gemini docs |
| AKI native | `num_cached_tokens` | yes | subset of `prompt_length` (Engine::AKI) |
| Anthropic | flat `cache_read_input_tokens` / `cache_creation_input_tokens` | no | Anthropic docs |

`Usage` did not record which case it had, so a pricer could not avoid either billing a cached
token twice (Anthropic-style addition on an OpenAI usage) or not at all.

Sibling distributions (skeid, knarr, raider) record and bill on `input_tokens` today, so
redefining it as "always the whole prompt" or "always the uncached part" would silently change
their numbers.

## Decision

1. `input_tokens` keeps the meaning the wire gives it.
2. `Usage` gains `input_includes_cache` (`Maybe[Bool]`), set by `from_hash` / `from_raw` from
   where the cache counts were found: nested `*_details`, Gemini and the flat `cached_tokens`
   → true; Anthropic's flat keys → false; no cache count → `undef`. One flag covers reads and
   writes because every known wire reports both the same way; a mixed hash is marked false.
3. `Usage->uncached_input_tokens` is `input_tokens` when the flag is false, else
   `input_tokens - cached - write` clamped at zero. `undef` counts as included, which is what
   `total_tokens = input + output` already assumes.
4. `Pricing` rules take optional `cached_input_per_million` and `cache_write_per_million`.
   A rule with neither is priced exactly as before. A rule with either one prices
   `uncached_input_tokens` at the input rate plus reads and writes at their rates, a missing
   one falling back to the input rate — Langertha never assumes a discount the rule did not
   state.
5. `Cost` gains `cache_read_usd` / `cache_write_usd` (default 0), summed into `total_usd` and
   emitted by `to_hash` as `cache_read_cost_usd` / `cache_write_cost_usd`.

## Consequences

- Cache pricing is opt-in per rule, so no existing rule changes its result. A rule without
  cache keys keeps under-billing Anthropic cache traffic (those tokens are not in
  `input_tokens`); adding a cache key is the fix.
- Built with `new` and no flag, a Usage is read as "included"; callers building one from an
  Anthropic-shaped count pass `input_includes_cache => 0`.
- The flag describes the spelling, not the provider. AKI.IO's `/anthropic` shim reports
  `input_tokens` 65 with `cache_read_input_tokens` 64 for the same request its OpenAI face
  reports as 65 / 64 — its count includes the reads — but it is marked false. An engine-scoped
  correction (ADR 0018 layer 3) is follow-up work; the other `/anthropic` shims are unverified.
- `Usage->merge` still sums only input and output; it drops the cache counts and the flag.

## Update (k265 — engine-scoped correction for shims; merge keeps the cache counts)

The spelling is not the meaning on every `/anthropic` shim, so the flag gets an engine-scoped
correction (ADR 0018 tier 3). `Role::AnthropicCompatible` has a hook,
`_usage_input_includes_cache`, that returns `undef` by default (keep the inference). When an
engine answers it, the role hands `Response` and the final stream chunk a *copy* of the usage
block with a canonical `input_includes_cache` key; `Usage->from_hash` lets that key beat the
inference whenever a cache count was found. One key serves both paths, since a stream chunk
carries its usage as a plain hash and consumers build the `Usage` from it themselves. The wire
body in `Response.raw` stays unmodified; the key does show in `$response->usage->{...}`, as
`Engine::AKI`'s canonical `cached_tokens` already does.

- `AKIAnthropic` answers 1 (the captures above: 65 / 64 on both faces).
- `MiniMaxAnthropic` and `MoonshotAnthropic` keep the default: both providers document that
  `input_tokens` excludes cache reads and writes (platform.minimax.io
  anthropic-api-compatible-cache, platform.kimi.ai context-caching, both read 2026-09-25).
- `LMStudioAnthropic` keeps the default; its behavior is unknown.
- A shim found to count the cache inside opts in with `sub _usage_input_includes_cache { 1 }`.

`Usage->from_hash` also sums `cache_creation.ephemeral_5m_input_tokens` /
`ephemeral_1h_input_tokens` into `cache_write_tokens` when the flat total is missing (Moonshot
reports the split; with the flat key present the flat key wins).

`Usage->merge` now sums `cached_tokens` and `cache_write_tokens` (`undef` only when neither side
reported one) and takes the flag from the sides that reported a cache count. Both beside
(false): the sum is false and nothing is added. One inside (true, or `undef` with counts) and
one beside: the beside side's `cached_tokens` and `cache_write_tokens` are added to its
`input_tokens` before summing and the sum is true — lossless, so pricing the merged Usage
costs exactly the sum of pricing each part, and the flag describes the sum. Both inside: true,
or `undef` if either side's flag was `undef` (which reads as inside anyway).

## Update (k354 — provider-reported cost is `Usage.cost_usd`, beside Pricing)

Some providers report what they actually billed. xAI puts it in every usage block as the
integer `cost_in_usd_ticks` (1 USD = 10^10 ticks; chat completions, Responses, images, video)
and, on Responses, also as `cost_in_nano_usd` (1 USD = 10^9); docs.x.ai cost-tracking and the
REST references, read 2026-09-30, docs-derived, not capture-verified. `Usage->from_hash` — the
value-object door every usage block passes (ADR 0018 tier 1; the field names are unique to
xAI) — normalizes it to `cost_usd` in US dollars, ticks first as the finer unit; the integers
stay verbatim in `raw` for exact accounting.

- `cost_usd` is `undef` when nothing is reported, never `0`: an unknown cost must not read as
  free.
- `merge` sums it only when both sides report one; otherwise the sum's cost is `undef`, so a
  partial sum never reads as the whole bill.
- It is deliberately **not** fed into `Pricing` / `Cost`. Those remain the caller's estimate
  from their own price rules; `cost_usd` is the provider's statement. Whether usage records or
  metrics should prefer it over the estimate is left open.
- Perplexity and OpenRouter report their cost under the same generic name, `usage.cost`, in
  two shapes, so each is normalized where its unit is known (karr #363, ADR 0018):
  - **Perplexity** (Agent API, Open-Responses envelope) sends an object that names its unit:
    `{ currency: "USD", total_cost, input_cost, output_cost, cache_*_cost, tool_calls_cost }`
    — capture-verified (`t/data/perplexity_agent_*`, k147 / k232). A self-describing USD
    amount is unambiguous on any wire, so `Usage->from_hash` reads `total_cost` (tier 1), but
    only when `currency` is `USD` and `total_cost` is present; another currency or a missing
    total stays `undef`, the parts are not summed.
  - **OpenRouter** sends a bare number in its credits; "OpenRouter uses a credit system where
    the base currency is US dollars" (openrouter.ai/docs/faq; usage accounting page, read
    2026-09-30) — docs-derived, no capture. The number names no unit and `cost` is too generic
    to read as USD from every OpenAI-compatible server, so the universal door does **not** read
    it. `Engine::OpenRouter` states the unit (tier 3) through a `_wire_usage` hook that
    `Role::OpenAICompatible` gained for this (default: the wire block unchanged; the parallel
    of `Role::AnthropicCompatible::_wire_usage` from k265): it returns a copy of the usage block
    with the canonical `cost_usd` key, which `from_hash` reads first, on the response and the
    stream path alike. `Usage->from_raw` on an OpenRouter body has no engine and so no
    `cost_usd`. `cost_details.upstream_inference_cost` (BYOK: what the key's own provider
    charged) is not OpenRouter's bill and is not folded in.
