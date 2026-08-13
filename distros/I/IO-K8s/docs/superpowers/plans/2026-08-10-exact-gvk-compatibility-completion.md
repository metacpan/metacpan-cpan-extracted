# Exact GVK Compatibility Completion Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make official Kubernetes GVK dispatch exact and fail-closed, retain all historical short aliases, and close the related serialization, AutoGen, dependency, and documentation gaps tracked in Karr.

**Architecture:** Keep the checked-in API classes and `k8s` DSL intact. Strengthen the existing resource-map boundary: explicit GVKs resolve exactly or fail, bare Kinds use a pinned compatibility map, namespace subclasses inherit schema metadata through Perl MRO, and AutoGen keys generated classes by exact GVK. Each Karr ticket is testable and committed independently.

**Tech Stack:** Perl 5.10+, Moo/Moo::Role, Type::Tiny, JSON::MaybeXS/JSON::PP, Test::More/Test::Deep/Test::Exception, Dist::Zilla, Karr refs board.

**Spec:** `docs/superpowers/specs/2026-08-10-exact-gvk-and-compatibility-design.md`

## Execution preconditions

- [ ] Commit this plan by itself before implementation under Karr #27 with
  subject `Plan exact GVK compatibility completion`, the required Codex
  trailers, and a reviewed `git diff --cached`. Append its SHA to #27, release
  the claim, move #27 to `done`, and verify it there.
- [ ] Capture `git status --short` immediately after that plan commit. Reconcile
  every pre-existing dirty path with its owning task: `t/42...` belongs to #21;
  `lib/IO/K8s.pm`, the generator, exceptions, spec fixture and dispatch test
  belong to #17. No implementation worker may absorb another task's path.
- [ ] Follow repository delegation lanes during execution: `io-k8s-test-writer`
  owns changes under `t/`, `io-k8s-worker` owns behavior under `lib/`,
  `io-k8s-doc-writer` owns POD, and the orchestrator owns Karr, `Changes`,
  `README.md`, verification, staging, and commits.
- [ ] Every RED must be an intended assertion failure for the behavior under
  test, not a compile error, missing fixture, or broken test setup.
- [ ] Every implementation commit message ends with exactly:

  ```text
  Karr: #ID

  Co-authored-by: Codex <noreply@openai.com>
  Codex-Model: GPT-5
  ```

---

## Chunk 1: Recover and complete the existing dirty-tree work

### Task 1: Commit registry-driven synthesis coverage (Karr #21)

**Files:**
- Add: `t/42_registry_synthesis_roundtrip.t` (already present and untracked)

- [ ] **Step 1: Review ownership and test intent**

Confirm the file only reads the shipped registry, synthesizes required/full
structs, verifies JSON scalar wire types, and performs byte-stable JSON
roundtrips. It must not read `t/data/spec-kinds.json` or alter production code.

- [ ] **Step 2: Run the focused test**

Run: `prove -lv t/42_registry_synthesis_roundtrip.t`

Expected: PASS, 1,689 tests, no warnings.

- [ ] **Step 3: Run the pre-existing registry guard**

Run: `prove -lv t/34_registry_guard.t`

Expected: PASS, 847 tests; every attribute target class is loadable.

- [ ] **Step 4: Review and commit only the test**

Run: `git diff --no-index /dev/null t/42_registry_synthesis_roundtrip.t`

Stage only `t/42_registry_synthesis_roundtrip.t`. Commit subject:
`Exercise every registry class through JSON roundtrips` with `Karr: #21` and
the Codex co-author/model trailers. Before committing, require
`git diff --cached --name-only` to name only that file and review the complete
`git diff --cached`.

### Task 2: Complete exact official GVK dispatch (Karr #17)

**Files:**
- Modify: `lib/IO/K8s.pm`
- Modify: `maint/spec-drift-exceptions.yaml`
- Add/modify: `maint/spec-kind-fixture-gen.pl`
- Add/modify: `t/data/spec-kinds.json`
- Add: `t/data/short-name-compat.json`
- Add: `t/43_spec_kind_dispatch.t`
- Modify: `Changes`

- [ ] **Step 1: RED — pin source provenance before changing the generator**

Start `t/43_spec_kind_dispatch.t` with assertions that the checked-in fixture
has `generated_from eq 'v1.36.3'`, exactly 311 entries, reports
`gvk_total_in_spec == 311`, and pins the exact source digest
`dcede2063da1d7ad62ecb5af8adb6d7fabd0b52385a7fa0048afb491dac90450`.
Run `prove -lv t/43_spec_kind_dispatch.t` and observe only the missing
provenance assertion fail.

