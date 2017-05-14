package Mesos::ExecutorDriver;
use Mesos::Messages;
use Mesos::Channel;
use Moo;
use Types::Standard qw(Str);
use Type::Params qw(validate);
use Mesos::Types qw(:all);
use strict;
use warnings;

=head1 NAME

Mesos::ExecutorDriver - perl driver for Mesos executor drivers

=cut

sub xs_init {
    my ($self) = @_;
    return $self->_xs_init($self->channel);
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
    return $self->executor;
}

# need to apply this after declaring channel and process
with 'Mesos::Role::ExecutorDriver';
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
