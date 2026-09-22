#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use IO::K8s;
use IO::K8s::VolumeSnapshot;

# --- All VolumeSnapshot CRD classes (matching upstream external-snapshotter v8.6.0) ---

my %v1_classes = (
    VolumeSnapshot        => { plural => 'volumesnapshots',        namespaced => 1 },
    VolumeSnapshotClass   => { plural => 'volumesnapshotclasses',  namespaced => 0 },
    VolumeSnapshotContent => { plural => 'volumesnapshotcontents', namespaced => 0 },
);

# --- Load all 3 top-level classes ---

subtest 'load all VolumeSnapshot classes' => sub {
    for my $kind (sort keys %v1_classes) {
        my $class = "IO::K8s::VolumeSnapshot::V1::$kind";
        use_ok($class) or BAIL_OUT("Cannot load $class");
    }
};

# --- Verify api_version, kind, resource_plural, namespaced/cluster-scoped ---

subtest 'V1 class metadata' => sub {
    for my $kind (sort keys %v1_classes) {
        my $class = "IO::K8s::VolumeSnapshot::V1::$kind";
        my $info  = $v1_classes{$kind};

        is($class->api_version, 'snapshot.storage.k8s.io/v1', "$kind api_version");
        is($class->kind, $kind, "$kind kind");
        is($class->resource_plural, $info->{plural}, "$kind resource_plural");
        if ($info->{namespaced}) {
            ok($class->does('IO::K8s::Role::Namespaced'), "$kind is namespaced");
        } else {
            ok(!$class->does('IO::K8s::Role::Namespaced'), "$kind is cluster-scoped");
        }
    }
};

# --- IO::K8s::VolumeSnapshot resource_map completeness ---

subtest 'IO::K8s::VolumeSnapshot resource_map' => sub {
    my $provider = IO::K8s::VolumeSnapshot->new;
    ok($provider->does('IO::K8s::Role::ResourceMap'), 'consumes ResourceMap role');
    is($provider->upstream_version, 'v8.6.0', 'upstream_version pin');

    my $map = $provider->resource_map;
    is(scalar keys %$map, 12, 'resource_map has 12 entries (3 VolumeSnapshot plus 9 VolumeGroupSnapshot registrations)');

    for my $kind (sort keys %v1_classes) {
        ok(exists $map->{$kind}, "$kind in resource_map");
        is($map->{$kind}, "VolumeSnapshot::V1::$kind", "$kind maps to correct class path");
    }

    my $sources = $provider->crd_sources;
    is($sources->{status}, 'ok', 'crd_sources status ok');
    like($sources->{base}, qr{external-snapshotter/v8\.6\.0/client/config/crd$}, 'crd_sources base URL');
    is_deeply(
        $sources->{files},
        [
            'snapshot.storage.k8s.io_volumesnapshotclasses.yaml',
            'snapshot.storage.k8s.io_volumesnapshotcontents.yaml',
            'snapshot.storage.k8s.io_volumesnapshots.yaml',
            'groupsnapshot.storage.k8s.io_volumegroupsnapshotclasses.yaml',
            'groupsnapshot.storage.k8s.io_volumegroupsnapshotcontents.yaml',
            'groupsnapshot.storage.k8s.io_volumegroupsnapshots.yaml',
        ],
        'crd_sources lists all 6 pinned Snapshot and GroupSnapshot manifests',
    );
};

# --- new(with => ['IO::K8s::VolumeSnapshot']) integration ---

subtest 'with constructor parameter' => sub {
    my $k8s = IO::K8s->new(with => ['IO::K8s::VolumeSnapshot']);

    for my $kind (sort keys %v1_classes) {
        is($k8s->expand_class($kind), "IO::K8s::VolumeSnapshot::V1::$kind",
            "expand_class('$kind') resolves");
    }

    is($k8s->expand_class('snapshot.storage.k8s.io/v1/VolumeSnapshot'),
        'IO::K8s::VolumeSnapshot::V1::VolumeSnapshot',
        'domain-qualified VolumeSnapshot resolves');

    # Core resources are unaffected
    is($k8s->expand_class('Pod'), 'IO::K8s::Api::Core::V1::Pod', 'core Pod still resolves');
    is($k8s->expand_class('PersistentVolumeClaim'), 'IO::K8s::Api::Core::V1::PersistentVolumeClaim',
        'core PersistentVolumeClaim still resolves');
};

# --- new_object + inflate round-trip: VolumeSnapshot (namespaced) ---

