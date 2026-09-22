#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use IO::K8s;
use IO::K8s::CertManager;

# --- All cert-manager CRD classes ---

my %classes = (
    # cert-manager.io/v1
    Certificate        => { api_version => 'cert-manager.io/v1',      plural => 'certificates',        namespaced => 1 },
    CertificateRequest => { api_version => 'cert-manager.io/v1',      plural => 'certificaterequests', namespaced => 1 },
    Issuer             => { api_version => 'cert-manager.io/v1',      plural => 'issuers',             namespaced => 1 },
    ClusterIssuer      => { api_version => 'cert-manager.io/v1',      plural => 'clusterissuers',      namespaced => 0 },
    # acme.cert-manager.io/v1
    Order              => { api_version => 'acme.cert-manager.io/v1', plural => 'orders',              namespaced => 1 },
    Challenge          => { api_version => 'acme.cert-manager.io/v1', plural => 'challenges',          namespaced => 1 },
);

# --- Load all 6 classes ---

subtest 'load all cert-manager classes' => sub {
    for my $kind (sort keys %classes) {
        my $class = "IO::K8s::CertManager::V1::$kind";
        use_ok($class) or BAIL_OUT("Cannot load $class");
    }
};

# --- Verify api_version, kind, resource_plural, namespaced ---

subtest 'class metadata' => sub {
    for my $kind (sort keys %classes) {
        my $class = "IO::K8s::CertManager::V1::$kind";
        my $info = $classes{$kind};

        is($class->api_version, $info->{api_version}, "$kind api_version");
        is($class->kind, $kind, "$kind kind");
        is($class->resource_plural, $info->{plural}, "$kind resource_plural");
        if ($info->{namespaced}) {
            ok($class->does('IO::K8s::Role::Namespaced'), "$kind is namespaced");
        } else {
            ok(!$class->does('IO::K8s::Role::Namespaced'), "$kind is cluster-scoped");
        }
    }
};

# --- IO::K8s::CertManager resource_map completeness ---

subtest 'IO::K8s::CertManager resource_map' => sub {
    my $provider = IO::K8s::CertManager->new;
    ok($provider->does('IO::K8s::Role::ResourceMap'), 'consumes ResourceMap role');

    my $map = $provider->resource_map;
    is(scalar keys %$map, 6, 'resource_map has 6 entries');

    for my $kind (sort keys %classes) {
        ok(exists $map->{$kind}, "$kind in resource_map");
        is($map->{$kind}, "CertManager::V1::$kind", "$kind maps to correct class path");
    }
};

# --- new(with => ['IO::K8s::CertManager']) integration ---

subtest 'with constructor parameter' => sub {
    my $k8s = IO::K8s->new(with => ['IO::K8s::CertManager']);

    # All 6 cert-manager kinds should be resolvable by short name
    for my $kind (sort keys %classes) {
        is($k8s->expand_class($kind), "IO::K8s::CertManager::V1::$kind",
            "expand_class('$kind') resolves");
    }

    # Domain-qualified access
    is($k8s->expand_class('cert-manager.io/v1/Certificate'),
        'IO::K8s::CertManager::V1::Certificate',
        'domain-qualified Certificate resolves');
    is($k8s->expand_class('acme.cert-manager.io/v1/Order'),
        'IO::K8s::CertManager::V1::Order',
        'domain-qualified Order resolves');

    # Core resources are unaffected
    is($k8s->expand_class('Pod'), 'IO::K8s::Api::Core::V1::Pod',
        'core Pod still resolves');
    is($k8s->expand_class('Deployment'), 'IO::K8s::Api::Apps::V1::Deployment',
        'core Deployment still resolves');
};

# --- new_object + inflate round-trip ---

