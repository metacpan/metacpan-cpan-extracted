use warnings;
use strict;
use Math::LongDouble qw(:all);

print "1..32\n";

my $ld = NVtoLD(2.5);
my $ld_copy = $ld;

$ld++;

if($ld == NVtoLD(3.5)) {print "ok 1\n"}
else {
  warn "\n\$ld: $ld\n";
  print "not ok 1\n";
}

$ld--;

if($ld == $ld_copy) {print "ok 2\n"}
else {
  warn "\n\$ld: $ld\n";
  print "not ok 2\n";
}

my $check = Math::LongDouble->new();

ceil_LD($check, $ld);

if($check == NVtoLD(3.0)) {print "ok 3\n"}
else {
  warn "\nExpected 3.0\nGot $check\n";
  print "not ok 3\n";
}

ceil_LD($check, -$ld);

if($check == NVtoLD(-2.0)) {print "ok 4\n"}
else {
  warn "\nExpected -2.0\nGot $check\n";
  print "not ok 4\n";
}

floor_LD($check, $ld);

if($check == NVtoLD(2.0)) {print "ok 5\n"}
else {
  warn "\nExpected 2.0\nGot $check\n";
  print "not ok 5\n";
}

floor_LD($check, -$ld);

if($check == NVtoLD(-3.0)) {print "ok 6\n"}
else {
  warn "\nExpected -3.0\nGot $check\n";
  print "not ok 6\n";
}

copysign_LD($check, NVtoLD(2.5), NVtoLD(-2.2));

if($check == NVtoLD(-2.5)) { print "ok 7\n"}
else {
  warn "\nExpected -2.5\nGot $check\n";
  print "not ok 7\n";
}

copysign_LD($check, NVtoLD(2.5), NVtoLD(2.2));

if($check == NVtoLD(2.5)) { print "ok 8\n"}
else {
  warn "\nExpected 2.5\nGot $check\n";
  print "not ok 8\n";
}

copysign_LD($check, NVtoLD(-2.5), NVtoLD(-2.2));

if($check == NVtoLD(-2.5)) { print "ok 9\n"}
else {
  warn "\nExpected -2.5\nGot $check\n";
  print "not ok 9\n";
}

copysign_LD($check, NVtoLD(-2.5), NVtoLD(2.2));

if($check == NVtoLD(2.5)) { print "ok 10\n"}
else {
  warn "\nExpected 2.5\nGot $check\n";
  print "not ok 10\n";
}

# The rint  functions round to nearest integer, tied to even for halfway cases.
# The round functions round to nearest integer, away from zero for halfway cases.

my $llok = Math::LongDouble::_longlong2iv_is_ok();
my  $lok = Math::LongDouble::_long2iv_is_ok();

if($lok) {

  my $lrint = lrint_LD($ld);
  if($lrint == 2) {print "ok 11\n"}
  else {
    warn "\nExpected 2\nGot $lrint\n";
    print "not ok 11\n";
  }

  $lrint = lrint_LD($ld + UnityLD(1));
  if($lrint == 4) {print "ok 12\n"}
  else {
    warn "\nExpected 4\nGot $lrint\n";
    print "not ok 12\n";
  }

  my $lround = lround_LD($ld);
  if($lround == 3) {print "ok 13\n"}
  else {
    warn "\nExpected 2\nGot $lround\n";
    print "not ok 13\n";
  }

  $lround = lround_LD($ld + UnityLD(1));
  if($lround == 4) {print "ok 14\n"}
  else {
    warn "\nExpected 4\nGot $lround\n";
    print "not ok 14\n";
  }

}
else {

  eval{my $lrint = lrint_LD($ld);};
  if($@ =~ /not implemented/) {print "ok 11\n"}
  else {print "not ok 11\n"}

  eval{my $lround = lround_LD($ld);};
  if($@ =~ /not implemented/) {print "ok 12\n"}
  else {print "not ok 12\n"}

  warn "\nSkipping tests 13-14: lrint_LD() and lround_LD() not implemented\n";
  for(13..14) {print "ok $_\n"}

}

