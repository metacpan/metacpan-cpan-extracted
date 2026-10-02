# Design Spec — Provider manifest `/.well-known/langertha.json` (karr k191)

- Status: **implemented** (branch k191, Phase 2)
- Date: 2026-09-25
- karr: k191 (this) · consumers: langertha-knarr k14 (auto export), langertha-skeid k29 (filtered export), langertha-raider (client)
- Origin: langertha-raider ADR 0007 "The provider manifest is declarative and lean in v1", handoff §11.1
- ADRs touched: relates **0002** (capability vocabulary), **0001** (tool_wire_format names), **0006** (engine inheritance encodes the wire dialect). Recorded as **ADR 0029** (fix round 1 of the review).

## 1. Problem & scope

`raider --provider host.tld` should fetch a manifest and just work; Knarr serves one
built from what it actually exposes, Skeid serves a filtered one per customer key.
All three need **one** schema and **one** data model. Core owns it: schema, value
objects, parser/validator, builder.

**In scope:** the v1 schema, Moose value objects, parsing from a JSON string or a
Perl hashref, validation, serialization to a hashref or JSON, and a builder that
maps a configured engine into a manifest.

**Out of scope (binding):** network I/O of any kind (no fetching of
`/.well-known`, no probing), alias management, secret binding, login / trust UI,
activation. Those belong to Raider (client side) and Knarr/Skeid (serving side).
MCP servers, packs, skills and default missions are **not** in v1 (ADR 0007: later,
as inactive references).

## 2. The v1 schema

A manifest is one JSON object. Exactly these fields exist; nothing else.

| Field | Type | Req. | Meaning |
|---|---|---|---|
| `schema_version` | integer | yes | Must be `1`. Any other value is rejected ("unsupported schema_version"). |
| `kind` | string | yes | Must be `"langertha-provider"`. |
| `provider_id` | string | yes | Stable provider slug, `^[a-z0-9][a-z0-9._-]*$`, max 128. |
| `issuer` | string | yes | Origin of the publisher, an `http`/`https` URL. |
| `endpoints` | array | yes | At least one Endpoint. |
| `auth` | array | no | Auth mechanisms (default `[]`). |
| `models` | array | no | Model entries (default `[]` — a filtered Skeid manifest may legitimately list none). |
| `extensions` | object | no | Inert, passed through untouched (default `{}`). |

**Endpoint** — `{ id, dialect, base_url, auth_ref? }`

| Field | Type | Req. | Meaning |
|---|---|---|---|
| `id` | string | yes | Local id, `^[A-Za-z0-9][A-Za-z0-9._-]*$`, max 64, unique among endpoints. |
| `dialect` | string | yes | Wire dialect (§5), token `^[a-z][a-z0-9-]*$`. |
| `base_url` | string | yes | `http`/`https` URL; exactly what a Langertha engine of this dialect takes as `url` (e.g. `https://api.openai.com/v1`, but `https://api.anthropic.com` — the dialect decides the path it appends). |
| `auth_ref` | string | no | Id of an `auth` entry. Absent = the endpoint needs no credentials (self-hosted vLLM, local Ollama). |

**Auth** — `{ id, type }`

| Field | Type | Req. | Meaning |
|---|---|---|---|
| `id` | string | yes | Local id (same pattern as endpoint ids), unique among auth entries. |
| `type` | string | yes | Mechanism token. v1 vocabulary: `api_key`. It describes the *mechanism only*; the header/query contract belongs to the dialect (Bearer for `openai-chat`, `x-api-key` for `anthropic`, `?key=` for `gemini`, key-in-body for `aki`). Which local credential feeds it is the **user's** decision (Raider). |

No env-var name, no key, no path. The orchestrator ruling allows "an env-var *name* at
most"; v1 does **not** use that allowance — the ticket's field list has none, and the
publisher's env-var naming means nothing to the client (ADR 0007: the user picks the
local credential reference). A key such as `env` / `api_key_env` is therefore rejected
as a secret-shaped field (§4).

**Model** — `{ id, endpoint_ref, capabilities? }`

| Field | Type | Req. | Meaning |
|---|---|---|---|
| `id` | string | yes | Model id as the endpoint expects it (`gpt-5.6`, `org/model:tag` — free-form, non-empty, no control characters, max 256). |
| `endpoint_ref` | string | yes | Id of an endpoint. |
| `capabilities` | object | no | `{ name: boolean }`. Names are `^[a-z][a-z0-9_]*$`. Default `{}`. |

`(id, endpoint_ref)` is the uniqueness key, not `id` alone: Knarr serves one model on
several protocol endpoints (OpenAI, Anthropic, Ollama) and lists it once per endpoint.

Example (v1, as the Builder emits it for an OpenAI engine):

