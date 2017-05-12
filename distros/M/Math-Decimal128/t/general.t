use warnings;
use strict;
use Math::Decimal128 qw(:all);

print "1..52\n";

my $d = "1.2314";
my $d128 = PVtoD128($d);
my $x128 = D128toNV($d128);


my $d128_2 = PVtoD128("189.651");
my $x128_2 = D128toNV($d128_2);

print PVtoD128(123.5), " ", NVtoD128(123.5), "\n";

if(PVtoD128( 123.5 )  == NVtoD128( 123.5 )) {print "ok 1\n"}
else {print "not ok 1\n"}
if( PVtoD128("123.5") == NVtoD128("123.5")) {print "ok 2\n"}
else {print "not ok 2\n"}
if( PVtoD128("1235e-1") == NVtoD128( 123.5 )) {print "ok 3\n"}
else {print "not ok 3\n"}
if( PVtoD128( 1235e-1 ) == NVtoD128("123.5")) {print "ok 4\n"}
else {print "not ok 4\n"}
if( PVtoD128("1235e-1") == PVtoD128( 123.5 )) {print "ok 5\n"}
else {print "not ok 5\n"}
if( NVtoD128("1235e-1") == NVtoD128( 123.5 )) {print "ok 6\n"}
else {print "not ok 6\n"}

my $add = MEtoD128("1908824", -4);
my $mul = MEtoD128("2335362414", -7);
my $sub = MEtoD128("-1884196", -4);
my $div = PVtoD128("0.006492979209178965573606255701261791");

if($d128 + $d128_2 == $add) {print "ok 7\n"}
else {
  warn "\nLHS: ", $d128 + $d128_2, "\nRHS: $add\n";
  print "not ok 7\n";
}

if($d128 * $d128_2 == $mul) {print "ok 8\n"}
else {
  warn "\nLHS: ", $d128 + $d128_2, "\nRHS: $mul\n";
  print "not ok 8\n";
}

if($d128 - $d128_2 == $sub) {print "ok 9\n"}
else {
  warn "\nLHS: ", $d128 + $d128_2, "\nRHS: $sub\n";
  print "not ok 9\n";
}

if($d128 / $d128_2 == $div) {print "ok 10\n"}
else {
  warn "\nLHS: ", $d128 / $d128_2, "\nRHS: $div\n";
  print "not ok 10\n";
}

#################################

if($d128 + $d128_2 >= $add) {print "ok 11\n"}
else {
  warn "\nLHS: ", $d128 + $d128_2, "\nRHS: $add\n";
  print "not ok 11\n";
}

if($d128 * $d128_2 >= $mul) {print "ok 12\n"}
else {
  warn "\nLHS: ", $d128 + $d128_2, "\nRHS: $mul\n";
  print "not ok 12\n";
}

if($d128 - $d128_2 >= $sub) {print "ok 13\n"}
else {
  warn "\nLHS: ", $d128 + $d128_2, "\nRHS: $sub\n";
  print "not ok 13\n";
}

if($d128 / $d128_2 >= $div) {print "ok 14\n"}
else {
  warn "\nLHS: ", $d128 + $d128_2, "\nRHS: $div\n";
  print "not ok 14\n";
}

#################################

if($d128 + $d128_2 <= $add) {print "ok 15\n"}
else {
  warn "\nLHS: ", $d128 + $d128_2, "\nRHS: $add\n";
  print "not ok 15\n";
}

if($d128 * $d128_2 <= $mul) {print "ok 16\n"}
else {
  warn "\nLHS: ", $d128 + $d128_2, "\nRHS: $mul\n";
  print "not ok 16\n";
}

if($d128 - $d128_2 <= $sub) {print "ok 17\n"}
else {
  warn "\nLHS: ", $d128 + $d128_2, "\nRHS: $sub\n";
  print "not ok 17\n";
}

if($d128 / $d128_2 <= $div) {print "ok 18\n"}
else {
  warn "\nLHS: ", $d128 + $d128_2, "\nRHS: $div\n";
  print "not ok 18\n";
}

#################################

if($d128 + $d128_2 >= $add - NVtoD128(0.0001)) {print "ok 19\n"}
else {
  warn "\nLHS: ", $d128 + $d128_2, "\nRHS: ",$add - PVtoD128('0.0001'), "\n";
  print "not ok 19\n";
}

