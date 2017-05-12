use strict;
use warnings;

use Games::Ratings::Chess::FIDE;

use Test::More tests => 14;

my %expected;
my %computed;

## test 1: create new object
my $player = Games::Ratings::Chess::FIDE->new();
$expected{t01_player_object_defined} = 1;
$computed{t01_player_object_defined} = defined $player;

## test 2: override old rating declaration
$player->set_rating(2235);
$expected{t02_own_rating} = 2235;
$computed{t02_own_rating} = $player->get_rating;

## test 3: override fide factor declaration
$player->set_coefficient(15);
$expected{t03_factor} = 15;
$computed{t03_factor} = $player->get_coefficient;

## tests 4 and 5: add a game against a weak opponent
$player->add_game( {
                     opponent_rating => 1700,
                     result          => 'win',
                   }
                 );
my @list_of_games = $player->get_all_games();
$expected{t04_game_1_opponent_rating} = 1700;
$computed{t04_game_1_opponent_rating} =  $list_of_games[0]->{opponent_rating};

$expected{t05_game_1_result} = 'win';
$computed{t05_game_1_result} = $list_of_games[0]->{result};

## test 6: check rating change for this game
$expected{t06_game_1_rating_change} = '+1.65';
$computed{t06_game_1_rating_change} 
          = sprintf("%+.2f", $player->get_rating_change);

## test 7: check new rating after this game
$expected{t07_game_1_new_rating} = '2237';
$computed{t07_game_1_new_rating} 
          = sprintf("%.f", $player->get_rating 
                           + $player->get_rating_change);

## tests 8 and 9: add a second game against a "normal" opponent
$player->add_game( {
                     opponent_rating => 2250,
                     result          => 'draw',
                   }
                 );
@list_of_games = $player->get_all_games();
$expected{t08_game_2_opponent_rating} = 2250;
$computed{t08_game_2_opponent_rating} = $list_of_games[1]->{opponent_rating};

$expected{t09_game_2_result} = 'draw';
$computed{t09_game_2_result} = $list_of_games[1]->{result};

## test 10: check for undefined game 3
$expected{t10_game_3_not_defined} = '';
$computed{t10_game_3_not_defined} = defined $list_of_games[2];

## test 11: check rating change for both games
$expected{t11_both_games_rating_change} = '+1.95';
$computed{t11_both_games_rating_change} 
          = sprintf("%+.2f", $player->get_rating_change);

## test 12: check new rating after both games
$expected{t12_both_games_new_rating} = '2237';
$computed{t12_both_games_new_rating} 
          = sprintf("%.f", $player->get_rating 
                           + $player->get_rating_change);

## test 13: check expected points
$expected{t13_expected_points_all_games} = '1.37';
$computed{t13_expected_points_all_games} = $player->get_points_expected();

## test 14: check performance
$expected{t14_performance} = '2168';
$computed{t14_performance} = $player->get_performance();

## run actual tests for all test_items in %expected
foreach my $test_item ( sort keys %expected ) {
    is( $computed{$test_item}, $expected{$test_item}, 
        "$test_item: $computed{$test_item} -> $expected{$test_item}" );
}
