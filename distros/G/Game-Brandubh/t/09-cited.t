use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";

use Game::Brandubh::Engine ':all';
use Game::Brandubh::Test::Squares qw(sq name wire unwire);
my $E = 'Game::Brandubh::Engine';

# POSITIONS WITH A SENTENCE ATTACHED. Every case names the rule it tests and
# quotes it, so that this file can be read by somebody who knows the game and
# not the code, and so that a case nobody can cite does not get in.
#
# The numbered rules are quoted from the reconstruction by Aage Nielsen as
# published at tafl.cyningstan.com. The three marked "reading" are this
# distribution's own, where that text is silent or brief, and each gives the
# sentence it leans on.

my %RULE = (
    R6 => 'A piece other than the king is captured when it is surrounded orthogonally on two '
        . 'opposite squares by enemies. The king can take part in captures in partnership with a defender.',
    R7 => 'A piece may also be captured between an enemy and the empty central square or a corner square.',
    R8 => 'When in the central square, the king is captured by surrounding him on four orthogonal '
        . 'sides with attackers.',
    R9 => 'When standing beside the central square, the king may be captured by surrounding him on '
        . 'the remaining three sides with attackers.',
    R10 => 'Elsewhere on the board, the king is captured as other pieces. This includes beside the '
         . 'corners, where he can be captured between an attacker and the corner as in rule 7.',
    'reading: only the mover captures' =>
        'It is usually acceptable to place a piece deliberately between two enemies without harm; '
      . 'capture must be a deliberate act.',
    'reading: several at once' =>
        'if the layout is XO-OX, and a third X moves into the middle, both Os are captured. '
      . 'It\'s possible to capture three at once this way (but never four',
    'reading: the king as hammer' =>
        'a king moving to C1 will capture an attacker on B1 against the A1 corner. '
      . 'There\'s no distinction between hammer and anvil here!',
    'reading: the edge' =>
        'Some versions of hnefatafl allow this, and also allow the king to be captured against '
      . 'the edge and a corner with two attackers. But most of the more popular versions (like '
      . 'Fetlar and Copenhagen hnefatafl) don\'t.',
);

