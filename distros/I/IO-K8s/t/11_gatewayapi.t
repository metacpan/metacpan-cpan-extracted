#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use IO::K8s;
use IO::K8s::GatewayAPI;

# --- All Gateway API CRD classes ---

my %v1_classes = (
    GatewayClass     => { plural => 'gatewayclasses',     namespaced => 0 },
    Gateway          => { plural => 'gateways',           namespaced => 1 },
    HTTPRoute        => { plural => 'httproutes',         namespaced => 1 },
    GRPCRoute        => { plural => 'grpcroutes',         namespaced => 1 },
    BackendTLSPolicy => { plural => 'backendtlspolicies', namespaced => 1 },
    ListenerSet      => { plural => 'listenersets',       namespaced => 1 },
    TLSRoute         => { plural => 'tlsroutes',          namespaced => 1 },
    TCPRoute         => { plural => 'tcproutes',          namespaced => 1 },
    UDPRoute         => { plural => 'udproutes',          namespaced => 1 },
);

my %v1beta1_classes = (
    ReferenceGrant => { plural => 'referencegrants', namespaced => 1 },
);

# ReferenceGrant also exists as a gateway.networking.k8s.io/v1 class (added in
# Gateway API v1.5.0), but v1beta1 remains the storage version and keeps the
# short name in the resource_map, so it's tested separately below rather than
# folded into %v1_classes.

# --- Load all 11 classes ---

subtest 'load all Gateway API classes' => sub {
    for my $kind (sort keys %v1_classes) {
        my $class = "IO::K8s::GatewayAPI::V1::$kind";
        use_ok($class) or BAIL_OUT("Cannot load $class");
    }
    for my $kind (sort keys %v1beta1_classes) {
        my $class = "IO::K8s::GatewayAPI::V1beta1::$kind";
        use_ok($class) or BAIL_OUT("Cannot load $class");
    }
    use_ok('IO::K8s::GatewayAPI::V1::ReferenceGrant')
        or BAIL_OUT('Cannot load IO::K8s::GatewayAPI::V1::ReferenceGrant');
};

# --- Verify api_version, kind, resource_plural, namespaced ---

subtest 'V1 class metadata' => sub {
    for my $kind (sort keys %v1_classes) {
        my $class = "IO::K8s::GatewayAPI::V1::$kind";
        my $info = $v1_classes{$kind};

        is($class->api_version, 'gateway.networking.k8s.io/v1', "$kind api_version");
        is($class->kind, $kind, "$kind kind");
        is($class->resource_plural, $info->{plural}, "$kind resource_plural");
        if ($info->{namespaced}) {
            ok($class->does('IO::K8s::Role::Namespaced'), "$kind is namespaced");
        } else {
            ok(!$class->does('IO::K8s::Role::Namespaced'), "$kind is cluster-scoped");
        }
    }
};

subtest 'V1beta1 class metadata' => sub {
    for my $kind (sort keys %v1beta1_classes) {
        my $class = "IO::K8s::GatewayAPI::V1beta1::$kind";
        my $info = $v1beta1_classes{$kind};

        is($class->api_version, 'gateway.networking.k8s.io/v1beta1', "$kind api_version");
        is($class->kind, $kind, "$kind kind");
        is($class->resource_plural, $info->{plural}, "$kind resource_plural");
        ok($class->does('IO::K8s::Role::Namespaced'), "$kind is namespaced");
    }
};

subtest 'V1 ReferenceGrant class metadata (dual-version kind)' => sub {
    my $class = 'IO::K8s::GatewayAPI::V1::ReferenceGrant';

    is($class->api_version, 'gateway.networking.k8s.io/v1', 'ReferenceGrant v1 api_version');
    is($class->kind, 'ReferenceGrant', 'ReferenceGrant v1 kind');
    is($class->resource_plural, 'referencegrants', 'ReferenceGrant v1 resource_plural');
    ok($class->does('IO::K8s::Role::Namespaced'), 'ReferenceGrant v1 is namespaced');
};

