package IO::K8s::CertManager::V1::X509Subject;
# ABSTRACT: Requested set of X509 certificate subject attributes.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s countries           => [Str];
k8s localities          => [Str];
k8s organizationalUnits => [Str];
k8s organizations       => [Str];
k8s postalCodes         => [Str];
k8s provinces           => [Str];
k8s serialNumber        => Str;
k8s streetAddresses     => [Str];









1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::CertManager::V1::X509Subject - Requested set of X509 certificate subject attributes.

=head1 VERSION

version 1.108

=head2 countries

Countries to be used on the Certificate.

=head2 localities

Cities to be used on the Certificate.

=head2 organizationalUnits

Organizational Units to be used on the Certificate.

=head2 organizations

Organizations to be used on the Certificate.

=head2 postalCodes

Postal codes to be used on the Certificate.

=head2 provinces

State/Provinces to be used on the Certificate.

=head2 serialNumber

Serial number to be used on the Certificate.

=head2 streetAddresses

Street addresses to be used on the Certificate.

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
