package IO::K8s::CertManager::V1::CertificateRequestSpec;
# ABSTRACT: Specification of the desired state of the CertificateRequest resource.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s duration  => Str;
k8s extra     => { Str => 1 };
k8s groups    => [Str];
k8s isCA      => Bool;
k8s issuerRef => '+IO::K8s::CertManager::V1::IssuerReference', { required => 'schema' };
k8s request   => Str, { required => 'schema' };
k8s uid       => Str;
k8s usages    => [Str], { enum => ['signing','digital signature','content commitment','key encipherment','key agreement','data encipherment','cert sign','crl sign','encipher only','decipher only','any','server auth','client auth','code signing','email protection','s/mime','ipsec end system','ipsec tunnel','ipsec user','timestamping','ocsp signing','microsoft sgc','netscape sgc'] };
k8s username  => Str;










1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::CertManager::V1::CertificateRequestSpec - Specification of the desired state of the CertificateRequest resource.

=head1 VERSION

version 1.108

=head2 duration

Requested 'duration' (i.e. lifetime) of the Certificate. Note that the
issuer may choose to ignore the requested duration, just like any other
requested attribute.

=head2 extra

Extra contains extra attributes of the user that created the CertificateRequest.
Populated by the cert-manager webhook on creation and immutable.

=head2 groups

Groups contains group membership of the user that created the CertificateRequest.
Populated by the cert-manager webhook on creation and immutable.

=head2 isCA

Requested basic constraints isCA value. Note that the issuer may choose
to ignore the requested isCA value, just like any other requested attribute.

NOTE: If the CSR in the `Request` field has a BasicConstraints extension,
it must have the same isCA value as specified here.

If true, this will automatically add the `cert sign` usage to the list
of requested `usages`.

=head2 issuerRef

Reference to the issuer responsible for issuing the certificate.
If the issuer is namespace-scoped, it must be in the same namespace
as the Certificate. If the issuer is cluster-scoped, it can be used
from any namespace.

The `name` field of the reference must always be specified.

=head2 request

The PEM-encoded X.509 certificate signing request to be submitted to the
issuer for signing.

If the CSR has a BasicConstraints extension, its isCA attribute must
match the `isCA` value of this CertificateRequest.
If the CSR has a KeyUsage extension, its key usages must match the
key usages in the `usages` field of this CertificateRequest.
If the CSR has a ExtKeyUsage extension, its extended key usages
must match the extended key usages in the `usages` field of this
CertificateRequest.

=head2 uid

UID contains the uid of the user that created the CertificateRequest.
Populated by the cert-manager webhook on creation and immutable.

=head2 usages

Requested key usages and extended key usages.

NOTE: If the CSR in the `Request` field has uses the KeyUsage or
ExtKeyUsage extension, these extensions must have the same values
as specified here without any additional values.

If unset, defaults to `digital signature` and `key encipherment`.

=head2 username

Username contains the name of the user that created the CertificateRequest.
Populated by the cert-manager webhook on creation and immutable.

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
