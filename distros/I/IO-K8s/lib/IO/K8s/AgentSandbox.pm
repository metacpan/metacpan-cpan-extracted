package IO::K8s::AgentSandbox;
# ABSTRACT: AgentSandbox CRD resource map provider for IO::K8s
our $VERSION = '1.100';
use Moo;
with 'IO::K8s::Role::ResourceMap';

sub upstream_version { 'v0.2.1' }  # kubernetes-sigs/agent-sandbox

sub resource_map {
    return {
        # agents.x-k8s.io/v1alpha1
        Sandbox         => 'AgentSandbox::V1alpha1::Sandbox',
        # extensions.agents.x-k8s.io/v1alpha1
        SandboxClaim    => 'AgentSandbox::V1alpha1::SandboxClaim',
        SandboxTemplate => 'AgentSandbox::V1alpha1::SandboxTemplate',
        SandboxWarmPool => 'AgentSandbox::V1alpha1::SandboxWarmPool',
    };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::AgentSandbox - AgentSandbox CRD resource map provider for IO::K8s

=head1 VERSION

version 1.100

=head1 SYNOPSIS

    my $k8s = IO::K8s->new(with => ['IO::K8s::AgentSandbox']);

    my $sandbox = $k8s->new_object('Sandbox',
        metadata => { name => 'my-sandbox', namespace => 'default' },
        spec => { ... },
    );

    print $sandbox->to_yaml;

=head1 DESCRIPTION

Resource map provider for L<AgentSandbox|https://github.com/kubernetes-sigs/agent-sandbox>
Custom Resource Definitions. Registers 4 CRD classes covering:

=over 4

=item * C<agents.x-k8s.io/v1alpha1>: Sandbox (main API group)

=item * C<extensions.agents.x-k8s.io/v1alpha1>: SandboxClaim, SandboxTemplate, SandboxWarmPool

=back

AgentSandbox manages isolated, stateful, singleton workloads for AI agent runtimes.

Not loaded by default — opt in via the C<with> constructor parameter of
L<IO::K8s> or by calling C<< $k8s->add('IO::K8s::AgentSandbox') >> at runtime.

=head2 Included CRDs (agents.x-k8s.io/v1alpha1)

Sandbox

=head2 Included CRDs (extensions.agents.x-k8s.io/v1alpha1)

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
