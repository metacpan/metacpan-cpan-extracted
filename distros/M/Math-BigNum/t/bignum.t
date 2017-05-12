#!perl -T

use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 399;

# Initialization

my $mbn = 'Math::BigNum';

{
    use Math::BigNum qw();
    my $x = Math::BigNum->new("1010", 2);
    is("$x", "10");

    $x = Math::BigNum->new("ff", 16);
    is("$x", "255");

    $x = Math::BigNum->new(255);
    is($x->in_base(16), "ff");

    # 'inf' and 'nan' without base
    is(Math::BigNum->new('inf'),  "Inf");
    is(Math::BigNum->new('-Inf'), "-Inf");
    is(Math::BigNum->new("nan"),  "NaN");
    is(Math::BigNum->new("abc"),  "NaN");

    # 'inf' in base 36
    is(Math::BigNum->new('inf',  36), 24171);
    is(Math::BigNum->new('Inf',  36), 24171);
    is(Math::BigNum->new('-Inf', 36), -24171);

    # 'nan' in base 36
    is(Math::BigNum->new('nan', 36), 30191);
    is(Math::BigNum->new('NaN', 36), 30191);

    # fraction in base 10
    is(Math::BigNum->new('123/45')->as_rat, '41/15');

    # fraction in base 36
    is(Math::BigNum->new("h5/1e", 36),         12.34);
    is(Math::BigNum->new("14/1e", 36)->as_rat, "4/5");

    is($mbn->new('1234'),    '1234');
    is($mbn->new("1234/1"),  '1234');
    is($mbn->new("1234/2"),  '617');
    is($mbn->new("100/1.0"), '100');

    #~ is($mbn->new("10.0/1.0"),       '10');
    #~ is($mbn->new("0.1/10")->as_rat, '1/100');
    #~ is($mbn->new("1e2/1e1"),        '10');

    #~ is($mbn->new("0.1/0.1"), '1');
    #~ is($mbn->new("1e2/10"),  '10');

    is($mbn->new("5/1e2"), '0.05');    # passes by luck

    is($mbn->new("1 / 3")->as_rat,  '1/3');
    is($mbn->new("-1 / 3")->as_rat, '-1/3');
    is($mbn->new("1 / -3")->as_rat, '-1/3');

    $x = $mbn->new("NaN");
    is("$x", "NaN");

    $x = $mbn->new("inf");
    is("$x", "Inf");

    $x = $mbn->new("-inf");
    is("$x", "-Inf");

    $x = $mbn->new("abc");
    is("$x", "NaN");

    $x = $mbn->new("1/");
    is("$x", "NaN");

    $x = $mbn->new("_");
    is("$x", "NaN");

    $x = $mbn->new("+");
    is("$x", "NaN");

    is($mbn->new("7e", 16), '126');

    #~ is($mbn->new("1/1.2")->as_rat,   '5/6');
    #~ is($mbn->new("1.3/1.2")->as_rat, "13/12");
    #~ is($mbn->new("1.2/1")->as_rat,   "6/5");
}

