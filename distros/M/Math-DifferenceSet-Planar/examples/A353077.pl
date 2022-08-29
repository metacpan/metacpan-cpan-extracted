#!/usr/bin/env perl

use strict;
use warnings;
use Math::Prime::Util qw(is_prime_power);
use Math::DifferenceSet::Planar;

my $MAX_ROWS  = @ARGV? shift @ARGV: 200;
my $MAX_TERMS = @ARGV? shift @ARGV: 20_100;

my $HAVE_LEX =
    $MAX_ROWS <= 4097 || $MAX_TERMS <= 8394753 and
    eval { Math::DifferenceSet::Planar->set_database('pds.db') };

my $n   = 0;
my $row = 0;

sub emit {
    if (++$row <= $MAX_ROWS) {
        print "# row $row\n" if $n < $MAX_TERMS;
        foreach my $y (@_) {
            ++$n;
            print "$n $y\n" if $n <= $MAX_TERMS;
        }
    }
}

print "# b-file for OEIS A353077\n";
emit(0);
emit(0, 1);

my $sets = Math::DifferenceSet::Planar->iterate_available_sets(2, $MAX_ROWS-1);
while ($n < $MAX_TERMS && (my $s0 = $sets->())) {
    my $first = $s0;
    my $order = $s0->order;
    if (!$HAVE_LEX) {
        my $planes = $s0->iterate_planes;
        while (my $s = $planes->()) {
            $first = $s if $first->compare($s) > 0;
        }
    }
    while($row < $order) {
        emit((-1) x ($row + 1));
    }
    if ($row < $MAX_ROWS && $n < $MAX_TERMS) {
        emit($first->elements);
        if ($n > $MAX_TERMS) {
            my $rem = $n - $MAX_TERMS;
            print "# remaining $rem values of row $row cut off\n";
            last;
        }
    }
}

__END__
=head1 NAME

A353077.pl - generate OEIS A353077

=head1 SYNOPSIS

  A353077.pl [max_rows [max_terms]]

=head1 DESCRIPTION

This example program genereates terms of OEIS A353077: Triangle read
by rows, where the n-th row consists of the lexicographically earliest
solution for n integers in 0..p-1 whose n*(n-1) differences are congruent
to 1..p-1 (mod p), where p=n*(n-1)+1. If no solution exists, the n-th row
consists of n -1's.  Solutions for n >= 2 are cyclic planar difference
sets of order n - 1..

The output stops after all rows up to I<max_rows> have been exhausted
or I<max_terms> terms have been generated, whichever happens first.

The default values for I<max_rows> and I<max_terms> are 200 and 20_100.
The triangle with I<n> rows has I<n * (n + 1) / 2> terms.

Note that an implementation-specific limitation of the underlying Perl
library may stop the output somewhere between 8 million and 10 billion
terms.

=head1 AUTHOR

Martin Becker, E<lt>becker-cpan-mp I<at> cozap.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2022 by Martin Becker, Blaubeuren.

This library is free software; you can distribute it and/or modify it
under the terms of the Artistic License 2.0 (see the LICENSE file).

=head1 DISCLAIMER OF WARRANTY

This library is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of merchantability
or fitness for a particular purpose.

=cut
