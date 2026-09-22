package IO::K8s::VolumeSnapshot::V1beta1::VolumeGroupSnapshot;
# ABSTRACT: VolumeGroupSnapshot is a user's request for creating a point-in-time group snapshot
our $VERSION = '1.108';
use IO::K8s::APIObject
    api_version     => 'groupsnapshot.storage.k8s.io/v1beta1',
    resource_plural => 'volumegroupsnapshots';
with 'IO::K8s::Role::Namespaced';


k8s spec => '+IO::K8s::VolumeSnapshot::V1beta1::VolumeGroupSnapshotSpec', { required => 'schema' };


k8s status => '+IO::K8s::VolumeSnapshot::V1beta1::VolumeGroupSnapshotStatus';



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::VolumeSnapshot::V1beta1::VolumeGroupSnapshot - VolumeGroupSnapshot is a user's request for creating a point-in-time group snapshot

=head1 VERSION

version 1.108

=head1 DESCRIPTION

VolumeGroupSnapshot is a user's request for creating either a point-in-time
group snapshot or binding to a pre-existing group snapshot.

This is a Kubernetes API object. See L<IO::K8s::Role::APIObject> for
C<metadata>, C<api_version()>, and C<kind()>.

=head2 spec

Spec defines the desired characteristics of a group snapshot requested by a user.
Required.

=head2 status

Status represents the current information of a group snapshot.
Consumers must verify binding between VolumeGroupSnapshot and
VolumeGroupSnapshotContent objects is successful (by validating that both
VolumeGroupSnapshot and VolumeGroupSnapshotContent point to each other) before
using this object.

=head1 SEE ALSO

L<external-snapshotter v8.6.0 VolumeGroupSnapshot CRD|https://github.com/kubernetes-csi/external-snapshotter/blob/v8.6.0/client/config/crd/groupsnapshot.storage.k8s.io_volumegroupsnapshots.yaml>

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
