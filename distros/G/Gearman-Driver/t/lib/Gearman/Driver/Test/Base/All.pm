package    # hide from PAUSE
  Gearman::Driver::Test::Base::All;

use base qw(Gearman::Driver::Worker);
use Moose;

sub process_name {
    my ( $self, $orig, $job_name ) = @_;
    return "$orig ($job_name)";
}

1;