#!/usr/bin/env perl

use strict;
use warnings;
use Math::Prime::Util qw(is_prime_power);
use Math::DifferenceSet::Planar;

$| = 1;

die "usage: A373514.pl [max_terms]\n"
    if 1 < @ARGV || grep {!/^[1-9][0-9]*\z/} @ARGV;

my $MAX_TERMS = @ARGV? shift @ARGV: 10_000;
my $n = 1;
my $q = 1;
my $order = 1;

print "# b-file for OEIS A373514\n";
print "1 0\n";

while ($n < $MAX_TERMS) {
    ++$q;
    my $exp = is_prime_power($q);
    next if !$exp;
    my $ds = eval { Math::DifferenceSet::Planar->new($q) };
    if (!$ds) {
        warn "(W) implementation restriction: could generate only $n values\n";
        last;
    }
    ++$n;
    $order = $q;
    my $value = $ds->plane_principal_elements;
    print "$n $value\n";
}

print "# highest order: $order\n";

__END__

=encoding utf8

=head1 NAME

A373514.pl - generate OEIS A373514

=head1 SYNOPSIS

  A373514.pl [max_terms]

=head1 DESCRIPTION

This example program generates terms of OEIS A373514: Number of simple
difference sets of the Singer type (m^2 + m + 1, m + 1, 1) that are a
superset of {0, 1, 3} with m = m(n) = A000961(n), for n >= 1.

A000961(n) gives 1 and the prime powers (p^k, p prime, k >= 1).

The output stops after I<max_terms> terms have been generated or an
implementation limit is reached, whichever happens first.  The default
value for I<max_terms> is 10_000.

Note that, strictly speaking, this program calculates the number of
principal planes rather than 013-sets of increasing orders.  At the
time of publication of this algorithm, the equivalence of 013-sets and
principal planes was stated without proof.  Until the equivalence is
confirmed, the validity of the output should be regarded as conjectural.

=head1 AUTHOR

Martin Becker, E<lt>becker-cpan-mp I<at> cozap.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2024 by Martin Becker, Blaubeuren.

This library is free software; you can distribute it and/or modify it
under the terms of the Artistic License 2.0 (see the LICENSE file).

The licence grants freedom for related software development but does
not cover incorporating code or documentation into AI training material.
Please contact the copyright holder if you want to use the library whole
or in part for other purposes than stated in the licence.

=head1 DISCLAIMER OF WARRANTY

This library is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of merchantability
or fitness for a particular purpose.

=cut
