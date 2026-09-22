package IO::K8s::CertManager::V1::ACMEChallengeSolverDNS01;
# ABSTRACT: Configures cert-manager to attempt to complete authorizations by performing the DNS01 challenge flow.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s acmeDNS       => '+IO::K8s::CertManager::V1::ACMEIssuerDNS01ProviderAcmeDNS';
k8s akamai        => '+IO::K8s::CertManager::V1::ACMEIssuerDNS01ProviderAkamai';
k8s azureDNS      => '+IO::K8s::CertManager::V1::ACMEIssuerDNS01ProviderAzureDNS';
k8s cloudDNS      => '+IO::K8s::CertManager::V1::ACMEIssuerDNS01ProviderCloudDNS';
k8s cloudflare    => '+IO::K8s::CertManager::V1::ACMEIssuerDNS01ProviderCloudflare';
k8s cnameStrategy => Str, { enum => [qw(None Follow)] };
k8s digitalocean  => '+IO::K8s::CertManager::V1::ACMEIssuerDNS01ProviderDigitalOcean';
k8s rfc2136       => '+IO::K8s::CertManager::V1::ACMEIssuerDNS01ProviderRFC2136';
k8s route53       => '+IO::K8s::CertManager::V1::ACMEIssuerDNS01ProviderRoute53';
k8s webhook       => '+IO::K8s::CertManager::V1::ACMEIssuerDNS01ProviderWebhook';











1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::CertManager::V1::ACMEChallengeSolverDNS01 - Configures cert-manager to attempt to complete authorizations by performing the DNS01 challenge flow.

=head1 VERSION

version 1.108

=head2 acmeDNS

Use the 'ACME DNS' (https://github.com/joohoi/acme-dns) API to manage
DNS01 challenge records.

=head2 akamai

Use the Akamai DNS zone management API to manage DNS01 challenge records.

=head2 azureDNS

Use the Microsoft Azure DNS API to manage DNS01 challenge records.

=head2 cloudDNS

Use the Google Cloud DNS API to manage DNS01 challenge records.

=head2 cloudflare

Use the Cloudflare API to manage DNS01 challenge records.

=head2 cnameStrategy

CNAMEStrategy configures how the DNS01 provider should handle CNAME
records when found in DNS zones.

=head2 digitalocean

Use the DigitalOcean DNS API to manage DNS01 challenge records.

=head2 rfc2136

Use RFC2136 ("Dynamic Updates in the Domain Name System") (https://datatracker.ietf.org/doc/rfc2136/)
to manage DNS01 challenge records.

=head2 route53

Use the AWS Route53 API to manage DNS01 challenge records.

=head2 webhook

Configure an external webhook based DNS01 challenge solver to manage
DNS01 challenge records.

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
