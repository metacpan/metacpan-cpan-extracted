#!/usr/bin/env perl
# Regression coverage for karr tickets #5 and #6 (v1.36.3 spec-drift sweep):
#
# #5: storagemigration.k8s.io is served by upstream v1.36 clusters ONLY
# under v1beta1 (v1alpha1 dropped from the spec). Only V1alpha1 was shipped,
# so IO::K8s::Api::Storagemigration::V1beta1::StorageVersionMigration(Spec|Status)
# and the GroupResource type it needs (Meta::V1::GroupResource) did not exist.
#
# #6: four Core::V1 classes gained a new optional $ref field in v1.36 whose
# target class was never shipped: EnvVarSource.fileKeyRef, NodeSystemInfo.swap,
# VolumeProjection.podCertificate, VolumeMountStatus.volumeStatus (which in turn
# needs ImageVolumeStatus). t/34_registry_guard.t cannot catch a field that was
# never declared in the first place -- this file exercises the new fields
# directly via inflate -> TO_JSON -> inflate round-trips, analogous to t/32/t/33.

use strict;
use warnings;
use Test::More;
use JSON::MaybeXS;

use IO::K8s;

my $k8s  = IO::K8s->new;
my $json = JSON::MaybeXS->new( utf8 => 0, canonical => 1, allow_nonref => 1 );

my $SVM        = 'IO::K8s::Api::Storagemigration::V1beta1::StorageVersionMigration';
my $SVM_SPEC   = 'IO::K8s::Api::Storagemigration::V1beta1::StorageVersionMigrationSpec';
my $SVM_STATUS = 'IO::K8s::Api::Storagemigration::V1beta1::StorageVersionMigrationStatus';
my $GROUP_RES  = 'IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::GroupResource';

subtest 'new v1beta1 storagemigration classes are shipped and loadable' => sub {
    ok( eval { $k8s->load_class($SVM); 1 },        'StorageVersionMigration loads' ) or diag($@);
    ok( eval { $k8s->load_class($SVM_SPEC); 1 },    'StorageVersionMigrationSpec loads' ) or diag($@);
    ok( eval { $k8s->load_class($SVM_STATUS); 1 },  'StorageVersionMigrationStatus loads' ) or diag($@);
    ok( eval { $k8s->load_class($GROUP_RES); 1 },   'GroupResource loads' ) or diag($@);
    ok( $SVM->DOES('IO::K8s::Role::APIObject'), 'StorageVersionMigration is a top-level API object' );
};

subtest 'StorageVersionMigration (v1beta1) full round-trip: inflate -> TO_JSON -> inflate' => sub {
    # apiVersion here is whatever this class's api_version() currently derives
    # (no 'storagemigration' entry in %API_GROUP_MAP yet -- pre-existing gap,
    # tracked separately; this test asserts round-trip stability, not the
    # upstream-correct group string).
    my $api_version = $SVM->api_version;

    my $hash = {
        apiVersion => $api_version,
        kind       => 'StorageVersionMigration',
        metadata   => { name => 'widgets-migration' },
        spec       => {
            resource => {
                group    => 'example.com',
                resource => 'widgets',
            },
        },
        status => {
            conditions => [
                {   type               => 'Running',
                    status             => 'True',
                    lastTransitionTime => '2026-01-02T03:04:05Z',
                    message            => 'migration in progress',
                    reason             => 'Migrating',
                },
            ],
            resourceVersion => '12345',
        },
    };

    my $obj = eval { $k8s->struct_to_object( $SVM, $hash ) };
    is( $@, '', 'no exception' ) or BAIL_OUT("inflate failed: $@");
    isa_ok( $obj,         $SVM );
    isa_ok( $obj->spec,   $SVM_SPEC );
    isa_ok( $obj->status, $SVM_STATUS );
    isa_ok( $obj->spec->resource, $GROUP_RES, 'spec.resource resolves to Meta::V1::GroupResource' );
    is( $obj->spec->resource->group,    'example.com', 'resource.group inflated' );
    is( $obj->spec->resource->resource, 'widgets',      'resource.resource inflated' );

    my $back = $k8s->object_to_struct($obj);
    is( $json->encode($back), $json->encode($hash),
        'serialised output equals the original input byte-for-byte (canonical)' );

    my $again = $k8s->struct_to_object( $SVM, $back );
    is( $json->encode( $k8s->object_to_struct($again) ),
        $json->encode($hash),
        'inflate -> struct -> inflate is idempotent' );
};

