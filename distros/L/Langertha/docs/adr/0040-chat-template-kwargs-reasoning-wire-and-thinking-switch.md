# ADR 0040 — Self-hosted thinking on/off goes through a `chat_template_kwargs` reasoning wire; `thinking_enabled` is the same concern as `reasoning_effort`

- Status: accepted
- Date: 2026-11-04
- Tags: reasoning, wire-format, value-objects, request, self-hosted, llamacpp, sglang, openai-chat
- Cross-links: ADR 0004, ADR 0009, ADR 0023, ADR 0025, ADR 0032, ADR 0038, CONTEXT.md
- Amends: ADR 0009 (new tag value), karr k46 per-key layering (for `reasoning_effort` + `thinking_enabled`)
- karr: k382

## Context

Langertha-Holmgang measures models in two variants, thinking on and thinking off. On llama.cpp
(`--jinja`), Qwen3.x, Kolibri, Nemotron and Gemma switch thinking only through the chat
template: a top-level `chat_template_kwargs: {"enable_thinking": false}` in the OpenAI-chat
request body. Measured on llama.cpp b12004: that switches Qwen3.8 off; Kolibri-1 reads both
`enable_thinking` and `reasoning_effort` (the server reports `reasoning_effort_levels`
`[low, medium]`); Step-3.7-Flash ignores `enable_thinking` but shortens on
`reasoning_effort=low`.

Langertha had no way to send this. vLLM maps `reasoning_effort` onto `enable_thinking` itself
(server-side), but llama.cpp and SGLang do not do it the same way, and a generic
OpenAI-compatible endpoint has no path at all. ADR 0004 rules out an `extra_body` side-channel,
so the switch has to be a modeled mapping on the reasoning seam of ADR 0009.

The run also needs a switch without an effort level ("thinking on", "thinking off"), and that
switch has to coexist with `reasoning_effort`, which every other wire already uses to mean the
same thing.

Sources read for the wire truth: llama.cpp `tools/server/README.md`,
`tools/server/server-common.cpp`, `common/jinja/caps.cpp`; SGLang `protocol.py`
(`ReasoningEffortTier`) and `serving_chat.py` (`normalize_reasoning_inputs`); DeepSeek
`api-docs.deepseek.com/api/create-chat-completion`.

## Decision

1. **A new `reasoning_wire_format` tag `chat_template_kwargs`**, serialized by
   `Langertha::Reasoning->to_chat_template_kwargs` (entry in the `to()` dispatch):

   | Input | Body |
   |---|---|
   | effort `none` | `chat_template_kwargs => { enable_thinking => false }`, no `reasoning_effort` |
   | effort `low` .. `max` | `chat_template_kwargs => { enable_thinking => true }`, `reasoning_effort => $effort` |
   | `thinking_enabled => 1` alone | `chat_template_kwargs => { enable_thinking => true }` |
   | nothing set | nothing; the template default applies |

   - `enable_thinking` is a real JSON boolean (`JSON->true` / `JSON->false`). llama.cpp's
     `server-common.cpp` dumps the kwarg values and reacts only to `true` / `false`; a `0` / `1`
     desyncs template and reasoning parser, a string is rejected.
   - Effort `none` sends no `reasoning_effort`: older SGLang (before PR 20556), gpt-oss and
     MiniMax-M3 templates reject it with a 400.
   - The effort is sent **unclamped**. The OpenAI per-model ladder (ADR 0023) is not
     consulted: a self-hosted model id is whatever the operator named it. llama.cpp does no
     validation of the value; SGLang validates against its own `ReasoningEffortTier` Literal.
   - Only the `enable_thinking` key is sent. Templates that read `thinking` instead
     (DeepSeek-V3.x GGUF, Kimi) need the caller's own `chat_template_kwargs` (decision 5).
     SGLang itself maps a `reasoning_effort` onto both `thinking` and `enable_thinking` with
     `setdefault`, so on SGLang an explicit key from us wins over its own mapping.
