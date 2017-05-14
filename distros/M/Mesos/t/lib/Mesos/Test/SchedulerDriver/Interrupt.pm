package Mesos::Test::SchedulerDriver::Interrupt;
use Mesos::Channel::Interrupt;
use Moo;
use strict;
use warnings;


has scheduler => (
    is       => 'ro',
    required => 1,
);

has channel => (
    is      => 'ro',
    builder => 1,
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
    return $self->scheduler;
}

with 'Mesos::Role::Dispatcher';


1;
