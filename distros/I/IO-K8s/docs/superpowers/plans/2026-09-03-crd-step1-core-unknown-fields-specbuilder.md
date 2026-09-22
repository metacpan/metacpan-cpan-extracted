# CRD Step 1: Preserved Unknown Fields, `strict`, Object-Aware SpecBuilder -- Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make every IO::K8s object keep the fields its class does not declare (re-emitting them on serialization, dying instead under `strict`), and make `SpecBuilder` plus the builder roles work on typed (inline-struct / object) specs as well as on plain hashes -- closing k90 and k91.

**Architecture:** A `BUILDARGS` wrapper in `IO::K8s::Role::Resource` diverts undeclared constructor keys into a per-object `_unknown_fields` bag that `TO_JSON` merges back; a dynamic `$IO::K8s::Resource::STRICT` flag, localized by an `IO::K8s` instance built with `strict => 1`, turns that into a fatal error at every nesting level. `IO::K8s::Role::SpecBuilder` is rewritten around three node helpers (read / vivify / store) that treat plain hashes, plain arrays and IO::K8s objects uniformly through the attribute registry; the builder roles are then expressed in `SpecBuilder` calls so they stop caring whether `spec` is a hash or an object.

**Tech Stack:** Perl 5.10+, Moo, Type::Tiny, Module::Runtime, Test::More, Test::Exception. Run tests with `prove -lr t/` (the `-r` is required) or a single file with `prove -l t/NN_name.t`.

**Spec:** `docs/superpowers/specs/2026-09-03-crd-design.md`, decisions D1 and D2, tickets k90 and k91.

## Global Constraints

- Every module keeps its own `our $VERSION = '1.108';` line (PAUSE indexing; do not "clean up").
- No new CPAN dependencies. `Module::Runtime`, `Moo`, `Type::Tiny`, `JSON::MaybeXS`, `Test::Exception` are already in `cpanfile`.
- Nothing under `lib/` is generated; all edits are by hand.
- The full suite must be green after every task: `prove -lr t/` (about 16 s). A task is not done while any test is skipped or failing.
- Code comments and POD are English, in the existing house voice (see the k56 / k68 comments in `lib/IO/K8s/AutoGen.pm` for the register).
- Delegation lanes (from `.claude/rules/io-k8s-rules.md`): `lib/` edits go to `io-k8s-worker`, new tests to `io-k8s-test-writer`, POD to `io-k8s-doc-writer`. Each task below names its lane.
- Commit after every task with the trailer:
  ```
  Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>
  Claude-Session: https://claude.ai/code/session_01MysDYqMAm8iUAbiTm1XhYi
  ```

## File structure

| File | Responsibility after this plan |
|------|-------------------------------|
| `lib/IO/K8s/Resource.pm` | the `k8s` DSL; gains the `$STRICT` package flag only |
| `lib/IO/K8s/Role/Resource.pm` | instance behaviour of every object: gains `_unknown_fields`, the known-init-arg cache, the `BUILDARGS` wrapper, the `TO_JSON` merge |
| `lib/IO/K8s.pm` | gains the `strict` attribute and localizes `$STRICT` in `inflate`, `new_object`, `json_to_object`, `struct_to_object` |
| `lib/IO/K8s/Role/SpecBuilder.pm` | rewritten: node helpers + `spec_get/set/push/merge/delete` + new `spec_array`/`spec_hash` |
| `lib/IO/K8s/Role/{CertManaged,HelmManaged,MiddlewareBuilder,Loadbalanced,Routable,NetworkPolicy}.pm` | builder roles expressed in `SpecBuilder` calls (core-typed branches untouched) |
| `t/66_unknown_fields.t` | D1 preservation, all construction paths |
| `t/67_strict.t` | D1 `strict` |
| `t/68_specbuilder_objects.t` | D2 on typed specs, k90 regression |
| `t/69_builder_roles_on_structs.t` | every builder role on a modeled spec |
| `README.md`, `lib/IO/K8s/AgentSandbox.pm`, `Changes` | k91 example fix, changelog |

---

### Task 1: Preserve unknown constructor fields (D1, preserve half)

**Lane:** `io-k8s-worker` for `lib/`, `io-k8s-test-writer` for the test.

**Files:**
- Modify: `lib/IO/K8s/Resource.pm` (after `our %_attr_registry;`, line 16)
- Modify: `lib/IO/K8s/Role/Resource.pm` (attribute block after `has json`, caches after `%_attributes_cache`, `_invalidate_k8s_attr_cache`, end of `TO_JSON`)
- Test: `t/66_unknown_fields.t`

**Interfaces:**
- Produces: `$IO::K8s::Resource::STRICT` (package var, default 0); `$obj->_unknown_fields` (rw hashref, default `{}`); `IO::K8s::Role::Resource::_known_init_args($class)` (hashref of accepted constructor keys, cached).
- Later tasks rely on: `_unknown_fields` (Task 3 reads/writes it for undeclared keys on objects), `$STRICT` (Task 2 localizes it).

- [ ] **Step 1: Write the failing test**

Create `t/66_unknown_fields.t`:

```perl
#!/usr/bin/env perl
# D1: a constructor key no attribute claims is kept in _unknown_fields and
# emitted again by TO_JSON -- on inflate, new_object and a direct ->new,
# at every nesting level, including inline structs (k91 part 2).
use strict;
use warnings;
use Test::More;
use JSON::PP ();

use IO::K8s;
use IO::K8s::Api::Core::V1::Pod;
use IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::ObjectMeta;

my $k8s = IO::K8s->new;

sub meta { IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::ObjectMeta->new(name => $_[0]) }

subtest 'inflate keeps undeclared fields at every level' => sub {
    my $pod = $k8s->inflate({
        apiVersion => 'v1',
        kind       => 'Pod',
        metadata   => { name => 'x' },
        spec       => {
            containers => [ { name => 'c', image => 'i', bogusToo => JSON::PP::true } ],
            bogusField => { nested => [ 1, 2 ] },
        },
    });
    my $out = $pod->TO_JSON;
    is_deeply($out->{spec}{bogusField}, { nested => [ 1, 2 ] }, 'unknown spec field round-trips');
    ok($out->{spec}{containers}[0]{bogusToo}, 'unknown field inside an array element round-trips');
    is_deeply($pod->spec->_unknown_fields, { bogusField => { nested => [ 1, 2 ] } }, 'the bag holds exactly the unknown field');
    ok(!exists $out->{_unknown_fields}, 'the bag itself is not a wire field');
    ok(!exists $out->{spec}{_unknown_fields}, 'nor on nested objects');
};

subtest 'new_object and a direct constructor keep unknown fields too' => sub {
    my $pod = $k8s->new_object('Pod',
        metadata => { name => 'y' },
        spec     => { containers => [], extra => 'v' },
    );
    is($pod->TO_JSON->{spec}{extra}, 'v', 'new_object path');

    my $direct = IO::K8s::Api::Core::V1::Pod->new(metadata => meta('z'), whatever => 1);
    is($direct->TO_JSON->{whatever}, 1, 'direct ->new path');
};

subtest 'apiVersion and kind in a struct are not unknown fields' => sub {
    my $pod = $k8s->inflate({ apiVersion => 'v1', kind => 'Pod', metadata => { name => 'x' } });
    is_deeply($pod->_unknown_fields, {}, 'the GVK keys the role supplies are recognised');
};

subtest 'a declared attribute wins over a same-named bag entry' => sub {
    my $pod = IO::K8s::Api::Core::V1::Pod->new(
        metadata => meta('z'),
        spec     => { containers => [] },
    );
    $pod->_unknown_fields({ spec => 'shadow' });
    is(ref $pod->TO_JSON->{spec}, 'HASH', 'declared spec is emitted, the bag entry is ignored');
};

subtest 'undef unknown values are not kept' => sub {
    my $pod = IO::K8s::Api::Core::V1::Pod->new(metadata => meta('z'), gone => undef);
    ok(!exists $pod->TO_JSON->{gone}, 'undef unknown value omitted');
    is_deeply($pod->_unknown_fields, {}, 'and not stored');
};

subtest 'the bag does not alias the caller data (k54 line)' => sub {
    my $data = { deep => 1 };
    my $pod = IO::K8s::Api::Core::V1::Pod->new(metadata => meta('z'), extra => $data);
    $data->{deep} = 2;
    is($pod->TO_JSON->{extra}{deep}, 1, 'one-level copy on the way in');
    my $out = $pod->TO_JSON;
    $out->{extra}{deep} = 3;
    is($pod->TO_JSON->{extra}{deep}, 1, 'one-level copy on the way out');
};

subtest 'inline struct keeps unknown keys (k91 part 2)' => sub {
    my $sb = IO::K8s->new(with => ['IO::K8s::AgentSandbox']);
    my $s = $sb->new_object('Sandbox',
        metadata => { name => 'x', namespace => 'd' },
        spec     => { replicas => 1, shutdownPolicy => 'Retain' },
    );
    is($s->TO_JSON->{spec}{replicas}, 1, 'undeclared spec.replicas survives on an inline struct');
    is($s->TO_JSON->{spec}{shutdownPolicy}, 'Retain', 'declared field still there');
};

subtest 'JSON round-trip through to_json / from_json keeps the field' => sub {
    my $pod = $k8s->new_object('Pod', metadata => { name => 'r' }, spec => { containers => [], extra => [ 'a' ] });
    my $again = IO::K8s::Api::Core::V1::Pod->from_json($pod->to_json);
    is_deeply($again->TO_JSON->{spec}{extra}, [ 'a' ], 'survives a full serialize/parse cycle');
};

done_testing;
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `prove -l t/66_unknown_fields.t`
Expected: FAIL -- the first subtest fails on `unknown spec field round-trips` (field missing), and `_unknown_fields` is an unknown method.

- [ ] **Step 3: Add the `$STRICT` flag to `lib/IO/K8s/Resource.pm`**

After `our %_attr_registry;` (line 16) insert:

```perl
# Unknown-field policy (D1). Off: a constructor key no attribute claims is
# kept in the object's _unknown_fields bag and emitted again by TO_JSON, so
# a document from a newer upstream than the class still round-trips. On: it
# dies naming the class and the field. IO::K8s localizes this around its own
# entry points when built with strict => 1 (see IO::K8s/strict); nothing
# else writes it. A package variable rather than a constructor argument so
# that it reaches the inline-struct coercers, which call ->new directly and
# never pass through IO::K8s::_inflate_struct.
our $STRICT = 0;
```

- [ ] **Step 4: Add the bag, the known-key cache and the `BUILDARGS` wrapper to `lib/IO/K8s/Role/Resource.pm`**

After the `_build_json` sub, add:

```perl
# Constructor arguments no attribute claims (D1). Kept so a document from a
# newer upstream than the class round-trips instead of losing fields; TO_JSON
# emits them again, declared attributes winning on a name clash. Filled by
# the BUILDARGS wrapper below; SpecBuilder writes undeclared keys here too.
# Not a k8s-registered attribute, so TO_JSON's attribute walk never sees the
# bag as a field of its own.
has _unknown_fields => (
    is       => 'rw',
    init_arg => '_unknown_fields',
    default  => sub { {} },
);
```

After the `my %_attributes_cache;` line, add:

```perl
my %_known_init_args_cache;

