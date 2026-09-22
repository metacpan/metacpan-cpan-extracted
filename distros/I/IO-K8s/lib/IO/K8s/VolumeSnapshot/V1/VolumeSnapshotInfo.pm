package IO::K8s::VolumeSnapshot::V1::VolumeSnapshotInfo;
# ABSTRACT: VolumeSnapshotInfo contains information for a snapshot
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s creationTime => Int;


k8s readyToUse => Bool;


k8s restoreSize => Int;


k8s snapshotHandle => Str;


k8s volumeHandle => Str;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::VolumeSnapshot::V1::VolumeSnapshotInfo - VolumeSnapshotInfo contains information for a snapshot

=head1 VERSION

version 1.108

=head2 creationTime

creationTime is the timestamp when the point-in-time snapshot is taken
by the underlying storage system.

=head2 readyToUse

ReadyToUse indicates if the snapshot is ready to be used to restore a volume.

=head2 restoreSize

RestoreSize represents the minimum size of volume required to create a volume
from this snapshot.

=head2 snapshotHandle

SnapshotHandle is the CSI "snapshot_id" of this snapshot on the underlying storage system.

=head2 volumeHandle

VolumeHandle specifies the CSI "volume_id" of the volume from which this snapshot
was taken from.

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