subtest 'Routable role scoping' => sub {
    for my $kind (qw(HTTPRoute GRPCRoute TLSRoute)) {
        my $class = "IO::K8s::GatewayAPI::V1::$kind";
        ok($class->does('IO::K8s::Role::Routable'), "$kind consumes Routable");
    }
    for my $kind (qw(TCPRoute UDPRoute)) {
        my $class = "IO::K8s::GatewayAPI::V1::$kind";
        ok(!$class->does('IO::K8s::Role::Routable'),
            "$kind does not consume Routable (no hostname matching)");
    }
};

# --- IO::K8s::GatewayAPI resource_map completeness ---

subtest 'IO::K8s::GatewayAPI resource_map' => sub {
    my $provider = IO::K8s::GatewayAPI->new;
    ok($provider->does('IO::K8s::Role::ResourceMap'), 'consumes ResourceMap role');

    my $map = $provider->resource_map;
    is(scalar keys %$map, 11, 'resource_map has 11 entries');

    for my $kind (sort keys %v1_classes) {
        ok(exists $map->{$kind}, "$kind in resource_map");
        is($map->{$kind}, "GatewayAPI::V1::$kind", "$kind maps to correct class path");
    }
    for my $kind (sort keys %v1beta1_classes) {
        ok(exists $map->{$kind}, "$kind in resource_map");
        is($map->{$kind}, "GatewayAPI::V1beta1::$kind", "$kind maps to correct class path");
    }

    # ReferenceGrant is dual-version: short name stays on the v1beta1 storage
    # version, v1 is reachable only via its domain-qualified key.
    is($map->{ReferenceGrant}, 'GatewayAPI::V1beta1::ReferenceGrant',
        'short name ReferenceGrant maps to v1beta1 storage version');
    is($map->{'gateway.networking.k8s.io/v1/ReferenceGrant'}, 'GatewayAPI::V1::ReferenceGrant',
        'domain-qualified key maps to v1 ReferenceGrant');
};

# --- new(with => ['IO::K8s::GatewayAPI']) integration ---

subtest 'with constructor parameter' => sub {
    my $k8s = IO::K8s->new(with => ['IO::K8s::GatewayAPI']);

    # All 9 unambiguous V1 Gateway API kinds should be resolvable by short name
    for my $kind (sort keys %v1_classes) {
        is($k8s->expand_class($kind), "IO::K8s::GatewayAPI::V1::$kind",
            "expand_class('$kind') resolves");
    }
    for my $kind (sort keys %v1beta1_classes) {
        is($k8s->expand_class($kind), "IO::K8s::GatewayAPI::V1beta1::$kind",
            "expand_class('$kind') resolves");
    }

    # Domain-qualified access
    is($k8s->expand_class('gateway.networking.k8s.io/v1/Gateway'),
        'IO::K8s::GatewayAPI::V1::Gateway',
        'domain-qualified V1 resolves');
    is($k8s->expand_class('gateway.networking.k8s.io/v1beta1/ReferenceGrant'),
        'IO::K8s::GatewayAPI::V1beta1::ReferenceGrant',
        'domain-qualified V1beta1 resolves');
    is($k8s->expand_class('gateway.networking.k8s.io/v1/ReferenceGrant'),
        'IO::K8s::GatewayAPI::V1::ReferenceGrant',
        'domain-qualified V1 ReferenceGrant resolves to the dual-version v1 class');

    # Core resources are unaffected
    is($k8s->expand_class('Pod'), 'IO::K8s::Api::Core::V1::Pod',
        'core Pod still resolves');
    is($k8s->expand_class('Deployment'), 'IO::K8s::Api::Apps::V1::Deployment',
        'core Deployment still resolves');
};

# --- new_object + inflate round-trip ---

