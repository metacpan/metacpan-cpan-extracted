# ADR 0035 — A bound Gemini `cachedContent` owns `systemInstruction`, `tools` and `toolConfig`: the request drops them and carps

- Status: accepted
- Date: 2026-09-26
- Tags: gemini, prompt-cache, cached-content, request, tools, wire-format
- Cross-links: ADR 0004, ADR 0018, ADR 0021, ADR 0024, ADR 0025
- karr: k340 (from k327)

## Context

`Engine::Gemini` can bind an explicit cache resource: `$engine->cached_content($cc)` with a
`Langertha::CachedContent` that has a `name` (karr #22). Every chat request then carries
`cachedContent => '{name}'` in the `generateContent` body, on both the plain and the streaming
route. A cache resource can itself hold a system instruction, tools and a tool configuration
(`Langertha::CachedContent` `system_instruction`, `tools`), set when it is created.

Gemini rejects a `generateContent` request that names a cache and also sets any of those three
fields. The server answers HTTP 400:

> CachedContent can not be used with GenerateContent request setting system_instruction, tools or
> tool_config. Proposed fix: move those values to CachedContent from GenerateContent request.

This comes from the observed server response, not from the documentation. The
`generate-content` reference only describes `cachedContent` as a plain resource-name string and
does not state the exclusion. Before k327 a Langertha engine with a bound cache still sent
whatever its `system_prompt`, a system message, `tools` or `tool_choice` produced, so any such
request failed. That includes every `chat_with_tools_f` iteration, which sends the tools each
turn.

The fix had to choose between four behaviours: send and let the 400 through, croak before the
request, merge the request values into the cache, or leave the fields out.

## Decision

While a cache is bound, the Gemini request builder leaves `systemInstruction`, `tools` and
`toolConfig` out of the body, and carps once per engine when it has dropped any of them.

1. **One helper on both routes.** `Engine::Gemini::_cached_content_reference($body, $extra)`
   sets `cachedContent` and removes the three fields. `chat_request` and `chat_stream_request`
   both call it, so the rule cannot hold on one route and not the other.
2. **Both JSON spellings are removed.** Each field is deleted as `systemInstruction` /
   `system_instruction`, `tools`, `toolConfig` / `tool_config`, from the built body and from the
   caller's `%extra`. An `%extra` passthrough (ADR 0004) therefore cannot put a field back.
3. **Drop and carp, not croak.** `_langertha_carp` with the once-key `cached_content_overrides`
   warns once per engine instance. The message lists only the fields that were actually set and
   names the cache. A request that sets none of the three stays silent. Without a bound cache,
   all three reach the wire unchanged.
4. **The cache is where those values go.** The engine POD tells the caller to put them into the
   cache when it is created. Langertha does not move request values into a cache and does not
   compare them with what the cache holds.

## Rationale

- **The cache owns these fields.** The server's own fix text says so: these values belong to
  the cache resource. Once a cache is bound, the request's copies can only be duplicates or
  conflicts. Dropping them restores the state the provider requires. The dropped value is
  already, or should already be, in the cache.
- **Drop + carp, not croak** (the ADR 0025 stance, against ADR 0021 / 0024). A croak would make
  a bound cache unusable with an engine that has a `system_prompt` or `tools` configured, and
  in particular with `chat_with_tools_f`. Nothing the caller can change per request fixes that,
  because the engine adds these fields itself. The ADR 0021 pair croaks because both fields
  carry essential intent and dropping either one loses half the request. Here the cache holds
  the intent. The carp covers the case where it does not (the cache was created without
  tools): the caller sees what was left out and where it should go.
- **No merge into the cache.** A cache's contents are fixed at creation, and writing to one is
  a lifecycle call (`update_cached_content_f`) with its own cost and TTL. Doing that implicitly
  from a chat request would be a hidden side effect on a server resource.
- **Engine-scoped, like ADR 0018's home 3.** Only Gemini's explicit cache has this constraint.
  The Anthropic and OpenAI prompt-cache controls (ADR 0009) mark or key a request. They do not
  bind a resource that owns part of it. So the rule lives in `Engine::Gemini` and not in a
  shared role or in `Langertha::PromptCache`.
- **Both spellings, per the normalize-don't-gatekeep rule.** Gemini's JSON accepts camelCase and
  the proto snake_case names. Deleting only one would let the other through to the same 400.

## Consequences

- **A bound cache overrides the engine's own `system_prompt`, a system message in `messages`,
  `tools` and `tool_choice`** for as long as it is bound. The caller sees this as one carp per
  engine, not per request. A later request that drops something different does not warn again.
- **`chat_with_tools_f` with a bound cache depends on the cache holding the tools.** The loop
  still reads calls from the response through `ToolCall->extract('gemini', …)` and still runs
  them against `mcp_servers`. But the declarations the model sees are the cache's, not the ones
  the loop sends. If the cache has no tools, the model gets no tools and the loop ends after one
  turn with a text answer. No test covers this path yet (see Future work).
- **Evidence grade: observed server text.** The documentation does not state the exclusion. If
  Gemini relaxes it (for example, by allowing a request `toolConfig` next to a cache), this rule
  is the place to narrow. The observed 400 text is kept in the `Engine::Gemini` comment and in
  `t/47_gemini_cached_content_wire.t`.
- **Verified offline** in `t/47_gemini_cached_content_wire.t`: none of the three fields are in
  the plain or the streaming body when a cache is bound, one carp names the fields and the cache,
  no carp when nothing was dropped, all three are sent when no cache is bound.
- **Cross-links.** **ADR 0004**: `%extra` is the outbound extras channel, and this rule removes
  keys from it as well as from the built body. **ADR 0018**: the engine-scoped tier and the
  both-spellings rule, applied to the request side. **ADR 0025**: the drop + carp precedent for a
  request field the wire rejects in a given state. **ADR 0021 / 0024**: the croak precedent,
  and why it does not apply here.

## Future work

- **A `chat_with_tools_f` test with a bound cache** (asked for on karr k340): the loop's tools
  are not sent, and calls the model returns from the cache's declarations are still extracted
  and executed. Not done here. This ADR records the decision only.
