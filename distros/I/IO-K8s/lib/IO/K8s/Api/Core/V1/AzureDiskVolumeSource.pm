package IO::K8s::Api::Core::V1::AzureDiskVolumeSource;
# ABSTRACT: AzureDisk represents an Azure Data Disk mount on the host and bind mount to the pod.
our $VERSION = '1.100';
use IO::K8s::Resource;

k8s cachingMode => Str;


k8s diskName => Str, 'required';


k8s diskURI => Str, 'required';


k8s fsType => Str;


k8s kind => Str;


k8s readOnly => Bool;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Core::V1::AzureDiskVolumeSource - AzureDisk represents an Azure Data Disk mount on the host and bind mount to the pod.

=head1 VERSION

version 1.100

=head2 cachingMode

cachingMode is the Host Caching mode: None, Read Only, Read Write.

=head2 diskName

diskName is the Name of the data disk in the blob storage

=head2 diskURI

diskURI is the URI of data disk in the blob storage

=head2 fsType

fsType is Filesystem type to mount. Must be a filesystem type supported by the host operating system. Ex. "ext4", "xfs", "ntfs". Implicitly inferred to be "ext4" if unspecified.

=head2 kind

kind expected values are Shared: multiple blob disks per storage account  Dedicated: single blob disk per storage account  Managed: azure managed data disk (only in managed availability set). defaults to shared

=head2 readOnly

readOnly Defaults to false (read/write). ReadOnly here will force the ReadOnly setting in VolumeMounts.

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
