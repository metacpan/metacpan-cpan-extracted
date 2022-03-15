use strict;
use warnings;
use Math::MPC qw(:mpc);
use Math::MPFR qw(:mpfr);

print "1..129\n";

# $Math::MPC::NOK_POK = 1; # Uncomment to display warnings

my $n = '98765' x 80;
my $r = '98765' x 80;
my $z;
my $count = 0;
print Math::MPC::nok_pokflag(), "\n";
if($n > 0) { # sets NV slot to inf, and turns on the NOK flag
  $z = Math::MPC->new($n);
}
print Math::MPC::nok_pokflag(), "\n";
adj($n, \$count, 1);

if(Math::MPC::nok_pokflag() == $count) {print "ok 1\n"}
else {
  warn "\n", Math::MPC::nok_pokflag(), " != $count\n";
  print "not ok 1\n";
}

if($z == $r) {print "ok 2\n"}
else {
  warn "$z != $r\n";
  print "not ok 2\n";
}

adj($r, \$count, 1);

if(Math::MPC::nok_pokflag() == $count) {print "ok 3\n"}
else {
  warn "\n", Math::MPC::nok_pokflag(), " != $count\n";
  print "not ok 3\n";
}

if($z != $r) {
  warn "$z != $r\n";
  print "not ok 4\n";
}
else {print "ok 4\n"}

adj($r, \$count, 1);

if(Math::MPC::nok_pokflag() == $count) {print "ok 5\n"}
else {
  warn "\n", Math::MPC::nok_pokflag(), " != $count\n";
  print "not ok 5\n";
}

my $inf = 999**(999**999); # value is inf, NOK flag is set.
my $nan = $inf / $inf; # value is nan, NOK flag is set.
my $ninf = $inf * -1;

my $discard = eval{"$inf" }; # POK flag is now also set for $inf  (mostly)
$discard    = eval{"$nan" }; # POK flag is now also set for $nan  (mostly)
$discard    = eval{"$ninf"}; # POK flag is now also set for $ninf (mostly)


$z = Math::MPC->new($inf);

adj($inf, \$count, 1);

if(Math::MPC::nok_pokflag() == $count) {print "ok 6\n"}
else {
  warn "\n", Math::MPC::nok_pokflag(), " != $count\n";
  print "not ok 6\n";
}

my $check = Math::MPFR->new();

RMPC_RE($check, $z);

if(Rmpfr_inf_p($check) && $check > 0) {print "ok 7\n"}
else {
  warn "\n Expected +ve inf\n Got $check\n";
  print "not ok 7\n";
}

if($z == $inf) {print "ok 8\n"}
else {
  warn "$z != inf\n";
  print "not ok 8\n";
}

adj($inf, \$count, 1);

if(Math::MPC::nok_pokflag() == $count) {print "ok 9\n"}
else {
  warn "\n", Math::MPC::nok_pokflag(), " != $count\n";
  print "not ok 9\n";
}

my $z2 = Math::MPC->new($nan);

adj($nan, \$count, 1);

if(Math::MPC::nok_pokflag() == $count) {print "ok 10\n"}
else {
  warn "\n", Math::MPC::nok_pokflag(), " != $count\n";
  print "not ok 10\n";
}

RMPC_RE($check, $z2);

if(Rmpfr_nan_p($check)) {print "ok 11\n"}
else {
  warn "\n Expected nan\n Got $check\n";
  print "not ok 11\n";
}

my $fr = Math::MPC->new(10);



my $ret = $fr * $inf;

adj($inf, \$count, 1);

if(Math::MPC::nok_pokflag() == $count) {print "ok 12\n"}
else {
  warn "\n", Math::MPC::nok_pokflag(), " != $count\n";
  print "not ok 12\n";
}

RMPC_RE($check, $ret);

if(Rmpfr_inf_p($check) && $check > 0) {print "ok 13\n"}
else {
  warn "\n Expected +ve inf\n Got $ret\n";
  print "not ok 13\n";
}

$ret = $fr + $inf;

adj($inf, \$count, 1);

if(Math::MPC::nok_pokflag() == $count) {print "ok 14\n"}
else {
  warn "\n", Math::MPC::nok_pokflag(), " != $count\n";
  print "not ok 14\n";
}

RMPC_RE($check, $ret);

if(Rmpfr_inf_p($check) && $check > 0) {print "ok 15\n"}
else {
  warn "\n Expected +ve inf\n Got $ret\n";
  print "not ok 15\n";
}

