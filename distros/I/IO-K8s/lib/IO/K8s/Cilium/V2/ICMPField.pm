package IO::K8s::Cilium::V2::ICMPField;
# ABSTRACT: ICMPField is a ICMP field.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s family => Str, { enum => [qw(IPv4 IPv6)], default => 'IPv4' };
k8s type   => IntOrStr, { required => 'schema', pattern => qr/^([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5]|EchoReply|DestinationUnreachable|Redirect|Echo|RouterAdvertisement|RouterSelection|TimeExceeded|ParameterProblem|Timestamp|TimestampReply|Photuris|ExtendedEchoRequest|ExtendedEcho Reply|PacketTooBig|ParameterProblem|EchoRequest|MulticastListenerQuery|MulticastListenerReport|MulticastListenerDone|RouterSolicitation|RouterAdvertisement|NeighborSolicitation|NeighborAdvertisement|RedirectMessage|RouterRenumbering|ICMPNodeInformationQuery|ICMPNodeInformationResponse|InverseNeighborDiscoverySolicitation|InverseNeighborDiscoveryAdvertisement|HomeAgentAddressDiscoveryRequest|HomeAgentAddressDiscoveryReply|MobilePrefixSolicitation|MobilePrefixAdvertisement|DuplicateAddressRequestCodeSuffix|DuplicateAddressConfirmationCodeSuffix)$/ };



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Cilium::V2::ICMPField - ICMPField is a ICMP field.

=head1 VERSION

version 1.108

=head2 family

Family is a IP address version.
Currently, we support `IPv4` and `IPv6`.
`IPv4` is set as default.

=head2 type

Type is a ICMP-type.
It should be an 8bit code (0-255), or it's CamelCase name (for example, "EchoReply").
Allowed ICMP types are:
    Ipv4: EchoReply | DestinationUnreachable | Redirect | Echo | EchoRequest |
		     RouterAdvertisement | RouterSelection | TimeExceeded | ParameterProblem |
			 Timestamp | TimestampReply | Photuris | ExtendedEcho Request | ExtendedEcho Reply
    Ipv6: DestinationUnreachable | PacketTooBig | TimeExceeded | ParameterProblem |
			 EchoRequest | EchoReply | MulticastListenerQuery| MulticastListenerReport |
			 MulticastListenerDone | RouterSolicitation | RouterAdvertisement | NeighborSolicitation |
			 NeighborAdvertisement | RedirectMessage | RouterRenumbering | ICMPNodeInformationQuery |
			 ICMPNodeInformationResponse | InverseNeighborDiscoverySolicitation | InverseNeighborDiscoveryAdvertisement |
			 HomeAgentAddressDiscoveryRequest | HomeAgentAddressDiscoveryReply | MobilePrefixSolicitation |
			 MobilePrefixAdvertisement | DuplicateAddressRequestCodeSuffix | DuplicateAddressConfirmationCodeSuffix |
			 ExtendedEchoRequest | ExtendedEchoReply

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