# Basic operations
{
    use Math::BigNum qw(:constant);

    # Division
    my $x = 1 / 3;
    my $y = $x * 3;
    is("$y", "1");

    # as_frac()
    is($x->as_frac, "1/3");

    # numerator/denominator
    my $nu = $x->numerator;
    is("$nu",    "1");
    is(ref($nu), 'Math::BigNum');

    my $de = $x->denominator;
    is("$de",    "3");
    is(ref($de), 'Math::BigNum');

    # (numerator, denominator)
    ($nu, $de) = $x->parts;

    is($nu, 1);
    is($de, 3);

    is(ref($nu), 'Math::BigNum');
    is(ref($de), 'Math::BigNum');

    my $bigstr =
        "46663107721972076340849619428133350245357984132190810"
      . "73429648194760879999661495780447073198807825914312684"
      . "8960413611879125592605458432000000000000000000000000.5";

    # Factorial
    my $fac = ((100->fac + 1) / 2);
    is("$fac", $bigstr);

    $fac = sqrt(1 / (100->fac + 1));
    is("$fac", "1.0351378111756264713204945916571793611614825651372e-79");

    my $bignum = Math::BigNum->new($bigstr);
    is("$bignum", $bigstr);

    $bignum = Math::BigNum->new($bigstr, "10");
    is("$bignum", $bigstr);

    # Division by zero
    my $inf = $x / 0;
    is(ref($inf), 'Math::BigNum::Inf');

    # Negation
    ok($y->neg == -1);

    # Absolute values
    my $n     = 42;
    my $neg_n = -$n;

    is("$neg_n", "-42");

    # Base conversion
    is(10->in_base(2), "1010");

    # Numbers with underscores
    is("1_00" + 2,                  102);
    is(Math::BigNum->new("1_00_2"), 1002);
    is(1_000_100,                   1000100);
}

=for comment
# Complex numbers
{
    use Math::BigNum qw(:constant i);

    my $z = 3 + 4 * i;
    is("$z", "3+4i");

    my $z2 = $z + 2;
    is("$z2", "5+4i");

    my $i = sqrt(-1);
    is("$i", 'i');

    $z = 10->complex;
    is(ref($z), 'Math::BigNum::Complex');

    my $re = $z->re;
    is("$re", "10");

    my $im = $z->im;
    is("$im", "0");

    $z = 3->complex(4);
    is("$z", "3+4i");
}
=cut

# Float
{
    use Math::BigNum qw(:constant);

    my $x = 1.2;
    my $y = 3.4;
    my $z;

    # Addition
    $z = $x + $y;
    is($z, 4.6);

    # Subtraction
    $z = $y - $x;
    is($z, 2.2);

    # Multiplication
    $z = $x * $y;
    is($z, 4.08);

    # Division
    $y += 0.2;
    $z = $y / $x;
    is($z, 3);

    # Square root
    $z = sqrt(25);
    is("$z", "5");

    # Cube root
    $z = 125->cbrt;
    is("$z", "5");

    # Integer square root
    $z = 26->isqrt;
    is($z, 5);

    # bisqrt()
    $z = 1234;
    $z->bisqrt;
    is($z, 35);

    # Sqr
    $z = 3->sqr;
    is("$z", "9");

    # Root
    $z = 125->root(3);
    like("$z", qr/^5(?:\.000|\z)/);

    # as_float() / as_int()
    is($x->as_float,      "1.2");
    is($x->as_float(0),   "1");
    is($y->as_float("1"), "3.6");
    is($z->as_int,        "5");
    is($z->as_int(2),     "101");
    is($y->as_int(10),    "3");
}

# Power
{
    use Math::BigNum qw();

    my $x = Math::BigNum->new(3);
    my $y = Math::BigNum->new(4);

    # Obj**Obj
    my $z = $x**$y;
    is("$z", 3**4);

    # Obj**Scalar
    my $z2 = $x**2;
    is("$z2", 3**2);

    # Scalar**Obj
    my $z3 = 2**$x;
    is("$z3", 2**3);

    my $r = Math::BigNum->new(125)->root(3);
    like("$r", qr/^5\b/);
}

