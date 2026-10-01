package Kubernetes::Comb::CRD::CombStatus;
# ABSTRACT: Status of the Comb custom resource
our $VERSION = '0.001';

use IO::K8s::Resource;

use Kubernetes::Comb::CRD::CombCondition;
use Kubernetes::Comb::CRD::CombEndpoint;
use Kubernetes::Comb::CRD::CombResource;
use Kubernetes::Comb::CRD::CombUpstreamStatus;


k8s phase => Str, {
  description => 'Running, Pending, Blocked, NeedsConfig, Disabled, Error,'
    .' Stopped or NotDeployed'
};


k8s conditions => ['+Kubernetes::Comb::CRD::CombCondition'];


k8s managedResources => ['+Kubernetes::Comb::CRD::CombResource'];


k8s endpoints => ['+Kubernetes::Comb::CRD::CombEndpoint'];


k8s upstream => '+Kubernetes::Comb::CRD::CombUpstreamStatus';


k8s observedGeneration => Int;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Kubernetes::Comb::CRD::CombStatus - Status of the Comb custom resource

=head1 VERSION

version 0.001

=head1 DESCRIPTION

The C<status> of a L<Kubernetes::Comb::CRD::Comb>, written by the Comb itself
through the status subresource.

=head2 phase

One of C<Running>, C<Pending>, C<Blocked>, C<NeedsConfig>, C<Disabled>,
C<Error>, C<Stopped>, C<NotDeployed>. Not enforced as an enum, so a status
written by a newer version still inflates.

=head2 conditions

ArrayRef of L<Kubernetes::Comb::CRD::CombCondition>.

=head2 managedResources

ArrayRef of L<Kubernetes::Comb::CRD::CombResource>: every object the Comb
deployed, the base for pruning.

=head2 endpoints

ArrayRef of L<Kubernetes::Comb::CRD::CombEndpoint>, already resolved.

=head2 upstream

L<Kubernetes::Comb::CRD::CombUpstreamStatus>, only while an upstream is
active -- or its bridge still stands: steps that change nothing carry it
forward, see L<Kubernetes::Comb/reconcile>.

=head2 observedGeneration

C<metadata.generation> of the spec this status describes.

=head1 SEE ALSO

=over

=item * L<Kubernetes::Comb::CRD::Comb>

=back

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/p5-kubernetes-comb/issues>.

=head2 IRC

Join C<#kubernetes> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <getty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
