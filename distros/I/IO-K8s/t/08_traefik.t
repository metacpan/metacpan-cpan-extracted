#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use IO::K8s;
use IO::K8s::Traefik;

# --- All Traefik CRD classes (all traefik.io/v1alpha1, all namespaced) ---

my %classes = (
    IngressRoute        => { plural => 'ingressroutes' },
    IngressRouteTCP     => { plural => 'ingressroutetcps' },
    IngressRouteUDP     => { plural => 'ingressrouteudps' },
    Middleware          => { plural => 'middlewares' },
    MiddlewareTCP       => { plural => 'middlewaretcps' },
    ServersTransport    => { plural => 'serverstransports' },
    ServersTransportTCP => { plural => 'serverstransporttcps' },
    TLSOption           => { plural => 'tlsoptions' },
    TLSStore            => { plural => 'tlsstores' },
    TraefikService      => { plural => 'traefikservices' },
);

# --- Load all 10 classes ---

subtest 'load all Traefik classes' => sub {
    for my $kind (sort keys %classes) {
        my $class = "IO::K8s::Traefik::V1alpha1::$kind";
        use_ok($class) or BAIL_OUT("Cannot load $class");
    }
};

# --- Verify api_version, kind, resource_plural, namespaced ---

subtest 'class metadata' => sub {
    for my $kind (sort keys %classes) {
        my $class = "IO::K8s::Traefik::V1alpha1::$kind";
        my $info = $classes{$kind};

        is($class->api_version, 'traefik.io/v1alpha1', "$kind api_version");
        is($class->kind, $kind, "$kind kind");
        is($class->resource_plural, $info->{plural}, "$kind resource_plural");
        ok($class->does('IO::K8s::Role::Namespaced'), "$kind is namespaced");
    }
};

# --- IO::K8s::Traefik resource_map completeness ---

subtest 'IO::K8s::Traefik resource_map' => sub {
    my $provider = IO::K8s::Traefik->new;
    ok($provider->does('IO::K8s::Role::ResourceMap'), 'consumes ResourceMap role');

    my $map = $provider->resource_map;
    is(scalar keys %$map, 10, 'resource_map has 10 entries');

    for my $kind (sort keys %classes) {
        ok(exists $map->{$kind}, "$kind in resource_map");
        is($map->{$kind}, "Traefik::V1alpha1::$kind", "$kind maps to correct class path");
    }
};

# --- new(with => ['IO::K8s::Traefik']) integration ---

subtest 'with constructor parameter' => sub {
    my $k8s = IO::K8s->new(with => ['IO::K8s::Traefik']);

    # All 10 Traefik kinds should be resolvable by short name
    for my $kind (sort keys %classes) {
        is($k8s->expand_class($kind), "IO::K8s::Traefik::V1alpha1::$kind",
            "expand_class('$kind') resolves");
    }

    # Core resources are unaffected
    is($k8s->expand_class('Pod'), 'IO::K8s::Api::Core::V1::Pod',
        'core Pod still resolves');
    is($k8s->expand_class('Deployment'), 'IO::K8s::Api::Apps::V1::Deployment',
        'core Deployment still resolves');
};

# --- new_object + inflate round-trip ---

