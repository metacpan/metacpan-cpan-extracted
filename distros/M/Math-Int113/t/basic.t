use strict;
use warnings;
use Math::Int113;
use Config;

use Test::More;

cmp_ok($Math::Int113::VERSION, 'eq', '0.05', "version number is as expected");

my $obj1 = Math::Int113->new(~0);

if($Config{ivsize} == 4) {
  $obj1 **= 2;
  cmp_ok($obj1, '==', 18446744065119617025, "overload **= with integer exponent ok");
  $obj1 += 8589934590;
  cmp_ok($obj1, '==', 18446744073709551615, "overload += ok");
}

cmp_ok($obj1, '==', 18446744073709551615, "value is 18446744073709551615");

$obj1 *= 10000;
cmp_ok($obj1, '==', 184467440737095516150000, "overload *= ok");

cmp_ok($obj1 + 11, '==', $obj1 + 11.9999, "overload '+' ok with fractional value");
cmp_ok($obj1 - 11, '==', $obj1 - 11.9999, "overload '-' ok with fractional value");
cmp_ok($obj1 * 11, '==', $obj1 * 11.9999, "overload '*' ok with fractional value");
cmp_ok($obj1 / 11, '==', $obj1 / 11.9999, "overload '/' ok with fractional value");

cmp_ok(11 - $obj1, '==', -184467440737095516149989, "overload '-' ok with reversed args");
cmp_ok(11.99999 - $obj1, '==', -184467440737095516149989, "overload '-' ok with reversed args && fractional value");

cmp_ok(11 / $obj1, '==', 0, "overload '/' ok with reversed args");
cmp_ok(11.99999 / $obj1, '==', 0, "overload '/' ok with reversed args && fractional value");

$obj1 **= 0.5;
cmp_ok($obj1, '==', 429496729599, "overload '**=' with fractional exponent ok");

my $obj2 = $obj1 ** 2.5;
cmp_ok($obj2, '==', 120892581960759230028842188800, "overload '**' with fractional exponent ok");
cmp_ok(2.5 ** Math::Int113->new(4), '==', 39, "overload '**' with reversed args && fractional exponent ok");

$obj2++;
cmp_ok($obj2, '==', 120892581960759230028842188801, "overload '++' ok");

$obj2--;
cmp_ok($obj2, '==', 120892581960759230028842188800, "overload '--' ok");

cmp_ok(99999, '<', $obj2,  "overload '<' ok");
cmp_ok(99999, '<=', $obj2, "overload '<=' ok");
cmp_ok(120892581960759230028842188800, '<=', $obj2, "overload '<=' ok with equivalent values");

cmp_ok($obj2, '>', 99999 , "overload '>' ok");
cmp_ok($obj2, '>=', 99999, "overload '>=' ok");
cmp_ok($obj2, '>=', 120892581960759230028842188800, "overload '>=' ok with equivalent values");
{
  no warnings 'uninitialized';
  cmp_ok(Math::Int113->new(undef), '==', 0, "undef treated as 0");
}
{
  no warnings 'numeric';
  cmp_ok(Math::Int113->new('hello'), '==', 0, "'hello' treated as 0");
}
cmp_ok(Math::Int113->new(0.9999), '==', 0, "0.9999 treated as 0");
cmp_ok(Math::Int113->new('0.9999' . ('9' x 60)), '==', 1, "'0.9999' . ('9' x 60) treated as 1");

my $num = 1.0384503717069655257060992658440192e34;
my $div = 1.0384593717069655257060992658440192e30;
my $mnum = Math::Int113->new($num);
my $mdiv = Math::Int113->new($div);

my $rem = $mnum % $div;
cmp_ok($rem, '==', Math::Int113->new(948459371706965525706099266036), "overload '%' with NV divisor ok");

$rem = $num % $mdiv;
cmp_ok($rem, '==', Math::Int113->new(948459371706965525706099266036), "overload '%' NV numerator ok");

$rem = $mnum % $mdiv;
cmp_ok($rem, '==', Math::Int113->new(948459371706965525706099266036), "overload '%' ok");

$mnum %= $div;
cmp_ok($mnum, '==', $rem, "overload '%=' with NV divisor ok");

$num %= $mdiv;
cmp_ok(ref($num), 'eq', 'Math::Int113', "overloaded '%=' converts NV to Math::Int113 object");
cmp_ok($num, '==', $rem, "overload '%=' with NV numerator ok");

$num %= Math::Int113->new(9384593717069655257060992660);
cmp_ok($num, '==', 615406282930344742939007376, "overload '%=' ok");

my $x = Math::Int113->new(42) >> 113;
cmp_ok($x, '==', 0, ">> 113 returns 0");

$x = Math::Int113->new(42) << 113;
cmp_ok($x, '==', 0, "<< 113 returns 0");

my $expected_refcnt = 1;
$expected_refcnt++
  if $Config{ccflags} =~ /\-DPERL_RC_STACK/;

cmp_ok(Math::Int113::get_refcnt($obj1), '==', $expected_refcnt, '$obj1 reference count ok');
cmp_ok(Math::Int113::get_refcnt($obj2), '==', $expected_refcnt, '$obj2 reference count ok');
cmp_ok(Math::Int113::get_refcnt($num),  '==', $expected_refcnt, '$num reference count ok' );
cmp_ok(Math::Int113::get_refcnt($div),  '==', $expected_refcnt, '$div reference count ok' );
cmp_ok(Math::Int113::get_refcnt($rem),  '==', $expected_refcnt, '$rem reference count ok' );
cmp_ok(Math::Int113::get_refcnt($mnum), '==', $expected_refcnt, '$mnum reference count ok');
cmp_ok(Math::Int113::get_refcnt($mdiv), '==', $expected_refcnt, '$mdiv reference count ok');

for(1 .. 100) {
  my $iv1 = int(rand(~0));
  my $iv2 = int(rand(sqrt(~0)));
  my $int113_1 = Math::Int113->new($iv1);
  my $int113_2 = Math::Int113->new($iv2);

#print "$iv1 $iv2\n";

  cmp_ok($iv1 & $iv2, '==', $int113_1 & $int113_2, "$iv1 & $iv2 ok");
  cmp_ok($iv1 & $int113_2, '==', $int113_1 & $iv2, "$iv1 & $iv2 (mixed types) ok");
  cmp_ok($iv1 | $iv2, '==', $int113_1 | $int113_2, "$iv1 | $iv2 ok");
  cmp_ok($iv1 | $int113_2, '==', $int113_1 | $iv2, "$iv1 | $iv2 (mixed types) ok");
  cmp_ok($iv1 ^ $iv2, '==', $int113_1 ^ $int113_2, "$iv1 ^ $iv2 ok");
  cmp_ok($iv1 ^ $int113_2, '==', $int113_1 ^ $iv2, "$iv1 ^ $iv2 (mixed types) ok");
}

cmp_ok(Math::Int113->new(1) << 112, '==', 5192296858534827628530496329220096, 'Math::Int113->new(1) << 112 == 5192296858534827628530496329220096');
cmp_ok(Math::Int113->new(1) << 112, '==', $Math::Int113::MAX_OBJ << 112, 'Math::Int113->new(1) << 112 == $Math::Int113::MAX_OBJ << 112');
cmp_ok(Math::Int113->new(17) << 113, '==', 0, 'Math::Int113->new(17) << 113 == 0');
cmp_ok(Math::Int113->new(2) << 112, '==', 0, 'Math::Int113->new(2) << 112 == 0');


done_testing();
