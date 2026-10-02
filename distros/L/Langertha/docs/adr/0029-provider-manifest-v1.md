# ADR 0029 — Provider manifest v1: strict structure, open values, a dialect vocabulary and a model-scoped capability allowlist

- Status: accepted
- Date: 2026-09-25
- Tags: manifest, provider-discovery, capabilities, value-objects, security, ecosystem
- karr: #191

## Context

langertha-raider ADR 0007 decided that a provider publishes a declarative, lean manifest at
`/.well-known/langertha.json`. Raider reads it as a client (`raider --provider host.tld`),
Knarr exports one from what it actually exposes, and Skeid exports a filtered one for each
customer key. The same ADR assigns ownership: core owns the schema, the value objects, the
parser/validator and the builder. Raider owns trust, aliases, secret binding and activation.
Knarr and Skeid own publishing.

Three distributions will build on this document, so its semantics are a public contract that
is expensive to change once shipped. Four questions had to be settled:

- how strict validation is;
- what `dialect` names;
- which capabilities a model entry may claim;
- where secrets stop.

Design spec: `docs/superpowers/specs/2026-09-25-provider-manifest-design.md`.

## Decision

1. **Scope and classes.** Schema version 1 contains exactly `schema_version` (a JSON number
   whose value is the whole number `1` — `1`, `1.0` and `1e0` alike, with the same verdict
   on every JSON backend; the string `"1"` is rejected), `kind` (`langertha-provider`), `provider_id`, `issuer` and `endpoints`
   (`id`, `dialect`, `base_url`, optional `auth_ref`). It also contains `auth` (`id`, `type`),
   `models` (`id`, `endpoint_ref`, `capabilities`) and an inert `extensions`.
   - The classes are `Langertha::Manifest` with `::Endpoint`, `::Auth` and `::Model`. The
     shared rules live in the internal role `::Validation`, and `::Builder` maps engines to
     manifests.
   - Core does no network I/O here: no fetching, no aliases, no login. Parsing takes a string
     or a hashref; serialization produces a hashref or canonical JSON.
   - `(model id, endpoint_ref)` is the uniqueness key, because a proxy serves one model on
     several protocol endpoints.

2. **Strict structure, open values.**
   - **Structure is closed.** A field outside the schema is rejected, both at the top level
     and in every entry. A field name containing a command, code, secret or prompt word is
     rejected with an explicit reason. `schema_version` is checked before anything else, so
     a v2 document reports its version rather than an "unknown field". URLs must be
     printable ASCII over http/https, with no userinfo, query or fragment. Model ids must not
     contain control or format characters.
   - **Values are open.** A pattern-valid but unknown `dialect`, auth `type` or capability
     name is accepted. `Endpoint->is_known_dialect` and `Auth->is_known_type` answer whether
     the client has an adapter; a client treats an unknown capability as absent.
   - `extensions` must hold plain JSON data. Core deep-copies it and never interprets it.

3. **No secrets, including no env-var name.**
   - An `auth` entry names only a mechanism (v1: `api_key`). The header, query or body
     contract belongs to the dialect.
   - An env-var name is not published either. The publisher's variable name means nothing to
     the client, and ADR 0007 leaves the choice of credential to the user. `env` and
     `api_key_env` are rejected as secret-shaped fields.
   - The Builder decides auth from the engine class's `api_key_required` / `api_key_env`. It
     checks only whether a key is defined, and does so on an in-memory clone; the key's
     value never enters the manifest.

4. **Dialect vocabulary.** A dialect names the wire variant a client adapter must speak. It
   follows the engine hierarchy (ADR 0006) and reuses the `tool_wire_format` names where the
   two coincide:
   - `openai-chat` (the `Engine::OpenAIBase` family);
   - `responses` (`Engine::OpenAIResponses`);
   - `perplexity-agent`;
   - `anthropic` (first party, native `output_config.format`);
   - **`anthropic-compat`** (the `/anthropic` shims, which emulate structured output with a
     synthetic tool plus a forced choice);
   - `gemini`, `ollama`, `aki` and `lmstudio`.

   `openai-chat` carries its suffix because OpenAI has two envelopes. Hermes is the
   `tools_hermes` capability, not a dialect. The Builder tells the two Anthropic variants
   apart with the engine's own predicate `_native_structured_output`
   (`Role::AnthropicCompatible`), not with a list of engine names.

