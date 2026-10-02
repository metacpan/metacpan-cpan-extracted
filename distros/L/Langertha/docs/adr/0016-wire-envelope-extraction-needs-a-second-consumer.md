# ADR 0016 — A wire envelope becomes a role only when a second consumer needs it from a different parent

- Status: accepted
- Date: 2026-08-17
- Tags: engines, inheritance, roles, composition, wire-format, symmetry, auth

## Context

ADR 0013 extracted the Anthropic wire envelope out of `Engine::AnthropicBase` into
`Role::AnthropicCompatible`, so that the two dominant dialects of the tree — OpenAI and
Anthropic — are solved the same way. It explicitly declined *one* follow-on: a wholesale
`Role::Engine::*` namespace rebrand across all ~40 engines. It said nothing about the four
engines that still carry their envelope inline in their own class, exactly as `AnthropicBase`
did before commit 579d0c8:

- `Engine::Gemini` (602 lines) — `?key=` auth, `contents` / `generationConfig` /
  `functionDeclarations` / `toolConfig` / `cachedContent`
- `Engine::Ollama` (500 lines) — native `/api/chat`, NDJSON framing
- `Engine::AKI` (327 lines) — key-in-body, `/api/call/{model}`
- `Engine::LMStudio` (471 lines) — native `/api/v1/...`

karr #66 read that silence as an open symmetry gap and proposed four further
`Role::<X>Compatible` extractions "analogous to `Role::AnthropicCompatible`". The sondierung
on that ticket (structural analysis plus live provider verification) recommended **no**
extraction for any of the four, and the ticket was rejected on the merits.

The reason to write this ADR is not the rejection — it is that ADR 0013 gives no rule for
*when* an envelope earns a role. Without one, the same ticket reappears at the next doku audit
as "still asymmetric", and the answer has to be re-derived from scratch.

## Decision

### 1. The extraction trigger is a second consumer from a different parent

A wire envelope moves from the engine class into a `Role::<X>Compatible` **at the moment a
second consumer needs that envelope while descending from a different parent** — not when the
tree merely *looks* asymmetric, and not because a sibling dialect already has a role.

Until then the envelope stays in the engine, which is ADR 0006 unchanged: inheritance encodes
the wire dialect.

Corollary on ownership: **the extraction belongs to the ticket of the shim that needs it**, not
to a standalone symmetry ticket. The shim is what proves the second consumer exists and what
pays for the extra file; a symmetry ticket has no such evidence and no such payer.

That is precisely how the Anthropic case actually ran, verified in the history:

| Commit | Date | What |
|---|---|---|
| `913f8a3` | 2026-03-08 | `AnthropicBase` + `LMStudioAnthropic` |
| `c1e1e38` | 2026-04-20 | `MiniMaxAnthropic` |
| `b5a26ac` | 2026-06-26 | `MoonshotAnthropic` |
| `579d0c8` | **2026-08-14** | envelope extracted into `Role::AnthropicCompatible` (ADR 0013) |

The extraction came *after* the shims existed — five months after the first one. It was the
accumulated multi-consumer reality that made the role worth its keep, not a prior decision to
be symmetric. (karr #89 records a fifth consumer arriving: AKI.IO's Anthropic-compatible
`/v1/messages` endpoint.)

### 2. The axis test: envelope vs. capability

The trigger above applies **only to envelopes**. The two axes are decided by different tests,
and conflating them is what makes the tree look inconsistent:

- **A wire envelope is the dialect** — the `chat_request` / `chat_response` pair, the auth
  header, the stream framing, the rate-limit reader. Envelope-shaped, all-or-nothing, one per
  engine. → **inheritance axis** (ADR 0006), until decision 1 fires.
- **A capability is a separable feature surface** — its own attributes and/or lifecycle
  methods, meaningfully present-or-absent independent of the dialect. → **role axis, from day
  one, regardless of how many engines compose it.** A capability role with exactly one consumer
  is correct by construction, because ADR 0002 derives `engine_capabilities` from
  `$self->does($role)`: a capability that is not a role cannot be advertised truthfully.

`Engine::Gemini` demonstrates both halves of the test at once, and is the reason this section
exists:

