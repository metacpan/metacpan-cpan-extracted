package TestRun;

use strict;

use Distributed::Process;
use Distributed::Process::Worker;
our @ISA = qw/ Distributed::Process::Worker /;

use threads;

our @data;
our $data_counter : shared = -1;

sub get_next_data {

    my $self = shift;

    lock $data_counter;
    ($data_counter += 1) %= @data;
    $data[$data_counter];
}

sub to_be_run_on_server {

    my $self = shift;

    'next is ' . $self->get_next_data();
}

sub square {

    my $self = shift;

    $_[0] ** 2;
}

sub run {

    my $self = shift;

    $self->result($self->run_on_server('to_be_run_on_server'));
    my ($n) = $self->client()->id() =~ /(\d+)/;
    $self->result("Square of $n is " . $self->run_on_server(square => $n));
    sleep $n;
    $self->result($self->run_on_server('to_be_run_on_server'));
}

1;
