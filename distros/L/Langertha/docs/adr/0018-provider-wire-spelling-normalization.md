# ADR 0018 — Where a provider's wire *spelling* is normalized: value object, dialect role, or engine-scoped `around`

- Status: accepted
- Date: 2026-09-01
- Tags: response, engines, roles, wire-format, thinking, usage

## Context

Langertha already has a written rule for a provider field that is *new*: ADR 0004 —
outbound it rides as a top-level `%extra` kwarg from an `around 'chat_request'`, inbound it
becomes a first-class `Maybe`-typed attribute on `Langertha::Response`. And it has a written
rule for *parsing*: ADR 0001 / 0010 put inbound wire-walking inside the canonical value
objects (`ToolCall->extract($fmt, $data)`), a stance ADR 0017 restates for `Moment->from_wire`
("the parse lives in the value object, not in the engine").

What was never written down is the far more common case: the field is **not** new, the
canonical attribute already exists, and the provider simply *spells it differently*. There are
three plausible homes for that knowledge and no rule saying which one to use. The batch that
landed on 2026-08-31 chose a different one in each of three commits, all in the same week, all
for the same class of problem:

| Commit | Spelling | Went to |
|---|---|---|
| `2653715` (k124) | AKI's `/anthropic` shim ships `tool_use.input` as a JSON *string* — the OpenAI encoding inside an Anthropic block | `Langertha::ToolCall::from_anthropic`, routed through the same `_decode_args` `from_openai` uses |
| `196a274` (k125) | Anthropic reports the cache read-back flat as `usage.cache_read_input_tokens`; OpenAI nests it at `usage.prompt_tokens_details.cached_tokens` | `Langertha::Response::BUILDARGS` — shared by every engine |
| `ca56b86` (k127) | AKI.IO returns chain-of-thought under a bare `choices[0].message.reasoning`; `Role::OpenAICompatible` reads only the DeepSeek/Nous `reasoning_content` | an engine-scoped `around 'chat_response'` in `Engine::AKIOpenAI` |

Three homes, three commits, no stated rule — and the widths differ by orders of magnitude.
`Role::OpenAICompatible` reaches every one of the twenty-plus engines that descend from
`Engine::OpenAIBase`; `Response::BUILDARGS` runs for every response of every engine there is;
the `around` in `AKIOpenAI` runs for one.

The layering that makes the third option work was also undocumented. `Role::Chat` composes
`Role::ThinkTag` (`lib/Langertha/Role/Chat.pm:807`), so **every** chat engine already carries a
role-level `around 'chat_response'` that can set `thinking` from `<think>` tags. `VLLMHook`
(ADR 0004) adds an engine-level one to lift `probes`. An engine-level modifier declared in the
class body wraps the already-role-wrapped inherited method, so it runs **outermost** — it sees
whatever the inner layers produced, and can silently overwrite it.

## Decision

A provider's spelling of a canonical field is taught to exactly one layer, chosen by **how wide
the spelling is** — never by which file was most convenient to edit.

### 1. The value object's inbound door — when the quantity has a value object

The default. `Usage->from_hash`, `Moment->from_wire`, `ToolCall->from_$fmt` / `->extract($fmt,
$data)`, `Tool->from_hash`. These classes exist precisely to be the one place a wire shape is
recognized; `Usage->from_hash` already carries three spellings for input tokens and three for
output. A new spelling of a quantity that has a value object goes here and nowhere else — that
is ADR 0001's "the value object owns inbound parsing", unchanged. k124 belongs here and went
here.

### 2. The wire-envelope role's `chat_response` — when the spelling is the family's

`Role::OpenAICompatible` reading `reasoning_content`, `Role::AnthropicCompatible` reading
`thinking` blocks. The envelope role is the right home when the spelling is a property of the
*dialect*, so that every engine speaking it benefits and no engine speaking it has to know.

### 3. An engine-scoped `around 'chat_response'` — when it is one provider's quirk

When a provider conforms to a family in every respect but one, the deviation is lifted in that
engine's own `around 'chat_response'`, onto the **existing canonical attribute** via
`clone_with`. Two constraints make this safe, and both are load-bearing:

