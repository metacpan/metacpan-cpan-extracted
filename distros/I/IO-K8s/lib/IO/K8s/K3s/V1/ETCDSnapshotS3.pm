package IO::K8s::K3s::V1::ETCDSnapshotS3;
# ABSTRACT: ETCDSnapshotS3 holds information about the S3 storage system holding the snapshot.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s bucket        => Str;
k8s bucketLookup  => Str;
k8s endpoint      => Str;
k8s endpointCA    => Str;
k8s insecure      => Bool;
k8s prefix        => Str;
k8s region        => Str;
k8s skipSSLVerify => Bool;









1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::K3s::V1::ETCDSnapshotS3 - ETCDSnapshotS3 holds information about the S3 storage system holding the snapshot.

=head1 VERSION

version 1.108

=head2 bucket

Bucket is the bucket holding the snapshot

=head2 bucketLookup

BucketLookup is the bucket lookup type, one of 'auto', 'dns', 'path'. Default if empty is 'auto'.

=head2 endpoint

Endpoint is the host or host:port of the S3 service

=head2 endpointCA

EndpointCA is the path on disk to the S3 service's trusted CA list. Leave empty to use the OS CA bundle.

=head2 insecure

Insecure is true if the S3 service uses HTTP instead of HTTPS

=head2 prefix

Prefix is the prefix in which the snapshot file is stored.

=head2 region

Region is the region of the S3 service

=head2 skipSSLVerify

SkipSSLVerify is true if TLS certificate verification is disabled

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
