# CRD Step 2: Per-Field Options in the `k8s` DSL -- Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let a `k8s` field declaration carry the schema facts a CRD needs (`required`, `default`, `enum`, `minimum`, `maximum`, `pattern`, `description`, `nullable`, `preserve_unknown`), record them in the attribute registry for `to_crd` (step 5), enforce the four value constraints client-side at construction, and have `IO::K8s::AutoGen` translate the same facts from an OpenAPI schema.

**Architecture:** `IO::K8s::Resource::_k8s` gains an options hashref as its third argument (and a two-element `[ Type, { ... } ]` form inside inline structs), validates the option names and their fit to the field's scalar kind at class-load time, builds the value constraints as Type::Tiny child types of the field's base type (so error messages name the rule, not a regex), and stores `required` and the remaining options in the registry. `IO::K8s::AutoGen::_generate_class` reads `required`, `enum`, `minimum`, `maximum`, `pattern`, `default`, `description`, `nullable` and `x-kubernetes-preserve-unknown-fields` from the property schema and passes them through the same DSL argument.

**Tech Stack:** Perl 5.10+, Moo, Type::Tiny 2.x (`create_child_type`), Test::More, Test::Exception. `prove -lr t/` (the `-r` is required).

**Spec:** `docs/superpowers/specs/2026-09-03-crd-design.md`, decision D3. Ticket k93. Step 1 (D1/D2) is on master as of commit `d80f7d6c`.

## Global Constraints

- Every module keeps `our $VERSION = '1.108';`.
- No new CPAN dependencies (`Type::Tiny` >= 2.0 and `Types::Standard` are declared; `Types::Common::*` is not used).
- The full suite `prove -lr t/` must be green with nothing skipped after every task; the 850 checked-in classes must load and round-trip unchanged (`t/02_compile_all.t`, `t/25_real_world.t`, `t/26_build_verify.t`).
- Every existing declaration form keeps working unchanged: `k8s x => Str, 'required'`, `k8s x => 'Str!'`, `k8s x => [Str]`, `k8s x => [ {} ]`, `k8s x => [ [] ]`, `k8s x => { Str => 1 }`, `k8s x => { Quantity => 1 }`, inline structs, `'+Full::Class'`.
- Comments and POD in English in the house voice; commit trailer:
  ```
  Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>
  Claude-Session: https://claude.ai/code/session_01MysDYqMAm8iUAbiTm1XhYi
  ```
- Delegation lanes: `lib/` and the plan's tests go to `io-k8s-worker` (the tests are fixed by this plan); POD to `io-k8s-doc-writer`.

## File structure

| File | Responsibility after this plan |
|------|-------------------------------|
| `lib/IO/K8s/Resource.pm` | the `k8s` DSL: option parsing (`%FIELD_OPTIONS`), `_constrain` (value constraints as child types), `_k8s` restructured to compute one un-wrapped `$inner` type per branch, registry gains `required` and `options` |
| `lib/IO/K8s/AutoGen.pm` | `_field_options` maps schema facts to DSL options; `_generate_class` passes them |
| `t/70_dsl_field_options.t` | every form, every option, every croak |
| `t/71_autogen_field_options.t` | schema -> options -> enforced |
| `Changes`, POD in `Resource.pm` and `AutoGen.pm` | documentation |

---

### Task 1: Option parsing, validation and registry (`_k8s`)

**Lane:** `io-k8s-worker`.

**Files:**
- Modify: `lib/IO/K8s/Resource.pm` (`use` lines; new `%FIELD_OPTIONS`, `%NUMERIC_KIND`, `%STRING_KIND`; new `_constrain`; `_k8s` restructured)
- Test: `t/70_dsl_field_options.t`

**Interfaces:**
- Produces: `k8s NAME => TYPE, { OPTIONS }`; inline-struct field form `NAME => [ TYPE, { OPTIONS } ]`; registry entries `$info->{required}` (1 when required, absent otherwise) and `$info->{options}` (hashref of the options other than `required`, absent when none). Option names: `required default enum minimum maximum pattern description nullable preserve_unknown`. Constraint errors read `Value "<v>" is not one of: <list>`, `Value "<v>" is below the minimum <n>` / `above the maximum <n>`, `Value "<v>" does not match the pattern <re>`. Load-time errors start with `k8s: ` and end with `for field '<name>' of <class>`.
- Task 2 relies on: `_k8s($class, $caller, $name, $type_spec, $opts_hashref)` accepting a hashref third argument and the registry keys above.

- [ ] **Step 1: Write the failing test**

Create `t/70_dsl_field_options.t`:

