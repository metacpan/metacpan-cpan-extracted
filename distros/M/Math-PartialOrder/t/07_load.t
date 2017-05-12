# -*- Mode: Perl -*-
# t/07_load.t - test Loader methods: load(), save(), store(), retrieve()

use Math::PartialOrder::Loader;

$TEST_DIR = './t';
#use lib qw(../blib/lib); $TEST_DIR = '.'; # for debugging


# load common subs
do "$TEST_DIR/common.plt";

$n = scalar(@classes);
plan(test => (8*$n));

# load and test subclasses (? subtests)
foreach (@classes) {
  $class = "Math::PartialOrder::$_";
  print "Test $class\n";
  $h = testhi($class);

  # test save
  isok('save',$h->save('tmp.gt'));      # ok=i+0
  $new = $class->new();
  isok('load',$new->load('tmp.gt'));    # ok=i+1
  isok('preserved',$new->is_equal($h)); # ok=i+2

  # test compile
  isok('compile',$h->compile); # ok=i+3

  # test store
  isok('store',$h->store('tmp.bin')); # ok=i+4
  $new = $class->new();
  isok('retrieve',$new->retrieve('tmp.bin')); # ok=i+5
  isok('preserved [structure]',$new->is_equal($h)); # ok=i+6
  isok('preserved [compiled]', $new->compiled eq $h->compiled); # ok=i+7

  # cleanup
  unlink(qw(tmp.gt tmp.bin));
}

# end of t/07_load.t

