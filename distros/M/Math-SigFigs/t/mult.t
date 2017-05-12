#!/usr/bin/perl -w

BEGIN {
  use Test::Inter;
  $t = new Test::Inter 'multSF';
}

BEGIN { $t->use_ok('Math::SigFigs','multSF'); }

$tests="

1.234     2.1       => 2.6

2.1       1.234     => 2.6

1.234     2.10      => 2.59

1.234     210       => 260

1.234     210.      => 259

1.234     0.0       => 0.0

1.234     0.00      => 0.00

1.234     0.0000    => 0.0000

1.234     0.00000   => 0.0000

####

1.0       __undef__ =>

__undef__ 1.0       =>

__undef__ __undef__ =>

";

$t->tests(func  => \&multSF,
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

