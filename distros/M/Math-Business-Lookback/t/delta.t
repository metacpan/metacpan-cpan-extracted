#!/etc/rmg/bin/perl

use strict;
use warnings;

use Test::Most;
use Test::Warnings;
use Test::Exception;

use Math::Business::Lookback::Greeks::Delta;
use Format::Util::Numbers qw(roundnear);

subtest 'test_delta' => sub {

    test_greek({    # Fixed strike lookback call
            type          => 'lbfixedcall',
            strike        => 101,
            spot          => 100,
            discount_rate => 0.4,
            t             => 0.1,
            mu            => 0.3,
            vol           => 0.1,
            spot_max      => 102,
            spot_min      => undef
        },
        0.82097
    );

    test_greek({    # Fixed strike lookback put
            type          => 'lbfixedput',
            strike        => 105,
            spot          => 100,
            discount_rate => 0.4,
            t             => 0.1,
            mu            => 0.3,
            vol           => 0.1,
            spot_max      => undef,
            spot_min      => 95
        },
        -0.0154
    );

    test_greek({    # Floating strike lookback call
            type          => 'lbfloatcall',
            strike        => 100,
            spot          => 100,
            discount_rate => 0.4,
            t             => 0.1,
            mu            => 0.3,
            vol           => 0.1,
            spot_max      => undef,
            spot_min      => 95
        },
        0.97465
    );

    test_greek({    # Floating strike lookback put
            type          => 'lbfloatput',
            strike        => 100,
            spot          => 100,
            discount_rate => 0.4,
            t             => 0.1,
            mu            => 0.3,
            vol           => 0.1,
            spot_max      => 105,
            spot_min      => undef
        },
        -0.58939
    );

    test_greek({    # High low lookback
            type          => 'lbhighlow',
            strike        => 100,
            spot          => 100,
            discount_rate => 0.4,
            t             => 0.1,
            mu            => 0.3,
            vol           => 0.1,
            spot_max      => 105,
            spot_min      => 95
        },
        0.38527
    );

};

#$S, $K, $t, $r_q, $mu, $sigma, $S_min or $S_min or both.

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

    is roundnear(0.00001, $price), roundnear(0.00001, $expected), "correct delta for " . $type;
}

done_testing;

