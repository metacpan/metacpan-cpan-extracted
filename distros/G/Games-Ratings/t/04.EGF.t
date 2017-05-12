use strict;
use warnings;

use Games::Ratings::Go::EGF;

use Test::More tests => 11;

my %expected;
my %computed;

## test 1: create new object
my $player = Games::Ratings::Go::EGF->new();
$expected{t01_player_object_defined} = 1;
$computed{t01_player_object_defined} = defined $player;

## test 2: override old rating declaration
$player->set_rating(320);
$expected{t02_own_rating} = 320;
$computed{t02_own_rating} = $player->get_rating;

## tests 3 and 4: add a game against a stronger opponent (example 1)
$player->add_game( {
                     opponent_rating => 400,
                     result          => 'win',
                   }
                 );
my @list_of_games = $player->get_all_games();
$expected{t03_game_1_opponent_rating} = 400;
$computed{t03_game_1_opponent_rating} =  $list_of_games[0]->{opponent_rating};

$expected{t04_game_1_result} = 'win';
$computed{t04_game_1_result} = $list_of_games[0]->{result};

## test 5: check rating change for this game
$expected{t05_game_1_rating_change} = '+62.84';
$computed{t05_game_1_rating_change} 
          = sprintf("%+.2f", $player->get_rating_change);

## test 6: check new rating after this game
$expected{t06_game_1_new_rating} = '383';
$computed{t06_game_1_new_rating} = $player->get_new_rating();

## test 7: same game, calculation for opponent
$player->remove_all_games();
$player->set_rating(400);
$player->add_game( {
                     opponent_rating => 320,
                     result          => 'loss',
                   }
                 );
$expected{t07_new_rating} = '341';
$computed{t07_new_rating} = $player->get_new_rating();

## test 8: new game (example 2)
$player->remove_all_games();
$player->set_rating(2400);
$player->add_game( {
                     opponent_rating => 2400,
                     result          => 'win',
                   }
                 );
$expected{t08_new_rating} = '2408';
$computed{t08_new_rating} = $player->get_new_rating();

## test 9: same game -- calculation for opponent (example 2)
$player->remove_all_games();
$player->set_rating(2400);
$player->add_game( {
                     opponent_rating => 2400,
                     result          => 'loss',
                   }
                 );
$expected{t09_new_rating} = '2392';
$computed{t09_new_rating} = $player->get_new_rating();

## test 10: new game (example 3)
$player->remove_all_games();
$player->set_rating(1850);
$player->add_game( {
                     opponent_rating => 2400,
                     result          => 'win',
                     handicap        => '+5',
                   }
                 );
$expected{t10_new_rating} = '1875';
$computed{t10_new_rating} = $player->get_new_rating();

## test 11: same game -- calculation for opponent (example 2)
$player->remove_all_games();
$player->set_rating(2400);
$player->add_game( {
                     opponent_rating => 1850,
                     result          => 'loss',
                     handicap        => '-5',
                   }
                 );
$expected{t11_new_rating} = '2389';
$computed{t11_new_rating} = $player->get_new_rating();


## run actual tests for all test_items in %expected
foreach my $test_item ( sort keys %expected ) {
    is( $computed{$test_item}, $expected{$test_item}, 
        "$test_item: $computed{$test_item} -> $expected{$test_item}" );
}
