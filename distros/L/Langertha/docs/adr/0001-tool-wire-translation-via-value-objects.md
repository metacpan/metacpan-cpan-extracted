# ADR 0001 — Tool wire-translation routes through value objects keyed by `tool_wire_format`

- Status: accepted
- Date: 2026-06-26
- Tags: tools, wire-format, value-objects, engines

## Context

Langertha talks to ~25 engines across several incompatible tool dialects: OpenAI
`chat/completions`, Anthropic `/v1/messages`, Gemini `functionDeclarations`, the OpenAI
Responses API, Ollama's native shape, and the Hermes XML convention for models with no native
tool support. Every dialect differs on three axes: how outbound tool *definitions* are
serialized, how inbound tool *calls* are located and parsed out of a response, and how tool
*results* are wrapped into the next-turn message envelope.

Historically each engine carried its own copies of `format_tools`, `response_tool_calls`,
`extract_tool_call`, `format_tool_results` and `response_text_content`. That meant the same
five per-format behaviours were duplicated and drifted across two dozen engine classes; a fix
to the Anthropic tool-result shape had to be applied in every Anthropic-family engine, and a
new provider meant pasting five more methods.

## Decision

1. **An engine declares exactly one `tool_wire_format`** — the enum `openai` | `anthropic` |
   `gemini` | `ollama` | `responses` | `hermes` (`Langertha::Role::Tools`). Its default follows
   the engine base-class hierarchy (`OpenAIBase` leaves it `openai`, `AnthropicBase` overrides
   to `anthropic`, …), so concrete engines inherit it and carry **no tool-format code of their
   own**. Override `_build_tool_wire_format` to change it.

2. **All wire-translation lives in canonical value objects, dispatched by that one tag:**
   - outbound definitions — `Langertha::Tool->to($fmt)` / `->format_list($fmt, \@mcp_tools)`
   - inbound calls — `Langertha::ToolCall` (`->locate($fmt, $data)` finds the raw structures,
     `->from_fmt($fmt, $hash)` parses one; `->extract($fmt, $data)` is the combined form)
   - result blocks — `Langertha::ToolResult->to($fmt)`

   `Langertha::Role::Tools` holds only the **thin tag-driven orchestration** that calls these
   (`format_tools`, `response_tool_calls`, `extract_tool_call`, `format_tool_results`,
   `response_text_content`). Engines carry none of it.

3. **`hermes` is a `tool_wire_format` value like any other.** Its outbound is system-prompt
   injection and its inbound is `<tool_call>` XML parsing, selected by the same tag; the tag
   names and prompt template come from `Langertha::Role::HermesTools`. It is not a separate
   code path bolted onto the loop — it is one branch of the same dispatch.

## Rationale

A new provider becomes a new tag value plus branches inside the value objects — never new
methods on an engine. A wire-shape fix happens once, in the value object, and every engine of
that format gets it. The engine classes shrink to configuration (which roles, which default
tag), which is the level they should operate at. `CONTEXT.md` fixes the vocabulary for this
seam (`tool_wire_format`, **Tool**, **ToolCall**, **ToolResult**, **Result envelope**,
**Assistant echo**) so the terms stay stable across future refactors.

## Consequences

- Adding a **format** = extend the value objects + the `Role::Tools` branches. Adding an
  **engine** of an existing format = zero tool code, just compose the roles and inherit the tag.
- **Result-envelope arity stays in `Role::Tools::format_tool_results`, not in `ToolResult`.**
  A `ToolResult` serializes exactly one block; the envelope (the **Assistant echo** of the
  prior turn plus N result blocks, where N-per-message differs — OpenAI emits N `role:tool`
  messages, Anthropic/Gemini one message with N blocks) is assembled by the orchestration. This
  split is deliberate: the block formatter knows nothing about the surrounding conversation.
