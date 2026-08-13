#!/usr/bin/env perl
# Regression coverage for karr tickets #7, #8, #10:
# a scattered set of upstream v1.36.3 fields/kinds that maint/spec-drift-check.pl
# found missing against the real swagger.json.
#
# #7: 14 fields missing on otherwise-shipped classes (Core::V1::ContainerStatus,
#     ::Lifecycle, ::PodCondition, ::PodSecurityContext, ::ResourceHealth,
#     Storage::V1::VolumeError, the two CustomResourceDefinitionCondition/Status
#     classes, Meta::V1::DeleteOptions/ListMeta, Version::Info), plus the new
#     Meta::V1::ShardInfo struct that ListMeta.shardInfo needed.
# #8: coordination.k8s.io/v1alpha2 (LeaseCandidate/LeaseCandidateSpec) was
#     entirely unshipped, and scheduling.k8s.io/v1alpha2.TypedLocalObjectReference
#     did not exist as its own class - WorkloadSpec.controllerRef pointed at
#     Core::V1::TypedLocalObjectReference instead, a different upstream schema
#     that happens to share the same three fields.
# #10: the meta.v1 discovery Kinds APIGroupList/APIResourceList (used by
#      /apis and /apis/<group>) were missing, unlike their already-shipped
#      siblings APIGroup/APIVersions/Status/DeleteOptions.
#
# This does not attempt full field coverage (t/34_registry_guard.t and
# t/02_compile_all.t already give every class that for free) - it exercises
# the specific gaps closed here plus one full round-trip each for the new
# Kind (LeaseCandidate) and the new discovery Lists.

use strict;
use warnings;
use Test::More;
use JSON::MaybeXS;

use IO::K8s;

my $k8s  = IO::K8s->new;
my $json = JSON::MaybeXS->new( utf8 => 0, canonical => 1, allow_nonref => 1 );

subtest 'karr #7: scattered field additions' => sub {
    my $cs = $k8s->struct_to_object(
        'IO::K8s::Api::Core::V1::ContainerStatus',
        { name => 'app', image => 'nginx', imageID => 'sha256:x', ready => JSON->true,
          restartCount => 0, stopSignal => 'SIGTERM' },
    );
    is( $cs->stopSignal, 'SIGTERM', 'ContainerStatus.stopSignal round-trips' );
    is( $k8s->object_to_struct($cs)->{stopSignal}, 'SIGTERM', 'stopSignal serializes' );

    my $pc = $k8s->struct_to_object(
        'IO::K8s::Api::Core::V1::PodCondition',
        { type => 'Ready', status => 'True', observedGeneration => 3 },
    );
    is( $pc->observedGeneration, 3, 'PodCondition.observedGeneration round-trips as an Int' );
    is( $k8s->object_to_struct($pc)->{observedGeneration}, 3, 'observedGeneration serializes unquoted' );

    my $ve = $k8s->struct_to_object(
        'IO::K8s::Api::Storage::V1::VolumeError',
        { errorCode => 13, message => 'boom' },
    );
    is( $ve->errorCode, 13, 'VolumeError.errorCode round-trips as an Int (upstream type: integer)' );

    my $do = $k8s->struct_to_object(
        'IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::DeleteOptions',
        { ignoreStoreReadErrorWithClusterBreakingPotential => JSON->true },
    );
    my $do_back = $k8s->object_to_struct($do);
    is( $do_back->{ignoreStoreReadErrorWithClusterBreakingPotential}, JSON->true,
        'DeleteOptions.ignoreStoreReadErrorWithClusterBreakingPotential serializes as a JSON boolean' );

    my $info = $k8s->struct_to_object(
        'IO::K8s::Apimachinery::Pkg::Version::Info',
        { major => '1', minor => '36', gitVersion => 'v1.36.3', gitCommit => 'abc',
          gitTreeState => 'clean', buildDate => '2026-01-01', goVersion => 'go1.24',
          compiler => 'gc', platform => 'linux/amd64',
          emulationMajor => '1', emulationMinor => '35',
          minCompatibilityMajor => '1', minCompatibilityMinor => '34' },
    );
    is( $info->emulationMajor,        '1',  'Info.emulationMajor round-trips' );
    is( $info->minCompatibilityMinor, '34', 'Info.minCompatibilityMinor round-trips' );
};

