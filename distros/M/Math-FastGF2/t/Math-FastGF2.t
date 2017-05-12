# -*- Perl -*-

use Test::More tests => 59;
BEGIN { use_ok('Math::FastGF2', ':all') };

# just a few random multiplies first
ok(gf2_mul(8,0x53,0xca) == 1, "{53} x {CA} == 1");
ok(gf2_mul(16,0x1b1,0xc350) == 0x76fa,
   "{01B1} x {C350} == {76FA}");
ok(gf2_mul(32,0xfacecafe,0xdeadbeef)==0xf64162cb,
   "{facecafe} x {deadbeef} == {f64162cb}");

# test inverses
my @v8 =(2,3,4,17,19,26,27,28,32,64,99,128,140,234,252,253,254,255);
my @v16=(2,3,140,252,255,256,257,667,1024,2401,32768,39067,44732,65535);
my @v32=(2,3,140,252,255,256,257,1024,32768,49152,44732,65535,65536,
	 0x0023544b,0x12483579,0xc04faced,0xf0d1cebd,0xffffffff);
my ($V8,$V16,$V32)=(scalar(@v8),scalar(@v16),scalar(@v32));

# first, check that 0 and 1 are set to be their own inverses
# (note that while inv(0) isn't defined, we'll set it to 0)
ok(gf2_inv(8,0)==0,  "inv(0) == 0 (8-bit)");
ok(gf2_inv(16,0)==0, "inv(0) == 0 (16-bit)");
ok(gf2_inv(32,0)==0, "inv(0) == 0 (32-bit)");
ok(gf2_inv(8,1)==1,  "inv(1) == 1 (8-bit)");
ok(gf2_inv(16,1)==1, "inv(1) == 1 (16-bit)");
ok(gf2_inv(32,1)==1, "inv(1) == 1 (32-bit)");

# by definition, a value multiplied by its inverse is 1
# (inv(0) notwithstanding)
my $failed=0;
foreach my $v (@v8) {
  ++$failed unless gf2_mul(8,$v,gf2_inv(8,$v)) == 1;
} ok(($failed == 0), "8-bit inverse test (failed $failed/$V8)");
$failed=0;
foreach my $v (@v16) {
  ++$failed unless  gf2_mul (16, $v, gf2_inv(16,$v)) == 1;
} ok(($failed == 0), "16-bit inverse test (failed $failed/$V16)");
$failed=0;
foreach my $v (@v32) {
  ++$failed unless gf2_mul(32,$v,gf2_inv(32,$v)) == 1;
} ok(($failed == 0), "32-bit inverse test (failed $failed/$V32)");

# test powers
ok(gf2_pow(8,0,0) ==1, "pow(0,0) == 1 (8-bit)");
ok(gf2_pow(16,0,0)==1, "pow(0,0) == 1 (16-bit)");
ok(gf2_pow(32,0,0)==1, "pow(0,0) == 1 (32-bit)");

ok(gf2_pow(8,1,0) ==1, "pow(1,0) == 1 (8-bit)");
ok(gf2_pow(16,1,0)==1, "pow(1,0) == 1 (16-bit)");
ok(gf2_pow(32,1,0)==1, "pow(1,0) == 1 (32-bit)");

ok(gf2_pow(8,0,1) ==0, "pow(0,1) == 0 (8-bit)");
ok(gf2_pow(16,0,1)==0, "pow(0,1) == 0 (16-bit)");
ok(gf2_pow(32,0,1)==0, "pow(0,1) == 0 (32-bit)");

# pick one other number to test powers of 0, 1
ok(gf2_pow(8,255,0) ==1,      "pow(max,0) == 1 (8-bit)");
ok(gf2_pow(16,65535,0)==1,    "pow(max,0) == 1 (16-bit)");
ok(gf2_pow(32,2**32 -1,0)==1, "pow(max,0) == 1 (32-bit)");

ok(gf2_pow(8,255,1)     == 255,       "pow(max,1) == max (8-bit)");
ok(gf2_pow(16,65535,1)  == 65535,     "pow(max,1) == max (16-bit)");
ok(gf2_pow(32,2**32 -1,1)== 2**32 -1, "pow(max,1) == max (32-bit)");

# Now check that a^max == a^0 == 1
$failed=0;
foreach my $v (@v8) {
  ++$failed unless gf2_pow(8,$v,255) == 1;
} ok(($failed == 0), "8-bit a ^ max == a ^ 0 (failed $failed/$V8)");
$failed=0;
foreach my $v (@v16) {
  ++$failed unless  gf2_pow(16, $v, 65535) == 1;
} ok(($failed == 0), "16-bit a ^ max == a ^ 0 (failed $failed/$V16)");
$failed=0;
foreach my $v (@v32) {
  ++$failed unless gf2_pow(32,$v,2**32-1) == 1;
} ok(($failed == 0), "32-bit a ^ max == a ^ 0 (failed $failed/$V32)");

# Now check that a^2 = a * a
$failed=0;
foreach my $v (@v8) {
  ++$failed unless gf2_pow(8,$v,2) == gf2_mul(8,$v,$v);
} ok(($failed == 0), "8-bit a^2 == a*a (failed $failed/$V8)");
$failed=0;
foreach my $v (@v16) {
  ++$failed unless  gf2_pow(16, $v, 2) == gf2_mul(16,$v,$v);
} ok(($failed == 0), "16-bit a^2 == a*a (failed $failed/$V16)");
$failed=0;
foreach my $v (@v32) {
  ++$failed unless gf2_pow(32,$v,2) == gf2_mul(32,$v,$v);
} ok(($failed == 0), "32-bit a^2 == a*a (failed $failed/$V32)");

