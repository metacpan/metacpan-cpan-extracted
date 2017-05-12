use strict;
use warnings;

use Games::Ratings::Chess::DWZ;

use Test::More tests => 3;

my %expected;
my %computed;

## see the following two links for the official calculation 
## * http://schachbund.de/dwz/turniere/2007.html?code=A514-000-ONO&mcount[]=1-10
##   (Player Bartolomaeus, Christian)

my $player = Games::Ratings::Chess::DWZ->new();
$player->set_rating(2217);
$player->set_coefficient(30);
$player->add_game( {
                     opponent_rating => 2378,
                     result          => 'draw',
                   }
                 );
$player->add_game( {
                     opponent_rating => 2263,
                     result          => 'loss',
                   }
                 );
$player->add_game( {
                     opponent_rating => 2409,
                     result          => 'draw',
                   }
                 );
$player->add_game( {
                     opponent_rating => 2189,
                     result          => 'loss',
                   }
                 );
$player->add_game( {
                     opponent_rating => 2333,
                     result          => 'draw',
                   }
                 );
$player->add_game( {
                     opponent_rating => 2302,
                     result          => 'loss',
                   }
                 );
$player->add_game( {
                     opponent_rating => 2251,
                     result          => 'loss',
                   }
                 );
$player->add_game( {
                     opponent_rating => 2306,
                     result          => 'loss',
                   }
                 );
$player->add_game( {
                     opponent_rating => 2476,
                     result          => 'loss',
                   }
                 );

## test 1: check new rating after this games
$expected{t07_new_rating_all_games} = '2181';
$computed{t07_new_rating_all_games} = $player->get_new_rating();

## test 2: check expected points
$expected{t08_expected_points_all_games} = '3.240';
$computed{t08_expected_points_all_games} = $player->get_points_expected();

## test 3: check performance
$expected{t12_performance} = '2038';
$computed{t12_performance} = $player->get_performance();

## run actual tests for all test_items in %expected
foreach my $test_item ( sort keys %expected ) {
    is( $computed{$test_item}, $expected{$test_item}, 
        "$test_item: $computed{$test_item} -> $expected{$test_item}" );
}

