package IO::K8s::Cilium::V2::TLSContext;
# ABSTRACT: TerminatingTLS is the TLS context for the connection terminated by the L7 proxy.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s certificate => Str;
k8s privateKey  => Str;
k8s secret      => 'Core::V1::SecretReference', { required => 'schema' };
k8s trustedCA   => Str;





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Cilium::V2::TLSContext - TerminatingTLS is the TLS context for the connection terminated by the L7 proxy.

=head1 VERSION

version 1.108

=head2 certificate

Certificate is the file name or k8s secret item name for the certificate
chain. If omitted, 'tls.crt' is assumed, if it exists. If given, the
item must exist.

=head2 privateKey

PrivateKey is the file name or k8s secret item name for the private key
matching the certificate chain. If omitted, 'tls.key' is assumed, if it
exists. If given, the item must exist.

=head2 secret

Secret is the secret that contains the certificates and private key for
the TLS context.
By default, Cilium will search in this secret for the following items:
 - 'ca.crt'  - Which represents the trusted CA to verify remote source.
 - 'tls.crt' - Which represents the public key certificate.
 - 'tls.key' - Which represents the private key matching the public key
               certificate.

=head2 trustedCA

TrustedCA is the file name or k8s secret item name for the trusted CA.
If omitted, 'ca.crt' is assumed, if it exists. If given, the item must
exist.

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
