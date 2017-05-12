package    # hide from PAUSE
  Gearman::Driver::Test::Live::WithBaseClass;

use base qw(Gearman::Driver::Test::Base::TestWorker);
use Moose;

sub job1 : Job : ProcessGroup(group1) {
    my ( $self, $job, $workload ) = @_;
    open my $fh, ">>$workload" or die "cannot open file $workload: $!";
    print $fh "job1 ...\n";
    close $fh;
}

sub job2 : Job : ProcessGroup(group1) {
    my ( $self, $job, $workload ) = @_;
    die;
}

1;
