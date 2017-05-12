use warnings;
use strict;
use Math::LongDouble qw(:all);

print "1..28\n";

my $nan = NaNLD();
my $nnan = NaNLD();
my $zero = ZeroLD(1);
my $nzero = ZeroLD(-1);
my $unity = UnityLD(1);
my $nunity = UnityLD(-1);
my $inf = InfLD(1);
my $ninf = InfLD(-1);

warn "\nMath::LongDouble::_have_isnanl() returns ", Math::LongDouble::_have_isnanl(), "\n";
warn "Math::LongDouble::_have_nanl() returns ", Math::LongDouble::_have_nanl(), "\n";
warn "Math::LongDouble::_have_signbitl() returns ", Math::LongDouble::_have_signbitl(), "\n";

if(abs($nunity) == $unity) {print "ok 1\n"}
else {
  warn "abs(\$nunity): ", abs($nunity), "\n\$unity: $unity\n";
  print "not ok 1\n";
}

if(abs($ninf) == $inf) {print "ok 2\n"}
else {
  warn "abs(\$ninf): ", abs($ninf), "\n\$inf: $inf\n";
  print "not ok 2\n";
}

if(abs($nzero) == $zero) {print "ok 3\n"}
else {
  warn "abs(\$nzero): ", abs($nzero), "\n\$zero: $zero\n";
  print "not ok 3\n";
}

if(is_ZeroLD(abs($nzero)) <= 0) {print "not ok 4\n"}
else {print "ok 4\n"}

if(is_NaNLD(abs($nnan))) {print "ok 5\n"}
else {print "not ok 5\n"}

if(is_NaNLD(abs($nan))) {print "ok 6\n"}
else {print "not ok 6\n"}

my $bool = isinf_LD($inf);
if($bool) {print "ok 7\n"}
else {print "not ok 7\n"}

$bool = isinf_LD($ninf);
if($bool) {print "ok 8\n"}
else {print "not ok 8\n"}

$bool = !isinf_LD($nan);
if($bool) {print "ok 9\n"}
else {print "not ok 9\n"}

$bool = !isinf_LD($unity);
if($bool) {print "ok 10\n"}
else {print "not ok 10\n"}

$bool = isnan_LD($nan);
if($bool) {print "ok 11\n"}
else {print "not ok 11\n"}

$bool = !isnan_LD($inf);
if($bool) {print "ok 12\n"}
else {print "not ok 12\n"}

$bool = !isnan_LD($nunity);
if($bool) {print "ok 13\n"}
else {print "not ok 13\n"}

my $rop = Math::LongDouble->new(1.0);
nan_LD($rop, '');

$bool = isnan_LD($rop);
if($bool) {print "ok 14\n"}
else {print "not ok 14\n"}

$bool = !finite_LD($inf);
if($bool) {print "ok 15\n"}
else {print "not ok 15\n"}

$bool = !finite_LD($ninf);
if($bool) {print "ok 16\n"}
else {print "not ok 16\n"}

$bool = !finite_LD($nan);
if($bool) {print "ok 17\n"}
else {print "not ok 17\n"}

$bool = finite_LD($zero);
if($bool) {print "ok 18\n"}
else {print "not ok 18\n"}

$bool = finite_LD($nzero);
if($bool) {print "ok 19\n"}
else {print "not ok 19\n"}

$bool = finite_LD($unity);
if($bool) {print "ok 20\n"}
else {print "not ok 20\n"}

$bool = finite_LD($nunity);
if($bool) {print "ok 21\n"}
else {print "not ok 21\n"}

fabs_LD($rop,$ninf);

if($rop == $inf) {print "ok 22\n"}
else {
  warn "\n\$rop: $rop\n\n";
  print "not ok 22\n";
}

if(!isnan_LD(ZeroLD(1))) {print "ok 23\n"}
else {
  warn "\n", ZeroLD(1), "unexpectedly reported as a NaN\n";
  print "not ok 23\n";
}

if(!isnan_LD(ZeroLD(-1))) {print "ok 24\n"}
else {
  warn "\n", ZeroLD(-1), "unexpectedly reported as a NaN\n";
  print "not ok 24\n";
}

if(!isnan_LD(InfLD(1))) {print "ok 25\n"}
else {
  warn "\n", InfLD(1), "unexpectedly reported as a NaN\n";
  print "not ok 25\n";
}

if(!isnan_LD(InfLD(-1))) {print "ok 26\n"}
else {
  warn "\n", InfLD(-1), "unexpectedly reported as a NaN\n";
  print "not ok 26\n";
}

if(!isnan_LD(UnityLD(1))) {print "ok 27\n"}
else {
  warn "\n", UnityLD(1), "unexpectedly reported as a NaN\n";
  print "not ok 27\n";
}

if(!isnan_LD(UnityLD(-1))) {print "ok 28\n"}
else {
  warn "\n", UnityLD(-1), "unexpectedly reported as a NaN\n";
  print "not ok 28\n";
}

