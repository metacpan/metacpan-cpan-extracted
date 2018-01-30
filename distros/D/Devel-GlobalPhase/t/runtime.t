use strict;
use lib 't/lib';
use MiniTest tests => 3;
use Test::Scope::Guard;

require Devel::GlobalPhase;
Devel::GlobalPhase->import;

eval '#line '.(__LINE__+1).q[ "].__FILE__.q["].q[
  {
    is global_phase, 'RUN',      'RUN';
  }
  END {
    local $TODO = "can't reliably detect runtime END blocks"
      if Devel::GlobalPhase::_CALLER_CAN_SEGFAULT
        && !Devel::GlobalPhase::_NATIVE_GLOBAL_PHASE;
    is global_phase, 'END',      'END';
  }
  our $global = Test::Scope::Guard->new(sub {
    is global_phase, 'DESTRUCT', 'DESTRUCT';
    done_testing;
  });
  1;
] or die $@;
