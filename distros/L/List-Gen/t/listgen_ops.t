#!/usr/bin/perl
use strict;
use warnings;
BEGIN {eval 'use Test::More skip_all => "no cover"' if %Devel::Cover::}
use Test::More tests => 15;
use lib qw(../lib lib t/lib);
use List::Gen::Lazy::Ops;
use List::Gen::Testing;

my $add = \&+;
my $add2 = 2->$add;
t 'add 1', is => 5->$add2, 7;
t 'add 2', is => 4->$add(5), 9;
t 'add 3', is => 4->$add->(5), 9;

my $will_add = my $to_add->$add;
$to_add = 5;
t 'will add 1', is => 10->$will_add, 15;
$to_add = 100;
t 'will add 2', is => 10->$will_add, 110;

use List::Gen::Haskell 0;

my $sum = foldl \&+;

t 'sum', is => $sum->(1..10), 55;

my $fac = gen {foldl \&*, 1..$_};

t 'in gen', is => $fac->(9), 362880;

t 'infix', is => 2->${\\&+}(3), 5;

my $cat = foldl \&.;

t 'cat 1', is => join(', ' => $cat->(qw(a b c d e)), $cat->(1..10)),
               'abcde, 12345678910';

t 'cat 2', is => &.(1)->(2), 12;

my $not = \&!;
{
    my ($x, $y) = (1, 1);
    my $not_x = $x->$not;
    my $not_y = $y->$not;
    $x = 0;
    t 'not 1', is => $not_x, 1;
    t 'not 2', is => $not_y, '';
}

$_ = L 0, 1, zipWith \&+, $_, tail $_ for my $fib;

t 'fib', is => "@$fib[0..10]", '0 1 1 2 3 5 8 13 21 34 55';

{
    my $rev = foldl \&{flip \&:}, [], 1..4;
    t 'foldl \&{flip \&:} [], 1 .. 4',
        is_deeply => $rev, [4, 3, 2, 1];

    my $norm = foldr \&:, [], 1..4;
    t 'foldr \&:, [], 1..4',
        is_deeply => $norm, [1, 2, 3, 4];

}
