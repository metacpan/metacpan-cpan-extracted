package IO::K8s::AgentSandbox::V1beta1::SandboxTemplate;
# ABSTRACT: Reusable sandbox configuration template
our $VERSION = '1.106';
use IO::K8s::APIObject
    api_version     => 'extensions.agents.x-k8s.io/v1beta1',
    resource_plural => 'sandboxtemplates';
with 'IO::K8s::Role::Namespaced';

k8s spec => {
    podTemplate                => { Str => 1 },
    networkPolicy               => { Str => 1 },
    networkPolicyManagement     => Str,
    envVarsInjectionPolicy      => Str,
    service                     => Bool,
    volumeClaimTemplates        => ['Core::V1::PersistentVolumeClaim'],
    volumeClaimTemplatesPolicy  => Str,
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::AgentSandbox::V1beta1::SandboxTemplate - Reusable sandbox configuration template

=head1 VERSION

version 1.106

=head1 DESCRIPTION

SandboxTemplate defines a reusable configuration for sandbox instances, including a pod
template and optional network policy. This is a namespace-scoped resource using API
version C<extensions.agents.x-k8s.io/v1beta1>, the storage version as of upstream
AgentSandbox v0.5.4. The C<spec> field is a typed inline struct generated from the
upstream AgentSandbox Go types. There is no C<status> object for this kind, in either
API version.

Compared to the deprecated (served-but-not-storage) C<extensions.agents.x-k8s.io/v1alpha1>
track modeled by L<IO::K8s::AgentSandbox::V1alpha1::SandboxTemplate>, this version's
C<spec> gains C<envVarsInjectionPolicy>, C<service>, C<volumeClaimTemplates>, and
C<volumeClaimTemplatesPolicy> — the same additions made to the C<v1alpha1> track.

=head1 SEE ALSO

=over

=item * L<IO::K8s::AgentSandbox>

=item * L<IO::K8s::AgentSandbox::V1alpha1::SandboxTemplate>

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
