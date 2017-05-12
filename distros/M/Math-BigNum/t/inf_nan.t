#!perl -T

use 5.006;
use strict;
use warnings;

use Test::More tests => 192;

use Math::BigNum qw(:constant);

is(1.0 / 0.0,   Inf);
is(-1.0 / 0.0,  -Inf);
is(0.0 / 0.0,   NaN);
is(-0.0,        0);      # should be -0.0
is(Inf + 1,     Inf);
is(5 - Inf,     -Inf);
is("5" - Inf,   -Inf);
is(Inf * 5,     Inf);
is(Inf * "5",   Inf);
is((Inf) / 5,   Inf);
is((Inf) / "5", Inf);
is(0 * Inf,     NaN);
is(-2 - Inf,    -Inf);
is(-Inf - 2,    -Inf);
is(-Inf - "2",  -Inf);
is("-2" - Inf,  -Inf);
is(-2 + Inf,    Inf);
is(-Inf + 2,    -Inf);
is(-Inf + "2",  -Inf);
is(Inf + -Inf,  NaN);
is(-Inf + Inf,  NaN);
is(Inf + "-2",  Inf);
is("-2" + Inf,  Inf);
is(1 /     (Inf), 0);
is("1.0" / (Inf), 0);
is(-1.0 /  (Inf), 0);    # should be -0.0
is(-Inf == -1 / 0, 1);
is(-Inf * 0,       NaN);
is(0 * -Inf,       NaN);
is("0" * -Inf,     NaN);
is(0 * 1 / 0,      NaN);
is(0 / 0,          NaN);
isnt(0 / 0 == 0 / 0, 1);    # NaN != NaN
is(Inf + Inf,    Inf);
is(Inf - Inf,    NaN);
is(Inf * Inf,    Inf);
is(Inf / Inf,    NaN);
is((-Inf) / Inf, NaN);
is(Inf / (-Inf), NaN);
is(Inf * 0.0,     NaN);
is(0 < Inf,       1);
is("0" < Inf,     1);
is(Inf == Inf,    1);
is(-Inf == -Inf,  1);
is(-Inf <=> Inf,  -1);
is(Inf <=> -Inf,  1);
is(Inf <=> Inf,   0);
is(-Inf <=> -Inf, 0);
is(0 <=> -Inf,    1);
is("0" <=> -Inf,  1);
is(NaN + 1,       NaN);
is(NaN + "1",     NaN);
is(NaN * 5,       NaN);
is(NaN - NaN,     NaN);
is(NaN * Inf,     NaN);
is(-NaN,          NaN);
isnt(NaN == NaN, 1);
isnt(NaN > 0,    1);
isnt(NaN < 0,    1);
isnt(NaN == 0,   1);
is(0.0 == -0.0, 1);     # should be false?
is(sin(Inf),    NaN);
is(sin(-Inf),   NaN);
is(cos(Inf),    NaN);
is(cos(-Inf),   NaN);
is(Inf / (-1), -Inf);
is(-Inf + 1e100,  -Inf);
is(Inf + -Inf,    NaN);
is(-Inf + Inf,    NaN);
is(Inf - Inf,     NaN);
is(-Inf - -Inf,   NaN);
is(0 * +Inf,      NaN);
is("0" * +Inf,    NaN);
is(NaN + 1.0,     NaN);
is(NaN + NaN,     NaN);
is(NaN != NaN,    1);
is(abs(Inf),      Inf);
is(abs(-Inf),     Inf);
is(abs(NaN),      NaN);
is(sqrt(Inf),     Inf);
is(sqrt(-Inf),    Inf);    # should be NaN?
is((-Inf)->isqrt, Inf);    # =//=
is(Inf->erfc,     0);
is((-Inf)->erfc,  2);
is(Inf->fac,      Inf);
is((-Inf)->fac,   NaN);
is((-1.01)->acos, NaN);
is(1.01->acos,    NaN);
is((-1.01)->asin, NaN);
is(1.01->asin,    NaN);
is(sqrt(-1),      NaN);
is(Inf**NaN,      NaN);
is((-Inf)**NaN,   NaN);
is(NaN**Inf,      NaN);

# BigNum
is((Inf)->root(-12),   0);
is((Inf)->iroot(-12),  0);
is((-Inf)->root(-12),  0);
is((Inf)->root(2),     Inf);
is((Inf)->iroot(2),    Inf);
is((-Inf)->root(2),    Inf);    # sqrt(-Inf) -- shouldn't be NaN?
is((Inf)->root(Inf),   1);
is((-Inf)->root(Inf),  1);
is((Inf)->root(-Inf),  1);
is((-Inf)->root(-Inf), 1);

# Scalar
is((Inf)->root("-12"),  0);
is((Inf)->iroot("-12"), 0);
is((-Inf)->root("-12"), 0);
is((Inf)->root("2"),    Inf);
is((Inf)->iroot("2"),   Inf);
is((-Inf)->root("2"),   Inf);    # sqrt(-Inf) -- shouldn't be NaN?

is((-Inf)->log, Inf);
is((+Inf)->log, Inf);

