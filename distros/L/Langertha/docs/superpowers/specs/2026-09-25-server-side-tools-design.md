# Design Spec — Provider server-side tools (`Langertha::ServerTool`) and `Engine::XAIResponses` (karr k206)

- Status: **proposed, revision 2** (spec only, nothing implemented). Option (b) was accepted
  by the orchestrator on 2026-09-25. The llm-advisor red-team verdict was "safe with
  changes", and those changes are folded in here.
- Date: 2026-09-25
- karr: k206 (this). Prerequisite **k212** (Responses stream parser drops tool calls and
  `response.failed`). Related: k208 (grok `Reasoning::Profile` row, parallel branch), k205
  (XAI default model, parallel branch), k213 (Perplexity Agent API now has tools, docs drift).
- ADRs read: **0001**, **0002**, **0003**, **0004**, **0005**, **0010**, **0016**, **0018**,
  **0019**, **0020**, **0024**, **0029**, `CONTEXT.md`
- ADRs touched when implemented: a new ADR (take the next free number and **re-check it at
  merge**, because parallel branches allocate numbers independently), an `## Update` on
  **0003** and on **0029**, and new terms in `CONTEXT.md`.
- Provider facts come from the two llm-advisor notes on k206 (both 2026-09-25, docs only, no
  live call) and from the current code. A fact the docs cannot settle is marked
  **[capture]**: it is decided by the Phase 1 captures (§6), not by another docs read.

## 1. Problem

Langertha has no seam for tools the provider executes itself during one request: web
search, X search, code interpreter, file/collection search and remote MCP. xAI offers these
**only** on `/v1/responses`. Its Chat Completions endpoint is "function calling only", and
Live Search `search_parameters` has answered HTTP 410 since 2026-01-12. So an
`Engine::XAIResponses` without this seam would give users nothing that `Engine::XAI` doesn't
already give them. `OpenAIResponses` users lack OpenAI's hosted tools for the same reason.

What the code does today, checked in the k206 worktree:

| Input | Path | Result |
|---|---|---|
| `{type=>'web_search'}` | `Tool->from_hash` → `from_anthropic` | `undef`, so `from_list`/`format_list` **silently drop** it |
| `{type=>'web_search_20250305', name=>'web_search'}` (Anthropic shape) | `Tool->from_hash` → `from_anthropic` | a **user function tool** named `web_search` with an empty schema. The server-tool `type` is lost, which silently corrupts the request |
| `chat_f(tools=>[{type=>'web_search'}, $mcp_tool])` on `OpenAIResponses` | `ResponsesCompatible::chat_request` formats the list only when `$tools[0]` has no `type` | the whole list goes out **verbatim**, so the MCP-shaped tool reaches the wire unformatted (400) |
| `chat_f(tools=>[$mcp_tool, {type=>'web_search'}])` on `OpenAIResponses` | same heuristic, and the first item has no `type` | `format_list` runs and web_search is **silently dropped** |
| `chat_f(tools=>[{type=>…}])` on `OpenAI` / `Anthropic` / `Gemini` | these `chat_request`s pass `tools` through verbatim | the list reaches the wire as written, so a raw escape hatch already exists on `chat_f` by accident |
| `chat_with_tools_f` | tools come only from `mcp_servers` → `format_tools` | there is no way to add a server tool at all |

Inbound, nothing crashes today, but a lot is lost:

- `ToolCall->locate` matches only `function_call` / `tool_use` / `functionCall`. Server-side
  call items are therefore already kept out of `Response.tool_calls`, which is correct
  (§3.2).
- Their results, the `url_citation` annotations and the server-tool usage are dropped. The
  one exception is Perplexity's `search_results`, which its `_responses_extra_fields` lifts
  into `Response.citations`.
- **Client-actionable** output items that the walker does not map are dropped silently too:
  `custom_tool_call`, `computer_call`, `local_shell_call`, `apply_patch_call`, a client
  `tool_search_call` and `mcp_approval_request`. A tool loop then ends as if the model had
  finished, which is wrong (§3.3).

Two side findings, both fixed in Phase 1:

- **Autovivification.** `ResponsesCompatible::chat_response` reads `$item->{summary}[0]{text}`
  as a chained rvalue. A `reasoning` item with `summary => []`, or with no `summary` at all,
  gets `summary => [{}]` written into `raw` (checked with perl). This is the same bug class
  as k168. xAI hits it on every reasoning reply, because grok-4.7 always returns
  `encrypted_content` with no summary.
- **Usage extras.** The usage normalization drops xAI's `server_side_tool_usage_details`,
  `num_server_side_tools_used` and `cost_in_usd_ticks` (§4.1).

## 2. Inventory

