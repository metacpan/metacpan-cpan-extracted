package IO::K8s::VolumeSnapshot::V1beta2::VolumeGroupSnapshotSource;
# ABSTRACT: VolumeGroupSnapshotSource specifies a new or pre-existing group snapshot source
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s selector => 'Meta::V1::LabelSelector';


k8s volumeGroupSnapshotContentName => Str;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::VolumeSnapshot::V1beta2::VolumeGroupSnapshotSource - VolumeGroupSnapshotSource specifies a new or pre-existing group snapshot source

=head1 VERSION

version 1.108

=head2 selector

Selector is a label query over persistent volume claims that are to be
grouped together for snapshotting.
This labelSelector will be used to match the label added to a PVC.
If the label is added or removed to a volume after a group snapshot
is created, the existing group snapshots won't be modified.
Once a VolumeGroupSnapshotContent is created and the sidecar starts to process
it, the volume list will not change with retries.

=head2 volumeGroupSnapshotContentName

VolumeGroupSnapshotContentName specifies the name of a pre-existing VolumeGroupSnapshotContent
object representing an existing volume group snapshot.
This field should be set if the volume group snapshot already exists and
only needs a representation in Kubernetes.
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