- **The lift is a strict fallback, guarded by the canonical predicate.** `AKIOpenAI` opens with
  `return $resp if $resp->has_thinking;` — the inner layers (the dialect role's own reading,
  `Role::ThinkTag`) always win, and the engine only fills a gap. Without the guard the
  outermost modifier would silently override `<think>` extraction on the same response.
- **It targets an attribute that already exists.** A genuinely new field is ADR 0004's case, not
  this one.

### 4. A new first-class `Response` attribute — when the field is genuinely new

Unchanged from ADR 0004. `probes` is a new quantity, not a new spelling of an old one.

### Deliberate keeps

- **We do not widen the shared dialect role for one provider.** Twenty-plus engines inherit
  `Role::OpenAICompatible` through `Engine::OpenAIBase`; every spelling added there is a
  permanent read on every response of every one of them, and the next provider quirk has
  exactly the same claim to be added. The role would accrete a spelling table nobody owns.
- **We do not introduce a per-engine spelling hook** (`response_thinking_key`, a
  `%SPELLINGS` table, a `Role::ReasoningSpelling`). One case does not earn an abstraction. The
  `around` is five lines, names the provider in a comment, and is deleted in one edit when the
  provider fixes its wire.
- **We do not leave the spelling to consumers reading `raw`.** `raw` is the unmodeled dump
  (ADR 0004); a caller reaching into it is the failure this seam exists to prevent.

### The k125 exception, recorded rather than rationalized

`cached_tokens` went to `Response::BUILDARGS` — home 1 by *scope* (it is universal) but not by
*mechanism*: the value object is bypassed. The cause is placement, not judgment. `cached_tokens`
is modeled as a `Langertha::Response` attribute rather than on `Langertha::Usage`, so its
spellings had no value object to live in — while the very same `BUILDARGS`, forty lines later,
hands the rest of the usage block to `Usage->from_hash`. The result is one method that both
delegates usage parsing to the value object and hand-parses two usage spellings itself. Under
this ADR those spellings belong on `Usage`. Behavior today is correct and gated by
`t/91_response_usage.t`; the seam is what is off. Tracked as karr k130. **Resolved — see the
Update (karr k130) below: the spellings now live on `Langertha::Usage`, and home 1 holds by
mechanism, not only by scope.**

## Rationale

The rule is one sentence: **the width of the code that knows a spelling should match the width
of the wire that uses it.** Every failure mode here is a width mismatch. A family spelling
hidden in one engine gets re-derived by the next engine of that family. A single provider's
spelling installed in a role shared by twenty engines is twenty engines carrying a fact about
one of them, and an invitation for the twenty-first.

Choosing the *narrowest* home that covers the wire also makes the decision cheap to reverse in
the direction it actually travels. Spellings turn out to be broader than first thought far more
often than the reverse: when a second engine of the family needs the same lift, the four-line
`around` moves up into the envelope role and the engines lose code. That is the same instinct
ADR 0016 applies to wire envelopes — a second consumer is the trigger to move something up, and
speculatively starting high is the mistake.

The predicate guard is what makes engine-scoping legitimate rather than merely convenient.
Because the class-level modifier is outermost, an unguarded lift is an *override* of everything
the framework already did, which is a different and much larger decision than filling a gap.
`return $resp if $resp->has_thinking` states the precedence in one line, at the only place it
could be misread.

## Consequences

- **A new provider quirk costs an `around` in one engine**, plus a POD paragraph on that
  engine and a test. The shared roles are untouched, so no other engine's behavior can move.
- **Callers read the canonical attribute and never learn which layer filled it.**
  `$response->thinking` is uniform whether it came from `reasoning_content` in the role,
  `<think>` tags in `Role::ThinkTag`, or the engine-scoped `reasoning` lift.
- **The engine-level modifier runs outermost — guard it or you overwrite.** `Role::Chat`
  composes `Role::ThinkTag` for every chat engine, so there is *always* an inner writer for
  `thinking`. This is the trap the pattern carries, and the predicate guard is not optional.
- **Two lifts of the same field can stack silently.** Nothing detects that a role and an engine
  both write `thinking`; the predicate guard is the only coordination. If a third layer ever
  wants in, this ADR is the place to write the ordering down explicitly.