```json
{
  "schema_version": 1,
  "kind": "langertha-provider",
  "provider_id": "openai",
  "issuer": "https://api.openai.com",
  "endpoints": [
    { "id": "chat", "dialect": "openai-chat",
      "base_url": "https://api.openai.com/v1", "auth_ref": "api" }
  ],
  "auth": [ { "id": "api", "type": "api_key" } ],
  "models": [
    { "id": "gpt-5.6", "endpoint_ref": "chat",
      "capabilities": { "chat": true, "streaming": true, "tools_native": true } }
  ],
  "extensions": {}
}
```

Note the capability names: the handoff §11.1 example says `tool_calling`; the
registry's name is `tools_native` (§6) — the example's name is not adopted.

## 3. Value objects

All Moose, immutable (`ro`), `make_immutable`, `# ABSTRACT:` + inline POD.

| Class | Holds | Key methods |
|---|---|---|
| `Langertha::Manifest` | `provider_id`, `issuer`, `endpoints` (ArrayRef[Endpoint]), `auth` (ArrayRef[Auth]), `models` (ArrayRef[Model]), `extensions` (HashRef); `schema_version` / `kind` are constants (`1`, `langertha-provider`) | `from_json($str)`, `from_hash($href)`, `to_hash`, `to_json`, `TO_JSON`, `endpoint($id)`, `auth_entry($id)`, `models_for_endpoint($id)` |
| `Langertha::Manifest::Endpoint` | `id`, `dialect`, `base_url`, `auth_ref` | `from_hash`, `to_hash`, `is_known_dialect`, class method `known_dialects` |
| `Langertha::Manifest::Auth` | `id`, `type` | `from_hash`, `to_hash`, `is_known_type`, class method `known_types` |
| `Langertha::Manifest::Model` | `id`, `endpoint_ref`, `capabilities` (HashRef of 1/0) | `from_hash`, `to_hash`, `supports($cap)` |
| `Langertha::Manifest::Validation` | — (a Moose role composed by the four classes above; internal, deliberately outside `Langertha::Role::`, not a capability) | all private: `_check_fields`, `_is_forbidden_field`, `_check_id` / `_check_token` / `_check_url`, `_string`, `_bool`, `_is_integer`, `_json_clone`, `_display`, `_error`, `_rethrow` |
| `Langertha::Manifest::Builder` | `provider_id`, `issuer`, accumulated entries | `add_engine($engine, %opt)`, `add_endpoint`, `add_auth`, `add_model`, `extensions`, `manifest`; class sugar `from_engine($engine, %opt)` |

JSON goes through `JSON::MaybeXS` configured like the house instance
(`utf8 => 1, canonical => 1`), so `to_json` is byte-stable and a roundtrip
`from_json → to_json → from_json` is the identity. Capability booleans serialize as
JSON `true`/`false`.

Validation runs in the constructors (Moose type constraints + `BUILD`), so a
`Langertha::Manifest` object is valid by construction whether it came from JSON,
from a hashref, from `new`, or from the Builder. `from_hash` additionally performs the
raw-shape checks (field sets) that a typed constructor cannot see. Errors `croak` with
a path: `Langertha::Manifest: endpoints[0]: unknown field 'foo'`.

## 4. Validation rules

1. **Shape.** The document is a JSON object; `endpoints`/`auth`/`models` are arrays of
   objects; `capabilities` and `extensions` are objects. Invalid JSON croaks with the
   decoder's message.
2. **Version.** `schema_version` must be the integer `1`. Missing → error; non-integer
   → error; another integer → `unsupported schema_version N (this Langertha reads 1)`.
   Checked **first**, before the field set: a document of another major version may
   carry fields v1 does not know, and the useful error is then the version, not
   "unknown field".
3. **Kind.** `kind` must be `langertha-provider`.
4. **Forbidden fields (explicit, before the unknown-field check).** At the top level and
   in every endpoint / auth / model object, a key whose name — split into lower-case
   words on `_`, `-`, `.` and camelCase boundaries — contains a forbidden word is
   rejected with `forbidden field 'X' … a manifest never carries commands, code,
   secrets or prompts`. Forbidden words:
   - command-like: `command`, `commands`, `cmd`, `exec`, `shell`, `script`, `run`, `install`, `hook`, `hooks`
   - code: `class`, `module`, `package`, `code`, `eval`, `require`, `plugin`, `plugins`, `perl`
   - secret-path / secret: `secret`, `secrets`, `password`, `token`, `credential`, `credentials`, `key`, `apikey`, `env`, `path`, `file`
   - prompt / tool injection (ADR 0007: later, as inactive refs): `prompt`, `mission`, `mcp`, `packs`, `skills`, `tools`

   No v1 field name contains any of these words, so the check has no false positive on
   a valid manifest. Capability names and `extensions` are not scanned (see 7).
