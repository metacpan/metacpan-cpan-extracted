package    # hide from PAUSE
  Gearman::Driver::Test::Base::TestWorker;

use base qw(Gearman::Driver::Test::Base::All);
use Moose;

sub begin {
    my ( $self, $job, $workload ) = @_;
    open my $fh, ">>$workload" or die "cannot open file $workload: $!";
    print $fh "begin ...\n";
    close $fh;
}

sub end {
    my ( $self, $job, $workload ) = @_;
    open my $fh, ">>$workload" or die "cannot open file $workload: $!";
    print $fh "end ...\n";
    close $fh;
}

1;