package IO::K8s::CertManager::V1::ACMEChallenge;
# ABSTRACT: Challenge specifies a challenge offered by the ACME server for an Order.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s token => Str, { required => 'schema' };
k8s type  => Str, { required => 'schema' };
k8s url   => Str, { required => 'schema' };




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::CertManager::V1::ACMEChallenge - Challenge specifies a challenge offered by the ACME server for an Order.

=head1 VERSION

version 1.108

=head2 token

Token is the token that must be presented for this challenge.
This is used to compute the 'key' that must also be presented.

=head2 type

Type is the type of challenge being offered, e.g., 'http-01', 'dns-01',
'tls-sni-01', etc.
This is the raw value retrieved from the ACME server.
Only 'http-01' and 'dns-01' are supported by cert-manager, other values
will be ignored.

=head2 url

URL is the URL of this challenge. It can be used to retrieve additional
metadata about the Challenge from the ACME server.

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
