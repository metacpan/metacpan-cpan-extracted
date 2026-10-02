# ADR 0010 — One canonical inbound `ToolCall->extract($fmt, $data)` and a symmetric `ToolChoice->to($fmt)` complete the value-object seam

- Status: accepted
- Date: 2026-06-26
- Tags: tools, wire-format, value-objects, tool_choice

## Context

ADR 0001 routed all tool wire-translation through four value objects (`Tool`, `ToolCall`,
`ToolResult`, `ToolChoice`) dispatched by a single per-engine `tool_wire_format` tag. It left
two asymmetries in that seam, flagged as future work:

1. **Two inbound entry points.** `ToolCall->extract` was meant to be the unified locate+parse
   API, but the inbound surface had drifted into three overlapping shapes: the tool-calling
   loop walked responses with the lower-level `locate` + `from_fmt` split; a legacy
   *self-sniffing* `extract($data)` (single-arg) re-implemented per-format response-walking that
   `locate` already owned; and `extract($fmt, $data)` existed but was not the single path. The
   per-format walking thus lived in more than one place — exactly the duplication ADR 0001 set
   out to remove.

2. **One value object missing its sibling's dispatch.** `ToolChoice` was the original exemplar
   of the value-object pattern, yet alone among the four it had no symmetric `to($fmt)`
   entry — only per-format `to_openai` / `to_anthropic` / `to_gemini` / `to_responses`
   serializers that each engine called by name. `Tool`, `ToolCall`, and `ToolResult` already
   exposed `to($fmt)`; `ToolChoice` did not.

