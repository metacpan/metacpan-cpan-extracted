package IO::K8s::CertManager::V1::ChallengeSpec;
# ABSTRACT: ChallengeSpec
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s authorizationURL => Str, { required => 'schema' };
k8s dnsName          => Str, { required => 'schema' };
k8s issuerRef        => '+IO::K8s::CertManager::V1::IssuerReference', { required => 'schema' };
k8s key              => Str, { required => 'schema' };
k8s solver           => '+IO::K8s::CertManager::V1::ACMEChallengeSolver', { required => 'schema' };
k8s token            => Str, { required => 'schema' };
k8s type             => Str, { required => 'schema', enum => [qw(HTTP-01 DNS-01)] };
k8s url              => Str, { required => 'schema' };
k8s wildcard         => Bool;










1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::CertManager::V1::ChallengeSpec - ChallengeSpec

=head1 VERSION

version 1.108

=head2 authorizationURL

The URL to the ACME Authorization resource that this
challenge is a part of.

=head2 dnsName

dnsName is the identifier that this challenge is for, e.g., example.com.
If the requested DNSName is a 'wildcard', this field MUST be set to the
non-wildcard domain, e.g., for `*.example.com`, it must be `example.com`.

=head2 issuerRef

References a properly configured ACME-type Issuer which should
be used to create this Challenge.
If the Issuer does not exist, processing will be retried.
If the Issuer is not an 'ACME' Issuer, an error will be returned and the
Challenge will be marked as failed.

=head2 key

The ACME challenge key for this challenge
For HTTP01 challenges, this is the value that must be responded with to
complete the HTTP01 challenge in the format:
`<private key JWK thumbprint>.<key from acme server for challenge>`.
For DNS01 challenges, this is the base64 encoded SHA256 sum of the
`<private key JWK thumbprint>.<key from acme server for challenge>`
text that must be set as the TXT record content.

=head2 solver

Contains the domain solving configuration that should be used to
solve this challenge resource.

=head2 token

The ACME challenge token for this challenge.
This is the raw value returned from the ACME server.

=head2 type

The type of ACME challenge this resource represents.
One of "HTTP-01" or "DNS-01".

=head2 url

The URL of the ACME Challenge resource for this challenge.
This can be used to lookup details about the status of this challenge.

=head2 wildcard

wildcard will be true if this challenge is for a wildcard identifier,
for example '*.example.com'.

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
