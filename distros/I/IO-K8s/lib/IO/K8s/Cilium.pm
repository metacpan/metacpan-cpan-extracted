package IO::K8s::Cilium;
# ABSTRACT: Cilium CRD resource map provider for IO::K8s
our $VERSION = '1.108';
use Moo;
with 'IO::K8s::Role::ResourceMap';

sub upstream_version { 'v1.20.1' }  # cilium/cilium

# Upstream CRD manifests for the pinned upstream_version, consumed by
# maint/crd-drift-check.pl. Data only -- no fetching happens here. `base`
# + each `files` entry is the raw manifest URL; the checker caches each
# under spec/crd/Cilium/ (path separators flattened to '_').
sub crd_sources {
    my $v = __PACKAGE__->upstream_version;
    return {
        status => 'ok',
        base   => "https://raw.githubusercontent.com/cilium/cilium/$v/pkg/k8s/apis/cilium.io/client/crds",
        files  => [
            # cilium.io/v2
            'v2/ciliumbgpadvertisements.yaml',
            'v2/ciliumbgpclusterconfigs.yaml',
            'v2/ciliumbgpnodeconfigoverrides.yaml',
            'v2/ciliumbgpnodeconfigs.yaml',
            'v2/ciliumbgppeerconfigs.yaml',
            'v2/ciliumcidrgroups.yaml',
            'v2/ciliumclusterwideenvoyconfigs.yaml',
            'v2/ciliumclusterwidenetworkpolicies.yaml',
            'v2/ciliumegressgatewaypolicies.yaml',
            'v2/ciliumendpoints.yaml',
            'v2/ciliumenvoyconfigs.yaml',
            'v2/ciliumidentities.yaml',
            'v2/ciliumloadbalancerippools.yaml',
            'v2/ciliumlocalredirectpolicies.yaml',
            'v2/ciliumnetworkpolicies.yaml',
            'v2/ciliumnodeconfigs.yaml',
            'v2/ciliumnodes.yaml',
            # cilium.io/v2alpha1
            'v2alpha1/ciliumdatapathplugins.yaml',
            'v2alpha1/ciliumendpointslices.yaml',
            'v2alpha1/ciliumgatewayclassconfigs.yaml',
            'v2alpha1/ciliuml2announcementpolicies.yaml',
            'v2alpha1/ciliumpodippools.yaml',
        ],
    };
}

