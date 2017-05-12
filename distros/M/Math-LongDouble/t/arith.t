use warnings;
use strict;
use Math::LongDouble qw(:all);

print "1..20\n";

my $n = Math::LongDouble->new('3.5');
my $unity = UnityLD(1);
my $two = Math::LongDouble::UVtoLD(2);

if(-$unity == UnityLD(-1)) {print "ok 1\n"}
else {print "not ok 1\n"}

$n = $n + $unity;
if($n == Math::LongDouble->new('4.5')){print "ok 2\n"}
else {
  warn "\n\$n: $n\n";
  print "not ok 2\n";
}

$n = $n - $unity;
if($n == Math::LongDouble->new('3.5')){print "ok 3\n"}
else {
  warn "\n\$n: $n\n";
  print "not ok 3\n";
}

$n = $n * $two;
if($n == Math::LongDouble->new('7')){print "ok 4\n"}
else {
  warn "\n\$n: $n\n";
  print "not ok 4\n";
}

$n = $n / $two;
if($n == Math::LongDouble->new('3.5')){print "ok 5\n"}
else {
  warn "\n\$n: $n\n";
  print "not ok 5\n";
}

$n += $unity;
if($n == Math::LongDouble->new('4.5')){print "ok 6\n"}
else {
  warn "\n\$n: $n\n";
  print "not ok 6\n";
}

$n -= $unity;
if($n == Math::LongDouble->new('3.5')){print "ok 7\n"}
else {
  warn "\n\$n: $n\n";
  print "not ok 7\n";
}

$n *= $two;
if($n == Math::LongDouble->new('7')){print "ok 8\n"}
else {
  warn "\n\$n: $n\n";
  print "not ok 8\n";
}

$n /= $two;
if($n == Math::LongDouble->new('3.5')){print "ok 9\n"}
else {
  warn "\n\$n: $n\n";
  print "not ok 9\n";
}

if(signbit_LD(UnityLD(-1))) {print "ok 10\n"}
else {
  warn "\nExpected 1\n Got ", signbit_LD(UnityLD(-1)), "\n";
  print "not ok 10\n";
}

if(signbit_LD(UnityLD(1)) == 0) {print "ok 11\n"}
else {
  warn "\nExpected 0\n Got ", signbit_LD(UnityLD(1)), "\n";
  print "not ok 11\n";
}

my $check  = Math::LongDouble->new();

cbrt_LD($check, NVtoLD(27.0));

if($check == NVtoLD(3.0)) {print "ok 12\n"}
else {
  warn "Looks like another glibc bug. Update glibc if possible\n";
  warn "\nExpected 3.0\nGot $check\n";
  warn "\nExpected ", ld_bytes(Math::LongDouble->new('3.0')), "\nGot ", ld_bytes($check), "\n";
  if(approx(3.0, $check)) {print "ok 12\n"}
  else {print "not ok 12\n"}
}

sqrt_LD($check, NVtoLD(25.0));

if($check == NVtoLD(5.0)) {print "ok 13\n"}
else {
  warn "\nExpected 3.0\nGot $check\n";
  print "not ok 13\n";
}

remainder_LD($check, NVtoLD(28.0), NVtoLD(9.0));
if($check == UnityLD(1)) {print "ok 14\n"}
else {
  warn "\nExpected 1\nGot $check\n";
  print "not ok 14\n";
}

my $check1; # Gets set to an int value that corresponds to the quotient.

# No longer testing remquo_LD as too many compilers give differing results.
#
#remquo_LD($check, $check1, NVtoLD(28.0), NVtoLD(9.0));
#if($check == UnityLD(1) && $check1 == 3) {print "ok 15\n"}
#else {
#  warn "\nExpected remainder of 1\nGot $check\n",
#         "Expected quotient of 3\nGot $check1\n";
#  print "not ok 15\n";
#}

print "ok 15\n"; # There is currently no test 15

fmod_LD($check, NVtoLD(28.0), NVtoLD(9.0));
if($check == UnityLD(1)) {print "ok 16\n"}
else {
  warn "\nExpected 1\nGot $check\n";
  print "not ok 16\n";
}

my $ld = NVtoLD(2.5);

fmax_LD($check, $ld, -$ld);

if($check == $ld) {print "ok 17\n"}
else {
  warn "\nExpected $ld\nGot $check\n";
  print "not ok 17\n";
}

fmin_LD($check, $ld, -$ld);

if($check == -$ld) {print "ok 18\n"}
else {
  warn "\nExpected -$ld\nGot $check\n";
  print "not ok 18\n";
}

fdim_LD($check, $ld, -$ld);

if($check == $ld * IVtoLD(2)) {print "ok 19\n"}
else {
  warn "\nExpected ", $ld * IVtoLD(2), "\nGot $check\n";
  print "not ok 19\n";
}

fdim_LD($check, -$ld, $ld);

if(!$check) {print "ok 20\n"}
else {
  warn "\nExpected 0\nGot $check\n";
  print "not ok 20\n";
}

########################################################

sub approx {
    my $eps = abs($_[0] - Math::LongDouble->new($_[1]));
    return 0 if  $eps > Math::LongDouble->new(0.000000001);
    return 1;
}

