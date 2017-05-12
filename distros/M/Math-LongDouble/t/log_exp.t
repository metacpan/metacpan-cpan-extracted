use warnings;
use strict;
use Math::LongDouble qw(:all);
use Config;

print "1..19\n";

my $n = 1.3;
my $nld = Math::LongDouble->new(1.3);

my $exp = exp($n);
my $exp_ld = exp($nld);
my $log_ld = log($exp_ld);
my $two = Math::LongDouble->new(2.0);
my $log = log($two);

if(approx($exp_ld, $exp, -50)) {print "ok 1\n"}
else {
  warn "\n\$exp_ld: $exp_ld\n\$exp: $exp\n";
  print "not ok 1\n";
}

if(approx($log_ld, $n, -50)) {print "ok 2\n"}
else {
  warn "\n\$log_ld: $log_ld\n\$n: $n\n";
  print "not ok 2\n";
}

if(is_InfLD(log(ZeroLD(1)))) {print "ok 3\n"}
else {
  warn "\nlog(0): ", log(ZeroLD(1)), "\n";
  print "not ok 3\n";
}

if(is_NaNLD(log(UnityLD(-1)))) {print "ok 4\n"}
else {
  warn "\nlog(-1): ", log(UnityLD(-1)), "\n";
  print "not ok 4\n";
}

if(Math::LongDouble::_long_double_size() != $Config{nvsize}) {
  if(cmp_NV($log, log(2.0))) {print "ok 5\n"}
  else {
    warn "\n\$log: ", log($two), "\nlog(2.0): ", log(2.0), "\n";
    print "not ok 5\n";
  }
}
else {
  unless(cmp_NV($log, log(2.0))) {print "ok 5\n"}
  else {
    warn "\n\$log: ", log($two), "\nlog(2.0): ", log(2.0), "\n";
    print "not ok 5\n";
  }
}

if(approx($log, Math::LongDouble->new('6.9314718055994530943e-001'), -50)) {print "ok 6\n"}
else {
  warn "\n\$log: $log\n";
  print "not ok 6\n";
}

my $compare = cmp_NV($exp_ld, $exp);

if(Math::LongDouble::_long_double_size() != $Config{nvsize} || ($Config{nvtype} eq '__float128' && LD_LDBL_MANT_DIG != 113)) {
  if($compare) {print "ok 7\n"}
  else {
    warn "\n\$compare: $compare\n";
    warn "\$exp_ld: $exp_ld\n\$exp: $exp\n";
    print "not ok 7\n";
  }
}
else {
  unless($compare) {print "ok 7\n"}
  else {
    warn "\n\$compare: $compare\n";
    warn "\$exp_ld: $exp_ld\n\$exp: $exp\n";
    print "not ok 7\n";
  }
}

my $check = NaNLD();

exp_LD($check, IVtoLD(0));

if($check == UnityLD(1)) {print "ok 8\n"}
else {
  warn "\nExpected 1\nGot $check\n";
  print "not ok 8\n";
}

expm1_LD($check, IVtoLD(0));

if(!$check) {print "ok 9\n"}
else {
  warn "\nExpected 0\nGot $check\n";
  print "not ok 9\n";
}

my $iv_ret;

# $check * (2 ** $iv_ret) == -543.25
frexp_LD($check, $iv_ret, NVtoLD(-543.25));

if($check == NVtoLD(-0.530517578125) && $iv_ret == 10) {print "ok 10\n"}
else {
  warn "\nExpected fraction to be -0.530517578125\nGot $check\n",
         "Expected exponent to be 10\nGot $iv_ret\n";
  print "not ok 10\n";
}

# $check == -543.25 * (2 ** 10)
ldexp_LD($check, NVtoLD(-543.25), 10);

if($check == IVtoLD(-556288)) {print "ok 11\n"}
else {
  warn "\nExpected ??\nGot $check\n";
  print "not ok 11\n";
}

# Looks at the float value in its normalised base representation
# (1.bbb...eX) and returns the value of the exponent (X).
$iv_ret = ilogb_LD(NVtoLD(-0.00017));

if($iv_ret == -13) {print "ok 12\n"}
else {
  warn "\nExpected -13\nGot $iv_ret\n";
  print "not ok 12\n";
}

log2_LD($check, NVtoLD(2));
if($check == UnityLD(1)) {print "ok 13\n"}
else {
  warn "\nExpected 1\nGot $check\n";
  print "not ok 13\n";
}

# powerpc requires some leeway here. The compile-time rendition of log10l(10.0)
# yields a precise result, but the runtime rendition of log10l(10.0) does not.

log10_LD($check, NVtoLD(10.0));
if(approx($check, NVtoLD(1.0), -106)) {print "ok 14\n"}
else {
  warn "\nExpected ", NVtoLD(1.0), " (", ld_bytes(NVtoLD(1.0)), ")\nGot $check (", ld_bytes($check), ")\n";
  print "not ok 14\n";
}

log_LD($check, NVtoLD(1));
if($check == ZeroLD(1)) {print "ok 15\n"}
else {
  warn "\nExpected 0\nGot $check\n";
  print "not ok 15\n";
}

log1p_LD($check, NVtoLD(0));
if($check == ZeroLD(1)) {print "ok 16\n"}
else {
  warn "\nExpected 0\nGot $check\n";
  print "not ok 16\n";
}

# powerpc requires some leeway here (gcc-4.6.3). The compile-time rendition of powl(3.0. 4.0)
# yields a precise result, but the runtime rendition of powl(3.0, 4.0) does not.

pow_LD($check, NVtoLD(3), NVtoLD(4));
if(approx($check, NVtoLD(81.0), -104)) {print "ok 17\n"}
else {
  warn "\nExpected ", NVtoLD(81.0), " (", ld_bytes(NVtoLD(81.0)), ")\nGot $check (", ld_bytes($check), ")\n";
  print "not ok 17\n";
}

# Guess that FLT_RADIX is 2 if it's not defined.
my $flt_radix = Math::LongDouble::_flt_radix() || 2;


scalbln_LD($check, NVtoLD(-543.25), 5);
if(approx($check, -543.25 * ($flt_radix ** 5), -50)) {print "ok 18\n"}
else {
  warn "\nExpected approx ", -543.25 * ($flt_radix ** 5), "\nGot $check\n",
        " FLT_RADIX: $flt_radix\n";
  print "not ok 18\n";
}

scalbn_LD($check, NVtoLD(-543.25), 5);
if(approx($check, -543.25 * ($flt_radix ** 5), -50)) {print "ok 19\n"}
else {
  warn "\nExpected approx ", -543.25 * ($flt_radix ** 5), "\nGot $check\n",
        " FLT_RADIX: $flt_radix\n";
  print "not ok 19\n";
}


sub approx {
    my $eps = abs($_[0] - Math::LongDouble->new($_[1]));
    return 0 if $eps > 2 ** $_[2];
    return 1;
}


