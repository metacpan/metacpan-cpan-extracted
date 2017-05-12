use strict;
use warnings;
use Math::LongDouble qw(:all);

print "1..31\n";

# Try to determine when the decimal point is a comma,
# and set $dp accordingly.
my $dp = '.';
$dp = ',' unless Math::LongDouble->new('0,5') == Math::LongDouble->new(0);

my ($ret, $ret1, $ret2);
my $eps = STRtoLD('1e-15');

#if(xxx == LD_DBL_MANT_DIG) {print "ok 1\n"}

eval {$ret = LD_DBL_MANT_DIG};
if(!$@ && $ret >= 53 && $ret <= 113) {print "ok 1\n"}
elsif($@ =~ /not implemented/) {
  warn "\nLD_DBL_MANT_DIG not implemented\n";
  print "ok 1\n";
}
else {
  warn "\nLD_DBL_MANT_DIG: ", LD_DBL_MANT_DIG, "\n";
  print "not ok 1\n";
}

eval {$ret = LD_LDBL_MANT_DIG};
if(!$@ && $ret >= 53 && $ret <= 113) {print "ok 2\n"}
elsif($@ =~ /not implemented/) {
  warn "\nLD_LDBL_MANT_DIG not implemented\n";
  print "ok 2\n";
}
else {
  warn "\nLD_LDBL_MANT_DIG: ", LD_LDBL_MANT_DIG, "\n";
  print "not ok 2\n";
}

#if(xxxx == LD_DBL_MIN_EXP) {print "ok 3\n"}

eval {$ret = LD_DBL_MIN_EXP};
if(!$@ && $ret >= -16381 && $ret <= -1021) {print "ok 3\n"}
elsif($@ =~ /not implemented/) {
  warn "\nLD_DBL_MIN_EXP not implemented\n";
  print "ok 3\n";
}
else {
  warn "\nLD_DBL_MIN_EXP: ", LD_DBL_MIN_EXP, "\n";
  print "not ok 3\n";
}

eval {$ret = LD_LDBL_MIN_EXP};
if(!$@ && $ret >= -16381 && $ret <= -968) {print "ok 4\n"}
elsif($@ =~ /not implemented/) {
  warn "\nLD_LDBL_MIN_EXP not implemented\n";
  print "ok 4\n";
}
else {
  warn "\nLD_LDBL_MIN_EXP: ", LD_LDBL_MIN_EXP, "\n";
  print "not ok 4\n";
}

#if(xxxx == LD_DBL_MAX_EXP) {print "ok 5\n"}

eval {$ret = LD_DBL_MAX_EXP};
if(!$@ && $ret <= 16384 && $ret >= 1024) {print "ok 5\n"}
elsif($@ =~ /not implemented/) {
  warn "\nLD_DBL_MAX_EXP not implemented\n";
  print "ok 5\n";
}
else {
  warn "\nLD_DBL_MAX_EXP: ", LD_DBL_MAX_EXP, "\n";
  print "not ok 5\n";
}

eval {$ret = LD_LDBL_MAX_EXP};
if(!$@ && $ret <= 16384 && $ret >= 1024) {print "ok 6\n"}
elsif($@ =~ /not implemented/) {
  warn "\nLD_LDBL_MAX_EXP not implemented\n";
  print "ok 6\n";
}
else {
  warn "\nLD_LDBL_MAX_EXP: ", LD_LDBL_MAX_EXP, "\n";
  print "not ok 6\n";
}

#if(xxxx == LD_DBL_MIN_10_EXP) {print "ok 7\n"}

eval {$ret = LD_DBL_MIN_10_EXP};
if(!$@ && $ret >= -4931 && $ret <= -307) {print "ok 7\n"}
elsif($@ =~ /not implemented/) {
  warn "\nLD_DBL_MIN_10_EXP not implemented\n";
  print "ok 7\n";
}
else {
  warn "\nLD_DBL_MIN_10_EXP: ", LD_DBL_MIN_10_EXP, "\n";
  print "not ok 7\n";
}