# Mixed arithmetic
{
    use Math::BigNum;

    my $x = Math::BigNum->new(12);
    my $y = $x->div(4);
    is("$y", "3");
    is("$x", "12");

    $x->bdiv(3);
    is("$x", "4");

    $x->bdiv(Math::BigNum->new(2));
    is("$x", "2");

    $x->bmul(5);
    is("$x", "10");

    $x->bmul(Math::BigNum->new(0.5));
    is("$x", "5");

    $x->bsub(1);
    is("$x", "4");

    $x->badd(38);
    is("$x", "42");

    $x->bsub(Math::BigNum->new(10));
    is("$x", "32");

    $x->badd(Math::BigNum->new(3));
    is("$x", "35");

    my $copy = $x->copy;
    $x->bdiv(Math::BigNum->new('5'));
    is("$x",    7);
    is("$copy", 35);

    $x = $copy % 9;
    is("$x", "8");

    $x = $copy % -8;
    is("$x", "-5");

    $copy %= -7;
    is("$copy", "0");

    $x = Math::BigNum->new(335) % -13;
    is("$x", "-3");

    $x = Math::BigNum->new(335);
    $x->bmod(-13);
    is("$x", "-3");

    $x = Math::BigNum->new(335) % -5;
    is("$x", "0");

    $x = Math::BigNum->new(335);
    $x->bmod(-5);
    is("$x", "0");

    $x = Math::BigNum->new(335);
    $x->bmod(Math::BigNum->new("-5"));
    is("$x", "0");

    $x = Math::BigNum->new(335) % Math::BigNum->new("-5.3");
    like("$x", qr/^-4\.[12]/);

    $x = Math::BigNum->new(335) % -5.3;
    like("$x", qr/^-4\.[12]/);

    $x = Math::BigNum->new(-335) % Math::BigNum->new("-3.3");
    like("$x", qr/^-1\.[67]/);

    $x = Math::BigNum->new(-335) % -3.3;
    like("$x", qr/^-1\.[67]/);

    $x = Math::BigNum->new(-335);
    $x->bmod(-3.3);
    like("$x", qr/^-1\.[67]/);

    $x = Math::BigNum->new(-335);
    $x->bmod(Math::BigNum->new("-3.3"));
    like("$x", qr/^-1\.[67]/);

    $x = Math::BigNum->new(335) % Math::BigNum->new("13.3");
    like("$x", qr/^2\.[45]/);

    $x = Math::BigNum->new(335) % 13.3;
    like("$x", qr/^2\.[45]/);

    $x = Math::BigNum->new(-335) % Math::BigNum->new("13.3");
    like("$x", qr/^10\.[78]/);

    $x = Math::BigNum->new(-335);
    $x->bmod(13.3);
    like("$x", qr/^10\.[78]/);

    $x = Math::BigNum->new(-335);
    $x->bmod(Math::BigNum->new("13.3"));
    like("$x", qr/^10\.[78]/);

    $x = Math::BigNum->new(-335) % 13.3;
    like("$x", qr/^10\.[78]/);

    $x = Math::BigNum->new(335) % Math::BigNum->new("-13.3");
    like("$x", qr/^-10\.[78]/);

    $x = Math::BigNum->new(335) % -13.3;
    like("$x", qr/^-10\.[78]/);

    $x = Math::BigNum->new(335);
    $x->bmod(-13.3);
    like("$x", qr/^-10\.[78]/);

    $x = Math::BigNum->new(335);
    $x->bmod(Math::BigNum->new("-13.3"));
    like("$x", qr/^-10\.[78]/);

    $x = Math::BigNum->new(-335) % Math::BigNum->new(-23);
    is("$x", "-13");

    $x = Math::BigNum->new(-335) % -23;
    is("$x", "-13");

    $x = Math::BigNum->new(335) % Math::BigNum->new(23);
    is("$x", "13");

    $x = Math::BigNum->new(335) % 23;
    is("$x", "13");

    $x = Math::BigNum->new(-335) % Math::BigNum->new(23);
    is("$x", "10");

    $x = Math::BigNum->new(-335) % 23;
    is("$x", "10");

    $x = Math::BigNum->new(335) % Math::BigNum->new(-23);
    is("$x", "-10");

    $x = Math::BigNum->new(335) % -23;
    is("$x", "-10");

    $x = Math::BigNum->new(335);
    $x->bmod(-23);
    is("$x", "-10");

    $x = Math::BigNum->new(335);
    $x->bmod(Math::BigNum->new("-23"));
    is("$x", "-10");

    $x = Math::BigNum->new(35) % 5;
    is("$x", "0");

    $x = Math::BigNum->new(35) % Math::BigNum->new(5);
    is("$x", "0");

    $x = Math::BigNum->new(35);
    $x->bmod(5);
    is("$x", "0");

    $x = Math::BigNum->new(35);
    $x->bmod(Math::BigNum->new(5));
    is("$x", "0");

    $x = Math::BigNum->new(1234);
    my ($d, $m) = $x->divmod(Math::BigNum->new(15));
    is("$d", "82");
    is("$m", "4");

    ($d, $m) = $x->divmod(17);
    is("$d", "72");
    is("$m", "10");

    $x = Math::BigNum->new(42);
    $m = $x->modinv(Math::BigNum->new(2017));
    is("$m", "1969");

    $m = $x->modinv(2017);
    is("$m", "1969");

    $x = Math::BigNum->new(16);
    $y = 2 * $x;
    is("$y", "32");

    $y = 2 + $x;
    is("$y", "18");

    $y = 2 - $x;
    is("$y", "-14");

    $y = 2 / $x;
    is("$y", "0.125");

    $y = 2**$x;
    is("$y", "65536");

    $y = 134 % $x;
    is("$y", "6");

    $y = 2 << $x;
    is("$y", "131072");

    $y = 131072 >> $x;
    is("$y", "2");

    $y = 2 | $x;
    is("$y", "18");

    $y = 31 & $x;
    is("$y", "16");

    $y = 42 ^ $x;
    is("$y", "58");
}

