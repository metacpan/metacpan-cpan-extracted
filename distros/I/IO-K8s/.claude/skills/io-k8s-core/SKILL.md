---
name: io-k8s-core
description: "IO::K8s distribution internals for contributors — Resource vs APIObject, the k8s DSL and its attribute registry, class-name expansion, the role mesh, CRD resource-map providers, runtime AutoGen, and how new API surface is added. Load before editing anything under lib/IO/K8s/."
user-invocable: false
allowed-tools: Read, Grep, Glob
model: sonnet
---

# IO::K8s — Distribution Internals

Consumer-facing usage (`new_object`, `inflate`, `to_json`, short names) lives in skill
`perl-kubernetes-classes`. This skill is about *changing* the distribution.

## There is no codegen step

The ~850 classes under `lib/IO/K8s/` are **checked in and hand-maintained**. No generator
runs at build time — edit the `.pm` files directly, then `dzil test`.

`IO::K8s::AutoGen` is the *runtime* fallback for types the distribution does not ship
(arbitrary CRDs from a user-supplied OpenAPI spec). It builds packages into a per-instance
namespace at call time and **never writes files**. A missing built-in class is a gap to fill
by hand, not something AutoGen papers over.

## Two base classes, one DSL

| `use ...` | For | Composes |
|---|---|---|
| `IO::K8s::Resource` | embedded objects — `PodSpec`, `Container`, `ObjectMeta` | `IO::K8s::Role::Resource` |
| `IO::K8s::APIObject` | top-level objects — `Pod`, `Deployment`, `Gateway` | the above **plus** `IO::K8s::Role::APIObject` |

Both `import` into the caller: `Moo`, `Types::Standard` (`Str Int Bool`), `IO::K8s::Types`
(`IntOrStr Quantity Time`), the composed role, and the `k8s` function. The import is
deliberately narrow — `t/27_no_import_leak.t` asserts that merely `use`-ing an IO::K8s class
from a foreign package leaks neither `k8s` nor the role. Do not widen it.

```perl
package IO::K8s::Api::Core::V1::Pod;
# ABSTRACT: Pod is a collection of containers that can run on a host
our $VERSION = '1.106';
use IO::K8s::APIObject;

k8s spec   => 'Core::V1::PodSpec';          # single nested object
k8s status => 'Core::V1::PodStatus';

1;
```

`k8s` forms: `Str`/`Int`/`Bool`/`IntOrStr`/`Quantity`/`Time` type constants,
`'Core::V1::Foo'` for a nested object, `['Core::V1::Foo']` for an array of them,
`{ Str => 1 }` for a hash, and a hashref of fields for an inline anonymous struct.
Add `'required'` after the type where the API demands it.

### Attribute registry

`k8s` records every attribute in `our %IO::K8s::Resource::_attr_registry`:
`class -> attr -> { type, class, is_array, is_hash, is_bool, is_int, … }`. `TO_JSON`,
`FROM_HASH` and `compare_to_schema` all read that registry — an attribute declared with a
plain `has` instead of `k8s` is invisible to serialization. **Never use `has` for wire
fields.**

### Class-name expansion (`_expand_class`)

- `+My::Own::Class` → used verbatim (leading `+` stripped)
- `IO::K8s::…` → used verbatim
- known prefix (`Core`, `Apps`, `Meta`, `Apiextensions`, `KubeAggregator`, …) → expanded via
  the `%_class_prefix` table in `lib/IO/K8s/Resource.pm`
- anything else → `IO::K8s::Api::<name>`

A new top-level namespace needs an entry in `%_class_prefix`, or every reference to it must
be written `+IO::K8s::…`.

### Attribute-name sanitising

JSON field names that are not valid Perl identifiers are rewritten: `$ref` → `_ref`,
`x-kubernetes-foo` → `x_kubernetes_foo`. The original wire name is what `TO_JSON` emits —
the accessor name is not the wire name.

## Top-level objects

`IO::K8s::Role::APIObject` derives `api_version()` and `kind()` from the class name and
supplies `metadata`, label/annotation helpers (`add_label`, `match_labels`, `has_annotation`),
condition helpers (`conditions`, `get_condition`, `is_ready`, `condition_message`), ownership
(`set_owner`, `is_owned_by`, `owner_refs`), plus `to_yaml`/`save`.

CRD classes pass their identity as import parameters instead:

```perl
package My::StaticWebSite;
use IO::K8s::APIObject
    api_version     => 'homelab.example.com/v1',
    resource_plural => 'staticwebsites';
with 'IO::K8s::Role::Namespaced';
```

