package IO::K8s::VolumeSnapshot::V1::VolumeSnapshotStatus;
# ABSTRACT: status represents the current information of a snapshot.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s boundVolumeSnapshotContentName => Str;
k8s creationTime                   => Time;
k8s error                          => '+IO::K8s::VolumeSnapshot::V1::VolumeSnapshotError';
k8s readyToUse                     => Bool;
k8s restoreSize                    => Quantity;
k8s volumeGroupSnapshotName        => Str;







1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::VolumeSnapshot::V1::VolumeSnapshotStatus - status represents the current information of a snapshot.

=head1 VERSION

version 1.108

=head2 boundVolumeSnapshotContentName

boundVolumeSnapshotContentName is the name of the VolumeSnapshotContent
object to which this VolumeSnapshot object intends to bind to.
If not specified, it indicates that the VolumeSnapshot object has not been
successfully bound to a VolumeSnapshotContent object yet.
NOTE: To avoid possible security issues, consumers must verify binding between
VolumeSnapshot and VolumeSnapshotContent objects is successful (by validating that
both VolumeSnapshot and VolumeSnapshotContent point at each other) before using
this object.

=head2 creationTime

creationTime is the timestamp when the point-in-time snapshot is taken
by the underlying storage system.
In dynamic snapshot creation case, this field will be filled in by the
snapshot controller with the "creation_time" value returned from CSI
"CreateSnapshot" gRPC call.
For a pre-existing snapshot, this field will be filled with the "creation_time"
value returned from the CSI "ListSnapshots" gRPC call if the driver supports it.
If not specified, it may indicate that the creation time of the snapshot is unknown.

=head2 error

error is the last observed error during snapshot creation, if any.
This field could be helpful to upper level controllers(i.e., application controller)
to decide whether they should continue on waiting for the snapshot to be created
based on the type of error reported.
The snapshot controller will keep retrying when an error occurs during the
snapshot creation. Upon success, this error field will be cleared.

=head2 readyToUse

readyToUse indicates if the snapshot is ready to be used to restore a volume.
In dynamic snapshot creation case, this field will be filled in by the
snapshot controller with the "ready_to_use" value returned from CSI
"CreateSnapshot" gRPC call.
For a pre-existing snapshot, this field will be filled with the "ready_to_use"
value returned from the CSI "ListSnapshots" gRPC call if the driver supports it,
otherwise, this field will be set to "True".
If not specified, it means the readiness of a snapshot is unknown.

=head2 restoreSize

restoreSize represents the minimum size of volume required to create a volume
from this snapshot.
In dynamic snapshot creation case, this field will be filled in by the
snapshot controller with the "size_bytes" value returned from CSI
"CreateSnapshot" gRPC call.
For a pre-existing snapshot, this field will be filled with the "size_bytes"
value returned from the CSI "ListSnapshots" gRPC call if the driver supports it.
When restoring a volume from this snapshot, the size of the volume MUST NOT
be smaller than the restoreSize if it is specified, otherwise the restoration will fail.
If not specified, it indicates that the size is unknown.

=head2 volumeGroupSnapshotName

VolumeGroupSnapshotName is the name of the VolumeGroupSnapshot of which this
VolumeSnapshot is a part of.

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
