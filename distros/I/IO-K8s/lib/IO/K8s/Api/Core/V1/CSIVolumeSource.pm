package IO::K8s::Api::Core::V1::CSIVolumeSource;
# ABSTRACT: Represents a source location of a volume to mount, managed by an external CSI driver
our $VERSION = '1.006';
use IO::K8s::Resource;

k8s driver => Str, 'required';


k8s fsType => Str;


k8s nodePublishSecretRef => 'Core::V1::LocalObjectReference';


k8s readOnly => Bool;


k8s volumeAttributes => { Str => 1 };


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Core::V1::CSIVolumeSource - Represents a source location of a volume to mount, managed by an external CSI driver

=head1 VERSION

version 1.006

=head2 driver

driver is the name of the CSI driver that handles this volume. Consult with your admin for the correct name as registered in the cluster.

=head2 fsType

fsType to mount. Ex. "ext4", "xfs", "ntfs". If not provided, the empty value is passed to the associated CSI driver which will determine the default filesystem to apply.

=head2 nodePublishSecretRef

nodePublishSecretRef is a reference to the secret object containing sensitive information to pass to the CSI driver to complete the CSI NodePublishVolume and NodeUnpublishVolume calls. This field is optional, and  may be empty if no secret is required. If the secret object contains more than one secret, all secret references are passed.

=head2 readOnly

readOnly specifies a read-only configuration for the volume. Defaults to false (read/write).

=head2 volumeAttributes

volumeAttributes stores driver-specific properties that are passed to the CSI driver. Consult your driver's documentation for supported values.

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

Jose Luis Martinez <jlmartin@cpan.org> (original author, inactive)

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Jose Luis Martinez.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
