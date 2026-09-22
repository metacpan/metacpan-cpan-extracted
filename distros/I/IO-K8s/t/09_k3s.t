#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use IO::K8s;
use IO::K8s::K3s;

# --- All K3s CRD classes ---

my %classes = (
    HelmChart        => { api_version => 'helm.cattle.io/v1',  plural => 'helmcharts',        namespaced => 1 },
    HelmChartConfig  => { api_version => 'helm.cattle.io/v1',  plural => 'helmchartconfigs',  namespaced => 1 },
    Addon            => { api_version => 'k3s.cattle.io/v1',   plural => 'addons',            namespaced => 1 },
    ETCDSnapshotFile => { api_version => 'k3s.cattle.io/v1',   plural => 'etcdsnapshotfiles', namespaced => 0 },
);

# --- Load all 4 classes ---

subtest 'load all K3s classes' => sub {
    for my $kind (sort keys %classes) {
        my $class = "IO::K8s::K3s::V1::$kind";
        use_ok($class) or BAIL_OUT("Cannot load $class");
    }
};

# --- Verify api_version, kind, resource_plural, namespaced ---

subtest 'class metadata' => sub {
    for my $kind (sort keys %classes) {
        my $class = "IO::K8s::K3s::V1::$kind";
        my $info = $classes{$kind};

        is($class->api_version, $info->{api_version}, "$kind api_version");
        is($class->kind, $kind, "$kind kind");
        is($class->resource_plural, $info->{plural}, "$kind resource_plural");
        if ($info->{namespaced}) {
            ok($class->does('IO::K8s::Role::Namespaced'), "$kind is namespaced");
        } else {
            ok(!$class->does('IO::K8s::Role::Namespaced'), "$kind is cluster-scoped (not namespaced)");
        }
    }
};

# --- IO::K8s::K3s resource_map completeness ---

subtest 'IO::K8s::K3s resource_map' => sub {
    my $provider = IO::K8s::K3s->new;
    ok($provider->does('IO::K8s::Role::ResourceMap'), 'consumes ResourceMap role');

    my $map = $provider->resource_map;
    is(scalar keys %$map, 4, 'resource_map has 4 entries');

    for my $kind (sort keys %classes) {
        ok(exists $map->{$kind}, "$kind in resource_map");
        is($map->{$kind}, "K3s::V1::$kind", "$kind maps to correct class path");
    }
};

# --- upstream_version ---

subtest 'IO::K8s::K3s upstream_version' => sub {
    my $provider = IO::K8s::K3s->new;
    is($provider->upstream_version, 'v1.36.4+k3s1', 'upstream_version reports latest tracked k3s release');
};

# --- new(with => ['IO::K8s::K3s']) integration ---

subtest 'with constructor parameter' => sub {
    my $k8s = IO::K8s->new(with => ['IO::K8s::K3s']);

    # All 3 K3s kinds should be resolvable by short name
    for my $kind (sort keys %classes) {
        is($k8s->expand_class($kind), "IO::K8s::K3s::V1::$kind",
            "expand_class('$kind') resolves");
    }

    # Domain-qualified access
    is($k8s->expand_class('helm.cattle.io/v1/HelmChart'),
        'IO::K8s::K3s::V1::HelmChart',
        'domain-qualified HelmChart resolves');
    is($k8s->expand_class('k3s.cattle.io/v1/Addon'),
        'IO::K8s::K3s::V1::Addon',
        'domain-qualified Addon resolves');
    is($k8s->expand_class('k3s.cattle.io/v1/ETCDSnapshotFile'),
        'IO::K8s::K3s::V1::ETCDSnapshotFile',
        'domain-qualified ETCDSnapshotFile resolves');

    # Core resources are unaffected
    is($k8s->expand_class('Pod'), 'IO::K8s::Api::Core::V1::Pod',
        'core Pod still resolves');
    is($k8s->expand_class('Deployment'), 'IO::K8s::Api::Apps::V1::Deployment',
        'core Deployment still resolves');
};

# --- new_object + inflate round-trip ---

