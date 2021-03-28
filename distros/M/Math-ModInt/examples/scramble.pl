#!/usr/bin/env perl
# Copyright (c) 2009-2021 Martin Becker, Blaubeuren.
# This package is free software; you can distribute it and/or modify it
# under the terms of the Artistic License 2.0 (see LICENSE file).

# Using Math::ModInt to scramble a short ASCII message (make it unreadable).
# Output is a Perl program printing the original message when run.
# This example uses Math::Polynomial to find interpolation polynomials.

use strict;
use warnings;
use Math::Polynomial;
use Math::ModInt 'mod';

my $plaintext = @ARGV? "@ARGV": 'Just another Perl hacker,';

my $modulus   = 127;

# map char numbers to escape sequences inside doublequoted strings
# (we assume ASCII encoding here but do not trust "\n" and "\r")
my @quoted     = (
    (map { q{\\c} . chr $_ } 64..95),
    (map { chr $_ } 32..126),
);
foreach my $c ('\\', '"', '$', '@') {
    $quoted[ord $c] = '\\' . $c;
}
foreach my $c ('\t', '\f', '\b', '\a', '\e') {
    $quoted[ord eval qq{"$c"}] = $c;
}
$quoted[28] = '\\x1c';

# find a set of primitive elements to choose from
my $one        = mod(1, $modulus);
my @exponents  = grep { 0 == ($modulus-1) % $_ } 1..$modulus-2;
my @generators =
    grep { my $g = $_; !grep { $one == $g**$_ } @exponents }
    map { $one->new($_) } 2..$modulus-2;

my $x0;
my $dx;
my $op;

# y-values are the numeric values of the characters of our plaintext
my @y = map { $one->new(ord $_) } split //, $plaintext;

# choose a sequence of distinct x-values we can easily reproduce
my @x = ();
if (rand(7) < 2) {
    $op = '*';
    $x0 = 1 + int rand($modulus - 1);
    my $factor = $generators[int rand scalar @generators];
    my $x1 = $one->new($x0);
    @x = map { $x1 *= $factor } @y;
    $dx = $factor->residue;
}
else {
    $op = '+';
    $x0 = int rand $modulus;
    my $delta = $one->new(1 + int rand($modulus - 1));
    my $x1 = $one->new($x0);
    @x = map { $x1 += $delta } @y;
    $dx = $delta->signed_residue;
    if ($dx < 0) {
        $dx = -$dx;
        $op = '-';
    }
}

# find a polynomial evaluating to y[i] at x[i]
my $p = Math::Polynomial->interpolate(\@x, \@y);
my $scrambled = join '', @quoted[reverse $p->coeff];

# print a short perl program evaluating the polynomial at those x-values
print
    "use Math::ModInt 'mod';\n",
    q[$a=mod(], $x0, q[,127);print map{$a], $op, q[=], $dx,
    q[;$b=0;$b=$a*$b+ord for], "\n", q[split//,"], $scrambled,
    q[";chr$b}1..], length($plaintext), ";\n";

__END__