5. **Model-scoped capability allowlist.** A Builder-made model entry claims only capabilities
   that describe a chat call to that model at that endpoint:
   - `chat` and `streaming`;
   - the tool flags: `tools_native`, `tools_hermes`, `tool_choice_*` and `parallel_tool_use`;
   - `response_format_json_{object,schema}`;
   - `reasoning_effort` and `thinking_budget`;
   - `temperature`, `seed`, `system_prompt` and `response_size`;
   - `prompt_cache` and `prompt_cache_key`.

   Flags that describe other operations of the engine (`embedding`, `transcription`,
   `image_generation`) are never published on a model. Neither are client-side or
   server-management features (`runtime_metrics`, `prefix_caching`, `keep_alive`,
   `cached_content`, and `context_size`, which is Ollama's server-side `num_ctx` allocation).

   How the list is built and kept honest:
   - The allowlist is one list in the Builder (`@MODEL_CAPABILITIES`, exposed as
     `model_capabilities`).
   - The names come from the `%ROLE_TO_CAPS` registry (ADR 0002); the Builder adds no names
     and no synonyms.
   - The values are `engine_capabilities` evaluated per model, on a clone whose
     `chat_model` is set to that model, so the model-scoped corrections of ADR 0019 apply.
   - A guard test fails on any flag that is in neither the allowlist nor the documented
     exclusion list.
   - The filter applies only to what the Builder emits. A parsed manifest accepts any name.

## Rationale

- **Strict structure** is what makes the security promise enforceable. A remote document can
  only contain what the closed field set lets through; the forbidden-word list merely makes
  the error say why.
- **Open values** follow ADR 0007's rule that what the provider claims and what the adapter
  understands stay separate. Rejecting a whole manifest because a newer publisher added one
  dialect would lock every client to the publisher's core version.
- **The dialect must name the wire variant, not just the envelope.** A client keyed on
  `anthropic` would send `output_config.format` to a shim that only understands the
  synthetic-tool emulation.
- **Publishing the whole capability set would be dishonest.** It would claim `transcription`
  on a Groq chat model and `runtime_metrics` behind a proxy URL that does not serve
  `/metrics`. Once three distributions read such flags, removing them is a breaking change,
  so the allowlist is fixed before the first release.

## Consequences

- Knarr and Skeid build manifests with `Langertha::Manifest::Builder` (`add_engine` for
  engines; `add_endpoint` and `add_model` for their own protocol routes). Raider parses them
  with `Langertha::Manifest->from_json`.
- Adding a capability to `%ROLE_TO_CAPS` now also requires classifying it for the manifest,
  and the builder test enforces that.
- **Known v1 limitations:** some engine-class facts cannot be expressed with the flag
  vocabulary, so the manifest does not carry them:
  - the Groq/Cerebras refusal of `tools` plus a structured-output `response_format` in one
    request (ADR 0024);
  - OpenAI's temperature gate under active reasoning (ADR 0025);
  - native structured output per model on an `anthropic-compat` shim: `MoonshotAnthropic`
    sends `output_config.format` on `kimi-k3` only (ADR 0005 k218 Update), but the dialect
    names the endpoint, so a manifest-driven client still takes the synthetic tool plus a
    forced named `tool_choice` there.

  A client that needs these must still know the engine class.
- **Relations:**
  - extends ADR 0002 (the capability vocabulary is reused, and a published subset is
    defined);
  - applies ADR 0006 (inheritance encodes the wire dialect) and refines it with
    `anthropic-compat`;
  - consumes ADR 0019 (per-model capabilities through `chat_model`);
  - follows ADR 0026 (siblings depend on core, and this contract lives in core for them);
  - implements langertha-raider ADR 0007.

## Future work

- Align the example in the raider handoff §11.1 and raider ADR 0007 (`tool_calling` →
  `tools_native`, plus `anthropic-compat`). Tracked as karr k198 (tagged `raider`).
- Fetch limits, origin rules and RFC 8615 registration belong to Raider and to publication,
  not to core.

## Update (k206 — `server_tools` joins the model capability allowlist)

`server_tools` (ADR 0030, from `Role::ServerTools`) describes a chat call to a model — the
request may carry provider-native server-side tools — so it joins `@MODEL_CAPABILITIES` and is
evaluated per model (a layer-3 correction can clear it). Known v1 limitation: the manifest says
*that* a model takes server tools, not *which* types; a client must still expect a provider 400
for a type the model does not offer. No dialect row changes: `OpenAIResponses` already maps to
`responses`. The `XAIResponses` row (it isa `OpenAIBase`, so it would read `openai-chat`) comes
with that engine in Phase 1b.
