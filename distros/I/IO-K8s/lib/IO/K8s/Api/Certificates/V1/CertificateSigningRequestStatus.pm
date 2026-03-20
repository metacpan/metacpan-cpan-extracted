package IO::K8s::Api::Certificates::V1::CertificateSigningRequestStatus;
# ABSTRACT: CertificateSigningRequestStatus contains conditions used to indicate approved/denied/failed status of the request, and the issued certificate.
our $VERSION = '1.009';
use IO::K8s::Resource;

k8s certificate => Str;


k8s conditions => ['Certificates::V1::CertificateSigningRequestCondition'];


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Certificates::V1::CertificateSigningRequestStatus - CertificateSigningRequestStatus contains conditions used to indicate approved/denied/failed status of the request, and the issued certificate.

=head1 VERSION

version 1.009

=head2 certificate

certificate is populated with an issued certificate by the signer after an Approved condition is present. This field is set via the /status subresource. Once populated, this field is immutable.

If the certificate signing request is denied, a condition of type "Denied" is added and this field remains empty. If the signer cannot issue the certificate, a condition of type "Failed" is added and this field remains empty.

Validation requirements:
 1. certificate must contain one or more PEM blocks.
 2. All PEM blocks must have the "CERTIFICATE" label, contain no headers, and the encoded data
  must be a BER-encoded ASN.1 Certificate structure as described in section 4 of RFC5280.
 3. Non-PEM content may appear before or after the "CERTIFICATE" PEM blocks and is unvalidated,
  to allow for explanatory text as described in section 5.2 of RFC7468.

If more than one PEM block is present, and the definition of the requested spec.signerName does not indicate otherwise, the first block is the issued certificate, and subsequent blocks should be treated as intermediate certificates and presented in TLS handshakes.

The certificate is encoded in PEM format.

When serialized as JSON or YAML, the data is additionally base64-encoded, so it consists of:

    base64(
    -----BEGIN CERTIFICATE-----
    ...
    -----END CERTIFICATE-----
    )

=head2 conditions

conditions applied to the request. Known conditions are "Approved", "Denied", and "Failed".

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/pplu/io-k8s-p5/issues>.

=head2 IRC

Join C<#kubernetes> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHORS

=over 4

=item *

Torsten Raudssus <torsten@raudssus.de>

=item *

Jose Luis Martinez Torres <jlmartin@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018-2026 by Jose Luis Martinez Torres <jlmartin@cpan.org>.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
