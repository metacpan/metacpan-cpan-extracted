package IO::K8s::Cilium::V2::IPAMStatus;
# ABSTRACT: IPAM is the IPAM status of the node.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s 'assigned-static-ip' => Str;
k8s 'ipv6-used'          => { '+IO::K8s::Cilium::V2::AllocationIP' => 1 };
k8s 'operator-status'    => '+IO::K8s::Cilium::V2::OperatorStatus';
k8s 'pod-cidrs'          => { '+IO::K8s::Cilium::V2::PodCIDRMapEntry' => 1 };
k8s 'release-ips'        => { Str => 1 };
k8s 'release-ipv6s'      => { Str => 1 };
k8s used                 => { '+IO::K8s::Cilium::V2::AllocationIP' => 1 };








1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Cilium::V2::IPAMStatus - IPAM is the IPAM status of the node.

=head1 VERSION

version 1.108

=head2 assigned-static-ip

AssignedStaticIP is the static IP assigned to the node (ex: public Elastic IP address in AWS)

=head2 ipv6-used

IPv6Used lists all IPv6 addresses out of Spec.IPAM.IPv6Pool which have been
allocated and are in use.

=head2 operator-status

Operator is the Operator status of the node

=head2 pod-cidrs

PodCIDRs lists the status of each pod CIDR allocated to this node.

=head2 release-ips

ReleaseIPs tracks the state for every IPv4 address considered for release.
The value can be one of the following strings:
* marked-for-release : Set by operator as possible candidate for IP
* ready-for-release  : Acknowledged as safe to release by agent
* do-not-release     : IP already in use / not owned by the node. Set by agent
* released           : IP successfully released. Set by operator

=head2 release-ipv6s

ReleaseIPv6s tracks the state for every IPv6 address considered for release.
The value can be one of the following strings:
* marked-for-release : Set by operator as possible candidate for IP
* ready-for-release  : Acknowledged as safe to release by agent
* do-not-release     : IP already in use / not owned by the node. Set by agent
* released           : IP successfully released. Set by operator

=head2 used

Used lists all IPv4 addresses out of Spec.IPAM.Pool which have been allocated
and are in use.

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