```perl
#!/usr/bin/env perl
# D3: per-field options in the k8s DSL -- forms, registry, client-side
# constraints, and the load-time checks that reject options a field cannot
# carry.
use strict;
use warnings;
use Test::More;
use Test::Exception;

# --- every accepted form, one class -------------------------------------

{
    package TestOpt::Widget;
    use IO::K8s::Resource;

    k8s name     => Str, { required => 1, pattern => qr/\A[a-z][a-z0-9-]*\z/, description => 'DNS-1123 label' };
    k8s policy   => Str, { enum => [qw(Retain Delete)], default => 'Retain' };
    k8s replicas => Int, { minimum => 0, maximum => 10, default => 1 };
    k8s ratio    => Num, { minimum => 0.5 };
    k8s tags     => [Str], { enum => [qw(web db)] };
    k8s ports    => [Int], { minimum => 1, maximum => 65535 };
    k8s limits   => { Quantity => 1 }, { description => 'per-container limits' };
    k8s weights  => { Int => 1 }, { maximum => 100 };
    k8s labels   => { Str => 1 }, { preserve_unknown => 1 };
    k8s note     => Str, { nullable => 1 };
    k8s legacy   => Str, 'required';
    k8s bang     => 'Str!';
    k8s spec     => {
        mode     => [ Str, { enum => [qw(fast safe)], required => 1 } ],
        retries  => [ Int, { minimum => 0 } ],
        hosts    => [ [Str], { pattern => '^[a-z.]+$' } ],
        plain    => Str,
    };
}

sub widget { TestOpt::Widget->new(name => 'w', spec => { mode => 'fast' }, @_) }

subtest 'registry carries required and the other options' => sub {
    my $info = TestOpt::Widget->_k8s_attr_info;
    is($info->{name}{required}, 1, 'required recorded');
    is_deeply([ sort keys %{ $info->{name}{options} } ], [qw(description pattern)], 'options without required');
    is($info->{name}{options}{description}, 'DNS-1123 label', 'description kept verbatim');
    is(ref $info->{name}{options}{pattern}, 'Regexp', 'pattern kept as given');
    is_deeply($info->{policy}{options}{enum}, [qw(Retain Delete)], 'enum kept');
    is($info->{policy}{options}{default}, 'Retain', 'default kept');
    ok(!exists $info->{policy}{required}, 'not required: key absent');
    is($info->{legacy}{required}, 1, "legacy 'required' marker still records required");
    ok(!exists $info->{legacy}{options}, 'and adds no options');
    is($info->{bang}{required}, 1, "'Str!' suffix still records required");
    is($info->{note}{options}{nullable}, 1, 'nullable is schema-only but recorded');
    is($info->{labels}{options}{preserve_unknown}, 1, 'preserve_unknown recorded');

    my $spec = $IO::K8s::Resource::_attr_registry{'TestOpt::Widget::_Spec'};
    is($spec->{mode}{required}, 1, 'inline [Type, {opts}] form: required');
    is_deeply($spec->{mode}{options}{enum}, [qw(fast safe)], 'inline form: enum');
    is($spec->{retries}{options}{minimum}, 0, 'inline form: minimum');
    ok($spec->{hosts}{is_array_of_str}, 'inline [[Str], {opts}] form keeps the array flag');
    ok(!exists $spec->{plain}{options}, 'inline field without options has none');
};

subtest 'required is enforced through the options hash' => sub {
    throws_ok { TestOpt::Widget->new(spec => { mode => 'fast' }) } qr/Missing required arguments: name/, 'required => 1';
    throws_ok { TestOpt::Widget->new(name => 'w', spec => {}) } qr/Missing required arguments: mode/, 'inline required';
    lives_ok { widget() } 'both present';
};

subtest 'enum' => sub {
    lives_ok { widget(policy => 'Delete') } 'listed value accepted';
    throws_ok { widget(policy => 'Purge') } qr/Value "Purge" is not one of: Retain, Delete/, 'unlisted value rejected with the list';
    lives_ok { widget(tags => [qw(web db)]) } 'array elements accepted';
    throws_ok { widget(tags => [qw(web cache)]) } qr/is not one of: web, db/, 'array element rejected';
    throws_ok { widget(spec => { mode => 'slow' }) } qr/is not one of: fast, safe/, 'inline enum rejected';
    lives_ok { widget(policy => undef) } 'undef still means unset on an optional field';
};

subtest 'minimum and maximum' => sub {
    lives_ok { widget(replicas => 0) } 'minimum inclusive';
    lives_ok { widget(replicas => 10) } 'maximum inclusive';
    throws_ok { widget(replicas => -1) } qr/Value "-1" is below the minimum 0/, 'below minimum';
    throws_ok { widget(replicas => 11) } qr/Value "11" is above the maximum 10/, 'above maximum';
    lives_ok { widget(ratio => 0.5) } 'Num minimum inclusive';
    throws_ok { widget(ratio => 0.25) } qr/below the minimum 0\.5/, 'Num below minimum';
    lives_ok { widget(ratio => 1e9) } 'open maximum';
    throws_ok { widget(ports => [ 80, 70000 ]) } qr/Value "70000" is above the maximum 65535/, 'array element range';
    throws_ok { widget(weights => { a => 101 }) } qr/above the maximum 100/, 'typed map value range';
    throws_ok { widget(replicas => 'abc') } qr/replicas/, 'the base type still applies first';
};

subtest 'pattern' => sub {
    lives_ok { widget(name => 'web-1') } 'matching';
    throws_ok { widget(name => 'Web') } qr/Value "Web" does not match the pattern/, 'non-matching';
    lives_ok { widget(spec => { mode => 'fast', hosts => [ 'a.example' ] }) } 'string pattern compiled';
    throws_ok { widget(spec => { mode => 'fast', hosts => [ 'A' ] }) } qr/does not match the pattern/, 'string pattern enforced per element';
};

subtest 'schema-only options change nothing at runtime' => sub {
    my $w = widget();
    ok(!defined $w->policy, 'default is not applied client-side');
    ok(!exists $w->TO_JSON->{policy}, 'and nothing is emitted for it');
    my $n = widget(note => undef);
    ok(!exists $n->TO_JSON->{note}, 'nullable: undef is still omitted on the wire');
    is_deeply(widget(labels => { a => 'b' })->TO_JSON->{labels}, { a => 'b' }, 'preserve_unknown: opaque map unchanged');
};

subtest 'TO_JSON of a class with options is unchanged' => sub {
    my $w = widget(policy => 'Delete', replicas => 3, tags => ['web'], spec => { mode => 'safe', retries => 2 });
    is_deeply($w->TO_JSON, {
        name => 'w', policy => 'Delete', replicas => 3, tags => ['web'],
        spec => { mode => 'safe', retries => 2 },
    }, 'options leave serialization alone');
};

# --- load-time rejection -------------------------------------------------

sub declare_dies {
    my ($code, $re, $label) = @_;
    my $pkg = 'TestOpt::Bad' . ++$main::_n;
    throws_ok { eval "package $pkg; use IO::K8s::Resource; $code; 1" or die $@ } $re, $label;
}

subtest 'unknown or misplaced options die at class load, naming class and field' => sub {
    declare_dies(q{k8s x => Str, { colour => 'red' }},
        qr/k8s: unknown field option 'colour' for field 'x' of TestOpt::Bad\d+/, 'unknown option');
    declare_dies(q{k8s x => Str, 'optional'},
        qr/k8s: third argument for field 'x' of TestOpt::Bad\d+ must be 'required' or a hashref/, 'bad marker');
    declare_dies(q{k8s x => Bool, { enum => [1] }},
        qr/k8s: 'enum' is not allowed on a Bool field/, 'enum on Bool');
    declare_dies(q{k8s x => Str, { minimum => 1 }},
        qr/k8s: 'minimum' and 'maximum' need an Int or Num field, not Str/, 'minimum on Str');
    declare_dies(q{k8s x => Int, { pattern => qr/1/ }},
        qr/k8s: 'pattern' needs a string field, not Int/, 'pattern on Int');
    declare_dies(q{k8s x => Int, { minimum => 'low' }},
        qr/k8s: 'minimum' and 'maximum' for field 'x' of TestOpt::Bad\d+ must be numbers/, 'non-numeric bound');
    declare_dies(q{k8s x => Str, { enum => [] }},
        qr/k8s: 'enum' for field 'x' of TestOpt::Bad\d+ must be a non-empty arrayref/, 'empty enum');
    declare_dies(q{k8s x => Str, { pattern => '[' }},
        qr/k8s: 'pattern' for field 'x' of TestOpt::Bad\d+ does not compile/, 'uncompilable pattern');
    declare_dies(q{k8s x => Int, { default => 'abc' }},
        qr/k8s: 'default' for field 'x' of TestOpt::Bad\d+ fails the field's own type/, 'default outside the type');
    declare_dies(q{k8s x => Str, { enum => ['a'], default => 'b' }},
        qr/k8s: 'default' for field 'x' of TestOpt::Bad\d+ fails the field's own type: Value "b" is not one of: a/, 'default outside the enum');
    declare_dies(q{k8s x => 'Core::V1::PodSpec', { enum => ['a'] }},
        qr/k8s: 'enum' needs a scalar field/, 'enum on an object field');
    declare_dies(q{k8s x => { Str => 1 }, { pattern => 'a' }},
        qr/k8s: 'pattern' needs a scalar field/, 'pattern on an opaque map');
    declare_dies(q{k8s x => [ {} ], { minimum => 1 }},
        qr/k8s: 'minimum' and 'maximum' need a scalar field/, 'range on an array of opaque hashes');
};

subtest 'schema-only options are accepted on any field' => sub {
    lives_ok {
        eval q{
            package TestOpt::AnyField; use IO::K8s::Resource;
            k8s obj  => 'Core::V1::PodSpec', { description => 'd', preserve_unknown => 1, nullable => 1 };
            k8s list => [ {} ], { description => 'd', default => [] };
            k8s map  => { Str => 1 }, { default => {} };
            1;
        } or die $@;
    } 'description, nullable, preserve_unknown, default on non-scalar fields';
};

done_testing;
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `prove -l t/70_dsl_field_options.t`
Expected: FAIL at class load -- the hashref third argument is not `'required'`, so today `$required_marker eq 'required'` is false and the options are silently ignored; the first registry subtest then fails on `required`.

- [ ] **Step 3: Restructure `_k8s` in `lib/IO/K8s/Resource.pm`**

Add to the `use` block: `use Carp qw( croak );` and extend `Scalar::Util` to `qw( blessed reftype looks_like_number )`.

After `%HASH_VALUE_TYPES` add:

```perl
# Field options a declaration may carry (D3): the third argument
# (`k8s name => Type, { ... }`) or, inside an inline struct, the two-element
# form `name => [ Type, { ... } ]`. The legacy 'required' marker and the
# `Type!` suffix still work and mean { required => 1 }. Everything here is
# recorded in the registry for to_crd; enum, minimum, maximum and pattern
# are also enforced at construction, the way { Quantity => 1 } validates
# its values -- a bad value fails here instead of at the API server.
# default is deliberately NOT applied client-side: defaulting is the API
# server's job, and a client default would change the wire output.
my %FIELD_OPTIONS = map { $_ => 1 } qw(
    required default enum minimum maximum pattern description nullable
    preserve_unknown
);
my %NUMERIC_KIND = (Int => 1, Num => 1);
my %STRING_KIND  = (Str => 1, IntOrStr => 1, Quantity => 1, Time => 1);

