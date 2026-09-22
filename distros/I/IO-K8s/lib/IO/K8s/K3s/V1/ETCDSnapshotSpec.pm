package IO::K8s::K3s::V1::ETCDSnapshotSpec;
# ABSTRACT: ETCDSnapshotSpec desribes an etcd snapshot file
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s location     => Str, { required => 'schema' };
k8s metadata     => { Str => 1 };
k8s nodeName     => Str, { required => 'schema' };
k8s s3           => '+IO::K8s::K3s::V1::ETCDSnapshotS3';
k8s snapshotName => Str, { required => 'schema' };






1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::K3s::V1::ETCDSnapshotSpec - ETCDSnapshotSpec desribes an etcd snapshot file

=head1 VERSION

version 1.108

=head2 location

Location is the absolute file:// or s3:// URI address of the snapshot.

=head2 metadata

Metadata contains point-in-time snapshot of the contents of the
k3s-etcd-snapshot-extra-metadata ConfigMap's data field, at the time the
snapshot was taken. This is intended to contain data about cluster state
that may be important for an external system to have available when restoring
the snapshot.

=head2 nodeName

NodeName contains the name of the node that took the snapshot.

=head2 s3

S3 contains extra metadata about the S3 storage system holding the
snapshot. This is guaranteed to be set for all snapshots uploaded to S3.
If not specified, the snapshot was not uploaded to S3.

=head2 snapshotName

SnapshotName contains the base name of the snapshot file. CLI actions that act
on snapshots stored locally or within a pre-configured S3 bucket and
prefix usually take the snapshot name as their argument.

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
