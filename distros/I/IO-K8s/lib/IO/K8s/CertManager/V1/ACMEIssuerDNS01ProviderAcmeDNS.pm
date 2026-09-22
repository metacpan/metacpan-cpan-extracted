package IO::K8s::CertManager::V1::ACMEIssuerDNS01ProviderAcmeDNS;
# ABSTRACT: Use the 'ACME DNS' (https://github.com/joohoi/acme-dns) API to manage DNS01 challenge records.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s accountSecretRef => '+IO::K8s::CertManager::V1::SecretKeySelector', { required => 'schema' };
k8s host             => Str, { required => 'schema' };



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::CertManager::V1::ACMEIssuerDNS01ProviderAcmeDNS - Use the 'ACME DNS' (https://github.com/joohoi/acme-dns) API to manage DNS01 challenge records.

=head1 VERSION

version 1.108

=head2 accountSecretRef

A reference to a specific 'key' within a Secret resource.
In some instances, `key` is a required field.

=head2 host

No description in the upstream schema.

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