if($llok) {

  my $llrint = llrint_LD($ld);
  if($llrint == 2) {print "ok 15\n"}
  else {
    warn "\nExpected 2\nGot $llrint\n";
    print "not ok 15\n";
  }

  $llrint = llrint_LD($ld + UnityLD(1));
  if($llrint == 4) {print "ok 16\n"}
  else {
    warn "\nExpected 4\nGot $llrint\n";
    print "not ok 16\n";
  }

  my $llround = llround_LD($ld);
  if($llround == 3) {print "ok 17\n"}
  else {
    warn "\nExpected 2\nGot $llround\n";
    print "not ok 17\n";
  }

  $llround = llround_LD($ld + UnityLD(1));
  if($llround == 4) {print "ok 18\n"}
  else {
    warn "\nExpected 4\nGot $llround\n";
    print "not ok 18\n";
  }

}
else {

  eval{my $llrint = llrint_LD($ld);};
  if($@ =~ /Use lrint_LD instead/) {print "ok 15\n"}
  else {print "not ok 15\n"}

  eval{my $llround = llround_LD($ld);};
  if($@ =~ /Use lround_LD instead/) {print "ok 16\n"}
  else {print "not ok 16\n"}

  warn "\nSkipping tests 17-18: llrint_LD() and llround_LD() not implemented\n";
  for(17..18) {print "ok $_\n"}

}

rint_LD($check, $ld);
if($check == NVtoLD(2)) {print "ok 19\n"}
else {
  warn "\nExpected 2\nGot $check\n";
  print "not ok 19\n";
}

rint_LD($check, $ld + UnityLD(1));
if($check == NVtoLD(4)) {print "ok 20\n"}
else {
  warn "\nExpected 4\nGot $check\n";
  print "not ok 20\n";
}

round_LD($check, $ld);
if($check == NVtoLD(3)) {print "ok 21\n"}
else {
  warn "\nExpected 2\nGot $check\n";
  print "not ok 21\n";
}

round_LD($check, $ld + UnityLD(1));
if($check == NVtoLD(4)) {print "ok 22\n"}
else {
  warn "\nExpected 4\nGot $check\n";
  print "not ok 22\n";
}

nearbyint_LD($check, $ld + UnityLD(1));

if($check ==  NVtoLD(4)) {print "ok 23\n"}
else {
  warn "\nExpected 4\nGot $check\n";
  print "not ok 23\n";
}

nearbyint_LD($check, $ld);

if($check ==  NVtoLD(2)) {print "ok 24\n"}
else {
  warn "\nExpected 4\nGot $check\n";
  print "not ok 24\n";
}

nextafter_LD($check, $ld, $ld + UnityLD(1));

if($check > $ld) {print "ok 25\n"}
else {
  warn "\nExpected a value greater than 2.5\nGot $check\n";
  print "not ok 25\n";
}

nextafter_LD($check, $ld, $ld - UnityLD(1));

if($check < $ld) {print "ok 26\n"}
else {
  warn "\nExpected a value less than 2.5\nGot $check\n";
  print "not ok 26\n";
}

my $check1 = Math::LongDouble->new();

modf_LD($check, $check1, $ld);

if($check == IVtoLD(2) && $check1 == NVtoLD(0.5)) {print "ok 27\n"}
else {
  warn "\nExpected integer value of 2\nGot $check\n",
         "Expected fractional value of 0.5\nGot $check1\n";
  print "not ok 27\n";
}

trunc_LD($check, STRtoLD("-543.11"));

if($check == IVtoLD(-543)) {print "ok 28\n"}
else {
  warn "\nExpected -543\nGot $check\n";
  print "not ok 28\n";
}

# Better do some more checking of nearbyint_LD for mingw-w64 compiler builds:

nearbyint_LD($check, NVtoLD(5.4));

if($check == NVtoLD(5)) {print "ok 29\n"}
else {
  warn "\nExpected 5\nGot $check\n";
  print "not ok 29\n";
}

nearbyint_LD($check, NVtoLD(-5.4));

if($check == NVtoLD(-5)) {print "ok 30\n"}
else {
  warn "\nExpected -5\nGot $check\n";
  print "not ok 30\n";
}

nearbyint_LD($check, NVtoLD(5.6));

if($check == NVtoLD(6)) {print "ok 31\n"}
else {
  warn "\nExpected 6\nGot $check\n";
  print "not ok 31\n";
}

nearbyint_LD($check, NVtoLD(-5.6));

if($check == NVtoLD(-6)) {print "ok 32\n"}
else {
  warn "\nExpected -6\nGot $check\n";
  print "not ok 32\n";
}
