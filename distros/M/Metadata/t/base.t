# Change 1..1 below to 1..last_test_to_print .

BEGIN { $| = 1; print "1..14\n"; }
END {print "not ok 1\n" unless $loaded;}
$loaded = 1;
print "ok 1\n";

$testnum=2;

use Metadata::Base;

{
my $a=new Metadata::Base;

$a->add("a", "b");
$a->add("a", "c");

my(@c)=$a->get("a");

warn "\@c is ",scalar(@c)," in size,\n" if $TEST_VERBOSE;
warn "contents are @c\n" if $TEST_VERBOSE;

# Test that the list is as expected
if (@c==2 && $c[0] eq 'b' && $c[1] eq 'c') {
  print "ok $testnum\n";
} else {
  print "notok $testnum\n";
  warn "\@c is ($c[0],$c[1]) but expected (b,c)\n";
}
$testnum++;

# Test get array as 1 string with a get in scalar context
my $d=$a->get("a");
if ($d eq 'b c') {
  print "ok $testnum\n";
} else {
  print "notok $testnum\n";
  warn "\$d is $d but expected 'b c'\n";
}
$testnum++;

# Test get undef on missing element
my $e=$a->get("c");
if (!defined $e) {
  print "ok $testnum\n";
} else {
  print "notok $testnum\n";
  warn "\$e is $e but expected it to be undef\n";
}
$testnum++;

}

sub compare_lists (\@\@) {
  my($aref1, $aref2)=@_;
  return 0 if scalar(@$aref1) != scalar(@$aref2);

  for (0..scalar(@$aref1)-1) {
    return 1 if $aref1->[$_] ne $aref2->[$_];
  }
  return 0;
}


{
  $i=new Metadata::Base {ORDERED => 1};
  # Also works:
  # $i=new Metadata::IAFA;

  $i->set('family', 'simpsons');
  $i->set('father', 'homer');
  $i->set('child', 'bart'); $i->add('child', 'lisa');
  $i->set('mother', 'marge');
  $i->set('cousin', 'dilbert'); $i->add('cousin', 'dogbert');
  
  my(@expected_order)=qw(family father child mother cousin);

  # Test order to get it
  my(@e)=$i->order;
  if (!compare_lists(@e, @expected_order)) {
    print "ok $testnum\n";
  } else {
    print "notok $testnum\n";
    warn "Order of \@e is @e but expected it to be @expected_order\n";
  }
  $testnum++;


  # Test using order to set it
  my(@new_order)=qw(mother father child family cousin);
  $i->order(@new_order);
  my(@f)=$i->order;
  if (!compare_lists(@f, @new_order)) {
    print "ok $testnum\n";
  } else {
    print "notok $testnum\n";
    warn "Order of \@f is @f but expected it to be @new_order\n";
  }
  $testnum++;

  # Test exists on an element
  if ($i->exists('mother')) {
    print "ok $testnum\n";
  } else {
    print "notok $testnum\n";
    warn "Element mother did not exist, but it does!\n";
  }
  $testnum++;

  # Test exists on an element subvalue
  if ($i->exists('child', 0)) {
    print "ok $testnum\n";
  } else {
    print "notok $testnum\n";
    warn "Subvalue child 0 did not exist, but it does!\n";
  }
  $testnum++;

  # Test delete on array element I
  my(@old)=$i->delete('cousin');
  my(@expected_old)=qw(dilbert dogbert);
  if(!compare_lists(@old, @expected_old)) {
    print "ok $testnum\n";
  } else {
    print "notok $testnum\n";
    warn "Delete of 'cousin' returned elements: @old, expected :@expected_old\n";
  }
  $testnum++;

  # Test delete on array element II
  my(@new_order2)=qw(mother father child family);

  my(@g)=$i->order;
  if (!compare_lists(@g, @new_order2)) {
    print "ok $testnum\n";
  } else {
    print "notok $testnum\n";
    warn "Delete of 'cousin' left elements in order: @new_order2, expected: @g\n";
  }
  $testnum++;

  # Test size
  if (my $value=$i->size==4) {
    print "ok $testnum\n";
  } else {
    print "notok $testnum\n";
    warn "Size of elements returned $value, expected 4\n";
  }
  $testnum++;

  # Test size on a element
  if (my $value=$i->size('child')==2) {
    print "ok $testnum\n";
  } else {
    print "notok $testnum\n";
    warn "Size on element child returned $value, expected 2\n";
  }
  $testnum++;

  # Test delete on a single element I
  my(@old2)=$i->delete('mother');
  my(@expected_old2)=qw(marge);
  if(!compare_lists(@old2, @expected_old2)) {
    print "ok $testnum\n";
  } else {
    print "notok $testnum\n";
    warn "Delete of 'mother' returned elements: @old2, expected :@expected_old2\n";
  }
  $testnum++;

  # Test delete on a single element II
  my(@new_order3)=qw(father child family);

  my(@h)=$i->order;
  if (!compare_lists(@h, @new_order3)) {
    print "ok $testnum\n";
  } else {
    print "notok $testnum\n";
    warn "Delete of 'mother' left elements in order: @new_order3, expected: @h\n";
  }
  $testnum++;


}

