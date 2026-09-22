#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use IO::K8s;
use IO::K8s::PrometheusOperator;

# --- All Prometheus Operator CRD classes (matching upstream v0.93.1) ---

my %v1_classes = (
    Alertmanager   => { plural => 'alertmanagers',   namespaced => 1 },
    Prometheus     => { plural => 'prometheuses',    namespaced => 1 },
    ServiceMonitor => { plural => 'servicemonitors', namespaced => 1 },
    PodMonitor     => { plural => 'podmonitors',     namespaced => 1 },
    Probe          => { plural => 'probes',          namespaced => 1 },
    PrometheusRule => { plural => 'prometheusrules', namespaced => 1 },
);

my %v1alpha1_classes = (
    ScrapeConfig => { plural => 'scrapeconfigs', namespaced => 1 },
);

# --- Load all 7 Kind classes ---

subtest 'load all PrometheusOperator classes' => sub {
    for my $kind (sort keys %v1_classes) {
        my $class = "IO::K8s::PrometheusOperator::V1::$kind";
        use_ok($class) or BAIL_OUT("Cannot load $class");
    }
    for my $kind (sort keys %v1alpha1_classes) {
        my $class = "IO::K8s::PrometheusOperator::V1alpha1::$kind";
        use_ok($class) or BAIL_OUT("Cannot load $class");
    }
};

# --- Verify api_version, kind, resource_plural, namespaced ---

subtest 'V1 class metadata' => sub {
    for my $kind (sort keys %v1_classes) {
        my $class = "IO::K8s::PrometheusOperator::V1::$kind";
        my $info = $v1_classes{$kind};

        is($class->api_version, 'monitoring.coreos.com/v1', "$kind api_version");
        is($class->kind, $kind, "$kind kind");
        is($class->resource_plural, $info->{plural}, "$kind resource_plural");
        ok($class->does('IO::K8s::Role::Namespaced'), "$kind is namespaced");
    }
};

subtest 'V1alpha1 class metadata' => sub {
    for my $kind (sort keys %v1alpha1_classes) {
        my $class = "IO::K8s::PrometheusOperator::V1alpha1::$kind";
        my $info = $v1alpha1_classes{$kind};

        is($class->api_version, 'monitoring.coreos.com/v1alpha1', "$kind api_version");
        is($class->kind, $kind, "$kind kind");
        is($class->resource_plural, $info->{plural}, "$kind resource_plural");
        ok($class->does('IO::K8s::Role::Namespaced'), "$kind is namespaced");
    }
};

# --- IO::K8s::PrometheusOperator resource_map completeness ---

subtest 'IO::K8s::PrometheusOperator resource_map' => sub {
    my $provider = IO::K8s::PrometheusOperator->new;
    ok($provider->does('IO::K8s::Role::ResourceMap'), 'consumes ResourceMap role');
    is($provider->upstream_version, 'v0.93.1', 'upstream_version');

    my $map = $provider->resource_map;
    is(scalar keys %$map, 7, 'resource_map has 7 entries');

    for my $kind (sort keys %v1_classes) {
        ok(exists $map->{$kind}, "$kind in resource_map");
        is($map->{$kind}, "PrometheusOperator::V1::$kind", "$kind maps to correct class path");
    }
    for my $kind (sort keys %v1alpha1_classes) {
        ok(exists $map->{$kind}, "$kind in resource_map");
        is($map->{$kind}, "PrometheusOperator::V1alpha1::$kind", "$kind maps to correct class path");
    }
};

# --- new(with => ['IO::K8s::PrometheusOperator']) integration ---

subtest 'with constructor parameter' => sub {
    my $k8s = IO::K8s->new(with => ['IO::K8s::PrometheusOperator']);

    for my $kind (sort keys %v1_classes) {
        is($k8s->expand_class($kind), "IO::K8s::PrometheusOperator::V1::$kind",
            "expand_class('$kind') resolves");
    }
    for my $kind (sort keys %v1alpha1_classes) {
        is($k8s->expand_class($kind), "IO::K8s::PrometheusOperator::V1alpha1::$kind",
            "expand_class('$kind') resolves");
    }

    # Core resources are unaffected
    is($k8s->expand_class('Pod'), 'IO::K8s::Api::Core::V1::Pod', 'core Pod still resolves');
    is($k8s->expand_class('Deployment'), 'IO::K8s::Api::Apps::V1::Deployment', 'core Deployment still resolves');
};