"Built-in" does not mean "server-side". Several built-in tool types are executed by the
**client**. This spec treats as server tools only the ones the provider executes, which is
decided by type **and** by the `execution` / `environment` fields (§3.4).

### 2.1 OpenAI Responses (`/v1/responses`, `tool_wire_format` `responses`)

- **Request.** Built-in tools are entries in the same `tools` array as function tools,
  discriminated by `type`. The ones the provider executes:

  | `type` | Example / notes |
  |---|---|
  | `web_search` | earlier spelled `web_search_preview` |
  | `file_search` | `vector_store_ids:[…]` |
  | `code_interpreter` | `container:{…}` |
  | `image_generation` | |
  | `mcp` | remote MCP: `server_label`, `server_url`, `require_approval` |
  | `tool_search` | only with `execution` ≠ `client` |
  | `shell` | only with `environment` `container_auto` / `container_reference` |

  Client-executed, per the OpenAI create-response reference (advisor):

  | `type` | Answered with |
  |---|---|
  | `custom` | a user tool, answered with `custom_tool_call_output` |
  | `namespace` | |
  | `tool_search` | when `execution:"client"` |
  | `shell` | when `environment` is local |
  | `local_shell` | |
  | `computer`, `computer_use_preview` | |
  | `apply_patch` | |

  `programmatic_tool_calling` is new, and its classification is **[capture]**. It is not a
  Phase 1 server tool; §3.4 treats it as unknown.
- **`require_approval` defaults to `"always"`** (advisor). An `mcp` tool without it
  therefore produces an `mcp_approval_request` that needs a client round-trip.
- **Response.** Typed `output[]` items sit next to `message` / `function_call`:

  | Kind | Item types |
  |---|---|
  | server calls | `web_search_call`, `file_search_call`, `code_interpreter_call`, `image_generation_call`, `mcp_list_tools`, `mcp_call`, hosted `shell_call` / `tool_search_call` |
  | client-actionable | `custom_tool_call`, `computer_call`, `local_shell_call`, `apply_patch_call`, client `tool_search_call`, `mcp_approval_request` |

  Citations are `output_text.annotations[]` entries of `type:"url_citation"` (`url`,
  `title`, `start_index`, `end_index`), plus `file_citation`.
- Server items may be **echoed** back in `input` on the next turn; the advisor confirmed
  both OpenAI and xAI accept this.

### 2.2 xAI Responses (`https://api.x.ai/v1/responses`)

Advisor notes, 2026-09-25:

- **Responses-only features:**
  - server-side agentic tools: `web_search`, `x_search`, `code_interpreter`,
    collections/`file_search`, remote `mcp`;
  - `grok-4.20-multi-agent`;
  - `previous_response_id` / `store`;
  - `max_turns`;
  - the encrypted-reasoning round-trip;
  - citations / annotations;
  - reasoning-summary stream events.
- **Not Responses-only:** `reasoning_effort`, `prompt_cache_key`, json_schema, function
  tools, streaming and `reasoning_content`. Users who only need function tools keep
  `Engine::XAI`.
- **MCP:** `require_approval` and `connector_id` are "not currently supported" (xAI docs).
  Langertha must not send them (§3.5).
- **Citations:** the xAI REST reference has **no top-level `citations` field**. That field
  exists in the xAI SDK (gRPC). On `/v1/responses`, citations are `output_text.annotations`
  entries of type `url_citation`, and their **`title` is the citation number** (`"1"`), not
  the page title. Confirm by **[capture]**.
- **Encrypted reasoning:** the xAI stateless-loop docs send
  `include: ["reasoning.encrypted_content"]` on every turn. grok-4.7 returns it regardless;
  older grok models return it only when asked.
- **Usage extras:** `usage.server_side_tool_usage_details`, `num_server_side_tools_used` and
  `cost_in_usd_ticks`.
- **Billing:** X Search has been billed per post and per profile fetched since 2026-09-21
  ($5 per 1k posts, $10 per 1k profiles), in addition to token costs.
- **`grok-4.20-multi-agent` limitations:** no client function tools and no `max_tokens`
  (docs, multi-agent Limitations).
- **Request/response item shapes:** the same Open-Responses `tools[]` and `output[]` shapes
  as §2.1. The exact server-call item type names xAI emits are **[capture]**. The output
  walker already skips unknown item types.

### 2.3 Anthropic Messages (`tool_wire_format` `anthropic`), Phase 2

