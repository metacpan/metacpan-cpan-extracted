package IO::K8s::CertManager::V1::VaultIssuer;
# ABSTRACT: Vault configures this issuer to sign certificates using a HashiCorp Vault PKI backend.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s auth                => '+IO::K8s::CertManager::V1::VaultAuth', { required => 'schema' };
k8s caBundle            => Str;
k8s caBundleSecretRef   => '+IO::K8s::CertManager::V1::SecretKeySelector';
k8s clientCertSecretRef => '+IO::K8s::CertManager::V1::SecretKeySelector';
k8s clientKeySecretRef  => '+IO::K8s::CertManager::V1::SecretKeySelector';
k8s namespace           => Str;
k8s path                => Str, { required => 'schema' };
k8s server              => Str, { required => 'schema' };
k8s serverName          => Str;










1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::CertManager::V1::VaultIssuer - Vault configures this issuer to sign certificates using a HashiCorp Vault PKI backend.

=head1 VERSION

version 1.108

=head2 auth

Auth configures how cert-manager authenticates with the Vault server.

=head2 caBundle

Base64-encoded bundle of PEM CAs which will be used to validate the certificate
chain presented by Vault. Only used if using HTTPS to connect to Vault and
ignored for HTTP connections.
Mutually exclusive with CABundleSecretRef.
If neither CABundle nor CABundleSecretRef are defined, the certificate bundle in
the cert-manager controller container is used to validate the TLS connection.

=head2 caBundleSecretRef

Reference to a Secret containing a bundle of PEM-encoded CAs to use when
verifying the certificate chain presented by Vault when using HTTPS.
Mutually exclusive with CABundle.
If neither CABundle nor CABundleSecretRef are defined, the certificate bundle in
the cert-manager controller container is used to validate the TLS connection.
If no key for the Secret is specified, cert-manager will default to 'ca.crt'.

=head2 clientCertSecretRef

Reference to a Secret containing a PEM-encoded Client Certificate to use when the
Vault server requires mTLS.

=head2 clientKeySecretRef

Reference to a Secret containing a PEM-encoded Client Private Key to use when the
Vault server requires mTLS.

=head2 namespace

Name of the vault namespace. Namespaces is a set of features within Vault Enterprise that allows Vault environments to support Secure Multi-tenancy. e.g: "ns1"
More about namespaces can be found here https://www.vaultproject.io/docs/enterprise/namespaces

=head2 path

Path is the mount path of the Vault PKI backend's `sign` endpoint, e.g:
"my_pki_mount/sign/my-role-name".

=head2 server

Server is the connection address for the Vault server, e.g: "https://vault.example.com:8200".

=head2 serverName

ServerName is used to verify the hostname on the returned certificates
by the Vault server.

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