# The value constraints as child types of the field's base type, so a
# failure names the rule ("is not one of", "is below the minimum") rather
# than an anonymous intersection. $kind is the scalar type name the field
# is built on (Str, Int, Num, Bool, IntOrStr, Quantity, Time).
sub _constrain {
    my ($base, $kind, $opts, $where) = @_;
    my $type = $base;

    if (exists $opts->{enum}) {
        croak "k8s: 'enum' for $where must be a non-empty arrayref"
            unless ref $opts->{enum} eq 'ARRAY' && @{ $opts->{enum} };
        croak "k8s: 'enum' is not allowed on a Bool field ($where)" if $kind eq 'Bool';
        my %allowed = map { $_ => 1 } @{ $opts->{enum} };
        my $list = join ', ', @{ $opts->{enum} };
        $type = $type->create_child_type(
            display_name => $type->display_name . '[enum]',
            constraint   => sub { defined $_ && exists $allowed{$_} },
            message      => sub { "Value \"$_\" is not one of: $list" },
        );
    }

    if (exists $opts->{minimum} || exists $opts->{maximum}) {
        croak "k8s: 'minimum' and 'maximum' need an Int or Num field, not $kind ($where)"
            unless $NUMERIC_KIND{$kind};
        my ($min, $max) = @{$opts}{qw(minimum maximum)};
        for my $bound ($min, $max) {
            croak "k8s: 'minimum' and 'maximum' for $where must be numbers"
                if defined $bound && !looks_like_number($bound);
        }
        $type = $type->create_child_type(
            display_name => $type->display_name . '[range]',
            constraint   => sub {
                (!defined $min || $_ >= $min) && (!defined $max || $_ <= $max)
            },
            message      => sub {
                defined $min && $_ < $min
                    ? "Value \"$_\" is below the minimum $min"
                    : "Value \"$_\" is above the maximum $max";
            },
        );
    }

    if (exists $opts->{pattern}) {
        croak "k8s: 'pattern' needs a string field, not $kind ($where)"
            unless $STRING_KIND{$kind};
        my $re = ref $opts->{pattern} eq 'Regexp'
            ? $opts->{pattern}
            : eval { my $p = $opts->{pattern}; qr/$p/ };
        croak "k8s: 'pattern' for $where does not compile: $@" unless $re;
        $type = $type->create_child_type(
            display_name => $type->display_name . '[pattern]',
            constraint   => sub { defined $_ && $_ =~ $re },
            message      => sub { "Value \"$_\" does not match the pattern $re" },
        );
    }

    return $type;
}

