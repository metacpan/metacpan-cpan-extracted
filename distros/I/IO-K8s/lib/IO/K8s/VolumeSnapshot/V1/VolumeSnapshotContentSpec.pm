package IO::K8s::VolumeSnapshot::V1::VolumeSnapshotContentSpec;
# ABSTRACT: spec defines properties of a VolumeSnapshotContent created by the underlying storage system.
our $VERSION = '1.108';
use utf8;
use IO::K8s::Resource;

k8s deletionPolicy          => Str, { required => 'schema', enum => [qw(Delete Retain)] };
k8s driver                  => Str, { required => 'schema' };
k8s source                  => '+IO::K8s::VolumeSnapshot::V1::VolumeSnapshotContentSource', { required => 'schema' };
k8s sourceVolumeMode        => Str;
k8s volumeSnapshotClassName => Str;
k8s volumeSnapshotRef       => 'Core::V1::ObjectReference', { required => 'schema' };








1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::VolumeSnapshot::V1::VolumeSnapshotContentSpec - spec defines properties of a VolumeSnapshotContent created by the underlying storage system.

=head1 VERSION

version 1.108

=head2 deletionPolicy

deletionPolicy determines whether this VolumeSnapshotContent and its physical snapshot on
the underlying storage system should be deleted when its bound VolumeSnapshot is deleted.
Supported values are "Retain" and "Delete".
"Retain" means that the VolumeSnapshotContent and its physical snapshot on underlying storage system are kept.
"Delete" means that the VolumeSnapshotContent and its physical snapshot on underlying storage system are deleted.
For dynamically provisioned snapshots, this field will automatically be filled in by the
CSI snapshotter sidecar with the "DeletionPolicy" field defined in the corresponding
VolumeSnapshotClass.
For pre-existing snapshots, users MUST specify this field when creating the
 VolumeSnapshotContent object.
Required.

=head2 driver

driver is the name of the CSI driver used to create the physical snapshot on
the underlying storage system.
This MUST be the same as the name returned by the CSI GetPluginName() call for
that driver.
Required.

=head2 source

source specifies whether the snapshot is (or should be) dynamically provisioned
or already exists, and just requires a Kubernetes object representation.
This field is immutable after creation.
Required.

=head2 sourceVolumeMode

SourceVolumeMode is the mode of the volume whose snapshot is taken.
Can be either “Filesystem” or “Block”.
If not specified, it indicates the source volume's mode is unknown.
This field is immutable.
This field is an alpha field.

=head2 volumeSnapshotClassName

name of the VolumeSnapshotClass from which this snapshot was (or will be)
created.
Note that after provisioning, the VolumeSnapshotClass may be deleted or
recreated with different set of values, and as such, should not be referenced
post-snapshot creation.

=head2 volumeSnapshotRef

volumeSnapshotRef specifies the VolumeSnapshot object to which this
VolumeSnapshotContent object is bound.
VolumeSnapshot.Spec.VolumeSnapshotContentName field must reference to
this VolumeSnapshotContent's name for the bidirectional binding to be valid.
For a pre-existing VolumeSnapshotContent object, name and namespace of the
VolumeSnapshot object MUST be provided for binding to happen.
This field is immutable after creation.
Required.

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
