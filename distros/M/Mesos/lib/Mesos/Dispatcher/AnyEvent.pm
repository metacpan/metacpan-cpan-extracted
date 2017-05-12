package Mesos::Dispatcher::AnyEvent;
use AnyEvent;
use Scalar::Util qw(weaken);
use Moo;
use namespace::autoclean;
extends 'Mesos::Dispatcher::Pipe';

=head1 NAME

Mesos::Dispatcher::AnyEvent

=head1 DESCRIPTION

A Mesos::Dispatcher implementation, and subclass of Mesos::Dispatcher::Pipe.

Creates an AnyEvent I/O watcher to handle reading from the pipe.

=cut

has ae_watcher => (
    is => 'rw',
);

sub setup_ae_watcher {
    weaken(my $self = shift);
    my $w = AnyEvent->io(
        fh   => $self->fd,
        poll => 'r',
        cb   => sub { $self->call },
    );
    $self->ae_watcher($w);
}

sub BUILD {
    my ($self) = @_;
    $self->setup_ae_watcher;
}

1;
