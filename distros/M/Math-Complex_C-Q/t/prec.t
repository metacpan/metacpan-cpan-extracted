use warnings;
use strict;
use Math::Complex_C::Q qw(:all);

print "1..2\n";

if(q_get_prec() == 36) {print "ok 1\n"}
else {
  warn "\nexpected 36, got ", q_get_prec(), "\n";
  print "not ok 1\n";
}

q_set_prec(20);

if(q_get_prec() == 20) {print "ok 2\n"}
else {
  warn "\nexpected 20, got ", q_get_prec(), "\n";
  print "not ok 2\n";
}