- `Role::CachedContent` is composed by `Engine::Gemini` **and by nothing else**, and its own
  POD justifies itself with *"any other engine with the same REST surface can compose the role
  rather than re-implement it"*. Read against decision 1 alone, that looks like a direct
  counterexample — a single-consumer role justified by a hypothetical second consumer. It is
  not. `CachedContent` is a **capability**: five REST lifecycle methods
  (`create`/`get`/`list`/`update`/`delete_cached_content_f`) over a resource that exists
  independently of the chat envelope, and a `cached_content` flag in `%ROLE_TO_CAPS`. It is on
  the role axis because of *what it is*, not because of how many engines compose it.
- The Gemini **envelope**, single-consumer too, stays in the class.

`Role::KeepAlive` (composed by `Engine::Ollama` and nothing else) is the same shape on the
Ollama side — a separable request-side knob pair, correctly a role, sitting in the same class
whose envelope is correctly not one. (It carries no `%ROLE_TO_CAPS` entry today; that is a
separate question, see *Future work*.)

### 3. For a single-consumer dialect, the extensibility axis is the auth/endpoint seam

The four engines above are **not** all single-consumer dialects — but where second consumers do
exist, they differ from the incumbent **exclusively in auth scheme and base URL / model path,
never in the envelope**:

| Dialect | Second consumer today | Delta |
|---|---|---|
| Gemini | Vertex AI (express + standard), Gemini-native gateways | base URL, `/v1` vs `/v1beta`, `publishers/google/models/` prefix, ADC Bearer vs `?key=` |
| Ollama native | Ollama Cloud, AMD Lemonade Server, Docker Model Runner | `Authorization: Bearer` vs none, base URL |
| AKI native | none plausible (single vendor, key-in-body `/api/call/{model}`) | — |
| LMStudio native | none plausible (`/api/v1` *is* the LM Studio app control surface) | — |

An `Engine::VertexGemini` or `Engine::OllamaCloud` would therefore simply `extends` the
existing engine — same parent, so decision 1 does not fire and the envelope role buys nothing.
What *does* block those shims is that the auth and endpoint construction are welded into the
method bodies:

- `Engine::Ollama` has `sub api_key_env { undef }` (line 126), **no** `api_key` attribute and
  **no** `update_request` hook — and `Role::HTTP` calls `update_request` only
  `if $self->can('update_request')`. So there is no code path by which an Ollama engine can
  send a Bearer token at all; Ollama Cloud is unreachable. That is a user-facing gap → karr #87.
- `Engine::Gemini` interpolates `?key=` and the `/v1beta/models/{model}` path shape at three
  call sites (lines 205 `generateContent`, 386 `streamGenerateContent`, 489 models listing),
  with `update_request` only setting the content type → karr #88.

So: **for a dialect with one engine, the symmetry worth pursuing is the auth/endpoint seam, not
the envelope role.** The seam is what actually makes a second consumer reachable; the role is
bookkeeping that would leave both gaps exactly where they are.

### 4. Applied: none of the four envelopes is extracted

karr #66 is rejected on the merits, not deferred — there is nothing here to revisit
when the tree grows, only the trigger in decision 1 to re-check.

## Rationale

**The analogy to 579d0c8 does not carry structurally.** On the Anthropic side the composition
*shell* already existed as its own class with four children; the extraction moved envelope
code from that shell into a role and left the shell thin. For Gemini/Ollama/AKI/LMStudio the
envelope, the shell and the single leaf are **one class** because there is exactly one leaf.
Extraction would not *free* a shell, it would *create* one — two files to read per dialect
instead of one, with no reuse on either side.

**The split line would run through coupled code.** Two mechanics verified against Moose and
against ADR 0013's composition-order trap:

- `has '+url'` cannot move into a role. Moose rejects it outright:
  `has '+attr' is not supported in roles`. The `url` attribute is declared in `Role::HTTP` and
  narrowed by `Engine::Remote` (`has '+url' => ( required => 1 )`); `Gemini`, `AKI` and
  `LMStudio` each narrow it again with their default URL. Every one of those declarations has
  to stay on a class.
- The model-family `around engine_capabilities` has to stay on the class. Gemini's inspects
  `chat_model` and switches `thinking_budget` / `reasoning_effort` and `cached_content` per
  generation — it is the ADR 0002 escape hatch, and ADR 0013 already established that these
  per-family corrections stay on the composition shell.

