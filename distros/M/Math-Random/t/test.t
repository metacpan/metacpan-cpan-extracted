#! perl

use Test2::V0;
use Math::Random qw(:all);

random_set_seed_from_phrase( 'En arkhe en ho Logos' );


{
    my @seeds      = random_get_seed;
    my $new_phrtsd = $seeds[0] == 964_304_455 && $seeds[1] == 841_103_996;
    skip_all 'original phrtsd detected; these tests require the new version'
      unless $new_phrtsd;
}


# the is() function is prototyped to force scalar context on the
# expected value. so can't use the same function to return checks for
# one element and checks for many, e.g. can't do this:

# is ($got, [ fcheck($a,$b,$c),  ], $name )  # many
# is ($got, fcheck($a) ], $name )            # one

# as the prototype will turn the direct call to fcheck, which returns
# a list, into the count of elements in the list, so this becomes
#
# is ($got, 1, $name )


sub fcheck {
    [ map { float( $_, precision => 5 ) } @_ ]
}

sub sfcheck {
    float( $_, precision => 5 );
}

#------ TESTS
# NOTE:  Do not change the order of these tests!!  Since at least
# one new variate is produced every time, the results will differ
# if the order is changed.  If new tests have to be added, add them
# at the end.

subtest 'list context' => sub {

    random_set_seed_from_phrase( 'En arkhe en ho Logos' );

    is(
        [ random_uniform( 3, 0, 1.5 ) ],    #
        fcheck( 0.05617, 0.51721, 0.83203 ),
        'random_uniform',
    );

    is(
        [ random_uniform_integer( 3, 1, 999_999 ) ],    #
        [ 134_416, 581_232, 488_982 ],
        'random_uniform_integer'
    );

    is(                                                 #
        [ random_permutation( qw[A 2 c iv E 6 g viii] ) ],
        [qw( A g E 6 viii 2 c iv )],
        'random_permutation',
    );

    is(                                                 #
        [ random_permuted_index( 9 ) ],
        [ 3, 7, 6, 8, 1, 0, 2, 5, 4 ],
        'random_permuted_index'
    );

    is(                                                 #
        [ random_normal( 3, 50, 2.3 ) ],
        fcheck( 51.32045, 52.86931, 51.42714 ),
        'random_normal',
    );

    is(                                                 #
        [ random_chi_square( 3, 4 ) ],
        fcheck( 3.06391, 2.69547, 3.06120 ),
        'random_chi_square',
    );

    is(                                                 #
        [ random_f( 3, 2, 5 ) ],
        fcheck( 20.49306, 1.76842, 0.18747 ),
        'random_f',
    );

    is(                                                 #
        [ random_beta( 3, 17, 23 ) ],
        fcheck( 0.42553, 0.39371, 0.35722 ),
        'random_beta',
    );

    is(                                                 #
        [ random_binomial( 3, 31, 0.43 ) ],
        [ 14, 13, 10 ],
        'random_binomial',
    );

    is(                                                 #
        [ random_poisson( 3, 555 ) ],
        [ 510, 557, 536 ],
        'random_poisson',
    );

    is(                                                 #
        [ random_exponential( 3, 444 ) ],
        fcheck( 127.98662, 8.24119, 397.19221 ),
        'random_exponential',
    );

    is(                                                 #
        [ random_gamma( 3, 11, 4 ) ],
        fcheck( 0.47858, 0.32865, 0.56708 ),
        'random_gamma',
    );

    is(                                                 #
        [ random_multinomial( 3, 0.1, 0.72, 0.18 ) ],
        [ 0, 2, 1 ],
        'random_multinomial',
    );

    is(                                                 #
        [ random_negative_binomial( 3, 10, 0.63 ) ],
        [ 0, 2, 5 ],
        'random_negative_binomial',
    );

    is(                                                 #
        [ random_multivariate_normal( 2, 1, 1, [ 0.1, 0.0 ], [ 0.0, 0.1 ] ) ],
        [
            fcheck( -0.0607633190045207, 0.893369401623808 ),    #
            fcheck(  1.51427988386676,   0.887689416564967 ),
        ],
        'random_multivariate_normal',
    );

    is(    #
        [ random_uniform( 3, 0.1, 0.63 ) ],
        fcheck( 0.520719806892417, 0.537560956162718, 0.441518971649517 ),
        'random_uniform',
    );

    is(    #
        [ random_noncentral_chi_square( 3, 5, 0.5 ) ],
        fcheck( 3.0446921958125, 1.42890084938461, 14.6079129017975 ),
        'random_noncentral_chi_square',
    );

    is(    #
        [ random_noncentral_f( 3, 5, 8, 0.5 ) ],
        fcheck( 1.24610734550915, 1.50688092597374, 1.55869913648373 ),
        'random_noncentral_f',
    );

};