subtest 'new_object and inflate round-trip: VolumeSnapshot' => sub {
    my $k8s = IO::K8s->new(with => ['IO::K8s::VolumeSnapshot']);

    my $vs = $k8s->new_object('VolumeSnapshot',
        metadata => { name => 'my-snapshot', namespace => 'default' },
        spec => {
            source => { persistentVolumeClaimName => 'my-pvc' },
            volumeSnapshotClassName => 'csi-hostpath-snapclass',
        },
    );
    isa_ok($vs, 'IO::K8s::VolumeSnapshot::V1::VolumeSnapshot');
    is($vs->kind, 'VolumeSnapshot', 'kind');
    is($vs->api_version, 'snapshot.storage.k8s.io/v1', 'api_version');
    isa_ok($vs->metadata, 'IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::ObjectMeta');
    is($vs->metadata->name, 'my-snapshot', 'name');
    is($vs->metadata->namespace, 'default', 'namespace');
    ok($vs->does('IO::K8s::Role::Namespaced'), 'VolumeSnapshot is namespaced');

    isa_ok($vs->spec, 'IO::K8s::VolumeSnapshot::V1::VolumeSnapshotSpec');
    isa_ok($vs->spec->source, 'IO::K8s::VolumeSnapshot::V1::VolumeSnapshotSource');
    is($vs->spec->source->persistentVolumeClaimName, 'my-pvc', 'spec.source.persistentVolumeClaimName');
    is($vs->spec->volumeSnapshotClassName, 'csi-hostpath-snapclass', 'spec.volumeSnapshotClassName');

    my $json = $k8s->object_to_json($vs);
    like($json, qr/"apiVersion":"snapshot\.storage\.k8s\.io\/v1"/, 'JSON has apiVersion');
    like($json, qr/"kind":"VolumeSnapshot"/, 'JSON has kind');

    my $re = $k8s->inflate($json);
    isa_ok($re, 'IO::K8s::VolumeSnapshot::V1::VolumeSnapshot', 're-inflated');
    is($re->metadata->name, 'my-snapshot', 'round-trip name preserved');
    is($re->spec->source->persistentVolumeClaimName, 'my-pvc', 'round-trip spec.source preserved');

    my $yaml = $vs->to_yaml;
    like($yaml, qr/apiVersion: snapshot\.storage\.k8s\.io\/v1/, 'YAML apiVersion');
    like($yaml, qr/kind: VolumeSnapshot/, 'YAML kind');
    like($yaml, qr/name: my-snapshot/, 'YAML name');
};

# --- full depth round-trip: VolumeSnapshot status (Quantity restoreSize, shared VolumeSnapshotError) ---

subtest 'full depth round-trip: VolumeSnapshot status' => sub {
    my $k8s = IO::K8s->new(with => ['IO::K8s::VolumeSnapshot']);

    my $vs = $k8s->new_object('VolumeSnapshot',
        metadata => { name => 'bound-snapshot', namespace => 'default' },
        spec => { source => { volumeSnapshotContentName => 'existing-content' } },
        status => {
            boundVolumeSnapshotContentName => 'existing-content',
            readyToUse   => 1,
            creationTime => '2026-01-01T00:00:00Z',
            restoreSize  => '5Gi',
            error        => { message => 'transient failure', time => '2026-01-01T00:01:00Z' },
        },
    );

    isa_ok($vs->status, 'IO::K8s::VolumeSnapshot::V1::VolumeSnapshotStatus');
    is($vs->status->restoreSize, '5Gi', 'status.restoreSize is a Quantity string');
    isa_ok($vs->status->error, 'IO::K8s::VolumeSnapshot::V1::VolumeSnapshotError');
    is($vs->status->error->message, 'transient failure', 'status.error.message');
    ok($vs->status->readyToUse, 'status.readyToUse true');

    my $json = $vs->TO_JSON;
    is($json->{status}{restoreSize}, '5Gi', 'TO_JSON status.restoreSize');
    is($json->{status}{error}{message}, 'transient failure', 'TO_JSON deep status.error.message');
    ok($json->{status}{readyToUse}, 'TO_JSON status.readyToUse true');

    my $re = $k8s->inflate($k8s->object_to_json($vs));
    isa_ok($re, 'IO::K8s::VolumeSnapshot::V1::VolumeSnapshot');
    is($re->status->error->message, 'transient failure', 'JSON round-trip preserves deep status.error.message');
    is($re->status->restoreSize, '5Gi', 'JSON round-trip preserves status.restoreSize');
};

# --- new_object + inflate round-trip: VolumeSnapshotClass (flat, cluster-scoped) ---

