use strict;
use warnings;
use Test::More;

use Game::Shogi::Engine ':all';
my $E = 'Game::Shogi::Engine';

sub play {
    my ($b, @moves) = @_;
    for my $m (@moves) {
        die "$m is not legal in " . $b->sfen unless grep { $_ eq $m } $b->legal;
        $b->do_move($m) or die "$m refused";
    }
    return $b;
}

sub pack_of { $_[0]->packed }

# Worked by hand. A Black rook checks along file 5, then file 4, while White's
# king steps between 5a and 4a: CHECK is a cycle of four plies, and Black
# checks with both its moves. QUIET is the rook going to 3i and back while a
# White gold steps to 1b and back: nobody checks.
my @CHECK = qw(4i5i 5a4a 5i4i 4a5a);
my @QUIET = qw(4i3i 1a1b 3i4i 1b1a);
my $S0    = '4k3g/9/9/9/9/9/9/9/K4R3 b - 1';

# ---- packed positions ----------------------------------------------------------------

{
    my $b = $E->new;
    is(length pack_of($b), PACKED, 'a packed position is PACKED bytes');
    my $more = $E->new(sfen => '4k4/9/9/9/9/9/9/9/4K4 b P 1');
    my $less = $E->new(sfen => '4k4/9/9/9/9/9/9/9/4K4 b - 1');
    isnt(pack_of($more), pack_of($less), 'a pawn in hand changes it');
    my $white = $E->new(sfen => '4k4/9/9/9/9/9/9/9/4K4 w - 1');
    isnt(pack_of($white), pack_of($less), 'so does the side to move');
    is(pack_of($E->new(sfen => '4k4/9/9/9/9/9/9/9/4K4 b - 77')), pack_of($less), 'the move number does not');
}

# ---- a quiet shuffle: a draw on the fourth standing -----------------------------------

{
    my $b = $E->new(sfen => $S0);
    play($b, @QUIET, @QUIET);
    is($b->outcome, undef, 'the start has stood three times: play on');
    play($b, @QUIET[0 .. 2]);
    is($b->outcome, undef, '  eleven plies in, still on');
    play($b, $QUIET[3]);
    my $r = $b->outcome;
    is($r && $r->how, 'sennichite', 'the fourth time it stands: sennichite');
    ok($r && $r->is_draw, '  a draw');
    is($r && $r->ply, 12, '  after twelve plies');
    is($b->status, 'ongoing', '  though the board itself still has moves');

    ok($b->undo_move, 'take the last move back');
    is($b->outcome, undef, '  and it is no longer the fourth time');
    play($b, $QUIET[3]);
    is($b->outcome && $b->outcome->how, 'sennichite', '  play it again and it is');

    {
        my $t = play($E->new(sfen => $S0), @QUIET, @QUIET);
        for (1 .. 3) { $t->do_move('4i3i'); $t->undo_move }
        play($t, '4i3i');
        is($t->outcome, undef, 'a move made and taken back three times leaves no trace: its position has stood three times, not four');
    }
    is($b->clone->outcome, undef, 'a clone has no history, so no repetition');
    $b->put($E->square('9a'), 'p');
    is($b->outcome, undef, 'a board changed by put is not judged by the trail it left');
}

# ---- perpetual check: the side that kept checking loses -------------------------------

{
    my $b = play($E->new(sfen => $S0), @CHECK, @CHECK, @CHECK);
    my $r = $b->outcome;
    is($r && $r->how, 'perpetual_check', 'Black gave check with every move: perpetual check');
    is($r && $r->winner, 'w', '  and White wins (W line 613: an illegal move, a loss)');

    my $w = play($E->new(sfen => 'k4r3/9/9/9/9/9/9/9/4K4 w - 1'),
                 qw(4a5a 5i4i 5a4a 4i5i), qw(4a5a 5i4i 5a4a 4i5i), qw(4a5a 5i4i 5a4a 4i5i));
    is($w->outcome && $w->outcome->how, 'perpetual_check', 'White\'s rook doing the same: perpetual check');
    is($w->outcome && $w->outcome->winner, 'b', '  and Black wins');
}

# ---- one quiet move in the window: a draw ---------------------------------------------

{
    my $b = play($E->new(sfen => $S0), @CHECK, @QUIET, @CHECK);
    my $r = $b->outcome;
    is($r && $r->how, 'sennichite', 'checks, then a quiet cycle, then checks: Black did not check every move, so a draw');
    ok($r && $r->is_draw, '  nobody wins');
}

# ---- the judge, fed by hand ----------------------------------------------------------
#
# A trail is the keys, the packed positions and whether each move gave check.

sub judge {
    my (@boards) = @_;
    return Game::Shogi::Engine::_repetition([ map { $_->key } @boards ], [ map { pack_of($_) } @boards ],
                                            [ map { 0 } @boards ]);
}

{
    my $A  = $E->new(sfen => '4k4/9/9/9/9/9/9/9/4K4 b P 1');
    my $A2 = $E->new(sfen => '4k4/9/9/9/9/9/9/9/4K4 b - 1');
    my $B  = $E->new(sfen => '4k4/9/9/9/9/9/9/9/3K5 w P 1');
    is((judge($A, $B, $A, $B, $A, $B, $A))[0], 1, 'A four times: a draw');
    is((judge($A, $B, $A, $B, $A2, $B, $A))[0], 0, 'once with a pawn fewer in hand, it has stood three times: nothing');

    my @k = map { '0000000000000000' } 1 .. 7;
    my @p = map { pack_of($_) } $A, $B, $A2, $B, $A2, $B, $A;
    is((Game::Shogi::Engine::_repetition(\@k, \@p, [ (0) x 7 ]))[0], 0,
        'every key the same, the positions not: a key collision is not a repetition');
    my @same = map { pack_of($A) } 1 .. 7;
    my @keys = map { sprintf '%016x', $_ } 1 .. 7;
    is((Game::Shogi::Engine::_repetition(\@keys, \@same, [ (0) x 7 ]))[0], 0,
        'and the bytes the same with the keys not: neither is it');

    is((Game::Shogi::Engine::_repetition([], [], []))[0], 0, 'an empty trail: nothing');
    is((Game::Shogi::Engine::_repetition([ $A->key ], [ pack_of($A) ], [ 0, 0 ]))[0], 0, 'lists of different lengths: nothing');
    is((Game::Shogi::Engine::_repetition([ 'xyz' ], [ pack_of($A) ], [ 0 ]))[0], 0, 'a key that is not hex: nothing');
    is((Game::Shogi::Engine::_repetition([ $A->key ], [ 'short' ], [ 0 ]))[0], 0, 'a packing of the wrong length: nothing');
    is((Game::Shogi::Engine::_repetition('a', 'b', 'c'))[0], 0, 'not array references: nothing');
}

done_testing();
