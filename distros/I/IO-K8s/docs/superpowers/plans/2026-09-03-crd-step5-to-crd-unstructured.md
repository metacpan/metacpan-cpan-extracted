# CRD step 5 — `to_crd`, multi-version `IO::K8s::CRD->new`, `IO::K8s::Unstructured` (D9, D4)

**Goal:** Close the round trip. Step 3 gave `add_crd` (a CRD manifest becomes classes);
step 5 gives the reverse (`Class->to_crd`: a typed class emits its
`CustomResourceDefinition`), assembles a multi-version CRD from one class per version
(`IO::K8s::CRD->new(classes => [...], storage => 'v1')`), and adds the opt-in untyped
escape hatch `IO::K8s::Unstructured` for a Kind nothing else resolves. This is what
`Kubernetes::REST` step 6 (kubernetes-rest #24) consumes to register a CRD and to carry
arbitrary discovered Kinds.

**Spec:** `docs/superpowers/specs/2026-09-03-crd-design.md`, decisions D9 and D4. Ticket k96.
Depends on k93 (step 3, landed). Unblocks kubernetes-rest #24.

**Architecture.** `to_crd` is the exact inverse of `IO::K8s::AutoGen`'s schema-to-DSL
mapping: it walks a class's `%IO::K8s::Resource::_attr_registry` entry and emits an
`openAPIV3Schema`. It must mirror AutoGen field for field so that
`add_crd(Class->to_crd)` round-trips to a class equivalent to the original (the primary
correctness property, tested against the shipped provider classes now that they are
full-depth). `IO::K8s::Unstructured` is a thin `IO::K8s::Resource` composition with
`apiVersion`/`kind`/`metadata` as real attributes and everything else preserved in the D1
`_unknown_fields` bag; `IO::K8s->new(unknown_kinds => 'unstructured')` opts into building
it for an otherwise-unresolvable Kind, and bare `IO::K8s` keeps failing closed.

**Tech stack:** Perl 5.10+, Moo, Type::Tiny, the existing `IO::K8s::CRD`,
`IO::K8s::AutoGen`, `IO::K8s::Role::Resource` attribute registry, and the shipped
`IO::K8s::Apiextensions::Pkg::Apis::Apiextensions::V1::CustomResourceDefinition` family.
`prove -lr t/` (the `-r` is required); `dzil test` before each commit.

## Facts this plan rests on

- A class that `use IO::K8s::APIObject api_version => 'g/v', resource_plural => 'plural'`
  exposes `api_version()` (group+version joined), `kind()`, `resource_plural()`. The group
  and version are split back out of `api_version()` for the CRD's `spec.group` and
  `spec.versions[].name`.
- Scope: a class composes `IO::K8s::Role::Namespaced` iff it is namespaced -> `Namespaced`,
  else `Cluster`.
- Registry entry (`Class->_k8s_attr_info->{field}`) carries: `json_key`, exactly one
  classifying `is_*` flag (`is_str`/`is_int`/`is_num`/`is_bool`/`is_int_or_string`/
  `is_quantity`/`is_time`/`is_object`(+`is_inline_struct`)/`is_array_of_*`/`is_hash_of_*`),
  `class` (for object/array-of-object/hash-of-object), `required`, and the D3 options
  (`enum`, `minimum`, `maximum`, `pattern`, `description`). The exact flag names and the
  opaque-`{ Str => 1 }` marker are in `lib/IO/K8s/Resource.pm` — read it; `to_crd` mirrors
  AutoGen's `_schema_to_type_spec` in reverse, so read that too.
- `apiVersion`/`kind`/`metadata` are supplied by `IO::K8s::Role::APIObject` outside the
  schema's own properties (AutoGen's `%role_supplied`); the emitted `openAPIV3Schema` still
  lists them as the standard envelope stubs (`apiVersion`/`kind`: `type: string`;
  `metadata`: `type: object`) alongside the registry-derived `spec`/`status`.

## Global Constraints

- Every module keeps its own `our $VERSION = '1.108';` (new modules included).
- No new CPAN dependencies.
- `prove -lr t/` green with nothing skipped after every task; `dzil test` green before every
  commit; `t/02_compile_all.t` must still pass (new modules load).
