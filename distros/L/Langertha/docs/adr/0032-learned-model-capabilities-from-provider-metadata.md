# ADR 0032 — Learned model capabilities: an explicit probe of the provider's own model metadata

- Status: accepted
- Date: 2026-09-25
- Tags: capabilities, model-scoped, image_input, value-objects, manifest, self-hosted, gateways
- Cross-links: ADR 0002, ADR 0019, ADR 0029, ADR 0027, ADR 0001
- karr: #270

## Context

`image_input` is model-scoped (ADR 0019 k266 Update): a true flag says the selected
`chat_model` sees an image. Cloud engines answer from static tables. Gateways (OpenRouter) and
self-hosted servers (Ollama, LM Studio, llama.cpp) could not: the model behind them is unknown
to the client, so they made no claim at all, and a knarr `/api/show` or a manifest built on them
said "no vision" for `llava` and `gpt-4o` alike.

These providers do publish the fact, in their own model metadata:

| Engine(s) | Endpoint | Field |
|---|---|---|
| OpenRouter | `GET {url}/models` | `data[].architecture.input_modalities` contains `image` |
| Mistral | `GET /v1/models` | `data[].capabilities.vision` (per `id` and `aliases`) |
| LMStudio, LMStudioOpenAI | `GET /api/v1/models` (native, beside `/v1`) | `models[].capabilities.vision` |
| Ollama, OllamaOpenAI | `POST /api/show {model}` (beside `/v1`) | `capabilities` contains `vision` |
| LlamaCpp | `GET /props` (beside `/v1`) | `modalities.vision` |

Shapes from each provider's documentation (lmstudio.ai `rest/list`, llama.cpp
`tools/server/README.md`, ollama `docs/api.md`, openrouter.ai models guide, Mistral models
endpoint reference), read 2026-09-25. None was live-verified; the test fixtures are shaped from
those documents.

Reading this metadata costs a request. `supports()` is called on hot paths (the `chat_f`
rewrite matrix, ADR 0005) and must never do network I/O.

## Decision

1. **An explicit, opt-in probe.** `$engine->probe_model_capabilities_f(models => [...])`
   (sync wrapper `probe_model_capabilities`) fetches the engine's metadata endpoint and stores
   the learned facts in a per-instance store, `{ $model_id => { $cap => 0|1 } }`. Without
   `models` it asks about `chat_model`. A document that describes every model (OpenRouter,
   Mistral, LM Studio) is fetched once and every model in it is learned; Ollama is asked once
   per model; llama.cpp serves one model, so its fact is stored under every id that was asked
   about. Nothing probes implicitly. `learned_model_capabilities` returns a copy of the store,
   `clear_learned_model_capabilities` empties it. Only non-empty plain strings are model ids
   (in `models` and in the documents). A model Ollama does not have (`/api/show` 404) gives no
   fact and the other models of the call are kept; any other non-success answer, or a success
   answer that is not JSON, fails the future with an engine-named error and stores nothing.

   Looking a fact up for `chat_model` is exact first, then the format's equivalent spelling
   (`ModelProbe->lookup_ids`): on Ollama a missing tag is `:latest` (`llava` ↔ `llava:latest`);
   on OpenRouter a routing variant (`:online`, `:free`, `:nitro`, …) falls back to its base id
   when the variant itself is not listed. Other formats match exactly. This is ADR 0018's
   "normalize, don't gatekeep" applied to ids the provider itself treats as the same model.

2. **A fourth layer, after layer 3.** `engine_capabilities` applies the learned facts for the
   current `chat_model` right after the static `model_capability_corrections` table, inside the
   base method. For a model the probe reported, **the probe is authoritative in both
   directions**: static no-claim + probe yes → yes; static yes + probe no → no. A model the
   document does not describe, or describes without the field, gets no fact and keeps its static
   answer.

3. **Two gates stay absolute.** A learned `1` re-asserts a flag only if the composed roles grant
   it (layer 1: the wire can carry the part at all). The engine's `around engine_capabilities`
   (layer 2) still wraps the whole method, so an endpoint that never carries the field stays
   closed whatever the metadata says. This is ADR 0019's "the endpoint gate is absolute", kept.

4. **The gateway / self-hosted no-claim moves from layer 2 to layer 3.** It was never a wire
   fact ("the endpoint cannot carry images"), only "the client does not know the model". On the
   probing engines (OpenRouter, Ollama, OllamaOpenAI, LMStudio, LMStudioOpenAI, LlamaCpp) the
   `delete $caps->{image_input}` in the `around` became a catch-all row
   `qr/\A/ => { image_input => 0 }`, so the learned layer can answer over it. Engines without a
   probe keep their layer-2 clear.

5. **The table walk resolves a croaking `chat_model` as no model.** OpenRouter and OllamaOpenAI
   have no default model; building `chat_model` croaks. `Role::Capabilities::_capability_model`
   turns that croak into `undef`, which the walk matches as `''` (the ADR 0019 k209 rule), so
   `supports()` keeps answering on a model-less engine with a catch-all row. The only other
   engine with a croaking default and a table, Groq, already returns an empty table without a
   model, so nothing changes there.

