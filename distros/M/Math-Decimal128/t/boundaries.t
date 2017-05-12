use warnings;
use strict;
use Math::Decimal128 qw(:all);

print "1..33\n";

my($man, $exp);

my $minus_one = Math::Decimal128->new(-1, 0);

my $max = Math::Decimal128->new('9999999999999999999999999999999999', 6111);

if(!is_InfD128($max)) {print "ok 1\n"}
else {
  warn "\n\$max: $max\n";
  print "not ok 1\n";
}

my $min = Math::Decimal128->new('-9999999999999999999999999999999999', 6111);

if(!is_InfD128($min)) {print "ok 2\n"}
else {
  warn "\n\$min: $min\n";
  print "not ok 2\n";
}

if($max * $minus_one == $min && -$max == $min && -$min == $max) {print "ok 3\n"}
else {print "not ok 3\n"}

($man, $exp) = D128toME($max);

if($man eq '9999999999999999999999999999999999' && $exp == 6111) {print "ok 4\n"}
else {
  warn "\$man: $man\n\$exp: $exp\n";
  print "not ok 4\n";
}

($man, $exp) = D128toME($min);

if($man eq '-9999999999999999999999999999999999' && $exp == 6111) {print "ok 5\n"}
else {
  warn "\$man: $man\n\$exp: $exp\n";
  print "not ok 5\n";
}

my $smallest_pos = Math::Decimal128->new(1, -6176);
($man, $exp) = D128toME($smallest_pos);

if($man == 1 && $exp == -6176){print "ok 6\n"}
else {
  warn "\$man: $man\n\$exp: $exp\n";
  print "not ok 6\n";
}

my $biggest_neg = Math::Decimal128->new(-1, -6176);
($man, $exp) = D128toME($biggest_neg);

if($man == -1 && $exp == -6176){print "ok 7\n"}
else {
  warn "\$man: $man\n\$exp: $exp\n";
  print "not ok 7\n";
}

my $zero = Math::Decimal128->new(0, 0);

if(is_ZeroD128($zero) > 0) {print "ok 8\n"}
else {print "not ok 8\n"}

($man, $exp) = D128toME($zero);

if($man eq '0' && $exp eq '0'){print "ok 9\n"}
else {
  warn "\$man: $man\n\$exp: $exp\n";
  print "not ok 9\n";
}

$zero *= $minus_one;

if(is_ZeroD128($zero) < 0) {print "ok 10\n"}
else {print "not ok 10\n"}

($man, $exp) = D128toME($zero);

if($man eq '-0' && $exp eq '0'){print "ok 11\n"}
else {
  warn "\$man: $man\n\$exp: $exp\n";
  print "not ok 11\n";
}

my $pos_test = Math::Decimal128::_testvalD128_2(1);
my $neg_test = Math::Decimal128::_testvalD128_2(-1);

($man, $exp) = D128toME($pos_test);
if($man eq '2547409938307199254740993' && $exp == 0) {print "ok 12\n"}
else {print "not ok 12\n"}


($man, $exp) = D128toME($neg_test);
if($man eq '-2547409938307199254740993' && $exp == 0) {print "ok 13\n"}
else {print "not ok 13\n"}

my $pos_check = Math::Decimal128->new('2547409938307199254740993', 0);
if($pos_check == $pos_test) {print "ok 14\n"}
else {
  warn "\$pos_check: $pos_check\n";
  print "not ok 14\n";
}

my $neg_check = Math::Decimal128->new('-2547409938307199254740993', 0);
if($neg_check == $neg_test) {print "ok 15\n"}
else {
  warn "\$neg_check: $neg_check\n";
  print "not ok 15\n";
}

my $pv_check = PVtoD128('-2547409938307199254740993e0');

if($pv_check == $neg_test) {print "ok 16\n"}
else {
 warn "\$pv_check: $pv_check\n";
 print "not ok 16\n";
}

my $shift = Exp10l(-15);
my $cancel = Exp10l(15);

if($shift * $cancel == UnityD128(1)){print "ok 17\n"}
else {
  warn "\$shift: $shift \$cancel: $cancel\n";
  print "not ok 17\n";
}

my $pv_check2 = PVtoD128('-2547409938307199254740993e15');
$pv_check2 *= $shift;

if($pv_check2 == $neg_test) {print "ok 18\n"}
else {
 warn "\$pv_check2: $pv_check2\n";
 print "not ok 18\n";
}

