package Math::Business::BlackScholes::Binaries::Greeks::Theta;
use strict;
use warnings;

our $VERSION = '0.05';    ## VERSION

=head1 NAME

Math::Business::BlackScholes::Binaries::Greeks::Theta

=head1 DESCRIPTION

Gets the Theta for different options, Vanilla and Foreign for all our bet types

=cut

=head1 SUBROUTINES

See L<Math::Business::BlackScholes::Binaries::Greeks>

=cut

use List::Util qw(max);
use Math::Trig;
use Math::CDF qw(pnorm);
use Math::Business::BlackScholes::Binaries;
use Math::Business::BlackScholes::Binaries::Greeks::Math qw(dgauss);

sub vanilla_call {
    my ($S, $K, $t, $r_q, $mu, $vol) = @_;

    my $d1 = (log($S / $K) + ($mu) * $t) / ($vol * sqrt($t)) + 0.5 * $vol * sqrt($t);
    my $d2 = $d1 - $vol * sqrt($t);

    my $theta =
        -($vol * $S * exp(($mu - $r_q) * $t) * dgauss($d1)) / (2 * sqrt($t)) +
        (($r_q - $mu) * $S * exp(($mu - $r_q) * $t) * pnorm($d1)) -
        ($r_q * $K * exp(-$r_q * $t) * pnorm($d2));

    return $theta;
}

sub vanilla_put {
    my ($S, $K, $t, $r_q, $mu, $vol) = @_;

    my $d1 = (log($S / $K) + ($mu) * $t) / ($vol * sqrt($t)) + 0.5 * $vol * sqrt($t);
    my $d2 = $d1 - $vol * sqrt($t);

    my $theta =
        -($vol * $S * exp(($mu - $r_q) * $t) * dgauss(-$d1)) / (2 * sqrt($t)) -
        (($r_q - $mu) * $S * exp(($mu - $r_q) * $t) * pnorm(-$d1)) +
        ($r_q * $K * exp(-$r_q * $t) * pnorm(-$d2));

    return $theta;
}

sub call {
    my ($S, $U, $t, $r_q, $mu, $vol) = @_;

    my $d1 = (log($S / $U) + ($mu) * $t) / ($vol * sqrt($t)) + 0.5 * $vol * sqrt($t);
    my $d2 = $d1 - $vol * sqrt($t);

    my $theta = $r_q * pnorm($d2) + dgauss($d2) * $d1 / (2 * $t) - dgauss($d2) * ($mu) / ($vol * sqrt($t));

    return $theta * exp(-$r_q * $t);
}

sub put {
    my ($S, $D, $t, $r_q, $mu, $vol) = @_;

    my $d1 = (log($S / $D) + ($mu) * $t) / ($vol * sqrt($t)) + 0.5 * $vol * sqrt($t);
    my $d2 = $d1 - $vol * sqrt($t);

    my $theta = $r_q * pnorm(-$d2) - dgauss($d2) * $d1 / (2 * $t) + dgauss($d2) * ($mu) / ($vol * sqrt($t));

    return $theta * exp(-$r_q * $t);
}

sub expirymiss {
    my ($S, $U, $D, $t, $r_q, $mu, $vol) = @_;

    return call($S, $U, $t, $r_q, $mu, $vol) + put($S, $D, $t, $r_q, $mu, $vol);
}

sub expiryrange {
    my ($S, $U, $D, $t, $r_q, $mu, $vol) = @_;

    return $r_q * exp(-$r_q * $t) - expirymiss($S, $U, $D, $t, $r_q, $mu, $vol);
}

sub onetouch {
    my ($S, $U, $t, $r_q, $mu, $vol, $w) = @_;
    if (not defined $w) {
        $w = 0;
    }

    my $sqrt_t = sqrt($t);

    my $theta_ = (($mu) / $vol) - (0.5 * $vol);

    # Floor v_ squared at zero in case negative interest rates push it negative.
    my $v_ = sqrt(max($Math::Business::BlackScholes::Binaries::SMALL_VALUE_MU, ($theta_ * $theta_) + (2 * (1 - $w) * $r_q)));

    my $e = (log($S / $U) - ($vol * $v_ * $t)) / ($vol * $sqrt_t);

    my $eta = ($S > $U) ? 1 : -1;

    my $part1 = $w * $r_q * Math::Business::BlackScholes::Binaries::onetouch($S, $U, $t, $r_q, $mu, $vol, $w);
    my $part2 = $eta * exp(-$w * $r_q * $t) / ($vol * ($t**1.5)) * (($U / $S)**(($theta_ + $v_) / $vol)) * dgauss($e) * log($U / $S);

    my $theta_onetouch = $part1 + $part2;

    return $theta_onetouch;
}

sub notouch {
    my ($S, $U, $t, $r_q, $mu, $vol, $w) = @_;

    # No touch bet always pay out at end
    $w = 1;

    return $r_q * exp(-$r_q * $t) - onetouch($S, $U, $t, $r_q, $mu, $vol, $w);
}

