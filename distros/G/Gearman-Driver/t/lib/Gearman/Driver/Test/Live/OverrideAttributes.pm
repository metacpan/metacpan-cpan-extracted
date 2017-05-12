package    # hide from PAUSE
  Gearman::Driver::Test::Live::OverrideAttributes;

use base qw(Gearman::Driver::Test::Base::All);
use Moose;

sub override_attributes {
    return {
        MinProcesses => 0,
        Encode       => 'encode',
        Decode       => 'decode',
    };
}

sub job1 : Job : MinProcesses(5) : Encode(invalid) : Decode(invalid) {
    my ( $self, $job, $workload ) = @_;
    return $workload;
}

sub job2 : Job : MinProcesses(5) : Encode(invalid) : Decode(invalid) {
    my ( $self, $job, $workload ) = @_;
    return $job->workload;
}

sub encode {
    my ( $self, $result ) = @_;
    my $package = ref($self);
    return "ENCODE::${result}::ENCODE";
}

sub decode {
    my ( $self, $workload ) = @_;
    my $package = ref($self);
    return "DECODE::${workload}::DECODE";
}

1;
