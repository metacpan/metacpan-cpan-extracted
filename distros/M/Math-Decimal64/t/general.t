use warnings;
use strict;
use Math::Decimal64 qw(:all);

print "1..52\n";

my $d = 1.2314;
my $d64 = NVtoD64($d);
my $x64 = D64toNV($d64);


my $d64_2 = PVtoD64("189.651");
my $x64_2 = D64toNV($d64_2);


if(PVtoD64( 123.5 )  == NVtoD64( 123.5 )) {print "ok 1\n"}
else {print "not ok 1\n"}
if( PVtoD64("123.5") == NVtoD64("123.5")) {print "ok 2\n"}
else {print "not ok 2\n"}
if( PVtoD64("123.5") == NVtoD64( 123.5 )) {print "ok 3\n"}
else {print "not ok 3\n"}
if( PVtoD64( 123.5 ) == NVtoD64("123.5")) {print "ok 4\n"}
else {print "not ok 4\n"}
if( PVtoD64("123.5") == PVtoD64( 123.5 )) {print "ok 5\n"}
else {print "not ok 5\n"}
if( NVtoD64("123.5") == NVtoD64( 123.5 )) {print "ok 6\n"}
else {print "not ok 6\n"}

my $add = MEtoD64("1908824", -4);
my $mul = MEtoD64("2335362414", -7);
my $sub = MEtoD64("-1884196", -4);
my $div = PVtoD64("0.006492979209178966");

if($d64 + $d64_2 == $add) {print "ok 7\n"}
else {
  warn "\nLHS: ", $d64 + $d64_2, "\nRHS: $add\n";
  print "not ok 7\n";
}

if($d64 * $d64_2 == $mul) {print "ok 8\n"}
else {
  warn "\nLHS: ", $d64 + $d64_2, "\nRHS: $mul\n";
  print "not ok 8\n";
}

if($d64 - $d64_2 == $sub) {print "ok 9\n"}
else {
  warn "\nLHS: ", $d64 + $d64_2, "\nRHS: $sub\n";
  print "not ok 9\n";
}

if($d64 / $d64_2 == $div) {print "ok 10\n"}
else {
  warn "\nLHS: ", $d64 / $d64_2, "\nRHS: $div\n";
  print "not ok 10\n";
}

#################################

if($d64 + $d64_2 >= $add) {print "ok 11\n"}
else {
  warn "\nLHS: ", $d64 + $d64_2, "\nRHS: $add\n";
  print "not ok 11\n";
}

if($d64 * $d64_2 >= $mul) {print "ok 12\n"}
else {
  warn "\nLHS: ", $d64 + $d64_2, "\nRHS: $mul\n";
  print "not ok 12\n";
}

if($d64 - $d64_2 >= $sub) {print "ok 13\n"}
else {
  warn "\nLHS: ", $d64 + $d64_2, "\nRHS: $sub\n";
  print "not ok 13\n";
}

if($d64 / $d64_2 >= $div) {print "ok 14\n"}
else {
  warn "\nLHS: ", $d64 + $d64_2, "\nRHS: $div\n";
  print "not ok 14\n";
}

#################################

if($d64 + $d64_2 <= $add) {print "ok 15\n"}
else {
  warn "\nLHS: ", $d64 + $d64_2, "\nRHS: $add\n";
  print "not ok 15\n";
}

if($d64 * $d64_2 <= $mul) {print "ok 16\n"}
else {
  warn "\nLHS: ", $d64 + $d64_2, "\nRHS: $mul\n";
  print "not ok 16\n";
}

if($d64 - $d64_2 <= $sub) {print "ok 17\n"}
else {
  warn "\nLHS: ", $d64 + $d64_2, "\nRHS: $sub\n";
  print "not ok 17\n";
}

if($d64 / $d64_2 <= $div) {print "ok 18\n"}
else {
  warn "\nLHS: ", $d64 / $d64_2, "\nRHS: $div\n";
  print "not ok 18\n";
}

#################################

if($d64 + $d64_2 >= $add - NVtoD64(0.0001)) {print "ok 19\n"}
else {
  warn "\nLHS: ", $d64 + $d64_2, "\nRHS: ",$add - PVtoD64('0.0001'), "\n";
  print "not ok 19\n";
}

if($d64 * $d64_2 >= $mul - NVtoD64(0.0001)) {print "ok 20\n"}
else {
  warn "\nLHS: ", $d64 + $d64_2, "\nRHS: ", $mul - PVtoD64('0.0001'),"\n";
  print "not ok 20\n";
}

if($d64 - $d64_2 >= $sub - NVtoD64(0.0001)) {print "ok 21\n"}
else {
  warn "\nLHS: ", $d64 + $d64_2, "\nRHS: ", $sub - PVtoD64('0.0001'), "\n";
  print "not ok 21\n";
}

if($d64 / $d64_2 >= $div - NVtoD64(0.0001)) {print "ok 22\n"}
else {
  warn "\nLHS: ", $d64 + $d64_2, "\nRHS: ", $div - PVtoD64('0.0001'), "\n";
  print "not ok 22\n";
}

#################################

if($d64 + $d64_2 <= $add + NVtoD64(0.0001)) {print "ok 23\n"}
else {
  warn "\nLHS: ", $d64 + $d64_2, "\nRHS: ",$add + PVtoD64('0.0001'), "\n";
  print "not ok 23\n";
}

if($d64 * $d64_2 <= $mul + NVtoD64(0.0001)) {print "ok 24\n"}
else {
  warn "\nLHS: ", $d64 + $d64_2, "\nRHS: ", $mul + PVtoD64('0.0001'),"\n";
  print "not ok 24\n";
}

