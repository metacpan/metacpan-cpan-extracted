use strict;
use warnings;
use Math::Int113;
use Config;

use Test::More;

cmp_ok($Math::Int113::VERSION, 'eq', '0.02', "version number is as expected");

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

done_testing();
