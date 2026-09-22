package IO::K8s::AgentSandbox::V1beta1::SandboxTemplateSpec;
# ABSTRACT: SandboxTemplateSpec
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s envVarsInjectionPolicy     => Str, { enum => [qw(Allowed Overrides Disallowed)], default => 'Disallowed' };
k8s networkPolicy              => '+IO::K8s::AgentSandbox::V1beta1::NetworkPolicySpec';
k8s networkPolicyManagement    => Str, { enum => [qw(Managed Unmanaged)], default => 'Managed' };
k8s podTemplate                => '+IO::K8s::AgentSandbox::V1beta1::PodTemplate', { required => 'schema' };
k8s service                    => Bool;
k8s volumeClaimTemplates       => ['+IO::K8s::AgentSandbox::V1beta1::PersistentVolumeClaimTemplate'];
k8s volumeClaimTemplatesPolicy => Str, { enum => [qw(Disallowed Allowed Overrides)], default => 'Disallowed' };








1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::AgentSandbox::V1beta1::SandboxTemplateSpec - SandboxTemplateSpec

=head1 VERSION

version 1.108

=head2 envVarsInjectionPolicy

No description in the upstream schema.

=head2 networkPolicy

No description in the upstream schema.

=head2 networkPolicyManagement

No description in the upstream schema.

=head2 podTemplate

No description in the upstream schema.

=head2 service

No description in the upstream schema.

=head2 volumeClaimTemplates

No description in the upstream schema.

=head2 volumeClaimTemplatesPolicy

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
