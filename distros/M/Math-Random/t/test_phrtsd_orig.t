#! perl

use Test2::V0;
use Math::Random qw(:all);

random_set_seed_from_phrase( 'En arkhe en ho Logos' );

# Check for original phrtsd version, which this test requires
{
    my @seeds      = random_get_seed;
    my $new_phrtsd = $seeds[0] == 964_304_455 && $seeds[1] == 841_103_996;
    skip_all 'new phrtsd detected; these tests require the original version'
      if $new_phrtsd;
}

sub fcheck {
    [ map { float( $_, precision => 5 ) } @_ ]
}

#------ TESTS
# NOTE:  Do not change the order of these tests!!  Since at least
# one new variate is produced every time, the results will differ
# if the order is changed.  If new tests have to be added, add them
# at the end.

is(    #
    [ random_uniform( 3, 0, 1.5 ) ],
    fcheck( 0.02021, 0.72981, 0.28370 ),
    'random_uniform',
);

is(    #
    [ random_uniform_integer( 3, 1, 999_999 ) ],
    [ 877_502, 385_465, 712_626 ],
    'random_uniform_integer'
);

is(    #
    [ random_permutation( qw[A 2 c iv E 6 g viii] ) ],
    [qw(iv c 6 2 E A g viii)],
    'random_permutation',
);

is(    #
    [ random_permuted_index( 9 ) ],
    [ 8, 5, 3, 7, 0, 6, 2, 1, 4 ],
    'random_permuted_index'
);

is(    #
    [ random_normal( 3, 50, 2.3 ) ],
    fcheck( 49.96739, 52.24146, 47.73983 ),
    'random_normal',
);

is(    #
    [ random_chi_square( 3, 4 ) ],
    fcheck( 2.53270, 1.71850, 5.85347 ),
    'random_chi_square',
);

is(    #
    [ random_f( 3, 2, 5 ) ],
    fcheck( 1.14801, 2.97847, 0.01688 ),
    'random_f',
);

is(    #
    [ random_beta( 3, 17, 23 ) ],
    fcheck( 0.49457, 0.55133, 0.37236 ),
    'random_beta',
);

is(    #
    [ random_binomial( 3, 31, 0.43 ) ],
    [ 17, 17, 18 ],
    'random_binomial',
);

is(    #
    [ random_poisson( 3, 555 ) ],
    [ 571, 560, 579 ],
    'random_poisson',
);

is(    #
    [ random_exponential( 3, 444 ) ],
    fcheck( 1037.53566, 20.06634, 1063.81861 ),
    'random_exponential',
);

is(    #
    [ random_gamma( 3, 11, 4 ) ],
    fcheck( 0.22119, 0.60820, 0.27125 ),
    'random_gamma',
);

is(    #
    [ random_multinomial( 3, 0.1, 0.72, 0.18 ) ],
    [ 0, 2, 1 ],
    'random_multinomial',
);

is(    #
    [ random_negative_binomial( 3, 10, 0.63 ) ],
    [ 7, 8, 2 ],
    'random_negative_binomial',
);


is(    #
    [ random_multivariate_normal( 2, 1, 1, [ 0.1, 0.0 ], [ 0.0, 0.1 ] ) ],
    [
        fcheck( 0.615922260157962, 0.0165563939840114 ),
        fcheck( 1.27740750809206,  1.1546774445748 ),
    ],
    'random_multivariate_normal',
);

done_testing;