- **Request.** Server tools are entries in `tools[]` with a dated `type` plus a fixed
  `name`, for example `{type:"web_search_20250305", name:"web_search", max_uses,
  allowed_domains, …}`, `web_fetch_…` and `code_execution_…`.
  - **Catch:** newer `web_search` / `web_fetch` versions default `allowed_callers` to
    `code_execution`. On models without programmatic tool calling that is a 400 unless the
    tool entry sets `allowed_callers: ["direct"]`.
  - The Anthropic-defined **client** tools (`bash_…`, `text_editor_…`, `computer_…`,
    `memory_…`) use the same dated-`type` shape but come back as ordinary `tool_use` blocks.
- **Response.** The reply carries:
  - `server_tool_use` blocks (`id`, `name`, `input`);
  - result blocks (`web_search_tool_result`, `code_execution_tool_result`, …) with
    `tool_use_id`;
  - `text` blocks carrying `citations[]` (`web_search_result_location`);
  - `usage.server_tool_use.web_search_requests`;
  - `stop_reason:"pause_turn"`, which means the turn must be re-sent to continue.
- **MCP connector.** It is an `mcp_toolset` entry in `tools` **plus** a top-level
  `mcp_servers` body field **plus** the header `anthropic-beta: mcp-client-2025-11-20`.
  - The top-level field has the same name as Langertha's `mcp_servers` attribute, which is
    client-side MCP and means something else.
  - Supporting it needs a header hook, and the ADR 0004 `%extra` route has to get past that
    name collision.

### 2.4 Gemini (`tool_wire_format` `gemini`), Phase 2

- **Request.** Server tools are sibling entries in `tools[]` next to the one
  `{functionDeclarations:[…]}` entry: `{google_search:{}}`, `{code_execution:{}}`,
  `{url_context:{}}`, …
- **Combining built-ins with `functionDeclarations` works on Gemini 3 only**, and it needs
  `toolConfig.includeServerSideToolInvocations: true`. The reply then carries
  `toolCall` / `toolResponse` parts with a `thoughtSignature`. That makes it a **companion
  request flag**, not only a model-scoped exclusion (§4).
- **Response.** `candidates[0].groundingMetadata` (`webSearchQueries`,
  `groundingChunks[].web.{uri,title}`, `groundingSupports`). Code execution produces
  `executableCode` / `codeExecutionResult` parts.

### 2.5 Perplexity Agent API (`/v1/agent`)

The Agent API now accepts explicit tools, both function and built-in (advisor). The docs
drift is filed as **k213**. Search is implicit in the preset, and its results already reach
`Response.citations` via `search_results`. Perplexity composes no `Role::Tools` (ADR
0005/0010), so the seam below must not depend on `Role::Tools`. Perplexity adopts the seam
under k213, not in this ticket.

### 2.6 Out of scope, named so nobody assumes coverage

- Groq "compound" models (server tools on `chat/completions`, `executed_tools` in the
  message).
- OpenRouter `plugins` / `:online`.
- Mistral Agents / Conversations connectors.
- OpenAI Chat Completions `web_search_options`.

All four are body fields, not `tools[]` entries. They already fit ADR 0004's top-level
`%extra` and need no seam.

## 3. The value-object seam

### 3.1 Options

**(a) A kind flag on `Langertha::Tool`.** Rejected.

- A `Tool` is the canonical definition that every wire can translate: `to($fmt)` covers all
  of `%TO_METHOD`.
- A server tool cannot be translated. `web_search`, `web_search_20250305` and
  `google_search` are three different contracts.
- A kind flag would add a branch plus a croak to `to`, `to_json_schema` (the ADR 0005
  forced-tool rewrite), `to_mcp`/hermes and `to_hash`.
- It would soften `name`/`input_schema` for every consumer, including sibling
  distributions.

**(b) A separate `Langertha::ServerTool` value object.** Accepted.

- It becomes the fifth member of the tool value-object family and is keyed by the same
  `tool_wire_format` (ADR 0001/0010).
- Its `to($fmt)` returns the native spec on its own wire and croaks on any other wire.
- Recognition is **format-pinned** (`from_hash($fmt, $hash)`), like
  `ToolCall->extract($fmt, …)`, and never sniffed.

**(c) A raw escape hatch.** Rejected as the design.

- It is the open-bucket shape that ADR 0004 rejects.
- It gives no capability check, no fail-loud, no mixed lists and nothing for
  `chat_with_tools_f`.
- The accidental verbatim `tools` path on `chat_f` for OpenAI, Anthropic and Gemini stays as
  it is. Removing it would break callers who pass provider-shaped tools today, so this is a
  deliberate keep.

### 3.2 ADR 0003: server-side calls do not go on `Response.tool_calls`

`tool_calls` has one operational meaning, "calls the client must act on":

- `chat_with_tools_f` dispatches each call to `mcp_servers` by name, and dies with
  "Tool '…' not found" on a miss.
- Raider does the same.
- `chat_f` callers act on them.

