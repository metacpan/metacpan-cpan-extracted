#!perl -T

use strict;
use warnings;

use Test::More tests => 31;

use Math::AnyNum qw(:overload);

is(655870882787,                Math::AnyNum->new("655870882787"));
is(655870882787,                Math::AnyNum->new(655870882787));
is(655870882787 / 409205648497, "655870882787/409205648497");

is(-660131804286 / 409205648497, "-660131804286/409205648497");
is(-3147483648,                  "-3147483648");

is(Math::AnyNum->new("-3147483648"), "-3147483648");
is(Math::AnyNum->new("-1147483648"), "-1147483648");

is(2**255, '578960446186580977117854925043439539266' . '34992332820282019728792003956564819968', '2 ** 255');

is(ref(0xff),  'Math::AnyNum');
is(ref(0123),  'Math::AnyNum');
is(ref(0b101), 'Math::AnyNum');

# hexadecimal constants
is(0x123456ff, Math::AnyNum->new('123456ff', '16'), 'hexadecimal constant');

# binary constants
is(0b0101010001100, Math::AnyNum->new('0101010001100', '2'), 'binary constant');

# octal constants
is(01234567, Math::AnyNum->new('1234567', '8'), 'octal constant');

my $x = 2 + 4.5;    # AnyNum 6.5
is("$x", "6.5");

my $inf = Inf * Inf;
like($inf, qr/^inf/i);

my $ninf = Inf * -1;
like($ninf, qr/^-inf/i);

my $nan = 3 * NaN;
is("$nan", "NaN");

$nan = Inf / Inf;
is("$nan", "NaN");

$nan = NaN + 2;
is("$nan", "NaN");

$nan = NaN / 2;
is("$nan", "NaN");

is(.5,          0.5);
is(1.23345e10,  "12334500000");
is(1.23445e-10, "0.000000000123445");
is(100_000_000, "100000000");

is(727, 0x2d7);
is(727, 01327);
is(727, 0b1011010111);

is(atan2(0, 0), 0);
like(atan2(0, -1), qr/^3.1415/);

like(1.0 / 3.0, qr/^0.333333333/, '1.0 / 3.0 = 0.333333333...');
