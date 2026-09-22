package IO::K8s::Cilium::V2::IPAMSpec;
# ABSTRACT: IPAM is the address management specification.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s 'ipv6-pool'           => { '+IO::K8s::Cilium::V2::AllocationIP' => 1 };
k8s 'max-above-watermark' => Int, { minimum => 0 };
k8s 'max-allocate'        => Int, { minimum => 0 };
k8s 'min-allocate'        => Int, { minimum => 0 };
k8s podCIDRs              => [Str];
k8s pool                  => { '+IO::K8s::Cilium::V2::AllocationIP' => 1 };
k8s pools                 => '+IO::K8s::Cilium::V2::IPAMPoolSpec';
k8s 'pre-allocate'        => Int, { minimum => 0 };
k8s 'static-ip-tags'      => { Str => 1 };










1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Cilium::V2::IPAMSpec - IPAM is the address management specification.

=head1 VERSION

version 1.108

=head2 ipv6-pool

IPv6Pool is the list of IPv6 addresses available to the node for allocation.
When an IPv6 address is used, it will remain on this list but will be added to
Status.IPAM.IPv6Used

=head2 max-above-watermark

MaxAboveWatermark is the maximum number of addresses to allocate
beyond the addresses needed to reach the PreAllocate watermark.
Going above the watermark can help reduce the number of API calls to
allocate IPs, e.g. when a new ENI is allocated, as many secondary
IPs as possible are allocated. Limiting the amount can help reduce
waste of IPs.

=head2 max-allocate

MaxAllocate is the maximum number of IPs that can be allocated to the
node. When the current amount of allocated IPs will approach this value,
the considered value for PreAllocate will decrease down to 0 in order to
not attempt to allocate more addresses than defined.

=head2 min-allocate

MinAllocate is the minimum number of IPs that must be allocated when
the node is first bootstrapped. It defines the minimum base socket
of addresses that must be available. After reaching this watermark,
the PreAllocate and MaxAboveWatermark logic takes over to continue
allocating IPs.

=head2 podCIDRs

PodCIDRs is the list of CIDRs available to the node for allocation.
When an IP is used, the IP will be added to Status.IPAM.Used

=head2 pool

Pool is the list of IPv4 addresses available to the node for allocation.
When an IPv4 address is used, it will remain on this list but will be added to
Status.IPAM.Used

=head2 pools

Pools contains the list of assigned IPAM pools for this node.

=head2 pre-allocate

PreAllocate defines the number of IP addresses that must be
available for allocation in the IPAMSpec. It defines the buffer of
addresses available immediately without requiring cilium-operator to
get involved.

=head2 static-ip-tags

StaticIPTags are used to determine the pool of IPs from which to
attribute a static IP to the node. For example in AWS this is used to
filter Elastic IP Addresses.

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
