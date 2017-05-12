package MethodWorker;

use strict;
use warnings;

use base 'Gearman::Spawner::Worker';

sub new {
    my $self = shift;
    $self = fields::new($self) unless ref $self;
    $self->SUPER::new(@_);

    $self->register_method('constant');
    $self->register_method('echo');
    $self->register_method('echo_ref');
    $self->register_method('add');
    return $self;
}

sub constant {
    my MethodWorker $self = shift;
    my $arg = shift;
    if ($arg) {
        return "string";
    }
    else {
        return 123;
    }
}

sub echo {
    my MethodWorker $self = shift;
    my $arg = shift;
    return $arg;
}

sub echo_ref {
    my MethodWorker $self = shift;
    my $arg_ref = shift;
    my $arg = $$arg_ref;
    return \$arg;
}

sub add {
    my MethodWorker $self = shift;
    my $args = shift;
    return { sum => $self->{data}{left_hand} + $args->{right_hand} };
}

1;
