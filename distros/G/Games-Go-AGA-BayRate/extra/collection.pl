#===============================================================================
#
#  DESCRIPTION:  Sample run on a few players (similar to t/Collection.t)
#
#       AUTHOR:  Reid Augustin
#        EMAIL:  reid@hellosix.com
#      CREATED:  Fri Mar 11 12:25:44 PST 2016
#===============================================================================

use strict;
use warnings;

use Carp;

our $VERSION = '0.104'; # VERSION

sub in_range {
    my ($val, $expect, $range) = @_;

    return ($val < $expect + $range and
            $val > $expect - $range);
}

use Games::Go::AGA::BayRate::Player;
use Games::Go::AGA::BayRate::Game;
use Games::Go::AGA::BayRate::Collection;

my $collection = Games::Go::AGA::BayRate::Collection->new(
    #iter_hook      => \&iter_hook,
);

my @players;
push @players, $collection->add_player(
    index   => 0,
    id      => 'player 0',
    seed    => -10,     # Initial rating
);
push @players, $collection->add_player(
    index   => 1,
    id      => 'player 1',
    seed    => -10,     # Initial rating
);
push @players, $collection->add_player(
    index   => 2,
    id      => 'player 2',
    seed    => -12,     # Initial rating
);
push @players, $collection->add_player(
    index   => 3,
    id      => 'player 3',
    seed    => -20,     # Initial rating
);

my @games;
push @games, $collection->add_game(
    komi        => 5.5,          # Komi
    handicap    => 0,            # Handicap
    whiteWins   => 0,           # True if White wins
    white       => $players[0], # 10K beats 11K, expected
    black       => $players[1],
);
push @games, $collection->add_game(
    komi        => -8,           # Komi
    handicap    => 8,           # Handicap
    whiteWins   => 1,           # True if White wins
    white       => $players[2], # 12K beats 20K, expected
    black       => $players[3],
);

$collection->calc_ratings;
show_players(@players);


sub show_players {
    my (@players) = @_;

    foreach my $player (@players) {
        printf("%s\t% 5.3g=>%g (sigma=% 5.3g)\n",
            $player->get_id,
            $player->get_seed,
            $player->get_rating,
            $player->get_sigma);
    }
}

