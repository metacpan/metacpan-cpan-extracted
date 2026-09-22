package IO::K8s::CertManager::V1::ACMEExternalAccountBinding;
# ABSTRACT: ExternalAccountBinding is a reference to a CA external account of the ACME server.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s keyAlgorithm => Str, { enum => [qw(HS256 HS384 HS512)] };
k8s keyID        => Str, { required => 'schema' };
k8s keySecretRef => '+IO::K8s::CertManager::V1::SecretKeySelector', { required => 'schema' };




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::CertManager::V1::ACMEExternalAccountBinding - ExternalAccountBinding is a reference to a CA external account of the ACME server.

=head1 VERSION

version 1.108

=head2 keyAlgorithm

Deprecated: keyAlgorithm field exists for historical compatibility
reasons and should not be used. The algorithm is now hardcoded to HS256
in golang/x/crypto/acme.

=head2 keyID

keyID is the ID of the CA key that the External Account is bound to.

=head2 keySecretRef

keySecretRef is a Secret Key Selector referencing a data item in a Kubernetes
Secret which holds the symmetric MAC key of the External Account Binding.
The `key` is the index string that is paired with the key data in the
Secret and should not be confused with the key data itself, or indeed with
the External Account Binding keyID above.
The secret key stored in the Secret **must** be un-padded, base64 URL
encoded data.

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
