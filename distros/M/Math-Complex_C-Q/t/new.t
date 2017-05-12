use strict;
use warnings;
use Math::Complex_C::Q qw(:all);
use Config;

print "1..16\n";


my $f128 = $Config{nvtype} eq '__float128' ? 1 : 0;

eval {require Math::Float128;};

my $have_m_f128 = $@ ? 0 : 1;


my $c1 = MCQ('3.1', '-5.1');
my $c2 = MCQ(3.1, -5.1);

if   ($c1 == $c2 &&  $f128) {print "ok 1\n"}
elsif($c1 != $c2 && !$f128) {print "ok 1\n"}
else {
  warn "\n\$f128: $f128\n\$c1: $c1\n\$c2: $c2\n";
  print "not ok 1\n";
}

assign_cq($c1, 2.0, 17);
assign_cq($c2, 2, 17.0);

if($c1 == $c2) {print "ok 2\n"}
else {
  warn "\n$c1 != $c2\n";
  print "not ok 2\n";
}

assign_cq($c1, '2.0', 17);
assign_cq($c2, 2, '17.0');

if($c1 == $c2) {print "ok 3\n"}
else {
  warn "\n$c1 != $c2\n";
  print "not ok 3\n";
}

my $c3 = Math::Complex_C::Q->new(2.0, 17);
my $c4 = Math::Complex_C::Q->new('2.0', 17);
my $c5 = Math::Complex_C::Q->new(2.0, '17');

if($c3 == $c4 && $c3 == $c5) {print "ok 4\n"}
else {
  warn "\n\$c3: $c3\n\$c4: $c4\n\$c5: $c5\n";
  print "not ok 4\n";
}

my $c6 = MCQ();

if($have_m_f128) {
  set_real_cq($c6, Math::Float128->new(2.0));
  set_imag_cq($c6, Math::Float128->new(17));
  if($c6 == $c3) {print "ok 5\n"}
  else {
    warn "\n$c6 != $c3\n";
    print "not ok 5\n";
  }
}
else {
  warn "\n Skipping test 5 - Math::Float128 not loaded\n";
  print "ok 5\n";
}

set_real_cq($c6, 2.0);
set_imag_cq($c6, 17);
if($c6 == $c3) {print "ok 6\n"}
else {
  warn "\n$c6 != $c3\n";
  print "not ok 6\n";
}

set_real_cq($c6, '2.0');
set_imag_cq($c6, '17');
if($c6 == $c3) {print "ok 7\n"}
else {
  warn "\n$c6 != $c3\n";
  print "not ok 7\n";
}

set_real_cq($c6, ~0);
set_imag_cq($c6, 0);
if($c6 == ~0) {print "ok 8\n"}
else {
  warn "\n$c6 != ", ~0, "\n";
  print "not ok 8\n";
}

set_real_cq($c6, -21.25);
set_imag_cq($c6, 123);

my $re = real_cq($c6);
my $ire = Math::Complex_C::Q::_itsa($re);

if($ire == 3) {print "ok 9\n"} # NV
else {
  warn "\nExpected 3\nGot $ire\n";
  print "not ok 9\n";
}

if($re == -21.25) {print "ok 10\n"}
else {
  warn "\nExpected -21.25\nGot $re\n";
  print "not ok 10\n";
}

my $im = imag_cq($c6);
my $iim = Math::Complex_C::Q::_itsa($im);

if($iim == 3) {print "ok 11\n"} # NV
else {
  warn "\nExpected 3\nGot $iim\n";
  print "not ok 11\n";
}

if($im == 123) {print "ok 12\n"}
else {
  warn "\nExpected 123\nGot $im\n";
  print "not ok 12\n";
}

###################################

$re = real_cq2str($c6);
$ire = Math::Complex_C::Q::_itsa($re);

if($ire == 4) {print "ok 13\n"} # PV
else {
  warn "\nExpected 4\nGot $ire\n";
  print "not ok 13\n";
}

if($re == -21.25) {print "ok 14\n"}
else {
  warn "\nExpected -21.25\nGot $re\n";
  print "not ok 14\n";
}

$im = imag_cq2str($c6);
$iim = Math::Complex_C::Q::_itsa($im);

if($iim == 4) {print "ok 15\n"} # PV
else {
  warn "\nExpected 4\nGot $iim\n";
  print "not ok 15\n";
}

if($im == 123) {print "ok 16\n"}
else {
  warn "\nExpected 123\nGot $im\n";
  print "not ok 16\n";
}

##################################