`synthetic` records provenance. It does not mean "don't execute".

Consequences:

1. **Inbound invariant (tested):** `ToolCall->locate($fmt, …)` never returns a
   server-side call item.
2. **New attribute `Response.server_tool_calls`** (ADR 0004: first-class, `Maybe`-typed,
   predicate `has_server_tool_calls`, listed in `clone_with`), typed
   `ArrayRef[Langertha::ServerToolCall]`.
   - A `ServerToolCall` is a thin immutable record: `type` (the wire item type), `id`,
     `status` (optional) and `data` (the item verbatim), plus `to_hash`/`TO_JSON`.
   - Phase 1 does not normalize inputs/outputs across providers. That would be the
     invented-value trap of ADR 0023.
3. **Citations** go to the existing `Response.citations` (§3.6).
4. **ADR 0003 gets an `## Update (k206)`:** `tool_calls` means calls the client must act
   on. Provider-executed activity is recorded on `server_tool_calls`, and that is not a
   second tool-call representation.

### 3.3 `chat_with_tools_f` and the inbound guard

- **The loop itself** does not change.
  - It sees only `ToolCall->locate` output, so server items never reach `call_tool`.
  - The `responses` / `anthropic` / `gemini` branches of `format_tool_results` echo the
    whole `output[]` / `content` / `parts`, so server items travel in the assistant echo.
    Both providers accept that echo.
  - A turn with only server activity plus final text returns that text.
- **Inbound fail-loud guard** (new, Responses walker, dialect layer). When `output[]`
  contains a **client-actionable** item type that Langertha does not map to `tool_calls`,
  `chat_response` **croaks** with the item type and a pointer.
  - The item types: `custom_tool_call`, `computer_call`, `local_shell_call`,
    `apply_patch_call`, a `tool_search_call` whose `execution` is `client`, and
    `mcp_approval_request`.
  - Without the guard, the loop silently ends as if the model were done, and a `chat_f`
    caller never learns that the model is waiting.
  - "Values open" (§3.4) covers only *outbound* types we don't know. A known item type the
    client must answer is never swallowed.
  - The list lives next to the outbound denylist, so both directions name the same
    client-executed families.
  - Unknown item types keep being skipped. They are observable on `raw`, and skipping them
    stays the values-open default.
- **Anthropic `pause_turn`** is the one loop behavior change, and it lands in Phase 2 (§6).

### 3.4 Recognizing a server tool (outbound)

The recognizer is an **explicit allowlist per wire**. It checks the known server-executed
types together with their execution predicates, and it never reasons "anything that is not
a function".

- **`responses`**, in the order the rules are applied:
  - `custom`, `namespace`, `function` → **never** a ServerTool. They are client tools and go
    to `Tool` (function) or keep today's verbatim path (custom, namespace).
  - Known client-executed built-ins → croak with "client-executed built-in; not a server
    tool" (orchestrator ruling on Q3). These are `local_shell`, `computer`,
    `computer_use_preview`, `apply_patch`, `shell` with a non-container `environment`, and
    `tool_search` with `execution:"client"`.
  - Server-executed → ServerTool:

    | `type` | Condition |
    |---|---|
    | `web_search`, `web_search_preview`, `file_search`, `code_interpreter`, `image_generation`, `mcp` | none |
    | `x_search` | xAI |
    | `shell` | `environment.type` ∈ {`container_auto`, `container_reference`} |
    | `tool_search` | `execution` ≠ `client` |
  - Anything else → **not** recognized. `from_hash` returns `undef`, and the item keeps
    today's verbatim passthrough on `chat_f`, where the provider gets to judge it (values
    open).
  - A caller who is sure about a new server type wraps it explicitly:
    `ServerTool->new(wire => 'responses', spec => {…}, force => 1)`. The name of that flag
    is an open detail for the implementer; `force` is a placeholder.
- **`anthropic` / `gemini`:** Phase 2, with the same structure.
- The **allowlist and denylist** are data tables in `ServerTool`. Extending either is a
  one-line change plus a test. Rows need a provider-docs source; the advisor supplies it.

### 3.5 Remote MCP: the approval check is an engine hook

OpenAI and xAI both use the `responses` tag but disagree on `require_approval`. The rule
therefore cannot live in `ServerTool->to('responses')`. The design:

- `Role::ServerTools` calls a hook named
  `_server_tool_wire_check($server_tool) → $spec`. The name is a proposal. The hook runs
  once per ServerTool when the request is built, and it can croak or rewrite the spec.
  The default returns the spec unchanged.
