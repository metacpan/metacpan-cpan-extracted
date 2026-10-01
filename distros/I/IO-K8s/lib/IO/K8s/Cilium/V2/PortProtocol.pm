package IO::K8s::Cilium::V2::PortProtocol;
# ABSTRACT: PortProtocol specifies an L4 port with an optional transport protocol
our $VERSION = '1.109';
use IO::K8s::Resource;

k8s endPort  => Int, { minimum => 0, maximum => 65535 };
k8s port     => Str, { pattern => qr/^(6553[0-5]|655[0-2][0-9]|65[0-4][0-9]{2}|6[0-4][0-9]{3}|[1-5][0-9]{4}|[0-9]{1,4})|([a-zA-Z0-9]-?)*[a-zA-Z](-?[a-zA-Z0-9])*$/ };
k8s protocol => Str, { enum => [qw(TCP UDP SCTP VRRP IGMP GRE IPIP IPV6 ESP AH ANY)] };




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Cilium::V2::PortProtocol - PortProtocol specifies an L4 port with an optional transport protocol

=head1 VERSION

version 1.109

=head2 endPort

EndPort can only be an L4 port number.

=head2 port

Port can be an L4 port number, or a name in the form of "http"
or "http-8080".

=head2 protocol

Protocol is the L4 protocol. If "ANY", omitted or empty, any protocols
with transport ports (TCP, UDP, SCTP) match.

Accepted values: "TCP", "UDP", "SCTP", "VRRP", "IGMP", "GRE", "IPIP",
"IPV6", "ESP", "AH", "ANY"

Tunnel/encapsulation protocols (GRE, IPIP, IPV6, ESP, AH) and other
extended IP protocols (VRRP, IGMP) require the --enable-extended-ip-protocols
flag to be set. These protocols do not use transport-layer ports.

Matching on ICMP is not supported.

Named port specified for a container may narrow this down, but may not
contradict this.

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
