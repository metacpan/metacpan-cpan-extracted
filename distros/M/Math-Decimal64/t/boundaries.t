use warnings;
use strict;
use Math::Decimal64 qw(:all);

print "1..33\n";

my($man, $exp);

my $minus_one = Math::Decimal64->new(-1, 0);

my $max = Math::Decimal64->new('9999999999999999', 369);

if(!is_InfD64($max)) {print "ok 1\n"}
else {
  warn "\n\$max: $max\n";
  print "not ok 1\n";
}

my $min = Math::Decimal64->new('-9999999999999999', 369);

if(!is_InfD64($min)) {print "ok 2\n"}
else {
  warn "\n\$min: $min\n";
  print "not ok 2\n";
}

if($max * $minus_one == $min && -$max == $min && -$min == $max) {print "ok 3\n"}
else {print "not ok 3\n"}

($man, $exp) = D64toME($max);

if($man eq '9999999999999999' && $exp == 369) {print "ok 4\n"}
else {
  warn "\$man: $man\n\$exp: $exp\n";
  print "not ok 4\n";
}

($man, $exp) = D64toME($min);

if($man eq '-9999999999999999' && $exp == 369) {print "ok 5\n"}
else {
  warn "\$man: $man\n\$exp: $exp\n";
  print "not ok 5\n";
}

my $smallest_pos = Math::Decimal64->new(1, -398);
($man, $exp) = D64toME($smallest_pos);

if($man == 1 && $exp == -398){print "ok 6\n"}
else {
  warn "\$man: $man\n\$exp: $exp\n";
  print "not ok 6\n";
}

my $biggest_neg = Math::Decimal64->new(-1, -398);
($man, $exp) = D64toME($biggest_neg);

if($man == -1 && $exp == -398){print "ok 7\n"}
else {
  warn "\$man: $man\n\$exp: $exp\n";
  print "not ok 7\n";
}

my $zero = Math::Decimal64->new(0, 0);

if(is_ZeroD64($zero) > 0) {print "ok 8\n"}
else {print "not ok 8\n"}

($man, $exp) = D64toME($zero);

if($man eq '0' && $exp eq '0'){print "ok 9\n"}
else {
  warn "\$man: $man\n\$exp: $exp\n";
  print "not ok 9\n";
}

$zero *= $minus_one;

if(is_ZeroD64($zero) < 0) {print "ok 10\n"}
else {print "not ok 10\n"}

($man, $exp) = D64toME($zero);

if($man eq '-0' && $exp eq '0'){print "ok 11\n"}
else {
  warn "\$man: $man\n\$exp: $exp\n";
  print "not ok 11\n";
}

my $pos_test = Math::Decimal64::_testvalD64(1);
my $neg_test = Math::Decimal64::_testvalD64(-1);

($man, $exp) = D64toME($pos_test);
if($man eq '9307199254740993' && $exp == -15) {print "ok 12\n"}
else {print "not ok 12\n"}


($man, $exp) = D64toME($neg_test);
if($man eq '-9307199254740993' && $exp == -15) {print "ok 13\n"}
else {print "not ok 13\n"}

my $pos_check = Math::Decimal64->new('9307199254740993', -15);
if($pos_check == $pos_test) {print "ok 14\n"}
else {
  warn "\$pos_check: $pos_check\n";
  print "not ok 14\n";
}

my $neg_check = Math::Decimal64->new('-9307199254740993', -15);
if($neg_check == $neg_test) {print "ok 15\n"}
else {
  warn "\$neg_check: $neg_check\n";
  print "not ok 15\n";
}

my $pv_check = PVtoD64('-9307199254740993e-15');

if($pv_check == $neg_test) {print "ok 16\n"}
else {
 warn "\$pv_check: $pv_check\n";
 print "not ok 16\n";
}

my $shift = Exp10(-15);
my $cancel = Exp10(15);

if($shift * $cancel == UnityD64(1)){print "ok 17\n"}
else {
  warn "\$shift: $shift \$cancel: $cancel\n";
  print "not ok 17\n";
}

my $pv_check2 = PVtoD64('-9307199254740993');
$pv_check2 *= $shift;

if($pv_check2 == $neg_test) {print "ok 18\n"}
else {
 warn "\$pv_check2: $pv_check2\n";
 print "not ok 18\n";
}

