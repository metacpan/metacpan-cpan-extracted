package IO::K8s::CertManager::V1::ACMEChallengeSolverHTTP01;
# ABSTRACT: Configures cert-manager to attempt to complete authorizations by performing the HTTP01 challenge flow.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s gatewayHTTPRoute => '+IO::K8s::CertManager::V1::ACMEChallengeSolverHTTP01GatewayHTTPRoute';
k8s ingress          => '+IO::K8s::CertManager::V1::ACMEChallengeSolverHTTP01Ingress';



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::CertManager::V1::ACMEChallengeSolverHTTP01 - Configures cert-manager to attempt to complete authorizations by performing the HTTP01 challenge flow.

=head1 VERSION

version 1.108

=head2 gatewayHTTPRoute

The Gateway API is a sig-network community API that models service networking
in Kubernetes (https://gateway-api.sigs.k8s.io/). The Gateway solver will
create HTTPRoutes with the specified labels in the same namespace as the challenge.
This solver is experimental, and fields / behaviour may change in the future.

=head2 ingress

The ingress based HTTP01 challenge solver will solve challenges by
creating or modifying Ingress resources in order to route requests for
'/.well-known/acme-challenge/XYZ' to 'challenge solver' pods that are
provisioned by cert-manager for each Challenge to be completed.

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
