package IO::K8s::VolumeSnapshot::V1::VolumeSnapshotContentStatus;
# ABSTRACT: status represents the current information of a snapshot.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s creationTime              => Int;
k8s error                     => '+IO::K8s::VolumeSnapshot::V1::VolumeSnapshotError';
k8s readyToUse                => Bool;
k8s restoreSize               => Int, { minimum => 0 };
k8s snapshotHandle            => Str;
k8s volumeGroupSnapshotHandle => Str;







1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::VolumeSnapshot::V1::VolumeSnapshotContentStatus - status represents the current information of a snapshot.

=head1 VERSION

version 1.108

=head2 creationTime

creationTime is the timestamp when the point-in-time snapshot is taken
by the underlying storage system.
In dynamic snapshot creation case, this field will be filled in by the
CSI snapshotter sidecar with the "creation_time" value returned from CSI
"CreateSnapshot" gRPC call.
For a pre-existing snapshot, this field will be filled with the "creation_time"
value returned from the CSI "ListSnapshots" gRPC call if the driver supports it.
If not specified, it indicates the creation time is unknown.
The format of this field is a Unix nanoseconds time encoded as an int64.
On Unix, the command `date +%s%N` returns the current time in nanoseconds
since 1970-01-01 00:00:00 UTC.

=head2 error

error is the last observed error during snapshot creation, if any.
Upon success after retry, this error field will be cleared.

=head2 readyToUse

readyToUse indicates if a snapshot is ready to be used to restore a volume.
In dynamic snapshot creation case, this field will be filled in by the
CSI snapshotter sidecar with the "ready_to_use" value returned from CSI
"CreateSnapshot" gRPC call.
For a pre-existing snapshot, this field will be filled with the "ready_to_use"
value returned from the CSI "ListSnapshots" gRPC call if the driver supports it,
otherwise, this field will be set to "True".
If not specified, it means the readiness of a snapshot is unknown.

=head2 restoreSize

restoreSize represents the complete size of the snapshot in bytes.
In dynamic snapshot creation case, this field will be filled in by the
CSI snapshotter sidecar with the "size_bytes" value returned from CSI
"CreateSnapshot" gRPC call.
For a pre-existing snapshot, this field will be filled with the "size_bytes"
value returned from the CSI "ListSnapshots" gRPC call if the driver supports it.
When restoring a volume from this snapshot, the size of the volume MUST NOT
be smaller than the restoreSize if it is specified, otherwise the restoration will fail.
If not specified, it indicates that the size is unknown.

=head2 snapshotHandle

snapshotHandle is the CSI "snapshot_id" of a snapshot on the underlying storage system.
If not specified, it indicates that dynamic snapshot creation has either failed
or it is still in progress.

=head2 volumeGroupSnapshotHandle

VolumeGroupSnapshotHandle is the CSI "group_snapshot_id" of a group snapshot
on the underlying storage system.

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
