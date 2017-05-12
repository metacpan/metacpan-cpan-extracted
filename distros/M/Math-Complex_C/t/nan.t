use strict;
use warnings;
use Math::Complex_C qw(:all);

print "1..3\n";

my $nan1 = MCD();
my $nan2 = Math::Complex_C->new();

if("$nan1" eq "$nan2" && $nan1 != $nan2) {print "ok 1\n"}
else {
  warn "\n$nan1 and $nan2 are not behaving like nans\n";
  print "not ok 1\n";
}

assign_c($nan1, get_nan(), 0);

if($nan1 != $nan2) {print "ok 2\n"}
else {
  warn "\n$nan1 and $nan2 are not behaving like nans\n";
  print "not ok 2\n";
}

assign_c($nan1, 0, get_nan());

if($nan1 != $nan2) {print "ok 3\n"}
else {
  warn "\n$nan1 and $nan2 are not behaving like nans\n";
  print "not ok 3\n";
}