# --- to_yaml output ---

subtest 'to_yaml output' => sub {
    my $k8s = IO::K8s->new(with => ['IO::K8s::PrometheusOperator']);
    my $rule = $k8s->new_object('PrometheusRule',
        metadata => { name => 'test-rules', namespace => 'default' },
        spec     => { groups => [ { name => 'grp', rules => [ { record => 'job:up:count', expr => 'sum(up)' } ] } ] },
    );
    my $yaml = $rule->to_yaml;
    like($yaml, qr/apiVersion: monitoring\.coreos\.com\/v1/, 'YAML apiVersion');
    like($yaml, qr/kind: PrometheusRule/, 'YAML kind');
    like($yaml, qr/name: test-rules/, 'YAML name');
};

# --- Full depth round-trip: Prometheus ---
# Exercises the deepest and largest Kind: shared classes (TLSConfig,
# SafeTLSConfig, BasicAuth, OAuth2, SafeAuthorization), the storage/volume
# subtree, and the three hand-written classes (Argument, ObjectReference)
# that AutoGen's reuse_core structurally (but wrongly) matched to an
# unrelated shipped class -- see IO::K8s::PrometheusOperator's own POD.

subtest 'full depth round-trip: Prometheus' => sub {
    my $k8s = IO::K8s->new(with => ['IO::K8s::PrometheusOperator']);

    my $prom = $k8s->new_object('Prometheus',
        metadata => { name => 'main', namespace => 'monitoring' },
        spec => {
            serviceAccountName     => 'prometheus',
            serviceMonitorSelector => { matchLabels => { team => 'sre' } },
            additionalArgs         => [
                { name => 'scrape.discovery-reload-interval', value => '30s' },
                { name => 'storage.tsdb.no-lockfile' },
            ],
            excludedFromEnforcement => [ { resource => 'servicemonitors', namespace => 'kube-system', name => 'foo' } ],
            imagePullSecrets        => [ { name => 'regcred' } ],
            volumeMounts            => [ { name => 'data', mountPath => '/data' } ],
            storage => {
                volumeClaimTemplate => {
                    spec => { accessModes => ['ReadWriteOnce'], resources => { requests => { storage => '10Gi' } } },
                },
            },
            remoteWrite => [ {
                url       => 'https://example.com/write',
                basicAuth => { username => { name => 'sec', key => 'user' }, password => { name => 'sec', key => 'pass' } },
                tlsConfig => { ca => { secret => { name => 'ca-secret', key => 'ca.crt' } }, insecureSkipVerify => 0 },
            } ],
            remoteRead => [ {
                url    => 'https://example.com/read',
                oauth2 => {
                    clientId     => { secret => { name => 'oauth', key => 'id' } },
                    clientSecret => { name => 'oauth', key => 'secret' },
                    tokenUrl     => 'https://example.com/token',
                    tlsConfig    => { insecureSkipVerify => 1 },
                },
            } ],
            thanos => {
                additionalArgs => [ { name => 'log.level', value => 'debug' } ],
            },
            alerting => {
                alertmanagers => [ {
                    name => 'alertmanager-main', namespace => 'monitoring', port => 'web',
                    authorization => { credentials => { name => 'am-token', key => 'token' } },
                } ],
            },
        },
    );

    isa_ok($prom->spec, 'IO::K8s::PrometheusOperator::V1::PrometheusSpec');

    isa_ok($prom->spec->additionalArgs->[0], 'IO::K8s::PrometheusOperator::V1::Argument',
        'additionalArgs uses the hand-written Argument class, not reuse_core\'s Core::V1::HTTPHeader');
    is($prom->spec->additionalArgs->[0]->name, 'scrape.discovery-reload-interval', 'Argument.name');
    is($prom->spec->additionalArgs->[0]->value, '30s', 'Argument.value');
    ok(!defined $prom->spec->additionalArgs->[1]->value, 'Argument.value optional (name-only argument)');

    isa_ok($prom->spec->excludedFromEnforcement->[0], 'IO::K8s::PrometheusOperator::V1::ObjectReference',
        'excludedFromEnforcement uses the hand-written ObjectReference class, not reuse_core\'s GatewayAPI ParentReference');
    is($prom->spec->excludedFromEnforcement->[0]->resource, 'servicemonitors', 'ObjectReference.resource');
    is($prom->spec->excludedFromEnforcement->[0]->namespace, 'kube-system', 'ObjectReference.namespace');
    ok(!defined $prom->spec->excludedFromEnforcement->[0]->group,
        'ObjectReference.group has no client-side default (server default is not applied client-side)');

    isa_ok($prom->spec->imagePullSecrets->[0], 'IO::K8s::Api::Core::V1::LocalObjectReference',
        'imagePullSecrets references the shipped core LocalObjectReference, not a duplicate one-field class');
    isa_ok($prom->spec->volumeMounts->[0], 'IO::K8s::PrometheusOperator::V1::VolumeMount');
    isa_ok($prom->spec->storage, 'IO::K8s::PrometheusOperator::V1::StorageSpec');
    isa_ok($prom->spec->storage->volumeClaimTemplate, 'IO::K8s::PrometheusOperator::V1::EmbeddedPersistentVolumeClaim');
    isa_ok($prom->spec->remoteWrite->[0], 'IO::K8s::PrometheusOperator::V1::RemoteWriteSpec');
    isa_ok($prom->spec->remoteWrite->[0]->basicAuth, 'IO::K8s::PrometheusOperator::V1::BasicAuth');
    isa_ok($prom->spec->remoteWrite->[0]->tlsConfig, 'IO::K8s::PrometheusOperator::V1::TLSConfig');
    isa_ok($prom->spec->remoteRead->[0]->oauth2, 'IO::K8s::PrometheusOperator::V1::OAuth2');
    isa_ok($prom->spec->remoteRead->[0]->oauth2->tlsConfig, 'IO::K8s::PrometheusOperator::V1::SafeTLSConfig');
    isa_ok($prom->spec->thanos, 'IO::K8s::PrometheusOperator::V1::ThanosSpec');
    isa_ok($prom->spec->thanos->additionalArgs->[0], 'IO::K8s::PrometheusOperator::V1::Argument',
        'Thanos-side additionalArgs shares the very same Argument class');
    isa_ok($prom->spec->alerting->alertmanagers->[0]->authorization, 'IO::K8s::PrometheusOperator::V1::SafeAuthorization');

    my $json = $prom->TO_JSON;
    is($json->{spec}{additionalArgs}[0]{value}, '30s', 'TO_JSON additionalArgs[0].value');
    ok(!exists $json->{spec}{additionalArgs}[1]{value}, 'TO_JSON omits unset additionalArgs[1].value');
    is($json->{spec}{excludedFromEnforcement}[0]{resource}, 'servicemonitors', 'TO_JSON excludedFromEnforcement resource');
    is($json->{spec}{remoteWrite}[0]{tlsConfig}{ca}{secret}{name}, 'ca-secret', 'TO_JSON deep remoteWrite tlsConfig.ca.secret.name');

    my $re = $k8s->inflate($k8s->object_to_json($prom));
    isa_ok($re, 'IO::K8s::PrometheusOperator::V1::Prometheus');
    is($re->spec->additionalArgs->[0]->name, 'scrape.discovery-reload-interval', 'JSON round-trip preserves Argument.name');
    is($re->spec->thanos->additionalArgs->[0]->value, 'debug', 'JSON round-trip preserves nested Thanos additionalArgs');
    is($re->spec->remoteRead->[0]->oauth2->tokenUrl, 'https://example.com/token', 'JSON round-trip preserves remoteRead.oauth2.tokenUrl');
    is($re->spec->storage->volumeClaimTemplate->spec->accessModes->[0], 'ReadWriteOnce',
        'JSON round-trip preserves deep storage.volumeClaimTemplate.spec.accessModes');
};

