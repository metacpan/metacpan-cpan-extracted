use Test::More tests => 1;

use Devel::PrettyTrace;
use lib 't/inc';
$Devel::PrettyTrace::Opts{colored} = 0;

my $f;
sub z{
	$f = bt;
}

eval 'use Foo';
$f =~ s/eval \d+/eval/g;

like($f, qr!\Q  main::z() called at t/inc/Foo.pm line 4
  Foo::import(
    [0] "Foo"
  ) called at (eval) line \E\d\Q
  main::BEGIN() called at \E[^ ]+\Q line \E\d\Q
  eval {...} called at \E[^ ]+\Q line \E\d\Q
  eval 'use Foo\E;?\Q' called at t/04_begin.t line 12
\E!s);