- **`OpenAIResponses`** override: when an `mcp` tool has `require_approval` absent (which
  the wire defaults to `"always"`) or set to anything other than the string `'never'`, it
  croaks: "remote MCP needs require_approval => 'never'; approval flow not supported". This
  is the orchestrator's ruling on Q2. An approval hook can be added later without breaking
  anything.
- **`XAIResponses`** override: `require_approval` and `connector_id` are not supported, so
  the override **deletes them** from the spec it sends. It carps when a caller set
  `require_approval` to something other than `'never'`, because xAI never asks for
  approval and the caller's intent can't be honored.
- This mirrors ADR 0020's divergence hooks. The envelope is shared, and the provider
  differences sit in overridable methods on the engine.

### 3.6 Citations: merge and dedup, never "the hook wins"

- **Sources:**
  - the Responses walker collects `output_text.annotations[]` entries of type
    `url_citation` (dialect layer, ADR 0018 level 2);
  - `_responses_extra_fields` may also return a `citations` key. Perplexity does this with
    `search_results`.
- **Merge:** the two lists are **concatenated and deduplicated by `url`**, keeping
  first-seen order, with the hook's entries first. Where the same `url` appears twice,
  fields are filled in from the second entry without overwriting what is already there.
  This keeps Perplexity's output unchanged when its payload has no annotations.
- **Normalized entry:** `{ url, title?, snippet?, start_index?, end_index? }`.
- **The xAI title rule:** an annotation `title` that is purely numeric is the citation
  **number**, not a page title. It is dropped from `title`, and nothing is invented to
  replace it. This is implemented as an `XAIResponses` override of a small hook
  (`_citation_from_annotation`), not as a global rule, because an OpenAI page title could
  legitimately be a number. The xAI shape is to be confirmed by **[capture]**.
- The final stream chunk uses the same merge (the existing k158 path).

### 3.7 How users hand server tools over

- **Per request.** `chat_f(tools => [ … ])` accepts a mix of MCP hashes, provider-shaped
  function hashes, `Langertha::Tool` objects, `Langertha::ServerTool` objects and
  recognized server-tool hashes. `Tool->format_list($fmt, …)` sorts each item:
  - a `ServerTool` object → `->to($fmt)`;
  - `ServerTool->from_hash($fmt, $h)` recognizes it → its spec;
  - `custom` / `namespace` / an unrecognized `type` → verbatim;
  - otherwise → `Tool->from_hash` → `to($fmt)`.

  This replaces the `$tools[0]` heuristic in `ResponsesCompatible` and fixes both
  mixed-list failures from §1. It also fixes the chat-completions-shaped
  `{type:function, function:{…}}` hash, which is currently sent unchanged to the flat-tool
  wire.
- **Per engine.** A new capability role `Langertha::Role::ServerTools` (ADR 0016: a
  capability role is a role from day one) adds the attribute `server_tools`, an ArrayRef
  with `default => sub { [] }`.
  - The envelope's `chat_request` and `chat_stream_request` append these tools to every
    request, which covers `simple_chat` and `chat_with_tools_f` without changing either.
  - The role does **not** require `Role::Tools`, which leaves room for Perplexity (k213).
- **Fail loud.**
  - A `ServerTool` given to an engine without `supports('server_tools')` croaks in
    `chat_f` / the envelope before the request is sent.
  - A `ServerTool` whose `wire` differs from the engine's `tool_wire_format` croaks in `to`.
- **Phase 1 surface:** provider-native only, with no portable constructors (orchestrator
  ruling on Q1). Portable constructors can be added later without breaking anything.

## 4. Capability registry (ADR 0002) and manifest (ADR 0029)

- **One flag, `server_tools`**, contributed by `Role::ServerTools` through `%ROLE_TO_CAPS`.
  It means *the wire accepts provider-native server-side tool entries in `tools`*. Per-tool
  flags are rejected, because they would need a closed and fast-drifting vocabulary.
  `t/78_capability_registry.t` sees the role in the map.
- **Layer 3 (ADR 0019): `grok-4.20-multi-agent` on `XAIResponses`** clears `tools_native`,
  `tool_choice_auto/any/none/named` and `response_size`. The docs say the model has no
  client function tools and no `max_tokens`. `server_tools` stays set: the model's purpose
  is agentic server tools.
  - Whether the model takes `tool_choice` for server tools is **[capture]**, so the
    `tool_choice_*` flags stay cleared until then.
  - Clearing `response_size` must also stop `max_output_tokens` from being emitted. Today
    `chat_request` emits it from `get_response_size` without checking the capability.
    Phase 1 therefore gates it on `supports('response_size')` inside the
    `ResponsesCompatible` body builder. That is a behavior change for every Responses
    consumer, but a no-op for engines that have the flag.
