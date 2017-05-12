# Check that arguments are being stringified as expected.

use warnings;
use strict;
use Math::LongDouble qw(:all);

print "1..7\n";

my $nnan = LDtoNV(NaNLD());
my $pnan = LDtoNV(NaNLD());
my $ninf = LDtoNV(InfLD(-1));
my $pinf = LDtoNV(InfLD(1));
my $negzero = LDtoNV(ZeroLD(-1));

#my $ld = Math::LongDouble->new($pinf);
#warn "\$ld: $ld\n";

my $ok = 1;

for(-10 .. 10) {
  unless(LDtoNV(STRtoLD($_)) == $_) {
    warn "\n\$_: $_ ", LDtoNV(STRtoLD($_)), "\n";
    $ok = 0;
  }
  unless(LDtoNV(STRtoLD($_ + 0.5)) == $_ + 0.5) {
    warn "\n\$_ + 0.5: ",$_ + 0.5, " ", LDtoNV(STRtoLD($_ +0.5)), "\n";
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
  unless(LDtoNV(Math::LongDouble->new($_)) == $_) {
    warn "\n\$_: $_ ", LDtoNV(Math::LongDouble->new($_)), "\n";
    $ok = 0;
  }
  unless(LDtoNV(Math::LongDouble->new($_ + 0.5)) == $_ + 0.5) {
    warn "\n\$_ + 0.5: ",$_ + 0.5, " ", LDtoNV(Math::LongDouble->new($_ + 0.5)), "\n";
    $ok = 0;
  }
}

if($ok == 1) {print "ok 2\n"}
else {
  warn "\n\$ok: $ok\n";
  print "not ok 2\n";
}

$ok = 1;

for($nnan, $pnan) {
  unless(is_NaNLD(Math::LongDouble->new($_))) {
    warn "\n\$_: $_ ", LDtoNV(Math::LongDouble->new($_)), "\n";
    $ok = 0;
  }
  unless(is_NaNLD(Math::LongDouble->new($_ + 0.5))) {
    warn "\n\$_ + 0.5: ",$_ + 0.5, " ", LDtoNV(Math::LongDouble->new($_ + 0.5)), "\n";
    $ok = 0;
  }
}

if($ok == 1) {print "ok 3\n"}
else {
  warn "\n\$ok: $ok\n";
  print "not ok 3\n";
}

if(Math::LongDouble::_overload_string(InfLD(-1)) eq '-Inf') {print "ok 4\n"}
else {
  warn "\nInfLD(-1): ", InfLD(-1), "\n";
  print "not ok 4\n";
}

if(Math::LongDouble::_overload_string(InfLD(1)) eq 'Inf') {print "ok 5\n"}
else {
  warn "\nInfLD(1): ", InfLD(1), "\n";
  print "not ok 5\n";
}

if(Math::LongDouble::_overload_string(NaNLD()) eq 'NaN') {print "ok 6\n"}
else {
  warn "\nNaNLD(): ", NaNLD(), "\n";
  print "not ok 6\n";
}

if(Math::LongDouble::_overload_string(NaNLD()) =~ /NaN/) {print "ok 7\n"}
else {
  warn "\nNaNLD(): ", NaNLD(), "\n";
  print "not ok 7\n";
}
