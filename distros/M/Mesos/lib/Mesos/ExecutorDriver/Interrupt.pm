package Mesos::ExecutorDriver::Interrupt;
use Mesos::Channel::Interrupt;
use Mesos::Types qw(Channel);
use Mesos::Messages;
use Moo;

=head1 NAME

Mesos::ExecutorDriver::Interrupt

=head1 DESCRIPTION

An ExecutorDriver that uses Async::Interrupt for event handling.

=cut

has channel => (
    is       => 'ro',
    isa      => Channel,
    builder  => 1,
    # this needs to be lazy so that BUILD runs xs_init first
    lazy     => 1,
);

sub _build_channel {
    my ($self) = @_;
    return Mesos::Channel::Interrupt->new(callback => sub { $self->dispatch_events });
}

has process => (
    is      => 'ro',
    builder => 1,
    lazy    => 1,
);

sub _build_process {
    my ($self) = @_;
    return $self->executor;
}

with qw(
    Mesos::Role::ExecutorDriver
    Mesos::Role::Dispatcher
);


sub xs_init {
    my ($self) = @_;
    return $self->_xs_init($self->channel);
}

sub join {
    my ($self) = @_;
    sleep 1 while $self->status == Mesos::Status::DRIVER_RUNNING;
}

1;