# a case: the rule, what it shows, the position, the move, what it takes, and
# whether the king was taken or went home
my @CASES = (
    [ 'R6', 'an attacker between two defenders is taken',
        '7/4d2/7/7/2da3/7/7 d', 'e6e3', 'd3', 0 ],
    [ 'R6', 'a defender between two attackers is taken',
        '7/4a2/7/7/2ad3/7/7 a', 'e6e3', 'd3', 0 ],
    [ 'R6', 'the king as the piece that waits: an attacker between him and a defender',
        '7/4d2/7/7/2ka3/7/7 d', 'e6e3', 'd3', 0 ],
    [ 'R6', 'the king as the piece that moves',
        '7/4k2/7/7/2da3/7/7 d', 'e6e3', 'd3', 0 ],
    [ 'R6', 'one enemy is not two: a defender with an attacker on one side only',
        '7/4a2/7/7/3d3/7/7 a', 'e6e3', '', 0 ],
    [ 'R6', 'two opposite squares, not two adjacent ones',
        '7/2a4/7/7/3d3/3a3/7 a', 'c6c3', '', 0 ],

    [ 'reading: only the mover captures', 'a defender moves between two attackers and stands',
        '7/3d3/7/7/2a1a2/7/7 d', 'd6d3', '', 0 ],
    [ 'reading: only the mover captures', 'an attacker does the same between two defenders',
        '7/3a3/7/7/2d1d2/7/7 a', 'd6d3', '', 0 ],
    [ 'reading: only the mover captures', 'and so does the king, between two attackers in the open',
        '7/7/7/7/2a1a2/7/3k3 d', 'd1d3', '', 0 ],

    [ 'R7', 'a defender beside the empty throne, an attacker arriving opposite',
        '7/1a5/7/2d4/7/7/7 a', 'b6b4', 'c4', 0 ],
    [ 'R7', '"A piece": an attacker beside the empty throne, a defender arriving opposite',
        '7/1d5/7/2a4/7/7/7 d', 'b6b4', 'c4', 0 ],
    [ 'R7', 'the same up a file, the attacker arriving under the defender',
        '7/7/7/7/3d3/a6/7 a', 'a2d2', 'd3', 0 ],
    [ 'R7', 'the king ON the throne is an enemy of the attacker beside him',
        '7/1d5/7/2ak3/7/7/7 d', 'b6b4', 'c4', 0 ],
    [ 'R7', '"the EMPTY central square": a defender beside his own king on the throne is safe',
        '7/1a5/7/2dk3/7/7/7 a', 'b6b4', '', 0 ],

    [ 'R8', 'three attackers round the king on the throne, and a fourth arriving',
        '3a3/7/7/2aka2/3a3/7/7 a', 'd7d5', 'd4', KING_TAKEN ],
    [ 'R8', 'three attackers and a defender on the fourth side: not captured',
        '3a3/7/7/2aka2/3d3/7/7 a', 'd7d5', '', 0 ],
    [ 'R8', 'two attackers on opposite sides of the throne are not four',
        '4a2/7/7/2ak3/7/7/7 a', 'e7e4', '', 0 ],
    [ 'R8', 'three are not four',
        '4a2/7/7/2ak3/3a3/7/7 a', 'e7e4', '', 0 ],

    [ 'R9', 'the king on c4, attackers on c5 and c3, a third arriving on b4',
        '1a5/7/2a4/2k4/2a4/7/7 a', 'b7b4', 'c4', KING_TAKEN ],
    [ 'R9', 'the king on e4, attackers on e5 and e3, a third arriving on f4',
        '5a1/7/4a2/4k2/4a2/7/7 a', 'f7f4', 'e4', KING_TAKEN ],
    [ 'R9', 'the king on d3, attackers on c3 and e3, a third arriving on d2',
        '7/7/7/7/2aka2/a6/7 a', 'a2d2', 'd3', KING_TAKEN ],
    [ 'R9', 'the king on d5, attackers on c5 and e5, a third arriving on d6',
        '7/a6/2aka2/7/7/7/7 a', 'a6d6', 'd5', KING_TAKEN ],
    [ 'R9', '"the remaining THREE sides": two attackers do not take him, though the throne is behind him',
        '1a5/7/2a4/2k4/7/7/7 a', 'b7b4', '', 0 ],
    [ 'R9', 'nor does an attacker facing the throne across him, alone',
        '1a5/7/7/2k4/7/7/7 a', 'b7b4', '', 0 ],

    [ 'R10', 'the king in the open, between two attackers',
        '7/5ka/7/7/7/4a2/7 a', 'e2e6', 'f6', KING_TAKEN ],
    [ 'R10', '"beside the corners": the king on b1, an attacker arriving on c1',
        '7/7/2a4/7/7/7/1k5 a', 'c5c1', 'b1', KING_TAKEN ],
    [ 'R10', 'the king on a2, an attacker arriving on a3',
        '7/7/7/7/4a2/k6/7 a', 'e3a3', 'a2', KING_TAKEN ],
    [ 'R10', 'the king on the edge between two attackers ALONG the edge',
        '7/7/4a2/7/7/7/2ak3 a', 'e5e1', 'd1', KING_TAKEN ],

    [ 'reading: the edge', 'the king on the edge with one attacker arriving in front of him',
        '7/7/7/7/7/a6/3k3 a', 'a2d2', '', 0 ],
    [ 'reading: the edge', 'a defender on the edge the same way',
        '7/7/7/7/7/a6/3d3 a', 'a2d2', '', 0 ],
    [ 'reading: the edge', 'an attacker on the a file with a defender arriving beside it',
        '7/7/7/a6/7/1d5/7 d', 'b2b4', '', 0 ],

    [ 'reading: the king as hammer', 'the sentence itself: the king to c1 takes the attacker on b1',
        '7/7/2k4/7/7/7/1a5 d', 'c5c1', 'b1', 0 ],
    [ 'reading: the king as hammer', 'the king takes against the empty throne on his own',
        '7/1k5/7/2a4/7/7/7 d', 'b6b4', 'c4', 0 ],
    [ 'reading: the king as hammer', 'the king reaches a corner and takes with the same move',
        '7/7/7/7/7/k6/1ad4 d', 'a2a1', 'b1', KING_HOME ],

    [ 'reading: several at once', 'two: an attacker into the middle of XO-OX',
        '7/7/7/7/ad1da2/7/2a4 a', 'c1c3', 'b3 d3', 0 ],
    [ 'reading: several at once', 'three, the most a move can take',
        '7/6k/2a4/2d4/ad1da2/7/2a4 a', 'c1c3', 'b3 c4 d3', 0 ],
    [ 'reading: several at once', 'three by the king',
        '7/6a/2d4/2a4/da1ad2/7/2k4 d', 'c1c3', 'b3 c4 d3', 0 ],
    [ 'reading: several at once', 'the king and a defender in one move',
        '7/7/2a4/7/7/ad1ka2/7 a', 'c5c2', 'b2 d2', KING_TAKEN ],
);