# Comparisons
{
    use Math::BigNum qw(:constant);
    ok(3.2 < 4);
    ok(1.5 <= 1.5);
    ok(2.3 <= 3);
    ok(3 > 1.2);
    ok(3 >= 3);
    ok(9 >= 2.1);
    ok(9 == 9);
    ok(!(3 == 4));
    ok(8 != 3);
    ok(!(4 != 4));

    is(4 <=> 4,     "0");
    is(4.2 <=> 4.2, "0");
    is(3.4 <=> 6.4, "-1");
    is(9.4 <=> 2.3, "1");
}

# Mixed comparisons
{
    use Math::BigNum;

    is(4 <=> Math::BigNum->new(4), 0);
    is(3 <=> Math::BigNum->new(4), -1);
    is(4 <=> Math::BigNum->new(3), 1);

    is(2.3 <=> Math::BigNum->new(2), 1);
    is(2 <=> Math::BigNum->new(2.3), -1);

    is(Math::BigNum->new(2) <=> 3, -1);
    is(Math::BigNum->new(4) <=> 2, 1);
    is(Math::BigNum->new(3) <=> 3, 0);

    is(Math::BigNum->new(3.4) <=> 3.4, 0);
    is(Math::BigNum->new(8.3) <=> 2.3, 1);
    is(Math::BigNum->new(1.4) <=> 3,   -1);

    is(3.4 <=> Math::BigNum->new(3.4), 0);
    is(2.3 <=> Math::BigNum->new(8.3), -1);
    is(3.1 <=> Math::BigNum->new(1.4), 1);

    ok(Math::BigNum->new(3) > 1);
    ok(Math::BigNum->new(3.4) > 2.3);
    ok(!(Math::BigNum->new(4) > 5));
    ok(!(Math::BigNum->new(4.3) > 5.7));

    ok(3 > Math::BigNum->new(1));
    ok(3.4 > Math::BigNum->new(2.3));
    ok(!(4 > Math::BigNum->new(5)));
    ok(!(4.3 > Math::BigNum->new(5.7)));

    ok(Math::BigNum->new(9) >= 9);
    ok(Math::BigNum->new(4.5) >= 3.4);
    ok(Math::BigNum->new(5.6) >= 5.6);
    ok(!(Math::BigNum->new(4.3) >= 10.3));
    ok(!(Math::BigNum->new(3) >= 21));

    ok(9 >= Math::BigNum->new(9));
    ok(4.5 >= Math::BigNum->new(3.4));
    ok(5.6 >= Math::BigNum->new(5.6));
    ok(!(4.3 >= Math::BigNum->new(10.3)));
    ok(!(3 >= Math::BigNum->new(21)));

    ok(Math::BigNum->new(1) < 3);
    ok(Math::BigNum->new(2.3) < 3.4);
    ok(!(Math::BigNum->new(5) < 4));
    ok(!(Math::BigNum->new(5.7) < 4.3));

    ok(1 < Math::BigNum->new(3));
    ok(2.3 < Math::BigNum->new(3.4));
    ok(!(5 < Math::BigNum->new(4)));
    ok(!(5.7 < Math::BigNum->new(4.3)));

    ok(Math::BigNum->new(9) <= 9);
    ok(Math::BigNum->new(3.4) <= 4.5);
    ok(Math::BigNum->new(5.6) <= 5.6);
    ok(!(Math::BigNum->new(10.3) <= 4.3));
    ok(!(Math::BigNum->new(21) <= 3));

    ok(9 <= Math::BigNum->new(9));
    ok(3.4 <= Math::BigNum->new(4.5));
    ok(5.6 <= Math::BigNum->new(5.6));
    ok(!(12.3 <= Math::BigNum->new(4.3)));
    ok(!(21 <= Math::BigNum->new(3)));
}