sub resource_map {
    return {
        # cilium.io/v2
        CiliumNetworkPolicy            => 'Cilium::V2::CiliumNetworkPolicy',
        CiliumClusterwideNetworkPolicy => 'Cilium::V2::CiliumClusterwideNetworkPolicy',
        CiliumLocalRedirectPolicy      => 'Cilium::V2::CiliumLocalRedirectPolicy',
        CiliumEgressGatewayPolicy      => 'Cilium::V2::CiliumEgressGatewayPolicy',
        CiliumIdentity                 => 'Cilium::V2::CiliumIdentity',
        CiliumEndpoint                 => 'Cilium::V2::CiliumEndpoint',
        CiliumNode                     => 'Cilium::V2::CiliumNode',
        CiliumNodeConfig               => 'Cilium::V2::CiliumNodeConfig',
        CiliumLoadBalancerIPPool       => 'Cilium::V2::CiliumLoadBalancerIPPool',
        CiliumEnvoyConfig              => 'Cilium::V2::CiliumEnvoyConfig',
        CiliumClusterwideEnvoyConfig   => 'Cilium::V2::CiliumClusterwideEnvoyConfig',
        CiliumCIDRGroup                => 'Cilium::V2::CiliumCIDRGroup',
        CiliumBGPClusterConfig         => 'Cilium::V2::CiliumBGPClusterConfig',
        CiliumBGPPeerConfig            => 'Cilium::V2::CiliumBGPPeerConfig',
        CiliumBGPAdvertisement         => 'Cilium::V2::CiliumBGPAdvertisement',
        CiliumBGPNodeConfig            => 'Cilium::V2::CiliumBGPNodeConfig',
        CiliumBGPNodeConfigOverride    => 'Cilium::V2::CiliumBGPNodeConfigOverride',
        # cilium.io/v2alpha1
        CiliumEndpointSlice            => 'Cilium::V2alpha1::CiliumEndpointSlice',
        CiliumL2AnnouncementPolicy     => 'Cilium::V2alpha1::CiliumL2AnnouncementPolicy',
        CiliumGatewayClassConfig       => 'Cilium::V2alpha1::CiliumGatewayClassConfig',
        CiliumPodIPPool                => 'Cilium::V2alpha1::CiliumPodIPPool',
        CiliumDatapathPlugin           => 'Cilium::V2alpha1::CiliumDatapathPlugin',
        # cilium.io/v2alpha1 back-compat for clusters still on older Cilium
        # releases (k78, k83): the v2alpha1 tracks of BGP/CIDR/LB Kinds were
        # superseded by the matching v2 classes (short names above), and two
        # Kinds were removed (CiliumBGPPeeringPolicy, CiliumExternalWorkload).
        # Each shipped class is reachable only via its domain-qualified key
        # so the short name keeps resolving to the storage version.
        'cilium.io/v2alpha1/CiliumBGPAdvertisement'      => 'Cilium::V2alpha1::CiliumBGPAdvertisement',
        'cilium.io/v2alpha1/CiliumBGPClusterConfig'      => 'Cilium::V2alpha1::CiliumBGPClusterConfig',
        'cilium.io/v2alpha1/CiliumBGPNodeConfig'         => 'Cilium::V2alpha1::CiliumBGPNodeConfig',
        'cilium.io/v2alpha1/CiliumBGPNodeConfigOverride' => 'Cilium::V2alpha1::CiliumBGPNodeConfigOverride',
        'cilium.io/v2alpha1/CiliumBGPPeerConfig'         => 'Cilium::V2alpha1::CiliumBGPPeerConfig',
        'cilium.io/v2alpha1/CiliumCIDRGroup'             => 'Cilium::V2alpha1::CiliumCIDRGroup',
        'cilium.io/v2alpha1/CiliumLoadBalancerIPPool'    => 'Cilium::V2alpha1::CiliumLoadBalancerIPPool',
        'cilium.io/v2alpha1/CiliumBGPPeeringPolicy'      => 'Cilium::V2alpha1::CiliumBGPPeeringPolicy',
        'cilium.io/v2/CiliumExternalWorkload'            => 'Cilium::V2::CiliumExternalWorkload',
    };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Cilium - Cilium CRD resource map provider for IO::K8s

=head1 VERSION

version 1.108

=head1 SYNOPSIS

    my $k8s = IO::K8s->new(with => ['IO::K8s::Cilium']);

    my $cnp = $k8s->new_object('CiliumNetworkPolicy',
        metadata => { name => 'allow-dns', namespace => 'kube-system' },
        spec => { endpointSelector => {} },
    );

    print $cnp->to_yaml;

=head1 DESCRIPTION

Resource map provider for L<Cilium|https://cilium.io/> Custom Resource
Definitions. Registers 31 resource_map entries (22 short-name keys plus 9
domain-qualified back-compat keys for v2alpha1 BGP/CIDR/LB tracks and
CiliumExternalWorkload) covering C<cilium.io/v2> and C<cilium.io/v2alpha1>,
matching upstream Cilium v1.20.1.

C<cilium.io/v2> is modeled to full depth: every Kind's C<spec> (and, where
upstream declares one, C<status>) is a typed object graph of further
C<IO::K8s::Cilium::V2::*> classes, one per upstream Go structure, named
after the upstream Go types (L<IO::K8s::Cilium::V2::CiliumNetworkPolicy>'s
C<spec> is an L<IO::K8s::Cilium::V2::Rule>, whose C<egress> is an array of
L<IO::K8s::Cilium::V2::EgressRule>, and so on down) rather than an opaque
hashref — 17 Kinds, 121 further classes. Embedded core types
(C<Meta::V1::LabelSelector>, C<Core::V1::NamespaceCondition>, ...) are
referenced, not re-modeled. C<policy/api.Rule> — the shared policy engine
struct upstream embeds literally the same in both C<CiliumNetworkPolicy> and
C<CiliumClusterwideNetworkPolicy>, at both their C<spec> (one C<Rule>) and
C<specs> (C<Rule[]>) fields — is one shared
L<IO::K8s::Cilium::V2::Rule|IO::K8s::Cilium::V2::Rule> class, not a copy per
Kind. C<CiliumEndpoint> and C<CiliumIdentity> are the two Kinds with no
C<spec> field upstream at all — C<CiliumEndpoint>'s C<status> is still fully
typed (L<IO::K8s::Cilium::V2::EndpointStatus>), C<CiliumIdentity>'s
C<security-labels> is a genuine free-form string map upstream (no per-key
schema to model further).

