#! /usr/bin/env perl

use 5.012; use warnings;
use lib qw< dlib ../dlib >;

use Show;

my $scalar = 'x';
my @array = 1..3;
my %hash  = (
    a => 1,
    b => 2,
    c => 3,
);

show $scalar;

{
#    no Show;

    show @array;

    show %hash;
}

show
    $scalar
    x
    $array[
    $hash{b}
    ];

show # wait for it...
     do { 'more'; };

warn 'done at line 36';