$ret = $fr - $inf;

adj($inf, \$count, 1);

if(Math::MPC::nok_pokflag() == $count) {print "ok 16\n"}
else {
  warn "\n", Math::MPC::nok_pokflag(), " != $count\n";
  print "not ok 16\n";
}

RMPC_RE($check, $ret);

if(Rmpfr_inf_p($check) && $check < 0) {print "ok 17\n"}
else {
  warn "\n Expected -ve inf\n Got $ret\n";
  print "not ok 17\n";
}

$ret = $fr / $inf;

adj($inf, \$count, 1);

if(Math::MPC::nok_pokflag() == $count) {print "ok 18\n"}
else {
  warn "\n", Math::MPC::nok_pokflag(), " != $count\n";
  print "not ok 18\n";
}

RMPC_RE($check, $ret);

if(Rmpfr_zero_p($check)) {print "ok 19\n"}
else {
  warn "\n Expected 0\n Got $ret\n";
  print "not ok 19\n";
}

$ret = $inf ** $fr;

adj($inf, \$count, 1);

if(Math::MPC::nok_pokflag() == $count) {print "ok 20\n"}
else {
  warn "\n", Math::MPC::nok_pokflag(), " != $count\n";
  print "not ok 20\n";
}

RMPC_RE($check, $ret);

if(Rmpfr_inf_p($check) && $check > 0) {print "ok 21\n"}
else {
  warn "\n Expected +ve inf\n Got $ret\n";
  print "not ok 21\n";
}

$fr *= $inf;

adj($inf, \$count, 1);

if(Math::MPC::nok_pokflag() == $count) {print "ok 22\n"}
else {
  warn "\n", Math::MPC::nok_pokflag(), " != $count\n";
  print "not ok 22\n";
}

RMPC_RE($check, $fr);

if(Rmpfr_inf_p($check) && $check > 0) {print "ok 23\n"}
else {
  warn "\n Expected +ve inf\n Got $ret\n";
  print "not ok 23\n";
}

$fr += $inf;

adj($inf, \$count, 1);

if(Math::MPC::nok_pokflag() == $count) {print "ok 24\n"}
else {
  warn "\n", Math::MPC::nok_pokflag(), " != $count\n";
  print "not ok 24\n";
}

RMPC_RE($check, $fr);

if(Rmpfr_inf_p($check) && $check > 0) {print "ok 25\n"}
else {
  warn "\n Expected +ve inf\n Got $ret\n";
  print "not ok 25\n";
}

$fr -= $inf;

adj($inf, \$count, 1);

if(Math::MPC::nok_pokflag() == $count) {print "ok 26\n"}
else {
  warn "\n", Math::MPC::nok_pokflag(), " != $count\n";
  print "not ok 26\n";
}

RMPC_RE($check, $fr);

if(Rmpfr_nan_p($check)) {print "ok 27\n"}
else {
  warn "\n Expected nan\n Got $ret\n";
  print "not ok 27\n";
}

$fr /= $inf;

adj($inf, \$count, 1);

if(Math::MPC::nok_pokflag() == $count) {print "ok 28\n"}
else {
  warn "\n", Math::MPC::nok_pokflag(), " != $count\n";
  print "not ok 28\n";
}

RMPC_RE($check, $fr);

if(Rmpfr_nan_p($check)) {print "ok 29\n"}
else {
  warn "\n Expected nan\n Got $ret\n";
  print "not ok 29\n";
}

Rmpc_set_NV($fr, 2.0, MPC_RNDNN);

$fr **= $inf;

adj($inf, \$count, 1);

if(Math::MPC::nok_pokflag() == $count) {print "ok 30\n"}
else {
  warn "\n", Math::MPC::nok_pokflag(), " != $count\n";
  print "not ok 30\n";
}

RMPC_RE($check, $fr);

if(Rmpfr_inf_p($check) && $check > 0) {print "ok 31\n"}
else {
  warn "\n Expected +ve inf\n Got $ret\n";
  print "not ok 31\n";
}

if($z != $n) {print "ok 32\n"}
else {
  warn "\n$z == $n\n";
  print "not ok 32\n";
}

adj($n, \$count, 1);

if(Math::MPC::nok_pokflag() == $count) {print "ok 33\n"}
else {
  warn "\n", Math::MPC::nok_pokflag(), " != $count\n";
  print "not ok 33\n";
}

