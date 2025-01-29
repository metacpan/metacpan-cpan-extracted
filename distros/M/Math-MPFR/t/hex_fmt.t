# Test mpfr's sprintf() and snprintf() functions with "%a" formatting.
# I assume that Rmpfr_printf() and Rmpfr_fprintf() will handle this formatting
# in exactly the same way. Tests involving Rmpfr_printf() and Rmpfr_fprintf()
# will be added if evidence contrary to my assumption arises.
# I think that trailing mantissa zeros are frowned upon, but these tests will
# accept them.
# On windows, gmp_sprintf() presents the trailing zeroes.
#
# Also we test nv2mpfr() as that sub is used by Rmpfr_*printf in these tests
# if WIN32_FMT_BUG is set. In such instances, 'Rmpfr_printf("%a", $nv)' will
# be replaced by "Rmpfr_printf("%Ra", nv2mpfr($nv)' - and similarly for the
# other Rmpfr_*printf() functions.

use strict;
use warnings;
use Config;
use Math::MPFR qw(:mpfr);

use Test::More;

my $nv = 1.0078125; # 0x1.02p+0
my $obj = Math::MPFR->new($nv);
my $buflen = 16;
my ($buf, $ret);

# 0x1.02p+0 ==  0x2.04p-1 == 0x4.08p-2 == 0x8.1p-3;
# Allow for any one of them to appear at any time.
# In the sprintf tests:
# "%a%: ^0x1\.02(0+)?p\+0$|^0x2\.04(0+)?p\-1$|^0x4\.08(0+)?p\-2$|^0x8\.1(0+)?p\-3$
# "%A": ^0X1\.02(0+)?P\+0$|^0X2\.04(0+)?P\-1$|^0X4\.08(0+)?P\-2$|^0X8\.1(0+)?P\-3$
#In the snprintf tests:
# "%a": ^0x1\.0$|^0x2\.0$|^0x4\.0$|^0x8\.1$
# "%A": ^0X1\.0$|^0X2\.0$|^0X4\.0$|^0X8\.1$

### nv2mpfr tests

my $s =  '1.3';
my $nv2mpfr =  1.3;
my $op = Math::MPFR->new(1.3);

cmp_ok(nv2mpfr($nv2mpfr), '==', $nv2mpfr, "equivalence holds for all NV precisions");
if($Config{nvsize} == 8) {
  cmp_ok(nv2mpfr($s), '==', $s, "string equivalence holds for 'double' precision");
  cmp_ok(nv2mpfr($op), '==', $op, "mpfr object equivalence holds for 'double' precision");
}
else {
  cmp_ok(nv2mpfr($s), '!=', $s, "no string equivalence for non 'double' precision");
  cmp_ok(nv2mpfr($op), '==', $op, "no mpfr object equivalence for non 'double' precision");
}

### sprintf tests on NV

if($Config{nvtype} eq 'double') {
  # "%a"/"%A" formatting of an NV is not expected to work
  # unless $Config{nvtype} is 'double'.
  $ret = Rmpfr_sprintf($buf, "%a", $nv, 16);
  like($buf, qr/^0x1.02(0+)?p\+0$|^0x2\.04p\-1$|^0x4\.08p\-2$|^0x8\.1p\-3$/, "\"%a\" (mpfr) formatting of NV as expected");
  cmp_ok($ret, '==', length($buf),  "\"%a\" (mpfr) formatting of NV returned correct value");

  $ret = Rmpfr_sprintf($buf, "%A", $nv, 16);
  like($buf, qr/^0X1.02(0+)?P\+0$|^0X2\.04P\-1$|^0X4\.08P\-2$|^0X8\.1P\-3$/, "\"%A\" (mpfr) formatting of NV as expected");
  cmp_ok($ret, '==', length($buf),  "\"%A\" (mpfr) formatting of NV returned correct value");
}

if($Config{nvtype} eq 'long double') {
  # "%La"/"%LA" formatting of an NV is not expected to work
  # unless $Config{nvtype} is 'long double'.
  $ret = Rmpfr_sprintf($buf, "%La", $nv, 16);
  like($buf, qr/^0x1\.02(0+)?p\+0$|^0x2\.04(0+)?p\-1$|^0x4\.08(0+)?p\-2$|^0x8\.1(0+)?p\-3$/, "\"%La\" formatting of NV as expected");
  cmp_ok($ret, '==', length($buf), "\"%La\" formatting of NV returned correct value");

  $ret = Rmpfr_sprintf($buf, "%LA", $nv, 16);
  like($buf, qr/^0X1\.02(0+)?P\+0$|^0X2\.04(0+)?P\-1$|^0X4\.08(0+)?P\-2$|^0X8\.1(0+)?P\-3$/, "\"%LA\" formatting of NV as expected");
  cmp_ok($ret, '==', length($buf), "\"%LA\" formatting of NV returned correct value");
}

