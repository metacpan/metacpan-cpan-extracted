package IO::K8s::Api::Core::V1::ReplicationControllerStatus;
# ABSTRACT: ReplicationControllerStatus represents the current status of a replication controller.
our $VERSION = '1.006';
use IO::K8s::Resource;

k8s availableReplicas => Int;


k8s conditions => ['Core::V1::ReplicationControllerCondition'];


k8s fullyLabeledReplicas => Int;


k8s observedGeneration => Int;


k8s readyReplicas => Int;


k8s replicas => Int, 'required';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Core::V1::ReplicationControllerStatus - ReplicationControllerStatus represents the current status of a replication controller.

=head1 VERSION

version 1.006

=head2 availableReplicas

The number of available replicas (ready for at least minReadySeconds) for this replication controller.

=head2 conditions

Represents the latest available observations of a replication controller's current state.

=head2 fullyLabeledReplicas

The number of pods that have labels matching the labels of the pod template of the replication controller.

=head2 observedGeneration

ObservedGeneration reflects the generation of the most recently observed replication controller.

=head2 readyReplicas

The number of ready replicas for this replication controller.

=head2 replicas

Replicas is the most recently observed number of replicas. More info: https://kubernetes.io/docs/concepts/workloads/controllers/replicationcontroller#what-is-a-replicationcontroller

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

Jose Luis Martinez <jlmartin@cpan.org> (original author, inactive)

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Jose Luis Martinez.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