if($z == $n) {
  warn "\n$z == $n\n";
  print "not ok 34\n";
}
else {
  print "ok 34\n";
}

adj($n, \$count, 1);

if(Math::MPC::nok_pokflag() == $count) {print "ok 35\n"}
else {
  warn "\n", Math::MPC::nok_pokflag(), " != $count\n";
  print "not ok 35\n";
}

my $ret2 = Math::MPC->new();

$ret = Math::MPC->new(1.2) *  $nan;

adj($nan, \$count, 1);

if(Math::MPC::nok_pokflag() == $count) {print "ok 36\n"}
else {
  warn "\n", Math::MPC::nok_pokflag(), " != $count\n";
  print "not ok 36\n";
}

RMPC_RE($check, $ret);

if(Rmpfr_nan_p($check)) {print "ok 37\n"}
else {
  warn "\n Expected NaN\n Got $check\n";
  print "not ok 37\n";
}

$ret = Math::MPC->new(1.2) +  $nan;

adj($nan, \$count, 1);

if(Math::MPC::nok_pokflag() == $count) {print "ok 38\n"}
else {
  warn "\n", Math::MPC::nok_pokflag(), " != $count\n";
  print "not ok 38\n";
}

RMPC_RE($check, $ret);

if(Rmpfr_nan_p($check)) {print "ok 39\n"}
else {
  warn "\n Expected NaN\n Got $check\n";
  print "not ok 39\n";
}

$ret = Math::MPC->new(1.2) -  $nan;

adj($nan, \$count, 1);

if(Math::MPC::nok_pokflag() == $count) {print "ok 40\n"}
else {
  warn "\n", Math::MPC::nok_pokflag(), " != $count\n";
  print "not ok 40\n";
}

RMPC_RE($check, $ret);

if(Rmpfr_nan_p($check)) {print "ok 41\n"}
else {
  warn "\n Expected NaN\n Got $check\n";
  print "not ok 41\n";
}

$ret = Math::MPC->new(1.2) /  $nan;

adj($nan, \$count, 1);

if(Math::MPC::nok_pokflag() == $count) {print "ok 42\n"}
else {
  warn "\n", Math::MPC::nok_pokflag(), " != $count\n";
  print "not ok 42\n";
}

RMPC_RE($check, $ret);

if(Rmpfr_nan_p($check)) {print "ok 43\n"}
else {
  warn "\n Expected NaN\n Got $check\n";
  print "not ok 43\n";
}

$ret = Math::MPC->new(1.2) ** $nan;

adj($nan, \$count, 1);

if(Math::MPC::nok_pokflag() == $count) {print "ok 44\n"}
else {
  warn "\n", Math::MPC::nok_pokflag(), " != $count\n";
  print "not ok 44\n";
}

RMPC_RE($check, $ret);

if(Rmpfr_nan_p($check)) {print "ok 45\n"}
else {
  warn "\n Expected NaN\n Got $check\n";
  print "not ok 45\n";
}

$ret = $nan -  Math::MPC->new(1.2);

adj($nan, \$count, 1);

if(Math::MPC::nok_pokflag() == $count) {print "ok 46\n"}
else {
  warn "\n", Math::MPC::nok_pokflag(), " != $count\n";
  print "not ok 46\n";
}

RMPC_RE($check, $ret);

if(Rmpfr_nan_p($check)) {print "ok 47\n"}
else {
  warn "\n Expected NaN\n Got $check\n";
  print "not ok 47\n";
}

$ret = $nan /  Math::MPC->new(1.2);

adj($nan, \$count, 1);

if(Math::MPC::nok_pokflag() == $count) {print "ok 48\n"}
else {
  warn "\n", Math::MPC::nok_pokflag(), " != $count\n";
  print "not ok 48\n";
}

RMPC_RE($check, $ret);

if(Rmpfr_nan_p($check)) {print "ok 49\n"}
else {
  warn "\n Expected NaN\n Got $check\n";
  print "not ok 49\n";
}

$ret = $nan ** Math::MPC->new(1.2);

adj($nan, \$count, 1);

if(Math::MPC::nok_pokflag() == $count) {print "ok 50\n"}
else {
  warn "\n", Math::MPC::nok_pokflag(), " != $count\n";
  print "not ok 50\n";
}

RMPC_RE($check, $ret);

