use strict;
use Config;
BEGIN {
  unless ($Config{useithreads}) {
    print "1..0 # SKIP your perl does not support ithreads\n";
    exit 0;
  }
}
use Carp;
my $early_load;

BEGIN {
  $early_load = !!$INC{'Devel/GlobalPhase.pm'};
  unless (eval { require threads }) {
    print "1..0 # SKIP threads.pm not installed\n";
    exit 0;
  }
  threads->VERSION(1.07);
}

use lib 't/lib';
use MiniTest tests => 8;
use Test::Scope::Guard;
use Devel::GlobalPhase;

sub t_name () { threads->tid ? 'thread' : 'main program' }

{
  is global_phase, 'RUN',     'pre-thread RUN in ' . t_name;
}
END   {
  local $TODO = "can't reliably detect runtime END blocks"
    if Devel::GlobalPhase::_CALLER_CAN_SEGFAULT
      && !Devel::GlobalPhase::_NATIVE_GLOBAL_PHASE
      && $early_load;
  is global_phase, 'END',     'pre-thread END in ' . t_name;
}
our $global = Test::Scope::Guard->new(sub {
  is global_phase, 'DESTRUCT', 'pre-thread global destroy -> DESTRUCT in ' . t_name;
  threads->tid or done_testing;
});
sub CloneTest::CLONE {
  is global_phase, 'RUN',     'CLONE -> RUN in ' . t_name;
}

threads->create(sub {
eval '#line '.(__LINE__+1).q[ "].__FILE__.q["].q[
  {
    is global_phase, 'RUN',     'RUN in ' . t_name;
  }
  END {
    local $TODO = "can't reliably detect runtime END blocks"
      if Devel::GlobalPhase::_CALLER_CAN_SEGFAULT
        && !Devel::GlobalPhase::_NATIVE_GLOBAL_PHASE;
    is global_phase, 'END',     'END in ' . t_name;
  }
  our $global_thread = Test::Scope::Guard->new(sub {
    is global_phase, 'DESTRUCT', 'in thread global destroy -> DESTRUCT in ' . t_name;
  });
  1; # don't leak guard
] or die $@;
})->join;
