package IO::K8s::VolumeSnapshot::V1::VolumeGroupSnapshotContentSource;
# ABSTRACT: VolumeGroupSnapshotContentSource represents the CSI source of a group snapshot
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s groupSnapshotHandles => '+IO::K8s::VolumeSnapshot::V1::GroupSnapshotHandles';


k8s volumeHandles => [Str];


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::VolumeSnapshot::V1::VolumeGroupSnapshotContentSource - VolumeGroupSnapshotContentSource represents the CSI source of a group snapshot

=head1 VERSION

version 1.108

=head2 groupSnapshotHandles

GroupSnapshotHandles specifies the CSI "group_snapshot_id" of a pre-existing
group snapshot and a list of CSI "snapshot_id" of pre-existing snapshots
on the underlying storage system for which a Kubernetes object
representation was (or should be) created.
This field is immutable.

=head2 volumeHandles

VolumeHandles is a list of volume handles on the backend to be snapshotted
together. It is specified for dynamic provisioning of the VolumeGroupSnapshot.
This field is immutable.

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