# Every constructor key a class accepts: the JSON key of each k8s-registered
# attribute (json_key when the Perl name was sanitized), the init_arg of every
# Moo attribute declared with a plain `has` (metadata from Role::APIObject,
# json, _unknown_fields itself), and apiVersion/kind on a top-level object,
# which Role::APIObject supplies as methods rather than attributes. The Moo
# side is read from the constructor maker -- the same view
# MooX::StrictConstructor uses; Moo has no public accessor for it.
sub _known_init_args {
    my ($class) = @_;
    return $_known_init_args_cache{$class} //= _collect_known_init_args($class);
}

sub _collect_known_init_args {
    my ($class) = @_;
    my %known;
    my $info = _k8s_attr_info($class);
    for my $attr (keys %$info) {
        $known{ $info->{$attr}{json_key} // $attr } = 1;
    }
    if (my $maker = Moo->_constructor_maker_for($class)) {
        my $specs = $maker->all_attribute_specs;
        for my $name (keys %$specs) {
            my $spec = $specs->{$name};
            my $init = exists $spec->{init_arg} ? $spec->{init_arg} : $name;
            $known{$init} = 1 if defined $init;
        }
    }
    if ($class->can('_is_resource')) {
        $known{apiVersion} = 1;
        $known{kind}       = 1;
    }
    return \%known;
}

# One level of copying for a plain container -- the same depth TO_JSON and
# IO::K8s::_inflate_struct use (k54), duplicated here because IO::K8s.pm is
# loaded after this role and must not be required from it.
sub _copy_one_level {
    my ($value) = @_;
    return [ @$value ] if ref $value eq 'ARRAY';
    return { %$value } if ref $value eq 'HASH';
    return $value;
}

around BUILDARGS => sub {
    my ($orig, $class, @args) = @_;
    my $args  = $class->$orig(@args);
    my $known = _known_init_args($class);
    my %unknown;
    for my $key (keys %$args) {
        next if $known->{$key};
        die "Unknown field '$key' for $class\n" if $IO::K8s::Resource::STRICT;
        my $value = delete $args->{$key};
        next unless defined $value;
        $unknown{$key} = _copy_one_level($value);
    }
    if (%unknown) {
        my $bag = $args->{_unknown_fields} // {};
        $args->{_unknown_fields} = { %$bag, %unknown };
    }
    return $args;
};
```

Extend `_invalidate_k8s_attr_cache` so the new cache is cleared alongside the two existing ones -- add `delete $_known_init_args_cache{$class};` next to the two existing `delete` lines at the top, and `delete $_known_init_args_cache{$cached_class};` next to the two in the descendant loop. Also add `keys %_known_init_args_cache` to the `@sweep{...}` slice so descendants cached only there are swept:

```perl
sub _invalidate_k8s_attr_cache {
    my ($class) = @_;
    delete $_attr_info_cache{$class};
    delete $_attributes_cache{$class};
    delete $_known_init_args_cache{$class};
    my %sweep;
    @sweep{keys %_attr_info_cache, keys %_attributes_cache, keys %_known_init_args_cache} = ();
    for my $cached_class (keys %sweep) {
        next if $cached_class eq $class;
        next unless $cached_class->isa($class);
        delete $_attr_info_cache{$cached_class};
        delete $_attributes_cache{$cached_class};
        delete $_known_init_args_cache{$cached_class};
    }
}
```

- [ ] **Step 5: Merge the bag in `TO_JSON`**

In `TO_JSON`, replace the final `return \%data;` with:

```perl
    # Unknown fields ride along (D1). Declared attributes win on a clash:
    # the bag only fills keys nothing above has set.
    my $extra = $self->_unknown_fields;
    if ($extra && %$extra) {
        for my $key (keys %$extra) {
            next if exists $data{$key};
            $data{$key} = _copy_one_level($extra->{$key});
        }
    }
    return \%data;
```

- [ ] **Step 6: Run the test to verify it passes**

Run: `prove -l t/66_unknown_fields.t`
Expected: PASS, 8 subtests.

- [ ] **Step 7: Run the full suite**

Run: `prove -lr t/`
Expected: PASS. If a test asserts that an extra key is *absent* from `TO_JSON`, that test was documenting the silent drop; read it, state what it claimed, and update it to assert preservation (rule 7 in the house rules: say what the test asserted before changing it).

- [ ] **Step 8: Commit**

```bash
git add lib/IO/K8s/Resource.pm lib/IO/K8s/Role/Resource.pm t/66_unknown_fields.t
git commit -m "Preserve unknown constructor fields and re-emit them from TO_JSON (D1, k91)"
```

---

### Task 2: `strict` on `IO::K8s` (D1, strict half)

**Lane:** `io-k8s-worker` for `lib/`, `io-k8s-test-writer` for the test.

**Files:**
- Modify: `lib/IO/K8s.pm` (attribute block near `has with`, line ~326; first line of `inflate`, `new_object`, `json_to_object`, `struct_to_object`)
- Test: `t/67_strict.t`

**Interfaces:**
- Consumes: `$IO::K8s::Resource::STRICT` (Task 1).
- Produces: `IO::K8s->new(strict => 1)`; `$k8s->strict` (ro, default 0).

- [ ] **Step 1: Write the failing test**

Create `t/67_strict.t`:

```perl
#!/usr/bin/env perl
# D1: an IO::K8s built with strict => 1 dies on an unknown field at any
# nesting level, naming class and field; the flag never leaks out of the
# call, and a non-strict instance in the same process still preserves.
use strict;
use warnings;
use Test::More;
use Test::Exception;

use IO::K8s;

my $strict = IO::K8s->new(strict => 1);
my $lax    = IO::K8s->new;

ok(!$lax->strict, 'strict is off by default');

throws_ok {
    $strict->inflate({
        apiVersion => 'v1', kind => 'Pod',
        metadata   => { name => 'x' },
        spec       => { containers => [], bogus => 1 },
    });
} qr/^Unknown field 'bogus' for IO::K8s::Api::Core::V1::PodSpec$/m,
    'inflate: unknown spec field dies naming class and field';

throws_ok {
    $strict->new_object('Pod',
        metadata => { name => 'x' },
        spec     => { containers => [ { name => 'c', typo => 1 } ] },
    );
} qr/Unknown field 'typo' for IO::K8s::Api::Core::V1::Container/,
    'new_object: unknown field inside an array element dies';

throws_ok {
    $strict->json_to_object('Pod', '{"metadata":{"name":"x"},"spec":{"containers":[],"nope":true}}');
} qr/Unknown field 'nope' for IO::K8s::Api::Core::V1::PodSpec/,
    'json_to_object honours strict';

throws_ok {
    $strict->struct_to_object('Pod', { metadata => { name => 'x' }, oops => 1 });
} qr/Unknown field 'oops' for IO::K8s::Api::Core::V1::Pod/,
    'struct_to_object honours strict';

subtest 'inline-struct coercer path is covered' => sub {
    my $sb = IO::K8s->new(strict => 1, with => ['IO::K8s::AgentSandbox']);
    throws_ok {
        $sb->new_object('Sandbox',
            metadata => { name => 'x', namespace => 'd' },
            spec     => { replicas => 1, shutdownPolicy => 'Retain' },
        );
    } qr/Unknown field 'replicas' for IO::K8s::AgentSandbox::V1beta1::Sandbox::_Spec/,
        'the k91 example dies under strict';
};

lives_ok {
    $strict->inflate({ apiVersion => 'v1', kind => 'Pod', metadata => { name => 'x' } });
} 'apiVersion and kind in the struct are not unknown fields';

is($IO::K8s::Resource::STRICT, 0, 'the flag is restored after a strict call');

is(
    $lax->new_object('Pod', metadata => { name => 'x' }, spec => { containers => [], bogus => 1 })
        ->TO_JSON->{spec}{bogus},
    1,
    'a non-strict instance in the same process still preserves',
);

subtest 'load_yaml goes through inflate and inherits strict' => sub {
    throws_ok {
        $strict->load_yaml("apiVersion: v1\nkind: Pod\nmetadata:\n  name: x\nspec:\n  containers: []\n  bogus: 1\n");
    } qr/Unknown field 'bogus'/, 'load_yaml dies';
    my ($objects, $errors) = $strict->load_yaml(
        "apiVersion: v1\nkind: Pod\nmetadata:\n  name: x\nspec:\n  containers: []\n  bogus: 1\n",
        collect_errors => 1,
    );
    is(scalar @$objects, 0, 'collect_errors: nothing inflated');
    like($errors->[0], qr/Pod\/x: Unknown field 'bogus'/, 'collect_errors: the error is collected with kind/name');
};

done_testing;
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `prove -l t/67_strict.t`
Expected: FAIL -- `strict` is not a known constructor argument (Moo ignores it, so `$lax->strict` dies with "Can't locate object method").

- [ ] **Step 3: Add the attribute and localize the flag in `lib/IO/K8s.pm`**

After the `has with => (...)` block add:

```perl
# Unknown-field policy for this instance's entry points (D1). 0: a field no
# class declares is kept and emitted again by TO_JSON. 1: it dies naming the
# class and the field. Applied by localizing $IO::K8s::Resource::STRICT in
# inflate, new_object, json_to_object and struct_to_object, so it reaches
# every nested constructor -- including the inline-struct coercers, which
# never pass through _inflate_struct. load and load_yaml inherit it through
# new_object / inflate.
has strict => (
    is      => 'ro',
    default => sub { 0 },
);
```

Insert `local $IO::K8s::Resource::STRICT = $self->strict;` as the first statement (after the `my (...) = @_;` line) of each of these four subs: `inflate`, `new_object`, `json_to_object`, `struct_to_object`. Example for `inflate`:

```perl
sub inflate {
    my ($self, $data) = @_;
    local $IO::K8s::Resource::STRICT = $self->strict;

    # Accept both JSON string and hashref
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `prove -l t/67_strict.t`
Expected: PASS.

- [ ] **Step 5: Run the full suite**

Run: `prove -lr t/`
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/IO/K8s.pm t/67_strict.t
git commit -m "Add strict => 1 to IO::K8s: unknown fields die instead of being kept (D1)"
```

---

### Task 3: Object-aware `SpecBuilder` (D2, k90)

**Lane:** `io-k8s-worker` for `lib/`, `io-k8s-test-writer` for the test.

**Files:**
- Rewrite: `lib/IO/K8s/Role/SpecBuilder.pm` (code section; keep the existing `=method` POD blocks and update their wording per Task 5)
- Test: `t/68_specbuilder_objects.t`
- Regression: `t/15_role_specbuilder.t` must stay green unchanged.

**Interfaces:**
- Consumes: `_k8s_attr_info` (registry view, `IO::K8s::Role::Resource`), `_unknown_fields` (Task 1), `IO::K8s::Role::Resource::_default_k8s()->_struct_to_object_expanded($class, $hashref)`.
- Produces: `spec_get($path)`, `spec_set($path, $value)`, `spec_push($path, @values)`, `spec_merge(%pairs)`, `spec_delete($path)` -- all chainable except `spec_get` -- plus new `spec_array($path)` and `spec_hash($path)` returning the vivified container at `$path`. Path segments: dot-separated; an integer segment indexes an array; `-1` means the last element, or a freshly created one on an empty array; other negative indices croak. Task 4 relies on all of these.

- [ ] **Step 1: Write the failing test**

Create `t/68_specbuilder_objects.t`:

```perl
#!/usr/bin/env perl
# D2: SpecBuilder on typed specs -- inline structs, referenced classes,
# arrays of objects -- plus the k90 regression and the unchanged hash path.
use strict;
use warnings;
use Test::More;
use Test::Exception;

use IO::K8s;

{
    package TestSB::Route;
    use IO::K8s::Resource;
    k8s match    => Str;
    k8s priority => Int;
}

{
    package TestSB::Widget;
    use IO::K8s::APIObject
        api_version     => 'test.example.com/v1',
        resource_plural => 'widgets';
    with 'IO::K8s::Role::Namespaced';

    k8s spec => {
        replicas => Int,
        tls      => { secretName => Str, options => { Str => 1 } },
        routes   => ['+TestSB::Route'],
        template => 'Core::V1::PodTemplateSpec',
        labels   => { Str => 1 },
        '$ref'   => Str,
    };
}

sub widget {
    my (%spec) = @_;
    return TestSB::Widget->new(
        metadata => IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::ObjectMeta->new(name => 'w'),
        (%spec ? (spec => \%spec) : ()),
    );
}

subtest 'k90: spec_set on a modeled spec keeps the spec' => sub {
    my $k8s = IO::K8s->new(with => ['IO::K8s::AgentSandbox']);
    my $s = $k8s->new_object('Sandbox',
        metadata => { name => 'x', namespace => 'd' },
        spec     => { shutdownPolicy => 'Retain' },
    );
    is($s->spec_get('shutdownPolicy'), 'Retain', 'spec_get reads through the struct');
    $s->spec_set('shutdownPolicy', 'Delete');
    is($s->TO_JSON->{spec}{shutdownPolicy}, 'Delete', 'spec_set writes through the struct');
    isa_ok($s->spec, 'IO::K8s::AgentSandbox::V1beta1::Sandbox::_Spec', 'spec is still the struct');
    $s->spec_merge(operatingMode => 'Standard');
    is_deeply($s->TO_JSON->{spec}, { shutdownPolicy => 'Delete', operatingMode => 'Standard' }, 'spec_merge keeps existing fields');
};

subtest 'spec_get walks structs, objects and arrays' => sub {
    my $w = widget(
        replicas => 2,
        tls      => { secretName => 's', options => { minVersion => '1.2' } },
        routes   => [ { match => 'a', priority => 1 }, { match => 'b', priority => 2 } ],
    );
    is($w->spec_get('replicas'), 2, 'scalar');
    is($w->spec_get('tls.secretName'), 's', 'inline struct field');
    is($w->spec_get('tls.options.minVersion'), '1.2', 'opaque map under a struct');
    is($w->spec_get('routes.1.match'), 'b', 'array index into objects');
    is($w->spec_get('routes.-1.priority'), 2, '-1 is the last element');
    isa_ok($w->spec_get('routes.0'), 'TestSB::Route', 'an object node is returned as is');
    is($w->spec_get('nope'), undef, 'undeclared, unset');
    is($w->spec_get('tls.nope'), undef, 'undeclared nested, unset');
    is($w->spec_get('replicas.deeper'), undef, 'cannot descend a scalar on read');
};

subtest 'spec_set vivifies typed intermediates' => sub {
    my $w = widget();
    ok(!$w->spec, 'starts without spec');
    $w->spec_set('tls.secretName', 'x');
    isa_ok($w->spec, 'TestSB::Widget::_Spec', 'spec vivified as the declared struct');
    isa_ok($w->spec->tls, 'TestSB::Widget::_Spec::_Tls', 'tls vivified as its struct');
    is($w->TO_JSON->{spec}{tls}{secretName}, 'x', 'and the value is on the wire');

    $w->spec_set('template.spec.containers.0.name', 'c');
    isa_ok($w->spec->template, 'IO::K8s::Api::Core::V1::PodTemplateSpec', 'referenced class vivified');
    isa_ok($w->spec->template->spec->containers->[0], 'IO::K8s::Api::Core::V1::Container', 'array element vivified as the element class');
    is($w->spec_get('template.spec.containers.0.name'), 'c', 'deep write reads back');

    $w->spec_set('labels.app', 'web');
    is_deeply($w->spec->labels, { app => 'web' }, 'opaque map vivified as a hash');

    $w->spec_set('$ref', 'r');
    is($w->TO_JSON->{spec}{'$ref'}, 'r', 'a sanitized JSON key is addressed by its JSON name');
};

subtest 'spec_set through typed slots validates and inflates' => sub {
    my $w = widget();
    throws_ok { $w->spec_set('replicas', 'abc') } qr/replicas|Int/, 'type constraint of the declared field applies';
    $w->spec_set('tls', { secretName => 'y' });
    isa_ok($w->spec->tls, 'TestSB::Widget::_Spec::_Tls', 'a hashref handed to a struct slot is inflated');
    $w->spec_set('routes', [ { match => 'm', priority => 3 } ]);
    isa_ok($w->spec->routes->[0], 'TestSB::Route', 'hashrefs handed to an array-of-objects slot are inflated');
    throws_ok { $w->spec_set('replicas.deeper', 1) } qr/cannot descend through scalar field 'replicas'/, 'descending a scalar on write croaks';
};

subtest 'spec_push onto arrays of objects' => sub {
    my $w = widget();
    $w->spec_push('routes', { match => 'a', priority => 1 }, TestSB::Route->new(match => 'b', priority => 2));
    isa_ok($w->spec->routes->[0], 'TestSB::Route', 'hashref element inflated');
    isa_ok($w->spec->routes->[1], 'TestSB::Route', 'object element kept');
    is($w->spec_get('routes.-1.match'), 'b', 'pushed in order');
    $w->spec_set('routes.-1.priority', 9);
    is($w->spec->routes->[1]->priority, 9, '-1 writes the last element');
};

subtest '-1 on an empty array creates the element' => sub {
    my $w = widget();
    $w->spec_set('routes.-1.match', 'first');
    is(scalar @{ $w->spec->routes }, 1, 'one element created');
    isa_ok($w->spec->routes->[0], 'TestSB::Route', 'as the element class');
    is($w->spec_get('routes.0.match'), 'first', 'with the value');
    throws_ok { $w->spec_set('routes.-3.match', 'x') } qr/index -3/, 'other negative indices are out of range';
};

subtest 'undeclared keys on a struct land in the bag (D1)' => sub {
    my $w = widget(replicas => 1);
    $w->spec_set('bogus.deep', 1);
    is($w->TO_JSON->{spec}{bogus}{deep}, 1, 'written through the bag and emitted');
    is($w->spec_get('bogus.deep'), 1, 'and readable');
    $w->spec_delete('bogus');
    ok(!exists $w->TO_JSON->{spec}{bogus}, 'spec_delete removes a bag entry');
};

subtest 'spec_delete on structs and arrays' => sub {
    my $w = widget(replicas => 1, tls => { secretName => 's' }, routes => [ { match => 'a' }, { match => 'b' } ]);
    $w->spec_delete('tls.secretName');
    is($w->spec->tls->secretName, undef, 'declared field cleared');
    $w->spec_delete('routes.0');
    is($w->spec_get('routes.0.match'), 'b', 'array element spliced');
    $w->spec_delete('nothing.here');
    pass('missing path is a no-op');
};

subtest 'spec_merge on a struct: declared and undeclared' => sub {
    my $w = widget(replicas => 1);
    $w->spec_merge(replicas => 5, extra => 'e');
    is($w->spec->replicas, 5, 'declared field set through the accessor');
    is($w->TO_JSON->{spec}{extra}, 'e', 'undeclared field preserved');
};

subtest 'spec_array and spec_hash vivify and return the container' => sub {
    my $w = widget();
    my $routes = $w->spec_array('routes');
    is(ref $routes, 'ARRAY', 'array vivified');
    is($routes, $w->spec->routes, 'and it is the attribute value itself');
    my $labels = $w->spec_hash('labels');
    $labels->{a} = 'b';
    is($w->TO_JSON->{spec}{labels}{a}, 'b', 'in-place edits of the returned hash reach the wire');
    isa_ok($w->spec_hash('tls'), 'TestSB::Widget::_Spec::_Tls', 'spec_hash on a struct slot returns the struct');
    throws_ok { $w->spec_array('replicas') } qr/holds a non-array value|replicas/, 'spec_array on a scalar slot croaks';
};

subtest 'plain hash specs behave as before' => sub {
    require IO::K8s::Traefik::V1alpha1::IngressRoute;
    my $ir = IO::K8s::Traefik::V1alpha1::IngressRoute->new(
        metadata => IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::ObjectMeta->new(name => 'r'),
    );
    $ir->spec_set('routes.-1.match', 'Host(`a`)');
    $ir->spec_push('routes.-1.services', { name => 'svc', port => 80 });
    is_deeply($ir->spec, { routes => [ { match => 'Host(`a`)', services => [ { name => 'svc', port => 80 } ] } ] }, 'hash path with -1 vivification');
    is_deeply($ir->spec_array('entryPoints'), [], 'spec_array on a hash spec');
};

done_testing;
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `prove -l t/68_specbuilder_objects.t`
Expected: FAIL -- the k90 subtest fails (`spec_get` returns undef, `TO_JSON` shows `spec: {}`), `spec_array`/`spec_hash` are unknown methods.

- [ ] **Step 3: Rewrite the code section of `lib/IO/K8s/Role/SpecBuilder.pm`**

Replace everything from `use Moo::Role;` down to (but not including) the final `1;` / `__END__` with the code below. Keep each existing `=method` POD block in front of its method (update the wording in Task 5), and add `=method spec_array` / `=method spec_hash` blocks with the two-line signature + one paragraph in the same style.

```perl
use Moo::Role;
use Scalar::Util qw(blessed);
use Carp qw(croak);
use Module::Runtime qw(use_module);

# ---------------------------------------------------------------------------
# A node on a spec path is one of: a plain hashref, a plain arrayref, or an
# IO::K8s object (anything composing IO::K8s::Role::Resource). Segments are
# dot-separated. An integer segment indexes an array; -1 is the last element,
# or the one created on an empty array. Anything else is a hash key or, on an
# object, a JSON field name mapped to its attribute through the registry (so
# '$ref' reaches _ref). A field an object does not declare lives in its
# _unknown_fields bag (D1) and is reachable like any other key.
#
# Before 1.109 every method assumed spec was a hashref: on a modeled spec
# spec_set replaced the struct with {} and wrote into an orphan (k90).
# ---------------------------------------------------------------------------

sub _sb_is_obj { blessed($_[0]) && $_[0]->can('_k8s_attr_info') }

sub _sb_is_index { defined $_[0] && $_[0] =~ /\A-?\d+\z/ }

# JSON key -> (attribute name, registry info) on an object; empty list when
# the object declares no such field.
sub _sb_attr {
    my ($node, $key) = @_;
    my $info = $node->_k8s_attr_info;
    for my $attr (keys %$info) {
        return ($attr, $info->{$attr}) if ($info->{$attr}{json_key} // $attr) eq $key;
    }
    return;
}

# Resolve an index against an array for writing. -1 on an empty array is the
# slot a new element goes into; any other index outside the array croaks
# rather than letting Perl autovivify a hole or die on a negative subscript.
sub _sb_index {
    my ($array, $seg, $path) = @_;
    croak "spec path '$path': '$seg' is not an array index" unless _sb_is_index($seg);
    return $seg if $seg >= 0 && $seg <= @$array;
    return 0 if $seg == -1 && !@$array;
    my $resolved = @$array + $seg;
    croak "spec path '$path': index $seg is out of range for an array of " . scalar(@$array)
        if $seg < 0 && $resolved < 0;
    croak "spec path '$path': index $seg is beyond the end of an array of " . scalar(@$array)
        if $seg > @$array;
    return $resolved;
}

# Read one segment. Returns the child, or undef when it is not there. Never
# creates anything.
sub _sb_child {
    my ($node, $seg) = @_;
    if (_sb_is_obj($node)) {
        my ($attr) = _sb_attr($node, $seg);
        return $node->$attr if defined $attr;
        return $node->_unknown_fields->{$seg};
    }
    if (ref $node eq 'ARRAY') {
        return undef unless _sb_is_index($seg);
        return undef if $seg < -@$node || $seg > $#$node;
        return $node->[$seg];
    }
    return $node->{$seg} if ref $node eq 'HASH';
    return undef;
}

# Hand a plain hashref (or an array/hash of them) to a typed slot as objects.
# Uses the shared default IO::K8s instance the way FROM_HASH does: registry
# class names are already fully expanded, so no per-instance resolution is
# involved. Scalars and already-blessed values pass through.
sub _sb_inflate {
    my ($info, $value) = @_;
    return $value unless $info && ref $value;
    my $k8s = IO::K8s::Role::Resource::_default_k8s();
    if ($info->{is_object}) {
        return ref $value eq 'HASH'
            ? $k8s->_struct_to_object_expanded($info->{class}, $value)
            : $value;
    }
    if ($info->{is_array_of_objects} && ref $value eq 'ARRAY') {
        return [ map { _sb_elem($info->{class}, $_) } @$value ];
    }
    if ($info->{is_hash_of_objects} && ref $value eq 'HASH') {
        return { map { $_ => _sb_elem($info->{class}, $value->{$_}) } keys %$value };
    }
    return $value;
}

# One element of an array/hash of objects: a hashref becomes $elem_class.
sub _sb_elem {
    my ($elem_class, $value) = @_;
    return $value unless $elem_class && ref $value eq 'HASH';
    return IO::K8s::Role::Resource::_default_k8s()->_struct_to_object_expanded($elem_class, $value);
}

# Store $value under $seg of $node. A declared field on an object goes
# through its accessor (hashrefs inflated first, so the type constraint sees
# an object); an undeclared one goes into the _unknown_fields bag. Returns
# the value as stored.
sub _sb_store {
    my ($node, $seg, $value, $path, $elem_class) = @_;
    if (_sb_is_obj($node)) {
        my ($attr, $info) = _sb_attr($node, $seg);
        if (defined $attr) {
            $value = _sb_inflate($info, $value);
            $node->$attr($value);
            return $value;
        }
        return $node->_unknown_fields->{$seg} = $value;
    }
    if (ref $node eq 'ARRAY') {
        my $i = _sb_index($node, $seg, $path);
        return $node->[$i] = _sb_elem($elem_class, $value);
    }
    if (ref $node eq 'HASH') {
        return $node->{$seg} = _sb_elem($elem_class, $value);
    }
    croak "spec path '$path': cannot store '$seg' in a " . (ref($node) || 'scalar');
}

# The class of the elements under an array/hash-of-objects field, when the
# node is an object and the field is one; undef otherwise.
sub _sb_elem_class {
    my ($node, $seg) = @_;
    return undef unless _sb_is_obj($node);
    my (undef, $info) = _sb_attr($node, $seg);
    return undef unless $info;
    return $info->{class} if $info->{is_array_of_objects} || $info->{is_hash_of_objects};
    return undef;
}

# What to create in an empty slot so a walk can continue. On an object the
# registry decides: the declared class for a struct/object field, [] or {}
# for the container forms, croak for a scalar. Inside an array or hash of
# objects the element class. Elsewhere the next segment decides: an index
# means an array, anything else a hash.
sub _sb_fresh {
    my ($node, $seg, $next, $elem_class, $path) = @_;
    if (_sb_is_obj($node)) {
        my (undef, $info) = _sb_attr($node, $seg);
        if ($info) {
            return use_module($info->{class})->new if $info->{is_object};
            return [] if grep { $info->{$_} } qw(
                is_array_of_objects is_array_of_str is_array_of_int
                is_array_of_bool is_array_of_hash is_array_of_array
            );
            return {} if grep { $info->{$_} } qw(
                is_hash_of_str is_hash_of_objects is_hash_of_int is_hash_of_num
                is_hash_of_bool is_hash_of_quantity is_hash_of_time
                is_hash_of_int_or_string
            );
            croak "spec path '$path': cannot descend through scalar field '$seg'";
        }
    }
    return use_module($elem_class)->new if $elem_class;
    return _sb_is_index($next) ? [] : {};
}

# The spec node. With $vivify, create it when missing: the declared class
# when spec is a typed field of this object, a plain hash otherwise.
sub _sb_root {
    my ($self, $vivify) = @_;
    my $spec = $self->spec;
    return $spec if ref $spec;
    return undef unless $vivify;
    my (undef, $info) = _sb_is_obj($self) ? _sb_attr($self, 'spec') : ();
    $spec = $info && $info->{is_object} ? use_module($info->{class})->new : {};
    $self->spec($spec);
    return $spec;
}

# Walk to the parent of the last segment, creating what is missing. Returns
# ($parent, $last_segment, $elem_class): $elem_class names the class a new
# element of $parent must be when $parent is an array or hash of objects.
sub _sb_walk_vivify {
    my ($self, $path) = @_;
    my @segs = split /\./, $path;
    my $last = pop @segs;
    croak "spec path '$path' is empty" unless defined $last && length $last;
    my $node = $self->_sb_root(1);
    my $elem_class;
    for my $i (0 .. $#segs) {
        my $seg  = $segs[$i];
        my $next = $i < $#segs ? $segs[$i + 1] : $last;
        my $child = _sb_child($node, $seg);
        if (defined $child && !ref $child) {
            croak "spec path '$path': cannot descend through scalar field '$seg'";
        }
        my $child_elem_class = _sb_elem_class($node, $seg);
        unless (ref $child) {
            $child = _sb_fresh($node, $seg, $next, $elem_class, $path);
            $child = _sb_store($node, $seg, $child, $path, $elem_class);
        }
        # Elements of a container we just entered are typed only when the
        # object we came from declared the container as one of objects.
        $elem_class = $child_elem_class;
        $node = $child;
    }
    return ($node, $last, $elem_class);
}

sub spec_get {
    my ($self, $path) = @_;
    my $node = $self->_sb_root(0);
    return undef unless ref $node;
    for my $seg (split /\./, $path) {
        return undef unless ref $node;
        $node = _sb_child($node, $seg);
        return undef unless defined $node;
    }
    return $node;
}

sub spec_set {
    my ($self, $path, $value) = @_;
    my ($parent, $last, $elem_class) = $self->_sb_walk_vivify($path);
    _sb_store($parent, $last, $value, $path, $elem_class);
    return $self;
}

sub spec_array {
    my ($self, $path) = @_;
    my ($parent, $last, $elem_class) = $self->_sb_walk_vivify($path);
    my $array = _sb_child($parent, $last);
    return $array if ref $array eq 'ARRAY';
    croak "spec path '$path': '$last' holds a non-array value" if defined $array;
    return _sb_store($parent, $last, [], $path, $elem_class);
}

sub spec_hash {
    my ($self, $path) = @_;
    my ($parent, $last, $elem_class) = $self->_sb_walk_vivify($path);
    my $node = _sb_child($parent, $last);
    return $node if ref $node;
    croak "spec path '$path': '$last' holds a scalar" if defined $node;
    my $fresh = _sb_fresh($parent, $last, undef, $elem_class, $path);
    return _sb_store($parent, $last, $fresh, $path, $elem_class);
}

sub spec_push {
    my ($self, $path, @values) = @_;
    my $array = $self->spec_array($path);
    my ($parent, $last) = $self->_sb_walk_vivify($path);
    my $item_class = _sb_elem_class($parent, $last);
    push @$array, map { _sb_elem($item_class, $_) } @values;
    return $self;
}

sub spec_merge {
    my ($self, %data) = @_;
    my $root = $self->_sb_root(1);
    _sb_store($root, $_, $data{$_}, $_) for keys %data;
    return $self;
}

sub spec_delete {
    my ($self, $path) = @_;
    my $node = $self->_sb_root(0);
    return $self unless ref $node;
    my @segs = split /\./, $path;
    my $last = pop @segs;
    for my $seg (@segs) {
        $node = _sb_child($node, $seg);
        return $self unless ref $node;
    }
    if (_sb_is_obj($node)) {
        my ($attr) = _sb_attr($node, $last);
        if (defined $attr) {
            $node->$attr(undef);
        } else {
            delete $node->_unknown_fields->{$last};
        }
    } elsif (ref $node eq 'ARRAY') {
        return $self unless _sb_is_index($last) && @$node;
        return $self if $last < -@$node || $last > $#$node;
        splice @$node, $last, 1;
    } elsif (ref $node eq 'HASH') {
        delete $node->{$last};
    }
    return $self;
}
```

Notes for the implementer:
- `_sb_fresh`'s scalar-field croak wording must match the test regex `cannot descend through scalar field 'replicas'`; `_sb_index`'s out-of-range wording must contain `index -3`.
- `spec_push` walks twice (once inside `spec_array`, once for the element class). That is deliberate simplicity; both walks are idempotent after the first.
- `Module::Runtime::use_module` on an inline struct class (already in memory, no file) works because `use_module` returns early when the package is loaded; inline struct packages set `$INC`-free packages -- if `use_module` complains about a missing file for `TestSB::Widget::_Spec`, replace `use_module($class)->new` with `($class->can('new') ? $class : use_module($class))->new` in both places and note it in the commit.

- [ ] **Step 4: Run the new test and the old one**

Run: `prove -l t/68_specbuilder_objects.t t/15_role_specbuilder.t`
Expected: both PASS.

- [ ] **Step 5: Run the full suite**

Run: `prove -lr t/`
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/IO/K8s/Role/SpecBuilder.pm t/68_specbuilder_objects.t
git commit -m "Make SpecBuilder object-aware: walk typed specs through the registry (D2, k90)"
```

---

### Task 4: Builder roles on `SpecBuilder` (D2)

**Lane:** `io-k8s-worker` for `lib/`, `io-k8s-test-writer` for the test.

**Files:**
- Modify: `lib/IO/K8s/Role/CertManaged.pm`, `HelmManaged.pm`, `MiddlewareBuilder.pm`, `Loadbalanced.pm`, `Routable.pm` (only the `gateway` and `traefik` branches), `NetworkPolicy.pm` (only the `cilium` branches and `_add_cilium_ingress_rule`)
- Test: `t/69_builder_roles_on_structs.t`
- Regression: `t/16_role_netpol.t`, `t/17_role_routable.t`, `t/18_role_certmanaged.t`, `t/19_role_helm.t` unchanged and green.

**Interfaces:**
- Consumes: `spec_get`, `spec_set`, `spec_push`, `spec_hash`, `spec_array` (Task 3).
- Produces: no new public methods; every existing builder method keeps its signature and its wire output on a hash spec.

The transformation rule, applied to every method below: `my $spec = $self->spec // {}; ... $self->spec($spec)` becomes the equivalent `SpecBuilder` call; `$x //= [{}]; $x->[-1]` becomes a `-1` path segment; `$h //= {}` followed by key writes becomes `spec_hash`. The `core` / `ingress` branches that already build typed core objects stay exactly as they are.

- [ ] **Step 1: Write the failing test**

Create `t/69_builder_roles_on_structs.t`:

```perl
#!/usr/bin/env perl
# D2: every builder role works on a modeled (inline-struct / object) spec.
# The hash-spec behaviour of the same roles is covered by t/16-t/19.
use strict;
use warnings;
use Test::More;

use IO::K8s;
use IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::ObjectMeta;

sub meta { IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::ObjectMeta->new(name => $_[0], namespace => 'd') }

# --- classes -------------------------------------------------------------

{
    package TestBR::Cert;
    use IO::K8s::APIObject api_version => 'cert-manager.io/v1', resource_plural => 'certificates';
    with 'IO::K8s::Role::Namespaced', 'IO::K8s::Role::CertManaged';
    k8s spec => {
        dnsNames    => [Str],
        ipAddresses => [Str],
        secretName  => Str,
        renewBefore => Str,
        issuerRef   => { name => Str, kind => Str, group => Str },
    };
}

{
    package TestBR::Solver;
    use IO::K8s::Resource;
    k8s http01 => { Str => 1 };
    k8s dns01  => { Str => 1 };
}

{
    package TestBR::Issuer;
    use IO::K8s::APIObject api_version => 'cert-manager.io/v1', resource_plural => 'issuers';
    with 'IO::K8s::Role::Namespaced', 'IO::K8s::Role::CertManaged';
    k8s spec => {
        acme       => { email => Str, server => Str, privateKeySecretRef => { name => Str }, solvers => ['+TestBR::Solver'] },
        selfSigned => { Str => 1 },
        ca         => { secretName => Str },
    };
}

{
    package TestBR::Chart;
    use IO::K8s::APIObject api_version => 'helm.cattle.io/v1', resource_plural => 'helmcharts';
    with 'IO::K8s::Role::Namespaced', 'IO::K8s::Role::HelmManaged';
    k8s spec => {
        repo          => Str,
        chart         => Str,
        version       => Str,
        set           => { Str => 1 },
        valuesContent => Str,
    };
}

{
    package TestBR::Middleware;
    use IO::K8s::APIObject api_version => 'traefik.io/v1alpha1', resource_plural => 'middlewares';
    with 'IO::K8s::Role::Namespaced', 'IO::K8s::Role::MiddlewareBuilder';
    k8s spec => {
        rateLimit      => { average => Int, burst => Int, period => Str },
        basicAuth      => { secret => Str, realm => Str },
        stripPrefix    => { prefixes => [Str] },
        redirectScheme => { scheme => Str, permanent => Bool },
        headers        => { customRequestHeaders => { Str => 1 }, customResponseHeaders => { Str => 1 } },
    };
}

{
    package TestBR::WSvc;
    use IO::K8s::Resource;
    k8s name   => Str;
    k8s weight => Int;
}

{
    package TestBR::Mirror;
    use IO::K8s::Resource;
    k8s name    => Str;
    k8s percent => Int;
}

{
    package TestBR::TraefikService;
    use IO::K8s::APIObject api_version => 'traefik.io/v1alpha1', resource_plural => 'traefikservices';
    with 'IO::K8s::Role::Namespaced', 'IO::K8s::Role::Loadbalanced';
    k8s spec => {
        weighted  => { services => ['+TestBR::WSvc'] },
        mirroring => { mirrors => ['+TestBR::Mirror'] },
    };
}

{
    package TestBR::BackendRef;
    use IO::K8s::Resource;
    k8s name   => Str;
    k8s port   => Int;
    k8s weight => Int;
}

{
    package TestBR::HeaderMatch;
    use IO::K8s::Resource;
    k8s name  => Str;
    k8s value => Str;
}

{
    package TestBR::Match;
    use IO::K8s::Resource;
    k8s path    => { type => Str, value => Str };
    k8s headers => ['+TestBR::HeaderMatch'];
}

{
    package TestBR::Rule;
    use IO::K8s::Resource;
    k8s backendRefs => ['+TestBR::BackendRef'];
    k8s matches     => ['+TestBR::Match'];
}

{
    package TestBR::HTTPRoute;
    use IO::K8s::APIObject api_version => 'gateway.networking.k8s.io/v1', resource_plural => 'httproutes';
    with 'IO::K8s::Role::Namespaced', 'IO::K8s::Role::Routable';
    sub _route_format { 'gateway' }
    k8s spec => {
        hostnames => [Str],
        rules     => ['+TestBR::Rule'],
    };
}

{
    package TestBR::TRoute;
    use IO::K8s::Resource;
    k8s match    => Str;
    k8s kind     => Str;
    k8s services => [ {} ];
}

{
    package TestBR::IngressRoute;
    use IO::K8s::APIObject api_version => 'traefik.io/v1alpha1', resource_plural => 'ingressroutes';
    with 'IO::K8s::Role::Namespaced', 'IO::K8s::Role::Routable';
    sub _route_format { 'traefik' }
    k8s spec => {
        routes => ['+TestBR::TRoute'],
    };
}

{
    package TestBR::CNPRule;
    use IO::K8s::Resource;
    k8s fromEndpoints => [ {} ];
    k8s toEndpoints   => [ {} ];
    k8s fromCIDR      => [Str];
    k8s toCIDR        => [Str];
    k8s toPorts       => [ {} ];
}

{
    package TestBR::CNP;
    use IO::K8s::APIObject api_version => 'cilium.io/v2', resource_plural => 'ciliumnetworkpolicies';
    with 'IO::K8s::Role::Namespaced', 'IO::K8s::Role::NetworkPolicy';
    sub _netpol_format { 'cilium' }
    k8s spec => {
        endpointSelector => { matchLabels => { Str => 1 } },
        ingress          => ['+TestBR::CNPRule'],
        egress           => ['+TestBR::CNPRule'],
        ingressDeny      => [ {} ],
        egressDeny       => [ {} ],
    };
}

# --- tests ---------------------------------------------------------------

subtest 'CertManaged on a modeled Certificate' => sub {
    my $c = TestBR::Cert->new(metadata => meta('c'));
    $c->for_domains('a.example', 'b.example')
      ->with_issuer('le', kind => 'ClusterIssuer')
      ->store_in_secret('tls')
      ->add_ip_san('10.0.0.1')
      ->renew_before(days => 2);
    my $spec = $c->TO_JSON->{spec};
    is_deeply($spec->{dnsNames}, [ 'a.example', 'b.example' ], 'dnsNames');
    is_deeply($spec->{issuerRef}, { name => 'le', kind => 'ClusterIssuer', group => 'cert-manager.io' }, 'issuerRef');
    is($c->spec->issuerRef->kind, 'ClusterIssuer', 'issuerRef is the struct');
    is($spec->{secretName}, 'tls', 'secretName');
    is_deeply($spec->{ipAddresses}, [ '10.0.0.1' ], 'ipAddresses');
    is($spec->{renewBefore}, '48h0m0s', 'renewBefore');
    $c->for_domains('c.example');
    is(scalar @{ $spec = $c->TO_JSON->{spec}; $spec->{dnsNames} }, 3, 'for_domains appends');
};

subtest 'CertManaged on a modeled Issuer' => sub {
    my $i = TestBR::Issuer->new(metadata => meta('i'));
    $i->letsencrypt(email => 'me@example', production => 1)
      ->add_http01_solver(class => 'traefik')
      ->add_dns01_solver(provider => 'cloudflare', secret => 'cf');
    my $acme = $i->TO_JSON->{spec}{acme};
    is($acme->{server}, 'https://acme-v02.api.letsencrypt.org/directory', 'production server');
    is($acme->{privateKeySecretRef}{name}, 'letsencrypt-account-key', 'default account key');
    is(scalar @{ $acme->{solvers} }, 2, 'two solvers');
    isa_ok($i->spec->acme->solvers->[0], 'TestBR::Solver', 'solver inflated to its class');
    is($acme->{solvers}[0]{http01}{ingress}{class}, 'traefik', 'http01 solver');
    is($acme->{solvers}[1]{dns01}{cloudflare}{apiTokenSecretRef}{name}, 'cf', 'dns01 solver');
    my $s = TestBR::Issuer->new(metadata => meta('s'))->self_signed;
    is_deeply($s->TO_JSON->{spec}{selfSigned}, {}, 'self_signed');
    my $ca = TestBR::Issuer->new(metadata => meta('ca'))->ca(secret => 'root');
    is($ca->TO_JSON->{spec}{ca}{secretName}, 'root', 'ca');
};

subtest 'HelmManaged on a modeled HelmChart' => sub {
    my $h = TestBR::Chart->new(metadata => meta('h'));
    $h->from_repo('https://charts.example', 'app')->set_version('1.2.3')
      ->set_values('image.tag' => 'v1', replicas => 3)
      ->set_values_yaml("a: 1\n");
    my $spec = $h->TO_JSON->{spec};
    is($spec->{repo}, 'https://charts.example', 'repo');
    is($spec->{chart}, 'app', 'chart');
    is($spec->{version}, '1.2.3', 'version');
    is_deeply($spec->{set}, { 'image.tag' => 'v1', replicas => 3 }, 'set keeps dotted keys intact');
    $h->set_values(replicas => 4);
    is($h->TO_JSON->{spec}{set}{replicas}, 4, 'set_values merges');
    is($spec->{valuesContent}, "a: 1\n", 'valuesContent');
};

subtest 'MiddlewareBuilder on a modeled Middleware' => sub {
    my $m = TestBR::Middleware->new(metadata => meta('m'));
    $m->rate_limit(average => 100, burst => 200)
      ->basic_auth(secret => 'users', realm => 'r')
      ->strip_prefix('/api', '/v1')
      ->redirect_https
      ->add_request_header('X-A' => '1')
      ->add_request_header('X-B' => '2')
      ->add_response_header('X-C' => '3');
    my $spec = $m->TO_JSON->{spec};
    is_deeply($spec->{rateLimit}, { average => 100, burst => 200 }, 'rateLimit');
    is($m->spec->rateLimit->average, 100, 'rateLimit is the struct');
    is_deeply($spec->{basicAuth}, { secret => 'users', realm => 'r' }, 'basicAuth');
    is_deeply($spec->{stripPrefix}{prefixes}, [ '/api', '/v1' ], 'stripPrefix');
    is($spec->{redirectScheme}{scheme}, 'https', 'redirectScheme');
    ok($spec->{redirectScheme}{permanent}, 'permanent is true');
    is_deeply($spec->{headers}{customRequestHeaders}, { 'X-A' => '1', 'X-B' => '2' }, 'request headers accumulate');
    is_deeply($spec->{headers}{customResponseHeaders}, { 'X-C' => '3' }, 'response headers');
};

subtest 'Loadbalanced on a modeled TraefikService' => sub {
    my $t = TestBR::TraefikService->new(metadata => meta('t'));
    $t->set_weighted('a', 10)->set_weighted('b', 20)->set_weighted('a', 30)->mirror_to('m', percent => 5);
    my $spec = $t->TO_JSON->{spec};
    is_deeply($spec->{weighted}{services}, [ { name => 'a', weight => 30 }, { name => 'b', weight => 20 } ], 'update-or-add');
    isa_ok($t->spec->weighted->services->[0], 'TestBR::WSvc', 'service inflated');
    is_deeply($spec->{mirroring}{mirrors}, [ { name => 'm', percent => 5 } ], 'mirror_to');
};

subtest 'Routable (gateway) on a modeled HTTPRoute' => sub {
    my $r = TestBR::HTTPRoute->new(metadata => meta('r'));
    $r->add_hostname('example.com')
      ->add_path_match('/api', type => 'PathPrefix')
      ->add_header_match('X-Env' => 'prod')
      ->add_backend('api-v1', port => 8080, weight => 90);
    my $spec = $r->TO_JSON->{spec};
    is_deeply($spec->{hostnames}, [ 'example.com' ], 'hostnames');
    is(scalar @{ $spec->{rules} }, 1, 'one rule vivified by -1');
    isa_ok($r->spec->rules->[0], 'TestBR::Rule', 'rule inflated');
    is_deeply($spec->{rules}[0]{matches}, [ { path => { type => 'PathPrefix', value => '/api' }, headers => [ { name => 'X-Env', value => 'prod' } ] } ], 'matches with header on the last match');
    is_deeply($spec->{rules}[0]{backendRefs}, [ { name => 'api-v1', port => 8080, weight => 90 } ], 'backendRefs');
};

subtest 'Routable (traefik) on a modeled IngressRoute' => sub {
    my $r = TestBR::IngressRoute->new(metadata => meta('r'));
    $r->add_hostname('example.com')->add_path_match('/api')->add_header_match('X-A' => 'b')->add_backend('svc', port => 80);
    my $routes = $r->TO_JSON->{spec}{routes};
    is(scalar @$routes, 1, 'one route');
    is($routes->[0]{match}, 'PathPrefix(`/api`) && Header(`X-A`, `b`)', 'match rule rewritten then extended');
    is_deeply($routes->[0]{services}, [ { name => 'svc', port => 80 } ], 'services');
};

subtest 'NetworkPolicy (cilium) on a modeled CiliumNetworkPolicy' => sub {
    my $p = TestBR::CNP->new(metadata => meta('p'));
    $p->select_pods(app => 'web')
      ->allow_ingress_from_pods({ app => 'nginx' }, ports => [ { port => '8080', protocol => 'TCP' } ])
      ->allow_ingress_from_cidrs([ '10.0.0.0/8' ])
      ->allow_ingress_from_namespace('other')
      ->allow_egress_to_pods({ app => 'db' })
      ->allow_egress_to_cidrs([ '0.0.0.0/0' ])
      ->allow_egress_to_dns;
    my $spec = $p->TO_JSON->{spec};
    is_deeply($spec->{endpointSelector}, { matchLabels => { app => 'web' } }, 'endpointSelector');
    is(scalar @{ $spec->{ingress} }, 3, 'three ingress rules');
    isa_ok($p->spec->ingress->[0], 'TestBR::CNPRule', 'rule inflated');
    is_deeply($spec->{ingress}[0]{fromEndpoints}, [ { matchLabels => { app => 'nginx' } } ], 'from pods');
    is_deeply($spec->{ingress}[0]{toPorts}, [ { ports => [ { port => '8080', protocol => 'TCP' } ] } ], 'ports');
    is_deeply($spec->{ingress}[1]{fromCIDR}, [ '10.0.0.0/8' ], 'from cidrs');
    is_deeply($spec->{ingress}[2]{fromEndpoints}[0]{matchLabels}, { 'k8s:io.kubernetes.pod.namespace' => 'other' }, 'from namespace');
    is(scalar @{ $spec->{egress} }, 3, 'three egress rules');
    is_deeply($spec->{egress}[1]{toCIDR}, [ '0.0.0.0/0' ], 'to cidrs');
    ok($spec->{egress}[2]{toPorts}, 'dns rule has ports');

    my $d = TestBR::CNP->new(metadata => meta('d'))->deny_all_ingress->deny_all_egress;
    my $dspec = $d->TO_JSON->{spec};
    is_deeply([ $dspec->{ingress}, $dspec->{ingressDeny} ], [ [], [ {} ] ], 'deny_all_ingress');
    is_deeply([ $dspec->{egress}, $dspec->{egressDeny} ], [ [], [ {} ] ], 'deny_all_egress');
};

done_testing;
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `prove -l t/69_builder_roles_on_structs.t`
Expected: FAIL -- the first subtest dies with "Not a HASH reference" (or produces an empty spec), because the roles still treat `spec` as a hashref.

- [ ] **Step 3: Rewrite the methods**

`lib/IO/K8s/Role/CertManaged.pm` -- replace the bodies:

```perl
sub for_domains {
    my ($self, @domains) = @_;
    $self->spec_push('dnsNames', @domains);
    return $self;
}

sub with_issuer {
    my ($self, $name, %opts) = @_;
    $self->spec_set('issuerRef', {
        name  => $name,
        kind  => $opts{kind} // 'Issuer',
        group => $opts{group} || 'cert-manager.io',
    });
    return $self;
}

sub store_in_secret {
    my ($self, $secret_name) = @_;
    $self->spec_set('secretName', $secret_name);
    return $self;
}

sub add_ip_san {
    my ($self, @ips) = @_;
    require IO::K8s::Types::Net;
    for my $ip (@ips) {
        croak "'$ip' is not a valid IP address"
            unless IO::K8s::Types::Net::IPAddress()->check($ip);
    }
    $self->spec_push('ipAddresses', @ips);
    return $self;
}

sub renew_before {
    my ($self, %opts) = @_;
    if ($opts{days}) {
        $self->spec_set('renewBefore', ($opts{days} * 24) . 'h0m0s');
    } elsif ($opts{hours}) {
        $self->spec_set('renewBefore', $opts{hours} . 'h0m0s');
    }
    return $self;
}

sub letsencrypt {
    my ($self, %opts) = @_;
    my $email = $opts{email} or croak 'email is required for letsencrypt';
    my $production = $opts{production} // 0;
    my $server = $production
        ? 'https://acme-v02.api.letsencrypt.org/directory'
        : 'https://acme-staging-v02.api.letsencrypt.org/directory';
    $self->spec_set('acme', {
        email  => $email,
        server => $server,
        privateKeySecretRef => { name => $opts{secret} // 'letsencrypt-account-key' },
    });
    return $self;
}

sub self_signed {
    my ($self) = @_;
    $self->spec_set('selfSigned', {});
    return $self;
}

sub ca {
    my ($self, %opts) = @_;
    $self->spec_set('ca', {
        secretName => $opts{secret} // croak('secret is required for ca'),
    });
    return $self;
}

sub add_http01_solver {
    my ($self, %opts) = @_;
    my $solver = { http01 => { ingress => {} } };
    $solver->{http01}{ingress}{class} = $opts{class} if $opts{class};
    $self->spec_push('acme.solvers', $solver);
    return $self;
}

sub add_dns01_solver {
    my ($self, %opts) = @_;
    my %dns01;
    if ($opts{provider} eq 'cloudflare') {
        $dns01{cloudflare} = {
            $opts{secret} ? (apiTokenSecretRef => { name => $opts{secret}, key => $opts{key} // 'api-token' }) : (),
        };
    } elsif ($opts{provider} eq 'route53') {
        $dns01{route53} = {
            $opts{region} ? (region => $opts{region}) : (),
        };
    } else {
        $dns01{$opts{provider}} = {};
    }
    $self->spec_push('acme.solvers', { dns01 => \%dns01 });
    return $self;
}
```

`lib/IO/K8s/Role/HelmManaged.pm`:

```perl
sub from_repo {
    my ($self, $repo_url, $chart_name) = @_;
    $self->spec_set('repo',  $repo_url);
    $self->spec_set('chart', $chart_name);
    return $self;
}

sub set_version {
    my ($self, $version) = @_;
    $self->spec_set('version', $version);
    return $self;
}

sub set_values {
    my ($self, %values) = @_;
    # Helm keys carry dots (image.tag), so they must not travel through a
    # dotted spec path: fetch the map once and write into it directly.
    my $set = $self->spec_hash('set');
    @{$set}{keys %values} = values %values;
    return $self;
}

sub set_values_yaml {
    my ($self, $yaml_str) = @_;
    $self->spec_set('valuesContent', $yaml_str);
    return $self;
}
```

`lib/IO/K8s/Role/MiddlewareBuilder.pm`:

```perl
sub rate_limit {
    my ($self, %opts) = @_;
    $self->spec_set('rateLimit', {
        $opts{average} ? (average => $opts{average}) : (),
        $opts{burst}   ? (burst   => $opts{burst})   : (),
        $opts{period}  ? (period  => $opts{period})  : (),
    });
    return $self;
}

sub basic_auth {
    my ($self, %opts) = @_;
    $self->spec_set('basicAuth', {
        $opts{secret} ? (secret => $opts{secret}) : (),
        $opts{realm}  ? (realm  => $opts{realm})  : (),
    });
    return $self;
}

sub strip_prefix {
    my ($self, @prefixes) = @_;
    $self->spec_set('stripPrefix', { prefixes => \@prefixes });
    return $self;
}

sub redirect_https {
    my ($self) = @_;
    $self->spec_set('redirectScheme', { scheme => 'https', permanent => 1 });
    return $self;
}

sub add_request_header {
    my ($self, $key, $value) = @_;
    # Header names may legally contain dots; write into the map directly.
    $self->spec_hash('headers.customRequestHeaders')->{$key} = $value;
    return $self;
}

sub add_response_header {
    my ($self, $key, $value) = @_;
    $self->spec_hash('headers.customResponseHeaders')->{$key} = $value;
    return $self;
}
```

`lib/IO/K8s/Role/Loadbalanced.pm`:

```perl
sub set_weighted {
    my ($self, $name, $weight) = @_;
    my $services = $self->spec_array('weighted.services');
    for my $i (0 .. $#$services) {
        next unless ($self->spec_get("weighted.services.$i.name") // '') eq $name;
        $self->spec_set("weighted.services.$i.weight", $weight);
        return $self;
    }
    $self->spec_push('weighted.services', { name => $name, weight => $weight });
    return $self;
}

sub mirror_to {
    my ($self, $name, %opts) = @_;
    $self->spec_push('mirroring.mirrors', {
        name => $name,
        $opts{percent} ? (percent => $opts{percent}) : (),
    });
    return $self;
}
```

`lib/IO/K8s/Role/Routable.pm` -- only the `gateway` and `traefik` branches change; the `ingress` branches are kept verbatim:

```perl
sub add_hostname {
    my ($self, @hostnames) = @_;
    my $format = $self->_route_format;
    if ($format eq 'gateway') {
        $self->spec_push('hostnames', @hostnames);
    } elsif ($format eq 'traefik') {
        # Traefik uses match rules like Host(`example.com`)
        # We add a route with the host match
        my $hosts = join ', ', map { "Host(`$_`)" } @hostnames;
        $self->spec_push('routes', { match => $hosts, kind => 'Rule', services => [] });
    } elsif ($format eq 'ingress') {
        # ... unchanged ...
    }
    return $self;
}

sub add_backend {
    my ($self, $name, %opts) = @_;
    my $format = $self->_route_format;
    my %backend = (
        name => $name,
        $opts{port}   ? (port   => $opts{port})   : (),
        $opts{weight} ? (weight => $opts{weight}) : (),
    );
    if ($format eq 'gateway') {
        $self->spec_push('rules.-1.backendRefs', \%backend);
    } elsif ($format eq 'traefik') {
        $self->spec_push('routes.-1.services', \%backend);
    } elsif ($format eq 'ingress') {
        # ... unchanged ...
    }
    return $self;
}

sub add_path_match {
    my ($self, $path, %opts) = @_;
    my $type = $opts{type} // 'Prefix';
    my $format = $self->_route_format;
    if ($format eq 'gateway') {
        $self->spec_push('rules.-1.matches', { path => { type => $type, value => $path } });
    } elsif ($format eq 'traefik') {
        my $match = $type eq 'Prefix' ? "PathPrefix(`$path`)"
                  : $type eq 'Exact'  ? "Path(`$path`)"
                  : $type eq 'Regex'  ? "PathRegexp(`$path`)"
                  : undef;
        $self->spec_set('routes.-1.match', $match) if defined $match;
    } elsif ($format eq 'ingress') {
        # ... unchanged ...
    }
    return $self;
}

sub add_header_match {
    my ($self, $header, $value) = @_;
    my $format = $self->_route_format;
    if ($format eq 'gateway') {
        $self->spec_push('rules.-1.matches.-1.headers', { name => $header, value => $value });
    } elsif ($format eq 'traefik') {
        my $existing = $self->spec_get('routes.-1.match') // '';
        my $header_match = "Header(`$header`, `$value`)";
        $self->spec_set('routes.-1.match', $existing ? "$existing && $header_match" : $header_match);
    }
    # Ingress doesn't support header matching natively
    return $self;
}
```

Behaviour note for `add_path_match` (traefik): the old code, on a missing `routes`, vivified `[{}]` and then wrote `match` into that element **only for a known type**; an unknown type left an empty route behind. The new code with `-1` vivifies only when it writes, so an unknown type now leaves `routes` untouched. State this in the commit message; it is a strict improvement and no test covers the old shape.

`lib/IO/K8s/Role/NetworkPolicy.pm` -- only the `cilium` branches and the helper change:

```perl
# in select_pods
    } elsif ($format eq 'cilium') {
        $self->spec_set('endpointSelector', { matchLabels => \%labels });
    }

# in allow_ingress_from_cidrs
    } elsif ($format eq 'cilium') {
        $self->spec_push('ingress', {
            fromCIDR => $cidrs,
            $opts{ports} ? (toPorts => [ { ports => $opts{ports} } ]) : (),
        });
    }

# in allow_ingress_from_namespace
    } elsif ($format eq 'cilium') {
        $self->spec_push('ingress', {
            fromEndpoints => [ { matchLabels => { 'k8s:io.kubernetes.pod.namespace' => $namespace } } ],
            $opts{ports} ? (toPorts => [ { ports => $opts{ports} } ]) : (),
        });
    }

# in allow_egress_to_pods
    } elsif ($format eq 'cilium') {
        $self->spec_push('egress', {
            toEndpoints => [ { matchLabels => $labels } ],
            $opts{ports} ? (toPorts => [ { ports => $opts{ports} } ]) : (),
        });
    }

# in allow_egress_to_cidrs
    } elsif ($format eq 'cilium') {
        $self->spec_push('egress', { toCIDR => $cidrs });
    }

# in allow_egress_to_dns
    } elsif ($format eq 'cilium') {
        $self->spec_push('egress', {
            toEndpoints => [ { matchLabels => { 'k8s:io.kubernetes.pod.namespace' => 'kube-system', 'k8s:k8s-app' => 'kube-dns' } } ],
            toPorts     => [ { ports => $dns_ports } ],
        });
    }