# Options that only make sense on a scalar-bearing field. Object, struct
# and opaque container fields reject them at class load.
sub _reject_value_options {
    my ($opts, $where) = @_;
    croak "k8s: 'enum' needs a scalar field ($where)" if exists $opts->{enum};
    croak "k8s: 'minimum' and 'maximum' need a scalar field ($where)"
        if exists $opts->{minimum} || exists $opts->{maximum};
    croak "k8s: 'pattern' needs a scalar field ($where)" if exists $opts->{pattern};
}
```

Replace the body of `_k8s` from its signature down to (but not including) the `# Store json_key when it differs` comment with:

```perl
sub _k8s {
    my ($class, $caller, $name, $type_spec, $marker) = @_;

    my $json_key  = $name;
    my $attr_name = _sanitize_attr_name($name);
    my $where     = "field '$name' of $caller";

    # Inline-struct form: name => [ Type, { options } ]. Exactly two elements
    # with a hashref second is unambiguous -- every array type spec ([Str],
    # ['Core::V1::Container'], [ {} ], [ [] ]) has one element.
    if (ref $type_spec eq 'ARRAY' && @$type_spec == 2 && ref $type_spec->[1] eq 'HASH') {
        ($type_spec, $marker) = @$type_spec;
    }

    my %opts;
    if (ref $marker eq 'HASH') {
        %opts = %$marker;
    } elsif (defined $marker && $marker eq 'required') {
        $opts{required} = 1;
    } elsif (defined $marker) {
        croak "k8s: third argument for $where must be 'required' or a hashref of field options, got '$marker'";
    }
    for my $key (sort keys %opts) {
        croak "k8s: unknown field option '$key' for $where (known: "
            . join(', ', sort keys %FIELD_OPTIONS) . ')'
            unless $FIELD_OPTIONS{$key};
    }
    my $required = delete $opts{required} ? 1 : 0;

    # `!` suffix on strings (legacy/alternative required syntax)
    if (!ref $type_spec && !_is_type_tiny($type_spec) && $type_spec =~ s/!$//) {
        $required = 1;
    } elsif (ref $type_spec eq 'ARRAY' && !ref($type_spec->[0]) && $type_spec->[0] =~ s/!$//) {
        $required = 1;
    }

    # Ensure the registry entry exists
    $_attr_registry{$caller} = {} unless exists $_attr_registry{$caller};

    # Every branch below sets $inner, the type of a present value; the
    # Maybe wrapping for an optional field happens once at the end.
    my %info;
    my $inner;

    # Handle Type::Tiny objects directly (Str, Int, Bool, IntOrStr, Quantity, Time)
    if (_is_type_tiny($type_spec)) {
        my $kind  = $type_spec->name;
        my $flags = $TYPE_FLAGS{$kind};
        if ($flags) {
            %info  = %$flags;
            $inner = _constrain($type_spec, $kind, \%opts, $where);
        }
    } elsif (!ref $type_spec) {
        if (my $flags = $TYPE_FLAGS{$type_spec}) {
            %info = %$flags;
            my $base = $STR_ISA_MAP{$type_spec} // Str;
            $inner = _constrain($base, $type_spec, \%opts, $where);
        } else {
            my $full_class = _expand_class($type_spec);
            $info{is_object} = 1;
            $info{class} = $full_class;
            _reject_value_options(\%opts, $where);
            $inner = InstanceOf[$full_class];
        }
    } elsif (ref $type_spec eq 'ARRAY') {
        my $elem = $type_spec->[0];
        # [ {} ] / [ [] ] -- an array of opaque hashes or opaque arrays, for a
        # schema whose items are `type: object` / `type: array` with no further
        # structure (k66). Validated as arrays of the right container
        # shape; the contents pass through untyped, the same one-level-copy
        # opaque handling a free-form HashRef gets in TO_JSON / _inflate_struct.
        if (ref $elem eq 'HASH') {
            $info{is_array_of_hash} = 1;
            _reject_value_options(\%opts, $where);
            $inner = ArrayRef[HashRef];
        } elsif (ref $elem eq 'ARRAY') {
            $info{is_array_of_array} = 1;
            _reject_value_options(\%opts, $where);
            $inner = ArrayRef[ArrayRef];
        # Handle [Str] with Type::Tiny object
        } elsif (_is_type_tiny($elem)) {
            my $kind = $elem->name;
            if ($kind eq 'Str') {
                $info{is_array_of_str} = 1;
            } elsif ($kind eq 'Int') {
                $info{is_array_of_int} = 1;
            } elsif ($kind eq 'Bool') {
                $info{is_array_of_bool} = 1;
            }
            $inner = ArrayRef[ _constrain($elem, $kind, \%opts, $where) ];
        } elsif ($elem eq 'Str') {
            $info{is_array_of_str} = 1;
            $inner = ArrayRef[ _constrain(Str, 'Str', \%opts, $where) ];
        } elsif ($elem eq 'Int') {
            $info{is_array_of_int} = 1;
            $inner = ArrayRef[ _constrain(Int, 'Int', \%opts, $where) ];
        } else {
            my $full_class = _expand_class($elem);
            $info{is_array_of_objects} = 1;
            $info{class} = $full_class;
            _reject_value_options(\%opts, $where);
            $inner = ArrayRef[InstanceOf[$full_class]];
        }
    } elsif (ref $type_spec eq 'HASH') {
        my @keys = keys %$type_spec;
        if (@keys == 1 && !ref($type_spec->{$keys[0]}) && $type_spec->{$keys[0]} eq '1') {
            # Hash-of-X pattern: { TypeName => 1 }
            my $vkind = $keys[0];
            if ($vkind eq 'Str') {
                $info{is_hash_of_str} = 1;
                # Use plain HashRef without inner constraint - K8s has nested hashes
                # in fields like fieldsV1, annotations, labels which can have any structure
                _reject_value_options(\%opts, $where);
                $inner = HashRef;
            } elsif (my $vt = $HASH_VALUE_TYPES{$vkind}) {
                # { Quantity => 1 } and friends: a typed value map. Each value
                # is validated against the scalar type (k63).
                $info{$vt->{flag}} = 1;
                $inner = HashRef[ _constrain($vt->{isa}, $vkind, \%opts, $where) ];
            } else {
                my $full_class = _expand_class($vkind);
                $info{is_hash_of_objects} = 1;
                $info{class} = $full_class;
                _reject_value_options(\%opts, $where);
                $inner = HashRef[InstanceOf[$full_class]];
            }
        } else {
            # Inline struct: { field => TypeSpec, ... }
            my $inner_class = $caller . '::_' . ucfirst($attr_name);
            _generate_inline_struct($inner_class, $type_spec);
            $info{is_object} = 1;
            $info{is_inline_struct} = 1;
            $info{class} = $inner_class;
            _reject_value_options(\%opts, $where);
            $inner = InstanceOf[$inner_class];
        }
    }

    croak "k8s: cannot interpret the type of $where" unless defined $inner;

    # A default that the field's own type rejects is a declaration error,
    # not something to discover when to_crd emits it.
    if (exists $opts{default} && !$inner->check($opts{default})) {
        croak "k8s: 'default' for $where fails the field's own type: "
            . $inner->get_message($opts{default});
    }

    my $isa = $required ? $inner : Maybe[$inner];

    $info{required} = 1 if $required;
    $info{options}  = { %opts } if %opts;
```

