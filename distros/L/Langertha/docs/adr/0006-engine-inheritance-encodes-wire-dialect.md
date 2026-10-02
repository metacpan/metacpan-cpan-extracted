# ADR 0006 — Engine inheritance encodes the wire dialect; roles encode capabilities

- Status: accepted
- Date: 2026-06-26
- Tags: engines, inheritance, roles, composition, wire-format, transcription

## Context

Langertha has ~25 engines spread across several mutually incompatible HTTP *wire dialects*:
OpenAI `/chat/completions` (Bearer auth, SSE), Anthropic `/v1/messages` (`x-api-key`,
event-typed SSE), Gemini (`?key=` auth, `functionDeclarations`, NDJSON-ish), Ollama native
(`/api/chat`, NDJSON), AKI (key-in-body). Within any one dialect, engines differ on a second,
orthogonal axis: *what they can do* — chat, tool calling, embeddings, transcription, image
generation, structured output — and on small wire-reality corrections.

So every engine sits at the intersection of two axes:

- **(a) which wire envelope** — the `chat_request` / `chat_response` pair, the auth header
  (`update_request`), the streaming framing (`stream_format` / `parse_stream_chunk`),
  rate-limit header parsing. This is shared, stateful, envelope-shaped.
- **(b) which capabilities** — chat AND tools AND embeddings in any combination. This is
  orthogonal and combinatorial.

A single mechanism cannot serve both axes well: putting capabilities into the class tree
explodes it (a class per capability combination); putting the wire envelope into roles forces
every concrete engine to re-declare its transport.

## Decision

Split the two axes across Perl's two composition mechanisms.

1. **Inheritance encodes the wire dialect (axis a).** `Langertha::Engine::Remote` is the root
   — it composes `JSON`, `HTTP`, `PluginHost`, makes `url` required, and holds the rate-limit
   plumbing. Per-dialect base classes extend it: `OpenAIBase` (OpenAI envelope + the universal
   chat roles), `AnthropicBase` (`/v1/messages` envelope, `x-api-key`, `content_format`
   `anthropic`), `TranscriptionBase` (OpenAI transcription endpoints only). The standalone
   non-OpenAI/Anthropic engines (`Gemini`, `Ollama`, `AKI`, `LMStudio`) extend `Remote`
   directly and carry their own envelope. A concrete engine extends the base whose wire it
   speaks and inherits the request/response handling **and** the `tool_wire_format` default
   (ADR 0001 — `OpenAIBase` leaves it `openai`, `AnthropicBase` overrides to `anthropic`).

2. **Composition encodes capabilities (axis b).** Capabilities are Moose roles (`Chat`,
   `Tools`, `Embedding`, `Transcription`, `ImageGeneration`, `ResponseFormat`, `Streaming`,
   …) and `engine_capabilities` derives the flag set from the composed role inventory
   (ADR 0002). A base composes the roles universal to its dialect; the concrete engine
   composes the capability roles that *vary*. `OpenAIBase` composes the always-on set
   (`OpenAICompatible`, `Chat`, `Streaming`, `ResponseFormat`, `Models`, `Temperature`, …);
   `Engine::OpenAI` adds `Embedding Transcription ImageGeneration Tools`, while
   `Engine::Perplexity` adds *none* of those (it cannot call tools) — same base, different
   capability composition.

3. **A capability subset of an existing dialect gets a slim base, not stripped inheritance —
   the `TranscriptionBase` deliberate keep.** `TranscriptionBase` speaks the *same* OpenAI
   wire as `OpenAIBase` but composes a deliberately *smaller* role set (`OpenAICompatible`,
   `OpenAPI`, `Models`, `Transcription`, `Capabilities` — **not** `Chat` / `Tools` /
   `Embedding` / `ImageGeneration`), so a caller of a transcription-only server
   (`Engine::Whisper`) gets a focused object exposing `simple_transcription` and nothing
   else. A review tempted to make `Whisper` simply extend `OpenAIBase` was rejected: because
   capability is composition, a transcription-only engine must *compose only* `Transcription`
   rather than *inherit* a chat interface it cannot serve. `Engine::OpenAI` exposes a
   `whisper` attribute returning a `TranscriptionBase` bound to the parent's `api_key`/`url`,
   so chat-side code can grab a transcription handle without re-stating credentials.

## Rationale

Wire dialect is shared and envelope-shaped, the natural fit for a base class — the request
builder, the auth header, the stream parser, the rate-limit reader all live once per dialect.
Capability is orthogonal and combinatorial, the natural fit for roles — an engine is any
subset of {chat, tools, embedding, transcription, image, structured output}. Forcing
capabilities into inheritance would multiply classes; forcing the wire envelope into roles
would scatter transport across every engine. The split keeps concrete engine classes at the
*configuration* level: pick a base (which wire), compose the varying roles (what it can do),
set `url`/`api_key`/`default_model`.

The split is also the precondition for ADR 0002 to be truthful: capabilities follow
`does($role)`, so they cannot silently disagree with what the engine is wired to do.
`TranscriptionBase` makes that literal — it cannot claim `chat` because it does not compose
`Role::Chat`.

## Consequences

- **New provider on an existing dialect** = extend the dialect base, set `url` / `api_key` /
  `default_model`, compose any extra capability roles. Zero wire code.
- **New wire dialect** = a new base extending `Remote` with its own `chat_request` /
  `chat_response` / auth / stream framing and `_build_tool_wire_format`.
- **A capability subset of an existing dialect** = a slim base on the `TranscriptionBase`
  pattern — fewer composed roles — not inheritance with capabilities stripped after the fact.
- Cross-links: ADR 0001 (`tool_wire_format` default follows this base hierarchy), ADR 0002
  (capabilities derive from the composed role inventory this decision makes the capability
  axis).

## Update (ADR 0013)

The wire *dialect* envelope for the two dominant families is now a composed role,
symmetrically: `Role::OpenAICompatible` (already) and `Role::AnthropicCompatible` (extracted
from `AnthropicBase`). Inheritance still encodes the transport *root* (`Remote`); the dialect
envelope moved to the role axis for OpenAI and Anthropic. NB: the envelope roles are **not**
self-contained — they assume `url`/`HTTP`/`JSON` come from `extends Remote`. See ADR 0013.

A third envelope role followed — `Role::ResponsesCompatible` for the Open-Responses envelope
(OpenAI's `/v1/responses` and Perplexity's Agent `/v1/agent`). It is the first extraction where
the two consumers descend from *different* parents, so it adds a divergence-hook layer to the
0013 shape. See ADR 0020 (and ADR 0016 for the trigger rule).