# in deny_all_ingress
    } elsif ($format eq 'cilium') {
        $self->spec_set('ingress',     []);
        $self->spec_set('ingressDeny', [ {} ]);
    }

# in deny_all_egress
    } elsif ($format eq 'cilium') {
        $self->spec_set('egress',     []);
        $self->spec_set('egressDeny', [ {} ]);
    }

sub _add_cilium_ingress_rule {
    my ($self, $endpoint_selector, $ports) = @_;
    $self->spec_push('ingress', {
        fromEndpoints => [ $endpoint_selector ],
        $ports ? (toPorts => [ { ports => $ports } ]) : (),
    });
}
```

`IO::K8s::Cilium::V2::CiliumNetworkPolicy` and `CiliumClusterwideNetworkPolicy` are CRD classes, so they compose `SpecBuilder` through `IO::K8s::APIObject`; the core `NetworkPolicy` class does not, and its `core` branches never call these methods. No `requires` is added to the roles for that reason.

- [ ] **Step 4: Run the new test and the four role tests**

Run: `prove -l t/69_builder_roles_on_structs.t t/16_role_netpol.t t/17_role_routable.t t/18_role_certmanaged.t t/19_role_helm.t`
Expected: all PASS.

- [ ] **Step 5: Run the full suite**

Run: `prove -lr t/`
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/IO/K8s/Role/CertManaged.pm lib/IO/K8s/Role/HelmManaged.pm lib/IO/K8s/Role/MiddlewareBuilder.pm lib/IO/K8s/Role/Loadbalanced.pm lib/IO/K8s/Role/Routable.pm lib/IO/K8s/Role/NetworkPolicy.pm t/69_builder_roles_on_structs.t
git commit -m "Express the builder roles in SpecBuilder calls so they work on typed specs (D2)"
```

