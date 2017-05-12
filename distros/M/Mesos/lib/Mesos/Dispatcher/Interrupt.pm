package Mesos::Dispatcher::Interrupt;
use AnyEvent;
use Async::Interrupt;
use Scalar::Util qw(weaken);
use Scope::Guard qw(guard);
use Moo;
use namespace::autoclean;
extends 'Mesos::Dispatcher';

=head1 NAME

Mesos::Dispatcher::Interrupt

=head1 DESCRIPTION

A Mesos::Dispatcher implementation that uses Async::Interrupt for dispatching.

In order to interrupt AnyEvent, during Mesos::Dispatcher's wait call,
the Interrupt implementation creates an AnyEvent timer to trigger every
100ms. This is needed because AnyEvent's recv blocks on a select call,
which Async::Interrupt cannot interrupt by itself.

=cut

has interrupt => (
    is      => 'ro',
    builder => '_build_interrupt',
);

sub _build_interrupt {
    weaken(my $self = shift);
    return Async::Interrupt->new(cb => sub { $self->call });
}

sub xs_init {
    my ($self) = @_;
    my ($func, $arg) = $self->interrupt->signal_func;
    $self->_xs_init($self->channel, $func, $arg);
}

sub ticker {
    my ($self, $tick) = @_;
    $tick ||= 0.1;
    return AnyEvent->timer(
        after    => $tick,
        interval => $tick,
        cb       => sub { },
    );
}

around wait => sub {
    my ($orig, $self, @args) = @_;
    my $ticker = $self->ticker;

    return $self->call if $self->channel->size;
    $self->$orig(@args);
};

1;
