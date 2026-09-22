package IO::K8s::Cilium::V2::NodeStatus;
# ABSTRACT: Status defines the realized specification/configuration and status of the node.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s 'alibaba-cloud' => '+IO::K8s::Cilium::V2::AlibabaCloudENIStatus';
k8s azure           => '+IO::K8s::Cilium::V2::AzureStatus';
k8s eni             => '+IO::K8s::Cilium::V2::ENIStatus';
k8s ipam            => '+IO::K8s::Cilium::V2::IPAMStatus';





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Cilium::V2::NodeStatus - Status defines the realized specification/configuration and status of the node.

=head1 VERSION

version 1.108

=head2 alibaba-cloud

AlibabaCloud is the AlibabaCloud specific status of the node.

=head2 azure

Azure is the Azure specific status of the node.

=head2 eni

ENI is the AWS ENI specific status of the node.

=head2 ipam

IPAM is the IPAM status of the node.

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