---

### Task 5: k91 example fix, POD, Changes

**Lane:** `io-k8s-doc-writer` for POD and README; the orchestrator edits `Changes`.

**Files:**
- Modify: `README.md` (AgentSandbox section, the `spec => { replicas => 1, shutdownPolicy => 'Retain' }` example; the `SpecBuilder` paragraph under "Convenience Roles")
- Modify: `lib/IO/K8s/AgentSandbox.pm` (SYNOPSIS `spec => { ... }` placeholder is fine; check the DESCRIPTION for a `replicas` mention)
- Modify: `lib/IO/K8s/Role/Resource.pm` (POD), `lib/IO/K8s.pm` (`=head2 strict` under ATTRIBUTES, next to `=head2 with`), `lib/IO/K8s/Role/SpecBuilder.pm` (`=method` blocks), `lib/IO/K8s/Role/APIObject.pm` or `lib/IO/K8s/APIObject.pm` wherever "CRD classes also get SpecBuilder" is described
- Modify: `Changes`

- [ ] **Step 1: Fix the AgentSandbox example (k91 part 1)**

In `README.md`, replace

```perl
    spec => { replicas => 1, shutdownPolicy => 'Retain' },
```

with

```perl
    spec => {
        shutdownPolicy => 'Retain',
        podTemplate    => { spec => { containers => [ { name => 'agent', image => 'agent:latest' } ] } },
    },
```

