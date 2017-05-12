use strict;
use Config;
BEGIN {
  unless ($Config{useithreads}) {
    print "1..0 # SKIP your perl does not support ithreads\n";
    exit 0;
  }
}

BEGIN {
  unless (eval { require threads }) {
    print "1..0 # SKIP threads.pm not installed\n";
    exit 0;
  }
  threads->VERSION(1.07);
}

use lib 't/lib';
use MiniTest tests => 8;
use Devel::GlobalPhase;

sub t_name () { threads->tid ? 'thread' : 'main program' }

      { is global_phase, 'RUN',     'pre-thread RUN in ' . t_name };
END   { is global_phase, 'END',     'pre-thread END in ' . t_name };
our $global = Test::Scope::Guard->new(sub {
      { is global_phase, 'DESTRUCT', 'pre-thread global destroy -> DESTRUCT in ' . t_name }
      threads->tid or done_testing;
});
sub CloneTest::CLONE
      { is global_phase, 'RUN',     'CLONE -> RUN in ' . t_name };

threads->create(sub {
eval q[
      { is global_phase, 'RUN',     'RUN in ' . t_name };
END   { is global_phase, 'END',     'END in ' . t_name };
our $global_thread = Test::Scope::Guard->new(sub {
      { is global_phase, 'DESTRUCT', 'in thread global destroy -> DESTRUCT in ' . t_name };
});
1; # don't leak guard
];
})->join;
