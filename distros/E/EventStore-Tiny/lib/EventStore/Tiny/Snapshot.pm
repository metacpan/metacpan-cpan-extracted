package EventStore::Tiny::Snapshot;

use strict;
use warnings;

use Class::Tiny {
    state       => sub {die "state is required.\n"},
    timestamp   => sub {die "timestamp is required.\n"},
};

sub BUILD {
    my $self = shift;

    # Check non-lazy
    $self->state;
    $self->timestamp;

    # Return nothing (will be ignored anyway)
    return;
}

1;

=pod

=encoding utf-8

=head1 NAME

EventStore::Tiny::Snapshot

=head1 REFERENCE

EventStore::Tiny::Snapshot implements the following attributes and methods.

=head2 state

    my $state_hr = $snapshot->state;

Returns the hashref representing the state of this snapshot.

=head2 timestamp

    my $timestamp = $snapshot->timestamp;

Returns a timestamp representing the time this snapshot was created.

=head1 SEE ALSO

L<EventStore::Tiny>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2018 Mirko Westermeier (mail: mirko@westermeier.de)

Released under the MIT License (see LICENSE.txt for details).

=cut