subtest 'new_object and inflate round-trip' => sub {
    my $k8s = IO::K8s->new(with => ['IO::K8s::K3s']);

    # Create a HelmChart
    my $hc = $k8s->new_object('HelmChart',
        metadata => { name => 'traefik', namespace => 'kube-system' },
        spec => {
            chart => 'https://traefik.github.io/charts',
            version => '25.0.0',
        },
    );
    isa_ok($hc, 'IO::K8s::K3s::V1::HelmChart');
    is($hc->kind, 'HelmChart', 'kind');
    is($hc->api_version, 'helm.cattle.io/v1', 'api_version');
    isa_ok($hc->metadata, 'IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::ObjectMeta');
    is($hc->metadata->name, 'traefik', 'name');
    is($hc->metadata->namespace, 'kube-system', 'namespace');

    # Serialize and re-inflate
    my $json = $k8s->object_to_json($hc);
    like($json, qr/"apiVersion":"helm\.cattle\.io\/v1"/, 'JSON has apiVersion');
    like($json, qr/"kind":"HelmChart"/, 'JSON has kind');

    my $re = $k8s->inflate($json);
    isa_ok($re, 'IO::K8s::K3s::V1::HelmChart', 're-inflated');
    is($re->metadata->name, 'traefik', 'round-trip name preserved');
    is($re->metadata->namespace, 'kube-system', 'round-trip namespace preserved');

    # Create an Addon (different api_version)
    my $addon = $k8s->new_object('Addon',
        metadata => { name => 'coredns', namespace => 'kube-system' },
        spec => { source => '/var/lib/rancher/k3s/server/manifests/coredns.yaml' },
    );
    isa_ok($addon, 'IO::K8s::K3s::V1::Addon');
    is($addon->api_version, 'k3s.cattle.io/v1', 'Addon api_version');
    ok($addon->does('IO::K8s::Role::Namespaced'), 'Addon is namespaced');

    # Round-trip Addon
    my $addon_re = $k8s->inflate($k8s->object_to_json($addon));
    isa_ok($addon_re, 'IO::K8s::K3s::V1::Addon');
    is($addon_re->metadata->name, 'coredns', 'Addon round-trip');

    # Create an ETCDSnapshotFile (cluster-scoped, no namespace)
    my $snap = $k8s->new_object('ETCDSnapshotFile',
        metadata => { name => 'etcd-snapshot-node1-1234567890' },
        spec => {
            snapshotName => 'etcd-snapshot-node1-1234567890',
            nodeName     => 'node1',
            location     => 'file:///var/lib/rancher/k3s/server/db/snapshots/etcd-snapshot-node1-1234567890',
        },
    );
    isa_ok($snap, 'IO::K8s::K3s::V1::ETCDSnapshotFile');
    is($snap->api_version, 'k3s.cattle.io/v1', 'ETCDSnapshotFile api_version');
    ok(!$snap->does('IO::K8s::Role::Namespaced'), 'ETCDSnapshotFile is cluster-scoped');

    # Round-trip ETCDSnapshotFile
    my $snap_re = $k8s->inflate($k8s->object_to_json($snap));
    isa_ok($snap_re, 'IO::K8s::K3s::V1::ETCDSnapshotFile');
    is($snap_re->metadata->name, 'etcd-snapshot-node1-1234567890', 'ETCDSnapshotFile round-trip');
};

# --- to_yaml output ---

subtest 'to_yaml output' => sub {
    my $k8s = IO::K8s->new(with => ['IO::K8s::K3s']);

    my $hc = $k8s->new_object('HelmChart',
        metadata => { name => 'test-chart', namespace => 'default' },
        spec => { chart => 'nginx' },
    );
    my $yaml = $hc->to_yaml;
    like($yaml, qr/apiVersion: helm\.cattle\.io\/v1/, 'YAML apiVersion');
    like($yaml, qr/kind: HelmChart/, 'YAML kind');
    like($yaml, qr/name: test-chart/, 'YAML name');
    like($yaml, qr/namespace: default/, 'YAML namespace');
};

# --- Domain-qualified expand_class ---

subtest 'domain-qualified expand_class' => sub {
    my $k8s = IO::K8s->new(with => ['IO::K8s::K3s']);

    is($k8s->expand_class('helm.cattle.io/v1/HelmChart'),
        'IO::K8s::K3s::V1::HelmChart',
        'helm.cattle.io/v1/HelmChart resolves');
    is($k8s->expand_class('helm.cattle.io/v1/HelmChartConfig'),
        'IO::K8s::K3s::V1::HelmChartConfig',
        'helm.cattle.io/v1/HelmChartConfig resolves');
    is($k8s->expand_class('k3s.cattle.io/v1/Addon'),
        'IO::K8s::K3s::V1::Addon',
        'k3s.cattle.io/v1/Addon resolves');
    is($k8s->expand_class('k3s.cattle.io/v1/ETCDSnapshotFile'),
        'IO::K8s::K3s::V1::ETCDSnapshotFile',
        'k3s.cattle.io/v1/ETCDSnapshotFile resolves');

    # api_version parameter style
    is($k8s->expand_class('HelmChart', 'helm.cattle.io/v1'),
        'IO::K8s::K3s::V1::HelmChart',
        'api_version parameter disambiguation');
};

