#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use IO::K8s;
use IO::K8s::ExternalSecrets;

# --- All ExternalSecrets CRD classes (matching upstream external-secrets v2.10.0) ---

my %v1_classes = (
    ExternalSecret        => { plural => 'externalsecrets',        namespaced => 1 },
    SecretStore           => { plural => 'secretstores',           namespaced => 1 },
    ClusterSecretStore    => { plural => 'clustersecretstores',    namespaced => 0 },
    ClusterExternalSecret => { plural => 'clusterexternalsecrets', namespaced => 0 },
);

my %v1alpha1_classes = (
    PushSecret        => { plural => 'pushsecrets',        namespaced => 1 },
    ClusterPushSecret => { plural => 'clusterpushsecrets', namespaced => 0 },
);

# generators.external-secrets.io/v1alpha1 -- a separate API group from the
# external-secrets.io one above (upstream Go package apis/generators/v1alpha1,
# not apis/externalsecrets/*), despite sharing both the "v1alpha1" version
# string and the V1alpha1 namespace with PushSecret's own group -- the same
# one-provider/two-groups layout CertManager already uses for
# cert-manager.io/v1 + acme.cert-manager.io/v1, disambiguated by each
# class's own api_version rather than a path segment (k113).
my %generators_classes = (
    ACRAccessToken                               => { plural => 'acraccesstokens',                               namespaced => 1 },
    BeyondtrustWorkloadCredentialsDynamicSecret  => { plural => 'beyondtrustworkloadcredentialsdynamicsecrets',  namespaced => 1 },
    CloudsmithAccessToken                        => { plural => 'cloudsmithaccesstokens',                        namespaced => 1 },
    ClusterGenerator                              => { plural => 'clustergenerators',                            namespaced => 0 },
    ECRAuthorizationToken                        => { plural => 'ecrauthorizationtokens',                        namespaced => 1 },
    Fake                                          => { plural => 'fakes',                                        namespaced => 1 },
    GCRAccessToken                                => { plural => 'gcraccesstokens',                              namespaced => 1 },
    GeneratorState                                => { plural => 'generatorstates',                              namespaced => 1 },
    GithubAccessToken                             => { plural => 'githubaccesstokens',                           namespaced => 1 },
    GitlabDeployToken                             => { plural => 'gitlabdeploytokens',                           namespaced => 1 },
    Grafana                                       => { plural => 'grafanas',                                     namespaced => 1 },
    MFA                                           => { plural => 'mfas',                                         namespaced => 1 },
    Password                                      => { plural => 'passwords',                                    namespaced => 1 },
    QuayAccessToken                               => { plural => 'quayaccesstokens',                             namespaced => 1 },
    SSHKey                                        => { plural => 'sshkeys',                                      namespaced => 1 },
    STSSessionToken                               => { plural => 'stssessiontokens',                             namespaced => 1 },
    UUID                                          => { plural => 'uuids',                                        namespaced => 1 },
    VaultDynamicSecret                            => { plural => 'vaultdynamicsecrets',                          namespaced => 1 },
    Webhook                                       => { plural => 'webhooks',                                     namespaced => 1 },
);

# --- Load all classes ---

subtest 'load all ExternalSecrets classes' => sub {
    for my $kind (sort keys %v1_classes) {
        my $class = "IO::K8s::ExternalSecrets::V1::$kind";
        use_ok($class) or BAIL_OUT("Cannot load $class");
    }
    for my $kind (sort keys %v1alpha1_classes) {
        my $class = "IO::K8s::ExternalSecrets::V1alpha1::$kind";
        use_ok($class) or BAIL_OUT("Cannot load $class");
    }
    for my $kind (sort keys %generators_classes) {
        my $class = "IO::K8s::ExternalSecrets::V1alpha1::$kind";
        use_ok($class) or BAIL_OUT("Cannot load $class");
    }
};

# --- Verify api_version, kind, resource_plural, namespaced ---

subtest 'V1 class metadata' => sub {
    for my $kind (sort keys %v1_classes) {
        my $class = "IO::K8s::ExternalSecrets::V1::$kind";
        my $info = $v1_classes{$kind};

        is($class->api_version, 'external-secrets.io/v1', "$kind api_version");
        is($class->kind, $kind, "$kind kind");
        is($class->resource_plural, $info->{plural}, "$kind resource_plural");
        if ($info->{namespaced}) {
            ok($class->does('IO::K8s::Role::Namespaced'), "$kind is namespaced");
        } else {
            ok(!$class->does('IO::K8s::Role::Namespaced'), "$kind is cluster-scoped");
        }
    }
};

subtest 'V1alpha1 class metadata' => sub {
    for my $kind (sort keys %v1alpha1_classes) {
        my $class = "IO::K8s::ExternalSecrets::V1alpha1::$kind";
        my $info = $v1alpha1_classes{$kind};

        is($class->api_version, 'external-secrets.io/v1alpha1', "$kind api_version");
        is($class->kind, $kind, "$kind kind");
        is($class->resource_plural, $info->{plural}, "$kind resource_plural");
        if ($info->{namespaced}) {
            ok($class->does('IO::K8s::Role::Namespaced'), "$kind is namespaced");
        } else {
            ok(!$class->does('IO::K8s::Role::Namespaced'), "$kind is cluster-scoped");
        }
    }
};

subtest 'generators.external-secrets.io/v1alpha1 class metadata' => sub {
    for my $kind (sort keys %generators_classes) {
        my $class = "IO::K8s::ExternalSecrets::V1alpha1::$kind";
        my $info = $generators_classes{$kind};

        is($class->api_version, 'generators.external-secrets.io/v1alpha1', "$kind api_version");
        is($class->kind, $kind, "$kind kind");
        is($class->resource_plural, $info->{plural}, "$kind resource_plural");
        if ($info->{namespaced}) {
            ok($class->does('IO::K8s::Role::Namespaced'), "$kind is namespaced");
        } else {
            ok(!$class->does('IO::K8s::Role::Namespaced'), "$kind is cluster-scoped");
        }
    }
};

# --- IO::K8s::ExternalSecrets resource_map completeness ---

subtest 'IO::K8s::ExternalSecrets resource_map' => sub {
    my $provider = IO::K8s::ExternalSecrets->new;
    ok($provider->does('IO::K8s::Role::ResourceMap'), 'consumes ResourceMap role');

    my $map = $provider->resource_map;
    is(scalar keys %$map, 25, 'resource_map has 25 entries');

    for my $kind (sort keys %v1_classes) {
        ok(exists $map->{$kind}, "$kind in resource_map");
        is($map->{$kind}, "ExternalSecrets::V1::$kind", "$kind maps to correct class path");
    }
    for my $kind (sort keys %v1alpha1_classes) {
        ok(exists $map->{$kind}, "$kind in resource_map");
        is($map->{$kind}, "ExternalSecrets::V1alpha1::$kind", "$kind maps to correct class path");
    }
    for my $kind (sort keys %generators_classes) {
        ok(exists $map->{$kind}, "$kind in resource_map");
        is($map->{$kind}, "ExternalSecrets::V1alpha1::$kind", "$kind maps to correct class path");
    }
};

# --- new(with => ['IO::K8s::ExternalSecrets']) integration ---