subtest 'karr #7: ListMeta.shardInfo is a real Meta::V1::ShardInfo, not a hashref' => sub {
    ok( eval { $k8s->load_class('IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::ShardInfo'); 1 },
        'ShardInfo loads' ) or diag $@;

    my $lm = $k8s->struct_to_object(
        'IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::ListMeta',
        { resourceVersion => '42', shardInfo => { selector => 'shard=0' } },
    );
    isa_ok( $lm->shardInfo, 'IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::ShardInfo' );
    is( $lm->shardInfo->selector, 'shard=0', 'shardInfo.selector round-trips' );
    is_deeply( $k8s->object_to_struct($lm)->{shardInfo}, { selector => 'shard=0' },
        'shardInfo serializes back to a plain selector hash' );
};

subtest 'karr #8: coordination.k8s.io/v1alpha2 LeaseCandidate round-trips byte-identical' => sub {
    my $LC = 'IO::K8s::Api::Coordination::V1alpha2::LeaseCandidate';
    ok( eval { $k8s->load_class($LC); 1 }, "$LC loads" ) or diag $@;
    ok( $LC->DOES('IO::K8s::Role::Namespaced'), "$LC is namespaced (paths carry namespaces/{namespace})" );

    my $hash = {
        apiVersion => 'coordination.k8s.io/v1alpha2',
        kind       => 'LeaseCandidate',
        metadata   => { name => 'candidate-1', namespace => 'kube-system' },
        spec       => {
            binaryVersion => '1.36.0',
            leaseName     => 'my-controller',
            strategy      => 'OldestEmulationVersion',
        },
    };
    my $obj = $k8s->struct_to_object( $LC, $hash );
    is( $obj->api_version, 'coordination.k8s.io/v1alpha2', 'api_version derived correctly' );
    is( $obj->metadata->namespace, 'kube-system', 'namespace preserved via Namespaced role' );
    isa_ok( $obj->spec, 'IO::K8s::Api::Coordination::V1alpha2::LeaseCandidateSpec' );

    my $back = $k8s->object_to_struct($obj);
    is( $json->encode($back), $json->encode($hash), 'round-trip identical' );

    my $again = $k8s->struct_to_object( $LC, $back );
    is( $json->encode( $k8s->object_to_struct($again) ), $json->encode($hash),
        'inflate -> TO_JSON -> inflate -> TO_JSON is idempotent' );
};

subtest 'karr #8: scheduling.k8s.io/v1alpha2.TypedLocalObjectReference is its own class' => sub {
    my $TLOR = 'IO::K8s::Api::Scheduling::V1alpha2::TypedLocalObjectReference';
    ok( eval { $k8s->load_class($TLOR); 1 }, "$TLOR loads" ) or diag $@;

    my $ws = $k8s->struct_to_object(
        'IO::K8s::Api::Scheduling::V1alpha2::WorkloadSpec',
        {
            controllerRef     => { kind => 'Job', name => 'batch-1' },
            podGroupTemplates => [ { name => 'main', schedulingPolicy => {} } ],
        },
    );
    isa_ok( $ws->controllerRef, $TLOR,
        'WorkloadSpec.controllerRef resolves to the scheduling/v1alpha2 schema, not Core::V1' );
};

subtest 'karr #10: meta.v1 discovery Kinds APIGroupList/APIResourceList' => sub {
    my $AGL = 'IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::APIGroupList';
    my $ARL = 'IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::APIResourceList';
    ok( eval { $k8s->load_class($AGL); 1 }, "$AGL loads" ) or diag $@;
    ok( eval { $k8s->load_class($ARL); 1 }, "$ARL loads" ) or diag $@;

    my $group_list = $k8s->struct_to_object(
        $AGL,
        {   groups => [
                {   name     => 'apps',
                    versions => [ { groupVersion => 'apps/v1', version => 'v1' } ],
                },
            ],
        },
    );
    is( scalar @{ $group_list->groups }, 1, 'APIGroupList.groups (required) passes through' );
    isa_ok( $group_list->groups->[0], 'IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::APIGroup' );

    my $resource_list = $k8s->struct_to_object(
        $ARL,
        {   groupVersion => 'apps/v1',
            resources    => [
                { name => 'deployments', singularName => 'deployment', namespaced => JSON->true, kind => 'Deployment', verbs => ['get'] },
            ],
        },
    );
    is( $resource_list->groupVersion, 'apps/v1', 'APIResourceList.groupVersion (required) passes through' );
    is( scalar @{ $resource_list->resources }, 1, 'APIResourceList.resources (required) passes through' );
    isa_ok( $resource_list->resources->[0], 'IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::APIResource' );
};

done_testing;