- **A lift on `chat_response` does not reach the streaming route.** All three homes above sit on
  the non-streaming path; a streamed call on the same engine and prompt used to read `undef`.
  Same class as ADR 0011's sync/async `ttft_seconds` gap. **Resolved (karr k129, commit
  `74ccc6d`): `Langertha::Stream::Chunk` gained a `thinking` field the dialect parsers fill, and
  `Role::Chat::aggregate_thinking` reassembles it — the aggregation layer normalizes once rather
  than the three homes each growing a streaming counterpart. This is an application of the
  existing `aggregate_tool_calls` precedent, not a new decision (see the note under Future
  work).**
- **The request-side `reasoning_wire_format` does not govern the response-side spelling.**
  ADR 0009's per-concern quartet places `reasoning_effort` *onto a request*; the model's
  chain-of-thought comes *back* under `reasoning_content` / `reasoning` / a `thinking` block and
  lands on `Response.thinking` with no tag at all. There is deliberately no
  `thinking_wire_format`: a wire-format tag earns its existence from a per-format serializer
  matrix (ADR 0001, ADR 0009, ADR 0012), and the response side has a one-line read per dialect
  plus the occasional engine quirk — which is exactly what the three homes above cover. If the
  read ever needs per-format branching in more than one direction, that is when to revisit.
- **`TO_JSON` is not a fourth home.** Serializing a value object is not normalizing a wire
  spelling — see the note added to ADR 0001's Consequences about `convert_blessed` (karr k120).
- **Cross-links.** **ADR 0001** (the value object owns inbound parsing; the `tool_wire_format`
  tag is the only outbound door) · **ADR 0003** (`Response` is the canonical home for
  normalized response data) · **ADR 0004** (new provider *fields*, the case this ADR sits
  beside) · **ADR 0010** (`ToolCall->extract($fmt, $data)` as the canonical inbound entry) ·
  **ADR 0011** (route asymmetry in response-side observability) · **ADR 0016** (a second
  consumer is what moves a thing up an axis) · **ADR 0017** (`Moment->from_wire` as a lenient
  value-object inbound door).

## Update (karr k130 — the cache read/write spellings now live on `Langertha::Usage`)

The k125 exception above is closed. Commit `012931f` moved both prompt-cache wire spellings out
of `Response::BUILDARGS` and onto `Langertha::Usage`, so home 1 now holds for the cache
read-back by *mechanism* — the value object's inbound door — and not only by *scope*:

- `Langertha::Usage` gains `cached_tokens` (the cache **read** count) and `cache_write_tokens`
  (the cache **creation** count), both `Maybe[Int]`, routed through the same field-hash the
  other accessors use. `Usage::from_hash` parses each from both wire spellings — OpenAI's
  `usage.prompt_tokens_details.{cached_tokens,cache_write_tokens}` nesting wins over Anthropic's
  flat `usage.{cache_read_input_tokens,cache_creation_input_tokens}` when both appear — with the
  values read into lexicals first so a missing key never autovivifies the caller's hash. This
  is exactly the multi-spelling inbound door `from_hash` already was for the input/output token
  families; the seam is unchanged, only extended.
- `Response::BUILDARGS` now coerces `usage` to a `Langertha::Usage` object *first* and lifts
  `cached_tokens` **off the parsed object**, dropping the inline hand-parse of the raw hash. The
  public `Response.cached_tokens` attribute and the explicit-parameter precedence k125
  established (an explicit `cached_tokens` arg wins) are preserved — one derives from the value
  object now instead of duplicating its wire knowledge.
- **The read/write distinction is deliberate and was already the k125 rule.** The write count is
  not folded into `cached_tokens`. What k130 adds is that it is now *modeled* rather than
  discarded: the langertha-llm-advisor pass on k130 established that cache **writes** became
  separately billable on OpenAI (GPT-5.6+ charges 1.25× for a write), so a write counter is no
  longer an Anthropic-only concern — it earns a home on the value object. Anthropic's per-TTL
  `cache_creation` breakdown and Gemini's `cacheTokensDetails[]` stay verbatim in `Usage.raw`,
  the same normalized-plus-native split as ADR 0011 / ADR 0017. `cache_write_tokens` has **no**
  `Response` accessor — it is read as `$response->usage->cache_write_tokens`, so no new
  first-class `Response` field is minted for a count with a value-object home (ADR 0004's line
  stays where it is).

This is an amendment in place, not a new ADR: the four-homes decision above is unchanged. k130
is simply the case moving from home 1-by-scope to home 1-by-mechanism, which is the direction
this ADR's Rationale said spellings travel — toward the widest correct home.

