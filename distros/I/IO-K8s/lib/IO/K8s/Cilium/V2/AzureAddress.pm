package IO::K8s::Cilium::V2::AzureAddress;
# ABSTRACT: AzureAddress is an IP address assigned to an AzureInterface
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s ip     => Str;
k8s state  => Str;
k8s subnet => Str;




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Cilium::V2::AzureAddress - AzureAddress is an IP address assigned to an AzureInterface

=head1 VERSION

version 1.108

=head2 ip

IP is the ip address of the address

=head2 state

State is the provisioning state of the address

=head2 subnet

Subnet is the subnet the address belongs to.

Deprecated: use AzureInterface.Subnet.ID. Populated as a mirror for one
release so external consumers of CiliumNode.Status.Azure can migrate.

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
