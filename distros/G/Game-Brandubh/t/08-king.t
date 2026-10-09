use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";

use Game::Brandubh::Engine ':all';
use Game::Brandubh::Test::Squares qw(sq name wire unwire);
my $E = 'Game::Brandubh::Engine';

sub board { my ($bd, $err) = $E->of_string($_[0]); die "refused $_[0]: $err" unless $bd; $bd }

# what a move takes, and what it reports, as two strings
sub result {
    my ($position, $move, $variant) = @_;
    my $bd = board($position);
    my ($flags, @squares) = $bd->preview(unwire($move), $variant);
    return (join(' ', sort map { name($_) } @squares), $flags);
}

sub takes_is {
    my ($position, $move, $variant, $want, $why) = @_;
    my ($got) = result($position, $move, $variant);
    is($got, $want, $why);
}

# The rules themselves are in t/09-cited.t, each with its sentence. This file
# is the king's corners of them: the positions no game reaches that the engine
# must still answer the same way twice, and the three rule sets that change how
# he is taken.

subtest 'only attackers capture the king' => sub {
    takes_is('7/3d3/7/2aka2/3a3/7/7 d', 'd6d5', undef, '',
        'a defender arriving on the fourth side of his own king takes nobody');
    takes_is('7/5ka/7/7/7/4d2/7 d', 'e2e6', undef, '',
        'nor does a defender arriving beside him in the open');
    my ($taken, $flags) = result('7/5ka/7/7/7/4a2/7 a', 'e2e6');
    is($taken, 'f6', 'an attacker arriving on the same square does');
    is($flags, DID_CAPTURE | KING_TAKEN, 'and it is reported as a capture and as the king');
};

subtest 'once taken he is off the board, and the engine plays on' => sub {
    my $bd = board('7/5ka/3d3/7/7/4a2/7 a');
    my ($flags, $undo) = $bd->do_move(unwire('e2e6'));
    ok($flags & KING_TAKEN, 'the king is taken');
    is($bd->count(KING), 0, 'no king is left');
    is($bd->king_square, -1, 'king_square says so');
    is($bd->side, DEFENDERS, 'and it is the defenders\' turn');
    cmp_ok(scalar($bd->moves), '>', 0, 'who still have a list: nothing here knows the game is over');
    $bd->undo_move($undo);
    is($bd->king_square, sq('f6'), 'the undo puts him back where he stood');
};

# Beside the throne the fourth side is the throne. In play it is empty. A
# hand-built board can put a piece there, and the answer is pinned so that it
# is the same answer every time: a friend there means he is not surrounded, and
# an enemy there surrounds him on all four.
subtest 'beside the throne, with something standing on it' => sub {
    takes_is('1a5/7/2a4/2k4/2a4/7/7 a', 'b7b4', undef, 'c4',
        'the throne empty: three attackers take him');
    takes_is('1a5/7/2a4/2kd3/2a4/7/7 a', 'b7b4', undef, '',
        'a defender on the throne: he is not surrounded');
    takes_is('1a5/7/2a4/2ka3/2a4/7/7 a', 'b7b4', undef, 'c4',
        'an attacker on the throne: four attackers, and he is');
};

subtest 'king_everywhere_two: no exception for the throne' => sub {
    my $v = { king_everywhere_two => 1 };
    takes_is('4a2/7/7/2ak3/7/7/7 a', 'e7e4', undef, '',  'on the throne between two: safe by default');
    takes_is('4a2/7/7/2ak3/7/7/7 a', 'e7e4', $v,    'd4', 'and taken under this rule set');
    takes_is('1a5/7/7/2k4/7/7/7 a', 'b7b4', undef, '',  'beside the throne, one attacker facing it: safe by default');
    takes_is('1a5/7/7/2k4/7/7/7 a', 'b7b4', $v,    'c4', 'and taken against the empty throne under this one');
    takes_is('1a5/7/7/2kd3/7/7/7 a', 'b7b4', $v,   '',   'but not against a throne with a defender on it');
    takes_is('7/7/2a4/7/7/7/1k5 a', 'c5c1', $v,    'b1', 'beside a corner he falls as he did before');
    takes_is('1a5/7/2a4/2k4/7/7/7 a', 'b7b4', $v,  'c4', 'with a second attacker beside him too, whatever it adds');
    takes_is('7/7/7/7/7/a6/3k3 a', 'a2d2', $v,     '',   'and the edge is still not an enemy');
};

