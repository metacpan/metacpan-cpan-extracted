# Symmetric wire-envelope roles: add `Role::AnthropicCompatible`

> **For agentic workers:** REQUIRED SUB-SKILL: Implement task-by-task with TDD.
> Steps use checkbox (`- [ ]`) syntax for tracking. Verify recursively with
> `prove -lr t/`.

**Goal:** Make the OpenAI and Anthropic wire-envelope topics symmetric by extracting the
Anthropic wire envelope out of `Engine::AnthropicBase` into a dedicated role —
`Role::AnthropicCompatible` — parallel to the existing `Role::OpenAICompatible`, and leaving
`Engine::AnthropicBase` as a thin composition layer exactly like `Engine::OpenAIBase`.

**Architecture:** Today `Role::OpenAICompatible` already owns the whole OpenAI envelope
(chat/stream/image/embedding/transcription request+response, auth header, rate limits, models),
and `Engine::OpenAIBase` is only a thin shell that `extends Remote` and composes that role plus
the universal chat roles. The Anthropic side has no such role — its entire envelope lives
directly in `Engine::AnthropicBase`. We bring the Anthropic side in line with the OpenAI side:
move the Anthropic envelope methods/attributes into `Role::AnthropicCompatible`, and have
`AnthropicBase` compose it. This is a pure move — no behavior change — verified by the existing
request-body tests.

**Tech Stack:** Moose roles, existing test framework (`Test2::Bundle::More`, `prove -lr t/`).

## Global Constraints

- Moose exclusively; every `.pm` class ends with `__PACKAGE__->meta->make_immutable`;
  every `.pm` role uses `Moose::Role` and does NOT call `make_immutable`.
- `# ABSTRACT:` required on every `.pm`. Only `extends` classes; roles use `with`.
- Do NOT change request/response wire behavior. This is a structural refactor verified by
  unchanged unit tests.
- Respect ADR 0002 (capabilities derive from composed roles) and nuanciere ADR 0006 —
  a new ADR 0013 records this decision afterward.
- Beware: `Role::OpenAICompatible` is NOT self-contained — it assumes the composer brings
  `url` / `HTTP` / `Json` infra (normally via `extends Remote`). `Role::AnthropicCompatible`
  inherits the same assumption.
- Naming: `Role::AnthropicCompatible` (parallel to the existing `Role::OpenAICompatible`).
  A broader `Role::Engine::*` namespace rebrand of both is explicitly OUT of scope here.
- Booleans: `JSON->true` / `JSON->false` (import `JSON`), never `JSON::MaybeXS->true`.

---

### Task 1: Add `Role::AnthropicCompatible` with the moved envelope

**Files:**
- Create: `lib/Langertha/Role/AnthropicCompatible.pm`
- Modify: `lib/Langertha/Engine/AnthropicBase.pm`
- Test: `t/20_chat_requests.t` (existing — must stay green), `t/10_engine_hierarchy.t`

**Interfaces:**
- Consumes: the same infra `Role::OpenAICompatible` assumes (`url`, `generate_http_request`,
  `parse_response`, `json`, `user_agent`, `chat_model`, `get_response_size`, `has_temperature`,
  `reasoning_kwargs_for`, `prompt_cache_kwargs_for`, `knobs_kwargs_for`, `tool_wire_format`,
  `has_parallel_tool_use` / `parallel_tool_use`, `has_response_format` / `response_format`).
- Produces: every method/attribute currently public on `Engine::AnthropicBase` that encodes the
  Anthropic wire envelope, moved verbatim into the role (no signature changes).

**Move list** (from `AnthropicBase` → `Role::AnthropicCompatible`), keeping code byte-identical
except for the package name and the `use Moose::Role;` swap:

- `use` statements needed by moved code: `Carp qw(croak)`, `JSON::MaybeXS`,
  `Langertha::ToolChoice`, `Langertha::Tool`, `Langertha::Response`, `Langertha::ToolCall`.
- Attributes: `api_key` (+ `_build_api_key`), `api_version` (+ `_build_api_version`), `effort`,
  `inference_geo`.
