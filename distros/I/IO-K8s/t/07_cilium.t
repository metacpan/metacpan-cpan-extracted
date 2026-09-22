#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use IO::K8s;
use IO::K8s::Cilium;

# --- All Cilium CRD classes (matching upstream Cilium v1.20.1) ---

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
    CiliumDatapathPlugin       => { plural => 'ciliumdatapathplugins',        namespaced => 0 },
);

# --- Load all 22 classes ---

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
    is(scalar keys %$map, 31, 'resource_map has 31 entries');

    for my $kind (sort keys %v2_classes) {
        ok(exists $map->{$kind}, "$kind in resource_map");
        is($map->{$kind}, "Cilium::V2::$kind", "$kind maps to correct class path");
    }
    for my $kind (sort keys %v2alpha1_classes) {
        ok(exists $map->{$kind}, "$kind in resource_map");
        is($map->{$kind}, "Cilium::V2alpha1::$kind", "$kind maps to correct class path");
    }

    # Back-compat CRDs (k78) are reachable only via domain-qualified
    # keys; the short names stay on the storage version.
    ok(exists $map->{'cilium.io/v2alpha1/CiliumBGPAdvertisement'},
        'CiliumBGPAdvertisement v2alpha1 back-compat reachable');
    is($map->{'cilium.io/v2alpha1/CiliumBGPAdvertisement'},
        'Cilium::V2alpha1::CiliumBGPAdvertisement',
        'CiliumBGPAdvertisement v2alpha1 maps correctly');
    ok(exists $map->{'cilium.io/v2alpha1/CiliumBGPClusterConfig'},
        'CiliumBGPClusterConfig v2alpha1 back-compat reachable');
    ok(exists $map->{'cilium.io/v2alpha1/CiliumBGPNodeConfig'},
        'CiliumBGPNodeConfig v2alpha1 back-compat reachable');
    ok(exists $map->{'cilium.io/v2alpha1/CiliumBGPNodeConfigOverride'},
        'CiliumBGPNodeConfigOverride v2alpha1 back-compat reachable');
    ok(exists $map->{'cilium.io/v2alpha1/CiliumBGPPeerConfig'},
        'CiliumBGPPeerConfig v2alpha1 back-compat reachable');
    ok(exists $map->{'cilium.io/v2alpha1/CiliumCIDRGroup'},
        'CiliumCIDRGroup v2alpha1 back-compat reachable');
    ok(exists $map->{'cilium.io/v2alpha1/CiliumLoadBalancerIPPool'},
        'CiliumLoadBalancerIPPool v2alpha1 back-compat reachable');
    is($map->{'cilium.io/v2alpha1/CiliumLoadBalancerIPPool'},
        'Cilium::V2alpha1::CiliumLoadBalancerIPPool',
        'CiliumLoadBalancerIPPool v2alpha1 maps correctly');
    ok(exists $map->{'cilium.io/v2alpha1/CiliumBGPPeeringPolicy'},
        'CiliumBGPPeeringPolicy reachable (back-compat, removed upstream)');
    ok(exists $map->{'cilium.io/v2/CiliumExternalWorkload'},
        'CiliumExternalWorkload reachable (back-compat, removed upstream)');
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

# --- Back-compat: 9 shipped Cilium classes now reachable via qualified GVKs (k78, k83) ---

