package IO::K8s::Traefik::V1alpha1::TLSClientCertificateInfo;
# ABSTRACT: Info selects the specific client certificate details you want to add to the X-Forwarded-Tls-Client-Cert-Info header.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s issuer       => '+IO::K8s::Traefik::V1alpha1::TLSClientCertificateIssuerDNInfo';
k8s notAfter     => Bool;
k8s notBefore    => Bool;
k8s sans         => Bool;
k8s serialNumber => Bool;
k8s subject      => '+IO::K8s::Traefik::V1alpha1::TLSClientCertificateSubjectDNInfo';







1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Traefik::V1alpha1::TLSClientCertificateInfo - Info selects the specific client certificate details you want to add to the X-Forwarded-Tls-Client-Cert-Info header.

=head1 VERSION

version 1.108

=head2 issuer

Issuer defines the client certificate issuer details to add to the X-Forwarded-Tls-Client-Cert-Info header.

=head2 notAfter

NotAfter defines whether to add the Not After information from the Validity part.

=head2 notBefore

NotBefore defines whether to add the Not Before information from the Validity part.

=head2 sans

Sans defines whether to add the Subject Alternative Name information from the Subject Alternative Name part.

=head2 serialNumber

SerialNumber defines whether to add the client serialNumber information.

=head2 subject

Subject defines the client certificate subject details to add to the X-Forwarded-Tls-Client-Cert-Info header.

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