subtest 'new_object and inflate round-trip' => sub {
    my $k8s = IO::K8s->new(with => ['IO::K8s::Traefik']);

    # Create an IngressRoute
    my $ir = $k8s->new_object('IngressRoute',
        metadata => { name => 'my-route', namespace => 'default' },
        spec => {
            entryPoints => ['web'],
            routes => [{ match => 'Host(`example.com`)', kind => 'Rule' }],
        },
    );
    isa_ok($ir, 'IO::K8s::Traefik::V1alpha1::IngressRoute');
    is($ir->kind, 'IngressRoute', 'kind');
    is($ir->api_version, 'traefik.io/v1alpha1', 'api_version');
    isa_ok($ir->metadata, 'IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::ObjectMeta');
    is($ir->metadata->name, 'my-route', 'name');
    is($ir->metadata->namespace, 'default', 'namespace');

    # Serialize and re-inflate
    my $json = $k8s->object_to_json($ir);
    like($json, qr/"apiVersion":"traefik\.io\/v1alpha1"/, 'JSON has apiVersion');
    like($json, qr/"kind":"IngressRoute"/, 'JSON has kind');

    my $re = $k8s->inflate($json);
    isa_ok($re, 'IO::K8s::Traefik::V1alpha1::IngressRoute', 're-inflated');
    is($re->metadata->name, 'my-route', 'round-trip name preserved');
    is($re->metadata->namespace, 'default', 'round-trip namespace preserved');

    # Create a Middleware
    my $mw = $k8s->new_object('Middleware',
        metadata => { name => 'rate-limit', namespace => 'default' },
        spec => { rateLimit => { average => 100, burst => 200 } },
    );
    isa_ok($mw, 'IO::K8s::Traefik::V1alpha1::Middleware');
    ok($mw->does('IO::K8s::Role::Namespaced'), 'Middleware is namespaced');

    # Round-trip Middleware
    my $mw_re = $k8s->inflate($k8s->object_to_json($mw));
    isa_ok($mw_re, 'IO::K8s::Traefik::V1alpha1::Middleware');
    is($mw_re->metadata->name, 'rate-limit', 'Middleware round-trip');
};

# --- to_yaml output ---

subtest 'to_yaml output' => sub {
    my $k8s = IO::K8s->new(with => ['IO::K8s::Traefik']);

    my $ir = $k8s->new_object('IngressRoute',
        metadata => { name => 'test-route', namespace => 'default' },
        spec => { entryPoints => ['web'] },
    );
    my $yaml = $ir->to_yaml;
    like($yaml, qr/apiVersion: traefik\.io\/v1alpha1/, 'YAML apiVersion');
    like($yaml, qr/kind: IngressRoute/, 'YAML kind');
    like($yaml, qr/name: test-route/, 'YAML name');
    like($yaml, qr/namespace: default/, 'YAML namespace');
};

# --- Domain-qualified expand_class ---

subtest 'domain-qualified expand_class' => sub {
    my $k8s = IO::K8s->new(with => ['IO::K8s::Traefik']);

    for my $kind (sort keys %classes) {
        is($k8s->expand_class("traefik.io/v1alpha1/$kind"),
            "IO::K8s::Traefik::V1alpha1::$kind",
            "traefik.io/v1alpha1/$kind resolves");
    }

    # api_version parameter style
    is($k8s->expand_class('IngressRoute', 'traefik.io/v1alpha1'),
        'IO::K8s::Traefik::V1alpha1::IngressRoute',
        'api_version parameter disambiguation');
};

# --- pk8s DSL with Traefik kinds ---

subtest 'pk8s DSL with Traefik kinds' => sub {
    require File::Temp;
    my $k8s = IO::K8s->new(with => ['IO::K8s::Traefik']);

    my ($fh, $filename) = File::Temp::tempfile(SUFFIX => '.pk8s', UNLINK => 1);
    print $fh q{
        IngressRoute {
            name => 'my-route',
            namespace => 'default',
            spec => { entryPoints => ['web'] },
        };

        Middleware {
            name => 'rate-limit',
            namespace => 'default',
            spec => { rateLimit => { average => 100 } },
        };

        TraefikService {
            name => 'mirror-svc',
            namespace => 'default',
            spec => { mirroring => { name => 'svc1' } },
        };
    };
    close $fh;

    my $objs = $k8s->load($filename);
    is(scalar(@$objs), 3, 'pk8s loaded 3 Traefik objects');

    my ($ir, $mw, $ts) = @$objs;

    isa_ok($ir, 'IO::K8s::Traefik::V1alpha1::IngressRoute');
    is($ir->kind, 'IngressRoute', 'pk8s IngressRoute kind');
    is($ir->metadata->name, 'my-route', 'pk8s IngressRoute name');

    isa_ok($mw, 'IO::K8s::Traefik::V1alpha1::Middleware');
    is($mw->kind, 'Middleware', 'pk8s Middleware kind');

    isa_ok($ts, 'IO::K8s::Traefik::V1alpha1::TraefikService');
    is($ts->kind, 'TraefikService', 'pk8s TraefikService kind');
    is($ts->api_version, 'traefik.io/v1alpha1', 'pk8s TraefikService api_version');
};

