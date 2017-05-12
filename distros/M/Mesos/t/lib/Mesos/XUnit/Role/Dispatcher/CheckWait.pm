package Mesos::XUnit::Role::Dispatcher::CheckWait;
use Mesos::Test::Utils qw(timeout);
use Scalar::Util qw(weaken);
use Test::Class::Moose::Role;
requires qw(new_delay new_dispatcher);

sub test_wait {
    my ($self) = @_;
    my $dispatcher = $self->new_dispatcher;

    my $timedout = timeout { $dispatcher->wait } 0.1;
    ok $timedout, 'timed out waiting before event trigger';

    $timedout = timeout { $dispatcher->wait(1) } 0.1;
    ok $timedout, 'timed out when passed long wait';

    $timedout = timeout { $dispatcher->wait(0.1) } 1;
    ok !$timedout, 'returned when passed short wait';

    my @rv; timeout { @rv = $dispatcher->wait(0.1) };
    is scalar(@rv), 0, 'returned empty list when no events';

    my @command = qw(some command and args);
    weaken(my $wdispatcher = $dispatcher);
    $dispatcher->set_cb(sub { $wdispatcher->recv });
    my $delay = $self->new_delay(0.1, sub {
        $dispatcher->send(@command);
    });
    timeout { @rv = $dispatcher->wait };
    is_deeply \@rv, \@command, 'wait returned triggered event';
}

1;
