# -*- mode: perl; -*-

use strict;
use warnings;

use Test::More tests => 37;

use Math::BigInt;
use Scalar::Util qw< refaddr >;

my $x;

################################################################################

note('class method, without upgrading');

$x = Math::BigInt -> bpi();
is($x, '3', '$x = Math::BigInt -> bpi()');
is(ref($x), 'Math::BigInt',
   '$x is a Math::BigInt');

$x = Math::BigInt -> bpi(10);
is($x, '3', '$x = Math::BigInt -> bpi(10)');
is(ref($x), 'Math::BigInt',
   '$x is a Math::BigInt');

note('class method, with upgrading');

require Math::BigFloat;
Math::BigInt -> upgrade('Math::BigFloat');

# When no accuracy is specified, default accuracy shall be used.

$x = Math::BigInt -> bpi();
is($x, '3.141592653589793238462643383279502884197', '$x = Math::BigInt -> bpi()');
is(ref($x), "Math::BigFloat",
   '$x is a Math::BigFloat');

# When accuracy is specified, it shall be used.

$x = Math::BigInt -> bpi(10);
is($x, '3.141592654', '$x = Math::BigInt -> bpi(10)');
is(ref($x), "Math::BigFloat",
   '$x is a Math::BigFloat');

# When precision is specified, it shall be used.

$x = Math::BigInt -> bpi(undef, -9);
is($x, '3.141592654', '$x = Math::BigInt -> bpi(undef, -9)');
is(ref($x), "Math::BigFloat",
   '$x is a Math::BigFloat');

################################################################################

Math::BigInt -> upgrade(undef);

note('instance method, without upgrading');

my $y;

$x = Math::BigInt -> new(100);
$y = $x -> bpi();
is($x, '3',
   '$x = Math::BigInt -> new(100); $y = $x -> bpi();');
is(ref($x), 'Math::BigInt',
   '$x is a Math::BigInt');
is(refaddr($x), refaddr($y), '$x and $y are the same object');

$x = Math::BigInt -> new(100);
$y = $x -> bpi(10);
is($x, '3',
   '$x = Math::BigInt -> new(100); $y = $x -> bpi(10);');
is(ref($x), 'Math::BigInt',
   '$x is a Math::BigInt');
is(refaddr($x), refaddr($y), '$x and $y are the same object');

note('instance method, with upgrading');

require Math::BigFloat;
Math::BigInt -> upgrade('Math::BigFloat');

# When no accuracy is specified, default accuracy shall be used.

$x = Math::BigInt -> new(100);
$y = $x -> bpi();
is($x, '3.141592653589793238462643383279502884197',
   '$x = Math::BigInt -> new(100); $y = $x -> bpi();');
is(ref($x), "Math::BigFloat",
   '$x is a Math::BigFloat');
is(refaddr($x), refaddr($y), '$x and $y are the same object');

# When accuracy is specified, it shall be used.

$x = Math::BigInt -> new(100);
$y = $x -> bpi(10);
is($x, '3.141592654',
   '$x = Math::BigInt -> new(100); $y = $x -> bpi(10);');
is(ref($x), "Math::BigFloat",
   '$y is a Math::BigFloat');
is(refaddr($x), refaddr($y), '$x and $y are the same object');

# When precision is specified, it shall be used.

$x = Math::BigInt -> new(100);
$y = $x -> bpi(undef, -9);
is($x, '3.141592654',
   '$x = Math::BigInt -> new(100); $y = $x -> bpi(undef, -9);');
is(ref($x), "Math::BigFloat",
   '$y is a Math::BigFloat');
is(refaddr($x), refaddr($y), '$x and $y are the same object');

# When accuracy is small enough, the result is an integer.

$x = Math::BigInt -> new(100);
$y = $x -> bpi(1);
is($x, '3',
   '$x = Math::BigInt -> new(100); $y = $x -> bpi(10);');
is(ref($x), "Math::BigFloat",
   '$y is a Math::BigFloat');
is(refaddr($x), refaddr($y), '$x and $y are the same object');

# When precision is small enough, the result is an integer.

$x = Math::BigInt -> new(100);
$y = $x -> bpi(undef, 0);
is($x, '3',
   '$x = Math::BigInt -> new(100); $y = $x -> bpi(undef, 0);');
is(ref($x), "Math::BigFloat",
   '$y is a Math::BigFloat');
is(refaddr($x), refaddr($y), '$x and $y are the same object');

note('instance method, with upgrading and downgrading');

# When accuracy is small enough, the result is an integer.

Math::BigFloat -> downgrade("Math::BigInt");

$x = Math::BigInt -> new(100);
$y = $x -> bpi(1);
is($x, '3',
   '$x = Math::BigInt -> new(100); $y = $x -> bpi(1);');
is(ref($x), "Math::BigInt",
   '$y is a Math::BigInt');
is(refaddr($x), refaddr($y), '$x and $y are the same object');

# When precision is small enough, the result is an integer.

$x = Math::BigInt -> new(100);
$y = $x -> bpi(undef, 0);
is($x, '3',
   '$x = Math::BigInt -> new(100); $y = $x -> bpi(undef, 0);');
is(ref($x), "Math::BigInt",
   '$y is a Math::BigInt');
is(refaddr($x), refaddr($y), '$x and $y are the same object');
