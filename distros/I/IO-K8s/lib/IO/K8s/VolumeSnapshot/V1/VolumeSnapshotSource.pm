package IO::K8s::VolumeSnapshot::V1::VolumeSnapshotSource;
# ABSTRACT: source specifies where a snapshot will be created from.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s persistentVolumeClaimName => Str;
k8s volumeSnapshotContentName => Str;



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::VolumeSnapshot::V1::VolumeSnapshotSource - source specifies where a snapshot will be created from.

=head1 VERSION

version 1.108

=head2 persistentVolumeClaimName

persistentVolumeClaimName specifies the name of the PersistentVolumeClaim
object representing the volume from which a snapshot should be created.
This PVC is assumed to be in the same namespace as the VolumeSnapshot
object.
This field should be set if the snapshot does not exists, and needs to be
created.
This field is immutable.

=head2 volumeSnapshotContentName

volumeSnapshotContentName specifies the name of a pre-existing VolumeSnapshotContent
object representing an existing volume snapshot.
This field should be set if the snapshot already exists and only needs a representation in Kubernetes.
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
