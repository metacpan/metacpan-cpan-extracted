use warnings;
use strict;
use Math::Float128 qw(:all);
use Config;

print "1..19\n";

my $n = 1.3;
my $nld = Math::Float128->new(1.3);

my $exp = exp($n);
my $exp_ld = exp($nld);
my $log_ld = log($exp_ld);
my $two = Math::Float128->new(2.0);
my $log = log($two);

# Try to determine when the decimal point is a comma,
# and set $dp accordingly.
my $dp = '.';
$dp = ',' unless Math::Float128->new('0,5') == Math::Float128->new(0);

if(approx($exp_ld, $exp)) {print "ok 1\n"}
else {
  warn "\n\$exp_ld: $exp_ld\n\$exp: $exp\n";
  print "not ok 1\n";
}

if(approx($log_ld, $n)) {print "ok 2\n"}
else {
  warn "\n\$log_ld: $log_ld\n\$n: $n\n";
  print "not ok 2\n";
}

if(is_InfF128(log(ZeroF128(1)))) {print "ok 3\n"}
else {
  warn "\nlog(0): ", log(ZeroF128(1)), "\n";
  print "not ok 3\n";
}

if(is_NaNF128(log(UnityF128(-1)))) {print "ok 4\n"}
else {
  warn "\nlog(-1): ", log(UnityF128(-1)), "\n";
  print "not ok 4\n";
}

if(cmp2NV($log, log(2.0)) && $Config{nvtype} ne '__float128') {print "ok 5\n"}
elsif(!cmp2NV($log, log(2.0)) && $Config{nvtype} eq '__float128') {print "ok 5\n"}
else {
  warn "\n\$log: ", log($two), "\nlog(2.0): ", log(2.0), "\n";
  print "not ok 5\n";
}

if(approx($log, Math::Float128->new("6${dp}9314718055994530943e-001"))) {print "ok 6\n"}
else {
  warn "\n\$log: $log\n";
  print "not ok 6\n";
}

if(cmp2NV($exp_ld, $exp) && $Config{nvtype} ne '__float128') {print "ok 7\n"}
elsif(!cmp2NV($exp_ld, $exp) && $Config{nvtype} eq '__float128') {print "ok 7\n"}
else {
  warn "\n\$exp_ld: $exp_ld\n\$exp: $exp\n";
  print "not ok 7\n";
}

my $check = NaNF128();

exp_F128($check, IVtoF128(0));

if($check == UnityF128(1)) {print "ok 8\n"}
else {
  warn "\nExpected 1\nGot $check\n";
  print "not ok 8\n";
}

expm1_F128($check, IVtoF128(0));

if(!$check) {print "ok 9\n"}
else {
  warn "\nExpected 0\nGot $check\n";
  print "not ok 9\n";
}

my $iv_ret;

# $check * (2 ** $iv_ret) == -543.25
frexp_F128($check, $iv_ret, NVtoF128(-543.25));

if($check == NVtoF128(-0.530517578125) && $iv_ret == 10) {print "ok 10\n"}
else {
  warn "\nExpected fraction to be -0.530517578125\nGot $check\n",
         "Expected exponent to be 10\nGot $iv_ret\n";
  print "not ok 10\n";
}

# $check == -543.25 * (2 ** 10)
ldexp_F128($check, NVtoF128(-543.25), 10);

if($check == IVtoF128(-556288)) {print "ok 11\n"}
else {
  warn "\nExpected ??\nGot $check\n";
  print "not ok 11\n";
}

# Looks at the float value in its normalised base representation
# (1.bbb...eX) and returns the value of the exponent (X).
$iv_ret = ilogb_F128(NVtoF128(-0.00017));

if($iv_ret == -13) {print "ok 12\n"}
else {
  warn "\nExpected -13\nGot $iv_ret\n";
  print "not ok 12\n";
}

log2_F128($check, NVtoF128(2));
if($check == UnityF128(1)) {print "ok 13\n"}
else {
  warn "\nExpected 1\nGot $check\n";
  print "not ok 13\n";
}

log10_F128($check, NVtoF128(10));
if($check == UnityF128(1)) {print "ok 14\n"}
else {
  warn "\nExpected 1\nGot $check\n";
  print "not ok 14\n";
}

log_F128($check, NVtoF128(1));
if($check == ZeroF128(1)) {print "ok 15\n"}
else {
  warn "\nExpected 0\nGot $check\n";
  print "not ok 15\n";
}

log1p_F128($check, NVtoF128(0));
if($check == ZeroF128(1)) {print "ok 16\n"}
else {
  warn "\nExpected 0\nGot $check\n";
  print "not ok 16\n";
}

pow_F128($check, NVtoF128(3), NVtoF128(4));

if($check == NVtoF128(81)) {print "ok 17\n"}
else {
  warn "\nExpected 82\nGot $check\n";
  print "not ok 17\n";
}

# Guess that FLT_RADIX is 2 if it's not defined.
my $flt_radix = Math::Float128::_flt_radix() || 2;


scalbln_F128($check, NVtoF128(-543.25), 5);
if(approx($check, -543.25 * ($flt_radix ** 5))) {print "ok 18\n"}
else {
  warn "\nExpected approx ", -543.25 * ($flt_radix ** 5), "\nGot $check\n",
        " FLT_RADIX: $flt_radix\n";
  print "not ok 18\n";
}

scalbn_F128($check, NVtoF128(-543.25), 5);
if(approx($check, -543.25 * ($flt_radix ** 5))) {print "ok 19\n"}
else {
  warn "\nExpected approx ", -543.25 * ($flt_radix ** 5), "\nGot $check\n",
        " FLT_RADIX: $flt_radix\n";
  print "not ok 19\n";
}


sub approx {
    my $eps = abs($_[0] - Math::Float128->new($_[1]));
    return 0 if $eps > Math::Float128->new(0.000000001);
    return 1;
}
