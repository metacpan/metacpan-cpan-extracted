use strict;
use warnings;

use Games::Ratings::Chess::FIDE;

use Test::More tests => 2;

## see the following link for the official calculation (player Viswanathan Anand)
## * http://ratings.fide.com/tournament_report.phtml?event16=42427
## see the following link for performance
## * http://www.chess.co.uk/twic/twic795.html#2

my %expected = (
                rating_change   => '-3.5',
                points_expected => '7.85',
               );
my $player = Games::Ratings::Chess::FIDE->new();
$player->set_rating(2790);
$player->set_coefficient(10);
my @opponent_ratings =   (2720,2696,2712,2708,2739,2810,2675,2749,2662,2723,2657,2788,2641);
my @results          = qw(draw draw draw draw draw draw draw draw draw win  draw win  draw);
foreach my $game ( 0 .. $#results ) {
    $player->add_game( { opponent_rating => $opponent_ratings[$game],
                         result          => $results[$game], });  
}

my %computed;

## test 1: check rating change
$computed{rating_change} = $player->get_rating_change();

## test 2: check points expected
$computed{points_expected} = $player->get_points_expected();

## run actual tests for all test_items in %expected
foreach my $test_item ( sort keys %expected ) {
    is( $computed{$test_item}, $expected{$test_item}, 
        "$test_item: $computed{$test_item} -> $expected{$test_item}" );
}



