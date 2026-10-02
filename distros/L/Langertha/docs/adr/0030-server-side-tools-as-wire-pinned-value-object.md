# ADR 0030 — Server-side tools are a wire-pinned value object (`Langertha::ServerTool`), recorded apart from `tool_calls`

- Status: accepted
- Date: 2026-09-25
- Tags: tools, value-objects, wire-format, capabilities, responses, citations
- Cross-links: ADR 0001, ADR 0002, ADR 0003, ADR 0004, ADR 0010, ADR 0018, ADR 0020, ADR 0029, CONTEXT.md
- karr: #206

## Context

Providers run some tools themselves during a single request: web search, file search, a code
interpreter, image generation, remote MCP. OpenAI offers them on `/v1/responses`; xAI offers
them *only* there (its chat/completions endpoint is "function calling only"). Langertha had no
seam for them. Since k210, `Tool->from_hash` / `format_list` croak on them ("not supported
yet"), and the Responses envelope passed a recognized server tool through verbatim without a
capability check. Inbound, nothing recorded what the provider ran: `ToolCall->locate` already
skipped `web_search_call` and friends, but their items, the answer's `url_citation`
annotations and the approval requests were dropped. A client-actionable item such as
`mcp_approval_request` was skipped too, so a tool loop ended as if the model were done.

Design spec: `docs/superpowers/specs/2026-09-25-server-side-tools-design.md` (option (b),
accepted by the orchestrator, red-teamed by the llm-advisor). Three OpenAI captures
(`t/data/responses_web_search*.json`, gpt-5.6-luna) pin the wire.

## Decision

1. **`Langertha::ServerTool` is the fifth member of the tool value-object family**, keyed by
   `tool_wire_format` like `Tool` / `ToolCall` / `ToolResult` / `ToolChoice` (ADR 0001/0010).
   It carries the provider-native hash (`spec`) verbatim, pinned to its `wire`. `to($fmt)`
   returns a copy of the hash on its own wire and **croaks on every other wire**: a server tool
   is a provider contract, not a translatable definition (`web_search`,
   `web_search_20250305` and `google_search` are three different things). Rejected: a kind
   flag on `Langertha::Tool` (it would put a branch plus a croak into every `to_*`,
   `to_json_schema` and `to_hash`, and soften `name` / `input_schema` for every consumer), and
   a raw escape hatch (the open bucket ADR 0004 rejects).

2. **Recognition reuses `Tool->classify`** (k210), the one classifier. `ServerTool->from_hash
   ($fmt, $hash)` is format-pinned, never sniffs, never croaks, and returns an object only for
   a hash `classify($hash, $fmt)` calls `server`. The constructor refuses function, `custom`
   and `namespace` tools, client-executed built-ins and a built-in of another wire. A type the
   table does not list yet can be vouched for with `unlisted => 1`; that never turns a client
   tool into a server tool. Phase 1a supports the `responses` wire only; Anthropic and Gemini
   croak "not supported yet".

3. **`Tool->format_list($fmt, …)` keeps a server tool of `$fmt` in place** (object → `to`,
   recognized hash → its spec). Everything else still goes through the k210 door, so a server
   tool of another wire, a client-executed built-in or an unknown type still croaks there.
   `Tool->from_hash` stays function-only and refuses a `ServerTool` object. `format_list` sees
   no engine, so it never runs an engine hook; that is why the one rule every Responses
   provider needs at emission (decision 5) lives in `ServerTool->to`. Deviation from spec
   §3.7: the envelope did *not* switch to `format_list('responses', …)`. It keeps its own
   per-item step, because it must stay values-open for unknown typed items, which
   `format_list` (k210) croaks on. So there are two partitioners; both route server tools
   through `ServerTool->to`.

4. **Capability: one flag, `server_tools`**, from the new capability role
   `Langertha::Role::ServerTools` (ADR 0002; ADR 0016: a capability role is a role from day
   one). It means *the wire accepts provider-native server-side entries in `tools`* — not which
   types. The role also carries the engine attribute `server_tools` (defaults appended to every
   request, so `simple_chat` and `chat_with_tools_f` send them without changes) and the hook
   `_server_tool_wire_check($server_tool) → $spec`. A default must be a server tool (a
   `ServerTool`, or a hash `ServerTool->from_hash` recognizes); a bare string, a function tool
   or an unlisted type croaks when the request is built, unlike a request's own tools, which
   stay values-open. **The request wins:** a default is left out when the request already
   carries a server tool of the same kind (same `type`; for `mcp`, also the same
   `server_label`), so one tool is never sent twice. It does not require `Role::Tools`.
   Composed into `Engine::OpenAIResponses` only. The manifest Builder publishes the flag per
   model (ADR 0029 Update k206).

5. **Remote MCP approval is checked in the value object; other provider divergence goes
   through the engine hook.** `ServerTool->to('responses')` croaks on an `mcp` tool unless
   `require_approval` is the plain string `'never'` — OpenAI defaults to `"always"` and there
   is no approval flow (orchestrator ruling Q2). The spec (and advisor must-change 2) put this
   rule in an engine hook because xAI does not support the field; review M3 showed that
   `Tool->format_list`, which sees no engine, would skip a hook, so the orchestrator moved it
   to the one door every emission passes, enforced once. The price: an xAI user must also
   write `'never'`, and `XAIResponses::_server_tool_wire_check` (Phase 1b) strips
   `require_approval` / `connector_id` afterwards. The hook stays the place for such
   provider divergence, mirroring ADR 0020's divergence hooks.

6. **Fail loud before the request.** In `Role::ResponsesCompatible` a server tool on an engine
   without `supports('server_tools')` is left on today's path (verbatim hash), but a
   `ServerTool` *object* croaks; `chat_f` and `chat_stream_realtime_f` call
   `ServerTool->check_engine` so a `ServerTool` never reaches a wire that cannot take it.
   Plain provider-shaped hashes on other engines keep their existing verbatim path (deliberate
   keep, spec §3.1(c)).

7. **Inbound: server calls are recorded apart from `tool_calls`.** `Response.server_tool_calls`
   (`ArrayRef[Langertha::ServerToolCall]`, `Maybe`, predicate, survives `clone_with`; ADR 0004)
   holds one thin record per provider-executed call item (`type`, `id`, `status`, `data` =
   the item verbatim). No cross-provider normalization of inputs or results. `tool_calls`
   keeps its one meaning, "calls the client must act on" (ADR 0003 Update k206), so
   `chat_with_tools_f` executes only function calls; its `responses` echo already sends every
   `output[]` item back unchanged, which the capture shows OpenAI accepts.

8. **Inbound fail-loud guard.** A Responses output item the client must answer and Langertha
   does not map — `custom_tool_call`, `computer_call`, `local_shell_call`, `apply_patch_call`,
   `mcp_approval_request`, `tool_search_call` with `execution: "client"` — croaks in both
   inbound doors: the `ResponsesCompatible` output walker (reply and stream final chunk) and
   `ToolCall->locate('responses')` (the tool loop). The table lives in `Tool.pm` next to the
   outbound client-built-in denylist, so both directions name the same families. Unknown item
   types are still skipped (values open; they stay on `raw`).

9. **Citations merge, never "the hook wins".** The walker lifts `url_citation` annotations of
   `output_text` blocks as `{ url, title?, start_index?, end_index? }` (dialect layer, ADR 0018
   level 2). They are merged with any `citations` from `_responses_extra_fields` (Perplexity):
   hook entries first, then annotations, one entry per page; the first entry wins and a later
   duplicate only fills fields it lacks. Without annotations the hook's list is returned as
   is, so Perplexity is unchanged.
   **Dedup key:** the `url` with every `utm_*` query parameter removed. OpenAI's citation url
   carries `?utm_source=openai`, and its search sources list the same page both with and
   without it; a tracking parameter must not make one page two citations, while any other
   query parameter (`?page=2`) still distinguishes pages. The stored url is never rewritten
   (normalize, don't gatekeep). Search sources (`web_search_call.action.sources`) are *not*
   citations — they are what was consulted, not what the answer cites — and stay on the
   server call's `data`.

10. **`max_output_tokens` only where `supports('response_size')`**, in the shared
    `ResponsesCompatible` body builder (orchestrator ruling Q2). A no-op for every shipped
    engine; it lets a model whose wire rejects the field (xAI `grok-4.20-multi-agent`, Phase
    1b) clear the flag and stop sending it.

## Rationale

The value-object seam already answers "how does a tool reach wire X": the engine declares one
tag and the value objects own the shapes. A server tool fits that seam as a value object that
has exactly one wire. Pinning it (rather than translating it) is the honest encoding of the
provider reality, and croaking on another wire turns a silent 400 or a silently dropped tool
into an immediate, explained error. Keeping provider-executed calls off `tool_calls` protects
the one invariant every tool loop depends on — each entry is something the client can run —
without inventing a second tool-call representation: a `ServerToolCall` is a record of what
happened, not an instruction. The guard exists because a known client-actionable item that is
silently skipped is indistinguishable from "the model finished", which is the worst failure a
loop can have.

## Consequences

- A new server-tool wire is: a row in `Tool`'s classifier table, the wire in
  `ServerTool`'s supported set, an extractor in `ServerToolCall`, and (if the provider
  diverges) an engine `_server_tool_wire_check`.
- `Response.to_hash` does not include `server_tool_calls` (bounded shape, like `citations`);
  read the attribute.
- `Stream::Chunk` carries no `server_tool_calls` yet; the stream's final chunk gets the merged
  citations only. No shipped engine streams Responses server tools yet.
- The manifest says *that* a model takes server tools, not *which* types (ADR 0029 Update).
- Echo turns send the MCP tool result as `ToolResult->to('responses')` encodes it (the MCP
  content array as JSON text), not as the bare JSON string the capture's hand-written request
  used; OpenAI takes any string there.

## Future work

- **Phase 1b (xAI):** `Engine::XAIResponses` on this seam, blocked on an xAI key for the
  captures — listed on karr #206.
- **Phase 2:** Anthropic (`server_tool_use` / `*_tool_result`, `pause_turn`, the MCP
  connector, `allowed_callers`) and Gemini (sibling `tools[]` entries,
  `includeServerSideToolInvocations`, `groundingMetadata`).
- `model_capability_exclusions` gains `has_server_tools` when a provider rejects a combination
  (Phase 2, Gemini).
