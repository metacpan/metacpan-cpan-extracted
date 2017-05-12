#!perl -T

###############################################################################

use strict;
use warnings;

use Test::More tests => 185;
use Math::BigNum;

my $mbn = 'Math::BigNum';

###############################################################################
# general tests

{
    use Math::BigNum qw(:constant);

    # see if rational constant works
    is((1 / 3)->as_rat,         '1/3',  qq|1/3 = '1/3'|);
    is((1 / 4 + 1 / 3)->as_rat, '7/12', qq|1/4+1/3 = '7/12'|);
    is((5 / 7 + 3 / 7)->as_rat, '8/7',  qq|5/7+3/7 = '8/7'|);

    is((3 / 7 + 1)->as_rat,     '10/7',   qq|3/7+1 = '10/7'|);
    is((3 / 7 + 1.1)->as_rat,   '107/70', qq|3/7+1.1 = '107/70'|);
    is((3 / 7 + 3 / 7)->as_rat, '6/7',    qq|3/7+3/7 = '6/7'|);

    is((3 / 7 - 1)->as_rat,     '-4/7',   qq|3/7-1 = '-4/7'|);
    is((3 / 7 - 1.1)->as_rat,   '-47/70', qq|3/7-1.1 = '-47/70'|);
    is((3 / 7 - 2 / 7)->as_rat, '1/7',    qq|3/7-2/7 = '1/7'|);

    is((1 + 3 / 7)->as_rat, '10/7', qq|1+3/7 = '10/7'|);

    is((1.1 + 3 / 7)->as_rat,   '107/70', qq|1.1+3/7 = '107/70'|);
    is((3 / 7 * 5 / 7)->as_rat, '15/49',  qq|3/7*5/7 = '15/49'|);
    is((3 / 7 / (5 / 7))->as_rat, '3/5', qq|3/7 / (5/7) = '3/5'|);
    is((3 / 7 / 1)->as_rat,   '3/7', qq|3/7 / 1 = '3/7'|);
    is((3 / 7 / 1.5)->as_rat, '2/7', qq|3/7 / 1.5 = '2/7'|);
}

{
    use Math::BigNum qw(:constant);

    is(Inf,  1 / 0);
    is(-Inf, -1 / 0);
    like(sqrt(2),  qr/^1\.414213562/);
    like(log(100), qr/^4\.605170185/);
    like(exp(10),  qr/^22026\.46579/);
    is(abs(-4.5),  4.5);
    is(abs(10),    10);
    is(2.9->floor, 2);
    is(2.5->floor, 2);
    is(2.1->floor, 2);
    is(2->floor,   2);
    is(2.9->ceil,  3);
    is(2.5->ceil,  3);
    is(2.1->ceil,  3);
    is(2->ceil,    2);
    like(2.3**5.4, qr/^89.811/);

    is(Math::BigNum->new("+2"), 2);
    is(Math::BigNum->new("-2"), -2);

    like(3->zeta,      qr/^1\.2020569031/);
    like(3->eta,       qr/^0\.9015426773/);
    like(1->eta,       qr/^0\.6931471805599/);    # special case
    like(3->beta(5),   qr/^0\.009523809523/);
    like(5->beta("3"), qr/^0\.009523809523/);

    #
    ## bessel_j()
    #
    like(12->bessel_j(0), qr/^0\.047689310796833/);
    like(42->bessel_j(5), qr/^-0\.0766076270275045651/);

    like((-5.12)->bessel_j(-3),   qr/^0\.3427458453114948/);
    like((-5.12)->bessel_j("-3"), qr/^0\.3427458453114948/);

    like(13->bessel_j(5.6),   qr/^0\.1316195599274807877/);    # 5.6 is truncated to 5
    like(13->bessel_j("5.6"), qr/^0\.1316195599274807877/);    # =//=

    like(12->bessel_j("1"), qr/^-0\.2234471044906276/);
    like(42->bessel_j("5"), qr/^-0\.0766076270275045651/);

    # Special cases of bessel_j()
    is(12->bessel_j(Inf),     0);
    is((-13)->bessel_j(-Inf), 0);
    is((-1.3)->bessel_j(Inf), 0);
    is(2->bessel_j(NaN),      NaN);

    #
    ## bessel_y()
    #
    like(12->bessel_y(0), qr/^-0\.22523731263436/);
    like(42->bessel_y(5), qr/^0\.096934297943598976/);

    like((5.12)->bessel_y(-3),   qr/^-0\.17873301338971176848/);
    like((5.12)->bessel_y("-3"), qr/^-0\.17873301338971176848/);

    like(13->bessel_y(5.6),   qr/^-0\.188760936228609544/);    # 5.6 is truncated to 5
    like(13->bessel_y("5.6"), qr/^-0\.188760936228609544/);    # =//=

    like(12->bessel_y("1"), qr/^-0\.057099218260896/);
    like(42->bessel_y("5"), qr/^0\.096934297943598976/);

    # Special cases of bessel_y()
    is(12->bessel_y(Inf),     -Inf);
    is(13.5->bessel_y(-Inf),  Inf);
    is((-1.4)->bessel_y(Inf), NaN);
    is((-23)->bessel_y(-Inf), NaN);
    is(2->bessel_y(NaN),      NaN);
}

