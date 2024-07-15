#!/usr/bin/env perl

use strict;
use warnings;
use Math::Prime::Util qw(is_prime_power);
use Math::DifferenceSet::Planar;

die "usage: A353077.pl [max_rows [max_terms]]\n"
    if 2 < @ARGV || grep {!/^[1-9][0-9]*\z/} @ARGV;

my $MAX_ROWS  = @ARGV? shift @ARGV: 200;
my $MAX_TERMS = @ARGV? shift @ARGV: 20_100;

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

my $order = 1;
while ($row < $MAX_ROWS && $n < $MAX_TERMS) {
    ++$order;
    my $first = eval { Math::DifferenceSet::Planar->lex_reference($order) };
    if (!defined $first) {
        my $s0 = $first = eval { Math::DifferenceSet::Planar->new($order) };
        if (defined $s0) {
            my $planes = $s0->iterate_planes;
            while (my $s = $planes->()) {
                $first = $s if $first->compare($s) > 0;
            }
        }
        elsif (is_prime_power($order)) {
            print
                "# rows >= $row left out ",
                "due to implementation restriction\n";
            last;
        }
    }
    if (!defined $first) {
        emit((-1) x ($order + 1));
    }
    else {
        emit($first->elements);
    }
    if ($n > $MAX_TERMS) {
        my $rem = $n - $MAX_TERMS;
        print "# remaining $rem values of row $row cut off\n";
    }
}

__END__

=encoding utf8

=head1 NAME

A353077.pl - generate OEIS A353077

=head1 SYNOPSIS

  A353077.pl [max_rows [max_terms]]

=head1 DESCRIPTION

This example program generates terms of OEIS A353077: Triangle read by
rows, where the I<n>-th row consists of the lexicographically earliest
solution for I<n> integers in I<0..n-1> whose I<n*(n-1)> differences are
congruent to I<1..p-1 (mod p)>, where I<p = n*(n-1)+1>. If no solution
exists, the I<n>-th row consists of I<n> values I<-1>.  Solutions for
I<n E<8805> 3> are cyclic planar difference sets of order I<n-1>.

The output stops after all rows up to I<max_rows> have been exhausted
or I<max_terms> terms have been generated, whichever happens first.

The default values for I<max_rows> and I<max_terms> are 200 and 20_100.
The triangle with I<n> rows has I<n * (n + 1) / 2> terms.

Note that an implementation-specific limitation of the underlying Perl
library may stop the output somewhere between 8 million and 10 billion
terms.

Note also that another limitation may slow down the output somewhere
after 60 million terms for lack of pre-computed reference sets.

Note finally, that the completeness of our data and hence the integrity of
the output partly depends on conjectures.  While recent massive computer
searches have increased our confidence, you should better not rely on it.
There is also a small probability our own search results are harmed by
a computer malfunction, which increases with increasing I<n>.  Work is
in progress to double-check all of it.

=head1 AUTHOR

Martin Becker, E<lt>becker-cpan-mp I<at> cozap.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2022-2024 by Martin Becker, Blaubeuren.

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
