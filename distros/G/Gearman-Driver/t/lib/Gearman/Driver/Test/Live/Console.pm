package    # hide from PAUSE
  Gearman::Driver::Test::Live::Console;

use base qw(Gearman::Driver::Test::Base::All);
use Moose;

sub ping : Job : MinProcesses(0) : MaxProcesses(1) {
}

sub pong : Job : MinProcesses(0) : MaxProcesses(1) {
}

1;
