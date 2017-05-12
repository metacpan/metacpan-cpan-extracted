package Math::Business::BlackScholes::Binaries::Greeks::Gamma;
use strict;
use warnings;

our $VERSION = '0.05';    ## VERSION

=head1 NAME

Math::Business::BlackScholes::Binaries::Greeks::Gamma

=head1 DESCRIPTION

Gets the gamma for different options, Vanilla and Foreign for all our bet types

=cut

=head1 SUBROUTINES

See L<Math::Business::BlackScholes::Binaries::Greeks>

=cut

use List::Util qw( max );
use Math::CDF qw( pnorm );
use Math::Trig;
use Math::Business::BlackScholes::Binaries;
use Math::Business::BlackScholes::Binaries::Greeks::Math qw( ddgauss dgauss );

sub vanilla_call {
    my ($S0, $Strike, $t, $r_q, $mu, $vol) = @_;

    my $d1 = (log($S0 / $Strike) + ($mu + (($vol**2) / 2)) * $t) / ($vol * sqrt($t));

    my $gamma =
        dgauss($d1) * exp(($mu - $r_q) * $t) / ($S0 * $vol * sqrt($t));

    return $gamma;
}

sub vanilla_put {
    return vanilla_call(@_);
}

sub call {
    my ($S, $U, $t, $r_q, $mu, $vol) = @_;

    my $v = $mu - ($vol**2) / 2;
    my $a = log($U / $S);

    my $da = -1 / $S;
    my $dda = 1 / ($S * $S);

    my $q = ($a - $v * $t) / ($vol * sqrt($t));
    my $dq  = $da /  ($vol * sqrt($t));
    my $ddq = $dda / ($vol * sqrt($t));

    my $gamma =
        -exp(-$r_q * $t) * (ddgauss($q) * $dq * $dq + dgauss($q) * $ddq);

    return $gamma;
}

sub put {
    my ($S, $D, $t, $r_q, $mu, $vol) = @_;

    my $v   = $mu - ($vol**2) / 2;
    my $b   = log($D / $S);
    my $db  = -1 / $S;
    my $ddb = 1 / ($S * $S);

    my $q = ($b - $v * $t) / ($vol * sqrt($t));
    my $dq  = $db /  ($vol * sqrt($t));
    my $ddq = $ddb / ($vol * sqrt($t));

    my $gamma =
        exp(-$r_q * $t) * (ddgauss($q) * $dq * $dq + dgauss($q) * $ddq);

    return $gamma;
}

sub expirymiss {
    my ($S, $U, $D, $t, $r_q, $mu, $vol) = @_;

    return call($S, $U, $t, $r_q, $mu, $vol) + put($S, $D, $t, $r_q, $mu, $vol);
}

sub expiryrange {
    my ($S, $U, $D, $t, $r_q, $mu, $vol) = @_;

    return -1 * expirymiss($S, $U, $D, $t, $r_q, $mu, $vol);
}

sub onetouch {
    my ($S, $U, $t, $r_q, $mu, $vol, $w) = @_;
    if (not defined $w) {
        $w = 0;
    }

    my $sqrt_t = sqrt($t);

    my $theta_ = (($mu) / $vol) - (0.5 * $vol);

    # Floor v_ squared near zero in case negative interest rates push it negative.
    my $v_ = sqrt(max($Math::Business::BlackScholes::Binaries::SMALL_VALUE_MU, ($theta_ * $theta_) + (2 * (1 - $w) * $r_q)));

    my $e = (log($S / $U) - ($vol * $v_ * $t)) / ($vol * $sqrt_t);

    my $e_ = (-log($S / $U) - ($vol * $v_ * $t)) / ($vol * $sqrt_t);

    my $eta = ($S > $U) ? 1 : -1;

    my $part1 = (($U / $S)**(($theta_ + $v_) / $vol)) * pnorm(-$eta * $e) * ($r_q * (1 - $w) + ($mu) * ($theta_ + $v_) / $vol);
    my $part2 = (($U / $S)**(($theta_ - $v_) / $vol)) * pnorm($eta * $e_) * ($r_q * (1 - $w) + ($mu) * ($theta_ - $v_) / $vol);
    my $part3 = $eta * (($U / $S)**(($theta_ + $v_) / $vol)) * dgauss($e) * (-$e_ * 0.5 / $t + ($mu) / ($vol * $sqrt_t));
    my $part4 = $eta * (($U / $S)**(($theta_ - $v_) / $vol)) * dgauss($e_) * ($e * 0.5 / $t + ($mu) / ($vol * $sqrt_t));

    my $gamma = $part1 + $part2 + $part3 + $part4;
    return $gamma * 2 * exp(-$w * $r_q * $t) / ($vol * $vol * $S * $S);
}

