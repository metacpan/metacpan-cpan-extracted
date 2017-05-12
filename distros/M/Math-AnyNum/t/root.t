#!perl -T

use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 205;

use Math::AnyNum;

# 2 ** 240 =
# 1766847064778384329583297500742918515827483896875618958121606201292619776

test_root('2', '240', 8,  qr/^1073741824\z/);
test_root('2', '240', 9,  qr/^106528681.309990/);
test_root('2', '120', 9,  qr/^10321.273240738/);
test_root('2', '120', 17, qr/^133.32684936327/);

test_root('2', '120', 8,  qr/^32768\z/);
test_root('2', '60',  8,  qr/^181.01933598375616624/);
test_root('2', '60',  9,  qr/^101.59366732596476638/);
test_root('2', '60',  17, qr/^11.546724616239651532/);

sub test_root {
    my ($x, $n, $y, $expected) = @_;

    # Test "pow(AnyNum, Scalar)" and "root(AnyNum, Scalar)"
    my $froot = Math::AnyNum->new($x)->pow($n)->root($y);

    like($froot, $expected, "Try: Math::AnyNum->new($x)->pow($n)->root($y) == $expected");

    # Test "pow(AnyNum, Scalar)" and "root(AnyNum, Scalar)"
    like(Math::AnyNum->new($x)->pow($n)->root($y), $expected, "Try: Math::AnyNum->new($x)->pow($n)->root($y) == $expected");

    # Test "pow(AnyNum, AnyNum)" and "root(AnyNum, AnyNum)"
    like(Math::AnyNum->new($x)->pow(Math::AnyNum->new($n))->root(Math::AnyNum->new($y)), $expected);

    $expected = "$froot";
    $expected =~ s/\..*//;
    $expected = qr/$expected/;

    # Test "pow" and "iroot"
    like(Math::AnyNum->new($x)->pow($n)->iroot($y), $expected, "Math::AnyNum->new($x)->pow($n)->iroot($y) == $expected");
}

is(Math::AnyNum->new(-1234)->iroot(3),                    -10);
is(Math::AnyNum->new(-1234)->iroot(Math::AnyNum->new(3)), -10);

is(Math::AnyNum->new(-1234)->iroot(4),                    Math::AnyNum->nan);
is(Math::AnyNum->new(-1234)->iroot(Math::AnyNum->new(4)), Math::AnyNum->nan);

{
    my $n = Math::AnyNum->new(-1234);

    my $x = $n->iroot(3);
    is($x, -10);

    $x = $n->iroot(Math::AnyNum->new(3));
    is($x, -10);

    $x = $n->iroot(4);
    is($x, Math::AnyNum->nan);

    $x = $n->iroot(Math::AnyNum->new(4));
    is($x, Math::AnyNum->nan);
}

#########################################
# More tests

my $one  = Math::AnyNum->one;
my $mone = Math::AnyNum->mone;
my $zero = Math::AnyNum->zero;

my $inf  = Math::AnyNum->inf;
my $ninf = Math::AnyNum->ninf;
my $nan  = Math::AnyNum->nan;

# [i]root(AnyNum)
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

my $two  = $one + $one;
my $mtwo = -$two;

is($mone->root($two),  Math::AnyNum->i);
is($mone->iroot($two), $nan);

is($one->root($mtwo),  $one);
is($one->iroot($mtwo), $one);

is($mone->root($mtwo),  -(Math::AnyNum->i));
is($mone->iroot($mtwo), $nan);

like($mtwo->root($mtwo), qr/^-0\.70710678118654752\d*i\z/);
is($mtwo->iroot($mtwo), $nan);

is($zero->root($mone),  $inf);
is($zero->iroot($mone), $inf);

is($two->root($mone), $one / $two);

is($two->iroot($mone), $zero);
is($two->iroot($mtwo), $zero);

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

is($mone->root(2),  'i');
is($mone->iroot(2), $nan);

is($one->root(-2),  $one);
is($one->iroot(-2), $one);

is($mone->root(-2),  -(Math::AnyNum->i));
is($mone->iroot(-2), $nan);

like($mtwo->root(-2), qr/^-0\.707106781186547524\d*i\z/);
is($mtwo->iroot(-2), $nan);

is($zero->root(-1),  $inf);
is($zero->iroot(-1), $inf);

is($two->root(-1), $one / $two);

is($two->iroot(-1), $zero);
is($two->iroot(-2), $zero);

#########################################
# isqrtrem() / irootrem()

{
    my $n = Math::AnyNum->new('562891172629241178357647834151');

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

    ## irootrem(n, Math::AnyNum->new(4))
    $c = Math::AnyNum->new(4);
    ($x, $y) = $n->irootrem($c);
    $r = $n->iroot($c);

    is($x, $r);
    is($y, $n->isub($r->ipow($c)));

    ## irootrem(n, -3)
    $c = Math::AnyNum->new(-3);
    ($x, $y) = $n->irootrem($c);
    $r = $n->iroot($c);

    is($x, $r);

    #is($y, $n->isub($r->ipow($c)));        # should also get -Inf?

    ## isqrtrem(n) == irootrem(n, 2)
    is(join(' ', $n->isqrtrem),    join(' ', $n->irootrem(2)));
    is(join(' ', $mone->isqrtrem), join(' ', $mone->irootrem(2)));
    is(join(' ', $zero->isqrtrem), join(' ', $zero->irootrem(2)));
    is(join(' ', $one->isqrtrem),  join(' ', $one->irootrem(2)));
    is(join(' ', $inf->isqrtrem),  join(' ', $inf->irootrem(2)));
    is(join(' ', $ninf->isqrtrem), join(' ', $ninf->irootrem(2)));

    ## isqrtrem(n) == irootrem(n, Math::AnyNum->new(2))
    my $two = Math::AnyNum->new(2);
    is(join(' ', $n->isqrtrem),    join(' ', $n->irootrem($two)));
    is(join(' ', $mone->isqrtrem), join(' ', $mone->irootrem($two)));
    is(join(' ', $zero->isqrtrem), join(' ', $zero->irootrem($two)));
    is(join(' ', $one->isqrtrem),  join(' ', $one->irootrem($two)));
    is(join(' ', $inf->isqrtrem),  join(' ', $inf->irootrem($two)));
    is(join(' ', $ninf->isqrtrem), join(' ', $ninf->irootrem($two)));

    # More tests to cover some special cases.
    # The commented tests fail under older versions of GMP < 5.1.0.
    foreach my $k (-3 .. 3) {
        foreach my $j (-3 .. 3) {

            my $n = Math::AnyNum->new_si($k);

            # irootrem(AnyNum, Scalar)
            {
                my ($x, $y) = $n->irootrem($j);
                my $r = $n->iroot($j);
                is($x, $r, "tested ($k, $j)");
                ##is($y, $n->sub($r->pow($j)), "tested ($k, $j)");       # fails in some cases
            }

            # irootrem(AnyNum, AnyNum)
            {
                my $c = Math::AnyNum->new_si($j);
                my ($x, $y) = $n->irootrem($c);
                my $r = $n->iroot($c);
                is($x, $r, "tested ($k, $j)");
                ##is($y, $n->sub($r->pow($c)), "tested ($k, $j)");       # fails in some cases
            }
        }
    }
}