# Now check that a^3 = a * a * a (by induction all other powers should
# be OK)
$failed=0;
foreach my $v (@v8) {
  ++$failed unless gf2_pow(8,$v,3) == gf2_mul(8,$v,gf2_mul(8,$v,$v));
} ok(($failed == 0), "8-bit a^3 == a*a*a (failed $failed/$V8)");
$failed=0;
foreach my $v (@v16) {
  ++$failed unless  gf2_pow(16,$v,3) == gf2_mul(16,$v,gf2_mul(16,$v,$v));
} ok(($failed == 0), "16-bit a^3 == a*a*a (failed $failed/$V16)");
$failed=0;
foreach my $v (@v32) {
  ++$failed unless gf2_pow(32,$v,3) == gf2_mul(32,$v,gf2_mul(32,$v,$v));
} ok(($failed == 0), "32-bit a^3 == a*a*a (failed $failed/$V32)");

# One more test for powers... is a^(max-1) == a^(-1)?
$failed=0;
foreach my $v (@v8) {
  ++$failed unless gf2_pow(8,$v,254) == gf2_inv(8,$v);
} ok(($failed == 0), "8-bit inv using pow (failed $failed/$V8)");
$failed=0;
foreach my $v (@v16) {
  ++$failed unless  gf2_pow(16,$v,65534) == gf2_inv(16,$v);
} ok(($failed == 0), "16-bit inv using pow (failed $failed/$V16)");
$failed=0;
foreach my $v (@v32) {
  ++$failed unless gf2_pow(32,$v,2**32 - 2) == gf2_inv(32,$v);
} ok(($failed == 0), "32-bit inv using pow (failed $failed/$V32)");

# not so many tests for division... we can check that a/b == a *
# inv(b), but some of the routines simplify to that anyway.
my $u;
$failed=0; $u=$v8[0];
foreach my $v (@v8) {
  ++$failed unless gf2_div(8,$u,$v) == gf2_mul(8,$u,gf2_inv(8,$v));
  $u=$v;
} ok(($failed == 0), "8-bit a/b == a*inv(b) (failed $failed/$V8)");
$failed=0; $u=$v16[0];
foreach my $v (@v16) {
  ++$failed unless gf2_div(16,$u,$v) == gf2_mul(16,$u,gf2_inv(16,$v));
  $u=$v;
} ok(($failed == 0), "16-bit a/b == a*inv(b) (failed $failed/$V16)");
$failed=0; $u=$v32[0];
foreach my $v (@v32) {
  ++$failed unless gf2_div(32,$u,$v) == gf2_mul(32,$u,gf2_inv(32,$v));
  $u=$v;
} ok(($failed == 0), "32-bit a/b == a*inv(b) (failed $failed/$V32)");

# There is one other test we can do to check division. Since we have a
# working power function (assuming the above tests passed) and it
# doesn't use the inverse routine, we can check division by testing
# whether a^(b-1) == a^b / a.
$failed=0; $u=$v8[0];
foreach my $v (@v8) {
  ++$failed unless gf2_pow(8,$u,$v-1) == gf2_div(8,gf2_pow(8,$u,$v),$u);
  $u=$v;
} ok(($failed == 0), "8-bit a/b == a*inv(b) (failed $failed/$V8)");
$failed=0; $u=$v16[0];
foreach my $v (@v16) {
  ++$failed unless gf2_pow(16,$u,$v-1) == gf2_div(16,gf2_pow(16,$u,$v),$u);
  $u=$v;
} ok(($failed == 0), "16-bit a/b == a*inv(b) (failed $failed/$V16)");
$failed=0; $u=$v32[0];
foreach my $v (@v32) {
  ++$failed unless gf2_pow(32,$u,$v-1) == gf2_div(32,gf2_pow(32,$u,$v),$u);
  $u=$v;
} ok(($failed == 0), "32-bit a/b == a*inv(b) (failed $failed/$V32)");

# Some final (simple) tests on division: a/1==a and a/0==0
$failed=0;
foreach my $v (@v8) {
  ++$failed unless gf2_div(8,$v,1) == $v;
} ok(($failed == 0), "8-bit a/1 == a (failed $failed/$V8)");
$failed=0;
foreach my $v (@v16) {
  ++$failed unless gf2_div(16,$v,1) == $v
} ok(($failed == 0), "16-bit a/1 == a (failed $failed/$V16)");
$failed=0;
foreach my $v (@v32) {
  ++$failed unless gf2_div(32,$v,1) == $v
} ok(($failed == 0), "32-bit a/1 == a (failed $failed/$V32)");

ok(gf2_div(8,1,0)==0, "8-bit 1/0 == 0");
ok(gf2_div(16,1,0)==0, "16-bit 1/0 == 0");
ok(gf2_div(32,1,0)==0, "32-bit 1/0 == 0");

# Known bug, won't fix: 0/0 == 1
# ok(gf2_div(8,0,0)==0, "8-bit 0/0 == 0");

ok(gf2_div(16,0,0)==0, "16-bit 0/0 == 0");
ok(gf2_div(32,0,0)==0, "32-bit 0/0 == 0");

# This value was causing an infinite loop in the u32 inv, due to
# having the wrong polynomial set for u32...
ok(gf2_inv(32,0x54451368) == 0x691eb69e, "wrong u32 poly bug");

# Might as well provide a routine for checking polynomials being used
ok(gf2_info(8) == 0x1b,    "poly for u8 != {11b}");
ok(gf2_info(16) == 0x2b,   "poly for u16 != {1002b}");
ok(gf2_info(32) == 0x8d,   "poly for u32 != {10000008d}");

# Also check on the table space used by the library
ok(gf2_info(0) == 19968,   "table space != 19.5 Kbytes");