sub notouch {
    my ($S, $U, $t, $r_q, $mu, $vol, $w) = @_;

    # No touch bet always pay out at end
    $w = 1;

    return -1 * onetouch($S, $U, $t, $r_q, $mu, $vol, $w);
}

sub upordown {
    my ($S, $U, $D, $t, $r_q, $mu, $vol, $w) = @_;

    # $w = 0, paid at hit
    # $w = 1, paid at end
    if (not defined $w) { $w = 0; }

    return ot_up_ko_down_pelsser_1997($S, $U, $D, $t, $r_q, $mu, $vol, $w) + ot_down_ko_up_pelsser_1997($S, $U, $D, $t, $r_q, $mu, $vol, $w);
}

sub xx_common_function_pelsser_1997 {
    my ($S, $U, $D, $t, $r_q, $mu, $vol, $w, $eta) = @_;

    my $pi = Math::Trig::pi;

    my $h = log($U / $D);
    my $x = log($S / $D);

    # $eta = 1, onetouch up knockout down
    # $eta = 0, onetouch down knockout up
    # This variable used to check stability
    if (not defined $eta) {
        die
            "$0: (xx_common_function_pelsser_1997) Wrong usage of this function for S=$S, U=$U, D=$D, t=$t, r=$r_q, mu=$mu, vol=$vol, w=$w. eta not defined.";
    }
    if ($eta == 0) { $x = $h - $x; }

    my $mu_ = $mu - (0.5 * $vol * $vol);
    my $mu_dash =
        sqrt(max($Math::Business::BlackScholes::Binaries::SMALL_VALUE_MU, ($mu_ * $mu_) + (2 * $vol * $vol * $r_q * (1 - $w))));

    my $series_part = 0;
    my $hyp_part    = 0;

    my $stability_constant =
        Math::Business::BlackScholes::Binaries::get_stability_constant_pelsser_1997($S, $U, $D, $t, $r_q, $mu, $vol, $w, $eta, 3);

    my $iterations_required = Math::Business::BlackScholes::Binaries::get_min_iterations_pelsser_1997($S, $U, $D, $t, $r_q, $mu, $vol, $w);

    for (my $k = 1; $k < $iterations_required; $k++) {
        my $lambda_k_dash = (0.5 * (($mu_dash * $mu_dash) / ($vol * $vol) + ($k * $k * $pi * $pi * $vol * $vol) / ($h * $h)));

        my $phi = ($vol * $vol) / ($h**4) * exp(-$lambda_k_dash * $t) * ($k**3) / $lambda_k_dash;

        $series_part += $phi * ($pi**3) * sin($k * $pi * ($h - $x) / $h);

        if ($k == 1
            and (not(abs($phi / ($S**2)) < $stability_constant)))
        {
            die
                "$0: PELSSER GAMMA formula for S=$S, U=$U, D=$D, t=$t, r=$r_q, mu=$mu, vol=$vol, w=$w, eta=$eta cannot be evaluated because PELSSER GAMMA stability conditions ($phi / ($S * $S) less than $stability_constant) not met. This could be due to barriers too big, volatilities too low, interest/dividend rates too high, or machine accuracy too low.";
        }
    }

    # Need to take care when $mu goes to zero
    if (abs($mu_) < $Math::Business::BlackScholes::Binaries::SMALL_VALUE_MU) {
        my $sign = ($mu_ >= 0) ? 1 : -1;
        $mu_ = $sign * $Math::Business::BlackScholes::Binaries::SMALL_VALUE_MU;
        $mu_dash =
            sqrt(max($Math::Business::BlackScholes::Binaries::SMALL_VALUE_MU, ($mu_ * $mu_) + (2 * $vol * $vol * $r_q * (1 - $w))));
    }

    $hyp_part = (($mu_dash**2) / ($vol**4)) * (Math::Trig::sinh($mu_dash * $x / ($vol * $vol)) / Math::Trig::sinh($mu_dash * $h / ($vol * $vol)));

    my $d2c_dwdx = ($hyp_part + $series_part) * exp(-$r_q * $t * $w);

    return $d2c_dwdx;
}

