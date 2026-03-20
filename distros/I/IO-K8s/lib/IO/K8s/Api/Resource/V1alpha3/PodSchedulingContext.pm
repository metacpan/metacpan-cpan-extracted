package IO::K8s::Api::Resource::V1alpha3::PodSchedulingContext;
# ABSTRACT: PodSchedulingContext objects hold information that is needed to schedule a Pod with ResourceClaims that use "WaitForFirstConsumer" allocation mode. This is an alpha type and requires enabling the DRAControlPlaneController feature gate.
our $VERSION = '1.009';
use IO::K8s::APIObject;
with 'IO::K8s::Role::Namespaced';


k8s spec => 'Resource::V1alpha3::PodSchedulingContextSpec', 'required';


k8s status => 'Resource::V1alpha3::PodSchedulingContextStatus';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Resource::V1alpha3::PodSchedulingContext - PodSchedulingContext objects hold information that is needed to schedule a Pod with ResourceClaims that use "WaitForFirstConsumer" allocation mode. This is an alpha type and requires enabling the DRAControlPlaneController feature gate.

=head1 VERSION

version 1.009

=head1 DESCRIPTION

PodSchedulingContext objects hold information that is needed to schedule a Pod with ResourceClaims that use "WaitForFirstConsumer" allocation mode.

This is an alpha type and requires enabling the DRAControlPlaneController feature gate.

This is a Kubernetes API object. See L<IO::K8s::Role::APIObject> for
C<metadata>, C<api_version()>, and C<kind()>.

=head2 spec

Spec describes where resources for the Pod are needed.

=head2 status

Status describes where resources for the Pod can be allocated.

=head1 SEE ALSO

L<https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.31/#podschedulingcontext-v1alpha3-resource.k8s.io>

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