6. **Parsing lives on a value-object door keyed by a per-concern tag.** `Langertha::ModelProbe`
   (class methods, no I/O) reads a decoded document per `model_metadata_format`
   (`openrouter` | `mistral` | `lmstudio` | `ollama` | `llamacpp`), like the tool value objects
   are keyed by `tool_wire_format` (ADR 0001). An engine opts in with two hooks,
   `model_metadata_format` and `model_metadata_url`; the defaults are `undef`, and then the probe
   resolves to `{}` without a request. The two LM Studio faces and the two Ollama faces share a
   format across different parents without a new role.

7. **Scope: `image_input` only.** `ModelProbe->probed_capabilities` is the allowlist of what a
   probe may learn. Other fields in the same documents (Ollama `tools` / `thinking`, OpenRouter
   `supported_parameters`, LM Studio `trained_for_tool_use` / `reasoning`, Mistral
   `function_calling`) are not read: those flags drive the `chat_f` rewrite matrix (ADR 0005),
   where a learned fact would change what is sent, while `image_input` is advisory.

8. **The manifest publishes learned facts without extra code.** `Manifest::Builder` evaluates
   `engine_capabilities` per model on a `clone_object` of the engine; the clone shares the store,
   so a probed engine publishes its facts (ADR 0029). The store is replaced on write, never
   mutated in place, so a probe on a clone never writes into its source.

## Rationale

- **Opt-in, not lazy.** A lazy probe inside `supports()` would put a blocking request (or an
  unresolved Future) under `chat_f`, `Manifest::Builder` and knarr's request path. The caller
  knows when a network round-trip is acceptable (server start, manifest build); core does not.
- **Authoritative in both directions.** The static tables are documentation-derived and dated;
  the provider's own metadata describes the model actually served, including a quantized or
  renamed local build. Letting a static yes survive a provider no would keep a claim the
  provider itself contradicts.
- **After layer 3, not after layer 2.** Putting the learned layer outermost would need an
  `around` that is guaranteed to wrap every engine's own `around`, which Moose cannot promise
  across `with`/`around` order. Placing it inside the base method is deterministic, and keeping
  layer 2 on top preserves the wire gate. The price is decision 4: a "no claim" that should be
  overridable must live in layer 3.
- **A format tag, not engine methods.** Four of the five formats have two consumers from
  different parents (LMStudio/LMStudioOpenAI, Ollama/OllamaOpenAI). A value-object door keeps
  the parsers in one place without a `Role::<X>Compatible` extraction (ADR 0016).

## Consequences

- `supports('image_input')` on the probing engines answers per model after a probe; before one,
  every answer is unchanged (asserted in `t/78_image_input_capability.t` and
  `t/78_model_capability_probe.t`).
- `engine_capabilities` has four layers in evaluation order: role map (1), static per-model
  table (3), learned facts, then the engine `around` (2) on the outside.
- The store is per engine instance and in memory. knarr, which caches engine instances, keeps
  facts across requests; a fresh instance knows nothing until probed.
- A failed probe (non-2xx) fails the future with `<engine> model metadata probe failed:
  <status> - <body>` and stores nothing.
- LlamaCpp facts are keyed by the id asked about (`default` unless a model is configured);
  `Manifest::Builder` skips the `default` placeholder, so a manifest of a llama.cpp server needs
  `probe_model_capabilities(models => [$published_id])` first.

## Future work

- **TSystems.** The advisor named `meta_data.input_modalities` on its models endpoint, but the
  public docs (docs.llmhub.t-systems.net, API endpoints page) document `GET /v2/models` without a
  response schema, and no key exists to check it. Not implemented; `probe_model_capabilities_f`
  resolves to `{}` there.
- **Anthropic** `/v1/models` `capabilities.image_input` would be a cross-check of the static
  Claude table; not implemented (the static answer is already "yes" for Claude 3+).
- **LMStudioAnthropic** talks to the same LM Studio server as the other two faces and could
  reuse the `lmstudio` format; not composed yet.
- **More capabilities** (tools, reasoning) from the same documents need their own decision,
  because they change what `chat_f` sends.

## Update (k282 — sharing learned facts across instances: `models => 'all'` + `import_learned_capabilities`)

The store stays per instance (decision 1), but a gateway that holds one engine instance per
discovered model (knarr k37: 300 OpenRouter slugs) would fetch the same catalogue once per
instance. Sharing is now **public and explicit**, still with no hidden I/O and no global cache:

- `probe_model_capabilities_f(models => 'all')` learns every model a catalogue document names,
  from one request, and does not fall back to `chat_model`. A format is a catalogue when its
  document names its models (`ModelProbe->is_catalogue`: `openrouter`, `mistral`, `lmstudio`);
  on `ollama` (one model per request) and `llamacpp` (the document does not name its model)
  `'all'` croaks before any request. The resolved value is exactly the facts this call merged
  into the store, as a fresh HashRef the caller owns.
