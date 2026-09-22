#!/usr/bin/env perl
# D9: IO::K8s::CRD->new(classes => [...], storage => 'v1') assembles ONE
# multi-version CustomResourceDefinition from one class per version -- the
# assembly layer over Task 2's Class->to_crd / IO::K8s::CRD::crd_for_class
# (t/79_to_crd.t). See docs/superpowers/specs/2026-09-03-crd-design.md, D9:
# "IO::K8s::CRD->new(classes => [...], storage => 'v1') assembles a
# multi-version CRD from one class per version."
use strict;
use warnings;
use Test::More;
use Test::Exception;
use Scalar::Util qw( blessed reftype );

use IO::K8s;
use IO::K8s::CRD;

# --- fixtures: same Kind (both packages end in '::Widget', so ->kind is
# 'Widget' for both -- see IO::K8s::Role::APIObject->kind), same group and
# resource_plural, two API versions with genuinely different spec shapes. ---

{
    package Test80::V1::Widget;
    use IO::K8s::APIObject
        api_version     => 'crdstep5.example.com/v1',
        resource_plural => 'widgets80';
    with 'IO::K8s::Role::Namespaced';

    k8s name => Str, 'required';
    k8s size => Int;

    1;
}

{
    package Test80::V1beta1::Widget;
    use IO::K8s::APIObject
        api_version     => 'crdstep5.example.com/v1beta1',
        resource_plural => 'widgets80';
    with 'IO::K8s::Role::Namespaced';

    k8s name       => Str, 'required';
    k8s legacySize => Str;

    1;
}

# Same group/version/plural as Test80::V1::Widget, but a different Kind
# (package ends '::Gadget') -- for the kind-mismatch guard.
{
    package Test80::V1::Gadget;
    use IO::K8s::APIObject
        api_version     => 'crdstep5.example.com/v1',
        resource_plural => 'widgets80';
    with 'IO::K8s::Role::Namespaced';

    k8s name => Str, 'required';

    1;
}

# Same Kind/plural/version as Test80::V1::Widget, but a different group --
# for the group-mismatch guard.
{
    package Test80::OtherGroup::Widget;
    use IO::K8s::APIObject
        api_version     => 'othergroup.example.com/v1',
        resource_plural => 'widgets80';
    with 'IO::K8s::Role::Namespaced';

    k8s name => Str, 'required';

    1;
}

# Same group/kind/version as Test80::V1::Widget, but a different
# resource_plural -- for the plural-mismatch guard.
{
    package Test80::OtherPlural::Widget;
    use IO::K8s::APIObject
        api_version     => 'crdstep5.example.com/v1',
        resource_plural => 'widgetsalt80';
    with 'IO::K8s::Role::Namespaced';

    k8s name => Str, 'required';

    1;
}

# Same group/kind/plural/scope/version ('v1') as Test80::V1::Widget -- a
# distinct class that is nonetheless NOT a distinct version -- for the
# duplicate-version guard.
{
    package Test80::V1Dup::Widget;
    use IO::K8s::APIObject
        api_version     => 'crdstep5.example.com/v1',
        resource_plural => 'widgets80';
    with 'IO::K8s::Role::Namespaced';

    k8s name => Str, 'required';

    1;
}

# Same group/kind/version/plural as Test80::V1::Widget, but Cluster-scoped
# (no IO::K8s::Role::Namespaced) -- for the scope-mismatch guard.
{
    package Test80::ClusterScope::Widget;
    use IO::K8s::APIObject
        api_version     => 'crdstep5.example.com/v1',
        resource_plural => 'widgets80';

    k8s name => Str, 'required';

    1;
}