5. **Unknown fields.** Any other key not in the §2 field set is rejected
   (`unknown field 'X'`), at the top level and inside every entry.
6. **Values.**
   - ids / `provider_id` / `dialect` / auth `type` / capability names match their patterns.
   - `issuer` and `base_url` are printable-ASCII `http` or `https` URLs with a host,
     **no userinfo** (`user:pass@`), **no query**, **no fragment** — the usual places a
     secret hides in a URL (`?key=…`). Best effort: a secret embedded in the path
     (`/key/SECRET/v1`, `;key=SECRET`) cannot be told from a real path.
   - model ids carry no control, format (bidi override U+202E), surrogate, private-use,
     unassigned or line/paragraph-separator characters; field names echoed in errors
     are escaped (`\x{1b}`) and truncated — a client prints both.
   - string fields reject objects/arrays; a JSON number in a string field is
     stringified (`"id": 42` serializes back as `"42"`).
   - `schema_version` is a JSON **number with a whole value** (`1`, `1.0`, `1e0` alike —
     the same verdict on JSON::PP and Cpanel::JSON::XS); the string `"1"` and a numified
     Perl string such as `"1abc"` are rejected (numeric slot required, and a cached string
     must be a plain JSON number).
   - capability values are booleans (JSON `true`/`false`; from Perl also the numbers
     `1`/`0`, `\1`/`\0`); strings, including the JSON string `"1"`, are rejected.
   - endpoint ids unique, auth ids unique, `(model id, endpoint_ref)` unique.
   - every `auth_ref` names an auth entry; every `endpoint_ref` names an endpoint.
   - at least one endpoint.
7. **`extensions` is inert.** It must be an object of plain JSON data (no blessed
   objects other than JSON booleans, no code refs); beyond that its content is neither
   validated nor interpreted, and it serializes as given. It is deep-copied on
   construction and every read returns a fresh copy, so the manifest stays immutable.
8. **Vocabulary is not validity.** A pattern-valid but unknown `dialect` or auth `type`
   is *accepted*; `is_known_dialect` / `is_known_type` tell a client whether it has an
   adapter. Rationale: ADR 0007's four states — what the provider claims vs. what the
   adapter understands are different questions; rejecting the whole manifest because a
   newer publisher adds one dialect would couple every client to the publisher's core
   version. Capability names likewise are claims, not a closed set
   (`Engine::Gemini` already emits `thinking_budget`, which is not in `%ROLE_TO_CAPS`).

## 5. The `dialect` vocabulary

Derived from the engine hierarchy (ADR 0006: inheritance encodes the wire dialect) and
named after the `tool_wire_format` tag wherever the two coincide:

| dialect | engine family | `tool_wire_format` |
|---|---|---|
| `openai-chat` | `Engine::OpenAIBase` (OpenAI, DeepSeek, Groq, vLLM, SGLang, LlamaCpp, NousResearch, …) | `openai` (or `hermes`) |
| `responses` | `Engine::OpenAIResponses` (`/v1/responses`) | `responses` |
| `perplexity-agent` | `Engine::Perplexity` (Open-Responses envelope on `/v1/agent`) | — (no tools) |
| `anthropic` | `Engine::Anthropic` (first-party Messages API: native `output_config.format`) | `anthropic` |
| `anthropic-compat` | the `/anthropic` shims (AKIAnthropic, MiniMaxAnthropic, MoonshotAnthropic, LMStudioAnthropic: structured output as synthetic tool + forced choice) | `anthropic` |
| `gemini` | `Engine::Gemini` | `gemini` |
| `ollama` | `Engine::Ollama` (native `/api/chat`) | `ollama` |
| `aki` | `Engine::AKI` (native `/api/call/{model}`) | `openai` |
| `lmstudio` | `Engine::LMStudio` (native) | `openai` |

`anthropic` vs `anthropic-compat`: the dialect names the wire variant a client adapter
must speak, not only the envelope. The Builder decides it from the engine's own
predicate `_native_structured_output` (`Role::AnthropicCompatible`), not from a name list.

`openai-chat` rather than `openai`: the dialect names an *envelope*, and OpenAI ships
two (`/chat/completions` and `/responses`); the suffix keeps them apart. `hermes` is a
tool format riding `openai-chat` and appears as the `tools_hermes` capability, not as
a dialect. `Engine::TranscriptionBase` / `Whisper` is transcription-only and has no
chat dialect: the Builder croaks for it.

## 6. Builder

`Langertha::Manifest::Builder->new( provider_id => …, issuer => … )`, then
`add_engine($engine, %opt)` one or more times, then `->manifest`. Sugar:
`Langertha::Manifest::Builder->from_engine($engine, %opt)` returns the Manifest.
The low-level `add_endpoint` / `add_auth` / `add_model` exist for Knarr and Skeid,
whose endpoints are their own protocol routes, not engines.

