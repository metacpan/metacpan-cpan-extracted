use strict;
use warnings;
use Math::Float128 qw(:all);

print "1..23\n";

# Try to determine when the decimal point is a comma,
# and set $dp accordingly.
my $dp = '.';
$dp = ',' unless Math::Float128->new('0,5') == Math::Float128->new(0);

my $ret;
my $eps = ZeroF128(-1);#STRtoF128('1e-33');

#if(113 == FLT128_MANT_DIG) {print "ok 1\n"}

eval {$ret = FLT128_MANT_DIG};
if(!$@ && $ret == 113) {print "ok 1\n"}
elsif($@ =~ /not implemented/) {
  warn "FLT128_MANT_DIG not implemented\n";
  print "ok 1\n";
}
else {
  warn "FLT128_MANT_DIG: ", FLT128_MANT_DIG, "\n";
  print "not ok 1\n";
}

#if(-16381 == FLT128_MIN_EXP) {print "ok 2\n"}

eval {$ret = FLT128_MIN_EXP};
if(!$@ && $ret == -16381) {print "ok 2\n"}
elsif($@ =~ /not implemented/) {
  warn "FLT128_MIN_EXP not implemented\n";
  print "ok 2\n";
}
else {
  warn "FLT128_MIN_EXP: ", FLT128_MIN_EXP, "\n";
  print "not ok 2\n";
}

#if(16384 == FLT128_MAX_EXP) {print "ok 3\n"}

eval {$ret = FLT128_MAX_EXP};
if(!$@ && $ret == 16384) {print "ok 3\n"}
elsif($@ =~ /not implemented/) {
  warn "FLT128_MAX_EXP not implemented\n";
  print "ok 3\n";
}
else {
  warn "FLT128_MAX_EXP: ", FLT128_MAX_EXP, "\n";
  print "not ok 3\n";
}

#if(-4931 == FLT128_MIN_10_EXP) {print "ok 4\n"}

eval {$ret = FLT128_MIN_10_EXP};
if(!$@ && $ret == -4931) {print "ok 4\n"}
elsif($@ =~ /not implemented/) {
  warn "FLT128_MIN_10_EXP not implemented\n";
  print "ok 4\n";
}
else {
  warn "FLT128_MIN_10_EXP: ", FLT128_MIN_10_EXP, "\n";
  print "not ok 4\n";
}

#if(4932 == FLT128_MAX_10_EXP) {print "ok 5\n"}

eval {$ret = FLT128_MAX_10_EXP};
if(!$@ && $ret == 4932) {print "ok 5\n"}
elsif($@ =~ /not implemented/) {
  warn "FLT128_MAX_10_EXP not implemented\n";
  print "ok 5\n";
}
else {
  warn "FLT128_MAX_10_EXP: ", FLT128_MAX_10_EXP, "\n";
  print "not ok 5\n";
}

if(abs(STRtoF128("2${dp}7182818284590452353602874713526625") - (M_Eq)) <= $eps) {print "ok 6\n"}
else {
  warn "M_Eq: ", M_Eq, "\n";
  print "not ok 6\n";
}

if(abs(STRtoF128("1${dp}4426950408889634073599246810018921") - (M_LOG2Eq)) <= $eps) {print "ok 7\n"}
else {
  warn "M_LOG2Eq: ", M_LOG2Eq, "\n";
  print "not ok 7\n";
}

if(abs(STRtoF128("0${dp}4342944819032518276511289189166051") - (M_LOG10Eq)) <= $eps) {print "ok 8\n"}
else {
  warn "M_LOG10Eq: ", M_LOG10Eq, "\n";
  print "not ok 8\n";
}

if(abs(STRtoF128("0${dp}6931471805599453094172321214581766") - (M_LN2q)) <= $eps) {print "ok 9\n"}
else {
  warn "M_LN2q: ", M_LN2q, "\n";
  print "not ok 9\n";
}

if(abs(STRtoF128("2${dp}3025850929940456840179914546843642") - (M_LN10q)) <= $eps) {print "ok 10\n"}
else {
  warn "M_LN10q: ", M_LN10q, "\n";
  print "not ok 10\n";
}

if(abs(STRtoF128("3${dp}1415926535897932384626433832795029") - (M_PIq)) <= $eps) {print "ok 11\n"}
else {
  warn "M_PIq: ", M_PIq, "\n";
  print "not ok 11\n";
}

if(abs(STRtoF128("1${dp}5707963267948966192313216916397514") - (M_PI_2q)) <= $eps) {print "ok 12\n"}
else {
  warn "M_PI_2q: ", M_PI_2q, "\n";
  print "not ok 12\n";
}

