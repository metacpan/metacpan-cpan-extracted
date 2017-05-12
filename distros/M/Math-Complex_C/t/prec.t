use warnings;
use strict;
use Math::Complex_C qw(:all);

print "1..2\n";

if(d_get_prec() == 17) {print "ok 1\n"}
else {
  warn "\nexpected 17, got ", d_get_prec(), "\n";
  print "not ok 1\n";
}

d_set_prec(20);

if(d_get_prec() == 20) {print "ok 2\n"}
else {
  warn "\nexpected 20, got ", d_get_prec(), "\n";
  print "not ok 2\n";
}