Run `grep -rn 'replicas' README.md lib/IO/K8s/AgentSandbox.pm lib/IO/K8s/AgentSandbox/` and fix every AgentSandbox example that still passes `replicas`.

- [ ] **Step 2: Document the new behaviour**

- `lib/IO/K8s/Role/Resource.pm`: add a `=head1 UNKNOWN FIELDS` section (before the `=method TO_JSON` block) of two paragraphs: what is kept, that `TO_JSON` re-emits it with declared attributes winning, that `_unknown_fields` holds it, and that `IO::K8s->new(strict => 1)` turns it into a fatal `Unknown field '<name>' for <class>` at every nesting level.
- `lib/IO/K8s.pm`: `=head2 strict` under ATTRIBUTES: default 0; the four entry points it covers; `load`/`load_yaml` inherit; the exact error text.
- `lib/IO/K8s/Role/SpecBuilder.pm`: rewrite the DESCRIPTION's path-syntax paragraph (object nodes, `-1`, undeclared keys go to the bag), update each `=method` block (`spec_get` returns objects as objects; `spec_set` validates through the declared type and inflates hashrefs; `spec_delete` clears a declared field to undef and croaks through Moo on a `required` one), add `=method spec_array` and `=method spec_hash`.
- README "Convenience Roles": after the `SpecBuilder` example add one sentence: "Paths walk typed specs too: `-1` addresses the last (or a new) array element, and a hashref written into a typed slot is inflated."