- [ ] **Step 2: GREEN — add deterministic offline fixture provenance**

Update `maint/spec-kind-fixture-gen.pl` to calculate
`Digest::SHA::sha256_hex` over the exact source bytes and emit
`source_sha256`, and add `--output`. Keep local `--spec` fully offline. Run:

```text
perl maint/spec-kind-fixture-gen.pl --spec spec/v1.36.3.json --output /tmp/io-k8s-spec-kinds-a.json
perl maint/spec-kind-fixture-gen.pl --spec spec/v1.36.3.json --output /tmp/io-k8s-spec-kinds-b.json
cmp /tmp/io-k8s-spec-kinds-a.json /tmp/io-k8s-spec-kinds-b.json
cp /tmp/io-k8s-spec-kinds-a.json t/data/spec-kinds.json
```

The comparison must not depend on Git tracking state.

Run `prove -lv t/43_spec_kind_dispatch.t`; the provenance subtest now passes.

- [ ] **Step 3: Approve and pin the compatibility alias oracle**

Generate a canonical JSON object mapping every bare key in the dirty
`IO::K8s->default_resource_map` to its class path, excluding keys containing
`/`. Independently extract the bare map from `HEAD:lib/IO/K8s.pm`, then diff
the two canonical objects before creating `t/data/short-name-compat.json`.
Use the same canonical `JSON::PP->new->canonical` extraction for both sources;
the HEAD source is evaluated in a renamed temporary package so it cannot read
the dirty map. Run:

```text
perl -Ilib -MIO::K8s -MJSON::PP -e 'my $m=IO::K8s->default_resource_map; print JSON::PP->new->canonical->pretty->encode({map {$_=>$m->{$_}} grep {index($_,"/")<0} keys %$m})' > /tmp/io-k8s-current-short.json
git show HEAD:lib/IO/K8s.pm | perl -Ilib -MJSON::PP -e 'local $/; my $s=<>; $s=~s/package IO::K8s;/package IO::K8s::HEAD;/; my $ok=eval $s; die $@ unless $ok; my $m=IO::K8s::HEAD->default_resource_map; print JSON::PP->new->canonical->pretty->encode({map {$_=>$m->{$_}} grep {index($_,"/")<0} keys %$m})' > /tmp/io-k8s-head-short.json
diff -u /tmp/io-k8s-head-short.json /tmp/io-k8s-current-short.json
cp /tmp/io-k8s-current-short.json t/data/short-name-compat.json
```

Save only the reviewed current object as the fixture.
Explicitly review and approve every added alias and every retarget; expected
new aliases include `ClusterTrustBundle`, `DeviceTaintRule`, `LeaseCandidate`,
`PodGroup`, `ResourcePoolStatusRequest`, `StorageVersion`,
`StorageVersionMigration`, and `Workload`. No existing bare alias may retarget
silently. Pin all values, including at least:

```json
{
  "Event": "Api::Core::V1::Event",
  "HorizontalPodAutoscaler": "Api::Autoscaling::V2::HorizontalPodAutoscaler",
  "DeviceClass": "Api::Resource::V1::DeviceClass",
  "VolumeAttributesClass": "Api::Storage::V1::VolumeAttributesClass"
}
```

The real fixture contains the complete approved map, not only this excerpt.
Record newly approved aliases explicitly in `Changes`.

- [ ] **Step 4: RED/GREEN — build the independent exhaustive oracle**

Create `t/43_spec_kind_dispatch.t`. Load the GVK fixture and exceptions,
translate `def_key` to its expected Perl class using the same segment
contractions as `maint/spec-drift-check.pl`, then assert for every dispatchable
non-List entry:

```perl
is($io->expand_class("$api_version/$kind"), $expected, "$gvk qualified");
is($io->expand_class($kind, $api_version), $expected, "$gvk split");
use_ok($expected);
```

Copy the drift checker's segment contractions exactly and add explicit oracle
checks for the `apiextensions-apiserver` and `kube-aggregator` paths. Assert
all 311 fixture entries are accounted for, every dispatchable non-List entry
resolves in both public forms, and every one of the fourteen multi-version
collision Kinds uses valid construction literals. Where `namespaced` is
non-null, assert the expected class does or does not consume
`IO::K8s::Role::Namespaced`. Verify exception presence and that every
`non_dispatchable_kinds` entry is used. Compare the live bare map exactly with
the approved compatibility snapshot.

