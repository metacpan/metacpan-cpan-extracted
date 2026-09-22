package IO::K8s::Traefik::V1alpha1::PassTLSClientCert;
# ABSTRACT: PassTLSClientCert holds the pass TLS client cert middleware configuration.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s info => '+IO::K8s::Traefik::V1alpha1::TLSClientCertificateInfo';
k8s pem  => Bool;



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Traefik::V1alpha1::PassTLSClientCert - PassTLSClientCert holds the pass TLS client cert middleware configuration.

=head1 VERSION

version 1.108

=head2 info

Info selects the specific client certificate details you want to add to the X-Forwarded-Tls-Client-Cert-Info header.

=head2 pem

PEM sets the X-Forwarded-Tls-Client-Cert header with the certificate.

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