subtest 'new_object and inflate round-trip' => sub {
    my $k8s = IO::K8s->new(with => ['IO::K8s::GatewayAPI']);

    # Create a Gateway
    my $gw = $k8s->new_object('Gateway',
        metadata => { name => 'my-gateway', namespace => 'default' },
        spec => {
            gatewayClassName => 'istio',
            listeners => [{ name => 'http', port => 80, protocol => 'HTTP' }],
        },
    );
    isa_ok($gw, 'IO::K8s::GatewayAPI::V1::Gateway');
    is($gw->kind, 'Gateway', 'kind');
    is($gw->api_version, 'gateway.networking.k8s.io/v1', 'api_version');
    isa_ok($gw->metadata, 'IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::ObjectMeta');
    is($gw->metadata->name, 'my-gateway', 'name');
    is($gw->metadata->namespace, 'default', 'namespace');

    # Serialize and re-inflate
    my $json = $k8s->object_to_json($gw);
    like($json, qr/"apiVersion":"gateway\.networking\.k8s\.io\/v1"/, 'JSON has apiVersion');
    like($json, qr/"kind":"Gateway"/, 'JSON has kind');

    my $re = $k8s->inflate($json);
    isa_ok($re, 'IO::K8s::GatewayAPI::V1::Gateway', 're-inflated');
    is($re->metadata->name, 'my-gateway', 'round-trip name preserved');
    is($re->metadata->namespace, 'default', 'round-trip namespace preserved');

    # Create a GatewayClass (cluster-scoped)
    my $gc = $k8s->new_object('GatewayClass',
        metadata => { name => 'istio' },
        spec => { controllerName => 'istio.io/gateway-controller' },
    );
    isa_ok($gc, 'IO::K8s::GatewayAPI::V1::GatewayClass');
    ok(!$gc->does('IO::K8s::Role::Namespaced'), 'GatewayClass is cluster-scoped');

    # Round-trip GatewayClass
    my $gc_re = $k8s->inflate($k8s->object_to_json($gc));
    isa_ok($gc_re, 'IO::K8s::GatewayAPI::V1::GatewayClass');
    is($gc_re->metadata->name, 'istio', 'GatewayClass round-trip');

    # V1beta1 resource
    my $rg = $k8s->new_object('ReferenceGrant',
        metadata => { name => 'allow-routes', namespace => 'default' },
        spec => {
            from => [{ group => 'gateway.networking.k8s.io', kind => 'HTTPRoute', namespace => 'web' }],
            to => [{ group => '', kind => 'Service' }],
        },
    );
    isa_ok($rg, 'IO::K8s::GatewayAPI::V1beta1::ReferenceGrant');
    is($rg->api_version, 'gateway.networking.k8s.io/v1beta1', 'V1beta1 api_version');
    my $rg_re = $k8s->inflate($k8s->object_to_json($rg));
    isa_ok($rg_re, 'IO::K8s::GatewayAPI::V1beta1::ReferenceGrant');
};

# --- New v1.6.1 kinds: new_object + inflate round-trip ---

