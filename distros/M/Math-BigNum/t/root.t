#!perl -T

use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 269;

use Math::BigNum;

# 2 ** 240 =
# 1766847064778384329583297500742918515827483896875618958121606201292619776

test_broot('2', '240', 8,  qr/^1073741824\z/);
test_broot('2', '240', 9,  qr/^106528681.309990/);
test_broot('2', '120', 9,  qr/^10321.273240738/);
test_broot('2', '120', 17, qr/^133.32684936327/);

test_broot('2', '120', 8,  qr/^32768\z/);
test_broot('2', '60',  8,  qr/^181.01933598375616624/);
test_broot('2', '60',  9,  qr/^101.59366732596476638/);
test_broot('2', '60',  17, qr/^11.546724616239651532/);

sub test_broot {
    my ($x, $n, $y, $expected) = @_;

    # Test "bpow(BigNum, Scalar)" and "broot(BigNum, Scalar)"
    my $froot = Math::BigNum->new($x)->bpow($n)->broot($y);

    like($froot, $expected, "Try: Math::BigNum->new($x)->bpow($n)->broot($y) == $expected");

    # Test "pow(BigNum, Scalar)" and "root(BigNum, Scalar)"
    like(Math::BigNum->new($x)->pow($n)->root($y), $expected, "Try: Math::BigNum->new($x)->pow($n)->root($y) == $expected");

    # Test "pow(BigNum, BigNum)" and "root(BigNum, BigNum)"
    like(Math::BigNum->new($x)->pow(Math::BigNum->new($n))->root(Math::BigNum->new($y)), $expected);

    # Test "bpow(BigNum, BigNum)" and "broot(BigNum, BigNum)"
    like(Math::BigNum->new($x)->bpow(Math::BigNum->new($n))->broot(Math::BigNum->new($y)), $expected);

    $expected = "$froot";
    $expected =~ s/\..*//;
    $expected = qr/$expected/;

    # Test "bpow" and "biroot"
    like(Math::BigNum->new($x)->bpow($n)->biroot($y),
         $expected, "Try: Math::BigNum->new($x)->bpow($n)->biroot($y) == $expected");

    # Test "pow" and "iroot"
    like(Math::BigNum->new($x)->pow($n)->iroot($y), $expected, "Try: Math::BigNum->new($x)->pow($n)->iroot($y) == $expected");
}

is(Math::BigNum->new(-1234)->iroot(3),                    -10);
is(Math::BigNum->new(-1234)->iroot(Math::BigNum->new(3)), -10);

is(Math::BigNum->new(-1234)->iroot(4),                    Math::BigNum->nan);
is(Math::BigNum->new(-1234)->iroot(Math::BigNum->new(4)), Math::BigNum->nan);

{
    my $n = Math::BigNum->new(-1234);

    my $x = $n->copy->biroot(3);
    is($x, -10);

    $x = $n->copy->biroot(Math::BigNum->new(3));
    is($x, -10);

    $x = $n->copy->biroot(4);
    is($x, Math::BigNum->nan);

    $x = $n->copy->biroot(Math::BigNum->new(4));
    is($x, Math::BigNum->nan);
}

{
    my $n = Math::BigNum->new('1234.56');
    $n->broot('3.45');
    like("$n", qr/^7\.8720980221609698183315224802963063\d*\z/);
}

#########################################
# More tests

my $one  = Math::BigNum->one;
my $mone = Math::BigNum->mone;
my $zero = Math::BigNum->zero;

my $inf  = Math::BigNum->inf;
my $ninf = Math::BigNum->ninf;
my $nan  = Math::BigNum->nan;

# [i]root(BigNum)
is($one->root($mone),  $one);
is($one->iroot($mone), $one);

is($zero->root($zero),  $zero);
is($zero->iroot($zero), $zero);

is($zero->root($mone),  $inf);
is($zero->iroot($mone), $inf);

