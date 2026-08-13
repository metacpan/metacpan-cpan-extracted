# Exact GVK Dispatch and Compatibility Design

## Goal

Make every official Kubernetes `apiVersion` + `kind` pair resolve to the exact
class described by the upstream API while retaining historical short-name
lookups as compatibility aliases.

The work also closes the concrete correctness and packaging gaps discovered
during the repository structure review, without turning the change into a
broad rewrite of the checked-in API corpus.

## Resolution contract

Class resolution follows this order:

1. A domain-qualified `apiVersion/kind` lookup is authoritative and resolves
   to the class for that exact upstream GVK.
2. A short Kind plus an explicit `apiVersion` is equivalent to the same
   domain-qualified lookup.
3. A bare short Kind remains a compatibility alias. Existing useful defaults
   stay intact unless upstream makes them impossible to support.
4. Historical aliases may continue to resolve, but they must never override or
   reinterpret an explicitly supplied official GVK.

An explicit lookup is fail-closed. If a domain-qualified string or a
Kind-plus-`apiVersion` has no exact built-in, provider, namespace, or AutoGen
match, `expand_class` returns `undef`; `inflate` and `new_object` throw a clear
error naming both values. Unknown, malformed, and mismatched explicit versions
never fall through to the bare-Kind alias. A versionless lookup alone may use
the compatibility alias.

This preserves calls such as `new_object('Event', ...)` while ensuring a real
`events.k8s.io/v1` payload inflates as `Api::Events::V1::Event`, not
`Api::Core::V1::Event`. The same rule applies to `autoscaling/v1` versus
`autoscaling/v2` HorizontalPodAutoscaler objects.

## Work packages

### Official GVK coverage

Finish the current uncommitted static resource-map work. The checked-in
`t/data/spec-kinds.json` fixture is generated from the pinned v1.36.3 Swagger
snapshot by `maint/spec-kind-fixture-gen.pl`. A new offline test consumes every
fixture entry, filters only documented non-dispatchable and removed generic
List cases, and proves each official GVK resolves to the exact expected Perl
class and loads. The expected-class oracle is derived deterministically from
the fixture's upstream `def_key`, using the same documented namespace
contractions as the drift checker rather than asking the resource map what it
expects.

For every dispatchable fixture entry the test covers both public resolution
calls exhaustively:

- `expand_class("$apiVersion/$kind")`;
- `expand_class($kind, $apiVersion)`;
- class loadability and the expected `IO::K8s::Role::Namespaced` scope when the
  fixture provides it.

Exhaustive `inflate()` is deliberately not duplicated here: many official
Kinds require nested values that the compact GVK fixture does not contain, and
`t/42_registry_synthesis_roundtrip.t` already owns full registry-driven object
construction. `t/43` instead uses valid literal manifests for representative
resolution branches: core, grouped, every multi-version collision, provider,
namespace override, unknown explicit GVK, and AutoGen exact/ambiguous cases.

All versionless compatibility aliases are pinned in a separate checked-in
`t/data/short-name-compat.json` snapshot. It records every bare key and target
in the approved post-change default map, not just known ambiguous examples, and
`t/43` requires exact equality. This prevents aliases such as `DeviceClass`,
`VolumeAttributesClass`, `SelfSubjectReview`, and `LeaseCandidate` from silently
retargeting. Notably, bare `Event` remains Core v1 and bare
`HorizontalPodAutoscaler` remains autoscaling v2, while their explicit GVKs
select Events v1 and autoscaling v1/v2 exactly.

The test is the guard against future drift between checked-in classes and
`%DEFAULT_RESOURCE_MAP`; the generator itself never runs in the test suite and
therefore never introduces network access into tests.

The fixture records `generated_from: v1.36.3`; its generator also records a
SHA-256 of the source snapshot. The offline test checks both provenance fields,
checks that each dispatch exception refers to a definition present in the
fixture, and fails on unused `non_dispatchable_kinds` exceptions. Generic List
filtering remains the existing structural rule, not a growing list of names.

### Class namespace inheritance

Classes selected through `class_namespaces` may subclass shipped IO::K8s
classes without redeclaring every `k8s` attribute. Attribute metadata is merged
across the inheritance chain, nearest class first, with caching so ordinary
inflation does not repeatedly walk `@ISA`. Subclass declarations override
inherited declarations of the same attribute.

Inheritance order uses Perl's active MRO (`mro::get_linear_isa`), merging from
the furthest ancestor toward the concrete class so the nearest declaration
wins. Any `k8s` declaration clears the entire small merged-registry cache; this keeps
runtime-generated classes and late declarations correct without descendant
bookkeeping. A namespace override need not subclass the mapped class if it
declares a complete APIObject of its own. If it does subclass a shipped class,
wire `apiVersion` derivation falls back to the nearest recognized IO::K8s
ancestor, while an explicit APIObject override remains authoritative.

Provider collision behavior stays compatible: the first provider keeps the
bare short alias, while every distinct provider GVK remains reachable. A `+`
full-class provider mapping remains exact and bypasses `class_namespaces`.
Relative built-in/provider mappings may be overridden by `class_namespaces`,
but the selected class must serialize the same explicit GVK. Two providers
claiming the same exact GVK remain deterministic first-wins, matching current
registration behavior; the later class is reachable only by its explicit full
class name. An exact namespace override whose class-level `api_version()` is
missing or mismatched is a descriptive error, not silently skipped or accepted.

### List apiVersion correctness

Empty `IO::K8s::List` objects using `item_class` derive the same official API
group as their item class would. RBAC, Storage, StorageMigration and every
other mapped group must emit their full wire group rather than a lowercased
package segment. Non-empty lists continue to delegate to the first item.