subtest 'with constructor parameter' => sub {
    my $k8s = IO::K8s->new(with => ['IO::K8s::ExternalSecrets']);

    for my $kind (sort keys %v1_classes) {
        is($k8s->expand_class($kind), "IO::K8s::ExternalSecrets::V1::$kind",
            "expand_class('$kind') resolves");
    }
    for my $kind (sort keys %v1alpha1_classes) {
        is($k8s->expand_class($kind), "IO::K8s::ExternalSecrets::V1alpha1::$kind",
            "expand_class('$kind') resolves");
    }
    for my $kind (sort keys %generators_classes) {
        is($k8s->expand_class($kind), "IO::K8s::ExternalSecrets::V1alpha1::$kind",
            "expand_class('$kind') resolves");
    }

    # Domain-qualified access
    is($k8s->expand_class('external-secrets.io/v1/SecretStore'),
        'IO::K8s::ExternalSecrets::V1::SecretStore',
        'domain-qualified V1 resolves');
    is($k8s->expand_class('external-secrets.io/v1alpha1/PushSecret'),
        'IO::K8s::ExternalSecrets::V1alpha1::PushSecret',
        'domain-qualified V1alpha1 resolves');

    # Core resources are unaffected
    is($k8s->expand_class('Secret'), 'IO::K8s::Api::Core::V1::Secret',
        'core Secret still resolves');
    is($k8s->expand_class('ConfigMap'), 'IO::K8s::Api::Core::V1::ConfigMap',
        'core ConfigMap still resolves');
};

# --- new_object + inflate round-trip (one namespaced, one cluster-scoped, at minimum) ---

subtest 'new_object and inflate round-trip' => sub {
    my $k8s = IO::K8s->new(with => ['IO::K8s::ExternalSecrets']);

    # Namespaced: ExternalSecret
    my $es = $k8s->new_object('ExternalSecret',
        metadata => { name => 'db-creds', namespace => 'default' },
        spec => {
            secretStoreRef => { name => 'aws-store', kind => 'SecretStore' },
            target         => { name => 'db-creds' },
            data           => [ { secretKey => 'password', remoteRef => { key => 'prod/db/password' } } ],
        },
    );
    isa_ok($es, 'IO::K8s::ExternalSecrets::V1::ExternalSecret');
    is($es->kind, 'ExternalSecret', 'kind');
    is($es->api_version, 'external-secrets.io/v1', 'api_version');
    isa_ok($es->metadata, 'IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::ObjectMeta');
    is($es->metadata->name, 'db-creds', 'name');
    is($es->metadata->namespace, 'default', 'namespace');
    ok($es->does('IO::K8s::Role::Namespaced'), 'ExternalSecret is namespaced');

    my $json = $k8s->object_to_json($es);
    like($json, qr/"apiVersion":"external-secrets\.io\/v1"/, 'JSON has apiVersion');
    like($json, qr/"kind":"ExternalSecret"/, 'JSON has kind');

    my $re = $k8s->inflate($json);
    isa_ok($re, 'IO::K8s::ExternalSecrets::V1::ExternalSecret', 're-inflated');
    is($re->metadata->name, 'db-creds', 'round-trip name preserved');
    is($re->spec->data->[0]->remoteRef->key, 'prod/db/password', 'round-trip nested remoteRef.key preserved');

    # Cluster-scoped: ClusterSecretStore
    my $css = $k8s->new_object('ClusterSecretStore',
        metadata => { name => 'fake-store' },
        spec => { provider => { fake => { data => [ { key => 'x', value => 'y' } ] } } },
    );
    isa_ok($css, 'IO::K8s::ExternalSecrets::V1::ClusterSecretStore');
    ok(!$css->does('IO::K8s::Role::Namespaced'), 'ClusterSecretStore is cluster-scoped');

    my $css_re = $k8s->inflate($k8s->object_to_json($css));
    isa_ok($css_re, 'IO::K8s::ExternalSecrets::V1::ClusterSecretStore');
    is($css_re->metadata->name, 'fake-store', 'cluster-scoped round-trip');
    is($css_re->spec->provider->fake->data->[0]->value, 'y', 'cluster-scoped nested round-trip');

    # v1alpha1: PushSecret
    my $ps = $k8s->new_object('PushSecret',
        metadata => { name => 'push-1', namespace => 'default' },
        spec => {
            secretStoreRefs => [ { name => 'aws-store', kind => 'SecretStore' } ],
            selector        => { secret => { name => 'source-secret' } },
        },
    );
    isa_ok($ps, 'IO::K8s::ExternalSecrets::V1alpha1::PushSecret');
    is($ps->api_version, 'external-secrets.io/v1alpha1', 'PushSecret api_version');
    ok($ps->does('IO::K8s::Role::Namespaced'), 'PushSecret is namespaced');
    my $ps_re = $k8s->inflate($k8s->object_to_json($ps));
    isa_ok($ps_re, 'IO::K8s::ExternalSecrets::V1alpha1::PushSecret');
    is($ps_re->spec->secretStoreRefs->[0]->name, 'aws-store', 'PushSecret round-trip');
};

# --- to_yaml output ---

subtest 'to_yaml output' => sub {
    my $k8s = IO::K8s->new(with => ['IO::K8s::ExternalSecrets']);

    my $es = $k8s->new_object('ExternalSecret',
        metadata => { name => 'test-secret', namespace => 'default' },
        spec => { secretStoreRef => { name => 'aws-store' } },
    );
    my $yaml = $es->to_yaml;
    like($yaml, qr/apiVersion: external-secrets\.io\/v1/, 'YAML apiVersion');
    like($yaml, qr/kind: ExternalSecret/, 'YAML kind');
    like($yaml, qr/name: test-secret/, 'YAML name');
    like($yaml, qr/namespace: default/, 'YAML namespace');
};

# --- No collision with core K8s kinds ---

subtest 'no collision with core K8s kinds' => sub {
    my $k8s = IO::K8s->new(with => ['IO::K8s::ExternalSecrets']);

    is($k8s->expand_class('Secret'), 'IO::K8s::Api::Core::V1::Secret',
        'core Secret unaffected');
    is($k8s->expand_class('Namespace'), 'IO::K8s::Api::Core::V1::Namespace',
        'core Namespace unaffected');
};

# --- Full depth round-trip: ExternalSecret ---

subtest 'full depth round-trip: ExternalSecret' => sub {
    my $k8s = IO::K8s->new(with => ['IO::K8s::ExternalSecrets']);

    my $es = $k8s->new_object('ExternalSecret',
        metadata => { name => 'full-es', namespace => 'default' },
        spec => {
            refreshInterval => '1h',
            secretStoreRef  => { name => 'aws-store', kind => 'SecretStore' },
            target => {
                name           => 'full-es-secret',
                creationPolicy => 'Owner',
                template => {
                    type     => 'Opaque',
                    metadata => { labels => { app => 'demo' } },
                    data     => { key => '{{ .password }}' },
                    templateFrom => [ { configMap => { name => 'cm1', items => [ { key => 'k1' } ] } } ],
                },
            },
            data => [
                { secretKey => 'password', remoteRef => { key => 'prod/db/password', property => 'password' } },
            ],
            dataFrom => [
                { extract => { key => 'prod/db/all' } },
                { find => { name => { regexp => '^prod-.*' }, tags => { env => 'prod' } } },
            ],
            syncWindows => { kind => 'deny', windows => [ { schedule => '0 0 * * *', duration => '1h' } ] },
        },
    );

    isa_ok($es->spec, 'IO::K8s::ExternalSecrets::V1::ExternalSecretSpec');
    isa_ok($es->spec->secretStoreRef, 'IO::K8s::ExternalSecrets::V1::SecretStoreRef');
    isa_ok($es->spec->target, 'IO::K8s::ExternalSecrets::V1::ExternalSecretTarget');
    isa_ok($es->spec->target->template, 'IO::K8s::ExternalSecrets::V1::ExternalSecretTemplate');
    isa_ok($es->spec->target->template->templateFrom->[0], 'IO::K8s::ExternalSecrets::V1::TemplateFrom');
    isa_ok($es->spec->data->[0], 'IO::K8s::ExternalSecrets::V1::ExternalSecretData');
    isa_ok($es->spec->data->[0]->remoteRef, 'IO::K8s::ExternalSecrets::V1::ExternalSecretDataRemoteRef');
    isa_ok($es->spec->dataFrom->[0], 'IO::K8s::ExternalSecrets::V1::ExternalSecretDataFromRemoteRef');
    isa_ok($es->spec->dataFrom->[0]->extract, 'IO::K8s::ExternalSecrets::V1::ExternalSecretDataRemoteRef');
    isa_ok($es->spec->dataFrom->[1]->find, 'IO::K8s::ExternalSecrets::V1::ExternalSecretFind');
    isa_ok($es->spec->dataFrom->[1]->find->name, 'IO::K8s::ExternalSecrets::V1::FindName');
    isa_ok($es->spec->syncWindows, 'IO::K8s::ExternalSecrets::V1::ExternalSecretSyncWindows');
    isa_ok($es->spec->syncWindows->windows->[0], 'IO::K8s::ExternalSecrets::V1::ExternalSecretSyncWindowEntry');

    my $json = $es->TO_JSON;
    is($json->{spec}{target}{template}{data}{key}, '{{ .password }}', 'TO_JSON template.data.key');
    is($json->{spec}{dataFrom}[1]{find}{name}{regexp}, '^prod-.*', 'TO_JSON dataFrom find.name.regexp');

    my $re = $k8s->inflate($k8s->object_to_json($es));
    isa_ok($re, 'IO::K8s::ExternalSecrets::V1::ExternalSecret');
    is($re->spec->target->template->templateFrom->[0]->configMap->name, 'cm1',
        'JSON round-trip preserves deep templateFrom.configMap.name');
    is($re->spec->dataFrom->[0]->extract->key, 'prod/db/all',
        'JSON round-trip preserves dataFrom extract.key');
};

