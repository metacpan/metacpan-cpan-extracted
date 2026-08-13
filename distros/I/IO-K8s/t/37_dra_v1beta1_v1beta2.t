#!/usr/bin/env perl
# Regression coverage for karr ticket #4:
# resource.k8s.io/v1beta1 was entirely missing (no V1beta1/ directory at all)
# and resource.k8s.io/v1beta2 shipped only 4 of its ~39 definitions (the
# DeviceTaintRule family from an earlier ticket). Any consumer talking to a
# cluster that serves DRA at v1beta1 (the most widely deployed DRA server
# version) or the fuller v1beta2 got "Can't locate .../DeviceClass.pm in @INC"
# for the core Kinds: DeviceClass, ResourceClaim, ResourceClaimTemplate,
# ResourceSlice.
#
# This test does not attempt full field coverage (that's what
# t/34_registry_guard.t and t/02_compile_all.t already give every class for
# free) - it exercises the registration/serialization path for the two Kinds
# most likely to be hit first (DeviceClass, ResourceClaim) on both newly
# shipped versions, plus three narrow regressions found and fixed while
# closing this ticket:
#
#   1. DeviceClass/ResourceSlice are cluster scoped, ResourceClaim/
#      ResourceClaimTemplate are namespaced - verified against the real
#      swagger.json paths, not just copied from the V1 sibling by pattern
#      match.
#   2. DeviceAttribute.bools ([Bool]) previously serialized as [1,0,1]
#      instead of [true,false,true], and FROM_HASH on a real JSON payload
#      with a boolean array died outright (JSON::PP::Boolean objects don't
#      satisfy Types::Standard's Bool). This was a latent bug already
#      present in the shipped V1::DeviceAttribute; fixed in
#      lib/IO/K8s/Resource.pm and lib/IO/K8s/Role/Resource.pm as part of
#      this ticket since v1beta1/v1beta2 ship the same field.
#   3. ResourceClaimTemplateSpec carries a real upstream `metadata:
#      ObjectMeta` field despite not being a Kind; it must be built on
#      IO::K8s::APIObject (like the shipped V1 sibling), not
#      IO::K8s::Resource, or the metadata attribute never gets registered.

use strict;
use warnings;
use Test::More;
use JSON::MaybeXS;

use IO::K8s;

my $k8s  = IO::K8s->new;
my $json = JSON::MaybeXS->new( utf8 => 0, canonical => 1, allow_nonref => 1 );