# --- Full depth round-trip: Alertmanager ---
# Exercises the third hand-written class (HostPort), and confirms the
# shared VolumeMount class is the SAME Perl class Prometheus uses (both
# Kinds embed the literal same upstream v1.VolumeMount).

subtest 'full depth round-trip: Alertmanager' => sub {
    my $k8s = IO::K8s->new(with => ['IO::K8s::PrometheusOperator']);

    my $am = $k8s->new_object('Alertmanager',
        metadata => { name => 'main', namespace => 'monitoring' },
        spec => {
            alertmanagerConfiguration => {
                global => {
                    smtp => {
                        smartHost => { host => 'smtp.example.com', port => '587' },
                        from      => 'alerts@example.com',
                    },
                },
            },
            volumeMounts     => [ { name => 'config', mountPath => '/etc/alertmanager' } ],
            imagePullSecrets => [ { name => 'regcred' } ],
        },
    );

    isa_ok($am->spec, 'IO::K8s::PrometheusOperator::V1::AlertmanagerSpec');
    isa_ok($am->spec->alertmanagerConfiguration->global->smtp->smartHost, 'IO::K8s::PrometheusOperator::V1::HostPort',
        'smartHost uses the hand-written HostPort class, not reuse_core\'s Core::V1::TCPSocketAction');
    is($am->spec->alertmanagerConfiguration->global->smtp->smartHost->host, 'smtp.example.com', 'HostPort.host');
    is($am->spec->alertmanagerConfiguration->global->smtp->smartHost->port, '587', 'HostPort.port');
    isa_ok($am->spec->imagePullSecrets->[0], 'IO::K8s::Api::Core::V1::LocalObjectReference');

    my $prom = $k8s->new_object('Prometheus',
        metadata => { name => 'main2', namespace => 'monitoring' },
        spec     => { volumeMounts => [ { name => 'data', mountPath => '/data' } ] },
    );
    is(ref($am->spec->volumeMounts->[0]), ref($prom->spec->volumeMounts->[0]),
        'Alertmanager and Prometheus share the SAME VolumeMount class (verified byte-identical schema)');

    my $re = $k8s->inflate($k8s->object_to_json($am));
    isa_ok($re, 'IO::K8s::PrometheusOperator::V1::Alertmanager');
    is($re->spec->alertmanagerConfiguration->global->smtp->smartHost->host, 'smtp.example.com',
        'JSON round-trip preserves HostPort.host');
    is($re->spec->alertmanagerConfiguration->global->smtp->smartHost->port, '587',
        'JSON round-trip preserves HostPort.port');
};

