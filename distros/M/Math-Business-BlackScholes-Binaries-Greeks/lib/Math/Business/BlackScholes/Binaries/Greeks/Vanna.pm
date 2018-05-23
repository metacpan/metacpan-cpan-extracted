package Math::Business::BlackScholes::Binaries::Greeks::Vanna;
use strict;
use warnings;

our $VERSION = '0.06';    ## VERSION

use List::Util qw( max );
use Math::CDF qw( pnorm );
use Math::Trig;
use Math::Business::BlackScholesMerton::Binaries;
use Math::Business::BlackScholes::Binaries::Greeks::Delta;
use Math::Business::BlackScholes::Binaries::Greeks::Vega;
use Math::Business::BlackScholes::Binaries::Greeks::Math qw( dgauss );

=head1 NAME

Math::Business::BlackScholes::Binaries::Greeks::Vanna

=head1 DESCRIPTION

Gets the Vanna for different options, Vanilla and Foreign for all our bet types

=head1 SUBROUTINES

See L<Math::Business::BlackScholes::Binaries::Greeks>

=cut

sub vanilla_call {
    my ($S, $K, $t, $r_q, $mu, $vol) = @_;

    my $d1 = (log($S / $K) + ($mu + $vol * $vol / 2.0) * $t) / ($vol * sqrt($t));
    my $d2 = $d1 - ($vol * sqrt($t));

    my $vega = Math::Business::BlackScholes::Binaries::Greeks::Vega::vanilla_call($S, $K, $t, $r_q, $mu, $vol);
    my $vanna = -$vega * $d2 / ($S * $vol * sqrt($t));
    return $vanna;
}

sub vanilla_put {
    my ($S, $K, $t, $r_q, $mu, $vol) = @_;

    # Same as vanna of vanilla call (because vega_vanilla_call = vega_vanilla_put)
    return vanilla_call($S, $K, $t, $r_q, $mu, $vol);
}

sub call {
    my ($S, $U, $t, $r_q, $mu, $vol) = @_;

    my $d1 = (log($S / $U) + ($mu + $vol * $vol / 2.0) * $t) / ($vol * sqrt($t));
    my $d2 = $d1 - ($vol * sqrt($t));

    my $vanna = -dgauss($d2) * exp(-$r_q * $t) * (1 - $d1 * $d2) / ($S * $vol * $vol * sqrt($t));
    return $vanna;
}

sub put {
    my ($S, $D, $t, $r_q, $mu, $vol) = @_;

    return -1 * call($S, $D, $t, $r_q, $mu, $vol);
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

    my $theta = (($mu) / $vol) + (0.5 * $vol);

    my $theta_ = (($mu) / $vol) - (0.5 * $vol);

    # Floor v_ squared at just above zero in case negative interest rates push it negative.
    my $v_ = sqrt(max($Math::Business::BlackScholesMerton::Binaries::SMALL_VALUE_MU, ($theta_ * $theta_) + (2 * (1 - $w) * $r_q)));

    my $e = (log($S / $U) - ($vol * $v_ * $t)) / ($vol * $sqrt_t);
    my $e_ = (-log($S / $U) - ($vol * $v_ * $t)) / ($vol * $sqrt_t);

    my $eta = ($S > $U) ? 1 : -1;

    my $pa_e = (log($U / $S) / ($vol * $vol * $sqrt_t)) + (($theta_ * $theta) / ($vol * $v_) * $sqrt_t);
    my $pa_e_ = (-log($U / $S) / ($vol * $vol * $sqrt_t)) + (($theta_ * $theta) / ($vol * $v_) * $sqrt_t);

    my $A  = -($theta + $theta_ + ($theta_ * $theta / $v_) + $v_) / ($vol * $vol);
    my $A_ = -($theta + $theta_ - ($theta_ * $theta / $v_) - $v_) / ($vol * $vol);

    my $d_ = (log($U / $S) - $vol * $theta_ * $t) / ($vol * $sqrt_t);

    my ($part1, $part2, $subpart_1_1, $subpart_1_2, $subpart_2_1, $subpart_2_2);

    $subpart_1_1 =
        pnorm(-$eta * $e) * $A * (-$vol - ($theta_ + $v_) * log($U / $S));
    $subpart_1_2 = $eta * dgauss($e) / $sqrt_t * ($d_ * $pa_e + $A * log($U / $S) - 1.0 / $vol);

    $subpart_2_1 = pnorm($eta * $e_) * $A_ * (-$vol - ($theta_ - $v_) * log($U / $S));
    $subpart_2_2 = $eta * dgauss($e_) / $sqrt_t * ($d_ * $pa_e_ - $A_ * log($U / $S) + 1.0 / $vol);

    $part1 = (($U / $S)**(($theta_ + $v_) / $vol)) * ($subpart_1_1 - $subpart_1_2);
    $part2 = (($U / $S)**(($theta_ - $v_) / $vol)) * ($subpart_2_1 + $subpart_2_2);

    return ($part1 + $part2) * exp(-$w * $r_q * $t) / ($vol * $S);
}