subtest 'new_object and inflate round-trip' => sub {
    my $k8s = IO::K8s->new(with => ['IO::K8s::CertManager']);

    # Create a Certificate
    my $cert = $k8s->new_object('Certificate',
        metadata => { name => 'my-cert', namespace => 'default' },
        spec => {
            secretName => 'my-cert-tls',
            issuerRef => { name => 'letsencrypt', kind => 'ClusterIssuer' },
            dnsNames => ['example.com'],
        },
    );
    isa_ok($cert, 'IO::K8s::CertManager::V1::Certificate');
    is($cert->kind, 'Certificate', 'kind');
    is($cert->api_version, 'cert-manager.io/v1', 'api_version');
    isa_ok($cert->metadata, 'IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::ObjectMeta');
    is($cert->metadata->name, 'my-cert', 'name');
    is($cert->metadata->namespace, 'default', 'namespace');

    # Serialize and re-inflate
    my $json = $k8s->object_to_json($cert);
    like($json, qr/"apiVersion":"cert-manager\.io\/v1"/, 'JSON has apiVersion');
    like($json, qr/"kind":"Certificate"/, 'JSON has kind');

    my $re = $k8s->inflate($json);
    isa_ok($re, 'IO::K8s::CertManager::V1::Certificate', 're-inflated');
    is($re->metadata->name, 'my-cert', 'round-trip name preserved');
    is($re->metadata->namespace, 'default', 'round-trip namespace preserved');

    # Create a ClusterIssuer (cluster-scoped)
    my $ci = $k8s->new_object('ClusterIssuer',
        metadata => { name => 'letsencrypt' },
        spec => {
            acme => {
                server => 'https://acme-v02.api.letsencrypt.org/directory',
                email => 'admin@example.com',
            },
        },
    );
    isa_ok($ci, 'IO::K8s::CertManager::V1::ClusterIssuer');
    ok(!$ci->does('IO::K8s::Role::Namespaced'), 'ClusterIssuer is cluster-scoped');

    # Round-trip ClusterIssuer
    my $ci_re = $k8s->inflate($k8s->object_to_json($ci));
    isa_ok($ci_re, 'IO::K8s::CertManager::V1::ClusterIssuer');
    is($ci_re->metadata->name, 'letsencrypt', 'ClusterIssuer round-trip');

    # Create an Order (acme.cert-manager.io/v1)
    my $order = $k8s->new_object('Order',
        metadata => { name => 'my-order', namespace => 'default' },
        spec => { request => 'base64-csr-data' },
    );
    isa_ok($order, 'IO::K8s::CertManager::V1::Order');
    is($order->api_version, 'acme.cert-manager.io/v1', 'Order api_version');
    my $order_re = $k8s->inflate($k8s->object_to_json($order));
    isa_ok($order_re, 'IO::K8s::CertManager::V1::Order');
};

# --- to_yaml output ---

subtest 'to_yaml output' => sub {
    my $k8s = IO::K8s->new(with => ['IO::K8s::CertManager']);

    my $cert = $k8s->new_object('Certificate',
        metadata => { name => 'test-cert', namespace => 'default' },
        spec => { secretName => 'test-tls' },
    );
    my $yaml = $cert->to_yaml;
    like($yaml, qr/apiVersion: cert-manager\.io\/v1/, 'YAML apiVersion');
    like($yaml, qr/kind: Certificate/, 'YAML kind');
    like($yaml, qr/name: test-cert/, 'YAML name');
    like($yaml, qr/namespace: default/, 'YAML namespace');
};

# --- Domain-qualified expand_class ---

subtest 'domain-qualified expand_class' => sub {
    my $k8s = IO::K8s->new(with => ['IO::K8s::CertManager']);

    # cert-manager.io/v1 kinds
    for my $kind (qw(Certificate CertificateRequest Issuer ClusterIssuer)) {
        is($k8s->expand_class("cert-manager.io/v1/$kind"),
            "IO::K8s::CertManager::V1::$kind",
            "cert-manager.io/v1/$kind resolves");
    }

    # acme.cert-manager.io/v1 kinds
    for my $kind (qw(Order Challenge)) {
        is($k8s->expand_class("acme.cert-manager.io/v1/$kind"),
            "IO::K8s::CertManager::V1::$kind",
            "acme.cert-manager.io/v1/$kind resolves");
    }

    # api_version parameter style
    is($k8s->expand_class('Certificate', 'cert-manager.io/v1'),
        'IO::K8s::CertManager::V1::Certificate',
        'api_version parameter disambiguation');
};

# --- pk8s DSL with cert-manager kinds ---