sub upordown {
    my ($S, $U, $D, $t, $r_q, $mu, $vol, $w) = @_;

    if (($S >= $U) || ($S <= $D)) { return 0; }

    # $w = 0, paid at hit
    # $w = 1, paid at end
    if (not defined $w) { $w = 0; }

    return ot_up_ko_down_pelsser_1997($S, $U, $D, $t, $r_q, $mu, $vol, $w) + ot_down_ko_up_pelsser_1997($S, $U, $D, $t, $r_q, $mu, $vol, $w);
}

sub common_function_pelsser_1997 {
    my ($S, $U, $D, $t, $r_q, $mu, $vol, $w, $eta) = @_;

    my $pi = Math::Trig::pi;

    my $h = log($U / $D);
    my $x = log($S / $D);

    # $eta = 1, onetouch up knockout down
    # $eta = 0, onetouch down knockout up
    # This variable used to check stability
    if (not defined $eta) {
        die
            "$0: (common_function_pelsser_1997) Wrong usage of this function for S=$S, U=$U, D=$D, t=$t, r=$r_q, mu=$mu, vol=$vol, w=$w. eta not defined.";
    }
    if ($eta == 0) { $x = $h - $x; }

    my $mu_ = $mu - (0.5 * $vol * $vol);
    my $mu_dash =
        sqrt(max($Math::Business::BlackScholes::Binaries::SMALL_VALUE_MU, ($mu_ * $mu_) + (2 * $vol * $vol * $r_q * (1 - $w))));

    my $hyp_part    = 0;
    my $series_part = 0;

    my $stability_constant =
        Math::Business::BlackScholes::Binaries::get_stability_constant_pelsser_1997($S, $U, $D, $t, $r_q, $mu, $vol, $w, $eta, 1);

    my $iterations_required = Math::Business::BlackScholes::Binaries::get_min_iterations_pelsser_1997($S, $U, $D, $t, $r_q, $mu, $vol, $w);

    for (my $k = 1; $k < $iterations_required; $k++) {
        my $lambda_k_dash = (0.5 * (($mu_dash * $mu_dash) / ($vol * $vol) + ($k * $k * $pi * $pi * $vol * $vol) / ($h * $h)));

        my $phi = ($vol * $vol) / ($h * $h) * (1 + ($r_q * $w / $lambda_k_dash)) * exp(-($r_q * $w + $lambda_k_dash) * $t) * $k;

        $series_part += $phi * $pi * sin($k * $pi * ($h - $x) / $h);

        if ($k == 1 and (not(abs($phi) < $stability_constant))) {
            die
                "$0: PELSSER THETA formula for S=$S, U=$U, D=$D, t=$t, r=$r_q, mu=$mu, vol=$vol, w=$w, eta=$eta cannot be evaluated because PELSSER THETA stability conditions ($phi less than $stability_constant) not met. This could be due to barriers too big, volatilities too low, interest/dividend rates too high, or machine accuracy too low.";
        }
    }

# We have to handle the special case where the denominator approaches 0, see our documentation in
# quant/Documents/Breakout_bet.tex under the SVN "quant" module.
    if ((Math::Trig::sinh($mu_dash * $h / ($vol * $vol))) == 0) {
        $hyp_part = -($r_q * $w) * exp(-$r_q * $w * $t) * ($x / $h);
    } else {
        $hyp_part =
            -($r_q * $w) * exp(-$r_q * $w * $t) * Math::Trig::sinh($mu_dash * $x / ($vol * $vol)) / Math::Trig::sinh($mu_dash * $h / ($vol * $vol));
    }

    my $dc_dT = ($hyp_part + $series_part);

    return $dc_dT;
}

sub ot_up_ko_down_pelsser_1997 {
    my ($S, $U, $D, $t, $r_q, $mu, $vol, $w) = @_;

    my $mu_ = $mu - (0.5 * $vol * $vol);
    my $h   = log($U / $D);
    my $x   = log($S / $D);

    my $dc_dT = common_function_pelsser_1997($S, $U, $D, $t, $r_q, $mu, $vol, $w, 1);

    my $dVu_dT = -exp(($mu_ / ($vol * $vol)) * ($h - $x)) * $dc_dT;
    return $dVu_dT;
}

sub ot_down_ko_up_pelsser_1997 {
    my ($S, $U, $D, $t, $r_q, $mu, $vol, $w) = @_;

    my $mu_ = $mu - (0.5 * $vol * $vol);
    my $x = log($S / $D);

    my $dc_dT = common_function_pelsser_1997($S, $U, $D, $t, $r_q, $mu, $vol, $w, 0);

    my $dVl_dT = -exp(-($mu_ / ($vol * $vol)) * $x) * $dc_dT;
    return $dVl_dT;
}

sub range {
    my ($S, $U, $D, $t, $r_q, $mu, $vol, $w) = @_;

    # Range always pay out at end
    $w = 1;

    return $r_q * exp(-$r_q * $t) - upordown($S, $U, $D, $t, $r_q, $mu, $vol, $w);
}

1;

