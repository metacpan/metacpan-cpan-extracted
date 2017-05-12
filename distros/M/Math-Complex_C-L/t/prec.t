use warnings;
use strict;
use Math::Complex_C::L qw(:all);

print "1..2\n";

if(l_get_prec() != 20) {print "ok 1\n"}
else {
  warn "\nexpected other than 20, got ", l_get_prec(), "\n";
  print "not ok 1\n";
}

l_set_prec(20);

if(l_get_prec() == 20) {print "ok 2\n"}
else {
  warn "\nexpected 20, got ", l_get_prec(), "\n";
  print "not ok 2\n";
}

