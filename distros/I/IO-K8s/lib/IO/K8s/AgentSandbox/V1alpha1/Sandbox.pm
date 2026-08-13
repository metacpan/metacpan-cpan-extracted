package IO::K8s::AgentSandbox::V1alpha1::Sandbox;
# ABSTRACT: Isolated runtime environment for AI agents
our $VERSION = '1.106';
use IO::K8s::APIObject
    api_version     => 'agents.x-k8s.io/v1alpha1',
    resource_plural => 'sandboxes';
with 'IO::K8s::Role::Namespaced';

k8s spec => {
    podTemplate           => { Str => 1 },
    volumeClaimTemplates  => { Str => 1 },
    shutdownTime          => Time,
    shutdownPolicy        => Str,
    replicas              => Int,
    service               => Bool,
};
k8s status => {
    serviceFQDN => Str,
    service     => Str,
    conditions  => { Str => 1 },
    replicas    => Int,
    selector    => Str,
    podIPs      => [Str],
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::AgentSandbox::V1alpha1::Sandbox - Isolated runtime environment for AI agents

=head1 VERSION

version 1.106

=head1 DESCRIPTION

Sandbox is an isolated runtime environment for AI agents. It provides a stateful,
singleton workload scheduled on Kubernetes nodes. This is a namespace-scoped resource
using API version C<agents.x-k8s.io/v1alpha1>. The C<spec> and C<status> fields are
typed inline structs generated from the upstream AgentSandbox Go types.

As of upstream AgentSandbox v0.5.4, this API version is still served but is no longer
the storage version — C<agents.x-k8s.io/v1beta1> (see
L<IO::K8s::AgentSandbox::V1beta1::Sandbox>) is now canonical. This C<v1alpha1> track
still carries C<spec.replicas> / C<status.replicas>, unlike C<v1beta1>, but has gained
C<spec.service> and C<status.podIPs>.

=head1 SEE ALSO

=over

=item * L<IO::K8s::AgentSandbox>

=item * L<IO::K8s::AgentSandbox::V1beta1::Sandbox>

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
