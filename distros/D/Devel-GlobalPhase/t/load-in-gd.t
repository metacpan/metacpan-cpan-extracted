use strict;
use lib 't/lib';
use MiniTest tests => 1;

use Devel::GlobalPhase;
use B ();

sub gd::DESTROY {
  require Devel::GlobalPhase;
  is Devel::GlobalPhase::global_phase(), 'DESTRUCT', 'works when loaded in global destruct';
  done_testing;
}
our $gd = bless {}, 'gd';

