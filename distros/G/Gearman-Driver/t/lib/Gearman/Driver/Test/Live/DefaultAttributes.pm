package    # hide from PAUSE
  Gearman::Driver::Test::Live::DefaultAttributes;

use base qw(Gearman::Driver::Test::Base::All);
use Moose;

sub default_attributes {
    return {
        Decode       => 'dec',
        Encode       => 'enc',
        ProcessGroup => 'group1',
    };
}

sub job1 : Job {
    my ( $self, $job, $workload ) = @_;
    return $workload;
}

sub job2 : Job {
    my ( $self, $job, $workload ) = @_;
    return $job->workload;
}

sub job3 : Job {
    my ( $self, $job, $workload ) = @_;
    return $self->pid;
}

sub job4 : Job {
    my ( $self, $job, $workload ) = @_;
    return $self->pid;
}

sub enc {
    my ( $self, $result ) = @_;
    my $package = ref($self);
    return "ENCODE::${result}::ENCODE";
}

sub dec {
    my ( $self, $workload ) = @_;
    my $package = ref($self);
    return "DECODE::${workload}::DECODE";
}

sub pid {
    my ($self) = @_;
    return $$;
}

1;