## Update (karr k248 — `finish_reason` `stop` next to tool calls reports `tool_calls`, dialect tier)

AKI.IO's OpenAI-compatible endpoint answers a non-streaming tool call with `finish_reason:
"stop"` instead of `"tool_calls"`. Live on 2026-09-25 with gpt-oss-120b
(`t/data/akiopenai_gptoss_tool_call_response.json`) and already in the k102 capture with
llama3-chat-8b (`t/data/akiopenai_tool_call_response.json`); the streamed reply to the same
gpt-oss request said `"tool_calls"` (`t/data/akiopenai_gptoss_tool_call_stream.sse`). The same
behaviour is reported for gpt-oss on other vLLM-style servers. Only AKI.IO is verified.

This is the finish *value* disagreeing with the reply, not a second spelling of a field. The fix
still goes to **home 2**. `Role::OpenAICompatible` has a private `_openai_finish_reason`, used by
`chat_response` and by `parse_stream_chunk` on the chunk that delivers the assembled calls.
It reports `tool_calls` when the reply has tool calls and the wire says `stop`. Every other
value passes through: `length` means truncation and must stay visible, and an absent finish is
not invented. The wire value stays readable in `raw`, so no new `Response` attribute is added
(ADR 0004 is not triggered). `Role::ResponsesCompatible` has applied the same rule since k171.
The rule keeps finish reason and `Response.tool_calls` consistent (ADR 0003), so a proxy or loop
that branches on `finish_reason` does not read a pending call as a finished answer.

Why home 2 despite the "do not widen the shared dialect role for one provider" keep: the
problem is not limited to one provider. It comes from the serving stack, has now been seen on two
models, and is reported beyond AKI.IO. The rewrite fires only on a reply that contradicts itself,
so a correct server is never changed and no spelling table grows. An engine-scoped `around` on
`AKIOpenAI` would have to be copied onto vLLM, SGLang and every gateway that serves gpt-oss.

## Update (karr k296 — `content` as a list of content chunks, dialect tier)

Mistral's reasoning models send `message.content` / `delta.content` as a list of chunks
(`{type:"thinking", thinking:[{type:"text",…}]}`, `{type:"text",…}`) instead of a string, and
the `Str` constructors died on it. `Role::OpenAICompatible::_openai_content_parts`, shared by
`chat_response` and `parse_stream_chunk`, reads the list: text chunks join into `content`,
thinking chunks into `thinking` (after `reasoning_content` / `reasoning`), other chunk types are
skipped. **Home 2**, for the k248 reason: the list reaches every engine that relays those models
(Mistral, OpenRouter, Scaleway, HuggingFace, self-hosted), the read fires only on a non-string
`content`, and a string `content` is untouched. Documentation-derived, not live-verified.

## Update (karr k298 — where a stream's usage is found)

Streamed usage is read from every documented place, each at its tier. **Home 2**:
`Role::AnthropicCompatible` merges `message_start`'s usage (input and cache counts) with
`message_delta`'s (whose keys win) in the per-stream state, and `Role::OpenAICompatible` turns
the `include_usage` frame (`choices: []`) into a content-less, non-final chunk carrying usage.
**Home 3**: Groq's `x_groq.usage` is read by an engine-scoped `around parse_stream_chunk` on
`Engine::Groq`, guarded by `has_usage`. `Role::Chat::aggregate_usage` returns the last usage a
stream's chunks carry, since the include_usage frame arrives after the `is_final` chunk.
Documentation-derived, not live-verified.

## Future work

- **karr k130** — *realized* (see the Update above): the `cached_tokens` (and now
  `cache_write_tokens`) wire spellings live on `Langertha::Usage`; home 1 holds for the cache
  read-back the way it already did for the token counts.
- **karr k129** — *resolved* (commit `74ccc6d`): the streamed-thinking gap is closed by a
  `Stream::Chunk.thinking` field plus `Role::Chat::aggregate_thinking`; the aggregation layer
  normalizes once (the `aggregate_tool_calls` precedent), so the three homes above did **not**
  need a per-home streaming counterpart. This was an application of existing seams, not a new
  architectural decision, so it earned no ADR of its own — see the resolved Consequences bullet.