if(Rmpfr_nan_p($check)) {print "ok 51\n"}
else {
  warn "\n Expected NaN\n Got $check\n";
  print "not ok 51\n";
}

Rmpc_set_NV($ret2, 1.2, MPC_RNDNN);
$ret2 *=  $nan;

adj($nan, \$count, 1);

if(Math::MPC::nok_pokflag() == $count) {print "ok 52\n"}
else {
  warn "\n", Math::MPC::nok_pokflag(), " != $count\n";
  print "not ok 52\n";
}

RMPC_RE($check, $ret2);

if(Rmpfr_nan_p($check)) {print "ok 53\n"}
else {
  warn "\n Expected NaN\n Got $check\n";
  print "not ok 53\n";
}

Rmpc_set_NV($ret2, 1.2, MPC_RNDNN);
$ret2 +=  $nan;

adj($nan, \$count, 1);

if(Math::MPC::nok_pokflag() == $count) {print "ok 54\n"}
else {
  warn "\n", Math::MPC::nok_pokflag(), " != $count\n";
  print "not ok 54\n";
}

RMPC_RE($check, $ret2);

if(Rmpfr_nan_p($check)) {print "ok 55\n"}
else {
  warn "\n Expected NaN\n Got $check\n";
  print "not ok 55\n";
}

Rmpc_set_NV($ret2, 1.2, MPC_RNDNN);
$ret2 /=  $nan;

adj($nan, \$count, 1);

if(Math::MPC::nok_pokflag() == $count) {print "ok 56\n"}
else {
  warn "\n", Math::MPC::nok_pokflag(), " != $count\n";
  print "not ok 56\n";
}

RMPC_RE($check, $ret2);

if(Rmpfr_nan_p($check)) {print "ok 57\n"}
else {
  warn "\n Expected NaN\n Got $check\n";
  print "not ok 57\n";
}

Rmpc_set_NV($ret2, 1.2, MPC_RNDNN);
$ret2 -=  $nan;

adj($nan, \$count, 1);

if(Math::MPC::nok_pokflag() == $count) {print "ok 58\n"}
else {
  warn "\n", Math::MPC::nok_pokflag(), " != $count\n";
  print "not ok 58\n";
}

RMPC_RE($check, $ret2);

if(Rmpfr_nan_p($check)) {print "ok 59\n"}
else {
  warn "\n Expected NaN\n Got $check\n";
  print "not ok 59\n";
}

Rmpc_set_NV($ret2, 1.2, MPC_RNDNN);
$ret2 **= $nan;

adj($nan, \$count, 1);

if(Math::MPC::nok_pokflag() == $count) {print "ok 60\n"}
else {
  warn "\n", Math::MPC::nok_pokflag(), " != $count\n";
  print "not ok 60\n";
}

RMPC_RE($check, $ret2);

if(Rmpfr_nan_p($check)) {print "ok 61\n"}
else {
  warn "\n Expected NaN\n Got $check\n";
  print "not ok 61\n";
}

##################################
##################################

$ret = Math::MPC->new(1.2) *  $inf;

adj($inf, \$count, 1);

if(Math::MPC::nok_pokflag() == $count) {print "ok 62\n"}
else {
  warn "\n", Math::MPC::nok_pokflag(), " != $count\n";
  print "not ok 62\n";
}

RMPC_RE($check, $ret);

if(Rmpfr_inf_p($check) && $check > 0) {print "ok 63\n"}
else {
  warn "\n Expected +ve inf\n Got $check\n";
  print "not ok 63\n";
}

$ret = Math::MPC->new(1.2) +  $inf;

adj($inf, \$count, 1);

if(Math::MPC::nok_pokflag() == $count) {print "ok 64\n"}
else {
  warn "\n", Math::MPC::nok_pokflag(), " != $count\n";
  print "not ok 64\n";
}

RMPC_RE($check, $ret);

if(Rmpfr_inf_p($check) && $check > 0) {print "ok 65\n"}
else {
  warn "\n Expected +ve inf\n Got $check\n";
  print "not ok 65\n";
}

$ret = Math::MPC->new(1.2) -  $inf;

adj($inf, \$count, 1);

if(Math::MPC::nok_pokflag() == $count) {print "ok 66\n"}
else {
  warn "\n", Math::MPC::nok_pokflag(), " != $count\n";
  print "not ok 66\n";
}

RMPC_RE($check, $ret);

