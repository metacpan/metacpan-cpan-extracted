# -*- Mode: Perl -*-
# t/05_clone.t - structural tests: is_equal(), assign(), merge(), clone(), clear()


$TEST_DIR = './t';
#use lib qw(../blib/lib); $TEST_DIR = '.'; # for debugging

# load common subs
do "$TEST_DIR/common.plt";

$n = scalar(@classes);
plan(test => ($n*2)+($n**2*4));


# load and generate subclasses (0 subtests)
foreach (@classes) {
  $class = "Math::PartialOrder::$_";
  $h = testhi($class);
  $hs{$class} = $h;
}

# test whole-hierarchy binary operations
foreach $c1 (keys(%hs)) {
  $h1 = $hs{$c1};
  isok("$c1->clone",($h2 = $h1->clone)); # ok=i+1
  isok("$c1->clear",$h2->clear);         # ok=i+0
  foreach $c2 (keys(%hs)) {
    $h2 = $hs{$c2};
    isok("$c1->assign($c2)", $h1->assign($h2));    # ok=(i+2)*j+0
    isok("$c1->is_equal($c2)",$h1->is_equal($h2)); # ok=(i+2)*j+1
    isok("$c1->merge($c2)", $h1->merge($h2));      # ok=(i+2)*j+2
    isok("$c1->is_equal($c2)",$h1->is_equal($h2)); # ok=(i+2)*j+3
  }
}

# end of t/05_clone.t