Run RED against the current incomplete map; the observed dirty baseline has
exactly two official qualified-map gaps, `events.k8s.io/v1/Event` and
`autoscaling/v1/HorizontalPodAutoscaler`. Complete those literals and run the
same subtest GREEN. Do not add namespace-substitution or AutoGen expectations
yet; Tasks 4 and 6 extend this shared test after those seams exist.

- [ ] **Step 5: GREEN characterization — real inflation and providers**

Use valid literals to cover core, grouped, every multi-version collision Kind,
and provider resolution. Include:

```perl
isa_ok($io->inflate({
  apiVersion => 'events.k8s.io/v1', kind => 'Event',
  metadata => { name => 'event' },
}), 'IO::K8s::Api::Events::V1::Event');

isa_ok($io->inflate({
  apiVersion => 'autoscaling/v1', kind => 'HorizontalPodAutoscaler',
  metadata => { name => 'hpa' },
  spec => { maxReplicas => 2, minReplicas => 1,
            scaleTargetRef => { apiVersion => 'apps/v1', kind => 'Deployment', name => 'app' },
            targetCPUUtilizationPercentage => 70 },
}), 'IO::K8s::Api::Autoscaling::V1::HorizontalPodAutoscaler');
```

Assert bare Event/HPA retain their approved pinned defaults. Exact provider
duplicates remain first-wins while a later provider is still reachable only by
its `+Full::Class` mapping.

- [ ] **Step 6: RED/GREEN — make every explicit lookup fail closed**

Add a matrix for both qualified-string and split-call forms covering an unknown
GVK, a mismatched official GVK such as `apps/v1/Pod`, malformed versions, and
an empty-but-explicit apiVersion. The API must distinguish omitted from
explicitly supplied empty version; do not use truthiness as that distinction.
For every explicit bad version, `expand_class` returns `undef`, while both
`inflate` and `new_object` die with an error containing the requested Kind and
the exact displayed apiVersion (including an explicit empty marker). No case
may fall through to a bare alias.

Thread an explicit-request flag through `expand_class` as needed. Complete the
existing map with literal entries including:

```perl
'events.k8s.io/v1/Event' => 'Api::Events::V1::Event',
'autoscaling/v1/HorizontalPodAutoscaler' =>
    'Api::Autoscaling::V1::HorizontalPodAutoscaler',
```

Keep bare Event and HPA unchanged. Add one private resolver-error helper used by
`inflate` and `new_object`.

- [ ] **Step 7: Integrated GREEN and regression seams**

Run:

```text
prove -lv t/43_spec_kind_dispatch.t
prove -lv t/40_karr_11_multi_version_dispatch.t
prove -lv t/41_api_group_short_form.t
perl maint/spec-drift-check.pl --spec spec/v1.36.3.json
prove -lr t/
```

Expected: `t/43` and the full recursive suite PASS; `t/40` has 25 tests;
drift tiers 1-3 remain zero. Keep Karr #17 open until this integrated run passes.

- [ ] **Step 8: Add the user-visible Changes entry and commit**

Under `{{$NEXT}}`, document exact official GVK coverage, fail-closed constructor
and inflate errors, Events v1/HPA v1 fixes, preserved and newly introduced bare
aliases, and the offline fixture guard. Stage only this task's listed files.
Require `git diff --cached --name-only` to match them and review the full
`git diff --cached`. Commit subject:
`Make official GVK dispatch exact and fail closed` with `Karr: #17` and trailers.

### Task 3: Correct the stale dispatch-test comment (Karr #19)

**Files:**
- Modify: `t/40_karr_11_multi_version_dispatch.t`

- [ ] **Step 1: Replace the obsolete mechanism name**

Change the comment referring to `BUILD/_qualify_defaults` to say the literal
qualified entries in `%DEFAULT_RESOURCE_MAP` are the karr #11 mechanism. Do not
change assertions.

- [ ] **Step 2: Verify and commit**

Run: `prove -lv t/40_karr_11_multi_version_dispatch.t`

Expected: PASS with 25 tests. Commit subject:
`Correct static dispatch map test commentary` with `Karr: #19` and trailers.
Stage only `t/40_karr_11_multi_version_dispatch.t`; review
`git diff --cached --name-only` and `git diff --cached` first.

