---
name: langertha-internals
description: Use when changing Langertha core itself — adding or modifying an engine, role, capability flag, wire format or value object in lib/Langertha/.
---

# Langertha internals

Implementer knowledge for core. The engine tree, role list and ADR index are in `CLAUDE.md`;
the public API is in `perl-ai-langertha`. This skill holds the rules for *changing* core.
When a change touches an area, read its owning ADR first (area map in `langertha-adr`).

## Invariants

- **An engine carries no per-format tool code** (ADR 0001). An engine declares one
  `tool_wire_format`; serialization lives on the value objects: `Tool->to($fmt)` /
  `format_list`, `ToolCall->extract($fmt, $data)` (inbound; `extract_sniff($data)` only when
  the shape is unknown), `ToolResult->to($fmt)`, `ToolChoice->to($fmt)` (ADR 0010). A new wire
  means a new tag plus a `to_<fmt>` / `from_<fmt>` on each value object. Never add a
  `format_tools`-style method back onto an engine.
- **`Response.tool_calls` is the only tool-call shape** (ADR 0003). Native, Hermes-XML and
  forced-tool fallbacks all land there as `Langertha::ToolCall`; rewritten ones set
  `synthetic`. Don't surface a parallel representation.
- **Capabilities stay honest.** `supports($cap)` drives `chat_f`'s rewrite matrix (ADR 0005).
  Over-claimed = a provider 400 at runtime; under-claimed = silent fallback to the synthetic
  path.
- **Normalize, don't gatekeep** (ADR 0018). When providers spell a field two ways, accept both
  at the narrowest right layer — never pick one as "correct":
  1. value-object inbound door (`Usage->from_hash`, `Moment->from_wire`, `ToolCall->from_*`)
     when the quantity has a value object;
  2. the `*Compatible` role's `chat_response` when the spelling belongs to the whole dialect;
  3. an engine-scoped `around chat_response` for one provider's quirk, guarded by the
     canonical predicate (`return $resp if $resp->has_thinking;`) and targeting an existing
     attribute. A genuinely new field is a new `Response` attribute (ADR 0004), not `raw`.
- **Provider reality is not in your memory.** A change that depends on what a provider accepts
  today says so in the report and asks for `langertha-llm-advisor`. TSystems is
  documentation-only (no key exists).

## Capabilities — three layers plus exclusions

`engine_capabilities` (`Role::Capabilities`) is built in order:

1. **Role map** — `%ROLE_TO_CAPS`: composed role → flags. Add a capability by editing that one
   map. Every `Langertha::Role::*` is either in the map or in the non-capability allowlist in
   `t/78_capability_registry.t` (ADR 0016's axis test); the test fails on a role in neither.
2. **Engine-wide** — `around engine_capabilities` deletes flags the whole endpoint never
   accepts (e.g. a string-only `tool_choice` clears `tool_choice_named`; dialect bases clear
   the wrong half of `prompt_cache` / `prompt_cache_key`, ADR 0015).
3. **Per-model** — `sub model_capability_corrections { ( 'exact-id' => {cap => 0|1},
   qr/\Afamily/ => {...} ) }`, an ordered list matched against `chat_model`; later matches win
   (ADR 0019). Per-model wire reality goes here, never into layer 2 behind a regex.

**Exclusions** — two flags that are each fine but reject each other in one request are not a
flag: `sub model_capability_exclusions { ( qr// => \&_rule ) }` on `Role::Chat`, a coderef
called as `$self->$rule(has_tools => …, response_format => …, streaming => …)` that croaks. It
runs after the ADR 0005 rewrite, from `chat_f` and `chat_stream_realtime_f`. Put the rule on
the engine whose serving stack rejects the combination (Groq, Cerebras), not on a shared base
(ADR 0024).

A flag means **the wire accepts the field**, not that every model honors it.

## Wire-format tags

Four independent per-concern tags, each a `_build_<x>_wire_format` builder on its role:
`tool_wire_format` (Role::Tools), `reasoning_wire_format` (Role::ReasoningEffort),
`cache_wire_format` (Role::PromptCache), `knob_wire_format` (Role::RuntimeKnobs). Each value
object (`Tool*`, `Reasoning` + `Reasoning::Profile`, `PromptCache`, `Runtime::Knobs`)
dispatches on its own tag (ADRs 0001/0009/0012). Never key one concern on another's tag.
Per-model reasoning truth lives in `Reasoning::Profile`, not in inline hashes (ADR 0023).

## Composition

- **`-excludes` canon** (ADR 0015). When two roles supply the same builder, the base excludes it
  from the default and lets the envelope role win, with a one-line comment saying who
  supplies it — see `Engine/AnthropicBase.pm`. Dialect bases list roles with
  `with map { 'Langertha::Role::'.$_ } qw(...)` so the intended set is visible.
- **Envelope roles** (`OpenAICompatible`, `AnthropicCompatible`, `ResponsesCompatible`): a wire
  envelope moves from an engine into a `Role::<X>Compatible` only when a *second consumer from
  a different parent* needs it (ADR 0016); the shim ticket that needs it owns the extraction.
  Divergence goes through overridable hooks (ADR 0020), not copies. Capability roles are roles
  from day one.
- **Inheritance encodes the dialect, roles encode capabilities** (ADR 0006). Pick the base by
  the wire the provider speaks, not by the vendor.

## Adding an engine — done means all of these

1. `lib/Langertha/Engine/<Name>.pm`: `extends` the dialect base; `with` only the capability
   roles the wire really has; `# ABSTRACT:`; `make_immutable`; `api_key` from
   `LANGERTHA_<NAME>_API_KEY` for cloud engines, `url` required for self-hosted.
2. No usable `/models` endpoint → `Role::StaticModels` with `_build_static_models`.
3. Wire reality: layer-2 `around engine_capabilities` and/or layer-3 corrections, exclusions if
   the stack rejects a combination. Clear what the docs do not confirm.
4. Tests: `t/00_load.t` entry, a request-building test (`2x`), `t/10_engine_hierarchy.t` for a
   new base relation, a live test only on request (skill `langertha-testing`).
5. Catalogue: `lib/Langertha.pm` `=head2 Engine Modules` (held by `t/79_pod_catalogue.t`; an
   abstract base goes in its allowlist with a reason) and the `CLAUDE.md` engine tree.

## Privates that siblings depend on

Siblings (langertha-raider, -knarr, -skeid) use the **public hooks** of ADR 0028:
`async_request_f`, `async_loop` (`Maybe[loop]`), `langfuse_timestamp`, `Usage->from_raw`,
and — for composers of `Role::PluginHost` — `plugin_instances`, `plugin_args`,
`plugin_pipeline_tool_call_f` (k226). The old privates (`_async_http`, `_async_loop`,
`_langfuse_timestamp`, `_plugin_instances`, `_plugin_args`, `_plugin_pipeline_tool_call`)
stay as aliases until the siblings have migrated (raider: k195 done, k226 pending) — renaming or
reshaping one still needs a karr ticket naming the sibling caller. `_async_http` may be a
`Langertha::Request::SyncHTTP` when Net::Async::HTTP is absent (ADR 0027), so nobody may assume
`->loop` exists — and core must never `use` IO::Async / Net::Async::HTTP at file scope (they
are `recommends`).
