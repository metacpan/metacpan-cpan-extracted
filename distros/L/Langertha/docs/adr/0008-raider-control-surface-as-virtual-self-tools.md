# ADR 0008 — Raider exposes its own control surface to the model as virtual self-tools

- Status: accepted
- Date: 2026-06-26
- Tags: raider, tools, self-tools, mcp, control-surface

## Context

An autonomous agent sometimes needs to do things only the *runtime* can do, not the model:
ask the user a question and wait, pause or abort, wait for a condition, query its own session
history, activate another MCP server from a catalog, or switch the underlying engine. The
model has to be able to trigger these from inside its reasoning loop.

There are two ways to give the model that handle:

- a **separate control channel** — special tokens or sentinel strings the tool loop sniffs
  for, with its own parser and its own failure modes, or
- **reuse of the existing tool-calling mechanism** the model already drives.

The framework already has a robust, provider-agnostic tool-calling seam (ADR 0001) whose
results land uniformly on `Response.tool_calls` (ADR 0003).

## Decision

The Raider's control surface is exposed as **virtual self-tools** — ordinary tool definitions
(name + `inputSchema`) injected into the same tool list the model already calls through, not a
separate channel.

1. **Self-tools are gated by `raider_mcp`** (`Raider.pm:371-388`, `_self_tool_enabled`
   `:948-955`): a truthy scalar enables all of them, a HashRef whitelists a subset. The
   surface is **closed by default** — with `raider_mcp` unset the Raider is a pure tool-runner
   with no self-control.

2. **Each self-tool is a normal tool definition** built by `_self_tool_definitions`
   (`Raider.pm:957+`) with an MCP-style camelCase `inputSchema`:
   `raider_ask_user`, `raider_pause`, `raider_abort`, `raider_wait`, `raider_wait_for`,
   `raider_session_history`, `raider_manage_mcps`, `raider_switch_engine`. They ride the same
   wire-translation (ADR 0001) as external tools and are parsed back as `Langertha::ToolCall`
   (ADR 0003) like any other call.

3. **Dispatch is by name to Perl handlers, not an MCP server.** In the loop, a call whose name
   matches a self-tool is routed to `_execute_self_tool` (`Raider.pm:1085+`) instead of an
   external MCP `call_tool`. User-facing self-tools fire callbacks (`on_ask_user`,
   `on_pause`, `on_wait_for`); `raider_session_history` reads the archive (ADR 0007);
   `raider_manage_mcps` activates/deactivates entries from the `mcp_catalog`;
   `raider_switch_engine` swaps the active engine via the `engine_catalog`.

4. **LLM-driven engine switching is opt-in, distinct from the programmatic lever.** The
   maintainer's `switch_engine` / `reset_engine` / `engine_info` API stays programmatic and is
   **not** model-controlled; `raider_switch_engine` is the model-facing path and exists only
   when that self-tool is enabled.

## Rationale

Reusing the tool-calling mechanism means the model controls *itself* with the exact same
affordance it already uses for *external* tools — there is no second protocol, no extra
parser, no new failure surface. Any engine that can call tools at all, native or Hermes, can
drive the control surface for free, because it inherits ADR 0001's seam and ADR 0003's uniform
result shape. A separate control channel would have re-implemented tool parsing for a second
purpose and coupled the loop to provider-specific sentinel formats.

Gating by `raider_mcp` keeps the principle of least authority: an agent gains the power to
pause, question the user, reconfigure its tools, or change its own engine only when the
operator opts in, and can be handed a narrow subset rather than the whole surface.

## Consequences

- Adding a control affordance = add a self-tool definition plus a handler branch in
  `_execute_self_tool`; the loop and the wire protocol are untouched.
- A Raider with `raider_mcp` unset behaves as a plain multi-turn tool-runner — no self-control
  is reachable by the model.
- Runtime reconfiguration (which MCP servers are active, which engine is in use) is itself
  performed *as a tool call*, so it is visible in the session archive (ADR 0007) and metered
  like any other call.
- Cross-links: ADR 0001 (the tool-calling seam self-tools ride), ADR 0003 (self-tool calls
  land on `Response.tool_calls`), ADR 0007 (`raider_session_history` reads the never-compressed
  archive).