for my $v (qw(V1beta1 V1beta2)) {
    my $DeviceClass    = "IO::K8s::Api::Resource::${v}::DeviceClass";
    my $ResourceSlice  = "IO::K8s::Api::Resource::${v}::ResourceSlice";
    my $ResourceClaim  = "IO::K8s::Api::Resource::${v}::ResourceClaim";
    my $ResourceClaimTemplate = "IO::K8s::Api::Resource::${v}::ResourceClaimTemplate";
    my $api_version = 'resource.k8s.io/' . lc($v);

    subtest "$v: DeviceClass/ResourceSlice are cluster scoped, ResourceClaim/ResourceClaimTemplate are namespaced" => sub {
        ok( eval { $k8s->load_class($DeviceClass); 1 }, "$DeviceClass loads" ) or diag $@;
        ok( eval { $k8s->load_class($ResourceSlice); 1 }, "$ResourceSlice loads" ) or diag $@;
        ok( eval { $k8s->load_class($ResourceClaim); 1 }, "$ResourceClaim loads" ) or diag $@;
        ok( eval { $k8s->load_class($ResourceClaimTemplate); 1 }, "$ResourceClaimTemplate loads" ) or diag $@;

        ok( !$DeviceClass->DOES('IO::K8s::Role::Namespaced'), "$DeviceClass is cluster scoped" );
        ok( !$ResourceSlice->DOES('IO::K8s::Role::Namespaced'), "$ResourceSlice is cluster scoped" );
        ok( $ResourceClaim->DOES('IO::K8s::Role::Namespaced'), "$ResourceClaim is namespaced" );
        ok( $ResourceClaimTemplate->DOES('IO::K8s::Role::Namespaced'), "$ResourceClaimTemplate is namespaced" );
    };

    subtest "$v: DeviceClass inflate -> TO_JSON -> inflate round-trips byte-identical" => sub {
        my $hash = {
            apiVersion => $api_version,
            kind       => 'DeviceClass',
            metadata   => { name => 'gpu.example.com' },
            spec       => {
                selectors => [
                    { cel => { expression => qq{device.driver == "gpu.example.com"} } },
                ],
            },
        };
        my $obj = $k8s->struct_to_object( $DeviceClass, $hash );
        is( $obj->api_version, $api_version, 'api_version derived correctly' );
        my $back = $k8s->object_to_struct($obj);
        is( $json->encode($back), $json->encode($hash), 'round-trip identical' );

        my $again = $k8s->struct_to_object( $DeviceClass, $back );
        is( $json->encode( $k8s->object_to_struct($again) ), $json->encode($hash),
            'inflate -> TO_JSON -> inflate -> TO_JSON is idempotent' );
    };

    subtest "$v: ResourceClaim inflate -> TO_JSON -> inflate round-trips byte-identical" => sub {
        my $device_request =
            $v eq 'V1beta1'
            ? { name => 'req-1', deviceClassName => 'gpu.example.com' }
            : { name => 'req-1', exactly => { deviceClassName => 'gpu.example.com' } };

        my $hash = {
            apiVersion => $api_version,
            kind       => 'ResourceClaim',
            metadata   => { name => 'my-claim', namespace => 'default' },
            spec       => {
                devices => { requests => [$device_request] },
            },
        };
        my $obj = $k8s->struct_to_object( $ResourceClaim, $hash );
        is( $obj->api_version, $api_version, 'api_version derived correctly' );
        is( $obj->metadata->namespace, 'default', 'namespace preserved via Namespaced role' );
        my $back = $k8s->object_to_struct($obj);
        is( $json->encode($back), $json->encode($hash), 'round-trip identical' );
    };

    subtest "$v: ResourceClaimTemplateSpec carries the upstream metadata field" => sub {
        my $spec_class = "IO::K8s::Api::Resource::${v}::ResourceClaimTemplateSpec";
        $k8s->load_class($spec_class);
        ok( $spec_class->can('metadata'), "$spec_class has a metadata attribute" );

        # Built on IO::K8s::APIObject like its shipped V1 sibling, so TO_JSON
        # also emits the class-derived apiVersion/kind - not a real Kind,
        # but the established, already-shipped behaviour for this class.
        my $hash = {
            metadata => { labels => { app => 'demo' } },
            spec     => { devices => {} },
        };
        my $obj = $k8s->struct_to_object( $spec_class, $hash );
        is( $obj->metadata->labels->{app}, 'demo', 'metadata.labels round-trips' );
        my $back = $k8s->object_to_struct($obj);
        is_deeply( $back->{metadata}, $hash->{metadata}, 'metadata survives the round-trip' )
            or diag $json->encode($back);
        is_deeply( $back->{spec}{devices}, $hash->{spec}{devices}, 'spec survives the round-trip' );
    };
}

subtest 'DeviceAttribute.bools serializes as JSON booleans, not 0/1, and real JSON round-trips' => sub {
    for my $v (qw(V1beta1 V1beta2)) {
        my $class = "IO::K8s::Api::Resource::${v}::DeviceAttribute";
        my $hash  = { bools => [ 1, 0, 1 ] };

        my $obj = $k8s->struct_to_object( $class, $hash );
        my $out = $obj->to_json;
        is( $out, '{"bools":[true,false,true]}', "$class.bools serializes as JSON booleans" );

        # A real cluster response decodes booleans as JSON::PP::Boolean
        # objects, not plain 1/0. FROM_HASH on that used to die with a Moo
        # type constraint violation before this fix.
        my $decoded = JSON::MaybeXS->new->decode($out);
        my $roundtripped = eval { $class->FROM_HASH($decoded) };
        is( $@, '', "$class->FROM_HASH survives real JSON booleans" ) or diag $@;
        is( $roundtripped->to_json, $out, "$class round-trips byte-identical through real JSON" );
    }
};

done_testing;