if(Rmpfr_inf_p($check) && $check < 0) {print "ok 67\n"}
else {
  warn "\n Expected -ve inf\n Got $check\n";
  print "not ok 67\n";
}


$ret = Math::MPC->new(1.2) /  $inf;

adj($inf, \$count, 1);

if(Math::MPC::nok_pokflag() == $count) {print "ok 68\n"}
else {
  warn "\n", Math::MPC::nok_pokflag(), " != $count\n";
  print "not ok 68\n";
}

RMPC_RE($check, $ret);

if(Rmpfr_zero_p($check) && !Rmpfr_signbit($check)) {print "ok 69\n"}
else {
  warn "\n Expected 0\n Got $check\n";
  print "not ok 69\n";
}


$ret = Math::MPC->new(1.2) ** $inf;

adj($inf, \$count, 1);

if(Math::MPC::nok_pokflag() == $count) {print "ok 70\n"}
else {
  warn "\n", Math::MPC::nok_pokflag(), " != $count\n";
  print "not ok 70\n";
}

RMPC_RE($check, $ret);

if(Rmpfr_inf_p($check) && $check > 0) {print "ok 71\n"}
else {
  warn "\n Expected +ve inf\n Got $check\n";
  print "not ok 71\n";
}

$ret = $inf -  Math::MPC->new(1.2);

adj($inf, \$count, 1);

if(Math::MPC::nok_pokflag() == $count) {print "ok 72\n"}
else {
  warn "\n", Math::MPC::nok_pokflag(), " != $count\n";
  print "not ok 72\n";
}

RMPC_RE($check, $ret);

if(Rmpfr_inf_p($check) && $check > 0) {print "ok 73\n"}
else {
  warn "\n Expected +ve inf\n Got $check\n";
  print "not ok 73\n";
}

$ret = $inf /  Math::MPC->new(1.2);

adj($inf, \$count, 1);

if(Math::MPC::nok_pokflag() == $count) {print "ok 74\n"}
else {
  warn "\n", Math::MPC::nok_pokflag(), " != $count\n";
  print "not ok 74\n";
}

RMPC_RE($check, $ret);

if(Rmpfr_inf_p($check) && $check > 0) {print "ok 75\n"}
else {
  warn "\n Expected +ve inf\n Got $check\n";
  print "not ok 75\n";
}

$ret = $inf ** Math::MPC->new(1.2);

adj($inf, \$count, 1);

if(Math::MPC::nok_pokflag() == $count) {print "ok 76\n"}
else {
  warn "\n", Math::MPC::nok_pokflag(), " != $count\n";
  print "not ok 76\n";
}

RMPC_RE($check, $ret);

if(Rmpfr_inf_p($check) && $check > 0) {print "ok 77\n"}
else {
  warn "\n Expected +ve inf\n Got $check\n";
  print "not ok 77\n";
}

Rmpc_set_NV($ret2, 1.2, MPC_RNDNN);
$ret2 *=  $inf;

adj($inf, \$count, 1);

if(Math::MPC::nok_pokflag() == $count) {print "ok 78\n"}
else {
  warn "\n", Math::MPC::nok_pokflag(), " != $count\n";
  print "not ok 78\n";
}

RMPC_RE($check, $ret2);

if(Rmpfr_inf_p($check) && $check > 0) {print "ok 79\n"}
else {
  warn "\n Expected +ve inf\n Got $check\n";
  print "not ok 79\n";
}

Rmpc_set_NV($ret2, 1.2, MPC_RNDNN);
$ret2 +=  $inf;

adj($inf, \$count, 1);

if(Math::MPC::nok_pokflag() == $count) {print "ok 80\n"}
else {
  warn "\n", Math::MPC::nok_pokflag(), " != $count\n";
  print "not ok 80\n";
}

RMPC_RE($check, $ret2);

if(Rmpfr_inf_p($check) && $check > 0) {print "ok 81\n"}
else {
  warn "\n Expected +ve inf\n Got $check\n";
  print "not ok 81\n";
}

Rmpc_set_NV($ret2, 1.2, MPC_RNDNN);
$ret2 /=  $inf;

adj($inf, \$count, 1);

if(Math::MPC::nok_pokflag() == $count) {print "ok 82\n"}
else {
  warn "\n", Math::MPC::nok_pokflag(), " != $count\n";
  print "not ok 82\n";
}

RMPC_RE($check, $ret2);

