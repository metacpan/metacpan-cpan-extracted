package IO::K8s::VolumeSnapshot::V1::VolumeSnapshot;
# ABSTRACT: VolumeSnapshot is a user's request for either creating a point-in-time snapshot of a persistent volume, or binding to a pre-existing snapshot.
our $VERSION = '1.108';
use IO::K8s::APIObject
    api_version     => 'snapshot.storage.k8s.io/v1',
    resource_plural => 'volumesnapshots';
with 'IO::K8s::Role::Namespaced';

k8s spec   => '+IO::K8s::VolumeSnapshot::V1::VolumeSnapshotSpec', { required => 'schema' };
k8s status => '+IO::K8s::VolumeSnapshot::V1::VolumeSnapshotStatus';



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::VolumeSnapshot::V1::VolumeSnapshot - VolumeSnapshot is a user's request for either creating a point-in-time snapshot of a persistent volume, or binding to a pre-existing snapshot.

=head1 VERSION

version 1.108

=head2 spec

spec defines the desired characteristics of a snapshot requested by a user.
More info: https://kubernetes.io/docs/concepts/storage/volume-snapshots#volumesnapshots
Required.

=head2 status

status represents the current information of a snapshot.
Consumers must verify binding between VolumeSnapshot and
VolumeSnapshotContent objects is successful (by validating that both
VolumeSnapshot and VolumeSnapshotContent point at each other) before
using this object.

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