# --- Full depth round-trip: ServiceMonitor / PodMonitor / Probe ---
# ServiceMonitor's Endpoint embeds the TLS-FILES-capable HTTPConfig variant
# (upstream `TLSConfig`), while PodMonitor/Probe use the Secret/ConfigMap-only
# variant (upstream `SafeTLSConfig`) -- a real upstream distinction, so the
# two must NOT resolve to the same Perl class.

subtest 'full depth round-trip: ServiceMonitor / PodMonitor / Probe' => sub {
    my $k8s = IO::K8s->new(with => ['IO::K8s::PrometheusOperator']);

    my $sm = $k8s->new_object('ServiceMonitor',
        metadata => { name => 'web', namespace => 'default' },
        spec => {
            selector => { matchLabels => { app => 'web' } },
            endpoints => [ {
                port         => 'metrics',
                relabelings  => [ { sourceLabels => ['__meta_kubernetes_pod_name'], targetLabel => 'pod' } ],
                tlsConfig    => { insecureSkipVerify => 1 },
            } ],
        },
    );
    isa_ok($sm->spec->endpoints->[0], 'IO::K8s::PrometheusOperator::V1::Endpoint');
    isa_ok($sm->spec->endpoints->[0]->relabelings->[0], 'IO::K8s::PrometheusOperator::V1::RelabelConfig');
    isa_ok($sm->spec->endpoints->[0]->tlsConfig, 'IO::K8s::PrometheusOperator::V1::TLSConfig');
    my $sm_re = $k8s->inflate($k8s->object_to_json($sm));
    is($sm_re->spec->endpoints->[0]->relabelings->[0]->targetLabel, 'pod', 'JSON round-trip preserves relabelings.targetLabel');

    my $pm = $k8s->new_object('PodMonitor',
        metadata => { name => 'pods', namespace => 'default' },
        spec => {
            selector => { matchLabels => { app => 'worker' } },
            podMetricsEndpoints => [ {
                port      => 'metrics',
                basicAuth => { username => { name => 's', key => 'u' } },
                tlsConfig => { insecureSkipVerify => 1 },
            } ],
        },
    );
    isa_ok($pm->spec->podMetricsEndpoints->[0], 'IO::K8s::PrometheusOperator::V1::PodMetricsEndpoint');
    isa_ok($pm->spec->podMetricsEndpoints->[0]->basicAuth, 'IO::K8s::PrometheusOperator::V1::BasicAuth');
    isa_ok($pm->spec->podMetricsEndpoints->[0]->tlsConfig, 'IO::K8s::PrometheusOperator::V1::SafeTLSConfig',
        'PodMonitor endpoints use SafeTLSConfig (Secret/ConfigMap only), unlike ServiceMonitor\'s file-capable TLSConfig');
    my $pm_re = $k8s->inflate($k8s->object_to_json($pm));
    isa_ok($pm_re->spec->podMetricsEndpoints->[0]->basicAuth, 'IO::K8s::PrometheusOperator::V1::BasicAuth');

    my $probe = $k8s->new_object('Probe',
        metadata => { name => 'blackbox', namespace => 'default' },
        spec => {
            module  => 'http_2xx',
            prober  => { url => 'blackbox-exporter.default.svc:9115' },
            targets => { staticConfig => { static => ['https://example.com'] } },
        },
    );
    isa_ok($probe->spec, 'IO::K8s::PrometheusOperator::V1::ProbeSpec');
    isa_ok($probe->spec->prober, 'IO::K8s::PrometheusOperator::V1::ProberSpec');
    isa_ok($probe->spec->targets, 'IO::K8s::PrometheusOperator::V1::ProbeTargets');
    isa_ok($probe->spec->targets->staticConfig, 'IO::K8s::PrometheusOperator::V1::ProbeTargetStaticConfig');
    my $probe_re = $k8s->inflate($k8s->object_to_json($probe));
    is($probe_re->spec->targets->staticConfig->static->[0], 'https://example.com', 'JSON round-trip preserves static target');
};

