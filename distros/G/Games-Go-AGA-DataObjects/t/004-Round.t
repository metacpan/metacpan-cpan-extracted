# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 004-Round.t'

#########################

use strict;
use warnings;

use Test::More tests => 23;
use Scalar::Util qw(refaddr);
use_ok('Games::Go::AGA::DataObjects::Player');
use_ok('Games::Go::AGA::DataObjects::Game');
use_ok('Games::Go::AGA::DataObjects::Round');

my $round = new_ok('Games::Go::AGA::DataObjects::Round',
    [ round_num => 1, ],
);

my $player0 = Games::Go::AGA::DataObjects::Player->new(
    id         => 'tmp00',
    last_name  => 'Last_0',
    first_name => 'First 0',
    rank       => '5d',
    flags      => ['flags'],
    comment    => 'comment',
);
my $player1 = Games::Go::AGA::DataObjects::Player->new(
    id         => 'tmp01',
    last_name  => 'Last 1',
    first_name => 'First_1',
    rank       => '2k',
    flags      => ['no', 'flags'],
);
my $player2 = Games::Go::AGA::DataObjects::Player->new(
    id         => 'tmp02',
    last_name  => 'Last 2',
    first_name => 'First 2',
    rank       => '1k',
);

my $game0 = Games::Go::AGA::DataObjects::Game->new(
    white  => $player0,         # a Games::Go::AGA::DataObjects::Player object
    black  => $player1,         # this too
    handi  => 6,                # positive integer
    komi   => 0,                # number
);
my $game1 = Games::Go::AGA::DataObjects::Game->new(
    white  => $player1,
    black  => $player0,
    handi  => 0,
    komi   => 5.5,
);
# add the games to the round
$round->add_game($game0);
$round->add_game($game1);

is ($round->games->[0]->white->id, 'TMP0',   'game 0 white player');
is ($round->games->[0]->black->id, 'TMP1',   'game 0 black player');
is ($round->games->[1]->white->id, 'TMP1',   'game 1 white player');
is ($round->games->[1]->black->id, 'TMP0',   'game 1 black player');

$game1->black($player2);        # change players

is ($round->games->[0]->white->id, 'TMP0',   'game 0 white player');
is ($round->games->[0]->black->id, 'TMP1',   'game 0 black player');
is ($round->games->[1]->white->id, 'TMP1',   'game 1 white player');
is ($round->games->[1]->black->id, 'TMP2',   'game 1 black player');
is ($round->games->[0]->handi,     6,        'game 0 handicap');
is ($round->games->[1]->komi,      5.5,      'game 1 komi');
is ($round->games->[0]->winner,    undef,    'game 0 winner not known');
is ($round->games->[1]->winner,    undef,    'game 1 winner not known');

# set some winners
$round->games->[0]->winner($player0);
$round->games->[1]->winner($player2);

is (refaddr($game0->winner),                refaddr($player0), 'game 0 winner is player 0');
is (refaddr($game1->winner),                refaddr($player2), 'game 1 winner is player 2');

my $game2 = Games::Go::AGA::DataObjects::Game->new(
    white  => $player2,
    black  => $player1,
    handi  => 2,
    komi   => 7.7,
);
$round->add_game($game2);

is ($round->games->[2]->white->id,  'TMP2',  'game 2 white player');
is ($round->games->[2]->black->id,  'TMP1',  'game 2 black player');
is ($round->games->[2]->handi,      2,       'game 2 handicap');
is ($round->games->[2]->komi,       7.7,     'game 2 komi');
is ($round->games->[2]->winner,     undef,   'game 2 winner not known');
