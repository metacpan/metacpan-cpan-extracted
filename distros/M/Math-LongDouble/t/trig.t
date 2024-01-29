use warnings;
use strict;
use Math::LongDouble qw(:all);
use Math::Trig;
use Config;

print "1..20\n";

warn "\n", Math::LongDouble::_sincosl_status(), "\n";

my $r = 2.0;
my $r2 = 1.5;
my $ldr = Math::LongDouble->new(2.0);
my $ldr2 = Math::LongDouble->new(1.5);

my $sin_r = sin($r);
my $cos_r = cos($r);
my $atan2_r = atan2($r, $r2);

my $sin_ldr = sin($ldr);
my $cos_ldr = cos($ldr);
my $atan2_ldr = atan2($ldr, $ldr2);

if(approx($sin_ldr, $sin_r) && test_cmp($sin_ldr, $sin_r)) {print "ok 1\n"}
else {
  warn "\n\$sin_ldr: $sin_ldr\n\$sin_r: $sin_r\n";
  print "not ok 1\n";
}

if(approx($cos_ldr, $cos_r) && test_cmp($cos_ldr, $cos_r)) {print "ok 2\n"}
else {
  warn "\n\$cos_ldr: $cos_ldr\n\$cos_r: $cos_r\n";
  print "not ok 2\n";
}

if(approx($atan2_ldr, $atan2_r) && test_cmp($atan2_ldr, $atan2_r)) {print "ok 3\n"}
else {
  warn "\n\$atan2_ldr: $atan2_ldr\n\$atan2_r: $atan2_r\n";
  print "not ok 3\n";
}

if($atan2_ldr == atan2("2.0", $ldr2)) {print "ok 4\n"}
else {
  warn "\nExpected $atan2_ldr\nGot ", atan2("2.0", $ldr2), "\n";
  print "not ok 4\n";
}

if($atan2_ldr == atan2(2, $ldr2)) {print "ok 5\n"}
else {
  warn "\nExpected $atan2_ldr\nGot ", atan2("2", $ldr2), "\n";
  print "not ok 5\n";
}

if($atan2_ldr == atan2($ldr, 1.5)) {print "ok 6\n"}
else {
  warn "\nExpected $atan2_ldr\nGot ", atan2($ldr, 1.5), "\n";
  print "not ok 6\n";
}

# COW shit breaks these tests if we assign $check2 and $check3
# as copies of $check1 using overload sub for '=' operator.
my $check1 = Math::LongDouble->new();
my $check2 = Math::LongDouble->new();
my $check3 = Math::LongDouble->new();

sincos_LD($check1, $check2, $ldr);
#print "$check1 $check2\n";
sin_LD($check3, $ldr);

if($check1 == $check3) {print "ok 7\n"}
else {
  warn "\nExpected$check3\nGot $check1\n";
  print "not ok 7\n";
}

cos_LD($check3, $ldr);

if($check2 == $check3) {print "ok 8\n"}
else {
  warn "\nExpected$check3\nGot $check2\n";
  print "not ok 8\n";
}

if(approx(($check1 ** 2) + ($check2 ** 2), 1)) {print "ok 9\n"}
else {
  warn "\nExpected approx 1\nGot ", ($check1 ** 2) + ($check2 ** 2), "\n";
  print "not ok 9\n";
}

sinh_LD($check1, $ldr);
cosh_LD($check2, $ldr);

if(approx(($check2 ** 2) - ($check1 ** 2), 1)) {print "ok 10\n"}
else {
  warn "\nExpected approx 1\nGot ", ($check2 ** 2) - ($check1 ** 2), "\n";
  print "not ok 10\n";
}

sin_LD($check1, $ldr);
cos_LD($check2, $ldr);
tan_LD($check3, $ldr);

if(approx($check3, $check1 / $check2)) {print "ok 11\n"}
else {
  warn "\nExpected approx ", $check1 / $check2, "\nGot $check3\n";
  print "not ok 11\n";
}

tanh_LD($check1, $ldr);
tanh_LD($check2, $ldr * -1);

if(approx($check1, $check2 * -1)) {print "ok 12\n"}
else {
  warn "\nExpected ", -$check2, "\nGot $check1\n";
  print "not ok 12\n";
}

# $atan2_ldr == atan2($ldr, 1.5)

atan2_LD($check1, $ldr, $ldr2);

if($check1 == $atan2_ldr) {print "ok 13\n"}
else {
  warn "\nExpected $atan2_ldr\nGot $check1\n";
  print "not ok 13\n";
}

atan_LD($check1, Math::LongDouble->new(0.6));
if(approx($check1, atan(0.6))) {print "ok 14\n"}
else {
  warn "\nExpected atan(0.6)\nGot $check1\n";
  print "not ok 14\n";
}

atanh_LD($check1, Math::LongDouble->new(0.6));
if(approx($check1, atanh(0.6))) {print "ok 15\n"}
else {
  warn "\nExpected atan(0.6)\nGot $check1\n";
  print "not ok 15\n";
}

acos_LD($check1, Math::LongDouble->new(0.6));
if(approx($check1, acos(0.6))) {print "ok 16\n"}
else {
  warn "\nExpected acos(0.6)\nGot $check1\n";
  print "not ok 16\n";
}

acosh_LD($check1, Math::LongDouble->new(1.6));
if(approx($check1, acosh(1.6))) {print "ok 17\n"}
else {
  warn "\nExpected acosh(1.6)\nGot $check1\n";
  print "not ok 17\n";
}

asin_LD($check1, Math::LongDouble->new(0.6));
if(approx($check1, asin(0.6))) {print "ok 18\n"}
else {
  warn "\nExpected asin(0.6)\nGot $check1\n";
  print "not ok 18\n";
}

asinh_LD($check1, Math::LongDouble->new(0.6));
if(approx($check1, asinh(0.6))) {print "ok 19\n"}
else {
  warn "\nExpected asinh(0.6)\nGot $check1\n";
  print "not ok 19\n";
}

hypot_LD($check1, Math::LongDouble->new('4.0'), Math::LongDouble->new('3.0'));
if($check1 == Math::LongDouble->new('5.0')) {print "ok 20\n"}
else {
  warn "\nExpected 5.0\nGot $check1\n";
  print "not ok 20\n";
}


sub approx {
    my $eps = abs($_[0] - Math::LongDouble->new($_[1]));
    return 0 if  $eps > Math::LongDouble->new(0.000000001);
    return 1;
}

sub test_cmp {
  if(Math::LongDouble::_get_actual_ldblsize() != Math::LongDouble::_get_actual_nvsize()) {
    return cmp_NV($_[0], $_[1]);
  }
  else {
    return 0 if cmp_NV($_[0], $_[1]);
    return 1;
  }
}