- [ ] **Step 3: Add the `Changes` entries**

Under `{{$NEXT}}`, above the existing first bullet, in the file's voice:

```
  - Unknown fields are kept instead of dropped (D1 of the CRD design,
    docs/superpowers/specs/2026-09-03-crd-design.md). A constructor key no
    attribute claims -- on inflate, new_object, FROM_HASH or a direct ->new,
    at any nesting level including inline structs -- now lands in the
    object's _unknown_fields bag and TO_JSON emits it again, declared
    attributes winning on a clash. Before, every class silently lost such a
    field on the round-trip (the README AgentSandbox example passed a
    spec.replicas that vanished, k91). IO::K8s->new(strict => 1) makes the
    same situation die with "Unknown field '<name>' for <class>" for the
    duration of that instance's inflate / new_object / json_to_object /
    struct_to_object calls (load and load_yaml inherit it).

  - SpecBuilder walks typed specs (k90). spec_get/spec_set/spec_push/
    spec_merge/spec_delete used to assume spec was a plain hashref; on a
    class whose spec is an inline struct (the eight AgentSandbox classes)
    spec_set replaced the struct with an empty hash and wrote into an
    orphan, so to_json emitted spec: {} afterwards. The methods now walk
    objects through their accessors, vivify missing intermediates as the
    declared class, inflate hashrefs handed to typed slots, and put a key an
    object does not declare into its _unknown_fields bag. A -1 path segment
    addresses the last array element, or a freshly created one on an empty
    array. New: spec_array($path) and spec_hash($path) return the vivified
    container. The builder roles (CertManaged, HelmManaged,
    MiddlewareBuilder, Loadbalanced, Routable's gateway and traefik
    branches, NetworkPolicy's cilium branch) are expressed in these calls
    and therefore work on hash and object specs alike. One visible change:
    Routable::add_path_match on a traefik route with an unknown type no
    longer leaves an empty route behind.

  - README: the AgentSandbox example no longer passes spec.replicas, a
    field neither the class nor upstream agent-sandbox v1.0.0 has (k91).
```

