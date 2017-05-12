package Math::Business::BlackScholes::Binaries::Greeks::Volga;
use strict;
use warnings;

our $VERSION = '0.05';    ## VERSION

use List::Util qw( max );
use Math::Business::BlackScholes::Binaries;
use Math::Business::BlackScholes::Binaries::Greeks::Vega;
use Math::Business::BlackScholes::Binaries::Greeks::Math qw( dgauss );
use Math::CDF qw( pnorm );
use Math::Trig;

=head1 NAME

Math::Business::BlackScholes::Binaries::Greeks::Volga

=head1 DESCRIPTION

Gets the Volga for different options, Vanilla and Foreign for all our bet types

=cut

=head1 SUBROUTINES

See L<Math::Business::BlackScholes::Binaries::Greeks>

=cut

sub vanilla_call {
    my ($S, $K, $t, $r_q, $mu, $vol) = @_;

    my $d1 = (log($S / $K) + ($mu + $vol * $vol / 2.0) * $t) / ($vol * sqrt($t));
    my $d2 = $d1 - ($vol * sqrt($t));

    my $vega = Math::Business::BlackScholes::Binaries::Greeks::Vega::vanilla_call($S, $K, $t, $r_q, $mu, $vol);

    my $volga = $vega * $d1 * $d2 / $vol;
    return $volga;
}

sub vanilla_put {
    my ($S, $K, $t, $r_q, $mu, $vol) = @_;

    # Same as volga of vanilla call (because vega_vanilla_call = vega_vanilla_put)
    return vanilla_call($S, $K, $t, $r_q, $mu, $vol);
}

