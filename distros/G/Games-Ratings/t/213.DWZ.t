use strict;
use warnings;

use Games::Ratings::Chess::DWZ;

use Test::More tests => 3;

## see the following two links for the official calculation 
## * http://schachbund.de/dwz/turniere/2007.html?code=A625-E03-VMA
##   (Player Bartolomaeus, Christian)

my %expected = (
                new_rating      => 2145,
                expected_points => 5.276,
                performance     => 2125,
               );
my $player = Games::Ratings::Chess::DWZ->new();
$player->set_rating(2151);
$player->set_coefficient(30);
my @opponent_ratings =   (1934,2052,2051,2091,1934,2052,2051,2091);
my @results          = qw(win  loss draw draw draw win  win  draw);
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
    # if ( $test_item eq 'performance' ) {
    # SKIP: {
    # skip 'official performance is 2125 for unknown reason', 1 if 1 ;
    # is( $computed{$test_item}, $expected{$test_item}, 
    # "$test_item: $computed{$test_item} -> $expected{$test_item}" );
    # }
    # }
    # else {
        is( $computed{$test_item}, $expected{$test_item}, 
            "$test_item: $computed{$test_item} -> $expected{$test_item}" );
        # }
}
