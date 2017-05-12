#!/bin/env perl
#
#   newton_raphson.pl
#
#   an implementation of newton raphson based on Math::Polynom
#   this is just an example. For a more robust implementation,
#   see the source of Math::Polynom.
#
#   $Id: newton_raphson.pl,v 1.1 2007/04/11 09:22:39 erwan_lemonnier Exp $
#

use 5.006;
use strict;
use warnings;
use Math::Polynom;

# we instanciate the polynom x^3-1
my $p = new Math::Polynom(3 => 1, 0 => -1);

my $new_guess = 5;
my $precision = 0.01;
my $max_depth = 20;

my $derivate = $p->derivate;
my $old_guess = $new_guess - 2*$precision; # pass the while condition first time

while (abs($new_guess - $old_guess) > $precision) {
    $old_guess = $new_guess;

    my $dividend = $derivate->eval($old_guess);

    die "division by zero: polynomial's derivate is 0 at $old_guess"
	if ($dividend == 0);

    $new_guess = $old_guess - $p->eval($old_guess)/$dividend;

    $p->iterations($p->iterations + 1);

    die "reached maximum number of iterations [$max_depth] without getting close enough to the root."
	if ($p->iterations > $max_depth);
}

print "the root of:\n".$p->stringify."\nis: ".$new_guess."\n";

