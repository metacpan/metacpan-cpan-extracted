package IO::K8s::Api::Apps::V1::DaemonSetStatus;
# ABSTRACT: DaemonSetStatus represents the current status of a daemon set.
our $VERSION = '1.006';
use IO::K8s::Resource;

k8s collisionCount => Int;


k8s conditions => ['Apps::V1::DaemonSetCondition'];


k8s currentNumberScheduled => Int, 'required';


k8s desiredNumberScheduled => Int, 'required';


k8s numberAvailable => Int;


k8s numberMisscheduled => Int, 'required';


k8s numberReady => Int, 'required';


k8s numberUnavailable => Int;


k8s observedGeneration => Int;


k8s updatedNumberScheduled => Int;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Apps::V1::DaemonSetStatus - DaemonSetStatus represents the current status of a daemon set.

=head1 VERSION

version 1.006

=head2 collisionCount

Count of hash collisions for the DaemonSet. The DaemonSet controller uses this field as a collision avoidance mechanism when it needs to create the name for the newest ControllerRevision.

=head2 conditions

Represents the latest available observations of a DaemonSet's current state.

=head2 currentNumberScheduled

The number of nodes that are running at least 1 daemon pod and are supposed to run the daemon pod. More info: https://kubernetes.io/docs/concepts/workloads/controllers/daemonset/

=head2 desiredNumberScheduled

The total number of nodes that should be running the daemon pod (including nodes correctly running the daemon pod). More info: https://kubernetes.io/docs/concepts/workloads/controllers/daemonset/

=head2 numberAvailable

The number of nodes that should be running the daemon pod and have one or more of the daemon pod running and available (ready for at least spec.minReadySeconds)

=head2 numberMisscheduled

The number of nodes that are running the daemon pod, but are not supposed to run the daemon pod. More info: https://kubernetes.io/docs/concepts/workloads/controllers/daemonset/

=head2 numberReady

numberReady is the number of nodes that should be running the daemon pod and have one or more of the daemon pod running with a Ready Condition.

=head2 numberUnavailable

The number of nodes that should be running the daemon pod and have none of the daemon pod running and available (ready for at least spec.minReadySeconds)

=head2 observedGeneration

The most recent generation observed by the daemon set controller.

=head2 updatedNumberScheduled

The total number of nodes that are running updated daemon pod

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
