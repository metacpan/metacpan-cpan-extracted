package IO::K8s::Api::Events::V1::Event;
# ABSTRACT: Event is a report of an event somewhere in the cluster. It generally denotes some state change in the system. Events have a limited retention time and triggers and messages may evolve with time.  Event consumers should not rely on the timing of an event with a given Reason reflecting a consistent underlying trigger, or the continued existence of events with that Reason.  Events should be treated as informative, best-effort, supplemental data.
our $VERSION = '1.006';
use IO::K8s::APIObject;
with 'IO::K8s::Role::Namespaced';


k8s action => Str;


k8s deprecatedCount => Int;


k8s deprecatedFirstTimestamp => Time;


k8s deprecatedLastTimestamp => Time;


k8s deprecatedSource => 'Core::V1::EventSource';


k8s eventTime => Time, 'required';


k8s note => Str;


k8s reason => Str;


k8s regarding => 'Core::V1::ObjectReference';


k8s related => 'Core::V1::ObjectReference';


k8s reportingController => Str;


k8s reportingInstance => Str;


k8s series => 'Events::V1::EventSeries';


k8s type => Str;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Events::V1::Event - Event is a report of an event somewhere in the cluster. It generally denotes some state change in the system. Events have a limited retention time and triggers and messages may evolve with time.  Event consumers should not rely on the timing of an event with a given Reason reflecting a consistent underlying trigger, or the continued existence of events with that Reason.  Events should be treated as informative, best-effort, supplemental data.

=head1 VERSION

version 1.006

=head1 DESCRIPTION

Event is a report of an event somewhere in the cluster. It generally denotes some state change in the system. Events have a limited retention time and triggers and messages may evolve with time.  Event consumers should not rely on the timing of an event with a given Reason reflecting a consistent underlying trigger, or the continued existence of events with that Reason.  Events should be treated as informative, best-effort, supplemental data.

This is a Kubernetes API object. See L<IO::K8s::Role::APIObject> for
C<metadata>, C<api_version()>, and C<kind()>.

=head2 action

action is what action was taken/failed regarding to the regarding object. It is machine-readable. This field cannot be empty for new Events and it can have at most 128 characters.

=head2 deprecatedCount

deprecatedCount is the deprecated field assuring backward compatibility with core.v1 Event type.

=head2 deprecatedFirstTimestamp

deprecatedFirstTimestamp is the deprecated field assuring backward compatibility with core.v1 Event type.

=head2 deprecatedLastTimestamp

deprecatedLastTimestamp is the deprecated field assuring backward compatibility with core.v1 Event type.

=head2 deprecatedSource

deprecatedSource is the deprecated field assuring backward compatibility with core.v1 Event type.

=head2 eventTime

eventTime is the time when this Event was first observed. It is required.

=head2 note

note is a human-readable description of the status of this operation. Maximal length of the note is 1kB, but libraries should be prepared to handle values up to 64kB.

=head2 reason

reason is why the action was taken. It is human-readable. This field cannot be empty for new Events and it can have at most 128 characters.

=head2 regarding

regarding contains the object this Event is about. In most cases it's an Object reporting controller implements, e.g. ReplicaSetController implements ReplicaSets and this event is emitted because it acts on some changes in a ReplicaSet object.

=head2 related

related is the optional secondary object for more complex actions. E.g. when regarding object triggers a creation or deletion of related object.

=head2 reportingController

reportingController is the name of the controller that emitted this Event, e.g. `kubernetes.io/kubelet`. This field cannot be empty for new Events.

=head2 reportingInstance

reportingInstance is the ID of the controller instance, e.g. `kubelet-xyzf`. This field cannot be empty for new Events and it can have at most 128 characters.

=head2 series

series is data about the Event series this event represents or nil if it's a singleton Event.

=head2 type

type is the type of this event (Normal, Warning), new types could be added in the future. It is machine-readable. This field cannot be empty for new Events.

=head1 SEE ALSO

L<https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.31/#event-v1-events.k8s.io>

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