# JSON::MaybeXS booleans are blessed scalar refs; flatten so is_deeply does
# not depend on the JSON backend or singleton identity (same helper as
# t/79_to_crd.t).
sub _flatten_bools {
    my ($val) = @_;
    return { map { $_ => _flatten_bools($val->{$_}) } keys %$val } if ref $val eq 'HASH';
    return [ map { _flatten_bools($_) } @$val ]                    if ref $val eq 'ARRAY';
    return ($val ? 1 : 0) if blessed($val) && (reftype($val) // '') eq 'SCALAR';
    return $val;
}

subtest 'multi-version assembly: two versions, correct storage flag, order as given' => sub {
    my $crd = IO::K8s::CRD->new(
        classes => [ 'Test80::V1::Widget', 'Test80::V1beta1::Widget' ],
        storage => 'v1',
    );
    isa_ok($crd, 'IO::K8s::ApiextensionsApiserver::Pkg::Apis::Apiextensions::V1::CustomResourceDefinition');
    is($crd->spec->group, 'crdstep5.example.com', 'spec.group shared by both classes');
    is($crd->spec->scope, 'Namespaced', 'spec.scope shared by both classes');
    is($crd->spec->names->kind, 'Widget', 'spec.names.kind shared by both classes');
    is($crd->spec->names->plural, 'widgets80', 'spec.names.plural shared by both classes');
    is($crd->metadata->name, 'widgets80.crdstep5.example.com', 'metadata.name is plural.group');

    my $versions = $crd->spec->versions;
    is(scalar @$versions, 2, 'one spec.versions entry per class');
    is_deeply([ map { $_->name } @$versions ], [ 'v1', 'v1beta1' ], 'versions ordered as given, not re-sorted');
    is_deeply([ map { $_->served } @$versions ], [ 1, 1 ], 'every version is served');
    is_deeply([ map { $_->storage } @$versions ], [ 1, 0 ], 'only the storage-named version is storage:true');

    is_deeply(
        _flatten_bools($versions->[0]->schema->openAPIV3Schema->TO_JSON),
        _flatten_bools(IO::K8s::CRD::_schema_for_class('Test80::V1::Widget')),
        'v1 entry schema matches Task 2 single-version schema for the v1 class (oracle)',
    );
    is_deeply(
        _flatten_bools($versions->[1]->schema->openAPIV3Schema->TO_JSON),
        _flatten_bools(IO::K8s::CRD::_schema_for_class('Test80::V1beta1::Widget')),
        'v1beta1 entry schema matches Task 2 single-version schema for the v1beta1 class (oracle)',
    );

    ok(exists $versions->[0]->schema->openAPIV3Schema->TO_JSON->{properties}{size}, 'v1 schema carries its own field (size)');
    ok(!exists $versions->[0]->schema->openAPIV3Schema->TO_JSON->{properties}{legacySize}, 'v1 schema does not carry the v1beta1-only field');
    ok(exists $versions->[1]->schema->openAPIV3Schema->TO_JSON->{properties}{legacySize}, 'v1beta1 schema carries its own field (legacySize)');
    ok(!exists $versions->[1]->schema->openAPIV3Schema->TO_JSON->{properties}{size}, 'v1beta1 schema does not carry the v1-only field');
};

subtest 'order as given: reversing the classes list reverses spec.versions' => sub {
    my $crd = IO::K8s::CRD->new(
        classes => [ 'Test80::V1beta1::Widget', 'Test80::V1::Widget' ],
        storage => 'v1',
    );
    my $versions = $crd->spec->versions;
    is_deeply([ map { $_->name } @$versions ], [ 'v1beta1', 'v1' ], 'spec.versions follows classes order, not a version-sort');
    is_deeply([ map { $_->storage } @$versions ], [ 0, 1 ], 'storage flag still tracks the named version regardless of position');
};

subtest 'mismatch guards' => sub {
    throws_ok {
        IO::K8s::CRD->new(classes => [ 'Test80::V1::Widget', 'Test80::V1::Gadget' ], storage => 'v1');
    } qr/disagree on kind/, 'differing kind across classes croaks';

    throws_ok {
        IO::K8s::CRD->new(classes => [ 'Test80::V1::Widget', 'Test80::OtherGroup::Widget' ], storage => 'v1');
    } qr/disagree on group/, 'differing group across classes croaks';

    throws_ok {
        IO::K8s::CRD->new(classes => [ 'Test80::V1::Widget', 'Test80::OtherPlural::Widget' ], storage => 'v1');
    } qr/disagree on plural/, 'differing resource_plural across classes croaks';

    throws_ok {
        IO::K8s::CRD->new(classes => [ 'Test80::V1::Widget', 'Test80::ClusterScope::Widget' ], storage => 'v1');
    } qr/disagree on scope/, 'differing scope (Namespaced vs Cluster) across classes croaks';

    throws_ok {
        IO::K8s::CRD->new(classes => [ 'Test80::V1::Widget', 'Test80::V1beta1::Widget' ], storage => 'v2');
    } qr/storage 'v2' does not name any/, 'a storage naming no given class croaks';

    throws_ok {
        IO::K8s::CRD->new(classes => [ 'Test80::V1::Widget', 'Test80::V1Dup::Widget' ], storage => 'v1');
    } qr/duplicate version name\(s\) \(v1\)/, 'two classes naming the same version croaks, even though group/kind/plural/scope all agree';

    throws_ok {
        IO::K8s::CRD->new(classes => [], storage => 'v1');
    } qr/non-empty/, 'empty classes croaks';

    throws_ok {
        IO::K8s::CRD->new(classes => [ 'Test80::V1::Widget' ]);
    } qr/storage/, 'missing storage croaks';
};

subtest 'Class->to_crd (Task 2) is unchanged: single-version shorthand still works' => sub {
    my $crd = Test80::V1::Widget->to_crd;
    isa_ok($crd, 'IO::K8s::ApiextensionsApiserver::Pkg::Apis::Apiextensions::V1::CustomResourceDefinition');
    is(scalar @{ $crd->spec->versions }, 1, 'to_crd still yields exactly one version');
    is($crd->spec->versions->[0]->name, 'v1', 'still the class own version');
    is($crd->spec->versions->[0]->storage, 1, 'still storage:true');
    is($crd->spec->versions->[0]->served, 1, 'still served:true');
    is_deeply(
        IO::K8s::CRD::crd_for_class('Test80::V1::Widget')->TO_JSON,
        $crd->TO_JSON,
        'IO::K8s::CRD->new(classes => [$class], storage => <its version>) matches crd_for_class exactly',
    );
};

done_testing;
