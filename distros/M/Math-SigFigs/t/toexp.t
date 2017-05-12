#!/usr/bin/perl -w

BEGIN {
  use Test::Inter;
  $t = new Test::Inter '_ToExp';
}

BEGIN { $t->use_ok('Math::SigFigs'); }

$tests="

''  123   456   0  => 123.456 0

''  123   456   1  => 12.3456 -1

''  123   456   2  => 1.23456 -2

''  123   456   4  => .0123456 -4

''  123   456  -1  => 1234.56 1

''  123   456  -2  => 12345.6 2

''  123   456  -4  => 1234560. 4

";

$t->tests(func  => \&Math::SigFigs::_ToExp,
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