if(Rmpfr_zero_p($check) && !Rmpfr_signbit($check)) {print "ok 83\n"}
else {
  warn "\n Expected +ve inf\n Got $check\n";
  print "not ok 83\n";
}

Rmpc_set_NV($ret2, 1.2, MPC_RNDNN);
$ret2 -=  $inf;

adj($inf, \$count, 1);

if(Math::MPC::nok_pokflag() == $count) {print "ok 84\n"}
else {
  warn "\n", Math::MPC::nok_pokflag(), " != $count\n";
  print "not ok 84\n";
}

RMPC_RE($check, $ret2);

if(Rmpfr_inf_p($check) && $check < 0) {print "ok 85\n"}
else {
  warn "\n Expected +ve inf\n Got $check\n";
  print "not ok 85\n";
}

Rmpc_set_NV($ret2, 1.2, MPC_RNDNN);
$ret2 **= $inf;

adj($inf, \$count, 1);

if(Math::MPC::nok_pokflag() == $count) {print "ok 86\n"}
else {
  warn "\n", Math::MPC::nok_pokflag(), " != $count\n";
  print "not ok 86\n";
}

RMPC_RE($check, $ret2);

if(Rmpfr_inf_p($check) && $check > 0) {print "ok 87\n"}
else {
  warn "\n Expected +ve inf\n Got $check\n";
  print "not ok 87\n";
}

##################################
##################################

$ret = Math::MPC->new(1.2) *  $ninf;

adj($ninf, \$count, 1);

if(Math::MPC::nok_pokflag() == $count) {print "ok 88\n"}
else {
  warn "\n", Math::MPC::nok_pokflag(), " != $count\n";
  print "not ok 88\n";
}

RMPC_RE($check, $ret);

if(Rmpfr_inf_p($check) && $check < 0) {print "ok 89\n"}
else {
  warn "\n Expected -ve inf\n Got $check\n";
  print "not ok 89\n";
}

$ret = Math::MPC->new(1.2) +  $ninf;

adj($ninf, \$count, 1);

if(Math::MPC::nok_pokflag() == $count) {print "ok 90\n"}
else {
  warn "\n", Math::MPC::nok_pokflag(), " != $count\n";
  print "not ok 90\n";
}

RMPC_RE($check, $ret);

if(Rmpfr_inf_p($check) && $check < 0) {print "ok 91\n"}
else {
  warn "\n Expected -ve inf\n Got $check\n";
  print "not ok 91\n";
}

$ret = Math::MPC->new(1.2) -  $ninf;

adj($ninf, \$count, 1);

if(Math::MPC::nok_pokflag() == $count) {print "ok 92\n"}
else {
  warn "\n", Math::MPC::nok_pokflag(), " != $count\n";
  print "not ok 92\n";
}

RMPC_RE($check, $ret);

if(Rmpfr_inf_p($check) && $check > 0) {print "ok 93\n"}
else {
  warn "\n Expected +ve inf\n Got $check\n";
  print "not ok 93\n";
}

$ret = Math::MPC->new(1.2) /  $ninf;

adj($ninf, \$count, 1);

if(Math::MPC::nok_pokflag() == $count) {print "ok 94\n"}
else {
  warn "\n", Math::MPC::nok_pokflag(), " != $count\n";
  print "not ok 94\n";
}

RMPC_RE($check, $ret);

if(Rmpfr_zero_p($check) && Rmpfr_signbit($check)) {print "ok 95\n"}
else {
  warn "\n Expected -0\n Got $check\n";
  print "not ok 95\n";
}

$ret = Math::MPC->new(1.2) ** $ninf;

adj($ninf, \$count, 1);

if(Math::MPC::nok_pokflag() == $count) {print "ok 96\n"}
else {
  warn "\n", Math::MPC::nok_pokflag(), " != $count\n";
  print "not ok 96\n";
}

RMPC_RE($check, $ret);

if($check == 0 && !Rmpfr_signbit($check)) {print "ok 97\n"}
else {
  warn "\n Expected 0\n Got $check\n";
  print "not ok 97\n";
}

$ret = $ninf -  Math::MPC->new(1.2);

adj($ninf, \$count, 1);

if(Math::MPC::nok_pokflag() == $count) {print "ok 98\n"}
else {
  warn "\n", Math::MPC::nok_pokflag(), " != $count\n";
  print "not ok 98\n";
}

RMPC_RE($check, $ret);

if(Rmpfr_inf_p($check) && $check < 0) {print "ok 99\n"}
else {
  warn "\n Expected -ve inf\n Got $check\n";
  print "not ok 99\n";
}

