package IO::K8s::CertManager::V1::ACMEChallengeSolverHTTP01GatewayHTTPRoute;
# ABSTRACT: The Gateway API is a sig-network community API that models service networking in Kubernetes (https://gateway-api.sigs.k8s.io/).
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s labels      => { Str => 1 };
k8s parentRefs  => ['+IO::K8s::CertManager::V1::ParentReference'];
k8s podTemplate => '+IO::K8s::CertManager::V1::ACMEChallengeSolverHTTP01IngressPodTemplate';
k8s serviceType => Str;





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::CertManager::V1::ACMEChallengeSolverHTTP01GatewayHTTPRoute - The Gateway API is a sig-network community API that models service networking in Kubernetes (https://gateway-api.sigs.k8s.io/).

=head1 VERSION

version 1.108

=head2 labels

Custom labels that will be applied to HTTPRoutes created by cert-manager
while solving HTTP-01 challenges.

=head2 parentRefs

When solving an HTTP-01 challenge, cert-manager creates an HTTPRoute.
cert-manager needs to know which parentRefs should be used when creating
the HTTPRoute. Usually, the parentRef references a Gateway. See:
https://gateway-api.sigs.k8s.io/api-types/httproute/#attaching-to-gateways

=head2 podTemplate

Optional pod template used to configure the ACME challenge solver pods
used for HTTP01 challenges.

=head2 serviceType

Optional service type for Kubernetes solver service. Supported values
are NodePort or ClusterIP. If unset, defaults to NodePort.

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
