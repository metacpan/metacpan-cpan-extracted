# -*- Mode: Perl -*-
# t/03_hinfo.t - structural tests: root(), size(), types(), leaves()

$TEST_DIR = './t';
#use lib qw(../blib/lib); $TEST_DIR = '.'; # for debugging

# load common subs
do "$TEST_DIR/common.plt";

plan(test => 10*scalar(@classes));

# $h = hinit($class) : initialize a test hierarchy (treelike)
sub hinit {
  my $class = shift;
  eval "use $class;";
  my $h = $class->new({root => 'myroot'});
  foreach (qw(a b c)) { $h->add($_, 'myroot'); }
  return $h;
}

# $h = chinit($class) : initialize a circular hierarchy
sub chinit {
  my $class = shift;
  my $h = $class->new;
  $h->add('a');
  $h->add(qw(b a));
  $h->add(qw(c b));
  $h->add_parents(qw(a c));
  return $h;
}

# $h = ndinit($class) : initialize non-deterministic (non-CCPO) hierarchy
sub ndinit {
  my $class = shift;
  my $h = $class->new;
  $h->add('a');
  $h->add('b');
  $h->add(qw(c a b));
  $h->add(qw(d a b));
  return $h;
}


# load & test subclasses (4 subtests)
foreach (@classes) {
  $class = "Math::PartialOrder::$_";
  print "\nTest $class\n";
  $h = hinit($class);

  # basic information
  isok('root()',$h->root,'myroot');                # ok=i+0
  isok('size',$h->size,4);                         # ok=i+1
  ulistok('types',[$h->types],[qw(a b c myroot)]); # ok=i+2
  ulistok('leaves',[$h->leaves],[qw(a b c)]);       # ok=i+3

  # circularity
  $ch = chinit($class);
  isok('is_circular [yes]', $ch->is_circular); # ok=i+4
  isok('is_circular [no]',!$h->is_circular);   # ok=i+5

  # multiple inheritance?
  $nd = ndinit($class);
  isok('is_treelike [yes]', $h->is_treelike); # ok=i+6
  isok('is_treelike [no]', !$nd->is_treelike); # ok=i+7

  # non-determinism?
  isok('is_deterministic [yes]', $h->is_deterministic); # ok=i+8
  isok('is_deterministic [no]', !$nd->is_deterministic); # ok=i+9
}

# end of t/03_hinfo.t

