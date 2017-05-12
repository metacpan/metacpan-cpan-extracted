use strict;
use warnings;
use Math::Complex_C::Q qw(:all);

eval{require Math::Float128;};

if($@) {
  print "1..1\n";
  warn "Skipping all tests as Math::Float128 is not available:\n$@\n";
  print "ok 1\n";
  exit 0;
}

if($Math::Float128::VERSION lt '0.05') {
  print "1..1\n";
  warn "Skipping all tests as Math-Float128-0.05 (or later) is not available.\n",
       "We have only version $Math::Float128::VERSION.\n";
  print "ok 1\n";
  exit 0;
}

print "1..8\n";

my $f_r = Math::Float128->new('3.1');
my $f_i = Math::Float128->new('-5.1');

my $root_2 = sqrt(Math::Float128->new(2.0));

my $c1 = MCQ('3.1', '-5.1');
my $c2 = MCQ($f_r, $f_i);

if($c1 == $c2) {print "ok 1\n"}
else {
  warn "\n$c1 != $c2\n";
  print "not ok 1\n";
}

my $c3 = sqrt(MCQ(-2, 0));
if($c3 == MCQ(0, $root_2)) {print "ok 2\n"}
else {
  warn"\n$c3 != ", MCQ(0, $root_2), "\n";
  print "not ok 2\n";
}

my $c4 = Math::Complex_C::Q->new($f_r, $f_i);
if($c4 == $c2) {print "ok 3\n"}
else {
  warn "\n$c4 != $c2\n";
  print "not ok 3\n";
}

F2cq($c4, Math::Float128->new('18.3'), Math::Float128->new(19.5));
cq2F($f_r, $f_i, $c4);

if($f_r == '18.3' && $f_i == 19.5) {print "ok 4\n"}
else {
  warn "\nExpected (18.3 19.5)\nGot ($f_r $f_i)\n";
  print "not ok 4\n";
}


###################################

my $c6 = MCQ('-21.25', '123');

my $re = real_cq2F($c6);
my $ire = Math::Complex_C::Q::_itsa($re);

if($ire == 113) {print "ok 5\n"} # M::F128 object
else {
  warn "\nExpected 113\nGot $ire\n";
  print "not ok 5\n";
}

if($re == -21.25) {print "ok 6\n"}
else {
  warn "\nExpected -21.25\nGot $re\n";
  print "not ok 6\n";
}

my $im = imag_cq2F($c6);
my $iim = Math::Complex_C::Q::_itsa($im);

if($iim == 113) {print "ok 7\n"} # M::F128 object
else {
  warn "\nExpected 113\nGot $iim\n";
  print "not ok 7\n";
}

if($im == 123) {print "ok 8\n"}
else {
  warn "\nExpected 123\nGot $im\n";
  print "not ok 8\n";
}

##################################
