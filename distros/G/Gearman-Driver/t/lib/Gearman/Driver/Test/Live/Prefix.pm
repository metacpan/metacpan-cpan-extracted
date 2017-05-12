package    # hide from PAUSE
  Gearman::Driver::Test::Live::Prefix;

use base qw(Gearman::Driver::Test::Base::All);
use Moose;

sub prefix { '' }

sub ping : Job {
    my ( $self, $job, $workload ) = @_;
    return "pong";
}

1;
