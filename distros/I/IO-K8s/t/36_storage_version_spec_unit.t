#!/usr/bin/env perl
# Standalone unit test for IO::K8s::Api::Apiserverinternal::V1alpha1::StorageVersionSpec.
#
# The class was added together with the bugfix to make karr ticket #3
# (missing StorageVersionSpec) a non-issue: without it,
# IO::K8s::Api::Apiserverinternal::V1alpha1::StorageVersion's `spec` slot
# failed to inflate.
#
# t/33 covers the class as a slot of StorageVersion; this test covers the
# class on its own — its role composition, instantiation, empty-struct
# serialisation, and the design intent that it is *not* an APIObject
# (it does not `use IO::K8s::APIObject;` and therefore does not expose
# api_version / kind).

use strict;
use warnings;
use Test::More;

my $SPEC = 'IO::K8s::Api::Apiserverinternal::V1alpha1::StorageVersionSpec';

# Make sure the class actually loads before doing anything else.
require_ok($SPEC);

subtest 'StorageVersionSpec consumes IO::K8s::Role::Resource' => sub {
    ok($SPEC->DOES('IO::K8s::Role::Resource'),
        'StorageVersionSpec DOES IO::K8s::Role::Resource');
};

subtest 'StorageVersionSpec can be instantiated with no arguments' => sub {
    my $obj = $SPEC->new;
    isa_ok($obj, $SPEC);
    ok(defined $obj, 'new returned a defined value');
};

subtest 'TO_JSON round-trips as an empty hash' => sub {
    my $obj   = $SPEC->new;
    my $struct = $obj->TO_JSON;
    is(ref $struct, 'HASH', 'TO_JSON returns a hashref');
    is_deeply($struct, {}, 'empty StorageVersionSpec serialises to {}');
};

subtest 'StorageVersionSpec is intentionally NOT an APIObject' => sub {
    # The class only does `use IO::K8s::Resource;`, not
    # `use IO::K8s::APIObject;`. Pin this contract so callers don't
    # accidentally start relying on api_version() / kind() on a struct
    # that has no Kubernetes apiVersion/kind of its own.
    my $obj = $SPEC->new;
    ok(!$obj->can('api_version'),
        'no api_version() — StorageVersionSpec is not an APIObject');
    ok(!$obj->can('kind'),
        'no kind() — StorageVersionSpec is not an APIObject');
    ok(!$obj->can('_is_resource'),
        'no _is_resource() — StorageVersionSpec is not an APIObject');
};

done_testing;