sub notouch {
    my ($S, $U, $t, $r_q, $mu, $vol, $w) = @_;

    # No touch bet always pay out at end
    $w = 1;

    # Since the value VALUE_NOTOUCH = D(T) - VALUE_ONETOUCH, where D(T)
    # is the discount from time T, any derivative (other than with
    # respect to time or discount rate) of the value of notouch
    # is just the negative of the onetouch derivative.
    return (-1 * onetouch($S, $U, $t, $r_q, $mu, $vol, $w));
}

sub upordown {
    my ($S, $U, $D, $t, $r_q, $mu, $vol, $w) = @_;

    # $w = 0, paid at hit
    # $w = 1, paid at end
    if (not defined $w) { $w = 0; }

    return ot_up_ko_down_pelsser_1997($S, $U, $D, $t, $r_q, $mu, $vol, $w) + ot_down_ko_up_pelsser_1997($S, $U, $D, $t, $r_q, $mu, $vol, $w);
}

sub xw_common_function_pelsser_1997 {
    my ($S, $U, $D, $t, $r_q, $mu, $vol, $w, $eta) = @_;

    my $pi = Math::Trig::pi;

    my $h = log($U / $D);
    my $x = log($S / $D);

    # $eta = 1, onetouch up knockout down
    # $eta = 0, onetouch down knockout up
    # This variable used to check stability
    if (not defined $eta) {
        die
            "$0: (xw_common_function_pelsser_1997) Wrong usage of this function for S=$S, U=$U, D=$D, t=$t, r_q=$r_q, mu=$mu, vol=$vol, w=$w. eta not defined.";
    }
    if ($eta == 0) { $x = $h - $x; }

    my $r_dash = $r_q * (1 - $w);
    my $mu_new = $mu - (0.5 * $vol * $vol);
    my $mu_dash = sqrt(max($Math::Business::BlackScholesMerton::Binaries::SMALL_VALUE_MU, ($mu_new * $mu_new) + (2 * $vol * $vol * $r_dash)));

    my $omega = ($vol * $vol);

    my $series_part = 0;
    my $hyp_part    = 0;

    my $stability_constant =
        Math::Business::BlackScholesMerton::Binaries::get_stability_constant_pelsser_1997($S, $U, $D, $t, $r_q, $mu, $vol, $w, $eta, 1);

    my $iterations_required = Math::Business::BlackScholesMerton::Binaries::get_min_iterations_pelsser_1997($S, $U, $D, $t, $r_q, $mu, $vol, $w);

    for (my $k = 1; $k < $iterations_required; $k++) {
        my $lambda_k_dash = (0.5 * (($mu_dash * $mu_dash) / ($vol * $vol) + ($k * $k * $pi * $pi * $vol * $vol) / ($h * $h)));

        # d{lambda_k}/dw
        my $dlambdak_domega = 0.5 * (-($mu_new / $omega) - (($mu_new * $mu_new) / ($omega * $omega)) + (($k * $k * $pi * $pi) / ($h * $h)));

        my $beta_k = exp(-$lambda_k_dash * $t) / $lambda_k_dash;

        # d{beta_k}/d{lambda_k}
        my $dbetak_dlambdak = -exp(-$lambda_k_dash * $t) * (($t * $lambda_k_dash + 1) / ($lambda_k_dash**2));

        # d{beta_k}/dw
        my $dbetak_domega = $dlambdak_domega * $dbetak_dlambdak;

        my $phi = (1.0 / ($h * $h * $h)) * ($omega * $dbetak_domega + $beta_k) * $k * $k;

        $series_part += $phi * $pi * $pi * cos($k * $pi * ($h - $x) / $h);

        if ($k == 1
            and (not(abs(2 * $vol * $phi / $S) < $stability_constant)))
        {
            die
                "$0: PELSSER VANNA formula for S=$S, U=$U, D=$D, t=$t, r_q=$r_q, mu=$mu, vol=$vol, w=$w, eta=$eta cannot be evaluated because PELSSER VANNA stability conditions (2 * $vol * $phi / $S less than $stability_constant) not met. This could be due to barriers too big, volatilities too low, interest/dividend rates too high, or machine accuracy too low.";
        }
    }

    my $alpha = $mu_dash / ($vol * $vol);
    my $dalpha_domega = -(($mu_new * $omega) + (2 * $mu_new * $mu_new) + (2 * $r_dash * $omega)) / (2 * $alpha * $omega * $omega * $omega);

# We have to handle the special case where the denominator approaches 0, see our documentation in
# quant/Documents/Breakout_bet.tex under the SVN "quant" module.
    if ((Math::Trig::sinh($alpha * $h)**2) == 0) {
        $hyp_part = 0;
    } else {
        $hyp_part =
            -($dalpha_domega * $alpha) *
            ((($h + $x) * Math::Trig::cosh($alpha * ($h - $x))) + (($h - $x) * Math::Trig::cosh($alpha * ($h + $x)))) /
            (2 * Math::Trig::sinh($alpha * $h) * Math::Trig::sinh($alpha * $h)) +
            $dalpha_domega *
            (Math::Trig::sinh($alpha * ($h - $x)) + Math::Trig::sinh($alpha * ($h + $x))) /
            (2 * Math::Trig::sinh($alpha * $h) * Math::Trig::sinh($alpha * $h));
    }

    my $d2c_domegadx = ($hyp_part + $series_part) * exp(-$r_q * $w * $t);

    return $d2c_domegadx;
}

