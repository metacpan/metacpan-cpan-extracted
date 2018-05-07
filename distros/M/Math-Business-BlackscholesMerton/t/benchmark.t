#!/etc/rmg/bin/perl

use strict;
use warnings;

use Test::Most;
use Test::Warnings;
use Test::Exception;

use Math::Business::BlackScholesMerton::NonBinaries;
use Format::Util::Numbers qw(roundnear);
use Text::CSV::Slurp;

my $pricing_parameters = Text::CSV::Slurp->load(file => 't/pricing_params.csv');

subtest 'benchmark' => sub {
    #spot,strike,duration,r_q,mu,vol,s_max,s_min,bbg_price,bbg_delta
    foreach my $line (@$pricing_parameters) {
        my $type      = $line->{type};
        my $spot      = $line->{spot};
        my $strike    = $line->{strike};
        my $duration  = $line->{duration};
        my $r_q       = $line->{r_q};
        my $mu        = $line->{mu};
        my $vol       = $line->{vol};
        my $s_max     = $line->{s_max};
        my $s_min     = $line->{s_min};
        my $bbg_price = $line->{bbg_price};
        my $bbg_delta = $line->{bbg_delta};

        test_price({
                type          => $type,
                strike        => $strike,
                spot          => $spot,
                discount_rate => $r_q,
                t             => $duration / 365,
                mu            => $mu,
                vol           => $vol,
                spot_max      => $s_max,
                spot_min      => $s_min
            },
            $bbg_price
        );

        SKIP: {
            skip 'enable this when we move lookbacks greeks to blackscholes', 1;
            test_greek({
                    type          => $type,
                    strike        => $strike,
                    spot          => $spot,
                    discount_rate => $r_q,
                    t             => $duration / 365,
                    mu            => $mu,
                    vol           => $vol,
                    spot_max      => $s_max,
                    spot_min      => $s_min
                },
                $bbg_delta * 0.01
            );
        }
    }
};

#$S, $K, $t, $r_q, $mu, $sigma, $S_min or $S_min or both.

sub test_price {
    my $args     = shift;
    my $expected = shift;

    my $type          = $args->{type};
    my $strike        = $args->{strike};
    my $spot          = $args->{spot};
    my $discount_rate = $args->{discount_rate};
    my $t             = $args->{t};
    my $mu            = $args->{mu};
    my $sigma         = $args->{vol};
    my $s_max         = $args->{spot_max};
    my $s_min         = $args->{spot_min};

    my $price;

    my $formula = 'Math::Business::BlackScholesMerton::NonBinaries::' . $type;

    my $func = \&$formula;

    $price = $func->($spot, $strike, $t, $discount_rate, $mu, $sigma, $s_max, $s_min);

    my $diff = abs($price - $expected) / $expected;

    cmp_ok($diff, '<', 0.08, 'Diff is within permissible range');
}

sub test_greek {
    my $args     = shift;
    my $expected = shift;

    my $type          = $args->{type};
    my $strike        = $args->{strike};
    my $spot          = $args->{spot};
    my $discount_rate = $args->{discount_rate};
    my $t             = $args->{t};
    my $mu            = $args->{mu};
    my $sigma         = $args->{vol};
    my $s_max         = $args->{spot_max};
    my $s_min         = $args->{spot_min};

    my $price;

    my $formula = 'Math::Business::Lookback::Greeks::Delta::' . $type;

    my $func = \&$formula;

    $price = $func->($spot, $strike, $t, $discount_rate, $mu, $sigma, $s_max, $s_min);

    my $diff = abs($price - $expected) / $expected;
    cmp_ok($diff, '<', 0.12, 'Diff is within permissible range');
}

done_testing;

