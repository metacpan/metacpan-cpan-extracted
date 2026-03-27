#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use IO::K8s;
use IO::K8s::Cilium;

# --- All Cilium CRD classes (matching upstream Cilium v1.19.2) ---

my %v2_classes = (
    CiliumNetworkPolicy            => { plural => 'ciliumnetworkpolicies',            namespaced => 1 },
    CiliumClusterwideNetworkPolicy => { plural => 'ciliumclusterwidenetworkpolicies', namespaced => 0 },
    CiliumLocalRedirectPolicy      => { plural => 'ciliumlocalredirectpolicies',      namespaced => 1 },
    CiliumEgressGatewayPolicy      => { plural => 'ciliumegressgatewaypolicies',      namespaced => 0 },
    CiliumIdentity                 => { plural => 'ciliumidentities',                 namespaced => 0 },
    CiliumEndpoint                 => { plural => 'ciliumendpoints',                  namespaced => 1 },
    CiliumNode                     => { plural => 'ciliumnodes',                      namespaced => 0 },
    CiliumNodeConfig               => { plural => 'ciliumnodeconfigs',                namespaced => 1 },
    CiliumLoadBalancerIPPool       => { plural => 'ciliumloadbalancerippools',        namespaced => 0 },
    CiliumEnvoyConfig              => { plural => 'ciliumenvoyconfigs',               namespaced => 1 },
    CiliumClusterwideEnvoyConfig   => { plural => 'ciliumclusterwideenvoyconfigs',    namespaced => 0 },
    CiliumCIDRGroup                => { plural => 'ciliumcidrgroups',                 namespaced => 0 },
    CiliumBGPClusterConfig         => { plural => 'ciliumbgpclusterconfigs',          namespaced => 0 },
    CiliumBGPPeerConfig            => { plural => 'ciliumbgppeerconfigs',             namespaced => 0 },
    CiliumBGPAdvertisement         => { plural => 'ciliumbgpadvertisements',          namespaced => 0 },
    CiliumBGPNodeConfig            => { plural => 'ciliumbgpnodeconfigs',             namespaced => 0 },
    CiliumBGPNodeConfigOverride    => { plural => 'ciliumbgpnodeconfigoverrides',     namespaced => 0 },
);

my %v2alpha1_classes = (
    CiliumEndpointSlice        => { plural => 'ciliumendpointslices',         namespaced => 0 },
    CiliumL2AnnouncementPolicy => { plural => 'ciliuml2announcementpolicies', namespaced => 0 },
    CiliumGatewayClassConfig   => { plural => 'ciliumgatewayclassconfigs',    namespaced => 1 },
    CiliumPodIPPool            => { plural => 'ciliumpodippools',             namespaced => 0 },
);

# --- Load all 21 classes ---

subtest 'load all Cilium classes' => sub {
    for my $kind (sort keys %v2_classes) {
        my $class = "IO::K8s::Cilium::V2::$kind";
        use_ok($class) or BAIL_OUT("Cannot load $class");
    }
    for my $kind (sort keys %v2alpha1_classes) {
        my $class = "IO::K8s::Cilium::V2alpha1::$kind";
        use_ok($class) or BAIL_OUT("Cannot load $class");
    }
};

# --- Verify api_version, kind, resource_plural, namespaced ---

subtest 'V2 class metadata' => sub {
    for my $kind (sort keys %v2_classes) {
        my $class = "IO::K8s::Cilium::V2::$kind";
        my $info = $v2_classes{$kind};

        is($class->api_version, 'cilium.io/v2', "$kind api_version");
        is($class->kind, $kind, "$kind kind");
        is($class->resource_plural, $info->{plural}, "$kind resource_plural");
        if ($info->{namespaced}) {
            ok($class->does('IO::K8s::Role::Namespaced'), "$kind is namespaced");
        } else {
            ok(!$class->does('IO::K8s::Role::Namespaced'), "$kind is cluster-scoped");
        }
    }
};

subtest 'V2alpha1 class metadata' => sub {
    for my $kind (sort keys %v2alpha1_classes) {
        my $class = "IO::K8s::Cilium::V2alpha1::$kind";
        my $info = $v2alpha1_classes{$kind};

        is($class->api_version, 'cilium.io/v2alpha1', "$kind api_version");
        is($class->kind, $kind, "$kind kind");
        is($class->resource_plural, $info->{plural}, "$kind resource_plural");
        if ($info->{namespaced}) {
            ok($class->does('IO::K8s::Role::Namespaced'), "$kind is namespaced");
        } else {
            ok(!$class->does('IO::K8s::Role::Namespaced'), "$kind is cluster-scoped");
        }
    }
};

# --- IO::K8s::Cilium resource_map completeness ---