**The `-excludes` bill is larger than the envelope is worth.** Each class-level method that
would move into a role and collides with a method of the same name on an already-composed role
needs an explicit `-excludes` resolution — the canonical pattern of ADR 0015. Counted against
the current source:

| Engine | Collisions a role extraction would create |
|---|---|
| `Gemini` | 3 — `content_format` (`Role::Chat`), `_build_reasoning_wire_format` (`Role::ReasoningEffort`), `_build_tool_wire_format` (`Role::Tools`) |
| `Ollama` | 2 — `_build_tool_wire_format` (`Role::Tools`), `_build_openapi_operations` (`Role::OpenAPI`) |
| `AKI` | 2 — `_build_tool_wire_format` (`Role::Tools`), `hermes_extract_content` (`Role::HermesTools`) |
| `LMStudio` | 2 — `_build_openapi_operations`, `_build_supported_operations` (both `Role::OpenAPI`) |

Nine resolutions, plus four new files and the bulk of 1,900 lines relocated, for zero reuse.
(The counts assume the whole dialect body moves; a narrower cut trades collisions for a
messier split line, it does not remove them.)

**Testability is unchanged either way.** The request-body tests instantiate engines and assert
the wire shape; nothing composes an envelope role standalone. Extraction would not enable a
test that cannot be written today — the same observation that made 579d0c8 safe makes these
four pointless.

**Why write the rule down rather than just close the ticket.** The asymmetry is visible from
the directory listing and invisible in its justification, so it re-presents itself as a defect
at every audit. Naming the trigger converts a recurring "why isn't this symmetric yet?" into a
one-line check: *is there a second consumer that cannot inherit?* If no, the answer is already
written.

## Consequences

- The four engines keep their envelopes inline. This is a **deliberate keep**, not backlog.
- **Adding a shim for an existing dialect**: extend the existing engine. If — and only if — the
  new consumer cannot inherit from it, extract the envelope into `Role::<X>Compatible` **as
  part of that shim's ticket**, following the ADR 0013 shape (pure move, `-excludes` on the
  colliding universal roles per ADR 0015, family `around engine_capabilities` stays on the
  class).
- **Adding a separable feature surface**: it is a role immediately, single consumer or not, so
  ADR 0002 can advertise it from `does($role)`.
- ADR 0006 is reaffirmed for the four engines and ADR 0013 is bounded: 0013 is the *outcome* of
  the trigger in decision 1, not a template to be applied ahead of it.
- Cross-links: **ADR 0006** (inheritance = dialect, roles = capabilities — the axis this ADR
  supplies the crossing rule for), **ADR 0013** (the Anthropic extraction; this ADR answers the
  question it left open), **ADR 0002** (capability roles are the reason single-consumer
  capability roles are correct), **ADR 0015** (`-excludes` canon, the cost unit counted above,
  and the per-family `engine_capabilities` correction that must stay on the class), **ADR 0020**
  (the first live firing of decision 1's trigger — the Open-Responses envelope extracted into
  `Role::ResponsesCompatible` for Perplexity's Agent API, a second consumer that descends from a
  *different* parent than `Engine::OpenAIResponses`; the case decision 1 describes and the
  Anthropic precedent never exercised).
- **CONTEXT.md** gains the term pair *dialect axis* / *capability axis* under a new "Engine
  composition axes" heading, with the vocabulary only — the rationale stays here.

## Future work

- karr **#87** — `Engine::Ollama` has no Bearer path; Ollama Cloud unreachable. The real
  extensibility fix for that dialect (user-facing gap, medium).
- karr **#88** — factor the Gemini `?key=` + `/v1beta/models/{model}` seam out of the three
  call sites. Do it *when* a shim is actually wanted, not speculatively.
- karr **#89** — `Engine::AKIAnthropic`: AKI.IO's Anthropic-compatible endpoint, a fifth
  consumer of `Role::AnthropicCompatible` and direct evidence that decision 1's trigger, once
  fired, pays off.
- `Role::KeepAlive` carries no `%ROLE_TO_CAPS` entry although it is a capability role by the
  decision-2 test. Not resolved here — noted so a future capability audit can decide whether
  `keep_alive` deserves a flag.
