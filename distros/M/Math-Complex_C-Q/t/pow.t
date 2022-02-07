use warnings;
use strict;
use Math::Complex_C::Q qw(:all);

my $op = MCQ(5, 4.5);
my $pow = MCQ(2, 2.5);
my $rop = MCQ();

my $mingw_w64_pow_bug = 0;
$mingw_w64_pow_bug = 1 if Math::Complex_C::Q::_mingw_w64_bug();

if($mingw_w64_pow_bug) {
  print "1..20\n";
}
else {
  print "1..28\n";
}

my $eps = 1e-12;

if($mingw_w64_pow_bug) {
  eval{pow_cq($rop, $op, $pow);};
  if($@ =~ /pow_cq not implemented/) {
    print "ok 1\nok 2\n"
  }
  else {
    warn "\n\$\@: $@\n";
    print "not ok 1\n";
  }
}
else {
  pow_cq($rop, $op, $pow);

  if(approx(real_cq($rop), 7.23403197989648, $eps)) {print "ok 1\n"}
  else {
    warn "\nExpected approx 7.23403197989648\nGot ", real_cq($rop), "\n";
    print "not ok 1\n";
  }

  if(approx(imag_cq($rop), -0.37869801657204, $eps)) {print "ok 2\n"}
  else {
    warn "\nExpected approx -0.37869801657204\nGot ", imag_cq($rop), "\n";
    print "not ok 2\n";
  }
}

sqrt_cq($rop, $op);

if(approx(real_cq($rop), 2.4214470904334102, $eps)) {print "ok 3\n"}
else {
  warn "\nExpected approx 2.4214470904334102\nGot ", real_cq($rop), "\n";
  print "not ok 3\n";
}

if(approx(imag_cq($rop), 0.929196433359722, $eps)) {print "ok 4\n"}
else {
  warn "\nExpected approx 0.929196433359722\nGot ", imag_cq($rop), "\n";
  print "not ok 4\n";
}

##############################
##############################

if($mingw_w64_pow_bug) {
  eval{$rop = $op ** $pow;};
  if($@ =~ /\*\* \(pow\) not overloaded/) {print "ok 5\nok 6\n"}
  else {
    warn "\n\$\@: $@\n";
    print "not ok 5\n";
  }
}
else {
  $rop = $op ** $pow;

  if(approx(real_cq($rop), 7.2340319798964812, 0.00000000001)) {print "ok 5\n"}
  else {
    warn "\nExpected approx 7.2340319798964812\nGot ", real_cq($rop), "\n";
    print "not ok 5\n";
  }

  if(approx(imag_cq($rop), -0.37869801657204, 0.00000000001)) {print "ok 6\n"}
  else {
    warn "\nExpected approx -0.37869801657204\nGot ", imag_cq($rop), "\n";
    print "not ok 6\n";
  }
}

$rop = sqrt($op);

if(approx(real_cq($rop), 2.4214470904334102, $eps)) {print "ok 7\n"}
else {
  warn "\nExpected approx 2.4214470904334102\nGot ", real_cq($rop), "\n";
  print "not ok 7\n";
}

if(approx(imag_cq($rop), 0.929196433359722, $eps)) {print "ok 8\n"}
else {
  warn "\nExpected approx 0.929196433359722\nGot ", imag_cq($rop), "\n";
  print "not ok 8\n";
}

##############################
##############################

if($mingw_w64_pow_bug) {
  eval{$rop = $op ** 3;};
  if($@ =~ /\*\* \(pow\) not overloaded/) {print "ok 9\nok 10\n"}
  else {
    warn "\n\$\@: $@\n";
    print "not ok 9\n";
  }
}
else {
  $rop = $op ** 3;

  if(approx(real_cq($rop), -178.75, $eps)) {print "ok 9\n"}
  else {
    warn "\nExpected approx -178.75\nGot ", real_cq($rop), "\n";
    print "not ok 9\n";
  }

  if(approx(imag_cq($rop), 246.375, $eps)) {print "ok 10\n"}
  else {
    warn "\nExpected approx 246.375\nGot ", imag_cq($rop), "\n";
    print "not ok 10\n";
  }
}

##############################
##############################

if($mingw_w64_pow_bug) {
  eval{$rop = $op ** -3;};
  if($@ =~ /\*\* \(pow\) not overloaded/) {print "ok 11\nok 12\n"}
  else {
    warn "\n\$\@: $@\n";
    print "not ok 11\n";
  }
}
else {
  $rop = $op ** -3;

  if(approx(real_cq($rop), -0.00192925795578593, $eps)) {print "ok 11\n"}
  else {
    warn "\nExpected approx -0.00192925795578593\nGot ", real_cq($rop), "\n";
    print "not ok 11\n";
  }

  if(approx(imag_cq($rop), -0.00265913806353431, $eps)) {print "ok 12\n"}
  else {
    warn "\nExpected approx -0.00265913806353431\nGot ", imag_cq($rop), "\n";
    print "not ok 12\n";
  }
}

##############################
##############################