# --- pk8s DSL with K3s kinds ---

subtest 'pk8s DSL with K3s kinds' => sub {
    require File::Temp;
    my $k8s = IO::K8s->new(with => ['IO::K8s::K3s']);

    my ($fh, $filename) = File::Temp::tempfile(SUFFIX => '.pk8s', UNLINK => 1);
    print $fh q{
        HelmChart {
            name => 'traefik',
            namespace => 'kube-system',
            spec => { chart => 'traefik' },
        };

        HelmChartConfig {
            name => 'traefik-config',
            namespace => 'kube-system',
            spec => { valuesContent => 'ports:\n  web:\n    port: 8080' },
        };

        Addon {
            name => 'coredns',
            namespace => 'kube-system',
            spec => { source => '/manifests/coredns.yaml' },
        };
    };
    close $fh;

    my $objs = $k8s->load($filename);
    is(scalar(@$objs), 3, 'pk8s loaded 3 K3s objects');

    my ($hc, $hcc, $addon) = @$objs;

    isa_ok($hc, 'IO::K8s::K3s::V1::HelmChart');
    is($hc->kind, 'HelmChart', 'pk8s HelmChart kind');
    is($hc->metadata->name, 'traefik', 'pk8s HelmChart name');

    isa_ok($hcc, 'IO::K8s::K3s::V1::HelmChartConfig');
    is($hcc->kind, 'HelmChartConfig', 'pk8s HelmChartConfig kind');

    isa_ok($addon, 'IO::K8s::K3s::V1::Addon');
    is($addon->kind, 'Addon', 'pk8s Addon kind');
    is($addon->api_version, 'k3s.cattle.io/v1', 'pk8s Addon api_version');
};

# --- Full-depth round-trip (k95/D5/D6: K3s hand-modeled from the upstream
# Go types -- helm.cattle.io/v1 from k3s-io/helm-controller v0.17.7,
# k3s.cattle.io/v1 from k3s-io/api v0.1.4, both vendored by k3s v1.36.4+k3s1)

