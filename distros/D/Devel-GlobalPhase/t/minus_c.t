use strict;
use lib 't/lib';
use MiniTest tests => 3;
use Test::Scope::Guard;
BEGIN {
  require B;
  B::minus_c();

  ok $^C, "Test properly running under minus-c";
}
BEGIN {
    package
        Quiet::MinusC;
    sub PUSHED { bless \(my $s), $_[0] }
    sub WRITE {
        return ( / syntax OK\n$/ || print {$_[2]} $_ ) ? length : -1 for $_[1];
    }
    binmode STDERR, ':via(Quiet::MinusC)';
}
use Devel::GlobalPhase;

BEGIN { is global_phase, 'START',   'START'   };
END   { is global_phase, 'END',     'END'     };
BEGIN {
our $global = Test::Scope::Guard->new(sub {
      { is global_phase, 'DESTRUCT', 'DESTRUCT' };
      done_testing;
});
}
