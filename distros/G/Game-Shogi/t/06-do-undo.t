use strict;
use warnings;
use Test::More;

use Game::Shogi::Engine ':all';
my $E = 'Game::Shogi::Engine';

my $live0 = $E->live;
my $START = 'lnsgkgsnl/1r5b1/ppppppppp/9/9/9/PPPPPPPPP/1B5R1/LNSGKGSNL b - 1';

sub sq { $E->square($_[0]) }

# ---- a move, made and taken back ---------------------------------------------------

{
    my $b = $E->new;
    my $key = $b->key;
    is($b->do_move('7g7f'), 1, '7g7f is made');
    is($b->sfen, 'lnsgkgsnl/1r5b1/ppppppppp/9/9/2P6/PP1PPPPPP/1B5R1/LNSGKGSNL w - 2',
        '  the pawn on 7f, White to move, move 2');
    is($b->moves_made, 1, '  one move to take back');
    is($b->undo_move, 1, 'and taken back');
    is($b->sfen, $START, '  to the start');
    is($b->key, $key, '  and its key');
    is($b->moves_made, 0, '  with nothing left to take back');
    is($b->undo_move, 0, 'a second undo has nothing to undo');
}

# ---- a capture goes into the hand as its base kind ------------------------------------

{
    my $b = $E->new(sfen => '4k4/9/9/9/4+r4/9/9/9/4R3K b - 1');
    my ($sfen, $key) = ($b->sfen, $b->key);
    ok($b->do_move('5i5e'), 'a rook takes a dragon');
    is($b->hand('b', 'R'), 1, '  and Black holds a ROOK: a captured piece goes into hand unpromoted');
    is($b->at(sq('5e')), 'R', '  the rook stands on 5e');
    is($b->key, $E->new(sfen => $b->sfen)->key, '  and the key is the one that SFEN reads to');
    ok($b->undo_move, 'taken back');
    is($b->sfen, $sfen, '  the dragon is back and the hand is empty');
    is($b->key, $key, '  and the key is back');
}

{
    my $b = $E->new(sfen => '4k4/9/9/4p4/9/9/9/9/4R3K b - 1');
    ok($b->do_move('5i5d'), 'a rook takes a pawn outside the zone');
    is($b->at(sq('5d')), 'R', '  and stays a rook');
    ok($b->undo_move, '  and is taken back');
    ok($b->do_move('5i5d'), 'the same again') && ok($b->undo_move, '  and back');
    my $b2 = $E->new(sfen => '4k4/9/4p4/9/9/9/9/9/4R3K b - 1');
    ok($b2->do_move('5i5c+'), 'a rook takes a pawn in the zone and promotes');
    is($b2->at(sq('5c')), '+R', '  to a dragon');
    is($b2->hand('b', 'P'), 1, '  with the pawn in hand');
    ok($b2->undo_move, '  and is taken back');
    is($b2->at(sq('5i')), 'R', '  a rook again on 5i');
}

# ---- what do_move refuses, and that it changes nothing when it does ----------------------

{
    my $b = $E->new;
    my ($sfen, $key) = ($b->sfen, $b->key);
    my %refused = (
        '5e5d'    => 'an empty square',
        '3c3d'    => "the other side's piece",
        '8h7g'    => 'onto its own piece',
        '6i6h+'   => 'a gold promoting',
        '5i5h+'   => 'a king promoting',
        '7g7g'    => 'onto the square it left',
        '7g'      => 'half a move',
        '7g7f++'  => 'two pluses',
        '0a1a'    => 'a file 0',
        '7j7f'    => 'a rank j',
        'P*5e'    => 'a drop, which is version 3',
        ''        => 'nothing',
    );
    for my $usi (sort keys %refused) {
        is($b->do_move($usi), 0, "refused: $refused{$usi} ('$usi')");
    }
    is($b->do_move(undef), 0, 'refused: undef');
    is($b->sfen, $sfen, 'and the board is as it was');
    is($b->key, $key, '  with its key');
    is($b->moves_made, 0, '  and nothing to take back');

    ok($b->do_move('2h3h'), 'do_move does NOT judge geometry: a rook sideways is a legal shape here');
    ok($b->undo_move, '  (and back)');
    ok($b->do_move('2h5e'), 'nor that the piece could get there: a rook to 5e in one move');
    ok($b->undo_move, '  (and back)');
    is($b->sfen, $sfen, 'that is what board_moves is for');
}

{
    my $b = $E->new(sfen => '4k4/9/9/9/9/9/9/9/4R4 b - 1');
    ok((grep { $_ eq '5i5a' } $b->pseudo_moves), 'taking a king is pseudo-legal');
    is($b->do_move('5i5a'), 0, 'but do_move refuses it: a king never goes into a hand');
    ok(!(grep { $_ eq '5i5a' } $b->board_moves), '  so it is not a board move either');
}

