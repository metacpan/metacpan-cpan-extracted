package IO::K8s::K3s::V1::ETCDSnapshotFile;
# ABSTRACT: ETCDSnapshot tracks a point-in-time snapshot of the etcd datastore.
our $VERSION = '1.108';
use IO::K8s::APIObject
    api_version     => 'k3s.cattle.io/v1',
    resource_plural => 'etcdsnapshotfiles';

k8s spec   => '+IO::K8s::K3s::V1::ETCDSnapshotSpec', { required => 'schema' };
k8s status => '+IO::K8s::K3s::V1::ETCDSnapshotStatus';



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::K3s::V1::ETCDSnapshotFile - ETCDSnapshot tracks a point-in-time snapshot of the etcd datastore.

=head1 VERSION

version 1.108

=head2 spec

Spec defines properties of an etcd snapshot file

=head2 status

Status represents current information about a snapshot.

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
