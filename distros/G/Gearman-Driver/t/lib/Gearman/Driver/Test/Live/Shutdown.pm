package    # hide from PAUSE
  Gearman::Driver::Test::Live::Shutdown;

use base qw(Gearman::Driver::Test::Base::All);
use Moose;

sub begin {
    my ( $self, $job, $workload ) = @_;
    open my $fh, ">>$workload" or die "cannot open file $workload: $!";
    print $fh "begin ...\n";
    close $fh;
}

sub job1 : Job : ProcessGroup(group1) {
    my ( $self, $job, $workload ) = @_;

    open my $fh, ">>$workload" or die "cannot open file $workload: $!";
    print $fh "started job1 ...\n";

    my $telnet_client = Net::Telnet->new(
        Timeout => 30,
        Host    => '127.0.0.1',
        Port    => 47300,
    );
    $telnet_client->print('shutdown');
    sleep 1;

    print $fh "done with job1 ...\n";
    close $fh;
}

sub end {
    my ( $self, $job, $workload ) = @_;
    open my $fh, ">>$workload" or die "cannot open file $workload: $!";
    print $fh "end ...\n";
    close $fh;
}

1;
