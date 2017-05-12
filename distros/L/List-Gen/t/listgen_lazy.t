#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 26;
use lib qw(../lib lib t/lib);
use List::Gen::Lazy '*';
use List::Gen::Testing;

{
    my $gen;
    my $pipe = lazypipe 3, 2, 0, $gen, 42;

    t 'lazypipe start',
        is => $pipe->next, 3;

    $gen = gen {$_**2} 1, 10;

    my @got;
    push @got, $pipe->next while $pipe->more;

    t 'lazypipe rest',
        is => "@got", '2 0 1 4 9 16 25 36 49 64 81 100 42';
}
{
    my $gen;
    my $pipe = lazypipe 3, 2, 0, $gen, 42;

    t 'lazypipe start 2',
        is => $pipe->next, 3;

    $gen = gen {$_**2} 1, 10;

    my @got;
    while ((my $x) = $pipe->next) {
        push @got, $x;
    }

    t 'lazypipe rest 2',
        is => "@got", '2 0 1 4 9 16 25 36 49 64 81 100 42';
}
{
    my $gen;
    my $pipe = lazyflatten 3, 2, 0, $gen, do {my $x = 5; sub {$x > 0 ? $x-- : ()}}, 42;

    t 'lazyflatten start',
        is => $pipe->next, 3;

    $gen = gen {$_**2} 1, 10;

    my @got;
    push @got, $pipe->next while $pipe->more;

    t 'lazyflatten rest',
        is => "@got", '2 0 1 4 9 16 25 36 49 64 81 100 5 4 3 2 1 42';
}
{
    my $gen;
    my $pipe = lazyflatten 3, 2, 0, $gen, do {my $x = 5; sub {$x > 0 ? $x-- : ()}}, 42;

    t 'lazyflatten start 2',
        is => $pipe->next, 3;

    $gen = gen {$_**2} 1, 10;

    my @got;
    while ((my $x) = $pipe->next) {
        push @got, $x;
    }

    t 'lazyflatten rest 2',
        is => "@got", '2 0 1 4 9 16 25 36 49 64 81 100 5 4 3 2 1 42';
}
{
    my $fib; $fib = lazy 0, 1, gen {$fib->($_) + $fib->($_ + 1)};

    t 'lazy fib',
        is => "@$fib[0 .. 10]", '0 1 1 2 3 5 8 13 21 34 55'
}
{
    my $fib; $fib = lazyx 0, 1, sub {$fib->($_ - 1) + $fib->($_ - 2)};

    t 'lazyx fib',
        is => "@$fib[0 .. 10]", '0 1 1 2 3 5 8 13 21 34 55'
}
{
    my $gen = gen {};
    my $lazy = lazy $gen;
    my $lazyx = lazyx $gen;
    t 'lazy passthru', is => $gen, $lazy;
    t 'lazyx passthru', is => $gen, $lazyx;
}
{
    my $fn = (fn {"3: @_"} 3)->(1);
    my $f2 = $fn->(5);

    t 'fn 1', is => $f2->(10),   '3: 1 5 10';
    t 'fn 2', is => $f2->(11),   '3: 1 5 11';
    t 'fn 3', is => $fn->(4)(6), '3: 1 4 6';
    t 'fn 3', is => $fn->(2, 3), '3: 1 2 3';
}
{
    no if $] > 5.012, warnings => 'illegalproto';
    my $fn = (fn sub (@@@) {"3: @_"})->(1);
    my $f2 = $fn->(5);

    t 'fn proto 1', is => $f2->(10),   '3: 1 5 10';
    t 'fn proto 2', is => $f2->(11),   '3: 1 5 11';
    t 'fn proto 3', is => $fn->(4)(6), '3: 1 4 6';
    t 'fn proto 3', is => $fn->(2, 3), '3: 1 2 3';
}

BEGIN {*aply = fn sub (&@) {$_[0]($_[1])}}
{
    my $wrap = aply {"<@_>"};

    t 'fn 4', is => $wrap->("asdf"), '<asdf>';
}
BEGIN {*fmap = fn \&gen, 2}
{
    my $squares_of = fmap {$_**2};

    my $ints = <0..>;

    my $squares_of_ints = $squares_of->($ints);

    t 'fn 5', is => "@$squares_of_ints[0..10]", '0 1 4 9 16 25 36 49 64 81 100';

    my $future_int;
    my $soi = fmap {$_**2} $future_int;
    $future_int = $ints;

    t 'fn 6', is => "@$soi[0..10]", '0 1 4 9 16 25 36 49 64 81 100';
}
{
    my $add3 = fn {$_[0] + $_[1] + $_[2]} 3;
    my $add2 = $add3->(my $first);
    my $add1 = $add2->(my $second);

    my $sum1 = $add1->(4);
    my $sum2 = $add1->(8);
    $first  = 10;
    $second = 100;
    t 'fn 7', is => $sum1, 114;

    $second = 800;
    t 'fn 8', is => $sum1, 114;
    t 'fn 9', is => $sum2, 818;
}
