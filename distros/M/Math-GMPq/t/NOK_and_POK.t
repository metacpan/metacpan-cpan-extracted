use strict;
use warnings;
use Math::GMPq;

print "1..1\n";

my $n = '98765' x 80;
my $r = '98765' x 80;
my $z;

if($n > 0) { # sets NV slot to inf, and turns on the NOK flag
  $z = Math::GMPq->new($n); # dies if the  value in the NV slot (inf) is used
}

if($z == $r) {print "ok 1\n"}
else {
  warn "$z != $r\n";
  print "not ok 1\n";
}

