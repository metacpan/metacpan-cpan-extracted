package IO::K8s::Cilium::V2::NodeSpec;
# ABSTRACT: Spec defines the desired specification/configuration of the node.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s addresses       => ['+IO::K8s::Cilium::V2::NodeAddress'];
k8s 'alibaba-cloud' => '+IO::K8s::Cilium::V2::AlibabaCloudSpec';
k8s azure           => '+IO::K8s::Cilium::V2::AzureSpec';
k8s bootid          => Str;
k8s encryption      => '+IO::K8s::Cilium::V2::EncryptionSpec';
k8s eni             => '+IO::K8s::Cilium::V2::ENISpec';
k8s health          => '+IO::K8s::Cilium::V2::HealthAddressingSpec';
k8s ingress         => '+IO::K8s::Cilium::V2::AddressPair';
k8s 'instance-id'   => Str;
k8s ipam            => '+IO::K8s::Cilium::V2::IPAMSpec';











1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Cilium::V2::NodeSpec - Spec defines the desired specification/configuration of the node.

=head1 VERSION

version 1.108

=head2 addresses

Addresses is the list of all node addresses.

=head2 alibaba-cloud

AlibabaCloud is the AlibabaCloud IPAM specific configuration.

=head2 azure

Azure is the Azure IPAM specific configuration.

=head2 bootid

BootID is a unique node identifier generated on boot

=head2 encryption

Encryption is the encryption configuration of the node.

=head2 eni

ENI is the AWS ENI specific configuration.

=head2 health

HealthAddressing is the addressing information for health connectivity
checking.

=head2 ingress

IngressAddressing is the addressing information for Ingress listener.

=head2 instance-id

InstanceID is the identifier of the node. This is different from the
node name which is typically the FQDN of the node. The InstanceID
typically refers to the identifier used by the cloud provider or
some other means of identification.

=head2 ipam

IPAM is the address management specification. This section can be
populated by a user or it can be automatically populated by an IPAM
operator.

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