if(DEC128_MAX == Math::Decimal128->new('9999999999999999999999999999999999', 6111)) {print "ok 19\n"}
else {
  warn "\nDEC128_MAX: ", DEC128_MAX, "\n";
  print "not ok 19\n";
}

if(UnityD128(-1) * DEC128_MAX == Math::Decimal128->new('-9999999999999999999999999999999999', 6111))
  {print "ok 20\n"}
else {
  warn "\nDEC128_MAX * -1: ", UnityD128(-1) * DEC128_MAX, "\n";
  print "not ok 20\n";
}

if(DEC128_MIN == Math::Decimal128->new('1', -6176)) {print "ok 21\n"}
else {
  warn "\nDEC128_MIN: ", DEC128_MIN, "\n";
  print "not ok 21\n";
}

if(UnityD128(-1) * DEC128_MIN == Math::Decimal128->new('-1', -6176))
  {print "ok 22\n"}
else {
  warn "\nDEC128_MIN * -1: ", UnityD128(-1) * DEC128_MIN, "\n";
  print "not ok 22\n";
}

my $mintest4 = MEtoD128('4', -6177);
my $mintest5 = MEtoD128('5', -6177);
my $mintest6 = MEtoD128('6', -6177);

if(is_ZeroD128($mintest4) && $mintest4 == $mintest5) { print "ok 23\n"}
else {
  warn "\n\$mintest4: $mintest4\n\$mintest5: $mintest5\n";
  print "not ok 23\n";
}

if($mintest6 == DEC128_MIN) {print "ok 24\n"}
else {
  warn "\n\$mintest6: $mintest6\n";
  print "not ok 24\n";
}

my $maxtest = MEtoD128('1000000000000000000000000000000000', 6111);

$maxtest *= MEtoD128('1', 1);

if(is_InfD128($maxtest)) {print "ok 25\n"}
else {
  warn "\n\$maxtest: $maxtest\n";
  print "not ok 25\n";
}

#############################################
#############################################

if(is_ZeroD128(DEC128_MIN() / MEtoD128('2', 0))) {print "ok 26\n"}
else {
  warn "\n", DEC128_MIN() / MEtoD128('2', 0), "\n";
  print "not ok 26\n";
}

if(DEC128_MIN == DEC128_MIN() / MEtoD128('19999', -4)) {print "ok 27\n"}
else {
  warn "\n", DEC128_MIN() / MEtoD128('19999', -4), "\n";
  print "not ok 27\n";
}

if(is_InfD128(DEC128_MAX() + MEtoD128('1', 6111)) == 1) {print "ok 28\n"}
else {
  warn "\n", DEC128_MAX() + MEtoD128('1', 369), "\n";
  print "not ok 28\n";
}

if(DEC128_MAX == DEC128_MAX() + MEtoD128('1', 368)) {print "ok 29\n"}
else {
  warn "\n", DEC128_MAX() + MEtoD128('1', 368), "\n";
  print "not ok 29\n";
}

#############################################
#############################################

if(is_ZeroD128(DEC128_MIN() * UnityD128(-1) / MEtoD128('2', 0))) {print "ok 30\n"}
else {
  warn "\n", DEC128_MIN() * UnityD128(-1) / MEtoD128('2', 0), "\n";
  print "not ok 30\n";
}

if(DEC128_MIN() * UnityD128(-1) == DEC128_MIN() * UnityD128(-1) / MEtoD128('19999', -4)) {print "ok 31\n"}
else {
  warn "\n", DEC128_MIN() * UnityD128(-1) / MEtoD128('19999', -4), "\n";
  print "not ok 31\n";
}

if(is_InfD128(DEC128_MAX() * UnityD128(-1) - MEtoD128('1', 6111)) == -1) {print "ok 32\n"}
else {
  warn "\n", DEC128_MAX() * UnityD128(-1) - MEtoD128('1', 369), "\n";
  print "not ok 32\n";
}

if(DEC128_MAX() * UnityD128(-1) == DEC128_MAX() * UnityD128(-1) + MEtoD128('1', 368)) {print "ok 33\n"}
else {
  warn "\n", DEC128_MAX() * UnityD128(-1) + MEtoD128('1', 368), "\n";
  print "not ok 33\n";
}

#############################################
#############################################