# --- Full depth round-trip (k95/D5): each Kind's manifest, written from
# the upstream traefik/traefik v3.7.12 Go sources (pkg/provider/kubernetes/
# crd/traefikio/v1alpha1, pkg/config/dynamic), inflates into typed nested
# objects several levels deep and TO_JSON reproduces it exactly. ---

subtest 'full depth round-trip: IngressRoute' => sub {
    my $k8s = IO::K8s->new(with => ['IO::K8s::Traefik']);
    my $ir = $k8s->new_object('IngressRoute',
        metadata => { name => 'web-route', namespace => 'default' },
        spec => {
            entryPoints => ['web', 'websecure'],
            routes => [{
                match       => 'Host(`example.com`)',
                kind        => 'Rule',
                priority    => 10,
                services    => [{
                    name        => 'web-svc',
                    port        => 80,
                    weight      => 1,
                    healthCheck => { path => '/healthz', interval => '10s' },
                }],
                middlewares   => [{ name => 'rate-limit', namespace => 'default' }],
                observability => { accessLogs => 1 },
            }],
            tls => {
                secretName => 'web-tls',
                options    => { name => 'default' },
                domains    => [{ main => 'example.com', sans => ['www.example.com'] }],
            },
        },
    );

    isa_ok($ir->spec, 'IO::K8s::Traefik::V1alpha1::IngressRouteSpec');
    my $route = $ir->spec->routes->[0];
    isa_ok($route, 'IO::K8s::Traefik::V1alpha1::Route');
    my $svc = $route->services->[0];
    isa_ok($svc, 'IO::K8s::Traefik::V1alpha1::Service');
    isa_ok($svc->healthCheck, 'IO::K8s::Traefik::V1alpha1::ServerHealthCheck');
    is($svc->healthCheck->path, '/healthz', 'nested healthCheck.path');
    isa_ok($route->middlewares->[0], 'IO::K8s::Api::Core::V1::SecretReference',
        'reused core SecretReference for middlewares (reuse_core, D5)');
    isa_ok($route->observability, 'IO::K8s::Traefik::V1alpha1::RouterObservabilityConfig');
    isa_ok($ir->spec->tls, 'IO::K8s::Traefik::V1alpha1::TLS');
    isa_ok($ir->spec->tls->domains->[0], 'IO::K8s::Traefik::V1alpha1::Domain');
    is($ir->spec->tls->domains->[0]->main, 'example.com', 'nested tls.domains[0].main');

    my $spec_json = $ir->TO_JSON->{spec};
    is($spec_json->{tls}{secretName}, 'web-tls', 'TO_JSON tls.secretName');
    is($spec_json->{routes}[0]{services}[0]{healthCheck}{interval}, '10s',
        'TO_JSON routes[0].services[0].healthCheck.interval');
    is($spec_json->{routes}[0]{middlewares}[0]{name}, 'rate-limit', 'TO_JSON middlewares[0].name');
    ok($spec_json->{routes}[0]{observability}{accessLogs}, 'TO_JSON observability.accessLogs true');

    my $re = $k8s->inflate($k8s->object_to_json($ir));
    isa_ok($re, 'IO::K8s::Traefik::V1alpha1::IngressRoute');
    is($re->spec->routes->[0]->services->[0]->name, 'web-svc', 'JSON round-trip preserves nested name');
};

