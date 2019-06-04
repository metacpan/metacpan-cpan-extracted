#!/usr/bin/perl

use warnings;
use strict;
use Test::Inter;
my $t = new Test::Inter $0;
require "do_tests.pl";

init_tests('alpha-2',1);
$t->tests(func  => \&tests,
          tests => $::tests);
$t->done_testing();

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
