package Math::Business::Lookback;

use strict;
use warnings;

use List::Util qw(max min);
use Math::CDF  qw(pnorm);

use Math::Business::Lookback::Common;

# ABSTRACT: The Black-Scholes formula for Lookback options.

our $VERSION = '0.01';

=head1 NAME

Math::Business::Lookback

=head1 SYNOPSIS

    use Math::Business::Lookback;

    # price of a Lookback Fixed Call option

    my $price_lbfixedcall_option = Math::Business::Lookback::lbfixedcall(
        1.35,       # stock price
        1.36,       # barrier
        (7/365),    # time
        0.002,      # payout currency interest rate (0.05 = 5%)
        0.001,      # quanto drift adjustment (0.05 = 5%)
        0.11,       # volatility (0.3 = 30%)
        1.39,       # maximum spot
        undef       # minimum spot
    );

=head1 DESCRIPTION

Prices lookback options using the GBM model, all closed formulas.

=head1 SUBROUTINES

=head2 lbfloatcall

    USAGE
    my $price = lbfloatcall($S, $K, $t, $r_q, $mu, $sigma, $S_max, $S_min)

    DESCRIPTION
    Price of a Lookback Float Call

=cut

sub lbfloatcall {
    my ($S, $K, $t, $r_q, $mu, $sigma, $S_max, $S_min) = @_;

    $S_max = undef;
    my $d1 = d1_function($S, $S_min, $t, $r_q, $mu, $sigma);
    my $d2 = $d1 - ($sigma * sqrt($t));

    my $value = exp(-$r_q * $t) * ($S * exp($mu * $t) * pnorm($d1) - $S_min * pnorm($d2) + l_min($S, $S_min, $t, $r_q, $mu, $sigma));

    return $value;
}

=head2 lbfloatput

    USAGE
    my $price = lbfloatcall($S, $K, $t, $r_q, $mu, $sigma, $S_max, $S_min)

    DESCRIPTION
    Price of a Lookback Float Put

=cut

sub lbfloatput {    # Floating Strike Put
    my ($S, $K, $t, $r_q, $mu, $sigma, $S_max, $S_min) = @_;

    $S_min = undef;
    my $d1 = d1_function($S, $S_max, $t, $r_q, $mu, $sigma);
    my $d2 = $d1 - ($sigma * sqrt($t));

    my $value = exp(-$r_q * $t) * ($S_max * pnorm(-$d2) - $S * exp($mu * $t) * pnorm(-$d1) + l_max($S, $S_max, $t, $r_q, $mu, $sigma));

    return $value;
}

=head2 lbfixedcall

    USAGE
    my $price = lbfixedcall($S, $K, $t, $r_q, $mu, $sigma, $S_max, $S_min)

    DESCRIPTION
    Price of a Lookback Fixed Call

=cut

sub lbfixedcall {
    my ($S, $K, $t, $r_q, $mu, $sigma, $S_max, $S_min) = @_;

    $S_min = undef;
    my $K_max = max($S_max, $K);
    my $d1    = d1_function($S, $K_max, $t, $r_q, $mu, $sigma);
    my $d2    = $d1 - ($sigma * sqrt($t));

    my $value =
        exp(-$r_q * $t) * (max($S_max - $K, 0.0) + $S * exp($mu * $t) * pnorm($d1) - $K_max * pnorm($d2) + l_max($S, $K_max, $t, $r_q, $mu, $sigma));

    return $value;
}

=head2 lbfixedput

    USAGE
    my $price = lbfixedput($S, $K, $t, $r_q, $mu, $sigma, $S_max, $S_min)

    DESCRIPTION
    Price of a Lookback Fixed Put

=cut

sub lbfixedput {
    my ($S, $K, $t, $r_q, $mu, $sigma, $S_max, $S_min) = @_;

    $S_max = undef;
    my $K_min = min($S_min, $K);
    my $d1    = d1_function($S, $K_min, $t, $r_q, $mu, $sigma);
    my $d2    = $d1 - ($sigma * sqrt($t));

    my $value = exp(-$r_q * $t) *
        (max($K - $S_min, 0.0) + $K_min * pnorm(-$d2) - $S * exp($mu * $t) * pnorm(-$d1) + l_min($S, $K_min, $t, $r_q, $mu, $sigma));

    return $value;
}

=head2 lbhighlow

    USAGE
    my $price = lbhighlow($S, $K, $t, $r_q, $mu, $sigma, $S_max, $S_min)

    DESCRIPTION
    Price of a Lookback High Low

=cut

sub lbhighlow {
    my ($S, $K, $t, $r_q, $mu, $sigma, $S_max, $S_min) = @_;

    my $value = lbfloatcall($S, $S_min, $t, $r_q, $mu, $sigma, $S_max, $S_min) + lbfloatput($S, $S_max, $t, $r_q, $mu, $sigma, $S_max, $S_min);

    return $value;
}

=head2 d1_function

returns the d1 term common to many BlackScholes formulae.

=cut

sub d1_function {
    my ($S, $K, $t, $r_q, $mu, $sigma) = @_;

    my $value = (log($S / $K) + ($mu + $sigma * $sigma * 0.5) * $t) / ($sigma * sqrt($t));

    return $value;
}

=head2 l_max

This is a common function use to calculate the lookbacks options price. See [1] for details.

=cut

sub l_max {
    my ($S, $K, $t, $r_q, $mu, $sigma) = @_;

    my $d1 = d1_function($S, $K, $t, $r_q, $mu, $sigma);
    my $value;

    if ($mu) {
        $value =
            $S *
            ($sigma**2) /
            (2.0 * $mu) *
            (-($S / $K)**(-2.0 * $mu / ($sigma**2)) * pnorm($d1 - 2.0 * $mu / $sigma * sqrt($t)) + exp($mu * $t) * pnorm($d1));
    } else {
        $value = $S * ($sigma * sqrt($t)) * (Math::Business::Lookback::Common::dnorm($d1) + $d1 * pnorm($d1));
    }

    return $value;
}

=head2 l_min

This is a common function use to calculate the lookbacks options price. See [1] for details.

=cut

sub l_min {
    my ($S, $K, $t, $r_q, $mu, $sigma) = @_;

    my $d1 = d1_function($S, $K, $t, $r_q, $mu, $sigma);
    my $value;

    if ($mu) {
        $value =
            $S *
            ($sigma**2) /
            (2.0 * $mu) *
            (($S / $K)**(-2.0 * $mu / ($sigma**2)) * pnorm(-$d1 + 2.0 * $mu / $sigma * sqrt($t)) - exp($mu * $t) * pnorm(-$d1));
    } else {
        $value = $S * ($sigma * sqrt($t)) * (Math::Business::Lookback::Common::dnorm($d1) + $d1 * (pnorm($d1) - 1));
    }

    return $value;
}

=head1 DEPENDENCIES

    * Math::CDF

=head1 SOURCE CODE

    https://github.com/binary-com/perl-Math-Business-Lookback

=head1 REFERENCES

[1] Espen Gaarder Haug, PhD
    The Complete Guide to Option Pricing Formulas p141-p144

=head1 AUTHOR

binary.com, C<< <shahrizal at binary.com> >>

=head1 BUGS

Please report any bugs or feature requests to

C<bug-math-business-lookbacks at rt.cpan.org>, or through the web

interface at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Math-Business-Lookback>.

I will be notified, and then you'll automatically be notified of progress on

your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Math::Business::Lookback

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Math-Business-Lookback>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Math-Business-Lookback>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Math-Business-Lookback>

=item * Search CPAN

L<http://search.cpan.org/dist/Math-Business-Lookback/>

=back

=cut

1;