- Behaviour default stays fail-closed: bare `IO::K8s` still dies on an unresolvable Kind;
  `unknown_kinds => 'unstructured'` is strictly opt-in.
- Delegation: implementation to `io-k8s-worker`, tests may be folded into the same task
  (TDD) or handed to `io-k8s-test-writer`; each task reviewed on opus before the next.
  Tasks are sequential (they share `IO::K8s::CRD` and `IO::K8s.pm`).
- Never `dzil release`. Never touch github.com/pplu/io-k8s issues/PRs.
- Commit trailer (exactly these two lines):
  ```
  Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>
  Claude-Session: https://claude.ai/code/session_01Q7d9DGeyjGGQKYPHw5ABuo
  ```

## File structure

| File | Responsibility |
|------|----------------|
| `lib/IO/K8s/Unstructured.pm` | new: apiVersion/kind/metadata attrs + D1 bag for the rest |
| `lib/IO/K8s.pm` | `unknown_kinds` option; build Unstructured for an unresolvable Kind when opted in |
| `lib/IO/K8s/CRD.pm` | `_schema_for_class` (registry -> openAPIV3Schema); `->new(classes, storage)` multi-version assembly |
| `lib/IO/K8s/Role/APIObject.pm` (or `APIObject.pm`) | install `to_crd` on APIObject classes, delegating to `IO::K8s::CRD` |
| `t/78_unstructured.t`, `t/79_to_crd.t`, `t/80_crd_multiversion.t` | tests |

---

## Task 1: `IO::K8s::Unstructured` + `unknown_kinds` opt-in (D4)

**Lane:** `io-k8s-worker`.

**Files:**
- Create: `lib/IO/K8s/Unstructured.pm`
- Modify: `lib/IO/K8s.pm` (`unknown_kinds` constructor option; resolution fallback)
- Test: `t/78_unstructured.t`

**Interfaces:**
- `IO::K8s::Unstructured` composes `IO::K8s::Role::Resource` with `apiVersion`, `kind` and
  `metadata` as real `k8s` attributes (metadata typed as the shipped `ObjectMeta` if that is
  how the core classes do it, else a plain object). Everything else on the wire is preserved
  via the D1 `_unknown_fields` bag: `FROM_HASH` keeps unknown keys, `TO_JSON` re-emits them,
  so an arbitrary CR round-trips byte-for-byte. It has NO fixed `api_version()`/`kind()`
  identity (unlike an APIObject class) — `apiVersion`/`kind` are ordinary data set from the
  document.
- `IO::K8s->new(unknown_kinds => 'unstructured')`: when `inflate`/`new_object` is handed a
  document whose `apiVersion`/`kind` resolves to no registered class (and AutoGen has no
  spec for it), build an `IO::K8s::Unstructured` populated from the document instead of
  dying. Any value other than the default keeps today's behaviour; the default (`unknown_kinds`
  unset, or its current fail-closed value) still dies with the current error. Confirm the
  exact current default and error in `lib/IO/K8s.pm` before wiring, and keep it unchanged.

- [ ] **Step 1 (TDD):** write `t/78_unstructured.t` first — (a) a direct
  `IO::K8s::Unstructured->new` / `FROM_HASH` on a hand-written CR with nested unknown fields
  round-trips through `TO_JSON` byte-identically and exposes `apiVersion`/`kind`/`metadata`
  as accessors; (b) `IO::K8s->new` (bare) still dies on an unregistered Kind (assert the
  current error); (c) `IO::K8s->new(unknown_kinds => 'unstructured')->inflate($unknown_cr)`
  returns an `IO::K8s::Unstructured` that round-trips. Run it, watch it fail.
- [ ] **Step 2:** implement `Unstructured.pm` and the `IO::K8s.pm` option + fallback.
- [ ] **Step 3:** `prove -l t/78_unstructured.t t/66_unknown_fields.t t/67_strict.t t/02_compile_all.t`; then `prove -lr t/`; `dzil test`; commit
  `IO::K8s::Unstructured + unknown_kinds => 'unstructured' opt-in (D4, k96)`.