- **Pairwise conflicts** (ADR 0024) go through `model_capability_exclusions`, which gains a
  `has_server_tools` argument. That is a Phase 2 change to the signature. Gemini's
  combination rule is a companion flag *and* an exclusion (§2.4).
- **Manifest (ADR 0029):**
  - Add `server_tools` to `@MODEL_CAPABILITIES`. The value is evaluated per model, so the
    multi-agent correction applies.
  - Known v1 limitation: the manifest says *that* server tools are accepted, not *which*
    types.
  - Record both as an `## Update (k206)` on 0029.
- **Builder dialect:** `XAIResponses` isa `XAI` isa `OpenAIBase`, so `@DIALECT_BY_CLASS`
  would call it `openai-chat`. Add `[ 'Langertha::Engine::XAIResponses' => 'responses' ]`
  above the `OpenAIBase` row. Keying the row on "composes `Role::ResponsesCompatible`"
  would be more general, but that is a small Builder decision the implementer flags rather
  than makes silently.

### 4.1 Usage and cost extensions (ADR 0004)

- `ResponsesCompatible::chat_response` rebuilds usage from an allowlist, and xAI's extras
  are lost. Carry `server_side_tool_usage_details`, `num_server_side_tools_used` and
  `cost_in_usd_ticks` through the normalized usage hash verbatim, the same way
  `input_tokens_details` and `cost` ride along today, including on the stream's final
  chunk.
- **Typed accessors** are a separate decision:
  - `Langertha::Usage` gets `server_tool_calls_count` (from `num_server_side_tools_used`)
    and `cost_usd`;
  - `cost_usd` is `cost_in_usd_ticks / 1e10`, **[capture]** for the tick unit — confirm it
    against the capture before converting anything;
  - until the unit is confirmed, only the raw pass-through ships. A wrong conversion is
    worse than none.
- Anthropic `usage.server_tool_use.*` joins the same accessors in Phase 2.

## 5. `Engine::XAIResponses`

```perl
package Langertha::Engine::XAIResponses;
# ABSTRACT: xAI Grok via the Responses API (server-side tools, multi-agent)
use Moose;
extends 'Langertha::Engine::XAI';
with 'Langertha::Role::ResponsesCompatible', 'Langertha::Role::ServerTools';
sub _build_supported_operations { [qw( createResponse )] }
sub model_capability_corrections { ... }   # grok-4.20-multi-agent, §4
sub _server_tool_wire_check      { ... }   # strip require_approval / connector_id, §3.5
sub _citation_from_annotation    { ... }   # numeric title is the citation number, §3.6
# chat_request / chat_stream_request: add include => ['reasoning.encrypted_content']
__PACKAGE__->meta->make_immutable;
```

- **Inherited from `XAI`:** the URL `https://api.x.ai/v1`, `LANGERTHA_XAI_API_KEY`, Bearer
  auth, the default model and `/models`. This is the same shape as `OpenAIResponses` on
  `OpenAI`. Because `ResponsesCompatible` sits on the subclass, its `_build_*_wire_format`
  (→ `responses`) and its `chat_request` / `chat_response` override the inherited ones.
- **ADR 0020 hooks:**
  - `_responses_model_kwargs`, `_responses_format_kwargs` (`text.format`),
    `_normalize_input_item` and `_responses_extra_fields` keep their defaults. Citations
    now come from annotations (§3.6), so no top-level lift is needed.
  - `_responses_dispatch` keeps its default `createResponse`. That requires
    `supported_operations` to be `createResponse`, because `XAI` restricts it to
    `createChatCompletion`.
- **`include: ["reasoning.encrypted_content"]` on every request.** It is sent as a
  top-level kwarg (ADR 0004), and a caller-supplied `include` is merged in rather than
  overwritten.
  - The `responses` assistant echo already carries the reasoning item back, so a stateless
    tool loop keeps its reasoning.
  - The `summary` autovivification fix (§1) ensures that an encrypted-only reasoning item
    yields `thinking` as undef.
- **Streaming is blocked on k212.** `parse_stream_chunk` drops streamed function calls and
  `response.failed`.
  - Until k212 lands, `XAIResponses` sets `stream_format` to undef and clears `streaming`,
    as `OpenAIResponses` does.
  - Once k212 lands, streaming is switched on in a follow-up. The xAI SSE event names are
    confirmed against the stream capture first.
- **Timeouts.** Agentic runs (several searches, code execution, multi-agent) can exceed
  LWP's 180 s default.
  - The engine POD tells users to set `user_agent_timeout` (sync path) and names `max_turns`
    as the budget knob. The async path's timeout behavior is **langertha-async-worker's
    call**.
  - Phase 1 does **not** raise any default silently.
