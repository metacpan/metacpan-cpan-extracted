use strict;
use warnings;
use Math::LongDouble qw(:all);

print "1..12\n";

my $rop = Math::LongDouble->new();
my $ld_nan = Math::LongDouble->new();
my $native_nan = LDtoNV($ld_nan);

warn "\nMath:LongDouble::_nan_pow_bug() returns ", Math::LongDouble::_nan_pow_bug(), "\n";

if($ld_nan != $ld_nan) {print "ok 1\n"}
else {
  warn "\nExpected a NaN\nGot $ld_nan\n";
  print "not ok 1\n";
}

if($native_nan != $native_nan) {print "ok 2\n"}
else {
  warn "\nExpected a NaN\nGot $native_nan\n";
  print "not ok 2\n";
}

pow_LD($rop, $ld_nan, Math::LongDouble->new(0));

if($rop == 1) {print "ok 3\n"}
else {
  warn "\nExpected 1\nGot $ld_nan ** ", Math::LongDouble->new(0), " is $rop\n";
  print "not ok 3\n";
}

# IV overloading

my $check = $ld_nan ** 0;
if($check == 1) {print "ok 4\n"}
else {
  warn "\nExpected 1\nGot $ld_nan ** 0 is $check\n";
  print "not ok 4\n";
}

# NV overloading

$check = $ld_nan ** 0.0;
if($check == 1) {print "ok 5\n"}
else {
  warn "\nExpected 1\nGot $ld_nan ** 0.0 is $check\n";
  print "not ok 5\n";
}

$check = $native_nan ** Math::LongDouble->new(0);
if($check == 1) {print "ok 6\n"}
else {
  warn "\nExpected 1\nGot $native_nan ** ", Math::LongDouble->new(0), " is $check\n";
  print "not ok 6\n";
}

# PV overloading

$check = $ld_nan ** '0';
if($check == 1) {print "ok 7\n"}
else {
  warn "\nExpected 1\nGot $ld_nan ** '0' is $check\n";
  print "not ok 7\n";
}

# OBJ overloading

$check = $ld_nan ** Math::LongDouble->new(0);
if($check == 1) {print "ok 8\n"}
else {
  warn "\nExpected 1\nGot $ld_nan ** ", Math::LongDouble->new(0), " is $check\n";
  warn "Math::LongDouble->new(0) is not zero\n" unless is_ZeroLD(Math::LongDouble->new(0));
  print "not ok 8\n";
}

# IV= overloading

$check = $ld_nan;
$check **= 0;
if($check == 1) {print "ok 9\n"}
else {
  warn "\nExpected 1\nGot $check\n";
  print "not ok 9\n";
}

# NV= overloading

$check = $ld_nan;
$check **= 0.0;
if($check == 1) {print "ok 10\n"}
else {
  warn "\nExpected 1\nGot $check\n";
  print "not ok 10\n";
}

# PV= overloading

$check = $ld_nan;
$check **= '0';
if($check == 1) {print "ok 11\n"}
else {
  warn "\nExpected 1\nGot $check\n";
  print "not ok 11\n";
}

# OBJ= overloading

$check = $ld_nan;
$check **= Math::LongDouble->new(0);
if($check == 1) {print "ok 12\n"}
else {
  warn "\nExpected 1\nGot $check\n";
  warn "Math::LongDouble->new(0) is not zero\n" unless is_ZeroLD(Math::LongDouble->new(0));
  print "not ok 12\n";
}