subtest 'IO::K8s::Cilium resource_map' => sub {
    my $provider = IO::K8s::Cilium->new;
    ok($provider->does('IO::K8s::Role::ResourceMap'), 'consumes ResourceMap role');

    my $map = $provider->resource_map;
    is(scalar keys %$map, 21, 'resource_map has 21 entries');

    for my $kind (sort keys %v2_classes) {
        ok(exists $map->{$kind}, "$kind in resource_map");
        is($map->{$kind}, "Cilium::V2::$kind", "$kind maps to correct class path");
    }
    for my $kind (sort keys %v2alpha1_classes) {
        ok(exists $map->{$kind}, "$kind in resource_map");
        is($map->{$kind}, "Cilium::V2alpha1::$kind", "$kind maps to correct class path");
    }

    # Removed CRDs should not be present
    ok(!exists $map->{CiliumExternalWorkload},  'CiliumExternalWorkload removed');
    ok(!exists $map->{CiliumBGPPeeringPolicy},  'CiliumBGPPeeringPolicy removed');
};

# --- new(with => ['IO::K8s::Cilium']) integration ---

subtest 'with constructor parameter' => sub {
    my $k8s = IO::K8s->new(with => ['IO::K8s::Cilium']);

    # All 21 Cilium kinds should be resolvable by short name
    for my $kind (sort keys %v2_classes) {
        is($k8s->expand_class($kind), "IO::K8s::Cilium::V2::$kind",
            "expand_class('$kind') resolves");
    }
    for my $kind (sort keys %v2alpha1_classes) {
        is($k8s->expand_class($kind), "IO::K8s::Cilium::V2alpha1::$kind",
            "expand_class('$kind') resolves");
    }

    # Domain-qualified access
    is($k8s->expand_class('cilium.io/v2/CiliumNetworkPolicy'),
        'IO::K8s::Cilium::V2::CiliumNetworkPolicy',
        'domain-qualified V2 resolves');
    is($k8s->expand_class('cilium.io/v2/CiliumBGPClusterConfig'),
        'IO::K8s::Cilium::V2::CiliumBGPClusterConfig',
        'domain-qualified V2 BGP resolves');
    is($k8s->expand_class('cilium.io/v2alpha1/CiliumGatewayClassConfig'),
        'IO::K8s::Cilium::V2alpha1::CiliumGatewayClassConfig',
        'domain-qualified V2alpha1 resolves');

    # Core resources are unaffected
    is($k8s->expand_class('Pod'), 'IO::K8s::Api::Core::V1::Pod',
        'core Pod still resolves');
    is($k8s->expand_class('Deployment'), 'IO::K8s::Api::Apps::V1::Deployment',
        'core Deployment still resolves');
};

# --- new_object + inflate round-trip ---

subtest 'new_object and inflate round-trip' => sub {
    my $k8s = IO::K8s->new(with => ['IO::K8s::Cilium']);

    # Create a CiliumNetworkPolicy
    my $cnp = $k8s->new_object('CiliumNetworkPolicy',
        metadata => { name => 'allow-dns', namespace => 'kube-system' },
        spec => {
            endpointSelector => { matchLabels => { 'k8s-app' => 'kube-dns' } },
        },
    );
    isa_ok($cnp, 'IO::K8s::Cilium::V2::CiliumNetworkPolicy');
    is($cnp->kind, 'CiliumNetworkPolicy', 'kind');
    is($cnp->api_version, 'cilium.io/v2', 'api_version');
    isa_ok($cnp->metadata, 'IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::ObjectMeta');
    is($cnp->metadata->name, 'allow-dns', 'name');
    is($cnp->metadata->namespace, 'kube-system', 'namespace');

    # Serialize and re-inflate
    my $json = $k8s->object_to_json($cnp);
    like($json, qr/"apiVersion":"cilium\.io\/v2"/, 'JSON has apiVersion');
    like($json, qr/"kind":"CiliumNetworkPolicy"/, 'JSON has kind');

    my $re = $k8s->inflate($json);
    isa_ok($re, 'IO::K8s::Cilium::V2::CiliumNetworkPolicy', 're-inflated');
    is($re->metadata->name, 'allow-dns', 'round-trip name preserved');
    is($re->metadata->namespace, 'kube-system', 'round-trip namespace preserved');

    # Create a cluster-scoped resource
    my $node = $k8s->new_object('CiliumNode',
        metadata => { name => 'worker-1' },
        spec => { addresses => [{ type => 'InternalIP', ip => '10.0.0.1' }] },
    );
    isa_ok($node, 'IO::K8s::Cilium::V2::CiliumNode');
    ok(!$node->does('IO::K8s::Role::Namespaced'), 'CiliumNode is cluster-scoped');

    # Round-trip cluster-scoped
    my $node_re = $k8s->inflate($k8s->object_to_json($node));
    isa_ok($node_re, 'IO::K8s::Cilium::V2::CiliumNode');
    is($node_re->metadata->name, 'worker-1', 'cluster-scoped round-trip');

    # BGP resource now in V2
    my $bgp = $k8s->new_object('CiliumBGPClusterConfig',
        metadata => { name => 'bgp-config' },
        spec => { nodeSelector => { matchLabels => { 'bgp' => 'true' } } },
    );
    isa_ok($bgp, 'IO::K8s::Cilium::V2::CiliumBGPClusterConfig');
    is($bgp->api_version, 'cilium.io/v2', 'BGP V2 api_version');
    my $bgp_re = $k8s->inflate($k8s->object_to_json($bgp));
    isa_ok($bgp_re, 'IO::K8s::Cilium::V2::CiliumBGPClusterConfig');

    # V2alpha1 resource
    my $gw = $k8s->new_object('CiliumGatewayClassConfig',
        metadata => { name => 'gw-config', namespace => 'default' },
        spec => { serviceType => 'LoadBalancer' },
    );
    isa_ok($gw, 'IO::K8s::Cilium::V2alpha1::CiliumGatewayClassConfig');
    is($gw->api_version, 'cilium.io/v2alpha1', 'GatewayClassConfig api_version');
    ok($gw->does('IO::K8s::Role::Namespaced'), 'CiliumGatewayClassConfig is namespaced');
};