is($mone->root($zero),  $one);
is($mone->iroot($zero), $one);

is($mone->root($one),  $mone);
is($mone->iroot($one), $mone);

my $two  = $one->add($one);
my $mtwo = $two->neg;

is($mone->root($two),  $nan);
is($mone->iroot($two), $nan);

is($one->root($mtwo),  $one);
is($one->iroot($mtwo), $one);

is($mone->root($mtwo),  $nan);
is($mone->iroot($mtwo), $nan);

is($mtwo->root($mtwo),  $nan);    # complex root
is($mtwo->iroot($mtwo), $nan);    # =//=

is($zero->root($mone),  $inf);
is($zero->iroot($mone), $inf);

is($two->root($mone), $one->div($two));

is($two->iroot($mone), $zero);
is($two->iroot($mtwo), $zero);

# b[i]root(BigNum)
is($one->copy->broot($mone),  $one);
is($one->copy->biroot($mone), $one);

is($zero->copy->broot($zero),  $zero);
is($zero->copy->biroot($zero), $zero);

is($zero->copy->broot($mone),  $inf);
is($zero->copy->biroot($mone), $inf);

is($mone->copy->broot($zero),  $one);
is($mone->copy->biroot($zero), $one);

is($mone->copy->broot($one),  $mone);
is($mone->copy->biroot($one), $mone);

is($mone->copy->broot($two),  $nan);
is($mone->copy->biroot($two), $nan);

is($one->copy->broot($mtwo),  $one);
is($one->copy->biroot($mtwo), $one);

is($mone->copy->broot($mtwo),  $nan);
is($mone->copy->biroot($mtwo), $nan);

is($mtwo->copy->broot($mtwo),  $nan);    # complex root
is($mtwo->copy->biroot($mtwo), $nan);    # =//=

is($zero->copy->broot($mone),  $inf);
is($zero->copy->biroot($mone), $inf);

is($two->copy->broot($mone), $one->copy->bdiv($two));

is($two->copy->biroot($mone), $zero);
is($two->copy->biroot($mtwo), $zero);

# [i]root(Scalar)
is($one->root(-1),  $one);
is($one->iroot(-1), $one);

is($zero->root(0),  $zero);
is($zero->iroot(0), $zero);

is($zero->root(-1),  $inf);
is($zero->iroot(-1), $inf);

is($mone->root(0),  $one);
is($mone->iroot(0), $one);

is($mone->root(1),  $mone);
is($mone->iroot(1), $mone);

is($mone->root(2),  $nan);
is($mone->iroot(2), $nan);

is($one->root(-2),  $one);
is($one->iroot(-2), $one);

is($mone->root(-2),  $nan);
is($mone->iroot(-2), $nan);

is($mtwo->root(-2),  $nan);    # complex root
is($mtwo->iroot(-2), $nan);    # =//=

is($zero->root(-1),  $inf);
is($zero->iroot(-1), $inf);

is($two->root(-1), $one->div($two));

is($two->iroot(-1), $zero);
is($two->iroot(-2), $zero);

# b[i]root(Scalar)
is($one->copy->broot(-1),  $one);
is($one->copy->biroot(-1), $one);

is($zero->copy->broot(0),  $zero);
is($zero->copy->biroot(0), $zero);

is($zero->copy->broot(-1),  $inf);
is($zero->copy->biroot(-1), $inf);

is($mone->copy->broot(0),  $one);
is($mone->copy->biroot(0), $one);

is($mone->copy->broot(1),  $mone);
is($mone->copy->biroot(1), $mone);

is($mone->copy->broot(2),  $nan);
is($mone->copy->biroot(2), $nan);

is($one->copy->broot(-2),  $one);
is($one->copy->biroot(-2), $one);

is($mone->copy->broot(-2),  $nan);
is($mone->copy->biroot(-2), $nan);

is($mtwo->copy->broot(-2),  $nan);    # complex root
is($mtwo->copy->biroot(-2), $nan);    # =//=