- Envelope defaults: `content_format => 'anthropic'`, `default_response_size` (1024).
- Auth: `update_request` (x-api-key / content-type / anthropic-version headers).
- Chat: `chat_request`, `chat_response`, `Streaming`: `stream_format`, `chat_stream_request`,
  `parse_stream_chunk`.
- Structured-output emulation: `$SYNTH_RF_TOOL_NAME`, `_translate_response_format`,
  `_normalize_tool_params`.
- Wire-format default: `_build_tool_wire_format => 'anthropic'`, `_build_reasoning_wire_format
  => 'anthropic'`, `_build_cache_wire_format => 'anthropic'`.
- Models listing: `list_models_request`, `list_models_response`, `_fetch_all_models`,
  `list_models`.
- Rate limits: `_parse_rate_limit_headers`.

**Left in `AnthropicBase`** (composition + engine-specific shell, mirroring how `OpenAIBase`
keeps its shell):
- `extends 'Langertha::Engine::Remote'`.
- Composition: `with map { 'Langertha::Role::'.$_ } qw( Models Chat Temperature
  ReasoningEffort PromptCache ResponseSize SystemPrompt ResponseFormat Streaming Tools
  AnthropicCompatible )` — i.e. the same universal roles as today PLUS `AnthropicCompatible`.
- `around engine_capabilities` (delete `prompt_cache_key`) — keep here in the shell, because
  `OpenAIBase` keeps its own `around engine_capabilities` in the shell.
- `around BUILDARGS` (effort alias).
- `default_model` (abstract croak stub) — mirror `OpenAIBase`, which keeps `default_model` in
  the shell.

**Order of composition matters for Moose:** compose `AnthropicCompatible` in the `with` list
alongside the others. Since `Role::AnthropicCompatible` defines `list_models*` and `Models`
also defines `list_models`, confirm at runtime the composed method resolution is identical to
today (today `AnthropicBase` defines `list_models*` directly, overriding/alongside`Models`).
Run `t/50_list_models.t` and the request tests to confirm no method-conflict warning changes
from before.

- [ ] **Step 1: Create `lib/Langertha/Role/AnthropicCompatible.pm`** by moving the listed
  envelope code verbatim from `AnthropicBase`, changing `use Moose;` → `use Moose::Role;` and
  dropping `make_immutable` / `$VERSION`-safe header to match `Role::OpenAICompatible` style
  (keep `# ABSTRACT:`).
- [ ] **Step 2: Slim `Engine::AnthropicBase.pm`** to the shell described above.
- [ ] **Step 3: Run `prove -lr t/20_chat_requests.t t/50_list_models.t
  t/10_engine_hierarchy.t t/78_engine_capabilities.t`** — must pass exactly as before.
- [ ] **Step 4: Run the full suite `prove -lr t/`** and fix any method-conflict or
  hierarchy regression.
- [ ] **Step 5: Commit** — e.g. `Extract Anthropic wire envelope into Role::AnthropicCompatible`.

---

### Task 2: Documentation & ADR

**Files:**
- Create: `docs/adr/0013-wire-envelope-as-role-not-only-in-esbase.md`
- Modify: `docs/adr/0006-engine-inheritance-encodes-wire-dialect.md` (cross-reference note,
  not contradiction), `CLAUDE.md` (Architecture section), `CONTEXT.md` if it names the seam.

**Interfaces:** none (docs).

- [ ] **Step 1: Write ADR 0013** recording that the wire envelope is a composed role
  (`Role::OpenAICompatible` / new `Role::AnthropicCompatible`) composed by a thin base shell,
  nuanzierend ADR 0006 (inheritance still encodes the *transport* root `Remote`; the dialect
  envelope is now a role on both sides). Link to ADR 0002 (capabilities still derive from
  composed roles, unaffected by the move) and ADR 0006.
- [ ] **Step 2: Add an explicit note/pointer in ADR 0006** that the envelope moved to roles for
  the OpenAI and Anthropic dialects (see ADR 0013), without rewriting its rationale.
- [ ] **Step 3: Update `CLAUDE.md`** Role list (add `AnthropicCompatible`) and the engine
  hierarchy prose if it mentions `AnthropicBase` owning the envelope.
- [ ] **Step 4: Commit** docs + ADR.