---

## Chunk 2: Runtime correctness follow-ups

### Task 4: Support schema inheritance for class_namespaces (Karr #18)

**Files:**
- Modify: `lib/IO/K8s/Resource.pm`
- Modify: `lib/IO/K8s/Role/Resource.pm`
- Modify: `lib/IO/K8s/Role/APIObject.pm`
- Modify: `lib/IO/K8s.pm`
- Add: `t/44_class_namespace_inheritance.t`
- Modify: `t/43_spec_kind_dispatch.t`
- Modify: `Changes`

- [ ] **Step 1: Write failing subclass and collision tests**

Define test packages inline: a plain subclass of Core v1 Pod under
`My::K8s::Api::Core::V1::Pod`, a child overriding one `k8s` attribute, a
multiple-inheritance class with explicit `mro 'c3'`, a complete custom
APIObject, and a namespace override reporting the wrong API version.

Assert the Pod subclass resolves through `class_namespaces`, inflates metadata
and nested containers as typed objects, serializes `apiVersion: v1`, and keeps
child declarations nearest-wins. Give parent and child incompatible types for
one overridden attribute, then prove child construction, inflate, and
serialization use the child's Moo constraint and registry metadata rather than
the inherited accessor. In the C3 diamond, make competing ancestors declare
the same attribute and prove the active C3 order wins and serialization emits
that JSON key exactly once.

Prime both merged-metadata and ordered-attribute caches for a descendant, add a
late `k8s` declaration to an ancestor, and prove the next lookup observes it.
Assert wrong wire identity is rejected with the requested and actual GVK in the
error.

Extend `t/43_spec_kind_dispatch.t` with the namespace exact/missing/mismatched
wire-identity cases deferred from Task 2, including conflicting namespace
candidates and the `+Full::Class` exemption.

- [ ] **Step 2: Run RED**

Run: `prove -lv t/44_class_namespace_inheritance.t`

Expected: the plain subclass fails metadata/nested inflation because the exact
class registry is empty; wire identity is missing or mismatched. All test setup
and packages compile; only the named behavior assertions fail.

- [ ] **Step 3: Implement MRO-aware registry metadata**

In `IO::K8s::Role::Resource::_k8s_attr_info`, use the active
`mro::get_linear_isa($class)` and merge ancestor registries from furthest to
nearest. Cache the merged result by concrete class. Create one shared internal
cache-invalidation seam owned by the registry; `IO::K8s::Resource::_k8s` calls
it after every declaration and it clears both merged-metadata and
ordered-attribute caches globally so already-cached descendants cannot stale.

Make `_k8s_attributes` return the same nearest-wins ordered attribute set, not
only the concrete package array, so serialization includes inherited fields
once. Preserve C3 precedence while de-duplicating overridden names.

Do not treat `$caller->can($attr_name)` as a reason to skip an inherited Moo
attribute override. Distinguish a locally installed accessor from an inherited
one; for the inherited case use Moo's `has '+name' => (...)` override path with
the child registry's computed constraint/coercion/init_arg. Keep the early
return only for a genuinely local accessor supplied by the class/role.

- [ ] **Step 4: Preserve inherited wire identity**

In `IO::K8s::Role::APIObject::api_version`, if the concrete class name is not a
recognized built-in namespace and no explicit method override exists, walk the
active MRO and derive from the nearest recognized IO::K8s ancestor. Keep
explicit CRD methods authoritative.

Thread the expected canonical apiVersion and Kind from both explicit public
lookup forms into `_resolve_mapped`. Validate only a namespace-substituted
relative-map candidate: it must expose class-level `api_version` equal to the
request and a matching `kind`. The first existing namespace override selected
for an exact request raises a descriptive error immediately when identity is
missing or mismatched; it must not continue to another namespace or silently
fall back to the built-in. Diagnostics name requested and actual GVK. Bare
aliases retain historical behavior. Keep `+Full::Class` mappings exempt from
namespace substitution and validation.

- [ ] **Step 5: Run GREEN and nearby tests**

Run:

```text
prove -lv t/44_class_namespace_inheritance.t
prove -lv t/06_resource_map.t
prove -lv t/13_role_labeled.t
prove -lv t/43_spec_kind_dispatch.t
prove -lv t/41_api_group_short_form.t
prove -lv t/42_registry_synthesis_roundtrip.t
```

Expected: all PASS.

