use strict;
use warnings;

use Games::Ratings::Chess::DWZ;

use Test::More tests => 3;

## see the following two links for the official calculation 
## * http://schachbund.de/dwz/db/spieler.html?zps=E0312-059 (Nr. 31)
## * http://schachbund.de/dwz/turniere/show.html?view=scoresheet&code=9529-0F0-IDJ&zps[]=E0312-059&name[]=Bartolom%E4us,Christian

my %expected = (
                new_rating      => 2125,
                expected_points => 4.837,
                performance     => 2279,
               );
my $player = Games::Ratings::Chess::DWZ->new();
$player->set_rating(2085);
$player->set_coefficient(24);
my @opponent_ratings =   (1551,1828,2310,2211,2082,1547,2049,2210,2375);
my @results          = qw(win  win  draw loss draw win  win  draw win );
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