C<cilium.io/v2alpha1> is modeled to full depth the same way -- 12 Kinds
(the five v2alpha1-only Kinds plus the seven BGP/CIDR/LoadBalancerIPPool
back-compat tracks, which share the very C<kinds.E<lt>KindE<gt>> overlay
entry the C<cilium.io/v2> render of the same Kind uses -- the version
directory alone disambiguates, so a Go type is never accidentally shared
I<across> C<v2>/C<v2alpha1>), under C<IO::K8s::Cilium::V2alpha1::*>.
C<CiliumEndpointSlice> is the third and last Kind with no C<spec> field
upstream; its C<endpoints> is still fully typed
(L<IO::K8s::Cilium::V2alpha1::CoreCiliumEndpoint>).

B<Fixed in 1.108 (karr #108):> L<IO::K8s::Cilium::V2alpha1::AccessLogs>
(nested under C<CiliumGatewayClassConfig>'s
C<spec.telemetry.accessLogs[]>) has a real upstream field literally named
C<json>, which used to collide with L<IO::K8s::Role::Resource>'s own
internal JSON-encoder attribute (previously also named C<json>). The role's
encoder attribute is now private (C<_json_encoder>), so C<to_json>/
C<to_yaml> work normally on C<AccessLogs> and any parent recursing into a
populated C<accessLogs[]>.

Not loaded by default — opt in via the C<with> constructor parameter of
L<IO::K8s> or by calling C<< $k8s->add('IO::K8s::Cilium') >> at runtime.

=head2 Included CRDs (cilium.io/v2)

=over 4

=item * C<CiliumNetworkPolicy> -- a Kubernetes third-party resource with an extended
version of C<NetworkPolicy>, adding L3-L7 rules the base Kubernetes API can't express.

=item * C<CiliumClusterwideNetworkPolicy> -- a modified version of
C<CiliumNetworkPolicy> which is cluster-scoped rather than namespace-scoped, and adds
node-selector-based rules.

=item * C<CiliumLocalRedirectPolicy> -- redirects pod traffic destined to an IP:port/
protocol tuple, or to a Kubernetes Service, to backend pod(s) local to the same node,
using eBPF.

=item * C<CiliumEgressGatewayPolicy> -- routes egress traffic from selected pods
through a designated gateway node so cluster-external destinations see a predictable,
SNAT'd egress IP.

=item * C<CiliumIdentity> -- represents a security identity managed by Cilium: the
numeric ID its policy engine assigns to a set of endpoint labels.

=item * C<CiliumEndpoint> -- the runtime status of a Cilium-managed endpoint (pod):
identity, networking and policy enforcement state. Has no C<spec> upstream at all --
see below.

=item * C<CiliumNode> -- represents a node managed by Cilium: per-node IPAM and
networking state the agent and operator maintain.

=item * C<CiliumNodeConfig> -- a list of per-node configuration key/value overrides
layered on top of the cluster-wide Cilium ConfigMap for a selected set of nodes.

=item * C<CiliumLoadBalancerIPPool> -- defines pools of IPs the Cilium operator can
allocate and advertise for Services of type C<LoadBalancer>, filling the gap when no
cloud provider load-balancer is available.

=item * C<CiliumEnvoyConfig> -- namespaced Envoy xDS configuration Cilium's embedded
Envoy proxy uses for L7 traffic management on selected Services.

=item * C<CiliumClusterwideEnvoyConfig> -- the cluster-scoped counterpart of
C<CiliumEnvoyConfig>.

=item * C<CiliumCIDRGroup> -- a named list of external CIDRs (peers outside the
cluster) that can be referenced as a single entity from C<CiliumNetworkPolicy> and
C<CiliumClusterwideNetworkPolicy> rules.

=item * C<CiliumBGPClusterConfig> -- cluster-wide BGP Control Plane configuration: one
or more virtual-router "instances" and the node selector choosing which nodes run them.

=item * C<CiliumBGPPeerConfig> -- reusable BGP peer configuration (timers, graceful
restart, address families, ...), referenced by name from a peer entry in a
C<CiliumBGPClusterConfig>.

=item * C<CiliumBGPAdvertisement> -- declares which routes (Service VIPs, Pod CIDRs,
...) a BGP instance advertises, and under what attributes.

=item * C<CiliumBGPNodeConfig> -- per-node BGP Control Plane state, derived
automatically by the operator from a C<CiliumBGPClusterConfig>'s node selector: one per
selected node.

=item * C<CiliumBGPNodeConfigOverride> -- manual, per-node overrides layered on top of
a node's derived C<CiliumBGPNodeConfig>.

=back

=head2 Included CRDs (cilium.io/v2alpha1)

=over 4

=item * C<CiliumEndpointSlice> -- batches many C<CiliumEndpoint> objects into one
resource to reduce per-endpoint API server load in large clusters. Has no C<spec>
upstream at all -- see above.

=item * C<CiliumL2AnnouncementPolicy> -- fine-grained control over which Services are
announced over L2 (ARP/NDP), from which nodes and which network interfaces.

=item * C<CiliumGatewayClassConfig> -- referenced from a Gateway API C<GatewayClass>'s
C<parametersRef> to customize Cilium's own Gateway API controller behaviour.

=item * C<CiliumPodIPPool> -- defines a cluster-wide CIDR pool used in multi-pool IPAM
mode, from which per-node Pod CIDRs are allocated based on workload/node labels.

=item * C<CiliumDatapathPlugin> -- registers an external datapath plugin with Cilium
and reports its status; creating, updating or deleting one triggers a full datapath
reinitialization.

=back

=head2 Back-compat CRDs (older Cilium releases)

Reachable only via their domain-qualified C<resource_map> key (never a bare short
name), for clusters that have not yet upgraded past the Cilium release where each was
superseded or removed (k78, k83):

=over 4

=item * C<cilium.io/v2alpha1/CiliumBGPAdvertisement>,
C<cilium.io/v2alpha1/CiliumBGPClusterConfig>,
C<cilium.io/v2alpha1/CiliumBGPNodeConfig>,
C<cilium.io/v2alpha1/CiliumBGPNodeConfigOverride>,
C<cilium.io/v2alpha1/CiliumBGPPeerConfig>,
C<cilium.io/v2alpha1/CiliumCIDRGroup>,
C<cilium.io/v2alpha1/CiliumLoadBalancerIPPool> -- the same BGP/CIDR/LoadBalancerIPPool
Kinds described above under C<cilium.io/v2>, at the older C<v2alpha1> API group version
those Kinds shipped at before being promoted.

=item * C<cilium.io/v2alpha1/CiliumBGPPeeringPolicy> -- the pre-BGP-Control-Plane-v2
Kind for configuring BGP peering, superseded by the
C<CiliumBGPClusterConfig>/C<CiliumBGPPeerConfig>/C<CiliumBGPAdvertisement>/
C<CiliumBGPNodeConfig> split above and removed from newer Cilium releases.

=item * C<cilium.io/v2/CiliumExternalWorkload> -- represented a non-Kubernetes workload
(e.g. a VM) joined to the cluster mesh. The external-workloads feature itself was
removed from Cilium at v1.18, ahead of this provider's pinned v1.20.1.

=back

=head1 SEE ALSO

L<IO::K8s>

L<Cilium documentation|https://docs.cilium.io/>

L<Cilium CRD reference|https://docs.cilium.io/en/stable/network/kubernetes/policy/>

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/pplu/io-k8s-p5/issues>.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHORS

=over 4

=item *

Torsten Raudssus <getty@cpan.org>

=item *

Jose Luis Martinez Torres <jlmartin@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018-2026 by Jose Luis Martinez Torres <jlmartin@cpan.org>.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