- **Reasoning and temperature belong to k208** on the parallel branch. This spec does not
  touch `Reasoning/Profile.pm` or `Engine/XAI.pm`. `_temperature_kwargs`' `can()` guard
  passes temperature through on XAI.
- **Capabilities:**
  - inherited: `tools_native`, `tool_choice_*`, `response_format_json_schema`;
  - added: `server_tools`;
  - `streaming`: cleared until k212 lands;
  - the multi-agent row as in §4;
  - `response_format_json_object` on xAI Responses: **[capture]**. It stays advertised if
    the capture shows the wire accepts it, and is cleared otherwise.
- **Out of scope:** `previous_response_id` / `store`. `max_turns` is reachable today as a
  top-level kwarg.
- **Done-list (langertha-internals):**
  - `t/00_load.t` and `t/10_engine_hierarchy.t`;
  - the `lib/Langertha.pm` catalogue (`t/79`) and the `CLAUDE.md` engine tree;
  - the Builder dialect row;
  - POD that points function-tool-only users at `Engine::XAI` and documents the X Search
    per-post billing.

## 6. Phasing and test strategy

### Prerequisite

**k212:** the Responses stream parser handles `function_call` events and `response.failed`,
and on `response.completed` it reuses the `chat_response` walker (tool_calls, citations,
server_tool_calls). Phase 1 does not depend on k212; only XAIResponses streaming does.

### Phase 1: the seam, OpenAIResponses and XAIResponses

1. `Langertha::ServerTool`: `new`, `from_hash($fmt,$h)` with the §3.4 tables, `to($fmt)` and
   `to_hash`. The `responses` wire only; the other wires croak "not yet supported".
2. The per-item partition in `Tool->format_list`. `ResponsesCompatible` switches to
   `format_list('responses', …)` with a pinned literal, like its `ToolChoice` pin (ADR 0010),
   and appends `server_tools`.
3. `Role::ServerTools`: the `server_tools` flag, `%ROLE_TO_CAPS`, the manifest allowlist,
   the `supports` croak and the `_server_tool_wire_check` hook (§3.5).
4. Inbound:
   - `ServerToolCall` and `Response.server_tool_calls`;
   - the client-actionable guard (§3.3);
   - the annotation citations merge (§3.6);
   - the usage pass-through (§4.1);
   - the `summary` autovivification fix;
   - the `supports('response_size')` gate on `max_output_tokens`.
5. `Engine::XAIResponses`, with streaming off (§5).
6. A new ADR, the 0003 and 0029 updates, and the `CONTEXT.md` terms **ServerTool** and
   **Server tool call**.

### Phase 2: Anthropic and Gemini

- **Anthropic:**
  - the recognizer tables;
  - `allowed_callers: ["direct"]` handling for the newer web_search / web_fetch versions
    (fill it in or croak on models without programmatic tool calling; which of the two is
    decided in Phase 2);
  - `server_tool_use` + `*_tool_result` → `server_tool_calls`;
  - text-block `citations` → `Response.citations`;
  - `usage.server_tool_use`;
  - **`pause_turn`** re-send in `chat_with_tools_f`, which needs its own mini-design;
  - the MCP connector (`mcp_toolset` + top-level `mcp_servers` + beta header, and the name
    collision in §2.3).
- **Gemini:**
  - server tools as sibling `tools[]` entries;
  - for Gemini 3 combined with `functionDeclarations`, the companion flag
    `toolConfig.includeServerSideToolInvocations: true`, plus `toolCall` / `toolResponse`
    parts with a `thoughtSignature` that must round-trip in the echo;
  - pre-Gemini-3 combinations → an exclusion;
  - `groundingMetadata` → citations;
  - `executableCode` / `codeExecutionResult` → `server_tool_calls` (kept out of `content`).
- **Perplexity:** under k213.

### Tests (skill `langertha-testing`)

- **Request building (`2x`, offline):**
  - the §3.4 tables row by row, including `custom` / `namespace` never becoming a
    ServerTool, `shell` and `tool_search` by their execution predicate, and the denylist
    croak;
  - `format_list` with all item kinds and both mixed-list orders;
  - `server_tools` appended on both request builders;
  - the `supports` croak on `Engine::OpenAI`;
  - the MCP hook: OpenAI croaks on absent or non-`'never'` `require_approval`; xAI strips
    `require_approval` / `connector_id`;
  - `include` sent and merged on XAIResponses;
  - no `max_output_tokens` for `grok-4.20-multi-agent`;
  - the XAIResponses body `is_deeply`.