subtest 'pk8s DSL with cert-manager kinds' => sub {
    require File::Temp;
    my $k8s = IO::K8s->new(with => ['IO::K8s::CertManager']);

    my ($fh, $filename) = File::Temp::tempfile(SUFFIX => '.pk8s', UNLINK => 1);
    print $fh q{
        ClusterIssuer {
            name => 'letsencrypt',
            spec => { acme => { server => 'https://acme-v02.api.letsencrypt.org/directory' } },
        };

        Certificate {
            name => 'my-cert',
            namespace => 'default',
            spec => { secretName => 'my-cert-tls', issuerRef => { name => 'letsencrypt' } },
        };

        Order {
            name => 'my-order',
            namespace => 'default',
            spec => { request => 'csr-data' },
        };
    };
    close $fh;

    my $objs = $k8s->load($filename);
    is(scalar(@$objs), 3, 'pk8s loaded 3 cert-manager objects');

    my ($ci, $cert, $order) = @$objs;

    isa_ok($ci, 'IO::K8s::CertManager::V1::ClusterIssuer');
    is($ci->kind, 'ClusterIssuer', 'pk8s ClusterIssuer kind');
    is($ci->metadata->name, 'letsencrypt', 'pk8s ClusterIssuer name');

    isa_ok($cert, 'IO::K8s::CertManager::V1::Certificate');
    is($cert->kind, 'Certificate', 'pk8s Certificate kind');

    isa_ok($order, 'IO::K8s::CertManager::V1::Order');
    is($order->kind, 'Order', 'pk8s Order kind');
    is($order->api_version, 'acme.cert-manager.io/v1', 'pk8s Order api_version');
};

# --- Full depth round-trip: every class below spec/status is now a typed
# object graph (D5, k95, task B-cert-manager), not an opaque hashref -- one
# subtest per Kind, built via new_object/hashrefs (the coercing path; a
# direct ->new(spec => {...}) does not coerce, k100) so nested classes come
# out typed. ---

subtest 'full depth round-trip: Certificate' => sub {
    my $k8s = IO::K8s->new(with => ['IO::K8s::CertManager']);
    my $cert = $k8s->new_object('Certificate',
        metadata => { name => 'web-cert', namespace => 'default' },
        spec => {
            secretName => 'web-tls',
            issuerRef  => { name => 'letsencrypt-prod', kind => 'ClusterIssuer' },
            dnsNames   => ['example.com', 'www.example.com'],
            subject    => { organizations => ['Example Inc'], countries => ['US'] },
            privateKey => { algorithm => 'ECDSA', size => 256, rotationPolicy => 'Always' },
            keystores  => {
                jks    => { create => 1, passwordSecretRef => { name => 'jks-pass', key => 'password' } },
                pkcs12 => { create => 1, passwordSecretRef => { name => 'p12-pass' }, profile => 'Modern2023' },
            },
            secretTemplate => { labels => { app => 'web' } },
            renewal        => { policy => 'RenewBefore', windows => [{ cron => '0 0 * * *', windowDuration => '1h' }] },
            nameConstraints => { critical => 1, permitted => { dnsDomains => ['example.com'] } },
            additionalOutputFormats => [{ type => 'DER' }],
            otherNames              => [{ oid => '1.3.6.1.4.1.311.20.2.3', utf8Value => 'user@example.com' }],
        },
    );

    isa_ok($cert->spec, 'IO::K8s::CertManager::V1::CertificateSpec');
    isa_ok($cert->spec->issuerRef, 'IO::K8s::CertManager::V1::IssuerReference');
    isa_ok($cert->spec->subject, 'IO::K8s::CertManager::V1::X509Subject');
    isa_ok($cert->spec->privateKey, 'IO::K8s::CertManager::V1::CertificatePrivateKey');
    isa_ok($cert->spec->keystores, 'IO::K8s::CertManager::V1::CertificateKeystores');
    isa_ok($cert->spec->keystores->jks, 'IO::K8s::CertManager::V1::JKSKeystore');
    isa_ok($cert->spec->keystores->jks->passwordSecretRef, 'IO::K8s::CertManager::V1::SecretKeySelector');
    isa_ok($cert->spec->keystores->pkcs12, 'IO::K8s::CertManager::V1::PKCS12Keystore');
    isa_ok($cert->spec->renewal, 'IO::K8s::CertManager::V1::CertificateRenewal');
    isa_ok($cert->spec->renewal->windows->[0], 'IO::K8s::CertManager::V1::CertificateRenewalWindows');
    isa_ok($cert->spec->nameConstraints, 'IO::K8s::CertManager::V1::NameConstraints');
    isa_ok($cert->spec->nameConstraints->permitted, 'IO::K8s::CertManager::V1::NameConstraintItem');
    isa_ok($cert->spec->additionalOutputFormats->[0], 'IO::K8s::CertManager::V1::CertificateAdditionalOutputFormat');
    isa_ok($cert->spec->otherNames->[0], 'IO::K8s::CertManager::V1::OtherName');

    my $spec_json = $cert->TO_JSON->{spec};
    is($spec_json->{issuerRef}{kind}, 'ClusterIssuer', 'TO_JSON issuerRef.kind');
    is($spec_json->{keystores}{jks}{passwordSecretRef}{key}, 'password', 'TO_JSON keystores.jks.passwordSecretRef.key');
    is($spec_json->{renewal}{windows}[0]{cron}, '0 0 * * *', 'TO_JSON renewal.windows[0].cron');
    is($spec_json->{nameConstraints}{permitted}{dnsDomains}[0], 'example.com', 'TO_JSON nameConstraints.permitted.dnsDomains[0]');
    is($spec_json->{otherNames}[0]{oid}, '1.3.6.1.4.1.311.20.2.3', 'TO_JSON otherNames[0].oid');

    my $re = $k8s->inflate($k8s->object_to_json($cert));
    isa_ok($re, 'IO::K8s::CertManager::V1::Certificate');
    is($re->spec->keystores->pkcs12->profile, 'Modern2023', 'JSON round-trip preserves keystores.pkcs12.profile');
};

