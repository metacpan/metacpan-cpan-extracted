# ADR 0013 — The wire envelope is a composed role, not only an engine-base concern

- Status: accepted
- Date: 2026-08-14
- Tags: engines, inheritance, roles, composition, wire-format, symmetry

## Context

ADR 0006 split the two engine axes across Perl's two composition mechanisms: inheritance
encodes the *wire dialect* (the envelope), roles encode *capabilities*. In practice that split
was applied asymmetrically:

- **OpenAI side:** the entire OpenAI wire envelope (chat/stream/image/embedding/transcription
  request+response, `update_request` auth header, `_parse_rate_limit_headers`, models
  listing) already lives in a **role**, `Role::OpenAICompatible`. `Engine::OpenAIBase` is a
  thin shell: it `extends Remote` and composes that role plus the universal chat roles, and
  nothing more.
- **Anthropic side:** there was **no** `Role::AnthropicCompatible`. The entire `/v1/messages`
  envelope (api_key/api_version/effort/inference_geo, chat_request/response,
  chat_stream_request/parse_stream_chunk, `_translate_response_format` /
  `_normalize_tool_params`, `_parse_rate_limit_headers`, models listing) lived **directly in
  `Engine::AnthropicBase`** — a class, not a composed role.

So the two dialects that dominate the tree were not "equally solved": one envelope was a
reusable, composable unit; the other was welded into a base class. That asymmetry also made the
Anthropic envelope impossible to compose onto a custom engine without inheriting the whole
`AnthropicBase` shell, and it kept the wire dialect and the composition shell entangled on the
Anthropic side while OpenAI already separated them.

## Decision

Extract the Anthropic wire envelope from `Engine::AnthropicBase` into
`Role::AnthropicCompatible`, placed symmetrically alongside `Role::OpenAICompatible`. Keep
`Engine::AnthropicBase` as a thin composition shell exactly like `Engine::OpenAIBase` —
`extends Remote`, composes the universal roles plus `AnthropicCompatible`, holds the
family-specific `around engine_capabilities` / `around BUILDARGS` corrections and the
abstract `default_model` stub. Same name namespace on both sides (`Role::*Compatible`), no new
`Role::Engine::*` sub-package.

The move is a **pure refactor**: every envelope method/attribute moved byte-identically into
the role (only `use Moose::Role;` swapped in, `make_immutable` dropped). The request-body
tests that assert the Anthropic wire shape against `Engine::Anthropic` (`t/20_chat_requests.t`,
`t/50_list_models.t`, `t/10_engine_hierarchy.t`, `t/78_engine_capabilities.t`) pass unchanged.

One composition consequence: `AnthropicCompatible` defines the `_build_*_wire_format`
builders (`tool`/`reasoning`/`cache` → `anthropic`) and `content_format` alongside the
same-named builders in the universal roles (`Tools`/`ReasoningEffort`/`PromptCache`/`Chat`),
which previously won because `AnthropicBase` *defined them itself*. Now the composer resolves
the three way via `with … => { -excludes => [ … ] }` on the universal roles, so the `anthropic`
values from `AnthropicCompatible` win — preserving the wire reality.

## Rationale

Symmetric modeling: the OpenAI envelope is a role; making the Anthropic envelope a role too
means both dialects of the tree are solved the same way, as the maintainer requested. The
switch is low-risk because it is a pure move verified by unchanged request-body tests. A fuller
`Role::Engine::*` namespace rebrand affecting all ~40 engines is deliberately **not** done
here — the envelope roles are not self-contained (they assume `url`/`HTTP`/`JSON` infra that
normally comes from `extends Remote`), so the intermediate shell cannot simply disappear, and a
wholesale base→role migration would be a high-risk, large diff that the maintainer
explicitly wanted handled in a small, revertible step ("kann ich noch den Commit zurück machen").

## Consequences

- The Anthropic envelope is now a composable Moose role mirroring `Role::OpenAICompatible`.
- Adding a new Anthropic-dialect provider = extend the thin shell OR, for a custom engine,
  compose `Role::AnthropicCompatible` with the required transport/universal roles.
- ADR 0006 is nuanced, not contradicted: inheritance still encodes the *transport root*
  (`Remote`); the *dialect envelope* is now on both sides a composed role; capabilities still
  derive from composed roles (ADR 0002), unaffected by the move.
- Cross-links: ADR 0002 (capabilities derive from roles — unchanged), ADR 0006 (this decision
  moves the Anthropic envelope to the role axis), ADR 0001 (`tool_wire_format` still follows
  the wire reality, now via the role's `_build_tool_wire_format`), ADR 0016 (generalizes this
  decision into the extraction-trigger rule), ADR 0020 (the third envelope role,
  `Role::ResponsesCompatible`, and the first extraction to fire that trigger across two
  *different* parents — so, unlike this pure move, it carries a divergence-hook layer).