subtest 'full depth round-trip: IngressRouteTCP' => sub {
    my $k8s = IO::K8s->new(with => ['IO::K8s::Traefik']);
    my $ir = $k8s->new_object('IngressRouteTCP',
        metadata => { name => 'tcp-route', namespace => 'default' },
        spec => {
            entryPoints => ['tcp-ep'],
            routes => [{
                match    => 'HostSNI(`*`)',
                priority => 5,
                services => [{
                    name          => 'tcp-svc',
                    port          => 6379,
                    weight        => 1,
                    proxyProtocol => { version => 2 },
                }],
            }],
            tls => {
                secretName  => 'tcp-tls',
                passthrough => 1,
                domains     => [{ main => 'tcp.example.com' }],
            },
        },
    );

    my $route = $ir->spec->routes->[0];
    isa_ok($route, 'IO::K8s::Traefik::V1alpha1::RouteTCP');
    my $svc = $route->services->[0];
    isa_ok($svc, 'IO::K8s::Traefik::V1alpha1::ServiceTCP');
    isa_ok($svc->proxyProtocol, 'IO::K8s::Traefik::V1alpha1::ProxyProtocol');
    is($svc->proxyProtocol->version, 2, 'nested proxyProtocol.version');
    isa_ok($ir->spec->tls, 'IO::K8s::Traefik::V1alpha1::TLSTCP');

    my $spec_json = $ir->TO_JSON->{spec};
    is($spec_json->{routes}[0]{services}[0]{proxyProtocol}{version}, 2,
        'TO_JSON routes[0].services[0].proxyProtocol.version');
    ok($spec_json->{tls}{passthrough}, 'TO_JSON tls.passthrough true');
    is($spec_json->{tls}{domains}[0]{main}, 'tcp.example.com', 'TO_JSON tls.domains[0].main');

    my $re = $k8s->inflate($k8s->object_to_json($ir));
    is($re->spec->routes->[0]->services->[0]->port, 6379, 'JSON round-trip preserves nested port');
};

subtest 'full depth round-trip: IngressRouteUDP' => sub {
    my $k8s = IO::K8s->new(with => ['IO::K8s::Traefik']);
    my $ir = $k8s->new_object('IngressRouteUDP',
        metadata => { name => 'udp-route', namespace => 'default' },
        spec => {
            entryPoints => ['udp-ep'],
            routes => [{ services => [{ name => 'udp-svc', port => 53, weight => 1 }] }],
        },
    );

    my $route = $ir->spec->routes->[0];
    isa_ok($route, 'IO::K8s::Traefik::V1alpha1::RouteUDP');
    my $svc = $route->services->[0];
    isa_ok($svc, 'IO::K8s::Traefik::V1alpha1::ServiceUDP');
    is($svc->port, 53, 'nested services[0].port');

    my $spec_json = $ir->TO_JSON->{spec};
    is($spec_json->{routes}[0]{services}[0]{name}, 'udp-svc', 'TO_JSON routes[0].services[0].name');

    my $re = $k8s->inflate($k8s->object_to_json($ir));
    is($re->spec->routes->[0]->services->[0]->weight, 1, 'JSON round-trip preserves nested weight');
};

subtest 'full depth round-trip: Middleware' => sub {
    my $k8s = IO::K8s->new(with => ['IO::K8s::Traefik']);
    my $mw = $k8s->new_object('Middleware',
        metadata => { name => 'my-mw', namespace => 'default' },
        spec => {
            rateLimit => {
                average         => 100,
                burst           => 200,
                period          => '1m',
                sourceCriterion => { ipStrategy => { depth => 1 } },
                redis           => { endpoints => ['redis:6379'], tls => { caSecret => 'ca-secret' } },
            },
            headers     => { customRequestHeaders => { 'X-Foo' => 'bar' } },
            stripPrefix => { prefixes => ['/api'] },
            errors      => {
                status  => ['500-599'],
                query   => '/error',
                service => { name => 'err-svc', port => 8080 },
            },
        },
    );

    isa_ok($mw->spec, 'IO::K8s::Traefik::V1alpha1::MiddlewareSpec');
    my $rl = $mw->spec->rateLimit;
    isa_ok($rl, 'IO::K8s::Traefik::V1alpha1::RateLimit');
    isa_ok($rl->sourceCriterion, 'IO::K8s::Traefik::V1alpha1::SourceCriterion');
    isa_ok($rl->sourceCriterion->ipStrategy, 'IO::K8s::Traefik::V1alpha1::IPStrategy');
    is($rl->sourceCriterion->ipStrategy->depth, 1, 'nested rateLimit.sourceCriterion.ipStrategy.depth');
    isa_ok($rl->redis, 'IO::K8s::Traefik::V1alpha1::Redis');
    isa_ok($rl->redis->tls, 'IO::K8s::Traefik::V1alpha1::ClientTLS');
    is($rl->redis->tls->caSecret, 'ca-secret', 'nested rateLimit.redis.tls.caSecret');
    isa_ok($mw->spec->errors, 'IO::K8s::Traefik::V1alpha1::ErrorPage');
    isa_ok($mw->spec->errors->service, 'IO::K8s::Traefik::V1alpha1::Service');
    is($mw->spec->errors->service->name, 'err-svc', 'nested errors.service.name');

    my $spec_json = $mw->TO_JSON->{spec};
    is($spec_json->{rateLimit}{redis}{endpoints}[0], 'redis:6379', 'TO_JSON rateLimit.redis.endpoints[0]');
    is($spec_json->{headers}{customRequestHeaders}{'X-Foo'}, 'bar', 'TO_JSON headers.customRequestHeaders');
    is_deeply($spec_json->{stripPrefix}, { prefixes => ['/api'] }, 'TO_JSON stripPrefix');

    my $re = $k8s->inflate($k8s->object_to_json($mw));
    is($re->spec->rateLimit->average, 100, 'JSON round-trip preserves nested average');
};