### sprintf tests on MPFR object

$ret = Rmpfr_sprintf($buf, "%Ra", $obj, 16);
cmp_ok($buf, 'eq', '0x1.02p+0', "\"%a\" formatting of MPFR object as expected");
cmp_ok($ret, '==', length($buf), "\"%a\" formatting of MPFR object returned correct value");

$ret = Rmpfr_sprintf($buf, "%RA", $obj, 16);
cmp_ok($buf, 'eq', '0X1.02P+0', "\"%A\" formatting of MPFR object as expected");
cmp_ok($ret, '==', length($buf), "\"%A\" formatting of MPFR object returned correct value");

################################################################
################################################################

### snprintf tests on NV

if($Config{nvtype} eq 'double') {
  # "%a"/"%A" formatting of an NV is not expected to work
  # unless $Config{nvtype} is 'double'.
  $ret = Rmpfr_snprintf($buf, 6, "%a", $nv, 16);
  like($buf, qr/^0x1\.0$|^0x2\.0$|^0x4\.0$|^0x8\.1$/, "\"%a\" (snprintf) formatting of NV as expected");
  my $expectation = 9;
  $expectation = 8 if $buf =~ /^0x8/i;
  cmp_ok($ret, '==', $expectation, "\"%a\" (snprintf) formatting of NV returned correct value");

  $ret = Rmpfr_snprintf($buf, 6, "%A", $nv, 16);
  like($buf, qr/^0X1\.0$|^0X2\.0$|^0X4\.0$|^0X8\.1$/, "\"%A\" (snprintf) formatting of NV as expected");
  $expectation = 9;
  $expectation = 8 if $buf =~ /^0x8/i;
  cmp_ok($ret, '==', $expectation, "\"%A\" (snprintf) formatting of NV returned correct value");
}

if($Config{nvtype} eq 'long double') {
  # "%La"/"%LA" formatting of an NV is not expected to work
  # unless $Config{nvtype} is 'long double'.
  my $returned = 9;
  $ret = Rmpfr_snprintf($buf, 6, "%La", $nv, 16);
  like($buf, qr/^0x1\.0$|^0x2\.0$|^0x4\.0$|^0x8\.1$/, "\"%La\" (mpfr snprintf) formatting of NV as expected");
  $returned = 8 if $buf =~ /0x8/i;
  cmp_ok($ret, '==', $returned,                       "\"%La\" (mpfr snprintf) formatting of NV returned correct value");

  $ret = Rmpfr_snprintf($buf, 6, "%LA", $nv, 16);
  like($buf, qr/^0X1\.0$|^0X2\.0$|^0X4\.0$|^0X8\.1$/, "\"%LA\" (mpfr snprintf) formatting of NV as expected");
  cmp_ok($ret, '==', $returned,                       "\"%LA\" (snprintf) formatting of NV returned correct value");
}

### snprintf tests on MPFR object
$ret = Rmpfr_snprintf($buf, 6, "%Ra", $obj, 16);
cmp_ok($buf, 'eq', '0x1.0', "\"%a\" (snprintf) formatting of MPFR object as expected");
cmp_ok($ret, '==', 9, "\"%a\" (snprintf) formatting of MPFR object returned correct value");

$ret = Rmpfr_snprintf($buf, 6, "%RA", $obj, 16);
cmp_ok($buf, 'eq', '0X1.0', "\"%A\" (snprintf) formatting of MPFR object as expected");
cmp_ok($ret, '==', 9, "\"%A\" (snprintf) formatting of MPFR object returned correct value");

################################################################
################################################################

# "%a" formatting error tests

unless($Config{nvtype} eq 'double') {
  eval { Rmpfr_sprintf($buf, " %%A %a %% ", $nv, 16) };
  like($@, qr/"%a" formatting applies only to doubles/, '"%a" formatting allowed only for doubles');

  eval { Rmpfr_sprintf($buf, " %%a %A %% ", $nv, 16) };
  like($@, qr/"%A" formatting applies only to doubles/, '"%A" formatting allowed only for doubles');
}

unless($Config{nvtype} eq 'long double') {
  eval { Rmpfr_sprintf($buf, " %%LA %La %% ", $nv, 16) };
  like($@, qr/"%La" formatting applies only to long doubles/, '"%La" formatting allowed only for long doubles');

  eval { Rmpfr_sprintf($buf, " %%La %LA %% ", $nv, 16) };
  like($@, qr/"%LA" formatting applies only to long doubles/, '"%LA" formatting allowed only for long doubles');
}

eval { Rmpfr_sprintf($buf, " %%a %A %% ", Math::MPFR->new($nv), 16) };
like($@, qr/"%A" formatting applies only to NVs/, '"%A" formatting disallowed for Math::MPFR objects');

done_testing();
