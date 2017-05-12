package Math::Random::Normal::Leva;
use strict;
use warnings;

our $VERSION = "0.04";

use Exporter qw(import export_to_level);
our @EXPORT_OK = qw(gbm_sample random_normal);

use Math::Random::Secure qw(rand);

use Carp qw(confess);

=head1 NAME

Math::Random::Normal::Leva - generate normally distributed PRN using Leva method

=head1 VERSION

This document describes Math::Random::Normal::Leva version 0.02

=head1 SYNOPSIS

    use Math::Random::Normal::Leva;
    my @normal = map { random_normal() } 1..1000;

=head1 DESCRIPTION

Generates normally distributed pseudorandom numbers using algorithm described
in the paper "A Fast Normal Random Number Generator", Joseph L. Leva, 1992
(L<http://saluc.engr.uconn.edu/refs/crypto/rng/leva92afast.pdf>)

=head1 FUNCTIONS

=cut

=head2 random_normal($rand)

Returns a random number sampled from the normal distribution.

=over 4

=item I<$rand>

is the value of the stock initially

=cut

# This algorithm comes from the paper
# "A Fast Normal Random Number Generator" (Leva, 1992)

sub random_normal {
    my $rand = shift || \&rand;
    my ($s, $t) = (0.449871, -0.386595);    # Center point
    my ($a, $b) = (0.19600,  0.25472);

    my $nv;
    while (not defined $nv) {
        my ($u, $v) = ($rand->(), 1.7156 * ($rand->() - 0.5));
        my $x = $u - $s;
        my $y = abs($v) - $t;
        my $Q = $x**2 + $y * ($a * $y - $b * $x);
        if ($Q >= 0.27597) {
            next if ($Q > 0.27846 || $v**2 > -4 * $u**2 * log($u));
        }
        $nv = $v / $u;
    }

    return $nv;
}

=back

=head2 gbm_sample($price, $vol, $t, $r, $q, $rand)

Generates a random sample price of a stock following Geometric Brownian Motion after t years.

=over 4

=item I<$price>

is the value of the stock initially

=item I<$vol>

is the annual volatility of the stock

=item I<$t>

is the time elapsed in years

=item I<$r>

is the annualized drift rate

=item I<$q>

is the annualized dividend rate

=item I<$rand>

custom rand generated if not passed will use Math::Random::Secure::rand

=back

note: all rates are taken as decimals (.06 for 6%)

=cut

sub gbm_sample {
    my ($price, $vol, $time, $r, $q, $rand) = @_;

    confess('All parameters are required to be set: generate_gbm($price, $annualized_vol, $time_in_years, $r_rate, $q_rate)')
        if grep { not defined $_ } ($price, $vol, $time, $r, $q);

    return $price * exp(($r - $q - $vol * $vol / 2) * $time + $vol * sqrt($time) * random_normal($rand));
}

1;

__END__

=head1 BUGS

Please report any bugs or feature requests via GitHub bug tracker at
L<http://github.com/binary-com/perl-Math-Random-Normal-Leva/issues>.

=head1 AUTHOR

Binary.com C<< <binary at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2014 Binary.com

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
