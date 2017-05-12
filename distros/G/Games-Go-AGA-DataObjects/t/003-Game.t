# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 003-Game.t'

#########################

use strict;
use warnings;

use Test::More tests => 12;
#use Test::Exception;
use Try::Tiny;
use_ok('Games::Go::AGA::DataObjects::Player');
use_ok('Games::Go::AGA::DataObjects::Game');

my $player1 = Games::Go::AGA::DataObjects::Player->new(
                id         => 'tmp0201',
                last_name  => 'last_name',
                first_name => 'first_name',
                rank       => '5d',
                flags      => ['flags'],
                comment    => 'comment',
                );
my $player2 = Games::Go::AGA::DataObjects::Player->new(
                id         => 'tmp0202',
                last_name  => 'second player',
                first_name => 'I am the',
                rank       => '2k',
                flags      => ['no', 'flags'],
                );
my $player3 = Games::Go::AGA::DataObjects::Player->new(
                id         => 'tmp0303',
                last_name  => 'third  player',
                first_name => 'I will be the',
                rank       => '15k',
                );
my $game = Games::Go::AGA::DataObjects::Game->new(
            black  => $player2,         # a Games::Go::AGA::DataObjects::Player object
            white  => $player1,         # this too
            handi  => 6,                # positive integer
            komi   => 0,                # number
            );
isa_ok ($game, 'Games::Go::AGA::DataObjects::Game', 'create object');

is ($game->white->last_name,  'last_name',       'white player last name');
is ($game->black->first_name, 'I am the',        'black player first name');
is ($game->handi,             6,                 'handicap is correct');
is ($game->komi,              0,                 'komi is correct');
is ($game->winner,            undef,             'winner currently unknown');
$game->komi(3.333);
$game->winner($player2);
is ($game->komi,       3.333,                    'komi set to 3.333');
is ($game->winner->id,   $player2->id,           'winner is player 2');
try {
    $game->winner($player3);    # should croak
    is (0, 1, 'failed to die with invalid winner');
} catch {
    is (1, 1, 'died properly with invalid winner');
};
# is ($game->winner->id,   $player2->id,           'winner is still player 2');
$game->winner($player1);
is ($game->winner->id,   $player1->id,           'winner is now player 1');

