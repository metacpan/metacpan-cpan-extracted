package IO::K8s::Api::Apps::V1::DeploymentStatus;
# ABSTRACT: DeploymentStatus is the most recently observed status of the Deployment.
our $VERSION = '1.009';
use IO::K8s::Resource;

k8s availableReplicas => Int;


k8s collisionCount => Int;


k8s conditions => ['Apps::V1::DeploymentCondition'];


k8s observedGeneration => Int;


k8s readyReplicas => Int;


k8s replicas => Int;


k8s unavailableReplicas => Int;


k8s updatedReplicas => Int;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Apps::V1::DeploymentStatus - DeploymentStatus is the most recently observed status of the Deployment.

=head1 VERSION

version 1.009

=head2 availableReplicas

Total number of available pods (ready for at least minReadySeconds) targeted by this deployment.

=head2 collisionCount

Count of hash collisions for the Deployment. The Deployment controller uses this field as a collision avoidance mechanism when it needs to create the name for the newest ReplicaSet.

=head2 conditions

Represents the latest available observations of a deployment's current state.

=head2 observedGeneration

The generation observed by the deployment controller.

=head2 readyReplicas

readyReplicas is the number of pods targeted by this Deployment with a Ready Condition.

=head2 replicas

Total number of non-terminated pods targeted by this deployment (their labels match the selector).

=head2 unavailableReplicas

Total number of unavailable pods targeted by this deployment. This is the total number of pods that are still required for the deployment to have 100% available capacity. They may either be pods that are running but not yet available or pods that still have not been created.

=head2 updatedReplicas

Total number of non-terminated pods targeted by this deployment that have the desired template spec.

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
