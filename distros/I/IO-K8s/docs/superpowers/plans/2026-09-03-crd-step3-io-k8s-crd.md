# CRD Step 3: `IO::K8s::CRD` -- `add_crd`, the Source Emitter and `--suggest` -- Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Turn a CustomResourceDefinition manifest into IO::K8s classes -- at runtime through `$k8s->add_crd(...)`, and as checked-in Perl source through an emitter -- with every nested object typed, so that a CRD's `spec` is modeled below the top level; and let `maint/crd-drift-check.pl --suggest` print that source for the gaps it reports.

**Architecture:** Three pieces. (1) `IO::K8s::AutoGen` starts generating a nested class for every inline `type: object` that carries `properties` (and for array items / map values shaped that way), named after its place in the parent -- the mapping every CRD schema needs because CRD schemas inline everything. (2) `IO::K8s::CRD` loads a manifest (object, hashref, YAML/JSON text, path, or a list of those), picks the served versions, and generates one Kind class per version through AutoGen; `IO::K8s->add_crd` registers them in the instance's resource map (domain-qualified keys for every version, the short name on the storage version). (3) `IO::K8s::CRD::Emitter` renders any generated class -- and its nested classes -- as house-style Perl source straight from the attribute registry (field order, types, `required`, options, descriptions as `=attr` POD), with a name map for the Go type names D6 asks for; the drift-check's `--suggest` is a thin CLI over it.

**Tech Stack:** Perl 5.10+, Moo, Type::Tiny, YAML::PP, Data::Dumper (core), Test::More, Test::Exception. `prove -lr t/` (the `-r` is required).

**Spec:** `docs/superpowers/specs/2026-09-03-crd-design.md`, decision D10 (with D5/D6 for naming and the step-4 hand-off). Ticket k94. Steps 1 and 2 are on master.

## Decisions this plan takes inside D10

