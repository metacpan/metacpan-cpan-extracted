package IO::K8s::Cilium::V2alpha1::BGPServiceOptions;
# ABSTRACT: Service defines configuration options for advertisementType service.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s addresses             => [Str], { required => 'schema', enum => [qw(LoadBalancerIP ClusterIP ExternalIP)] };
k8s aggregationLengthIPv4 => Int, { minimum => 0, maximum => 31 };
k8s aggregationLengthIPv6 => Int, { minimum => 0, maximum => 127 };




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Cilium::V2alpha1::BGPServiceOptions - Service defines configuration options for advertisementType service.

=head1 VERSION

version 1.108

=head2 addresses

Addresses is a list of service address types which needs to be advertised via BGP.

=head2 aggregationLengthIPv4

IPv4 mask to aggregate BGP route advertisements of service

=head2 aggregationLengthIPv6

IPv6 mask to aggregate BGP route advertisements of service

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