- [ ] **Step 6: Update Changes and commit**

Document that `class_namespaces` subclasses now inherit schema metadata and
wire identity, with explicit GVK mismatch rejection. Commit subject:
`Inflate class namespace subclasses through inherited schemas` with `Karr: #18`
and trailers. Stage only the listed files, require
`git diff --cached --name-only` to match, and review `git diff --cached`.

### Task 5: Fix empty generic List apiVersion (Karr #22)

**Files:**
- Modify: `lib/IO/K8s/List.pm`
- Add: `t/45_list_api_version.t`
- Modify: `Changes`

- [ ] **Step 1: Write failing empty-list tests**

Cover Core Pod, Apps Deployment, RBAC Role, StorageClass,
StorageVersionMigration, a custom APIObject, a namespace subclass, an AutoGen
item class, an invalid class, and a class without `api_version`. Assert the
built-in exact wire
versions, including `rbac.authorization.k8s.io/v1`, `storage.k8s.io/v1`, and
`storagemigration.k8s.io/v1beta1`. Invalid/non-API classes return `undef` and
TO_JSON omits `apiVersion`. Also prove a non-empty list delegates to its first
item even when `item_class` disagrees, and `kind` uses only the final class-name
segment plus `List` for empty namespace/custom/AutoGen lists.

For the custom APIObject, namespace subclass, and AutoGen item class, assert
both the exact class-level wire version returned by `List->api_version` and the
same exact `apiVersion` in `TO_JSON`; these are not kind-only cases.

- [ ] **Step 2: Run RED**

Run: `prove -lv t/45_list_api_version.t`

Expected: grouped built-ins fail because they currently return shortened
invalid groups, while custom/namespace/AutoGen empty-list cases fail because
the regex path cannot derive their versions; test setup compiles.

- [ ] **Step 3: Implement class-method delegation**

For an empty list with `item_class`, load the class safely and call its
class-level `api_version()` when available. Guard both class loading and the
method invocation so either failure returns `undef`. Remove the duplicated
package-name group derivation. Preserve non-throwing `undef` on invalid/non-API
classes and first-item delegation for non-empty lists.

- [ ] **Step 4: Run GREEN and commit**

Run: `prove -lv t/45_list_api_version.t t/to_yaml.t`

Update Changes. Commit subject: `Derive empty List apiVersion from item classes`
with `Karr: #22` and trailers. Stage only the listed files, verify
`git diff --cached --name-only`, and review `git diff --cached`.

### Task 6: Make AutoGen GVK-aware (Karr #23)

**Files:**
- Modify: `lib/IO/K8s.pm`
- Modify: `lib/IO/K8s/AutoGen.pm`
- Add: `t/46_autogen_api_version.t`
- Modify: `t/43_spec_kind_dispatch.t`
- Modify: `Changes`

- [ ] **Step 1: Write failing deterministic-selection tests**

Use an in-memory OpenAPI spec containing Core `v1/Kind`, the same grouped Kind
in v1alpha1 and v1beta1, two definitions claiming one exact GVK, one definition
advertising multiple GVKs, malformed GVK metadata, case-only differences, and
a suffix-only legacy definition. Assert both public explicit forms (qualified
string and split Kind/apiVersion) try exact AutoGen before failing and never
fall through to a bare map or suffix candidate. Exact selection is
case-sensitive for group, version, and Kind and serializes the selected
apiVersion. Malformed metadata is not selectable, but a malformed entry naming
the Kind still suppresses suffix fallback. Ambiguity errors name the requested
GVK and every conflicting definition, and suffix fallback applies only to a
versionless request for which no GVK metadata names that Kind at all.

Generate two GVKs from one definition and assert distinct package names with
the exact `__GVK_` plus first 12 lowercase SHA-1 hex suffix. Repeating one GVK
reuses its package/cache; different GVKs never share it. Versionless selection
is stable across reversed hash construction order and reuses the package keyed
by the selected canonical GVK.

- [ ] **Step 2: Run RED**

Run: `prove -lv t/46_autogen_api_version.t`

Expected: only exact-selection/identity assertions fail because current lookup
selects by Kind/hash order and ignores explicit apiVersion; test setup compiles.

- [ ] **Step 3: Thread exact GVK through IO::K8s**

