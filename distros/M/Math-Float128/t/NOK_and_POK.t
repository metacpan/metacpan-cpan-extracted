use strict;
use warnings;
use Math::Float128 qw(:all);

print "1..27\n";

my $n = '98765' x 1000;
my $r = '98765' x 1000;
my $z;
my $check = 0;

# $Math::Float128::NOK_POK = 1; # Uncomment to view warnings.

if(Math::Float128::nok_pokflag() == $check) {print "ok 1\n"}
else {
  warn "\n", Math::Float128::nok_pokflag(), " != $check\n";
  print "not ok 1\n";
}

adj($n, \$check, 1); # Should do nothing

if($n > 0) { # sets NV slot to inf, and turns on the NOK flag
  adj($n, \$check, 1);
  $z = Math::Float128->new($n);
}

if(Math::Float128::nok_pokflag() == $check) {print "ok 2\n"}
else {
  warn "\n", Math::Float128::nok_pokflag(), " != $check\n";
  print "not ok 2\n";
}

if($z == $r) {print "ok 3\n"}
else {
  warn "$z != $r\n";
  print "not ok 3\n";
}

if(Math::Float128::nok_pokflag() == $check) {print "ok 4\n"} # No change as $r is not a dualvar.
else {
  warn "\n", Math::Float128::nok_pokflag(), " != $check\n";
  print "not ok 4\n";
}

my $inf = 999**(999**999); # value is inf, NOK flag is set.
my $nan = $inf / $inf; # value is nan, NOK flag is set.

my $discard = eval{"$inf"}; # POK flag is now also set for $inf (mostly)
$discard    = eval{"$nan"}; # POK flag is now also set for $nan (mostly)

adj($inf, \$check, 1);
$check++ if Math::Float128::ISSUE_19550;

$z = Math::Float128->new($inf);

if(Math::Float128::nok_pokflag() == $check) {print "ok 5\n"}
else {
  warn "\n", Math::Float128::nok_pokflag(), " != $check\n";
  print "not ok 5\n";
}

if(is_InfF128($z)) {print "ok 6\n"}
else {
  warn "\n Expected inf\n Got $z\n";
  print "not ok 6\n";
}

adj($inf, \$check, 1);

if($z == $inf) {print "ok 7\n"}
else {
  warn "$z != inf\n";
  print "not ok 7\n";
}

if(Math::Float128::nok_pokflag() == $check) {print "ok 8\n"}
else {
  warn "\n", Math::Float128::nok_pokflag(), " != $check\n";
  print "not ok 8\n";
}

adj($nan, \$check, 1);
$check++ if Math::Float128::ISSUE_19550;

my $z2 = Math::Float128->new($nan);

if(Math::Float128::nok_pokflag() == $check) {print "ok 9\n"}
else {
  warn "\n", Math::Float128::nok_pokflag(), " != $check\n";
  print "not ok 9\n";
}

if(is_NaNF128($z2)) {print "ok 10\n"}
else {
  warn "\n Expected nan\n Got $z2\n";
  print "not ok 10\n";
}

my $fr = Math::Float128->new(10);

adj($n, \$check, 1);

my $ret = ($fr > $n);

if(Math::Float128::nok_pokflag() == $check) {print "ok 11\n"}
else {
  warn "\n", Math::Float128::nok_pokflag(), " != $check\n";
  print "not ok 11\n";
}

adj($inf, \$check, 1);

$ret = ($fr < $inf);

if(Math::Float128::nok_pokflag() == $check) {print "ok 12\n"}
else {
  warn "\n", Math::Float128::nok_pokflag(), " != $check\n";
  print "not ok 12\n";
}

adj($inf, \$check, 1);

$ret = ($fr >= $inf);

if(Math::Float128::nok_pokflag() == $check) {print "ok 13\n"}
else {
  warn "\n", Math::Float128::nok_pokflag(), " != $check\n";
  print "not ok 13\n";
}

adj($inf, \$check, 1);

$ret = ($fr <= $inf);

