use strict;
use lib 't/lib';
use MiniTest tests => 3;

require Devel::GlobalPhase;
Devel::GlobalPhase->import;

eval q[
      { is global_phase, 'RUN',     'RUN'     };
END   { is global_phase, 'END',     'END'     };
our $global = Test::Scope::Guard->new(sub {
      { is global_phase, 'DESTRUCT', 'DESTRUCT' };
      done_testing;
});
] or die $@;
