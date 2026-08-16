package IO::K8s::AgentSandbox::V1beta1::SandboxClaim;
# ABSTRACT: Request for sandbox allocation from a warm pool
our $VERSION = '1.107';
use IO::K8s::APIObject
    api_version     => 'extensions.agents.x-k8s.io/v1beta1',
    resource_plural => 'sandboxclaims';
with 'IO::K8s::Role::Namespaced';

k8s spec => {
    additionalPodMetadata => {
        annotations => { Str => 1 },
        labels      => { Str => 1 },
    },
    env => { Str => 1 },
    lifecycle => {
        shutdownTime            => Time,
        shutdownPolicy          => Str,
        ttlSecondsAfterFinished => Int,
    },
    volumeClaimTemplates => ['Core::V1::PersistentVolumeClaim'],
    warmPoolRef => {
        name => Str,
    },
};
k8s status => {
    conditions => { Str => 1 },
    sandbox    => {
        name   => Str,
        podIPs => [Str],
    },
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::AgentSandbox::V1beta1::SandboxClaim - Request for sandbox allocation from a warm pool

=head1 VERSION

version 1.107

=head1 DESCRIPTION

SandboxClaim requests allocation of a sandbox instance. This is a namespace-scoped
resource using API version C<extensions.agents.x-k8s.io/v1beta1>, the storage
version as of upstream AgentSandbox v0.5.4. The C<spec> and C<status> fields are
typed inline structs generated from the upstream AgentSandbox Go types.

Unlike the deprecated (served-but-not-storage) C<extensions.agents.x-k8s.io/v1alpha1>
track modeled by L<IO::K8s::AgentSandbox::V1alpha1::SandboxClaim>, this version drops
C<spec.sandboxTemplateRef> entirely — a claim is fulfilled by referencing a
L<IO::K8s::AgentSandbox::V1beta1::SandboxWarmPool> via C<spec.warmPoolRef> instead
of a template directly. It also gains C<spec.additionalPodMetadata>, C<spec.env>,
C<spec.lifecycle.ttlSecondsAfterFinished>, and a typed C<spec.volumeClaimTemplates>
list, and C<status.sandbox.name> (lowercase, replacing the C<v1alpha1> track's
C<status.sandbox.Name>) gains a sibling C<status.sandbox.podIPs>.

=head1 SEE ALSO

=over

=item * L<IO::K8s::AgentSandbox>

=item * L<IO::K8s::AgentSandbox::V1alpha1::SandboxClaim>

=item * L<IO::K8s::AgentSandbox::V1beta1::SandboxWarmPool>

=item * L<https://github.com/kubernetes-sigs/agent-sandbox>

=back

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
