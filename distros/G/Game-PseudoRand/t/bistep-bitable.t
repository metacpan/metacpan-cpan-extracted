#!perl
use strict;
use warnings;
use Game::PseudoRand qw(prd_bistep prd_bitable);
use Test::Most;

# missing required arguments (TODO improve)
dies_ok { Game::PseudoRand::prd_bistep };
for my $arg (qw(start step_hit step_miss)) {
    dies_ok { Game::PseudoRand::prd_bistep( $arg => 42 ) };
}
dies_ok { Game::PseudoRand::prd_bitable };
for my $arg (qw(start table_hit table_miss)) {
    dies_ok { Game::PseudoRand::prd_bitable( $arg => 42 ) };
}

# invalid arguments
dies_ok {
    prd_bistep(
        start     => 0.5,
        step_hit  => -0.1,
        step_miss => 0.1,
        rand      => "not CODE"
    )
};
dies_ok {
    prd_bitable(
        start      => 0.5,
        table_hit  => [-0.1],
        table_miss => [0.1],
        rand       => "not CODE"
    )
};

my $ok_table = [ 0.1, 0.2 ];
for my $ref ( [qw(table_hit table_miss)], [qw(table_miss table_hit)] ) {
    dies_ok {
        prd_bitable( start => 0.5, $ref->[0] => $ok_table, $ref->[1] => "not ARRAY" )
    };
    dies_ok { prd_bitable( start => 0.5, $ref->[0] => $ok_table, $ref->[1] => [] ) };
}
for my $iname (qw(index_hit index_miss)) {
    dies_ok {
        prd_bitable(
            start      => 0.5,
            table_hit  => $ok_table,
            table_miss => $ok_table,
            $iname     => -1
        )
    };
    dies_ok {
        prd_bitable(
            start      => 0.5,
            table_hit  => $ok_table,
            table_miss => $ok_table,
            $iname     => 2
        )
    };
}

my ( $randfn, $rstfn );

# could also double as a needlessly complicated and expensive logic gate
( $randfn, undef ) = prd_bistep( start => -1, step_hit => -3, step_miss => 3 );
is( &$randfn, 0 );
is( &$randfn, 1 );
is( &$randfn, 0 );

( $randfn, undef ) =
  prd_bistep( start => -1, step_hit => -1, step_miss => -1, rand => sub { 9 } );
is( &$randfn, 0 );
is( &$randfn, 0 );

( $randfn, undef ) =
  prd_bitable( start => -9, table_hit => [ 0, -3 ], table_miss => [ 3, 5 ] );
is( &$randfn, 0 );    # -9, +3
is( &$randfn, 0 );    # -6, +5
is( &$randfn, 0 );    # -1, +3
is( &$randfn, 1 );    #  2, +0
is( &$randfn, 1 );    #  2, -3
is( &$randfn, 0 );    #  -1, +3
is( &$randfn, 1 );    #  1, +0
is( &$randfn, 1 );    #  1, -3
is( &$randfn, 0 );    #  -2, +3

( $randfn, undef ) =
  prd_bitable( start => 9, table_hit => [ -3, -5 ], table_miss => [0] );
is( &$randfn, 1 );    #  9, -3
is( &$randfn, 1 );    #  6, -5
is( &$randfn, 1 );    #  1, -3
is( &$randfn, 0 );    #  -2, +0

( $randfn, undef ) = prd_bitable(
    start      => -1,
    table_hit  => [0],
    table_miss => [3],
    rand       => sub { 9 }
);
is( &$randfn, 0 );
is( &$randfn, 0 );

done_testing 38
