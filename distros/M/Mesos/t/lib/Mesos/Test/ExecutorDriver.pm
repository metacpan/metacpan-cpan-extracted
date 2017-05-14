package Mesos::Test::ExecutorDriver;
use Moo;
use strict;
use warnings;


has executor => (
    is       => 'ro',
    required => 1,
);

has process => (
    is      => 'ro',
    builder => 1,
    lazy    => 1,
);

sub _build_process {
    my ($self) = @_;
    return $self->executor;
}

has channel => (
    is => 'rw',
);

sub BUILD {
    my ($self) = @_;
    $self->channel($self->executor->channel);
}

with 'Mesos::Role::Dispatcher::AnyEvent';


1;