Resolved on `main` in commit `d4a0cf6` ("Unify ToolCall inbound on extract($fmt,$data); add
ToolChoice->to($fmt)").

## Decision

1. **One canonical inbound entry: `ToolCall->extract($fmt, $data)`** — strictly
   `locate($fmt, $data)` (find the raw structures) + `from_fmt($fmt, $hash)` (parse one). The
   per-format response-walking lives in exactly one place, `locate`. A fail-loud guard
   (`croak ... if ref $fmt`) kills the legacy single-arg `extract($hashref)` call. Every engine
   `chat_response` path now passes a format into `extract`.

2. **Self-sniffing is demoted and explicitly named.** Shape detection becomes
   `sniff_format($data)` (top-level shape only — it does *not* walk per-format tool structures),
   and `extract_sniff($data)` = `sniff_format` → `extract`. It is deliberately *not* called
   `extract`, so there is exactly one canonical, format-pinned inbound entry. `extract_sniff` is
   used by a single caller — the `Langertha::Output::Tools` back-compat facade, which genuinely
   has no wire format in scope.

3. **`ToolChoice->to($fmt)` is added**, mirroring `Tool` / `ToolCall` / `ToolResult`. All four
   tool value objects now share the symmetric `to($fmt)` outbound dispatch. `%TO_METHOD` maps
   only the wires that carry a wire-level `tool_choice` parameter — `openai` / `anthropic` /
   `gemini` / `responses`. `ollama` and `hermes` croak through `to` (Ollama has no wire-level
   tool_choice; Hermes forces via prompt injection). `to_perplexity` stays a standalone
   helper, off the tag dispatch, because Perplexity's named-tool request is not a
   `tool_wire_format` value — it is rewritten to `response_format` by `chat_f` (ADR 0005).

## Rationale

This closes ADR 0001's symmetry: per direction there is now one place that knows the wire
shape. Adding inbound for a new format = one branch in `locate` + one entry in `%FROM_METHOD`;
adding outbound tool-choice = one branch in `ToolChoice` + one entry in `%TO_METHOD`. Nothing
per-engine, in either direction. The `extract` / `extract_sniff` split makes the rare
no-format-in-scope case loud and singular instead of letting a self-sniffing overload quietly
duplicate the locator.

### The deliberate exception worth preserving: `Role::OpenAICompatible` pins `openai`

`Role::OpenAICompatible` does **not** use `$self->tool_wire_format` for its inbound or its
tool_choice. It pins both to the literal `openai`:

- inbound — `Langertha::ToolCall->extract('openai', $data)` in `chat_response`
- tool_choice — `$tc->to('openai')` in `chat_request`

This is intentional and must **not** be "consistency-fixed" to `$self->tool_wire_format` by a
future refactor. Two independent reasons:

- **The OpenAI-compatible response envelope is always OpenAI-shaped**, even for engines whose
  `tool_wire_format` is `hermes`. A Hermes engine's calls ride inside the message *text* and
  are parsed by the `Role::Tools` hermes branch — never by `chat_response`. So `chat_response`
  must read the OpenAI envelope as OpenAI, regardless of the engine's tool dialect.
- **Perplexity composes no `Role::Tools`** (it deliberately omits it because that path sends a
  `tools` array Perplexity rejects). `tool_wire_format` is an attribute of `Role::Tools`, so
  `$self->tool_wire_format` would *die* on a Perplexity engine. The literal `openai` is what
  keeps the shared `Role::OpenAICompatible` code path safe for an engine that has no tool
  dialect at all.

## Consequences

- **Deliberate keep: the tool-calling loop stays on the `locate` / `from_fmt` split, not
  `extract`.** `Role::Tools::response_tool_calls` returns raw structures via `locate`, and
  `extract_tool_call` parses one via `from_fmt`. The loop keeps the raw wire hashes (not parsed
  `ToolCall` objects) because it threads each raw `$tc` all the way to `format_tool_results`,
  which rebuilds the **Result envelope** (the **Assistant echo** plus per-result blocks) from
  provider-shaped raw fields (`$_->{tool_call}{id}`, `…{functionCall}{name}`, `…{call_id}`).
  Collapsing to `extract` would discard the raw structure too early. This split is preserved on
  purpose, not overlooked.
- A new provider that carries a wire-level tool_choice is added by extending `ToolChoice` and
  `%TO_METHOD`; one that does not (like Ollama/Hermes) simply isn't in the map and croaks loudly
  if asked — the absence is explicit.
- **The symmetry is a property to be maintained, not one that holds by construction.** Each
  inbound constructor is still written by hand, so a tolerance added to one does not reach its
  siblings. karr k124 taught `from_anthropic` to decode a JSON-string argument blob (the AKI
  `/anthropic` shim ships the OpenAI encoding inside an Anthropic block); `from_openai`,
  `from_ollama` and `from_responses` already did — `from_gemini` still does not, and silently
  reduces a stringified `args` to `{}`. Tracked as karr k131. The lesson generalizes: a
  compatibility endpoint re-encoding one dialect inside another is now a routine wire reality,
  so per-constructor leniency has to be kept in step deliberately.
- Cross-links: **ADR 0001** — this completes the value-object wire-translation symmetry it
  established and resolves its "Future work" item. **ADR 0003** — every `ToolCall` that
  `extract` produces lands on `Response.tool_calls`, the single sink. **ADR 0005** — records
  why Perplexity's named-tool request is a `response_format` rewrite, not a `tool_wire_format`
  value, which is why `to_perplexity` stays off the `to($fmt)` dispatch. `CONTEXT.md` fixes the
  vocabulary (the `ToolChoice` entry now describes the unified `to($fmt)` dispatch).

## Update (k235 — a `ToolChoice` object is canonical tool_choice input)

`ToolChoice->from_hash` returns an already-blessed `Langertha::ToolChoice` as-is. Before, it
returned `undef` for one, so every request builder took the object for an unreadable,
provider-native choice: it reached the wire through `TO_JSON` in the canonical
`{type => ...}` shape (wrong on the OpenAI and Responses wires, which take `'none'` /
`'required'` strings), and on Perplexity a `ToolChoice->none` carped and still sent the tools,
bypassing the ADR 0020 k233 none-withhold. Every tool_choice entry point — `chat_f`'s ADR 0005
rewrite and its exclusion signal, `Role::Chat::_hermes_prompt_tools` (the hermes wire, where
`none` withholds the tools from the prompt, k231), the `OpenAICompatible` / `AnthropicCompatible` /
`ResponsesCompatible` / Gemini request builders, the `Input::Tools` facade — funnels through
`from_hash`, so one identity branch there makes the object serialize by `to($fmt)` on every
wire; no builder learns about objects on its own. `TO_JSON` stays the canonical `to_hash`
for logging (Langfuse), never a wire form. The same audit found that
`OpenAICompatible::chat_stream_request` did not normalize tool_choice at all (a hash or object
went out verbatim); both builders now share `_openai_tool_choice_kwarg`. Native engines with no
wire-level tool_choice serializer (Ollama native, AKI native, LMStudio native) still pass any
tool_choice through untouched — pre-existing, tracked as karr k239.

## Update (k239 — native engines no longer pass tool_choice through)

The k235 note above is resolved: Ollama native and LM Studio native decide a `tool_choice`
through `Role::Chat::_gate_tool_choice` and, claiming no `tool_choice_*`, never send one. They
classify with `ToolChoice->from_hash` only; `to('ollama')` still croaks, as there is no such
wire form. AKI native is a hermes engine: `chat_f` takes the tools and `tool_choice` off the
request before the builder (k231, k234).

## Update (k252 — nested JSON is characters; the transport encodes once)

Several wires carry JSON as a *string* inside the JSON body or inside model text: OpenAI
`function.arguments`, the tool-result `content` of the `openai` / `ollama` wires, the Responses
`function_call_output.output`, the hermes `<tool_call>` / `<tool_response>` payloads and tool
prompt, AKI native's `chat_context`, vLLM-Hook's `vllm_xargs`, and the structured-output JSON the
`/anthropic` shims lift into `Response.content`. `ToolCall::to_openai` (`encode_json`) and
`ToolResult` (a `utf8 => 1` encoder) produced UTF-8 *bytes* there; the request body encoder then
encoded them a second time, so a provider — or knarr's client, which re-serializes
`ToolCall->to_openai` — read `Köln` as `KÃ¶ln`. The inbound twin: `extract_hermes_from_text`
fed character text to a byte decoder and silently dropped any call with non-ASCII arguments.

The contract: value objects and serializers produce and accept **character strings**; the one
UTF-8 encode happens in `Role::JSON`'s `json` when `Role::HTTP` builds the request body, and the
one decode when `parse_response` / the stream parsers read the wire bytes. Code that nests JSON
uses a character codec — `$engine->encode_json_text` (mirror of `decode_json_text`) on engines,
a `utf8 => 0` `JSON::MaybeXS` in the value objects. `$engine->json->encode` stays the byte
encoder for whole bodies only. Held by `t/77_utf8_tool_wire.t`. Out of scope: `Manifest->to_json`
is a whole-document serializer, documented to return UTF-8 bytes.
