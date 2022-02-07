
# In assigning values we look at the flags of the
# given argument. Here we simply check that the flags
# of that argument will be as expected.

use strict;
use warnings;
use Test::More;

use Math::MPFI;
*_ITSA = \&Math::MPFI::_itsa;

my $uv_max = ~0;

my $nan1 = 'nan' + 0;
my $nan2 = 'nan' + 0;

my $inf1 = 'inf' + 0;
my $inf2 = 'inf' + 0;

if($] < 5.03) {
  warn "Skipping for $] - the aim here is to detect any recent changes,\n",
       "                        not to concern ourselves with old behaviour.\n";
  is(1, 1);
  done_testing();
  exit 0;
}

if($inf1 - $inf1 == 0) {
  warn "Skipping - failed to create an inf\n";
  is(1, 1);
  done_testing();
  exit 0;
}

if($nan1 == $nan1) {
  warn "Skipping - failed to create a nan\n";
  is(1, 1);
  done_testing();
  exit 0;
}

my $uv = $uv_max;
cmp_ok(_ITSA($uv),      '==', 1, "\$uv is UV");
my $uv_copy = $uv;
my $uv_x = "$uv";
cmp_ok(_ITSA($uv),      '==', 1, "\$uv is still UV");
$uv_x -= 2;
cmp_ok(_ITSA($uv_x),    '==', 1, "\$uv_x is also UV");
cmp_ok(_ITSA($uv_copy), '==', 1, "\$uv_copy is UV");

my $uv2 = ~0 - 1;
my $foo = $uv2 + 2;
cmp_ok(_ITSA($uv2),     '==', 1, "\$uv2 is still UV");

my $uv3 = ~0;
$uv3 += 1;
cmp_ok(_ITSA($uv3),     '==', 3, "\$uv3 is now NV");

my $uv4 = ~0;
$foo = "$uv4";
$uv4 += 1;
cmp_ok(_ITSA($uv4),     '==', 3, "\$uv4 is now NV");

my $iv = -23;
cmp_ok(_ITSA($iv),      '==', 2, "\$iv is IV");
my $iv_copy = $iv;
my $iv_x = "$iv";
cmp_ok(_ITSA($iv),      '==', 2, "\$iv is still IV");
$iv_x -= 2;
cmp_ok(_ITSA($iv_x),    '==', 2, "\$iv_x is also IV");
cmp_ok(_ITSA($iv_copy), '==', 2, "\$iv_copy is IV");

my $iv2 = 14411;
$foo = 112 / $iv2;
cmp_ok(_ITSA($iv2), '==', 2, "\$iv2 is still IV");

my $pv1 = "$uv_max";
cmp_ok(_ITSA($pv1),     '==', 4, "\$pv1 is PV");
$pv1 -= 1;
cmp_ok(_ITSA($pv1),     '==', 1, "\$pv1 is now UV");
$pv1 >>= 1;
cmp_ok(_ITSA($pv1),     '==', 2, "$pv1 is IV");

my $pv2 = "2.3";
cmp_ok(_ITSA($pv2),     '==', 4, "\$pv2 is PV");
$pv2 -= 1;
cmp_ok(_ITSA($pv2),     '==', 3, "\$pv2 is now NV");

my $nv = 1.2e-11;
cmp_ok(_ITSA($nv),      '==', 3, "\$nv is NV");
my $nv_copy = $nv;
my $nv_x = "$nv";
cmp_ok(_ITSA($nv),      '==', 3, "\$nv is still NV");
$nv -= 2;
cmp_ok(_ITSA($nv),      '==', 3, "$nv is also NV");
cmp_ok(_ITSA($nv_copy), '==', 3, "\$nv_copy is NV");

my $nv2 = 2.3;
$nv = $nv2 / 2;
cmp_ok(_ITSA($nv2),      '==', 3, "\$nv2 is still NV");

$foo = $inf1 / 2;
cmp_ok(_ITSA($inf1),      '==', 3, "\$inf1 is still NV");

$foo = $inf2 / $inf2;
cmp_ok(_ITSA($inf2),      '==', 3, "\$inf2 is still NV");

$foo = $nan1 / 2;
cmp_ok(_ITSA($nan1),      '==', 3, "\$nan1 is still NV");

$foo = $nan2 / $nan2;
cmp_ok(_ITSA($nan2),      '==', 3, "\$nan2 is still NV");

my $pv3 = '987654' x 100;
cmp_ok(_ITSA($pv3),     '==', 4, "\$pv3 is PV");
cmp_ok($pv3, '>=', 0, "\$pv3 >= 0"); # NOK flag is now set, but we want
                                     # to use the value in the PV slot

cmp_ok(_ITSA($pv3),     '==', 4, "\$pv3 is still PV");
cmp_ok($pv3, 'eq', '987654' x 100, "\$pv3 PV slot is unchanged");

my $pv4 = sprintf "%u", ~0;
$foo = $pv4 + 1; # $pv4 should now be seen as UV, though it
                 # would be ok if it were still seen as PV

cmp_ok(_ITSA($pv4),     '==', 1, "\$pv4 is now UV");
cmp_ok($pv4, 'eq', sprintf("%u", ~0), "\$pv4 PV slot is unchanged");

my $pv5 = sprintf("%u", ~0) . 'xyz';

{
  no warnings 'numeric';
  $foo = $pv5 + 1; # $pv5 should still be seen as PV
}

cmp_ok(_ITSA($pv5),     '==', 4, "\$pv5 is still PV");
cmp_ok($pv5, 'eq', sprintf("%u", ~0) . 'xyz', "\$pv5 PV slot is unchanged");


done_testing();
