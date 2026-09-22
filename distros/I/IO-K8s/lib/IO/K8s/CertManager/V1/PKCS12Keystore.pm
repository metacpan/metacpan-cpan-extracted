package IO::K8s::CertManager::V1::PKCS12Keystore;
# ABSTRACT: PKCS12 configures options for storing a PKCS12 keystore in the `spec.secretName` Secret resource.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s create            => Bool, { required => 'schema' };
k8s password          => Str;
k8s passwordSecretRef => '+IO::K8s::CertManager::V1::SecretKeySelector';
k8s profile           => Str, { enum => [qw(LegacyRC2 LegacyDES Modern2023 Modern2026)] };





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::CertManager::V1::PKCS12Keystore - PKCS12 configures options for storing a PKCS12 keystore in the `spec.secretName` Secret resource.

=head1 VERSION

version 1.108

=head2 create

Create enables PKCS12 keystore creation for the Certificate.
If true, a file named `keystore.p12` will be created in the target
Secret resource, encrypted using the password stored in
`passwordSecretRef` or in `password`.
The keystore file will be updated immediately.
If the issuer provided a CA certificate, a file named `truststore.p12` will
also be created in the target Secret resource, encrypted using the
password stored in `passwordSecretRef` containing the issuing Certificate
Authority

=head2 password

Password provides a literal password used to encrypt the PKCS#12 keystore.
Mutually exclusive with passwordSecretRef.
One of password or passwordSecretRef must provide a password with a non-zero length.

=head2 passwordSecretRef

PasswordSecretRef is a reference to a non-empty key in a Secret resource
containing the password used to encrypt the PKCS#12 keystore.
Mutually exclusive with password.
One of password or passwordSecretRef must provide a password with a non-zero length.

=head2 profile

Profile specifies the key and certificate encryption algorithms and the HMAC algorithm
used to create the PKCS12 keystore. Default value is `LegacyRC2` for backward compatibility.

If provided, allowed values are:
`LegacyRC2`: Deprecated. Not supported by default in OpenSSL 3 or Java 20.
`LegacyDES`: Less secure algorithm. Use this option for maximal compatibility.
`Modern2023`: Secure algorithm. Use this option in case you have to always use secure algorithms
(e.g., because of company policy). Please note that the security of the algorithm is not that important
in reality, because the unencrypted certificate and private key are also stored in the Secret.
`Modern2026`: Encodes PKCS#12 files using algorithms that are considered modern as of 2026.
Private keys and certificates are encrypted using PBES2 with PBKDF2-HMAC-SHA-256 and AES-256-CBC.
The MAC algorithm is PBMAC1 with PBKDF2-HMAC-SHA-256 and HMAC-SHA256.
Files produced with this profile can be read by OpenSSL 3.4.0 and higher, Java 26 and higher,
or with Java using compatible versions of Bouncy Castle. Meets FIPS 140-3 requirements.

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
