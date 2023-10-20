use strict;
use warnings;
use Math::Int113;
use Config;

use Test::More;

cmp_ok($Math::Int113::VERSION, 'eq', '0.03', "version number is as expected");

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

eval { my $x = Math::Int113->new(42) >> 113;};
like ($@, qr/exceeds 112/, ">> 113 disallowed");

eval { my $x = Math::Int113->new(42) << 113;};
like ($@, qr/exceeds 112/, "<< 113 disallowed");

done_testing();