Pass an explicit-request flag and optional `$api_version` into
`_autogen_class_for` and `_find_definition_for_kind`. Both qualified-string and
split explicit lookup paths must call the exact AutoGen seam after an exact map
miss and return `undef` if it finds nothing. `_find_definition_for_kind`
returns both the definition name and selected canonical GVK. For explicit
requests, filter well-formed metadata by exact case-sensitive GVK and die when
more than one definition matches. For versionless requests, sort definition
keys, then matching well-formed GVKs by canonical apiVersion. Only then use
sorted suffix fallback, and only when no GVK metadata entry names the exact
case-sensitive Kind at all. A malformed entry that still names the Kind is not
a selectable candidate but suppresses the legacy suffix path. Never use suffix
fallback for explicit requests.

- [ ] **Step 4: Key generated packages and caches by exact GVK**

Extend `IO::K8s::AutoGen::get_or_generate` with the selected canonical GVK.
Append `::__GVK_` plus `substr(sha1_hex($gvk), 0, 12)` to resource package
identity, include GVK in both caches, and install the selected official
`api_version`. Embedded referenced types without GVK retain their existing
definition-derived identity.

Keep the existing direct four-argument `get_or_generate` call working for
callers that do not supply a GVK, and update its POD signature/options. Extend
`t/43_spec_kind_dispatch.t` here with the exact AutoGen qualified/split and
ambiguity branches deferred from Task 2.

- [ ] **Step 5: Run GREEN and AutoGen regressions**

Run:

```text
prove -lv t/46_autogen_api_version.t
prove -lv t/04_autogen.t
prove -lv t/06_resource_map.t
prove -lv t/43_spec_kind_dispatch.t
```

Expected: all PASS; no live-cluster requirement.

- [ ] **Step 6: Update Changes and commit**

Document exact and deterministic multi-version AutoGen dispatch. Commit
subject: `Make AutoGen class selection GVK-aware` with `Karr: #23` and trailers.
Stage only the listed files, verify `git diff --cached --name-only`, and review
`git diff --cached`.

---

## Chunk 3: Packaging, trust boundary, and release-quality verification

### Task 7: Declare Module::Runtime (Karr #24)

**Files:**
- Modify: `cpanfile`
- Modify: `Changes`

- [ ] **Step 1: Capture the failing packaging assertion**

Run: `/storage/raid/home/getty/perl5/bin/dzil listdeps | rg '^Module::Runtime$'`

Expected before fix: exit 1, no matching dependency.

- [ ] **Step 2: Add the direct prerequisite**

Add `requires 'Module::Runtime';` next to the other runtime module-loading
dependencies. Add a Changes bullet explaining clean installs no longer rely on
a transitive/system copy.

- [ ] **Step 3: Verify and commit**

Run: `/storage/raid/home/getty/perl5/bin/dzil listdeps | rg '^Module::Runtime$'`

Expected: exactly one line. Commit subject: `Declare Module::Runtime dependency`
with `Karr: #24` and trailers. Stage only `cpanfile` and `Changes`, verify
`git diff --cached --name-only`, and review `git diff --cached`.

### Task 8: Document the pk8s trust boundary (Karr #25)

**Files:**
- Modify: `lib/IO/K8s.pm` POD only
- Modify: `README.md`
- Modify: `Changes`

- [ ] **Step 1: Add matching public warnings**

Delegate the `lib/IO/K8s.pm` POD-only edit to `io-k8s-doc-writer`. The
orchestrator edits the matching `README.md` prose and `Changes`. Immediately
beside each `.pk8s` loader example, state that the file is Perl code evaluated
in-process, can perform arbitrary actions with the caller's permissions, and
must only come from a trusted source. Point untrusted/data-only input to
`load_yaml`.

- [ ] **Step 2: Verify documentation build and commit**

Run:

```text
perl -Ilib -MIO::K8s -e 1
/storage/raid/home/getty/perl5/bin/dzil clean
/storage/raid/home/getty/perl5/bin/dzil build
/storage/raid/home/getty/perl5/bin/dzil clean
```

Expected: module loads and build completes without POD warnings. Add a Changes
bullet. Commit subject: `Document pk8s manifests as trusted Perl code` with
`Karr: #25` and trailers. Stage only the three listed files, verify
`git diff --cached --name-only`, and review `git diff --cached`.

### Task 9: Final integrated verification and board closure

**Files:**
- Verify: all changed files
- Modify only if verification finds a ticket-scoped defect

- [ ] **Step 1: Run whitespace and dependency checks**

Run:

```text
git diff --check origin/master..HEAD
git diff --check
git status --short
/storage/raid/home/getty/perl5/bin/dzil listdeps
```

Expected: both committed and working-tree diffs are clean, `git status --short`
is empty, and `Module::Runtime` is present. Reconcile this state explicitly
against the pre-execution dirty-tree capture: every original path must now be
in its assigned ticket commit, not merely absent or silently reverted.

- [ ] **Step 2: Run the complete recursive suite**

Run: `prove -lr t/`

Expected: all non-optional tests, including 42-46, PASS; report the optional
live-cluster subtest as skipped, not passed or executed.

- [ ] **Step 3: Run upstream coverage and distribution verification**

Run:

```text
perl maint/spec-drift-check.pl --spec spec/v1.36.3.json
/storage/raid/home/getty/perl5/bin/dzil clean
/storage/raid/home/getty/perl5/bin/dzil build
```

Expected: drift tiers 1-3 are zero and clean build/test pass without warnings.
Before the intervening `dzil clean`, run these exact assertions against
`IO-K8s-1.106/META.json`:

```text
perl -MJSON::PP -0777 -e 'my $m=JSON::PP::decode_json(<>); die "Module::Runtime missing from runtime requires\n" unless exists $m->{prereqs}{runtime}{requires}{"Module::Runtime"}' IO-K8s-1.106/META.json
perl -MJSON::PP -MFile::Find -e 'my($mf,$root)=@ARGV; open my $h,"<",$mf or die $!; local $/; my $m=JSON::PP::decode_json(<$h>); my @f; find(sub{push @f,$File::Find::name if /\.pm\z/},$root); my @bad; for my $f(@f){open my $p,"<",$f or die $!; local $/; my $s=<$p>; while($s=~/^package\s+([A-Za-z_]\w*(?:::\w+)*)/mg){my $n=$1; push @bad,"$n ($f)" unless $m->{provides}{$n} && defined $m->{provides}{$n}{version} && $m->{provides}{$n}{version} eq $m->{version}}} die "META provides missing/wrong version: @bad\n" if @bad' IO-K8s-1.106/META.json lib
```

The first asserts the runtime prerequisite. The second asserts that every
package declared below `lib/` appears in `provides` at the distribution
version, as required by the repository release checker.

Then finish from a clean build state:

```text
/storage/raid/home/getty/perl5/bin/dzil clean
/storage/raid/home/getty/perl5/bin/dzil test
/storage/raid/home/getty/perl5/bin/dzil clean
```

- [ ] **Step 4: Audit Changes and commit history**

Confirm `{{$NEXT}}` covers exact GVK dispatch, fail-closed constructor/inflate
errors, Events/HPA, preserved and newly approved short aliases, class namespace
inheritance, List versions, AutoGen versions, the prerequisite, and pk8s trust.
Confirm every task commit has `Co-authored-by: Codex <noreply@openai.com>` and
`Codex-Model: GPT-5`.

- [ ] **Step 5: Independent final review**

Dispatch a final code reviewer over `origin/master..HEAD` plus the recorded
dirty-tree baseline. Resolve every blocking issue through the owning ticket and
rerun its focused and integrated verification. Then dispatch the required
`io-k8s-release-checker` pre-release audit and resolve every blocker it reports
before board closure.

Every review fix is staged only with its owning ticket's paths, reviewed with
`git diff --cached --name-only` and `git diff --cached`, and committed with that
ticket number plus the required trailers. Append the additional SHA to that
ticket. If an audit blocker is genuinely outside existing scope, create a
separate Karr ticket instead of hiding it in another commit. Rerun Steps 1-4
after the last fix. Never run `dzil release`.

- [ ] **Step 6: Close Karr tickets serially**

Using the established working Karr container wrapper, execute these commands
one ticket at a time for IDs 17, 18, 19, 21, 22, 23, 24, and 25 (substitute the
actual SHA and focused verification text; include any follow-up fix SHAs):

```text
karr edit ID -a "Completed in SHA; verification: COMMANDS/RESULTS"
karr edit ID --release
karr move ID done
karr show ID
```

Do not parallelize these ref mutations. Finally run `karr board`,
`karr list --status done --compact`, and `karr show 26`. Expected final state:
#17, #18, #19, and #21-#25 are `done` and unclaimed; #20 and #27 were already
completed during design/planning; #26 alone remains in backlog as the deferred
registry-metadata architecture concern. Never run `dzil release`.
