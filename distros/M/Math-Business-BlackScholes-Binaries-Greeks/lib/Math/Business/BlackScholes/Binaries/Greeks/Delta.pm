package Math::Business::BlackScholes::Binaries::Greeks::Delta;
use strict;
use warnings;

our $VERSION = '0.05';    ## VERSION

=head1 NAME

Math::Business::BlackScholes::Binaries::Greeks::Delta

=head1 DESCRIPTION

Gets the delta for different options, Vanilla and Foreign for all contract types

=head1 COMMENTS

It is tricky to decide what form to use. Should the delta be with respect to
1/$S, or with respect to $S? For the binary bets, whether foreign or domestic
we are differentiating with respect to $S.

For a vanilla, the correct way should be with respect to 1/$S (so that we know
how many units of the domestic currency to hedge), but to keep things standard,
we do it with respect to $S.

For example take USDJPY vanilla call with premium in USD. Thus this is a vanilla
contract on JPY. Thus delta with respect to 1/$S tells us how many units of JPY
to hedge, but with respect to $S, there really isn't a meaning and needs to be
converted back before interpretation.

=cut

=head1 SUBROUTINES

See L<Math::Business::BlackScholes::Binaries::Greeks>

=cut

use List::Util qw(max);
use Math::CDF qw(pnorm);
use Math::Trig;
use Math::Business::BlackScholes::Binaries;
use Math::Business::BlackScholes::Binaries::Greeks::Math qw( dgauss );

sub vanilla_call {
    my ($S, $K, $t, $r_q, $mu, $vol) = @_;

    my $d1 = (log($S / $K) + ($mu + $vol * $vol / 2.0) * $t) / ($vol * sqrt($t));

    return exp(($mu - $r_q) * $t) * pnorm($d1);
}

sub vanilla_put {
    my ($S, $K, $t, $r_q, $mu, $vol) = @_;

    my $d1 = (log($S / $K) + ($mu + $vol * $vol / 2.0) * $t) / ($vol * sqrt($t));

    return -exp(($mu - $r_q) * $t) * pnorm(-$d1);
}

sub call {
    my ($S, $U, $t, $r_q, $mu, $vol) = @_;

    my $d2 = (log($S / $U) + ($mu - $vol * $vol / 2.0) * $t) / ($vol * sqrt($t));

    return exp(-$r_q * $t) * dgauss($d2) / ($vol * sqrt($t) * $S);
}