if(DEC64_MAX == Math::Decimal64->new('9999999999999999', 369)) {print "ok 19\n"}
else {
  warn "\nDEC64_MAX: ", DEC64_MAX, "\n";
  print "not ok 19\n";
}

if(UnityD64(-1) * DEC64_MAX == Math::Decimal64->new('-9999999999999999', 369))
  {print "ok 20\n"}
else {
  warn "\nDEC64_MAX * -1: ", UnityD64(-1) * DEC64_MAX, "\n";
  print "not ok 20\n";
}

if(DEC64_MIN == Math::Decimal64->new('1', -398)) {print "ok 21\n"}
else {
  warn "\nDEC64_MIN: ", DEC64_MIN, "\n";
  print "not ok 21\n";
}

if(UnityD64(-1) * DEC64_MIN == Math::Decimal64->new('-1', -398))
  {print "ok 22\n"}
else {
  warn "\nDEC64_MIN * -1: ", UnityD64(-1) * DEC64_MIN, "\n";
  print "not ok 22\n";
}

my $mintest4 = MEtoD64('4', -399);
my $mintest5 = MEtoD64('5', -399);
my $mintest6 = MEtoD64('6', -399);

if(is_ZeroD64($mintest4) && $mintest4 == $mintest5) { print "ok 23\n"}
else {
  warn "\n\$mintest4: $mintest4\n\$mintest5: $mintest5\n";
  print "not ok 23\n";
}

if($mintest6 == DEC64_MIN) {print "ok 24\n"}
else {
  warn "\n\$mintest6: $mintest6\n";
  print "not ok 24\n";
}

my $maxtest = MEtoD64('1000000000000000', 369);

$maxtest *= MEtoD64('1', 1);

if(is_InfD64($maxtest)) {print "ok 25\n"}
else {
  warn "\n\$maxtest: $maxtest\n";
  print "not ok 25\n";
}

#############################################
#############################################

if(is_ZeroD64(DEC64_MIN() / MEtoD64('2', 0))) {print "ok 26\n"}
else {
  warn "\n", DEC64_MIN() / MEtoD64('2', 0), "\n";
  print "not ok 26\n";
}

if(DEC64_MIN == DEC64_MIN() / MEtoD64('19999', -4)) {print "ok 27\n"}
else {
  warn "\n", DEC64_MIN() / MEtoD64('19999', -4), "\n";
  print "not ok 27\n";
}

if(is_InfD64(DEC64_MAX() + MEtoD64('1', 369)) == 1) {print "ok 28\n"}
else {
  warn "\n", DEC64_MAX() + MEtoD64('1', 369), "\n";
  print "not ok 28\n";
}

if(DEC64_MAX == DEC64_MAX() + MEtoD64('1', 368)) {print "ok 29\n"}
else {
  warn "\n", DEC64_MAX() + MEtoD64('1', 368), "\n";
  print "not ok 29\n";
}

#############################################
#############################################

if(is_ZeroD64(DEC64_MIN() * UnityD64(-1) / MEtoD64('2', 0))) {print "ok 30\n"}
else {
  warn "\n", DEC64_MIN() * UnityD64(-1) / MEtoD64('2', 0), "\n";
  print "not ok 30\n";
}

if(DEC64_MIN() * UnityD64(-1) == DEC64_MIN() * UnityD64(-1) / MEtoD64('19999', -4)) {print "ok 31\n"}
else {
  warn "\n", DEC64_MIN() * UnityD64(-1) / MEtoD64('19999', -4), "\n";
  print "not ok 31\n";
}

if(is_InfD64(DEC64_MAX() * UnityD64(-1) - MEtoD64('1', 369)) == -1) {print "ok 32\n"}
else {
  warn "\n", DEC64_MAX() * UnityD64(-1) - MEtoD64('1', 369), "\n";
  print "not ok 32\n";
}

if(DEC64_MAX() * UnityD64(-1) == DEC64_MAX() * UnityD64(-1) + MEtoD64('1', 368)) {print "ok 33\n"}
else {
  warn "\n", DEC64_MAX() * UnityD64(-1) + MEtoD64('1', 368), "\n";
  print "not ok 33\n";
}

#############################################
#############################################