if($d128 * $d128_2 >= $mul - NVtoD128(0.0001)) {print "ok 20\n"}
else {
  warn "\nLHS: ", $d128 + $d128_2, "\nRHS: ", $mul - PVtoD128('0.0001'),"\n";
  print "not ok 20\n";
}

if($d128 - $d128_2 >= $sub - NVtoD128(0.0001)) {print "ok 21\n"}
else {
  warn "\nLHS: ", $d128 + $d128_2, "\nRHS: ", $sub - PVtoD128('0.0001'), "\n";
  print "not ok 21\n";
}

if($d128 / $d128_2 >= $div - NVtoD128(0.0001)) {print "ok 22\n"}
else {
  warn "\nLHS: ", $d128 + $d128_2, "\nRHS: ", $div - PVtoD128('0.0001'), "\n";
  print "not ok 22\n";
}

#################################

if($d128 + $d128_2 <= $add + NVtoD128(0.0001)) {print "ok 23\n"}
else {
  warn "\nLHS: ", $d128 + $d128_2, "\nRHS: ",$add + PVtoD128('0.0001'), "\n";
  print "not ok 23\n";
}

if($d128 * $d128_2 <= $mul + NVtoD128(0.0001)) {print "ok 24\n"}
else {
  warn "\nLHS: ", $d128 + $d128_2, "\nRHS: ", $mul + PVtoD128('0.0001'),"\n";
  print "not ok 24\n";
}

if($d128 - $d128_2 <= $sub + NVtoD128(0.0001)) {print "ok 25\n"}
else {
  warn "\nLHS: ", $d128 + $d128_2, "\nRHS: ", $sub + PVtoD128('0.0001'), "\n";
  print "not ok 25\n";
}

if($d128 / $d128_2 <= $div + NVtoD128(0.0001)) {print "ok 26\n"}
else {
  warn "\nLHS: ", $d128 + $d128_2, "\nRHS: ", $div + PVtoD128('0.0001'), "\n";
  print "not ok 26\n";
}

#################################

if($d128 + $d128_2 > $add - NVtoD128(0.0001)) {print "ok 27\n"}
else {
  warn "\nLHS: ", $d128 + $d128_2, "\nRHS: ",$add - NVtoD128(0.0001), "\n";
  print "not ok 27\n";
}

if($d128 * $d128_2 > $mul - NVtoD128(0.0001)) {print "ok 28\n"}
else {
  warn "\nLHS: ", $d128 + $d128_2, "\nRHS: ",$mul - NVtoD128(0.0001), "\n";
  print "not ok 28\n";
}

if($d128 - $d128_2 > $sub - NVtoD128(0.0001)) {print "ok 29\n"}
else {
  warn "\nLHS: ", $d128 + $d128_2, "\nRHS: ",$sub - NVtoD128(0.0001), "\n";
  print "not ok 29\n";
}

if($d128 / $d128_2 > $div - NVtoD128(0.0001)) {print "ok 30\n"}
else {
  warn "\nLHS: ", $d128 + $d128_2, "\nRHS: ",$div - NVtoD128(0.0001), "\n";
  print "not ok 30\n";
}

#################################

if($d128 + $d128_2 < $add + NVtoD128(0.0001)) {print "ok 31\n"}
else {
  warn "\nLHS: ", $d128 + $d128_2, "\nRHS: ",$add + NVtoD128(0.0001), "\n";
  print "not ok 31\n";
}

if($d128 * $d128_2 < $mul + NVtoD128(0.0001)) {print "ok 32\n"}
else {
  warn "\nLHS: ", $d128 + $d128_2, "\nRHS: ",$mul + NVtoD128(0.0001), "\n";
  print "not ok 32\n";
}

if($d128 - $d128_2 < $sub + NVtoD128(0.0001)) {print "ok 33\n"}
else {
  warn "\nLHS: ", $d128 + $d128_2, "\nRHS: ",$sub + NVtoD128(0.0001), "\n";
  print "not ok 33\n";
}

if($d128 / $d128_2 < $div + NVtoD128(0.0001)) {print "ok 34\n"}
else {
  warn "\nLHS: ", $d128 + $d128_2, "\nRHS: ",$div + NVtoD128(0.0001), "\n";
  print "not ok 34\n";
}

#################################

my $d128_copy = $d128;

