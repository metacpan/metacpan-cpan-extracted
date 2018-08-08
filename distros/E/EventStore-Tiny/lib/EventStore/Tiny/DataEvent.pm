package EventStore::Tiny::DataEvent;
use parent 'EventStore::Tiny::Event';

use strict;
use warnings;

use Class::Tiny {
    data => sub {{}},
};

sub new_from_template {
    my ($class, $event, $data) = @_;

    # "clone"
    return EventStore::Tiny::DataEvent->new(
        name            => $event->name,
        transformation  => $event->transformation,
        data            => $data,
    );
}

# Lets transformation work on state by side-effect
sub apply_to {
    my ($self, $state, $logger) = @_;

    # Apply the transformation by side effect
    $self->transformation->($state, $self->data);

    # Log this event, if logger present
    $logger->($self) if defined $logger;

    # Returned the same state just in case
    return $state;
}

# Return a one-line summary of this event
sub summary {
    my $self = shift;

    # Prepare data summary
    my $data_summary = join ', ' => map {
        my $d = $self->data->{$_};
        $d =~ s/\s+/ /g;    # Summarize in-between whitespace
        $d =~ s/^\s+//;     # Get rid of leading whitespace
        $d =~ s/\s+$//;     # Get rid of whitespace in the end
        $d =~ s/['"]+//g;   # Get rid of quotes
        $d =~ s/^(.{17}).{3,}/$1.../; # Shorten
        "$_: '$d'"          # Quoted, shortened key-value pair
    } sort keys %{$self->data};

    # Retrieve event summary (without data) and inject data summary
    my $summary = $self->SUPER::summary;
    $summary =~ s/\)\]$/) | $data_summary]/;

    # Done
    return $summary;
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

Creates a new data event based on another event (usually representing an L<EventStore::Tiny::Event> event type which was registered before using L<EventStore::Tiny/register_event>). The additional argument sets the new event's L</data> attribute.

=head3 apply_to

    $event->apply_to(\%state, $logger);

Applies this event's L<transformation> to the given state (by side-effect) and its L</data>. If a C<$logger> as a subref is given, it is used to log this application.

=head3 summary

    say $event->summary;

Extended version of L<EventStory::Tiny::Event/summary> from the parent. It features a simple L</data> summary.

=head1 SEE ALSO

L<EventStore::Tiny>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2018 Mirko Westermeier (mail: mirko@westermeier.de)

Released under the MIT License (see LICENSE.txt for details).

=cut
