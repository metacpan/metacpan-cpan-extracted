use strict;
use warnings;

use Games::Ratings::Chess::FIDE;

use Test::More tests => 2;

## see the following link for the official calculation 
## * http://ratings.fide.com/individual_calculations.phtml?idnumber=4625200&rating_period=2008-07-01

my %expected = (
                rating_change   => '-18.9',
                points_expected => '4.26',
               );
my $player = Games::Ratings::Chess::FIDE->new();
$player->set_rating(2240);
$player->set_coefficient(15);
my @opponent_ratings =   (2242,2360,2289,2251,2303,2152,2313,2309,2110);
my @results          = qw(draw draw draw loss loss draw draw draw loss);
foreach my $game ( 0 .. $#results ) {
    $player->add_game( { opponent_rating => $opponent_ratings[$game],
                         result          => $results[$game], });  
}

my %computed;

## test 1: check rating change
$computed{rating_change} = $player->get_rating_change();

## test 1: check points expected
$computed{points_expected} = $player->get_points_expected();

## run actual tests for all test_items in %expected
foreach my $test_item ( sort keys %expected ) {
    is( $computed{$test_item}, $expected{$test_item}, 
        "$test_item: $computed{$test_item} -> $expected{$test_item}" );
}