# --- Full depth round-trip: SecretStore / ClusterSecretStore share one Spec class ---

subtest 'full depth round-trip: SecretStore / ClusterSecretStore share one SecretStoreSpec class' => sub {
    my $k8s = IO::K8s->new(with => ['IO::K8s::ExternalSecrets']);

    my %store_spec = (
        controller    => 'my-controller',
        retrySettings => { maxRetries => 5, retryInterval => '10s' },
        provider => {
            aws => {
                service => 'SecretsManager',
                region  => 'eu-west-1',
                auth    => { jwt => { serviceAccountRef => { name => 'my-sa' } } },
            },
        },
    );

    my $store = $k8s->new_object('SecretStore',
        metadata => { name => 'aws-store', namespace => 'default' },
        spec     => { %store_spec },
    );
    my $cluster_store = $k8s->new_object('ClusterSecretStore',
        metadata => { name => 'aws-cluster-store' },
        spec     => { %store_spec, conditions => [ { namespaces => ['default', 'prod'] } ] },
    );

    isa_ok($store->spec, 'IO::K8s::ExternalSecrets::V1::SecretStoreSpec');
    isa_ok($cluster_store->spec, 'IO::K8s::ExternalSecrets::V1::SecretStoreSpec');
    is(ref($store->spec), ref($cluster_store->spec),
        'SecretStore and ClusterSecretStore share the SAME SecretStoreSpec class');

    isa_ok($store->spec->provider, 'IO::K8s::ExternalSecrets::V1::SecretStoreProvider');
    isa_ok($store->spec->provider->aws, 'IO::K8s::ExternalSecrets::V1::AWSProvider');
    isa_ok($store->spec->provider->aws->auth, 'IO::K8s::ExternalSecrets::V1::AWSAuth');
    isa_ok($store->spec->provider->aws->auth->jwt, 'IO::K8s::ExternalSecrets::V1::AWSJWTAuth');
    isa_ok($store->spec->provider->aws->auth->jwt->serviceAccountRef,
        'IO::K8s::ExternalSecrets::V1::ServiceAccountSelector');
    isa_ok($store->spec->retrySettings, 'IO::K8s::ExternalSecrets::V1::SecretStoreRetrySettings');
    isa_ok($cluster_store->spec->conditions->[0], 'IO::K8s::ExternalSecrets::V1::ClusterSecretStoreCondition');

    # A second, unrelated backend, still through the same shared union class.
    my $vault_store = $k8s->new_object('SecretStore',
        metadata => { name => 'vault-store', namespace => 'default' },
        spec => {
            provider => {
                vault => {
                    server => 'https://vault.example.com',
                    path   => 'secret',
                    version => 'v2',
                    auth => { kubernetes => { mountPath => 'kubernetes', role => 'eso-role', serviceAccountRef => { name => 'eso-sa' } } },
                },
            },
        },
    );
    isa_ok($vault_store->spec->provider->vault, 'IO::K8s::ExternalSecrets::V1::VaultProvider');
    isa_ok($vault_store->spec->provider->vault->auth, 'IO::K8s::ExternalSecrets::V1::VaultAuth');
    isa_ok($vault_store->spec->provider->vault->auth->kubernetes, 'IO::K8s::ExternalSecrets::V1::VaultKubernetesAuth');
    isa_ok($vault_store->spec->provider->vault->auth->kubernetes->serviceAccountRef,
        'IO::K8s::ExternalSecrets::V1::ServiceAccountSelector');

    my $json = $store->TO_JSON;
    is($json->{spec}{provider}{aws}{region}, 'eu-west-1', 'TO_JSON provider.aws.region');
    is($json->{spec}{retrySettings}{maxRetries}, 5, 'TO_JSON retrySettings.maxRetries');

    my $re = $k8s->inflate($k8s->object_to_json($store));
    isa_ok($re, 'IO::K8s::ExternalSecrets::V1::SecretStore');
    is($re->spec->provider->aws->auth->jwt->serviceAccountRef->name, 'my-sa',
        'JSON round-trip preserves deep AWS auth.jwt.serviceAccountRef.name');

    my $cluster_re = $k8s->inflate($k8s->object_to_json($cluster_store));
    isa_ok($cluster_re, 'IO::K8s::ExternalSecrets::V1::ClusterSecretStore');
    is($cluster_re->spec->conditions->[0]->namespaces->[1], 'prod',
        'JSON round-trip preserves ClusterSecretStore conditions.namespaces');
};

# --- Full depth round-trip: ClusterExternalSecret shares ExternalSecretSpec with ExternalSecret ---

subtest 'full depth round-trip: ClusterExternalSecret' => sub {
    my $k8s = IO::K8s->new(with => ['IO::K8s::ExternalSecrets']);

    my $ces = $k8s->new_object('ClusterExternalSecret',
        metadata => { name => 'ces-1' },
        spec => {
            externalSecretName => 'generated-es',
            namespaceSelector  => { matchLabels => { env => 'prod' } },
            namespaceSelectors => [ { matchLabels => { env => 'staging' } } ],
            externalSecretSpec => {
                secretStoreRef => { name => 'aws-store' },
                target         => { name => 'generated-es' },
            },
        },
    );

    ok(!$ces->does('IO::K8s::Role::Namespaced'), 'ClusterExternalSecret is cluster-scoped');
    isa_ok($ces->spec, 'IO::K8s::ExternalSecrets::V1::ClusterExternalSecretSpec');
    isa_ok($ces->spec->externalSecretSpec, 'IO::K8s::ExternalSecrets::V1::ExternalSecretSpec');
    is(ref($ces->spec->externalSecretSpec),
        'IO::K8s::ExternalSecrets::V1::ExternalSecretSpec',
        'ClusterExternalSecret.spec.externalSecretSpec is the SAME class ExternalSecret.spec uses');
    isa_ok($ces->spec->externalSecretSpec->secretStoreRef, 'IO::K8s::ExternalSecrets::V1::SecretStoreRef');
    isa_ok($ces->spec->namespaceSelector, 'IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::LabelSelector');
    isa_ok($ces->spec->namespaceSelectors->[0], 'IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::LabelSelector');

    my $ces_re = $k8s->inflate($k8s->object_to_json($ces));
    isa_ok($ces_re, 'IO::K8s::ExternalSecrets::V1::ClusterExternalSecret');
    is($ces_re->spec->externalSecretSpec->target->name, 'generated-es',
        'JSON round-trip preserves nested externalSecretSpec.target.name');

    # status
    my $with_status = $k8s->new_object('ClusterExternalSecret',
        metadata => { name => 'ces-2' },
        spec => { externalSecretSpec => { secretStoreRef => { name => 's1' } } },
        status => {
            conditions       => [ { type => 'Ready', status => 'True' } ],
            failedNamespaces => [ { namespace => 'kube-system', reason => 'forbidden' } ],
        },
    );
    isa_ok($with_status->status, 'IO::K8s::ExternalSecrets::V1::ClusterExternalSecretStatus');
    isa_ok($with_status->status->conditions->[0], 'IO::K8s::ExternalSecrets::V1::ClusterExternalSecretStatusCondition');
    isa_ok($with_status->status->failedNamespaces->[0], 'IO::K8s::ExternalSecrets::V1::ClusterExternalSecretNamespaceFailure');
    is($with_status->TO_JSON->{status}{failedNamespaces}[0]{reason}, 'forbidden',
        'TO_JSON status.failedNamespaces[0].reason');
};