sub ot_up_ko_down_pelsser_1997 {
    my ($S, $U, $D, $t, $r_q, $mu, $vol, $w) = @_;

    my $mu_ = $mu - (0.5 * $vol * $vol);
    my $h   = log($U / $D);
    my $x   = log($S / $D);

    my $c = Math::Business::BlackScholes::Binaries::common_function_pelsser_1997($S, $U, $D, $t, $r_q, $mu, $vol, $w, 1);
    my $dc_dx = Math::Business::BlackScholes::Binaries::Greeks::Delta::x_common_function_pelsser_1997($S, $U, $D, $t, $r_q, $mu, $vol, $w, 1);
    my $d2c_dx2 = xx_common_function_pelsser_1997($S, $U, $D, $t, $r_q, $mu, $vol, $w, 1);

    my $dVu_dx =
        -(($mu_ / ($vol * $vol)) * Math::Business::BlackScholes::Binaries::common_function_pelsser_1997($S, $U, $D, $t, $r_q, $mu, $vol, $w, 1));
    $dVu_dx += Math::Business::BlackScholes::Binaries::Greeks::Delta::x_common_function_pelsser_1997($S, $U, $D, $t, $r_q, $mu, $vol, $w, 1);
    $dVu_dx *= exp($mu_ * ($h - $x) / ($vol * $vol));

    my $d2Vu_dx2 =
        ((($mu_**2) / ($vol**4)) * exp(($mu_ / ($vol * $vol)) * ($h - $x)) * $c) -
        (2 * ($mu_ / ($vol**2)) * exp(($mu_ / ($vol * $vol)) * ($h - $x)) * $dc_dx) +
        (exp(($mu_ / ($vol**2)) * ($h - $x)) * $d2c_dx2);

    return (1 / ($S**2)) * ($d2Vu_dx2 - $dVu_dx);
}

sub ot_down_ko_up_pelsser_1997 {
    my ($S, $U, $D, $t, $r_q, $mu, $vol, $w) = @_;

    my $mu_ = $mu - (0.5 * $vol * $vol);
    my $x = log($S / $D);

    my $c = Math::Business::BlackScholes::Binaries::common_function_pelsser_1997($S, $U, $D, $t, $r_q, $mu, $vol, $w, 0);
    my $dc_dx = Math::Business::BlackScholes::Binaries::Greeks::Delta::x_common_function_pelsser_1997($S, $U, $D, $t, $r_q, $mu, $vol, $w, 0);
    my $d2c_dx2 = xx_common_function_pelsser_1997($S, $U, $D, $t, $r_q, $mu, $vol, $w, 0);

    my $dVl_dx =
        -(($mu_ / ($vol * $vol)) * Math::Business::BlackScholes::Binaries::common_function_pelsser_1997($S, $U, $D, $t, $r_q, $mu, $vol, $w, 0));
    $dVl_dx -= Math::Business::BlackScholes::Binaries::Greeks::Delta::x_common_function_pelsser_1997($S, $U, $D, $t, $r_q, $mu, $vol, $w, 0);
    $dVl_dx *= exp(-$mu_ * $x / ($vol * $vol));

    my $d2Vl_dx2 =
        ((($mu_**2) / ($vol**4)) * exp(-($mu_ / ($vol * $vol)) * $x) * $c) +
        (2 * ($mu_ / ($vol**2)) * exp(-($mu_ / ($vol * $vol)) * $x) * $dc_dx) +
        (exp(-($mu_ / ($vol**2)) * $x) * $d2c_dx2);

    return (1 / ($S**2)) * ($d2Vl_dx2 - $dVl_dx);
}

sub range {
    my ($S, $U, $D, $t, $r_q, $mu, $vol, $w) = @_;

    # Range always pay out at end
    $w = 1;

    return -1 * upordown($S, $U, $D, $t, $r_q, $mu, $vol, $w);
}

1;

