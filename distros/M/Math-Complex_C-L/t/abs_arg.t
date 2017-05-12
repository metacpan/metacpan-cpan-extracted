use warnings;
use strict;
use Math::Complex_C::L qw(:all);

my $op = MCL(5, 4.5);

my $eps = 1e-12;

print "1..15\n";

my $rop = arg_cl($op);
my $irop = Math::Complex_C::L::_itsa($rop);

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

$rop = abs_cl($op);
my $check = $rop;
$irop = Math::Complex_C::L::_itsa($rop);

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
$irop = Math::Complex_C::L::_itsa($rop);

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

$rop = arg_cl2str($op);
$irop = Math::Complex_C::L::_itsa($rop);

if($irop == 4) {print "ok 8\n"} # PV
else {
  warn "\nExpected 4\nGot $irop\n";
  print "not ok 8\n";
}

if(approx($rop, 7.3281510178650655e-1, $eps)) {print "ok 9\n"}
else {
  warn "\nExpected approx 7.3281510178650655e-1\nGot $rop\n";
  print "not ok 9\n";
}

$rop = abs_cl2str($op);
$irop = Math::Complex_C::L::_itsa($rop);

if($irop == 4) {print "ok 10\n"} # PV
else {
  warn "\nExpected 4\nGot $irop\n";
  print "not ok 10\n";
}

if(approx($rop, 6.7268120235368549, $eps)) {print "ok 11\n"}
else {
  warn "\nExpected approx 6.7268120235368549\nGot $rop\n";
  print "not ok 11\n";
}

##############################
##############################

eval {require Math::LongDouble;};

if(!$@) {
  $rop = arg_cl2LD($op);
  $irop = Math::Complex_C::L::_itsa($rop);

  if($irop == 96) {print "ok 12\n"} # Math::LongDouble object
  else {
    warn "\nExpected 96\nGot $irop\n";
    print "not ok 12\n";
  }

  if(approx($rop, 7.3281510178650655e-1, $eps)) {print "ok 13\n"}
  else {
    warn "\nExpected approx 7.3281510178650655e-1\nGot $rop\n";
    print "not ok 13\n";
  }

  $rop = abs_cl2LD($op);
  $irop = Math::Complex_C::L::_itsa($rop);

  if($irop == 96) {print "ok 14\n"} # Math::LongDouble object
  else {
    warn "\nExpected 96\nGot $irop\n";
    print "not ok 14\n";
  }

  if(approx($rop, 6.7268120235368549, $eps)) {print "ok 15\n"}
  else {
    warn "\nExpected approx 6.7268120235368549\nGot $rop\n";
    print "not ok 15\n";
  }
}
else {
  warn "\nSkipping tests 12-15 - Math::LongDouble not loaded\n\$\@: $@\n";
  for(12..15) {print "ok $_\n"}
}

##############################
##############################

sub approx {
    if(($_[0] > ($_[1] - $_[2])) && ($_[0] < ($_[1] + $_[2]))) {return 1}
    return 0;
}
