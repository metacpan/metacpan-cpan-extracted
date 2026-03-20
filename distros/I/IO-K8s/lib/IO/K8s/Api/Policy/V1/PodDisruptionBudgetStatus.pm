package IO::K8s::Api::Policy::V1::PodDisruptionBudgetStatus;
# ABSTRACT: PodDisruptionBudgetStatus represents information about the status of a PodDisruptionBudget. Status may trail the actual state of a system.
our $VERSION = '1.009';
use IO::K8s::Resource;

k8s conditions => ['Meta::V1::Condition'];


k8s currentHealthy => Int, 'required';


k8s desiredHealthy => Int, 'required';


k8s disruptedPods => { Str => 1 };


k8s disruptionsAllowed => Int, 'required';


k8s expectedPods => Int, 'required';


k8s observedGeneration => Int;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Policy::V1::PodDisruptionBudgetStatus - PodDisruptionBudgetStatus represents information about the status of a PodDisruptionBudget. Status may trail the actual state of a system.

=head1 VERSION

version 1.009

=head2 conditions

Conditions contain conditions for PDB. The disruption controller sets the DisruptionAllowed condition. The following are known values for the reason field (additional reasons could be added in the future): - SyncFailed: The controller encountered an error and wasn't able to compute the number of allowed disruptions. Therefore no disruptions are allowed and the status of the condition will be False. - InsufficientPods: The number of pods are either at or below the number required by the PodDisruptionBudget. No disruptions are allowed and the status of the condition will be False. - SufficientPods: There are more pods than required by the PodDisruptionBudget. The condition will be True, and the number of allowed disruptions are provided by the disruptionsAllowed property.

=head2 currentHealthy

current number of healthy pods

=head2 desiredHealthy

minimum desired number of healthy pods

=head2 disruptedPods

DisruptedPods contains information about pods whose eviction was processed by the API server eviction subresource handler but has not yet been observed by the PodDisruptionBudget controller. A pod will be in this map from the time when the API server processed the eviction request to the time when the pod is seen by PDB controller as having been marked for deletion (or after a timeout). The key in the map is the name of the pod and the value is the time when the API server processed the eviction request. If the deletion didn't occur and a pod is still there it will be removed from the list automatically by PodDisruptionBudget controller after some time. If everything goes smooth this map should be empty for the most of the time. Large number of entries in the map may indicate problems with pod deletions.

=head2 disruptionsAllowed

Number of pod disruptions that are currently allowed.

=head2 expectedPods

total number of pods counted by this disruption budget

=head2 observedGeneration

Most recent generation observed when updating this PDB status. DisruptionsAllowed and other status information is valid only if observedGeneration equals to PDB's object generation.

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