The rest of `_k8s` (json_key storage, registry write, cache invalidation, `return if $caller->can($attr_name)`, the `has` call with coercions) stays as it is; it already uses `$isa` and `$required`.

Note for the implementer: `_constrain` also receives `Bool` (kind `'Bool'`) and must reject `enum`/range/pattern for it -- the enum branch does so explicitly, the range branch via `%NUMERIC_KIND`, the pattern branch via `%STRING_KIND`. `default => 1` on a Bool passes the `->check` (Bool accepts 1). Both `'required'` with a trailing marker and a `!` suffix together remain legal and simply mean required.

- [ ] **Step 4: Run the test to verify it passes**

Run: `prove -l t/70_dsl_field_options.t`
Expected: PASS, 10 subtests.

- [ ] **Step 5: Run the full suite**

Run: `prove -lr t/`
Expected: PASS. Pay attention to `t/02_compile_all.t` (every class still loads), `t/29_inline_struct.t`, `t/53_bool_normalization.t`, `t/64_k63_hash_of_quantity.t` -- they exercise the branches that were restructured.

- [ ] **Step 6: Commit**

```bash
git add lib/IO/K8s/Resource.pm t/70_dsl_field_options.t
git commit -m "k8s DSL: per-field options with client-side enum, range and pattern constraints (D3, k93)"
```

