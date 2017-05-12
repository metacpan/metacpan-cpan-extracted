use strict;
use warnings;

BEGIN {
  if ($ENV{DEVEL_GLOBALDESTRUCTION_PP_TEST}) {
    unshift @INC, sub {
      die 'no XS' if $_[1] eq 'Devel/GlobalDestruction/XS.pm';
    };
  }
}

{
  package Test::Scope::Guard;
  sub new { my ($class, $code) = @_; bless [$code], $class; }
  sub DESTROY { my $self = shift; $self->[0]->() }
}

use POSIX qw(_exit);

$|++;
print "1..3\n";

our $alive = Test::Scope::Guard->new(sub {
  require Devel::GlobalDestruction;
  my $gd = Devel::GlobalDestruction::in_global_destruction();
  print(($gd ? '' : 'not ') . "ok 3 - global destruct detected when loaded during GD\n");
  _exit($gd ? 0 : 1);
});

print(($alive ? '' : 'not ') . "ok 1 - alive during runtime\n");
END {
  print(($alive ? '' : 'not ') . "ok 2 - alive during END\n");
}
