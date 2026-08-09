package IO::K8s::AgentSandbox::V1beta1::SandboxWarmPool;
# ABSTRACT: Pre-warmed pool of sandbox instances
our $VERSION = '1.105';
use IO::K8s::APIObject
    api_version     => 'extensions.agents.x-k8s.io/v1beta1',
    resource_plural => 'sandboxwarmpools';
with 'IO::K8s::Role::Namespaced';

k8s spec => {
    replicas     => Int,
    sandboxTemplateRef => {
        name => Str,
    },
    updateStrategy => {
        type => Str,
    },
};
k8s status => {
    replicas      => Int,
    readyReplicas => Int,
    selector      => Str,
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::AgentSandbox::V1beta1::SandboxWarmPool - Pre-warmed pool of sandbox instances

=head1 VERSION

version 1.105

=head1 DESCRIPTION

SandboxWarmPool manages a pool of pre-warmed Sandbox instances for quick allocation,
reducing startup latency. This is a namespace-scoped resource using API version
C<extensions.agents.x-k8s.io/v1beta1>, the storage version as of upstream
AgentSandbox v0.5.4. The C<spec> and C<status> fields are typed inline structs
generated from the upstream AgentSandbox Go types.

Compared to the deprecated (served-but-not-storage) C<extensions.agents.x-k8s.io/v1alpha1>
track modeled by L<IO::K8s::AgentSandbox::V1alpha1::SandboxWarmPool>, this version's
C<spec> gains C<updateStrategy.type> (C<Recreate> or C<OnReplenish>, defaulting to
C<OnReplenish> upstream) — the same addition made to the C<v1alpha1> track.

=head1 SEE ALSO

=over

=item * L<IO::K8s::AgentSandbox>

=item * L<IO::K8s::AgentSandbox::V1alpha1::SandboxWarmPool>

=item * L<https://github.com/kubernetes-sigs/agent-sandbox>

=back

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/pplu/io-k8s-p5/issues>.

=head2 IRC

Join C<#kubernetes> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHORS

=over 4

=item *

Torsten Raudssus <torsten@raudssus.de>

=item *

Jose Luis Martinez Torres <jlmartin@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018-2026 by Jose Luis Martinez Torres <jlmartin@cpan.org>.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