$ret = $ninf /  Math::MPC->new(1.2);

adj($ninf, \$count, 1);

if(Math::MPC::nok_pokflag() == $count) {print "ok 100\n"}
else {
  warn "\n", Math::MPC::nok_pokflag(), " != $count\n";
  print "not ok 100\n";
}

RMPC_RE($check, $ret);

if(Rmpfr_inf_p($check) && $check < 0) {print "ok 101\n"}
else {
  warn "\n Expected -ve inf\n Got $check\n";
  print "not ok 101\n";
}

$ret = $ninf ** Math::MPC->new(1.2);

adj($ninf, \$count, 1);

if(Math::MPC::nok_pokflag() == $count) {print "ok 102\n"}
else {
  warn "\n", Math::MPC::nok_pokflag(), " != $count\n";
  print "not ok 102\n";
}

RMPC_RE($check, $ret);

if(Rmpfr_inf_p($check) && $check > 0) {print "ok 103\n"}
else {
  warn "\n Expected +ve inf\n Got $check\n";
  print "not ok 103\n";
}

Rmpc_set_NV($ret2, 1.2, MPC_RNDNN);
$ret2 *=  $ninf;

adj($ninf, \$count, 1);

if(Math::MPC::nok_pokflag() == $count) {print "ok 104\n"}
else {
  warn "\n", Math::MPC::nok_pokflag(), " != $count\n";
  print "not ok 104\n";
}

RMPC_RE($check, $ret2);

if(Rmpfr_inf_p($check) && $check < 0) {print "ok 105\n"}
else {
  warn "\n Expected -ve inf\n Got $check\n";
  print "not ok 105\n";
}

Rmpc_set_NV($ret2, 1.2, MPC_RNDNN);
$ret2 +=  $ninf;

adj($ninf, \$count, 1);

if(Math::MPC::nok_pokflag() == $count) {print "ok 106\n"}
else {
  warn "\n", Math::MPC::nok_pokflag(), " != $count\n";
  print "not ok 106\n";
}

RMPC_RE($check, $ret2);

if(Rmpfr_inf_p($check) && $check < 0) {print "ok 107\n"}
else {
  warn "\n Expected -ve inf\n Got $check\n";
  print "not ok 107\n";
}

Rmpc_set_NV($ret2, 1.2, MPC_RNDNN);
$ret2 /=  $ninf;

adj($ninf, \$count, 1);

if(Math::MPC::nok_pokflag() == $count) {print "ok 108\n"}
else {
  warn "\n", Math::MPC::nok_pokflag(), " != $count\n";
  print "not ok 108\n";
}

RMPC_RE($check, $ret2);

if(Rmpfr_zero_p($check) && Rmpfr_signbit($check)) {print "ok 109\n"}
else {
  warn "\n Expected -ve inf\n Got $check\n";
  print "not ok 109\n";
}

Rmpc_set_NV($ret2, 1.2, MPC_RNDNN);
$ret2 -=  $ninf;

adj($ninf, \$count, 1);

if(Math::MPC::nok_pokflag() == $count) {print "ok 110\n"}
else {
  warn "\n", Math::MPC::nok_pokflag(), " != $count\n";
  print "not ok 110\n";
}

RMPC_RE($check, $ret2);

if(Rmpfr_inf_p($check) && $check > 0) {print "ok 111\n"}
else {
  warn "\n Expected +ve inf\n Got $check\n";
  print "not ok 111\n";
}

Rmpc_set_NV($ret2, 1.2, MPC_RNDNN);
$ret2 **= $ninf;

adj($ninf, \$count, 1);

if(Math::MPC::nok_pokflag() == $count) {print "ok 112\n"}
else {
  warn "\n", Math::MPC::nok_pokflag(), " != $count\n";
  print "not ok 112\n";
}

RMPC_RE($check, $ret2);

if($check == 0 && !Rmpfr_signbit($check)) {print "ok 113\n"}
else {
  warn "\n Expected 0\n Got $check\n";
  print "not ok 113\n";
}

###################################
###################################

$ret = (Math::MPC->new(0, '1.3') == $nan);

adj($nan, \$count, 1);

if(Math::MPC::nok_pokflag() == $count) {print "ok 114\n"}
else {
  warn "\n", Math::MPC::nok_pokflag(), " != $count\n";
  print "not ok 114\n";
}

