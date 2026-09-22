package IO::K8s::CertManager::V1::VenafiTPP;
# ABSTRACT: TPP specifies CyberArk Certificate Manager Self-Hosted configuration settings.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s caBundle          => Str;
k8s caBundleSecretRef => '+IO::K8s::CertManager::V1::SecretKeySelector';
k8s credentialsRef    => '+IO::K8s::CertManager::V1::CertManagerLocalObjectReference', { required => 'schema' };
k8s url               => Str, { required => 'schema' };





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::CertManager::V1::VenafiTPP - TPP specifies CyberArk Certificate Manager Self-Hosted configuration settings.

=head1 VERSION

version 1.108

=head2 caBundle

Base64-encoded bundle of PEM CAs which will be used to validate the certificate
chain presented by the CyberArk Certificate Manager Self-Hosted server. Only used if using HTTPS; ignored for HTTP.
If undefined, the certificate bundle in the cert-manager controller container
is used to validate the chain.

=head2 caBundleSecretRef

Reference to a Secret containing a base64-encoded bundle of PEM CAs
which will be used to validate the certificate chain presented by the CyberArk Certificate Manager Self-Hosted server.
Only used if using HTTPS; ignored for HTTP. Mutually exclusive with CABundle.
If neither CABundle nor CABundleSecretRef is defined, the certificate bundle in
the cert-manager controller container is used to validate the TLS connection.

=head2 credentialsRef

CredentialsRef is a reference to a Secret containing the CyberArk Certificate Manager Self-Hosted API credentials.
The secret must contain the key 'access-token' for the Access Token Authentication,
or two keys, 'username' and 'password' for the API Keys Authentication.

=head2 url

URL is the base URL for the vedsdk endpoint of the CyberArk Certificate Manager Self-Hosted instance,
for example: "https://tpp.example.com/vedsdk".

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
