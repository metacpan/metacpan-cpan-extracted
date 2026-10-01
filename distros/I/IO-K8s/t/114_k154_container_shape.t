#!/usr/bin/env perl
# k154: the wrong container shape at an array or hash field.
#
# _inflate_struct dereferenced an array-of-objects / hash-of-objects value
# without looking at it first, so
#     new_object('Pod', spec => { containers => 'x' })
# died with Perl's own "Can't use string ("x") as an ARRAY ref" (or "Not an
# ARRAY reference" for {}), naming neither PodSpec nor the field. Arrays and
# hashes of scalars reached the constructor instead and failed there with a
# Type::Tiny message that names the field but not the class.
#
# Approved contract: a defined value at an array field that is not an array,
# or at a hash field that is not a hash, fails in the k146 message form --
# the class being inflated, the field, the expected and the received shape --
# on every entry point that reaches the inflation: new_object, inflate,
# struct_to_object, json_to_object, FROM_HASH and the constructor's nested
# coercion. undef and a missing key stay allowed. The contents of an opaque
# field ({ Str => 1 }, untyped) are not constrained any further; the check
# is on the container alone, which a { Str => 1 } field's own HashRef type
# already demanded.
#
# Messages are matched on class names, field names and shapes, never on
# exact wording. Pure local fixtures -- no network, no cluster.

use strict;
use warnings;
use Test::More;
use Test::Exception;
use lib 'lib';

use IO::K8s;
use IO::K8s::Api::Core::V1::Pod;
use IO::K8s::Api::Core::V1::PodSpec;

my $COUNTERSET = 'IO::K8s::Api::Resource::V1::CounterSet';

{
    # The generic container forms the core API classes do not all use.
    package T154::Bag;
    use IO::K8s::APIObject api_version => 'test.example.com/v1';
    k8s spec => {
        docs   => [ {} ],
        flags  => [Bool],
        counts => { Int => 1 },
        blob   => Opaque,   # k191: the opaque map
    };
}

sub dies_naming {
    my ($label, $code, @res) = @_;
    for my $re (@res) {
        throws_ok { $code->() } $re, "$label dies matching $re";
    }
    eval { $code->() };
    unlike($@, qr/Can't use (?:string|an undefined value)|Not an? (?:ARRAY|HASH) reference/,
        "$label: not a bare Perl dereference error");
}

my $pod_with_spec = sub {
    my ($spec, %o) = @_;
    return sub {
        IO::K8s->new(%o)->new_object('Pod', metadata => { name => 'p' }, spec => $spec);
    };
};

# ===========================================================================
# RED: array of objects
# ===========================================================================

# Claim: a string where the containers array belongs names PodSpec, the
# field, the expected array and the plain scalar received.
subtest 'new_object: containers => "x" dies in the k146 form' => sub {
    dies_naming('containers=>"x"', $pod_with_spec->({ containers => 'x' }),
        qr/PodSpec/, qr/\bcontainers\b/, qr/array/i, qr/plain scalar/, qr/Container\b/);
};

# Claim: a hash where the array belongs is refused the same way and the
# received form says HASH.
subtest 'new_object: containers => {} dies in the k146 form' => sub {
    dies_naming('containers=>{}', $pod_with_spec->({ containers => {} }),
        qr/PodSpec/, qr/\bcontainers\b/, qr/array/i, qr/HASH/);
};

# Claim: strict has no say in shape -- same refusal under strict.
subtest 'new_object: containers => "x" dies under strict too' => sub {
    dies_naming('containers=>"x" (strict)', $pod_with_spec->({ containers => 'x' }, strict => 1),
        qr/PodSpec/, qr/\bcontainers\b/);
};

# Claim: inflate reaches the same check.
subtest 'inflate: containers => {} dies' => sub {
    dies_naming('inflate containers=>{}',
        sub {
            IO::K8s->new->inflate({ apiVersion => 'v1', kind => 'Pod',
                metadata => { name => 'p' }, spec => { containers => {} } });
        },
        qr/PodSpec/, qr/\bcontainers\b/, qr/HASH/);
};