subtest 'full depth round-trip: HelmChart' => sub {
    my $k8s = IO::K8s->new(with => ['IO::K8s::K3s']);
    my $hc = $k8s->new_object('HelmChart',
        metadata => { name => 'traefik', namespace => 'kube-system' },
        spec => {
            chart              => 'traefik',
            repo               => 'https://traefik.github.io/charts',
            version            => '25.0.0',
            targetNamespace    => 'kube-system',
            createNamespace    => 1,
            set                => { 'ingressClass.enabled' => 'true', replicas => 3 },
            values             => { replicaCount => 3, image => { tag => 'v3.7.12' } },
            valuesContent      => "service:\n  type: LoadBalancer\n",
            valuesSecrets      => [{ name => 'traefik-overrides', keys => ['values.yaml'] }],
            bootstrap          => 1,
            failurePolicy      => 'retry',
            driver             => 'secret',
            serverSide         => 'auto',
            timeout            => '5m',
            authSecret         => { name => 'repo-creds' },
            podSecurityContext => { runAsNonRoot => 1 },
        },
        status => {
            jobName    => 'helm-install-traefik',
            conditions => [
                { type => 'JobCreated', status => 'True', reason => 'Created', message => 'job created' },
            ],
        },
    );

    isa_ok($hc->spec, 'IO::K8s::K3s::V1::HelmChartSpec');
    isa_ok($hc->spec->valuesSecrets->[0], 'IO::K8s::K3s::V1::SecretSpec');
    isa_ok($hc->spec->authSecret, 'IO::K8s::Api::Core::V1::LocalObjectReference');
    isa_ok($hc->spec->podSecurityContext, 'IO::K8s::Api::Core::V1::PodSecurityContext');
    isa_ok($hc->spec->values, 'IO::K8s::ApiextensionsApiserver::Pkg::Apis::Apiextensions::V1::JSON');
    isa_ok($hc->status, 'IO::K8s::K3s::V1::HelmChartStatus');
    isa_ok($hc->status->conditions->[0], 'IO::K8s::K3s::V1::HelmChartCondition');

    is($hc->spec->valuesSecrets->[0]->name, 'traefik-overrides', 'valuesSecrets[0].name');
    is($hc->spec->set->{replicas}, 3, 'set.replicas (IntOrStr, int given)');
    is($hc->spec->set->{'ingressClass.enabled'}, 'true', 'set with dotted key (IntOrStr, str given)');
    is($hc->spec->values->value->{replicaCount}, 3, 'values (apiextensions/v1.JSON) wraps the raw structure');
    is($hc->status->conditions->[0]->reason, 'Created', 'status.conditions[0].reason');

    my $json = $hc->TO_JSON;
    is($json->{spec}{chart}, 'traefik', 'TO_JSON spec.chart');
    is($json->{spec}{driver}, 'secret', 'TO_JSON spec.driver');
    is($json->{spec}{values}{image}{tag}, 'v3.7.12', 'TO_JSON spec.values emits the bare structure, not a wrapper');
    is($json->{spec}{valuesSecrets}[0]{keys}[0], 'values.yaml', 'TO_JSON spec.valuesSecrets[0].keys[0]');
    is($json->{status}{conditions}[0]{type}, 'JobCreated', 'TO_JSON status.conditions[0].type');

    my $re = $k8s->inflate($k8s->object_to_json($hc));
    isa_ok($re, 'IO::K8s::K3s::V1::HelmChart');
    is($re->spec->authSecret->name, 'repo-creds', 'JSON round-trip preserves spec.authSecret.name');
    is($re->spec->values->value->{image}{tag}, 'v3.7.12', 'JSON round-trip preserves spec.values');
};

subtest 'full depth round-trip: HelmChartConfig' => sub {
    my $k8s = IO::K8s->new(with => ['IO::K8s::K3s']);
    my $cfg = $k8s->new_object('HelmChartConfig',
        metadata => { name => 'traefik', namespace => 'kube-system' },
        spec => {
            valuesContent  => "additionalArguments:\n  - '--log.level=DEBUG'\n",
            valuesSecrets  => [{ name => 'traefik-secret-overrides' }],
            failurePolicy  => 'retry',
            serverSide     => 'true',
            forceConflicts => 1,
        },
    );

    isa_ok($cfg->spec, 'IO::K8s::K3s::V1::HelmChartConfigSpec');
    isa_ok($cfg->spec->valuesSecrets->[0], 'IO::K8s::K3s::V1::SecretSpec');
    is($cfg->spec->failurePolicy, 'retry', 'spec.failurePolicy');

    my $json = $cfg->TO_JSON;
    is($json->{spec}{valuesSecrets}[0]{name}, 'traefik-secret-overrides', 'TO_JSON spec.valuesSecrets[0].name');
    ok(!exists $json->{status}, 'HelmChartConfig has no status field (upstream Go type has none)');

    my $re = $k8s->inflate($k8s->object_to_json($cfg));
    isa_ok($re, 'IO::K8s::K3s::V1::HelmChartConfig');
    is($re->spec->serverSide, 'true', 'JSON round-trip preserves spec.serverSide');
};

subtest 'full depth round-trip: Addon' => sub {
    my $k8s = IO::K8s->new(with => ['IO::K8s::K3s']);
    my $addon = $k8s->new_object('Addon',
        metadata => { name => 'coredns', namespace => 'kube-system' },
        spec => {
            source   => '/var/lib/rancher/k3s/server/manifests/coredns.yaml',
            checksum => 'deadbeefcafef00d',
        },
    );

    isa_ok($addon->spec, 'IO::K8s::K3s::V1::AddonSpec');
    is($addon->spec->source, '/var/lib/rancher/k3s/server/manifests/coredns.yaml', 'spec.source');
    is($addon->spec->checksum, 'deadbeefcafef00d', 'spec.checksum');

    my $json = $addon->TO_JSON;
    is($json->{spec}{checksum}, 'deadbeefcafef00d', 'TO_JSON spec.checksum');
    ok(!exists $json->{status}, 'Addon has no status field (upstream Go type has none, +genclient:noStatus)');

    my $re = $k8s->inflate($k8s->object_to_json($addon));
    isa_ok($re, 'IO::K8s::K3s::V1::Addon');
    is($re->spec->source, '/var/lib/rancher/k3s/server/manifests/coredns.yaml', 'JSON round-trip preserves spec.source');
};

