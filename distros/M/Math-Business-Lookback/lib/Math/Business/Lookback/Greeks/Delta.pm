package Math::Business::Lookback::Greeks::Delta;
use strict;
use warnings;

use List::Util qw(max min);
use Math::CDF  qw(pnorm);

use Math::Business::Lookback::Common;

our $VERSION = '0.01';    ## VERSION

=head2 lbfixedcall

Delta of a Lookback Fixed Call

=cut

sub lbfixedcall {
    my ($S, $K, $t, $r_q, $mu, $sigma, $S_max, $S_min) = @_;

    my $delta;

    $S_min = undef;
    my $a1 = _a1($S, $K, $t, $r_q, $mu, $sigma, max($S_max, $K));

    $delta = exp(($mu - $r_q) * $t) * pnorm($a1) + _l_max_delta($S, $K, $t, $r_q, $mu, $sigma, max($S_max, $K));

    return $delta;
}

=head2 lbfixedput

Delta of a Lookback Fixed Put

=cut

sub lbfixedput {
    my ($S, $K, $t, $r_q, $mu, $sigma, $S_max, $S_min) = @_;

    my $delta;

    $S_max = undef;
    my $a1 = _a1($S, $K, $t, $r_q, $mu, $sigma, min($S_min, $K));

    $delta = -exp(($mu - $r_q) * $t) * pnorm(-$a1) + _l_min_delta($S, $K, $t, $r_q, $mu, $sigma, min($S_min, $K));

    return $delta;
}

=head2 lbfloatcall

Delta of a Lookback Float Call

=cut

sub lbfloatcall {
    my ($S, $K, $t, $r_q, $mu, $sigma, $S_max, $S_min) = @_;

    my $delta;

    $S_max = undef;
    my $a1 = _a1($S, $K, $t, $r_q, $mu, $sigma, $S_min);

    $delta = exp(($mu - $r_q) * $t) * pnorm($a1) + _l_min_delta($S, $K, $t, $r_q, $mu, $sigma, $S_min);

    return $delta;
}

=head2 lbfloatput

Delta of a Lookback Float Put

=cut

sub lbfloatput {
    my ($S, $K, $t, $r_q, $mu, $sigma, $S_max, $S_min) = @_;

    my $delta;

    $S_min = undef;
    my $a1 = _a1($S, $K, $t, $r_q, $mu, $sigma, $S_max);

    $delta = -exp(($mu - $r_q) * $t) * pnorm(-$a1) + _l_max_delta($S, $K, $t, $r_q, $mu, $sigma, $S_max);

    return $delta;
}

=head2 lbhighlow

Delta of a Lookback HighLow

=cut

sub lbhighlow {
    my ($S, $K, $t, $r_q, $mu, $sigma, $S_max, $S_min) = @_;

    my $delta = lbfloatcall($S, $K, $t, $r_q, $mu, $sigma, $S_max, $S_min) + lbfloatput($S, $K, $t, $r_q, $mu, $sigma, $S_max, $S_min);

    return $delta;
}

sub _a1 {
    my ($S, $K, $t, $r_q, $mu, $sigma, $S_min_or_max) = @_;

    my $a1 = (log($S / $S_min_or_max) + ($mu + (0.5 * ($sigma**2))) * $t) / ($sigma * sqrt($t));

    return $a1;
}

sub _l_min_delta {
    my ($S, $K, $t, $r_q, $mu, $sigma, $S_min) = @_;

    my $a1 = _a1($S, $K, $t, $r_q, $mu, $sigma, $S_min);

    my $l_min_delta;

    if ($mu == 0) {
        $l_min_delta = exp(-$r_q * $t) * $sigma * sqrt($t) * Math::Business::Lookback::Common::dnorm($a1);
        $l_min_delta = $l_min_delta + exp(-$r_q * $t) * (pnorm($a1) - 1) * (log($S / $S_min) + 1 + ($mu * $t) + (0.5 * ($sigma**2) * $t));
    } else {
        $l_min_delta = (exp(($mu - $r_q) * $t) * 0.5 * ($sigma**2) * pnorm(-$a1)) / $mu;
        $l_min_delta =
            $l_min_delta +
            (-1 + 0.5 * ($sigma**2) / $mu) *
            exp(-$r_q * $t) *
            (($S / $S_min)**(-2 * $mu / ($sigma**2))) *
            pnorm(-$a1 + (2 * $mu * sqrt($t)) / $sigma);
    }

    return $l_min_delta;
}

sub _l_max_delta {
    my ($S, $K, $t, $r_q, $mu, $sigma, $S_max) = @_;

    my $b1 = _a1($S, $K, $t, $r_q, $mu, $sigma, $S_max);

    my $l_max_delta;

    if ($mu == 0) {
        $l_max_delta = exp(-$r_q * $t) * $sigma * sqrt($t) * Math::Business::Lookback::Common::dnorm($b1);
        $l_max_delta = $l_max_delta + exp(-$r_q * $t) * pnorm($b1) * (log($S / $S_max) + 1 + ($mu * $t) + (0.5 * ($sigma**2) * $t));
    } else {
        $l_max_delta = (exp(($mu - $r_q) * $t) * 0.5 * ($sigma**2) * pnorm($b1)) / $mu;
        $l_max_delta = $l_max_delta +
            (1 - 0.5 * ($sigma**2) / $mu) * exp(-$r_q * $t) * (($S / $S_max)**(-2 * $mu / ($sigma**2))) * pnorm($b1 - (2 * $mu * sqrt($t)) / $sigma);
    }

    return $l_max_delta;
}

1;