# --- Full depth round-trip: PushSecret ---

subtest 'full depth round-trip: PushSecret' => sub {
    my $k8s = IO::K8s->new(with => ['IO::K8s::ExternalSecrets']);

    my $ps = $k8s->new_object('PushSecret',
        metadata => { name => 'push-full', namespace => 'default' },
        spec => {
            deletionPolicy  => 'Delete',
            updatePolicy    => 'Replace',
            secretStoreRefs => [ { name => 'aws-store', kind => 'SecretStore' } ],
            selector        => { secret => { name => 'source-secret' } },
            data => [
                { match => { secretKey => 'password', remoteRef => { remoteKey => 'prod/db', property => 'password' } } },
            ],
            dataTo => [
                { match => { regexp => '^db-.*' }, remoteKey => 'prod/db-bulk' },
            ],
        },
    );

    isa_ok($ps->spec, 'IO::K8s::ExternalSecrets::V1alpha1::PushSecretSpec');
    isa_ok($ps->spec->secretStoreRefs->[0], 'IO::K8s::ExternalSecrets::V1alpha1::PushSecretStoreRef');
    isa_ok($ps->spec->selector, 'IO::K8s::ExternalSecrets::V1alpha1::PushSecretSelector');
    isa_ok($ps->spec->data->[0], 'IO::K8s::ExternalSecrets::V1alpha1::PushSecretData');
    isa_ok($ps->spec->data->[0]->match, 'IO::K8s::ExternalSecrets::V1alpha1::PushSecretMatch');
    isa_ok($ps->spec->data->[0]->match->remoteRef, 'IO::K8s::ExternalSecrets::V1alpha1::PushSecretRemoteRef');
    isa_ok($ps->spec->dataTo->[0], 'IO::K8s::ExternalSecrets::V1alpha1::PushSecretDataTo');
    isa_ok($ps->spec->dataTo->[0]->match, 'IO::K8s::ExternalSecrets::V1alpha1::PushSecretDataToMatch');

    my $json = $ps->TO_JSON;
    is($json->{spec}{data}[0]{match}{remoteRef}{remoteKey}, 'prod/db', 'TO_JSON data match.remoteRef.remoteKey');

    my $re = $k8s->inflate($k8s->object_to_json($ps));
    isa_ok($re, 'IO::K8s::ExternalSecrets::V1alpha1::PushSecret');
    is($re->spec->dataTo->[0]->match->regexp, '^db-.*', 'JSON round-trip preserves dataTo match.regexp');
};

# --- Full depth round-trip: ClusterPushSecret shares PushSecretSpec with PushSecret ---

subtest 'full depth round-trip: ClusterPushSecret' => sub {
    my $k8s = IO::K8s->new(with => ['IO::K8s::ExternalSecrets']);

    my $cps = $k8s->new_object('ClusterPushSecret',
        metadata => { name => 'cps-1' },
        spec => {
            pushSecretName     => 'generated-ps',
            namespaceSelectors => [ { matchLabels => { env => 'staging' } } ],
            pushSecretMetadata => { labels => { team => 'platform' } },
            pushSecretSpec     => {
                secretStoreRefs => [ { name => 'aws-store', kind => 'SecretStore' } ],
                selector        => { secret => { name => 'source-secret' } },
            },
        },
    );

    ok(!$cps->does('IO::K8s::Role::Namespaced'), 'ClusterPushSecret is cluster-scoped');
    isa_ok($cps->spec, 'IO::K8s::ExternalSecrets::V1alpha1::ClusterPushSecretSpec');
    isa_ok($cps->spec->pushSecretSpec, 'IO::K8s::ExternalSecrets::V1alpha1::PushSecretSpec');
    is(ref($cps->spec->pushSecretSpec),
        'IO::K8s::ExternalSecrets::V1alpha1::PushSecretSpec',
        'ClusterPushSecret.spec.pushSecretSpec is the SAME class PushSecret.spec uses');
    isa_ok($cps->spec->pushSecretSpec->secretStoreRefs->[0], 'IO::K8s::ExternalSecrets::V1alpha1::PushSecretStoreRef');
    isa_ok($cps->spec->namespaceSelectors->[0], 'IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::LabelSelector');
    isa_ok($cps->spec->pushSecretMetadata, 'IO::K8s::ExternalSecrets::V1alpha1::PushSecretMetadata');

    my $json = $cps->TO_JSON;
    is($json->{spec}{pushSecretSpec}{selector}{secret}{name}, 'source-secret',
        'TO_JSON pushSecretSpec.selector.secret.name');

    my $cps_re = $k8s->inflate($k8s->object_to_json($cps));
    isa_ok($cps_re, 'IO::K8s::ExternalSecrets::V1alpha1::ClusterPushSecret');
    is($cps_re->spec->pushSecretSpec->selector->secret->name, 'source-secret',
        'JSON round-trip preserves nested pushSecretSpec.selector.secret.name');
    is($cps_re->spec->pushSecretMetadata->labels->{team}, 'platform',
        'JSON round-trip preserves pushSecretMetadata.labels');

    # status
    my $with_status = $k8s->new_object('ClusterPushSecret',
        metadata => { name => 'cps-2' },
        spec => {
            pushSecretSpec => {
                secretStoreRefs => [ { name => 's1' } ],
                selector        => { secret => { name => 'src' } },
            },
        },
        status => {
            conditions            => [ { type => 'Ready', status => 'True' } ],
            failedNamespaces      => [ { namespace => 'kube-system', reason => 'forbidden' } ],
            provisionedNamespaces => [ 'default', 'staging' ],
            pushSecretName        => 'generated-ps',
        },
    );
    isa_ok($with_status->status, 'IO::K8s::ExternalSecrets::V1alpha1::ClusterPushSecretStatus');
    isa_ok($with_status->status->conditions->[0], 'IO::K8s::ExternalSecrets::V1alpha1::PushSecretStatusCondition');
    isa_ok($with_status->status->failedNamespaces->[0], 'IO::K8s::ExternalSecrets::V1alpha1::ClusterPushSecretNamespaceFailure');
    is($with_status->TO_JSON->{status}{failedNamespaces}[0]{reason}, 'forbidden',
        'TO_JSON status.failedNamespaces[0].reason');
    is($with_status->TO_JSON->{status}{provisionedNamespaces}[1], 'staging',
        'TO_JSON status.provisionedNamespaces');

    my $status_re = $k8s->inflate($k8s->object_to_json($with_status));
    isa_ok($status_re, 'IO::K8s::ExternalSecrets::V1alpha1::ClusterPushSecret');
    is($status_re->status->conditions->[0]->type, 'Ready',
        'JSON round-trip preserves status.conditions[0].type');
};

