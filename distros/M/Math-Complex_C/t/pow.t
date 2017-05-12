use warnings;
use strict;
use Math::Complex_C qw(:all);

my $op = MCD(5, 4.5);
my $pow = MCD(2, 2.5);
my $rop = MCD();

print "1..20\n";

my $eps = 1e-12;

pow_c($rop, $op, $pow);

if(approx(real_c($rop), 7.23403197989648, $eps)) {print "ok 1\n"}
else {
  warn "\nExpected approx 7.23403197989648\nGot ", real_c($rop), "\n";
  print "not ok 1\n";
}

if(approx(imag_c($rop), -0.37869801657204, $eps)) {print "ok 2\n"}
else {
  warn "\nExpected approx -0.37869801657204\nGot ", imag_c($rop), "\n";
  print "not ok 2\n";
}

sqrt_c($rop, $op);

if(approx(real_c($rop), 2.4214470904334102, $eps)) {print "ok 3\n"}
else {
  warn "\nExpected approx 2.4214470904334102\nGot ", real_c($rop), "\n";
  print "not ok 3\n";
}

if(approx(imag_c($rop), 0.929196433359722, $eps)) {print "ok 4\n"}
else {
  warn "\nExpected approx 0.929196433359722\nGot ", imag_c($rop), "\n";
  print "not ok 4\n";
}

##############################
##############################

$rop = $op ** $pow;

if(approx(real_c($rop), 7.2340319798964812, 0.00000000001)) {print "ok 5\n"}
else {
  warn "\nExpected approx 7.2340319798964812\nGot ", real_c($rop), "\n";
  print "not ok 5\n";
}

if(approx(imag_c($rop), -0.37869801657204, 0.00000000001)) {print "ok 6\n"}
else {
  warn "\nExpected approx -0.37869801657204\nGot ", imag_c($rop), "\n";
  print "not ok 6\n";
}

$rop = sqrt($op);

if(approx(real_c($rop), 2.4214470904334102, $eps)) {print "ok 7\n"}
else {
  warn "\nExpected approx 2.4214470904334102\nGot ", real_c($rop), "\n";
  print "not ok 7\n";
}

if(approx(imag_c($rop), 0.929196433359722, $eps)) {print "ok 8\n"}
else {
  warn "\nExpected approx 0.929196433359722\nGot ", imag_c($rop), "\n";
  print "not ok 8\n";
}

##############################
##############################

$rop = $op ** 3;

if(approx(real_c($rop), -178.75, $eps)) {print "ok 9\n"}
else {
  warn "\nExpected approx -178.75\nGot ", real_c($rop), "\n";
  print "not ok 9\n";
}

if(approx(imag_c($rop), 246.375, $eps)) {print "ok 10\n"}
else {
  warn "\nExpected approx 246.375\nGot ", imag_c($rop), "\n";
  print "not ok 10\n";
}

##############################
##############################

$rop = $op ** -3;

if(approx(real_c($rop), -0.00192925795578593, $eps)) {print "ok 11\n"}
else {
  warn "\nExpected approx -0.00192925795578593\nGot ", real_c($rop), "\n";
  print "not ok 11\n";
}

if(approx(imag_c($rop), -0.00265913806353431, $eps)) {print "ok 12\n"}
else {
  warn "\nExpected approx -0.00265913806353431\nGot ", imag_c($rop), "\n";
  print "not ok 12\n";
}


##############################
##############################

$rop = $op ** -2.75;

if(approx(real_c($rop), -0.00227483300435652, $eps)) {print "ok 13\n"}
else {
  warn "\nExpected approx -0.00227483300435652\nGot ", real_c($rop), "\n";
  print "not ok 13\n";
}

if(approx(imag_c($rop), -0.00477682943207756, $eps)) {print "ok 14\n"}
else {
  warn "\nExpected approx -0.00477682943207756\nGot ", imag_c($rop), "\n";
  print "not ok 14\n";
}

##############################
##############################

my $op1 = $op;
my $op2 = $op;
my $op3 = $op;

##############################
##############################

$op1 **= 3;

if(approx(real_c($op1), -178.75, $eps)) {print "ok 15\n"}
else {
  warn "\nExpected approx -178.75\nGot ", real_c($rop), "\n";
  print "not ok 15\n";
}

if(approx(imag_c($op1), 246.375, $eps)) {print "ok 16\n"}
else {
  warn "\nExpected approx 246.375\nGot ", imag_c($rop), "\n";
  print "not ok 16\n";
}

##############################
##############################

$op2 **= -3;

if(approx(real_c($op2), -0.00192925795578593, $eps)) {print "ok 17\n"}
else {
  warn "\nExpected approx -0.00192925795578593\nGot ", real_c($rop), "\n";
  print "not ok 17\n";
}

if(approx(imag_c($op2), -0.00265913806353431, $eps)) {print "ok 18\n"}
else {
  warn "\nExpected approx -0.00265913806353431\nGot ", imag_c($rop), "\n";
  print "not ok 18\n";
}

##############################
##############################

$op3 **= -2.75;

if(approx(real_c($op3), -0.00227483300435652, $eps)) {print "ok 19\n"}
else {
  warn "\nExpected approx -0.00227483300435652\nGot ", real_c($rop), "\n";
  print "not ok 19\n";
}

if(approx(imag_c($op3), -0.00477682943207756, $eps)) {print "ok 20\n"}
else {
  warn "\nExpected approx -0.00477682943207756\nGot ", imag_c($rop), "\n";
  print "not ok 20\n";
}

##############################
##############################

sub approx {
    if(($_[0] > ($_[1] - $_[2])) && ($_[0] < ($_[1] + $_[2]))) {return 1}
    return 0;
}


