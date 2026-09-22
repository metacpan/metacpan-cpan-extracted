package IO::K8s::Cilium::V2::AzureInterface;
# ABSTRACT: AzureInterface represents an Azure Interface
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s addresses        => ['+IO::K8s::Cilium::V2::AzureAddress'];
k8s cidr             => Str;
k8s gateway          => Str;
k8s id               => Str;
k8s ip               => Str;
k8s mac              => Str;
k8s name             => Str;
k8s 'security-group' => Str;
k8s state            => Str;
k8s subnet           => '+IO::K8s::Cilium::V2::AzureSubnet';











1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Cilium::V2::AzureInterface - AzureInterface represents an Azure Interface

=head1 VERSION

version 1.108

=head2 addresses

Addresses is the list of secondary IPs associated with the interface.
The primary IP is tracked separately in the IP field, but is also
included here when the operator is configured to expose it for
allocation.

=head2 cidr

CIDR is the range that the interface belongs to.

Deprecated: use Subnet.CIDR. Retained for one release so agent/operator
rolling upgrades work in either order.

=head2 gateway

Gateway is the interface's subnet's default route

=head2 id

ID is the identifier

=head2 ip

IP is the primary IP of the interface

=head2 mac

MAC is the mac address

=head2 name

Name is the name of the interface

=head2 security-group

SecurityGroup is the security group associated with the interface

=head2 state

State is the provisioning state

=head2 subnet

Subnet is the subnet the interface is attached to.

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