subtest 'full depth round-trip: CertificateRequest' => sub {
    my $k8s = IO::K8s->new(with => ['IO::K8s::CertManager']);
    my $cr = $k8s->new_object('CertificateRequest',
        metadata => { name => 'web-cr', namespace => 'default' },
        spec => {
            issuerRef => { name => 'letsencrypt-prod', kind => 'ClusterIssuer' },
            request   => 'base64-csr-data',
            isCA      => 0,
            usages    => ['digital signature', 'key encipherment'],
        },
        status => {
            certificate => 'base64-cert-data',
            conditions  => [{ type => 'Ready', status => 'True' }],
        },
    );

    isa_ok($cr->spec, 'IO::K8s::CertManager::V1::CertificateRequestSpec');
    isa_ok($cr->spec->issuerRef, 'IO::K8s::CertManager::V1::IssuerReference');
    isa_ok($cr->status, 'IO::K8s::CertManager::V1::CertificateRequestStatus');
    isa_ok($cr->status->conditions->[0], 'IO::K8s::CertManager::V1::CertificateRequestCondition',
        'cert-manager-owned CertificateRequestCondition for conditions (k135)');
    is($cr->status->conditions->[0]->type, 'Ready', 'nested status.conditions[0].type');

    my $json = $cr->TO_JSON;
    is($json->{spec}{usages}[1], 'key encipherment', 'TO_JSON spec.usages[1]');
    is($json->{status}{conditions}[0]{status}, 'True', 'TO_JSON status.conditions[0].status');

    my $re = $k8s->inflate($k8s->object_to_json($cr));
    is($re->spec->request, 'base64-csr-data', 'JSON round-trip preserves spec.request');
};