# --- Full depth round-trip: VaultDynamicSecret (generators.external-secrets.io/v1alpha1) ---
#
# The Kind's own group is generators.external-secrets.io, a separate
# upstream Go package from external-secrets.io -- distinct from the
# %v1alpha1_classes group above despite sharing both the "v1alpha1" version
# string and the V1alpha1 namespace (same one-provider/two-groups layout as
# CertManager's cert-manager.io/v1 + acme.cert-manager.io/v1, disambiguated
# by api_version rather than a path segment). Its spec.provider and
# spec.retrySettings schemas are byte-identical (upstream field-doc string
# aside) to SecretStore's own VaultProvider / SecretStoreRetrySettings, so
# this Kind reuses those existing V1 classes rather than a private
# VaultDynamicSecret-only copy.

subtest 'full depth round-trip: VaultDynamicSecret' => sub {
    my $k8s = IO::K8s->new(with => ['IO::K8s::ExternalSecrets']);

    my $vds = $k8s->new_object('VaultDynamicSecret',
        metadata => { name => 'vds-1', namespace => 'default' },
        spec => {
            allowEmptyResponse => 1,
            controller         => 'my-controller',
            getParameters      => { role_id => ['a', 'b'], ttl => ['1h'] },
            method             => 'GET',
            parameters         => '{"raw":"blob"}',
            path               => 'creds/my-role',
            provider => {
                server => 'https://vault.example.com',
                path   => 'secret',
                auth   => { kubernetes => { mountPath => 'kubernetes', role => 'eso-role', serviceAccountRef => { name => 'eso-sa' } } },
            },
            resultType    => 'Data',
            retrySettings => { maxRetries => 3, retryInterval => '5s' },
        },
    );

    isa_ok($vds, 'IO::K8s::ExternalSecrets::V1alpha1::VaultDynamicSecret');
    is($vds->api_version, 'generators.external-secrets.io/v1alpha1', 'api_version');
    ok($vds->does('IO::K8s::Role::Namespaced'), 'VaultDynamicSecret is namespaced');

    isa_ok($vds->spec, 'IO::K8s::ExternalSecrets::V1alpha1::VaultDynamicSecretSpec');

    # The convention decision this pilot exists to make: provider and
    # retrySettings are the SAME classes SecretStore's Vault backend uses,
    # not private VaultDynamicSecret-only copies.
    isa_ok($vds->spec->provider, 'IO::K8s::ExternalSecrets::V1::VaultProvider');
    is(ref($vds->spec->provider), 'IO::K8s::ExternalSecrets::V1::VaultProvider',
        'spec.provider reuses the SAME VaultProvider class SecretStore uses');
    isa_ok($vds->spec->provider->auth, 'IO::K8s::ExternalSecrets::V1::VaultAuth');
    isa_ok($vds->spec->provider->auth->kubernetes, 'IO::K8s::ExternalSecrets::V1::VaultKubernetesAuth');
    isa_ok($vds->spec->provider->auth->kubernetes->serviceAccountRef,
        'IO::K8s::ExternalSecrets::V1::ServiceAccountSelector');
    isa_ok($vds->spec->retrySettings, 'IO::K8s::ExternalSecrets::V1::SecretStoreRetrySettings');
    is(ref($vds->spec->retrySettings), 'IO::K8s::ExternalSecrets::V1::SecretStoreRetrySettings',
        'spec.retrySettings reuses the SAME SecretStoreRetrySettings class SecretStore uses');

    my $json = $vds->TO_JSON;
    is($json->{spec}{allowEmptyResponse}, 1, 'TO_JSON allowEmptyResponse (true)');
    is($json->{spec}{getParameters}{role_id}[1], 'b', 'TO_JSON getParameters (map[string][]string)');
    is($json->{spec}{parameters}, '{"raw":"blob"}', 'TO_JSON parameters (opaque preserve-unknown blob)');
    is($json->{spec}{provider}{auth}{kubernetes}{role}, 'eso-role', 'TO_JSON provider.auth.kubernetes.role');
    is($json->{spec}{retrySettings}{maxRetries}, 3, 'TO_JSON retrySettings.maxRetries');

    my $re = $k8s->inflate($k8s->object_to_json($vds));
    isa_ok($re, 'IO::K8s::ExternalSecrets::V1alpha1::VaultDynamicSecret');
    is($re->spec->path, 'creds/my-role', 'JSON round-trip preserves path');
    is($re->spec->getParameters->{ttl}[0], '1h', 'JSON round-trip preserves getParameters');
    is($re->spec->provider->auth->kubernetes->serviceAccountRef->name, 'eso-sa',
        'JSON round-trip preserves deep provider.auth.kubernetes.serviceAccountRef.name');
    is($re->spec->retrySettings->retryInterval, '5s',
        'JSON round-trip preserves retrySettings.retryInterval');
    isa_ok($re->spec->provider, 'IO::K8s::ExternalSecrets::V1::VaultProvider');
};

# --- Full depth round-trip: the remaining generators.external-secrets.io/v1alpha1 Kinds ---
#
# Each subtest below exercises the reuse decision made while modeling that
# Kind (a shared V1/V1alpha1 class where the upstream schema was verified
# byte-identical) and confirms both serialization directions -- a test that
# only reads accessors cannot catch a broken TO_JSON/FROM_HASH round-trip.

subtest 'full depth round-trip: ACRAccessToken' => sub {
    my $k8s = IO::K8s->new(with => ['IO::K8s::ExternalSecrets']);

    my $acr = $k8s->new_object('ACRAccessToken',
        metadata => { name => 'acr-1', namespace => 'default' },
        spec => {
            auth => {
                servicePrincipal => {
                    secretRef => {
                        clientId     => { name => 'acr-sp', key => 'client-id' },
                        clientSecret => { name => 'acr-sp', key => 'client-secret' },
                    },
                },
            },
            registry => 'foobarexample.azurecr.io',
            scope    => 'repository:my-repository:pull',
        },
    );
    isa_ok($acr, 'IO::K8s::ExternalSecrets::V1alpha1::ACRAccessToken');
    is($acr->api_version, 'generators.external-secrets.io/v1alpha1', 'api_version');
    isa_ok($acr->spec->auth, 'IO::K8s::ExternalSecrets::V1alpha1::ACRAuth');
    isa_ok($acr->spec->auth->servicePrincipal, 'IO::K8s::ExternalSecrets::V1alpha1::ACRServicePrincipal');
    isa_ok($acr->spec->auth->servicePrincipal->secretRef,
        'IO::K8s::ExternalSecrets::V1alpha1::AzureACRServicePrincipalAuthSecretRef');
    isa_ok($acr->spec->auth->servicePrincipal->secretRef->clientId, 'IO::K8s::ExternalSecrets::V1::SecretKeySelector');

    my $json = $acr->TO_JSON;
    is($json->{spec}{registry}, 'foobarexample.azurecr.io', 'TO_JSON registry');
    is($json->{spec}{auth}{servicePrincipal}{secretRef}{clientId}{key}, 'client-id',
        'TO_JSON deep clientId.key');

    my $re = $k8s->inflate($k8s->object_to_json($acr));
    is($re->spec->auth->servicePrincipal->secretRef->clientSecret->key, 'client-secret',
        'JSON round-trip preserves deep clientSecret.key');
};