# --- Full depth round-trip: PrometheusRule ---

subtest 'full depth round-trip: PrometheusRule' => sub {
    my $k8s = IO::K8s->new(with => ['IO::K8s::PrometheusOperator']);

    my $rule = $k8s->new_object('PrometheusRule',
        metadata => { name => 'rules', namespace => 'default' },
        spec => {
            groups => [ {
                name  => 'grp',
                rules => [ { alert => 'HighLatency', expr => 'up == 0', for => '5m', labels => { severity => 'page' } } ],
            } ],
        },
    );
    isa_ok($rule->spec, 'IO::K8s::PrometheusOperator::V1::PrometheusRuleSpec');
    isa_ok($rule->spec->groups->[0], 'IO::K8s::PrometheusOperator::V1::RuleGroup');
    isa_ok($rule->spec->groups->[0]->rules->[0], 'IO::K8s::PrometheusOperator::V1::Rule');
    is($rule->TO_JSON->{spec}{groups}[0]{rules}[0]{expr}, 'up == 0', 'TO_JSON deep rules[0].expr');

    my $re = $k8s->inflate($k8s->object_to_json($rule));
    isa_ok($re, 'IO::K8s::PrometheusOperator::V1::PrometheusRule');
    is($re->spec->groups->[0]->rules->[0]->alert, 'HighLatency', 'JSON round-trip preserves rules[0].alert');
    is($re->spec->groups->[0]->rules->[0]->labels->{severity}, 'page', 'JSON round-trip preserves rules[0].labels');
};

