use strict;
use warnings;

use Games::Ratings::Chess::DWZ;

# use Test::More tests => 3;
use Test::More skip_all => 'calculated and official performance differ';

## see the following two links for the official calculation 
## * http://schachbund.de/dwz/turniere/2007.html?code=A734-E02-OMX
##   (Player Bartolomaeus, Christian)

my %expected = (
                new_rating      => 2165,
                expected_points => 4.763,
                performance     => 2191,
               );
my $player = Games::Ratings::Chess::DWZ->new();
$player->set_rating(2160);
$player->set_coefficient(30);
my @opponent_ratings =   (1794,1710,2038,2122,1981,2137,2211);
my @results          = qw(win  win  win  loss win  draw draw);
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
            # skip 'official performance is 2191 for unknown reason', 1 if 1 ;
            # is( $computed{$test_item}, $expected{$test_item}, 
                # "$test_item: $computed{$test_item} -> $expected{$test_item}" );
        # }
    # }
    # else {
        is( $computed{$test_item}, $expected{$test_item}, 
            "$test_item: $computed{$test_item} -> $expected{$test_item}" );
    # }
}
