# -*- Mode: Perl -*-
# t/04_tinfo.t - structural tests: root(), size(), types(), leaves()


$TEST_DIR = './t';
#use lib qw(../blib/lib); $TEST_DIR = '.'; # for debugging

# load common subs
do "$TEST_DIR/common.plt";

plan(test => 9*scalar(@classes));


# load and test sub-packages (9 subtests)
foreach (@classes) {
  $class = "Math::PartialOrder::$_";
  print "\nTest $class\n";
  $h = testhi($class);

  isok('has_types',$h->has_types(qw(a b c)));    # ok=i+0
  isok('has_parent',$h->has_parent(qw(a root)));  # ok=i+1
  isok('has_child',$h->has_child(qw(root a)));   # ok=i+2
  isok('has_ancestor',$h->has_ancestor(qw(c a)));   # ok=i+3
  isok('has_descendant',$h->has_descendant(qw(b c))); # ok=i+4

  ulistok('parents',[$h->parents('c')],[qw(aaa bb)]);    # ok=i+6
  ulistok('children',[$h->children('a')],[qw(aa1 aa2)]); # ok=i+5
  ulistok('ancestors',[$h->ancestors('c')], [qw(aaa aa2 a bb b root)]); # ok=i+7
  ulistok('descendants',[$h->descendants('b')], [qw(bb c)]);            # ok=i+8
}

# end of t/04_tinfo.t