2. **Default only where the server is known to read it.** `Engine::LlamaCpp` and
   `Engine::SGLang` override `_build_reasoning_wire_format` to `chat_template_kwargs`.
   `Engine::vLLM` stays `openai`: vLLM does the `reasoning_effort` → `enable_thinking` mapping
   itself. Every other OpenAI-compatible engine opts in at construction with
   `reasoning_wire_format => 'chat_template_kwargs'`, never implicitly — `api.openai.com`
   rejects request fields it does not know.
3. **Top-level body fields, no `extra_body` door** (ADR 0004). The serializer's keys go into
   the request body next to the other generation kwargs, the way `reasoning_kwargs_for` and
   `Runtime::Knobs` already place theirs.
4. **`thinking_enabled` — a tri-state switch on the same concern as `reasoning_effort`.**
   An engine attribute on `Role::ReasoningEffort`, an attribute on `Langertha::Reasoning`, and
   a canonical `chat_f` / streaming control (`%CANONICAL_CONTROLS` in `Role::Chat`). Unset,
   `0` or `1`.
   - **Layering — one concern, not per key.** A defined per-request value of either
     `reasoning_effort` or `thinking_enabled` replaces **both** engine values
     (`Role::ReasoningEffort::_reasoning_controls_for`). Engine `reasoning_effort => 'high'`
     plus per-request `thinking_enabled => 0` is thinking off, not a contradiction. An undef
     per-request value counts as not set. `thinking_budget` and `thinking_display` keep the
     k46 per-key layering.
   - **Croak only on a same-layer contradiction**: `thinking_enabled => 0` with an effort other
     than `none`, or `1` with `none` (`Langertha::Reasoning->assert_switch_agrees`). For the
     engine attributes it fires at construction (`around BUILDARGS` on the role, which also
     reads Anthropic's `effort` alias); for the per-request controls when the `Reasoning`
     object is built, or — on an engine that resolves the controls without building one
     (DeepSeek) — by calling `assert_switch_agrees` itself.
   - **Off is effort `none` on every wire.** `Reasoning->normalize_off_switch` turns
     `thinking_enabled => 0` without an effort into `effort => 'none'` (in `Reasoning`'s
     `BUILDARGS`, and in the role's resolver for readers other than the serializers). So off
     disables thinking exactly where `none` does, and the ADR 0025 temperature gate in
     `Engine::OpenAI` reads the resolved effort and sees it. Exception: a budget-control
     profile (Gemini 2.5) takes no effort, so the off switch stays bare there and is dropped
     with a carp; mapping it to `thinkingBudget: 0` is deferred (which 2.5 models take 0 is
     unverified).
   - **On without a level** has a wire form only where a level-free on-switch exists:
     `chat_template_kwargs`, the opted-in thinking toggle (MiniMax, Kimi: the profile's
     on-type), Ollama's boolean `think` (not GPT-OSS, which takes only levels), and DeepSeek
     V3.x `thinking: {type: enabled}`. Everywhere else nothing is sent and the engine carps
     once per engine instance, keyed on wire + value + model — a per-request model override
     carps again for the new model (`Reasoning->drops_thinking_enabled_on`,
     `_warn_thinking_enabled_dropped`).
   - **Never croak across a matrix.** A switch that has no form on a wire is dropped with a
     carp, not an exception, because Holmgang runs one on/off matrix over every engine.
   - **DeepSeek V3.x effort `none` now sends `thinking: {type: disabled}`** (documented on the
     DeepSeek API reference). It used to send `enabled` for every effort, `none` included — a
     bug fix that falls out of routing `Engine::DeepSeek` through the shared resolver.
5. **Merge a caller's `chat_template_kwargs` one level deep.** In both
   `Role::OpenAICompatible::chat_request` and `chat_stream_request`
   (`_openai_generation_kwargs`), a caller's `chat_template_kwargs` HashRef from `%extra` is
   merged over ours key by key: the reasoning keys go first, the caller's keys win, the caller's
   other keys survive. A non-hash caller value replaces ours whole; an undef caller value is
   dropped (not sent as `null`), and ours goes out as if none were given.

## Rationale

- **A tag value, not an engine override.** The switch is a whole dialect of the reasoning
  concern — a different field, a different value type, no clamping — shared by at least two
  unrelated servers and reachable by any OpenAI-compatible endpoint. ADR 0009 says such a
  variation is "a new tag value with a new `to_<fmt>` branch"; an engine-level
  `reasoning_kwargs_for` override would have to be copied for every opt-in endpoint.
- **Opt-in beyond llama.cpp/SGLang** because an unknown body field is a 400 on strict schemas
  (`api.openai.com`, cf. the Mistral case in ADR 0038). vLLM is left alone because it already
  does the mapping, and sending both would put two sources of truth on one request.
- **No clamping** because the value object has nothing to clamp against: the ladder belongs to
  the model behind the server, not to the id string. The honest clamp source is the server
  itself (llama.cpp `/props` `reasoning_effort_levels`), which is a learned-capability question
  for ADR 0032, not a guess in `Reasoning`.
- **One concern, not two.** Every existing wire already expresses "off" as effort `none`.
  Treating `thinking_enabled` as an independent key would let the engine layer say `high` and
  the request say "off" and leave Langertha to pick one silently; per-key layering would turn
  that ordinary override into a croak. Replacing both engine values when the request touches
  either keeps the override natural and leaves the croak for the one case that is really a
  contradiction — the caller saying two different things in the same place.
- **Normalizing off to `none`** makes the new switch inherit every existing wire's off form,
  every floor and every drop rule for free, and keeps the temperature gate (ADR 0025) correct
  without a second code path.
- **Carp, not croak, on a missing wire form**, because the caller's intent is a matrix
  dimension, not a per-engine requirement: one run over ~25 engines must not die on the engine
  that has no level-free on-switch.
- **Merge instead of whole-replace** — a deliberate divergence from `stream_options` in ADR
  0038. `stream_options` is one setting, so a caller value replacing ours whole is the
  intuitive override. `chat_template_kwargs` is a bag of independent template variables; a
  caller adding `thinking => false` for a Kimi template must not silently erase our
  `enable_thinking`.

## Consequences

- `reasoning_wire_format` now has six values: `openai`, `anthropic`, `gemini`, `responses`,
  `ollama` (called directly by the native Ollama engine) and `chat_template_kwargs`.
- `t/data/reasoning_capability_gate_bodies.json` changed for the LlamaCpp and SGLang rows and
  the two DeepSeek V3.2 effort-`none` rows (`enabled` → `disabled`); vLLM and the generic
  OpenAI bodies are unchanged unless an engine opts in.
- A template that does not read `enable_thinking` ignores the switch silently; Langertha cannot
  detect that from the request side. The documented remedy is the caller's own
  `chat_template_kwargs`.
- `thinking_enabled => 0` cannot disable thinking where effort `none` cannot (Gemini 3/4 floor,
  gpt-6 / legacy gpt-5 without `none`, GPT-OSS on Ollama raised to `low`); that is the
  consequence of normalizing, and is documented on the attribute.
- Engines that override `reasoning_kwargs_for` and resolve the controls themselves (DeepSeek)
  must go through `_reasoning_controls_for` so the layering and the off normalization hold, and
  call `Langertha::Reasoning->assert_switch_agrees` so a same-layer contradiction still croaks.

## Future work

- **Per-model effort clamp on llama.cpp** from `/props` `reasoning_effort_levels`, via the ADR
  0032 learned-capability seam (explicit probe, never implicit). Not filed yet.
- **Gemini 2.5 off switch → `thinkingBudget: 0`** once it is verified which 2.5 models accept 0.
