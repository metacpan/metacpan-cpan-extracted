package IO::K8s::CertManager::V1::OrderSpec;
# ABSTRACT: OrderSpec
our $VERSION = '1.108';
use utf8;
use IO::K8s::Resource;

k8s commonName  => Str;
k8s dnsNames    => [Str];
k8s duration    => Str;
k8s ipAddresses => [Str];
k8s issuerRef   => '+IO::K8s::CertManager::V1::IssuerReference', { required => 'schema' };
k8s profile     => Str;
k8s replaces    => Str;
k8s request     => Str, { required => 'schema' };










1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::CertManager::V1::OrderSpec - OrderSpec

=head1 VERSION

version 1.108

=head2 commonName

CommonName is the common name as specified on the DER encoded CSR.
If specified, this value must also be present in `dnsNames` or `ipAddresses`.
This field must match the corresponding field on the DER encoded CSR.

=head2 dnsNames

DNSNames is a list of DNS names that should be included as part of the Order
validation process.
This field must match the corresponding field on the DER encoded CSR.

=head2 duration

Duration is the duration for the not after date for the requested certificate.
This is set on order creation as per the ACME spec.

=head2 ipAddresses

IPAddresses is a list of IP addresses that should be included as part of the Order
validation process.
This field must match the corresponding field on the DER encoded CSR.

=head2 issuerRef

IssuerRef references a properly configured ACME-type Issuer which should
be used to create this Order.
If the Issuer does not exist, processing will be retried.
If the Issuer is not an 'ACME' Issuer, an error will be returned and the
Order will be marked as failed.

=head2 profile

Profile allows requesting a certificate profile from the ACME server.
Supported profiles are listed by the server's ACME directory URL.

=head2 replaces

Replaces is the ARI CertID (RFC 9773 §4.1) of the certificate that this
Order is intended to replace. When set, cert-manager will include the
"replaces" field on the newOrder request to the ACME server if and only
if the server advertises ARI support in its directory. The CertID has
the form "base64url(AKI).base64url(serial)" and is derived locally from
the currently issued leaf certificate.

=head2 request

Certificate signing request bytes in DER encoding.
This will be used when finalizing the order.
This field must be set on the order.

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
