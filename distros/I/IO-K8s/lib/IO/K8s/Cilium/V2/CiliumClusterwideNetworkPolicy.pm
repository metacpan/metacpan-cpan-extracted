package IO::K8s::Cilium::V2::CiliumClusterwideNetworkPolicy;
# ABSTRACT: CiliumClusterwideNetworkPolicy is a Kubernetes third-party resource with an modified version of CiliumNetworkPolicy which is cluster scoped rather than namespace scoped.
our $VERSION = '1.108';
use IO::K8s::APIObject
    api_version     => 'cilium.io/v2',
    resource_plural => 'ciliumclusterwidenetworkpolicies';
with 'IO::K8s::Role::NetworkPolicy';
sub _netpol_format { 'cilium' }

k8s spec   => '+IO::K8s::Cilium::V2::Rule';
k8s specs  => ['+IO::K8s::Cilium::V2::Rule'];
k8s status => '+IO::K8s::Cilium::V2::CiliumNetworkPolicyStatus';




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Cilium::V2::CiliumClusterwideNetworkPolicy - CiliumClusterwideNetworkPolicy is a Kubernetes third-party resource with an modified version of CiliumNetworkPolicy which is cluster scoped rather than namespace scoped.

=head1 VERSION

version 1.108

=head2 spec

Spec is the desired Cilium specific rule specification.

=head2 specs

Specs is a list of desired Cilium specific rule specification.

=head2 status

Status is the status of the Cilium policy rule.

The reason this field exists in this structure is due a bug in the k8s
code-generator that doesn't create a `UpdateStatus` method because the
field does not exist in the structure.

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