is($zero->copy->broot(-1),  $inf);
is($zero->copy->biroot(-1), $inf);

is($two->copy->broot(-1), $one->copy->bdiv($two));

is($two->copy->biroot(-1), $zero);
is($two->copy->biroot(-2), $zero);

#########################################
# isqrtrem() / irootrem()

{
    my $n = Math::BigNum->new('562891172629241178357647834151');

    my ($x, $y, $r, $c);

    ## isqrtrem(n)
    ($x, $y) = $n->isqrtrem;
    $r = $n->isqrt;

    is($x, $r);
    is($y, $n->isub($r->ipow(2)));

    ## irootrem(n, 3)
    ($x, $y) = $n->irootrem(3);
    $r = $n->iroot(3);

    is($x, $r);
    is($y, $n->isub($r->ipow(3)));

    ## irootrem(n, 10)
    ($x, $y) = $n->irootrem(10);
    $r = $n->iroot(10);

    is($x, $r);
    is($y, $n->isub($r->ipow(10)));

    ## irootrem(n, Math::BigNum->new(4))
    $c = Math::BigNum->new(4);
    ($x, $y) = $n->irootrem($c);
    $r = $n->iroot($c);

    is($x, $r);
    is($y, $n->isub($r->ipow($c)));

    ## irootrem(n, -3)
    $c = Math::BigNum->new(-3);
    ($x, $y) = $n->irootrem($c);
    $r = $n->iroot($c);

    is($x, $r);
    is($y, $n->isub($r->ipow($c)));

    ## isqrtrem(n) == irootrem(n, 2)
    is(join(' ', $n->isqrtrem),    join(' ', $n->irootrem(2)));
    is(join(' ', $mone->isqrtrem), join(' ', $mone->irootrem(2)));
    is(join(' ', $zero->isqrtrem), join(' ', $zero->irootrem(2)));
    is(join(' ', $one->isqrtrem),  join(' ', $one->irootrem(2)));
    is(join(' ', $inf->isqrtrem),  join(' ', $inf->irootrem(2)));
    is(join(' ', $ninf->isqrtrem), join(' ', $ninf->irootrem(2)));

    ## isqrtrem(n) == irootrem(n, Math::BigNum->new(2))
    my $two = Math::BigNum->new(2);
    is(join(' ', $n->isqrtrem),    join(' ', $n->irootrem($two)));
    is(join(' ', $mone->isqrtrem), join(' ', $mone->irootrem($two)));
    is(join(' ', $zero->isqrtrem), join(' ', $zero->irootrem($two)));
    is(join(' ', $one->isqrtrem),  join(' ', $one->irootrem($two)));
    is(join(' ', $inf->isqrtrem),  join(' ', $inf->irootrem($two)));
    is(join(' ', $ninf->isqrtrem), join(' ', $ninf->irootrem($two)));

    # More tests to cover some special cases.
    # However, some of them fail under old versions of GMP < 5.1.0.
    # http://www.cpantesters.org/cpan/report/b91fc046-cfbd-11e6-a04a-a8c1413d0b36
    foreach my $k (-3 .. 3) {
        foreach my $j (-3 .. 3) {

            my $n = Math::BigNum->new_int($k);

            # irootrem(BigNum, Scalar)
            {
                my ($x, $y) = $n->irootrem($j);
                my $r = $n->iroot($j);
                is($x, $r, "tested ($k, $j)");

                #is($y, $n->isub($r->bipow($j)), "tested ($k, $j)");       # fails in some cases
            }

            # irootrem(BigNum, BigNum)
            {
                my $c = Math::BigNum->new_int($j);
                my ($x, $y) = $n->irootrem($c);
                my $r = $n->iroot($c);
                is($x, $r, "tested ($k, $j)");

                #is($y, $n->isub($r->bipow($c)), "tested ($k, $j)");       # fails in some cases
            }
        }
    }
}
