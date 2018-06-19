package EventStore::Tiny::Event;
use Mo qw(default required build);

use UUID::Tiny qw(create_uuid_as_string);
use Time::HiRes qw(time);

has uuid            => sub {create_uuid_as_string};
has timestamp       => is => 'ro';
has name            => required => 1;
has transformation  => sub {sub {}};
has data            => {};

sub BUILD {
    my $self = shift;

    # make sure to set the timestamp non-lazy
    # see Mo issue #36 @ github
    $self->timestamp(time);
}

# lets transformation work on state by side-effect
sub apply_to {
    my ($self, $state, $logger) = @_;

    # apply the transformation by side effect
    $self->transformation->($state, $self->data);

    # log this event, if logger present
    $logger->($self) if defined $logger;

    # returned the same state just in case
    return $state;
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

=head1 SEE ALSO

L<EventStore::Tiny>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2018 Mirko Westermeier (mail: mirko@westermeier.de)

Released under the MIT License (see LICENSE.txt for details).

=cut
