package Dummy;

use warnings;
use strict;

use Distributed::Process; # qw/ :debug /;
use Distributed::Process::Worker;
our @ISA = qw/ Distributed::Process::Worker /;

sub test1 { DEBUG 'Dummy::test1'; my $self = shift; $self->result('test1 ' .uc $_[0]) }
sub test2 { DEBUG 'Dummy::test2'; my $self = shift; $self->result('test2 ' .uc($_[0]) . ' ' . $self->get_result_from_list()) }
sub test3 { DEBUG 'Dummy::test3'; my $self = shift; $self->result('test3 ' .uc $_[0]) }

{
    my $result = 1;
    sub get_result_from_list {

	INFO "get_result_from_list: yielding $result";
	'result_' . $result++;
    }
}

sub run {

    my $self = shift;

    DEBUG 'about to run test1';
    $self->test1();
    DEBUG 'about to synchronise';
    $self->synchro('meeting 1');
    DEBUG 'about to run test2';
    $self->test2($self->run_on_server('get_result_from_list'));
    DEBUG 'about to synchronise';
    $self->synchro('meeting 2');
    DEBUG 'about to run test3';
    $self->test3($self->run_on_server('get_result_from_list'));
}

1;
