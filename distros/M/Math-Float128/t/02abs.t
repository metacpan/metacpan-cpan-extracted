use warnings;
use strict;
use Math::Float128 qw(:all);

print "1..21\n";

my $nan = NaNF128();
my $zero = ZeroF128(1);
my $nzero = ZeroF128(-1);
my $unity = UnityF128(1);
my $nunity = UnityF128(-1);
my $inf = InfF128(1);
my $ninf = InfF128(-1);

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

if(is_ZeroF128(abs($nzero)) <= 0) {print "not ok 4\n"}
else {print "ok 4\n"}

if(is_NaNF128(abs($nan))) {print "ok 5\n"}
else {print "not ok 5\n"}

my $rop = Math::Float128->new();

fabs_F128($rop,$ninf);

if($rop == $inf) {print "ok 6\n"}
else {
  warn "\n\$rop: $rop\n\n";
  print "not ok 6\n";
}

my $bool = isinf_F128($inf);
if($bool) {print "ok 7\n"}
else {print "not ok 7\n"}

$bool = isinf_F128($ninf);
if($bool) {print "ok 8\n"}
else {print "not ok 8\n"}

$bool = !isinf_F128($nan);
if($bool) {print "ok 9\n"}
else {print "not ok 9\n"}

$bool = !isinf_F128($unity);
if($bool) {print "ok 10\n"}
else {print "not ok 10\n"}

$bool = isnan_F128($nan);
if($bool) {print "ok 11\n"}
else {print "not ok 11\n"}

$bool = !isnan_F128($inf);
if($bool) {print "ok 12\n"}
else {print "not ok 12\n"}

$bool = !isnan_F128($nunity);
if($bool) {print "ok 13\n"}
else {print "not ok 13\n"}

nan_F128($rop, '');

$bool = isnan_F128($rop);
if($bool) {print "ok 14\n"}
else {print "not ok 14\n"}

$bool = !finite_F128($inf);
if($bool) {print "ok 15\n"}
else {print "not ok 15\n"}

$bool = !finite_F128($ninf);
if($bool) {print "ok 16\n"}
else {print "not ok 16\n"}

$bool = !finite_F128($nan);
if($bool) {print "ok 17\n"}
else {print "not ok 17\n"}

$bool = finite_F128($zero);
if($bool) {print "ok 18\n"}
else {print "not ok 18\n"}

$bool = finite_F128($nzero);
if($bool) {print "ok 19\n"}
else {print "not ok 19\n"}

$bool = finite_F128($unity);
if($bool) {print "ok 20\n"}
else {print "not ok 20\n"}

$bool = finite_F128($nunity);
if($bool) {print "ok 21\n"}
else {print "not ok 21\n"}