eval {$ret = LD_LDBL_MIN_10_EXP};
if(!$@ && $ret >= -4931 && $ret <= -291) {print "ok 8\n"}
elsif($@ =~ /not implemented/) {
  warn "\nLD_LDBL_MIN_10_EXP not implemented\n";
  print "ok 8\n";
}
else {
  warn "\nLD_LDBL_MIN_10_EXP: ", LD_LDBL_MIN_10_EXP, "\n";
  print "not ok 8\n";
}

#if(xxxx == LD_DBL_MAX_10_EXP) {print "ok 9\n"}

eval {$ret = LD_DBL_MAX_10_EXP};
if(!$@ && $ret <= 4932 && $ret >= 308) {print "ok 9\n"}
elsif($@ =~ /not implemented/) {
  warn "\nLD_DBL_MAX_10_EXP not implemented\n";
  print "ok 9\n";
}
else {
  warn "\nLD_DBL_MAX_10_EXP: ", LD_DBL_MAX_10_EXP, "\n";
  print "not ok 9\n";
}

eval {$ret = LD_LDBL_MAX_10_EXP};
if(!$@ && $ret <= 4932 && $ret >= 308) {print "ok 10\n"}
elsif($@ =~ /not implemented/) {
  warn "\nLD_LDBL_MAX_10_EXP not implemented\n";
  print "ok 10\n";
}
else {
  warn "\nLD_LDBL_MAX_10_EXP: ", LD_LDBL_MAX_10_EXP, "\n";
  print "not ok 10\n";
}

if(abs(STRtoLD("2${dp}7182818284590452354") - (M_El)) <= $eps) {print "ok 11\n"}
else {
  warn "\nM_El: ", M_El, "\n";
  print "not ok 11\n";
}

if(abs(STRtoLD("1${dp}4426950408889634074") - (M_LOG2El)) <= $eps) {print "ok 12\n"}
else {
  warn "\nM_LOG2El: ", M_LOG2El, "\n";
  print "not ok 12\n";
}

if(abs(STRtoLD("0${dp}43429448190325182765") - (M_LOG10El)) <= $eps) {print "ok 13\n"}
else {
  warn "\nM_LOG10El: ", M_LOG10El, "\n";
  print "not ok 13\n";
}

if(abs(STRtoLD("0${dp}69314718055994530942") - (M_LN2l)) <= $eps) {print "ok 14\n"}
else {
  warn "\nM_LN2l: ", M_LN2l, "\n";
  print "not ok 14\n";
}

if(abs(STRtoLD("2${dp}30258509299404568402") - (M_LN10l)) <= $eps) {print "ok 15\n"}
else {
  warn "\nM_LN10l: ", M_LN10l, "\n";
  print "not ok 15\n";
}

if(abs(STRtoLD("3${dp}14159265358979323846") - (M_PIl)) <= $eps) {print "ok 16\n"}
else {
  warn "\nM_PIl: ", M_PIl, "\n";
  print "not ok 16\n";
}

if(abs(STRtoLD("1${dp}57079632679489661923") - (M_PI_2l)) <= $eps) {print "ok 17\n"}
else {
  warn "\nM_PI_2l: ", M_PI_2l, "\n";
  print "not ok 17\n";
}

if(abs(STRtoLD("0${dp}78539816339744830962") - (M_PI_4l)) <= $eps) {print "ok 18\n"}
else {
  warn "\nM_PI_4l: ", M_PI_4l, "\n";
  print "not ok 18\n";
}

if(abs(STRtoLD("0${dp}31830988618379067154") - (M_1_PIl)) <= $eps) {print "ok 19\n"}
else {
  warn "\nM_1_PIl: ", M_1_PIl, "\n";
  print "not ok 19\n";
}

if(abs(STRtoLD("0${dp}63661977236758134308") - (M_2_PIl)) <= $eps) {print "ok 20\n"}
else {
  warn "\nM_2_PIl: ", M_2_PIl, "\n";
  print "not ok 20\n";
}

