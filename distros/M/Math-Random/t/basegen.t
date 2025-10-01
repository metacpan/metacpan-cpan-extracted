#! perl

use Test2::V0;

use Math::Random qw(
  random_advance_state
  random_get_generator_num
  random_get_seed
  random_init_generator
  random_integer
  random_set_antithetic
  random_set_generator_num
  random_set_seed_from_phrase
  random_uniform
);

sub init_seed {
    random_set_seed_from_phrase( 'common seed' );
}

subtest 'generator number' => sub {

    init_seed;

    is( random_get_generator_num(), 1, 'default generator number' );

    my $gen = 32;
    is( random_set_generator_num( $gen ), 1,    'set new, returned old' );
    is( random_get_generator_num,         $gen, 'new was set' );
};

subtest 'advance state' => sub {

    init_seed;
    my $r;
    my $k = 1;
    $r = random_integer for 0 .. 2**$k;
    init_seed;
    random_advance_state( $k );
    is( random_integer(), $r );
};


subtest 'antithetic' => sub {

    init_seed;
    my $u1 = random_uniform();
    init_seed;
    random_set_antithetic( 1 );
    my $u1_anti = random_uniform();
    random_set_antithetic( 0 );    # Turn off

    is( $u1_anti, float( 1 - $u1 ) );

};


subtest 'random_init_generator' => sub {

    subtest 'reset to start' => sub {
        init_seed;
        my @s1 = random_get_seed;
        my $r1 = random_integer;    # first random

        random_integer for 0 .. 100;
        # reset to initial seed
        random_init_generator( -1 );
        my @s2 = random_get_seed;
        my $r2 = random_integer;    # first random

        is( \@s2, \@s1, 'same seed' );
        is( $r2,  $r1,  'same number' );
    };

    subtest 'set to current block' => sub {
        init_seed;
        my @s0 = random_get_seed;

        # move forward one block
        random_init_generator( 1 );
        my @s1 = random_get_seed;

        isnt( \@s1, \@s0, 'moved to next block' );

        # move forward some amount
        random_integer for 0 .. 100;
        my @s2 = random_get_seed;

        isnt( \@s2, \@s1, 'moved within block' );

        # reset to start of block
        random_init_generator( 0 );
        my @s3 = random_get_seed;

        is( \@s3, \@s1, 'seed for current block' );
    };

    subtest 'set to next block' => sub {
        init_seed;

        # move to next block
        random_init_generator( 1 );
        my @s1 = random_get_seed;

        # reset
        init_seed;
        # move to next block
        random_advance_state( 30 );
        my @s2 = random_get_seed;

        is( \@s2, \@s1, 'got correct seeds' );

    };

};

done_testing;
