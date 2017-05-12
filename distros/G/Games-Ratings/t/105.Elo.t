use strict;
use warnings;

use Games::Ratings::Chess::FIDE;

use Test::More tests => 3;

## see the following link for the official calculation (player Magnus Carlsen)
## * http://ratings.fide.com/individual_calculations.phtml?idnumber=1503014&rating_period=2010-03-01
## see the following link for performance
## * http://www.chess.co.uk/twic/twic795.html#2

my %expected = (
                rating_change   => '2.9',
                performance     => '2822',
                points_expected => '8.21',
               );
my $player = Games::Ratings::Chess::FIDE->new();
$player->set_rating(2810);
$player->set_coefficient(10);
my @opponent_ratings =   (2662,2657,2641,2696,2708,2790,2749,2723,2788,2720,2712,2739,2675);
my @results          = qw(draw win  win  draw draw draw win  draw loss win  win  draw draw);
foreach my $game ( 0 .. $#results ) {
    $player->add_game( { opponent_rating => $opponent_ratings[$game],
                         result          => $results[$game], });  
}

my %computed;

## test 1: check rating change
$computed{rating_change} = $player->get_rating_change();

## test 2: check performance
$computed{performance} = $player->get_performance();

## test 3: check performance
$computed{points_expected} = $player->get_points_expected();

## run actual tests for all test_items in %expected
foreach my $test_item ( sort keys %expected ) {
    is( $computed{$test_item}, $expected{$test_item}, 
        "$test_item: $computed{$test_item} -> $expected{$test_item}" );
}
