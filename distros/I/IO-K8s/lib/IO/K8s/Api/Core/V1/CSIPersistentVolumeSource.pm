package IO::K8s::Api::Core::V1::CSIPersistentVolumeSource;
# ABSTRACT: Represents storage that is managed by an external CSI volume driver (Beta feature)
our $VERSION = '1.009';
use IO::K8s::Resource;

k8s controllerExpandSecretRef => 'Core::V1::SecretReference';


k8s controllerPublishSecretRef => 'Core::V1::SecretReference';


k8s driver => Str, 'required';


k8s fsType => Str;


k8s nodeExpandSecretRef => 'Core::V1::SecretReference';


k8s nodePublishSecretRef => 'Core::V1::SecretReference';


k8s nodeStageSecretRef => 'Core::V1::SecretReference';


k8s readOnly => Bool;


k8s volumeAttributes => { Str => 1 };


k8s volumeHandle => Str, 'required';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Core::V1::CSIPersistentVolumeSource - Represents storage that is managed by an external CSI volume driver (Beta feature)

=head1 VERSION

version 1.009

=head2 controllerExpandSecretRef

controllerExpandSecretRef is a reference to the secret object containing sensitive information to pass to the CSI driver to complete the CSI ControllerExpandVolume call. This field is optional, and may be empty if no secret is required. If the secret object contains more than one secret, all secrets are passed.

=head2 controllerPublishSecretRef

controllerPublishSecretRef is a reference to the secret object containing sensitive information to pass to the CSI driver to complete the CSI ControllerPublishVolume and ControllerUnpublishVolume calls. This field is optional, and may be empty if no secret is required. If the secret object contains more than one secret, all secrets are passed.

=head2 driver

driver is the name of the driver to use for this volume. Required.

=head2 fsType

fsType to mount. Must be a filesystem type supported by the host operating system. Ex. "ext4", "xfs", "ntfs".

=head2 nodeExpandSecretRef

nodeExpandSecretRef is a reference to the secret object containing sensitive information to pass to the CSI driver to complete the CSI NodeExpandVolume call. This field is optional, may be omitted if no secret is required. If the secret object contains more than one secret, all secrets are passed.

=head2 nodePublishSecretRef

nodePublishSecretRef is a reference to the secret object containing sensitive information to pass to the CSI driver to complete the CSI NodePublishVolume and NodeUnpublishVolume calls. This field is optional, and may be empty if no secret is required. If the secret object contains more than one secret, all secrets are passed.

=head2 nodeStageSecretRef

nodeStageSecretRef is a reference to the secret object containing sensitive information to pass to the CSI driver to complete the CSI NodeStageVolume and NodeStageVolume and NodeUnstageVolume calls. This field is optional, and may be empty if no secret is required. If the secret object contains more than one secret, all secrets are passed.

=head2 readOnly

readOnly value to pass to ControllerPublishVolumeRequest. Defaults to false (read/write).

=head2 volumeAttributes

volumeAttributes of the volume to publish.

=head2 volumeHandle

volumeHandle is the unique volume name returned by the CSI volume plugin’s CreateVolume to refer to the volume on all subsequent calls. Required.

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