---

## Task 2: `Class->to_crd` — single-version CRD from the registry (D9)

**Lane:** `io-k8s-worker`.

**Files:**
- Modify: `lib/IO/K8s/CRD.pm` (new `_schema_for_class($class)` returning an `openAPIV3Schema`
  hashref, and a `crd_for_class($class)` returning a `CustomResourceDefinition` object)
- Modify: `lib/IO/K8s/Role/APIObject.pm` or `lib/IO/K8s/APIObject.pm` (install a `to_crd`
  method on APIObject classes that calls `IO::K8s::CRD::crd_for_class(__PACKAGE__)`)
- Test: `t/79_to_crd.t`

**Interfaces:**
- `_schema_for_class($class)` walks `$class->_k8s_attr_info` and returns the `openAPIV3Schema`
  for one version, mirroring `IO::K8s::AutoGen::_schema_to_type_spec` IN REVERSE, keyed by
  each field's `json_key`:
  - `is_str` -> `{ type => 'string' }`; `is_int` -> `{ type => 'integer' }`;
    `is_num` -> `{ type => 'number' }`; `is_bool` -> `{ type => 'boolean' }`;
    `is_int_or_string` -> `{ 'x-kubernetes-int-or-string' => JSON::true }`;
    `is_quantity`/`is_time` -> `{ type => 'string' }` (match AutoGen's own treatment; add a
    `format` only if AutoGen records one).
  - `is_object`/`is_inline_struct` with a `class` -> recurse `_schema_for_class` into that
    class (`{ type => 'object', properties => {...}, required => [...] }`).
  - `is_array_of_<scalar>` -> `{ type => 'array', items => <scalar schema> }`;
    `is_array_of_object` (with `class`) -> `{ type => 'array', items => <recursed schema> }`.
  - `is_hash_of_<scalar>` -> `{ type => 'object', additionalProperties => <scalar schema> }`;
    `is_hash_of_object` -> `additionalProperties => <recursed schema>`.
  - the opaque `{ Str => 1 }` free-form map (the marker AutoGen uses; find it in Resource.pm)
    -> `{ type => 'object', 'x-kubernetes-preserve-unknown-fields' => JSON::true }`.
  - `required` truthy on a field (either `1` or the `'schema'` marker) -> its `json_key`
    joins the enclosing object's `required` array.
  - D3 options copied onto the property: `enum` -> `enum`, `minimum`/`maximum` verbatim,
    `pattern` -> `pattern`, `description` -> `description`.
  - Recursion must guard against cycles (a class that references itself, directly or via a
    reused core class) — cap depth or track the visited-class set and emit
    `{ type => 'object', 'x-kubernetes-preserve-unknown-fields' => JSON::true }` at a repeat,
    rather than looping. Decide and document which.
  - The top-level object schema for the Kind lists the envelope stubs `apiVersion`
    (`type: string`), `kind` (`type: string`), `metadata` (`type: object`) alongside the
    registry-derived `spec`/`status` — the role-supplied fields AutoGen excludes from the
    schema get their standard stubs here.
- `crd_for_class($class)` builds and returns a real
  `IO::K8s::Apiextensions::Pkg::Apis::Apiextensions::V1::CustomResourceDefinition` object:
  `metadata.name = "$plural.$group"`, `spec.group = $group`,
  `spec.scope = $class->DOES('IO::K8s::Role::Namespaced') ? 'Namespaced' : 'Cluster'`,
  `spec.names = { plural => resource_plural, kind => kind, singular => lc(kind),
  listKind => "${kind}List" }`, `spec.versions = [ { name => $version, served => JSON::true,
  storage => JSON::true, schema => { openAPIV3Schema => _schema_for_class($class) } } ]`.
  `$group`/`$version` are split from `$class->api_version()`.
- `Class->to_crd` is the public method (installed on APIObject classes) returning that object.

