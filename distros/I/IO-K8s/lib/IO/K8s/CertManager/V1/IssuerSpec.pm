package IO::K8s::CertManager::V1::IssuerSpec;
# ABSTRACT: Desired state of the Issuer resource.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s acme       => '+IO::K8s::CertManager::V1::ACMEIssuer';
k8s ca         => '+IO::K8s::CertManager::V1::CAIssuer';
k8s selfSigned => '+IO::K8s::CertManager::V1::SelfSignedIssuer';
k8s vault      => '+IO::K8s::CertManager::V1::VaultIssuer';
k8s venafi     => '+IO::K8s::CertManager::V1::VenafiIssuer';






1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::CertManager::V1::IssuerSpec - Desired state of the Issuer resource.

=head1 VERSION

version 1.108

=head2 acme

ACME configures this issuer to communicate with a RFC8555 (ACME) server
to obtain signed x509 certificates.

=head2 ca

CA configures this issuer to sign certificates using a signing CA keypair
stored in a Secret resource.
This is used to build internal PKIs that are managed by cert-manager.

=head2 selfSigned

SelfSigned configures this issuer to 'self sign' certificates using the
private key used to create the CertificateRequest object.

=head2 vault

Vault configures this issuer to sign certificates using a HashiCorp Vault
PKI backend.

=head2 venafi

Venafi configures this issuer to sign certificates using a CyberArk Certificate Manager Self-Hosted
or SaaS policy zone.

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
