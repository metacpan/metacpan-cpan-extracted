use warnings;
use strict;
use Math::Complex_C qw(:all);

my $op = MCD(5, 4.5);

my $eps = 1e-12;

print "1..7\n";

my $rop = arg_c($op);
my $irop = Math::Complex_C::_itsa($rop);

if($irop == 3) {print "ok 1\n"}
else {
  warn "\nExpected 3\nGot $irop\n";
  print "not ok 1\n";
}

if(approx($rop, 7.3281510178650655e-1, $eps)) {print "ok 2\n"}
else {
  warn "\nExpected approx 7.3281510178650655e-1\nGot $rop\n";
  print "not ok 2\n";
}

$rop = abs_c($op);
my $check = $rop;
$irop = Math::Complex_C::_itsa($rop);

if($irop == 3) {print "ok 3\n"} # NV
else {
  warn "\nExpected 3\nGot $irop\n";
  print "not ok 3\n";
}

if(approx($rop, 6.7268120235368549, $eps)) {print "ok 4\n"}
else {
  warn "\nExpected approx 6.7268120235368549\nGot $rop\n";
  print "not ok 4\n";
}

$rop = abs($op);
$irop = Math::Complex_C::_itsa($rop);

if($irop == 3) {print "ok 5\n"} # NV
else {
  warn "\nExpected 3\nGot $irop\n";
  print "not ok 5\n";
}

if(approx($rop, 6.7268120235368549, $eps)) {print "ok 6\n"}
else {
  warn "\nExpected approx 6.7268120235368549\nGot $rop\n";
  print "not ok 6\n";
}

if($rop == $check) {print "ok 7\n"}
else {
  warn "\n$rop != $check\n";
  print "not ok 7\n";
}

##############################
##############################
##############################
##############################
##############################

sub approx {
    if(($_[0] > ($_[1] - $_[2])) && ($_[0] < ($_[1] + $_[2]))) {return 1}
    return 0;
}