if(Math::Float128::nok_pokflag() == $check) {print "ok 14\n"}
else {
  warn "\n", Math::Float128::nok_pokflag(), " != $check\n";
  print "not ok 14\n";
}

adj($inf, \$check, 1);

$ret = ($fr <=> $inf);

if(Math::Float128::nok_pokflag() == $check) {print "ok 15\n"}
else {
  warn "\n", Math::Float128::nok_pokflag(), " != $check\n";
  print "not ok 15\n";
}

adj($inf, \$check, 1);

$ret = $fr * $inf;

if(Math::Float128::nok_pokflag() == $check) {print "ok 16\n"}
else {
  warn "\n", Math::Float128::nok_pokflag(), " != $check\n";
  print "not ok 16\n";
}

adj($inf, \$check, 1);

$ret = $fr + $inf;

if(Math::Float128::nok_pokflag() == $check) {print "ok 17\n"}
else {
  warn "\n", Math::Float128::nok_pokflag(), " != $check\n";
  print "not ok 17\n";
}

adj($inf, \$check, 1);

$ret = $fr - $inf;

if(Math::Float128::nok_pokflag() == $check) {print "ok 18\n"}
else {
  warn "\n", Math::Float128::nok_pokflag(), " != $check\n";
  print "not ok 18\n";
}

adj($inf, \$check, 1);

$ret = $fr / $inf;

if(Math::Float128::nok_pokflag() == $check) {print "ok 19\n"}
else {
  warn "\n", Math::Float128::nok_pokflag(), " != $check\n";
  print "not ok 19\n";
}

adj($inf, \$check, 1);

$ret = $inf ** $fr;

if(Math::Float128::nok_pokflag() == $check) {print "ok 20\n"}
else {
  warn "\n", Math::Float128::nok_pokflag(), " != $check\n";
  print "not ok 20\n";
}

adj($inf, \$check, 1);

$fr *= $inf;

if(Math::Float128::nok_pokflag() == $check) {print "ok 21\n"}
else {
  warn "\n", Math::Float128::nok_pokflag(), " != $check\n";
  print "not ok 21\n";
}

adj($inf, \$check, 1);

$fr += $inf;

if(Math::Float128::nok_pokflag() == $check) {print "ok 22\n"}
else {
  warn "\n", Math::Float128::nok_pokflag(), " != $check\n";
  print "not ok 22\n";
}

adj($inf, \$check, 1);

$fr -= $inf;

if(Math::Float128::nok_pokflag() == $check) {print "ok 23\n"}
else {
  warn "\n", Math::Float128::nok_pokflag(), " != $check\n";
  print "not ok 23\n";
}

adj($inf, \$check, 1);

$fr /= $inf;

if(Math::Float128::nok_pokflag() == $check) {print "ok 24\n"}
else {
  warn "\n", Math::Float128::nok_pokflag(), " != $check\n";
  print "not ok 24\n";
}

adj($inf, \$check, 1);

$inf **= Math::Float128->new(1);

if(Math::Float128::nok_pokflag() == $check) {print "ok 25\n"}
else {
  warn "\n", Math::Float128::nok_pokflag(), " != $check\n";
  print "not ok 25\n";
}

adj($n, \$check, 1);

$ret = ($z != $n);

if(Math::Float128::nok_pokflag() == $check) {print "ok 26\n"}
else {
  warn "\n", Math::Float128::nok_pokflag(), " != $check\n";
  print "not ok 26\n";
}

if(Math::Float128::ISSUE_19550) {
  if($] < 5.035010) {
    warn "ISSUE_19550 unexpectedly set\n";
    print "not ok 27\n";
  }
  else {
    warn "ISSUE_19550 set\n";
    print "ok 27\n";
  }
}
else {
  warn "ISSUE_19550 not set\n";
  print "ok 27\n";
}

########

sub adj {
  if(Math::Float128::_SvNOK($_[0]) && Math::Float128::_SvPOK($_[0])) {
  ${$_[1]} += $_[2];
  }
}
