#!/usr/bin/env perl
# k147 (RED): SpecBuilder's whole-field writes go through the Moo accessor
# (coercion + type constraint), but its element writes -- the ARRAY/HASH
# branches of _sb_store, and the item list spec_push builds via _sb_elem --
# write straight into the collection instead. A scalar-typed array element
# ([Bool], [Int], ...) is never normalized or checked; an object-array/typed
# -map element is only inflated when it already looks like the right shape
# (a hashref), so anything else -- a bare string, say -- is accepted as is
# and corrupts the collection silently, sometimes for good (the wire never
# says so; TO_JSON just serializes what is there) and sometimes until a
# later, unrelated call chokes on it (TO_JSON dying on a plain string that
# should have been a Container).
#
# Approved contract this file tests for (not yet implemented): every element
# write -- spec_push, indexed spec_set (including negative indices), and a
# typed map's per-key spec_set -- must apply the same effective
# coercion/type-check the field's whole-value accessor already applies.
# A bad element fails at the WRITE, named with spec-path context, not later
# at to_json. A multi-value spec_push is all-or-nothing for the target
# collection: if a later value is invalid, nothing from that call lands,
# including values before it that were themselves fine. A reference already
# handed out by spec_array/spec_hash stays connected to the object (same
# refaddr) and reflects reality after both a successful AND a failed
# builder write.
#
# Explicitly NOT covered here (non-goals per the approved contract): rolling
# back an intermediate node that a failed walk already vivified, a
# transaction spanning several spec_merge keys, direct external mutation of
# a container obtained via spec_array/spec_hash, or strict unknown-key
# checking after construction.
use strict;
use warnings;
use Test::More;
use Test::Exception;
use Scalar::Util qw(refaddr);
use lib 'lib';

use IO::K8s;

# ---------------------------------------------------------------------------
# Fixtures
# ---------------------------------------------------------------------------

{
    # The confirmed repro class from the ticket: a scalar-typed array
    # ([Bool]) directly on spec, with nothing else in the way.
    package T147::Flags;
    use IO::K8s::APIObject api_version => 'test.example.com/v1';
    k8s spec => { flags => [Bool] };
}

{
    # A second scalar-typed array, [Int], for the "is this easy enough to
    # cover too" scalar-constraint case -- the same shape of bug as [Bool],
    # kept in its own class so T147::Flags stays exactly the ticket's repro.
    package T147::Ports;
    use IO::K8s::APIObject api_version => 'test.example.com/v1';
    k8s spec => { ports => [Int] };
}

{
    # A genuinely opaque spec: there is no field type to enforce here, so
    # element writes are expected to keep behaving exactly as before the fix.
    # k191: declared Opaque now. It was `{ Str => 1 }`, which used to be the
    # opaque map and is a string map since k191; the GUARD below (values keep
    # their JSON types) is about the opaque map, so only the spelling moved.
    package T147::Opaque;
    use IO::K8s::APIObject api_version => 'test.example.com/v1';
    k8s spec => Opaque;
}

my $k8s = IO::K8s->new;

sub pod_with_containers {
    my (@containers) = @_;
    return $k8s->new_object('Pod',
        metadata => { name => 'p' },
        spec     => { containers => [@containers] },
    );
}

# ---------------------------------------------------------------------------
# RED: scalar-typed array elements ([Bool]) bypass the field's normalization
# ---------------------------------------------------------------------------

# Claim: spec_push onto a [Bool] field must apply the same Bool
# normalization the whole-field accessor already does -- the string 'false'
# must become the wire boolean false, not a Perl-truthy raw string that
# TO_JSON's truthiness check turns into true.
subtest 'RED k147: spec_push on [Bool] applies the field\'s Bool normalization' => sub {
    my $obj = T147::Flags->new(metadata => { name => 'f' }, spec => { flags => [] });
    $obj->spec_push('flags', 'false');

    my $got = $obj->TO_JSON->{spec}{flags}[0];
    is(ref($got), 'JSON::PP::Boolean',
        'pushed element is a real JSON boolean, the same wire type the whole-field path produces');
    is($got, 0, 'and it normalizes the string false to the wire false, not true');
};

# Claim: indexed spec_set -- an existing index and the '-1' idiom alike --
# on a [Bool] field must apply the same normalization, not write the raw
# value straight into the array.
subtest 'RED k147: indexed spec_set on [Bool] applies the field\'s Bool normalization' => sub {
    my $by_index = T147::Flags->new(metadata => { name => 'f1' }, spec => { flags => ['true'] });
    $by_index->spec_set('flags.0', 'false');
    is(ref($by_index->TO_JSON->{spec}{flags}[0]), 'JSON::PP::Boolean',
        'spec_set(\'flags.0\', ...) produces a real JSON boolean');
    is($by_index->TO_JSON->{spec}{flags}[0], 0, 'and normalizes false correctly');

    my $by_last = T147::Flags->new(metadata => { name => 'f2' }, spec => { flags => ['true'] });
    $by_last->spec_set('flags.-1', 'false');
    is(ref($by_last->TO_JSON->{spec}{flags}[0]), 'JSON::PP::Boolean',
        'spec_set(\'flags.-1\', ...) produces a real JSON boolean too');
    is($by_last->TO_JSON->{spec}{flags}[0], 0, 'and normalizes false correctly');
};