- `import_learned_capabilities(\%map)` merges `{ $model_id => { $cap => 0|1 } }` (a probe result
  or another instance's `learned_model_capabilities`) into this instance's store, with the same
  rules as a probe: only `probed_capabilities` are taken (other names ignored), only non-empty
  string ids, values normalized to `0|1` (a JSON boolean counts; `undef` and unblessed references
  are no fact), later facts win, the store is replaced not mutated (clones stay independent).
  Imported facts sit in the learned layer exactly like probed ones, so both wire gates (layers 1
  and 2) still hold. It croaks on a non-HashRef and returns what it merged.

Why not a shared store object passed at construction (keyed by metadata URL, with a TTL): it
would put cache lifetime and invalidation policy into core, and a per-URL key is not an identity
the engine owns (proxies, rewritten base URLs). The caller already decides when a round-trip is
acceptable (Rationale, "opt-in, not lazy"); it now also decides which instances share. Facts are
keyed by model id, not endpoint, so importing into an engine on a different endpoint is the
caller's error to avoid.

## Update (k281 — TSystems probe: `tsystems` format from the public OpenAPI, docs-derived)

The Future-work TSystems item is done. The public OpenAPI document of the LLM server
(`llm-server.llmhub.t-systems.net/openapi.json`) does give the response schema the docs page
lacked: `GET /v2/models` returns `data[].meta_data` with a nullable `input_modalities` array of
strings. `Engine::TSystems` now declares `model_metadata_format` `tsystems` and
`model_metadata_url` = `{url}{list_models_path}` (the engine base already ends in `/v2`, so this
is the documented `/v2/models`). `ModelProbe` reads it as a catalogue (`is_catalogue`, so
`models => 'all'` works): facts keyed by `id`; `image` in the list means the model sees images,
**matched case-insensitively** because the schema types the entries as strings without fixing
their spelling (ADR 0018, normalize, don't gatekeep); a missing `meta_data`, or a missing or
`null` `input_modalities`, gives no fact, so the static table (catch-all no-claim plus the
documented vision rows, k266/k280) keeps answering for that model.

Documentation-derived only: no TSystems key exists (CLAUDE.md), the fixture
`t/data/tsystems_models_probe.json` is shaped from the schema, not captured, and model ids are
matched exactly (the docs spell ids inconsistently; the static rows are case-insensitive, the
learned lookup is not). Revisit the id matching if a real answer ever shows ids that differ
from what callers configure.

## Update (k344 — `image_input` now picks the tool-result image form)

Decision 7 limits probing to `image_input` because that flag "is advisory" and a learned fact
should not change what is sent. Since k344 the flag has one reader that does change it:
`Role::Tools::format_tool_results` sends a tool's image as an image part on the `responses` and
Gemini 3 wires only when the model claims `image_input`, and as a text placeholder otherwise
(ADR 0001 and ADR 0019 k344 Updates). The scope stays `image_input` only. No probing engine
(OpenRouter, Mistral, Ollama, OllamaOpenAI, LMStudio, LMStudioOpenAI, LlamaCpp, TSystems) is on
either wire, so no learned fact changes a request today. An engine on `responses` or `gemini` that
gains a probe must treat a wrong learned `image_input` as request-changing: it can put an image
part into a tool-loop turn the model rejects.

## Update (k365 — LMStudioAnthropic probes too: the first probing engine on the `anthropic` wire)

The Future-work LMStudioAnthropic item is done. The Anthropic face talks to the same LM Studio
server as the other two, and its `url` is the server root (the envelope appends
`/v1/messages`; lmstudio.ai `anthropic-compat` gives `http://localhost:1234` as the base URL), so
`model_metadata_url` is `server_root_url($url) . '/api/v1/models'`, the document the other two
faces read, with format `lmstudio`. As there (decision 4), the layer-2
`delete $caps->{image_input}` became the layer-3 catch-all `qr/\A/ => { image_input => 0 }`, so a
learned fact can answer per model; `AnthropicBase` composes `Role::ImageInput`, so the layer-1
wire gate lets a learned `1` through.

One wire difference: LM Studio documents its API token only as `Authorization: Bearer` for the
native REST API, while this engine sends it as `x-api-key` (documented for `/v1/messages`). With
"Require Authentication" on, the probe would 401, so the engine adds the Bearer header to the
probe request only (`around update_request`, matched on `model_metadata_url`); chat requests are
unchanged. Documentation-derived, not live-verified, like the rest of this ADR's fixtures.

The k344 paragraph above said no probing engine is on a wire where `image_input` changes a
request. This engine is on `anthropic`, and the tool-result image form on that wire is gated on
`image_input` (k359, ADR 0001/0019), so a learned fact here is request-changing in the same way:
a wrong learned `1` sends an image block into a tool-loop turn of a model that cannot read it.
