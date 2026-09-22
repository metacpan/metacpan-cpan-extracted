# CRD Step 4: Bundled Providers to Full Depth -- Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Every bundled CRD provider (Cilium, Traefik, cert-manager, Gateway API, AgentSandbox, K3s) models `spec` and `status` to the full depth of its upstream schema, one class file per structure, named after the upstream Go types, with embedded core types referenced rather than re-modeled; Gateway API ships every served track; `maint/crd-drift-check.pl` reports zero opaque specs and zero missing fields and can prove the checked-in files still match the manifest.

**Architecture:** Two phases. Phase A extends the step-3 tooling so the mass work is a render-and-curate loop rather than typing: AutoGen and the emitter learn to reference a shipped core class when a nested schema is exactly that class's shape (`reuse_core`), the emitter learns short provider class names and a per-Kind overlay (roles, verbatim extra lines) so that a checked-in provider file is *exactly* emitter output plus overlay, and the drift-check gains `--render` (every Kind of a provider, not only the gaps) and `--check` (diff the rendered output against `lib/`). Phase B is one task per provider, run by a Sonnet-class `io-k8s-worker`: write the name map and overlay from the upstream Go types, render, review, copy into `lib/`, wire the resource map and tests, until `--check` and the drift report are clean. The classes stay hand-checked-in: nothing in the tooling writes into `lib/`.

**Tech Stack:** Perl 5.10+, Moo, Type::Tiny, YAML::PP, the step-3 `IO::K8s::CRD::Emitter`, `maint/crd-drift-check.pl`. `prove -lr t/` (the `-r` is required); `dzil test` before each provider commit.

