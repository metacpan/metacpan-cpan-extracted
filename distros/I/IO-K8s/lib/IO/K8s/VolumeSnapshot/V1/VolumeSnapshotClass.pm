package IO::K8s::VolumeSnapshot::V1::VolumeSnapshotClass;
# ABSTRACT: VolumeSnapshotClass specifies parameters that a underlying storage system uses when creating a volume snapshot.
our $VERSION = '1.108';
use IO::K8s::APIObject
    api_version     => 'snapshot.storage.k8s.io/v1',
    resource_plural => 'volumesnapshotclasses';

k8s deletionPolicy => Str, { required => 'schema', enum => [qw(Delete Retain)] };
k8s driver         => Str, { required => 'schema' };
k8s parameters     => { Str => 1 };




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::VolumeSnapshot::V1::VolumeSnapshotClass - VolumeSnapshotClass specifies parameters that a underlying storage system uses when creating a volume snapshot.

=head1 VERSION

version 1.108

=head2 deletionPolicy

deletionPolicy determines whether a VolumeSnapshotContent created through
the VolumeSnapshotClass should be deleted when its bound VolumeSnapshot is deleted.
Supported values are "Retain" and "Delete".
"Retain" means that the VolumeSnapshotContent and its physical snapshot on underlying storage system are kept.
"Delete" means that the VolumeSnapshotContent and its physical snapshot on underlying storage system are deleted.
Required.

=head2 driver

driver is the name of the storage driver that handles this VolumeSnapshotClass.
Required.

=head2 parameters

parameters is a key-value map with storage driver specific parameters for creating snapshots.
These values are opaque to Kubernetes.

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