# log() / blog()
{
    my $x = Math::BigNum->inf;
    $x->blog;
    is($x, Inf);

    $x = Math::BigNum->ninf;
    $x->blog(42);
    is($x, Inf);

    $x = Math::BigNum->inf;
    is($x->ln, Inf);

    $x->bln;
    is($x, Inf);

    $x = $x->log(42);
    is($x, Inf);

    $x->bneg;
    $x = $x->log(42);
    is($x, Inf);

    is(Math::BigNum->new(42)->log(Inf),  0);
    is(Math::BigNum->new(42)->log(-Inf), 0);

    is(Math::BigNum->new(-42)->log(Inf),  0);
    is(Math::BigNum->new(-42)->log(-Inf), 0);

    is(Math::BigNum->new(42)->blog(Inf),  0);
    is(Math::BigNum->new(42)->blog(-Inf), 0);

    is(Math::BigNum->new(-42)->blog(Inf),  0);
    is(Math::BigNum->new(-42)->blog(-Inf), 0);

    is(Math::BigNum->new(42)->log(NaN),  NaN);
    is(Math::BigNum->new(42)->blog(NaN), NaN);

    is(Math::BigNum->zero->ln,       -Inf);
    is(Math::BigNum->zero->bln,      -Inf);
    is(Math::BigNum->zero->log(42),  -Inf);
    is(Math::BigNum->zero->blog(42), -Inf);

    is(Math::BigNum->zero->log(-Inf),  NaN);
    is(Math::BigNum->zero->blog(-Inf), NaN);

    is(Math::BigNum->zero->log(Inf),  NaN);
    is(Math::BigNum->zero->blog(Inf), NaN);

    is((Inf)->log(Math::BigNum->zero),  NaN);
    is((-Inf)->log(Math::BigNum->zero), NaN);

    is((Inf)->copy->blog(Math::BigNum->zero),  NaN);
    is((-Inf)->copy->blog(Math::BigNum->zero), NaN);

    is((Inf)->log(Math::BigNum->new(-42)),  NaN);
    is((Inf)->log(Math::BigNum->new(42)),   Inf);
    is((-Inf)->log(Math::BigNum->new(-42)), NaN);
    is((-Inf)->log(Math::BigNum->new(42)),  Inf);

    is((Inf)->copy->blog(Math::BigNum->new(-42)),  NaN);
    is((Inf)->copy->blog(Math::BigNum->new(42)),   Inf);
    is((-Inf)->copy->blog(Math::BigNum->new(-42)), NaN);
    is((-Inf)->copy->blog(Math::BigNum->new(42)),  Inf);

    is(Math::BigNum->zero->log(Math::BigNum->zero),  NaN);
    is(Math::BigNum->zero->blog(Math::BigNum->zero), NaN);

    is(Math::BigNum->new(42)->log(Math::BigNum->zero),  0);
    is(Math::BigNum->new(42)->blog(Math::BigNum->zero), 0);

    is(Math::BigNum->new(-42)->log(Math::BigNum->zero),  NaN);    # should this also equal 0?
    is(Math::BigNum->new(-42)->blog(Math::BigNum->zero), NaN);    # =//=
}

{
    my $inf  = Inf;
    my $ninf = -Inf;
    my $nan  = NaN;

    my ($num, $den) = $nan->parts;

    is($num, NaN);
    is($den, NaN);

    my $zero = 0;
    my $one  = 1;

    my $o = 'Math::BigNum';

    #################################################
    # Pow

    is($inf->pow($o->new(-12)->inv),  $zero);
    is($ninf->pow($o->new(-12)->inv), $zero);
    is($inf->pow($o->new(2)->inv),    $inf);
    is($inf->pow($o->new(2)->inv),    $inf);
    is($ninf->pow($o->new(2)->inv),   $inf);    # should be `inf*i`
    is($inf->pow($inf->inv),          $one);
    is($ninf->pow($inf->inv),         $one);
    is($inf->pow($ninf->inv),         $one);
    is($ninf->pow($ninf->inv),        $one);
    is($ninf->pow($o->new(1)->inv),   $ninf);
    is($ninf->pow($o->new(0)->inv),   $inf);
    is($inf->pow($o->new(1)->inv),    $inf);
    is($inf->pow($o->new(0)->inv),    $inf);
    is($ninf->pow($nan),              $nan);
    is($inf->pow($nan),               $nan);
    is($nan->pow($nan),               $nan);

    ##################################################
    # Root

    is($inf->root($o->new(-12)),  $zero);
    is($ninf->root($o->new(-12)), $zero);
    is($inf->root($o->new(2)),    $inf);
    is($ninf->root($o->new(2)),   $inf);    # should be `inf*i`
    is($inf->root($inf),          $one);
    is($ninf->root($inf),         $one);
    is($inf->root($ninf),         $one);
    is($ninf->root($ninf),        $one);
    is($ninf->root($o->new(1)),   $ninf);
    is($ninf->root($o->new(0)),   $inf);
    is($inf->root($o->new(1)),    $inf);
    is($inf->root($o->new(0)),    $inf);
    is($ninf->root($nan),         $nan);
    is($inf->root($nan),          $nan);
    is($nan->root($nan),          $nan);

    ##################################################
    # Sign

    is($inf->sign,  1);
    is($ninf->sign, -1);
    is($nan->sign,  undef);
}

is(Math::BigNum->new('foo'), NaN);

like(Inf->asec, qr/^1\.5707963267/);
