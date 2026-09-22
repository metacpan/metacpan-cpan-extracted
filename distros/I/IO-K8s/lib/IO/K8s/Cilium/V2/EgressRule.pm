package IO::K8s::Cilium::V2::EgressRule;
# ABSTRACT: EgressRule contains all rule types which can be applied at egress, i.e.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s authentication => '+IO::K8s::Cilium::V2::Authentication';
k8s icmps          => ['+IO::K8s::Cilium::V2::ICMPRule'];
k8s toCIDR         => [Str];
k8s toCIDRSet      => ['+IO::K8s::Cilium::V2::CIDRRule'];
k8s toEndpoints    => ['Meta::V1::LabelSelector'];
k8s toEntities     => [Str], { enum => [qw(all world cluster cluster-mesh host init ingress unmanaged remote-node health none kube-apiserver)] };
k8s toFQDNs        => ['+IO::K8s::Cilium::V2::FQDNSelector'];
k8s toGroups       => ['+IO::K8s::Cilium::V2::Groups'];
k8s toNodes        => ['Meta::V1::LabelSelector'];
k8s toPorts        => ['+IO::K8s::Cilium::V2::PortRule'];
k8s toRequires     => [Str];
k8s toServices     => ['+IO::K8s::Cilium::V2::Service'];













1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Cilium::V2::EgressRule - EgressRule contains all rule types which can be applied at egress, i.e.

=head1 VERSION

version 1.108

=head2 authentication

Authentication is the required authentication type for the allowed traffic, if any.

=head2 icmps

ICMPs is a list of ICMP rule identified by type number
which the endpoint subject to the rule is allowed to connect to.

Example:
Any endpoint with the label "app=httpd" is allowed to initiate
type 8 ICMP connections.

=head2 toCIDR

ToCIDR is a list of IP blocks which the endpoint subject to the rule
is allowed to initiate connections. Only connections destined for
outside of the cluster and not targeting the host will be subject
to CIDR rules.  This will match on the destination IP address of
outgoing connections. Adding a prefix into ToCIDR or into ToCIDRSet
with no ExcludeCIDRs is equivalent. Overlaps are allowed between
ToCIDR and ToCIDRSet.

Example:
Any endpoint with the label "app=database-proxy" is allowed to
initiate connections to 10.2.3.0/24

=head2 toCIDRSet

ToCIDRSet is a list of IP blocks which the endpoint subject to the rule
is allowed to initiate connections to in addition to connections
which are allowed via ToEndpoints, along with a list of subnets contained
within their corresponding IP block to which traffic should not be
allowed. This will match on the destination IP address of outgoing
connections. Adding a prefix into ToCIDR or into ToCIDRSet with no
ExcludeCIDRs is equivalent. Overlaps are allowed between ToCIDR and
ToCIDRSet.

Example:
Any endpoint with the label "app=database-proxy" is allowed to
initiate connections to 10.2.3.0/24 except from IPs in subnet 10.2.3.0/28.

=head2 toEndpoints

ToEndpoints is a list of endpoints identified by an EndpointSelector to
which the endpoints subject to the rule are allowed to communicate.

Example:
Any endpoint with the label "role=frontend" can communicate with any
endpoint carrying the label "role=backend".

Note that while an empty non-nil ToEndpoints does not select anything,
nil ToEndpoints is implicitly treated as a wildcard selector if ToPorts
are also specified.
To select everything, use one EndpointSelector without any match requirements.

=head2 toEntities

ToEntities is a list of special entities to which the endpoint subject
to the rule is allowed to initiate connections. Supported entities are
`world`, `cluster`, `cluster-mesh`, `host`, `remote-node`, `kube-apiserver`, `ingress`, `init`,
`health`, `unmanaged`, `none` and `all`.

=head2 toFQDNs

ToFQDN allows whitelisting DNS names in place of IPs. The IPs that result
from DNS resolution of `ToFQDN.MatchName`s are added to the same
EgressRule object as ToCIDRSet entries, and behave accordingly. Any L4 and
L7 rules within this EgressRule will also apply to these IPs.
The DNS -> IP mapping is re-resolved periodically from within the
cilium-agent, and the IPs in the DNS response are effected in the policy
for selected pods as-is (i.e. the list of IPs is not modified in any way).
Note: An explicit rule to allow for DNS traffic is needed for the pods, as
ToFQDN counts as an egress rule and will enforce egress policy when
PolicyEnforcment=default.
Note: If the resolved IPs are IPs within the kubernetes cluster, the
ToFQDN rule will not apply to that IP.
Note: ToFQDN cannot occur in the same policy as other To* rules.

=head2 toGroups

ToGroups allows policies to reference CIDRs provided by external integrations.
Currently, only AWS is supported, and the rule can select by multiple sub directives.
ToGroups entries are functionally equivalent to toCIDR, and have the same
limitiations. They cannot select traffic originating from within the cluster.

Example:
toGroups:
- aws:
    securityGroupsIds:
    - 'sg-XXXXXXXXXXXXX'

=head2 toNodes

ToNodes is a list of nodes identified by an
EndpointSelector to which endpoints subject to the rule is allowed to communicate.

=head2 toPorts

ToPorts is a list of destination ports identified by port number and
protocol which the endpoint subject to the rule is allowed to
connect to.

Example:
Any endpoint with the label "role=frontend" is allowed to initiate
connections to destination port 8080/tcp

=head2 toRequires

Deprecated.

=head2 toServices

ToServices is a list of services to which the endpoint subject
to the rule is allowed to initiate connections.
Currently Cilium only supports toServices for K8s services.

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
