package Math::Business::BlackScholesMerton::NonBinaries;

use strict;
use warnings;

use List::Util qw(min max);
use Math::CDF  qw(pnorm);
use POSIX      qw(ceil);
use Machine::Epsilon;

use constant PI => 3.14159265359;

our $VERSION = '1.25';    ## VERSION

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
    my $d1    = _d1_function($S, $K_max, $t, $r_q, $mu, $sigma);
    my $d2    = $d1 - ($sigma * sqrt($t));

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
    my $d1    = _d1_function($S, $K_min, $t, $r_q, $mu, $sigma);
    my $d2    = $d1 - ($sigma * sqrt($t));

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
    my $x = shift;

    my $value = exp(-$x**2 / 2) / sqrt(2.0 * PI);

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

=head2 standardbarrier

A function implemented by Diethelm Wuertz.

Description of parameters:

$S - starting spot
$H - barrier
$X - exercise price
$K - cash rebate

References:
  Haug, Chapter 2.10.1

=cut

sub standardbarrier {
    my ($S, $H, $X, $K, $tiy, $r, $q, $sigma, $type) = @_;

    die 'wrong type[' . $type . ']' unless $type eq 'c' or $type eq 'p';

    my $mu     = ($q - $sigma**2 / 2) / $sigma**2;
    my $lambda = sqrt($mu**2 + 2 * $r / $sigma**2);
    my $X1     = log($S / $X) / ($sigma * sqrt($tiy)) + (1 + $mu) * $sigma * sqrt($tiy);
    my $X2     = log($S / $H) / ($sigma * sqrt($tiy)) + (1 + $mu) * $sigma * sqrt($tiy);
    my $y1     = (log($H**2 / ($S * $X)) / ($sigma * sqrt($tiy)) + (1 + $mu) * $sigma * sqrt($tiy));
    my $y2     = log($H / $S) / ($sigma * sqrt($tiy)) + (1 + $mu) * $sigma * sqrt($tiy);
    my $Z      = log($H / $S) / ($sigma * sqrt($tiy)) + $lambda * $sigma * sqrt($tiy);
    my ($eta, $phi) = $type eq 'c' ? (1, 1) : (-1, -1);

    my $f1 = ($phi * $S * exp(($q - $r) * $tiy) * pnorm($phi * $X1) - $phi * $X * exp(-$r * $tiy) * pnorm($phi * $X1 - $phi * $sigma * sqrt($tiy)));

    my $f2 = ($phi * $S * exp(($q - $r) * $tiy) * pnorm($phi * $X2) - $phi * $X * exp(-$r * $tiy) * pnorm($phi * $X2 - $phi * $sigma * sqrt($tiy)));

    my $f3 = ($phi * $S * exp(($q - $r) * $tiy) * ($H / $S)**(2 * ($mu + 1)) * pnorm($eta * $y1) -
            $phi * $X * exp(-$r * $tiy) * ($H / $S)**(2 * $mu) * pnorm($eta * $y1 - $eta * $sigma * sqrt($tiy)));

    my $f4 = ($phi * $S * exp(($q - $r) * $tiy) * ($H / $S)**(2 * ($mu + 1)) * pnorm($eta * $y2) -
            $phi * $X * exp(-$r * $tiy) * ($H / $S)**(2 * $mu) * pnorm($eta * $y2 - $eta * $sigma * sqrt($tiy)));

    my $f6 = (
        $K * (
            ($H / $S)**($mu + $lambda) * pnorm($eta * $Z) + ($H / $S)**($mu - $lambda) * pnorm($eta * $Z - 2 * $eta * $lambda * $sigma * sqrt($tiy)))
    );

    if ($X >= $H) {
        return $type eq 'c' ? $f1 - $f3 + $f6 : $f2 - $f4 + $f6;
    }

    return $type eq 'c' ? $f2 + $f6 - $f4 : $f1 - $f3 + $f6;
}

=head2 doubleknockout

Description of parameters:

$S - spot
$H2 - high barrier
$H1 - low barrier
$K - payout strike
$tiy - time in years
$sigma - volatility
$mu - mean
$r - interest rate
$type - 'c' for buy or 'p' for sell

Reference:
    https://core.ac.uk/download/pdf/19187200.pdf

=cut

sub doubleknockout {
    my ($S, $H2, $H1, $K, $tiy, $mu, $sigma, $r, $type) = @_;

    my $eps = machine_epsilon();
    my $l   = log($H2 / $H1);
    my $x   = log($S / $H1);
    my $d   = log($K / $H1);

    my $k = ceil(sqrt(((-2 * log($eps) / $tiy) - ($mu / $sigma)**2) / ((PI * $sigma / $l)**2)));

    if ($type eq 'c') {
        return
            exp(-$r * $tiy) *
            ($H1 * (_calculate_q(1, $l, $l, $mu, $sigma, $x, $k, $tiy) - _calculate_q(1, $d, $l, $mu, $sigma, $x, $k, $tiy)) -
                $K * (_calculate_q(0, $l, $l, $mu, $sigma, $x, $k, $tiy) - _calculate_q(0, $d, $l, $mu, $sigma, $x, $k, $tiy)));
    }

    return
        exp(-$r * $tiy) *
        ($K * (_calculate_q(0, $d, $l, $mu, $sigma, $x, $k, $tiy) - _calculate_q(0, 0, $l, $mu, $sigma, $x, $k, $tiy)) -
            $H1 * (_calculate_q(1, $d, $l, $mu, $sigma, $x, $k, $tiy) - _calculate_q(1, 0, $l, $mu, $sigma, $x, $k, $tiy)));
}

sub _calculate_q {
    my ($alpha, $y, $l, $mu, $sigma, $x, $k, $tiy) = @_;

    my $z = 0;
    for (my $i = 1; $i <= $k; $i++) {
        my $lambda = 0.5 * (($mu / $sigma)**2 + ($i * PI * $sigma / $l)**2);
        $z +=
            exp(-$lambda * $tiy) *
            sin($i * PI * $x / $l) *
            ((($mu / ($sigma)**2 + $alpha) * sin($i * PI * $y / $l) - ($i * PI / $l) * cos($i * PI * $y / $l)) /
                (($mu / ($sigma)**2 + $alpha)**2 + ($i * PI / $l)**2));
    }

    return (2 / $l) * exp(($mu / $sigma**2) * ($y - $x)) * exp($alpha * $y) * $z;
}

1;