**Spec:** `docs/superpowers/specs/2026-09-03-crd-design.md`, decisions D5, D6, D7 (and D8's "builder roles stay hand-maintained"). Ticket k95. Steps 1-3 are on master.

## Facts this plan rests on (measured 2026-09-03 with the step-3 emitter)

| Provider | Kinds (served) | nested classes at full depth | of which exact core-class shapes |
|---|---:|---:|---:|
| Cilium | 26 versions | 619 | 241 |
| cert-manager | 6 | 464 | 249 |
| Gateway API | 14 | 253 | 51 |
| Traefik | 10 | 143 | 16 |
| AgentSandbox | 8 | (top level modeled today; full render pending) | -- |
| K3s | 4 | schemaless upstream: from Go types by hand | -- |

- The most frequent embedded shapes are `Meta::V1::LabelSelector` (138), the `{key, operator, values}` requirement (162 -- ambiguous between `NodeSelectorRequirement`, `LabelSelectorRequirement` and others; the parent decides), `metav1.Condition` (28), `Core::V1::PodAffinityTerm` (24), `Core::V1::HTTPHeader` (30). cert-manager inlines a whole `PodTemplateSpec`, which is what pushed names past Perl's identifier limit in step 3; referencing `Core::V1::PodTemplateSpec` removes that subtree entirely.
- `maint/crd-drift-check.pl`'s `shipped_spec_fields` only recognizes an inline-struct spec (`is_inline_struct`); a spec declared as a named class is reported as opaque. Phase A fixes that.
- `IO::K8s::Resource::%_class_prefix` knows no provider prefix, so a provider class can only be referenced as `'+IO::K8s::Traefik::V1alpha1::X'`; the core style is the short form.
- The emitter renders `required => 'schema'` (D5 + the step-2 ruling): provider classes never reject a cluster document.

## Decisions this plan takes

- **Provider files are reproducible.** A checked-in provider class equals `emitter(manifest, names, overlay)`. The overlay (`maint/crd-render/<Provider>.yaml`) carries, per Kind, the roles to compose (`with`), verbatim extra lines (`extra`, e.g. `sub _netpol_format { 'cilium' }`) and the Go names for nested classes (`names`). `--check` proves the equality. This keeps D5's "hand-built, checked in, POD-readable" (the POD is the upstream description, the same text the core classes carry) while making an upstream bump a re-render plus a diff, not a rewrite.
- **`reuse_core` is on by default** in AutoGen, `add_crd` and the emitter: a nested object whose property set is exactly a shipped core/apimachinery class's key set is typed as that class. Ambiguity is resolved by the parent (a field of a core class is typed as that core class's registry says), then by preference (`Meta::V1`, `Core::V1`, then first alphabetically); an unresolved ambiguity stays a nested class. Opt-out `reuse_core => 0`.
- **Provider prefixes join `%_class_prefix`** (`Cilium`, `Traefik`, `CertManager`, `GatewayAPI`, `K3s`, `AgentSandbox` and, for step 7, `PrometheusOperator`, `VolumeSnapshot`, `ExternalSecrets`), so a provider class is written `'Traefik::V1alpha1::MiddlewareSpec'` like a core class is written `'Core::V1::PodSpec'`.
- **Go type names come from the upstream Go sources at the pinned version**, recorded in the overlay by the provider task's agent; the emitter's default (joined path) is only a fallback. Shared types (Cilium's `Rule`) become one class by mapping every occurrence to the same name; the emitter renders a name once.
- **Gateway API served tracks (D7):** v1beta1 Gateway/GatewayClass/HTTPRoute, v1alpha2 TCPRoute/UDPRoute/TLSRoute, v1alpha3 TLSRoute/BackendTLSPolicy get classes; the eight `ignore_missing_kinds` exceptions go away; short names stay on the v1 storage classes.
- **Builder roles** are composed through the overlay and re-checked by hand against the modeled fields (D8); their tests (t/16-t/19, t/69) must stay green.

## Global Constraints

- Every module keeps `our $VERSION = '1.108';`.
- No new CPAN dependencies.
- `prove -lr t/` green with nothing skipped after every task; `dzil test` green before every provider commit; `t/02_compile_all.t`, `t/25_real_world.t`, `t/26_build_verify.t` cover every new class automatically.
- Nothing under `lib/` is written by tooling: the agent copies rendered files in after review. `--suggest-dir`/`--render-dir` keep refusing `lib/`.
- Commit trailer:
  ```
  Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>
  Claude-Session: https://claude.ai/code/session_01MysDYqMAm8iUAbiTm1XhYi
  ```
- Delegation: Phase A tasks to `io-k8s-worker` (sonnet); each Phase B provider task to a fresh `io-k8s-worker` on **sonnet** (the mass work, per the user's cost rule); reviews per the usual lanes; Phase B tasks run one at a time (shared files: `Changes`, `maint/crd-drift-exceptions.yaml`, `lib/IO/K8s/Resource.pm`).

## File structure

| File | Responsibility after this plan |
|------|-------------------------------|
| `lib/IO/K8s/Resource.pm` | `%_class_prefix` gains the provider prefixes; `class_prefixes()` accessor |
| `lib/IO/K8s/AutoGen.pm` | `reuse_core`: core-shape index, parent-context resolution, preference order |
| `lib/IO/K8s/CRD.pm` | `generate(..., reuse_core => ...)` passthrough |
| `lib/IO/K8s/CRD/Emitter.pm` | short provider names, overlay (`with`, `extra`), `names` from the overlay |
| `maint/crd-drift-check.pl` | `--render`, `--render-dir`, `--check`, `--overlay`; named spec classes recognized |
| `maint/crd-render/<Provider>.yaml` | per-provider overlay: names, roles, extra lines |
| `lib/IO/K8s/<Provider>/<Version>/*.pm` | the full-depth classes |
| `lib/IO/K8s/<Provider>.pm` | resource_map (new tracks), POD counts |
| `t/75_reuse_core.t`, `t/76_emitter_overlay.t`, per-provider tests | tests |

---

## Phase A -- tooling

### Task A1: `reuse_core` in AutoGen

**Lane:** `io-k8s-worker`.

**Files:**
- Modify: `lib/IO/K8s/AutoGen.pm` (new `%_core_shapes` index built lazily from `lib/IO/K8s/Api` + `Apimachinery`; `_core_class_for($schema, $parent_core_class, $field)`; hook in `_schema_to_type_spec`'s object / items / additionalProperties branches before `_nested_class`; option `reuse_core` threaded through `get_or_generate` -> `_generate_class` -> `_schema_to_type_spec`, default 1)
- Modify: `lib/IO/K8s/CRD.pm` (`generate($crd, $namespace, %opts)` passes `reuse_core`)
- Test: `t/75_reuse_core.t`

**Interfaces:**
- Produces: `IO::K8s::AutoGen::core_class_for_shape(\@json_keys)` (list of candidate classes, preference-ordered); `get_or_generate(..., reuse_core => 0|1)`; registry entries for reused fields carry `class => 'IO::K8s::Api::...'` exactly like a hand-written reference.
- Rule: a nested object schema with a non-empty `properties` set S is reused when (1) the parent field is itself a reused core class C and C's registry has this field typed as class D whose key set equals S -> D; else (2) exactly one shipped class has key set S -> it; else (3) several -> the first by preference `Meta::V1`, `Core::V1`, then alphabetical, **only if** all candidates have identical registries (same types per key), otherwise no reuse; (4) `items`/`additionalProperties` shaped that way follow the same rule for the element class.

- [ ] **Step 1: Write the failing test**

Create `t/75_reuse_core.t`:

```perl
#!/usr/bin/env perl
# D5: a nested schema whose property set is exactly a shipped core class's
# key set is typed as that class instead of a nested AutoGen class.
use strict;
use warnings;
use Test::More;
use Test::Exception;

use IO::K8s;
use IO::K8s::AutoGen;

IO::K8s::AutoGen::clear_cache();

my $label_selector = {
    type => 'object',
    properties => {
        matchLabels      => { type => 'object', additionalProperties => { type => 'string' } },
        matchExpressions => {
            type  => 'array',
            items => {
                type => 'object',
                properties => {
                    key      => { type => 'string' },
                    operator => { type => 'string' },
                    values   => { type => 'array', items => { type => 'string' } },
                },
            },
        },
    },
};

my $schema = {
    type => 'object',
    'x-kubernetes-group-version-kind' => [ { group => 'reuse.example.com', version => 'v1', kind => 'Thing' } ],
    properties => {
        apiVersion => { type => 'string' }, kind => { type => 'string' }, metadata => { type => 'object' },
        spec => {
            type => 'object',
            properties => {
                selector    => $label_selector,
                requirement => {                      # {key,operator,values} alone: ambiguous
                    type => 'object',
                    properties => {
                        key      => { type => 'string' },
                        operator => { type => 'string' },
                        values   => { type => 'array', items => { type => 'string' } },
                    },
                },
                header => {                           # Core::V1::HTTPHeader: unique
                    type => 'object',
                    properties => { name => { type => 'string' }, value => { type => 'string' } },
                },
                partial => {                          # LabelSelector minus one field: not reused
                    type => 'object',
                    properties => { matchLabels => { type => 'object', additionalProperties => { type => 'string' } } },
                },
            },
        },
    },
};

my $class = IO::K8s::AutoGen::get_or_generate('com.example.reuse.v1.Thing', $schema, {}, 'IO::K8s::_AUTOGEN_reuse',
    api_version => 'reuse.example.com/v1', kind => 'Thing', resource_plural => 'things', is_namespaced => 1);
my $spec = $class->_k8s_attr_info->{spec}{class}->_k8s_attr_info;

subtest 'exact core shapes are referenced' => sub {
    is($spec->{selector}{class}, 'IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::LabelSelector', 'LabelSelector reused');
    is($spec->{header}{class}, 'IO::K8s::Api::Core::V1::HTTPHeader', 'unique shape reused');
    like($spec->{requirement}{class}, qr/^IO::K8s::_AUTOGEN_reuse::.*::Spec::Requirement$/, 'ambiguous shape stays a nested class');
    like($spec->{partial}{class}, qr/::Spec::Partial$/, 'a subset shape stays a nested class');
};

subtest 'parent context resolves the requirement inside a reused LabelSelector' => sub {
    my $k8s = IO::K8s->new;
    $k8s->add({ Thing => "+$class" });
    my $t = $k8s->inflate({ apiVersion => 'reuse.example.com/v1', kind => 'Thing', metadata => { name => 't' },
        spec => { selector => { matchExpressions => [ { key => 'k', operator => 'In', values => ['a'] } ] } } });
    isa_ok($t->spec->selector, 'IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::LabelSelector');
    isa_ok($t->spec->selector->matchExpressions->[0], 'IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::LabelSelectorRequirement');
    is_deeply($t->TO_JSON->{spec}{selector}{matchExpressions}[0], { key => 'k', operator => 'In', values => ['a'] }, 'round-trips');
};

subtest 'reuse_core => 0 keeps nested classes' => sub {
    IO::K8s::AutoGen::clear_cache();
    my $c = IO::K8s::AutoGen::get_or_generate('com.example.reuse.v1.Thing', $schema, {}, 'IO::K8s::_AUTOGEN_noreuse',
        api_version => 'reuse.example.com/v1', kind => 'Thing', resource_plural => 'things', is_namespaced => 1, reuse_core => 0);
    like($c->_k8s_attr_info->{spec}{class}->_k8s_attr_info->{selector}{class}, qr/::Spec::Selector$/, 'nested class');
};

subtest 'core_class_for_shape lists candidates in preference order' => sub {
    my @c = IO::K8s::AutoGen::core_class_for_shape([qw(key operator values)]);
    ok(@c > 1, 'several candidates');
    is($c[0], 'IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::LabelSelectorRequirement', 'Meta::V1 first');
};

done_testing;
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `prove -l t/75_reuse_core.t`
Expected: FAIL -- `selector` is a nested `::Spec::Selector` class.

- [ ] **Step 3: Implement in `lib/IO/K8s/AutoGen.pm`**

Add after `_has_properties`:

```perl
# ---------------------------------------------------------------------------
# reuse_core (D5): a nested object whose property set is exactly the key set
# of a shipped core / apimachinery class is typed as that class. CRD schemas
# inline the types they embed (a LabelSelector, a PodTemplateSpec), and
# modeling them again would give every provider its own copy of PodSpec.
#
# The index is built once from the shipped class files. Ambiguity (several
# shipped classes share a key set: {key, operator, values}) is resolved by
# the parent first -- inside a reused LabelSelector the field is whatever
# LabelSelector's registry says -- then by preference, and only when the
# candidates agree on every field type; otherwise the schema keeps its own
# nested class. A subset or superset never matches: an upstream that trims
# a core type gets its own class.
# ---------------------------------------------------------------------------

my %_core_shapes;      # "k1,k2,..." -> [ classes, preference-ordered ]
my $_core_indexed = 0;

my @CORE_PREFERENCE = (
    'IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::',
    'IO::K8s::Api::Core::V1::',
);

sub _core_rank {
    my ($class) = @_;
    for my $i (0 .. $#CORE_PREFERENCE) {
        return $i if index($class, $CORE_PREFERENCE[$i]) == 0;
    }
    return scalar @CORE_PREFERENCE;
}

sub _index_core_shapes {
    return if $_core_indexed++;
    require File::Find;
    require Module::Runtime;
    require IO::K8s::Role::Resource;
    (my $lib = $INC{'IO/K8s/AutoGen.pm'}) =~ s{/IO/K8s/AutoGen\.pm\z}{};
    my @files;
    File::Find::find(sub { push @files, $File::Find::name if /\.pm\z/ },
        "$lib/IO/K8s/Api", "$lib/IO/K8s/Apimachinery");
    for my $file (sort @files) {
        (my $class = $file) =~ s{^\Q$lib\E/}{};
        $class =~ s{/}{::}g;
        $class =~ s/\.pm\z//;
        eval { Module::Runtime::use_module($class); 1 } or next;
        my $info = IO::K8s::Role::Resource::_k8s_attr_info($class);
        my @keys = sort map { $info->{$_}{json_key} // $_ } grep { $_ ne 'metadata' } keys %$info;
        next unless @keys;
        push @{ $_core_shapes{ join ',', @keys } }, $class;
    }
    for my $shape (keys %_core_shapes) {
        @{ $_core_shapes{$shape} } = sort { _core_rank($a) <=> _core_rank($b) || $a cmp $b } @{ $_core_shapes{$shape} };
    }
}

sub core_class_for_shape {
    my ($keys) = @_;
    _index_core_shapes();
    my $shape = join ',', sort @$keys;
    return @{ $_core_shapes{$shape} // [] };
}

# The class to reuse for a nested object schema, or undef.
sub _core_class_for {
    my ($schema, $parent_core, $field_name) = @_;
    return undef unless _has_properties($schema);
    my @keys = sort keys %{ $schema->{properties} };
    my @candidates = core_class_for_shape(\@keys);
    return undef unless @candidates;

    if ($parent_core) {
        require IO::K8s::Role::Resource;
        my $pinfo = IO::K8s::Role::Resource::_k8s_attr_info($parent_core);
        my ($attr) = grep { ($pinfo->{$_}{json_key} // $_) eq $field_name } keys %$pinfo;
        if (defined $attr && $pinfo->{$attr}{class}) {
            my $typed = $pinfo->{$attr}{class};
            return $typed if grep { $_ eq $typed } @candidates;
        }
    }
    return $candidates[0] if @candidates == 1;

    # Several shipped classes share this key set: reuse only when they agree
    # on every field's type, then take the preferred one.
    require IO::K8s::Role::Resource;
    my %sig;
    for my $c (@candidates) {
        my $info = IO::K8s::Role::Resource::_k8s_attr_info($c);
        $sig{ join ';', map { ($info->{$_}{json_key} // $_) . '=' . join('|', sort grep { $info->{$_}{$_} } keys %{ $info->{$_} }) } sort keys %$info } = 1;
    }
    return keys %sig == 1 ? $candidates[0] : undef;
}
```

The signature line above collapses each candidate's registry to `key=flags;...`; the implementer keeps it readable (a helper `_registry_signature($class)` is fine).

Thread the option: `get_or_generate` and `_generate_class` accept `reuse_core` (default 1) in `%opts`; `_generate_class` passes `$opts{reuse_core}` and the class's own core identity (`undef` for a generated class) into `_schema_to_type_spec($prop_schema, $all_defs, $namespace, $prop, $class, $reuse_core, $parent_core)`; nested calls pass `$parent_core` = the core class chosen for the parent (when the parent was reused there is no nested call at all -- reuse ends the recursion, since the core class already exists; so `$parent_core` is only ever set for the *element* of a reused container: `items` of a reused array field, `additionalProperties` of a reused map field). Concretely, in `_schema_to_type_spec`: before `_nested_class` in the object branch, `if ($reuse_core and my $core = _core_class_for($schema, $parent_core, $field_name)) { return "+$core"; }`; the array-items and additionalProperties branches do the same and return `["+$core"]` / `{ "+$core" => 1 }`. Nested classes generated because no core class matched pass `reuse_core` down unchanged.

`IO::K8s::CRD->generate($crd, $namespace, %opts)` forwards `reuse_core` to `get_or_generate`; `add_crd` accepts a trailing hashref of options (`$k8s->add_crd($path, { reuse_core => 0 })`) and documents it.

- [ ] **Step 4: Run the test to verify it passes**

Run: `prove -l t/75_reuse_core.t t/72_autogen_nested_objects.t t/73_add_crd.t t/74_crd_emitter.t`
Expected: PASS. If a t/72 or t/74 fixture happens to contain an exact core shape (none is expected), the reviewer decides whether the fixture or the assertion is right.

- [ ] **Step 5: Run the full suite; commit**

Run: `prove -lr t/` -- PASS.

```bash
git add lib/IO/K8s/AutoGen.pm lib/IO/K8s/CRD.pm lib/IO/K8s.pm t/75_reuse_core.t
git commit -m "AutoGen: reuse a shipped core class for a nested schema of exactly its shape (reuse_core, D5)"
```

---

### Task A2: provider prefixes, emitter overlay, short names

**Lane:** `io-k8s-worker`.

**Files:**
- Modify: `lib/IO/K8s/Resource.pm` (`%_class_prefix` gains `Cilium`, `Traefik`, `CertManager`, `GatewayAPI`, `K3s`, `AgentSandbox`, `PrometheusOperator`, `VolumeSnapshot`, `ExternalSecrets` -> `IO::K8s::<Same>`; new `sub class_prefixes { \%_class_prefix }`)
- Modify: `lib/IO/K8s/CRD/Emitter.pm` (`overlay` attribute; `_class_ref` uses `class_prefixes` for short names, longest prefix first; `_render_class` emits `with '...'` lines and `extra` lines from the overlay for the root Kind; `names` may come from the overlay's `names` map)
- Test: `t/76_emitter_overlay.t`

**Interfaces:**
- Overlay file shape (`maint/crd-render/<Provider>.yaml`):
  ```yaml
  base: IO::K8s::Traefik           # version directory appended per served version: IO::K8s::Traefik::V1alpha1
  kinds:
    Middleware:
      with: [IO::K8s::Role::Namespaced, IO::K8s::Role::MiddlewareBuilder]
      extra: []                      # verbatim lines after the `with` line
      names:                         # logical path below the Kind -> bare package name (Go type)
        Spec: MiddlewareSpec
        Spec::RateLimit: RateLimit
        Spec::RateLimit::SourceCriterion: SourceCriterion
    IngressRoute:
      with: [IO::K8s::Role::Namespaced, IO::K8s::Role::Routable]
      extra: ["sub _route_format { 'traefik' }"]
      names: { Spec: IngressRouteSpec, Spec::RoutesItem: Route, Spec::RoutesItem::ServicesItem: Service }
  ```
  `IO::K8s::CRD::Emitter->new(base => ..., overlay => $kind_overlay_hashref)` where `names` keys are logical paths (what `class_path` returns) rather than generated class names; the emitter maps them. `with` defaults to `[IO::K8s::Role::Namespaced]` for a namespaced Kind and `[]` otherwise.
- `_class_ref`: a class under a known prefix renders as `'<Prefix>::<Rest>'` (e.g. `'Traefik::V1alpha1::MiddlewareSpec'`, `'Meta::V1::LabelSelector'`, `'Core::V1::PodTemplateSpec'`); anything else as `'+Full'`.

- [ ] **Step 1: Write the failing test** -- `t/76_emitter_overlay.t`: render the `t/data/crd-knob.yaml` v1 root with `base => 'TestOv::V1'` and an overlay `{ with => ['IO::K8s::Role::Namespaced', 'IO::K8s::Role::SpecBuilder'], extra => ["sub _format { 'x' }"], names => { 'Spec' => 'KnobSpec', 'Spec::Limit' => 'RateLimit' } }`; assert the root file has the two `with` roles on one `with` line in that order, the `extra` line follows it, `RateLimit.pm` exists, `k8s limit => '+TestOv::V1::RateLimit';` (TestOv is not a known prefix, so `+` form), and that a class under a known prefix renders short: build a small schema whose `spec` has a field exactly shaped like `Meta::V1::LabelSelector` (reuse_core on) and assert the line reads `k8s selector => 'Meta::V1::LabelSelector';`; eval-compile every rendered file and round-trip a document.
- [ ] **Step 2: Run it to verify it fails.**
- [ ] **Step 3: Implement** (`%_class_prefix` additions + `class_prefixes`; emitter `overlay` handling; `_class_ref` via `class_prefixes` sorted longest-first, replacing the hand-kept `@SHORT_PREFIXES`; `names` lookup by `IO::K8s::AutoGen::class_path`).
- [ ] **Step 4: `prove -l t/76_emitter_overlay.t t/74_crd_emitter.t t/35_expand_class.t t/52_expand_class_shadow_window.t`** (the prefix map change touches `_expand_class`; a provider prefix must not shadow anything: `expand_class('Cilium::V2::CiliumNetworkPolicy')` must give `IO::K8s::Cilium::V2::CiliumNetworkPolicy`).
- [ ] **Step 5: `prove -lr t/`; commit** `Emitter overlay (roles, extra lines, Go names by path) and short provider class names`.

---

### Task A3: `crd-drift-check.pl --render / --render-dir / --check / --overlay`; named spec classes

**Lane:** `io-k8s-worker`.

**Files:**
- Modify: `maint/crd-drift-check.pl`

**Interfaces:**
- `--render` / `--render-dir DIR`: like `--suggest`/`--suggest-dir` but for EVERY served GVK of the provider (not only reported gaps), always through the overlay `maint/crd-render/<Provider>.yaml` when present (`--overlay FILE` overrides), `reuse_core` on, base `IO::K8s::<Provider>::<Version>`.
- `--check`: render every GVK to memory and compare each rendered file to the checked-in `lib/IO/K8s/<Provider>/<Version>/<File>.pm`; report per file `MATCH`, `DIFFERS` (with a unified diff, first 40 lines), `MISSING IN LIB`, `NOT RENDERED` (a file under the provider directory the render does not produce -- back-compat tracks kept on purpose are listed in the exceptions file under a new `ignore_unrendered` list); exit status 1 when anything differs.
- `shipped_spec_fields`: a spec that is `is_object` with a class under `IO::K8s::<Provider>::` counts as modeled; its fields are that class's registry keys.

- [ ] **Step 1: implement** (extend `parse_args`/`usage`; factor the suggest rendering into `render_gvk($opt, $provider, $u, $overlay)` used by both `--suggest` and `--render`; `--check` uses `Text::Diff`? not a dependency -- print both sides' differing line numbers with a small hand-rolled LCS-free "first differing line and context" report instead, sufficient for the loop).
- [ ] **Step 2: verify offline** with the Traefik cache: `--render-dir <scratch>` writes files for all 10 Kinds; `--check` against the current (opaque) `lib/` reports `DIFFERS` for the 10 roots and `MISSING IN LIB` for every nested class; `--suggest` still works; `prove -lr t/` green.
- [ ] **Step 3: commit** `crd-drift-check: --render, --check and overlay support; named spec classes count as modeled`.

---

## Phase B -- one task per provider

Each provider task follows the same recipe; the differences are listed after it. Run them one at a time; the implementer is a fresh `io-k8s-worker` on sonnet each time.

### Task B-<Provider> (recipe)

**Files:**
- Create: `maint/crd-render/<Provider>.yaml`
- Create/replace: `lib/IO/K8s/<Provider>/<Version>/*.pm`
- Modify: `lib/IO/K8s/<Provider>.pm` (resource_map entries for new tracks, POD counts), `maint/crd-drift-exceptions.yaml` (remove entries the render now satisfies; add `ignore_unrendered` for kept back-compat classes), `Changes`, the provider's test `t/NN_<provider>.t`
- Test: `t/NN_<provider>.t` gains a "full depth round-trip" subtest per Kind: a realistic manifest (written by the agent from the upstream schema's documentation) inflates into typed nested objects and `TO_JSON` reproduces it.

- [ ] **Step 1: Names.** Fetch the upstream Go types at the pinned `upstream_version` (URLs below), and for every nested class the render produces (`--render-dir <scratch>` first, no overlay) write the Go type name into the overlay's `names` map keyed by logical path. Shared types get the same name at every path. Where the Go name is the same as the emitter's default, no entry is needed.
- [ ] **Step 2: Roles and extra lines.** Copy the existing root class's `with` roles and any `sub _*_format { ... }` into the overlay's `with` / `extra` for that Kind.
- [ ] **Step 3: Render** with the overlay into the scratchpad; `perl -c -Ilib -I<dir>` every file; read the roots and a sample of nested classes; fix names; repeat until the file set is right.
- [ ] **Step 4: Copy** the rendered files into `lib/IO/K8s/<Provider>/<Version>/`, replacing the opaque roots; delete nothing that the exceptions file protects.
- [ ] **Step 5: Wire.** `resource_map` for any new track; POD counts in the provider module; exceptions file cleanup.
- [ ] **Step 6: Verify.** `perl maint/crd-drift-check.pl --provider <Provider>` reports 0 MISSING KIND, 0 MISSING FIELD, 0 OPAQUE SPEC; `--check` reports MATCH for every file; `prove -l t/NN_<provider>.t t/16_role_netpol.t t/17_role_routable.t t/18_role_certmanaged.t t/19_role_helm.t t/69_builder_roles_on_structs.t t/02_compile_all.t t/25_real_world.t t/26_build_verify.t`; then `prove -lr t/` and `dzil test`.
- [ ] **Step 7: Changes bullet** (`<Provider> modeled to full depth (D5, k95): N classes across M Kinds, Go type names, embedded core types referenced; the builder roles unchanged`), commit.

**Provider specifics:**

- **Traefik** (`v3.7.12`): Go types in `pkg/provider/kubernetes/crd/traefikio/v1alpha1/*.go` and `pkg/config/dynamic/*.go` (github.com/traefik/traefik). Roles: `MiddlewareBuilder` on Middleware, `Routable` (`_route_format 'traefik'`) on IngressRoute, `Loadbalanced` on TraefikService. ~140 classes.
- **cert-manager** (`v1.21.1`): `pkg/apis/certmanager/v1/types_*.go`, `pkg/apis/acme/v1/types_*.go`, `pkg/apis/meta/v1/types.go` (github.com/cert-manager/cert-manager). Roles: `CertManaged` on Certificate, Issuer, ClusterIssuer. The inlined PodTemplate must come out as `Core::V1::PodTemplateSpec` (reuse_core) -- if it does not (cert-manager trims fields), name it after cert-manager's own `ACMEChallengeSolverHTTP01IngressPodTemplate` etc. ~200 classes after reuse.
- **Cilium** (`v1.20.1`): `pkg/k8s/apis/cilium.io/v2/*.go`, `v2alpha1/*.go`, `pkg/policy/api/*.go` (the `Rule`, `EndpointSelector`, `IngressRule`, `EgressRule`, `PortRule` family) (github.com/cilium/cilium). Roles: `NetworkPolicy` (`_netpol_format 'cilium'`) on CiliumNetworkPolicy and CiliumClusterwideNetworkPolicy. Shared `api.Rule` across both policy Kinds and across v2/v2alpha1 -> one class per version directory. ~400 classes after reuse; the largest task -- split into two commits (v2, then v2alpha1) inside the one task.
- **Gateway API** (`v1.6.1`): `apis/v1/*.go`, `apis/v1beta1`, `apis/v1alpha2`, `apis/v1alpha3` (sigs.k8s.io/gateway-api). Roles: `Routable` (`_route_format 'gateway'`) on HTTPRoute. Plus D7: classes and resource_map keys for the served older tracks (qualified keys only), and the eight `ignore_missing_kinds` exceptions removed. ~200 classes.
- **AgentSandbox** (`v1.0.0`): `api/v1beta1/*.go`, `api/v1alpha1/*.go` if still in the repo (kubernetes-sigs/agent-sandbox). `podTemplate` -> `Core::V1::PodTemplateSpec`, `volumeClaimTemplates` -> `['Core::V1::PersistentVolumeClaim']` if the shape matches. The existing inline-struct roots are replaced by rendered files; the v1alpha1 back-compat classes stay (their manifest is no longer upstream: render them from the cached v0.5.4 manifest if present, else keep the inline structs and list them under `ignore_unrendered`).
- **K3s** (`v1.36.4+k3s1`): schemaless CRDs; model by hand from `pkg/apis/helm.cattle.io/v1/types.go` (github.com/k3s-io/helm-controller) and `pkg/apis/k3s.cattle.io/v1/types.go` (github.com/k3s-io/k3s): HelmChart, HelmChartConfig, Addon, ETCDSnapshotFile. Write the classes in the emitter's layout by hand (no overlay, no `--check`); `HelmManaged` on HelmChart. Small.

---

## Self-review

- **Spec coverage:** D5 full depth, one file per structure, hand-checked-in -> Phase B + the reproducibility decision; embedded core types referenced -> A1; D6 Go names -> overlay `names` + provider URLs; D7 served tracks + exceptions -> B-GatewayAPI; drift-check Tier 3 live -> A3 + each provider's Step 6; D8 builder roles hand-maintained -> overlay `with`/`extra`, tests kept.
- **Placeholder scan:** A1 carries its code; A2/A3 give exact interfaces and verification but not full code -- their implementers read the step-3 emitter/drift-check code they extend; the reviewer holds them to the interfaces above. Phase B is a recipe by design: the deliverable is data (overlay + rendered files), not new code.
- **Type consistency:** `reuse_core` option name in A1 (AutoGen, CRD, add_crd) and A3 (`--render` uses it); overlay keys `base`, `kinds`, `with`, `extra`, `names` in A2 and A3 and the recipe; `class_path` (step 3) is what `names` keys match.