`add_engine` mapping (no network I/O — never calls `list_models`):

| Manifest field | Source |
|---|---|
| `provider_id` (if not given) | engine class: strip `Langertha::Engine::`, else last `::` segment; lower-case (`vLLM` → `vllm`) |
| `issuer` (if not given) | scheme + host (+ non-default port) of `$engine->url` |
| endpoint `id` | `%opt{endpoint_id}`, default `chat` |
| endpoint `dialect` | ordered `isa` table of §5, most specific first (`dialect_for_engine`); `%opt{dialect}` overrides (third-party engines); croak if none |
| endpoint `base_url` | `$engine->url` (`%opt{base_url}` overrides — Knarr publishes its public URL, not an internal one) |
| auth | class-level `api_key_required` / `api_key_env` (`Engine::Remote`): *required* → `api_key` entry (id `%opt{auth_id}` // `api`); *optional* → only if the engine has a key configured (definedness is checked, the value is never read into the manifest); *none* → no auth. `%opt{auth}` = `api_key` / `none` overrides. |
| models | `%opt{models}` (ArrayRef of ids). Otherwise the engine's model, read on an in-memory clone; a placeholder id (`default`, empty) is skipped; a model-less engine croaks asking for `models`. With `models` given, the engine's own `chat_model` is never read — model-less engines (OpenRouter, OllamaOpenAI) work. |
| model `capabilities` | `engine_capabilities` evaluated **for that model id**: the engine is cloned with `chat_model => $id` (Moose `clone_object`, in memory only) so layer 3 (`model_capability_corrections`, ADR 0019) and model-aware `around engine_capabilities` (Gemini) apply per model. Then filtered to `Builder->model_capabilities` (below). The caller's engine is never read for lazy slots and never modified. |

Capability names are exactly what `engine_capabilities` returns — the `%ROLE_TO_CAPS`
vocabulary plus the engines' own documented corrections. The Builder introduces no
names and no synonyms.

**Model-scoped allowlist** (`@MODEL_CAPABILITIES` in the Builder, exposed as
`model_capabilities`): a model entry claims only what describes a chat call to that
model at that endpoint — `chat`, `streaming`, `tools_native`, `tools_hermes`,
`tool_choice_{auto,any,none,named}`, `parallel_tool_use`,
`response_format_json_{object,schema}`, `reasoning_effort`, `thinking_budget`,
`temperature`, `seed`, `system_prompt`, `response_size`, `prompt_cache`,
`prompt_cache_key`. Never published on a model: `embedding`, `transcription`,
`image_generation` (other operations), `runtime_metrics`, `prefix_caching`,
`keep_alive`, `cached_content`, `context_size` (client-side / server-management; `context_size` is Ollama's server-side `num_ctx`). A placeholder-only engine (model `default`) warns once that its endpoint is published without models. A guard test fails
on any capability an engine reports that is in neither list. The filter applies only
to what the Builder emits; a parsed manifest accepts any name.

**Known v1 limitations:** engine-class facts outside the flag vocabulary are not
expressed — the Groq/Cerebras refusal of `tools` + `response_format` in one request
(ADR 0024) and OpenAI's temperature gate under active reasoning (ADR 0025).

**Atomicity:** `add_engine` builds and checks every entry first (duplicate endpoint
id, duplicate `(model, endpoint)` pair, auth type conflict) and only then commits;
a croak leaves the builder unchanged. `add_model` / `add_auth` check duplicates at
add time.

**Secrets:** the Builder never reads `api_key`'s value into any structure; a test
constructs engines with a sentinel key and asserts the sentinel appears nowhere in
`to_json`. Userinfo/query in `$engine->url` are rejected by the Endpoint validator,
so a key smuggled into a URL cannot be published either.

## 7. Tests

- `t/96_manifest.t` — roundtrip (hash → object → hash, JSON → object → JSON → object),
  extensions passed through untouched, lookups, boolean handling.
- `t/96_manifest_rejections.t` — one negative test per rule in §4.
- `t/96_manifest_builder.t` — offline engines OpenAI, Groq, OpenAIResponses, Anthropic
  and the four shims, vLLM (with `url`, with/without model and key), Ollama,
  OllamaOpenAI/OpenRouter without a model, Gemini: dialect, base_url, auth, per-model
  allowlisted capabilities, no secret leakage, the caller's engine untouched,
  atomicity, multi-endpoint build, Whisper croaks, capability classification guard.

## 8. Not decided here

- Size / time / redirect limits and origin rules for *fetching* (Raider, ADR 0007).
- Whether a future `schema_version` 2 carries MCP / pack references (as inactive
  `extensions`-style refs) — v1 rejects those fields outright.
- RFC 8615 registration of the well-known name.
