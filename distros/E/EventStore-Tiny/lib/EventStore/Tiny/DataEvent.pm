package EventStore::Tiny::DataEvent;
use Mo qw(default);
extends 'EventStore::Tiny::Event';

has data => {};

sub new_from_template {
    my ($class, $event, $data) = @_;

    # "clone"
    return EventStore::Tiny::DataEvent->new(
        name            => $event->name,
        transformation  => $event->transformation,
        data            => $data,
    );
}

1;

=pod

=encoding utf-8

=head1 NAME

EventStore::Tiny::DataEvent

=head1 REFERENCE

EventStore::Tiny::DataEvent extends EventStore::Tiny::Event and implements the following additional attributes and methods.

=head2 data

    my $ev = EventStore::Tiny::DataEvent->new(data => {id => 42});

Sets concrete data for this event which will be used during application.

=head2 new_from_template

    my $concrete = EventStore::Tiny::DataEvent->new_from_template(
        $event, {id => 17}
    );

Creates a new data event based on an event (usually representing an event type which was registered before using L<EventStore::Tiny/register_event>).

=head1 SEE ALSO

L<EventStore::Tiny>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2018 Mirko Westermeier (mail: mirko@westermeier.de)

Released under the MIT License (see LICENSE.txt for details).

=cut
