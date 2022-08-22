#!/usr/bin/env perl

use strict;
use warnings;
use Math::Prime::Util qw(is_prime_power);
use Math::DifferenceSet::Planar;

my $LIM_ORDER = Math::DifferenceSet::Planar->available_max_order;
my $MAX_ORDER = @ARGV? shift @ARGV: 32;
my $MAX_TERMS = @ARGV? shift @ARGV: 20_000;

my $n = 0;

sub emit {
    foreach my $e (@_) {
        ++$n;
        print "$n $e\n" if $n <= $MAX_TERMS;
    }
}

print "# b-file for OEIS A333852\n";
print "# order 1: 1 set\n";
emit(0, 1);

my $order = 1;
while ($n < $MAX_TERMS && ++$order < $MAX_ORDER) {
    next if !is_prime_power($order);
    if ($order > $LIM_ORDER) {
        print
            "# orders >= $order left out ",
           "due to implementation restriction\n";
        last;
    }
    my $s0 = Math::DifferenceSet::Planar->new($order);
    my $it = $s0->iterate_planes;
    my @sets = ();
    while (my $s = $it->()) {
        push @sets, $s;
    }
    print "# order $order: ", 0+@sets, " sets\n";
    foreach my $s ( sort { $a->compare($b) } @sets ) {
        emit($s->elements);
    }
    if ($n > $MAX_TERMS) {
        my $rem = $n - $MAX_TERMS;
        print "# remaining $rem values of order $order cut off\n";
        last;
    }
}

__END__
=head1 NAME

A333852.pl - generate OEIS A333852

=head1 SYNOPSIS

  A333852.pl [max_order [max_terms]]

=head1 DESCRIPTION

This example program generates terms of OEIS A333852: Irregular triangle
read by rows: representative simple difference sets of Singer type of
order m, for prime powers m, in lexicographic order.  The output is
formatted as an OEIS b-file.

The output stops after all representative sets up to the order of
I<max_order> have been exhausted or I<max_terms> terms have been
generated, whichever happens first.

The default value for I<max_terms> is 20_000.  A I<max_order> of 5 yields
94 values.  Other values of I<max_order> and corresponding numbers of
terms are:

  +-----------+---------------------+
  | max_order |        terms        |
  +-----------+---------------------+
  |         2 |                   8 |
  |         4 |                  34 |
  |         8 |                 262 |
  |        16 |                1578 |
  |        32 |               29690 |
  |        64 |              301310 |
  |       128 |             3873574 |
  |       256 |            51751698 |
  |       512 |           779148470 |
  |      1024 |         10898804834 |
  |      2048 |        151368966098 |
  |      4096 |       2271173024250 |
  +-----------+---------------------+

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