$d128 *= $d128_2;
if($d128 == $d128_copy * $d128_2) {print "ok 35\n"}
else {
  warn "\nLHS: $d128\nRHS: ", $d128_copy * $d128_2, "\n";
  print "not ok 35\n";
}

$d128 /= $d128_2;
if($d128 == $d128_copy) {print "ok 36\n"}
else {
  warn "\nLHS: $d128\nRHS: $d128_copy\n";
  print "not ok 36\n";
}

$d128 += $d128_2;
if($d128 == $d128_copy + $d128_2) {print "ok 37\n"}
else {
  warn "\nLHS: $d128\nRHS: ", $d128_copy * $d128_2, "\n";
  print "not ok 37\n";
}

$d128 -= $d128_2;
if($d128 == $d128_copy) {print "ok 38\n"}
else {
  warn "\nLHS: $d128\nRHS: $d128_copy\n";
  print "not ok 38\n";
}

#################################

my $pnan = NaND128();
my $nnan = NaND128();

my $pinf = InfD128(1);
my $ninf = InfD128(-1);

if($nnan == $nnan || $pnan == $pnan || $nnan == $pnan) {
  warn "\n\$pnan: $pnan\n\$nnan: $nnan\n";
  print "not ok 39\n";
}
else {print "ok 39\n"}

if($nnan != $nnan && $pnan != $pnan && $nnan != $pnan) {print "ok 40\n"}
else {
  warn "\n\$pnan: $pnan\n\$nnan: $nnan\n";
  print "not ok 40\n";
}

if($pinf > $ninf && $ninf < $pinf) {print "ok 41\n"}
else {
  warn "\n\$pinf: $pinf\n\$ninf: $ninf\n";
  print "not ok 41\n";
}

if(
   (($pinf / $pinf) != ($pinf / $pinf)) && (($ninf / $ninf) != ($ninf / $ninf)) &&
   (($pinf / $pinf) != ($ninf / $ninf)) && (($ninf / $pinf) != ($ninf / $pinf)) &&
   (($pinf / $ninf) != ($ninf / $pinf)) && (($ninf / $pinf) != ($pinf / $ninf))
  ) {print "ok 42\n"}
else {
  warn "\n\$pinf: $pinf\n\$ninf: $ninf\n";
  print "not ok 42\n";
}

if($d128 && $d128_2) {print "ok 43\n"}
else {
  warn "\n\$d128: $d128\n\$d128_2: $d128_2\n";
  print "not ok 43\n";
}

if(!$d128 || !$d128_2) {
  warn "\n\$d128: $d128\n\$d128_2: $d128_2\n";
  print "not ok 44\n";
}
else {print "ok 44\n"}

my $zero = NVtoD128(0.0);

if(!$zero) {print "ok 45\n"}
else {
  warn "\n\$zero: $zero\n";
  print "not ok 45\n";
}

if($zero) {
  warn "\n\$zero: $zero\n";
  print "not ok 46\n";
}
else {print "ok 46\n"}

if($nnan || $pnan) {
  warn "\n\$pnan: $pnan\n\$nnan: $nnan\n";
  print "not ok 47\n";
}
else {print "ok 47\n"}

my $zerod128 = NVtoD128(0.0);

if(is_ZeroD128($zerod128) <= 0) {
  warn "\n\$zerod128: $zerod128\n";
  print "not ok 48\n";
}
else {print "ok 48\n"}

my $minus1  = NVtoD128(-1.0);

$zerod128 *= $minus1;

if(is_ZeroD128($zerod128) < 0  && !$zerod128) {print "ok 49\n"}
else {
  warn "\n\$zerod128: $zerod128\n";
  print "not ok 49\n";
}

if(Math::Decimal128::_overload_string($zerod128) eq '-0') {print "ok 50\n"}
else {
  warn "\n\$zerod128: $zerod128\n";
  print "not ok 50\n";
}

#################################

my $abs = abs($zerod128);
if("$abs" eq '0') {print "ok 51\n"}
else {
  warn "\n\$abs: $abs\n";
  print "not ok 51\n";
}

if(abs($minus1) == UVtoD128(1)) {print "ok 52\n"}
else {
  warn "\nLHS: ", abs($minus1), "\nRHS: ", UVtoD128(1), "\n";
  print "not ok 52\n";
}