if($d64 - $d64_2 <= $sub + NVtoD64(0.0001)) {print "ok 25\n"}
else {
  warn "\nLHS: ", $d64 + $d64_2, "\nRHS: ", $sub + PVtoD64('0.0001'), "\n";
  print "not ok 25\n";
}

if($d64 / $d64_2 <= $div + NVtoD64(0.0001)) {print "ok 26\n"}
else {
  warn "\nLHS: ", $d64 + $d64_2, "\nRHS: ", $div + PVtoD64('0.0001'), "\n";
  print "not ok 26\n";
}

#################################

if($d64 + $d64_2 > $add - NVtoD64(0.0001)) {print "ok 27\n"}
else {
  warn "\nLHS: ", $d64 + $d64_2, "\nRHS: ",$add - NVtoD64(0.0001), "\n";
  print "not ok 27\n";
}

if($d64 * $d64_2 > $mul - NVtoD64(0.0001)) {print "ok 28\n"}
else {
  warn "\nLHS: ", $d64 + $d64_2, "\nRHS: ",$mul - NVtoD64(0.0001), "\n";
  print "not ok 28\n";
}

if($d64 - $d64_2 > $sub - NVtoD64(0.0001)) {print "ok 29\n"}
else {
  warn "\nLHS: ", $d64 + $d64_2, "\nRHS: ",$sub - NVtoD64(0.0001), "\n";
  print "not ok 29\n";
}

if($d64 / $d64_2 > $div - NVtoD64(0.0001)) {print "ok 30\n"}
else {
  warn "\nLHS: ", $d64 + $d64_2, "\nRHS: ",$div - NVtoD64(0.0001), "\n";
  print "not ok 30\n";
}

#################################

if($d64 + $d64_2 < $add + NVtoD64(0.0001)) {print "ok 31\n"}
else {
  warn "\nLHS: ", $d64 + $d64_2, "\nRHS: ",$add + NVtoD64(0.0001), "\n";
  print "not ok 31\n";
}

if($d64 * $d64_2 < $mul + NVtoD64(0.0001)) {print "ok 32\n"}
else {
  warn "\nLHS: ", $d64 + $d64_2, "\nRHS: ",$mul + NVtoD64(0.0001), "\n";
  print "not ok 32\n";
}

if($d64 - $d64_2 < $sub + NVtoD64(0.0001)) {print "ok 33\n"}
else {
  warn "\nLHS: ", $d64 + $d64_2, "\nRHS: ",$sub + NVtoD64(0.0001), "\n";
  print "not ok 33\n";
}

if($d64 / $d64_2 < $div + NVtoD64(0.0001)) {print "ok 34\n"}
else {
  warn "\nLHS: ", $d64 + $d64_2, "\nRHS: ",$div + NVtoD64(0.0001), "\n";
  print "not ok 34\n";
}

#################################

my $d64_copy = $d64;

$d64 *= $d64_2;
if($d64 == $d64_copy * $d64_2) {print "ok 35\n"}
else {
  warn "\nLHS: $d64\nRHS: ", $d64_copy * $d64_2, "\n";
  print "not ok 35\n";
}

$d64 /= $d64_2;
if($d64 == $d64_copy) {print "ok 36\n"}
else {
  warn "\nLHS: $d64\nRHS: $d64_copy\n";
  print "not ok 36\n";
}

$d64 += $d64_2;
if($d64 == $d64_copy + $d64_2) {print "ok 37\n"}
else {
  warn "\nLHS: $d64\nRHS: ", $d64_copy * $d64_2, "\n";
  print "not ok 37\n";
}

$d64 -= $d64_2;
if($d64 == $d64_copy) {print "ok 38\n"}
else {
  warn "\nLHS: $d64\nRHS: $d64_copy\n";
  print "not ok 38\n";
}

#################################

my $pnan = NaND64();
my $nnan = NaND64();

my $pinf = InfD64(1);
my $ninf = InfD64(-1);

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

if($d64 && $d64_2) {print "ok 43\n"}
else {
  warn "\n\$d64: $d64\n\$d64_2: $d64_2\n";
  print "not ok 43\n";
}

if(!$d64 || !$d64_2) {
  warn "\n\$d64: $d64\n\$d64_2: $d64_2\n";
  print "not ok 44\n";
}
else {print "ok 44\n"}

my $zero = NVtoD64(0.0);

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

my $zerod64 = NVtoD64(0.0);

if(is_ZeroD64($zerod64) <= 0) {
  warn "\n\$zerod64: $zerod64\n";
  print "not ok 48\n";
}
else {print "ok 48\n"}

my $minus1  = NVtoD64(-1.0);

$zerod64 *= $minus1;

if(is_ZeroD64($zerod64) < 0  && !$zerod64) {print "ok 49\n"}
else {
  warn "\n\$zerod64: $zerod64\n";
  print "not ok 49\n";
}

if(Math::Decimal64::_overload_string($zerod64) eq '-0') {print "ok 50\n"}
else {
  warn "\n\$zerod64: $zerod64\n";
  print "not ok 50\n";
}

#################################

my $abs = abs($zerod64);
if("$abs" eq '0') {print "ok 51\n"}
else {
  warn "\n\$abs: $abs\n";
  print "not ok 51\n";
}

if(abs($minus1) == UVtoD64(1)) {print "ok 52\n"}
else {
  warn "\nLHS: ", abs($minus1), "\nRHS: ", UVtoD64(1), "\n";
  print "not ok 52\n";
}



