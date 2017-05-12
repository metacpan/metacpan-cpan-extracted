package Mesos::XUnit::Role::Dispatcher::CheckLeaks;
use Mesos::Types qw(TaskID);
use Test::LeakTrace;
use Test::Class::Moose::Role;
requires qw(new_dispatcher);

sub test_dispatcher_constructor {
    my ($test) = @_;

    no_leaks_ok {
        $test->new_dispatcher;
    } 'dispatcher constructor does not leak';
}

sub test_dispatcher_event_transmission_leaks {
    my ($test) = @_;
    my $dispatcher = $test->new_dispatcher;

    no_leaks_ok {
        my $task_id = TaskID->new({value => "mytask"});
        $dispatcher->send(qw(test-command some args), $task_id);
        $dispatcher->recv;
    } 'event transmission does not leak';
}

sub test_dispatcher_event_callback_leaks {
    my ($test) = @_;
    my $dispatcher = $test->new_dispatcher;

    no_leaks_ok {
        my $future = $test->new_future;
        $dispatcher->set_cb(sub { $future->done($dispatcher->recv) });
        $dispatcher->send(qw(test-command some args));

        $future->get;
        $dispatcher->set_cb(sub{ });
    } 'event transmission does not leak';
}

1;
