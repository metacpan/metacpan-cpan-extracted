package IO::K8s::CertManager::V1::ACMEChallengeSolverHTTP01IngressPodSpec;
# ABSTRACT: PodSpec defines overrides for the HTTP01 challenge solver pod.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s affinity           => 'Core::V1::Affinity';
k8s imagePullSecrets   => ['+IO::K8s::CertManager::V1::LocalObjectReference'];
k8s nodeSelector       => { Str => 1 };
k8s priorityClassName  => Str;
k8s resources          => 'Core::V1::VolumeResourceRequirements';
k8s securityContext    => '+IO::K8s::CertManager::V1::ACMEChallengeSolverHTTP01IngressPodSecurityContext';
k8s serviceAccountName => Str;
k8s tolerations        => ['Core::V1::Toleration'];









1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::CertManager::V1::ACMEChallengeSolverHTTP01IngressPodSpec - PodSpec defines overrides for the HTTP01 challenge solver pod.

=head1 VERSION

version 1.108

=head2 affinity

If specified, the pod's scheduling constraints

=head2 imagePullSecrets

If specified, the pod's imagePullSecrets

=head2 nodeSelector

NodeSelector is a selector which must be true for the pod to fit on a node.
Selector which must match a node's labels for the pod to be scheduled on that node.
More info: https://kubernetes.io/docs/concepts/configuration/assign-pod-node/

=head2 priorityClassName

If specified, the pod's priorityClassName.

=head2 resources

If specified, the pod's resource requirements.
These values override the global resource configuration flags.
Note that when only specifying resource limits, ensure they are greater than or equal
to the corresponding global resource requests configured via controller flags
(--acme-http01-solver-resource-request-cpu, --acme-http01-solver-resource-request-memory).
Kubernetes will reject pod creation if limits are lower than requests, causing challenge failures.

=head2 securityContext

If specified, the pod's security context

=head2 serviceAccountName

If specified, the pod's service account

=head2 tolerations

If specified, the pod's tolerations.

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