# Integer tests
{
    use Math::BigNum;

    my $x = Math::BigNum->new(42);
    my $y = Math::BigNum->new(1227);

    # 1227^42
    my $int =
        '53885464952588636769288796952610833906623325457053423'
      . '69492596680077919898979278105197183545838519370517708'
      . '740399910496813982887129';

    my $bint = Math::BigNum->new($int);

    is($bint->valuation(-9),    21);
    is($bint->valuation($y),    42);
    is($bint->copy->biroot(42), 1227);

    ok($bint->is_pow(42));
    ok($bint->is_pow($x));

    ok(Math::BigNum->mone->is_pow(3));
    ok(!(Math::BigNum->mone->is_pow(2)));

    ok(Math::BigNum->mone->is_pow(-3));
    ok(!(Math::BigNum->mone->is_pow(-2)));

    ok(Math::BigNum->mone->is_pow(Math::BigNum->new(3)));
    ok(!(Math::BigNum->mone->is_pow(Math::BigNum->new(2))));

    ok(Math::BigNum->mone->is_pow(Math::BigNum->new(-3)));
    ok(!(Math::BigNum->mone->is_pow(Math::BigNum->new(-2))));

    ok(Math::BigNum->new(-27)->is_pow(3));
    ok(Math::BigNum->new(-27)->is_pow(Math::BigNum->new(3)));

    ok(!(Math::BigNum->new(-16)->is_pow(2)));
    ok(!(Math::BigNum->new(-25)->is_pow(Math::BigNum->new(2))));

    ok(!(Math::BigNum->new(-27)->is_pow(-3)));
    ok(!(Math::BigNum->new(-27)->is_pow(Math::BigNum->new(-3))));

    ok(Math::BigNum->one->is_pow(3));
    ok(Math::BigNum->one->is_pow(Math::BigNum->new(3)));

    ok(Math::BigNum->one->is_pow(-2));
    ok(Math::BigNum->one->is_pow(Math::BigNum->new(-2)));

    ok(Math::BigNum->zero->is_pow(1));
    ok(Math::BigNum->zero->is_pow(10));
    ok(Math::BigNum->zero->is_pow(Math::BigNum->new(3)));

    ok(!(Math::BigNum->zero->is_pow(0)));
    ok(!(Math::BigNum->zero->is_pow(-3)));
    ok(!(Math::BigNum->zero->is_pow(-4)));
    ok(!(Math::BigNum->zero->is_pow(Math::BigNum->new(-2))));
    ok(!(Math::BigNum->zero->is_pow(Math::BigNum->zero)));

    ok($bint->is_pow(2));
    ok($bint->is_pow(Math::BigNum->new(2)));

    ok($bint->is_pow(3));
    ok($bint->is_pow(Math::BigNum->new(3)));

    ok(!$bint->is_pow(4));
    ok(!$bint->is_pow(Math::BigNum->new(4)));
    ok(!$bint->is_pow(5));
    ok(!$bint->is_pow(Math::BigNum->new(5)));

    #
    ## fadd
    #
    is($x->fadd(2),     44);
    is($x->fadd(-2),    40);
    is($x->fadd(-1.5),  40.5);
    is($x->fadd(1.5),   43.5);
    is($x->fadd($y),    1269);
    is($x->fadd("abc"), "NaN");

    #
    ## fsub
    #
    is($x->fsub(2),     40);
    is($x->fsub(-2),    44);
    is($x->fsub(-1.5),  43.5);
    is($x->fsub(1.5),   40.5);
    is($x->fsub($y),    -1185);
    is($x->fsub("abc"), "NaN");

    #
    ## fmul
    #
    is($x->fmul(2),     84);
    is($x->fmul(-2),    -84);
    is($x->fmul(-1.2),  -50.4);
    is($x->fmul(1.5),   63);
    is($x->fmul($y),    51534);
    is($x->fmul("abc"), "NaN");

    #
    ## fdiv
    #
    is($x->fdiv(4),    10.5);
    is($x->fdiv(-4),   -10.5);
    is($x->fdiv(-1.6), -26.25);
    is($x->fdiv(1.6),  26.25);
    like($y->fdiv($x), qr/^29\.2142/);
    is($x->fdiv("abc"),              "NaN");
    is($x->fdiv(0),                  "Inf");
    is($x->fdiv(Math::BigNum->zero), "Inf");

    #
    ## bfadd
    #
    my $xcp;
    $xcp = $x->copy;
    $xcp->bfadd(2);
    is($xcp, 44);
    $xcp = $x->copy;
    $xcp->bfadd(-2);
    is($xcp, 40);
    $xcp = $x->copy;
    $xcp->bfadd(-1.5);
    is($xcp, 40.5);
    $xcp = $x->copy;
    $xcp->bfadd(1.5);
    is($xcp, 43.5);
    $xcp = $x->copy;
    $xcp->bfadd($y);
    is($xcp, 1269);
    $xcp = $x->copy;
    $xcp->bfadd("abc");
    is($xcp, "NaN");

    #
    ## bfsub
    #
    $xcp = $x->copy;
    $xcp->bfsub(2);
    is($xcp, 40);
    $xcp = $x->copy;
    $xcp->bfsub(-2);
    is($xcp, 44);
    $xcp = $x->copy;
    $xcp->bfsub(-1.5);
    is($xcp, 43.5);
    $xcp = $x->copy;
    $xcp->bfsub(1.5);
    is($xcp, 40.5);
    $xcp = $x->copy;
    $xcp->bfsub($y);
    is($xcp, -1185);
    $xcp = $x->copy;
    $xcp->bfsub("abc");
    is($xcp, "NaN");

    #
    ## bfmul
    #
    $xcp = $x->copy;
    $xcp->bfmul(2);
    is($xcp, 84);
    $xcp = $x->copy;
    $xcp->bfmul(-2);
    is($xcp, -84);
    $xcp = $x->copy;
    $xcp->bfmul(-1.5);
    is($xcp, -63);
    $xcp = $x->copy;
    $xcp->bfmul(1.2);
    is($xcp, 50.4);
    $xcp = $x->copy;
    $xcp->bfmul($y);
    is($xcp, 51534);
    $xcp = $x->copy;
    $xcp->bfmul("abc");
    is($xcp, "NaN");

    #
    ## bfdiv
    #
    $xcp = $x->copy;
    $xcp->bfdiv(4);
    is($xcp, 10.5);
    $xcp = $x->copy;
    $xcp->bfdiv(-4);
    is($xcp, -10.5);
    $xcp = $x->copy;
    $xcp->bfdiv(-1.6);
    is($xcp, -26.25);
    $xcp = $x->copy;
    $xcp->bfdiv(1.6);
    is($xcp, 26.25);
    $xcp = $x->copy;
    $xcp->bfdiv($y);
    like($xcp, qr/^0\.034229/);
    $xcp = $x->copy;
    $xcp->bfdiv("abc");
    is($xcp, "NaN");
    $xcp = $x->copy;
    $xcp->bfdiv(0);
    is($xcp, "Inf");
    $xcp = $x->copy;
    $xcp->bfdiv(Math::BigNum->zero);
    is($xcp, "Inf");

    my $i = $y**42;
    is("$i", $int);

    $i = $y**$x;
    is("$i", $int);

    my $j = $i->idiv(1227);
    like("$j", qr/9638805202027\z/);

    $i->bidiv(1227);
    ok($i == $j);

    my $root = $y->iroot(3);
    is("$root", "10");

    $root = $y->iroot(Math::BigNum->new(4));
    is("$root", "5");

    $y->bneg;

    #$root = $y->iroot(2);
    #is("$root", "35i");

    #$root = $y->iroot(Math::BigNum->new(3));
    #is("$root", "-10");

    #$root = $y->iroot(Math::BigNum->new(6));
    #is("$root", "3i");

    $root = $y->iroot(Math::BigNum->new(6));
    is("$root", Math::BigNum->nan);

    $root = $y->iroot(3);
    is("$root", "-10");

    $root = $y->iroot(4);
    is("$root", Math::BigNum->nan);

    $root = $y->iroot(5);
    is("$root", "-4");

    my $r = $x->imul($y);
    is("$r", "-51534");

    $r = $x->imul(4.7);
    is("$r", "168");

    $x->bmul(9);
    is("$x", "378");

    $x->bmul($r);
    is("$x", "63504");
    is("$r", "168");

    $r = $r->imul(-3);
    is("$r", "-504");

    $r->bimul(-5);
    is("$r", "2520");

    $r = $x->isub(1234);
    is("$r", "62270");

    $r = $x->isub(-42);
    is("$r", "63546");

    $r->bisub(Math::BigNum->new(12345));
    is("$r", "51201");

    $r->bisub(-5);
    is("$r", "51206");

    $r->bisub(51207);
    is("$r", "-1");

    $r = $x->iadd(42);
    is("$r", "63546");

    $r = $x->iadd(-10);
    is("$r", "63494");

    $r = $x->iadd(Math::BigNum->new(10));
    is("$r", "63514");

    $x->biadd(-60000);
    is("$x", "3504");

    $x->biadd(10);
    is("$x", "3514");

    $x->biadd(Math::BigNum->new(-3002));
    is("$x", "512");

    is(Math::BigNum->new(12345)->popcount,     6);
    is(Math::BigNum->new(1048576.7)->popcount, 1);
    is(Math::BigNum->new(-4095)->popcount,     12);

    is(Math::BigNum->new("-10")->sign,    -1);
    is(Math::BigNum->new("10")->sign,     1);
    is(Math::BigNum->new("0.0000")->sign, 0);
}