subtest 'full depth round-trip: MiddlewareTCP' => sub {
    my $k8s = IO::K8s->new(with => ['IO::K8s::Traefik']);
    my $mw = $k8s->new_object('MiddlewareTCP',
        metadata => { name => 'my-mw-tcp', namespace => 'default' },
        spec => {
            inFlightConn => { amount => 10 },
            ipAllowList  => { sourceRange => ['10.0.0.0/8'] },
        },
    );

    isa_ok($mw->spec->inFlightConn, 'IO::K8s::Traefik::V1alpha1::TCPInFlightConn');
    isa_ok($mw->spec->ipAllowList, 'IO::K8s::Traefik::V1alpha1::TCPIPAllowList');
    is($mw->spec->inFlightConn->amount, 10, 'nested inFlightConn.amount');

    my $spec_json = $mw->TO_JSON->{spec};
    is_deeply($spec_json, {
        inFlightConn => { amount => 10 },
        ipAllowList  => { sourceRange => ['10.0.0.0/8'] },
    }, 'TO_JSON reproduces the manifest exactly');
};

subtest 'full depth round-trip: ServersTransport' => sub {
    my $k8s = IO::K8s->new(with => ['IO::K8s::Traefik']);
    my $st = $k8s->new_object('ServersTransport',
        metadata => { name => 'my-st', namespace => 'default' },
        spec => {
            serverName          => 'backend.example.com',
            insecureSkipVerify  => 0,
            rootCAs             => [{ secret => 'ca-secret' }],
            forwardingTimeouts  => { dialTimeout => '30s' },
            spiffe              => { ids => ['spiffe://example.org/svc'], trustDomain => 'example.org' },
        },
    );

    isa_ok($st->spec->rootCAs->[0], 'IO::K8s::Traefik::V1alpha1::RootCA');
    isa_ok($st->spec->forwardingTimeouts, 'IO::K8s::Traefik::V1alpha1::ForwardingTimeouts');
    isa_ok($st->spec->spiffe, 'IO::K8s::Traefik::V1alpha1::Spiffe');
    is($st->spec->spiffe->trustDomain, 'example.org', 'nested spiffe.trustDomain');

    my $spec_json = $st->TO_JSON->{spec};
    is($spec_json->{rootCAs}[0]{secret}, 'ca-secret', 'TO_JSON rootCAs[0].secret');
    is($spec_json->{forwardingTimeouts}{dialTimeout}, '30s', 'TO_JSON forwardingTimeouts.dialTimeout');

    my $re = $k8s->inflate($k8s->object_to_json($st));
    is($re->spec->spiffe->ids->[0], 'spiffe://example.org/svc', 'JSON round-trip preserves nested spiffe.ids');
};

