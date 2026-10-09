use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";

use Game::Brandubh::Engine ':all';
use Game::Brandubh::Test::Squares qw(sq wire);
my $E = 'Game::Brandubh::Engine';

# EVERY CASE IS A POSITION AND THE WHOLE LIST IT SHOULD GIVE, written out. A
# test that asked only "is d4 absent" would pass a generator that had lost
# half the board.
#
# The rules, from the source the documentation names:
#
#   4. "Pieces move any distance orthogonally, not landing on nor jumping over
#      other pieces on the board."
#   5. "No piece may land on the central square, not even the king once he has
#      left it. Only the king may land on the corner squares."
#
# and this distribution's own reading where they are silent: a piece may slide
# across the empty throne.

sub list_is {
    my ($position, $variant, $want, $why) = @_;
    my ($bd, $err) = $E->of_string($position);
    die "refused $position: $err" unless $bd;
    my $got = join ' ', sort map { wire($_) } $bd->moves($variant);
    is($got, $want, $why);
}

subtest 'the throne: across it, never onto it' => sub {
    list_is('7/7/7/2d4/7/7/7 d', undef,
        'c4a4 c4b4 c4c1 c4c2 c4c3 c4c5 c4c6 c4c7 c4e4 c4f4 c4g4',
        'a defender beside the throne slides across it and may stop beyond, not on it');
    list_is('7/7/7/2d4/7/7/7 d', { throne_pass => 0 },
        'c4a4 c4b4 c4c1 c4c2 c4c3 c4c5 c4c6 c4c7',
        'and stops short when the rule set closes the throne to passing');

    list_is('7/7/7/7/7/3a3/7 a', undef,
        'd2a2 d2b2 d2c2 d2d1 d2d3 d2d5 d2d6 d2d7 d2e2 d2f2 d2g2',
        'the same up a file: d3, then d5, and never d4');
    list_is('7/7/7/7/7/3a3/7 a', { throne_pass => 0 },
        'd2a2 d2b2 d2c2 d2d1 d2d3 d2e2 d2f2 d2g2',
        'and d3 only when it is closed');

    list_is('7/7/7/2a1d2/7/7/7 a', undef,
        'c4a4 c4b4 c4c1 c4c2 c4c3 c4c5 c4c6 c4c7',
        'a piece beyond the throne leaves nowhere to stop: the only square before it is the throne');
};

subtest 'the king and the throne' => sub {
    list_is('7/7/7/3k3/7/7/7 d', undef,
        'd4a4 d4b4 d4c4 d4d1 d4d2 d4d3 d4d5 d4d6 d4d7 d4e4 d4f4 d4g4',
        'the king on the throne moves off it like any piece');
    list_is('7/7/7/2k4/7/7/7 d', undef,
        'c4a4 c4b4 c4c1 c4c2 c4c3 c4c5 c4c6 c4c7 c4e4 c4f4 c4g4',
        'once he has left it he has no move back: "not even the king"');
    list_is('7/7/7/2k4/7/7/7 d', { throne_reentry => 1 },
        'c4a4 c4b4 c4c1 c4c2 c4c3 c4c5 c4c6 c4c7 c4d4 c4e4 c4f4 c4g4',
        'unless the rule set lets him, and then d4 is one more move');
    list_is('7/7/7/2k4/7/7/7 d', { throne_reentry => 1, throne_pass => 0 },
        'c4a4 c4b4 c4c1 c4c2 c4c3 c4c5 c4c6 c4c7 c4d4',
        'he may stop on a throne he may not cross');
    list_is('7/7/7/2d4/7/7/7 d', { throne_reentry => 1 },
        'c4a4 c4b4 c4c1 c4c2 c4c3 c4c5 c4c6 c4c7 c4e4 c4f4 c4g4',
        'and that rule is the king\'s alone: a defender still may not');
};

subtest 'an occupied throne is a piece in the way' => sub {
    list_is('7/7/7/a2k3/7/7/7 a', undef,
        'a4a2 a4a3 a4a5 a4a6 a4b4 a4c4',
        'an attacker stops before the king on the throne, and does not pass');
    list_is('7/7/7/a2d3/7/7/7 a', undef,
        'a4a2 a4a3 a4a5 a4a6 a4b4 a4c4',
        'the same before a defender standing where no game puts one');
};

subtest 'the corners are the king\'s' => sub {
    list_is('7/7/7/7/7/7/3a3 a', undef,
        'd1b1 d1c1 d1d2 d1d3 d1d5 d1d6 d1d7 d1e1 d1f1',
        'an attacker on rank 1 slides to b1 and f1 and no further');
    list_is('7/7/7/7/7/7/3d3 d', undef,
        'd1b1 d1c1 d1d2 d1d3 d1d5 d1d6 d1d7 d1e1 d1f1',
        'so does a defender');
    list_is('7/7/7/7/7/7/3k3 d', undef,
        'd1a1 d1b1 d1c1 d1d2 d1d3 d1d5 d1d6 d1d7 d1e1 d1f1 d1g1',
        'and the king on the same square has a1 and g1 as well');
    list_is('7/7/7/k6/7/7/7 d', undef,
        'a4a1 a4a2 a4a3 a4a5 a4a6 a4a7 a4b4 a4c4 a4e4 a4f4 a4g4',
        'the king on the a file reaches a1 and a7');
    list_is('7/7/7/6k/7/7/7 d', undef,
        'g4a4 g4b4 g4c4 g4e4 g4f4 g4g1 g4g2 g4g3 g4g5 g4g6 g4g7',
        'and on the g file g1 and g7: all four corners, each by name');
    list_is('7/7/7/7/7/7/1ak4 d', undef,
        'c1c2 c1c3 c1c4 c1c5 c1c6 c1c7 c1d1 c1e1 c1f1 c1g1',
        'a king with an attacker between him and a1 has g1 and not a1');
};

subtest 'boxed in' => sub {
    list_is('7/a6/7/2d4/1dad3/2d4/7 a', undef,
        'a6a2 a6a3 a6a4 a6a5 a6b6 a6c6 a6d6 a6e6 a6f6 a6g6',
        'a piece closed on four sides has no move, and the side\'s list is the other piece\'s');
    list_is('7/7/7/7/d6/ad5/7 a', undef, '',
        'a piece closed by two enemies, the edge and a corner it may not use: no move at all');
    list_is('7/7/7/7/d6/kd5/7 d', undef,
        'a2a1 a3a4 a3a5 a3a6 a3b3 a3c3 a3d3 a3e3 a3f3 a3g3 b2b1 b2b3 b2b4 b2b5 b2b6 b2b7 b2c2 b2d2 b2e2 b2f2 b2g2',
        'the king in the same place has the corner');

    my ($bd) = $E->of_string('7/7/7/7/d6/ad5/7 a');
    is(scalar($bd->moves), 0, 'an empty list is a count of zero');
    is($bd->why_not(sq('a2'), sq('a1')), WHY_CORNER, 'and the corner is the reason the last square is closed');
};

subtest 'only the side to move moves' => sub {
    list_is('7/7/7/7/7/7/a5d a', undef,
        'a1a2 a1a3 a1a4 a1a5 a1a6 a1b1 a1c1 a1d1 a1e1 a1f1',
        'the attackers to move: the attacker\'s moves and none of the defender\'s');
    list_is('7/7/7/7/7/7/a5d d', undef,
        'g1b1 g1c1 g1d1 g1e1 g1f1 g1g2 g1g3 g1g4 g1g5 g1g6',
        'the defenders to move: the other way about');
};

done_testing();
