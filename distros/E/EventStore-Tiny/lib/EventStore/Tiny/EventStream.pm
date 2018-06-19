package EventStore::Tiny::EventStream;
use Mo 'default';

has events => [];

sub add_event {
    my ($self, $event) = @_;

    # append event to internal list
    push @{$self->events}, $event;
}

sub length {
    my $self = shift;
    return scalar @{$self->events};
}

sub first_timestamp {
    my $self = shift;
    return unless @{$self->events};
    return $self->events->[0]->timestamp;
}

sub last_timestamp {
    my $self = shift;
    return unless @{$self->events};
    return $self->events->[$self->length - 1]->timestamp;
}

sub apply_to {
    my ($self, $state, $logger) = @_;

    # start with empty state by default
    $state = {} unless defined $state;

    # apply all events
    $_->apply_to($state, $logger) for @{$self->events};

    # done
    return $state;
}

sub substream {
    my ($self, $selector) = @_;

    # default selector: take everything
    $selector = sub {1} unless defined $selector;

    # filter events
    my @filtered = grep {$selector->($_)} @{$self->events};

    # build new sub stream
    return EventStore::Tiny::EventStream->new(events => \@filtered);
}

sub until {
    my ($self, $timestamp) = @_;

    # all events until the given timestamp (including)
    return $self->substream(sub {$_->timestamp <= $timestamp});
}

sub after {
    my ($self, $timestamp) = @_;

    # all events after the given timestamp (excluding)
    return $self->substream(sub {$_->timestamp > $timestamp});
}

1;

=pod

=encoding utf-8

=head1 NAME

EventStore::Tiny::EventStream

=head1 REFERENCE

EventStore::Tiny::Stream implements the following attributes and methods.

=head2 events

    my $event17 = $stream->events->[16];

Internal list representation (arrayref) of all events of this stream.

=head2 add_event

    $stream->add_event($event);

Adds an event to the stream.

=head2 length

    my $event_count = $stream->length;

Returns the number of events in this stream.

=head2 first_timestamp

    my $start_ts = $stream->first_timestamp;

Returns the timestamp of the first event of this stream.

=head2 last_timestamp

    my $end_ts = $stream->last_timestamp;

Returns the timestamp of the last event of this stream.

=head2 apply_to

    my $state = $stream->apply_to(\%state);

Applies the whole stream (all events one after another) to a given state (by default an empty hash). The state is changed by side-effect but is also returned.

=head2 substream

    my $filtered = $stream->substream(sub {
        my $event = shift;
        return we_want($event);
    });

Creates a substream using a given filter. All events the given subref returns true for are selected for this substream.

=head2 until

    my $pre_stream = $stream->until($timestamp);

Returns a substream with all events before or at the same time of a given timestamp.

=head2 after

    my $post_stream = $stream->after($timestamp);

Returns a substream with all events after a given timestamp.

=head1 SEE ALSO

L<EventStore::Tiny>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2018 Mirko Westermeier (mail: mirko@westermeier.de)

Released under the MIT License (see LICENSE.txt for details).

=cut
