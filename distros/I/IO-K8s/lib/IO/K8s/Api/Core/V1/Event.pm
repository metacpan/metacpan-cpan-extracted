package IO::K8s::Api::Core::V1::Event;
# ABSTRACT: Event is a report of an event somewhere in the cluster.  Events have a limited retention time and triggers and messages may evolve with time.  Event consumers should not rely on the timing of an event with a given Reason reflecting a consistent underlying trigger, or the continued existence of events with that Reason.  Events should be treated as informative, best-effort, supplemental data.
our $VERSION = '1.100';
use IO::K8s::APIObject;
with 'IO::K8s::Role::Namespaced';


k8s action => Str;


k8s count => Int;


k8s eventTime => Time;


k8s firstTimestamp => Time;


k8s involvedObject => 'Core::V1::ObjectReference', 'required';


k8s lastTimestamp => Time;


k8s message => Str;


k8s reason => Str;


k8s related => 'Core::V1::ObjectReference';


k8s reportingComponent => Str;


k8s reportingInstance => Str;


k8s series => 'Core::V1::EventSeries';


k8s source => 'Core::V1::EventSource';


k8s type => Str;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Core::V1::Event - Event is a report of an event somewhere in the cluster.  Events have a limited retention time and triggers and messages may evolve with time.  Event consumers should not rely on the timing of an event with a given Reason reflecting a consistent underlying trigger, or the continued existence of events with that Reason.  Events should be treated as informative, best-effort, supplemental data.

=head1 VERSION

version 1.100

=head1 DESCRIPTION

Event is a report of an event somewhere in the cluster.  Events have a limited retention time and triggers and messages may evolve with time.  Event consumers should not rely on the timing of an event with a given Reason reflecting a consistent underlying trigger, or the continued existence of events with that Reason.  Events should be treated as informative, best-effort, supplemental data.

This is a Kubernetes API object. See L<IO::K8s::Role::APIObject> for
C<metadata>, C<api_version()>, and C<kind()>.

=head2 action

What action was taken/failed regarding to the Regarding object.

=head2 count

The number of times this event has occurred.

=head2 eventTime

Time when this Event was first observed.

=head2 firstTimestamp

The time at which the event was first recorded. (Time of server receipt is in TypeMeta.)

=head2 involvedObject

The object that this event is about.

=head2 lastTimestamp

The time at which the most recent occurrence of this event was recorded.

=head2 message

A human-readable description of the status of this operation.

=head2 reason

This should be a short, machine understandable string that gives the reason for the transition into the object's current status.

=head2 related

Optional secondary object for more complex actions.

=head2 reportingComponent

Name of the controller that emitted this Event, e.g. `kubernetes.io/kubelet`.

=head2 reportingInstance

ID of the controller instance, e.g. `kubelet-xyzf`.

=head2 series

Data about the Event series this event represents or nil if it's a singleton Event.

=head2 source

The component reporting this event. Should be a short machine understandable string.

=head2 type

Type of this event (Normal, Warning), new types could be added in the future

=head1 SEE ALSO

L<https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.31/#event-v1-core>

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
