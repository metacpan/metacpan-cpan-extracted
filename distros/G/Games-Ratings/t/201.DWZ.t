use strict;
use warnings;

use Games::Ratings::Chess::DWZ;

use Test::More tests => 3;

## see the following two links for the official calculation 
## * http://schachbund.de/dwz/turniere/2007.html?code=9706-E00-NBA (Player
##   Bartolomaeus, Christian)
## * #http://schachbund.de/dwz/turniere/show.html?view=scoresheet&code=9706-E00-NBA&zps[]=E0312-059&name[]=Bartolom%E4us,Christian

my %expected = (
                new_rating      => 2195,
                expected_points => 2.987,
                performance     => 2197,
               );
my $player = Games::Ratings::Chess::DWZ->new();
$player->set_rating(2195);
$player->set_coefficient(30);
my @opponent_ratings =   (2024,2099,2076,2228,2188);
my @results          = qw(win  draw draw win  loss);
foreach my $game ( 0 .. $#results ) {
    $player->add_game( { opponent_rating => $opponent_ratings[$game],
                         result          => $results[$game], });
}

my %computed;

## test 1: check new rating after this games
$computed{new_rating} = $player->get_new_rating();

## test 2: check expected points
$computed{expected_points} = $player->get_points_expected();

## test 3: check performance
$computed{performance} = $player->get_performance();

## run actual tests for all test_items in %expected
foreach my $test_item ( sort keys %expected ) {
    is( $computed{$test_item}, $expected{$test_item},
        "$test_item: $computed{$test_item} -> $expected{$test_item}" );
}
