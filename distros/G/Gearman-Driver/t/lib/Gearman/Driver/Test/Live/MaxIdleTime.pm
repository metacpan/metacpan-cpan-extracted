package    # hide from PAUSE
  Gearman::Driver::Test::Live::MaxIdleTime;

use base qw(Gearman::Driver::Test::Base::All);
use Moose;

sub get_pid : Job : MinProcesses(0) {
    my ( $self, $job, $workload ) = @_;
    return $self->pid;
}

sub pid {
    my ($self) = @_;
    return $$;
}

1;
