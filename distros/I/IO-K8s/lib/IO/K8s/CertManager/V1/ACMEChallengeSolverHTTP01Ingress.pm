package IO::K8s::CertManager::V1::ACMEChallengeSolverHTTP01Ingress;
# ABSTRACT: The ingress based HTTP01 challenge solver will solve challenges by creating or modifying Ingress resources in order to route requests for '/.well-known/acme-challenge/XYZ' to 'challenge solver' pods that are provisioned by cert-manager for each Challenge to be completed.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s class            => Str;
k8s ingressClassName => Str;
k8s ingressTemplate  => '+IO::K8s::CertManager::V1::ACMEChallengeSolverHTTP01IngressTemplate';
k8s name             => Str;
k8s podTemplate      => '+IO::K8s::CertManager::V1::ACMEChallengeSolverHTTP01IngressPodTemplate';
k8s serviceType      => Str;







1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::CertManager::V1::ACMEChallengeSolverHTTP01Ingress - The ingress based HTTP01 challenge solver will solve challenges by creating or modifying Ingress resources in order to route requests for '/.well-known/acme-challenge/XYZ' to 'challenge solver' pods that are provisioned by cert-manager for each Challenge to be completed.

=head1 VERSION

version 1.108

=head2 class

This field configures the annotation `kubernetes.io/ingress.class` when
creating Ingress resources to solve ACME challenges that use this
challenge solver. Only one of `class`, `name` or `ingressClassName` may
be specified.

=head2 ingressClassName

This field configures the field `ingressClassName` on the created Ingress
resources used to solve ACME challenges that use this challenge solver.
This is the recommended way of configuring the ingress class. Only one of
`class`, `name` or `ingressClassName` may be specified.

=head2 ingressTemplate

Optional ingress template used to configure the ACME challenge solver
ingress used for HTTP01 challenges.

=head2 name

The name of the ingress resource that should have ACME challenge solving
routes inserted into it in order to solve HTTP01 challenges.
This is typically used in conjunction with ingress controllers like
ingress-gce, which maintains a 1:1 mapping between external IPs and
ingress resources. Only one of `class`, `name` or `ingressClassName` may
be specified.

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
