use strict;
use warnings;
use Math::Complex_C::L qw(:all);

print "1..4\n";

my $nan1 = MCL();
my $nan2 = Math::Complex_C::L->new();

if("$nan1" eq "$nan2" && $nan1 != $nan2) {print "ok 1\n"}
else {
  warn "\n$nan1 and $nan2 are not behaving like nans\n";
  print "not ok 1\n";
}

assign_cl($nan1, get_nanl(), 0);

if($nan1 != $nan2) {print "ok 2\n"}
else {
  warn "\n$nan1 and $nan2 are not behaving like nans\n";
  print "not ok 2\n";
}

assign_cl($nan1, 0, get_nanl());

if($nan1 != $nan2) {print "ok 3\n"}
else {
  warn "\n$nan1 and $nan2 are not behaving like nans\n";
  print "not ok 3\n";
}

eval{require Math::LongDouble;};

my $nan3;

if(!$@) {$nan3 = MCL(Math::LongDouble->new(), Math::LongDouble->new())}
else { $nan3 = MCL() }

if("$nan3" eq "$nan2" && $nan3 != $nan2) {print "ok 4\n"}
else {
  warn "\n$nan1 and $nan2 are not behaving like nans\n";
  print "not ok 4\n";
}