subtest 'new_object and inflate round-trip: VolumeSnapshotClass' => sub {
    my $k8s = IO::K8s->new(with => ['IO::K8s::VolumeSnapshot']);

    my $vsc = $k8s->new_object('VolumeSnapshotClass',
        metadata => { name => 'csi-hostpath-snapclass' },
        driver => 'hostpath.csi.k8s.io',
        deletionPolicy => 'Delete',
        parameters => { foo => 'bar' },
    );
    isa_ok($vsc, 'IO::K8s::VolumeSnapshot::V1::VolumeSnapshotClass');
    is($vsc->kind, 'VolumeSnapshotClass', 'kind');
    ok(!$vsc->does('IO::K8s::Role::Namespaced'), 'VolumeSnapshotClass is cluster-scoped');
    is($vsc->driver, 'hostpath.csi.k8s.io', 'driver');
    is($vsc->deletionPolicy, 'Delete', 'deletionPolicy');
    is($vsc->parameters->{foo}, 'bar', 'parameters hash preserved');

    my $re = $k8s->inflate($k8s->object_to_json($vsc));
    isa_ok($re, 'IO::K8s::VolumeSnapshot::V1::VolumeSnapshotClass');
    is($re->driver, 'hostpath.csi.k8s.io', 'round-trip driver preserved');

    eval {
        $k8s->new_object('VolumeSnapshotClass',
            metadata => { name => 'bad' },
            driver => 'hostpath.csi.k8s.io',
            deletionPolicy => 'NotAValue',
        );
    };
    like($@, qr/is not one of/, 'deletionPolicy enum is enforced');
};

# --- full depth round-trip: VolumeSnapshotContent (cluster-scoped, reuses core ObjectReference) ---

subtest 'full depth round-trip: VolumeSnapshotContent' => sub {
    my $k8s = IO::K8s->new(with => ['IO::K8s::VolumeSnapshot']);

    my $vsc = $k8s->new_object('VolumeSnapshotContent',
        metadata => { name => 'content-1' },
        spec => {
            deletionPolicy => 'Retain',
            driver         => 'hostpath.csi.k8s.io',
            source         => { volumeHandle => 'vol-handle-1' },
            volumeSnapshotClassName => 'csi-hostpath-snapclass',
            volumeSnapshotRef => {
                name      => 'my-snapshot',
                namespace => 'default',
            },
        },
        status => {
            readyToUse   => 1,
            creationTime => 1735689600000000000,
            restoreSize  => 5368709120,
            snapshotHandle => 'snap-handle-1',
            error        => { message => 'none' },
        },
    );

    isa_ok($vsc, 'IO::K8s::VolumeSnapshot::V1::VolumeSnapshotContent');
    ok(!$vsc->does('IO::K8s::Role::Namespaced'), 'VolumeSnapshotContent is cluster-scoped');

    isa_ok($vsc->spec, 'IO::K8s::VolumeSnapshot::V1::VolumeSnapshotContentSpec');
    isa_ok($vsc->spec->source, 'IO::K8s::VolumeSnapshot::V1::VolumeSnapshotContentSource');
    is($vsc->spec->source->volumeHandle, 'vol-handle-1', 'spec.source.volumeHandle');
    isa_ok($vsc->spec->volumeSnapshotRef, 'IO::K8s::Api::Core::V1::ObjectReference',
        'volumeSnapshotRef reuses core ObjectReference');
    is($vsc->spec->volumeSnapshotRef->name, 'my-snapshot', 'spec.volumeSnapshotRef.name');
    is($vsc->spec->volumeSnapshotRef->namespace, 'default', 'spec.volumeSnapshotRef.namespace');

    isa_ok($vsc->status, 'IO::K8s::VolumeSnapshot::V1::VolumeSnapshotContentStatus');
    is($vsc->status->restoreSize, 5368709120, 'status.restoreSize is a plain Int (bytes)');
    isa_ok($vsc->status->error, 'IO::K8s::VolumeSnapshot::V1::VolumeSnapshotError',
        'VolumeSnapshotContentStatus.error shares the VolumeSnapshotError class');

    my $json = $vsc->TO_JSON;
    is($json->{spec}{volumeSnapshotRef}{name}, 'my-snapshot', 'TO_JSON deep spec.volumeSnapshotRef.name');
    is($json->{status}{restoreSize}, 5368709120, 'TO_JSON status.restoreSize numeric');

    my $re = $k8s->inflate($k8s->object_to_json($vsc));
    isa_ok($re, 'IO::K8s::VolumeSnapshot::V1::VolumeSnapshotContent');
    is($re->spec->volumeSnapshotRef->namespace, 'default',
        'JSON round-trip preserves deep spec.volumeSnapshotRef.namespace');
    is($re->status->error->message, 'none', 'JSON round-trip preserves deep status.error.message');
};

done_testing;