subtest 'full depth round-trip: ServersTransportTCP' => sub {
    my $k8s = IO::K8s->new(with => ['IO::K8s::Traefik']);
    my $stt = $k8s->new_object('ServersTransportTCP',
        metadata => { name => 'my-stt', namespace => 'default' },
        spec => {
            dialTimeout   => '30s',
            proxyProtocol => { version => 1 },
            tls => {
                serverName => 'backend.example.com',
                rootCAs    => [{ configMap => 'ca-cm' }],
                spiffe     => { trustDomain => 'example.org' },
            },
        },
    );

    isa_ok($stt->spec->proxyProtocol, 'IO::K8s::Traefik::V1alpha1::ProxyProtocol');
    isa_ok($stt->spec->tls, 'IO::K8s::Traefik::V1alpha1::TLSClientConfig');
    isa_ok($stt->spec->tls->rootCAs->[0], 'IO::K8s::Traefik::V1alpha1::RootCA');
    isa_ok($stt->spec->tls->spiffe, 'IO::K8s::Traefik::V1alpha1::Spiffe');
    is($stt->spec->tls->rootCAs->[0]->configMap, 'ca-cm', 'nested tls.rootCAs[0].configMap');

    my $spec_json = $stt->TO_JSON->{spec};
    is($spec_json->{proxyProtocol}{version}, 1, 'TO_JSON proxyProtocol.version');
    is($spec_json->{tls}{spiffe}{trustDomain}, 'example.org', 'TO_JSON tls.spiffe.trustDomain');

    my $re = $k8s->inflate($k8s->object_to_json($stt));
    is($re->spec->tls->serverName, 'backend.example.com', 'JSON round-trip preserves nested tls.serverName');
};

subtest 'full depth round-trip: TLSOption' => sub {
    my $k8s = IO::K8s->new(with => ['IO::K8s::Traefik']);
    my $to = $k8s->new_object('TLSOption',
        metadata => { name => 'my-tlsopt', namespace => 'default' },
        spec => {
            minVersion   => 'VersionTLS12',
            maxVersion   => 'VersionTLS13',
            cipherSuites => ['TLS_AES_128_GCM_SHA256'],
            clientAuth   => { secretNames => ['ca-secret'], clientAuthType => 'RequireAndVerifyClientCert' },
            sniStrict    => 1,
        },
    );

    isa_ok($to->spec->clientAuth, 'IO::K8s::Traefik::V1alpha1::ClientAuth');
    is($to->spec->clientAuth->clientAuthType, 'RequireAndVerifyClientCert', 'nested clientAuth.clientAuthType');

    my $spec_json = $to->TO_JSON->{spec};
    is($spec_json->{minVersion}, 'VersionTLS12', 'TO_JSON minVersion');
    is_deeply($spec_json->{clientAuth}{secretNames}, ['ca-secret'], 'TO_JSON clientAuth.secretNames');
    ok($spec_json->{sniStrict}, 'TO_JSON sniStrict true');

    my $re = $k8s->inflate($k8s->object_to_json($to));
    is($re->spec->clientAuth->clientAuthType, 'RequireAndVerifyClientCert',
        'JSON round-trip preserves nested clientAuthType');
};

subtest 'full depth round-trip: TLSStore' => sub {
    my $k8s = IO::K8s->new(with => ['IO::K8s::Traefik']);
    my $tst = $k8s->new_object('TLSStore',
        metadata => { name => 'default', namespace => 'default' },
        spec => {
            defaultCertificate   => { secretName => 'default-cert' },
            certificates         => [{ secretName => 'extra-cert' }],
            defaultGeneratedCert => {
                resolver => 'myresolver',
                domain   => { main => 'example.com', sans => ['*.example.com'] },
            },
        },
    );

    isa_ok($tst->spec->defaultCertificate, 'IO::K8s::Traefik::V1alpha1::Certificate');
    isa_ok($tst->spec->certificates->[0], 'IO::K8s::Traefik::V1alpha1::Certificate');
    isa_ok($tst->spec->defaultGeneratedCert, 'IO::K8s::Traefik::V1alpha1::GeneratedCert');
    isa_ok($tst->spec->defaultGeneratedCert->domain, 'IO::K8s::Traefik::V1alpha1::Domain');
    is($tst->spec->defaultGeneratedCert->domain->main, 'example.com', 'nested defaultGeneratedCert.domain.main');

    my $spec_json = $tst->TO_JSON->{spec};
    is($spec_json->{defaultCertificate}{secretName}, 'default-cert', 'TO_JSON defaultCertificate.secretName');
    is($spec_json->{certificates}[0]{secretName}, 'extra-cert', 'TO_JSON certificates[0].secretName');
    is_deeply($spec_json->{defaultGeneratedCert}{domain}{sans}, ['*.example.com'],
        'TO_JSON defaultGeneratedCert.domain.sans');

    my $re = $k8s->inflate($k8s->object_to_json($tst));
    is($re->spec->certificates->[0]->secretName, 'extra-cert', 'JSON round-trip preserves nested certificate');
};

