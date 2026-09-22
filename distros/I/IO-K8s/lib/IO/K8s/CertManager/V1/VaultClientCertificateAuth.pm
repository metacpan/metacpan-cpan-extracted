package IO::K8s::CertManager::V1::VaultClientCertificateAuth;
# ABSTRACT: ClientCertificate authenticates with Vault by presenting a client certificate during the request's TLS handshake.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s mountPath  => Str;
k8s name       => Str;
k8s secretName => Str;




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::CertManager::V1::VaultClientCertificateAuth - ClientCertificate authenticates with Vault by presenting a client certificate during the request's TLS handshake.

=head1 VERSION

version 1.108

=head2 mountPath

The Vault mountPath here is the mount path to use when authenticating with
Vault. For example, setting a value to `/v1/auth/foo`, will use the path
`/v1/auth/foo/login` to authenticate with Vault. If unspecified, the
default value "/v1/auth/cert" will be used.

=head2 name

Name of the certificate role to authenticate against.
If not set, matching any certificate role, if available.

=head2 secretName

Reference to Kubernetes Secret of type "kubernetes.io/tls" (hence containing
tls.crt and tls.key) used to authenticate to Vault using TLS client
authentication.

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
