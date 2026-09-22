package IO::K8s::VolumeSnapshot::V1beta1::VolumeGroupSnapshotContentSpec;
# ABSTRACT: VolumeGroupSnapshotContentSpec describes common group snapshot content attributes
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s deletionPolicy => Str, { required => 'schema', enum => [qw(Delete Retain)] };


k8s driver => Str, { required => 'schema' };


k8s source => '+IO::K8s::VolumeSnapshot::V1beta1::VolumeGroupSnapshotContentSource', { required => 'schema' };


k8s volumeGroupSnapshotClassName => Str;


k8s volumeGroupSnapshotRef => 'Core::V1::ObjectReference', { required => 'schema' };


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::VolumeSnapshot::V1beta1::VolumeGroupSnapshotContentSpec - VolumeGroupSnapshotContentSpec describes common group snapshot content attributes

=head1 VERSION

version 1.108

=head2 deletionPolicy

DeletionPolicy determines whether this VolumeGroupSnapshotContent and the
physical group snapshot on the underlying storage system should be deleted
when the bound VolumeGroupSnapshot is deleted.
Supported values are "Retain" and "Delete".
"Retain" means that the VolumeGroupSnapshotContent and its physical group
snapshot on underlying storage system are kept.
"Delete" means that the VolumeGroupSnapshotContent and its physical group
snapshot on underlying storage system are deleted.
For dynamically provisioned group snapshots, this field will automatically
be filled in by the CSI snapshotter sidecar with the "DeletionPolicy" field
defined in the corresponding VolumeGroupSnapshotClass.
For pre-existing snapshots, users MUST specify this field when creating the
VolumeGroupSnapshotContent object.
Required.

=head2 driver

Driver is the name of the CSI driver used to create the physical group snapshot on
the underlying storage system.
This MUST be the same as the name returned by the CSI GetPluginName() call for
that driver.
Required.

=head2 source

Source specifies whether the snapshot is (or should be) dynamically provisioned
or already exists, and just requires a Kubernetes object representation.
This field is immutable after creation.
Required.

=head2 volumeGroupSnapshotClassName

VolumeGroupSnapshotClassName is the name of the VolumeGroupSnapshotClass from
which this group snapshot was (or will be) created.
Note that after provisioning, the VolumeGroupSnapshotClass may be deleted or
recreated with different set of values, and as such, should not be referenced
post-snapshot creation.
For dynamic provisioning, this field must be set.
This field may be unset for pre-provisioned snapshots.

=head2 volumeGroupSnapshotRef

VolumeGroupSnapshotRef specifies the VolumeGroupSnapshot object to which this
VolumeGroupSnapshotContent object is bound.
VolumeGroupSnapshot.Spec.VolumeGroupSnapshotContentName field must reference to
this VolumeGroupSnapshotContent's name for the bidirectional binding to be valid.
For a pre-existing VolumeGroupSnapshotContent object, name and namespace of the
VolumeGroupSnapshot object MUST be provided for binding to happen.
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
