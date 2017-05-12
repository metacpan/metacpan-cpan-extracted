#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 23;

use Games::Cards::ShuffleTrack;

my $deck = Games::Cards::ShuffleTrack->new();
my @original_deck = @{$deck->get_deck};

# dribble cards to a pile
my $pile = $deck->dribble;
is( ref( $pile ), 'Games::Cards::ShuffleTrack' );

# pile and deck in total have the original number of cards
cmp_ok( $pile->size, '>', 0  );
cmp_ok( $deck->size, '<', 52 );
is( $pile->size + $deck->size, 52 );

# alternate way of calling the method
$deck->restart;
$pile->restart;
$deck->dribble( $pile );
is( ref( $pile ), 'Games::Cards::ShuffleTrack' );
cmp_ok( $pile->size, '>', 1  );
cmp_ok( $deck->size,    '<', 52 );

# TODO: dribble to a pile that already has cards
# TODO: dribble without having the pile pre-specified
# TODO: what happens when you reset the pile dribbled into?

# dribble to position 10 (in a 52 card deck, 42 cards would fall)
$deck->restart;
$pile->restart;
$pile = $deck->dribble( 10 );
is( $pile->size, 42 );
is( $deck->size, 10 );

# dribble X cards
$deck->restart;
$pile->restart;
$pile = $deck->dribble( -10 );
is( $pile->size, 10 );
is( $deck->size, 42 );

# dribble between two positions
$deck->restart;
$pile->restart;
$pile = $deck->dribble( 10, 20 );
cmp_ok( $pile->size, '>=', 32 );
cmp_ok( $pile->size, '<=', 42 );
cmp_ok( $deck->size, '>=', 10 );
cmp_ok( $deck->size, '<=', 20 );

# dribble between two positions where one is negative
$deck->restart;
$pile->restart;
$pile = $deck->dribble( 10, -10 );
cmp_ok( $pile->size, '>=', 10 );
cmp_ok( $pile->size, '<=', 42 );
cmp_ok( $deck->size, '>=', 10 );
cmp_ok( $deck->size, '<=', 42 );

# dribble without cards
$pile->restart;
$deck->restart;
ok( $pile->dribble( $deck ) );
is( $pile->size, 0 );
is( $deck->size, 52 );

# final test to see if we can still restart the deck
$deck->restart;
is_deeply( $deck->get_deck, [@original_deck] );