sub call {
    my ($S, $U, $t, $r_q, $mu, $vol) = @_;

    my $d1 = (log($S / $U) + ($mu + $vol * $vol / 2.0) * $t) / ($vol * sqrt($t));
    my $d2 = $d1 - ($vol * sqrt($t));

    my $volga = -dgauss($d2) * exp(-$r_q * $t) / ($vol * $vol) * (-$d1 - $d2 + ($d1 * $d1 * $d2));
    return $volga;
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

    my $theta  = (($mu) / $vol) + (0.5 * $vol);
    my $theta_ = (($mu) / $vol) - (0.5 * $vol);

    # Floor v_ squared at just above zero in case negative interest rates push it negative.
    my $v_ = sqrt(max($Math::Business::BlackScholes::Binaries::SMALL_VALUE_MU, ($theta_ * $theta_) + (2 * (1 - $w) * $r_q)));

    my $e = (log($S / $U) - ($vol * $v_ * $t)) / ($vol * $sqrt_t);
    my $e_ = (-log($S / $U) - ($vol * $v_ * $t)) / ($vol * $sqrt_t);

    my $eta = ($S > $U) ? 1 : -1;

    my $pa_e = (log($U / $S) / ($vol * $vol * $sqrt_t)) + ($theta_ * $theta) / ($vol * $v_) * $sqrt_t;
    my $pa_e_ = (-log($U / $S) / ($vol * $vol * $sqrt_t)) + (($theta_ * $theta) / ($vol * $v_) * $sqrt_t);

    my $A  = -($theta + $theta_ + ($theta_ * $theta / $v_) + $v_) / ($vol * $vol);
    my $A_ = -($theta + $theta_ - ($theta_ * $theta / $v_) - $v_) / ($vol * $vol);

    my $g = 1 / ($vol * $vol * $v_) * (-$theta * $theta - $theta_ * $theta_ - $theta * $theta_ + $theta * $theta_ * $theta * $theta_ / ($v_ * $v_));

    my $pa_2_e  = -2 * log($U / $S) / ($vol * $vol * $vol * $sqrt_t) + $g * $sqrt_t;
    my $pa_2_e_ = 2 * log($U / $S) /  ($vol * $vol * $vol * $sqrt_t) + $g * $sqrt_t;

    my $pa_A  = ($theta + $theta_) / ($vol * $vol * $vol) - (2 * $A + $g) / $vol;
    my $pa_A_ = ($theta + $theta_) / ($vol * $vol * $vol) - (2 * $A_ - $g) / $vol;

    my ($part1, $part2, $subpart_1_1, $subpart_1_2, $subpart_2_1, $subpart_2_2);

    $subpart_1_1 = pnorm(-$eta * $e) * log($U / $S) * ($A * $A * log($U / $S) + $pa_A);
    $subpart_1_2 = $eta * dgauss($e) * (2 * log($U / $S) * $A * $pa_e - $e * $pa_e * $pa_e + $pa_2_e);

    $subpart_2_1 = pnorm($eta * $e_) * log($U / $S) * ($A_ * $A_ * log($U / $S) + $pa_A_);
    $subpart_2_2 = $eta * dgauss($e_) * (2 * log($U / $S) * $A_ * $pa_e_ - $e_ * $pa_e_ * $pa_e_ + $pa_2_e_);

    $part1 = (($U / $S)**(($theta_ + $v_) / $vol)) * ($subpart_1_1 - $subpart_1_2);
    $part2 = (($U / $S)**(($theta_ - $v_) / $vol)) * ($subpart_2_1 + $subpart_2_2);

    return exp(-$w * $r_q * $t) * ($part1 + $part2);
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

sub w_common_function_pelsser_1997 {
    my ($S, $U, $D, $t, $r_q, $mu, $vol, $w, $eta) = @_;

    my $pi = Math::Trig::pi;

    my $h = log($U / $D);
    my $x = log($S / $D);

    # $eta = 1, onetouch up knockout down
    # $eta = 0, onetouch down knockout up
    # This variable used to check stability
    if (not defined $eta) {
        die
            "$0: (w_common_function_pelsser_1997) Wrong usage of this function for S=$S, U=$U, D=$D, t=$t, r_q=$r_q, mu=$mu, vol=$vol, w=$w. eta not defined.";
    }
    if ($eta == 0) { $x = $h - $x; }

    my $mu_new = $mu - (0.5 * $vol * $vol);
    my $mu_dash = sqrt(max($Math::Business::BlackScholes::Binaries::SMALL_VALUE_MU, ($mu_new * $mu_new) + (2 * $vol * $vol * $r_q * (1 - $w))));

    my $r_dash = $r_q * (1 - $w);
    my $omega = ($vol * $vol);

    my $series_part = 0;
    my $hyp_part    = 0;

    my $stability_constant =
        Math::Business::BlackScholes::Binaries::get_stability_constant_pelsser_1997($S, $U, $D, $t, $r_q, $mu, $vol, $w, $eta, 1);

    my $iterations_required = Math::Business::BlackScholes::Binaries::get_min_iterations_pelsser_1997($S, $U, $D, $t, $r_q, $mu, $vol, $w);

    for (my $k = 1; $k < $iterations_required; $k++) {
        my $lambda_k_dash = (0.5 * (($mu_dash * $mu_dash) / ($vol * $vol) + ($k * $k * $pi * $pi * $vol * $vol) / ($h * $h)));

        # d{lambda_k}/dw
        my $dlambdak_domega = 0.5 * (-($mu_new / $omega) - (($mu_new * $mu_new) / ($omega * $omega)) + (($k * $k * $pi * $pi) / ($h * $h)));
        my $d2lambdak_domega2 = 0.5 * ($omega + 2 * $mu_new) / (2 * $omega * $omega);
        $d2lambdak_domega2 *= (1 + (2 * $mu_new / $omega));

        # d{beta_k}/d{lambda_k}
        my $dbetak_dlambdak = -exp(-$lambda_k_dash * $t) * (($t * $lambda_k_dash + 1) / ($lambda_k_dash**2));
        my $d2betak_dlambdak2 = -($t * $dbetak_dlambdak) + exp(-$lambda_k_dash * $t) * (($t / ($lambda_k_dash**2)) + (2 / ($lambda_k_dash**3)));

        # d{beta_k}/dw
        my $dbetak_domega = $dlambdak_domega * $dbetak_dlambdak;
        my $d2betak_domega2 = ($dlambdak_domega * $dlambdak_domega * $d2betak_dlambdak2) + ($dbetak_dlambdak * $d2lambdak_domega2);

        my $phi = (1.0 / ($h * $h)) * ($omega * $d2betak_domega2 + 2 * $dbetak_domega) * $k;

        $series_part += $phi * $pi * sin($k * $pi * ($h - $x) / $h);

        if ($k == 1 and (not(abs(4 * $vol * $vol * $phi) < $stability_constant))) {
            die
                "$0: PELSSER VOLGA formula for S=$S, U=$U, D=$D, t=$t, r_q=$r_q, mu=$mu, vol=$vol, w=$w, eta=$eta cannot be evaluated because PELSSER VOLGA stability conditions (4 * $vol * $vol * $phi less than $stability_constant) not met. This could be due to barriers too big, volatilities too low, interest/dividend rates too high, or machine accuracy too low.";
        }
    }

    my $alpha = $mu_dash / ($vol * $vol);
    my $dalpha_domega = -(($mu_new * $omega) + (2 * $mu_new * $mu_new) + (2 * $r_dash * $omega)) / (2 * $alpha * $omega * $omega * $omega);

    my $d2alpha_domega2 = $alpha * ($omega**3) * (2 * $mu_new + $omega - 4 * $r_dash);
    $d2alpha_domega2 +=
        (($mu_new * $omega) + (2 * $mu_new * $mu_new) + (2 * $r_dash * $omega)) *
        ((6 * $alpha * $omega * $omega) + (2 * $omega * $omega * $omega * $dalpha_domega));
    $d2alpha_domega2 = $d2alpha_domega2 / (4 * $alpha * $alpha * ($omega**6));

    # We have to handle the special case where the denominator approaches 0, see our documentation in
    # quant/Documents/Breakout_bet.tex under the SVN "quant" module.
    my $hyp_part1;
    if ((Math::Trig::sinh($alpha * $h)**3) == 0) {
        $hyp_part1 = 0;
    } else {
        $hyp_part1 =
            Math::Trig::sinh($alpha * $h) *
            ($h**2 - $x**2) *
            (Math::Trig::cosh($alpha * ($h - $x)) - Math::Trig::cosh($alpha * ($h + $x))) -
            (2 * $h * Math::Trig::cosh($alpha * $h)) *
            ((($h + $x) * Math::Trig::sinh($alpha * ($h - $x))) - (($h - $x) * Math::Trig::sinh($alpha * ($h + $x))));
        $hyp_part1 *= ($dalpha_domega**2) / (2 * (Math::Trig::sinh($alpha * $h)**3));
    }

    my $hyp_part2;
    if ((Math::Trig::sinh($alpha * $h)**2) == 0) {
        $hyp_part2 = 0;
    } else {
        $hyp_part2 =
            ($d2alpha_domega2 / (2 * (Math::Trig::sinh($alpha * $h)**2))) *
            (($h + $x) * Math::Trig::sinh($alpha * ($h - $x)) - ($h - $x) * Math::Trig::sinh($alpha * ($h + $x)));
    }

    $hyp_part = $hyp_part1 + $hyp_part2;

    my $d2c_domega2 = ($hyp_part - $series_part) * exp(-$r_q * $w * $t);

    return $d2c_domega2;
}

sub ot_up_ko_down_pelsser_1997 {
    my ($S, $U, $D, $t, $r_q, $mu, $vol, $w) = @_;

    my $mu_new = $mu - (0.5 * $vol * $vol);
    my $h      = log($U / $D);
    my $x      = log($S / $D);
    my $omega  = ($vol * $vol);

    my $c = Math::Business::BlackScholes::Binaries::common_function_pelsser_1997($S, $U, $D, $t, $r_q, $mu, $vol, $w, 1);
    my $dc_domega = Math::Business::BlackScholes::Binaries::Greeks::Vega::w_common_function_pelsser_1997($S, $U, $D, $t, $r_q, $mu, $vol, $w, 1);
    my $d2c_domega2 = w_common_function_pelsser_1997($S, $U, $D, $t, $r_q, $mu, $vol, $w, 1);

    my $Vu = Math::Business::BlackScholes::Binaries::ot_up_ko_down_pelsser_1997($S, $U, $D, $t, $r_q, $mu, $vol, $w);
    my $dVu_domega = -((0.5 * $omega + $mu_new) * ($h - $x) / ($omega * $omega)) * $c;
    $dVu_domega += $dc_domega;
    $dVu_domega *= exp($mu_new * ($h - $x) / $omega);

    my $d2Vu_domega2 =
        -((((0.5 * $omega) + $mu_new) / ($omega * $omega)) * ($h - $x) * $dVu_domega) +
        ((($omega + (2 * $mu_new)) / ($omega**3)) * ($h - $x) * $Vu) -
        ((((0.5 * $omega) + $mu_new) / ($omega * $omega)) * ($h - $x) * exp($mu_new * ($h - $x) / $omega) * $dc_domega) +
        (exp($mu_new * ($h - $x) / $omega) * $d2c_domega2);

    return (4 * $vol * $vol * $d2Vu_domega2) + (2 * $dVu_domega);
}

sub ot_down_ko_up_pelsser_1997 {
    my ($S, $U, $D, $t, $r_q, $mu, $vol, $w) = @_;

    my $mu_new = $mu - (0.5 * $vol * $vol);
    my $x      = log($S / $D);
    my $omega  = ($vol * $vol);

    my $c = Math::Business::BlackScholes::Binaries::common_function_pelsser_1997($S, $U, $D, $t, $r_q, $mu, $vol, $w, 0);
    my $dc_domega = Math::Business::BlackScholes::Binaries::Greeks::Vega::w_common_function_pelsser_1997($S, $U, $D, $t, $r_q, $mu, $vol, $w, 0);
    my $d2c_domega2 = w_common_function_pelsser_1997($S, $U, $D, $t, $r_q, $mu, $vol, $w, 0);

    my $Vl = Math::Business::BlackScholes::Binaries::ot_down_ko_up_pelsser_1997($S, $U, $D, $t, $r_q, $mu, $vol, $w);
    my $dVl_domega = ((0.5 * $omega + $mu_new) * $x / ($omega * $omega)) * $c;
    $dVl_domega += $dc_domega;
    $dVl_domega *= exp(-$mu_new * $x / $omega);

    my $d2Vl_domega2 =
        ((((0.5 * $omega) + $mu_new) / ($omega * $omega)) * $x * $dVl_domega) -
        ((($omega + (2 * $mu_new)) / ($omega**3)) * $x * $Vl) +
        ((((0.5 * $omega) + $mu_new) / ($omega * $omega)) * $x * exp(-$mu_new * $x / $omega) * $dc_domega) +
        (exp(-$mu_new * $x / $omega) * $d2c_domega2);

    return (4 * $vol * $vol * $d2Vl_domega2) + (2 * $dVl_domega);
}

sub range {
    my ($S, $U, $D, $t, $r_q, $mu, $vol, $w) = @_;

    # Range always pay out at end
    $w = 1;

    return -1 * upordown($S, $U, $D, $t, $r_q, $mu, $vol, $w);
}

1;

