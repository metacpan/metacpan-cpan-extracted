use warnings;
use strict;
use Math::Float128 qw(:all);
use Config;

print "1..20\n";

# Check for mingw64 gcc-4.9.2 bug that casts long double inf to __float128 nan.

my $nv = 99**99**99**99;
my $bugtest = NVtoF128($nv);

if($nv == $nv && ($nv - $nv) != ($nv - $nv) && is_NaNF128($bugtest)) {
  warn "\nIgnoring compiler bug that has cast $Config{nvtype} inf to __float128 nan\n";
}

# Try to determine when the decimal point is a comma,
# and set $dp accordingly.
my $dp = '.';
$dp = ',' unless Math::Float128->new('0,5') == Math::Float128->new(0);

#print "\$dp: $dp\n";

my $n = Math::Float128->new("3${dp}5");
my $unity = UnityF128(1);
my $two = Math::Float128::UVtoF128(2);

if(-$unity == UnityF128(-1)) {print "ok 1\n"}
else {print "not ok 1\n"}

$n = $n + $unity;
if($n == Math::Float128->new("4${dp}5")){print "ok 2\n"}
else {
  warn "\n\$n: $n\n";
  print "not ok 2\n";
}

$n = $n - $unity;
if($n == Math::Float128->new("3${dp}5")){print "ok 3\n"}
else {
  warn "\n\$n: $n\n";
  print "not ok 3\n";
}

$n = $n * $two;

if($n == Math::Float128->new('7')){print "ok 4\n"}
else {
  warn "\n\$n: $n\n";
  print "not ok 4\n";
}

$n = $n / $two;
if($n == Math::Float128->new("3${dp}5")){print "ok 5\n"}
else {
  warn "\n\$n: $n\n";
  print "not ok 5\n";
}

$n += $unity;
if($n == Math::Float128->new("4${dp}5")){print "ok 6\n"}
else {
  warn "\n\$n: $n\n";
  print "not ok 6\n";
}

$n -= $unity;
if($n == Math::Float128->new("3${dp}5")){print "ok 7\n"}
else {
  warn "\n\$n: $n\n";
  print "not ok 7\n";
}

$n *= $two;
if($n == Math::Float128->new('7')){print "ok 8\n"}
else {
  warn "\n\$n: $n\n";
  print "not ok 8\n";
}

$n /= $two;
if($n == Math::Float128->new("3${dp}5")){print "ok 9\n"}
else {
  warn "\n\$n: $n\n";
  print "not ok 9\n";
}

if(signbit_F128(UnityF128(-1)) == 1) {print "ok 10\n"}
else {
  warn "\nExpected 1\n Got ", signbit_F128(UnityF128(-1)), "\n";
  print "not ok 10\n";
}

if(signbit_F128(UnityF128(1)) == 0) {print "ok 11\n"}
else {
  warn "\nExpected 0\n Got ", signbit_F128(UnityF128(1)), "\n";
  print "not ok 11\n";
}

my $check  = Math::Float128->new();

cbrt_F128($check, NVtoF128(27.0));

if($check == NVtoF128(3.0)) {print "ok 12\n"}
else {
  warn "\nExpected 3.0\nGot $check\n";
  print "not ok 12\n";
}

sqrt_F128($check, NVtoF128(25.0));

if($check == NVtoF128(5.0)) {print "ok 13\n"}
else {
  warn "\nExpected 3.0\nGot $check\n";
  print "not ok 13\n";
}

remainder_F128($check, NVtoF128(28.0), NVtoF128(9.0));
if($check == UnityF128(1)) {print "ok 14\n"}
else {
  warn "\nExpected 1\nGot $check\n";
  print "not ok 14\n";
}

my $check1; # Gets set to an int value that corresponds to the quotient.

remquo_F128($check, $check1, NVtoF128(28.0), NVtoF128(9.0));
if($check == UnityF128(1) && $check1 == 3) {print "ok 15\n"}
else {
  warn "\nExpected remainder of 1\nGot $check\n",
         "Expected quotient of 3\nGot $check1\n";
  print "not ok 15\n";
}

fmod_F128($check, NVtoF128(28.0), NVtoF128(9.0));
if($check == UnityF128(1)) {print "ok 16\n"}
else {
  warn "\nExpected 1\nGot $check\n";
  print "not ok 16\n";
}

my $ld = NVtoF128(2.5);

fmax_F128($check, $ld, -$ld);

if($check == $ld) {print "ok 17\n"}
else {
  warn "\nExpected $ld\nGot $check\n";
  print "not ok 17\n";
}

fmin_F128($check, $ld, -$ld);

if($check == -$ld) {print "ok 18\n"}
else {
  warn "\nExpected -$ld\nGot $check\n";
  print "not ok 18\n";
}

fdim_F128($check, $ld, -$ld);

if($check == $ld * IVtoF128(2)) {print "ok 19\n"}
else {
  warn "\nExpected ", $ld * IVtoF128(2), "\nGot $check\n";
  print "not ok 19\n";
}

fdim_F128($check, -$ld, $ld);

if(!$check) {print "ok 20\n"}
else {
  warn "\nExpected 0\nGot $check\n";
  print "not ok 20\n";
}