- `Role::HermesTools` keeps the tags/template but is no longer a parallel tool-calling
  subsystem — it is the data behind one tag value. It is not retired: it also carries the
  overridable `hermes_extract_content` (for engines whose response shape is not OpenAI's) and
  is the `does()` source of the `tools_hermes` capability flag (ADR 0002).
- **`TO_JSON` is the canonical shape, not a wire shape.** `Role::JSON`'s shared encoder gained
  `convert_blessed` (karr k120, commit `b9ec772`) so the distribution's value objects serialize
  through their `TO_JSON` instead of croaking — that is for traces, logs and `UsageRecord`-style
  data, and it is **not** a second outbound door. Note the sharp edge it introduces: handing a
  `Langertha::Tool` straight into a request body now yields `to_hash`
  (`name` / `description` / `input_schema`), which is byte-identical to `to_anthropic` — so on
  any wire that is not Anthropic's it is the wrong dialect, emitted silently, where it used to
  be a loud croak. The tag remains the only outbound door: `Tool->to($fmt)` /
  `->format_list($fmt, \@mcp_tools)`.
- **A per-format serializer may also key on the schema *shape*, not only on the tag.** k133 gave
  `Tool->to_anthropic` a top-level `strict: true` — but only for a **closed** `input_schema`
  (`additionalProperties:false` + a non-empty `required`); it stays silent otherwise, because
  Anthropic 400s on `strict` over an open schema. The decision is keyed on the schema, not on
  any engine or `tool_wire_format` value, so it lives inside the value object exactly like the
  rest of `to_anthropic` — the "value object owns its wire shape" principle of this ADR,
  extended to a per-schema wire toggle. See the ADR 0005 Update (k133).

## Future work

- **Reconcile the two inbound entry points.** ~~`ToolCall->extract($fmt, $data)` is the unified
  locate+parse API, but the loop (`Role::Tools::response_tool_calls` + `extract_tool_call`)
  uses the lower-level `locate` + `from_fmt` split, and the legacy self-sniffing
  `extract($data)` form duplicates the per-format response-walking already in `locate`. Collapse
  to one canonical inbound path so there is a single place the per-format walking lives.~~
  **Resolved — see ADR 0010.** `extract($fmt, $data)` is now the single canonical inbound entry
  (per-format walking lives only in `locate`); self-sniffing is the explicitly-named
  `extract_sniff`; and `ToolChoice` gained the symmetric `to($fmt)` the other three value
  objects already had. The loop's `locate` / `from_fmt` split is kept deliberately (it threads
  raw structures to the result-envelope rebuild) — ADR 0010 records why.

## Update (k210 — only function tools pass the `Tool` door; `classify` names the rest; the Responses envelope decides per item)

The inbound door `Tool->from_hash` had no notion of a tool that is not a function tool. It
routed any hash by shape. So `{type=>'web_search'}`, Gemini's keyed `{google_search=>{}}` and
`{functionDeclarations=>[…]}` (no `name`) returned `undef`, and `from_list` / `format_list`
dropped them. Anthropic's `{type=>'web_search_20250305', name=>'web_search'}` fell through to
`from_anthropic` and became a *function* tool with an empty schema. Either way the request lost
its meaning without a word.

**One classifier.** `Tool->classify($hash, $fmt)` is public and never croaks. It returns
`function`, `server`, `client_builtin`, `foreign` (a built-in of a wire other than `$fmt`) or
`unknown`. In list context it also returns the wire and a label. It is the single source of
truth: the door croaks from it, `ResponsesCompatible` decides from it, and a sibling gateway can
map it to a 400 instead of dying (k216). A function tool is recognized by its `type`, not by
guessing from the rest of the shape: no `type` plus a `name` (canonical, MCP, Gemini, Anthropic
client tool), `type => 'function'` (OpenAI), or `custom` *with* an `input_schema` (Anthropic's
explicit client tool).

Built-ins are recognized explicitly per wire, from the provider documentation (spec k206 §3.4;
llm-advisor against the OpenAI create-response reference). "Any other `type` is server-side"
would be wrong.

- responses, server: `web_search` (also dated `web_search_YYYY_MM_DD`), `web_search_preview*`,
  `file_search`, `code_interpreter`, `image_generation`, `mcp`, `x_search`,
  `collections_search`, `tool_search` unless `execution: "client"`, and `shell` with a
  `container_auto` or `container_reference` environment.
- responses, client-executed: `local_shell`, `computer`, `computer_use_preview`, `apply_patch`,
  any other `shell` (local, missing or unrecognized environment, so an unknown shell fails
  loud rather than going out verbatim), and `tool_search` with `execution: "client"`.
- anthropic: server `web_search_*`, `web_fetch_*`, `code_execution_*`, `tool_search_tool_*`
  (versioned) and `mcp_toolset`. Client-executed `bash_*`, `text_editor_*`, `computer_*` and
  `memory_*`.
- gemini (keyed, snake and camel case, ADR 0018): server `google_search`,
  `google_search_retrieval`, `code_execution`, `url_context`, `google_maps`,
  `enterprise_web_search`, `file_search` and `retrieval`. Client-executed `computer_use`.

**The door fails closed.** `from_hash` / `from_list` / `format_list` croak on every category
except `function`. The messages differ per category: a server-side tool "not supported yet", a
client-executed built-in "not a server tool", an unsupported `type`, or a hash with no `type`
and no `name`. Nothing is dropped silently any more. ~~The one exception is the flat Responses
function form, which `from_openai` still cannot parse; that predates this change and is k217.~~
**Resolved — see the k217 Update.**
Every function-tool form the door accepted before is pinned in `t/92_tool_input_forms.t`. The
server-side croak is interim until server-side tools get their own value object (k206). It is
a croak and not a pass-through because `from_hash`'s callers only ever emit function tools.

