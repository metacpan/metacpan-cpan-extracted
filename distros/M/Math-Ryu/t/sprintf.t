# We check that spanyf(@args) returns the
# same string that pany(@args) outputs.
use strict;
use warnings;
use Config;
use Math::BigInt;
use Math::Ryu qw(:all);
use Test::More;

my $nv = 1.4 / 10;
my $mbi = Math::BigInt->new(21) ** 10;
my $ref = \$nv;

my @args = (
'hello world', ' ',
$nv, ' ', "NV: $nv", ' ',
$mbi, ' ', 123456789, ' ', '987654321', ' ',
2 ** 30, ' ', -(2 ** 29), ' ', '14_', ' ', '7.3a'
);

my $dig = Math::Ryu::MAX_DEC_DIG;
my $nv_str = $dig == 17 ? '0.13999999999999999'
                        : $dig == 21 ? '0.14'
                                     : '0.13999999999999999999999999999999999';

cmp_ok(spanyf(@args), 'eq',
      "hello world $nv_str NV: 0.14 16679880978201 123456789 987654321 1073741824 -536870912 14_ 7.3a",
      'returned string is as expected');

my $str = spanyf($ref);
like($str, qr/^SCALAR\(0/, "$str starts correctly");
like($str, qr/[a-fA-F0-9]\)$/, "$str ends correctly");

$str = nv2s($ref);
like($str, qr/\d\.0$/, "nv2s() returns a number when handed a scalar reference");

$str = '6.5rubbish';
cmp_ok(n2s($str), 'eq', '6.5', "n2s('6.5 rubbish') handled as expected");

my $test = 'hello world' + 0;
# $test is an IV on old perls, but an NV from about 5.12.0 onwards.
# We must therefore taylor the next test to cater for both possibilities.
my $expected = '0.0';              # Assume $test is an NV.
$expected = 0 if ryu_SvIOK($test); # Make correction if $test is an IV.

cmp_ok(n2s('hello world'), 'eq', $expected, "n2s('hello world') returns $expected");

my $newstr = spanyf($str);
cmp_ok($newstr, 'eq', '6.5rubbish', "string is still assessed by spanyf() as '6.5rubbish'");

eval{my $s = n2s($mbi);};
like($@, qr/^The n2s\(\) function does not accept/, "passing of a reference to n2s() is disallowed");

$str = '9' x 5000;
$nv = $str + 0;

cmp_ok(spanyf($nv, ' ', $str), 'eq', "inf $str", "conforms to usual perl practice");

if($Config{ivsize} == 8) {
  $str = '-9223372036854775808';
  my $dis = $str + 1.23;
  cmp_ok(spanyf($str + 0), 'eq', '-9223372036854775808', "('$str' + 0) is treated as IV");
}

$str = spanyf(-9223372036854775810);

if(Math::Ryu::MAX_DEC_DIG == 17) {
  # Some explanation:
  # For nvtype of double, -9223372036854775810 will be rounded to the NV -9.2233720368547758e+18,
  # which fits into an IV if IVSIZE is 8. Therefore spany() will present it as -9223372036854775808
  if($Config{ivsize} == 8) {
    cmp_ok($str, 'eq', '-9223372036854775808',   "1: '-9223372036854775810 is handled as expected");
  }
  else {
    # IVSIZE == 4, so the rounded double won't fit into an IV, and spanyf() will present it as -9.223372036854776e+18
    cmp_ok($str, 'eq', '-9.223372036854776e+18', "2: '-9223372036854775810' is handled as expected");
  }
}
else {
  # It will be handled as an NV, with no loss of precision or value.
  cmp_ok(  $str, 'eq', '-9223372036854775810.0', "3: '-9223372036854775810' is handled as expected");
}

done_testing();