subtest 'full depth round-trip: BeyondtrustWorkloadCredentialsDynamicSecret' => sub {
    my $k8s = IO::K8s->new(with => ['IO::K8s::ExternalSecrets']);

    my $bt = $k8s->new_object('BeyondtrustWorkloadCredentialsDynamicSecret',
        metadata => { name => 'bt-1', namespace => 'default' },
        spec => {
            provider => {
                auth       => { apikey => { token => { name => 'bt-token', key => 'apikey' } } },
                server     => { apiUrl => 'https://api.beyondtrust.io/siie', siteId => 'a1b2c3d4' },
                folderPath => 'production/aws-temp',
            },
            retrySettings => { maxRetries => 3, retryInterval => '5s' },
        },
    );
    # The convention decision this Kind exists to make: its whole `provider`
    # tree is the SAME class SecretStore's own beyondtrustworkloadcredentials
    # provider uses -- verified byte-identical, not a private copy.
    isa_ok($bt->spec->provider, 'IO::K8s::ExternalSecrets::V1::BeyondtrustWorkloadCredentialsProvider');
    is(ref($bt->spec->provider), 'IO::K8s::ExternalSecrets::V1::BeyondtrustWorkloadCredentialsProvider',
        'spec.provider reuses the SAME class SecretStore uses');
    isa_ok($bt->spec->retrySettings, 'IO::K8s::ExternalSecrets::V1::SecretStoreRetrySettings');

    my $json = $bt->TO_JSON;
    is($json->{spec}{provider}{server}{apiUrl}, 'https://api.beyondtrust.io/siie', 'TO_JSON provider.server.apiUrl');

    my $re = $k8s->inflate($k8s->object_to_json($bt));
    is($re->spec->provider->auth->apikey->token->key, 'apikey',
        'JSON round-trip preserves deep provider.auth.apikey.token.key');
};

subtest 'full depth round-trip: CloudsmithAccessToken' => sub {
    my $k8s = IO::K8s->new(with => ['IO::K8s::ExternalSecrets']);

    my $cs = $k8s->new_object('CloudsmithAccessToken',
        metadata => { name => 'cs-1', namespace => 'default' },
        spec => {
            orgSlug           => 'my-org',
            serviceSlug       => 'my-service',
            serviceAccountRef => { name => 'my-sa' },
        },
    );
    isa_ok($cs->spec->serviceAccountRef, 'IO::K8s::ExternalSecrets::V1::ServiceAccountSelector');

    my $re = $k8s->inflate($k8s->object_to_json($cs));
    is($re->spec->serviceAccountRef->name, 'my-sa', 'JSON round-trip preserves serviceAccountRef.name');
};

subtest 'full depth round-trip: ECRAuthorizationToken' => sub {
    my $k8s = IO::K8s->new(with => ['IO::K8s::ExternalSecrets']);

    my $ecr = $k8s->new_object('ECRAuthorizationToken',
        metadata => { name => 'ecr-1', namespace => 'default' },
        spec => {
            region => 'eu-west-1',
            auth   => { jwt => { serviceAccountRef => { name => 'ecr-sa' } } },
        },
    );
    # auth reuses the SAME AWSAuth class SecretStore's AWS provider uses.
    isa_ok($ecr->spec->auth, 'IO::K8s::ExternalSecrets::V1::AWSAuth');
    is(ref($ecr->spec->auth), 'IO::K8s::ExternalSecrets::V1::AWSAuth', 'spec.auth reuses the SAME AWSAuth class');

    my $re = $k8s->inflate($k8s->object_to_json($ecr));
    is($re->spec->auth->jwt->serviceAccountRef->name, 'ecr-sa', 'JSON round-trip preserves auth.jwt.serviceAccountRef.name');
};

subtest 'full depth round-trip: Fake' => sub {
    my $k8s = IO::K8s->new(with => ['IO::K8s::ExternalSecrets']);

    my $fake = $k8s->new_object('Fake',
        metadata => { name => 'fake-1', namespace => 'default' },
        spec => { controller => 'my-controller', data => { username => 'admin', password => 'hunter2' } },
    );
    my $json = $fake->TO_JSON;
    is($json->{spec}{data}{password}, 'hunter2', 'TO_JSON data (opaque string map)');

    my $re = $k8s->inflate($k8s->object_to_json($fake));
    is($re->spec->data->{username}, 'admin', 'JSON round-trip preserves data map');
};

subtest 'full depth round-trip: GCRAccessToken' => sub {
    my $k8s = IO::K8s->new(with => ['IO::K8s::ExternalSecrets']);

    my $gcr = $k8s->new_object('GCRAccessToken',
        metadata => { name => 'gcr-1', namespace => 'default' },
        spec => {
            projectID => 'my-project',
            auth      => {
                workloadIdentity => {
                    clusterLocation   => 'europe-west1',
                    clusterName       => 'my-cluster',
                    serviceAccountRef => { name => 'gcr-sa' },
                },
            },
        },
    );
    isa_ok($gcr->spec->auth, 'IO::K8s::ExternalSecrets::V1alpha1::GCRAuth');
    # GCRWorkloadIdentity is a NEW class, not a reuse of V1::GCPWorkloadIdentity:
    # the generator's clusterLocation/clusterName are required, SecretStore's are not.
    isa_ok($gcr->spec->auth->workloadIdentity, 'IO::K8s::ExternalSecrets::V1alpha1::GCRWorkloadIdentity');

    my $re = $k8s->inflate($k8s->object_to_json($gcr));
    is($re->spec->auth->workloadIdentity->clusterName, 'my-cluster',
        'JSON round-trip preserves auth.workloadIdentity.clusterName');

    # secretRef and workloadIdentityFederation DO reuse the V1 classes.
    my $gcr2 = $k8s->new_object('GCRAccessToken',
        metadata => { name => 'gcr-2', namespace => 'default' },
        spec => {
            projectID => 'my-project',
            auth      => { secretRef => { secretAccessKeySecretRef => { name => 'gcp-key' } } },
        },
    );
    isa_ok($gcr2->spec->auth->secretRef, 'IO::K8s::ExternalSecrets::V1::GCPSMAuthSecretRef');
};

subtest 'full depth round-trip: GeneratorState' => sub {
    my $k8s = IO::K8s->new(with => ['IO::K8s::ExternalSecrets']);

    my $gs = $k8s->new_object('GeneratorState',
        metadata => { name => 'gs-1', namespace => 'default' },
        spec => {
            resource => '{"kind":"Password"}',
            state    => '{"value":"generated"}',
        },
        status => {
            conditions => [ { type => 'Ready', status => 'True' } ],
        },
    );
    isa_ok($gs->status, 'IO::K8s::ExternalSecrets::V1alpha1::GeneratorStateStatus');
    isa_ok($gs->status->conditions->[0], 'IO::K8s::ExternalSecrets::V1alpha1::GeneratorStateStatusCondition');

    my $json = $gs->TO_JSON;
    is($json->{spec}{state}, '{"value":"generated"}', 'TO_JSON state (opaque preserve-unknown blob)');

    my $re = $k8s->inflate($k8s->object_to_json($gs));
    is($re->spec->resource, '{"kind":"Password"}', 'JSON round-trip preserves resource');
    is($re->status->conditions->[0]->type, 'Ready', 'JSON round-trip preserves status.conditions[0].type');
};

subtest 'full depth round-trip: GithubAccessToken' => sub {
    my $k8s = IO::K8s->new(with => ['IO::K8s::ExternalSecrets']);

    my $gh = $k8s->new_object('GithubAccessToken',
        metadata => { name => 'gh-1', namespace => 'default' },
        spec => {
            appID      => '123456',
            installID  => '789',
            auth       => { privateKey => { secretRef => { name => 'gh-key', key => 'pem' } } },
            repositories => ['my-org/my-repo'],
        },
    );
    isa_ok($gh->spec->auth, 'IO::K8s::ExternalSecrets::V1alpha1::GithubAuth');
    isa_ok($gh->spec->auth->privateKey, 'IO::K8s::ExternalSecrets::V1alpha1::GithubSecretRef');
    isa_ok($gh->spec->auth->privateKey->secretRef, 'IO::K8s::ExternalSecrets::V1::SecretKeySelector');

    my $re = $k8s->inflate($k8s->object_to_json($gh));
    is($re->spec->auth->privateKey->secretRef->key, 'pem', 'JSON round-trip preserves auth.privateKey.secretRef.key');
    is($re->spec->repositories->[0], 'my-org/my-repo', 'JSON round-trip preserves repositories');
};