**The Responses envelope decides per item, by denylist.** `ResponsesCompatible::chat_request`
used to format the whole `tools` list only when the *first* item had no `type`. A typed item
first sent an MCP tool out unformatted (400). An MCP tool first dropped a built-in and turned
`custom` / `namespace` into function tools. Now each item is decided on its own and the order is
kept, as spec §3.4 says (`_is_native_responses_tool`). A flat `{type=>'function', …}`, a
Responses `server` tool, and any typed `unknown` go out verbatim, so the provider judges them
(values open). That covers `custom`, `namespace` and future
server types. Other function-tool forms (MCP, canonical, OpenAI chat's nested `function`, a
`Langertha::Tool`, an Anthropic `custom`) are formatted. A Responses `client_builtin`, a
`foreign` built-in, and an untyped nameless hash croak at the door. Known client-executed
built-ins croak even though they went out verbatim when listed first before this change, per
the Q3 ruling on k206: their `*_call` output items are not mapped, so the turn would end
silently. Loop integration for them is future work.

Not yet consistent, and deliberately so: `custom` goes out verbatim, but its `custom_tool_call`
output is not mapped into `Response.tool_calls` either (`ToolCall` only knows `function_call`).
So a turn that calls it ends with empty `tool_calls`. The spec keeps `custom` verbatim on
purpose. The inbound fail-loud for unmapped client-actionable items belongs to k206
(llm-advisor must-change 1).

## Update (k217 — `from_openai` accepts the flat Responses function form too)

`from_openai` required the Chat Completions nesting (`{type=>'function', function=>{name,
description, parameters}}`) and returned `undef` for the OpenAI Responses API's flat form
(`{type=>'function', name, description, parameters}`) — `classify` already reported the flat
form as `function`, but the door dropped it anyway, so `from_hash` / `from_list` /
`format_list` silently lost it on every wire except the Responses envelope (which already
passed it through verbatim). `from_openai` now reads `name` / `description` / `parameters`
from `$hash->{function}` when that is a hash, and from `$hash` itself otherwise, so both shapes
resolve to the same `Langertha::Tool` (value-object inbound door, ADR 0018 tier 1); the nested
form's behavior is unchanged. `t/92_tool_input_forms.t` pins the flat form through the same
table as every other accepted form and checks its `format_list` output is identical to the
nested form's on every wire.

## Update (k206 — server-side tools get their own wire-pinned value object)

The interim "server-side tools are not supported yet" croak of the k210 Update is resolved for
the `responses` wire by `Langertha::ServerTool` (ADR 0030): the fifth tool value object, keyed
by the same `tool_wire_format`, carrying the provider-native hash and croaking on every other
wire. `Tool->format_list($fmt, …)` keeps a server tool of `$fmt` in place; `Tool->from_hash`
stays function-only (its server-side croak now points at `ServerTool`). Recognition reuses
`classify`, so the two objects cannot disagree. The inbound mirror of the client-executed
denylist — Responses output items the client must answer and Langertha does not map
(`custom_tool_call`, `computer_call`, `local_shell_call`, `apply_patch_call`,
`mcp_approval_request`, a client `tool_search_call`) — sits next to it in `Tool.pm` and croaks
in the Responses walker and in `ToolCall->locate('responses')`, closing the gap the k210 Update
named for `custom`. Anthropic and Gemini server tools still croak at the door (Phase 2).

## Update (k227 — `chat_f` shapes a caller's tools list per item, through one path)

`chat_f` handed `tools` to `chat_request` raw, and only the Responses envelope reshaped it. A
`Langertha::Tool` therefore went out through `TO_JSON` in its canonical `to_hash` shape, which
only the Anthropic wire reads; OpenAI, Gemini and Ollama got an invalid tool. The `chat_f` POD
claimed `chat_request` serialized per provider, which was false. k221 had fixed only
`chat_stream_realtime_f` (objects serialized, every hash passed through).

