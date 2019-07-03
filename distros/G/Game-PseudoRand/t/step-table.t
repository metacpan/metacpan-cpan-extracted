#!perl
use strict;
use warnings;
use Game::PseudoRand qw(prd_step prd_table);
use Test::Most;

# missing required arguments (TODO improve)
dies_ok { Game::PseudoRand::prd_step };
for my $arg (qw(start step)) {
    dies_ok { Game::PseudoRand::prd_step( $arg => 42 ) };
}
dies_ok { Game::PseudoRand::prd_table };
for my $arg (qw(start table)) {
    dies_ok { Game::PseudoRand::prd_step( $arg => 42 ) };
}

# invalid arguments
dies_ok { prd_step( start => 0.5, step => 0.1, rand => "not CODE" ) };
dies_ok { prd_table( start => 0.5, table => [0.1], rand => "not CODE" ) };
dies_ok { prd_table( start => 0.5, table => "not ARRAY" ) };
dies_ok { prd_table( start => 0.5, table => [] ) };
dies_ok { prd_table( start => 0.5, table => [ 0.1, 0.2 ], index => -1 ) };
dies_ok { prd_table( start => 0.5, table => [ 0.1, 0.2 ], index => 2 ) };

my ( $randfn, $rstfn );

# not useful expect mostly for testing purposes (some may want errors if
# start or step or invalid, but there can be legit cases where the start
# is negative and eventually goes positive)
( $randfn, undef ) = prd_step( start => -1, step => 0 );
is( &$randfn, 0 );

( $randfn, undef ) = prd_step( start => -1, step => 3, reset => -1 );
is( &$randfn, 0 );
is( &$randfn, 1 );
is( &$randfn, 0 );

( $randfn, undef ) = prd_step( start => 2, step => 0 );
is( &$randfn, 1 );

# NOTE step is unused on hit, only increments on miss
( $randfn, undef ) = prd_step( start => 2, step => 3, reset => -1 );
is( &$randfn, 1 );
is( &$randfn, 0 );
is( &$randfn, 1 );

( $randfn, undef ) = prd_table( start => -1, table => [0] );
is( &$randfn, 0 );

( $randfn, undef ) = prd_table( start => -1, table => [ 0, 3 ], reset => -1 );
is( &$randfn, 0 );
is( &$randfn, 0 );
is( &$randfn, 1 );
is( &$randfn, 0 );
is( &$randfn, 0 );
is( &$randfn, 1 );

( $randfn, undef ) = prd_table( start => 2, table => [0] );
is( &$randfn, 1 );

( $randfn, undef ) = prd_table( start => 2, table => [ 0, 3 ], reset => -1 );
is( &$randfn, 1 );
is( &$randfn, 0 );
is( &$randfn, 0 );
is( &$randfn, 1 );

( $randfn, undef ) =
  prd_table( start => -1, table => [ 0, 0, 3, 3 ], index => 2 );
is( &$randfn, 0 );
is( &$randfn, 1 );
is( &$randfn, 0 );

# breaking things with custom random functions
( $randfn, undef ) = prd_step( start => -1, step => 3, rand => sub { 9 } );
is( &$randfn, 0 );
is( &$randfn, 0 );

( $randfn, undef ) = prd_table( start => 9, table => [9], rand => sub { -1 } );
is( &$randfn, 1 );
is( &$randfn, 1 );

( $randfn, $rstfn ) = prd_step( start => -1, step => 9 );
is( &$randfn, 0 );
&$rstfn;
is( &$randfn, 0 );

( $randfn, $rstfn ) = prd_table( start => -1, table => [ 7, 8, 9 ] );
is( &$randfn, 0 );
&$rstfn;
is( &$randfn, 0 );
&$rstfn;
is( &$randfn, 0 );

done_testing 44
