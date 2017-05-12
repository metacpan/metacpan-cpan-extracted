#!/usr/bin/perl

# Copyright (c) 2009 Martin Becker.  All rights reserved.
# This package is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: migration.pl 56 2009-06-10 20:57:24Z demetri $

# Math::Polynomial usage example: Migration from version 0.04 to 1.002
#
# Math::Polynomial version 1.000 broke backwards compatibility with
# earlier versions.  This example demonstrates how legacy code using
# Math::Polynomial version 0.04 can be adapted to use a more current
# version of Math::Polynomial.
#
# Throughout the rest of this example, old code is in comments,
# immediately followed by changed code.  Parts needing no modification
# are in blocks without any comments.

use strict;
use warnings;

# use Math::Polynomial;
use Math::Polynomial 1.002;

# my $p = Math::Polynomial->new(1, 3, -2);
my $p = Math::Polynomial->new(-2, 3, 1);

# Math::Polynomial->verbose(0);
Math::Polynomial->string_config({
    with_variable => 0,
    plus          => q{ },
});

print "p is $p\n";

# my $result = $p->eval(5);
my $result = $p->evaluate(5);

print "p(5) is $result\n";

# my $q = Math::Polynomial->new(2, 3);
my $q = Math::Polynomial->new(3, 2);

# my $r = $q->clone;
my $r = $q;

$r += 1;
print "q is $q, r is $r\n";

# my $s = $q - $r;
# $s->tidy;
my $s = $q - $r;

print "s is $s\n";

# my $qq = $q->clone;
# $qq->mul1c(2);
my $qq = $q->mul_root(2);

print "qq is $qq\n";

# $qq->div1c(2);
$qq = $qq->div_root(2);

print "qq is now $qq\n";

# Math::Polynomial->verbose(1);
Math::Polynomial->string_config({
    fold_sign     => 1,
    leading_minus => q{-},
    times         => q{*},
    variable      => q{$X},
    power         => q{**},
    prefix        => q{},
    suffix        => q{},
});

# my ($quot, $rem) = Math::Polynomial::quotrem($p, $q);
my ($quot, $rem) = $p->divmod($q);

print "($p) / ($q) = $quot\n";
print "($p) % ($q) = $rem\n";

# print "q^2 % p = ", $q * $q % $p, "\n";
print "q^2 % p = ", $q**2 % $p, "\n";

# my $pp = Math::Polynomial::interpolate(1 => 9, 2 => 14, 3 => 11);
my $pp = Math::Polynomial->interpolate([1, 2, 3], [9, 14, 11]);

print "pp = $pp\n";

__END__
