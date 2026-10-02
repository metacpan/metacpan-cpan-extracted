# ADR 0002 — Engine capabilities derive from the composed role inventory

- Status: accepted
- Date: 2026-06-26
- Tags: tools, capabilities, roles, chat_f

## Context

`chat_f` has to decide, per engine, whether a caller's `tools` / `tool_choice` /
`response_format` request can go to the wire as-is or must be rewritten into a form the
provider actually accepts (see the auto-rewrite matrix in `CLAUDE.md`). That decision needs a
truthful, queryable picture of each engine's capabilities: does it do native tools? named
`tool_choice`? `response_format` JSON-schema? Hermes-only?

Hardcoding a capability list on each of ~25 engines would drift away from what the engine can
really do the moment someone adds or removes a role.

## Decision

1. **`Langertha::Role::Capabilities` derives the flag set from which capability-bearing roles
   the engine composes.** A single `%ROLE_TO_CAPS` map (`Role::Chat` → `chat`, `Role::Tools` →
   `tools_native tool_choice_auto tool_choice_any tool_choice_none tool_choice_named`,
   `Role::HermesTools` → `tools_hermes`, `Role::ResponseFormat` →
   `response_format_json_object response_format_json_schema`, …) is the **single source of
   truth**. `engine_capabilities` scans `$self->does($role)` over that map. The role itself
   needs no knowledge of `engine_capabilities`; adding a capability is a one-file change.

2. **`supports($cap)` is the single query.** It is the only way the rest of the codebase asks
   "can this engine do X" — `chat_f`'s auto-rewrite matrix keys off it.

3. **An engine corrects wire reality only via `around engine_capabilities`** — when the role
   inventory over-promises (e.g. a provider composes `Role::Tools` but only accepts a *string*
   `tool_choice`, never a named object), the engine deletes `tool_choice_named` in an `around`.
   This is the one sanctioned escape hatch; it sits next to the engine, not in the map.

`Role::Capabilities` is composed by `Role::Chat`, so every engine has it.

## Rationale

Capabilities follow composition, so they cannot silently disagree with what the engine is
actually wired to do — if it doesn't compose `Role::Tools`, it can't claim tool flags. The only
two places to look are the central map (what a role grants) and the engine's `around` (where
the wire truth differs from the inventory). A capability flag with no role to back it has
nowhere to live, which forces the corresponding role to exist rather than letting a bare string
flag float.

## Consequences

- Adding a capability = edit `%ROLE_TO_CAPS` once. Adding an engine = compose the right roles
  and, only if the wire disagrees with the inventory, one `around`.
- The auto-rewrite matrix in `chat_f` is downstream of `supports()`; keeping the flags honest
  keeps the rewrites correct. A dishonest flag (claimed but not deliverable) is the failure
  mode to guard against — hence the `around` corrections rather than editing the shared map.
- This registry is the precondition for ADR 0001's tag dispatch to be safe: the loop only
  reaches a value-object branch the engine actually supports.

## Update (ADR 0019)

The `around engine_capabilities` escape hatch (decision 3) resolves **per engine** — it cannot
say "this field, but only for that model." On the tool / structured-output axis the wire reality
is frequently per-model (`kimi-k3` forbids a forced named tool while its `kimi-k2.*` siblings
allow it), so the role-derived base was identical across ~17 OpenAI-dialect engines and wrong on
~11 of them. ADR 0019 adds a **layer 3**: a declarative, ordered `model_capability_corrections`
table keyed on `chat_model`, applied *inside* `engine_capabilities` after the role derivation.
The `around` hatch is unchanged and is now specifically the **engine-wide endpoint gate** (the
whole endpoint never accepts a field); per-model reality lives in the new table. Layers 1 and 2
of this decision stand as written. See ADR 0019.

## Update (k234 — a layer-2 rule on a role: Role::HermesTools clears the native tool flags)

Composing `Role::Tools` gives `tools_native`, `tool_choice_{auto,any,none,named}` and
`parallel_tool_use`, but the hermes wire has no `tools`, `tool_choice` or `parallel_tool_calls`
body key: the tools ride the system prompt, which cannot force a tool. `Role::HermesTools` now
carries an `around engine_capabilities` that deletes `tools_native`, `tool_choice_any`,
`tool_choice_named` and `parallel_tool_use`. `tools_hermes`, `tool_choice_auto` (what the prompt
says) and `tool_choice_none` (`chat_f` withholds the tools, k231) stay. The rule sits on the role,
not on each engine, because its two consumers have different parents (`OpenAIBase`, `Remote`) —
the ADR 0016 placement. It only deletes, so its order against an engine's own `around` or its
layer-3 corrections does not change the result. It is not a layer-3 row: `tool_wire_format` is
per engine, so a per-model `tools_native` would misdescribe the wire. Pinned in
`t/78_engine_capabilities.t`.

## Update (k239, k241 — field emission follows the claimed capability)