- **Response parsing (`7x`/`9x`, verbatim captures only):**
  - `server_tool_calls`;
  - citations merge / dedup / order, and the numeric xAI title dropped;
  - `tool_calls` empty on a server-only turn;
  - the client-actionable guard croaks on an `mcp_approval_request`. The fixture for this is
    a documented exception: the guard test uses a minimal item taken from the OpenAI
    reference, because provoking one live costs an approval round-trip. Flag this in the
    test's intent comment;
  - usage extras carried through;
  - no autovivification in `raw`.
- **Mocked async (`6x`):**
  - on the web-search capture, `chat_with_tools_f` makes **zero** `call_tool` calls;
  - on the mixed server + function capture it makes exactly one, and the echo carries the
    server item.
- **Registry / manifest:** `t/78` and the Builder test (the `server_tools` classification,
  the multi-agent correction, and `XAIResponses` → `responses`).

### Captures (need the maintainer's approval; none have been made)

The advisor's plan is about **9 requests**: OpenAI `gpt-5.6-luna` and xAI `grok-4.7` with
`max_turns` ≤ 2. The estimate is **$0.40–1.00**, with a proposed **$3 hard cap**.
**Awaiting Getty's approval.** The list below reconstructs those 9 requests from the karr
summary. The advisor's full per-request list sits in its report to the orchestrator, so
reconcile the two before running anything.

| # | Capture (`t/data/`, + `.headers.json`) | Provider / model | Needed for | ~Cost |
|---|---|---|---|---|
| 1 | `responses_web_search.json`: `web_search_call` + message with `url_citation`, `include: ["web_search_call.action.sources"]` | OpenAI gpt-5.6-luna (fallback gpt-5.4-mini) | parsing, citations | $0.02–0.05 |
| 2 | `responses_web_search_function_call.json`: server call + `function_call` in one turn | OpenAI gpt-5.6-luna | the loop executes only the function call | $0.05–0.10 (2+3) |
| 3 | `responses_web_search_echo.json`: follow-up echoing #2's items + `function_call_output` | OpenAI gpt-5.6-luna | echo acceptance | (with 2) |
| 4 | `xairesponses_chat_response.json`: plain text | xAI grok-4.6 (current default of Engine::XAI at capture time; grok-4.7 after k205) | reasoning item shape, the summary autoviv fix (k211) | < $0.01 |
| 5 | `xairesponses_web_search.json`: server items, annotations, usage extras | xAI grok-4.7, `max_turns: 2` | top-level `citations` present?, annotation `title`, usage / ticks unit | $0.05–0.15 |
| 6 | `xairesponses_web_search_function_call.json`: `web_search` + function tool | xAI grok-4.7, `max_turns: 2` | function tools on the new engine | $0.10–0.25 (6+7) |
| 7 | `xairesponses_web_search_echo.json`: echo turn incl. encrypted reasoning | xAI grok-4.7 | echo with `reasoning.encrypted_content` | (with 6) |
| 8 | `xairesponses_web_search_stream.sse`: streamed web-search turn | xAI grok-4.7, `max_turns: 1` | xAI SSE event names (feeds k212) | $0.05–0.15 |
| 9 (optional) | `xairesponses_json_object.json`: `text.format` json_object | xAI | the `response_format_json_object` flag | < $0.01 |

Total ≈ 9 requests on two keys, ≈ $0.40–1.00; proposed hard cap $3 — **awaits maintainer approval**.
`x_search` is deferred (per-post billing since 2026-09-21; if wanted later: `max_turns: 1` +
`allowed_x_handles`, ≈ $0.10–0.30). Anthropic `pause_turn` is not triggerable on demand — Phase 2
uses the documented shape. (List reconciled by the orchestrator against the advisor's full
red-team report, 2026-09-25.)

Phase 2 captures (Anthropic web_search / `pause_turn` / `allowed_callers`, Gemini
google_search / Gemini 3 combined tools) are a separate approval.

## 7. Non-goals

- No portable canonical constructors in Phase 1 (Q1 ruling).
- No MCP approval flow (Q2 ruling).
- No tool-loop integration for client-executed built-ins; that gets its own later ticket
  (Q3 ruling).
- No `previous_response_id` / server-side conversation state.
- No change to `chat_f`'s verbatim `tools` passthrough on engines without the capability.
- No silent timeout changes.

## 8. Open questions for the maintainer

1. **Capture spend:** may we make the 9 Phase 1 capture requests (about $0.40–1.00, hard
   cap $3) on the OpenAI and xAI keys?
2. **`max_output_tokens` gate:** Phase 1 would stop `ResponsesCompatible` from sending
   `max_output_tokens` when `supports('response_size')` is false (needed for
   `grok-4.20-multi-agent`). Every other Responses engine has the flag today, so this is a
   no-op for them. Is it OK to make this change in the shared role rather than as an
   XAIResponses-only override?
