package IO::K8s::Cilium::V2alpha1::CiliumBGPFamilyWithAdverts;
# ABSTRACT: CiliumBGPFamilyWithAdverts represents a AFI/SAFI address family pair along with reference to BGP Advertisements.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s advertisements => 'Meta::V1::LabelSelector';
k8s afi            => Str, { required => 'schema', enum => [qw(ipv4 ipv6 l2vpn ls opaque)] };
k8s safi           => Str, { required => 'schema', enum => [qw(unicast multicast mpls_label encapsulation vpls evpn ls sr_policy mup mpls_vpn mpls_vpn_multicast route_target_constraints flowspec_unicast flowspec_vpn key_value)] };




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Cilium::V2alpha1::CiliumBGPFamilyWithAdverts - CiliumBGPFamilyWithAdverts represents a AFI/SAFI address family pair along with reference to BGP Advertisements.

=head1 VERSION

version 1.108

=head2 advertisements

Advertisements selects group of BGP Advertisement(s) to advertise for this family.

If not specified, no advertisements are sent for this family.

=head2 afi

Afi is the Address Family Identifier (AFI) of the family.

=head2 safi

Safi is the Subsequent Address Family Identifier (SAFI) of the family.

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
