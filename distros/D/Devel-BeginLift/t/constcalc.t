BEGIN { our @warnings; $SIG{__WARN__} = sub { push(@warnings, $_[0]); } }

use Devel::BeginLift 'foo';

use vars qw($int);

BEGIN { $int = 1 }

sub foo { warn "foo: $_[0]\n"; $int++; 4; }

sub bar { warn "bar: $_[0]\n"; $int; }

warn "yep\n";

warn foo("foo")."\n";

warn bar("bar")."\n";

no Devel::BeginLift;

foo('');

END {
  use Test::More 'no_plan';
  our @warnings;
  is(shift(@warnings), "foo: foo\n", "compile-time foo call first");
  is(shift(@warnings), "yep\n", "manual warning");
  is(shift(@warnings), "4\n", "const return from compile-time foo");
  is(shift(@warnings), "bar: bar\n", "bar called at run-time");
  is(shift(@warnings), "2\n", "\$int was incremented");
  is(shift(@warnings), "foo: \n", "run-time foo after BeginLift disabled");
  ok(!@warnings, "no more warnings");
}
