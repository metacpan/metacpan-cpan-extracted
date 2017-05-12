#===============================================================================
#
#  DESCRIPTION:  Tests for Games::Go::AGA::BayRate::Collection
#
#       AUTHOR:  Reid Augustin
#        EMAIL:  reid@hellosix.com
#      CREATED:  05/24/2011 12:53:53 PM
#===============================================================================

use strict;
use warnings;

use Test::More;
plan ( tests => 7 );

use Carp;

our $VERSION = '0.104'; # VERSION

use_ok('Games::Go::AGA::BayRate::Player');
use_ok('Games::Go::AGA::BayRate::Game');
use_ok('Games::Go::AGA::BayRate::Collection');

my $collection = Games::Go::AGA::BayRate::Collection->new(
    #iter_hook      => \&iter_hook,
);

my @players = (
    $collection->add_player(
        index   => 0,
        id      => 'player 0',
        seed    => -10,     # Initial rating
    ),
    $collection->add_player(
        index   => 1,
        id      => 'player 1',
        seed    => -10,
    ),
    $collection->add_player(
        index   => 2,
        id      => 'player 2',
        seed    => -12,
    ),
    $collection->add_player(
        index   => 3,
        id      => 'player 3',
        seed    => -20,
    ),
);

my @games = (
    $collection->add_game(
        komi        => 5.5,         # Komi
        handicap    => 0,           # Handicap
        whiteWins   => 0,           # True if White wins
        white       => $players[0], # even game, could go either way
        black       => $players[1],
    ),
    $collection->add_game(
        komi        => -8,          # Komi
        handicap    => 8,           # Handicap
        whiteWins   => 1,           # True if White wins
        white       => $players[2], # 12K beats 20K, expected
        black       => $players[3],
    ),
);

$collection->calc_ratings;  # get ratings adjustments

my @expect = (
-10.6434,   # player 0 loses, gets weaker
-9.35646,   # player 1 wins, gets stronger
-11.067,    # player 2 wins, gets stronger
-20.933,    # player 3 loses, gets weaker
);

my $ii = 0;
foreach my $player (@players) {
    ok in_range($player->get_rating, $expect[$ii++], 0.001), "player $ii correct";
}

sub in_range {      # floats just need to be close
    my ($val, $expect, $range) = @_;

    return ($val < $expect + $range and
            $val > $expect - $range);
}