---

### Task 2: AutoGen maps schema facts to field options

**Lane:** `io-k8s-worker`.

**Files:**
- Modify: `lib/IO/K8s/AutoGen.pm` (`_generate_class` property loop; new `_field_options`, `_scalar_kind`)
- Test: `t/71_autogen_field_options.t`

**Interfaces:**
- Consumes: `_k8s($prop, $type_spec, \%opts)` from Task 1.
- Produces: generated classes whose registry carries `required`/`options` and whose constructors enforce enum/range/pattern; `_field_options($prop_schema, $type_spec, $is_required)` returns a hashref or undef.

- [ ] **Step 1: Write the failing test**

Create `t/71_autogen_field_options.t`:

```perl
#!/usr/bin/env perl
# D3: IO::K8s::AutoGen carries an OpenAPI property's required/enum/minimum/
# maximum/pattern/default/description/nullable/x-kubernetes-preserve-
# unknown-fields into the generated class's field options.
use strict;
use warnings;
use Test::More;
use Test::Exception;

use IO::K8s::AutoGen;

IO::K8s::AutoGen::clear_cache();

my $schema = {
    type => 'object',
    'x-kubernetes-group-version-kind' => [ { group => 'opts.example.com', version => 'v1', kind => 'Knob' } ],
    required => [ 'spec' ],
    properties => {
        apiVersion => { type => 'string' },
        kind       => { type => 'string' },
        metadata   => { '$ref' => '#/definitions/io.k8s.apimachinery.pkg.apis.meta.v1.ObjectMeta' },
        spec => {
            type => 'object',
            required => [ 'mode' ],
            properties => {
                mode     => { type => 'string', enum => [ 'fast', 'safe' ], description => 'operating mode', default => 'safe' },
                replicas => { type => 'integer', minimum => 0, maximum => 5, default => 1 },
                ratio    => { type => 'number', minimum => 0.1 },
                name     => { type => 'string', pattern => '^[a-z]+$' },
                tags     => { type => 'array', items => { type => 'string', enum => [ 'a', 'b' ] } },
                ports    => { type => 'array', items => { type => 'integer', maximum => 65535 } },
                weird    => { type => 'string', pattern => '[' },
                flag     => { type => 'boolean', default => JSON::PP::true() },
                extra    => { type => 'object', 'x-kubernetes-preserve-unknown-fields' => JSON::PP::true(), nullable => JSON::PP::true() },
            },
        },
    },
};
require JSON::PP;

my $class = IO::K8s::AutoGen::get_or_generate('com.example.opts.v1.Knob', $schema, {}, 'IO::K8s::_AUTOGEN_opts',
    api_version => 'opts.example.com/v1', kind => 'Knob', resource_plural => 'knobs', is_namespaced => 1);
my $spec_class = $class->_k8s_attr_info->{spec}{class};

subtest 'registry of the generated spec class' => sub {
    my $info = $spec_class->_k8s_attr_info;
    is($info->{mode}{required}, 1, 'required list -> required');
    is_deeply($info->{mode}{options}{enum}, [ 'fast', 'safe' ], 'enum');
    is($info->{mode}{options}{description}, 'operating mode', 'description');
    is($info->{mode}{options}{default}, 'safe', 'default');
    is($info->{replicas}{options}{minimum}, 0, 'minimum');
    is($info->{replicas}{options}{maximum}, 5, 'maximum');
    is($info->{ratio}{options}{minimum}, 0.1, 'Num minimum');
    is(ref $info->{name}{options}{pattern}, 'Regexp', 'pattern compiled');
    is_deeply($info->{tags}{options}{enum}, [ 'a', 'b' ], 'array items enum lifted to the field');
    is($info->{ports}{options}{maximum}, 65535, 'array items maximum lifted');
    ok(!exists $info->{weird}{options}{pattern}, 'an uncompilable pattern is dropped, the class still exists');
    ok($info->{flag}{options}{default}, 'boolean default kept');
    ok(!exists $info->{flag}{options}{enum}, 'no value constraints on Bool');
    is($info->{extra}{options}{preserve_unknown}, 1, 'x-kubernetes-preserve-unknown-fields');
    is($info->{extra}{options}{nullable}, 1, 'nullable');
    is($class->_k8s_attr_info->{spec}{required}, 1, 'top-level required list applies too');
};

subtest 'constraints are enforced on the generated class' => sub {
    lives_ok { $spec_class->new(mode => 'fast', replicas => 5, name => 'abc', tags => ['a'], ports => [80]) } 'valid values';
    throws_ok { $spec_class->new(mode => 'slow') } qr/Value "slow" is not one of: fast, safe/, 'enum';
    throws_ok { $spec_class->new(mode => 'fast', replicas => 6) } qr/above the maximum 5/, 'maximum';
    throws_ok { $spec_class->new(mode => 'fast', name => 'ABC') } qr/does not match the pattern/, 'pattern';
    throws_ok { $spec_class->new(mode => 'fast', tags => ['c']) } qr/is not one of: a, b/, 'array element enum';
    throws_ok { $spec_class->new(mode => 'fast', ports => [70000]) } qr/above the maximum 65535/, 'array element maximum';
    throws_ok { $spec_class->new() } qr/Missing required arguments: mode/, 'required';
    lives_ok { $spec_class->new(mode => 'fast', weird => 'anything[') } 'dropped pattern enforces nothing';
};

subtest 'inflate through IO::K8s honours the same constraints' => sub {
    require IO::K8s;
    my $k8s = IO::K8s->new(openapi_spec => { definitions => { 'com.example.opts.v1.Knob' => $schema } });
    throws_ok {
        $k8s->inflate({ apiVersion => 'opts.example.com/v1', kind => 'Knob', metadata => { name => 'k' }, spec => { mode => 'slow' } });
    } qr/is not one of: fast, safe/, 'a document from the cluster with a bad enum value fails at inflate';
};

done_testing;
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `prove -l t/71_autogen_field_options.t`
Expected: FAIL -- the first subtest's `required` and `options` keys are absent.

- [ ] **Step 3: Implement in `lib/IO/K8s/AutoGen.pm`**

In `_generate_class`, replace the property loop with:

```perl
    # Generate attributes using k8s DSL
    # Property names with special characters ($ref, x-kubernetes-*) are
    # automatically sanitized to valid Perl identifiers by _k8s(), with
    # init_arg mapping so constructors still accept the original JSON keys.
    my %required = map { $_ => 1 } @{ $schema->{required} // [] };
    for my $prop (sort keys %$properties) {
        next if $role_supplied{$prop};
        my $prop_schema = $properties->{$prop};
        my $type_spec = _schema_to_type_spec($prop_schema, $all_defs, $namespace, $prop, $class);
        next unless defined $type_spec;  # Skip unsupported types

        my $opts = _field_options($prop_schema, $type_spec, $required{$prop});
        $k8s->($prop, $type_spec, ($opts ? $opts : ()));
    }
```

Add after `_schema_to_type_spec`:

```perl
# The scalar type a DSL type spec is built on -- Str, Int, Num, Bool,
# IntOrStr, Quantity, Time -- or undef for objects, structs and the opaque
# container forms. Value constraints (enum, minimum, maximum, pattern) only
# make sense on the former; passing one to the DSL for the latter would
# croak at class generation.
my %SCALAR_KIND = map { $_ => 1 } qw( Str Int Num Bool IntOrStr Quantity Time );

sub _scalar_kind {
    my ($type_spec) = @_;
    if (!ref $type_spec) {
        return $SCALAR_KIND{$type_spec} ? $type_spec : undef;
    }
    if (ref $type_spec eq 'ARRAY') {
        my $elem = $type_spec->[0];
        return undef if ref $elem eq 'HASH' || ref $elem eq 'ARRAY';
        return $elem->name if Scalar::Util::blessed($elem) && $elem->isa('Type::Tiny');
        return $SCALAR_KIND{$elem} ? $elem : undef;
    }
    if (ref $type_spec eq 'HASH') {
        my ($k) = keys %$type_spec;
        # { Str => 1 } is the deliberately opaque map; typed maps carry
        # their value kind.
        return undef if $k eq 'Str';
        return $SCALAR_KIND{$k} ? $k : undef;
    }
    return undef;
}

# Field options for one property (D3). Schema-only facts (description,
# default, nullable, x-kubernetes-preserve-unknown-fields) travel for every
# field; the value constraints only where the DSL can enforce them. For an
# array the constraints sit on `items` and apply per element.
#
# A pattern is an ECMA 262 regex on the wire. Perl compiles nearly all of
# them; one it cannot is dropped rather than failing the whole class -- the
# client-side check is a convenience, the API server validates regardless,
# and no data is lost (the k56 line is about data, not about checks).
sub _field_options {
    my ($prop_schema, $type_spec, $is_required) = @_;
    my %opts;
    $opts{required}    = 1 if $is_required;
    $opts{description} = $prop_schema->{description} if defined $prop_schema->{description};
    $opts{default}     = $prop_schema->{default}     if exists $prop_schema->{default};
    $opts{nullable}    = 1 if $prop_schema->{nullable};
    $opts{preserve_unknown} = 1 if $prop_schema->{'x-kubernetes-preserve-unknown-fields'};

    my $kind = _scalar_kind($type_spec);
    if ($kind && $kind ne 'Bool') {
        my $src = ($prop_schema->{type} // '') eq 'array' ? ($prop_schema->{items} // {}) : $prop_schema;
        $opts{enum} = $src->{enum} if ref $src->{enum} eq 'ARRAY' && @{ $src->{enum} };
        if ($kind eq 'Int' || $kind eq 'Num') {
            $opts{minimum} = $src->{minimum} if defined $src->{minimum};
            $opts{maximum} = $src->{maximum} if defined $src->{maximum};
        } elsif (defined $src->{pattern}) {
            my $re = eval { my $p = $src->{pattern}; qr/$p/ };
            $opts{pattern} = $re if $re;
        }
    }
    return %opts ? \%opts : undef;
}
```

`Scalar::Util` is already imported in AutoGen (`reftype`); extend the import to `qw(blessed reftype)` and use `blessed($elem)` instead of the fully qualified call.

Note for the implementer: the top-level `required` of a CRD schema usually lists `spec`; the generated class then requires `spec` at construction, which `inflate` always supplies. Nothing in `t/04_autogen.t`, `t/45_autogen_dispatch.t` or `t/57_autogen_k55_60.t` constructs an AutoGen object without a listed-required field -- if one does, it was documenting the old leniency; say what it asserted before changing it.

- [ ] **Step 4: Run the test to verify it passes**

Run: `prove -l t/71_autogen_field_options.t`
Expected: PASS, 3 subtests.

- [ ] **Step 5: Run the full suite**

Run: `prove -lr t/`
Expected: PASS (watch the AutoGen tests and `t/09`-style live fixtures in `t/04_autogen.t`).

- [ ] **Step 6: Commit**

```bash
git add lib/IO/K8s/AutoGen.pm t/71_autogen_field_options.t
git commit -m "AutoGen: carry required, enum, range, pattern, default and description into field options (D3)"
```

---

### Task 3: POD and Changes

**Lane:** `io-k8s-doc-writer`; the orchestrator moves k93 on the board after review.

**Files:**
- Modify: `lib/IO/K8s/Resource.pm` (the `=head2 k8s` POD: a "Field options" subsection with the forms, the nine options, which are enforced and which are schema-only, the exact load-time and value error texts, the `default` non-application rule, the `nullable` note that `TO_JSON` still omits `undef`)
- Modify: `lib/IO/K8s/AutoGen.pm` (DESCRIPTION: what is mapped, per-element lifting from `items`, the dropped-uncompilable-pattern rule, `required` lists now enforced)
- Modify: `Changes`

- [ ] **Step 1: Document**

`=head2 k8s` in `Resource.pm` gains, after the existing type-spec examples:

```
=head3 Field options

    k8s replicas => Int, { minimum => 0, maximum => 10, default => 1 };
    k8s policy   => Str, { enum => [qw(Retain Delete)], required => 1 };
    k8s name     => Str, { pattern => qr/\A[a-z0-9-]+\z/, description => '...' };
    k8s spec     => {
        mode  => [ Str, { enum => [qw(fast safe)] } ],   # inside an inline struct
        hosts => [ [Str], { pattern => '^[a-z.]+$' } ],
    };
```

followed by one paragraph each: the two forms and the legacy `'required'` / `Type!` equivalents; the nine option names; `enum`, `minimum`, `maximum`, `pattern` enforced at construction with their messages, on scalar fields, arrays of scalars and typed value maps, and rejected at class load elsewhere; `default`, `description`, `nullable`, `preserve_unknown` recorded for the CRD schema only (`default` never applied client-side, `nullable` does not make `TO_JSON` emit `null`); the load-time errors (`k8s: unknown field option ...`, `k8s: 'enum' is not allowed on a Bool field ...`, `k8s: 'default' for ... fails the field's own type`); where the registry keeps them (`required`, `options`).

`AutoGen.pm` DESCRIPTION gains a paragraph on field options and one on the pattern rule.

- [ ] **Step 2: Changes**

Under `{{$NEXT}}`, above the step-1 bullets:

```
  - The k8s DSL takes per-field options (D3 of the CRD design, k93):
    `k8s replicas => Int, { minimum => 0, maximum => 10, default => 1 }`,
    or `name => [ Type, { ... } ]` inside an inline struct. required,
    default, enum, minimum, maximum, pattern, description, nullable and
    preserve_unknown are recorded in the attribute registry for the CRD
    schema that to_crd will emit; enum, minimum, maximum and pattern are
    also enforced at construction on scalar fields, arrays of scalars and
    typed value maps, failing with "Value "x" is not one of: ...", "is
    below the minimum N" / "is above the maximum N" and "does not match
    the pattern ...". default is never applied client-side. An option a
    field cannot carry (enum on Bool, minimum on Str, pattern on an object)
    is a class-load error naming class and field. The legacy 'required'
    marker and the Type! suffix keep working.

  - IO::K8s::AutoGen carries an OpenAPI property's required list, enum,
    minimum, maximum, pattern, default, description, nullable and
    x-kubernetes-preserve-unknown-fields into those options, per element
    for arrays. Generated classes therefore reject a bad value at
    construction and require the fields the schema lists as required --
    an AutoGen object built without one now dies with "Missing required
    arguments". A pattern Perl cannot compile is dropped (the API server
    still validates it); no data is affected.
```

- [ ] **Step 3: Verify**

Run: `podchecker lib/IO/K8s/Resource.pm lib/IO/K8s/AutoGen.pm` (ignore the pre-existing `=method`/`=head3`-under-weaver noise, look for new errors), `prove -lr t/`, `dzil test`, `dzil clean`.
Expected: all PASS, worktree clean.

- [ ] **Step 4: Commit**

```bash
git add lib/IO/K8s/Resource.pm lib/IO/K8s/AutoGen.pm Changes
git commit -m "Document k8s field options and the AutoGen mapping (D3, k93)"
```

---

## Self-review

- **Spec coverage (D3):** nine options -> Task 1 (`%FIELD_OPTIONS`); recorded in the registry -> Task 1 (`required`, `options`); enum/min/max/pattern enforced client-side like `{ Quantity => 1 }` -> Task 1 (`_constrain`); `default` not applied -> Task 1 (only checked against the type) and documented in Task 3; `description` emitted only -> registry + Task 3; AutoGen mapping is not literally in D3 but is what step 3's emitter builds on -> Task 2.
- **Placeholder scan:** none; every code step carries the code, every test the assertions.
- **Type consistency:** `_k8s($class, $caller, $name, $type_spec, $marker)` in Task 1 matches the `$k8s->($prop, $type_spec, $opts)` call in Task 2; registry keys `required`/`options` are the same in both tests; error strings in `_constrain` match the regexes in t/70 and t/71.
