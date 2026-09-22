package IO::K8s::Cilium::V2::IngressDenyRule;
# ABSTRACT: IngressDenyRule contains all rule types which can be applied at ingress, i.e.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s fromCIDR      => [Str];
k8s fromCIDRSet   => ['+IO::K8s::Cilium::V2::CIDRRule'];
k8s fromEndpoints => ['Meta::V1::LabelSelector'];
k8s fromEntities  => [Str], { enum => [qw(all world cluster cluster-mesh host init ingress unmanaged remote-node health none kube-apiserver)] };
k8s fromGroups    => ['+IO::K8s::Cilium::V2::Groups'];
k8s fromNodes     => ['Meta::V1::LabelSelector'];
k8s fromRequires  => [Str];
k8s icmps         => ['+IO::K8s::Cilium::V2::ICMPRule'];
k8s toPorts       => ['+IO::K8s::Cilium::V2::PortDenyRule'];










1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Cilium::V2::IngressDenyRule - IngressDenyRule contains all rule types which can be applied at ingress, i.e.

=head1 VERSION

version 1.108

=head2 fromCIDR

FromCIDR is a list of IP blocks which the endpoint subject to the
rule is allowed to receive connections from. Only connections which
do *not* originate from the cluster or from the local host are subject
to CIDR rules. In order to allow in-cluster connectivity, use the
FromEndpoints field.  This will match on the source IP address of
incoming connections. Adding  a prefix into FromCIDR or into
FromCIDRSet with no ExcludeCIDRs is  equivalent.  Overlaps are
allowed between FromCIDR and FromCIDRSet.

Example:
Any endpoint with the label "app=my-legacy-pet" is allowed to receive
connections from 10.3.9.1

=head2 fromCIDRSet

FromCIDRSet is a list of IP blocks which the endpoint subject to the
rule is allowed to receive connections from in addition to FromEndpoints,
along with a list of subnets contained within their corresponding IP block
from which traffic should not be allowed.
This will match on the source IP address of incoming connections. Adding
a prefix into FromCIDR or into FromCIDRSet with no ExcludeCIDRs is
equivalent. Overlaps are allowed between FromCIDR and FromCIDRSet.

Example:
Any endpoint with the label "app=my-legacy-pet" is allowed to receive
connections from 10.0.0.0/8 except from IPs in subnet 10.96.0.0/12.

=head2 fromEndpoints

FromEndpoints is a list of endpoints identified by an
EndpointSelector which are allowed to communicate with the endpoint
subject to the rule.

Example:
Any endpoint with the label "role=backend" can be consumed by any
endpoint carrying the label "role=frontend".

Note that while an empty non-nil FromEndpoints does not select anything,
nil FromEndpoints is implicitly treated as a wildcard selector if ToPorts
are also specified.
To select everything, use one EndpointSelector without any match requirements.

=head2 fromEntities

FromEntities is a list of special entities which the endpoint subject
to the rule is allowed to receive connections from. Supported entities are
`world`, `cluster`, `cluster-mesh`, `host`, `remote-node`, `kube-apiserver`, `ingress`, `init`,
`health`, `unmanaged`, `none` and `all`.

=head2 fromGroups

FromGroups allows policies to reference CIDRs provided by external integrations.
Currently, only AWS is supported, and the rule can select by multiple sub directives.
FromGroups entries are functionally equivalent to FromCIDR, and have the same
limitiations. They cannot select traffic originating from within the cluster.

Example:
fromGroups:
- aws:
    securityGroupsIds:
    - 'sg-XXXXXXXXXXXXX'

=head2 fromNodes

FromNodes is a list of nodes identified by an
EndpointSelector which are allowed to communicate with the endpoint
subject to the rule.

=head2 fromRequires

Deprecated.

=head2 icmps

ICMPs is a list of ICMP rule identified by type number
which the endpoint subject to the rule is not allowed to
receive connections on.

Example:
Any endpoint with the label "app=httpd" can not accept incoming
type 8 ICMP connections.

=head2 toPorts

ToPorts is a list of destination ports identified by port number and
protocol which the endpoint subject to the rule is not allowed to
receive connections on.

Example:
Any endpoint with the label "app=httpd" can not accept incoming
connections on port 80/tcp.

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