# Claim: struct_to_object reaches the same check.
subtest 'struct_to_object: containers => "x" dies' => sub {
    dies_naming('struct_to_object containers=>"x"',
        sub { IO::K8s->new->struct_to_object('Pod', { spec => { containers => 'x' } }) },
        qr/PodSpec/, qr/\bcontainers\b/);
};

# Claim: json_to_object reaches the same check.
subtest 'json_to_object: "containers":{} dies' => sub {
    dies_naming('json_to_object containers:{}',
        sub { IO::K8s->new->json_to_object('Pod', '{"spec":{"containers":{}}}') },
        qr/PodSpec/, qr/\bcontainers\b/, qr/HASH/);
};

# Claim: FROM_HASH reaches the same check, at the top level of its class.
subtest 'FROM_HASH: PodSpec->FROM_HASH({ containers => "x" }) dies' => sub {
    dies_naming('FROM_HASH containers=>"x"',
        sub { IO::K8s::Api::Core::V1::PodSpec->FROM_HASH({ containers => 'x' }) },
        qr/PodSpec/, qr/\bcontainers\b/);
};

# Claim: the constructor's nested coercion (spec is a hashref, built via the
# inflation) reaches the same check.
subtest 'constructor coercion: Pod->new(spec => { containers => "x" }) dies' => sub {
    dies_naming('Pod->new spec.containers=>"x"',
        sub { IO::K8s::Api::Core::V1::Pod->new(spec => { containers => 'x' }) },
        qr/PodSpec/, qr/\bcontainers\b/);
};

# ===========================================================================
# RED: hash of objects
# ===========================================================================

# Claim: an array where a hash of objects belongs names CounterSet, the
# field, the expected hash and ARRAY.
subtest 'hash of objects: counters => [...] dies' => sub {
    dies_naming('counters=>[]',
        sub { IO::K8s->new->struct_to_object($COUNTERSET, { name => 'c', counters => [ 'x' ] }) },
        qr/CounterSet/, qr/\bcounters\b/, qr/hash/i, qr/ARRAY/, qr/Counter\b/);
};

# Claim: a plain string there is refused the same way.
subtest 'hash of objects: counters => "x" dies' => sub {
    dies_naming('counters=>"x"',
        sub { IO::K8s->new->struct_to_object($COUNTERSET, { name => 'c', counters => 'x' }) },
        qr/CounterSet/, qr/\bcounters\b/, qr/plain scalar/);
};

# ===========================================================================
# RED: arrays and hashes of scalars (message form only -- the constructor's
# type check already refused these, without naming the class)
# ===========================================================================

# Claim: [Str] -- Container.args => {} names Container and args.
subtest 'array of scalars: args => {} dies naming Container' => sub {
    dies_naming('args=>{}',
        $pod_with_spec->({ containers => [ { name => 'a', args => {} } ] }),
        qr/Api::Core::V1::Container field args/, qr/array/i, qr/HASH/);
};

# Claim: { Quantity => 1 } -- ResourceRequirements.limits => [...] names the
# class and the field.
subtest 'typed hash of scalars: limits => [...] dies naming ResourceRequirements' => sub {
    dies_naming('limits=>[]',
        $pod_with_spec->({ containers => [ { name => 'a', resources => { limits => [ '1' ] } } ] }),
        qr/ResourceRequirements field limits/, qr/hash/i, qr/ARRAY/);
};

# Claim: { Str => 1 } -- the container check applies (labels was a HashRef
# before too); only the message changes.
subtest '{ Str => 1 }: labels => [...] dies naming ObjectMeta' => sub {
    dies_naming('labels=>[]',
        sub { IO::K8s->new->new_object('Pod', metadata => { name => 'p', labels => [ 'x' ] }) },
        qr/ObjectMeta field labels/, qr/hash/i, qr/ARRAY/);
};

