package IO::K8s::ExternalSecrets::V1::OpenBaoProvider;
# ABSTRACT: OpenBao configures this store to sync secrets using the OpenBao provider.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s auth       => '+IO::K8s::ExternalSecrets::V1::OpenBaoAuth';
k8s caBundle   => Str;
k8s caProvider => '+IO::K8s::ExternalSecrets::V1::CAProvider';
k8s namespace  => Str;
k8s path       => Str;
k8s server     => Str, { required => 'schema' };
k8s version    => Str, { enum => [qw(v1 v2)], default => 'v2' };








1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::ExternalSecrets::V1::OpenBaoProvider - OpenBao configures this store to sync secrets using the OpenBao provider.

=head1 VERSION

version 1.108

=head2 auth

Auth configures how secret-manager authenticates with the OpenBao server.

=head2 caBundle

PEM encoded CA bundle used to validate the OpenBao server certificate. If
this and `caProvider` are not set the system root certificates are used
to validate the TLS connection.

=head2 caProvider

The provider for the CA bundle to use to validate OpenBao server
certificate. If this and `caBundle` are not set the system root
certificates are used to validate the TLS connection.

=head2 namespace

Name of the [OpenBao Namespace]. Namespaces is a set of features within
OpenBao that allows OpenBao environments to support secure multi-tenancy.
e.g: "ns1".

[OpenBao Namespace]: https://openbao.org/docs/concepts/namespaces/

=head2 path

Path is the mount path of the OpenBao KV backend endpoint, e.g:
"secret". The v2 KV secret engine version specific "/data" path suffix
for fetching secrets from OpenBao is optional and will be appended
if not present in specified path.

=head2 server

Server is the connection address for the OpenBao server, e.g: `https://openbao.example.com:8200`.

=head2 version

Version is the OpenBao KV secret engine version. This can be either "v1" or
"v2". Version defaults to "v2".

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