subtest 'back-compat GVK resolution (k78, k83)' => sub {
    my $k8s = IO::K8s->new(with => ['IO::K8s::Cilium']);

    my @back_compat = (
        [ 'cilium.io/v2alpha1', 'CiliumBGPAdvertisement',      'IO::K8s::Cilium::V2alpha1::CiliumBGPAdvertisement' ],
        [ 'cilium.io/v2alpha1', 'CiliumBGPClusterConfig',      'IO::K8s::Cilium::V2alpha1::CiliumBGPClusterConfig' ],
        [ 'cilium.io/v2alpha1', 'CiliumBGPNodeConfig',         'IO::K8s::Cilium::V2alpha1::CiliumBGPNodeConfig' ],
        [ 'cilium.io/v2alpha1', 'CiliumBGPNodeConfigOverride', 'IO::K8s::Cilium::V2alpha1::CiliumBGPNodeConfigOverride' ],
        [ 'cilium.io/v2alpha1', 'CiliumBGPPeerConfig',         'IO::K8s::Cilium::V2alpha1::CiliumBGPPeerConfig' ],
        [ 'cilium.io/v2alpha1', 'CiliumCIDRGroup',             'IO::K8s::Cilium::V2alpha1::CiliumCIDRGroup' ],
        [ 'cilium.io/v2alpha1', 'CiliumLoadBalancerIPPool',    'IO::K8s::Cilium::V2alpha1::CiliumLoadBalancerIPPool' ],
        [ 'cilium.io/v2alpha1', 'CiliumBGPPeeringPolicy',      'IO::K8s::Cilium::V2alpha1::CiliumBGPPeeringPolicy' ],
        [ 'cilium.io/v2',       'CiliumExternalWorkload',      'IO::K8s::Cilium::V2::CiliumExternalWorkload' ],
    );

    for my $row (@back_compat) {
        my ($api_version, $kind, $expected_class) = @$row;
        my $qualified = "$api_version/$kind";

        # Domain-qualified lookup
        is($k8s->expand_class($qualified), $expected_class,
            "expand_class('$qualified') resolves");

        # inflate() of a hashref with the matching apiVersion
        my $obj = $k8s->inflate({
            apiVersion => $api_version,
            kind       => $kind,
            metadata   => { name => 'sample', namespace => 'default' },
            spec       => {},
        });
        isa_ok($obj, $expected_class, "inflate returned $expected_class");
        is($obj->api_version, $api_version, "$kind api_version preserved");
        is($obj->kind, $kind, "$kind kind preserved");
    }

    # Short name for the 7 BGP/CIDR/LB Kinds still resolves to the storage version (v2)
    for my $kind (qw(CiliumBGPAdvertisement CiliumBGPClusterConfig
                     CiliumBGPNodeConfig CiliumBGPNodeConfigOverride
                     CiliumBGPPeerConfig CiliumCIDRGroup
                     CiliumLoadBalancerIPPool)) {
        is($k8s->expand_class($kind), "IO::K8s::Cilium::V2::$kind",
            "short name '$kind' still resolves to V2 storage version");
        is($k8s->expand_class($kind, 'cilium.io/v2'),
            "IO::K8s::Cilium::V2::$kind",
            "$kind with api_version v2 resolves to V2");
        is($k8s->expand_class($kind, 'cilium.io/v2alpha1'),
            "IO::K8s::Cilium::V2alpha1::$kind",
            "$kind with api_version v2alpha1 resolves to V2alpha1");
    }

    # The two removed Kinds are reachable only via their qualified keys —
    # no short-name entry exists, matching the k58 pattern. (This is not
    # tested via expand_class() directly: expand_class() falls through to a
    # non-existent IO::K8s::<Kind> class without the resource_map entry.
    # What callers care about is that inflate/dispatch of the back-compat
    # GVKs above now succeeds — which the rows above assert.)
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

    # New in v1.20.0: CiliumDatapathPlugin (Extensible Datapath)
    my $cddp = $k8s->new_object('CiliumDatapathPlugin',
        metadata => { name => 'my-plugin' },
        spec => { attachmentPolicy => 'BestEffort', version => '1.0.0' },
    );
    isa_ok($cddp, 'IO::K8s::Cilium::V2alpha1::CiliumDatapathPlugin');
    is($cddp->kind, 'CiliumDatapathPlugin', 'CiliumDatapathPlugin kind');
    is($cddp->api_version, 'cilium.io/v2alpha1', 'CiliumDatapathPlugin api_version');
    ok(!$cddp->does('IO::K8s::Role::Namespaced'), 'CiliumDatapathPlugin is cluster-scoped');
    my $cddp_re = $k8s->inflate($k8s->object_to_json($cddp));
    isa_ok($cddp_re, 'IO::K8s::Cilium::V2alpha1::CiliumDatapathPlugin');
    is($cddp_re->metadata->name, 'my-plugin', 'CiliumDatapathPlugin round-trip');
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

# --- Full depth round-trip (D5, k95, task B-Cilium): cilium.io/v2 ---
# Every subtest below builds through $k8s->new_object (the coercing path,
# k100 -- a direct ->new(spec => {...}) does not inflate nested hashrefs
# into typed objects), asserts the typed nested object graph a few levels
# deep, checks representative TO_JSON leaf values, and round-trips through
# real JSON.

subtest 'full depth round-trip: CiliumNetworkPolicy / CiliumClusterwideNetworkPolicy share one Rule class' => sub {
    my $k8s = IO::K8s->new(with => ['IO::K8s::Cilium']);

    my %rule_spec = (
        endpointSelector => { matchLabels => { app => 'web' } },
        nodeSelector      => {},
        ingress => [{
            fromEndpoints  => [{ matchLabels => { role => 'frontend' } }],
            authentication => { mode => 'required' },
            toPorts => [{
                ports => [{ port => '80', protocol => 'TCP' }],
                rules => { http => [{ method => 'GET', path => '/api' }] },
            }],
        }],
        egress => [{
            toCIDR  => ['10.0.0.0/8'],
            toFQDNs => [{ matchName => 'example.com' }],
            toPorts => [{ ports => [{ port => '53', protocol => 'UDP' }] }],
        }],
        labels            => [{ key => 'app', source => 'k8s', value => 'web' }],
        log               => { value => 'audit' },
        enableDefaultDeny => { ingress => 1, egress => 0 },
    );

    my $cnp = $k8s->new_object('CiliumNetworkPolicy',
        metadata => { name => 'allow-web', namespace => 'default' },
        spec     => { %rule_spec },
    );
    my $ccnp = $k8s->new_object('CiliumClusterwideNetworkPolicy',
        metadata => { name => 'allow-web-cluster' },
        spec     => { %rule_spec },
    );

    isa_ok($cnp->spec, 'IO::K8s::Cilium::V2::Rule');
    isa_ok($ccnp->spec, 'IO::K8s::Cilium::V2::Rule');
    is(ref($cnp->spec), ref($ccnp->spec),
        'CiliumNetworkPolicy and CiliumClusterwideNetworkPolicy share the SAME Rule class (D6)');
    is(ref($cnp->spec), 'IO::K8s::Cilium::V2::Rule', 'and it is IO::K8s::Cilium::V2::Rule');

    isa_ok($cnp->spec->endpointSelector, 'IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::LabelSelector',
        'endpointSelector reused Meta::V1::LabelSelector (reuse_core)');
    isa_ok($cnp->spec->ingress->[0], 'IO::K8s::Cilium::V2::IngressRule');
    isa_ok($cnp->spec->ingress->[0]->fromEndpoints->[0], 'IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::LabelSelector');
    isa_ok($cnp->spec->ingress->[0]->authentication, 'IO::K8s::Cilium::V2::Authentication');
    isa_ok($cnp->spec->ingress->[0]->toPorts->[0], 'IO::K8s::Cilium::V2::PortRule');
    isa_ok($cnp->spec->ingress->[0]->toPorts->[0]->ports->[0],
        'IO::K8s::Api::Networking::V1::NetworkPolicyPort',
        'PortRule.ports reused core NetworkPolicyPort (reuse_core)');
    isa_ok($cnp->spec->ingress->[0]->toPorts->[0]->rules, 'IO::K8s::Cilium::V2::L7Rules');
    isa_ok($cnp->spec->ingress->[0]->toPorts->[0]->rules->http->[0], 'IO::K8s::Cilium::V2::PortRuleHTTP');
    isa_ok($cnp->spec->egress->[0], 'IO::K8s::Cilium::V2::EgressRule');
    isa_ok($cnp->spec->egress->[0]->toFQDNs->[0], 'IO::K8s::Cilium::V2::FQDNSelector');
    isa_ok($cnp->spec->enableDefaultDeny, 'IO::K8s::Cilium::V2::DefaultDenyConfig');
    isa_ok($cnp->spec->log, 'IO::K8s::Cilium::V2::LogConfig');
    isa_ok($cnp->spec->labels->[0], 'IO::K8s::Cilium::V2::Label');

    my $json = $cnp->TO_JSON;
    is($json->{spec}{ingress}[0]{toPorts}[0]{ports}[0]{port}, '80', 'TO_JSON ingress toPorts port');
    is($json->{spec}{ingress}[0]{toPorts}[0]{rules}{http}[0]{method}, 'GET', 'TO_JSON HTTP rule method');
    is($json->{spec}{egress}[0]{toFQDNs}[0]{matchName}, 'example.com', 'TO_JSON egress toFQDNs matchName');
    ok($json->{spec}{enableDefaultDeny}{ingress}, 'TO_JSON enableDefaultDeny.ingress true');
    ok(!$json->{spec}{enableDefaultDeny}{egress}, 'TO_JSON enableDefaultDeny.egress false');

    my $re = $k8s->inflate($k8s->object_to_json($cnp));
    isa_ok($re, 'IO::K8s::Cilium::V2::CiliumNetworkPolicy');
    isa_ok($re->spec, 'IO::K8s::Cilium::V2::Rule');
    is($re->spec->egress->[0]->toCIDR->[0], '10.0.0.0/8', 'JSON round-trip preserves egress.toCIDR');
    is($re->spec->ingress->[0]->toPorts->[0]->rules->http->[0]->path, '/api',
        'JSON round-trip preserves deep HTTP rule path');

    # specs[] (array of Rule) uses the same shared class too.
    my $cnp_multi = $k8s->new_object('CiliumNetworkPolicy',
        metadata => { name => 'multi-spec', namespace => 'default' },
        specs    => [ { %rule_spec }, { endpointSelector => {} } ],
    );
    isa_ok($cnp_multi->specs->[0], 'IO::K8s::Cilium::V2::Rule');
    is(ref($cnp_multi->specs->[0]), ref($cnp->spec), 'specs[] items are the same Rule class as spec');
};

subtest 'full depth round-trip: CiliumBGPClusterConfig / CiliumBGPPeerConfig / CiliumBGPNodeConfig' => sub {
    my $k8s = IO::K8s->new(with => ['IO::K8s::Cilium']);

    my $cluster = $k8s->new_object('CiliumBGPClusterConfig',
        metadata => { name => 'cluster-a' },
        spec => {
            nodeSelector  => { matchLabels => { bgp => 'true' } },
            bgpInstances  => [{
                name      => 'instance-65000',
                localASN  => 65000,
                peers     => [{
                    name           => 'peer-1',
                    peerASN        => 65001,
                    peerAddress    => '10.0.0.1',
                    autoDiscovery  => { mode => 'DefaultGateway', defaultGateway => { addressFamily => 'ipv4' } },
                    peerConfigRef  => { name => 'peer-config-1' },
                }],
            }],
        },
    );
    isa_ok($cluster->spec, 'IO::K8s::Cilium::V2::CiliumBGPClusterConfigSpec');
    isa_ok($cluster->spec->bgpInstances->[0], 'IO::K8s::Cilium::V2::CiliumBGPInstance');
    isa_ok($cluster->spec->bgpInstances->[0]->peers->[0], 'IO::K8s::Cilium::V2::CiliumBGPPeer');
    isa_ok($cluster->spec->bgpInstances->[0]->peers->[0]->autoDiscovery, 'IO::K8s::Cilium::V2::BGPAutoDiscovery');
    isa_ok($cluster->spec->bgpInstances->[0]->peers->[0]->autoDiscovery->defaultGateway, 'IO::K8s::Cilium::V2::DefaultGateway');
    isa_ok($cluster->spec->bgpInstances->[0]->peers->[0]->peerConfigRef, 'IO::K8s::Cilium::V2::PeerConfigReference');
    is($cluster->TO_JSON->{spec}{bgpInstances}[0]{peers}[0]{peerConfigRef}{name}, 'peer-config-1',
        'TO_JSON deep peerConfigRef.name');

    my $peer = $k8s->new_object('CiliumBGPPeerConfig',
        metadata => { name => 'peer-config-1' },
        spec => {
            transport        => { peerPort => 179 },
            timers           => { holdTimeSeconds => 90 },
            gracefulRestart  => { enabled => 1, restartTimeSeconds => 120 },
            families         => [{ afi => 'ipv4', safi => 'unicast', advertisements => { matchLabels => { advertise => 'true' } } }],
        },
    );
    isa_ok($peer->spec, 'IO::K8s::Cilium::V2::CiliumBGPPeerConfigSpec');
    isa_ok($peer->spec->transport, 'IO::K8s::Cilium::V2::CiliumBGPTransport');
    isa_ok($peer->spec->timers, 'IO::K8s::Cilium::V2::CiliumBGPTimers');
    isa_ok($peer->spec->gracefulRestart, 'IO::K8s::Cilium::V2::CiliumBGPNeighborGracefulRestart');
    isa_ok($peer->spec->families->[0], 'IO::K8s::Cilium::V2::CiliumBGPFamilyWithAdverts');
    isa_ok($peer->spec->families->[0]->advertisements, 'IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::LabelSelector');
    my $peer_re = $k8s->inflate($k8s->object_to_json($peer));
    is($peer_re->spec->transport->peerPort, 179, 'JSON round-trip transport.peerPort');

    my $node_cfg = $k8s->new_object('CiliumBGPNodeConfig',
        metadata => { name => 'node-a-bgp' },
        spec => {
            bgpInstances => [{ name => 'instance-65000', localASN => 65000, peers => [{ name => 'peer-1', peerAddress => '10.0.0.1' }] }],
        },
        status => {
            bgpInstances => [{
                name => 'instance-65000',
                peers => [{
                    name => 'peer-1', peerAddress => '10.0.0.1', peeringState => 'established',
                    timers => { appliedHoldTimeSeconds => 90 },
                    routeCount => [{ afi => 'ipv4', safi => 'unicast', received => 5, advertised => 3 }],
                }],
            }],
        },
    );
    isa_ok($node_cfg->spec, 'IO::K8s::Cilium::V2::CiliumBGPNodeSpec');
    isa_ok($node_cfg->status, 'IO::K8s::Cilium::V2::CiliumBGPNodeStatus');
    isa_ok($node_cfg->status->bgpInstances->[0], 'IO::K8s::Cilium::V2::CiliumBGPNodeInstanceStatus');
    isa_ok($node_cfg->status->bgpInstances->[0]->peers->[0], 'IO::K8s::Cilium::V2::CiliumBGPNodePeerStatus');
    isa_ok($node_cfg->status->bgpInstances->[0]->peers->[0]->timers, 'IO::K8s::Cilium::V2::CiliumBGPTimersState');
    isa_ok($node_cfg->status->bgpInstances->[0]->peers->[0]->routeCount->[0], 'IO::K8s::Cilium::V2::BGPFamilyRouteCount');
    is($node_cfg->TO_JSON->{status}{bgpInstances}[0]{peers}[0]{routeCount}[0]{received}, 5,
        'TO_JSON deep routeCount.received');

    my $override = $k8s->new_object('CiliumBGPNodeConfigOverride',
        metadata => { name => 'node-a-bgp' },
        spec => {
            bgpInstances => [{ name => 'instance-65000', localPort => 179, peers => [{ name => 'peer-1', localPort => 179 }] }],
        },
    );
    isa_ok($override->spec, 'IO::K8s::Cilium::V2::CiliumBGPNodeConfigOverrideSpec');
    isa_ok($override->spec->bgpInstances->[0], 'IO::K8s::Cilium::V2::CiliumBGPNodeConfigInstanceOverride');
    isa_ok($override->spec->bgpInstances->[0]->peers->[0], 'IO::K8s::Cilium::V2::CiliumBGPNodeConfigPeerOverride');
};

subtest 'full depth round-trip: CiliumBGPAdvertisement' => sub {
    my $k8s = IO::K8s->new(with => ['IO::K8s::Cilium']);
    my $adv = $k8s->new_object('CiliumBGPAdvertisement',
        metadata => { name => 'advert-1' },
        spec => {
            advertisements => [{
                advertisementType => 'Service',
                service => { addresses => ['LoadBalancerIP'], aggregationLengthIPv4 => 24 },
                attributes => { communities => { standard => ['65000:100'] }, localPreference => 100 },
                selector => { matchLabels => { advertise => 'bgp' } },
            }],
        },
    );
    isa_ok($adv->spec, 'IO::K8s::Cilium::V2::CiliumBGPAdvertisementSpec');
    isa_ok($adv->spec->advertisements->[0], 'IO::K8s::Cilium::V2::BGPAdvertisement');
    isa_ok($adv->spec->advertisements->[0]->service, 'IO::K8s::Cilium::V2::BGPServiceOptions');
    isa_ok($adv->spec->advertisements->[0]->attributes, 'IO::K8s::Cilium::V2::BGPAttributes');
    isa_ok($adv->spec->advertisements->[0]->attributes->communities, 'IO::K8s::Cilium::V2::BGPCommunities');
    isa_ok($adv->spec->advertisements->[0]->selector, 'IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::LabelSelector');
    is($adv->TO_JSON->{spec}{advertisements}[0]{attributes}{communities}{standard}[0], '65000:100',
        'TO_JSON deep BGP community value');
    my $re = $k8s->inflate($k8s->object_to_json($adv));
    is($re->spec->advertisements->[0]->attributes->localPreference, 100, 'JSON round-trip localPreference');
};

subtest 'full depth round-trip: CiliumEgressGatewayPolicy' => sub {
    my $k8s = IO::K8s->new(with => ['IO::K8s::Cilium']);
    my $cegp = $k8s->new_object('CiliumEgressGatewayPolicy',
        metadata => { name => 'egress-1' },
        spec => {
            selectors         => [{ podSelector => { matchLabels => { app => 'egress-client' } } }],
            destinationCIDRs  => ['192.0.2.0/24'],
            egressGateway     => { nodeSelector => { matchLabels => { role => 'gateway' } }, egressIP => '192.0.2.10' },
            egressGateways    => [{ nodeSelector => { matchLabels => { role => 'gateway2' } } }],
        },
    );
    isa_ok($cegp->spec, 'IO::K8s::Cilium::V2::CiliumEgressGatewayPolicySpec');
    isa_ok($cegp->spec->selectors->[0], 'IO::K8s::Cilium::V2::EgressGatewaySelector');
    isa_ok($cegp->spec->selectors->[0]->podSelector, 'IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::LabelSelector');
    isa_ok($cegp->spec->egressGateway, 'IO::K8s::Cilium::V2::EgressGateway');
    isa_ok($cegp->spec->egressGateways->[0], 'IO::K8s::Cilium::V2::EgressGateway');
    is($cegp->TO_JSON->{spec}{egressGateway}{egressIP}, '192.0.2.10', 'TO_JSON egressGateway.egressIP');
};

subtest 'full depth round-trip: CiliumLocalRedirectPolicy' => sub {
    my $k8s = IO::K8s->new(with => ['IO::K8s::Cilium']);
    my $lrp = $k8s->new_object('CiliumLocalRedirectPolicy',
        metadata => { name => 'lrp-1', namespace => 'default' },
        spec => {
            redirectFrontend => {
                addressMatcher => { ip => '10.0.0.1', toPorts => [{ port => '53', protocol => 'UDP' }] },
            },
            redirectBackend => {
                localEndpointSelector => { matchLabels => { app => 'dns' } },
                toPorts               => [{ port => '5353', protocol => 'UDP' }],
            },
        },
    );
    isa_ok($lrp->spec, 'IO::K8s::Cilium::V2::CiliumLocalRedirectPolicySpec');
    isa_ok($lrp->spec->redirectFrontend, 'IO::K8s::Cilium::V2::RedirectFrontend');
    isa_ok($lrp->spec->redirectFrontend->addressMatcher, 'IO::K8s::Cilium::V2::Frontend');
    isa_ok($lrp->spec->redirectFrontend->addressMatcher->toPorts->[0], 'IO::K8s::Cilium::V2::PortInfo');
    isa_ok($lrp->spec->redirectBackend, 'IO::K8s::Cilium::V2::RedirectBackend');
    isa_ok($lrp->spec->redirectBackend->localEndpointSelector, 'IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::LabelSelector');
    is(ref($lrp->spec->redirectFrontend->addressMatcher->toPorts->[0]), ref($lrp->spec->redirectBackend->toPorts->[0]),
        'PortInfo shared between RedirectFrontend and RedirectBackend');
    is($lrp->TO_JSON->{spec}{redirectBackend}{toPorts}[0]{port}, '5353', 'TO_JSON redirectBackend port');
};

subtest 'full depth round-trip: CiliumLoadBalancerIPPool / CiliumCIDRGroup / CiliumNodeConfig' => sub {
    my $k8s = IO::K8s->new(with => ['IO::K8s::Cilium']);

    my $pool = $k8s->new_object('CiliumLoadBalancerIPPool',
        metadata => { name => 'pool-1' },
        spec => {
            serviceSelector => { matchLabels => { pool => 'external' } },
            blocks          => [{ cidr => '192.0.2.0/24' }, { start => '198.51.100.1', stop => '198.51.100.10' }],
        },
    );
    isa_ok($pool->spec, 'IO::K8s::Cilium::V2::CiliumLoadBalancerIPPoolSpec');
    isa_ok($pool->spec->blocks->[0], 'IO::K8s::Cilium::V2::CiliumLoadBalancerIPPoolIPBlock');
    is($pool->spec->blocks->[1]->stop, '198.51.100.10', 'block[1].stop');

    my $cidrgroup = $k8s->new_object('CiliumCIDRGroup',
        metadata => { name => 'trusted' },
        spec     => { externalCIDRs => ['10.0.0.0/8', '192.168.0.0/16'] },
    );
    isa_ok($cidrgroup->spec, 'IO::K8s::Cilium::V2::CiliumCIDRGroupSpec');
    is_deeply($cidrgroup->spec->externalCIDRs, ['10.0.0.0/8', '192.168.0.0/16'], 'externalCIDRs');

    my $nc = $k8s->new_object('CiliumNodeConfig',
        metadata => { name => 'override-1', namespace => 'kube-system' },
        spec => {
            defaults     => { 'enable-ipv6' => 'false' },
            nodeSelector => { matchLabels => { node => 'special' } },
        },
    );
    isa_ok($nc->spec, 'IO::K8s::Cilium::V2::CiliumNodeConfigSpec');
    isa_ok($nc->spec->nodeSelector, 'IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::LabelSelector');
    is($nc->spec->defaults->{'enable-ipv6'}, 'false', 'defaults hash preserved');
};

subtest 'full depth round-trip: CiliumEnvoyConfig / CiliumClusterwideEnvoyConfig share Spec/Service classes' => sub {
    my $k8s = IO::K8s->new(with => ['IO::K8s::Cilium']);

    my %cec_spec = (
        services        => [{ name => 'my-listener-svc', namespace => 'default', ports => [8080], listener => 'my-listener' }],
        backendServices => [{ name => 'my-backend-svc', namespace => 'default', number => ['8080'] }],
        nodeSelector    => { matchLabels => { envoy => 'true' } },
        resources       => [{ '@type' => 'type.googleapis.com/envoy.config.listener.v3.Listener', name => 'my-listener' }],
    );

    my $cec = $k8s->new_object('CiliumEnvoyConfig',
        metadata => { name => 'envoy-1', namespace => 'default' },
        spec     => { %cec_spec },
    );
    my $ccec = $k8s->new_object('CiliumClusterwideEnvoyConfig',
        metadata => { name => 'envoy-cluster-1' },
        spec     => { %cec_spec },
    );

    isa_ok($cec->spec, 'IO::K8s::Cilium::V2::CiliumEnvoyConfigSpec');
    is(ref($cec->spec), ref($ccec->spec), 'CiliumEnvoyConfig / CiliumClusterwideEnvoyConfig share the same Spec class');
    isa_ok($cec->spec->services->[0], 'IO::K8s::Cilium::V2::ServiceListener');
    isa_ok($cec->spec->backendServices->[0], 'IO::K8s::Cilium::V2::EnvoyConfigService');
    isa_ok($cec->spec->nodeSelector, 'IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::LabelSelector');
    is($cec->spec->resources->[0]{name}, 'my-listener', 'raw xDS resource preserved opaquely');
    is($cec->TO_JSON->{spec}{services}[0]{listener}, 'my-listener', 'TO_JSON services[0].listener');
};

subtest 'full depth round-trip: CiliumNode' => sub {
    my $k8s = IO::K8s->new(with => ['IO::K8s::Cilium']);

    my $node = $k8s->new_object('CiliumNode',
        metadata => { name => 'worker-1' },
        spec => {
            addresses  => [{ type => 'InternalIP', ip => '10.0.0.5' }],
            'instance-id' => 'i-0123456789abcdef0',
            health     => { ipv4 => '10.0.0.6', ipv6 => '' },
            ingress    => { ipv4 => '10.0.0.7' },
            encryption => { key => 3 },
            eni        => { 'instance-type' => 'm5.large', 'security-groups' => ['sg-1'], 'first-interface-index' => 1 },
            'azure'    => { 'interface-name' => 'eth0' },
            'alibaba-cloud' => { 'instance-type' => 'ecs.g6.large', 'availability-zone' => 'cn-hangzhou-a' },
            ipam => {
                pools => {
                    allocated => [{ pool => 'default', cidrs => ['10.1.0.0/24'] }],
                    requested => [{ pool => 'default', needed => { 'ipv4-addrs' => 16 } }],
                },
                pool => { 'ip-1' => { owner => 'default/pod-1', resource => 'eni-1' } },
            },
        },
        status => {
            eni    => { enis => { 'eni-1' => { id => 'eni-1', mac => 'aa:bb:cc:dd:ee:ff', vpc => { id => 'vpc-1' }, subnet => { id => 'subnet-1' } } } },
            azure  => { interfaces => [{ id => 'iface-1', addresses => [{ ip => '10.0.0.8' }], subnet => { id => 'subnet-a' } }] },
            'alibaba-cloud' => { enis => { 'eni-a' => { 'network-interface-id' => 'eni-a', vpc => { 'vpc-id' => 'vpc-a' }, vswitch => { 'vswitch-id' => 'vsw-a' }, 'private-ipsets' => [{ primary => 1, 'private-ip-address' => '10.2.0.5' }] } } },
            ipam   => { used => { 'ip-1' => { owner => 'default/pod-1' } }, 'pod-cidrs' => { '10.1.0.0/24' => { status => 'in-use' } }, 'operator-status' => { error => '' } },
        },
    );

    isa_ok($node->spec, 'IO::K8s::Cilium::V2::NodeSpec');
    isa_ok($node->spec->addresses->[0], 'IO::K8s::Cilium::V2::NodeAddress');
    isa_ok($node->spec->health, 'IO::K8s::Cilium::V2::HealthAddressingSpec');
    isa_ok($node->spec->ingress, 'IO::K8s::Cilium::V2::AddressPair');
    isa_ok($node->spec->encryption, 'IO::K8s::Cilium::V2::EncryptionSpec');
    isa_ok($node->spec->eni, 'IO::K8s::Cilium::V2::ENISpec');
    isa_ok($node->spec->azure, 'IO::K8s::Cilium::V2::AzureSpec');
    isa_ok($node->spec->alibaba_cloud, 'IO::K8s::Cilium::V2::AlibabaCloudSpec');
    isa_ok($node->spec->ipam, 'IO::K8s::Cilium::V2::IPAMSpec');
    isa_ok($node->spec->ipam->pools, 'IO::K8s::Cilium::V2::IPAMPoolSpec');
    isa_ok($node->spec->ipam->pools->allocated->[0], 'IO::K8s::Cilium::V2::IPAMPoolAllocation');
    isa_ok($node->spec->ipam->pools->requested->[0], 'IO::K8s::Cilium::V2::IPAMPoolRequest');
    isa_ok($node->spec->ipam->pools->requested->[0]->needed, 'IO::K8s::Cilium::V2::IPAMPoolDemand');
    isa_ok($node->spec->ipam->pool->{'ip-1'}, 'IO::K8s::Cilium::V2::AllocationIP');

    isa_ok($node->status, 'IO::K8s::Cilium::V2::NodeStatus');
    isa_ok($node->status->eni, 'IO::K8s::Cilium::V2::ENIStatus');
    isa_ok($node->status->eni->enis->{'eni-1'}, 'IO::K8s::Cilium::V2::ENI');
    isa_ok($node->status->eni->enis->{'eni-1'}->vpc, 'IO::K8s::Cilium::V2::AwsVPC');
    isa_ok($node->status->eni->enis->{'eni-1'}->subnet, 'IO::K8s::Cilium::V2::AwsSubnet');
    isa_ok($node->status->azure, 'IO::K8s::Cilium::V2::AzureStatus');
    isa_ok($node->status->azure->interfaces->[0], 'IO::K8s::Cilium::V2::AzureInterface');
    isa_ok($node->status->azure->interfaces->[0]->addresses->[0], 'IO::K8s::Cilium::V2::AzureAddress');
    isa_ok($node->status->alibaba_cloud, 'IO::K8s::Cilium::V2::AlibabaCloudENIStatus');
    isa_ok($node->status->alibaba_cloud->enis->{'eni-a'}, 'IO::K8s::Cilium::V2::AlibabaCloudENI');
    isa_ok($node->status->alibaba_cloud->enis->{'eni-a'}->vpc, 'IO::K8s::Cilium::V2::VPC');
    isa_ok($node->status->alibaba_cloud->enis->{'eni-a'}->vswitch, 'IO::K8s::Cilium::V2::VSwitch');
    isa_ok($node->status->alibaba_cloud->enis->{'eni-a'}->private_ipsets->[0], 'IO::K8s::Cilium::V2::PrivateIPSet');
    is($node->status->alibaba_cloud->enis->{'eni-a'}->private_ipsets->[0]->private_ip_address, '10.2.0.5',
        'deep alibaba-cloud ENI private IP address');
    isa_ok($node->status->ipam, 'IO::K8s::Cilium::V2::IPAMStatus');
    isa_ok($node->status->ipam->used->{'ip-1'}, 'IO::K8s::Cilium::V2::AllocationIP');
    isa_ok($node->status->ipam->pod_cidrs->{'10.1.0.0/24'}, 'IO::K8s::Cilium::V2::PodCIDRMapEntry');
    isa_ok($node->status->ipam->operator_status, 'IO::K8s::Cilium::V2::OperatorStatus');

    my $json = $node->TO_JSON;
    is($json->{spec}{eni}{'instance-type'}, 'm5.large', 'TO_JSON spec.eni instance-type (hyphenated wire key)');
    is($json->{status}{eni}{enis}{'eni-1'}{mac}, 'aa:bb:cc:dd:ee:ff', 'TO_JSON deep status.eni.enis map value');

    my $re = $k8s->inflate($k8s->object_to_json($node));
    isa_ok($re, 'IO::K8s::Cilium::V2::CiliumNode');
    is($re->status->eni->enis->{'eni-1'}->vpc->id, 'vpc-1', 'JSON round-trip preserves deep AWS ENI vpc.id');
};

subtest 'full depth round-trip: CiliumEndpoint (status-only, no spec upstream) / CiliumIdentity' => sub {
    my $k8s = IO::K8s->new(with => ['IO::K8s::Cilium']);

    my $cep = $k8s->new_object('CiliumEndpoint',
        metadata => { name => 'pod-abc123', namespace => 'default' },
        status => {
            id       => 1234,
            state    => 'ready',
            identity => { id => 5, labels => ['k8s:app=web'] },
            'external-identifiers' => { 'pod-name' => 'web-abc123', 'k8s-namespace' => 'default' },
            health   => { bpf => 'OK', connected => 1, overallHealth => 'OK', policy => 'OK' },
            encryption => { key => 0 },
            networking => { node => '10.0.0.5', addressing => [{ ipv4 => '10.1.2.3' }] },
            controllers => [{
                name => 'endpoint-1234-sync-to-k8s-ciliumendpoint', uuid => 'uuid-1',
                configuration => { interval => 30, 'error-retry' => 1, 'error-retry-base' => 1 },
                status => { 'success-count' => 10, 'failure-count' => 0 },
            }],
            log => [{ code => 'ok', message => 'regeneration successful', state => 'ready', timestamp => '2026-01-01T00:00:00Z' }],
            'named-ports' => [{ name => 'http', port => 8080, protocol => 'TCP' }],
            policy => {
                ingress => { enforcing => 1, allowed => [{ identity => 5, 'dest-port' => 80, protocol => 6 }] },
                egress  => { enforcing => 0 },
            },
        },
    );

    ok(!$cep->can('spec'), 'CiliumEndpoint has no spec attribute (upstream v1.20.1 declares none -- k107)');
    isa_ok($cep->status, 'IO::K8s::Cilium::V2::EndpointStatus');
    isa_ok($cep->status->identity, 'IO::K8s::Cilium::V2::EndpointIdentity');
    isa_ok($cep->status->external_identifiers, 'IO::K8s::Cilium::V2::EndpointIdentifiers');
    isa_ok($cep->status->health, 'IO::K8s::Cilium::V2::EndpointHealth');
    isa_ok($cep->status->networking, 'IO::K8s::Cilium::V2::EndpointNetworking');
    isa_ok($cep->status->networking->addressing->[0], 'IO::K8s::Cilium::V2::AddressPair');
    isa_ok($cep->status->controllers->[0], 'IO::K8s::Cilium::V2::ControllerStatus');
    isa_ok($cep->status->controllers->[0]->configuration, 'IO::K8s::Cilium::V2::ControllerStatusConfiguration');
    isa_ok($cep->status->controllers->[0]->status, 'IO::K8s::Cilium::V2::ControllerStatusStatus');
    isa_ok($cep->status->log->[0], 'IO::K8s::Cilium::V2::EndpointStatusChange');
    isa_ok($cep->status->named_ports->[0], 'IO::K8s::Cilium::V2::Port');
    isa_ok($cep->status->policy, 'IO::K8s::Cilium::V2::EndpointPolicy');
    isa_ok($cep->status->policy->ingress, 'IO::K8s::Cilium::V2::EndpointPolicyDirection');
    isa_ok($cep->status->policy->ingress->allowed->[0], 'IO::K8s::Cilium::V2::IdentityTuple');

    my $json = $cep->TO_JSON;
    ok(!exists $json->{spec}, 'TO_JSON emits no spec key (upstream has none)');
    is($json->{status}{identity}{id}, 5, 'TO_JSON status.identity.id');
    is($json->{status}{policy}{ingress}{allowed}[0]{'dest-port'}, 80, 'TO_JSON deep policy.ingress.allowed dest-port');

    my $re = $k8s->inflate($k8s->object_to_json($cep));
    isa_ok($re, 'IO::K8s::Cilium::V2::CiliumEndpoint');
    is($re->status->controllers->[0]->name, 'endpoint-1234-sync-to-k8s-ciliumendpoint',
        'JSON round-trip preserves deep controller name');

    my $identity = $k8s->new_object('CiliumIdentity',
        metadata => { name => '12345' },
        'security-labels' => { 'k8s:io.kubernetes.pod.namespace' => 'default', 'k8s:app' => 'web' },
    );
    is($identity->security_labels->{'k8s:app'}, 'web', 'CiliumIdentity security-labels is a typed string map');
    is($identity->TO_JSON->{'security-labels'}{'k8s:app'}, 'web', 'TO_JSON round-trips security-labels');
};

# --- Full depth round-trip (D5, k95, task B-Cilium): cilium.io/v2alpha1 ---
# The five Kinds native to this track (the seven BGP/CIDR/LoadBalancerIPPool
# back-compat tracks share their classes with the cilium.io/v2 render
# already exercised above, so are not re-tested here).

subtest 'full depth round-trip: CiliumDatapathPlugin' => sub {
    my $k8s = IO::K8s->new(with => ['IO::K8s::Cilium']);
    my $cddp = $k8s->new_object('CiliumDatapathPlugin',
        metadata => { name => 'my-plugin' },
        spec => { attachmentPolicy => 'BestEffort', version => '1.0.0' },
    );
    isa_ok($cddp->spec, 'IO::K8s::Cilium::V2alpha1::CiliumDatapathPluginSpec');
    is($cddp->TO_JSON->{spec}{attachmentPolicy}, 'BestEffort', 'TO_JSON attachmentPolicy');
    my $re = $k8s->inflate($k8s->object_to_json($cddp));
    is($re->spec->version, '1.0.0', 'JSON round-trip preserves version');
};

subtest 'full depth round-trip: CiliumGatewayClassConfig' => sub {
    my $k8s = IO::K8s->new(with => ['IO::K8s::Cilium']);
    my $gcc = $k8s->new_object('CiliumGatewayClassConfig',
        metadata => { name => 'gw-config', namespace => 'default' },
        spec => {
            description => 'shared gateway class config',
            service     => { type => 'LoadBalancer', externalTrafficPolicy => 'Local' },
            httpOptions => { grpcWebTranslation => { enabled => 1 } },
            telemetry   => { accessLogs => [{
                format => 'JSON', targets => ['HTTP'],
                json   => { authority => '%REQUEST_HEADER(:AUTHORITY)%' },
            }] },
            envoy       => { serverHeaderTransformation => 'PASS_THROUGH' },
        },
        status => { conditions => [{
            type => 'Accepted', status => 'True', reason => 'Accepted',
            message => 'config accepted', lastTransitionTime => '2026-01-01T00:00:00Z',
        }] },
    );
    isa_ok($gcc->spec, 'IO::K8s::Cilium::V2alpha1::CiliumGatewayClassConfigSpec');
    isa_ok($gcc->spec->service, 'IO::K8s::Cilium::V2alpha1::ServiceConfig');
    isa_ok($gcc->spec->httpOptions, 'IO::K8s::Cilium::V2alpha1::HTTPOptions');
    isa_ok($gcc->spec->httpOptions->grpcWebTranslation, 'IO::K8s::Cilium::V2alpha1::GRPCWebTranslationConfig');
    isa_ok($gcc->spec->telemetry, 'IO::K8s::Cilium::V2alpha1::Telemetry');
    isa_ok($gcc->spec->telemetry->accessLogs->[0], 'IO::K8s::Cilium::V2alpha1::AccessLogs');
    isa_ok($gcc->spec->envoy, 'IO::K8s::Cilium::V2alpha1::EnvoyConfig');
    isa_ok($gcc->status, 'IO::K8s::Cilium::V2alpha1::CiliumGatewayClassConfigStatus');
    isa_ok($gcc->status->conditions->[0], 'IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::Condition');
    is($gcc->TO_JSON->{spec}{telemetry}{accessLogs}[0]{format}, 'JSON', 'TO_JSON deep telemetry.accessLogs format');

    # Full object_to_json -> inflate round-trip (k108: this used to die
    # recursing into the populated accessLogs[].json field, since that
    # field's attribute slot was the Role::Resource JSON encoder itself).
    my $re = $k8s->inflate($k8s->object_to_json($gcc));
    isa_ok($re, 'IO::K8s::Cilium::V2alpha1::CiliumGatewayClassConfig');
    is_deeply($re->spec->telemetry->accessLogs->[0]->json,
        { authority => '%REQUEST_HEADER(:AUTHORITY)%' },
        'JSON round-trip preserves deep telemetry.accessLogs.json (k108)');
};

subtest 'full depth round-trip: CiliumL2AnnouncementPolicy' => sub {
    my $k8s = IO::K8s->new(with => ['IO::K8s::Cilium']);
    my $l2 = $k8s->new_object('CiliumL2AnnouncementPolicy',
        metadata => { name => 'l2-policy' },
        spec => {
            nodeSelector    => { matchLabels => { 'l2-announce' => 'true' } },
            serviceSelector => {},
            loadBalancerIPs => 1,
            interfaces      => ['eth0', 'eth1'],
        },
    );
    isa_ok($l2->spec, 'IO::K8s::Cilium::V2alpha1::CiliumL2AnnouncementPolicySpec');
    isa_ok($l2->spec->nodeSelector, 'IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::LabelSelector');
    is_deeply($l2->spec->interfaces, ['eth0', 'eth1'], 'interfaces preserved');
    ok($l2->TO_JSON->{spec}{loadBalancerIPs}, 'TO_JSON loadBalancerIPs true');
};

subtest 'full depth round-trip: CiliumPodIPPool' => sub {
    my $k8s = IO::K8s->new(with => ['IO::K8s::Cilium']);
    my $pool = $k8s->new_object('CiliumPodIPPool',
        metadata => { name => 'ipv4-pool' },
        spec => {
            ipv4 => { cidrs => ['10.10.0.0/16'], maskSize => 24 },
            ipv6 => { cidrs => ['fd00::/104'], maskSize => 120 },
        },
    );
    isa_ok($pool->spec, 'IO::K8s::Cilium::V2alpha1::IPPoolSpec');
    isa_ok($pool->spec->ipv4, 'IO::K8s::Cilium::V2alpha1::IPv4PoolSpec');
    isa_ok($pool->spec->ipv6, 'IO::K8s::Cilium::V2alpha1::IPv6PoolSpec');
    is($pool->spec->ipv4->maskSize, 24, 'ipv4 maskSize');
    my $re = $k8s->inflate($k8s->object_to_json($pool));
    is($re->spec->ipv6->cidrs->[0], 'fd00::/104', 'JSON round-trip preserves ipv6 cidrs');
};

subtest 'full depth round-trip: CiliumEndpointSlice (no spec upstream, like CiliumEndpoint)' => sub {
    my $k8s = IO::K8s->new(with => ['IO::K8s::Cilium']);
    my $ces = $k8s->new_object('CiliumEndpointSlice',
        metadata  => { name => 'ces-abc' },
        namespace => 'default',
        endpoints => [{
            name       => 'pod-abc123',
            id         => 5,
            'pod-uid'  => 'uid-1',
            networking => { node => '10.0.0.5', addressing => [{ ipv4 => '10.1.2.3' }] },
            encryption => { key => 0 },
            'named-ports' => [{ name => 'http', port => 8080, protocol => 'TCP' }],
            'service-account' => 'default',
        }],
    );

    ok(!$ces->can('spec'), 'CiliumEndpointSlice has no spec attribute (upstream v1.20.1 declares none -- k107)');
    isa_ok($ces->endpoints->[0], 'IO::K8s::Cilium::V2alpha1::CoreCiliumEndpoint');
    isa_ok($ces->endpoints->[0]->networking, 'IO::K8s::Cilium::V2alpha1::EndpointNetworking');
    isa_ok($ces->endpoints->[0]->networking->addressing->[0], 'IO::K8s::Cilium::V2alpha1::AddressPair');
    isa_ok($ces->endpoints->[0]->encryption, 'IO::K8s::Cilium::V2alpha1::EncryptionSpec');
    isa_ok($ces->endpoints->[0]->named_ports->[0], 'IO::K8s::Cilium::V2alpha1::Port');

    my $json = $ces->TO_JSON;
    ok(!exists $json->{spec}, 'TO_JSON emits no spec key (upstream has none)');
    is($json->{endpoints}[0]{'pod-uid'}, 'uid-1', 'TO_JSON deep endpoints pod-uid (hyphenated wire key)');

    my $re = $k8s->inflate($k8s->object_to_json($ces));
    isa_ok($re, 'IO::K8s::Cilium::V2alpha1::CiliumEndpointSlice');
    is($re->endpoints->[0]->networking->addressing->[0]->ipv4, '10.1.2.3',
        'JSON round-trip preserves deep networking.addressing.ipv4');
};

subtest 'AccessLogs.json field (k108, fixed in 1.108)' => sub {
    # IO::K8s::Cilium::V2alpha1::AccessLogs (nested under
    # CiliumGatewayClassConfig.spec.telemetry.accessLogs[]) is the one class
    # in the whole registry with a real upstream field literally named
    # `json` (Envoy access-log format spec, map[string]string). Before
    # 1.108 this collided with IO::K8s::Role::Resource's own internal JSON
    # encoder attribute (also named `json`): Resource.pm's _k8s() skips
    # creating a second attribute when the class already can($attr_name),
    # so the field's attribute slot WAS the encoder, and to_json()/to_yaml()
    # died on every AccessLogs instance, populated or not. Fixed by
    # renaming the role's internal encoder attribute to `_json_encoder`,
    # freeing `json` for this real upstream field. See karr #108.
    my $al = IO::K8s::Cilium::V2alpha1::AccessLogs->new(
        format  => 'JSON',
        json    => { authority => '%REQUEST_HEADER(:AUTHORITY)%' },
        targets => ['HTTP'],
        text    => 'unused-in-json-format',
    );
    my $json = eval { $al->to_json };
    ok(!$@, 'to_json does not die with AccessLogs.json set (k108)')
        or diag("died: $@");
    like($json, qr/"json":\{"authority":"%REQUEST_HEADER\(:AUTHORITY\)%"\}/,
        'to_json emits the json field value, not the encoder');

    my $yaml = eval { $al->to_yaml };
    ok(!$@, 'to_yaml does not die with AccessLogs.json set (k108)')
        or diag("died: $@");

    my $re = eval { IO::K8s::Cilium::V2alpha1::AccessLogs->from_json($json) };
    ok(!$@, 'from_json round-trip does not die') or diag("died: $@");
    is_deeply($re->json, { authority => '%REQUEST_HEADER(:AUTHORITY)%' },
        'round-trip preserves the json field value');

    # A bare instance (json field left unset) also used to die -- TO_JSON
    # read the encoder object back unconditionally regardless of whether
    # the field was ever populated.
    my $bare = IO::K8s::Cilium::V2alpha1::AccessLogs->new(format => 'JSON');
    my $bare_json = eval { $bare->to_json };
    ok(!$@, 'to_json does not die on a bare AccessLogs instance (k108)')
        or diag("died: $@");
};

done_testing;