subtest 'full depth round-trip: GitlabDeployToken' => sub {
    my $k8s = IO::K8s->new(with => ['IO::K8s::ExternalSecrets']);

    my $gl = $k8s->new_object('GitlabDeployToken',
        metadata => { name => 'gl-1', namespace => 'default' },
        spec => {
            name    => 'my-deploy-token',
            scopes  => ['read_repository', 'read_registry'],
            auth    => { token => { secretRef => { name => 'gl-token', key => 'token' } } },
            projectID => 'group/project',
        },
    );
    isa_ok($gl->spec->auth, 'IO::K8s::ExternalSecrets::V1alpha1::GitlabTokenAuth');
    isa_ok($gl->spec->auth->token, 'IO::K8s::ExternalSecrets::V1alpha1::GitlabDeployTokenSecretRef');
    isa_ok($gl->spec->auth->token->secretRef, 'IO::K8s::ExternalSecrets::V1::SecretKeySelector');

    my $re = $k8s->inflate($k8s->object_to_json($gl));
    is($re->spec->scopes->[1], 'read_registry', 'JSON round-trip preserves scopes');
    is($re->spec->auth->token->secretRef->name, 'gl-token', 'JSON round-trip preserves auth.token.secretRef.name');
};

subtest 'full depth round-trip: Grafana' => sub {
    my $k8s = IO::K8s->new(with => ['IO::K8s::ExternalSecrets']);

    my $gf = $k8s->new_object('Grafana',
        metadata => { name => 'gf-1', namespace => 'default' },
        spec => {
            url  => 'https://grafana.example.com',
            auth => { basic => { username => 'admin', password => { name => 'gf-pw', key => 'password' } } },
            serviceAccount => { name => 'eso-generated', role => 'Admin', secondsToLive => 3600 },
        },
    );
    isa_ok($gf->spec->auth->basic, 'IO::K8s::ExternalSecrets::V1alpha1::GrafanaBasicAuth');
    # The narrow, namespace-less 2-field SecretRef shared with Webhook.
    isa_ok($gf->spec->auth->basic->password, 'IO::K8s::ExternalSecrets::V1alpha1::SecretRef');
    isa_ok($gf->spec->serviceAccount, 'IO::K8s::ExternalSecrets::V1alpha1::GrafanaServiceAccount');

    my $re = $k8s->inflate($k8s->object_to_json($gf));
    is($re->spec->auth->basic->password->key, 'password', 'JSON round-trip preserves auth.basic.password.key');
    is($re->spec->serviceAccount->secondsToLive, 3600, 'JSON round-trip preserves serviceAccount.secondsToLive');
};

subtest 'full depth round-trip: MFA' => sub {
    my $k8s = IO::K8s->new(with => ['IO::K8s::ExternalSecrets']);

    my $mfa = $k8s->new_object('MFA',
        metadata => { name => 'mfa-1', namespace => 'default' },
        spec => { secret => { name => 'totp-seed', key => 'seed', namespace => 'other-ns' }, length => 8 },
    );
    isa_ok($mfa->spec->secret, 'IO::K8s::ExternalSecrets::V1::SecretKeySelector');

    my $re = $k8s->inflate($k8s->object_to_json($mfa));
    is($re->spec->secret->namespace, 'other-ns', 'JSON round-trip preserves secret.namespace (full SecretKeySelector, unlike Grafana/Webhook)');
    is($re->spec->length, 8, 'JSON round-trip preserves length');
};

subtest 'full depth round-trip: Password' => sub {
    my $k8s = IO::K8s->new(with => ['IO::K8s::ExternalSecrets']);

    my $pw = $k8s->new_object('Password',
        metadata => { name => 'pw-1', namespace => 'default' },
        spec => { length => 32, digits => 5, symbols => 5, secretKeys => ['password', 'password-confirm'] },
    );
    my $json = $pw->TO_JSON;
    is($json->{spec}{length}, 32, 'TO_JSON length');
    is($json->{spec}{secretKeys}[1], 'password-confirm', 'TO_JSON secretKeys');

    my $re = $k8s->inflate($k8s->object_to_json($pw));
    is($re->spec->digits, 5, 'JSON round-trip preserves digits');
};

subtest 'full depth round-trip: QuayAccessToken' => sub {
    my $k8s = IO::K8s->new(with => ['IO::K8s::ExternalSecrets']);

    my $quay = $k8s->new_object('QuayAccessToken',
        metadata => { name => 'quay-1', namespace => 'default' },
        spec => { robotAccount => 'myorg+myrobot', serviceAccountRef => { name => 'quay-sa' } },
    );
    isa_ok($quay->spec->serviceAccountRef, 'IO::K8s::ExternalSecrets::V1::ServiceAccountSelector');

    my $re = $k8s->inflate($k8s->object_to_json($quay));
    is($re->spec->robotAccount, 'myorg+myrobot', 'JSON round-trip preserves robotAccount');
};

subtest 'full depth round-trip: SSHKey' => sub {
    my $k8s = IO::K8s->new(with => ['IO::K8s::ExternalSecrets']);

    my $ssh = $k8s->new_object('SSHKey',
        metadata => { name => 'ssh-1', namespace => 'default' },
        spec => { keyType => 'ed25519', comment => 'generated by eso' },
    );
    my $re = $k8s->inflate($k8s->object_to_json($ssh));
    is($re->spec->keyType, 'ed25519', 'JSON round-trip preserves keyType');
    is($re->spec->comment, 'generated by eso', 'JSON round-trip preserves comment');
};

subtest 'full depth round-trip: STSSessionToken' => sub {
    my $k8s = IO::K8s->new(with => ['IO::K8s::ExternalSecrets']);

    my $sts = $k8s->new_object('STSSessionToken',
        metadata => { name => 'sts-1', namespace => 'default' },
        spec => {
            region            => 'eu-west-1',
            auth              => { jwt => { serviceAccountRef => { name => 'sts-sa' } } },
            requestParameters => { serialNumber => 'arn:aws:iam::123456789012:mfa/user', tokenCode => '123456' },
        },
    );
    isa_ok($sts->spec->auth, 'IO::K8s::ExternalSecrets::V1::AWSAuth');
    isa_ok($sts->spec->requestParameters, 'IO::K8s::ExternalSecrets::V1alpha1::STSSessionTokenRequestParameters');

    my $re = $k8s->inflate($k8s->object_to_json($sts));
    is($re->spec->requestParameters->tokenCode, '123456', 'JSON round-trip preserves requestParameters.tokenCode');
};

subtest 'full depth round-trip: UUID' => sub {
    my $k8s = IO::K8s->new(with => ['IO::K8s::ExternalSecrets']);

    # UUIDSpec has no fields at all upstream -- spec is present but empty.
    my $uuid = $k8s->new_object('UUID',
        metadata => { name => 'uuid-1', namespace => 'default' },
        spec => {},
    );
    isa_ok($uuid->spec, 'IO::K8s::ExternalSecrets::V1alpha1::UUIDSpec');

    my $re = $k8s->inflate($k8s->object_to_json($uuid));
    isa_ok($re, 'IO::K8s::ExternalSecrets::V1alpha1::UUID');
    is($re->metadata->name, 'uuid-1', 'JSON round-trip preserves name on an otherwise-empty spec');
};

