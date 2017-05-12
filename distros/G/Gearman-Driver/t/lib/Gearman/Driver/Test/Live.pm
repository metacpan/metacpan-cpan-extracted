package    # hide from PAUSE
  Gearman::Driver::Test::Live;

use base qw(Gearman::Driver::Test::Base::All);
use Moose;

sub job : Job {
    my ( $self, $job, $workload ) = @_;
    return 'ok';
}

1;