subtest 'full depth round-trip: TraefikService' => sub {
    my $k8s = IO::K8s->new(with => ['IO::K8s::Traefik']);

    my $weighted = $k8s->new_object('TraefikService',
        metadata => { name => 'my-ts-weighted', namespace => 'default' },
        spec => {
            weighted => {
                services => [
                    { name => 'svc-a', weight => 3, port => 80 },
                    { name => 'svc-b', weight => 1, port => 80 },
                ],
                sticky => { cookie => { name => 'my-cookie' } },
            },
        },
    );
    isa_ok($weighted->spec->weighted, 'IO::K8s::Traefik::V1alpha1::WeightedRoundRobin');
    isa_ok($weighted->spec->weighted->services->[0], 'IO::K8s::Traefik::V1alpha1::Service');
    isa_ok($weighted->spec->weighted->sticky, 'IO::K8s::Traefik::V1alpha1::Sticky');
    isa_ok($weighted->spec->weighted->sticky->cookie, 'IO::K8s::Traefik::V1alpha1::Cookie');
    is($weighted->spec->weighted->sticky->cookie->name, 'my-cookie', 'nested weighted.sticky.cookie.name');
    is($weighted->TO_JSON->{spec}{weighted}{services}[1]{weight}, 1,
        'TO_JSON weighted.services[1].weight');

    my $mirroring = $k8s->new_object('TraefikService',
        metadata => { name => 'my-ts-mirroring', namespace => 'default' },
        spec => {
            mirroring => {
                name => 'main-svc', port => 80,
                mirrors => [{ name => 'mirror-svc', percent => 10 }],
            },
        },
    );
    isa_ok($mirroring->spec->mirroring, 'IO::K8s::Traefik::V1alpha1::Mirroring');
    isa_ok($mirroring->spec->mirroring->mirrors->[0], 'IO::K8s::Traefik::V1alpha1::MirrorService');
    is($mirroring->spec->mirroring->mirrors->[0]->percent, 10, 'nested mirroring.mirrors[0].percent');

    my $failover = $k8s->new_object('TraefikService',
        metadata => { name => 'my-ts-failover', namespace => 'default' },
        spec => {
            failover => {
                service  => { name => 'primary-svc' },
                fallback => { name => 'backup-svc' },
                errors   => { status => ['500-599'] },
            },
        },
    );
    isa_ok($failover->spec->failover, 'IO::K8s::Traefik::V1alpha1::Failover');
    isa_ok($failover->spec->failover->service, 'IO::K8s::Traefik::V1alpha1::LoadBalancerSpec');
    isa_ok($failover->spec->failover->fallback, 'IO::K8s::Traefik::V1alpha1::LoadBalancerSpec');
    isa_ok($failover->spec->failover->errors, 'IO::K8s::Traefik::V1alpha1::FailoverError');
    is($failover->spec->failover->fallback->name, 'backup-svc', 'nested failover.fallback.name');

    my $hrw = $k8s->new_object('TraefikService',
        metadata => { name => 'my-ts-hrw', namespace => 'default' },
        spec => { highestRandomWeight => { services => [{ name => 'hrw-svc', weight => 1 }] } },
    );
    isa_ok($hrw->spec->highestRandomWeight, 'IO::K8s::Traefik::V1alpha1::HighestRandomWeight');
    is($hrw->spec->highestRandomWeight->services->[0]->name, 'hrw-svc',
        'nested highestRandomWeight.services[0].name');

    my $re = $k8s->inflate($k8s->object_to_json($failover));
    is($re->spec->failover->service->name, 'primary-svc',
        'JSON round-trip preserves nested failover.service.name');
};

done_testing;
