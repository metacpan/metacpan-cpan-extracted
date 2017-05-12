use warnings;
use strict;
use Math::Complex_C::Q qw(:all);

print "1..30\n";

my $eps = 1e-12;

my $op = MCQ(2, 2);
my $rop = MCQ();

if(Math::Complex_C::Q::_mingw_w64_bug()) {
  eval{sin_cq($rop, $op);};
  if($@ =~ /sin_cq not implemented/) {print "ok 1\nok 2\n"}
  else {
    warn "\n\$\@: $@\n";
    print "not ok 1\n";
  }
}
else {
  sin_cq($rop, $op);

  if(approx(real_cq($rop), 3.420954861117, $eps)) {print "ok 1\n"}
  else {
    warn "\nExpected approx 3.420954861117\nGot ", real_cq($rop), "\n";
    print "not ok 1\n";
  }

  if(approx(imag_cq($rop), -1.50930648532362, $eps)) {print "ok 2\n"}
  else {
    warn "\nExpected approx -1.50930648532362\nGot ", imag_cq($rop), "\n";
    print "not ok 2\n";
  }
}

if(Math::Complex_C::Q::_mingw_w64_bug()) {
  eval{cos_cq($rop, $op);};
  if($@ =~ /cos_cq not implemented/) {print "ok 3\nok 4\n"}
  else {
    warn "\n\$\@: $@\n";
    print "not ok 3\n";
  }
}
else {
  cos_cq($rop, $op);

  if(approx(real_cq($rop), -1.56562583531574, $eps)) {print "ok 3\n"}
  else {
    warn "\nExpected approx -1.56562583531574\nGot ", real_cq($rop), "\n";
    print "not ok 3\n";
  }

  if(approx(imag_cq($rop), -3.29789483631124, $eps)) {print "ok 4\n"}
  else {
    warn "\nExpected approx -3.29789483631124\nGot ", imag_cq($rop), "\n";
    print "not ok 4\n";
  }
}

if(Math::Complex_C::Q::_mingw_w64_bug()) {
  eval{tan_cq($rop, $op);};
  if($@ =~ /tan_cq not implemented/) {print "ok 5\nok 6\n"}
  else {
    warn "\n\$\@: $@\n";
    print "not ok 5\n";
  }
}
else {
  tan_cq($rop, $op);

  if(approx(real_cq($rop), -0.0283929528682323, 0.00000000001)) {print "ok 5\n"}
  else {
    warn "\nExpected approx -0.0283929528682323\nGot ", real_cq($rop), "\n";
    print "not ok 5\n";
  }

  if(approx(imag_cq($rop), 1.0238355945704727, 0.00000000001)) {print "ok 6\n"}
  else {
    warn "\nExpected approx 1.0238355945704727\nGot ", imag_cq($rop), "\n";
    print "not ok 6\n";
  }
}

###################################
###################################

asin_cq($rop, $op);

if(approx(real_cq($rop), 0.754249144698046, $eps)) {print "ok 7\n"}
else {
  warn "\nExpected approx 0.754249144698046\nGot ", real_cq($rop), "\n";
  print "not ok 7\n";
}

if(approx(imag_cq($rop), 1.73432452148797, $eps)) {print "ok 8\n"}
else {
  warn "\nExpected approx 1.73432452148797\nGot ", imag_cq($rop), "\n";
  print "not ok 8\n";
}

acos_cq($rop, $op);

if(approx(real_cq($rop), 0.81654718209685, $eps)) {print "ok 9\n"}
else {
  warn "\nExpected approx 0.81654718209685\nGot ", real_cq($rop), "\n";
  print "not ok 9\n";
}

if(approx(imag_cq($rop), -1.73432452148797, $eps)) {print "ok 10\n"}
else {
  warn "\nExpected approx -1.73432452148797\nGot ", imag_cq($rop), "\n";
  print "not ok 10\n";
}

atan_cq($rop, $op);

if(approx(real_cq($rop), 1.31122326967164, 0.00000000001)) {print "ok 11\n"}
else {
  warn "\nExpected approx 1.31122326967164\nGot ", real_cq($rop), "\n";
  print "not ok 11\n";
}

if(approx(imag_cq($rop), 0.238877861256859, 0.00000000001)) {print "ok 12\n"}
else {
  warn "\nExpected approx 0.238877861256859\nGot ", imag_cq($rop), "\n";
  print "not ok 12\n";
}

#################################
#################################

if(Math::Complex_C::Q::_mingw_w64_bug()) {
  eval{sinh_cq($rop, $op);};
  if($@ =~ /sinh_cq not implemented/) {print "ok 13\nok 14\n"}
  else {
    warn "\n\$\@: $@\n";
    print "not ok 13\n";
  }
}
else {
  sinh_cq($rop, $op);

  if(approx(real_cq($rop), -1.50930648532362, $eps)) {print "ok 13\n"}
  else {
    warn "\nExpected approx -1.50930648532362\nGot ", real_cq($rop), "\n";
    print "not ok 13\n";
  }

  if(approx(imag_cq($rop), 3.42095486111701, $eps)) {print "ok 14\n"}
  else {
    warn "\nExpected approx 3.42095486111701\nGot ", imag_cq($rop), "\n";
    print "not ok 14\n";
  }
}