{
    my $b = $E->new(sfen => '9/9/9/9/9/9/9/9/9 b 18P 1');
    $b->put(sq('5e'), 'p')->put(sq('5i'), 'R');
    is($b->do_move('5i5e'), 0, 'a nineteenth pawn cannot go into a hand: refused');
    is($b->hand('b', 'P'), 18, '  and the hand is as it was');
}

# ---- undo checks the board -----------------------------------------------------------

{
    my $b = $E->new;
    $b->do_move('7g7f');
    $b->lift(sq('7f'));
    is($b->undo_move, 0, 'undo is refused when the board no longer shows the move');
    is($b->moves_made, 1, '  and the move is still on the list');
    $b->put(sq('7f'), 'P');
    is($b->undo_move, 1, 'put back as it was, it is taken back');

    $b->do_move('7g7f');
    $b->set_side_to_move('b');
    is($b->undo_move, 0, 'refused when it is not the other side\'s turn');
    $b->set_side_to_move('w');
    is($b->undo_move, 1, '  and taken back when it is');

    is($b->sfen, $START, 'back at the start');

    # A record that was never one, handed straight to the XSUB on a raw board,
    # held so it is let go.
    my $raw = Game::Shogi::Engine::_new_board();
    my $hold = Game::Shogi::Engine::_hold_board($raw);
    is(Game::Shogi::Engine::_undo_move($raw, 'not a record'), 0, 'a string that is not a record is refused');
    is(Game::Shogi::Engine::_undo_move($raw, "\0" x 16), 0, 'and so is one of the right length that is not a move made');
    is(Game::Shogi::Engine::_to_sfen($raw), $START, 'and the board is untouched');
    my $record = Game::Shogi::Engine::_do_move($raw, Game::Shogi::Engine::_move_of('7g7f'));
    ok(defined $record, 'a real record from a real move');
    is(Game::Shogi::Engine::_undo_move($raw, $record . 'x'), 0, '  with a byte too many is refused, though its first bytes are right');
    is(Game::Shogi::Engine::_undo_move($raw, $record), 1, '  and as it was, is taken back');

    my $c = $E->new;
    $c->do_move('7g7f');
    my $d = $c->clone;
    is($d->moves_made, 0, 'a clone starts with nothing to take back');
    is($d->undo_move, 0, '  and refuses an undo');
}

# ---- 1,000 plies of key identity --------------------------------------------------------
#
# After every move of random games, the key carried along equals the key the
# SFEN reads to from nothing, and taking every move back returns the start.

{
    srand(20261015);
    my ($plies, $bad, $captures, $games, $drops) = (0, 0, 0, 0, 0);
    while ($plies < 1000 && $games++ < 50) {
        my $b = $E->new;
        for my $ply (1 .. 200) {
            my @legal = $b->legal;
            last unless @legal;
            my $move = $legal[ int rand @legal ];
            $drops++ if $move =~ /\*/;
            $b->do_move($move) or do { $bad++; last };
            $plies++;
            $bad++ unless $b->key eq $E->new(sfen => $b->sfen)->key;
        }
        $captures += $_ for map { values %$_ } values %{ $b->hands };
        1 while $b->undo_move;
        $bad++ unless $b->sfen eq $START && $b->moves_made == 0;
    }
    is($bad, 0, "$plies plies in $games games: the key after every move is the key of its SFEN, and every game undoes to the start");
    cmp_ok($plies, '>=', 1000, '  at least a thousand of them');
    cmp_ok($captures, '>', 0, "  with $captures pieces in hand at the ends, so captures were made and undone");
    cmp_ok($drops, '>', 0, "  and $drops drops among the moves, made and undone");
}

# ---- perft, board moves only -------------------------------------------------------------
#
# P: 30 at depth 1 and 900 at depth 2 from the start. No capture can happen by
# then, so no drop could, and these are whole perft counts.

sub perft {
    my ($b, $depth) = @_;
    my @moves = $b->board_moves;
    return scalar @moves if $depth == 1;
    my $n = 0;
    for my $m (@moves) {
        $b->do_move($m) or die "$m refused";
        $n += perft($b, $depth - 1);
        $b->undo_move or die "$m not undone";
    }
    return $n;
}

is(perft($E->new, 1), 30, 'perft 1 from the start is 30');
is(perft($E->new, 2), 900, 'perft 2 from the start is 900');

is($E->live, $live0, 'every board made in this file was let go');

done_testing();