##############################################################################

my ($x, $y, $z);

$x = $mbn->new('1/4');
$y = $mbn->new('1/3');

is(($x + $y)->as_rat, '7/12');
is(($x * $y)->as_rat, '1/12');
is(($x / $y)->as_rat, '3/4');

$x = $mbn->new('7/5');
$x *= '3/2';
is($x->as_rat, '21/10');
$x -= '0.1';
is($x, '2');

$x = $mbn->new('2/3');
$y = $mbn->new('3/2');
ok(!($x > $y));
ok($x < $y);
ok(!($x == $y));

$x = $mbn->new('-2/3');
$y = $mbn->new('3/2');
ok(!($x > $y));
ok($x < $y);
ok(!($x == $y));

$x = $mbn->new('-2/3');
$y = $mbn->new('-2/3');
ok(!($x > $y));
ok(!($x < $y));
ok($x == $y);

$x = $mbn->new('-2/3');
$y = $mbn->new('-1/3');
ok(!($x > $y));
ok($x < $y);
ok(!($x == $y));

$x = $mbn->new('-124');
$y = $mbn->new('-122');
is($x->acmp($y), 1);

$x = $mbn->new('-124');
$y = $mbn->new('-122');
is($x->cmp($y), -1);

$x = $mbn->new('3/7');
$y = $mbn->new('5/7');
is(($x + $y)->as_rat, '8/7');

$x = $mbn->new('3/7');
$y = $mbn->new('5/7');
is(($x * $y)->as_rat, '15/49');

$x = $mbn->new('3/5');
$y = $mbn->new('5/7');
is(($x * $y)->as_rat, '3/7');

$x = $mbn->new('3/5');
$y = $mbn->new('5/7');
is(($x / $y)->as_rat, '21/25');

$x = $mbn->new('7/4');
$y = $mbn->new('1');
is(($x % $y)->as_rat, '3/4');

## Not exact, yet.
#$x = $mbn->new('7/4');
#$y = $mbn->new('5/13');
#is(($x % $y)->as_rat, '11/52');

## Not exact, yet.
#$x = $mbn->new('7/4');
#$y = $mbn->new('5/9');
#is(($x % $y)->as_rat, '1/12');

#$x = $mbn->new('-144/9')->bsqrt();
#is("$x", '4i');

$x = $mbn->new('144/9')->bsqrt();
is($x, '4');

$x = $mbn->new('3/4');

my $n = 'numerator';
my $d = 'denominator';

my $num = $x->$n;
my $den = $x->$d;

is($num, 3);
is($den, 4);

##############################################################################
# mixed arguments

is($mbn->new('3/7')->badd(1)->as_rat,                 '10/7');
is($mbn->new('3/10')->badd(1.1)->as_rat,              '7/5');
is($mbn->new('3/7')->badd($mbn->new(1))->as_rat,      '10/7');
is($mbn->new('3/10')->badd($mbn->new('1.1'))->as_rat, '7/5');

