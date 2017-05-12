use Devel::GC::Helper;
print "1..2\n";

use strict;
use Scalar::Util qw(weaken);
my $check;
{

  my $blah = {};
  my $foo = "bar";
  $blah->{bar} = \$foo;
  $blah->{foo} = \$blah;
  $check = \$blah;
  weaken($check);
}

if ($check) {
  print "ok 1 - did leak ($check)\n";
} else {
  print "not ok 1 - did not leak ($check)\n";
}


my $leaks = Devel::GC::Helper::sweep;

my $found_it = 0;
foreach my $leak (@$leaks) {
  if ($check == $leak) {
    $found_it++;
  }
}
if ($found_it == 1) {
  print "ok 2 - found the leak\n";
} else {
  print "not ok 2 - did not find the leak ($found_it)\n";
}


1;