subtest 'new v1.6.1 kinds round-trip' => sub {
    my $k8s = IO::K8s->new(with => ['IO::K8s::GatewayAPI']);

    my $tls_policy = $k8s->new_object('BackendTLSPolicy',
        metadata => { name => 'backend-tls', namespace => 'default' },
        spec => {
            targetRefs => [{ group => '', kind => 'Service', name => 'backend' }],
            validation => { wellKnownCACertificates => 'System', hostname => 'backend.example.com' },
        },
    );
    isa_ok($tls_policy, 'IO::K8s::GatewayAPI::V1::BackendTLSPolicy');
    is($tls_policy->kind, 'BackendTLSPolicy', 'BackendTLSPolicy kind');
    ok($tls_policy->does('IO::K8s::Role::Namespaced'), 'BackendTLSPolicy is namespaced');

    my $listener_set = $k8s->new_object('ListenerSet',
        metadata => { name => 'extra-listeners', namespace => 'default' },
        spec => {
            parentRef => { name => 'my-gateway' },
            listeners => [{ name => 'https', port => 8443, protocol => 'HTTPS' }],
        },
    );
    isa_ok($listener_set, 'IO::K8s::GatewayAPI::V1::ListenerSet');
    is($listener_set->kind, 'ListenerSet', 'ListenerSet kind');

    my $tls_route = $k8s->new_object('TLSRoute',
        metadata => { name => 'my-tls-route', namespace => 'default' },
        spec => { parentRefs => [{ name => 'my-gateway' }] },
    );
    isa_ok($tls_route, 'IO::K8s::GatewayAPI::V1::TLSRoute');
    $tls_route->add_hostname('tls.example.com');
    $tls_route->add_backend('backend-svc', port => 443);
    is_deeply($tls_route->spec->{hostnames}, ['tls.example.com'], 'TLSRoute add_hostname');
    is($tls_route->spec->{rules}[-1]{backendRefs}[-1]{name}, 'backend-svc', 'TLSRoute add_backend');

    my $tcp_route = $k8s->new_object('TCPRoute',
        metadata => { name => 'my-tcp-route', namespace => 'default' },
        spec => {
            parentRefs => [{ name => 'my-gateway' }],
            rules => [{ backendRefs => [{ name => 'tcp-svc', port => 9000 }] }],
        },
    );
    isa_ok($tcp_route, 'IO::K8s::GatewayAPI::V1::TCPRoute');
    is($tcp_route->kind, 'TCPRoute', 'TCPRoute kind');
    ok(!$tcp_route->can('add_hostname'), 'TCPRoute has no add_hostname (no Routable role)');

    my $udp_route = $k8s->new_object('UDPRoute',
        metadata => { name => 'my-udp-route', namespace => 'default' },
        spec => {
            parentRefs => [{ name => 'my-gateway' }],
            rules => [{ backendRefs => [{ name => 'udp-svc', port => 9001 }] }],
        },
    );
    isa_ok($udp_route, 'IO::K8s::GatewayAPI::V1::UDPRoute');
    is($udp_route->kind, 'UDPRoute', 'UDPRoute kind');

    # Round-trip all five through JSON
    for my $obj ($tls_policy, $listener_set, $tls_route, $tcp_route, $udp_route) {
        my $re = $k8s->inflate($k8s->object_to_json($obj));
        isa_ok($re, ref($obj), ref($obj) . ' round-trip');
        is($re->metadata->name, $obj->metadata->name, ref($obj) . ' round-trip name preserved');
    }

    # Dual-version ReferenceGrant: construct the v1 class explicitly via '+'
    my $rg_v1 = $k8s->new_object('+IO::K8s::GatewayAPI::V1::ReferenceGrant',
        metadata => { name => 'allow-routes-v1', namespace => 'default' },
        spec => {
            from => [{ group => 'gateway.networking.k8s.io', kind => 'HTTPRoute', namespace => 'web' }],
            to => [{ group => '', kind => 'Service' }],
        },
    );
    isa_ok($rg_v1, 'IO::K8s::GatewayAPI::V1::ReferenceGrant');
    is($rg_v1->api_version, 'gateway.networking.k8s.io/v1', 'v1 ReferenceGrant api_version');
    my $rg_v1_re = $k8s->inflate($k8s->object_to_json($rg_v1));
    isa_ok($rg_v1_re, 'IO::K8s::GatewayAPI::V1::ReferenceGrant', 'v1 ReferenceGrant round-trip');
};

# --- to_yaml output ---

