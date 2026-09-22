package IO::K8s::Traefik::V1alpha1::ClientTLS;
# ABSTRACT: TLS defines TLS-specific configurations, including the CA, certificate, and key, which can be provided as a file path or file content.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s caSecret           => Str;
k8s certSecret         => Str;
k8s insecureSkipVerify => Bool;




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Traefik::V1alpha1::ClientTLS - TLS defines TLS-specific configurations, including the CA, certificate, and key, which can be provided as a file path or file content.

=head1 VERSION

version 1.108

=head2 caSecret

CASecret is the name of the referenced Kubernetes Secret containing the CA to validate the server certificate.
The CA certificate is extracted from key `tls.ca` or `ca.crt`.

=head2 certSecret

CertSecret is the name of the referenced Kubernetes Secret containing the client certificate.
The client certificate is extracted from the keys `tls.crt` and `tls.key`.

=head2 insecureSkipVerify

InsecureSkipVerify defines whether the server certificates should be validated.

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
