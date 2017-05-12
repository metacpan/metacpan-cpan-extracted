# Check that arguments are being stringified as expected.

use warnings;
use strict;
use Math::Float128 qw(:all);

print "1..7\n";

my $pnan = F128toNV(NaNF128());
my $ninf = F128toNV(InfF128(-1));
my $pinf = F128toNV(InfF128(1));
my $negzero = F128toNV(ZeroF128(-1));
my $ap_tester = Math::Float128->new('1.68');

# Try to determine when the decimal point is a comma,
# and set $dp accordingly.
my $dp = '.';
$dp = ',' unless Math::Float128->new('0,5') == Math::Float128->new(0);

my $ok = 1;

for(-10 .. 10) {
  unless(F128toNV(STRtoF128($_)) == $_) {
    warn "\n\$_: $_ ", F128toNV(STRtoF128($_)), "\n";
    $ok = 0;
  }
  unless(F128toNV(STRtoF128($_ + "0${dp}5")) == $_ + 0.5) {
    warn "\n\$_ + 0.5: ",$_ + 0.5, " ", F128toNV(STRtoF128($_ + "0${dp}5")), "\n";
    $ok = 0;
  }
}

if($ok == 1) {print "ok 1\n"}
else {
  warn "\n\$ok: $ok\n";
  print "not ok 1\n";
}

$ok = 1;

for($ninf, $pinf) {
  unless(F128toNV(Math::Float128->new($_)) == $_) {
    warn "\n\$_: $_ ", F128toNV(Math::Float128->new($_)), "\n";
    $ok = 0;
  }
  unless(F128toNV(Math::Float128->new($_ + 0.5)) == $_ + 0.5) {
    warn "\n\$_ + 0.5: ",$_ + 0.5, " ", F128toNV(Math::Float128->new($_ + 0.5)), "\n";
    $ok = 0;
  }
}

if($ok == 1) {print "ok 2\n"}
else {
  warn "\n\$ok: $ok\n";
  print "not ok 2\n";
}

$ok = 1;

for($pnan) {
  unless(is_NaNF128(Math::Float128->new($_))) {
    warn "\n\$_: $_ ", F128toNV(Math::Float128->new($_)), "\n";
    $ok = 0;
  }
  unless(is_NaNF128(Math::Float128->new($_ + 0.5))) {
    warn "\n\$_ + 0.5: ",$_ + 0.5, " ", F128toNV(Math::Float128->new($_ + 0.5)), "\n";
    $ok = 0;
  }
}

if($ok == 1) {print "ok 3\n"}
else {
  warn "\n\$ok: $ok\n";
  print "not ok 3\n";
}

if(Math::Float128::_overload_string(InfF128(-1)) eq '-Inf') {print "ok 4\n"}
else {
  warn "\nInfF128(-1): ", InfF128(-1), "\n";
  print "not ok 4\n";
}

if(Math::Float128::_overload_string(InfF128(1)) eq 'Inf') {print "ok 5\n"}
else {
  warn "\nInfF128(1): ", InfF128(1), "\n";
  print "not ok 5\n";
}

if(Math::Float128::_overload_string(NaNF128()) eq 'NaN') {print "ok 6\n"}
else {
  warn "\nNaNF128(): ", NaNF128(), "\n";
  print "not ok 6\n";
}

my $returned_string = F128toSTR($ap_tester);

if($returned_string =~ /1\.6/) {print "ok 7\n"}
else {
  warn "\nExpected something matching /1.6/\nGot $returned_string\n";
  print "not ok 7\n";
}