subtest 'EnvVarSource.fileKeyRef round-trips through Core::V1::FileKeySelector' => sub {
    my $EVS = 'IO::K8s::Api::Core::V1::EnvVarSource';
    my $FKS = 'IO::K8s::Api::Core::V1::FileKeySelector';

    ok( eval { $k8s->load_class($FKS); 1 }, 'FileKeySelector loads' ) or diag($@);

    my $hash = {
        fileKeyRef => {
            key        => 'MY_KEY',
            optional   => JSON::MaybeXS::false,
            path       => 'envs/my.env',
            volumeName => 'env-volume',
        },
    };

    my $obj = eval { $k8s->struct_to_object( $EVS, $hash ) };
    is( $@, '', 'no exception' ) or BAIL_OUT("inflate failed: $@");
    isa_ok( $obj->fileKeyRef, $FKS, 'fileKeyRef resolves to the new FileKeySelector class' );
    is( $obj->fileKeyRef->key,        'MY_KEY',      'key inflated' );
    is( $obj->fileKeyRef->path,       'envs/my.env', 'path inflated' );
    is( $obj->fileKeyRef->volumeName, 'env-volume',  'volumeName inflated' );

    my $back = $k8s->object_to_struct($obj);
    is( $json->encode($back), $json->encode($hash), 'fileKeyRef round-trips byte-for-byte' );
};

subtest 'VolumeMountStatus.volumeStatus round-trips through Core::V1::VolumeStatus/ImageVolumeStatus' => sub {
    my $VMS = 'IO::K8s::Api::Core::V1::VolumeMountStatus';
    my $VS  = 'IO::K8s::Api::Core::V1::VolumeStatus';
    my $IVS = 'IO::K8s::Api::Core::V1::ImageVolumeStatus';

    ok( eval { $k8s->load_class($VS); 1 },  'VolumeStatus loads' )      or diag($@);
    ok( eval { $k8s->load_class($IVS); 1 }, 'ImageVolumeStatus loads' ) or diag($@);

    my $hash = {
        mountPath    => '/var/data',
        name         => 'data',
        volumeStatus => {
            image => {
                imageRef => 'registry.example.com/image@sha256:abc123',
            },
        },
    };

    my $obj = eval { $k8s->struct_to_object( $VMS, $hash ) };
    is( $@, '', 'no exception' ) or BAIL_OUT("inflate failed: $@");
    isa_ok( $obj->volumeStatus,       $VS,  'volumeStatus resolves to the new VolumeStatus class' );
    isa_ok( $obj->volumeStatus->image, $IVS, 'volumeStatus.image resolves to ImageVolumeStatus' );
    is( $obj->volumeStatus->image->imageRef,
        'registry.example.com/image@sha256:abc123', 'imageRef inflated' );

    my $back = $k8s->object_to_struct($obj);
    is( $json->encode($back), $json->encode($hash), 'volumeStatus round-trips byte-for-byte' );
};

subtest 'NodeSystemInfo.swap and VolumeProjection.podCertificate load and inflate' => sub {
    my $NSI = 'IO::K8s::Api::Core::V1::NodeSystemInfo';
    my $NSS = 'IO::K8s::Api::Core::V1::NodeSwapStatus';
    my $VP  = 'IO::K8s::Api::Core::V1::VolumeProjection';
    my $PCP = 'IO::K8s::Api::Core::V1::PodCertificateProjection';

    ok( eval { $k8s->load_class($NSS); 1 }, 'NodeSwapStatus loads' )          or diag($@);
    ok( eval { $k8s->load_class($PCP); 1 }, 'PodCertificateProjection loads' ) or diag($@);

    my $nsi_hash = {
        architecture            => 'amd64',
        bootID                  => 'boot-1',
        containerRuntimeVersion => 'containerd://1.4.2',
        kernelVersion           => '6.1.0',
        kubeProxyVersion        => 'v1.36.3',
        kubeletVersion          => 'v1.36.3',
        machineID               => 'machine-1',
        operatingSystem         => 'linux',
        osImage                 => 'Debian GNU/Linux',
        swap                    => { capacity => 2147483648 },
        systemUUID              => 'uuid-1',
    };
    my $nsi = $k8s->struct_to_object( $NSI, $nsi_hash );
    isa_ok( $nsi->swap, $NSS, 'swap resolves to NodeSwapStatus' );
    is( $nsi->swap->capacity, 2147483648, 'capacity inflated' );
    is( $json->encode( $k8s->object_to_struct($nsi) ), $json->encode($nsi_hash),
        'NodeSystemInfo with swap round-trips byte-for-byte' );

    my $vp_hash = {
        podCertificate => {
            keyType    => 'ED25519',
            signerName => 'example.com/signer',
        },
    };
    my $vp = $k8s->struct_to_object( $VP, $vp_hash );
    isa_ok( $vp->podCertificate, $PCP, 'podCertificate resolves to PodCertificateProjection' );
    is( $vp->podCertificate->keyType,    'ED25519',            'keyType inflated' );
    is( $vp->podCertificate->signerName, 'example.com/signer', 'signerName inflated' );
    is( $json->encode( $k8s->object_to_struct($vp) ), $json->encode($vp_hash),
        'VolumeProjection with podCertificate round-trips byte-for-byte' );
};

done_testing;
