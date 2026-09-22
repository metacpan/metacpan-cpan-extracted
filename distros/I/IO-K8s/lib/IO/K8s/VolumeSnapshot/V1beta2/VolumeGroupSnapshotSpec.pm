package IO::K8s::VolumeSnapshot::V1beta2::VolumeGroupSnapshotSpec;
# ABSTRACT: VolumeGroupSnapshotSpec defines the desired state of a volume group snapshot
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s source => '+IO::K8s::VolumeSnapshot::V1beta2::VolumeGroupSnapshotSource', { required => 'schema' };


k8s volumeGroupSnapshotClassName => Str;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::VolumeSnapshot::V1beta2::VolumeGroupSnapshotSpec - VolumeGroupSnapshotSpec defines the desired state of a volume group snapshot

=head1 VERSION

version 1.108

=head2 source

Source specifies where a group snapshot will be created from.
This field is immutable after creation.
Required.

=head2 volumeGroupSnapshotClassName

VolumeGroupSnapshotClassName is the name of the VolumeGroupSnapshotClass
requested by the VolumeGroupSnapshot.
VolumeGroupSnapshotClassName may be left nil to indicate that the default
class will be used.
Empty string is not allowed for this field.

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
