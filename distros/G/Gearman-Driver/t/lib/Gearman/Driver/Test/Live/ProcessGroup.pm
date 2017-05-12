package    # hide from PAUSE
  Gearman::Driver::Test::Live::ProcessGroup;

use base qw(Gearman::Driver::Test::Base::All);
use Moose;

sub job1 : Job : MinProcesses(1) : ProcessGroup(group1) {
    my ( $self, $job, $workload ) = @_;
    return $self->pid;
}

sub job2 : Job : ProcessGroup(group1) {
    my ( $self, $job, $workload ) = @_;
    return $self->pid;
}

sub job3 : Job : ProcessGroup(group1) {
    my ( $self, $job, $workload ) = @_;
    return $self->pid;
}

sub job4 : Job : ProcessGroup(group1) {
    my ( $self, $job, $workload ) = @_;
    return $self->pid;
}

sub job5 : Job {
    my ( $self, $job, $workload ) = @_;
    return $self->pid;
}

sub pid {
    my ($self) = @_;
    return $$;
}

1;
