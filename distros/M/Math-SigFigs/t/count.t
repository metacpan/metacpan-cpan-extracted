#!/usr/bin/perl -w

BEGIN {
  use Test::Inter;
  $t = new Test::Inter 'CountSigFigs';
}

BEGIN { $t->use_ok('Math::SigFigs'); }

$tests="

x      =>

0.003  => 1

+0.003 => 1

-0.003 => 1

0.103  => 3

1.0500 => 5

11.    => 2

11     => 2

110    => 2

110.   => 3

0      => 1

0.0    => 1

1.2e2  => 2

0.0e2  => 1

";

$t->tests(func  => \&CountSigFigs,
          tests => $tests);

$t->done_testing();
1;

# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 3
# cperl-continued-statement-offset: 2
# cperl-continued-brace-offset: 0
# cperl-brace-offset: 0
# cperl-brace-imaginary-offset: 0
# cperl-label-offset: 0
# End:

