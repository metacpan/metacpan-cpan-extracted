package IO::K8s::AgentSandbox;
# ABSTRACT: AgentSandbox CRD resource map provider for IO::K8s
our $VERSION = '1.105';
use Moo;
with 'IO::K8s::Role::ResourceMap';

sub upstream_version { 'v0.5.4' }  # kubernetes-sigs/agent-sandbox

sub resource_map {
    return {
        # agents.x-k8s.io/v1beta1 (storage version)
        Sandbox         => 'AgentSandbox::V1beta1::Sandbox',
        # extensions.agents.x-k8s.io/v1beta1 (storage version)
        SandboxClaim    => 'AgentSandbox::V1beta1::SandboxClaim',
        SandboxTemplate => 'AgentSandbox::V1beta1::SandboxTemplate',
        SandboxWarmPool => 'AgentSandbox::V1beta1::SandboxWarmPool',
    };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::AgentSandbox - AgentSandbox CRD resource map provider for IO::K8s

=head1 VERSION

version 1.105

=head1 SYNOPSIS

    my $k8s = IO::K8s->new(with => ['IO::K8s::AgentSandbox']);

    my $sandbox = $k8s->new_object('Sandbox',
        metadata => { name => 'my-sandbox', namespace => 'default' },
        spec => { ... },
    );

    print $sandbox->to_yaml;

=head1 DESCRIPTION

Resource map provider for L<AgentSandbox|https://github.com/kubernetes-sigs/agent-sandbox>
Custom Resource Definitions, matching upstream AgentSandbox v0.5.4. Registers 4 short
names covering 4 CRD kinds:

=over 4

=item * C<agents.x-k8s.io>: Sandbox (main API group)

=item * C<extensions.agents.x-k8s.io>: SandboxClaim, SandboxTemplate, SandboxWarmPool

=back

Each kind ships two API versions on disk — C<v1alpha1> (still served, but deprecated
and no longer the storage version as of v0.5.4) and C<v1beta1> (the current storage
version). The short-name C<resource_map> below resolves to the C<v1beta1> class for
each kind; the C<v1alpha1> classes remain available for direct use by their full class
name (C<IO::K8s::AgentSandbox::V1alpha1::*>) or via domain-qualified lookup (e.g.
C<agents.x-k8s.io/v1alpha1/Sandbox>).

AgentSandbox manages isolated, stateful, singleton workloads for AI agent runtimes.

Not loaded by default — opt in via the C<with> constructor parameter of
L<IO::K8s> or by calling C<< $k8s->add('IO::K8s::AgentSandbox') >> at runtime.

=head2 Included CRDs (agents.x-k8s.io/v1beta1, agents.x-k8s.io/v1alpha1)

Sandbox

=head2 Included CRDs (extensions.agents.x-k8s.io/v1beta1, extensions.agents.x-k8s.io/v1alpha1)

SandboxClaim, SandboxTemplate, SandboxWarmPool

=head1 SEE ALSO

L<IO::K8s>

L<AgentSandbox repository|https://github.com/kubernetes-sigs/agent-sandbox>

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
