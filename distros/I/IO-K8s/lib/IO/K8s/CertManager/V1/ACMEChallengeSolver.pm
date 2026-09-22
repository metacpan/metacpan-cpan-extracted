package IO::K8s::CertManager::V1::ACMEChallengeSolver;
# ABSTRACT: An ACMEChallengeSolver describes how to solve ACME challenges for the issuer it is part of.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s dns01                  => '+IO::K8s::CertManager::V1::ACMEChallengeSolverDNS01';
k8s http01                 => '+IO::K8s::CertManager::V1::ACMEChallengeSolverHTTP01';
k8s selector               => '+IO::K8s::CertManager::V1::CertificateDNSNameSelector';
k8s waitInsteadOfSelfCheck => Str;





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::CertManager::V1::ACMEChallengeSolver - An ACMEChallengeSolver describes how to solve ACME challenges for the issuer it is part of.

=head1 VERSION

version 1.108

=head2 dns01

Configures cert-manager to attempt to complete authorizations by
performing the DNS01 challenge flow.

=head2 http01

Configures cert-manager to attempt to complete authorizations by
performing the HTTP01 challenge flow.
It is not possible to obtain certificates for wildcard domain names
(e.g., `*.example.com`) using the HTTP01 challenge mechanism.

=head2 selector

Selector selects a set of DNSNames on the Certificate resource that
should be solved using this challenge solver.
If not specified, the solver will be treated as the 'default' solver
with the lowest priority, i.e. if any other solver has a more specific
match, it will be used instead.

=head2 waitInsteadOfSelfCheck

WaitInsteadOfSelfCheck, if set, skips cert-manager's self-check and
instead waits this long after presentation before asking the ACME server
to validate the challenge.

This is an advanced escape hatch for environments where cert-manager's
self-check cannot succeed from its own network or DNS viewpoint even
though the ACME server can still validate successfully, for example due
to split-horizon DNS or NAT hairpinning.

A value of 0 skips the self-check and asks the ACME server to validate
immediately after presentation, relying on the ACME server's own
validation retries (RFC 8555 section 8.2) to succeed once the challenge
has propagated. A negative duration is rejected.
Value must be in units accepted by Go time.ParseDuration https://golang.org/pkg/time/#ParseDuration,
for example `30s` or `2m`.

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
