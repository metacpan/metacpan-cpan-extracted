package Mesos::XUnit::Dispatcher::Interrupt;
use AnyEvent;
use Try::Tiny;
use Test::Class::Moose;
with 'Mesos::XUnit::Role::Dispatcher';
with 'Mesos::XUnit::Role::Dispatcher::CheckLeaks';
with 'Mesos::XUnit::Role::Dispatcher::CheckWait';

has ticker => (
    is      => 'ro',
    builder => '_build_ticker'
);
sub _build_ticker {
    my $tick = 0.1;
    return AnyEvent->timer(
        after    => $tick,
        interval => $tick,
        cb       => sub { },
    );
}

sub test_startup {
    my ($self) = @_;
    try {
        require AnyEvent::Future;
        require Mesos::Dispatcher::Interrupt;
    } catch {
        $self->test_skip('Could not require Mesos::Dispatcher::Interrupt');
    };
}

sub new_future { AnyEvent::Future->new }

sub new_delay {
    my ($self, $after, $cb) = @_;
    return AnyEvent->timer(
        after => $after,
        cb    => $cb,
    );
}

sub new_dispatcher {
    my ($self, @args) = @_;
    return Mesos::Dispatcher::Interrupt->new(@args);
}

1;
