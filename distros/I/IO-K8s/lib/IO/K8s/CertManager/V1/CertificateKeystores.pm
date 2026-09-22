package IO::K8s::CertManager::V1::CertificateKeystores;
# ABSTRACT: Additional keystore output formats to be stored in the Certificate's Secret.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s jks    => '+IO::K8s::CertManager::V1::JKSKeystore';
k8s pkcs12 => '+IO::K8s::CertManager::V1::PKCS12Keystore';



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::CertManager::V1::CertificateKeystores - Additional keystore output formats to be stored in the Certificate's Secret.

=head1 VERSION

version 1.108

=head2 jks

JKS configures options for storing a JKS keystore in the
`spec.secretName` Secret resource.

=head2 pkcs12

PKCS12 configures options for storing a PKCS12 keystore in the
`spec.secretName` Secret resource.

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
