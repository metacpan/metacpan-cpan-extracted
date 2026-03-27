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

done_testing;
