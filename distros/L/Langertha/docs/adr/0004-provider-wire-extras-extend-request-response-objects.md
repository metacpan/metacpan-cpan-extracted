# ADR 0004 — Provider-specific wire extras extend the request/response objects, not a side-channel

- Status: accepted
- Date: 2026-06-26
- Tags: engines, wire-format, request, response, http

## Context

Most engine request/response handling fits a common shape, but some providers carry fields
outside it. `Langertha::Engine::VLLMHook` (a sub-engine of `vLLM` for the vLLM-Hook probe
plugin) is the first to need both directions at once: it must put a non-standard `vllm_xargs`
field *into* the request body to arm the plugin, and lift a non-standard `probes` field *out*
of the response body to return the captured tensors.

The implementation plan assumed Langertha mirrors the **OpenAI Python SDK's `extra_body`**
convenience — a client-side wrapper whose contents the SDK flattens into the JSON root before
sending. Langertha has no such layer. The request body is built by
`Langertha::Role::HTTP::generate_json_body` (`lib/Langertha/Role/HTTP.pm:32-34`), which
JSON-encodes **every** kwarg as a literal top-level body key, and `chat_request`'s `%extra`
(`lib/Langertha/Role/OpenAICompatible.pm:266-293`) spreads straight into it. A literal
`extra_body => {...}` kwarg would therefore have shipped an `{"extra_body":{...}}` key that the
server ignores — an entirely dead request field, the bug this decision exists to prevent.

On the inbound side, ADR 0003 already establishes `Langertha::Response` as the canonical, typed
home for normalized response data (`tool_calls`). A provider-specific field like `probes` could
have been left to live only in `raw`, but `raw` is the unmodeled dump — undocumented,
unpredicated, and not the shape a consumer should reach into.

## Decision

There is no generic provider-extras side-channel — by design. Provider-specific wire data
extends the canonical request and response shapes directly.

1. **Outbound: engine-specific request body fields are injected as top-level `%extra` kwargs**,
   in an `around 'chat_request'`, **not via any `extra_body` passthrough — because none
   exists.** Because `generate_json_body` flattens every kwarg to a top-level body key, a
   top-level `%extra` field is exactly what reaches the wire. `VLLMHook`'s
   `around 'chat_request'` (`lib/Langertha/Engine/VLLMHook.pm:143-152`) adds `vllm_xargs` this
   way. Any wire encoding the provider's value type demands is the engine's job too — vLLM's
   `vllm_xargs` accepts only scalars, so `_encode_xargs` JSON-stringifies nested HashRef/ArrayRef
   values while letting plain scalars and JSON booleans ride native.

2. **Inbound: provider-specific response fields get a first-class `Maybe`-typed attribute on
   `Langertha::Response`**, with a predicate, **added to the `clone_with` copy-list.** `probes`
   is `is => 'ro', isa => 'Maybe[HashRef]', predicate => 'has_probes'`
   (`lib/Langertha/Response.pm:157-161`) and is listed in `clone_with`
   (`lib/Langertha/Response.pm:269`) so it survives cloning (e.g. ThinkTag `<think>` filtering
   rebuilds the response via `clone_with`). This is the same pattern as `tool_calls`,
   `rate_limit`, `thinking`, `usage` and `timing` — every Response field is a named, typed,
   documented attribute, not an open bag.

## Rationale

The request body *is* the spread of kwargs; the response *is* a typed value object. Provider
extras therefore extend these canonical shapes rather than threading through a parallel channel
that would have to be invented. A named attribute with a predicate and POD is discoverable and
type-checked; a field hidden in `raw` or smuggled through a nonexistent passthrough is neither.
This is the same instinct as ADR 0001 — wire reality is owned by canonical objects (there, the
Tool/ToolCall/ToolResult/ToolChoice value objects keyed by `tool_wire_format`) so engines stay
thin; here the canonical objects are the request body itself and `Langertha::Response`.

Choosing first-class attributes over a generic `extra` / `extra_body` HashRef is the same stance
ADR 0003 takes for tool calls — *the shape stays closed*. Each provider extra is an explicit,
reviewed addition to `Langertha::Response`, not an open bucket that quietly erodes the response
contract. This ADR extends ADR 0003's principle (Response is the canonical home for normalized
response data) from tool calls to provider-specific extras generally.

The `extra_body` myth is the precise trap this records: the convenience is real in the OpenAI
*Python SDK* (a client-side flatten) and absent in Langertha. An author porting SDK idioms would
ship a dead nested key with no error. Naming the seam — top-level `%extra` out, first-class
Response attribute in — stops the next engine author from re-deriving it the hard way.

## Consequences

- **A new outbound provider field** = an `around 'chat_request'` adding a top-level `%extra`
  key, plus any encoding the provider's value type needs. No core HTTP change; `generate_json_body`
  already does the right thing for any kwarg.
- **A new inbound provider field** = an additive change to `Langertha::Response`: a `Maybe`-typed
  attribute, a predicate, and an entry in the `clone_with` copy-list. `raw` still holds the
  unmodeled remainder; the attribute is the normalized, documented view of the one field
  consumers actually want.
- **The `clone_with` copy-list is hand-maintained** (`Response.pm:269`). Forgetting to add a new
  attribute there silently drops it through any `clone_with` transformation — the failure mode
  that the `probes` work (karr #4) had to step around by hand. The list is the fragility, not
  the pattern; making `clone_with` attribute-driven is tracked separately (see Future work).

- **This ADR is about a *new* field, not a new spelling of an existing one.** When a provider
  reports a quantity `Langertha::Response` already models, under a different key, no new
  attribute is added — the spelling is normalized in the value object, the dialect role, or an
  engine-scoped `around 'chat_response'`, per **ADR 0018**. `VLLMHook`'s `around 'chat_response'`
  is the shared mechanism; which layer it belongs in is the question ADR 0018 answers.

## Future work

- **Drive `clone_with` off the meta attribute inventory** rather than a hand-maintained `qw(...)`
  list, so new Response attributes are carried automatically and cannot be forgotten. Tracked on
  the karr board (#5).
