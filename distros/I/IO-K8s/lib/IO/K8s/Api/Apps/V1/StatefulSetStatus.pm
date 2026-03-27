package IO::K8s::Api::Apps::V1::StatefulSetStatus;
# ABSTRACT: StatefulSetStatus represents the current state of a StatefulSet.
our $VERSION = '1.100';
use IO::K8s::Resource;

k8s availableReplicas => Int;


k8s collisionCount => Int;


k8s conditions => ['Apps::V1::StatefulSetCondition'];


k8s currentReplicas => Int;


k8s currentRevision => Str;


k8s observedGeneration => Int;


k8s readyReplicas => Int;


k8s replicas => Int, 'required';


k8s updateRevision => Str;


k8s updatedReplicas => Int;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Apps::V1::StatefulSetStatus - StatefulSetStatus represents the current state of a StatefulSet.

=head1 VERSION

version 1.100

=head2 availableReplicas

Total number of available pods (ready for at least minReadySeconds) targeted by this statefulset.

=head2 collisionCount

collisionCount is the count of hash collisions for the StatefulSet. The StatefulSet controller uses this field as a collision avoidance mechanism when it needs to create the name for the newest ControllerRevision.

=head2 conditions

Represents the latest available observations of a statefulset's current state.

=head2 currentReplicas

currentReplicas is the number of Pods created by the StatefulSet controller from the StatefulSet version indicated by currentRevision.

=head2 currentRevision

currentRevision, if not empty, indicates the version of the StatefulSet used to generate Pods in the sequence [0,currentReplicas).

=head2 observedGeneration

observedGeneration is the most recent generation observed for this StatefulSet. It corresponds to the StatefulSet's generation, which is updated on mutation by the API Server.

=head2 readyReplicas

readyReplicas is the number of pods created for this StatefulSet with a Ready Condition.

=head2 replicas

replicas is the number of Pods created by the StatefulSet controller.

=head2 updateRevision

updateRevision, if not empty, indicates the version of the StatefulSet used to generate Pods in the sequence [replicas-updatedReplicas,replicas)

=head2 updatedReplicas

updatedReplicas is the number of Pods created by the StatefulSet controller from the StatefulSet version indicated by updateRevision.

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
