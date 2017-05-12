package Mesos::XUnit::Dispatcher::AnyEvent;
use Try::Tiny;
use Test::Class::Moose;
with 'Mesos::XUnit::Role::Dispatcher';
with 'Mesos::XUnit::Role::Dispatcher::CheckLeaks';
with 'Mesos::XUnit::Role::Dispatcher::CheckWait';

sub test_startup {
    my ($self) = @_;
    try {
        require AnyEvent::Future;
        require Mesos::Dispatcher::AnyEvent;
    } catch {
        $self->test_skip('Could not require Mesos::Dispatcher::AnyEvent');
    };
}

sub test_setup {
    my ($test) = @_;
    my $test_method = $test->test_report->current_method;
    if ($test_method->name eq 'test_dispatcher_constructor') {
        $test->test_skip('TODO');
    }
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
    return Mesos::Dispatcher::AnyEvent->new(@args);
}

1;