subtest 'full depth round-trip: ETCDSnapshotFile' => sub {
    my $k8s = IO::K8s->new(with => ['IO::K8s::K3s']);
    my $snap = $k8s->new_object('ETCDSnapshotFile',
        metadata => { name => 'etcd-snapshot-node1-1700000000' },
        spec => {
            snapshotName => 'etcd-snapshot-node1-1700000000',
            nodeName     => 'node1',
            location     => 's3://k3s-backups/snapshots/etcd-snapshot-node1-1700000000',
            metadata     => { 'cluster-id' => 'abc123' },
            s3           => {
                endpoint => 's3.example.com',
                bucket   => 'k3s-backups',
                region   => 'us-east-1',
                prefix   => 'snapshots',
                insecure => 0,
            },
        },
        status => {
            size         => '10485760',
            creationTime => '2026-01-01T00:00:00Z',
            readyToUse   => 1,
        },
    );

    isa_ok($snap->spec, 'IO::K8s::K3s::V1::ETCDSnapshotSpec');
    isa_ok($snap->spec->s3, 'IO::K8s::K3s::V1::ETCDSnapshotS3');
    isa_ok($snap->status, 'IO::K8s::K3s::V1::ETCDSnapshotStatus');

    is($snap->spec->s3->bucket, 'k3s-backups', 'spec.s3.bucket');
    is($snap->spec->metadata->{'cluster-id'}, 'abc123', 'spec.metadata (opaque map[string]string)');
    is($snap->status->readyToUse, 1, 'status.readyToUse');

    my $json = $snap->TO_JSON;
    is($json->{spec}{s3}{region}, 'us-east-1', 'TO_JSON spec.s3.region');
    is($json->{status}{size}, '10485760', 'TO_JSON status.size (Quantity stays a string)');

    my $re = $k8s->inflate($k8s->object_to_json($snap));
    isa_ok($re, 'IO::K8s::K3s::V1::ETCDSnapshotFile');
    is($re->spec->s3->bucket, 'k3s-backups', 'JSON round-trip preserves spec.s3.bucket');

    my $errored = $k8s->new_object('ETCDSnapshotFile',
        metadata => { name => 'failed-snap' },
        spec => {
            snapshotName => 'failed-snap',
            nodeName     => 'node2',
            location     => 'file:///var/lib/rancher/k3s/server/db/snapshots/failed-snap',
        },
        status => {
            error => { time => '2026-01-01T00:05:00Z', message => 'disk full' },
        },
    );
    isa_ok($errored->status->error, 'IO::K8s::K3s::V1::ETCDSnapshotError');
    is($errored->status->error->message, 'disk full', 'status.error.message');
};

# --- HelmManaged builder methods exercised against the typed spec ---

subtest 'HelmManaged builder methods on the typed HelmChartSpec' => sub {
    my $k8s = IO::K8s->new(with => ['IO::K8s::K3s']);
    my $chart = $k8s->new_object('HelmChart',
        metadata => { name => 'cilium', namespace => 'kube-system' },
    );

    $chart->from_repo('https://helm.cilium.io', 'cilium')
          ->set_version('1.20.1')
          ->set_values(replicas => 3, 'ipam.mode' => 'kubernetes')
          ->set_values_yaml("hubble:\n  enabled: true\n");

    isa_ok($chart->spec, 'IO::K8s::K3s::V1::HelmChartSpec');
    is($chart->spec->repo, 'https://helm.cilium.io', 'from_repo sets spec.repo on the typed spec');
    is($chart->spec->chart, 'cilium', 'from_repo sets spec.chart on the typed spec');
    is($chart->spec->version, '1.20.1', 'set_version on the typed spec');
    is($chart->spec->set->{replicas}, 3, 'set_values writes into the typed spec.set map');
    is($chart->spec->set->{'ipam.mode'}, 'kubernetes', 'set_values dotted key on the typed spec.set map');
    like($chart->spec->valuesContent, qr/hubble:/, 'set_values_yaml on the typed spec');

    my $re = $k8s->inflate($k8s->object_to_json($chart));
    is($re->spec->set->{replicas}, 3, 'JSON round-trip preserves builder-written spec.set');
};

done_testing;
