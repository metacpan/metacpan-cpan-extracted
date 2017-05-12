################################################################################
# ABSTRACT:  test for Games::Go::AGA::DataObjects::Tournament
#
#   AUTHOR:  Reid Augustin
#    EMAIL:  reid@HelloSix.com
#  CREATED:  04/27/2016 11:04:14 AM
################################################################################

use 5.008;
use strict;
use warnings;

use Games::Go::AGA::DataObjects::Player;
use Games::Go::AGA::DataObjects::Game;
use Games::Go::AGA::DataObjects::Round;

use Test::More
    tests => 10;
our $VERSION = '0.001'; # VERSION

use_ok('Games::Go::AGA::DataObjects::Tournament');   # the module under test

my $dut = new_ok('Games::Go::AGA::DataObjects::Tournament');   # the module under test

$dut->add_player(
    Games::Go::AGA::DataObjects::Player->new(
        id         => 'tmp01',
        last_name  => 'Last 1',
        first_name => 'First_1',
        rank       => '2k',
        flags      => ['no', 'flags'],
    ),
);
$dut->add_player(
    Games::Go::AGA::DataObjects::Player->new(
        id         => 'tmp02',
        last_name  => 'Last 2',
        first_name => 'First 2',
        rank       => '1k',
    ),
);
$dut->add_player(
    Games::Go::AGA::DataObjects::Player->new(
        id         => 'tmp03',
        last_name  => 'Last 3',
        first_name => 'First 3',
        rank       => '-1.6',
    ),
);
$dut->add_player(
    Games::Go::AGA::DataObjects::Player->new(
        id         => 'tmp04',
        last_name  => 'Last_4',
        first_name => 'First 4',
        rank       => '5d',
        flags      => ['flags'],
        comment    => 'comment',
    ),
);

my $round_num = $dut->rounds + 1;
$dut->add_round($round_num,
    Games::Go::AGA::DataObjects::Round->new(
        round_num => $round_num,
    ),
);
$dut->round(1)->add_game(
    Games::Go::AGA::DataObjects::Game->new(
        white  => $dut->get_player('Tmp002'),
        black  => $dut->get_player('TMP1'),
        handi  => 2,
        komi   => 7.7,
    ),
);
$dut->round(1)->add_game(
    Games::Go::AGA::DataObjects::Game->new(
        white  => $dut->get_player('Tmp004'),
        black  => $dut->get_player('TMP3'),
        handi  => 4,
        komi   => 0.7,
    ),
);
$dut->round(1)->game('tmp1')->winner('w');
$dut->round(1)->game('tmp3', 'TMP04')->winner('b');
is scalar @{$dut->player_wins('tMP1')}, 0, 'Tmp1 0 wins';
is scalar @{$dut->player_wins('tMP2')}, 1, 'Tmp2 1 win';
is scalar @{$dut->player_wins('tMP3')}, 1, 'Tmp3 1 win';
is scalar @{$dut->player_wins('tMP4')}, 0, 'Tmp4 0 wins';
$dut->round(1)->suppress_changes(0);
# oops, change a game result:
$dut->round(1)->game('tmp1')->winner('b');
is scalar @{$dut->player_wins('tMP1')}, 1, 'Tmp1 0 wins';
is scalar @{$dut->player_wins('tMP2')}, 0, 'Tmp2 1 win';
is scalar @{$dut->player_wins('tMP3')}, 1, 'Tmp3 1 win';
is scalar @{$dut->player_wins('tMP4')}, 0, 'Tmp4 0 wins';

