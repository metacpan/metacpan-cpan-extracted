package Mesos::Role::Dispatcher::AnyEvent;
use Moo::Role;
use AnyEvent;

=head1 NAME

Mesos::Role::Dispatcher::AnyEvent

=head1 DESCRIPTION

Handle driver events in an AnyEvent loop.

=cut

with 'Mesos::Role::Dispatcher';

has watcher => (
    is        => 'rw',
    clearer   => 1,
    predicate => 1,
);

has loop_condvar => (
    is        => 'rw',
    clearer   => 1,
    predicate => 1,
);

=head1 METHODS


=cut

sub setup_watcher {
    my ($self) = @_;
    my $w = AnyEvent->io(
        fh   => $self->channel->fd,
        poll => 'r',
        cb   => sub {
            $self->clear_watcher;
            $self->dispatch_event;
            $self->setup_watcher;
        },
    );
    $self->watcher($w);
}

=head2 dispatch_loop()

    Enter into the AnyEvent loop. The loop can be broke by calling stop_dispatch.

=cut

sub dispatch_loop {
    my ($self) = @_;
    my $condvar = AnyEvent->condvar;
    $self->loop_condvar($condvar);
    $condvar->recv;
}

=head2 stop_dispatch()

    If in the middle of a dispatch loop, this will delete the condvar used, and break the loop.

=cut

sub stop_dispatch {
    my ($self) = @_;
    $self->clear_watcher;
    $self->loop_condvar->send if $self->has_loop_condvar;
}


1;
