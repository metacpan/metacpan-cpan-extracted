package Mesos::SchedulerDriver;
use Mesos;
use Mesos::Messages;
use Mesos::Channel;
use Moo;
use Types::Standard qw(:all);
use Type::Params qw(validate);
use Mesos::Types qw(:all);
use strict;
use warnings;

=head1 NAME

Mesos::SchedulerDriver - perl driver for Mesos scheduler drivers

=cut

sub xs_init {
    my ($self) = @_;
    return $self->_xs_init(grep {$_} map {$self->$_} qw(framework master channel credential));
}

sub join {
    my ($self) = @_;
    $self->dispatch_loop;
    return $self->status;
}

has channel => (
    is       => 'ro',
    isa      => Channel,
    builder  => 1,
    # this needs to be lazy so that BUILD runs xs_init first
    lazy     => 1,
);

sub _build_channel {
    require Mesos::Channel::Pipe;
    return Mesos::Channel::Pipe->new;
}

has process => (
    is      => 'ro',
    builder => 1,
    lazy    => 1,
);

sub _build_process {
    my ($self) = @_;
    return $self->scheduler;
}

# need to apply this after declaring channel and process
with 'Mesos::Role::SchedulerDriver';
with 'Mesos::Role::Dispatcher::AnyEvent';

after start => sub {
    my ($self) = @_;
    $self->setup_watcher;
};

after $_ => sub {
    my ($self) = @_;
    $self->stop_dispatch;
} for qw(stop abort);


1;