# --- Full depth round-trip: ScrapeConfig (monitoring.coreos.com/v1alpha1) ---
# ScrapeConfig embeds the SAME upstream v1 package types (SafeTLSConfig,
# BasicAuth, OAuth2, SafeAuthorization, RelabelConfig) across many
# per-provider service-discovery blocks, but as its OWN V1alpha1 copies
# (never sharing a class across the V1/V1alpha1 boundary -- same rule
# IO::K8s::Cilium's V2/V2alpha1 split follows). `Filter` (docker/
# dockerSwarm/ec2 SD configs) is a shared class within V1alpha1 reached via
# a named Go slice type (`Filters []Filter`), which is why it does not
# carry an "Item"-suffixed nested-schema name of its own.

subtest 'full depth round-trip: ScrapeConfig' => sub {
    my $k8s = IO::K8s->new(with => ['IO::K8s::PrometheusOperator']);

    my $sc = $k8s->new_object('ScrapeConfig',
        metadata => { name => 'sc1', namespace => 'default' },
        spec => {
            staticConfigs       => [ { targets => ['10.0.0.1:9100'], labels => { job => 'node' } } ],
            kubernetesSDConfigs => [ { role => 'Pod', basicAuth => { username => { name => 's', key => 'u' } } } ],
            dockerSDConfigs     => [ {
                host    => 'unix:///var/run/docker.sock',
                filters => [ { name => 'status', values => ['running'] } ],
            } ],
            relabelings => [ { action => 'keep', sourceLabels => ['__meta_kubernetes_namespace'] } ],
        },
    );

    isa_ok($sc->spec, 'IO::K8s::PrometheusOperator::V1alpha1::ScrapeConfigSpec');
    isa_ok($sc->spec->staticConfigs->[0], 'IO::K8s::PrometheusOperator::V1alpha1::StaticConfig');
    isa_ok($sc->spec->kubernetesSDConfigs->[0], 'IO::K8s::PrometheusOperator::V1alpha1::KubernetesSDConfig');
    isa_ok($sc->spec->kubernetesSDConfigs->[0]->basicAuth, 'IO::K8s::PrometheusOperator::V1alpha1::BasicAuth');
    isa_ok($sc->spec->dockerSDConfigs->[0], 'IO::K8s::PrometheusOperator::V1alpha1::DockerSDConfig');
    isa_ok($sc->spec->dockerSDConfigs->[0]->filters->[0], 'IO::K8s::PrometheusOperator::V1alpha1::Filter');
    isa_ok($sc->spec->relabelings->[0], 'IO::K8s::PrometheusOperator::V1alpha1::RelabelConfig');

    isnt(ref($sc->spec->kubernetesSDConfigs->[0]->basicAuth), ref($k8s->new_object('PodMonitor',
        metadata => { name => 'x', namespace => 'default' },
        spec     => { selector => {}, podMetricsEndpoints => [ { basicAuth => { username => { name=>'a',key=>'b'} } } ] },
    )->spec->podMetricsEndpoints->[0]->basicAuth),
        'ScrapeConfig (V1alpha1) BasicAuth is its own class, not shared across the V1/V1alpha1 boundary');

    my $json = $sc->TO_JSON;
    is($json->{spec}{dockerSDConfigs}[0]{filters}[0]{values}[0], 'running', 'TO_JSON deep dockerSDConfigs filters value');

    my $re = $k8s->inflate($k8s->object_to_json($sc));
    isa_ok($re, 'IO::K8s::PrometheusOperator::V1alpha1::ScrapeConfig');
    is($re->spec->dockerSDConfigs->[0]->filters->[0]->name, 'status', 'JSON round-trip preserves filters[0].name');
    is($re->spec->relabelings->[0]->action, 'keep', 'JSON round-trip preserves relabelings[0].action');
};

done_testing;
