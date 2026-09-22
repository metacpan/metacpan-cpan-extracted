package IO::K8s::VolumeSnapshot::V1beta1::VolumeGroupSnapshotContentStatus;
# ABSTRACT: VolumeGroupSnapshotContentStatus defines the observed group snapshot content state
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s creationTime => Time;


k8s error => '+IO::K8s::VolumeSnapshot::V1::VolumeSnapshotError';


k8s readyToUse => Bool;


k8s volumeGroupSnapshotHandle => Str;


k8s volumeSnapshotHandlePairList => ['+IO::K8s::VolumeSnapshot::V1beta1::VolumeSnapshotHandlePair'];


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::VolumeSnapshot::V1beta1::VolumeGroupSnapshotContentStatus - VolumeGroupSnapshotContentStatus defines the observed group snapshot content state

=head1 VERSION

version 1.108

=head2 creationTime

CreationTime is the timestamp when the point-in-time group snapshot is taken
by the underlying storage system.
If not specified, it indicates the creation time is unknown.
If not specified, it means the readiness of a group snapshot is unknown.
This field is the source for the CreationTime field in VolumeGroupSnapshotStatus

=head2 error

Error is the last observed error during group snapshot creation, if any.
Upon success after retry, this error field will be cleared.

=head2 readyToUse

ReadyToUse indicates if all the individual snapshots in the group are ready to be
used to restore a group of volumes.
ReadyToUse becomes true when ReadyToUse of all individual snapshots become true.

=head2 volumeGroupSnapshotHandle

VolumeGroupSnapshotHandle is a unique id returned by the CSI driver
to identify the VolumeGroupSnapshot on the storage system.
If a storage system does not provide such an id, the
CSI driver can choose to return the VolumeGroupSnapshot name.

=head2 volumeSnapshotHandlePairList

VolumeSnapshotHandlePairList is a list of CSI "volume_id" and "snapshot_id"
pair returned by the CSI driver to identify snapshots and their source volumes
on the storage system.

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
