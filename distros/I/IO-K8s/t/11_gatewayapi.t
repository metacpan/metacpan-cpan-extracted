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

# Gateway, GatewayClass and HTTPRoute are ALSO served at v1beta1 upstream
# (served: true, storage: false at v1.6.1) -- D7: every served version gets a
# class -- but v1 is their storage version, so (unlike ReferenceGrant above)
# their short name resolves to V1, not V1beta1; the v1beta1 track is
# reachable only via its domain-qualified resource_map key. Kept apart from
# %v1beta1_classes because the short-name-resolution assertions below differ.
my %v1beta1_dual_classes = (
    Gateway      => { plural => 'gateways',       namespaced => 1 },
    GatewayClass => { plural => 'gatewayclasses', namespaced => 0 },
    HTTPRoute    => { plural => 'httproutes',     namespaced => 1 },
);

# --- Load all 14 classes ---

subtest 'load all Gateway API classes' => sub {
    for my $kind (sort keys %v1_classes) {
        my $class = "IO::K8s::GatewayAPI::V1::$kind";
        use_ok($class) or BAIL_OUT("Cannot load $class");
    }
    for my $kind (sort keys %v1beta1_classes) {
        my $class = "IO::K8s::GatewayAPI::V1beta1::$kind";
        use_ok($class) or BAIL_OUT("Cannot load $class");
    }
    for my $kind (sort keys %v1beta1_dual_classes) {
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

subtest 'V1beta1 dual-version class metadata (D7: served, but v1 is storage)' => sub {
    for my $kind (sort keys %v1beta1_dual_classes) {
        my $class = "IO::K8s::GatewayAPI::V1beta1::$kind";
        my $info = $v1beta1_dual_classes{$kind};

        is($class->api_version, 'gateway.networking.k8s.io/v1beta1', "$kind v1beta1 api_version");
        is($class->kind, $kind, "$kind v1beta1 kind");
        is($class->resource_plural, $info->{plural}, "$kind v1beta1 resource_plural");
        if ($info->{namespaced}) {
            ok($class->does('IO::K8s::Role::Namespaced'), "$kind v1beta1 is namespaced");
        } else {
            ok(!$class->does('IO::K8s::Role::Namespaced'), "$kind v1beta1 is cluster-scoped");
        }
    }
    ok(IO::K8s::GatewayAPI::V1beta1::HTTPRoute->does('IO::K8s::Role::Routable'),
        'V1beta1 HTTPRoute also consumes Routable (same overlay applies to both tracks)');
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
    is(scalar keys %$map, 14, 'resource_map has 14 entries');

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

    # Gateway/GatewayClass/HTTPRoute are dual-version the other way round:
    # short name stays on v1 (storage), v1beta1 is reachable only via its
    # domain-qualified key (D7).
    for my $kind (sort keys %v1beta1_dual_classes) {
        is($map->{$kind}, "GatewayAPI::V1::$kind",
            "short name $kind still maps to the v1 storage version");
        is($map->{"gateway.networking.k8s.io/v1beta1/$kind"}, "GatewayAPI::V1beta1::$kind",
            "domain-qualified key maps to v1beta1 $kind");
    }
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

    # Gateway/GatewayClass/HTTPRoute: the short name still resolves to v1
    # (their storage version), NOT v1beta1, even though v1beta1 is served too.
    for my $kind (sort keys %v1beta1_dual_classes) {
        is($k8s->expand_class($kind), "IO::K8s::GatewayAPI::V1::$kind",
            "expand_class('$kind') resolves to the v1 storage version, not v1beta1");
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
    for my $kind (sort keys %v1beta1_dual_classes) {
        is($k8s->expand_class("gateway.networking.k8s.io/v1beta1/$kind"),
            "IO::K8s::GatewayAPI::V1beta1::$kind",
            "domain-qualified V1beta1 $kind resolves to the dual-version v1beta1 class");
    }

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

    # V1beta1 dual-version kinds (D7) via domain-qualified
    for my $kind (sort keys %v1beta1_dual_classes) {
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

# --- Full depth round-trip (k95/D5): each Kind's manifest, written from the
# upstream kubernetes-sigs/gateway-api v1.6.1 Go sources (apis/v1/*.go),
# inflates into typed nested objects several levels deep and TO_JSON
# reproduces it exactly. Built via new_object (coercing; NOT
# ->new(spec => {hashref}), which does not coerce -- k100). ---

subtest 'full depth round-trip: BackendTLSPolicy' => sub {
    my $k8s = IO::K8s->new(with => ['IO::K8s::GatewayAPI']);
    my $btp = $k8s->new_object('BackendTLSPolicy',
        metadata => { name => 'backend-tls', namespace => 'default' },
        spec => {
            targetRefs => [{ group => '', kind => 'Service', name => 'backend', sectionName => 'https' }],
            validation => {
                caCertificateRefs => [{ group => '', kind => 'ConfigMap', name => 'ca-bundle' }],
                hostname          => 'backend.example.com',
                subjectAltNames   => [{ type => 'Hostname', hostname => 'backend.example.com' }],
            },
        },
    );

    isa_ok($btp->spec, 'IO::K8s::GatewayAPI::V1::BackendTLSPolicySpec');
    isa_ok($btp->spec->targetRefs->[0], 'IO::K8s::GatewayAPI::V1::LocalPolicyTargetReferenceWithSectionName');
    isa_ok($btp->spec->validation, 'IO::K8s::GatewayAPI::V1::BackendTLSPolicyValidation');
    isa_ok($btp->spec->validation->caCertificateRefs->[0], 'IO::K8s::GatewayAPI::V1::LocalObjectReference');
    isa_ok($btp->spec->validation->subjectAltNames->[0], 'IO::K8s::GatewayAPI::V1::SubjectAltName');

    my $spec_json = $btp->TO_JSON->{spec};
    is($spec_json->{targetRefs}[0]{sectionName}, 'https', 'TO_JSON targetRefs[0].sectionName');
    is($spec_json->{validation}{subjectAltNames}[0]{hostname}, 'backend.example.com',
        'TO_JSON validation.subjectAltNames[0].hostname');

    my $re = $k8s->inflate($k8s->object_to_json($btp));
    isa_ok($re, 'IO::K8s::GatewayAPI::V1::BackendTLSPolicy');
    is($re->spec->validation->hostname, 'backend.example.com', 'JSON round-trip preserves validation.hostname');
};

subtest 'full depth round-trip: GatewayClass' => sub {
    my $k8s = IO::K8s->new(with => ['IO::K8s::GatewayAPI']);
    my $gc = $k8s->new_object('GatewayClass',
        metadata => { name => 'istio' },
        spec => {
            controllerName => 'istio.io/gateway-controller',
            parametersRef  => { group => '', kind => 'ConfigMap', name => 'istio-params', namespace => 'istio-system' },
        },
        status => {
            conditions        => [{ type => 'Accepted', status => 'True', reason => 'Accepted', message => 'Accepted', lastTransitionTime => '2026-09-03T00:00:00Z' }],
            supportedFeatures => [{ name => 'HTTPRoute' }, { name => 'Gateway' }],
        },
    );

    isa_ok($gc->spec, 'IO::K8s::GatewayAPI::V1::GatewayClassSpec');
    isa_ok($gc->spec->parametersRef, 'IO::K8s::GatewayAPI::V1::ParametersReference');
    isa_ok($gc->status, 'IO::K8s::GatewayAPI::V1::GatewayClassStatus');
    isa_ok($gc->status->conditions->[0], 'IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::Condition',
        'reused core Condition for status.conditions (reuse_core, D5)');
    isa_ok($gc->status->supportedFeatures->[0], 'IO::K8s::GatewayAPI::V1::SupportedFeature');

    my $json = $gc->TO_JSON;
    is($json->{spec}{parametersRef}{namespace}, 'istio-system', 'TO_JSON spec.parametersRef.namespace');
    is($json->{status}{supportedFeatures}[1]{name}, 'Gateway', 'TO_JSON status.supportedFeatures[1].name');

    my $re = $k8s->inflate($k8s->object_to_json($gc));
    isa_ok($re, 'IO::K8s::GatewayAPI::V1::GatewayClass');
    is($re->status->conditions->[0]->status, 'True', 'JSON round-trip preserves status.conditions[0].status');
};

subtest 'full depth round-trip: Gateway' => sub {
    my $k8s = IO::K8s->new(with => ['IO::K8s::GatewayAPI']);
    my $gw = $k8s->new_object('Gateway',
        metadata => { name => 'my-gateway', namespace => 'default' },
        spec => {
            gatewayClassName => 'istio',
            listeners        => [{
                name          => 'https',
                port          => 443,
                protocol      => 'HTTPS',
                allowedRoutes => {
                    namespaces => { from => 'Selector', selector => { matchLabels => { shared => 'true' } } },
                    kinds      => [{ kind => 'HTTPRoute' }],
                },
                tls => { certificateRefs => [{ group => '', kind => 'Secret', name => 'gw-tls' }] },
            }],
            addresses => [{ type => 'IPAddress', value => '10.0.0.1' }],
            tls       => { frontend => { default => { validation => { caCertificateRefs => [{ group => '', kind => 'ConfigMap', name => 'ca' }] } } } },
        },
        status => {
            listeners => [{ name => 'https', attachedRoutes => 2, conditions => [{ type => 'Programmed', status => 'True', reason => 'Programmed', message => 'Programmed', lastTransitionTime => '2026-09-03T00:00:00Z' }], supportedKinds => [{ kind => 'HTTPRoute' }] }],
        },
    );

    isa_ok($gw->spec, 'IO::K8s::GatewayAPI::V1::GatewaySpec');
    my $listener = $gw->spec->listeners->[0];
    isa_ok($listener, 'IO::K8s::GatewayAPI::V1::Listener');
    isa_ok($listener->allowedRoutes, 'IO::K8s::GatewayAPI::V1::AllowedRoutes');
    isa_ok($listener->allowedRoutes->namespaces, 'IO::K8s::GatewayAPI::V1::RouteNamespaces');
    isa_ok($listener->allowedRoutes->namespaces->selector, 'IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::LabelSelector',
        'reused core LabelSelector for allowedRoutes.namespaces.selector (reuse_core, D5)');
    isa_ok($listener->allowedRoutes->kinds->[0], 'IO::K8s::GatewayAPI::V1::RouteGroupKind');
    isa_ok($listener->tls, 'IO::K8s::GatewayAPI::V1::ListenerTLSConfig');
    isa_ok($listener->tls->certificateRefs->[0], 'IO::K8s::GatewayAPI::V1::SecretObjectReference');
    isa_ok($gw->spec->addresses->[0], 'IO::K8s::GatewayAPI::V1::GatewaySpecAddress');
    isa_ok($gw->spec->tls, 'IO::K8s::GatewayAPI::V1::GatewayTLSConfig');
    isa_ok($gw->spec->tls->frontend, 'IO::K8s::GatewayAPI::V1::FrontendTLSConfig');
    isa_ok($gw->spec->tls->frontend->default, 'IO::K8s::GatewayAPI::V1::TLSConfig');
    isa_ok($gw->spec->tls->frontend->default->validation, 'IO::K8s::GatewayAPI::V1::FrontendTLSValidation');
    isa_ok($gw->status->listeners->[0], 'IO::K8s::GatewayAPI::V1::ListenerStatus');
    isa_ok($gw->status->listeners->[0]->conditions->[0], 'IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::Condition');

    my $spec_json = $gw->TO_JSON->{spec};
    is($spec_json->{listeners}[0]{allowedRoutes}{namespaces}{selector}{matchLabels}{shared}, 'true',
        'TO_JSON listeners[0].allowedRoutes.namespaces.selector.matchLabels.shared');
    is($spec_json->{tls}{frontend}{default}{validation}{caCertificateRefs}[0]{name}, 'ca',
        'TO_JSON tls.frontend.default.validation.caCertificateRefs[0].name');

    my $re = $k8s->inflate($k8s->object_to_json($gw));
    isa_ok($re, 'IO::K8s::GatewayAPI::V1::Gateway');
    is($re->spec->listeners->[0]->tls->certificateRefs->[0]->name, 'gw-tls',
        'JSON round-trip preserves listeners[0].tls.certificateRefs[0].name');
};

subtest 'full depth round-trip: GRPCRoute' => sub {
    my $k8s = IO::K8s->new(with => ['IO::K8s::GatewayAPI']);
    my $gr = $k8s->new_object('GRPCRoute',
        metadata => { name => 'my-grpc-route', namespace => 'default' },
        spec => {
            parentRefs => [{ name => 'my-gateway' }],
            rules      => [{
                matches => [{
                    method  => { service => 'helloworld.Greeter', method => 'SayHello', type => 'Exact' },
                    headers => [{ name => 'x-trace', value => 'on' }],
                }],
                filters => [
                    { type => 'RequestHeaderModifier', requestHeaderModifier => { add => [{ name => 'x-grpc', value => '1' }] } },
                    { type => 'RequestMirror', requestMirror => { backendRef => { name => 'mirror-svc' }, fraction => { numerator => 10, denominator => 100 } } },
                ],
                backendRefs => [{ name => 'greeter-svc', port => 50051, weight => 1 }],
            }],
        },
        status => {
            parents => [{ parentRef => { name => 'my-gateway' }, controllerName => 'istio.io/gateway-controller', conditions => [{ type => 'Accepted', status => 'True', reason => 'Accepted', message => 'Accepted', lastTransitionTime => '2026-09-03T00:00:00Z' }] }],
        },
    );

    isa_ok($gr->spec, 'IO::K8s::GatewayAPI::V1::GRPCRouteSpec');
    isa_ok($gr->spec->parentRefs->[0], 'IO::K8s::GatewayAPI::V1::ParentReference');
    my $rule = $gr->spec->rules->[0];
    isa_ok($rule, 'IO::K8s::GatewayAPI::V1::GRPCRouteRule');
    isa_ok($rule->matches->[0], 'IO::K8s::GatewayAPI::V1::GRPCRouteMatch');
    isa_ok($rule->matches->[0]->method, 'IO::K8s::GatewayAPI::V1::GRPCMethodMatch');
    isa_ok($rule->matches->[0]->headers->[0], 'IO::K8s::GatewayAPI::V1::GRPCHeaderMatch');
    isa_ok($rule->filters->[0], 'IO::K8s::GatewayAPI::V1::GRPCRouteFilter');
    isa_ok($rule->filters->[0]->requestHeaderModifier, 'IO::K8s::GatewayAPI::V1::HTTPHeaderFilter',
        'GRPCRouteFilter reuses the same HTTPHeaderFilter class as HTTPRoute (D6 shared type)');
    isa_ok($rule->filters->[1]->requestMirror, 'IO::K8s::GatewayAPI::V1::HTTPRequestMirrorFilter');
    isa_ok($rule->filters->[1]->requestMirror->backendRef, 'IO::K8s::GatewayAPI::V1::BackendObjectReference');
    isa_ok($rule->backendRefs->[0], 'IO::K8s::GatewayAPI::V1::GRPCBackendRef');
    isa_ok($gr->status->parents->[0], 'IO::K8s::GatewayAPI::V1::RouteParentStatus');
    isa_ok($gr->status->parents->[0]->parentRef, 'IO::K8s::GatewayAPI::V1::ParentReference');

    my $spec_json = $gr->TO_JSON->{spec};
    is($spec_json->{rules}[0]{matches}[0]{method}{method}, 'SayHello', 'TO_JSON rules[0].matches[0].method.method');
    is($spec_json->{rules}[0]{filters}[1]{requestMirror}{fraction}{numerator}, 10,
        'TO_JSON rules[0].filters[1].requestMirror.fraction.numerator');

    my $re = $k8s->inflate($k8s->object_to_json($gr));
    isa_ok($re, 'IO::K8s::GatewayAPI::V1::GRPCRoute');
    is($re->spec->rules->[0]->backendRefs->[0]->port, 50051, 'JSON round-trip preserves rules[0].backendRefs[0].port');
};

subtest 'full depth round-trip: HTTPRoute (deep rules[].matches/filters/backendRefs)' => sub {
    my $k8s = IO::K8s->new(with => ['IO::K8s::GatewayAPI']);
    my $hr = $k8s->new_object('HTTPRoute',
        metadata => { name => 'my-route', namespace => 'default' },
        spec => {
            hostnames  => ['example.com'],
            parentRefs => [{ name => 'my-gateway', sectionName => 'https' }],
            rules      => [{
                matches => [{
                    path        => { type => 'PathPrefix', value => '/api' },
                    method      => 'POST',
                    headers     => [{ name => 'x-env', value => 'prod' }],
                    queryParams => [{ name => 'debug', value => 'false' }],
                }],
                filters => [
                    { type => 'RequestHeaderModifier', requestHeaderModifier => { add => [{ name => 'x-forwarded', value => 'gw' }], remove => ['x-drop'] } },
                    { type => 'RequestRedirect', requestRedirect => { scheme => 'https', statusCode => 301, path => { type => 'ReplacePrefixMatch', replacePrefixMatch => '/v2' } } },
                    { type => 'RequestMirror', requestMirror => { backendRef => { name => 'mirror-svc', port => 80 }, fraction => { numerator => 5, denominator => 100 } } },
                    { type => 'URLRewrite', urlRewrite => { hostname => 'internal.example.com' } },
                    { type => 'CORS', cors => { allowOrigins => ['https://example.com'], allowMethods => ['GET', 'POST'] } },
                ],
                backendRefs => [{
                    name    => 'api-svc',
                    port    => 8080,
                    weight  => 1,
                    filters => [{ type => 'ResponseHeaderModifier', responseHeaderModifier => { set => [{ name => 'x-served-by', value => 'api-svc' }] } }],
                }],
                timeouts => { request => '30s', backendRequest => '10s' },
            }],
        },
        status => {
            parents => [{ parentRef => { name => 'my-gateway', sectionName => 'https' }, controllerName => 'istio.io/gateway-controller', conditions => [{ type => 'Accepted', status => 'True', reason => 'Accepted', message => 'Accepted', lastTransitionTime => '2026-09-03T00:00:00Z' }] }],
        },
    );

    isa_ok($hr->spec, 'IO::K8s::GatewayAPI::V1::HTTPRouteSpec');
    my $parent_ref_class = ref $hr->spec->parentRefs->[0];
    is($parent_ref_class, 'IO::K8s::GatewayAPI::V1::ParentReference', 'spec.parentRefs[0] is ParentReference');

    my $rule = $hr->spec->rules->[0];
    isa_ok($rule, 'IO::K8s::GatewayAPI::V1::HTTPRouteRule');
    my $match = $rule->matches->[0];
    isa_ok($match, 'IO::K8s::GatewayAPI::V1::HTTPRouteMatch');
    isa_ok($match->path, 'IO::K8s::GatewayAPI::V1::HTTPPathMatch');
    isa_ok($match->headers->[0], 'IO::K8s::GatewayAPI::V1::HTTPHeaderMatch');
    isa_ok($match->queryParams->[0], 'IO::K8s::GatewayAPI::V1::HTTPQueryParamMatch');

    my ($f_hdr, $f_redir, $f_mirror, $f_rewrite, $f_cors) = @{ $rule->filters };
    isa_ok($f_hdr, 'IO::K8s::GatewayAPI::V1::HTTPRouteFilter');
    isa_ok($f_hdr->requestHeaderModifier, 'IO::K8s::GatewayAPI::V1::HTTPHeaderFilter');
    isa_ok($f_hdr->requestHeaderModifier->add->[0], 'IO::K8s::Api::Core::V1::HTTPHeader');
    isa_ok($f_redir->requestRedirect, 'IO::K8s::GatewayAPI::V1::HTTPRequestRedirectFilter');
    isa_ok($f_redir->requestRedirect->path, 'IO::K8s::GatewayAPI::V1::HTTPPathModifier');
    isa_ok($f_mirror->requestMirror, 'IO::K8s::GatewayAPI::V1::HTTPRequestMirrorFilter');
    isa_ok($f_mirror->requestMirror->backendRef, 'IO::K8s::GatewayAPI::V1::BackendObjectReference');
    isa_ok($f_mirror->requestMirror->fraction, 'IO::K8s::GatewayAPI::V1::Fraction');
    isa_ok($f_rewrite->urlRewrite, 'IO::K8s::GatewayAPI::V1::HTTPURLRewriteFilter');
    isa_ok($f_cors->cors, 'IO::K8s::GatewayAPI::V1::HTTPCORSFilter');

    my $backend = $rule->backendRefs->[0];
    isa_ok($backend, 'IO::K8s::GatewayAPI::V1::HTTPBackendRef');
    isa_ok($backend->filters->[0], 'IO::K8s::GatewayAPI::V1::HTTPRouteFilter');
    isa_ok($backend->filters->[0]->responseHeaderModifier, 'IO::K8s::GatewayAPI::V1::HTTPHeaderFilter');
    isa_ok($rule->timeouts, 'IO::K8s::GatewayAPI::V1::HTTPRouteTimeouts');

    # D6: the SAME ParentReference class is used at spec.parentRefs[] and at
    # status.parents[].parentRef -- one shared class, not two look-alikes.
    my $status_parent_ref_class = ref $hr->status->parents->[0]->parentRef;
    is($status_parent_ref_class, $parent_ref_class,
        'status.parents[0].parentRef is the same class as spec.parentRefs[0] (shared ParentReference, D6)');
    isa_ok($hr->status->parents->[0], 'IO::K8s::GatewayAPI::V1::RouteParentStatus');

    my $spec_json = $hr->TO_JSON->{spec};
    is($spec_json->{rules}[0]{matches}[0]{path}{value}, '/api', 'TO_JSON rules[0].matches[0].path.value');
    is($spec_json->{rules}[0]{filters}[1]{requestRedirect}{path}{replacePrefixMatch}, '/v2',
        'TO_JSON rules[0].filters[1].requestRedirect.path.replacePrefixMatch');
    is($spec_json->{rules}[0]{filters}[2]{requestMirror}{fraction}{numerator}, 5,
        'TO_JSON rules[0].filters[2].requestMirror.fraction.numerator');
    is($spec_json->{rules}[0]{backendRefs}[0]{filters}[0]{responseHeaderModifier}{set}[0]{name}, 'x-served-by',
        'TO_JSON rules[0].backendRefs[0].filters[0].responseHeaderModifier.set[0].name');
    is($spec_json->{rules}[0]{timeouts}{request}, '30s', 'TO_JSON rules[0].timeouts.request');

    my $re = $k8s->inflate($k8s->object_to_json($hr));
    isa_ok($re, 'IO::K8s::GatewayAPI::V1::HTTPRoute');
    is($re->spec->rules->[0]->matches->[0]->headers->[0]->value, 'prod',
        'JSON round-trip preserves rules[0].matches[0].headers[0].value');
    is($re->spec->rules->[0]->backendRefs->[0]->name, 'api-svc',
        'JSON round-trip preserves rules[0].backendRefs[0].name');
};

subtest 'full depth round-trip: HTTPRoute at v1beta1 (D7 dual-version track)' => sub {
    my $k8s = IO::K8s->new(with => ['IO::K8s::GatewayAPI']);
    my $hr = $k8s->new_object('+IO::K8s::GatewayAPI::V1beta1::HTTPRoute',
        metadata => { name => 'my-route-beta', namespace => 'default' },
        spec => {
            parentRefs => [{ name => 'my-gateway' }],
            rules      => [{
                matches     => [{ path => { type => 'Exact', value => '/health' } }],
                backendRefs => [{ name => 'health-svc', port => 8080 }],
            }],
        },
    );

    isa_ok($hr, 'IO::K8s::GatewayAPI::V1beta1::HTTPRoute');
    is($hr->api_version, 'gateway.networking.k8s.io/v1beta1', 'v1beta1 api_version');
    isa_ok($hr->spec, 'IO::K8s::GatewayAPI::V1beta1::HTTPRouteSpec');
    isa_ok($hr->spec->parentRefs->[0], 'IO::K8s::GatewayAPI::V1beta1::ParentReference');
    isa_ok($hr->spec->rules->[0], 'IO::K8s::GatewayAPI::V1beta1::HTTPRouteRule');
    isa_ok($hr->spec->rules->[0]->matches->[0], 'IO::K8s::GatewayAPI::V1beta1::HTTPRouteMatch');
    isa_ok($hr->spec->rules->[0]->matches->[0]->path, 'IO::K8s::GatewayAPI::V1beta1::HTTPPathMatch');
    isa_ok($hr->spec->rules->[0]->backendRefs->[0], 'IO::K8s::GatewayAPI::V1beta1::HTTPBackendRef');

    my $spec_json = $hr->TO_JSON->{spec};
    is($spec_json->{rules}[0]{matches}[0]{path}{type}, 'Exact', 'TO_JSON rules[0].matches[0].path.type');
    is($spec_json->{rules}[0]{backendRefs}[0]{port}, 8080, 'TO_JSON rules[0].backendRefs[0].port');

    my $re = $k8s->inflate($k8s->object_to_json($hr));
    isa_ok($re, 'IO::K8s::GatewayAPI::V1beta1::HTTPRoute');
    is($re->spec->rules->[0]->backendRefs->[0]->name, 'health-svc',
        'JSON round-trip preserves rules[0].backendRefs[0].name at v1beta1');
};

subtest 'full depth round-trip: ListenerSet' => sub {
    my $k8s = IO::K8s->new(with => ['IO::K8s::GatewayAPI']);
    my $ls = $k8s->new_object('ListenerSet',
        metadata => { name => 'extra-listeners', namespace => 'default' },
        spec => {
            parentRef => { name => 'my-gateway' },
            listeners => [{
                name          => 'https',
                port          => 8443,
                protocol      => 'HTTPS',
                allowedRoutes => { namespaces => { from => 'Same' }, kinds => [{ kind => 'HTTPRoute' }] },
                tls           => { certificateRefs => [{ group => '', kind => 'Secret', name => 'extra-tls' }] },
            }],
        },
        status => {
            listeners => [{ name => 'https', attachedRoutes => 1, conditions => [{ type => 'Programmed', status => 'True', reason => 'Programmed', message => 'Programmed', lastTransitionTime => '2026-09-03T00:00:00Z' }], supportedKinds => [{ kind => 'HTTPRoute' }] }],
        },
    );

    isa_ok($ls->spec, 'IO::K8s::GatewayAPI::V1::ListenerSetSpec');
    isa_ok($ls->spec->parentRef, 'IO::K8s::GatewayAPI::V1::ParentGatewayReference');
    my $listener = $ls->spec->listeners->[0];
    isa_ok($listener, 'IO::K8s::GatewayAPI::V1::ListenerEntry');
    isa_ok($listener->allowedRoutes, 'IO::K8s::GatewayAPI::V1::AllowedRoutes');
    isa_ok($listener->tls, 'IO::K8s::GatewayAPI::V1::ListenerTLSConfig');
    isa_ok($ls->status->listeners->[0], 'IO::K8s::GatewayAPI::V1::ListenerEntryStatus');
    isa_ok($ls->status->listeners->[0]->supportedKinds->[0], 'IO::K8s::GatewayAPI::V1::RouteGroupKind');

    my $spec_json = $ls->TO_JSON->{spec};
    is($spec_json->{listeners}[0]{tls}{certificateRefs}[0]{name}, 'extra-tls',
        'TO_JSON listeners[0].tls.certificateRefs[0].name');

    my $re = $k8s->inflate($k8s->object_to_json($ls));
    isa_ok($re, 'IO::K8s::GatewayAPI::V1::ListenerSet');
    is($re->spec->parentRef->name, 'my-gateway', 'JSON round-trip preserves spec.parentRef.name');
};

subtest 'full depth round-trip: ReferenceGrant' => sub {
    my $k8s = IO::K8s->new(with => ['IO::K8s::GatewayAPI']);
    my $rg = $k8s->new_object('ReferenceGrant',
        metadata => { name => 'allow-routes', namespace => 'backend-ns' },
        spec => {
            from => [{ group => 'gateway.networking.k8s.io', kind => 'HTTPRoute', namespace => 'web' }],
            to   => [{ group => '', kind => 'Service', name => 'backend-svc' }],
        },
    );

    isa_ok($rg->spec, 'IO::K8s::GatewayAPI::V1beta1::ReferenceGrantSpec');
    isa_ok($rg->spec->from->[0], 'IO::K8s::GatewayAPI::V1beta1::ReferenceGrantFrom');
    isa_ok($rg->spec->to->[0], 'IO::K8s::GatewayAPI::V1beta1::ReferenceGrantTo');
    is($rg->spec->to->[0]->name, 'backend-svc', 'nested spec.to[0].name');

    my $spec_json = $rg->TO_JSON->{spec};
    is($spec_json->{from}[0]{namespace}, 'web', 'TO_JSON from[0].namespace');
    is($spec_json->{to}[0]{name}, 'backend-svc', 'TO_JSON to[0].name');

    my $re = $k8s->inflate($k8s->object_to_json($rg));
    isa_ok($re, 'IO::K8s::GatewayAPI::V1beta1::ReferenceGrant');
    is($re->spec->from->[0]->kind, 'HTTPRoute', 'JSON round-trip preserves spec.from[0].kind');
};

subtest 'full depth round-trip: TCPRoute' => sub {
    my $k8s = IO::K8s->new(with => ['IO::K8s::GatewayAPI']);
    my $tr = $k8s->new_object('TCPRoute',
        metadata => { name => 'my-tcp-route', namespace => 'default' },
        spec => {
            parentRefs => [{ name => 'my-gateway' }],
            rules      => [{ name => 'main', backendRefs => [{ name => 'tcp-svc', port => 9000, weight => 2 }] }],
        },
        status => {
            parents => [{ parentRef => { name => 'my-gateway' }, controllerName => 'istio.io/gateway-controller', conditions => [{ type => 'Accepted', status => 'True', reason => 'Accepted', message => 'Accepted', lastTransitionTime => '2026-09-03T00:00:00Z' }] }],
        },
    );

    isa_ok($tr->spec, 'IO::K8s::GatewayAPI::V1::TCPRouteSpec');
    isa_ok($tr->spec->rules->[0], 'IO::K8s::GatewayAPI::V1::TCPRouteRule');
    isa_ok($tr->spec->rules->[0]->backendRefs->[0], 'IO::K8s::GatewayAPI::V1::BackendRef');
    isa_ok($tr->status->parents->[0], 'IO::K8s::GatewayAPI::V1::RouteParentStatus');

    my $spec_json = $tr->TO_JSON->{spec};
    is($spec_json->{rules}[0]{backendRefs}[0]{weight}, 2, 'TO_JSON rules[0].backendRefs[0].weight');

    my $re = $k8s->inflate($k8s->object_to_json($tr));
    isa_ok($re, 'IO::K8s::GatewayAPI::V1::TCPRoute');
    is($re->spec->rules->[0]->backendRefs->[0]->port, 9000, 'JSON round-trip preserves rules[0].backendRefs[0].port');
};

subtest 'full depth round-trip: TLSRoute' => sub {
    my $k8s = IO::K8s->new(with => ['IO::K8s::GatewayAPI']);
    my $tr = $k8s->new_object('TLSRoute',
        metadata => { name => 'my-tls-route', namespace => 'default' },
        spec => {
            hostnames  => ['tls.example.com'],
            parentRefs => [{ name => 'my-gateway' }],
            rules      => [{ name => 'main', backendRefs => [{ name => 'tls-svc', port => 443 }] }],
        },
    );

    isa_ok($tr->spec, 'IO::K8s::GatewayAPI::V1::TLSRouteSpec');
    isa_ok($tr->spec->rules->[0], 'IO::K8s::GatewayAPI::V1::TLSRouteRule');
    isa_ok($tr->spec->rules->[0]->backendRefs->[0], 'IO::K8s::GatewayAPI::V1::BackendRef');
    ok($tr->does('IO::K8s::Role::Routable'), 'TLSRoute consumes Routable');

    my $spec_json = $tr->TO_JSON->{spec};
    is($spec_json->{hostnames}[0], 'tls.example.com', 'TO_JSON hostnames[0]');

    my $re = $k8s->inflate($k8s->object_to_json($tr));
    isa_ok($re, 'IO::K8s::GatewayAPI::V1::TLSRoute');
    is($re->spec->rules->[0]->backendRefs->[0]->name, 'tls-svc', 'JSON round-trip preserves rules[0].backendRefs[0].name');
};

subtest 'full depth round-trip: UDPRoute' => sub {
    my $k8s = IO::K8s->new(with => ['IO::K8s::GatewayAPI']);
    my $ur = $k8s->new_object('UDPRoute',
        metadata => { name => 'my-udp-route', namespace => 'default' },
        spec => {
            parentRefs => [{ name => 'my-gateway' }],
            rules      => [{ name => 'main', backendRefs => [{ name => 'udp-svc', port => 9001 }] }],
        },
    );

    isa_ok($ur->spec, 'IO::K8s::GatewayAPI::V1::UDPRouteSpec');
    isa_ok($ur->spec->rules->[0], 'IO::K8s::GatewayAPI::V1::UDPRouteRule');
    isa_ok($ur->spec->rules->[0]->backendRefs->[0], 'IO::K8s::GatewayAPI::V1::BackendRef');

    my $re = $k8s->inflate($k8s->object_to_json($ur));
    isa_ok($re, 'IO::K8s::GatewayAPI::V1::UDPRoute');
    is($re->spec->rules->[0]->name, 'main', 'JSON round-trip preserves rules[0].name');
};

done_testing;
