#!/usr/bin/perl

# Implementation of the `is_power(n, k)` function,
# which returns true when `a^k = n` for some integer `a`.

use 5.014;
use strict;
use warnings;

use lib qw(../lib);
use Math::BigNum;

sub is_power {
    my ($n, $k) = @_;
    Math::BigNum->new($n)->biroot($k)->bipow($k) == $n;
}

my $pow = shift(@ARGV) // 3;
my @bools = qw(false true);

foreach my $i (-1000 .. 1000) {

    my $b1 = Math::BigNum->new($i)->is_pow($pow);    # this is built-in
    my $b2 = is_power($i, $pow);                     # this is user-defined

    say $i if $b2;

    $b1 = $bools[!!$b1];
    $b2 = $bools[!!$b2];

    if ($b1 ne $b2) {
        say "!! $i -- ($b1, $b2)";
    }
}