subtest 'king_strong: every side closed, wherever he stands' => sub {
    my $v = { king_strong => 1 };
    takes_is('7/5ka/7/7/7/4a2/7 a', 'e2e6', undef, 'f6', 'in the open between two: taken by default');
    takes_is('7/5ka/7/7/7/4a2/7 a', 'e2e6', $v,    '',   'and safe under this rule set');
    takes_is('7/7/7/7/1a5/aka4/5a1 a', 'f1b1', $v, 'b2', 'four attackers round him in the open take him');
    takes_is('7/7/7/7/1a5/ak5/5a1 a', 'f1b1', $v,  '',   'three do not');
    takes_is('3a3/7/7/2aka2/3a3/7/7 a', 'd7d5', $v, 'd4', 'on the throne, four, as ever');
    takes_is('1a5/7/2a4/2k4/2a4/7/7 a', 'b7b4', $v, 'c4', 'beside it, three and the empty throne');
    takes_is('1a5/7/2a4/2kd3/2a4/7/7 a', 'b7b4', $v, '',  'beside it with a defender on the throne: no');
    takes_is('7/7/2a4/7/7/7/1k5 a', 'c5c1', undef, 'b1', 'beside a corner: taken by default');
    takes_is('7/7/2a4/7/7/1a5/1k5 a', 'c5c1', $v, '',
        'beside a corner under this rule set he is on the edge, and the edge closes nothing');
    takes_is('7/7/4a2/7/7/3a3/2ak3 a', 'e5e1', $v, '',
        'on the edge with attackers on all three sides the board gives him: still nothing');
    takes_is('7/7/7/7/ad1da2/7/2a4 a', 'c1c3', $v, 'b3 d3', 'other pieces are taken as they always were');
};

subtest 'the two rule sets are not the same rule set' => sub {
    my ($bd) = $E->of_string('7/7/7/7/7/7/7 a');
    ok($bd, 'an empty board loads');
    my $both = eval { $bd->moves({ king_strong => 1, king_everywhere_two => 1 }); 1 };
    ok($both, 'the engine takes both fields at once; refusing the pair is the facade\'s business');
    takes_is('7/5ka/7/7/7/4a2/7 a', 'e2e6', { king_strong => 1, king_everywhere_two => 1 }, 'f6',
        'and when both are set, two is what applies');
};

subtest 'the king home' => sub {
    for my $case ([ 'a4', 'a1' ], [ 'a4', 'a7' ], [ 'g4', 'g1' ], [ 'g4', 'g7' ],
                  [ 'd1', 'a1' ], [ 'd1', 'g1' ], [ 'd7', 'a7' ], [ 'd7', 'g7' ]) {
        my ($from, $to) = @$case;
        my $bd = $E->new(empty => 1);
        $bd->put(sq($from), KING)->set_side(DEFENDERS);
        my ($flags) = $bd->preview(unwire("$from$to"));
        is($flags, KING_HOME, "the king from $from to the corner $to is home");
    }

    my ($taken, $flags) = result('7/7/7/k6/7/7/7 d', 'a4a2');
    is($flags, 0, 'the king along the edge to a square that is not a corner: not home');
    ($taken, $flags) = result('7/7/7/2k4/7/7/7 d', 'c4c1', { escape => 'edge' });
    is($flags, KING_HOME, 'with the edge as the way out, reaching any edge square is home');
    ($taken, $flags) = result('7/7/7/2k4/7/7/7 d', 'c4c2', { escape => 'edge' });
    is($flags, 0, 'and a square one short of it is not');
    ($taken, $flags) = result('7/7/7/2d4/7/7/7 d', 'c4c1', { escape => 'edge' });
    is($flags, 0, 'a defender reaching the edge is nobody\'s escape');
    ($taken, $flags) = result('7/7/7/7/7/k6/1ad4 d', 'a2a1');
    is($taken, 'b1', 'the king reaching a corner takes the attacker beside it');
    is($flags, DID_CAPTURE | KING_HOME, 'and both are reported');

    my $bd = board('k6/7/7/7/7/7/6a a');
    my ($f) = $bd->do_move(unwire('g1g2'));
    is($f, 0, 'a king already standing on a corner is not home by somebody else\'s move');
};

subtest 'the king between two attackers, by his own move' => sub {
    my $bd = board('7/7/7/7/2a1a2/6a/3k3 d');
    my ($flags) = $bd->do_move(unwire('d1d3'));
    is($flags, 0, 'he moves between them and nothing happens');
    ($flags) = $bd->do_move(unwire('g2g5'));
    is($flags, 0, 'an attacker moves elsewhere and nothing happens');
    is($bd->king_square, sq('d3'), 'and he is still there');
    is($bd->at(sq('d4')), EMPTY, 'with the empty throne behind him, which is not an attacker');
};

done_testing();
