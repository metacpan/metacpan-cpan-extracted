# -*- Mode: Perl -*-
# t/01_ini.t; just to load Math::PartialOrder by using it

$TEST_DIR = './t';
#use lib qw(../blib/lib); $TEST_DIR = '.'; # for debugging

# load common subs
do "$TEST_DIR/common.plt";

plan(test => (1 + scalar(@classes)));

# 1 load Math::PartialOrder
use Math::PartialOrder;
ok(1);

# 2--N: load subclasses (1 subtest/class)
foreach (@classes) {
  $class = "Math::PartialOrder::$_";
  print "Test $class\n";
  eval "use $class;";
  ok(defined(${'Math::PartialOrder::'.$_.'::VERSION'})); # hack, but it ought to work...
}

print "\n";
# end of t/01_ini.t