# Claim: the generic forms [ {} ], [Bool] and { Int => 1 } get the same --
# and, since k191, the opaque map Opaque, which has no is_hash_of_ flag and
# is counted as a hash container by name (IO::K8s::_container_shape).
subtest 'generic container forms of a DSL class' => sub {
    my $k8s = IO::K8s->new;
    for my $case (
        [ docs   => 'x', qr/field docs\b.*array/i ],
        [ flags  => {},  qr/field flags\b.*array/i ],
        [ counts => [],  qr/field counts\b.*hash/i ],
        [ blob   => [],  qr/field blob\b.*hash/i ],
    ) {
        my ($field, $value, $re) = @$case;
        dies_naming("$field wrong shape",
            sub { $k8s->new_object('+T154::Bag', metadata => { name => 'b' }, spec => { $field => $value }) },
            $re, qr/T154::Bag/);
    }
};

# ===========================================================================
# GUARDS
# ===========================================================================

# Claim: undef and an absent key at an optional array field stay allowed.
subtest 'GUARD: undef / absent optional array field' => sub {
    my $pod = IO::K8s->new->new_object('Pod',
        metadata => { name => 'p' },
        spec     => { containers => [ { name => 'a' } ], initContainers => undef });
    ok(!defined $pod->spec->initContainers, 'initContainers => undef stays unset');
    ok(!exists $pod->TO_JSON->{spec}{ephemeralContainers}, 'absent field stays absent');
};

# Claim: empty containers of the right shape are fine.
subtest 'GUARD: empty array / empty hash of the right shape' => sub {
    my $k8s = IO::K8s->new;
    my $pod = $k8s->new_object('Pod', metadata => { name => 'p' }, spec => { containers => [] });
    is_deeply($pod->spec->containers, [], 'containers => []');
    my $cs = $k8s->struct_to_object($COUNTERSET, { name => 'c', counters => {} });
    is_deeply($cs->counters, {}, 'counters => {}');
};

# Claim: well-formed values build normally on every container form.
subtest 'GUARD: right shapes still build' => sub {
    my $b = IO::K8s->new->new_object('+T154::Bag',
        metadata => { name => 'b' },
        spec     => { docs => [ { a => 1 } ], flags => [ 1, 0 ], counts => { x => 3 } });
    is_deeply($b->TO_JSON->{spec},
        { docs => [ { a => 1 } ], flags => [ JSON::MaybeXS::true, JSON::MaybeXS::false ], counts => { x => 3 } },
        'wire form');
};

# Claim: the contents of an opaque map stay unconstrained. Before k191 this
# was asserted on labels/annotations, declared { Str => 1 }, which was the
# opaque map then. k191 made { Str => 1 } the string map (numbers go out as
# JSON strings; a nested structure still passes, with a deprecation warning
# -- t/151_k191_typed_maps.t), so the claim moved to an Opaque field, the
# opaque map's own spelling. The claim itself is unchanged.
subtest 'GUARD: opaque map (Opaque) contents stay untouched' => sub {
    my $bag = IO::K8s->new->new_object('+T154::Bag',
        metadata => { name => 'b' }, spec => { blob => { a => { b => 1 }, x => [ 1 ] } });
    is_deeply($bag->TO_JSON->{spec},
        { blob => { a => { b => 1 }, x => [ 1 ] } },
        'nested structures inside an Opaque field pass through as before');
};

# Claim: the direct constructor keeps failing at Moo's own type constraint --
# this change is about the inflation path, not about the attribute check.
subtest 'GUARD: direct PodSpec->new(containers => "x") keeps failing at the type constraint' => sub {
    throws_ok { IO::K8s::Api::Core::V1::PodSpec->new(containers => 'x') }
        qr/did not pass type constraint.*containers/s, 'Moo type check, as before';
};

done_testing;
