package IO::K8s::CertManager::V1::ACMEIssuerDNS01ProviderRFC2136;
# ABSTRACT: Use RFC2136 ("Dynamic Updates in the Domain Name System") (https://datatracker.ietf.org/doc/rfc2136/) to manage DNS01 challenge records.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s nameserver          => Str, { required => 'schema' };
k8s protocol            => Str, { enum => [qw(TCP UDP)] };
k8s tsigAlgorithm       => Str;
k8s tsigKeyName         => Str;
k8s tsigSecretSecretRef => '+IO::K8s::CertManager::V1::SecretKeySelector';






1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::CertManager::V1::ACMEIssuerDNS01ProviderRFC2136 - Use RFC2136 ("Dynamic Updates in the Domain Name System") (https://datatracker.ietf.org/doc/rfc2136/) to manage DNS01 challenge records.

=head1 VERSION

version 1.108

=head2 nameserver

The IP address or hostname of an authoritative DNS server supporting
RFC2136 in the form host:port. If the host is an IPv6 address it must be
enclosed in square brackets (e.g [2001:db8::1]); port is optional.
This field is required.

=head2 protocol

Protocol to use for dynamic DNS update queries. Valid values are (case-sensitive) ``TCP`` and ``UDP``; ``UDP`` (default).

=head2 tsigAlgorithm

The TSIG Algorithm configured in the DNS supporting RFC2136. Used only
when ``tsigSecretSecretRef`` and ``tsigKeyName`` are defined.
Supported values are (case-insensitive): ``HMACMD5`` (default),
``HMACSHA1``, ``HMACSHA256`` or ``HMACSHA512``.

=head2 tsigKeyName

The TSIG Key name configured in the DNS.
If ``tsigSecretSecretRef`` is defined, this field is required.

=head2 tsigSecretSecretRef

The name of the secret containing the TSIG value.
If ``tsigKeyName`` is defined, this field is required.

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