subtest 'full depth round-trip: Webhook' => sub {
    my $k8s = IO::K8s->new(with => ['IO::K8s::ExternalSecrets']);

    my $wh = $k8s->new_object('Webhook',
        metadata => { name => 'wh-1', namespace => 'default' },
        spec => {
            url    => 'https://example.com/generate',
            result => { jsonPath => '$.data.password' },
            auth   => { ntlm => { usernameSecret => { name => 'wh-ntlm', key => 'user' }, passwordSecret => { name => 'wh-ntlm', key => 'pass' } } },
            secrets => [ { name => 'db', secretRef => { name => 'db-secret', key => 'password' } } ],
        },
    );
    # auth, caProvider and result reuse the SAME classes SecretStore's own
    # webhook provider uses; secrets does NOT (its secretRef lacks
    # namespace, unlike SecretStore's WebhookSecret).
    isa_ok($wh->spec->auth, 'IO::K8s::ExternalSecrets::V1::AuthorizationProtocol');
    isa_ok($wh->spec->result, 'IO::K8s::ExternalSecrets::V1::WebhookResult');
    isa_ok($wh->spec->secrets->[0], 'IO::K8s::ExternalSecrets::V1alpha1::WebhookSecret');
    isa_ok($wh->spec->secrets->[0]->secretRef, 'IO::K8s::ExternalSecrets::V1alpha1::SecretRef');

    my $json = $wh->TO_JSON;
    is($json->{spec}{result}{jsonPath}, '$.data.password', 'TO_JSON result.jsonPath');

    my $re = $k8s->inflate($k8s->object_to_json($wh));
    is($re->spec->secrets->[0]->secretRef->key, 'password', 'JSON round-trip preserves secrets[0].secretRef.key');
    is($re->spec->auth->ntlm->usernameSecret->name, 'wh-ntlm', 'JSON round-trip preserves auth.ntlm.usernameSecret.name');
};

# --- Full depth round-trip: ClusterGenerator (the 17-member union kind) ---
#
# ClusterGenerator's spec.generator.<x>Spec fields each reference the SAME
# *Spec class the corresponding standalone Kind uses for its own spec
# (verified byte-identical upstream for all 17 members before writing this
# class) -- so a value set through the union must produce exactly the same
# object graph, down to reused V1 classes several levels deep, as the same
# value set through the standalone Kind would. Two different union members
# are exercised: VaultDynamicSecret (whose nested provider/auth chain is
# itself a V1 reuse) and GCRAccessToken (whose workloadIdentity is a
# V1alpha1-only class, NOT the V1::GCPWorkloadIdentity SecretStore uses --
# see the GCRAccessToken subtest above) -- checking accessors alone would
# not catch either a wrong class or a wrong required-ness that far down.

subtest 'full depth round-trip: ClusterGenerator' => sub {
    my $k8s = IO::K8s->new(with => ['IO::K8s::ExternalSecrets']);

    my $cg = $k8s->new_object('ClusterGenerator',
        metadata => { name => 'cg-vault' },
        spec => {
            kind      => 'VaultDynamicSecret',
            generator => {
                vaultDynamicSecretSpec => {
                    path     => 'creds/my-role',
                    provider => {
                        server => 'https://vault.example.com',
                        path   => 'secret',
                        auth   => { kubernetes => { mountPath => 'kubernetes', role => 'eso-role', serviceAccountRef => { name => 'eso-sa' } } },
                    },
                    retrySettings => { maxRetries => 2, retryInterval => '3s' },
                },
            },
        },
    );

    isa_ok($cg, 'IO::K8s::ExternalSecrets::V1alpha1::ClusterGenerator');
    is($cg->api_version, 'generators.external-secrets.io/v1alpha1', 'api_version');
    ok(!$cg->does('IO::K8s::Role::Namespaced'), 'ClusterGenerator is cluster-scoped');

    isa_ok($cg->spec, 'IO::K8s::ExternalSecrets::V1alpha1::ClusterGeneratorSpec');
    isa_ok($cg->spec->generator, 'IO::K8s::ExternalSecrets::V1alpha1::ClusterGeneratorGenerator');
    is($cg->spec->kind, 'VaultDynamicSecret', 'spec.kind');

    # The union member is the SAME class the standalone VaultDynamicSecret
    # Kind's own .spec uses -- not a private ClusterGenerator-only copy.
    isa_ok($cg->spec->generator->vaultDynamicSecretSpec, 'IO::K8s::ExternalSecrets::V1alpha1::VaultDynamicSecretSpec');
    is(ref($cg->spec->generator->vaultDynamicSecretSpec), 'IO::K8s::ExternalSecrets::V1alpha1::VaultDynamicSecretSpec',
        'spec.generator.vaultDynamicSecretSpec reuses the SAME class VaultDynamicSecret.spec uses');
    # ...and that class's own reuse chain (VaultProvider, several levels down
    # through the union) still resolves to the SAME V1 classes SecretStore uses.
    isa_ok($cg->spec->generator->vaultDynamicSecretSpec->provider, 'IO::K8s::ExternalSecrets::V1::VaultProvider');
    isa_ok($cg->spec->generator->vaultDynamicSecretSpec->provider->auth->kubernetes,
        'IO::K8s::ExternalSecrets::V1::VaultKubernetesAuth');
    isa_ok($cg->spec->generator->vaultDynamicSecretSpec->retrySettings, 'IO::K8s::ExternalSecrets::V1::SecretStoreRetrySettings');

    my $json = $cg->TO_JSON;
    is($json->{spec}{kind}, 'VaultDynamicSecret', 'TO_JSON spec.kind');
    is($json->{spec}{generator}{vaultDynamicSecretSpec}{provider}{auth}{kubernetes}{role}, 'eso-role',
        'TO_JSON deep generator.vaultDynamicSecretSpec.provider.auth.kubernetes.role');

    my $re = $k8s->inflate($k8s->object_to_json($cg));
    isa_ok($re, 'IO::K8s::ExternalSecrets::V1alpha1::ClusterGenerator');
    is($re->spec->generator->vaultDynamicSecretSpec->path, 'creds/my-role',
        'JSON round-trip preserves deep generator.vaultDynamicSecretSpec.path');
    is($re->spec->generator->vaultDynamicSecretSpec->provider->auth->kubernetes->serviceAccountRef->name, 'eso-sa',
        'JSON round-trip preserves very deep provider.auth.kubernetes.serviceAccountRef.name');
    isa_ok($re->spec->generator->vaultDynamicSecretSpec->provider, 'IO::K8s::ExternalSecrets::V1::VaultProvider');

    # A second union member: GCRAccessToken, whose workloadIdentity is a
    # V1alpha1-only class (required-ness differs from SecretStore's own
    # GCPWorkloadIdentity) -- confirms the union isn't special-cased to
    # just the one member exercised above, and that the type distinction
    # survives being reached through the union rather than the standalone Kind.
    my $cg2 = $k8s->new_object('ClusterGenerator',
        metadata => { name => 'cg-gcr' },
        spec => {
            kind      => 'GCRAccessToken',
            generator => {
                gcrAccessTokenSpec => {
                    projectID => 'my-project',
                    auth      => {
                        workloadIdentity => {
                            clusterLocation   => 'europe-west1',
                            clusterName       => 'my-cluster',
                            serviceAccountRef => { name => 'gcr-sa' },
                        },
                    },
                },
            },
        },
    );
    isa_ok($cg2->spec->generator->gcrAccessTokenSpec, 'IO::K8s::ExternalSecrets::V1alpha1::GCRAccessTokenSpec');
    isa_ok($cg2->spec->generator->gcrAccessTokenSpec->auth, 'IO::K8s::ExternalSecrets::V1alpha1::GCRAuth');
    isa_ok($cg2->spec->generator->gcrAccessTokenSpec->auth->workloadIdentity,
        'IO::K8s::ExternalSecrets::V1alpha1::GCRWorkloadIdentity');

    my $cg2_re = $k8s->inflate($k8s->object_to_json($cg2));
    is($cg2_re->spec->generator->gcrAccessTokenSpec->auth->workloadIdentity->clusterName, 'my-cluster',
        'JSON round-trip preserves the second union member (GCRAccessToken) deep field');
};

done_testing;