# b* methods
{
    use Math::BigNum qw(:constant);

    my $x = 1;
    is(ref($x->badd(Math::BigNum::Inf->new)), 'Math::BigNum::Inf');
    is(ref($x),                               'Math::BigNum::Inf');

    my $y = 2;
    $y->badd(3);
    is("$y", "5");

    $y->bsub("3");
    is("$y", "2");

    $y->bneg;
    is("$y", "-2");

    $y->babs;
    is("$y", "2");

    my $z = 42;

    $z->bnan;
    is($z, NaN);

    $z->bone;
    is($z, 1);

    $z->bmone;
    is($z, -1);

    $z->binf;
    is($z, Inf);

    $z->bzero;
    is($z, 0);

    $z->bninf;
    is($z, -Inf);

    $z->bnan;
    is($z, NaN);

    $z->binf;
    is($z, Inf);
}

{
    use Math::BigNum;

    my $x = Math::BigNum->new(1234);
    my $y = Math::BigNum->new(99);
    my $k = Math::BigNum->new(3);

    my $z = $x->copy;
    $z->bior($y);
    is($z, "1267");

    $z = $x->copy;
    $z->bior("99");
    is($z, "1267");

    is($x | $y,     "1267");
    is($y | $x,     "1267");
    is($x | "99",   "1267");
    is("1234" | $y, "1267");

    $z = $x->copy;
    $z->band($y);
    is($z, "66");

    $z = $x->copy;
    $z->band("99");
    is($z, "66");

    is($x & $y,     "66");
    is($y & $x,     "66");
    is($x & "99",   "66");
    is("1234" & $y, "66");

    $z = $x->copy;
    $z->bxor($y);
    is($z, "1201");

    $z = $x->copy;
    $z->bxor("99");
    is($z, "1201");

    is($x ^ $y,     "1201");
    is($y ^ $x,     "1201");
    is($x ^ "99",   "1201");
    is("1234" ^ $y, "1201");

    $z = $x->copy;
    $z->blsft("3");
    is($z, "9872");

    $z = $x->copy;
    $z->blsft($k);
    is($z, "9872");

    $z = $x->copy;
    $z <<= "3";
    is($z, "9872");

    $z = $x->copy;
    $z <<= $k;
    is($z, "9872");

    is($x << ("3"), "9872");
    is($x << $k,     "9872");
    is("1234" << $k, "9872");

    $z = $x->copy;
    $z->brsft("3");
    is($z, "154");

    $z = $x->copy;
    $z->brsft($k);
    is($z, "154");

    $z = $x->copy;
    $z >>= "3";
    is($z, "154");

    $z = $x->copy;
    $z >>= $k;
    is($z, "154");

    is($x >> "3",    "154");
    is($x >> $k,     "154");
    is("1234" >> $k, "154");
}