subtest 'to_yaml output' => sub {
    my $k8s = IO::K8s->new(with => ['IO::K8s::GatewayAPI']);

    my $gw = $k8s->new_object('Gateway',
        metadata => { name => 'test-gw', namespace => 'default' },
        spec => { gatewayClassName => 'istio' },
    );
    my $yaml = $gw->to_yaml;
    like($yaml, qr/apiVersion: gateway\.networking\.k8s\.io\/v1/, 'YAML apiVersion');
    like($yaml, qr/kind: Gateway/, 'YAML kind');
    like($yaml, qr/name: test-gw/, 'YAML name');
    like($yaml, qr/namespace: default/, 'YAML namespace');
};

# --- Domain-qualified expand_class ---

subtest 'domain-qualified expand_class' => sub {
    my $k8s = IO::K8s->new(with => ['IO::K8s::GatewayAPI']);

    # V1 kinds via domain-qualified
    for my $kind (sort keys %v1_classes) {
        is($k8s->expand_class("gateway.networking.k8s.io/v1/$kind"),
            "IO::K8s::GatewayAPI::V1::$kind",
            "gateway.networking.k8s.io/v1/$kind resolves");
    }

    # V1beta1 kinds via domain-qualified
    for my $kind (sort keys %v1beta1_classes) {
        is($k8s->expand_class("gateway.networking.k8s.io/v1beta1/$kind"),
            "IO::K8s::GatewayAPI::V1beta1::$kind",
            "gateway.networking.k8s.io/v1beta1/$kind resolves");
    }

    # api_version parameter style
    is($k8s->expand_class('Gateway', 'gateway.networking.k8s.io/v1'),
        'IO::K8s::GatewayAPI::V1::Gateway',
        'api_version parameter disambiguation');
};

# --- pk8s DSL with Gateway API kinds ---

subtest 'pk8s DSL with Gateway API kinds' => sub {
    require File::Temp;
    my $k8s = IO::K8s->new(with => ['IO::K8s::GatewayAPI']);

    my ($fh, $filename) = File::Temp::tempfile(SUFFIX => '.pk8s', UNLINK => 1);
    print $fh q{
        GatewayClass {
            name => 'istio',
            spec => { controllerName => 'istio.io/gateway-controller' },
        };

        Gateway {
            name => 'my-gateway',
            namespace => 'default',
            spec => { gatewayClassName => 'istio' },
        };

        HTTPRoute {
            name => 'my-route',
            namespace => 'default',
            spec => { parentRefs => [{ name => 'my-gateway' }] },
        };
    };
    close $fh;

    my $objs = $k8s->load($filename);
    is(scalar(@$objs), 3, 'pk8s loaded 3 Gateway API objects');

    my ($gc, $gw, $hr) = @$objs;

    isa_ok($gc, 'IO::K8s::GatewayAPI::V1::GatewayClass');
    is($gc->kind, 'GatewayClass', 'pk8s GatewayClass kind');
    is($gc->metadata->name, 'istio', 'pk8s GatewayClass name');

    isa_ok($gw, 'IO::K8s::GatewayAPI::V1::Gateway');
    is($gw->kind, 'Gateway', 'pk8s Gateway kind');
    is($gw->metadata->namespace, 'default', 'pk8s Gateway namespace');

    isa_ok($hr, 'IO::K8s::GatewayAPI::V1::HTTPRoute');
    is($hr->kind, 'HTTPRoute', 'pk8s HTTPRoute kind');
    is($hr->api_version, 'gateway.networking.k8s.io/v1', 'pk8s HTTPRoute api_version');
};

# --- No collision with core K8s kinds ---

subtest 'no collision with core K8s kinds' => sub {
    my $k8s = IO::K8s->new(with => ['IO::K8s::GatewayAPI']);

    # Ingress is a core K8s kind, not a Gateway API kind
    is($k8s->expand_class('Ingress'),
        'IO::K8s::Api::Networking::V1::Ingress',
        'core Ingress unaffected');
    is($k8s->expand_class('Service'),
        'IO::K8s::Api::Core::V1::Service',
        'core Service unaffected');
};

done_testing;
