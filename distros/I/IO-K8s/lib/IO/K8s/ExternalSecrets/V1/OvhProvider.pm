package IO::K8s::ExternalSecrets::V1::OvhProvider;
# ABSTRACT: OVHcloud configures this store to sync secrets using the OVHcloud provider.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s auth        => '+IO::K8s::ExternalSecrets::V1::OvhAuth', { required => 'schema' };
k8s casRequired => Bool;
k8s okmsTimeout => Int, { minimum => 1, default => 30 };
k8s okmsid      => Str, { required => 'schema' };
k8s server      => Str, { required => 'schema' };






1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::ExternalSecrets::V1::OvhProvider - OVHcloud configures this store to sync secrets using the OVHcloud provider.

=head1 VERSION

version 1.108

=head2 auth

Authentication method (mtls or token).

=head2 casRequired

Enables or disables check-and-set (CAS) (default: false).

=head2 okmsTimeout

Setup a timeout in seconds when requests to the KMS are made (default: 30).

=head2 okmsid

specifies the OKMS ID.

=head2 server

specifies the OKMS server endpoint.

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