- **Nested inline objects become classes everywhere AutoGen runs** (cluster `/openapi/v2` and CRD manifests alike), not only in the CRD path. One mapping, one behaviour. Compatibility: a Moo object is a blessed hash keyed by attribute name, so the hash-style access existing callers use on a formerly opaque spec (`$obj->spec->{domain}`, `t/04_autogen.t`; `Kubernetes::REST` `t/09_crd_autogen.t`) keeps working for top-level keys; only sanitized keys (`$ref` -> `_ref`) differ, and nothing shipped relies on those. `additionalProperties`-only objects (maps) and property-less objects stay opaque exactly as k55 settled.
- **Runtime class names are path-derived**: `<KindClass>::<Prop>` for an object property, `<KindClass>::<Prop>Item` for array items, `<KindClass>::<Prop>Value` for map values, `<Prop>` being the sanitized, ucfirst'd JSON key. The Go type names of D6 are the emitter's business (`names` map); the runtime never needs them.
- **`required` lists are recorded, not enforced**, on every generated class (`required => 'schema'`, the step-2 review's ruling): a cluster hands back `status: {}` for a fresh object whatever the status schema requires, and defaulted fields arrive absent.
- **`add_crd` registers through `add()`**: qualified `"$group/$version/$Kind"` keys for every served version, the bare `Kind` for the storage version, first-wins on a short-name collision (a provider registered earlier keeps the short name -- D13's order). Returns `{ $Kind => { $api_version => $class, ..., storage => $api_version } }`.
- **Descriptions go to POD, not to the `description` option**, in emitted source: the house format documents every field in an `=attr` block, and doubling the text into the DSL line would make the 1700 step-4 classes unreadable. `to_crd` (step 5) will read descriptions from the option for user-authored classes; feeding it from POD stays deferred as the spec says.
- **Emitted source records `required` as `required => 'schema'`**, never as the enforcing marker: provider classes must inflate whatever the cluster returns (`status: {}` on a fresh object), exactly like the generated classes they are rendered from; `to_crd` still sees the field as required.
- **The emitter never writes into `lib/`**: it returns `{ relative_path => source }`; `--suggest` prints, `--suggest-dir DIR` writes to a directory that must not be inside `lib/`.

## Global Constraints

- Every module keeps `our $VERSION = '1.108';` (new modules too).
- No new CPAN dependencies (`Data::Dumper` is core; `YAML::PP`, `Moo`, `Type::Tiny` are declared).
- `prove -lr t/` green with nothing skipped after every task; `t/04_autogen.t`, `t/45_autogen_dispatch.t`, `t/57_autogen_k55_60.t`, `t/71_autogen_field_options.t` stay green (a test that asserted the opaque shape of an inline object is updated with its claim stated first).
- Comments and POD in English in the house voice; commit trailer:
  ```
  Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>
  Claude-Session: https://claude.ai/code/session_01MysDYqMAm8iUAbiTm1XhYi
  ```
- Delegation lanes: `lib/`, `maint/` and the tests go to `io-k8s-worker`; POD/README to `io-k8s-doc-writer`.

## File structure

| File | Responsibility after this plan |
|------|-------------------------------|
| `lib/IO/K8s/AutoGen.pm` | nested-class generation for inline objects (`_nested_class`), array items and map values |
| `lib/IO/K8s/CRD.pm` | `load` (input normalization), `served_versions`, `generate` (one class per served version via AutoGen) |
| `lib/IO/K8s.pm` | `add_crd` |
| `lib/IO/K8s/CRD/Emitter.pm` | registry -> Perl source, name map, house template |
| `maint/crd-drift-check.pl` | `--suggest`, `--suggest-dir`, `--names`; `parse_crds` keeps the CRD document per GVK |
| `t/data/crd-knob.yaml` | fixture: one CRD, two served versions, nested objects, arrays of objects, options |
| `t/72_autogen_nested_objects.t`, `t/73_add_crd.t`, `t/74_crd_emitter.t` | tests |
| POD, README, `Changes` | documentation |

---

### Task 1: AutoGen types inline nested objects

**Lane:** `io-k8s-worker`.

**Files:**
- Modify: `lib/IO/K8s/AutoGen.pm` (`_schema_to_type_spec` object and array branches; new `_nested_class`, `_class_segment`)
- Test: `t/72_autogen_nested_objects.t`

**Interfaces:**
- Produces: for a property whose schema is `type: object` with a non-empty `properties`, `_schema_to_type_spec` returns `"+<Parent>::<Prop>"` and the class exists; for `items` shaped that way `[ "+<Parent>::<Prop>Item" ]`; for `additionalProperties` shaped that way `{ "+<Parent>::<Prop>Value" => 1 }`. Nested classes are plain `IO::K8s::Resource` classes (no GVK), generated in the parent's namespace, cached in `%_generated`.
- Later tasks rely on: `IO::K8s::AutoGen::_class_segment($json_key)` (sanitized, ucfirst) and on the naming rule above.

- [ ] **Step 1: Write the failing test**

Create `t/72_autogen_nested_objects.t`:

```perl
#!/usr/bin/env perl
# D10: an inline `type: object` with properties becomes a nested class named
# after its place in the parent; array items and map values shaped that way
# too. Property-less objects and additionalProperties-only maps stay opaque
# (k55). Hash-style access on the result keeps working (blessed hash).
use strict;
use warnings;
use Test::More;
use Test::Exception;

use IO::K8s::AutoGen;
use IO::K8s;

IO::K8s::AutoGen::clear_cache();

my $schema = {
    type => 'object',
    'x-kubernetes-group-version-kind' => [ { group => 'nest.example.com', version => 'v1', kind => 'Widget' } ],
    properties => {
        apiVersion => { type => 'string' },
        kind       => { type => 'string' },
        metadata   => { type => 'object' },
        spec => {
            type => 'object',
            required => [ 'name' ],
            properties => {
                name  => { type => 'string' },
                limit => {
                    type => 'object',
                    properties => {
                        average => { type => 'integer', minimum => 0 },
                        burst   => { type => 'integer' },
                    },
                },
                routes => {
                    type  => 'array',
                    items => {
                        type => 'object',
                        properties => {
                            match    => { type => 'string' },
                            priority => { type => 'integer' },
                        },
                    },
                },
                weights => {
                    type => 'object',
                    additionalProperties => {
                        type => 'object',
                        properties => { value => { type => 'integer' } },
                    },
                },
                labels  => { type => 'object', additionalProperties => { type => 'string' } },
                blob    => { type => 'object' },
                'x-extra' => { type => 'object', properties => { on => { type => 'boolean' } } },
            },
        },
    },
};

my $ns = 'IO::K8s::_AUTOGEN_nested';
my $class = IO::K8s::AutoGen::get_or_generate('com.example.nest.v1.Widget', $schema, {}, $ns,
    api_version => 'nest.example.com/v1', kind => 'Widget', resource_plural => 'widgets', is_namespaced => 1);

subtest 'nested classes exist with path-derived names' => sub {
    my $spec = $class->_k8s_attr_info->{spec};
    ok($spec->{is_object}, 'spec is an object field');
    is($spec->{class}, "$class\::Spec", 'spec class named <Kind>::Spec');
    my $sinfo = $spec->{class}->_k8s_attr_info;
    is($sinfo->{limit}{class}, "$class\::Spec::Limit", 'object property -> <Parent>::<Prop>');
    ok($sinfo->{routes}{is_array_of_objects}, 'array of objects');
    is($sinfo->{routes}{class}, "$class\::Spec::RoutesItem", 'array items -> <Parent>::<Prop>Item');
    ok($sinfo->{weights}{is_hash_of_objects}, 'map of objects');
    is($sinfo->{weights}{class}, "$class\::Spec::WeightsValue", 'map values -> <Parent>::<Prop>Value');
    ok($sinfo->{labels}{is_hash_of_str}, 'additionalProperties: string stays an opaque map (k55)');
    ok($sinfo->{blob}{is_hash_of_str}, 'property-less object stays opaque');
    is($sinfo->{x_extra}{class}, "$class\::Spec::X_extra", 'sanitized key names the nested class');
    is($sinfo->{name}{required}, 1, 'required list applies inside the nested class');
    is($sinfo->{limit}{class}->_k8s_attr_info->{average}{options}{minimum}, 0, 'options apply below the top level');
};

subtest 'inflate builds the nested objects and round-trips' => sub {
    my $k8s = IO::K8s->new;
    $k8s->add({ Widget => "+$class" });
    my $doc = {
        apiVersion => 'nest.example.com/v1', kind => 'Widget',
        metadata   => { name => 'w' },
        spec => {
            name    => 'n',
            limit   => { average => 10, burst => 20 },
            routes  => [ { match => 'a', priority => 1 }, { match => 'b' } ],
            weights => { x => { value => 5 } },
            labels  => { app => 'web' },
            blob    => { anything => [ 1, 2 ] },
            'x-extra' => { on => JSON::PP::true() },
        },
    };
    require JSON::PP;
    my $obj = $k8s->inflate($doc);
    isa_ok($obj->spec, "$class\::Spec");
    isa_ok($obj->spec->limit, "$class\::Spec::Limit");
    isa_ok($obj->spec->routes->[1], "$class\::Spec::RoutesItem");
    isa_ok($obj->spec->weights->{x}, "$class\::Spec::WeightsValue");
    is($obj->spec->{name}, 'n', 'hash-style access on the blessed hash still works');
    my $out = $obj->TO_JSON;
    is_deeply($out->{spec}{limit}, { average => 10, burst => 20 }, 'nested object round-trips');
    is_deeply($out->{spec}{routes}[0], { match => 'a', priority => 1 }, 'array item round-trips');
    is_deeply($out->{spec}{weights}, { x => { value => 5 } }, 'map value round-trips');
    is_deeply($out->{spec}{blob}, { anything => [ 1, 2 ] }, 'opaque object round-trips');
    ok($out->{spec}{'x-extra'}{on}, 'sanitized nested key round-trips under its JSON name');
    throws_ok { $k8s->inflate({ %$doc, spec => { name => 'n', limit => { average => -1 } } }) } qr/below the minimum 0/,
        'constraints are enforced inside nested classes';
    throws_ok { IO::K8s->new(strict => 1)->inflate({ %$doc, spec => { name => 'n', limit => { typo => 1 } } }) }
        qr/Unknown field 'typo' for \Q$class\E::Spec::Limit/, 'strict reaches nested classes';
};

subtest 'nested classes are cached per parent, not regenerated' => sub {
    my $again = IO::K8s::AutoGen::get_or_generate('com.example.nest.v1.Widget', $schema, {}, $ns,
        api_version => 'nest.example.com/v1', kind => 'Widget', resource_plural => 'widgets', is_namespaced => 1);
    is($again, $class, 'same Kind class');
    my @nested = grep { /^\Q$class\E::/ } IO::K8s::AutoGen::generated_classes();
    is(scalar @nested, 5, 'Spec, Limit, RoutesItem, WeightsValue, X_extra -- each once');
};

done_testing;
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `prove -l t/72_autogen_nested_objects.t`
Expected: FAIL -- `spec` is registered as an opaque hash (`is_object` false).

- [ ] **Step 3: Implement in `lib/IO/K8s/AutoGen.pm`**

Add after `_croak_unresolved_ref`:

```perl
# The class segment for a nested class: the JSON key, sanitized the way the
# DSL sanitizes attribute names, then ucfirst'd. `x-extra` -> `X_extra`,
# `$ref` -> `_ref`.
sub _class_segment {
    my ($json_key) = @_;
    return ucfirst(IO::K8s::Resource::_sanitize_attr_name($json_key));
}

# An inline `type: object` with its own properties becomes a nested class
# named after its place in the parent -- <Parent>::<Prop>, plus an Item /
# Value suffix for array items and map values -- generated in the parent's
# namespace and cached like every other generated class. Before 1.108 such
# an object was an opaque hash, so a CRD's spec, which every CRD schema
# inlines, carried no typing below the top level (k94). Hash-style access on
# the result keeps working: a Moo object is a blessed hash keyed by
# attribute name. Property-less objects and additionalProperties-only maps
# are not touched here; they stay opaque (k55).
sub _nested_class {
    my ($parent_class, $field_name, $suffix, $schema, $all_defs, $namespace) = @_;
    my $class = $parent_class . '::' . _class_segment($field_name) . ($suffix // '');
    unless ($_generated{$class}) {
        my $def_name = class_to_def($parent_class) . '.' . _class_segment($field_name) . ($suffix // '');
        _generate_class($class, $def_name, $schema, $all_defs, $namespace);
    }
    return $class;
}

sub _has_properties {
    my ($schema) = @_;
    return ref $schema eq 'HASH'
        && ($schema->{type} // '') eq 'object'
        && ref $schema->{properties} eq 'HASH'
        && %{ $schema->{properties} };
}
```

In `_schema_to_type_spec`, in the `array` branch, before `my $item_type = $items->{type} // 'string';` insert:

```perl
        if (_has_properties($items)) {
            return [ '+' . _nested_class($class, $field_name, 'Item', $items, $all_defs, $namespace) ];
        }
```

In the `object` branch, at its very top (before the `additionalProperties` handling) insert:

```perl
        if (_has_properties($schema)) {
            return '+' . _nested_class($class, $field_name, undef, $schema, $all_defs, $namespace);
        }
```

and inside the `additionalProperties` hashref handling, before `return { Str => 1 };  # Hash of strings`, insert:

```perl
            if (_has_properties($addl)) {
                return { '+' . _nested_class($class, $field_name, 'Value', $addl, $all_defs, $namespace) => 1 };
            }
```

`class_to_def` already strips the `IO::K8s::_AUTOGEN...` prefix; for a custom namespace the def name is only used in diagnostics, so a longer name there is harmless.

Also in this task (carried over from the step-2 final re-review): in `_field_options` the Bool-default normalization calls `_normalize_bool` on the raw value for every Bool kind, including an array of booleans, where a `default: [true, false]` would die on the arrayref and kill class generation. Guard it: for `[Bool]` normalize each element, and drop the default when any element is not a boolean; keep the scalar Bool path as it is. One t/72 subtest with `flags => { type => 'array', items => { type => 'boolean' }, default => [ JSON::PP::true(), JSON::PP::false() ] }` asserting generation lives and the recorded default is `[1, 0]`.

Note for the implementer: `_generate_class` marks `$_generated{$class}` before its property loop, so a nested class generated from inside the parent's loop is not re-entered; the nested class has no GVK, so it gets no `Role::APIObject`. `_scalar_kind` from step 2 already returns undef for `'+Class'`, `['+Class']` and `{ '+Class' => 1 }`, so no value option is passed for these fields; `description`, `nullable`, `preserve_unknown` and `required` still are.

- [ ] **Step 4: Run the new test and the existing AutoGen tests**

Run: `prove -l t/72_autogen_nested_objects.t t/04_autogen.t t/45_autogen_dispatch.t t/57_autogen_k55_60.t t/71_autogen_field_options.t`
Expected: PASS. If a subtest in `t/04` or `t/57` asserted that an inline object *with properties* is a plain hash (`is(ref $obj->spec, 'HASH')`-style), it documented the old shape: state its claim in the report and change it to the object assertion; keep every hash-style value access as it is (it still works).

- [ ] **Step 5: Run the full suite**

Run: `prove -lr t/`
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/IO/K8s/AutoGen.pm t/72_autogen_nested_objects.t t/04_autogen.t t/57_autogen_k55_60.t
git commit -m "AutoGen: generate nested classes for inline objects, array items and map values with properties (D10, k94)"
```

---

### Task 2: `IO::K8s::CRD` and `IO::K8s->add_crd`

**Lane:** `io-k8s-worker`.

**Files:**
- Create: `lib/IO/K8s/CRD.pm`
- Modify: `lib/IO/K8s.pm` (new `add_crd` after `add`)
- Create: `t/data/crd-knob.yaml`
- Test: `t/73_add_crd.t`

**Interfaces:**
- Produces: `IO::K8s::CRD->load($input)` -> arrayref of plain CRD hashrefs (`$input`: a `CustomResourceDefinition` object, a hashref, YAML/JSON text, a file path, or an arrayref of those); `IO::K8s::CRD->served_versions($crd)` -> arrayref of `{ name, api_version, storage, schema }`; `IO::K8s::CRD->generate($crd, $namespace)` -> `{ $api_version => $class, ..., storage => $api_version }`; `$k8s->add_crd(@inputs)` -> `{ $Kind => { $api_version => $class, ..., storage => $api_version } }` and registers the classes in `$k8s->resource_map`.
- Task 3 relies on `generate` and on the class layout Task 1 produces.

- [ ] **Step 1: Write the fixture and the failing test**

Create `t/data/crd-knob.yaml`:

```yaml
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  name: knobs.opts.example.com
spec:
  group: opts.example.com
  scope: Namespaced
  names:
    kind: Knob
    plural: knobs
    singular: knob
    shortNames: [kn]
  versions:
    - name: v1alpha1
      served: true
      storage: false
      schema:
        openAPIV3Schema:
          type: object
          properties:
            spec:
              type: object
              properties:
                mode:
                  type: string
    - name: v1
      served: true
      storage: true
      subresources:
        status: {}
      schema:
        openAPIV3Schema:
          type: object
          required: [spec]
          properties:
            spec:
              type: object
              required: [mode]
              properties:
                mode:
                  type: string
                  description: Operating mode.
                  enum: [fast, safe]
                  default: safe
                replicas:
                  type: integer
                  minimum: 0
                  maximum: 5
                limit:
                  type: object
                  description: Rate limit applied to the knob.
                  properties:
                    average:
                      type: integer
                      minimum: 0
                    period:
                      type: string
                      pattern: '^[0-9]+[smh]$'
                routes:
                  type: array
                  items:
                    type: object
                    required: [match]
                    properties:
                      match:
                        type: string
                      weight:
                        type: integer
                size:
                  x-kubernetes-int-or-string: true
                extra:
                  type: object
                  x-kubernetes-preserve-unknown-fields: true
            status:
              type: object
              properties:
                ready:
                  type: boolean
    - name: v0
      served: false
      storage: false
      schema:
        openAPIV3Schema:
          type: object
```

Create `t/73_add_crd.t`:

```perl
#!/usr/bin/env perl
# D10: IO::K8s::CRD turns a CustomResourceDefinition manifest into one class
# per served version; IO::K8s->add_crd registers them (qualified keys for
# every version, the short name on the storage version).
use strict;
use warnings;
use Test::More;
use Test::Exception;
use FindBin;

use IO::K8s;
use IO::K8s::CRD;

my $fixture = "$FindBin::Bin/data/crd-knob.yaml";

subtest 'load accepts every input form' => sub {
    my $from_path = IO::K8s::CRD->load($fixture);
    is(scalar @$from_path, 1, 'one CRD from a path');
    is($from_path->[0]{spec}{names}{kind}, 'Knob', 'parsed');

    open my $fh, '<', $fixture or die $!;
    my $text = do { local $/; <$fh> };
    is_deeply(IO::K8s::CRD->load($text), $from_path, 'same from YAML text');
    is_deeply(IO::K8s::CRD->load($from_path->[0]), $from_path, 'same from a hashref');

    my $k8s = IO::K8s->new;
    my $obj = $k8s->inflate($from_path->[0]);
    isa_ok($obj, 'IO::K8s::ApiextensionsApiserver::Pkg::Apis::Apiextensions::V1::CustomResourceDefinition');
    my $from_obj = IO::K8s::CRD->load($obj);
    is($from_obj->[0]{spec}{versions}[1]{schema}{openAPIV3Schema}{properties}{spec}{properties}{mode}{enum}[0], 'fast',
        'from an object, through TO_JSON');
    is(scalar @{ IO::K8s::CRD->load([ $fixture, $from_path->[0] ]) }, 2, 'an arrayref of inputs concatenates');

    throws_ok { IO::K8s::CRD->load("apiVersion: v1\nkind: Pod\nmetadata:\n  name: x\n") }
        qr/document is a 'Pod', not a CustomResourceDefinition/, 'wrong kind dies';
    throws_ok { IO::K8s::CRD->load({ kind => 'CustomResourceDefinition', spec => { group => 'g' } }) }
        qr/without spec\.group \/ spec\.names\.kind \/ spec\.versions/, 'incomplete CRD dies';
    throws_ok { IO::K8s::CRD->load(undef) } qr/needs a CustomResourceDefinition/, 'undef dies';
};

subtest 'served_versions skips unserved and marks storage' => sub {
    my ($crd) = @{ IO::K8s::CRD->load($fixture) };
    my $v = IO::K8s::CRD->served_versions($crd);
    is_deeply([ map { $_->{api_version} } @$v ], [ 'opts.example.com/v1alpha1', 'opts.example.com/v1' ], 'v0 is not served');
    is_deeply([ map { $_->{storage} } @$v ], [ 0, 1 ], 'storage flag');
    is($v->[1]{name}, 'v1', 'name');
    ok($v->[1]{schema}{properties}{spec}, 'schema carried');
};

subtest 'add_crd registers every served version and the storage short name' => sub {
    my $k8s = IO::K8s->new;
    my $reg = $k8s->add_crd($fixture);
    is_deeply([ sort keys %$reg ], [ 'Knob' ], 'one Kind');
    is($reg->{Knob}{storage}, 'opts.example.com/v1', 'storage version');
    my $v1  = $reg->{Knob}{'opts.example.com/v1'};
    my $v1a = $reg->{Knob}{'opts.example.com/v1alpha1'};
    like($v1,  qr/^IO::K8s::_AUTOGEN_[0-9a-f]+::opts::example::com::v1::Knob$/, 'v1 class in the instance namespace');
    like($v1a, qr/::v1alpha1::Knob$/, 'v1alpha1 class');
    is($k8s->expand_class('Knob'), $v1, 'short name -> storage version');
    is($k8s->expand_class('Knob', 'opts.example.com/v1alpha1'), $v1a, 'qualified lookup -> other version');
    is($k8s->expand_class('opts.example.com/v1/Knob'), $v1, 'domain-qualified string');
    is($v1->api_version, 'opts.example.com/v1', 'api_version');
    is($v1->kind, 'Knob', 'kind');
    is($v1->resource_plural, 'knobs', 'resource_plural from names.plural');
    ok($v1->does('IO::K8s::Role::Namespaced'), 'Namespaced scope');
    ok($v1->does('IO::K8s::Role::APIObject'), 'top-level object');
};

subtest 'objects from the registered classes are typed to full depth' => sub {
    my $k8s = IO::K8s->new;
    $k8s->add_crd($fixture);
    my $knob = $k8s->new_object('Knob',
        metadata => { name => 'k', namespace => 'd' },
        spec => {
            mode => 'fast', replicas => 2,
            limit => { average => 10, period => '5s' },
            routes => [ { match => 'a', weight => 1 } ],
            size => '10Gi',
            extra => { anything => 1 },
        },
    );
    isa_ok($knob->spec->limit, ref($knob) . '::Spec::Limit');
    isa_ok($knob->spec->routes->[0], ref($knob) . '::Spec::RoutesItem');
    is($knob->spec->size, '10Gi', 'x-kubernetes-int-or-string -> IntOrStr');
    is_deeply($knob->TO_JSON->{spec}{extra}, { anything => 1 }, 'preserve-unknown object is opaque and round-trips');
    throws_ok { $k8s->new_object('Knob', metadata => { name => 'k' }, spec => { mode => 'slow' }) } qr/not one of: fast, safe/, 'enum';
    throws_ok { $k8s->new_object('Knob', metadata => { name => 'k' }, spec => { mode => 'fast', replicas => 9 }) } qr/above the maximum 5/, 'range';
    throws_ok { $k8s->new_object('Knob', metadata => { name => 'k' }, spec => { mode => 'fast', limit => { period => 'x' } }) } qr/does not match the pattern/, 'pattern below the top level';
    # required lists are recorded for the schema (required => 'schema', step 2's
    # ruling), never enforced on a generated class: a cluster returns
    # status: {} for a fresh object no matter what the status schema requires.
    is(ref($knob)->_k8s_attr_info->{spec}{required}, 1, 'top-level required recorded');
    is($knob->spec->_k8s_attr_info->{mode}{required}, 1, 'nested required recorded');
    lives_ok { $k8s->new_object('Knob', metadata => { name => 'k' }, spec => {}) } 'a missing required field does not fail construction';
    lives_ok { $k8s->inflate({ apiVersion => 'opts.example.com/v1', kind => 'Knob', metadata => { name => 'k' }, spec => { mode => 'fast' }, status => {} }) }
        'a cluster document with an empty status inflates';
    my $old = $k8s->new_object('Knob', { metadata => { name => 'o' }, spec => { mode => 'anything' } }, 'opts.example.com/v1alpha1');
    is($old->api_version, 'opts.example.com/v1alpha1', 'the other served version is its own class');
    is($old->TO_JSON->{spec}{mode}, 'anything', 'with its own, looser schema');
};

subtest 'a provider registered first keeps the short name' => sub {
    my $k8s = IO::K8s->new;
    $k8s->add({ Knob => '+IO::K8s::Api::Core::V1::Pod' });   # stands in for a provider class
    my $reg = $k8s->add_crd($fixture);
    is($k8s->expand_class('Knob'), 'IO::K8s::Api::Core::V1::Pod', 'first registration wins the short name');
    is($k8s->expand_class('opts.example.com/v1/Knob'), $reg->{Knob}{'opts.example.com/v1'}, 'the CRD class is reachable by its qualified key');
};

subtest 'two instances do not share generated classes' => sub {
    my $a = IO::K8s->new; my $b = IO::K8s->new;
    my $ra = $a->add_crd($fixture); my $rb = $b->add_crd($fixture);
    isnt($ra->{Knob}{'opts.example.com/v1'}, $rb->{Knob}{'opts.example.com/v1'}, 'different namespaces');
};

done_testing;
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `prove -l t/73_add_crd.t`
Expected: FAIL -- `Can't locate IO/K8s/CRD.pm`.

- [ ] **Step 3: Create `lib/IO/K8s/CRD.pm`**

```perl
package IO::K8s::CRD;
# ABSTRACT: Turn CustomResourceDefinition manifests into IO::K8s classes
our $VERSION = '1.108';
use v5.10;
use strict;
use warnings;
use Carp qw( croak );
use Scalar::Util qw( blessed );
use IO::K8s::AutoGen ();
use IO::K8s::Resource ();

=head1 SYNOPSIS

    use IO::K8s;
    my $k8s = IO::K8s->new;
    $k8s->add_crd('crds/knobs.yaml');          # a path, YAML/JSON text, a hashref,
                                               # a CustomResourceDefinition object,
                                               # or an arrayref of those
    my $knob = $k8s->new_object('Knob', ...);   # storage version
    my $old  = $k8s->new_object('opts.example.com/v1alpha1/Knob', ...);

    # The pieces, for callers that want them separately:
    my $crds     = IO::K8s::CRD->load($input);            # plain hashrefs
    my $versions = IO::K8s::CRD->served_versions($crds->[0]);
    my $classes  = IO::K8s::CRD->generate($crds->[0], 'My::Namespace');

=head1 DESCRIPTION

The manifest-to-class half of D10 in the CRD design: a
C<CustomResourceDefinition> is loaded from whatever form the caller has,
every B<served> version of it becomes one L<IO::K8s::AutoGen> class (with
nested classes for every object below C<spec>), and L<IO::K8s/add_crd>
registers them the way a provider's resource map is registered. Nothing
here writes files; L<IO::K8s::CRD::Emitter> renders the same classes as
source for the checked-in case.

=cut

=method load

    my $crds = IO::K8s::CRD->load($input);

Normalizes C<$input> to an arrayref of plain CRD hashrefs. Accepts a
C<CustomResourceDefinition> object (anything with C<TO_JSON>), a hashref,
YAML or JSON text (multi-document YAML yields several), a path to such a
file, or an arrayref of any of those. Dies on a document that is not a
C<CustomResourceDefinition> or lacks C<spec.group>, C<spec.names.kind> or
C<spec.versions>.

=cut

sub load {
    my ($class, $input) = @_;
    croak 'IO::K8s::CRD->load needs a CustomResourceDefinition object, a hashref, YAML/JSON text or a file path'
        unless defined $input;

    my @docs;
    if (ref $input eq 'ARRAY') {
        return [ map { @{ $class->load($_) } } @$input ];
    }
    elsif (blessed($input) && $input->can('TO_JSON')) {
        @docs = ($input->TO_JSON);
    }
    elsif (ref $input eq 'HASH') {
        @docs = ($input);
    }
    elsif (!ref $input) {
        my $text = $input;
        if ($input !~ /\n/ && -f $input) {
            open my $fh, '<:encoding(UTF-8)', $input
                or croak "IO::K8s::CRD->load: cannot open $input: $!";
            $text = do { local $/; <$fh> };
            close $fh;
        }
        require YAML::PP;
        my $yp = YAML::PP->new(boolean => 'JSON::PP');
        @docs = grep { ref $_ eq 'HASH' } $yp->load_string($text);
    }
    else {
        croak 'IO::K8s::CRD->load: unsupported input ' . ref($input);
    }

    for my $doc (@docs) {
        my $kind = $doc->{kind} // '';
        croak "IO::K8s::CRD->load: document is a '$kind', not a CustomResourceDefinition"
            unless $kind eq 'CustomResourceDefinition';
        croak 'IO::K8s::CRD->load: CustomResourceDefinition without spec.group / spec.names.kind / spec.versions'
            unless ref $doc->{spec} eq 'HASH'
                && defined $doc->{spec}{group}
                && ref $doc->{spec}{names} eq 'HASH' && defined $doc->{spec}{names}{kind}
                && ref $doc->{spec}{versions} eq 'ARRAY' && @{ $doc->{spec}{versions} };
    }
    return \@docs;
}

# served / storage arrive as JSON booleans, plain 0/1, or the strings a
# hand-written YAML may carry; the DSL's one boolean normalization decides.
sub _flag {
    my ($value) = @_;
    return 0 unless defined $value;
    my $bool = eval { IO::K8s::Resource::_normalize_bool($value) };
    return $bool ? 1 : 0;
}

=method served_versions

    my $versions = IO::K8s::CRD->served_versions($crd);

The served versions of one loaded CRD, in manifest order, each as
C<< { name, api_version, storage, schema } >> where C<schema> is the
version's C<openAPIV3Schema> (an empty C<type: object> when the manifest has
none). Dies when no version is served.

=cut

sub served_versions {
    my ($class, $crd) = @_;
    my $group = $crd->{spec}{group};
    my @out;
    for my $v (@{ $crd->{spec}{versions} }) {
        next unless _flag($v->{served});
        push @out, {
            name        => $v->{name},
            api_version => "$group/$v->{name}",
            storage     => _flag($v->{storage}),
            schema      => $v->{schema}{openAPIV3Schema} // { type => 'object' },
        };
    }
    croak "IO::K8s::CRD: no served version in the CRD for $crd->{spec}{names}{kind}" unless @out;
    return \@out;
}

=method generate

    my $classes = IO::K8s::CRD->generate($crd, $namespace);

Generates one L<IO::K8s::AutoGen> class per served version under
C<$namespace> and returns C<< { $api_version => $class, ..., storage =>
$api_version } >>. The storage version is the one the manifest marks; when
none is marked (an invalid manifest, but a common one in hand-written
fixtures) the last served version is used. Each class carries the CRD's
C<kind>, C<names.plural> and scope, and every object with C<properties>
below it is a nested class (see L<IO::K8s::AutoGen>).

=cut

sub generate {
    my ($class, $crd, $namespace) = @_;
    my $spec  = $crd->{spec};
    my $group = $spec->{group};
    my $kind  = $spec->{names}{kind};
    my $namespaced = ($spec->{scope} // 'Namespaced') eq 'Namespaced' ? 1 : 0;

    my %out;
    for my $v (@{ $class->served_versions($crd) }) {
        my $def_name = join '.', $group, $v->{name}, $kind;
        my $schema = {
            %{ $v->{schema} },
            'x-kubernetes-group-version-kind' => [ { group => $group, version => $v->{name}, kind => $kind } ],
        };
        $out{ $v->{api_version} } = IO::K8s::AutoGen::get_or_generate(
            $def_name, $schema, {}, $namespace,
            api_version     => $v->{api_version},
            kind            => $kind,
            resource_plural => $spec->{names}{plural},
            is_namespaced   => $namespaced,
        );
        $out{storage} = $v->{api_version} if $v->{storage} || !exists $out{storage};
    }
    return \%out;
}

1;
```

Note: the `$out{storage}` assignment picks the last served version as a fallback and lets a real storage flag override it -- both are covered by the fixture (v1 marked storage, listed second).

- [ ] **Step 4: Add `add_crd` to `lib/IO/K8s.pm`**

After `sub add { ... }`:

```perl
=method add_crd

    my $registered = $k8s->add_crd('crds/knobs.yaml', $crd_object, \%crd_hash, ...);

Loads each argument through L<IO::K8s::CRD/load>, generates one class per
served version in this instance's AutoGen namespace, and registers them:
every version under its domain-qualified key (C<group/version/Kind>), the
storage version under the bare Kind -- through L</add>, so a class already
holding the short name (a provider merged earlier) keeps it and the CRD's
class stays reachable by its qualified key. Returns
C<< { $Kind => { $api_version => $class, ..., storage => $api_version } } >>.

=cut

sub add_crd {
    my ($self, @inputs) = @_;
    require IO::K8s::CRD;
    my %registered;
    for my $input (@inputs) {
        for my $crd (@{ IO::K8s::CRD->load($input) }) {
            my $classes = IO::K8s::CRD->generate($crd, $self->_autogen_namespace);
            my $kind    = $crd->{spec}{names}{kind};
            my $storage = $classes->{storage};
            my %map = map { ("$_/$kind" => '+' . $classes->{$_}) } grep { $_ ne 'storage' } keys %$classes;
            $map{$kind} = '+' . $classes->{$storage};
            $self->add(\%map);
            $registered{$kind} = $classes;
        }
    }
    return \%registered;
}
```

- [ ] **Step 5: Run the test to verify it passes**

Run: `prove -l t/73_add_crd.t t/72_autogen_nested_objects.t`
Expected: PASS.

- [ ] **Step 6: Run the full suite**

Run: `prove -lr t/`
Expected: PASS.

- [ ] **Step 7: Commit**

```bash
git add lib/IO/K8s/CRD.pm lib/IO/K8s.pm t/data/crd-knob.yaml t/73_add_crd.t
git commit -m "Add IO::K8s::CRD and IO::K8s->add_crd: classes for every served version of a CRD manifest (D10, k94)"
```

---

### Task 3: `IO::K8s::CRD::Emitter` -- registry to source

**Lane:** `io-k8s-worker`.

**Files:**
- Create: `lib/IO/K8s/CRD/Emitter.pm`
- Test: `t/74_crd_emitter.t`

**Interfaces:**
- Consumes: generated classes from Task 2 (`IO::K8s::CRD->generate`), their registries (`_k8s_attr_info`, `_k8s_attributes`, `required`, `options`), `api_version`/`kind`/`resource_plural`/`Role::Namespaced`.
- Produces: `IO::K8s::CRD::Emitter->new(base => 'IO::K8s::Traefik::V1alpha1', names => { ... }, version => '1.108')`; `$emitter->render($root_class)` -> `{ 'IO/K8s/Traefik/V1alpha1/Middleware.pm' => $source, ... }` for the root and every nested class reachable from it; `$emitter->package_for($generated_class)`.
- Task 4 relies on `render` and `package_for`.

- [ ] **Step 1: Write the failing test**

Create `t/74_crd_emitter.t`:

```perl
#!/usr/bin/env perl
# D10: the emitter renders a generated class set as house-style Perl source
# from the registry. The rendered source must compile into working classes
# that round-trip the same document as the generated originals.
use strict;
use warnings;
use Test::More;
use Test::Exception;
use FindBin;

use IO::K8s;
use IO::K8s::CRD;
use IO::K8s::CRD::Emitter;

my ($crd) = @{ IO::K8s::CRD->load("$FindBin::Bin/data/crd-knob.yaml") };
my $classes = IO::K8s::CRD->generate($crd, 'IO::K8s::_AUTOGEN_emit');
my $root = $classes->{'opts.example.com/v1'};

my $emitter = IO::K8s::CRD::Emitter->new(
    base  => 'TestEmit::V1',
    names => { "$root\::Spec::Limit" => 'RateLimit' },
);
my $files = $emitter->render($root);

subtest 'one file per class, named from the base and the name map' => sub {
    is_deeply([ sort keys %$files ], [
        'TestEmit/V1/Knob.pm',
        'TestEmit/V1/KnobSpec.pm',
        'TestEmit/V1/KnobSpecRoutesItem.pm',
        'TestEmit/V1/KnobStatus.pm',
        'TestEmit/V1/RateLimit.pm',
    ], 'root, nested, and the renamed class');
    is($emitter->package_for("$root\::Spec::Limit"), 'TestEmit::V1::RateLimit', 'name map wins');
    is($emitter->package_for("$root\::Spec"), 'TestEmit::V1::KnobSpec', 'default: base + path joined');
};

subtest 'the root file is a house-style APIObject class' => sub {
    my $src = $files->{'TestEmit/V1/Knob.pm'};
    like($src, qr/^package TestEmit::V1::Knob;\n# ABSTRACT: /m, 'package + ABSTRACT');
    like($src, qr/^our \$VERSION = '1\.108';$/m, 'version line');
    like($src, qr/^use IO::K8s::APIObject\n    api_version     => 'opts\.example\.com\/v1',\n    resource_plural => 'knobs';$/m, 'APIObject import');
    like($src, qr/^with 'IO::K8s::Role::Namespaced';$/m, 'Namespaced');
    like($src, qr/^k8s spec\s+=> '\+TestEmit::V1::KnobSpec', \{ required => 'schema' \};$/m, 'required object field, renamed, recorded not enforced');
    like($src, qr/^k8s status\s+=> '\+TestEmit::V1::KnobStatus';$/m, 'status');
    like($src, qr/^=attr spec\n/m, 'attr POD for spec');
    like($src, qr/\n1;\n\z/, 'ends with 1;');
    unlike($src, qr/_AUTOGEN/, 'no generated namespace leaks into the source');
};

subtest 'field lines render every type form and the options' => sub {
    my $src = $files->{'TestEmit/V1/KnobSpec.pm'};
    like($src, qr/^use IO::K8s::Resource;$/m, 'nested class is a Resource');
    like($src, qr/^k8s mode\s+=> Str, \{ required => 'schema', enum => \[qw\(fast safe\)\], default => 'safe' \};$/m, 'enum + default + schema-required');
    like($src, qr/^k8s replicas\s+=> Int, \{ minimum => 0, maximum => 5 \};$/m, 'range');
    like($src, qr/^k8s limit\s+=> '\+TestEmit::V1::RateLimit';$/m, 'nested object via the name map');
    like($src, qr/^k8s routes\s+=> \['\+TestEmit::V1::KnobSpecRoutesItem'\];$/m, 'array of objects');
    like($src, qr/^k8s size\s+=> IntOrStr;$/m, 'int-or-string');
    like($src, qr/^k8s extra\s+=> \{ Str => 1 \}, \{ preserve_unknown => 1 \};$/m, 'opaque map with a schema-only option');
    like($src, qr/^=attr mode\n\nOperating mode\.\n/m, 'description becomes the =attr text');
    like($src, qr/^=attr replicas\n\nNo description in the upstream schema\.\n/m, 'fallback text');
    unlike($src, qr/description =>/, 'description is not repeated as an option');
    my $limit = $files->{'TestEmit/V1/RateLimit.pm'};
    like($limit, qr/^package TestEmit::V1::RateLimit;\n# ABSTRACT: Rate limit applied to the knob\.$/m, 'ABSTRACT from the object description');
    like($limit, qr/^k8s period\s+=> Str, \{ pattern => qr\/\^\[0-9\]\+\[smh\]\$\/ \};$/m, 'pattern as qr//');
    my $item = $files->{'TestEmit/V1/KnobSpecRoutesItem.pm'};
    like($item, qr/^k8s match\s+=> Str, \{ required => 'schema' \};$/m, 'required alone still renders the schema form');
};

subtest 'the rendered source compiles and round-trips the same document' => sub {
    for my $path (sort keys %$files) {
        my $src = $files->{$path};
        ok(eval "$src\n1;", "compiles: $path") or diag $@;
    }
    my $k8s = IO::K8s->new;
    $k8s->add({ Knob => '+TestEmit::V1::Knob' });
    my $doc = {
        apiVersion => 'opts.example.com/v1', kind => 'Knob',
        metadata => { name => 'k', namespace => 'd' },
        spec => { mode => 'fast', replicas => 2, limit => { average => 1, period => '5s' },
                  routes => [ { match => 'a', weight => 1 } ], size => 3, extra => { x => 1 } },
        status => { ready => JSON::PP::true() },
    };
    require JSON::PP;
    my $hand = $k8s->inflate($doc);
    isa_ok($hand->spec->limit, 'TestEmit::V1::RateLimit');
    my $gen = do { my $g = IO::K8s->new; $g->add({ Knob => "+$root" }); $g->inflate($doc) };
    is_deeply($hand->TO_JSON, $gen->TO_JSON, 'emitted classes and generated classes agree on the wire');
    throws_ok { $k8s->inflate({ %$doc, spec => { mode => 'slow' } }) } qr/not one of: fast, safe/, 'constraints survive the round-trip into source';
};

done_testing;
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `prove -l t/74_crd_emitter.t`
Expected: FAIL -- `Can't locate IO/K8s/CRD/Emitter.pm`.

- [ ] **Step 3: Create `lib/IO/K8s/CRD/Emitter.pm`**

```perl
package IO::K8s::CRD::Emitter;
# ABSTRACT: Render generated IO::K8s classes as house-style Perl source
our $VERSION = '1.108';
use v5.10;
use Moo;
use Carp qw( croak );
use Data::Dumper ();
use Types::Standard qw( Str HashRef );
use IO::K8s::Role::Resource ();

=head1 SYNOPSIS

    my $classes = IO::K8s::CRD->generate($crd, 'IO::K8s::_SUGGEST');
    my $emitter = IO::K8s::CRD::Emitter->new(
        base  => 'IO::K8s::Traefik::V1alpha1',
        names => { "$root\::Spec::RateLimit" => 'RateLimit' },   # D6: upstream Go type names
    );
    my $files = $emitter->render($classes->{'traefik.io/v1alpha1'});
    # { 'IO/K8s/Traefik/V1alpha1/Middleware.pm' => "package ...", ... }

=head1 DESCRIPTION

The source half of D10: what L<IO::K8s::CRD> generates at runtime, rendered
as the checked-in, hand-maintained class files this distribution ships --
one file per class, the C<k8s> DSL line per field with its options, the
schema description as the field's C<=attr> POD. It reads nothing but the
attribute registry of the generated classes, so it renders any AutoGen
class set, and it never writes a file: callers get C<< { path => source } >>
and decide (C<maint/crd-drift-check.pl --suggest> prints,
C<--suggest-dir> writes outside C<lib/>).

Descriptions go into POD, not into the C<description> field option: the
house format documents every field once, in the C<=attr> block.

=cut

=attr base

The package prefix of the rendered classes, e.g. C<IO::K8s::Traefik::V1alpha1>.
Required.

=attr names

Hashref from a generated class name to the bare package name it should get
under L</base>: C<< { 'IO::K8s::_AUTOGEN_x::...::Middleware::Spec::RateLimit' => 'RateLimit' } >>.
Classes not listed get their path joined: C<Middleware::Spec::RateLimit>
becomes C<MiddlewareSpecRateLimit>. This is where the upstream Go type
names (D6) come in.

=attr version

The C<$VERSION> line to write. Defaults to this distribution's.

=cut

has base    => (is => 'ro', isa => Str, required => 1);
has names   => (is => 'ro', isa => HashRef, default => sub { {} });
has version => (is => 'ro', isa => Str, default => sub { $VERSION });

# Reverse of IO::K8s::Resource's class-prefix map: a stock class is written
# the short way the hand-written classes use ('Core::V1::PodTemplateSpec').
my @SHORT_PREFIXES = (
    [ 'IO::K8s::Apimachinery::Pkg::Apis::Meta'                          => 'Meta' ],
    [ 'IO::K8s::ApiextensionsApiserver::Pkg::Apis::Apiextensions'       => 'Apiextensions' ],
    [ 'IO::K8s::KubeAggregator::Pkg::Apis::Apiregistration'             => 'KubeAggregator' ],
    [ 'IO::K8s::Api'                                                    => '' ],
);

=method package_for

    my $package = $emitter->package_for($generated_class);

The package a generated class is rendered as: L</names> when listed,
otherwise L</base> plus the class's path segments below its Kind joined
together (the Kind itself for the root).

=cut

sub package_for {
    my ($self, $class) = @_;
    my $root = $self->{_root} // croak 'package_for needs a render() first';
    return $self->base . '::' . $self->names->{$class} if $self->names->{$class};
    (my $rel = $class) =~ s/^\Q$root\E(?:::)?//;
    my $kind = (split /::/, $root)[-1];
    my $joined = join '', $kind, split /::/, $rel;
    return $self->base . '::' . $joined;
}

=method render

    my $files = $emitter->render($root_class);

Renders C<$root_class> and every generated class reachable from its fields
(objects, arrays of objects, maps of objects) as
C<< { 'Relative/Path.pm' => $source } >>. Stock classes referenced by a
field (C<ObjectMeta>, core types) are written by their short name and not
rendered.

=cut

sub render {
    my ($self, $root) = @_;
    $self->{_root} = $root;   # kept after render() so package_for() stays usable
    my %files;
    my @todo = ($root);
    my %seen;
    while (my $class = shift @todo) {
        next if $seen{$class}++;
        my ($source, @nested) = $self->_render_class($class);
        (my $path = $self->package_for($class)) =~ s{::}{/}g;
        $files{"$path.pm"} = $source;
        push @todo, @nested;
    }
    return \%files;
}

# A generated class is one this emitter renders; anything else is stock.
sub _is_generated {
    my ($self, $class) = @_;
    return index($class, $self->{_root}) == 0;
}

sub _class_ref {
    my ($self, $class) = @_;
    return "'+" . $self->package_for($class) . "'" if $self->_is_generated($class);
    for my $pair (@SHORT_PREFIXES) {
        my ($full, $short) = @$pair;
        next unless index($class, "$full\::") == 0;
        my $rest = substr($class, length($full) + 2);
        return "'" . ($short ? "$short\::$rest" : $rest) . "'";
    }
    return "'+$class'";
}

# The DSL type spec for one registry entry, as source. Returns
# ($source, $nested_class_or_undef).
sub _type_source {
    my ($self, $info) = @_;
    my $nested = $info->{class} && $self->_is_generated($info->{class}) ? $info->{class} : undef;
    return ($self->_class_ref($info->{class}), $nested)                if $info->{is_object};
    return ('[' . $self->_class_ref($info->{class}) . ']', $nested)    if $info->{is_array_of_objects};
    return ('{ ' . $self->_class_ref($info->{class}) . ' => 1 }', $nested) if $info->{is_hash_of_objects};
    return ('[Str]')      if $info->{is_array_of_str};
    return ('[Int]')      if $info->{is_array_of_int};
    return ('[Bool]')     if $info->{is_array_of_bool};
    return ('[ {} ]')     if $info->{is_array_of_hash};
    return ('[ [] ]')     if $info->{is_array_of_array};
    return ('{ Str => 1 }')      if $info->{is_hash_of_str};
    return ('{ Int => 1 }')      if $info->{is_hash_of_int};
    return ('{ Num => 1 }')      if $info->{is_hash_of_num};
    return ('{ Bool => 1 }')     if $info->{is_hash_of_bool};
    return ('{ Quantity => 1 }') if $info->{is_hash_of_quantity};
    return ('{ Time => 1 }')     if $info->{is_hash_of_time};
    return ('{ IntOrStr => 1 }') if $info->{is_hash_of_int_or_string};
    return ('Str')      if $info->{is_str};
    return ('Int')      if $info->{is_int};
    return ('Num')      if $info->{is_num};
    return ('Bool')     if $info->{is_bool};
    return ('IntOrStr') if $info->{is_int_or_string};
    return ('Quantity') if $info->{is_quantity};
    return ('Time')     if $info->{is_time};
    croak 'IO::K8s::CRD::Emitter: registry entry with no recognizable type';
}

# A Perl literal for an option value.
sub _literal {
    my ($value) = @_;
    if (ref $value eq 'Regexp') {
        my $pattern = re::regexp_pattern($value);
        (my $body = $pattern) =~ s{/}{\\/}g;
        return "qr/$body/";
    }
    if (ref $value eq 'ARRAY' && @$value && !grep { ref $_ || /[\s'\\()]/ } @$value) {
        return '[qw(' . join(' ', @$value) . ')]';
    }
    local $Data::Dumper::Terse    = 1;
    local $Data::Dumper::Indent   = 0;
    local $Data::Dumper::Sortkeys = 1;
    local $Data::Dumper::Useqq    = 0;
    my $dumped = Data::Dumper::Dumper($value);
    $dumped =~ s/^\s+|\s+$//g;
    return $dumped;
}

my @OPTION_ORDER = qw( required enum minimum maximum pattern default nullable preserve_unknown );

# `required` is rendered as `required => 'schema'`: recorded for the CRD
# schema, never enforced at construction -- the same policy AutoGen applies,
# because a cluster returns `status: {}` for a fresh object whatever the
# status schema requires. A hand-written class that wants enforcement
# writes `'required'` itself.
sub _options_source {
    my ($info) = @_;
    my %opts = %{ $info->{options} // {} };
    delete $opts{description};             # goes to POD
    $opts{required} = 'schema' if $info->{required};
    return '' unless %opts;
    my @parts = map { "$_ => " . _literal($opts{$_}) } grep { exists $opts{$_} } @OPTION_ORDER;
    return ', { ' . join(', ', @parts) . ' }';
}

sub _render_class {
    my ($self, $class) = @_;
    require re;
    my $info  = IO::K8s::Role::Resource::_k8s_attr_info($class);
    my $attrs = $class->_k8s_attributes;
    my $is_top = $class->can('_is_resource') ? 1 : 0;
    my $package = $self->package_for($class);

    my @nested;
    my (@lines, @pod);
    my $width = 0;
    for my $attr (@$attrs) {
        my $key = $info->{$attr}{json_key} // $attr;
        $width = length $key if length $key > $width;
    }
    for my $attr (@$attrs) {
        my $i   = $info->{$attr};
        my $key = $i->{json_key} // $attr;
        my ($type, $nested) = $self->_type_source($i);
        push @nested, $nested if $nested;
        my $name = $key =~ /^[A-Za-z_]\w*$/ ? $key : "'$key'";
        push @lines, sprintf("k8s %-*s => %s%s;", $width, $name, $type, _options_source($i));
        my $desc = $i->{options}{description} // 'No description in the upstream schema.';
        push @pod, "=attr $key\n\n$desc\n\n=cut\n";
    }

    my $abstract = $self->{_abstracts}{$class} // ($is_top ? $class->kind : (split /::/, $package)[-1]);
    my $header = join "\n",
        "package $package;",
        "# ABSTRACT: $abstract",
        "our \$VERSION = '" . $self->version . "';";
    my $use = $is_top
        ? join("\n",
            'use IO::K8s::APIObject',
            "    api_version     => '" . $class->api_version . "',",
            "    resource_plural => '" . ($class->resource_plural // '') . "';",
            ($class->does('IO::K8s::Role::Namespaced') ? "with 'IO::K8s::Role::Namespaced';" : ()),
          )
        : 'use IO::K8s::Resource;';

    my $source = join "\n", $header, $use, '', @lines, '', @pod, '1;', '';
    return ($source, @nested);
}

1;
```

Two things the implementer wires up beyond the code above, both small:

1. **Object descriptions for `# ABSTRACT`.** AutoGen does not keep a class-level description. Add to `lib/IO/K8s/AutoGen.pm`, in `_generate_class` right after `$_generated{$class} = 1;`, the line `$_descriptions{$class} = $schema->{description} if defined $schema->{description};` with `my %_descriptions;` declared next to `%_generated`, a `sub class_description { $_descriptions{$_[0]} }` accessor, and `clear_cache` also clearing it. The emitter's `_render_class` then uses `IO::K8s::AutoGen::class_description($class)` in place of `$self->{_abstracts}{$class}`; the first sentence (up to the first `. ` or the end) becomes the ABSTRACT.
2. **`re::regexp_pattern`** returns `(pattern, flags)` in list context; take the pattern only (`my ($pattern) = re::regexp_pattern($value);`) and append the flags after the closing slash when non-empty.

- [ ] **Step 4: Run the test to verify it passes**

Run: `prove -l t/74_crd_emitter.t`
Expected: PASS. If a regex in the test disagrees with the rendered whitespace, the test's expectation is the spec: it pins the house layout (`k8s name => Type, opts;` with the names padded to the longest key).

- [ ] **Step 5: Run the full suite**

Run: `prove -lr t/`
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/IO/K8s/CRD/Emitter.pm lib/IO/K8s/AutoGen.pm t/74_crd_emitter.t
git commit -m "Add IO::K8s::CRD::Emitter: render generated classes as house-style source (D10)"
```

---

### Task 4: `maint/crd-drift-check.pl --suggest`

**Lane:** `io-k8s-worker`.

**Files:**
- Modify: `maint/crd-drift-check.pl` (`usage`, `parse_args`, `parse_crds` keeps the document, new `suggest_for`, main)

**Interfaces:**
- Consumes: `IO::K8s::CRD->generate($doc, $namespace)`, `IO::K8s::CRD::Emitter`.
- Produces: `--suggest` (print rendered source for every GVK reported under OPAQUE SPEC or MISSING FIELD, after the report), `--suggest-dir DIR` (write the files under DIR, refuse a DIR inside the distribution's `lib/`), `--names FILE` (YAML map of generated-class suffix to bare package name; keys are written relative to the Kind class, e.g. `Middleware::Spec::RateLimit: RateLimit`).

- [ ] **Step 1: Extend `parse_crds` to keep the document**

In the `$by_gvk{$gvk} = { ... }` hash add `doc => $doc,` (the whole CRD hashref) so a later step can regenerate the Kind for one version.

- [ ] **Step 2: Add the options**

In `usage`, after the `--output PATH` line:

```
  --suggest           After the report, print the class source the emitter
                       renders for every OPAQUE SPEC and MISSING FIELD Kind
                       (never touches lib/).
  --suggest-dir PATH  Write those files under PATH instead of printing
                       (PATH must not be inside the distribution's lib/).
  --names FILE        YAML map of generated-class path (relative to the
                       Kind, e.g. "Middleware::Spec::RateLimit") to the
                       package name to use (e.g. "RateLimit") -- the
                       upstream Go type names (D6).
```

In `parse_args`, add `'suggest' => \$opt{suggest}, 'suggest-dir=s' => \$opt{suggest_dir}, 'names=s' => \$opt{names}` to the GetOptions list (match the file's existing style for the other options) and, after parsing, when `$opt{suggest_dir}` is set: resolve it with `File::Spec->rel2abs`, and die `crd-drift-check: --suggest-dir must not point inside lib/` if it starts with the resolved `lib` directory (`$opt{lib}`).

- [ ] **Step 3: Add `suggest_for` and the main hook**

After `render_report`:

```perl
# ---------------------------------------------------------------------------
# --suggest: the classes the emitter would write for a reported Kind.
#
# Report-only stays report-only: the source goes to stdout or to a directory
# the caller names, never into lib/. One throwaway AutoGen namespace per
# GVK keeps the generated classes apart from anything the providers loaded.
# ---------------------------------------------------------------------------

sub load_names {
    my ($path) = @_;
    return {} unless $path;
    require YAML::PP;
    my $map = YAML::PP->new->load_file($path);
    die "crd-drift-check: --names file must be a YAML map\n" unless ref $map eq 'HASH';
    return $map;
}

sub suggest_for {
    my ($opt, $result, $upstream, $names) = @_;
    require IO::K8s::CRD;
    require IO::K8s::CRD::Emitter;
    my @gvks = map { $_->[0] } @{ $result->{opaque_spec} }, @{ $result->{missing_field} };
    my %seen;
    my %files;
    my $n = 0;
    for my $gvk (grep { !$seen{$_}++ } @gvks) {
        my $u = $upstream->{$gvk} or next;
        my $ns = 'IO::K8s::_SUGGEST_' . ++$n;
        my $classes = IO::K8s::CRD->generate($u->{doc}, $ns);
        my $root = $classes->{"$u->{group}/$u->{version}"} or next;
        my %class_names = map { ("$root\::$_" => $names->{$_}) } grep { $_ ne $u->{kind} } keys %$names;
        my $emitter = IO::K8s::CRD::Emitter->new(
            base  => "IO::K8s::$result->{provider}::" . ucfirst($u->{version}),
            names => \%class_names,
        );
        my $rendered = $emitter->render($root);
        $files{$_} = $rendered->{$_} for keys %$rendered;
    }
    return \%files;
}

sub emit_suggestions {
    my ($opt, $files) = @_;
    return unless %$files;
    if ($opt->{suggest_dir}) {
        require File::Path;
        require File::Basename;
        for my $rel (sort keys %$files) {
            my $path = "$opt->{suggest_dir}/$rel";
            File::Path::make_path(File::Basename::dirname($path));
            open my $fh, '>:encoding(UTF-8)', $path or die "crd-drift-check: cannot write $path: $!\n";
            print $fh $files->{$rel};
            close $fh;
        }
        print "\n--- suggest: wrote " . scalar(keys %$files) . " file(s) under $opt->{suggest_dir}\n";
        return;
    }
    for my $rel (sort keys %$files) {
        print "\n#### $rel\n", $files->{$rel};
    }
}
```

`check_provider` must hand back the parsed upstream view for `suggest_for`: add `$result->{_upstream} = $upstream;` before its final `return $result;` (and `delete $_->{_upstream} for @results;` before the JSON encode in main so the JSON report stays as it was). In main, after `print $report;` and the `--output` block:

```perl
if ($opt->{suggest} || $opt->{suggest_dir}) {
    my $names = load_names($opt->{names});
    my %files;
    for my $r (@results) {
        next unless $r->{_upstream};
        my $f = suggest_for($opt, $r, $r->{_upstream}, $names);
        $files{$_} = $f->{$_} for keys %$f;
    }
    emit_suggestions($opt, \%files);
}
```

Note: `--names` keys are relative to the Kind (`Middleware::Spec::RateLimit`), so `suggest_for` prefixes each with the generated root class; a key equal to the Kind itself is ignored (the root keeps the Kind's name).

- [ ] **Step 4: Verify offline against the cached manifests**

Run (from the distribution root, using the manifest cache under `spec/crd/` so no network is needed):
```
perl maint/crd-drift-check.pl --provider Traefik --suggest 2>&1 | grep -c '^#### IO/K8s/Traefik/V1alpha1/'
```
Expected: a count of at least 10 (one root file per opaque Traefik Kind plus nested classes). Then:
```
perl maint/crd-drift-check.pl --provider Traefik --suggest-dir /tmp/claude-1000/-home-getty-dev-io-k8s-p5/4cb4b20a-4bbe-4b8f-860a-704af0bc5a88/scratchpad/suggest-traefik && perl -c /tmp/claude-1000/-home-getty-dev-io-k8s-p5/4cb4b20a-4bbe-4b8f-860a-704af0bc5a88/scratchpad/suggest-traefik/IO/K8s/Traefik/V1alpha1/Middleware.pm
```
Expected: the directory is written and the Middleware file compiles with `-Ilib -I<suggest-dir>` (add both to `perl -c`). And:
```
perl maint/crd-drift-check.pl --provider Traefik --suggest-dir lib/IO/K8s/Traefik
```
Expected: dies with `--suggest-dir must not point inside lib/`. Finally `prove -lr t/` stays green (the script has no test of its own; the three commands above are the verification and their output goes into the report).

- [ ] **Step 5: Commit**

```bash
git add maint/crd-drift-check.pl
git commit -m "crd-drift-check: --suggest / --suggest-dir / --names print or write the emitted classes for reported gaps (D10)"
```

---

### Task 5: POD, README, Changes

**Lane:** `io-k8s-doc-writer`.

**Files:**
- Modify: `README.md` ("Custom Resource Definitions (CRDs)" section: `add_crd` example before the hand-written class example; one sentence on the emitter and `--suggest`), `lib/IO/K8s.pm` (AUTO-GENERATION section: nested classes now typed, `add_crd` cross-reference), `lib/IO/K8s/AutoGen.pm` (DESCRIPTION: the nested-class rule replaces the k94 caveat written in step 2), `CLAUDE.md` (the "Checking coverage against upstream" paragraph gains one sentence on `--suggest`), `Changes`.

- [ ] **Step 1: Document**

README, in "Custom Resource Definitions (CRDs)", before "Write your own CRD classes":

```perl
# From the cluster's own CRD manifest -- one class per served version,
# nested objects typed, constraints enforced:
my $k8s = IO::K8s->new;
$k8s->add_crd('knobs.opts.example.com.yaml');   # path, YAML/JSON text, hashref or CRD object
my $knob = $k8s->new_object('Knob', metadata => { name => 'k' }, spec => { mode => 'fast' });
```

plus one sentence: the same classes can be rendered as checked-in source with `IO::K8s::CRD::Emitter`, which is what `maint/crd-drift-check.pl --suggest` prints for the bundled providers' gaps.

`lib/IO/K8s/Resource.pm` `=head3 Field options`: the "Class load fails ... on:" catalogue still says a `default` failing the field's own type is checked for every field; add that object-bearing fields (an object, an inline struct, an array or map of objects) are exempt and their default is recorded as given (carried over from the step-2 re-review). `lib/IO/K8s.pm` AUTO-GENERATION: state that inline objects with properties become nested classes named `<Kind>::<Prop>` (`Item`/`Value` suffixes), that hash-style access on them still works, and point to `add_crd`. `lib/IO/K8s/AutoGen.pm`: replace the step-2 k94 caveat paragraph with the nested-class rule. `CLAUDE.md`: one sentence after the `--verbose` sentence: `--suggest` prints the classes the emitter renders for reported gaps, `--suggest-dir` writes them outside `lib/`.

- [ ] **Step 2: Changes**

Under `{{$NEXT}}`, above the step-2 bullets:

```
  - IO::K8s::AutoGen types inline objects (D10, k94). A `type: object`
    with properties -- which is how every CRD schema is written below its
    top level -- now becomes a nested class named after its place in the
    parent (<Kind>::Spec, <Kind>::Spec::Limit, ...Item for array items,
    ...Value for map values) instead of an opaque hash, so field options,
    strict and the unknown-field bag reach every level. Hash-style access
    on such a field keeps working (a Moo object is a blessed hash);
    property-less objects and additionalProperties-only maps stay opaque.

  - New IO::K8s::CRD and IO::K8s->add_crd (D10, k94): load a
    CustomResourceDefinition (object, hashref, YAML/JSON text, path, or a
    list of those), generate one class per served version, register every
    version under its domain-qualified key and the storage version under
    the bare Kind -- through add(), so a provider merged earlier keeps the
    short name.

  - New IO::K8s::CRD::Emitter renders generated classes as house-style
    source files from the attribute registry (fields, options, required,
    descriptions as =attr POD, a name map for upstream Go type names).
    maint/crd-drift-check.pl --suggest prints those files for every
    OPAQUE SPEC / MISSING FIELD Kind; --suggest-dir writes them, and
    refuses a directory inside lib/.
```

- [ ] **Step 3: Verify and commit**

Run: `podchecker lib/IO/K8s/CRD.pm lib/IO/K8s/CRD/Emitter.pm lib/IO/K8s.pm lib/IO/K8s/AutoGen.pm` (new errors only), `prove -lr t/`, `dzil test`, `dzil clean`.

```bash
git add README.md CLAUDE.md Changes lib/IO/K8s.pm lib/IO/K8s/AutoGen.pm lib/IO/K8s/CRD.pm lib/IO/K8s/CRD/Emitter.pm
git commit -m "Document add_crd, the emitter and --suggest (D10, k94)"
```

---

## Self-review

- **Spec coverage (D10):** `add_crd` accepting object/hashref/text/path -> Task 2; one class per served version, qualified keys + storage short name -> Task 2; nested typing "extended for openAPIV3Schema" -> Task 1; source emitter with POD skeleton and Go-name map -> Task 3; `--suggest` never writing `lib/` -> Task 4; D6 naming via `names` -> Tasks 3/4; docs -> Task 5.
- **Placeholder scan:** none; every code step carries the code.
- **Type consistency:** `IO::K8s::CRD->generate` returns `{ api_version => class, storage => api_version }` in Task 2 and is consumed with exactly those keys in Tasks 2 (`add_crd`), 3 (test) and 4 (`suggest_for`); nested class names `<Parent>::<Prop>` / `Item` / `Value` from Task 1 are what Task 3's `package_for` joins and what the t/74 expectations spell out; `IO::K8s::AutoGen::class_description` is added in Task 3 and used only there.
