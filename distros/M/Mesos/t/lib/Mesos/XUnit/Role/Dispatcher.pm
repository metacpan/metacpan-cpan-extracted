package Mesos::XUnit::Role::Dispatcher;
use Scalar::Util qw(weaken);
use Moose::Meta::Class;
use Test::Class::Moose::Role;
requires qw(new_delay new_dispatcher);

sub new_handler {
    my ($test, %methods) = @_;

    while (my ($name, $code) = each %methods) {
        $methods{$name} = sub {
            my ($self, $driver, @args) = @_;
            $self->last_event([$name, @args]);
            return $code->(@_);
        };
    }

    my $class = Moose::Meta::Class->create_anon_class(
        superclasses => [qw(Moose::Object)],
        attributes   => [
            Moose::Meta::Attribute->new('last_event', is => 'rw')
        ],
        methods => \%methods,
    );
    return $class->new_object(%methods);
}

sub new_driver {
    my ($test, %methods) = @_;
    my $class = Moose::Meta::Class->create_anon_class(
        cache        => 1,
        superclasses => [qw(Moose::Object)],
        roles        => [qw(Mesos::Role::HasDispatcher)],
        attributes   => [
            Moose::Meta::Attribute->new('event_handler',
                is      => 'ro',
                handles => [qw(last_event)],
            ),
        ],
        methods => {
            start  => sub {},
            stop   => sub {},
            abort  => sub {},
            status => sub {},
            BUILD  => sub {},
        },
    );
    $class->make_immutable;

    return $class->new_object(
        event_handler => $test->new_handler(%methods),
        dispatcher    => $test->new_dispatcher,
    );
}

sub test_basic_dispatch {
    my ($test) = @_;
    my $dispatcher = $test->new_dispatcher;

    my @expected = qw(some results here);
    my $future = $test->new_future;
    weaken(my $wdispatcher = $dispatcher);
    $dispatcher->set_cb(sub { $future->done($wdispatcher->recv) });
    $dispatcher->send(@expected);
    is_deeply [$future->get], \@expected, 'dispatcher cb triggered with sent args';
}

sub test_event_dispatching {
    my ($test) = @_;

    my $future1 = $test->new_future;
    my $future2 = $test->new_future;
    my $driver  = $test->new_driver(
        event1 => sub { $future1->done },
        event2 => sub { $future2->done },
    );
    my $dispatcher = $driver->dispatcher;

    {
        my @args = qw(event1 args for testing);
        $dispatcher->send(@args);
        $future1->get;
        ok $future1->is_done,  'dispatched event1 command';
        ok !$future2->is_done, 'did not dispatch event2';
        is_deeply $driver->last_event, \@args, 'received event1 args';
    }

    {
        my @args = qw(event2 args for testing);
        $dispatcher->send(@args);
        $future2->get;
        ok $future2->is_done, 'dispatched event2 command';
        is_deeply $driver->last_event, \@args, 'received event2 args';
    }
}

1;