# Claim: the result of building a [Bool] field element-by-element must be
# identical to building it in one whole-field spec_set call.
subtest 'RED k147: spec_push result on [Bool] matches the whole-field spec_set result' => sub {
    my $pushed = T147::Flags->new(metadata => { name => 'f3' }, spec => { flags => [] });
    $pushed->spec_push('flags', 'false');

    my $whole = T147::Flags->new(metadata => { name => 'f3' }, spec => { flags => [] });
    $whole->spec_set('flags', ['false']);

    is_deeply($pushed->TO_JSON->{spec}{flags}, $whole->TO_JSON->{spec}{flags},
        'spec_push and whole-field spec_set produce the same wire array for the same logical value');
};

# ---------------------------------------------------------------------------
# RED: object-array elements accepted without becoming the element class
# ---------------------------------------------------------------------------

# Claim: spec_push onto an array of objects (Pod.spec.containers, a real
# shipped field) must refuse an element that cannot become the declared
# class, at push time, naming the path or the class -- not accept a bare
# string and defer the failure to TO_JSON.
subtest 'RED k147: spec_push onto an array of objects validates the element at push time' => sub {
    my $pod = pod_with_containers();
    throws_ok { $pod->spec_push('containers', 'bad') }
        qr/containers|Container/i,
        'a value that cannot become a Container is refused by spec_push itself';
};

# Claim: the same guarantee applies to an indexed spec_set into an existing
# array-of-objects slot.
subtest 'RED k147: indexed spec_set into an array of objects validates the element at write time' => sub {
    my $pod = pod_with_containers({ name => 'app', image => 'nginx' });
    throws_ok { $pod->spec_set('containers.0', 'bad') }
        qr/containers|Container/i,
        'a value that cannot become a Container is refused by spec_set itself';
};

# ---------------------------------------------------------------------------
# RED: multi-value spec_push must be all-or-nothing for the collection, and
# a reference already handed out by spec_array must stay connected and
# correct across both a successful and a FAILED push.
# ---------------------------------------------------------------------------

# Claim: when one of several values given to spec_push is invalid, NONE of
# them land -- not even the valid ones ahead of the bad one -- so the
# collection is exactly as it was before the call.
subtest 'RED k147: multi-value spec_push is all-or-nothing for the target collection' => sub {
    my $pod = pod_with_containers({ name => 'keep', image => 'nginx' });

    throws_ok {
        $pod->spec_push('containers', { name => 'ok', image => 'x' }, 'bad');
    } qr/containers|Container/i, 'a later invalid value in a multi-value push croaks';

    is(scalar(@{ $pod->spec->containers }), 1,
        'the container list still has exactly its original one element -- the valid value ahead of the bad one was not applied either');
    is($pod->spec->containers->[0]->name, 'keep',
        'and it is still the original element, untouched by the failed push');
};

# Claim: a reference obtained from spec_array before a spec_push call stays
# the live backing array (same refaddr) and reflects the true content
# afterwards, whether that push succeeded or failed. Today the push never
# fails at all, so this assertion is really the atomicity guarantee above
# seen through a reference taken beforehand.
subtest 'RED k147: a spec_array reference stays connected and correct after a FAILED spec_push' => sub {
    my $pod = pod_with_containers({ name => 'keep', image => 'nginx' });
    my $ref = $pod->spec_array('containers');
    my $addr = refaddr($ref);

    throws_ok { $pod->spec_push('containers', 'bad') }
        qr/containers|Container/i, 'the push is rejected';

    is(refaddr($pod->spec_array('containers')), $addr,
        'spec_array still returns the same backing array (refaddr) after the failed push');
    is(scalar(@$ref), 1,
        'and the array obtained BEFORE the failed push still shows only the original element -- nothing from the rejected push leaked in through it');
};

# ---------------------------------------------------------------------------
# RED: a typed hash-of-scalar map's per-key write skips the value's type
# ---------------------------------------------------------------------------

