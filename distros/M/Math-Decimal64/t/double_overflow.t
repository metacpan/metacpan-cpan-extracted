# Check that 16 digit mantissa's that are > 9007199254740992 (and that
# therefore exceed double precision) still get assigned correctly.
# We'll check that 16-digit mantissa's in the ranges
# 9307199254700000 .. 9307199254799999 and
# 9907199254800000 .. 9907199254899999 assign correctly.

use warnings;
use strict;
use Math::Decimal64 qw(:all);

print "1..7\n";

my $ok = 1;

my $check = Math::Decimal64::_testvalD64(1);  # 9307199254740993e-15
$check -= Math::Decimal64->new('40993', -15);  # 9307199254700000e-15

my $init = '93071992547';
my $suff = '00000';
my $addon = Exp10(-15);

if($check == Math::Decimal64->new($init . $suff, -15)) {print "ok 1\n"}
else {
  warn "\n\$check: $check\n\$init: $init\n\$suff: $suff\n";
  print "not ok 1\n";
}

for(1..99999) {
  $suff++;
  $suff = '0' . $suff while length($suff) < 5;
  $check += $addon;
  my $new = Math::Decimal64->new($init . $suff, -15);
  unless($check == $new) {
    warn "\n\$check: $check \$new: $new\n";
    $ok = 0;
  }
}

if($ok) { print "ok 2\n"}
else {print "not ok 2\n"}

if($check == Math::Decimal64->new('9307199254799999', -15)) {print "ok 3\n"}
else {
  warn "\n\$check: $check\n";
  print "not ok 3\n";
}

$check += Math::Decimal64->new('600000000000001', -15);

if($check == Math::Decimal64->new('99071992548', -10)) {print "ok 4\n"}
else {
  warn "\$check: $check\n";
  print "not ok 4\n";
}

$init = '99071992548';
$suff = '00000';

if($check == Math::Decimal64->new($init . $suff, -15)) {print "ok 5\n"}
else {
  warn "\n\$check: $check\n\$init: $init\n\$suff: $suff\n";
  print "not ok 5\n";
}

$ok = 1;

for(1..99999) {
  $suff++;
  $suff = '0' . $suff while length($suff) < 5;
  $check += $addon;
  my $new = Math::Decimal64->new($init . $suff, -15);
  unless($check == $new) {
    warn "\n\$check: $check \$new: $new\n";
    $ok = 0;
  }
}

if($ok) { print "ok 6\n"}
else {print "not ok 6\n"}

if($check == Math::Decimal64->new('9907199254899999', -15)) {print "ok 7\n"}
else {
  warn "\n\$check: $check\n";
  print "not ok 7\n";
}
