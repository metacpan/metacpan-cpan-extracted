use strict;
use warnings;

use Games::Ratings::Chess::DWZ;

use Test::More tests => 12;

my %expected;
my %computed;

## test 1: create new object
my $player = Games::Ratings::Chess::DWZ->new();
$expected{t01_player_object_defined} = 1;
$computed{t01_player_object_defined} = defined $player;

## test 2: override old rating declaration
$player->set_rating(2212);
$expected{t02_own_rating} = 2212;
$computed{t02_own_rating} = $player->get_rating;

## test 3: override declaration of development coefficient
$player->set_coefficient(30);
$expected{t03_factor} = 30;
$computed{t03_factor} = $player->get_coefficient;

## tests 4 and 5: add first games
$player->add_game( {
                     opponent_rating => 2329,
                     result          => 'win',
                   }
                 );
my @list_of_games = $player->get_all_games();
$expected{t04_game_1_opponent_rating} = 2329;
$computed{t04_game_1_opponent_rating} =  $list_of_games[0]->{opponent_rating};

$expected{t05_game_1_result} = 'win';
$computed{t05_game_1_result} = $list_of_games[0]->{result};

## add eight other games
$player->add_game( {
                     opponent_rating => 2328,
                     result          => 'loss',
                   }
                 );
$player->add_game( {
                     opponent_rating => 2293,
                     result          => 'draw',
                   }
                 );
$player->add_game( {
                     opponent_rating => 2300,
                     result          => 'loss',
                   }
                 );
$player->add_game( {
                     opponent_rating => 2302,
                     result          => 'win',
                   }
                 );
$player->add_game( {
                     opponent_rating => 2190,
                     result          => 'draw',
                   }
                 );
$player->add_game( {
                     opponent_rating => 2348,
                     result          => 'win',
                   }
                 );
$player->add_game( {
                     opponent_rating => 2350,
                     result          => 'win',
                   }
                 );
$player->add_game( {
                     opponent_rating => 2181,
                     result          => 'draw',
                   }
                 );

## test 6: check rating change for this games
$expected{t06_rating_change_all_games} = '+40.53';
$computed{t06_rating_change_all_games} 
          = sprintf("%+.2f", $player->get_rating_change);

## test 7: check new rating after this games
$expected{t07_new_rating_all_games} = '2253';
$computed{t07_new_rating_all_games} = $player->get_new_rating();

## test 8: check expected points
$expected{t08_expected_points_all_games} = '3.524';
$computed{t08_expected_points_all_games} = $player->get_points_expected();

## test 9: check scored points
$expected{t09_scored_points_all_games} = '5.5';
$computed{t09_scored_points_all_games} = $player->get_points_scored();

## test 10: check number of games
$expected{t10_number_of_games_played} = '9';
$computed{t10_number_of_games_played} = $player->get_number_of_games_played();

## test 11: check average rating of opponents
$expected{t11_average_rating_of_opponents} = '2291';
$computed{t11_average_rating_of_opponents} 
          = $player->get_average_rating_of_opponents();

## test 12: check performance
$expected{t12_performance} = '2373';
$computed{t12_performance} = $player->get_performance();

## run actual tests for all test_items in %expected
foreach my $test_item ( sort keys %expected ) {
    is( $computed{$test_item}, $expected{$test_item}, 
        "$test_item: $computed{$test_item} -> $expected{$test_item}" );
}