# Claim: IO::K8s::Api::Core::V1::ResourceRequirements.limits is a real
# shipped map[string]Quantity field (`k8s limits => { Quantity => 1 }`),
# reached here through Pod.spec.containers[0].resources.limits. An indexed
# spec_set into one of its keys must apply the Quantity constraint the
# whole-field accessor already applies to the hash as a unit.
subtest 'RED k147: indexed spec_set into a typed hash-of-Quantity map validates the value' => sub {
    my $bad = pod_with_containers({ name => 'app', image => 'nginx' });
    throws_ok { $bad->spec_set('containers.0.resources.limits.cpu', 'not-a-quantity') }
        qr/Quantity|limits/i,
        'an invalid Quantity value croaks at the indexed write, the way it already does on the whole field';

    my $good = pod_with_containers({ name => 'app', image => 'nginx' });
    $good->spec_set('containers.0.resources.limits.cpu', '500m');
    is($good->spec_get('containers.0.resources.limits.cpu'), '500m',
        'a valid value is still written and readable the same as via the whole field');
    like($good->to_json, qr/"cpu":"500m"/, 'and lands correctly on the wire');
};

# ---------------------------------------------------------------------------
# RED (bonus, per the ticket: "falls es eine einfache Moeglichkeit gibt"):
# a plain scalar constraint ([Int]) on an array element
# ---------------------------------------------------------------------------

# Claim: the same element-write gap applies to any scalar-typed array, not
# just [Bool] -- a non-Int element pushed onto a declared [Int] field must
# be refused, the way spec_set(['ports'], [...]) already is.
subtest 'RED k147: spec_push onto a [Int] field validates the element' => sub {
    my $obj = T147::Ports->new(metadata => { name => 'p' }, spec => { ports => [] });
    throws_ok { $obj->spec_push('ports', 'not-a-number') }
        qr/ports|Int/i,
        'a non-integer element croaks at push time, the way a whole-field spec_set would';
};

# ---------------------------------------------------------------------------
# GUARDS -- already correct today; must stay green after the fix
# ---------------------------------------------------------------------------

# Claim: a valid object hashref handed to spec_push is still inflated to the
# declared element class -- the bug is about invalid values slipping
# through unchecked, not about breaking the working case.
subtest 'GUARD: spec_push still inflates a valid object hashref' => sub {
    my $pod = pod_with_containers();
    $pod->spec_push('containers', { name => 'app', image => 'nginx' });
    isa_ok($pod->spec->containers->[0], 'IO::K8s::Api::Core::V1::Container',
        'pushed hashref inflated to the declared element class');
};

# Claim: '-1' on an empty array still vivifies a first element (the
# existing behaviour t/68_specbuilder_objects.t already pins for
# object-array fields; here on a [Bool] field instead).
subtest 'GUARD: -1 on an empty [Bool] array vivifies an element' => sub {
    my $obj = T147::Flags->new(metadata => { name => 'f' }, spec => { flags => [] });
    $obj->spec_set('flags.-1', 1);
    is(scalar(@{ $obj->spec->flags }), 1, 'one element created on the previously empty array');
};

# Claim: a reference obtained from spec_array before a SUCCESSFUL spec_push
# stays the live backing array and shows the new element.
subtest 'GUARD: a spec_array reference stays connected after a successful spec_push' => sub {
    my $pod = pod_with_containers();
    my $ref = $pod->spec_array('containers');
    my $addr = refaddr($ref);

    $pod->spec_push('containers', { name => 'app', image => 'nginx' });

    is(refaddr($pod->spec_array('containers')), $addr, 'same backing array (refaddr) after a successful push');
    is(scalar(@$ref), 1, 'and the reference taken beforehand now shows the new element');
};

# Claim: an opaque spec (Opaque) has no field type to enforce, so its
# element writes must keep behaving exactly as before the fix -- arbitrary
# values pass through untouched and keep their JSON types on the wire.
subtest 'GUARD: opaque spec (Opaque) element writes are unaffected' => sub {
    my $obj = T147::Opaque->new(metadata => { name => 'o' }, spec => { rules => [] });
    $obj->spec_push('rules', 'x', 3, { a => 1 });
    is_deeply($obj->spec->{rules}, [ 'x', 3, { a => 1 } ],
        'values pass through untouched, whatever their type');
    like($obj->to_json, qr/"rules":\["x",3,\{"a":1\}\]/,
        'and keep their JSON types on the wire (3 unquoted, the nested hash intact)');
};

# Claim: whole-field spec_set on a [Bool] field already normalizes
# correctly -- this is the behaviour the element-write paths above are
# claimed to match, not something this ticket needs to change.
subtest 'GUARD: whole-field spec_set on [Bool] already normalizes correctly' => sub {
    my $obj = T147::Flags->new(metadata => { name => 'f' }, spec => { flags => [] });
    $obj->spec_set('flags', ['false']);
    is(ref($obj->TO_JSON->{spec}{flags}[0]), 'JSON::PP::Boolean',
        'whole-field replacement produces a real JSON boolean');
    is($obj->TO_JSON->{spec}{flags}[0], 0, 'and normalizes the string false to the wire false');
};

done_testing;
