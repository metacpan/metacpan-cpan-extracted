#!/usr/bin/env perl
# Regression coverage for karr ticket #3:
# IO::K8s::Api::Apiserverinternal::V1alpha1::StorageVersionSpec.pm was
# never shipped. Because StorageVersion->spec is declared 'required' and
# the type specifier resolves cleanly via the default IO::K8s::Api prefix,
# every StorageVersion inflate died with "Can't locate .../StorageVersionSpec.pm
# in @INC". There was no working path through the class.
#
# Upstream (kubernetes.io, k8s.io/api/apiserverinternal/v1alpha1) declares
# StorageVersionSpec as an empty struct ("StorageVersionSpec is an empty
# spec"). That makes it the easiest class to ship, but the failure mode
# that matters is on the serialisation side: an empty class that is
# round-tripped through `TO_JSON` can collapse to an empty hash or disappear,
# both of which are observable differences downstream. This test asserts the
# full StorageVersion object inflates, that the spec slot is the new class,
# and that empty hashes round-trip as empty hashes on both legs.

use strict;
use warnings;
use Test::More;
use JSON::MaybeXS;

use IO::K8s;

my $k8s  = IO::K8s->new;
my $json = JSON::MaybeXS->new(utf8 => 0, canonical => 1, allow_nonref => 1);

my $SV     = 'IO::K8s::Api::Apiserverinternal::V1alpha1::StorageVersion';
my $SPEC   = 'IO::K8s::Api::Apiserverinternal::V1alpha1::StorageVersionSpec';
my $STATUS = 'IO::K8s::Api::Apiserverinternal::V1alpha1::StorageVersionStatus';
my $COND   = 'IO::K8s::Api::Apiserverinternal::V1alpha1::StorageVersionCondition';
my $SERVER = 'IO::K8s::Api::Apiserverinternal::V1alpha1::ServerStorageVersion';

# Upstream wire apiVersion for this group. The class derives this from its
# own package name via %API_GROUP_MAP (see IO::K8s::Role::APIObject); if
# the map is missing an entry, TO_JSON emits a syntactically plausible
# but rejected-by-the-API-server string instead. Regression coverage for
# the map lives in t/39_api_group_short_form.t.
my $API_VERSION = 'internal.apiserver.k8s.io/v1alpha1';

subtest 'StorageVersionSpec class is shipped and loadable' => sub {
    ok( eval { $k8s->load_class($SPEC); 1 }, 'StorageVersionSpec loads without dying' );
    ok( IO::K8s::Api::Apiserverinternal::V1alpha1::StorageVersionSpec->DOES('IO::K8s::Role::Resource'),
        'StorageVersionSpec consumes IO::K8s::Role::Resource' );
};

subtest 'minimal StorageVersion inflates without dying' => sub {
    my $hash = {
        apiVersion => $API_VERSION,
        kind       => 'StorageVersion',
        metadata   => { name => 'widgets.example.com' },
        spec       => {},
        status     => {
            commonEncodingVersion => 'v1',
            conditions            => [],
            storageVersions       => [],
        },
    };
    my $obj = eval { $k8s->struct_to_object( $SV, $hash ) };
    is( $@, '', 'no exception' ) or BAIL_OUT("inflate failed: $@");
    isa_ok( $obj, $SV );
    isa_ok( $obj->spec,   $SPEC,   'spec is the newly shipped empty-spec class' );
    isa_ok( $obj->status, $STATUS, 'status is the shipped Status class' );
};

subtest 'empty spec survives the round-trip' => sub {
    my $hash = {
        apiVersion => $API_VERSION,
        kind       => 'StorageVersion',
        metadata   => { name => 'x' },
        spec       => {},
        status     => {
            commonEncodingVersion => 'v1',
            conditions            => [],
            storageVersions       => [],
        },
    };
    my $obj  = $k8s->struct_to_object( $SV, $hash );
    my $back = $k8s->object_to_struct($obj);
    ok( exists $back->{spec}, 'spec key present in serialised output' );
    is( ref $back->{spec}, 'HASH', 'spec serialised as an object/hash, not absent' );
    is( scalar( keys %{ $back->{spec} } ), 0, 'spec round-trips as an empty hash' );
    is( $json->encode($back), $json->encode($hash), 'round-trip identical' );
};

subtest 'non-empty status with one condition + storageVersion round-trips' => sub {
    my $hash = {
        apiVersion => $API_VERSION,
        kind       => 'StorageVersion',
        metadata   => { name => 'y' },
        spec       => {},
        status     => {
            commonEncodingVersion => 'v1',
            conditions            => [
                {   type                => 'AllDecodable',
                    status              => 'True',
                    lastTransitionTime  => '2026-01-02T03:04:05Z',
                    message             => 'all good',
                    reason              => 'Local',
                },
            ],
            storageVersions => [
                {   apiServerID       => 'node-1',
                    decodableVersions => [ 'v1', 'v1beta1' ],
                    encodingVersion   => 'v1',
                    servedVersions    => [ 'v1', 'v1beta1' ],
                },
            ],
        },
    };
    my $obj  = $k8s->struct_to_object( $SV, $hash );
    my $back = $k8s->object_to_struct($obj);
    isa_ok( $obj->status->conditions->[0],      $COND,   'condition class resolved' );
    isa_ok( $obj->status->storageVersions->[0], $SERVER, 'storageVersion entry class resolved' );
    is( $json->encode($back), $json->encode($hash), 'full object round-trips byte-for-byte' );
};

subtest 'inflate -> struct -> inflate is idempotent' => sub {
    my $hash = {
        apiVersion => $API_VERSION,
        kind       => 'StorageVersion',
        metadata   => { name => 'z' },
        spec       => {},
        status     => {
            commonEncodingVersion => 'v1',
            conditions            => [],
            storageVersions       => [],
        },
    };
    my $a = $k8s->struct_to_object( $SV, $hash );
    my $b = $k8s->struct_to_object( $SV, $k8s->object_to_struct($a) );
    is(
        $json->encode( $k8s->object_to_struct($b) ),
        $json->encode($hash),
        'inflate -> TO_JSON -> inflate -> TO_JSON matches the original'
    );
};

done_testing;
