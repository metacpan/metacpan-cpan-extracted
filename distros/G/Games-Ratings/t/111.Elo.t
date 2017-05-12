use strict;
use warnings;

use Games::Ratings::Chess::FIDE;

use Test::More tests => 3;

## see the following link for the official calculation (player Alexei Shirov)
## * http://ratings.fide.com/tournament_report.phtml?event16=44463
## see the following link for performance
## * http://www.chess.co.uk/twic/twic762.html#2

my %expected = (
                rating_change   => '-32',
                performance     => '2469',
                points_expected => '5.2',
               );
my $player = Games::Ratings::Chess::FIDE->new();
$player->set_rating(2745);
$player->set_coefficient(10);
my @opponent_ratings =   (2676,2700,2677,2730,2690,2702,2684,2682,2660);
my @results          = qw(loss loss loss loss draw draw loss draw draw);
foreach my $game ( 0 .. $#results ) {
    $player->add_game( { opponent_rating => $opponent_ratings[$game],
                         result          => $results[$game], });  
}

my %computed;

## test 1: check rating change
$computed{rating_change} = $player->get_rating_change();

## test 2: check performance
$computed{performance} = $player->get_performance();

## test 2: check points expected
$computed{points_expected} = $player->get_points_expected();

## run actual tests for all test_items in %expected
foreach my $test_item ( sort keys %expected ) {
    is( $computed{$test_item}, $expected{$test_item}, 
        "$test_item: $computed{$test_item} -> $expected{$test_item}" );
}
