use strict;
use warnings;
use Math::Complex_C qw(:all);
use Config;

print "1..12\n";


my $c1 = MCD('3.1', '-5.1');
my $c2 = MCD(3.1, -5.1);

if   ($c1 == $c2) {print "ok 1\n"}
else {
  warn "\n\$c1: $c1\n\$c2: $c2\n";
  print "not ok 1\n";
}

assign_c($c1, 2.0, 17);
assign_c($c2, 2, 17.0);

if($c1 == $c2) {print "ok 2\n"}
else {
  warn "\n$c1 != $c2\n";
  print "not ok 2\n";
}

assign_c($c1, '2.0', 17);
assign_c($c2, 2, '17.0');

if($c1 == $c2) {print "ok 3\n"}
else {
  warn "\n$c1 != $c2\n";
  print "not ok 3\n";
}

my $c3 = Math::Complex_C->new(2.0, 17);
my $c4 = Math::Complex_C->new('2.0', 17);
my $c5 = Math::Complex_C->new(2.0, '17');

if($c3 == $c4 && $c3 == $c5) {print "ok 4\n"}
else {
  warn "\n\$c3: $c3\n\$c4: $c4\n\$c5: $c5\n";
  print "not ok 4\n";
}

my $c6 = MCD();

print "ok 5\n"; # deleted test 5


set_real_c($c6, 2.0);
set_imag_c($c6, 17);
if($c6 == $c3) {print "ok 6\n"}
else {
  warn "\n$c6 != $c3\n";
  print "not ok 6\n";
}

set_real_c($c6, '2.0');
set_imag_c($c6, '17');
if($c6 == $c3) {print "ok 7\n"}
else {
  warn "\n$c6 != $c3\n";
  print "not ok 7\n";
}

set_real_c($c6, ~0);
set_imag_c($c6, 0);
if($c6 == ~0) {print "ok 8\n"}
else {
  warn "\n$c6 != ", ~0, "\n";
  print "not ok 8\n";
}

set_real_c($c6, -21.25);
set_imag_c($c6, 123);

my $re = real_c($c6);
my $ire = Math::Complex_C::_itsa($re);

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

my $im = imag_c($c6);
my $iim = Math::Complex_C::_itsa($im);

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
##################################