For an empty list, `item_class` is loaded when possible and its class-level
`api_version()` is the sole source of truth. This covers built-ins, namespace
subclasses, custom APIObjects, and AutoGen classes without copying the group
map into `List`. An invalid class or a class without `api_version()` preserves
the current non-throwing behavior: `api_version` returns `undef` and TO_JSON
omits the field. `kind` continues to derive from the final package segment.

### AutoGen version awareness

Auto-generation receives the requested `apiVersion` and matches it against
`x-kubernetes-group-version-kind`. When more than one definition has the same
Kind, an explicit version selects the exact definition. A versionless lookup
uses the lexicographically first definition among exact Kind-bearing GVK
candidates as its deterministic compatibility fallback. The legacy
definition-name suffix fallback is considered only when no GVK metadata names
the Kind, and is also sorted lexicographically. No path may depend on Perl hash
iteration order.

For a versionless Kind, definitions are ordered lexicographically by definition
key. Within the selected definition, entries for that exact case-sensitive Kind
are ordered lexicographically by canonical wire `apiVersion`, and the first is
the selected GVK. Canonical wire identity is case-sensitive and consists of
bare `version` for the core group or `group/version` otherwise, followed by the
case-sensitive Kind; malformed alternatives are not normalized into a match.

An explicit unknown GVK asks AutoGen for that exact GVK before failing closed;
it never reuses a differently versioned bare-Kind candidate. More than one
definition advertising the same exact GVK is an ambiguity error. A single
definition advertising several distinct GVKs is generated per requested GVK:
cache identity and generated package identity include the normalized requested
`apiVersion/kind`, and the generated APIObject's `api_version()` returns that
requested official version. Versionless generation caches under its
deterministically selected GVK. Generated package identity appends
`::__GVK_` plus the first 12 hexadecimal characters of `sha1_hex` over the
exact canonical `apiVersion/kind`; this makes separators safe without folding
case or creating another mapping table.

### Packaging and documentation

`Module::Runtime` becomes a declared runtime prerequisite because IO::K8s uses
it directly and Dist::Zilla currently omits it from `listdeps`.

The `.pk8s` loader documentation explicitly states that `.pk8s` files are Perl
code evaluated in-process and must only be loaded from trusted sources. YAML
loading remains the data-only path.

The stale `_qualify_defaults` test comment is corrected. `Changes` records all
user-visible dispatch, inflation, List, AutoGen, prerequisite and trust-boundary
changes under `{{$NEXT}}`.

## Explicit non-goals

- Do not remove historical short-name aliases.
- Do not regenerate or mass-rewrite the approximately 850 shipped modules.
- Do not redesign the `k8s` DSL or move Requiredness into its registry in this
  change. Record that longer-term concern on the Karr board instead.
- Do not make tests fetch an upstream spec or contact a Kubernetes cluster.
- Do not release the distribution.

## Acceptance matrix

| Input | Exact mapping exists | AutoGen exact mapping exists | Result |
|---|---:|---:|---|
| `apiVersion/kind` string | yes | n/a | exact mapped/namespace/provider class |
| Kind + explicit `apiVersion` | yes | n/a | exact mapped/namespace/provider class |
| Explicit GVK | no | yes | exact generated class for that GVK |
| Explicit GVK | no | no | `expand_class`: `undef`; constructors/inflate: descriptive error |
| Bare Kind | yes | n/a | pinned compatibility alias |
| Bare Kind | no | candidates exist | deterministic AutoGen fallback |
| Provider collision, bare Kind | yes | n/a | first registered short alias |
| Provider collision, explicit GVK | yes | n/a | provider owning that exact GVK |
| Two providers claim identical GVK | yes | n/a | first registration wins; later class only by full name |
| Namespace override of relative map | yes | n/a | override class with identical wire GVK |
| Namespace override has wrong GVK | yes | n/a | descriptive mismatch error |
| `+Full::Class` provider map | yes | n/a | exact full class; no namespace override |

## Testing

Every behavior change starts with a focused failing regression test. Relevant
single tests run during each red/green cycle, followed by `prove -lr t/` for the
integrated result. The local drift report runs against
`spec/v1.36.3.json`. Packaging verification includes `dzil listdeps` and must
show `Module::Runtime`. Final distribution verification runs `dzil build` and
`dzil test`, then checks the built META prerequisites and `git diff --check`.

The existing optional live-cluster AutoGen test remains opt-in and is not
required for offline completion.

## Commit and board discipline

Each bounded work package has a Karr ticket, a focused implementation commit,
and the Codex co-author/model trailers requested by the repository workflow.
Board mutations are serialized. Tickets move to `done` only after their focused
tests and the integrated suite pass. Existing unrelated user changes are never
staged accidentally.

The dirty-tree baseline is path-partitioned before implementation:

| Existing path | Owning work package/commit |
|---|---|
| `docs/superpowers/specs/2026-08-10-exact-gvk-and-compatibility-design.md` | design/planning ticket and documentation-only commit |
| `lib/IO/K8s.pm` | static exact-GVK map and fail-closed resolution |
| `maint/spec-drift-exceptions.yaml` | official-GVK fixture exceptions |
| `maint/spec-kind-fixture-gen.pl` | official-GVK fixture generator |
| `t/data/spec-kinds.json` | generated official-GVK fixture |
| `t/42_registry_synthesis_roundtrip.t` | independent registry roundtrip ticket/commit |

The missing fixture consumer is added as
`t/43_spec_kind_dispatch.t`. No commit stages both the independent `t/42` test
and the GVK fixture work. Before every commit, `git diff --cached` is reviewed
and only paths named by that ticket are staged.
