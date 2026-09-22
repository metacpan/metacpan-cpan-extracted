package IO::K8s::Cilium::V2::CiliumBGPNodePeerStatus;
# ABSTRACT: CiliumBGPNodePeerStatus is the status of a BGP peer.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s establishedTime => Str;
k8s name            => Str, { required => 'schema' };
k8s peerASN         => Int;
k8s peerAddress     => Str, { required => 'schema' };
k8s peeringState    => Str;
k8s routeCount      => ['+IO::K8s::Cilium::V2::BGPFamilyRouteCount'];
k8s timers          => '+IO::K8s::Cilium::V2::CiliumBGPTimersState';








1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Cilium::V2::CiliumBGPNodePeerStatus - CiliumBGPNodePeerStatus is the status of a BGP peer.

=head1 VERSION

version 1.108

=head2 establishedTime

EstablishedTime is the time when the peering session was established.
It is represented in RFC3339 form and is in UTC.

=head2 name

Name is the name of the BGP peer.

=head2 peerASN

PeerASN is the ASN of the neighbor.

=head2 peerAddress

PeerAddress is the IP address of the neighbor.

=head2 peeringState

PeeringState is last known state of the peering session.

=head2 routeCount

RouteCount is the number of routes exchanged with this peer per AFI/SAFI.

=head2 timers

Timers is the state of the negotiated BGP timers for this peer.

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
