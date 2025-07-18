#!/usr/bin/env perl

use strict;
use warnings;
use Math::Prime::Util qw(is_prime_power);
use Math::DifferenceSet::Planar;

$| = 1;

die "usage: A383574.pl [max_terms]\n"
    if 1 < @ARGV || grep {!/^[1-9][0-9]*\z/} @ARGV;

my $MAX_TERMS = @ARGV? shift @ARGV: 10_000;
my $order = 3;
my $count = 0;

print "# b-file for OEIS A383574\n";

while ($count < $MAX_TERMS) {
    my $val = -1;
    my $exp = is_prime_power($order);
    if ($exp) {
        my $ds = Math::DifferenceSet::Planar->lex_reference($order);
        if (!$ds) {
            warn "(W) not enough data: could generate only $count values\n";
            last;
        }
        $val = $ds->element_sorted(3);;
    }
    print $order+1, " $val\n";
    ++$order;
    ++$count;
}

__END__

=encoding utf8

=head1 NAME

A383574.pl - generate OEIS A383574

=head1 SYNOPSIS

  A383574.pl [max_terms]

=head1 DESCRIPTION

This example program generates terms of OEIS A383574: Fourth value
of lexicographically earliest perfect difference set with n elements,
sorted in ascending order, if such a set exists, or -1 otherwise.

The output stops after I<max_terms> terms have been generated or an
implementation limit is reached, whichever happens first.  The default
value for I<max_terms> is 10_000.

Note that this program takes its values from the universe of Singer type
difference sets and is thus based on the conjecture that all perfect
difference sets are of Singer type.  Therefore, the validity of the
output should be regarded as conjectural.

=head1 AUTHOR

Martin Becker, E<lt>becker-cpan-mp I<at> cozap.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2025 by Martin Becker, Blaubeuren.

This library is free software; you can distribute it and/or modify it
under the terms of the Artistic License 2.0 (see the LICENSE file).

The license grants freedom for related software development but does
not cover incorporating code or documentation into AI training material.
Please contact the copyright holder if you want to use the library whole
or in part for other purposes than stated in the license.

=head1 DISCLAIMER OF WARRANTY

This library is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of merchantability
or fitness for a particular purpose.

=cut