sub put {
    my ($S, $D, $t, $r_q, $mu, $vol) = @_;

    my $d2 = (log($S / $D) + ($mu - $vol * $vol / 2.0) * $t) / ($vol * sqrt($t));

    return -exp(-$r_q * $t) * dgauss($d2) / ($vol * sqrt($t) * $S);
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

    # w = 0, rebate paid at hit.
    # w = 1, rebate paid at end.
    if (not defined $w) {
        $w = 0;
    }

    my $sqrt_t = sqrt($t);

    my $theta_ = ($mu / $vol) - (0.5 * $vol);

    # Floor v_ squared near zero in case negative interest rates push it negative.
    my $v_ = sqrt(max($Math::Business::BlackScholes::Binaries::SMALL_VALUE_MU, ($theta_ * $theta_) + (2 * (1 - $w) * $r_q)));

    my $e = (log($S / $U) - ($vol * $v_ * $t)) / ($vol * $sqrt_t);

    my $e_ = (-log($S / $U) - ($vol * $v_ * $t)) / ($vol * $sqrt_t);

    my $eta = ($S > $U) ? 1 : -1;

    my $part1 =
        ($theta_ + $v_) * pnorm(-$eta * $e) + $eta * dgauss($e) / $sqrt_t;
    my $part2 =
        ($theta_ - $v_) * pnorm($eta * $e_) + $eta * dgauss($e_) / $sqrt_t;

    my $delta = (($U / $S)**(($theta_ + $v_) / $vol)) * $part1 + (($U / $S)**(($theta_ - $v_) / $vol)) * $part2;

    return -$delta * exp(-$w * $r_q * $t) / ($vol * $S);
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

sub x_common_function_pelsser_1997 {
    my ($S, $U, $D, $t, $r_q, $mu, $vol, $w, $eta) = @_;

    my $pi = Math::Trig::pi;

    my $h = log($U / $D);
    my $x = log($S / $D);

    # $eta = 1, onetouch up knockout down
    # $eta = 0, onetouch down knockout up
    # This variable used to check stability
    if (not defined $eta) {
        die
            "$0: (x_common_function_pelsser_1997) Wrong usage of this function for S=$S, U=$U, D=$D, t=$t, r_q=$r_q, mu=$mu, vol=$vol, w=$w. eta not defined.";
    }
    if ($eta == 0) { $x = $h - $x; }

    my $mu_new = $mu - (0.5 * $vol * $vol);
    my $mu_dash =
        sqrt(max($Math::Business::BlackScholes::Binaries::SMALL_VALUE_MU, ($mu_new * $mu_new) + (2 * $vol * $vol * $r_q * (1 - $w))));

    my $series_part = 0;
    my $hyp_part    = 0;

    my $stability_constant =
        Math::Business::BlackScholes::Binaries::get_stability_constant_pelsser_1997($S, $U, $D, $t, $r_q, $mu, $vol, $w, $eta, 2);

    my $iterations_required = Math::Business::BlackScholes::Binaries::get_min_iterations_pelsser_1997($S, $U, $D, $t, $r_q, $mu, $vol, $w);

    for (my $k = 1; $k < $iterations_required; $k++) {
        my $lambda_k_dash = (0.5 * (($mu_dash * $mu_dash) / ($vol * $vol) + ($k * $k * $pi * $pi * $vol * $vol) / ($h * $h)));

        my $phi = ($vol * $vol) / ($h * $h * $h) * exp(-$lambda_k_dash * $t) * $k * $k / $lambda_k_dash;

        $series_part += $phi * $pi * $pi * cos($k * $pi * ($h - $x) / $h);

        #
        # For delta, the stability function is $phi/$S, for gamma it is different,
        # but we shall ignore for now.
        #
        if ($k == 1 and (not(abs($phi / $S) < $stability_constant))) {
            die
                "$0: PELSSER DELTA formula for S=$S, U=$U, D=$D, t=$t, r_q=$r_q, mu=$mu, vol=$vol, w=$w, eta=$eta cannot be evaluated because PELSSER DELTA stability conditions ($phi / $S less than $stability_constant) not met. This could be due to barriers too big, volatilities too low, interest/dividend rates too high, or machine accuracy too low.";
        }
    }

    # Need to take care when $mu goes to zero
    if (abs($mu_new) < $Math::Business::BlackScholes::Binaries::SMALL_VALUE_MU) {
        my $sign = ($mu_new >= 0) ? 1 : -1;
        $mu_new = $sign * $Math::Business::BlackScholes::Binaries::SMALL_VALUE_MU;
        $mu_dash = sqrt(($mu_new * $mu_new) + (2 * $vol * $vol * $r_q * (1 - $w)));
    }

    $hyp_part = ($mu_dash / ($vol * $vol)) * (Math::Trig::cosh($mu_dash * $x / ($vol * $vol)) / Math::Trig::sinh($mu_dash * $h / ($vol * $vol)));

    my $dc_dx = ($hyp_part + $series_part) * exp(-$r_q * $t * $w);

    return $dc_dx;
}

sub ot_up_ko_down_pelsser_1997 {
    my ($S, $U, $D, $t, $r_q, $mu, $vol, $w) = @_;

    my $mu_new = $mu - (0.5 * $vol * $vol);
    my $h      = log($U / $D);
    my $x      = log($S / $D);

    my $dVu_dx =
        -(($mu_new / ($vol * $vol)) * Math::Business::BlackScholes::Binaries::common_function_pelsser_1997($S, $U, $D, $t, $r_q, $mu, $vol, $w, 1));

    $dVu_dx += x_common_function_pelsser_1997($S, $U, $D, $t, $r_q, $mu, $vol, $w, 1);
    $dVu_dx *= exp($mu_new * ($h - $x) / ($vol * $vol));

    # dV/dS = dV/dx * dx/dS = dV/dx * 1/S
    return $dVu_dx / $S;
}

sub ot_down_ko_up_pelsser_1997 {
    my ($S, $U, $D, $t, $r_q, $mu, $vol, $w) = @_;

    my $mu_new = $mu - (0.5 * $vol * $vol);
    my $x = log($S / $D);

    my $dVl_dx =
        -(($mu_new / ($vol * $vol)) * Math::Business::BlackScholes::Binaries::common_function_pelsser_1997($S, $U, $D, $t, $r_q, $mu, $vol, $w, 0));

    $dVl_dx -= x_common_function_pelsser_1997($S, $U, $D, $t, $r_q, $mu, $vol, $w, 0);
    $dVl_dx *= exp(-$mu_new * $x / ($vol * $vol));

    # dV/dS = dV/dx * dx/dS = dV/dx * 1/S
    return $dVl_dx / $S;
}

sub range {
    my ($S, $U, $D, $t, $r_q, $mu, $vol, $w) = @_;

    # Range always pay out at end
    $w = 1;

    return -1 * upordown($S, $U, $D, $t, $r_q, $mu, $vol, $w);
}

1;

