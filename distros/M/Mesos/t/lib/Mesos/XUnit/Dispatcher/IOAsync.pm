package Mesos::XUnit::Dispatcher::IOAsync;
use Try::Tiny;
use Test::Class::Moose;
with 'Mesos::XUnit::Role::Dispatcher';
with 'Mesos::XUnit::Role::Dispatcher::CheckLeaks';
with 'Mesos::XUnit::Role::Dispatcher::CheckWait';

sub test_startup {
    my ($self) = @_;
    try {
        require IO::Async::Loop;
        require Mesos::Dispatcher::IOAsync;
    } catch {
        $self->test_skip('Could not require Mesos::Dispatcher::IOAsync');
    };
}

has loop => (
    is      => 'ro',
    lazy    => 1,
    default => sub { IO::Async::Loop->new },
);

sub new_future { shift->loop->new_future }

sub new_delay {
    my ($self, $after, $cb) = @_;
    my $loop = $self->loop;
    return $loop->delay_future(after => $after)
                ->on_done($cb);
}

sub new_dispatcher {
    my ($self, @args) = @_;
    return Mesos::Dispatcher::IOAsync->new(loop => $self->loop, @args);
}

1;