- [ ] **Step 1 (TDD):** write `t/79_to_crd.t` first. Core assertions:
  (a) a small hand-rolled `use IO::K8s::APIObject` fixture class exercising every branch
  (scalar, int, bool, array-of-scalar, array-of-object, hash-of-scalar, opaque `{Str=>1}`,
  a referenced class, a `required` field, and D3 enum/min/max/pattern) -> `to_crd` yields the
  expected `openAPIV3Schema` (`is_deeply` on the schema).
  (b) **round-trip:** take a shipped full-depth provider class (e.g.
  `IO::K8s::Traefik::V1alpha1::Middleware` or a small cert-manager Kind), call `to_crd`, feed
  it to a fresh `IO::K8s->new->add_crd($crd)`, and assert the regenerated class's
  `_k8s_attr_info` top-level `spec` field set matches the original's (the primary correctness
  property: `add_crd(Class->to_crd)` reconstructs an equivalent class). Pick a Kind whose
  shape survives the round trip; document any lossy edge (e.g. `is_quantity` -> `string`).
  (c) scope: a namespaced Kind -> `spec.scope eq 'Namespaced'`; a cluster-scoped one ->
  `'Cluster'`.
  Run it, watch it fail.
- [ ] **Step 2:** implement `_schema_for_class` + `crd_for_class` in `IO::K8s::CRD` and the
  `to_crd` method installer. Reuse the shipped CustomResourceDefinition classes (do not
  hand-build the manifest as a bare hashref where a typed object exists).
- [ ] **Step 3:** `prove -l t/79_to_crd.t t/73_add_crd.t t/04_autogen.t t/02_compile_all.t`;
  then `prove -lr t/`; `dzil test`; commit
  `Class->to_crd: CustomResourceDefinition from the attribute registry (D9, k96)`.

---

## Task 3: `IO::K8s::CRD->new(classes => [...], storage => 'v1')` — multi-version (D9)

**Lane:** `io-k8s-worker`.

**Files:**
- Modify: `lib/IO/K8s/CRD.pm` (`->new` / a constructor accepting `classes` + `storage`)
- Test: `t/80_crd_multiversion.t`

**Interfaces:**
- `IO::K8s::CRD->new(classes => [ $class_v1, $class_v1beta1, ... ], storage => 'v1')` returns
  ONE `CustomResourceDefinition` object with one entry in `spec.versions` per class (reusing
  Task 2's `_schema_for_class`), each `served => true`, exactly the `storage`-named version
  `storage => true` and the rest `storage => false`.
- Validation (croak with a clear message): all classes must share the same group, kind,
  resource_plural and scope (they are versions of one CRD); `storage` must name one of the
  classes' versions; `classes` must be non-empty. Versions are ordered as given (or by
  Kubernetes version-sort — pick one, document it).
- This is the assembly layer over Task 2; `Class->to_crd` stays the single-version shorthand
  (equivalent to `IO::K8s::CRD->new(classes => [$class], storage => <its version>)`).

- [ ] **Step 1 (TDD):** write `t/80_crd_multiversion.t` first — build two fixture classes
  for the same group/kind/plural at `v1` and `v1beta1` (differing spec shapes), assemble with
  `storage => 'v1'`, and assert: two `spec.versions`, both `served`, only `v1` is `storage`,
  each version's `openAPIV3Schema` matches its class; then the mismatch guards
  (`throws_ok` on differing kind/group, on a `storage` naming no class, on empty `classes`).
  Run it, watch it fail.
- [ ] **Step 2:** implement the constructor over `_schema_for_class`.
- [ ] **Step 3:** `prove -l t/80_crd_multiversion.t t/79_to_crd.t t/73_add_crd.t t/02_compile_all.t`;
  then `prove -lr t/`; `dzil test`; commit
  `IO::K8s::CRD->new(classes, storage): multi-version CRD assembly (D9, k96)`.

---

## After the three tasks

- Final whole-branch review (opus) focused on: the `to_crd` <-> `add_crd`/AutoGen round-trip
  fidelity (does every AutoGen input branch have an inverse, and are the lossy ones
  documented?), the fail-closed default staying intact, and POD on the three new public
  surfaces. One fix wave if needed.
- Merge to master (fast-forward, matching steps 1-4). Close k96. Report to the user;
  kubernetes-rest #24 is then unblocked (the user is running that in parallel).
