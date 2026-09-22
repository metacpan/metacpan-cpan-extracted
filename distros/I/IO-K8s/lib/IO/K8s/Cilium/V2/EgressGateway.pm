package IO::K8s::Cilium::V2::EgressGateway;
# ABSTRACT: EgressGateway identifies the node that should act as egress gateway for a given egress Gateway policy.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s egressIP     => Str;
k8s interface    => Str;
k8s nodeSelector => 'Meta::V1::LabelSelector', { required => 'schema' };




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Cilium::V2::EgressGateway - EgressGateway identifies the node that should act as egress gateway for a given egress Gateway policy.

=head1 VERSION

version 1.108

=head2 egressIP

EgressIP is the source IP address that the egress traffic is SNATed
with.

Example:
When set to "192.168.1.100", matching egress traffic will be
redirected to the node matching the NodeSelector field and SNATed
with IP address 192.168.1.100.

When set to "2001:db8::1", matching egress traffic will be
redirected to the node matching the NodeSelector field and SNATed
with IPv6 address 2001:db8::1.

When none of the Interface or EgressIP fields is specified, the
policy will use the first IPv4 assigned to the interface with the
default route.

=head2 interface

Interface is the network interface to which the egress IP address
that the traffic is SNATed with is assigned.

Example:
When set to "eth1", matching egress traffic will be redirected to the
node matching the NodeSelector field and SNATed with the first IPv4
address assigned to the eth1 interface.

When none of the Interface or EgressIP fields is specified, the
policy will use the first IPv4 assigned to the interface with the
default route.

=head2 nodeSelector

This is a label selector which selects the node that should act as
egress gateway for the given policy.
In case multiple nodes are selected, only the first one in the
lexical ordering over the node names will be used.
This field follows standard label selector semantics.

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
