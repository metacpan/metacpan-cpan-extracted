package EventStore::Tiny::Event;

use strict;
use warnings;

use UUID::Tiny qw(create_uuid_as_string);
use Time::HiRes qw(time);

use Class::Tiny {
    uuid            => sub {create_uuid_as_string},
    timestamp       => sub {time},
    name            => sub {die "name is required.\n"},
    transformation  => sub {sub {}},
};

sub BUILD {
    my $self = shift;

    # Set non-lazy
    $self->name;
    $self->timestamp;

    # Return nothing (will be ignored anyway)
    return;
}

# Lets transformation work on state by side-effect
sub apply_to {
    my ($self, $state, $logger) = @_;

    # Apply the transformation by side effect
    $self->transformation->($state);

    # Log this event, if logger present
    $logger->($self) if defined $logger;

    # Returned the same state just in case
    return $state;
}

# Return a one-line summary of this event
sub summary {
    my $self = shift;
    my $decimals    = $self->timestamp =~ /(\.\d+)$/ ? $1 : '';
    my @time_parts  = localtime $self->timestamp;
    return sprintf '[%s (%4d-%02d-%02dT%02d:%02d:%02d%s)]',
        $self->name,
        $time_parts[5] + 1900,      # Year
        @time_parts[4, 3, 2, 1, 0], # Rest of time representation
        $decimals;                  # Possibly empty
}

1;

=pod

=encoding utf-8

=head1 NAME

EventStore::Tiny::Event

=head1 REFERENCE

EventStore::Tiny::Event implements the following attributes and methods.

=head2 ATTRIBUTES

All these attributes can be manipulated by setters/getters with the attribute's name or can be set on construction:

    my $event = EventStore::Tiny::Event->new(name => "Foo");

=head3 uuid

This event's UUID. By default a new UUID is created.

=head3 timestamp

This event's timestamp. By default a new timestamp of the creation time is set.

=head3 name

This event's name. Setting this attribute on construction is required.

=head3 transformation

This event's state transformation function, represented by a subref. By default it does nothing, so it should be set as a reasonable subref changing the given state argument (as a hashref) based on the given data (as a hashref) by side-effect.

=head2 METHODS

=head3 apply_to

    $event->apply_to(\%state, $logger);

Applies this event's L<transformation> to the given state (by side-effect). If a C<$logger> as a subref is given, it is used to log this application.

=head3 summary

    say $event->summary;

Returns a one-line summarized stringification of this event.

=head1 SEE ALSO

L<EventStore::Tiny>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2018 Mirko Westermeier (mail: mirko@westermeier.de)

Released under the MIT License (see LICENSE.txt for details).

=cut
