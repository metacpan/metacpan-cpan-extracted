package IO::K8s::VolumeSnapshot::V1::VolumeSnapshotContentSource;
# ABSTRACT: source specifies whether the snapshot is (or should be) dynamically provisioned or already exists, and just requires a Kubernetes object representation.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s snapshotHandle => Str;
k8s volumeHandle   => Str;



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::VolumeSnapshot::V1::VolumeSnapshotContentSource - source specifies whether the snapshot is (or should be) dynamically provisioned or already exists, and just requires a Kubernetes object representation.

=head1 VERSION

version 1.108

=head2 snapshotHandle

snapshotHandle specifies the CSI "snapshot_id" of a pre-existing snapshot on
the underlying storage system for which a Kubernetes object representation
was (or should be) created.
This field is immutable.

=head2 volumeHandle

volumeHandle specifies the CSI "volume_id" of the volume from which a snapshot
should be dynamically taken from.
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
