#!/usr/bin/env perl

use strict;
use warnings;
use Math::Prime::Util qw(is_prime_power);
use Math::DifferenceSet::Planar;

my $MAX_ORDER = @ARGV? shift @ARGV: 512;
my $MAX_TERMS = @ARGV? shift @ARGV: 20_000;

my $HAVE_LEX =
    $MAX_TERMS <= 1112772 &&
    eval { Math::DifferenceSet::Planar->set_database('pds.db') };

my $n = 0;

sub emit {
    foreach my $y (@_) {
        ++$n;
        print "$n $y\n" if $n <= $MAX_TERMS;
    }
}

print "# b-file for OEIS Axxxxxx (sub-series of A333852)\n";
print "# order 1\n";
emit(0, 1);

my $sets = Math::DifferenceSet::Planar->iterate_available_sets(2, $MAX_ORDER);
while ($n < $MAX_TERMS && (my $s0 = $sets->())) {
    my $first = $s0;
    my $order = $s0->order;
    if (!$HAVE_LEX) {
        my $planes = $s0->iterate_planes;
        while (my $s = $planes->()) {
            $first = $s if $first->compare($s) > 0;
        }
    }
    print "# order $order\n";
    emit($first->elements);
    if ($n > $MAX_TERMS) {
        my $rem = $n - $MAX_TERMS;
        print "# remaining $rem values of order $order cut off\n";
        last;
    }
}

__END__
=head1 NAME

A333852-essential.pl - generate essential sub-series of OEIS A333852

=head1 SYNOPSIS

  A333852-essential.pl [max_order [max_terms]]

=head1 DESCRIPTION

This example program genereates terms of a sub-series of OEIS A333852:
Irregular triangle read by rows: Lexicographically first representative
simple difference set of Singer type of order m, for prime powers m.
The output is formatted as an OEIS b-file.  As sets of equal size can be
derived from each other by simple modular arithmetic, the "essence"
or "interesting values" of A333852 are not all sets but only one set
per size.  We choose the first one occuring in the series, which will
also be the lexicographically lowest Singer set at all of that order.

This series might get an own entry in the OEIS eventually.

The output stops after all orders up to I<max_order> have been exhausted
or I<max_terms> terms have been generated, whichever happens first.

The default value for I<max_terms> is 20_000.  A I<max_order> of 17
yields 108 values.  Other values of I<max_order> and resulting numbers
of terms are:

  +-------------+---------------------+
  |  max_order  |        terms        |
  +-------------+---------------------+
  |           2 |                   5 |
  |           4 |                  14 |
  |           8 |                  37 |
  |          16 |                  90 |
  |          32 |                 301 |
  |          64 |                 764 |
  |         128 |                2455 |
  |         256 |                7510 |
  |         512 |               25529 |
  |        1024 |               87960 |
  |        2048 |              305367 |
  |        4096 |             1112772 |
  |        8192 |             4014231 |
  |       16384 |            14832378 |
  |       32768 |            54732219 |
  |       65536 |           203724678 |
  |      131072 |           765539863 |
  |      262144 |          2877794966 |
  |      524288 |         10887966193 |
  |     1048576 |         41228578390 |
  |     2097152 |        156763899951 |
  |     4194304 |        597392828396 |
  |     8388608 |       2281528655903 |
  |    16777216 |       8732263074848 |
  |    33554432 |      33491611444997 |
  |    67108864 |     128638711757326 |
  |   134217728 |     494909859931581 |
  |   268435456 |    1906983584474766 |
  |   536870912 |    7357526031869965 |
  |  1073741824 |   28424136622109474 |
  |  2147483648 |  109934125492375449 |
  +-------------+---------------------+

Note that an implementation-specific limitation of the underlying Perl
library may stop the output somewhere between a million and a billion
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