if($mingw_w64_pow_bug) {
  eval{$rop = $op ** -2.75;};
  if($@ =~ /\*\* \(pow\) not overloaded/) {print "ok 13\nok 14\n"}
  else {
    warn "\n\$\@: $@\n";
    print "not ok 13\n";
  }
}
else {
  $rop = $op ** -2.75;

  if(approx(real_cq($rop), -0.00227483300435652, $eps)) {print "ok 13\n"}
  else {
    warn "\nExpected approx -0.00227483300435652\nGot ", real_cq($rop), "\n";
    print "not ok 13\n";
  }

  if(approx(imag_cq($rop), -0.00477682943207756, $eps)) {print "ok 14\n"}
  else {
    warn "\nExpected approx -0.00477682943207756\nGot ", imag_cq($rop), "\n";
    print "not ok 14\n";
  }
}

##############################
##############################

my $op1 = $op;
my $op2 = $op;
my $op3 = $op;

##############################
##############################

if($mingw_w64_pow_bug) {
  eval{$op1 **= 3;};
  if($@ =~ /\*\*= \(pow\-equal\) not overloaded/) {print "ok 15\nok 16\n"}
  else {
    warn "\n\$\@: $@\n";
    print "not ok 15\n";
  }
}
else {
  $op1 **= 3;

  if(approx(real_cq($op1), -178.75, $eps)) {print "ok 15\n"}
  else {
    warn "\nExpected approx -178.75\nGot ", real_cq($rop), "\n";
    print "not ok 15\n";
  }

  if(approx(imag_cq($op1), 246.375, $eps)) {print "ok 16\n"}
  else {
    warn "\nExpected approx 246.375\nGot ", imag_cq($rop), "\n";
    print "not ok 16\n";
  }
}

##############################
##############################

if($mingw_w64_pow_bug) {
  eval{$op2 **= -3;};
  if($@ =~ /\*\*= \(pow\-equal\) not overloaded/) {print "ok 17\nok 18\n"}
  else {
    warn "\n\$\@: $@\n";
    print "not ok 17\n";
  }
}
else {
  $op2 **= -3;

  if(approx(real_cq($op2), -0.00192925795578593, $eps)) {print "ok 17\n"}
  else {
    warn "\nExpected approx -0.00192925795578593\nGot ", real_cq($rop), "\n";
    print "not ok 17\n";
  }

  if(approx(imag_cq($op2), -0.00265913806353431, $eps)) {print "ok 18\n"}
  else {
    warn "\nExpected approx -0.00265913806353431\nGot ", imag_cq($rop), "\n";
    print "not ok 18\n";
  }
}

##############################
##############################

if($mingw_w64_pow_bug) {
  eval{$op3 **= -2.75;};
  if($@ =~ /\*\*= \(pow\-equal\) not overloaded/) {print "ok 19\nok 20\n"}
  else {
    warn "\n\$\@: $@\n";
    print "not ok 19\n";
  }
}
else {
  $op3 **= -2.75;

  if(approx(real_cq($op3), -0.00227483300435652, $eps)) {print "ok 19\n"}
  else {
    warn "\nExpected approx -0.00227483300435652\nGot ", real_cq($rop), "\n";
    print "not ok 19\n";
  }

  if(approx(imag_cq($op3), -0.00477682943207756, $eps)) {print "ok 20\n"}
  else {
    warn "\nExpected approx -0.00477682943207756\nGot ", imag_cq($rop), "\n";
    print "not ok 20\n";
  }
}

##############################
##############################

if(!$mingw_w64_pow_bug) {
  if(approx(real_cq(MCQ(2.0) ** 5), 32, $eps)) {print "ok 21\n"}
  else {
    print "not ok 21\n";
  }

  if(approx(real_cq(5 ** MCQ(2.0)), 25, $eps)) {print "ok 22\n"}
  else {
    print "not ok 22\n";
  }

##############################
##############################

  if(approx(real_cq(MCQ(9.0) ** 0.5), 3, $eps)) {print "ok 23\n"}
  else {print "not ok 23\n"}

  if(approx(real_cq(0.5 ** MCQ(9.0)), 0.001953125, $eps)) {print "ok 24\n"}
  else {
    print "not ok 24\n";
  }

##############################
##############################

  if(approx(real_cq(MCQ(9.0) ** '0.5'), 3, $eps)) {print "ok 25\n"}
  else {print "not ok 25\n"}

  if(approx(real_cq('0.5' ** MCQ(9.0)), 0.001953125, $eps)) {print "ok 26\n"}
  else {
    print "not ok 26\n";
  }

##############################
##############################

  if(approx(real_cq(MCQ(9.0) ** MCQ(0.5)), 3, $eps)) {print "ok 27\n"}
  else {print "not ok 27\n"}

  if(approx(real_cq(MCQ(0.5) ** MCQ(9.0)), 0.001953125, $eps)) {print "ok 28\n"}
  else {
    print "not ok 28\n";
  }
}

sub approx {
    if(($_[0] > ($_[1] - $_[2])) && ($_[0] < ($_[1] + $_[2]))) {return 1}
    return 0;
}