# --- to_yaml output ---

subtest 'to_yaml output' => sub {
    my $k8s = IO::K8s->new(with => ['IO::K8s::Cilium']);

    my $cnp = $k8s->new_object('CiliumNetworkPolicy',
        metadata => { name => 'test-policy', namespace => 'default' },
        spec => { endpointSelector => {} },
    );
    my $yaml = $cnp->to_yaml;
    like($yaml, qr/apiVersion: cilium\.io\/v2/, 'YAML apiVersion');
    like($yaml, qr/kind: CiliumNetworkPolicy/, 'YAML kind');
    like($yaml, qr/name: test-policy/, 'YAML name');
    like($yaml, qr/namespace: default/, 'YAML namespace');
};

# --- Domain-qualified expand_class ---

subtest 'domain-qualified expand_class' => sub {
    my $k8s = IO::K8s->new(with => ['IO::K8s::Cilium']);

    # V2 kinds via domain-qualified
    for my $kind (sort keys %v2_classes) {
        is($k8s->expand_class("cilium.io/v2/$kind"),
            "IO::K8s::Cilium::V2::$kind",
            "cilium.io/v2/$kind resolves");
    }

    # V2alpha1 kinds via domain-qualified
    for my $kind (sort keys %v2alpha1_classes) {
        is($k8s->expand_class("cilium.io/v2alpha1/$kind"),
            "IO::K8s::Cilium::V2alpha1::$kind",
            "cilium.io/v2alpha1/$kind resolves");
    }

    # api_version parameter style
    is($k8s->expand_class('CiliumNetworkPolicy', 'cilium.io/v2'),
        'IO::K8s::Cilium::V2::CiliumNetworkPolicy',
        'api_version parameter disambiguation');
};

# --- pk8s DSL with Cilium kinds ---

subtest 'pk8s DSL with Cilium kinds' => sub {
    require File::Temp;
    my $k8s = IO::K8s->new(with => ['IO::K8s::Cilium']);

    my ($fh, $filename) = File::Temp::tempfile(SUFFIX => '.pk8s', UNLINK => 1);
    print $fh q{
        CiliumNetworkPolicy {
            name => 'allow-dns',
            namespace => 'kube-system',
            spec => { endpointSelector => {} },
        };

        CiliumNode {
            name => 'worker-1',
            spec => { nodeIdentity => 12345 },
        };

        CiliumBGPClusterConfig {
            name => 'bgp-config',
            spec => { nodeSelector => {} },
        };
    };
    close $fh;

    my $objs = $k8s->load($filename);
    is(scalar(@$objs), 3, 'pk8s loaded 3 Cilium objects');

    my ($cnp, $node, $bgp) = @$objs;

    isa_ok($cnp, 'IO::K8s::Cilium::V2::CiliumNetworkPolicy');
    is($cnp->kind, 'CiliumNetworkPolicy', 'pk8s CNP kind');
    is($cnp->metadata->name, 'allow-dns', 'pk8s CNP name');
    is($cnp->metadata->namespace, 'kube-system', 'pk8s CNP namespace');

    isa_ok($node, 'IO::K8s::Cilium::V2::CiliumNode');
    is($node->kind, 'CiliumNode', 'pk8s CiliumNode kind');
    is($node->metadata->name, 'worker-1', 'pk8s CiliumNode name');

    isa_ok($bgp, 'IO::K8s::Cilium::V2::CiliumBGPClusterConfig');
    is($bgp->kind, 'CiliumBGPClusterConfig', 'pk8s BGP kind');
    is($bgp->api_version, 'cilium.io/v2', 'pk8s BGP api_version');
};

# --- No collision with core K8s kinds ---

subtest 'no collision with core K8s kinds' => sub {
    my $k8s = IO::K8s->new(with => ['IO::K8s::Cilium']);

    # All Cilium kinds are Cilium-prefixed, no collisions
    is($k8s->expand_class('NetworkPolicy'),
        'IO::K8s::Api::Networking::V1::NetworkPolicy',
        'core NetworkPolicy unaffected');
    is($k8s->expand_class('Node'),
        'IO::K8s::Api::Core::V1::Node',
        'core Node unaffected');
    is($k8s->expand_class('Endpoints'),
        'IO::K8s::Api::Core::V1::Endpoints',
        'core Endpoints unaffected');
    is($k8s->expand_class('EndpointSlice'),
        'IO::K8s::Api::Discovery::V1::EndpointSlice',
        'core EndpointSlice unaffected');
};

done_testing;
