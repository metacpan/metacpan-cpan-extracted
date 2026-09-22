package IO::K8s::CertManager::V1::JKSKeystore;
# ABSTRACT: JKS configures options for storing a JKS keystore in the `spec.secretName` Secret resource.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s alias             => Str;
k8s create            => Bool, { required => 'schema' };
k8s password          => Str;
k8s passwordSecretRef => '+IO::K8s::CertManager::V1::SecretKeySelector';





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::CertManager::V1::JKSKeystore - JKS configures options for storing a JKS keystore in the `spec.secretName` Secret resource.

=head1 VERSION

version 1.108

=head2 alias

Alias specifies the alias of the key in the keystore, required by the JKS format.
If not provided, the default alias `certificate` will be used.

=head2 create

Create enables JKS keystore creation for the Certificate.
If true, a file named `keystore.jks` will be created in the target
Secret resource, encrypted using the password stored in
`passwordSecretRef` or `password`.
The keystore file will be updated immediately.
If the issuer provided a CA certificate, a file named `truststore.jks`
will also be created in the target Secret resource, encrypted using the
password stored in `passwordSecretRef`
containing the issuing Certificate Authority

=head2 password

Password provides a literal password used to encrypt the JKS keystore.
Mutually exclusive with passwordSecretRef.
One of password or passwordSecretRef must provide a password with a non-zero length.

=head2 passwordSecretRef

PasswordSecretRef is a reference to a non-empty key in a Secret resource
containing the password used to encrypt the JKS keystore.
Mutually exclusive with password.
One of password or passwordSecretRef must provide a password with a non-zero length.

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