**One path.** Both `chat_f` and `chat_stream_realtime_f` now call `Role::Chat::_wire_tools`
(k221's `_stream_wire_tools`, renamed now that it is shared), which delegates the per-item work
to the value object: `Langertha::Tool->request_list($fmt, \@tools)`. The per-format shape
knowledge stays on `Tool`, as this ADR requires. `_wire_tools` leaves the list alone on the
`hermes` wire (tools ride the prompt through `chat_with_tools_f`), on an engine without
`Role::Tools`, and on the `responses` wire, whose envelope already decides per item (k210) and
needs the `ServerTool` objects for its `_server_tool_wire_check` hook and default-tool dedup —
an `unlisted` ServerTool turned into a hash there would lose both.

**Decision: classify plain hashes per item.** Serializing only objects (the k221 state) left an
MCP or canonical hash on the OpenAI, Gemini or Ollama wire just as broken as an object, and the
end state named on k227 is per-item classification. `request_list` decides each item with
`classify`, in place:

- a `Tool` or `ServerTool` object goes through its own `to($fmt)`;
- a `function` hash already in the wire's own shape goes out **verbatim** — OpenAI/Ollama
  nested `{type=>'function', function=>{…}}`, Anthropic `input_schema` (plain or `custom`), a
  Gemini declaration. That is where `function.strict`, `cache_control` and Gemini's `behavior`
  live, so nothing the value object does not model is lost, and a wire-shaped caller's body is
  byte-identical to before (pinned in `t/69_chat_f_wire_tools.t` before the change);
- a `function` hash in another shape (MCP `inputSchema`, canonical `input_schema` on a
  non-Anthropic wire, the other dialect's shape) is converted through `from_hash`, carrying over
  the extras the target wire takes: `strict` (to `function.strict` on OpenAI, top-level on
  Anthropic, an explicit value beating `to_anthropic`'s schema guess) and `cache_control` on
  Anthropic. An extra the target wire has no field for is not carried; the hash was invalid on
  that wire before;
- everything else — `server`, `client_builtin`, `foreign`, `unknown` — goes out **verbatim**.

This adapts the k210 policy rather than copying it. The Responses envelope croaks on a
client-executed built-in, a foreign built-in and an untyped nameless hash because its door only
emits function tools and its `*_call` output items are unmapped. On the other wires those same
hashes are native and work today: Anthropic's `web_search_20250305` and `bash_*` (its
`tool_use` is an ordinary call), Gemini's `{google_search=>{}}` and
`{functionDeclarations=>[…]}` (untyped and nameless by design), typed OpenAI-compatible
extensions such as Moonshot's `builtin_function`. Croaking would regress working callers and
gatekeep a provider's own vocabulary; the classifier's lists are documentation-derived, not
capture-verified. So the k210 principle carries over — nothing is dropped, nothing is silently
turned into a function tool — and the provider judges what is not a function tool, as the
envelope already does for typed `unknown` items.

**Gemini: merge, not croak (k221 review M4).** Converted declarations, `Tool` objects and a
raw `{functionDeclarations=>[…]}` hash could have produced several `functionDeclarations`
entries; some Gemini versions reportedly reject that (unverified). All declarations now go into
one entry, placed where the first declaration came from, in caller order; a later raw entry
gives up its declarations and keeps its other fields (dropped only when nothing is left).
Merging loses nothing and is what the caller meant, so it is normalization, not gatekeeping. A
single raw entry is unchanged. The REST API reads both `functionDeclarations` and
`function_declarations` (ADR 0018), so a raw entry in either spelling joins the merge; the merged
entry is written `functionDeclarations` (k227 review M1). Likewise the inbound door
`Tool->from_hash` / `from_gemini` reads a declaration's schema from `parameters`,
`parametersJsonSchema` or `parameters_json_schema`, so converting one to another wire keeps it
(k227 review M2).

## Update (k231 — `chat_f` on the `hermes` wire is one `chat_with_tools_f` turn)

The k227 path left the list alone on `hermes`, so `chat_f(tools => [...])` on NousResearch or
AKI native put a `tools` body key the model never sees (in the `to_hash` shape for a `Tool`).
The `hermes` wire has no tools body key: definitions ride the system prompt. `chat_f` and
`chat_stream_realtime_f` now take `tools` and `tool_choice` off the request there
(`Role::Chat::_hermes_prompt_tools`) and build the turn from the pieces the tool loop already
uses: `format_tools` (`Tool->format_list('hermes', …)`, MCP shape) and the
`hermes_tool_prompt` system message (`Role::Tools::_hermes_tool_messages`, now shared with
`build_tool_chat_request`), so a single `chat_f` sends the body a loop turn sends. On the reply,
`chat_f` lifts `<tool_call>` blocks (honoring `hermes_call_tag`, via the loop's own
`_hermes_split_text`) onto `Response.tool_calls` and out of `content` (ADR 0003), unless the
engine's `chat_response` already did (AKI native, k123). The lift runs only when tools were
sent, so `simple_chat_f` on a hermes engine keeps its content. A streamed turn keeps the tags in
its text: chunks carry no Hermes call (superseded by the k253 Update below).

`tool_choice` is never sent. `none` withholds the tools: no tool prompt, so no reply lift
either, with a carp saying so — the rule k233 set for the Responses envelope (ADR 0020), since a
prompt cannot forbid a tool it offers. The prompt cannot force a tool either, so any other value
but `auto` is dropped with a carp; an explicit `undef` is no choice and stays silent, as in
`OpenAICompatible`. Only function tools fit the prompt: a built-in or other non-function item
croaks in `format_tools` rather than going out verbatim as on the other wires. The ADR 0005 forced-tool rewrite does not fire here, because the hermes
engines still claim `tool_choice_named` (and `tools_native`) through `Role::Tools` in
`%ROLE_TO_CAPS` — an over-claim for this wire, left for k234, not changed here.

## Update (k253 — a streamed hermes turn lifts its calls too)

k231 left `chat_stream_realtime_f` on the `hermes` wire with the `<tool_call>` markup in the
streamed text and no call on any chunk, so `aggregate_tool_calls` and a relay built on the chunks
(langertha-knarr k19) saw none, and the markup reached the user. Text already handed to the
chunk callback cannot be taken back, so a lift at stream end was not enough. When the tools rode
the prompt (the same condition as `chat_f`'s reply lift), each chunk now goes through a tag-aware
incremental splitter (`Role::Tools::_hermes_stream_chunk` / `_hermes_stream_split`): text outside
the call tag (`hermes_call_tag`) streams as it comes, a closed block is withheld, and a tail that
may still become an opening tag is held until the next chunk. A chunk that carried only markup is
not delivered. Each block is decided when it closes, through the same `_hermes_split_text`
`chat_f` uses: a call is kept, a block that carries no call (invalid JSON, no `name`, a nested
opening tag) is emitted as text in place. On the final chunk (`is_final` or a non-empty
`finish_reason`) the calls land as `Langertha::ToolCall` objects (ADR 0003:
`Stream::Chunk.tool_calls` is the streamed form of `Response.tool_calls`). A stream that ends
without a final chunk gets a closing chunk for what is still held.

Review round (k253 review). `_hermes_split_text` itself now keeps a block that carries no call in
the text instead of deleting it, so `chat_f`, `response_text_content` and the tool loop lose
nothing the model wrote either, and stream and `chat_f` content agree. When calls were lifted,
`finish_reason` reads `tool_calls` over `stop` or none, on the final chunk and on `chat_f`'s
`Response` alike (the rule k248 set for native OpenAI-dialect calls; `->raw` keeps the wire
value); `length` and other provider values stay. The OpenAI dialect's `parse_stream_chunk` now
treats an empty-string `finish_reason` as no finish for `is_final` and `finish_reason` too, as
Gemini's parser already did, so a server that sends `""` on every delta cannot end the lift early.

Unclosed or partial markup at the end is emitted as text and gives no call: nothing the model
wrote is lost, and `chat_f` treats an unclosed block the same way. With the think tag filter on
(`Role::ThinkTag`) a `<think>` block streams as text and a call tag inside it is no call, since
`chat_f` strips thinking before its lift; parity with `chat_f` on the same reply text is what the
tests pin (`t/43_hermes_stream_tool_calls.t`). ThinkTag's own streaming handling is a filter over
the aggregated content at the end, not incremental, so there was no splitter to reuse. Engines
off the `hermes` wire, a hermes turn without tools and `tool_choice => 'none'` are unchanged; AKI
native still has no streaming.

Known and accepted after the k253 review: the stream merges native chunk `tool_calls` with the
lifted hermes calls, while `chat_f` skips the lift when the reply already carries native calls —
theoretical on the `hermes` wire, left as is. The splitter rescans its held buffer from the start
on each chunk while inside a call block (quadratic for very large arguments in tiny chunks);
negligible at realistic sizes, remembering the scan offset is the fix if it ever shows.

## Update (k255 — one hermes text lift, on the value object)

`Langertha::ToolCall->extract_hermes_from_text` (the public door: `Output::Tools`, skeid's
protocols) still deleted a `<tool_call>` block that carried no call while `_hermes_split_text`
kept it. The door is now the one implementation: it keeps such blocks in the text in place and
takes an optional `tag => ...` (default `tool_call`); `Role::Tools::_hermes_split_text` delegates
to it with `hermes_call_tag` and returns `{name, arguments}` hashes, so a non-object `arguments`
now reaches the tool loop as `{}` on every path, as `Response` already coerced it.

## Update (k267 — `content_format` gains `responses`, `ollama`, `lmstudio`; inline-only images)

Multimodal content follows the same rule as tools: `Langertha::Content::Image` owns one
`to_<fmt>` per `content_format` (the `Role::Chat` tag, independent of `tool_wire_format`), and
`Role::Chat::_normalize_content_blocks` dispatches on it. Three wires were served the
chat-completions shape and are now their own formats: `responses` (supplied by
`Role::ResponsesCompatible`: `input_text` / `input_image` with `image_url` as a plain string,
`output_text` for an assistant turn's text), `ollama` (native `/api/chat`: text joined into a
string `content`, raw base64 lifted into the message `images` array) and `lmstudio` (native
`/api/v1/chat`: `{ type => 'image', data_url }` input items). Endpoints that take a chat-shaped
image but reject remote URLs (Ollama `/v1`, Cerebras, Moonshot Kimi, LM Studio native) set the
internal engine hook `_content_inline_images_only`; a URL image is then fetched and sent as a
data URL, as `to_gemini` always did, and a failed fetch croaks with the engine's name before
any request exists. The hook is wire truth for the serializer, deliberately not a capability
flag: whether a model *sees* images is the separate `image_input` question (k266). Messages
without a `Langertha::Content` object are passed through unchanged on every format.

## Update (k330 — Gemini declarations carry `parametersJsonSchema`, which ties them to v1beta)

`Tool->to_gemini` sent `input_schema` as `functionDeclarations[].parameters`. That field is
Gemini's OpenAPI-subset `Schema` proto, which rejects every keyword outside its allowlist with a
400 ("Unknown name ..."), and MCP input schemas routinely carry such keywords
(`additionalProperties`, `$ref` / `$defs`, `const`, `$schema`). `to_gemini` now emits
`parametersJsonSchema`, the same JSON-Schema engine as the `responseJsonSchema` Gemini structured
output already uses, with the schema passed through unchanged. The two fields are mutually
exclusive, so `parameters` is never sent, and no sanitizer is written: stripping keywords would
silently loosen a tool's contract. Only a top-level `$schema` is dropped (not documented as
accepted), and a tool without arguments (no `properties`, nothing beyond `type` / `required` /
`additionalProperties`) declares no schema at all. Every Gemini declaration Langertha builds
goes through `to_gemini` (`format_list`, `request_list`, `Langertha::CachedContent`); a caller's
own raw Gemini declaration still goes out verbatim, in whichever spelling it chose. Inbound,
`from_gemini` keeps reading both spellings (ADR 0018).

The dependency this creates: `parametersJsonSchema` exists on the v1beta `FunctionDeclaration`
only; v1 (GA) has `parameters` alone. `Engine::Gemini` pins `gemini_api_version` to `v1beta`, so
the wire is consistent today. A subclass or future change that serves `v1` must revisit
`to_gemini` (fall back to `parameters`, and then face the keyword allowlist) in the same change.

## Update (k326, k336 — MCP result content is mapped per wire through one normalizer)

A tool's MCP `call_tool` result used to reach the wire as-is: Anthropic embedded the content
array (a 400 on the first image or annotated text block), and OpenAI, OpenAI Responses and
Ollama JSON-encoded it, which put an image's base64 data into the prompt as tokens. None of
those wires takes MCP content blocks: Anthropic's `tool_result` takes text / image / document /
search_result blocks and rejects unknown fields; the OpenAI chat tool message, the Responses
`function_call_output` and the Ollama tool message take a string; Gemini's
`functionResponse.response` takes a JSON object.

`ToolResult` now reads the content array once into neutral items (text, text document, base64
blob, Anthropic-native block, placeholder) and each `to_<fmt>` renders them. Anthropic maps
them onto its blocks, following anthropic-sdk-python `lib/tools/mcp.py`. Every other wire gets
one string: text joined with `"\n"`, a text resource as its text, a `text/*` blob decoded as
UTF-8, a `resource_link` as `[resource_link] name <uri>`, and any blob the wire cannot carry as
a placeholder naming type, MIME type, URI and decoded size — never the payload. Unlike the SDK,
nothing dies inside the tool loop: an unsupported block degrades to a placeholder. When the
content is empty, every wire sends the JSON-encoded `structuredContent` (as the SDK does);
Gemini, whose response is an object anyway, sends the `structuredContent` object whenever there
is one and `{ result => <string> }` otherwise. `Role::Tools::format_tool_results` passes
`structuredContent` into every format.

Deliberately not done: re-attaching tool-result images as a follow-up user message with
`image_url` parts on the string wires. It would let a vision model see a screenshot tool's
output, but it adds a message the model did not ask for into the tool-loop envelope, and the
Responses and Gemini 3 wires offer native image outputs (`input_image` parts,
`functionResponse.parts`) that would be the better target. A possible later feature.

## Update (k344 — tool-result images ride natively on the Responses and Gemini 3 wires)

The k336 "possible later feature" is done for the two wires that have a native form, and not by
re-attaching a user message. `ToolResult->to($fmt, image_input => 1)` renders a result image
natively: on `responses`, `function_call_output.output` becomes an array of parts in content order
(an image as `input_image` with a `data:` URL, every other item as `input_text` with its string
form); on `gemini`, the image moves out of the `result` string into
`functionResponse.parts[].inlineData` (`mimeType`, `data`, no `displayName`, which only a `$ref`
from `response` needs and the v1beta discovery schema of `FunctionResponseBlob` does not list).
Without a carriable image (MIME outside JPEG/PNG/GIF/WebP on Responses, JPEG/PNG/WebP on Gemini)
the output is exactly the k336 form. The shape stays on the value object; the orchestration only
decides whether to ask for it.

`Role::Tools::format_tool_results` asks on those two branches when the selected model claims
`image_input` (ADR 0019) and the engine's `_tool_result_images_on_wire` hook allows it: true by
default, `gemini-3*` only on `Engine::Gemini` (the guide documents the feature for the Gemini 3
series). The hook is a private predicate and not a capability flag, like ADR 0033's
`_is_hermes_model` and k267's `_content_inline_images_only`: it is wire truth for one
serializer choice inside the loop, and nothing outside it (the `chat_f` matrix, a manifest, a
caller) has a question it would answer. The gate is there because the tool loop sends what an MCP server returned, not what the
caller chose: a text-only model must not start receiving image parts because a tool happened to
return one. OpenAI `/v1/responses` and Perplexity `/v1/agent` document the same
`output = string | [input_text | input_image]` shape, so the Responses envelope needs no divergence
hook for it (ADR 0020); Perplexity's `sonar` presets make no `image_input` claim and keep the string.

The other wires ignore the option instead of croaking: the OpenAI chat tool message and the
Ollama and Hermes results have no image form, and nothing dies inside the tool loop (k336).
Anthropic maps images unconditionally since k326 and is unchanged. Both native forms are
**documentation-derived, not live-verified** (OpenAI API reference, docs.perplexity.ai agent
reference, Gemini v1beta discovery doc and function-calling guide, 2026-09-29); pinned in
`t/92_tool_result_images.t`.

## Update (k359, k364, k366, k367 — the Anthropic `tool_result` follows the image gate; source blocks only where the wire takes them)

The k344 Update left Anthropic mapping tool-result images unconditionally (k326). That was right
for first-party Claude and wrong for the `/anthropic` shims, which answer 200 whether or not the
model sees the image: an AKI.IO live probe (2026-09-30, llm-advisor) showed `gpt-oss-120b`
silently dropping a `tool_result` image and `qwen3.6-35b` misreading it (a red square answered
"White", a green one "Black"), although the same model reads a plain user-message image. The k344
reason — the tool loop sends what an MCP server returned, not what the caller chose — applies
word for word, so `to_anthropic` now takes `image_input` like `to_responses` / `to_gemini`: an
MCP image (or image resource) becomes an `image` block only with it, else the k336 placeholder.
An Anthropic-native `image` block (with a `source`) is the caller's choice and passes through.
First-party Claude claims `image_input` for every Claude 3+ model, so nothing changes there.
Keeping Anthropic unconditional would have made the flag mean "sees images" on two wires and
nothing on the third (house rule 5).

`Engine::AKIAnthropic` sets `_tool_result_images_on_wire` to 0 with the probe in its comment: the
user-image path works for `qwen3.6-35b`, so an `image_input` row for that face is likely one day,
and the `tool_result` path must then still not carry images.

Anthropic's source blocks — `document` (k364) and `search_result` (k366) — get a second private
predicate, `_tool_result_source_blocks_on_wire` (default 1, `Role::Tools`), passed as
`source_blocks => 0` to `to_anthropic`. One predicate, not one per block type: where there is
evidence, both are rejected alike. Without it a text resource or `text/*` blob becomes a `text`
block holding the text (as on the string wires), a PDF blob the placeholder, and a native
`document` or `search_result` block a `text` block with its string form — unlike a native image,
because this is a wire fact, not a model question. It is 0 on `AKIAnthropic` (live, 2026-09-30:
HTTP 529 "Unsupported content type: document" / "... search_result", deterministic, so every
tool-loop turn with an MCP text resource broke) and on `MoonshotAnthropic` (Kimi's Messages
OpenAPI lists `tool_result` content as string | text | image; docs only). `MiniMaxAnthropic` and
`LMStudioAnthropic` keep the default: neither documents the case either way, and a failure there
would be a loud 4xx, not a silent loss. Both predicates are private for the k344 reason: they
answer one serializer choice inside the loop and nothing outside it asks.

Degrading a native `document` / `search_result` changes what the caller chose, so
`format_tool_results` carps once per engine instance when it does (the `_langertha_carp` once-key
pattern of ADR 0035, key `tool_result_source_blocks`). The value object knows no engine, so the
warning sits in the orchestration, which asks `ToolResult` for the native source-block types it
holds. An MCP resource becoming text is the normal path on these shims and stays quiet.

The string form of a native block (k366, k367) keeps its text instead of a bare placeholder: a
`search_result` is a `[search_result] title <source>` line followed by its text parts, and a
`document` with a `content` source its inner parts joined with `"\n"` (an image among them as a
placeholder). This fixes the same loss on every string wire (OpenAI, Responses, Ollama, Gemini,
Hermes), present since k326/k336. `is_error` stays as it is on every shim (k366): AKI accepts it
and silently ignores it (live), the other shims document Claude Code, which sends it, and no wire
fails on it; the flag is lost on every string wire anyway, so a shim-only text marker would split
the behaviour. Pinned in `t/92_tool_result_images.t`, `t/92_tool_result_anthropic.t` and
`t/92_tool_result_string.t`.

## Update (k361 — tool-result PDFs ride natively on OpenAI Responses and Gemini 3)

The k344 mechanism now also carries a PDF (an MCP embedded resource blob, `application/pdf` — the
one MCP shape that holds a document, as on the anthropic wire since k326). `ToolResult->to($fmt,
native_pdf => 1)` renders it on `responses` as an `input_file` part of
`function_call_output.output` (`file_data` a `data:application/pdf;base64,...` URL, `filename`
the percent-decoded last segment of the resource URI's hierarchical path with `.pdf` appended
when missing, `document.pdf` for an opaque URI such as `urn:uuid:…` or an empty path), and on `gemini` as a `functionResponse.parts[].inlineData` part with `mimeType`
`application/pdf`. The part array of `responses` now forms when any item is carried natively (an
image under `image_input`, a PDF under `native_pdf`); each option carries only its own kind.
`filename` is optional in the OpenAI reference but the server rejects `file_data` without it
(community reports 2025–2026), so it is always sent.

`Role::Tools::format_tool_results` asks for it on the `responses` and `gemini` branches through a
third private predicate, `_tool_result_pdf_on_wire` (default 0): 1 on `Engine::OpenAIResponses`,
the `gemini-3*` image predicate on `Engine::Gemini`, and an explicit 0 on `Engine::Perplexity`,
where the shared envelope diverges — its Agent API's `FunctionCallOutputInput.output` lists only
`input_text` / `input_image` and no input schema has `input_file`. The flag sits on the engines,
not on `Role::ResponsesCompatible`, because `Role::Tools` already owns the `_tool_result_*`
predicates and a same-named method on two roles composed into one class would conflict. Off by
default because every other wire (openai chat, ollama, hermes, Gemini before 3) documents no PDF
inside a tool result, and the anthropic wire's PDF `document` block stays governed by
`source_blocks` (k326/k364).

The model half of the gate is `image_input`, not a new flag: both providers document PDF
understanding as a vision feature (OpenAI's PDF guide puts extracted text *and page images* into
the context and says this "requires models with vision capabilities"; Gemini reads documents
through its vision), and the k344 reason applies unchanged — the tool loop sends what an MCP
server returned, so a text-only model (`gpt-oss-*`, `o3-mini` on OpenAIResponses) keeps the
placeholder instead of risking a 400 mid-loop. A separate `document_input` capability was
considered and not invented: no provider in the tree documents PDF input for a model that does
not see images, or the reverse, so it would be a second name for the same fact (open question on
karr k361, to reopen when one does). The anthropic `document` path is wire-only and does not read
`image_input`; aligning it is noted on k361, not done here.

All of it is **documentation-derived, not live-verified** (OpenAI API reference
`developers.openai.com/api/reference/resources/responses/methods/create` and PDF-files guide,
docs.perplexity.ai `agent-post` reference, ai.google.dev `generate-content/function-calling`
"Multimodal function responses": "Documents: application/pdf, text/plain", all fetched
2026-09-30). Pinned in `t/92_tool_result_pdf.t`.

## Update (k371 — anthropic tool-result PDFs stay a wire decision)

k361 gated native tool-result PDFs on `image_input` for `responses` and Gemini 3. The anthropic
wire deliberately does **not** follow: its PDF `document` block is decided by
`_tool_result_source_blocks_on_wire` alone (k326/k364). The asymmetry is provider reality, not
drift. OpenAI and Gemini document PDF input as a vision feature; on the Anthropic dialect the text
track is evidenced without vision: a live probe (2026-09-30, tool_use → tool_result with a text
part plus a base64 `application/pdf` `document`, a 1-page PDF carrying a codeword) got HTTP 200 and
the correct codeword from MiniMax-M2.7 (text-only, `image_input` 0, 244 input tokens) and from
MiniMax-M3 (vision, 3159 tokens, page seen as well), although MiniMax's documented content-block
enum has no `document`. Gating on `image_input` would regress working PDF reading on M2.x into the
k336 placeholder; first-party Claude models all claim `image_input`, so the gate would be a no-op
there. Only a PDF/base64 document was probed; a text-source `document` and `search_result` were
not. `MiniMaxAnthropic` states `_tool_result_source_blocks_on_wire { 1 }` explicitly, with that
evidence, so the default cannot be flipped as "undocumented". Pinned in
`t/92_tool_result_anthropic.t` (behavior rows plus the override via `find_method_by_name`).

## Update (k372 — LMStudioAnthropic takes no source blocks in a tool_result)

`Engine::LMStudioAnthropic` now sets `_tool_result_source_blocks_on_wire { 0 }`, like
`MoonshotAnthropic` and `AKIAnthropic`: an MCP text resource (the common case) goes out as a
`text` block, a PDF as the k336 placeholder, a native `document` / `search_result` as its text,
with the once-per-engine carp. Evidence is **indirect and not live-verified** (no LM Studio server
in the project): the anthropic-compat docs only point to Anthropic's, the changelog lists only
"Images in tool call results" for `/v1/messages`, and lmstudio-bug-tracker#1792 (LM Studio 0.4.11,
Apr 2026) reports PDFs rejected with a 400 even for vision models, with no document type. The
axis is the wire, not `image_input` (k371): a learned-vision model gets the same treatment. Flip
back to the default if a probe shows `document` accepted.
