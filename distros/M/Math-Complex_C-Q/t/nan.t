use strict;
use warnings;
use Math::Complex_C::Q qw(:all);

print "1..4\n";

my $nan1 = MCQ();
my $nan2 = Math::Complex_C::Q->new();

if("$nan1" eq "$nan2" && $nan1 != $nan2) {print "ok 1\n"}
else {
  warn "\n$nan1 and $nan2 are not behaving like nans\n";
  print "not ok 1\n";
}

assign_cq($nan1, get_nanq(), 0);

if($nan1 != $nan2) {print "ok 2\n"}
else {
  warn "\n$nan1 and $nan2 are not behaving like nans\n";
  print "not ok 2\n";
}

assign_cq($nan1, 0, get_nanq());

if($nan1 != $nan2) {print "ok 3\n"}
else {
  warn "\n$nan1 and $nan2 are not behaving like nans\n";
  print "not ok 3\n";
}

eval{require Math::Float128;};

my $nan3;

if(!$@) {$nan3 = MCQ(Math::Float128->new(), Math::Float128->new())}
else { $nan3 = MCQ() }

if("$nan3" eq "$nan2" && $nan3 != $nan2) {print "ok 4\n"}
else {
  warn "\n$nan1 and $nan2 are not behaving like nans\n";
  print "not ok 4\n";
}

