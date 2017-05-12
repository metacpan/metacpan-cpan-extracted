#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 7;
BEGIN { use_ok('Games::Ratings::LogisticElo', 'multi_elo') };

my $player = Games::Ratings::LogisticElo->new;
$player->set_rating(2240);
$player->set_coefficient(15);
$player->add_game({
  opponent_rating => 2114,
  result => 'win',
});
my $rating_change = int ($player->get_rating_change + 0.5);
my $new_rating = int ($player->get_new_rating + 0.5);

is $rating_change, 5, 'rating change';
is $new_rating, 2245, 'new rating';


sub clean_ratings {
	map { int ($_ + 0.5) } @_
}

my @ratings = clean_ratings multi_elo [2240, 5];
is_deeply [@ratings], [2240], 'multi_elo - 1 arg';

@ratings = clean_ratings multi_elo [2240, 5], [2114, 2];
is_deeply [@ratings], [2245, 2109], 'multi_elo - 2 args';

@ratings = clean_ratings multi_elo 30, [2114, 2], [2240, 5];
is_deeply [@ratings], [2104, 2250], 'multi_elo - 2 args, custom K';


$player = Games::Ratings::LogisticElo->new;
$player->set_rating(2240);
$player->set_coefficient(15);
$player->add_game({
  opponent_rating => 2240,
  result => 'draw',
}) for 1 .. 100;
$rating_change = int ($player->get_rating_change + 0.5);
is $rating_change, 0, 'rating change (only draws against self)';
