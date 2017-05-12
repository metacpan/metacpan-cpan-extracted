use strict;
use warnings;
use Math::Complex_C::L qw(:all);
use Config;

print "1..16\n";


my $ld = $Config{nvtype} eq 'long double' ? 1 : 0;
my $nv_is_f128 = $Config{nvtype} eq '__float128' ? 1 : 0;

eval {require Math::LongDouble;};

my $have_m_ld = $@ ? 0 : 1;


my $c1 = MCL('3.1', '-5.1');
my $c2 = MCL(3.1, -5.1);

if   ($c1 == $c2 &&  $Config{nvsize} >= $Config{longdblsize}) {print "ok 1\n"}
elsif($c1 != $c2 &&  !$ld && !$nv_is_f128)  {print "ok 1\n"}
elsif($c1 != $c2 && "$c1" eq "$c2" && $ld) {
  my $ok = 0;
  if(real_cl($c1) != real_cl($c2)) {
    warn "\nIgnoring that 3.1 and strtold('3.1') are (insignificantly) different\n";
    $ok = 1;
  }
  if(imag_cl($c1) != imag_cl($c2)) {
    warn "\nIgnoring that -5.1 and strtold('-5.1') are (insignificantly) different\n";
    $ok = 1;
  }
  $ok ? print "ok 1\n" : print "not ok 1\n";
}
else {
  warn "\n\$ld: $ld\n\$c1: $c1\n\$c2: $c2\n";
  warn "longdblsize: $Config{longdblsize}\nnvsize: $Config{nvsize}\n";
  print "not ok 1\n";
}

assign_cl($c1, 2.0, 17);
assign_cl($c2, 2, 17.0);

if($c1 == $c2) {print "ok 2\n"}
else {
  warn "\n$c1 != $c2\n";
  print "not ok 2\n";
}

assign_cl($c1, '2.0', 17);
assign_cl($c2, 2, '17.0');

if($c1 == $c2) {print "ok 3\n"}
else {
  warn "\n$c1 != $c2\n";
  print "not ok 3\n";
}

my $c3 = Math::Complex_C::L->new(2.0, 17);
my $c4 = Math::Complex_C::L->new('2.0', 17);
my $c5 = Math::Complex_C::L->new(2.0, '17');

if($c3 == $c4 && $c3 == $c5) {print "ok 4\n"}
else {
  warn "\n\$c3: $c3\n\$c4: $c4\n\$c5: $c5\n";
  print "not ok 4\n";
}

my $c6 = MCL();

if($have_m_ld) {
  set_real_cl($c6, Math::LongDouble->new(2.0));
  set_imag_cl($c6, Math::LongDouble->new(17));
  if($c6 == $c3) {print "ok 5\n"}
  else {
    warn "\n$c6 != $c3\n";
    print "not ok 5\n";
  }
}
else {
  warn "\n Skipping test 5 - Math::LongDouble not loaded\n";
  print "ok 5\n";
}

set_real_cl($c6, 2.0);
set_imag_cl($c6, 17);
if($c6 == $c3) {print "ok 6\n"}
else {
  warn "\n$c6 != $c3\n";
  print "not ok 6\n";
}

set_real_cl($c6, '2.0');
set_imag_cl($c6, '17');
if($c6 == $c3) {print "ok 7\n"}
else {
  warn "\n$c6 != $c3\n";
  print "not ok 7\n";
}

set_real_cl($c6, ~0);
set_imag_cl($c6, 0);
if($c6 == ~0) {print "ok 8\n"}
else {
  warn "\n$c6 != ", ~0, "\n";
  print "not ok 8\n";
}

set_real_cl($c6, -21.25);
set_imag_cl($c6, 123);

my $re = real_cl($c6);
my $ire = Math::Complex_C::L::_itsa($re);

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

my $im = imag_cl($c6);
my $iim = Math::Complex_C::L::_itsa($im);

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

$re = real_cl2str($c6);
$ire = Math::Complex_C::L::_itsa($re);

if($ire == 4) {print "ok 13\n"} # PV
else {
  warn "\nExpected 4\nGot $ire\n";
  print "not ok 13\n";
}

# Crazy bug on my powerpc box with long doubles (doubledouble) necessitates
# that we multiply by 1 and then do a string comparison (eq).

$re *= 1.0;

if($re == -21.25 || "$re" eq "-21.25") {print "ok 14\n"}
else {
  warn "\nExpected -21.25\nGot $re\n";
  print "not ok 14\n";
}

$im = imag_cl2str($c6);
$iim = Math::Complex_C::L::_itsa($im);

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