# op= operations
{
    use Math::BigNum;

    my $x = Math::BigNum->new(10);
    my $y = Math::BigNum->new(42);

    $y += $x;
    is("$y", "52");

    $y -= $x;
    is("$y", "42");

    $y *= 2;
    is("$y", "84");

    $y -= 42;
    is("$y", "42");

    $y /= $x;
    is("$y", "4.2");

    $y += -0.2;
    is("$y", "4");

    $x**= 3;
    is("$x", "1000");

    $x /= 4;
    is("$x", "250");

    $y |= $x;
    is("$y", "254");

    $x ^= $y;
    is("$x", "4");

    $y &= $x;
    is("$y", "4");

    $x**= $y;
    is("$x", "256");

    $y *= $x;
    is("$y", "1024");

    ++$y;
    is("$y", "1025");

    --$x;
    is("$x", "255");

    $y %= $x;
    is("$y", "5");

    $x++;
    is("$x", "256");

    $y--;
    is("$y", "4");

    $x >>= $y;
    is("$x", "16");

    $y <<= $x;
    is("$y", "262144");

    $y >>= 16;
    is("$y", "4");

    $x <<= 2;
    is("$x", "64");

    $x %= 6;
    is("$x", "4");
}

# More **= tests
{
    my $x = "2";
    my $y = $mbn->new(100);
    $x**= $y;
    is("$x", "1267650600228229401496703205376");

    $x = $mbn->new(2);
    $x**= $y;
    is("$x", "1267650600228229401496703205376");
}