is($mbn->new('3/7')->bsub(1)->as_rat,                 '-4/7');
is($mbn->new('3/10')->bsub(1.1)->as_rat,              '-4/5');
is($mbn->new('3/7')->bsub($mbn->new(1))->as_rat,      '-4/7');
is($mbn->new('3/10')->bsub($mbn->new('1.1'))->as_rat, '-4/5');

is($mbn->new('3/7')->bmul(1)->as_rat,                 '3/7');
is($mbn->new('3/10')->bmul(1.1)->as_rat,              '33/100');
is($mbn->new('3/7')->bmul($mbn->new(1))->as_rat,      '3/7');
is($mbn->new('3/10')->bmul($mbn->new('1.1'))->as_rat, '33/100');

is($mbn->new('3/7')->bdiv(1)->as_rat,                 '3/7');
is($mbn->new('3/10')->bdiv(1.1)->as_rat,              '3/11');
is($mbn->new('3/7')->bdiv($mbn->new(1))->as_rat,      '3/7');
is($mbn->new('3/10')->bdiv($mbn->new('1.1'))->as_rat, '3/11');

##############################################################################
# bpow

$x = $mbn->new('2/1');
$z = $x->bpow('3');
is($x, '8');

$x = $mbn->new('1/2');
$z = $x->bpow('3');
is($x, '0.125');    # 1/8

$x = $mbn->new('1/3');
$z = $x->bpow('4');
is($x, $mbn->new(81)->inv);    # 1/81

$x = $mbn->new('2/3');
$z = $x->bpow('4');
like($x, qr/^0\.1975308641975308641/);    # 16/81

$x = $mbn->new('2/3');
$z = $x->bpow($mbn->new('5/3'));
like("$z", qr/^0\.50876188557925/);

##############################################################################
# modpow

{
    my $x = Math::BigNum->new(3);
    my $y = Math::BigNum->new(23);
    my $z = Math::BigNum->new(17);

    my $nan  = Math::BigNum->nan;
    my $mone = Math::BigNum->mone;

    is($x->modpow($y,   $z),   11);
    is($x->modpow('23', $z),   11);
    is($x->modpow('23', '17'), 11);
    is($x->modpow($y,   '17'), 11);

    is($x->modpow('-1',  $z),   6);
    is($x->modpow('-2',  $z),   2);
    is($x->modpow('-2',  '17'), 2);
    is($x->modpow('-1',  '17'), 6);
    is($x->modpow($mone, $z),   6);
    is($x->modpow($mone, '17'), 6);

    is($x->modpow('-1',  '15'),                       $nan);
    is($x->modpow($mone, '15'),                       $nan);
    is($x->modpow($mone, Math::BigNum->new_int(15)),  $nan);
    is($x->modpow('-1',  Math::BigNum->new_uint(15)), $nan);
}

##############################################################################
# fac

$x = $mbn->new('1');
$x->fac();
is($x, '1');

my @fac = qw(1 1 2 6 24 120);

for (my $i = 0 ; $i < 6 ; $i++) {
    $x = $mbn->new("$i/1")->fac();
    is($x, $fac[$i]);
}

# test for $self->bnan() vs. $x->bnan();
$x = $mbn->new('-1');
$x->bfac();
is("$x", 'NaN');

##############################################################################
# binc/bdec

$x = $mbn->new('3/2');
is($x->binc()->as_rat, '5/2');
$x = $mbn->new('15/6');
is($x->bdec()->as_rat, '3/2');

##############################################################################
# bsqrt

$x = $mbn->new('144');
is($x->bsqrt(), '12', 'bsqrt(144)');

$x = $mbn->new('144/16');
is($x->bsqrt(), '3', 'bsqrt(144/16)');

##############################################################################
# floor/ceil

$x = $mbn->new('-7/7');
is($x->$n(), '-1');
is($x->$d(), '1');
$x = $mbn->new('-7/7')->floor();
is($x->$n(), '-1');
is($x->$d(), '1');

