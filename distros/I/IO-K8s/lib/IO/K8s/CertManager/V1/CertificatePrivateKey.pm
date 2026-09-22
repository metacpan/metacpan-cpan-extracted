package IO::K8s::CertManager::V1::CertificatePrivateKey;
# ABSTRACT: Private key options.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s algorithm      => Str, { enum => [qw(RSA ECDSA Ed25519)] };
k8s encoding       => Str, { enum => [qw(PKCS1 PKCS8)] };
k8s rotationPolicy => Str, { enum => [qw(Never Always)] };
k8s size           => Int;





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::CertManager::V1::CertificatePrivateKey - Private key options.

=head1 VERSION

version 1.108

=head2 algorithm

Algorithm is the private key algorithm of the corresponding private key
for this certificate.

If provided, allowed values are either `RSA`, `ECDSA` or `Ed25519`.
If `algorithm` is specified and `size` is not provided,
key size of 2048 will be used for `RSA` key algorithm and
key size of 256 will be used for `ECDSA` key algorithm.
key size is ignored when using the `Ed25519` key algorithm.

=head2 encoding

The private key cryptography standards (PKCS) encoding for this
certificate's private key to be encoded in.

If provided, allowed values are `PKCS1` and `PKCS8` standing for PKCS#1
and PKCS#8, respectively.
Defaults to `PKCS1` if not specified.

=head2 rotationPolicy

RotationPolicy controls how private keys should be regenerated when a
re-issuance is being processed.

If set to `Never`, a private key will only be generated if one does not
already exist in the target `spec.secretName`. If one does exist but it
does not have the correct algorithm or size, a warning will be raised
to await user intervention.
If set to `Always`, a private key matching the specified requirements
will be generated whenever a re-issuance occurs.
Default is `Always`.
The default was changed from `Never` to `Always` in cert-manager >=v1.18.0.

=head2 size

Size is the key bit size of the corresponding private key for this certificate.

If `algorithm` is set to `RSA`, valid values are `2048`, `4096` or `8192`,
and will default to `2048` if not specified.
If `algorithm` is set to `ECDSA`, valid values are `256`, `384` or `521`,
and will default to `256` if not specified.
If `algorithm` is set to `Ed25519`, Size is ignored.
No other values are allowed.

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
