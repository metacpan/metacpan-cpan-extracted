package IO::K8s::VolumeSnapshot::V1::VolumeSnapshotSpec;
# ABSTRACT: spec defines the desired characteristics of a snapshot requested by a user.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s source                  => '+IO::K8s::VolumeSnapshot::V1::VolumeSnapshotSource', { required => 'schema' };
k8s volumeSnapshotClassName => Str;



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::VolumeSnapshot::V1::VolumeSnapshotSpec - spec defines the desired characteristics of a snapshot requested by a user.

=head1 VERSION

version 1.108

=head2 source

source specifies where a snapshot will be created from.
This field is immutable after creation.
Required.

=head2 volumeSnapshotClassName

VolumeSnapshotClassName is the name of the VolumeSnapshotClass
requested by the VolumeSnapshot.
VolumeSnapshotClassName may be left nil to indicate that the default
SnapshotClass should be used.
A given cluster may have multiple default Volume SnapshotClasses: one
default per CSI Driver. If a VolumeSnapshot does not specify a SnapshotClass,
VolumeSnapshotSource will be checked to figure out what the associated
CSI Driver is, and the default VolumeSnapshotClass associated with that
CSI Driver will be used. If more than one VolumeSnapshotClass exist for
a given CSI Driver and more than one have been marked as default,
CreateSnapshot will fail and generate an event.
Empty string is not allowed for this field.

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
