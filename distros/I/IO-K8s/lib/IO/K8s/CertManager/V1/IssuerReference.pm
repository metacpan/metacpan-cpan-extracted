package IO::K8s::CertManager::V1::IssuerReference;
# ABSTRACT: Reference to the issuer responsible for issuing the certificate.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s group => Str;
k8s kind  => Str;
k8s name  => Str, { required => 'schema' };




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::CertManager::V1::IssuerReference - Reference to the issuer responsible for issuing the certificate.

=head1 VERSION

version 1.108

=head2 group

Group of the issuer being referred to.
Defaults to 'cert-manager.io'.

=head2 kind

Kind of the issuer being referred to.
Defaults to 'Issuer'.

=head2 name

Name of the issuer being referred to.

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
