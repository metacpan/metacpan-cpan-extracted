#!/usr/bin/perl -w

BEGIN {
  use Test::Inter;
  $t = new Test::Inter 'divSF';
}

BEGIN { $t->use_ok('Math::SigFigs','divSF'); }

$tests="

1.234 2.1     => 0.59

1.234 2.10    => 0.588

1.234 210     => 0.0059

1.234 210.    => 0.00588

1.234 2.10000 => 0.5876

####

1.0 __undef__ =>

__undef__ 1.0 =>

__undef__ __undef__ =>

1.0 0.0 =>

0.0 1.0 => 0.0

";

$t->tests(func  => \&divSF,
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

