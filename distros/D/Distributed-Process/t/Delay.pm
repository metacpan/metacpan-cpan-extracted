package Delay;

use Distributed::Process;
use Distributed::Process::Worker;

our @ISA = qw/ Distributed::Process::Worker /;

sub run {

    my $self = shift;
    $self->delay('delay_1');
    $self->result('after delay_1');
    $self->delay('delay_2');
    $self->result('after delay_2');
    $self->delay('delay_3');
    $self->result('after delay_3');
}

1;