- [ ] **Step 4: Verify POD and the whole distribution**

Run: `podchecker lib/IO/K8s/Role/Resource.pm lib/IO/K8s/Role/SpecBuilder.pm lib/IO/K8s.pm` -- Expected: no errors.
Run: `prove -lr t/` -- Expected: PASS.
Run: `dzil test` -- Expected: PASS (this also builds the POD through the Author::GETTY weaver and catches a malformed `=method`).

- [ ] **Step 5: Commit and close the tickets**

```bash
git add README.md Changes lib/IO/K8s/Role/Resource.pm lib/IO/K8s/Role/SpecBuilder.pm lib/IO/K8s.pm lib/IO/K8s/AgentSandbox.pm
git commit -m "Document preserved unknown fields, strict and the object-aware SpecBuilder; fix the AgentSandbox example (k90, k91)"
karr move 90 done
karr move 91 done
```

---

## Self-review

- **Spec coverage:** D1 preserve -> Task 1; D1 strict -> Task 2; D2 SpecBuilder -> Task 3; D2 builder roles -> Task 4; k90 -> Tasks 3 + 5; k91 part 1 -> Task 5, part 2 -> Task 1. The "core/ingress branches untouched" boundary is stated in Task 4.
- **Placeholder scan:** the only "unchanged" markers are inside Task 4's Routable listing and refer to the `ingress` branches that are explicitly left verbatim; every changed branch is spelled out.
- **Type consistency:** `_unknown_fields` (rw hashref) is used identically in Tasks 1, 3 and 5; `$IO::K8s::Resource::STRICT` in Tasks 1 and 2; `spec_array` / `spec_hash` signatures in Tasks 3 and 4; the error strings `Unknown field '<key>' for <class>`, `cannot descend through scalar field '<seg>'`, `index <n> is out of range` are shared by the code and the tests that match them.