if($ret) {
  warn "\n(0, 1.3) == $nan\n";
  print "not ok 115\n";
}
else {print "ok 115\n"}

$ret = (Math::MPC->new(0, '1.3') != $nan);

adj($nan, \$count, 1);

if(Math::MPC::nok_pokflag() == $count) {print "ok 116\n"}
else {
  warn "\n", Math::MPC::nok_pokflag(), " != $count\n";
  print "not ok 116\n";
}

if(!$ret) {
  warn "\n(0, 1.3) == $nan\n";
  print "not ok 117\n";
}
else {print "ok 117\n"}

$ret = (Math::MPC->new(0, '1.3') == $inf);

adj($inf, \$count, 1);

if(Math::MPC::nok_pokflag() == $count) {print "ok 118\n"}
else {
  warn "\n", Math::MPC::nok_pokflag(), " != $count\n";
  print "not ok 118\n";
}

if($ret) {
  warn "\n(0, 1.3) == $inf\n";
  print "not ok 119\n";
}
else {print "ok 119\n"}

$ret = (Math::MPC->new(0, '1.3') != $inf);

adj($inf, \$count, 1);

if(Math::MPC::nok_pokflag() == $count) {print "ok 120\n"}
else {
  warn "\n", Math::MPC::nok_pokflag(), " != $count\n";
  print "not ok 120\n";
}

if(!$ret) {
  warn "\n(0, 1.3) == $inf\n";
  print "not ok 121\n";
}
else {print "ok 121\n"}

$ret = (Math::MPC->new(0, '1.3') == $ninf);

adj($ninf, \$count, 1);

if(Math::MPC::nok_pokflag() == $count) {print "ok 122\n"}
else {
  warn "\n", Math::MPC::nok_pokflag(), " != $count\n";
  print "not ok 122\n";
}

if($ret) {
  warn "\n(0, 1.3) == $ninf\n";
  print "not ok 123\n";
}
else {print "ok 123\n"}

$ret = (Math::MPC->new(0, '1.3') != $ninf);

adj($ninf, \$count, 1);

if(Math::MPC::nok_pokflag() == $count) {print "ok 124\n"}
else {
  warn "\n", Math::MPC::nok_pokflag(), " != $count\n";
  print "not ok 124\n";
}

if(!$ret) {
  warn "\n(0, 1.3) == $ninf\n";
  print "not ok 125\n";
}
else {print "ok 125\n"}

eval{$ret = Math::MPC::_win32_infnanstring('hello');};

if($^O =~ /MSWin32/i && $] < 5.022) {
  if(!$@ && $ret == 0) {print "ok 126\n"}
  else {
    warn "\n\$\@: $@\n\$ret: $ret\n";
    print "not ok 126\n";
  }
}
else {
  if($@ =~ /^Math::MPC::_win32_infnanstring not implemented/) {print "ok 126\n"}
  else {
    warn "\n\$\@: $@\n";
    print "not ok 126\n";
  }
}

#print Math::MPC::nok_pokflag(), " $count\n";

my $nv = 1.3;
my $s  = "$nv"; # $nv should be POK && NOK if MPC_PV_NV_BUG is 1
                # Else (ie MPC_NV_BUG is 0) and $nv should be POK only.

$z = Math::MPC->new($nv, 0);

if(MPC_PV_NV_BUG) { $count++ }

if(Math::MPC::nok_pokflag() == $count) {print "ok 127\n"}
else {
  warn "\n", Math::MPC::nok_pokflag(), " != $count\n";
  print "not ok 127\n";
}

$z = Math::MPC->new($nv, $nv);

if(MPC_PV_NV_BUG) { $count += 2 }

if(Math::MPC::nok_pokflag() == $count) {print "ok 128\n"}
else {
  warn "\n", Math::MPC::nok_pokflag(), " != $count\n";
  print "not ok 128\n";
}

my $s2 = '1.3';

if($s2 > 0) {  # True
  $z = Math::MPC->new($s2, $s2);

  $count += 2;

  if(Math::MPC::nok_pokflag() == $count) {print "ok 129\n"}
  else {
    warn "\n", Math::MPC::nok_pokflag(), " != $count\n";
    print "not ok 129\n";
  }
}


##########

sub adj {
  if(Math::MPC::_SvNOK($_[0]) && Math::MPC::_SvPOK($_[0])) {
  ${$_[1]} += $_[2];
  }
}