# the corners, each from both sides of it and for both sides of the board: R7
# says "a corner square" and there are four
for my $c (
    [ 'a1', 'b1', 'c5', 'c1' ], [ 'a1', 'a2', 'e3', 'a3' ],
    [ 'g1', 'f1', 'e5', 'e1' ], [ 'g1', 'g2', 'c3', 'g3' ],
    [ 'a7', 'b7', 'c3', 'c7' ], [ 'a7', 'a6', 'e5', 'a5' ],
    [ 'g7', 'f7', 'e3', 'e7' ], [ 'g7', 'g6', 'c5', 'g5' ],
) {
    my ($corner, $victim, $from, $to) = @$c;
    for my $pair ([ ATTACKER, DEFENDER, ATTACKERS ], [ DEFENDER, ATTACKER, DEFENDERS ]) {
        my ($mover, $prey, $side) = @$pair;
        my $bd = $E->new(empty => 1);
        $bd->put(sq($victim), $prey)->put(sq($from), $mover)->set_side($side);
        push @CASES, [ 'R7',
            ($prey == DEFENDER ? 'a defender' : 'an attacker') . " on $victim against the corner $corner",
            $bd->to_string, "$from$to", $victim, 0 ];
    }
}

my %cited;
for my $case (@CASES) {
    my ($rule, $what, $position, $move, $takes, $flag) = @$case;
    my $quote = $RULE{$rule};
    $cited{$rule}++;

    subtest "$rule: $what" => sub {
        ok(defined $quote, "cited: \"" . ($quote // 'NO SUCH RULE') . "\"");
        my ($bd, $err) = $E->of_string($position);
        ok($bd, "the position loads: $position") or return;
        my $mv = unwire($move);
        ok($bd->is_legal($mv), "$move is a legal move");

        my ($pflags, @psquares) = $bd->preview($mv);
        is(join(' ', sort map { name($_) } @psquares), $takes, 'preview: ' . ($takes eq '' ? 'takes nothing' : "takes $takes"));

        my %before = map { $_ => $bd->at($_) } $E->all_squares;
        my ($flags) = $bd->do_move($mv);
        my @gone = grep { $before{$_} != EMPTY && $bd->at($_) == EMPTY && $_ != sq(substr($move, 0, 2)) } $E->all_squares;
        is(join(' ', sort map { name($_) } @gone), $takes, 'and the board afterwards is missing exactly those');
        is($flags, $pflags, 'do_move reports what preview reported');

        is(!!($flags & DID_CAPTURE), $takes ne '', 'DID_CAPTURE says whether anything was taken');
        is($flags & KING_TAKEN, $flag & KING_TAKEN, ($flag & KING_TAKEN) ? 'the king was taken' : 'the king was not taken');
        is($flags & KING_HOME,  $flag & KING_HOME,  ($flag & KING_HOME)  ? 'the king is home' : 'the king is not home');
    };
}

is(join(', ', sort keys %RULE), join(', ', sort keys %cited), 'every rule quoted above has at least one case');
cmp_ok(scalar(@CASES), '>=', 50, scalar(@CASES) . ' cited positions');
ok(!(grep { !exists $RULE{ $_->[0] } } @CASES), 'and no case without a citation');

done_testing();
