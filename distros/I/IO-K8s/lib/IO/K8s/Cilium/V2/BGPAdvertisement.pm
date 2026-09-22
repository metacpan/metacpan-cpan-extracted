package IO::K8s::Cilium::V2::BGPAdvertisement;
# ABSTRACT: BGPAdvertisement defines which routes Cilium should advertise to BGP peers.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s advertisementType => Str, { required => 'schema', enum => [qw(PodCIDR CiliumPodIPPool Service Interface)] };
k8s attributes        => '+IO::K8s::Cilium::V2::BGPAttributes';
k8s interface         => '+IO::K8s::Cilium::V2::BGPInterfaceOptions';
k8s selector          => 'Meta::V1::LabelSelector';
k8s service           => '+IO::K8s::Cilium::V2::BGPServiceOptions';






1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Cilium::V2::BGPAdvertisement - BGPAdvertisement defines which routes Cilium should advertise to BGP peers.

=head1 VERSION

version 1.108

=head2 advertisementType

AdvertisementType defines type of advertisement which has to be advertised.

=head2 attributes

Attributes defines additional attributes to set to the advertised routes.
If not specified, no additional attributes are set.

=head2 interface

Interface defines configuration options for the "Interface" advertisementType.

=head2 selector

Selector is a label selector to select objects of the type specified by AdvertisementType.
For the PodCIDR AdvertisementType it is not applicable. For other advertisement types,
if not specified, no objects of the type specified by AdvertisementType are selected for advertisement.

=head2 service

Service defines configuration options for the "Service" advertisementType.

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
