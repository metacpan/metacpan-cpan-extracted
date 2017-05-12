package    # hide from PAUSE
  Gearman::Driver::Test::Live::Quit;

use base qw(Gearman::Driver::Test::Base::All);
use Moose;

sub quit1 : Job : ProcessGroup(group1) {
    my ( $self, $job, $workload ) = @_;
    exit(0) if $workload eq 'exit';
    return $self->pid;
}

sub quit2 : Job : ProcessGroup(group1) {
    my ( $self, $job, $workload ) = @_;
    die() if $workload eq 'die';
    return $self->pid;
}

sub pid {
    my ($self) = @_;
    return $$;
}

1;