if(Math::Complex_C::Q::_mingw_w64_bug()) {
  eval{cosh_cq($rop, $op);};
  if($@ =~ /cosh_cq not implemented/) {print "ok 15\nok 16\n"}
  else {
    warn "\n\$\@: $@\n";
    print "not ok 15\n";
  }
}
else {
  cosh_cq($rop, $op);

  if(approx(real_cq($rop), -1.56562583531574, $eps)) {print "ok 15\n"}
  else {
    warn "\nExpected approx -1.56562583531574\nGot ", real_cq($rop), "\n";
    print "not ok 15\n";
  }

  if(approx(imag_cq($rop), 3.29789483631124, $eps)) {print "ok 16\n"}
  else {
    warn "\nExpected approx 3.29789483631124\nGot ", imag_cq($rop), "\n";
    print "not ok 16\n";
  }
}

if(Math::Complex_C::Q::_mingw_w64_bug()) {
  eval{tanh_cq($rop, $op);};
  if($@ =~ /tanh_cq not implemented/) {print "ok 17\nok 18\n"}
  else {
    warn "\n\$\@: $@\n";
    print "not ok 17\n";
  }
}
else {
  tanh_cq($rop, $op);

  if(approx(real_cq($rop), 1.0238355945704727, 0.00000000001)) {print "ok 17\n"}
  else {
    warn "\nExpected approx 1.0238355945704727\nGot ", real_cq($rop), "\n";
    print "not ok 17\n";
  }

  if(approx(imag_cq($rop), -0.0283929528682323, 0.00000000001)) {print "ok 18\n"}
  else {
    warn "\nExpected approx -0.0283929528682323\nGot ", imag_cq($rop), "\n";
    print "not ok 18\n";
  }
}

###################################
###################################

asinh_cq($rop, $op);

if(approx(real_cq($rop), 1.73432452148797, $eps)) {print "ok 19\n"}
else {
  warn "\nExpected approx 1.73432452148797\nGot ", real_cq($rop), "\n";
  print "not ok 19\n";
}

if(approx(imag_cq($rop), 0.754249144698046, $eps)) {print "ok 20\n"}
else {
  warn "\nExpected approx 0.754249144698046\nGot ", imag_cq($rop), "\n";
  print "not ok 20\n";
}

acosh_cq($rop, $op);

if(approx(real_cq($rop), 1.73432452148797, $eps)) {print "ok 21\n"}
else {
  warn "\nExpected approx 1.73432452148797\nGot ", real_cq($rop), "\n";
  print "not ok 21\n";
}

if(approx(imag_cq($rop), 0.81654718209685, $eps)) {print "ok 22\n"}
else {
  warn "\nExpected approx 0.81654718209685\nGot ", imag_cq($rop), "\n";
  print "not ok 22\n";
}

atanh_cq($rop, $op);

if(approx(real_cq($rop), 0.238877861256859, 0.00000000001)) {print "ok 23\n"}
else {
  warn "\nExpected approx 0.238877861256859\nGot ", real_cq($rop), "\n";
  print "not ok 23\n";
}

if(approx(imag_cq($rop), 1.311223269671635, 0.00000000001)) {print "ok 24\n"}
else {
  warn "\nExpected approx 1.311223269671635\nGot ", imag_cq($rop), "\n";
  print "not ok 24\n";
}

###################################
###################################

if(Math::Complex_C::Q::_mingw_w64_bug()) {
  eval {$rop = sin($op);};
  if($@ =~ /sin not overloaded/) {print "ok 25\nok 26\n"}
  else {
    warn "\n\$\@: $@\n";
    print "not ok 25\n";
  }
}
else {
  $rop = sin($op);

  if(approx(real_cq($rop), 3.420954861117, $eps)) {print "ok 25\n"}
  else {
    warn "\nExpected approx 3.420954861117\nGot ", real_cq($rop), "\n";
    print "not ok 25\n";
  }

  if(approx(imag_cq($rop), -1.50930648532362, $eps)) {print "ok 26\n"}
  else {
    warn "\nExpected approx -1.50930648532362\nGot ", imag_cq($rop), "\n";
    print "not ok 26\n";
  }
}

if(Math::Complex_C::Q::_mingw_w64_bug()) {
  eval {$rop = cos($op);};
  if($@ =~ /cos not overloaded/) {print "ok 27\nok 28\n"}
  else {
    warn "\n\$\@: $@\n";
    print "not ok 27\n";
  }
}
else {
  $rop = cos($op);

  if(approx(real_cq($rop), -1.56562583531574, $eps)) {print "ok 27\n"}
  else {
    warn "\nExpected approx -1.56562583531574\nGot ", real_cq($rop), "\n";
    print "not ok 27\n";
  }

  if(approx(imag_cq($rop), -3.29789483631124, $eps)) {print "ok 28\n"}
  else {
    warn "\nExpected approx -3.29789483631124\nGot ", imag_cq($rop), "\n";
    print "not ok 28\n";
  }
}

###################################
###################################

my $at = Math::Complex_C::Q->new(2.5, 3.5);

$rop = atan2($op, $at);

if(approx(real_cq($rop), 0.579192942598755, 0.00000000001)) {print "ok 29\n"}
else {
  warn "\nExpected approx  0.579192942598755\nGot ", real_cq($rop), "\n";
  print "not ok 29\n";
}

if(approx(imag_cq($rop), -0.0760528436007479, 0.00000000001)) {print "ok 30\n"}
else {
  warn "\nExpected approx -0.0760528436007479\nGot ", imag_cq($rop), "\n";
  print "not ok 30\n";
}


sub approx {
    if(($_[0] > ($_[1] - $_[2])) && ($_[0] < ($_[1] + $_[2]))) {return 1}
    return 0;
}



