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
__END__
