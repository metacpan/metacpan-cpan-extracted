package Math::Business::BlackScholesMerton::NonBinaries;

use strict;
use warnings;

use List::Util qw(min max);
use Math::CDF qw(pnorm);

our $VERSION = '1.24';    ## VERSION

=head1 NAME

Math::Business::BlackScholesMerton::NonBinaries

=head1 SYNOPSIS

    use Math::Business::BlackScholesMerton::NonBinaries;

    # price of a Call spread option
    my $price_call_option = Math::Business::BlackScholesMerton::NonBinaries::vanilla_call(
        1.35,       # stock price
        1.34,       # barrier
        (7/365),    # time
        0.002,      # payout currency interest rate (0.05 = 5%)
        0.001,      # quanto drift adjustment (0.05 = 5%)
        0.11,       # volatility (0.3 = 30%)
    );

=head1 DESCRIPTION

Contains non-binary option pricing formula.

=cut

=head2 vanilla_call

    USAGE
    my $price = vanilla_call($S, $K, $t, $r_q, $mu, $sigma);

    DESCRIPTION
    Price of a Vanilla Call

=cut

sub vanilla_call {
    my ($S, $K, $t, $r_q, $mu, $sigma) = @_;

    my $d1 = (log($S / $K) + ($mu + $sigma * $sigma / 2.0) * $t) / ($sigma * sqrt($t));
    my $d2 = $d1 - ($sigma * sqrt($t));

    return exp(-$r_q * $t) * ($S * exp($mu * $t) * pnorm($d1) - $K * pnorm($d2));
}

=head2 vanilla_put

    USAGE
    my $price = vanilla_put($S, $K, $t, $r_q, $mu, sigma)

    DESCRIPTION
    Price a standard Vanilla Put

=cut

sub vanilla_put {
    my ($S, $K, $t, $r_q, $mu, $sigma) = @_;

    my $d1 = (log($S / $K) + ($mu + $sigma * $sigma / 2.0) * $t) / ($sigma * sqrt($t));
    my $d2 = $d1 - ($sigma * sqrt($t));

    return -1 * exp(-$r_q * $t) * ($S * exp($mu * $t) * pnorm(-$d1) - $K * pnorm(-$d2));
}

=head2 lbfloatcall

    USAGE
    my $price = lbfloatcall($S, $K, $t, $r_q, $mu, $sigma, $S_max, $S_min)

    DESCRIPTION
    Price of a Lookback Float Call

=cut

sub lbfloatcall {
    my ($S, $K, $t, $r_q, $mu, $sigma, $S_max, $S_min) = @_;

    $S_max = undef;
    my $d1 = _d1_function($S, $S_min, $t, $r_q, $mu, $sigma);
    my $d2 = $d1 - ($sigma * sqrt($t));

    my $value = exp(-$r_q * $t) * ($S * exp($mu * $t) * pnorm($d1) - $S_min * pnorm($d2) + _l_min($S, $S_min, $t, $r_q, $mu, $sigma));

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
    my $d1 = _d1_function($S, $S_max, $t, $r_q, $mu, $sigma);
    my $d2 = $d1 - ($sigma * sqrt($t));

    my $value = exp(-$r_q * $t) * ($S_max * pnorm(-$d2) - $S * exp($mu * $t) * pnorm(-$d1) + _l_max($S, $S_max, $t, $r_q, $mu, $sigma));

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
    my $d1 = _d1_function($S, $K_max, $t, $r_q, $mu, $sigma);
    my $d2 = $d1 - ($sigma * sqrt($t));

    my $value =
        exp(-$r_q * $t) * (max($S_max - $K, 0.0) + $S * exp($mu * $t) * pnorm($d1) - $K_max * pnorm($d2) + _l_max($S, $K_max, $t, $r_q, $mu, $sigma));

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
    my $d1 = _d1_function($S, $K_min, $t, $r_q, $mu, $sigma);
    my $d2 = $d1 - ($sigma * sqrt($t));

    my $value = exp(-$r_q * $t) *
        (max($K - $S_min, 0.0) + $K_min * pnorm(-$d2) - $S * exp($mu * $t) * pnorm(-$d1) + _l_min($S, $K_min, $t, $r_q, $mu, $sigma));

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

=head2 _d1_function

returns the d1 term common to many BlackScholesMerton formulae.

=cut

sub _d1_function {
    my ($S, $K, $t, $r_q, $mu, $sigma) = @_;

    my $value = (log($S / $K) + ($mu + $sigma * $sigma * 0.5) * $t) / ($sigma * sqrt($t));

    return $value;
}

=head2 _l_max

This is a common function use to calculate the lookbacks options price. See [5] for details.

=cut

sub _l_max {
    my ($S, $K, $t, $r_q, $mu, $sigma) = @_;

    my $d1 = _d1_function($S, $K, $t, $r_q, $mu, $sigma);
    my $value;

    if ($mu) {
        $value =
            $S *
            ($sigma**2) /
            (2.0 * $mu) *
            (-($S / $K)**(-2.0 * $mu / ($sigma**2)) * pnorm($d1 - 2.0 * $mu / $sigma * sqrt($t)) + exp($mu * $t) * pnorm($d1));
    } else {
        $value = $S * ($sigma * sqrt($t)) * (dnorm($d1) + $d1 * pnorm($d1));
    }

    return $value;
}

=head2 _l_min

This is a common function use to calculate the lookbacks options price. See [5] for details.

=cut

sub _l_min {
    my ($S, $K, $t, $r_q, $mu, $sigma) = @_;

    my $d1 = _d1_function($S, $K, $t, $r_q, $mu, $sigma);
    my $value;

    if ($mu) {
        $value =
            $S *
            ($sigma**2) /
            (2.0 * $mu) *
            (($S / $K)**(-2.0 * $mu / ($sigma**2)) * pnorm(-$d1 + 2.0 * $mu / $sigma * sqrt($t)) - exp($mu * $t) * pnorm(-$d1));
    } else {
        $value = $S * ($sigma * sqrt($t)) * (dnorm($d1) + $d1 * (pnorm($d1) - 1));
    }

    return $value;
}

=head2 dnorm

Standard normal density function

=cut

sub dnorm {    # Standard normal density function
    my $x  = shift;
    my $pi = 3.14159265359;

    my $value = exp(-$x**2 / 2) / sqrt(2.0 * $pi);

    return $value;
}

=head2 callspread

    USAGE
    my $price = callspread($S, $U, $D, $t, $r_q, $mu, $sigmaU, $sigmaD);

    DESCRIPTION
    Price of a CALL SPREAD

=cut

sub callspread {
    my ($S, $U, $D, $t, $r_q, $mu, $sigmaU, $sigmaD) = @_;

    return vanilla_call($S, $D, $t, $r_q, $mu, $sigmaD) - vanilla_call($S, $U, $t, $r_q, $mu, $sigmaU);
}

=head2 putspread

    USAGE
    my $price = putspread($S, $U, $D, $t, $r_q, $mu, $sigmaU, $sigmaD);

    DESCRIPTION
    Price of a PUT SPREAD

=cut

sub putspread {
    my ($S, $U, $D, $t, $r_q, $mu, $sigmaU, $sigmaD) = @_;

    return vanilla_put($S, $U, $t, $r_q, $mu, $sigmaU) - vanilla_put($S, $D, $t, $r_q, $mu, $sigmaD);
}

1;
