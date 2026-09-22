package IO::K8s::AgentSandbox::V1beta1::PodSpec;
# ABSTRACT: PodSpec
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s activeDeadlineSeconds         => Int;
k8s affinity                      => 'Core::V1::Affinity';
k8s automountServiceAccountToken  => Bool;
k8s containers                    => ['Core::V1::Container'], { required => 'schema' };
k8s dnsConfig                     => 'Core::V1::PodDNSConfig';
k8s dnsPolicy                     => Str;
k8s enableServiceLinks            => Bool;
k8s ephemeralContainers           => ['Core::V1::EphemeralContainer'];
k8s hostAliases                   => ['Core::V1::HostAlias'];
k8s hostIPC                       => Bool;
k8s hostNetwork                   => Bool;
k8s hostPID                       => Bool;
k8s hostUsers                     => Bool;
k8s hostname                      => Str;
k8s hostnameOverride              => Str;
k8s imagePullSecrets              => ['+IO::K8s::AgentSandbox::V1beta1::LocalObjectReference'];
k8s initContainers                => ['Core::V1::Container'];
k8s nodeName                      => Str;
k8s nodeSelector                  => { Str => 1 };
k8s os                            => '+IO::K8s::AgentSandbox::V1beta1::PodOS';
k8s overhead                      => { Str => 1 };
k8s preemptionPolicy              => Str;
k8s priority                      => Int;
k8s priorityClassName             => Str;
k8s readinessGates                => ['+IO::K8s::AgentSandbox::V1beta1::PodReadinessGate'];
k8s resourceClaims                => ['Core::V1::PodResourceClaim'];
k8s resources                     => 'Core::V1::ResourceRequirements';
k8s restartPolicy                 => Str;
k8s runtimeClassName              => Str;
k8s schedulerName                 => Str;
k8s schedulingGates               => ['+IO::K8s::AgentSandbox::V1beta1::PodSchedulingGate'];
k8s schedulingGroup               => '+IO::K8s::AgentSandbox::V1beta1::PodSchedulingGroup';
k8s securityContext               => 'Core::V1::PodSecurityContext';
k8s serviceAccount                => Str;
k8s serviceAccountName            => Str;
k8s setHostnameAsFQDN             => Bool;
k8s shareProcessNamespace         => Bool;
k8s subdomain                     => Str;
k8s terminationGracePeriodSeconds => Int;
k8s tolerations                   => ['Core::V1::Toleration'];
k8s topologySpreadConstraints     => ['Core::V1::TopologySpreadConstraint'];
k8s volumes                       => ['Core::V1::Volume'];











































1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::AgentSandbox::V1beta1::PodSpec - PodSpec

=head1 VERSION

version 1.108

=head2 activeDeadlineSeconds

No description in the upstream schema.

=head2 affinity

No description in the upstream schema.

=head2 automountServiceAccountToken

No description in the upstream schema.

=head2 containers

No description in the upstream schema.

=head2 dnsConfig

No description in the upstream schema.

=head2 dnsPolicy

No description in the upstream schema.

=head2 enableServiceLinks

No description in the upstream schema.

=head2 ephemeralContainers

No description in the upstream schema.

=head2 hostAliases

No description in the upstream schema.

=head2 hostIPC

No description in the upstream schema.

=head2 hostNetwork

No description in the upstream schema.

=head2 hostPID

No description in the upstream schema.

=head2 hostUsers

No description in the upstream schema.

=head2 hostname

No description in the upstream schema.

=head2 hostnameOverride

No description in the upstream schema.

=head2 imagePullSecrets

No description in the upstream schema.

=head2 initContainers

No description in the upstream schema.

=head2 nodeName

No description in the upstream schema.

=head2 nodeSelector

No description in the upstream schema.

=head2 os

No description in the upstream schema.

=head2 overhead

No description in the upstream schema.

=head2 preemptionPolicy

No description in the upstream schema.

=head2 priority

No description in the upstream schema.

=head2 priorityClassName

No description in the upstream schema.

=head2 readinessGates

No description in the upstream schema.

=head2 resourceClaims

No description in the upstream schema.

=head2 resources

No description in the upstream schema.

=head2 restartPolicy

No description in the upstream schema.

=head2 runtimeClassName

No description in the upstream schema.

=head2 schedulerName

No description in the upstream schema.

=head2 schedulingGates

No description in the upstream schema.

=head2 schedulingGroup

No description in the upstream schema.

=head2 securityContext

No description in the upstream schema.

=head2 serviceAccount

No description in the upstream schema.

=head2 serviceAccountName

No description in the upstream schema.

=head2 setHostnameAsFQDN

No description in the upstream schema.

=head2 shareProcessNamespace

No description in the upstream schema.

=head2 subdomain

No description in the upstream schema.

=head2 terminationGracePeriodSeconds

No description in the upstream schema.

=head2 tolerations

No description in the upstream schema.

=head2 topologySpreadConstraints

No description in the upstream schema.

=head2 volumes

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