if(abs(STRtoLD("1${dp}12837916709551257390") - (M_2_SQRTPIl)) <= $eps) {print "ok 21\n"}
else {
  warn "\nM_2_SQRTPIl: ", M_2_SQRTPIl, "\n";
  print "not ok 21\n";
}

if(abs(STRtoLD("1${dp}41421356237309504880") - (M_SQRT2l)) <= $eps) {print "ok 22\n"}
else {
  warn "\nM_SQRT2l: ", M_SQRT2l, "\n";
  print "not ok 22\n";
}

if(abs(STRtoLD("0${dp}70710678118654752440") - (M_SQRT1_2l)) <= $eps) {print "ok 23\n"}
else {
  warn "\nM_SQRT1_2l: ", M_SQRT1_2l, "\n";
  print "not ok 23\n";
}


#if(xx == LD_DBL_DIG) {print "ok 23\n"}

eval {$ret = LD_DBL_DIG};
if(!$@ && $ret >= 15 && $ret <= 33) {print "ok 24\n"}
elsif($@ =~ /not implemented/) {
  warn "\nLD_DBL_DIG not implemented\n";
  print "ok 24\n";
}
else {
  warn "\nLD_DBL_DIG: ", LD_DBL_DIG, "\n";
  print "not ok 24\n";
}

eval {$ret = LD_LDBL_DIG};
if(!$@ && $ret >= 15 && $ret <= 33) {print "ok 25\n"}
elsif($@ =~ /not implemented/) {
  warn "\nLD_LDBL_DIG not implemented\n";
  print "ok 25\n";
}
else {
  warn "\nLD_LDBL_DIG: ", LD_LDBL_DIG, "\n";
  print "not ok 25\n";
}

eval {$ret = LD_DBL_EPSILON};
if(!$@) {print "ok 26\n"}
elsif($@ =~ /not implemented/) {
  warn "\nLD_DBL_EPSILON not implemented\n";
  print "ok 26\n";
}
else {
  warn "\n\$\@: $@\n";
  print "not ok 26\n";
}

eval {$ret = LD_LDBL_EPSILON};
if(!$@) {print "ok 27\n"}
elsif($@ =~ /not implemented/) {
  warn "\nLD_LDBL_EPSILON not implemented\n";
  print "ok 27\n";
}
else {
  warn "\n\$\@: $@\n";
  print "not ok 27\n";
}

eval {$ret = LD_DBL_DENORM_MIN};
if(!$@) {print "ok 28\n"}
elsif($@ =~ /not implemented/) {
  warn "\nLD_DBL_DENORM_MIN not implemented\n";
  print "ok 28\n";
}
else {
  warn "\n\$\@: $@\n";
  print "not ok 28\n";
}

eval {$ret = LD_LDBL_DENORM_MIN};
if(!$@) {print "ok 29\n"}
elsif($@ =~ /not implemented/) {
  warn "\nLD_LDBL_DENORM_MIN not implemented\n";
  print "ok 29\n";
}
else {
  warn "\n\$\@: $@\n";
  print "not ok 29\n";
}

eval {$ret1 = LD_DBL_MAX; $ret2 = LD_DBL_MIN;};
if(!$@ && $ret1 > $ret2) {print "ok 30\n"}
elsif($@ =~ /not implemented/) {
  warn "\nLD_DBL_MIN and/or LD_DBL_MAX not implemented\n";
  print "ok 30\n";
}
else {
  warn "\nLD_DBL_MAX: ", LD_DBL_MAX, " LD_DBL_MIN: ", LD_DBL_MIN, "\n";
  print "not ok 30\n";
}

eval {$ret1 = LD_LDBL_MAX; $ret2 = LD_LDBL_MIN;};
if(!$@ && $ret1 > $ret2) {print "ok 31\n"}
elsif($@ =~ /not implemented/) {
  warn "\nLD_LDBL_MIN and/or LD_LDBL_MAX not implemented\n";
  print "ok 31\n";
}
else {
  warn "\nLD_LDBL_MAX: ", LD_LDBL_MAX, " LD_LDBL_MIN: ", LD_LDBL_MIN, "\n";
  print "not ok 31\n";
}