subtest 'full depth round-trip: Issuer' => sub {
    my $k8s = IO::K8s->new(with => ['IO::K8s::CertManager']);
    my $iss = $k8s->new_object('Issuer',
        metadata => { name => 'multi-issuer', namespace => 'default' },
        spec => {
            acme => {
                email  => 'ops@example.com',
                server => 'https://acme-v02.api.letsencrypt.org/directory',
                privateKeySecretRef => { name => 'acme-account-key' },
                solvers => [
                    {
                        selector => { dnsNames => ['example.com'] },
                        http01   => {
                            ingress => {
                                class       => 'nginx',
                                podTemplate => {
                                    metadata => { labels => { app => 'solver' } },
                                    spec     => { serviceAccountName => 'acme-solver' },
                                },
                            },
                        },
                    },
                    {
                        dns01 => {
                            route53 => {
                                region => 'us-east-1',
                                auth   => { kubernetes => { serviceAccountRef => { name => 'route53-sa' } } },
                            },
                        },
                    },
                ],
            },
        },
    );

    isa_ok($iss->spec, 'IO::K8s::CertManager::V1::IssuerSpec');
    isa_ok($iss->spec->acme, 'IO::K8s::CertManager::V1::ACMEIssuer');
    isa_ok($iss->spec->acme->privateKeySecretRef, 'IO::K8s::CertManager::V1::SecretKeySelector');
    my $solvers = $iss->spec->acme->solvers;
    isa_ok($solvers->[0], 'IO::K8s::CertManager::V1::ACMEChallengeSolver');
    isa_ok($solvers->[0]->selector, 'IO::K8s::CertManager::V1::CertificateDNSNameSelector');
    isa_ok($solvers->[0]->http01, 'IO::K8s::CertManager::V1::ACMEChallengeSolverHTTP01');
    isa_ok($solvers->[0]->http01->ingress, 'IO::K8s::CertManager::V1::ACMEChallengeSolverHTTP01Ingress');
    isa_ok($solvers->[0]->http01->ingress->podTemplate, 'IO::K8s::CertManager::V1::ACMEChallengeSolverHTTP01IngressPodTemplate');
    is($solvers->[0]->http01->ingress->podTemplate->spec->serviceAccountName, 'acme-solver',
        'nested http01.ingress.podTemplate.spec.serviceAccountName');
    isa_ok($solvers->[1]->dns01, 'IO::K8s::CertManager::V1::ACMEChallengeSolverDNS01');
    isa_ok($solvers->[1]->dns01->route53, 'IO::K8s::CertManager::V1::ACMEIssuerDNS01ProviderRoute53');
    isa_ok($solvers->[1]->dns01->route53->auth, 'IO::K8s::CertManager::V1::Route53Auth');
    isa_ok($solvers->[1]->dns01->route53->auth->kubernetes, 'IO::K8s::CertManager::V1::Route53KubernetesAuth');
    isa_ok($solvers->[1]->dns01->route53->auth->kubernetes->serviceAccountRef, 'IO::K8s::CertManager::V1::ServiceAccountRef');

    my $spec_json = $iss->TO_JSON->{spec};
    is($spec_json->{acme}{solvers}[0]{http01}{ingress}{podTemplate}{metadata}{labels}{app}, 'solver',
        'TO_JSON solvers[0].http01.ingress.podTemplate.metadata.labels.app');
    is($spec_json->{acme}{solvers}[1]{dns01}{route53}{auth}{kubernetes}{serviceAccountRef}{name}, 'route53-sa',
        'TO_JSON solvers[1].dns01.route53.auth.kubernetes.serviceAccountRef.name');

    my $re = $k8s->inflate($k8s->object_to_json($iss));
    is($re->spec->acme->solvers->[1]->dns01->route53->region, 'us-east-1',
        'JSON round-trip preserves solvers[1].dns01.route53.region');
};

subtest 'full depth round-trip: ClusterIssuer (shares IssuerSpec with Issuer)' => sub {
    my $k8s = IO::K8s->new(with => ['IO::K8s::CertManager']);
    my $ci = $k8s->new_object('ClusterIssuer',
        metadata => { name => 'vault-ci' },
        spec => {
            vault => {
                server => 'https://vault.example.com:8200',
                path   => 'pki/sign/example-dot-com',
                auth   => { appRole => { path => 'approle', roleId => 'role-1', secretRef => { name => 'vault-secret', key => 'secretId' } } },
            },
        },
    );

    isa_ok($ci->spec, 'IO::K8s::CertManager::V1::IssuerSpec');
    is(ref($ci->spec), 'IO::K8s::CertManager::V1::IssuerSpec',
        'ClusterIssuer.spec is the literal same class as Issuer.spec (D6: shared Go type)');
    isa_ok($ci->spec->vault, 'IO::K8s::CertManager::V1::VaultIssuer');
    isa_ok($ci->spec->vault->auth, 'IO::K8s::CertManager::V1::VaultAuth');
    isa_ok($ci->spec->vault->auth->appRole, 'IO::K8s::CertManager::V1::VaultAppRole');
    isa_ok($ci->spec->vault->auth->appRole->secretRef, 'IO::K8s::CertManager::V1::SecretKeySelector');
    is($ci->spec->vault->auth->appRole->roleId, 'role-1', 'nested vault.auth.appRole.roleId');

    my $spec_json = $ci->TO_JSON->{spec};
    is($spec_json->{vault}{auth}{appRole}{secretRef}{key}, 'secretId',
        'TO_JSON vault.auth.appRole.secretRef.key');

    my $re = $k8s->inflate($k8s->object_to_json($ci));
    is($re->spec->vault->path, 'pki/sign/example-dot-com', 'JSON round-trip preserves vault.path');
};

