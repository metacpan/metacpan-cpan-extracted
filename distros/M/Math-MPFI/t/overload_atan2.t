use Math::MPFI qw(:mpfi);
use Math::MPFR qw(:mpfr);
use warnings;
use strict;

print "1..7\n";

my $c1 = atan2(1.4, 1.3);
my $c2 = atan2(1.3, 1.4);
my $c3 = atan2(-2, 1.3);
my $c4 = atan2(1.3, -2);
my $c5 = atan2(100001, ~0);
my $c6 = atan2(~0, 100001);

my $mpfi1 = Math::MPFI->new(1.3);
my $mpfi2 = Math::MPFI->new(1.4);
my $mpfi3 = Math::MPFI->new(2);
my $mpfi4 = Math::MPFI->new(100001);

my $i1 = atan2($mpfi1, $mpfi2);

if($i1 == $c2) {print "ok 1\n"}
else {
  warn "\$i1: $i1\n\$c2: $c2\n";
  print "not ok 1\n";
}

my $i2 = atan2($mpfi1, "1.4");

if($i2 == $c2) {print "ok 2\n"}
else {
  warn "\$i2: $i2\n\$c2: $c2\n";
  print "not ok 2\n";
}

my $i3 = atan2("1.3", $mpfi2);

if($i3 == $c2) {print "ok 3\n"}
else {
  warn "\$i3: $i3\n\$c2: $c2\n";
  print "not ok 3\n";
}

my $i4 = atan2($mpfi4, ~0);

if($i4 == $c5) {print "ok 4\n"}
else {
  warn "\$i4: $i4\n\$c5: $c5\n";
  print "not ok 4\n";
}

my $i5 = atan2(~0, $mpfi4);

if($i5 == $c6) {print "ok 5\n"}
else {
  warn "\$i5: $i5\n\$c6: $c6\n";
  print "not ok 5\n";
}

my $i6 = atan2($mpfi1, -2);

if($i6 == $c4) {print "ok 6\n"}
else {
  warn "\$i6: $i6\n\$c4: $c4\n";
  print "not ok 6\n";
}

my $i7 = atan2(-2, $mpfi1);

if($i7 == $c3) {print "ok 7\n"}
else {
  warn "\$i7: $i7\n\$c3: $c3\n";
  print "not ok 7\n";
}