A cleared flag used to steer only `chat_f`'s rewrite: the request builders still put the field
on the body. Ollama native and Ollama's `/v1` accept an unknown `tool_choice` or
`parallel_tool_calls`, ignore it and answer 200, so the caller believed a tool was forced. Now
the claimed capability also gates emission on the tool-selection axis:

- **`tool_choice`** — one rule in `Role::Chat::_gate_tool_choice` (the ADR 0020 k213/k233 rule,
  generalized), used by `OpenAICompatible`, `ResponsesCompatible`, Ollama native and LM Studio
  native. A kind the engine does not `supports('tool_choice_<kind>')` is not sent: `auto` and
  `undef` drop silently, `none` withholds the request's tools with a carp, a forced choice drops
  with a carp. An unreadable choice passes through only where some `tool_choice_*` is claimed.
  The builder serializes what the rule returns with `ToolChoice->to($fmt)`.
- **`parallel_tool_calls`** — `Role::Chat::_parallel_tool_calls_kwarg`, shared by the Chat
  Completions and Responses envelopes, emits only where `supports('parallel_tool_use')`. A value
  the caller set (control or attribute) that the gate drops carps, the ADR 0025 drop+carp;
  nothing set stays silent. Ollama native and Gemini call it too, only for that carp: their
  flag is cleared, so it never emits there. An explicit `parallel_tool_calls` kwarg is wire intent and passes.

Layer-2 clears that go with it: Ollama native drops `tool_choice_*` and `parallel_tool_use`
(tools_native stays, so a forced named tool in `chat_f` takes the ADR 0005 `format` rewrite);
Gemini (no parallel knob in `ToolConfig`) and OllamaOpenAI drop `parallel_tool_use`. LM Studio
native composes no `Role::Tools` and croaks on a non-empty `tools` list.

The registry is the truth, with no per-engine exception: wherever an OpenAI-compatible engine
clears a `tool_choice_*` kind, the gate applies — MiniMax and OllamaOpenAI (no field),
llama.cpp (named downgraded to auto), Moonshot per model (400), SGLang (auto and none
undocumented: auto drops as the default, none withholds the tools) and Hetzner (all four
cleared as unverified: auto drops, a forced choice drops with a carp). `tools_native` gates no
emission: it steers only `chat_f`'s rewrite, so a request's `tools` still go on the body where the
flag is cleared (Hetzner) — only `tool_choice` and `parallel_tool_calls` are gated. A `none` with
no tools to withhold drops silently (k246). A flag cleared for want of
confirmation is re-added once confirmed, and the field comes back with it. Tests: `t/76_tool_choice_capability_gate.t`,
`t/76_parallel_tool_use_capability_gate.t`.

## Update (k242, k244 — the parallel_tool_use audit; SGLang tool_choice re-added)

`parallel_tool_use` is cleared at layer 2 on DeepSeek (ignored, always parallel), Moonshot,
the HuggingFace router and AKIOpenAI (not in the chat schema) and Replicate (no chat/completions
path in its OpenAPI). All docs-derived; AKIOpenAI also had one live probe (2026-09-25,
`gpt-oss-120b`, two tools, `parallel_tool_calls: false`): HTTP 200, one call — accepted, not
shown honored, so still cleared. TSystems keeps it: its LLM Server OpenAPI lists the field.
MoonshotAnthropic keeps it: the shim field is `tool_choice.disable_parallel_tool_use`, outside
this audit. SGLang gets `tool_choice_auto` / `tool_choice_none` back, the re-add the k239
Update foresees: `protocol.py` types `tool_choice` as auto|required|none|named and
`serving_chat` honors none; the docs list only the grammar-backed forms. Pinned in
`t/78_engine_capabilities.t` and `t/78_model_scoped_capabilities.t`.

## Update (k251 — the Role::HermesTools rule keys on the resolved tag, not on composition)

The k234 rule deleted the native tool flags whenever the role was composed. `tool_wire_format`
has an init_arg, so `NousResearch->new(tool_wire_format => 'openai')` sent tools natively while
`supports()` still reported `tools_hermes` and no `tool_choice_named`, and `chat_f` rewrote a
forced tool to `json_schema` (ADR 0005). The rule now reads `$self->tool_wire_format`: on
`hermes` it deletes `tools_native`, `tool_choice_any`, `tool_choice_named` and
`parallel_tool_use` as before; on any other tag it deletes `tools_hermes` and leaves the native
flags as the role inventory gives them. The flags follow the tag the engine actually sends with.
`Manifest::Builder` probes each model on a `clone_object` copy, which copies an already-built lazy
tag; the probe now drops a builder-made tag (`_reset_derived_tool_wire_format`, via the
`_clear_tool_wire_format` clearer) so it resolves again for the probed `chat_model`. A tag passed
to the constructor is kept: a `trigger`, which fires for constructor values and never for the
builder, records it in `_tool_wire_format_given`. A model-aware tag builder (k238 step c) is not
part of this change. Pinned in `t/66_hermes_tag_override.t` and `t/96_manifest_builder.t`.
