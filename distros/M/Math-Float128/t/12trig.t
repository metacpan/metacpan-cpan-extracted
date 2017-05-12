use warnings;
use strict;
use Math::Float128 qw(:all);
use Math::Trig;
use Config;

print "1..21\n";

my $r = 2.0;
my $r2 = 1.5;
my $ldr = Math::Float128->new(2.0);
my $ldr2 = Math::Float128->new(1.5);
my $check = Math::Float128->new();
my $check1 = Math::Float128->new();

my $sin_r = sin($r);
my $cos_r = cos($r);
my $atan2_r = atan2($r, $r2);

my $sin_ldr = sin($ldr);
my $cos_ldr = cos($ldr);
my $atan2_ldr = atan2($ldr, $ldr2);

sin_F128($check, $ldr);
if($check == $sin_ldr) {print "ok 1\n"}
else {
  warn "\nExpected $sin_ldr\nGot $check\n";
  print "not ok 1\n";
}

if(approx($sin_ldr, $sin_r) && test_cmp($sin_ldr, $sin_r) && $Config{nvtype} ne '__float128') {
  print "ok 2\n";
}
elsif(approx($sin_ldr, $sin_r) && !test_cmp($sin_ldr, $sin_r) && $Config{nvtype} eq '__float128') {
  print "ok 2\n";
}
else {
  warn "\n\$sin_ldr: $sin_ldr\n\$sin_r: $sin_r\n";
  print "not ok 2\n";
}

cos_F128($check, $ldr);
if($check == $cos_ldr) {print "ok 3\n"}
else {
  warn "\nExpected $cos_ldr\nGot $check\n";
  print "not ok 3\n";
}

sincos_F128($check, $check1, $ldr);
if($check1 == $cos_ldr) {print "ok 4\n"}
else {
  warn "\nExpected $cos_ldr\nGot $check1\n";
  print "not ok 4\n";
}

if($check == $sin_ldr) {print "ok 5\n"}
else {
  warn "\nExpected $sin_ldr\nGot $check\n";
  print "not ok 5\n";
}

if(approx($cos_ldr, $cos_r) && test_cmp($cos_ldr, $cos_r) && $Config{nvtype} ne '__float128') {
  print "ok 6\n";
}
elsif(approx($cos_ldr, $cos_r) && !test_cmp($cos_ldr, $cos_r) && $Config{nvtype} eq '__float128') {
  print "ok 6\n";
}
else {
  warn "\n\$cos_ldr: $cos_ldr\n\$cos_r: $cos_r\n";
  print "not ok 6\n";
}

atan2_F128($check, $ldr, $ldr2);

if($check == $atan2_ldr) {print "ok 7\n"}
else {
  warn "\nExpected $atan2_ldr\nGot $check\n";
  print "not ok 7\n";
}

if(approx($atan2_ldr, $atan2_r) && test_cmp($atan2_ldr, $atan2_r) && $Config{nvtype} ne '__float128') {
  print "ok 8\n";
}
elsif(approx($atan2_ldr, $atan2_r) && !test_cmp($atan2_ldr, $atan2_r) && $Config{nvtype} eq '__float128') {
  print "ok 8\n";
}
else {
  warn "\n\$atan2_ldr: $atan2_ldr\n\$atan2_r: $atan2_r\n";
  print "not ok 8\n";
}

acos_F128($check, Math::Float128->new(0.6));
if(approx($check, acos(0.6))) {print "ok 9\n"}
else {
  warn "\nExpected acos(0.6)\nGot $check\n";
  print "not ok 9\n";
}

acosh_F128($check, Math::Float128->new(1.6));
if(approx($check, acosh(1.6))) {print "ok 10\n"}
else {
  warn "\nExpected acosh(1.6)\nGot $check\n";
  print "not ok 10\n";
}

asin_F128($check, Math::Float128->new(0.6));
if(approx($check, asin(0.6))) {print "ok 11\n"}
else {
  warn "\nExpected asin(0.6)\nGot $check\n";
  print "not ok 11\n";
}

asinh_F128($check, Math::Float128->new(1.6));
if(approx($check, asinh(1.6))) {print "ok 12\n"}
else {
  warn "\nExpected asinh(1.6)\nGot $check\n";
  print "not ok 12\n";
}

atan_F128($check, Math::Float128->new(0.6));
if(approx($check, atan(0.6))) {print "ok 13\n"}
else {
  warn "\nExpected atan(0.6)\nGot $check\n";
  print "not ok 13\n";
}

atanh_F128($check, Math::Float128->new(0.6));
if(approx($check, atanh(0.6))) {print "ok 14\n"}
else {
  warn "\nExpected atanh(0.6)\nGot $check\n";
  print "not ok 14\n";
}

sinh_F128($check, Math::Float128->new(1.6));
if(approx($check, sinh(1.6))) {print "ok 15\n"}
else {
  warn "\nExpected sinh(1.6)\nGot $check\n";
  print "not ok 15\n";
}

cosh_F128($check, Math::Float128->new(1.6));
if(approx($check, cosh(1.6))) {print "ok 16\n"}
else {
  warn "\nExpected cosh(1.6)\nGot $check\n";
  print "not ok 16\n";
}

tan_F128($check, Math::Float128->new(0.6));
if(approx($check, tan(0.6))) {print "ok 17\n"}
else {
  warn "\nExpected tan(0.6)\nGot $check\n";
  print "not ok 17\n";
}

tanh_F128($check, Math::Float128->new(0.6));
if(approx($check, tanh(0.6))) {print "ok 18\n"}
else {
  warn "\nExpected tanh(0.6)\nGot $check\n";
  print "not ok 18\n";
}

hypot_F128($check, Math::Float128->new('4.0'), Math::Float128->new('3.0'));
if($check == Math::Float128->new('5.0')) {print "ok 19\n"}
else {
  warn "\nExpected 5.0\nGot $check\n";
  print "not ok 19\n";
}

my $atan2_check1 = atan2(IVtoF128(2), 1.5);
my $atan2_check2 = atan2("2.0", NVtoF128(1.5));
my $atan2_check3 = atan2(NVtoF128(2.0), NVtoF128(1.5));

if($atan2_check1 == $atan2_check2) {print "ok 20\n"}
else {
  warn "$atan2_check1 != $atan2_check2\n";
  print "not ok 20\n";
}

if($atan2_check1 == $atan2_check3) {print "ok 21\n"}
else {
  warn "$atan2_check1 != $atan2_check3\n";
  print "not ok 21\n";
}

sub approx {
    my $eps = abs($_[0] - Math::Float128->new($_[1]));
    return 0 if  $eps > Math::Float128->new(0.000000001);
    return 1;
}

sub test_cmp {
  return cmp2NV($_[0], $_[1]);
}
