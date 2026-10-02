# ADR 0003 — `Response.tool_calls` is the single source of truth for emitted tool calls

- Status: accepted
- Date: 2026-06-26
- Tags: tools, response, tool-calls, structured-output

## Context

A model can emit a tool call through several distinct mechanisms, each with its own wire shape:

- a **native** tool call (`tool_calls` in `choices[0].message`, Anthropic `tool_use` blocks,
  Gemini `functionCall` parts, Responses `function_call` items),
- a **Hermes** `<tool_call>` XML payload parsed out of plain text,
- a **forced-tool fallback** that `chat_f` synthesizes when the wire reality won't take the
  caller's request directly — e.g. Perplexity (no tool calling) where a `tool_choice` of a
  named tool is rewritten to `response_format=json_schema` and the parsed content is turned
  back into a tool call; or Anthropic structured output, where a `response_format` is satisfied
  by a synthetic tool plus a forced `tool_choice` and the `tool_use` input is lifted out.

If callers had to branch on which mechanism produced the call, every consumer of a `Response`
would have to know all of the above — the exact coupling ADR 0001 removed from the engines.

## Decision

1. **`Langertha::Response.tool_calls` is `ArrayRef[Langertha::ToolCall]` — the one place
   emitted tool calls live**, native and synthetic alike. Whatever mechanism produced the call,
   it is normalized to a `Langertha::ToolCall` and lands on this one list. There is no second,
   parallel tool-call representation on the response.

2. **A `synthetic` flag on `Langertha::ToolCall` records provenance** — true for the
   forced/rewritten fallbacks, false for calls the model emitted natively. This keeps the
   distinction (did the model choose this tool, or did we synthesize it to satisfy a request?)
   without introducing a second type. The `chat_f` auto-rewrites attach `synthetic` ToolCalls
   so the caller still reads one uniform shape.

## Rationale

One representation means a `Response` consumer iterates `tool_calls` and is done — it never
learns that Perplexity has no native tools or that Anthropic structured output is implemented
with a forced tool. The rewrites in `chat_f` (ADR 0001's value objects do the per-format
parsing; the capability registry of ADR 0002 decides *whether* to rewrite) stay invisible above
the seam. The `synthetic` flag is the minimum needed to preserve the one piece of information a
caller might legitimately want — provenance — without leaking the mechanism.

## Consequences

- Consumers (including `Raider`) read `Response.tool_calls` uniformly; provider quirks do not
  reach them.
- A new forced-tool fallback is added by producing `synthetic` ToolCalls, not by inventing a
  new response field — the shape stays closed.
- Streaming follows the same rule: `Stream::Chunk` carries an optional `tool_calls` field and
  `Role::Chat::aggregate_tool_calls(\@chunks)` collects them into the same `Langertha::ToolCall`
  list, so streamed and non-streamed responses converge on one representation.

## Update (k206 — `tool_calls` means "calls the client must act on"; provider-executed calls go to `server_tool_calls`)

`chat_with_tools_f` dispatches every entry of `tool_calls` to an MCP server by name and dies on
a miss; Raider and `chat_f` callers act on them the same way. A tool call the *provider* already
ran during the request (a `web_search_call`, an `mcp_call`, …) must therefore never land there.
Such calls are recorded on the new `Response.server_tool_calls`
(`ArrayRef[Langertha::ServerToolCall]`, ADR 0030): a record of what happened, with the wire item
verbatim, not an instruction and not a second tool-call representation. `ToolCall->locate`
never returns a server call item (tested against the verbatim OpenAI captures). `synthetic`
still records provenance only; it never means "don't execute".

## Update (k221 — every dialect's stream delivers its tool calls)

The streaming consequence above held only on paper: the Chat-Completions, Anthropic, Gemini and
Ollama-native stream parsers read text and thinking and dropped tool calls, so
`chat_stream_realtime_f` ended a tool-calling turn as an empty success (a gap accepted since
k171; k212 closed it for the Open-Responses envelope). Now each parser delivers them, under one
contract:

- **A finished call, on exactly one chunk.** A `Stream::Chunk` never holds a fragment. Where
  the wire fragments a call, the parser assembles it in per-stream state: Chat-Completions
  `delta.tool_calls` per `index`, delivered on the chunk that carries `finish_reason`;
  Anthropic `tool_use` blocks from `content_block_start` + `input_json_delta`, delivered on the
  block's `content_block_stop`. Gemini `functionCall` parts and Ollama `message.tool_calls`
  arrive whole and land on the chunk that carries them. A call leaves the state when it is
  delivered, so `aggregate_tool_calls` only collects and never sees it twice.
- **Built by the same extractor as the reply.** The assembled fragments are put back into the
  dialect's reply shape and read by the `ToolCall->extract($fmt, …)` call that `chat_response`
  makes, so a streamed and a non-streamed reply of one response yield equal `ToolCall`s
  (ADR 0010). The tests replay the non-streaming captures as the source of truth; the event
  streams themselves are built from the providers' documented shapes, not captured.
- **Stream state is per stream.** Both stream paths (`process_stream_data` and
  `chat_stream_realtime_f`) hand `parse_stream_chunk` a fresh HashRef as its third argument, so
  two concurrent streams on one engine cannot mix fragments. Anthropic's k167 terminal-metadata
  carry (`finish_reason` + `usage` replayed from `message_delta` onto `message_stop`) moved into
  the same state; engine-wide, a second stream's `message_start` wiped the first stream's. A
  direct caller that omits the state shares an engine-wide fallback, closed by a final
  `_process_stream_buffer` flush.
- **A truncated stream is loud, not flushed.** A Chat-Completions call still pending when the
  stream ends without a `finish_reason` is dropped with one `carp` naming it: its `arguments` may
  be cut off, and a partial JSON string would decode to `{}` and run the tool with made-up
  arguments. An empty-string `finish_reason` is no finish. A fragment without `index` is keyed by
  its `id` (by position only when it has neither), so servers that stream whole calls without
  `index` keep them apart.
- **Text-only streams are unchanged.** `finish_reason` is passed through as the provider sends
  it, as on the non-streaming path; `t/43_stream_text_only_pin.t` pins every text-only chunk
  against a snapshot taken before the change.

On the request side, `chat_stream_realtime_f` serializes `Langertha::Tool` objects for the
engine's `tool_wire_format` (ADR 0001); tool hashes are taken as already in the wire shape and
pass through, because the `Tool` round trip would drop wire extras (`strict`, `cache_control`).
Every tool keeps its place in the list (Gemini's function declarations are grouped into one entry
where the first object was). `chat_f` still puts `tools` on the wire as given (karr k227).