$x = $mbn->new('49/4');
is($x->floor(), '12', 'floor(49/4)');

$x = $mbn->new('49/4');
is($x->ceil(), '13', 'ceil(49/4)');

##############################################################################
# broot(), blog(), bmodpow() and bmodinv()

$x = $mbn->new(2)**32;
$y = $mbn->new(4);
$z = $mbn->new(3);

is($x->copy()->broot($y),      2**8);
is(ref($x->copy()->broot($y)), $mbn);

is($x->modpow($y, $z), 1);
is(ref($x->modpow($y, $z)), $mbn);

$x = $mbn->new(8);
$y = $mbn->new(5033);
$z = $mbn->new(4404);

is($x->modinv($y),      $z);
is(ref($x->modinv($y)), $mbn);

# square root with exact result
$x = $mbn->new('1.44');
is($x->copy()->broot(2), "1.2");
is(ref($x->root(2)),     $mbn);

# log with exact result
$x = $mbn->new('256.1');
like($x->copy()->blog(2), qr/^8.0005634/);
is(ref($x->copy()->blog(2)), $mbn);

$x = $mbn->new(144);
is($x->copy()->broot('2'), 12, 'v/144 = 12');

$x = $mbn->new(12 * 12 * 12);
is($x->copy()->broot('3'), 12, '(12*12*12) ** 1/3 = 12');

##############################################################################
# as_float()

$x = $mbn->new('1/2');
my $f = $x->as_float();

is($x->as_rat, '1/2', '$x unmodified');
is($f,         '0.5', 'as_float(0.5)');

$x = $mbn->new('2/3');
$f = $x->as_float(5);

is($x->as_rat, '2/3',     '$x unmodified');
is($f,         '0.66667', 'as_float(2/3, 5)');

##############################################################################
# int()

$x = $mbn->new('5/2');
is(int($x), '2', '5/2 converted to integer');

$x = $mbn->new('-1/2');
is(int($x), '0', '-1/2 converted to integer');

##############################################################################
# as_hex(), as_bin(), as_oct()

$x = $mbn->new('8/8');
is($x->as_hex(), '1');
is($x->as_bin(), '1');
is($x->as_oct(), '1');

$x = $mbn->new('80/8');
is($x->as_hex(), 'a');
is($x->as_bin(), '1010');
is($x->as_oct(), '12');

##############################################################################
# numify()

my @array = qw/1 2 3 4 5 6 7 8 9/;
$x = $mbn->new('8/8');
is($array[$x], 2);

$x = $mbn->new('16/8');
is($array[$x], 3);

$x = $mbn->new('17/8');
is($array[$x], 3);

$x = $mbn->new('33/8');
is($array[$x], 5);

$x = $mbn->new('-33/8');
is($array[$x], 6);

$x = $mbn->new('-8/1');
is($array[$x], 2);    # -8 => 2

$x = $mbn->new('33/8');
is($x->numify() * 1000, 4125);

$x = $mbn->new('-33/8');
is($x->numify() * 1000, -4125);

$x = $mbn->inf;
like($x->numify(), qr/^[^-]*inf/i);

$x = $mbn->ninf;
like($x->numify(), qr/-.*?inf/i);

#$x = $mbn->nan;
#like($x->numify(), qr/nan/i);      # this is not portable

$x = $mbn->new('4/3');
like($x->numify(), qr/^1\.33333/);

##############################################################################
# digits()

{
    my $n = $mbn->new(-4095.56);

    my @array = $n->digits;
    is(scalar(@array), 4);
    is(join('', @array), '4095');

    @array = $n->digits(16);
    is(scalar(@array), 3);
    is(join('', @array), 'f' x 3);

    @array = $n->digits($mbn->new(2));
    is(scalar(@array), 12);
    is(join('', @array), '1' x 12);

    is(join('', $mbn->new('helloworld', 36)->digits(36)), 'helloworld');
}

##############################################################################
# done

1;