Those are installed as class methods *before* the role is composed — that ordering is what
avoids redefinition warnings; don't "simplify" it into an after-the-fact override. CRD
classes also get `IO::K8s::Role::SpecBuilder` automatically.

## The role mesh (`lib/IO/K8s/Role/`)

| Role | Purpose |
|---|---|
| `Resource` | instance behaviour: `TO_JSON`, `to_json`, `TO_YAML`, `to_yaml`, `FROM_HASH`, `from_json`, `compare_to_schema` |
| `APIObject` | top-level identity, metadata, labels, annotations, conditions, owners |
| `Namespaced` | resources that live in a namespace |
| `SpecBuilder` | deep-path spec manipulation: `spec_get`/`spec_set`/`spec_push`/`spec_merge`/`spec_delete` |
| `ResourceMap` | packages that provide a short-name → class map (requires `resource_map`) |
| `Routable`, `Loadbalanced`, `NetworkPolicy`, `CertManaged`, `HelmManaged`, `MiddlewareBuilder` | opt-in behaviour mixins for routing, traffic splitting, netpol, cert-manager, K3s Helm, Traefik middleware |

Behaviour mixins are opt-in per class — applying one to a whole namespace is an API change,
not a refactor.

## CRD providers

A provider is a Moo class with `with 'IO::K8s::Role::ResourceMap'` and a `resource_map`
returning short-name → class-path pairs. Shipped ones: `IO::K8s::Cilium`, `::GatewayAPI`,
`::Traefik`, `::CertManager`, `::K3s`, `::AgentSandbox`. Consumers opt in with
`IO::K8s->new(with => ['IO::K8s::Cilium'])`.

Built-in Kubernetes kinds live in `%DEFAULT_RESOURCE_MAP` at the top of `lib/IO/K8s.pm` —
a new *core* kind is not reachable by short name until it is listed there.

## Adding API surface — checklist

1. Create the `.pm` under the right namespace; `# ABSTRACT:` line and `our $VERSION` matching
   every other module (see the release skill — every module carries the same version, by design).
2. Choose `IO::K8s::Resource` (embedded) or `IO::K8s::APIObject` (top-level).
3. Declare every wire field with `k8s`, matching the upstream OpenAPI schema — types and
   required-ness verbatim, no invented fields, no guessed casing.
4. Top-level kind → add it to `%DEFAULT_RESOURCE_MAP` in `lib/IO/K8s.pm` (or the provider's
   `resource_map` for a CRD).
5. New top-level namespace → add it to `%_class_prefix` in `lib/IO/K8s/Resource.pm`.
6. `dzil test`. `t/02_compile_all.t` walks `lib/` itself, so a new module is compile-tested
   automatically — but nothing asserts its *shape* until you write that test.

## Finding coverage gaps against upstream

`maint/spec-drift-check.pl` is the repeatable version of the manual sweep that found karr
#4-#8 (the v1.36 sync gaps): it loads a real upstream `swagger.json`, loads the shipped
attribute registry the same way `t/34_registry_guard.t` does, maps each upstream definition
key to the Perl class name the conventions above imply, and diffs kind-by-kind, field-by-field.
It weights a missing top-level Kind above a missing field whose target type is *also*
unshipped — the gap class `t/34` structurally cannot see, since it only walks classes that
were already declared. `--from TAG --to TAG` instead diffs two upstream releases against each
other with no reference to `lib/`, for "is upgrading worth it." Settled non-gaps (the dropped
`*List` kinds, old back-compat API tracks like `flowcontrol/v1beta3`, the apimachinery
scalar/opaque barewords) live in `maint/spec-drift-exceptions.yaml`, not in the script, so a
maintainer can silence a made decision without touching code. It only ever prints a report —
no karr tickets, no lib/ edits.

## Removing API surface is a breaking change

The 1.105 removal of the 76 `*List` classes is the worked example: names that disappear must
land in `IO::K8s::Deprecated` with a redirect message, `Changes` must spell out that the
failure mode changes from "warns" to "fails to install", and the empty namespaces left behind
get removed in the same release. Generic list handling is `IO::K8s::List`.

## Serialization invariants

Kubernetes rejects wrong JSON types. `Int` must serialize unquoted, `Bool` as `true`/`false`,
`IntOrStr` keeps whatever the caller gave, `Quantity` and `Time` stay strings. `TO_JSON` is
canonical-ordered. `t/26_build_verify.t` builds manifests in Perl and compares against the
kubectl-canonical structure; `t/25_real_world.t` goes the other direction, parsing real YAML.
Any change to `TO_JSON`/`FROM_HASH` must keep both green.