subtest 'full depth round-trip: Order' => sub {
    my $k8s = IO::K8s->new(with => ['IO::K8s::CertManager']);
    my $order = $k8s->new_object('Order',
        metadata => { name => 'web-order', namespace => 'default' },
        spec => {
            issuerRef => { name => 'letsencrypt-prod', kind => 'ClusterIssuer' },
            request   => 'base64-csr-data',
            dnsNames  => ['example.com'],
        },
        status => {
            state          => 'pending',
            authorizations => [{
                url        => 'https://acme.example.com/authz/1',
                identifier => 'example.com',
                challenges => [{ url => 'https://acme.example.com/chal/1', token => 'tok123', type => 'http-01' }],
            }],
        },
    );

    isa_ok($order->spec, 'IO::K8s::CertManager::V1::OrderSpec');
    isa_ok($order->spec->issuerRef, 'IO::K8s::CertManager::V1::IssuerReference');
    isa_ok($order->status, 'IO::K8s::CertManager::V1::OrderStatus');
    isa_ok($order->status->authorizations->[0], 'IO::K8s::CertManager::V1::ACMEAuthorization');
    isa_ok($order->status->authorizations->[0]->challenges->[0], 'IO::K8s::CertManager::V1::ACMEChallenge');
    is($order->status->authorizations->[0]->challenges->[0]->token, 'tok123',
        'nested status.authorizations[0].challenges[0].token');

    my $json = $order->TO_JSON;
    is($json->{status}{authorizations}[0]{challenges}[0]{type}, 'http-01',
        'TO_JSON status.authorizations[0].challenges[0].type');

    my $re = $k8s->inflate($k8s->object_to_json($order));
    is($re->status->authorizations->[0]->identifier, 'example.com',
        'JSON round-trip preserves status.authorizations[0].identifier');
};

subtest 'full depth round-trip: Challenge' => sub {
    my $k8s = IO::K8s->new(with => ['IO::K8s::CertManager']);
    my $chal = $k8s->new_object('Challenge',
        metadata => { name => 'web-chal', namespace => 'default' },
        spec => {
            url              => 'https://acme.example.com/chal/1',
            authorizationURL => 'https://acme.example.com/authz/1',
            dnsName          => 'example.com',
            type             => 'DNS-01',
            token            => 'tok123',
            key              => 'key123',
            issuerRef        => { name => 'letsencrypt-prod', kind => 'ClusterIssuer' },
            solver           => {
                dns01 => {
                    cloudflare => { apiTokenSecretRef => { name => 'cf-token', key => 'api-token' } },
                },
            },
        },
        status => { processing => 1, presented => 1, state => 'pending' },
    );

    isa_ok($chal->spec, 'IO::K8s::CertManager::V1::ChallengeSpec');
    isa_ok($chal->spec->issuerRef, 'IO::K8s::CertManager::V1::IssuerReference');
    isa_ok($chal->spec->solver, 'IO::K8s::CertManager::V1::ACMEChallengeSolver');
    isa_ok($chal->spec->solver->dns01, 'IO::K8s::CertManager::V1::ACMEChallengeSolverDNS01');
    isa_ok($chal->spec->solver->dns01->cloudflare, 'IO::K8s::CertManager::V1::ACMEIssuerDNS01ProviderCloudflare');
    isa_ok($chal->spec->solver->dns01->cloudflare->apiTokenSecretRef, 'IO::K8s::CertManager::V1::SecretKeySelector');
    isa_ok($chal->status, 'IO::K8s::CertManager::V1::ChallengeStatus');

    my $spec_json = $chal->TO_JSON->{spec};
    is($spec_json->{solver}{dns01}{cloudflare}{apiTokenSecretRef}{name}, 'cf-token',
        'TO_JSON solver.dns01.cloudflare.apiTokenSecretRef.name');

    my $re = $k8s->inflate($k8s->object_to_json($chal));
    is($re->spec->solver->dns01->cloudflare->apiTokenSecretRef->key, 'api-token',
        'JSON round-trip preserves solver.dns01.cloudflare.apiTokenSecretRef.key');
};

done_testing;
