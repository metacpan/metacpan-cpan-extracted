package IO::K8s::VolumeSnapshot::V1::VolumeGroupSnapshotClass;
# ABSTRACT: VolumeGroupSnapshotClass specifies parameters for a volume group snapshot
our $VERSION = '1.108';
use IO::K8s::APIObject
    api_version     => 'groupsnapshot.storage.k8s.io/v1',
    resource_plural => 'volumegroupsnapshotclasses';


k8s deletionPolicy => Str, { required => 'schema', enum => [qw(Delete Retain)] };


k8s driver => Str, { required => 'schema' };


k8s parameters => { Str => 1 };



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::VolumeSnapshot::V1::VolumeGroupSnapshotClass - VolumeGroupSnapshotClass specifies parameters for a volume group snapshot

=head1 VERSION

version 1.108

=head1 DESCRIPTION

VolumeGroupSnapshotClass specifies parameters that a underlying storage system
uses when creating a volume group snapshot. A specific VolumeGroupSnapshotClass
is used by specifying its name in a VolumeGroupSnapshot object.
VolumeGroupSnapshotClasses are non-namespaced.

This is a Kubernetes API object. See L<IO::K8s::Role::APIObject> for
C<metadata>, C<api_version()>, and C<kind()>.

=head2 deletionPolicy

DeletionPolicy determines whether a VolumeGroupSnapshotContent created
through the VolumeGroupSnapshotClass should be deleted when its bound
VolumeGroupSnapshot is deleted.
Supported values are "Retain" and "Delete".
"Retain" means that the VolumeGroupSnapshotContent and its physical group
snapshot on underlying storage system are kept.
"Delete" means that the VolumeGroupSnapshotContent and its physical group
snapshot on underlying storage system are deleted.
Required.

=head2 driver

Driver is the name of the storage driver expected to handle this VolumeGroupSnapshotClass.
Required.

=head2 parameters

Parameters is a key-value map with storage driver specific parameters for
creating group snapshots.
These values are opaque to Kubernetes and are passed directly to the driver.

=head1 SEE ALSO

L<external-snapshotter v8.6.0 VolumeGroupSnapshotClass CRD|https://github.com/kubernetes-csi/external-snapshotter/blob/v8.6.0/client/config/crd/groupsnapshot.storage.k8s.io_volumegroupsnapshotclasses.yaml>

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
