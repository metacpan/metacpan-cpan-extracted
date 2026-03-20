package IO::K8s::Api::Core::V1::StorageOSVolumeSource;
# ABSTRACT: Represents a StorageOS persistent volume resource.
our $VERSION = '1.009';
use IO::K8s::Resource;

k8s fsType => Str;


k8s readOnly => Bool;


k8s secretRef => 'Core::V1::LocalObjectReference';


k8s volumeName => Str;


k8s volumeNamespace => Str;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Core::V1::StorageOSVolumeSource - Represents a StorageOS persistent volume resource.

=head1 VERSION

version 1.009

=head2 fsType

fsType is the filesystem type to mount. Must be a filesystem type supported by the host operating system. Ex. "ext4", "xfs", "ntfs". Implicitly inferred to be "ext4" if unspecified.

=head2 readOnly

readOnly defaults to false (read/write). ReadOnly here will force the ReadOnly setting in VolumeMounts.

=head2 secretRef

secretRef specifies the secret to use for obtaining the StorageOS API credentials.  If not specified, default values will be attempted.

=head2 volumeName

volumeName is the human-readable name of the StorageOS volume.  Volume names are only unique within a namespace.

=head2 volumeNamespace

volumeNamespace specifies the scope of the volume within StorageOS.  If no namespace is specified then the Pod's namespace will be used.  This allows the Kubernetes name scoping to be mirrored within StorageOS for tighter integration. Set VolumeName to any name to override the default behaviour. Set to "default" if you are not using namespaces within StorageOS. Namespaces that do not pre-exist within StorageOS will be created.

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