subtest 'scalar context' => sub {

    random_set_seed_from_phrase( 'En arkhe en ho Logos' );

    subtest 'random_uniform' => sub {
        is(
            scalar random_uniform( 3, 0, 1.5 ),    #
            sfcheck( $_ ),
            $_,
        ) for 0.05617, 0.51721, 0.83203;

    };

    subtest 'random_uniform_integer' => sub {
        is( scalar random_uniform_integer( 3, 1, 999_999 ), $_, $_, )    #
          for 134_416, 581_232, 488_982;
    };

    is(                                                                  #
        [ random_permutation( qw[A 2 c iv E 6 g viii] ) ],
        [qw( A g E 6 viii 2 c iv )],
        'random_permutation',
    );

    is(                                                                  #
        [ random_permuted_index( 9 ) ],
        [ 3, 7, 6, 8, 1, 0, 2, 5, 4 ],
        'random_permuted_index'
    );

    subtest 'random_normal' => sub {
        is( scalar random_normal( 3, 50, 2.3 ), sfcheck( $_ ), $_, )    #
          for 51.32045, 52.86931, 51.42714;
    };

    subtest 'random_chi_square' => sub {
        is( scalar random_chi_square( 3, 4 ), sfcheck( $_ ), $_, )      #
          for 3.06391, 2.69547, 3.06120;
    };

    subtest 'random_f' => sub {
        is( scalar random_f( 3, 2, 5 ), sfcheck( $_ ), $_, )            #
          for 20.49306, 1.76842, 0.18747;
    };

    subtest 'random_beta' => sub {
        is( scalar random_beta( 3, 17, 23 ), sfcheck( $_ ), $_, )       #
          for 0.42553, 0.39371, 0.35722;
    };

    subtest 'random_binomial' => sub {
        is( scalar random_binomial( 3, 31, 0.43 ), $_, $_, )            #
          for 14, 13, 10;
    };

    subtest 'random_poisson' => sub {
        is( scalar random_poisson( 3, 555 ), $_, $_, )                  #
          for 510, 557, 536;
    };

    subtest 'random_exponential' => sub {
        is( scalar random_exponential( 3, 444 ), sfcheck( $_ ), $_, )    #
          for 127.98662, 8.24119, 397.19221;
    };

    subtest 'random_gamma' => sub {
        is( scalar random_gamma( 3, 11, 4 ), sfcheck( $_ ), $_, )        #
          for 0.47858, 0.32865, 0.56708;
    };

    is(                                                                  #
        [ random_multinomial( 3, 0.1, 0.72, 0.18 ) ],
        [ 0, 2, 1 ],
        'random_multinomial',
    );

    subtest 'random_negative_binomial' => sub {
        is( scalar random_negative_binomial( 3, 10, 0.63 ), $_, $_, )    #
          for 0, 2, 5;
    };

    subtest 'random_multivariate_normal' => sub {
        is(
            scalar random_multivariate_normal( 2, 1, 1, [ 0.1, 0.0 ], [ 0.0, 0.1 ] ),
            fcheck( @$_ ),
            "variate @$_"
        ) for [ -0.0607633190045207, 0.893369401623808 ], [ 1.51427988386676, 0.887689416564967 ];
    };

    subtest 'random_uniform' => sub {
        is(
            random_uniform( 3, 0.1, 0.63 ),    #
            sfcheck( $_ ), $_
        ) for 0.520719806892417, 0.537560956162718, 0.441518971649517;
    };

    subtest 'random_noncentral_chi_square' => sub {
        is(                                    #
            random_noncentral_chi_square( 3, 5, 0.5 ),
            sfcheck( $_ ), $_
        ) for 3.0446921958125, 1.42890084938461, 14.6079129017975;
    };

    subtest 'random_noncentral_f' => sub {
        is(                                    #
            random_noncentral_f( 3, 5, 8, 0.5 ),
            sfcheck( $_ ), $_
        ) for 1.24610734550915, 1.50688092597374, 1.55869913648373;
    };

    is( random_integer(), 481_408_049, 'random_integer' );

};



done_testing;