sub ot_up_ko_down_pelsser_1997 {
    my ($S, $U, $D, $t, $r_q, $mu, $vol, $w) = @_;

    my $mu_new = $mu - (0.5 * $vol * $vol);
    my $h      = log($U / $D);
    my $x      = log($S / $D);
    my $omega  = ($vol * $vol);

    my $c = Math::Business::BlackScholesMerton::Binaries::common_function_pelsser_1997($S, $U, $D, $t, $r_q, $mu, $vol, $w, 1);
    my $dc_domega = Math::Business::BlackScholes::Binaries::Greeks::Vega::w_common_function_pelsser_1997($S, $U, $D, $t, $r_q, $mu, $vol, $w, 1);
    my $dc_dx = Math::Business::BlackScholes::Binaries::Greeks::Delta::x_common_function_pelsser_1997($S, $U, $D, $t, $r_q, $mu, $vol, $w, 1);
    my $d2c_domegadx = xw_common_function_pelsser_1997($S, $U, $D, $t, $r_q, $mu, $vol, $w, 1);

    my $d2Vu_domegadx =
        ((((0.5 * $omega) + $mu_new) / ($omega * $omega)) * (1 + ($mu_new / $omega) * ($h - $x)) * exp(($mu_new / $omega) * ($h - $x)) * $c) -
        ((((0.5 * $omega) + $mu_new) / ($omega * $omega)) * ($h - $x) * exp(($mu_new / $omega) * ($h - $x)) * $dc_dx) -
        (($mu_new / $omega) * exp(($mu_new / $omega) * ($h - $x)) * $dc_domega) +
        (exp(($mu_new / $omega) * ($h - $x)) * $d2c_domegadx);

    return (2 * $vol / $S) * $d2Vu_domegadx;
}

sub ot_down_ko_up_pelsser_1997 {
    my ($S, $U, $D, $t, $r_q, $mu, $vol, $w) = @_;

    my $mu_new = $mu - (0.5 * $vol * $vol);
    my $x      = log($S / $D);
    my $omega  = ($vol * $vol);

    my $c = Math::Business::BlackScholesMerton::Binaries::common_function_pelsser_1997($S, $U, $D, $t, $r_q, $mu, $vol, $w, 0);
    my $dc_domega = Math::Business::BlackScholes::Binaries::Greeks::Vega::w_common_function_pelsser_1997($S, $U, $D, $t, $r_q, $mu, $vol, $w, 0);
    my $dc_dx = Math::Business::BlackScholes::Binaries::Greeks::Delta::x_common_function_pelsser_1997($S, $U, $D, $t, $r_q, $mu, $vol, $w, 0);
    my $d2c_domegadx = xw_common_function_pelsser_1997($S, $U, $D, $t, $r_q, $mu, $vol, $w, 0);

    my $d2Vl_domegadx =
        ((((0.5 * $omega) + $mu_new) / ($omega * $omega)) * (1 - ($mu_new / $omega) * $x) * exp(-($mu_new / $omega) * $x) * $c) -
        ((((0.5 * $omega) + $mu_new) / ($omega * $omega)) * $x * exp(-($mu_new / $omega) * $x) * $dc_dx) -
        (($mu_new / $omega) * exp(-($mu_new / $omega) * $x) * $dc_domega) -
        (exp(-($mu_new / $omega) * $x) * $d2c_domegadx);

    return (2 * $vol / $S) * $d2Vl_domegadx;
}

sub range {
    my ($S, $U, $D, $t, $r_q, $mu, $vol, $w) = @_;

    # Range always pay out at end
    $w = 1;

    return -1 * upordown($S, $U, $D, $t, $r_q, $mu, $vol, $w);
}

1;

