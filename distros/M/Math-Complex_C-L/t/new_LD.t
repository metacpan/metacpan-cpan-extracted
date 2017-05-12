use strict;
use warnings;
use Math::Complex_C::L qw(:all);

eval{require Math::LongDouble;};

if($@) {
  print "1..1\n";
  warn "Skipping all tests as Math::LongDouble is not available:\n$@\n";
  print "ok 1\n";
  exit 0;
}

print "1..8\n";

my $f_r = Math::LongDouble->new('3.1');
my $f_i = Math::LongDouble->new('-5.1');

my $root_2 = sqrt(Math::LongDouble->new(2.0));

my $c1 = MCL('3.1', '-5.1');
my $c2 = MCL($f_r, $f_i);

if($c1 == $c2) {print "ok 1\n"}
else {
  warn "\n$c1 != $c2\n";
  print "not ok 1\n";
}

my $c3 = sqrt(MCL(-2, 0));
if($c3 == MCL(0, $root_2)) {print "ok 2\n"}
else {
  warn"\n$c3 != ", MCL(0, $root_2), "\n";
  print "not ok 2\n";
}

my $c4 = Math::Complex_C::L->new($f_r, $f_i);
if($c4 == $c2) {print "ok 3\n"}
else {
  warn "\n$c4 != $c2\n";
  print "not ok 3\n";
}

LD2cl($c4, Math::LongDouble->new('18.3'), Math::LongDouble->new(19.5));
cl2LD($f_r, $f_i, $c4);

if($f_r == '18.3' && $f_i == 19.5) {print "ok 4\n"}
else {
  warn "\nExpected (18.3 19.5)\nGot ($f_r $f_i)\n";
  print "not ok 4\n";
}


###################################

my $c6 = MCL('-21.25', '123');

my $re = real_cl2LD($c6);
my $ire = Math::Complex_C::L::_itsa($re);

if($ire == 96) {print "ok 5\n"} # M::LD object
else {
  warn "\nExpected 96\nGot $ire\n";
  print "not ok 5\n";
}

if($re == -21.25) {print "ok 6\n"}
else {
  warn "\nExpected -21.25\nGot $re\n";
  print "not ok 6\n";
}

my $im = imag_cl2LD($c6);
my $iim = Math::Complex_C::L::_itsa($im);

if($iim == 96) {print "ok 7\n"} # M::LD object
else {
  warn "\nExpected 96\nGot $iim\n";
  print "not ok 7\n";
}

if($im == 123) {print "ok 8\n"}
else {
  warn "\nExpected 123\nGot $im\n";
  print "not ok 8\n";
}

##################################
