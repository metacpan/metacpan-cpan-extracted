# -*- Mode: Perl -*-
# t/02_add.t - structural tests: add/move/remove

$TEST_DIR = './t';
#use lib qw(../blib/lib); $TEST_DIR = '.'; # for debugging

# load common subs
do "$TEST_DIR/common.plt";

plan(test => 7*scalar(@classes));

# test subclasses (7 subtests/class)
foreach (@classes) {
  $class = "Math::PartialOrder::$_";
  print "Test $class\n";
  eval "use $class;";
  isok('new',$h = $class->new);                     # ok=i+0
  isok('add [implicit]',$h->add('foo'));            # ok=i+1
  isok('add [explicit]',$h->add(qw(bar baz)));      # ok=i+2
  isok('add_parents',$h->add_parents(qw(foo bar))); # ok=i+3
  isok('move', $h->move(qw(baz foo)));              # ok=i+4
  isok('replace',$h->replace(qw(foo moo)));         # ok=i+5
  isok('remove',$h->remove('baz'));                 # ok=i+6
}

print "\n";
# end of t/02_add.t