if(abs(STRtoF128("0${dp}7853981633974483096156608458198757") - (M_PI_4q)) <= $eps) {print "ok 13\n"}
else {
  warn "M_PI_4q: ", M_PI_4q, "\n";
  print "not ok 13\n";
}

if(abs(STRtoF128("0${dp}3183098861837906715377675267450287") - (M_1_PIq)) <= $eps) {print "ok 14\n"}
else {
  warn "M_1_PIq: ", M_1_PIq, "\n";
  print "not ok 14\n";
}

if(abs(STRtoF128("0${dp}6366197723675813430755350534900574") - (M_2_PIq)) <= $eps) {print "ok 15\n"}
else {
  warn "M_2_PIq: ", M_2_PIq, "\n";
  print "not ok 15\n";
}

if(abs(STRtoF128("1${dp}1283791670955125738961589031215452") - (M_2_SQRTPIq)) <= $eps) {print "ok 16\n"}
else {
  warn "M_2_SQRTPIq: ", M_2_SQRTPIq, "\n";
  print "not ok 16\n";
}

if(abs(STRtoF128("1${dp}4142135623730950488016887242096981") - (M_SQRT2q)) <= $eps) {print "ok 17\n"}
else {
  warn "M_SQRT2q: ", M_SQRT2q, "\n";
  print "not ok 17\n";
}

if(abs(STRtoF128("0${dp}7071067811865475244008443621048490") - (M_SQRT1_2q)) <= $eps) {print "ok 18\n"}
else {
  warn "M_SQRT1_2q: ", M_SQRT1_2q, "\n";
  print "not ok 18\n";
}

#if(abs(STRtoF128("1${dp}18973149535723176508575932662800702e+4932") - (FLT128_MAX)) <= $eps) {print "ok 19\n"}

$ret = abs(STRtoF128("1${dp}18973149535723176508575932662800702e+4932") - (FLT128_MAX));
if(!$@ && $ret <= $eps) {print "ok 19\n"}
elsif($@ =~ /not implemented/) {
  warn "FLT128_MAX not implemented\n";
  print "ok 19\n";
}
else {
  warn "FLT128_MAX: ", FLT128_MAX, "\n";
  print "not ok 19\n";
}

#if(abs(STRtoF128("3${dp}36210314311209350626267781732175260e-4932") - (FLT128_MIN)) <= $eps) {print "ok 20\n"}

$ret = abs(STRtoF128("3${dp}36210314311209350626267781732175260e-4932") - (FLT128_MIN));
if(!$@ && $ret <= $eps) {print "ok 20\n"}
elsif($@ =~ /not implemented/) {
  warn "FLT128_MIN not implemented\n";
  print "ok 20\n";
}
else {
  warn "FLT128_MIN: ", FLT128_MIN, "\n";
  print "not ok 20\n";
}

#if(abs(STRtoF128("1${dp}92592994438723585305597794258492732e-34") - (FLT128_EPSILON)) <= $eps) {print "ok 21\n"}

$ret = abs(STRtoF128("1${dp}92592994438723585305597794258492732e-34") - (FLT128_EPSILON));
if(!$@ && $ret <= $eps) {print "ok 21\n"}
elsif($@ =~ /not implemented/) {
  warn "FLT128_EPSILON not implemented\n";
  print "ok 21\n";
}
else {
  warn "FLT128_EPSILON: ", FLT128_EPSILON, "\n";
  print "not ok 21\n";
}

#if(abs(STRtoF128("6${dp}475175119438025110924438958227646552e-4966") - (FLT128_DENORM_MIN)) <= $eps) {print "ok 22\n"}

$ret = abs(STRtoF128("6${dp}475175119438025110924438958227646552e-4966") - (FLT128_DENORM_MIN));
if(!$@ && $ret <= $eps) {print "ok 22\n"}
elsif($@ =~ /not implemented/) {
  warn "FLT128_DENORM_MIN not implemented\n";
  print "ok 22\n";
}
else {
  warn "FLT128_DENORM_MIN: ", FLT128_DENORM_MIN, "\n";
  print "not ok 22\n";
}

#if(33 == FLT128_DIG) {print "ok 23\n"}

eval {$ret = FLT128_DIG};
if(!$@ && $ret == 33) {print "ok 23\n"}
elsif($@ =~ /not implemented/) {
  warn "FLT128_DIG not implemented\n";
  print "ok 23\n";
}
else {
  warn "FLT128_DIG: ", FLT128_DIG, "\n";
  print "not ok 23\n";
}
