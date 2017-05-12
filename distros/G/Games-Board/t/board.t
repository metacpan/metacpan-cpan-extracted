#!/usr/bin/perl

use Test::More 'no_plan';

use_ok( 'Games::Board' );

my $board = Games::Board->new;

isa_ok($board, 'Games::Board');

my $space = $board->add_space(
  id  => 'summer',
  dir => { next => 'autumn', prev => 'spring' }
);

isa_ok($space, 'Games::Board::Space');

isa_ok($board->space('summer'), 'Games::Board::Space');

$board->add_space(
  id  => 'autumn',
  dir => { next => 'winter', prev => 'summer' }
);

$board->add_space(
  id  => 'winter',
  dir => { next => 'spring', prev => 'autumn' }
);

$board->add_space(
  id  => 'spring',
  dir => { next => 'summer', prev => 'winter' }
);

isa_ok($board->space('autumn'), 'Games::Board::Space');
isa_ok($board->space('winter'), 'Games::Board::Space');
isa_ok($board->space('spring'), 'Games::Board::Space');

is( $board->space('summer')->dir_id('next'), 'autumn', "autumn follows summer" );
is( $board->space('summer')->dir_id('prev'), 'spring', "spring precedes summer" );
is( $board->space('autumn')->dir_id('next'), 'winter', "winter follows autumn" );
is( $board->space('autumn')->dir_id('prev'), 'summer', "summer precedes autumn" );
is( $board->space('winter')->dir_id('next'), 'spring', "spring follows winter" );
is( $board->space('winter')->dir_id('prev'), 'autumn', "autumn precedes winter" );
is( $board->space('spring')->dir_id('next'), 'summer', "summer follows spring" );
is( $board->space('spring')->dir_id('prev'), 'winter', "winter precedes spring" );
