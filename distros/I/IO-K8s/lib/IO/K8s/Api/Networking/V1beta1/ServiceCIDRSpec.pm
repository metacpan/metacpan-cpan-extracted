package IO::K8s::Api::Networking::V1beta1::ServiceCIDRSpec;
# ABSTRACT: ServiceCIDRSpec define the CIDRs the user wants to use for allocating ClusterIPs for Services.
our $VERSION = '1.009';
use IO::K8s::Resource;

k8s cidrs => [Str];


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Networking::V1beta1::ServiceCIDRSpec - ServiceCIDRSpec define the CIDRs the user wants to use for allocating ClusterIPs for Services.

=head1 VERSION

version 1.009

=head2 cidrs

CIDRs defines the IP blocks in CIDR notation (e.g. "192.168.0.0/24" or "2001:db8::/64") from which to assign service cluster IPs. Max of two CIDRs is allowed, one of each IP family. This field is immutable.

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/pplu/io-k8s-p5/issues>.

=head2 IRC

Join C<#kubernetes> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHORS

=over 4

=item *

Torsten Raudssus <torsten@raudssus.de>

=item *

Jose Luis Martinez Torres <jlmartin@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018-2026 by Jose Luis Martinez Torres <jlmartin@cpan.org>.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
