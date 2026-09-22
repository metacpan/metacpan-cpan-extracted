package IO::K8s::VolumeSnapshot::V1::VolumeGroupSnapshotStatus;
# ABSTRACT: VolumeGroupSnapshotStatus defines the observed state of a volume group snapshot
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s boundVolumeGroupSnapshotContentName => Str;


k8s creationTime => Time;


k8s error => '+IO::K8s::VolumeSnapshot::V1::VolumeSnapshotError';


k8s readyToUse => Bool;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::VolumeSnapshot::V1::VolumeGroupSnapshotStatus - VolumeGroupSnapshotStatus defines the observed state of a volume group snapshot

=head1 VERSION

version 1.108

=head2 boundVolumeGroupSnapshotContentName

BoundVolumeGroupSnapshotContentName is the name of the VolumeGroupSnapshotContent
object to which this VolumeGroupSnapshot object intends to bind to.
If not specified, it indicates that the VolumeGroupSnapshot object has not
been successfully bound to a VolumeGroupSnapshotContent object yet.
NOTE: To avoid possible security issues, consumers must verify binding between
VolumeGroupSnapshot and VolumeGroupSnapshotContent objects is successful
(by validating that both VolumeGroupSnapshot and VolumeGroupSnapshotContent
point at each other) before using this object.

=head2 creationTime

CreationTime is the timestamp when the point-in-time group snapshot is taken
by the underlying storage system.
If not specified, it may indicate that the creation time of the group snapshot
is unknown.
This field is updated based on the CreationTime field in VolumeGroupSnapshotContentStatus

=head2 error

Error is the last observed error during group snapshot creation, if any.
This field could be helpful to upper level controllers (i.e., application
controller) to decide whether they should continue on waiting for the group
snapshot to be created based on the type of error reported.
The snapshot controller will keep retrying when an error occurs during the
group snapshot creation. Upon success, this error field will be cleared.

=head2 readyToUse

ReadyToUse indicates if all the individual snapshots in the group are ready
to be used to restore a group of volumes.
ReadyToUse becomes true when ReadyToUse of all individual snapshots become true.
If not specified, it means the readiness of a group snapshot is unknown.

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
