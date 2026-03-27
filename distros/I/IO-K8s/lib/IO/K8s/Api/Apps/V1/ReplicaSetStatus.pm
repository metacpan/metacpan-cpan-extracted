package IO::K8s::Api::Apps::V1::ReplicaSetStatus;
# ABSTRACT: ReplicaSetStatus represents the current status of a ReplicaSet.
our $VERSION = '1.100';
use IO::K8s::Resource;

k8s availableReplicas => Int;


k8s conditions => ['Apps::V1::ReplicaSetCondition'];


k8s fullyLabeledReplicas => Int;


k8s observedGeneration => Int;


k8s readyReplicas => Int;


k8s replicas => Int, 'required';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Apps::V1::ReplicaSetStatus - ReplicaSetStatus represents the current status of a ReplicaSet.

=head1 VERSION

version 1.100

=head2 availableReplicas

The number of available replicas (ready for at least minReadySeconds) for this replica set.

=head2 conditions

Represents the latest available observations of a replica set's current state.

=head2 fullyLabeledReplicas

The number of pods that have labels matching the labels of the pod template of the replicaset.

=head2 observedGeneration

ObservedGeneration reflects the generation of the most recently observed ReplicaSet.

=head2 readyReplicas

readyReplicas is the number of pods targeted by this ReplicaSet with a Ready Condition.

=head2 replicas

Replicas is the most recently observed number of replicas. More info: https://kubernetes.io/docs/concepts/workloads/controllers/replicationcontroller/#what-is-a-replicationcontroller

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
