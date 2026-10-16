use strict;
use warnings;
use Test::More;

use Game::Shogi::Engine ':all';
use Game::Shogi::Result;
my $E = 'Game::Shogi::Engine';

sub played {
    my ($sfen, @moves) = @_;
    my $b = $E->new(sfen => $sfen);
    for my $m (@moves) {
        ok((grep { $_ eq $m } $b->legal), "$m is legal") or return $b;
        $b->do_move($m);
    }
    return $b;
}

# ---- the start, and a check that is not mate ---------------------------------------

{
    my $b = $E->new;
    is($b->status, 'ongoing', 'the start is in play');
    is($b->outcome, undef, '  with no outcome');
    $b = $E->new(sfen => '4k4/9/9/9/9/9/9/9/4R3K w - 1');
    ok($b->in_check('w'), 'a rook on the open file checks the king');
    is($b->status, 'ongoing', '  but the king can step aside: in play');
}

# ---- mate, three ways ---------------------------------------------------------------
#
# Worked by hand. W line 560: check with no move that answers it.

{
    # A gold dropped on the king's head, held by a pawn: it covers 4a, 6a, 4b
    # and 6b, and the king cannot take it.
    my $b = played('4k4/9/4P4/9/9/9/9/9/4K4 b G 1', 'G*5b');
    is($b->status, 'mate', 'a gold dropped on the king\'s head, held by a pawn: mate');
    my $r = $b->outcome;
    isa_ok($r, 'Game::Shogi::Result');
    is($r->how, 'mate', '  how: mate');
    is($r->winner, 'b', '  Black wins');
    is($r->loser, 'w', '  White loses');
    is($r->ply, 1, '  after one ply');
    ok(!$r->is_draw, '  and it is not a draw');
}

{
    # 03's board: a pawn PUSHED to 1b mates, where a pawn dropped there may not.
    my $b = played('8k/6G2/7SP/9/9/9/9/9/9 b - 1', '1c1b');
    is($b->status, 'mate', 'a pawn pushed to give mate: mate');
}

{
    # A smothered king: its own knight on 2a, bishop on 2b and lance on 1b fill
    # every square round it, and none of them reaches 2c, where a knight drops.
    my $b = played('7nk/7bl/9/9/9/9/9/9/4K4 b N 1', 'N*2c');
    is($b->status, 'mate', 'a knight dropped on a smothered king: mate');
    is($b->outcome->winner, 'b', '  Black wins');
}

{
    my $b = $E->new(sfen => '4k4/4G4/4P4/9/9/9/9/9/4K4 w - 57');
    is($b->status, 'mate', 'a position loaded already mated is mate');
    is($b->outcome->ply, 56, '  and its ply is the move number less one');
}

# ---- no legal move, and not in check ------------------------------------------------

{
    my $b = $E->new(sfen => '+R+N+SGKG+S+N+R/+B+N+SG+LG+S+N+B/P+LPP+LPP+LP/1P2P2P1/9/9/9/9/4k4 b 9P 200');
    ok(!$b->in_check('b'), 'P test_3: Black is not in check');
    is_deeply([ $b->legal ], [], '  and has no legal move');
    is($b->status, 'no_move', '  status: no_move, not mate');
    my $r = $b->outcome;
    is($r->how, 'no_move', '  how: no_move');
    is($r->winner, 'w', '  and it is a LOSS for Black, not a draw');
    ok(!$r->is_draw, '  not a draw');
}

# ---- resignation --------------------------------------------------------------------
#
# W line 565: "at any time during their turn". The board accepts it from the
# side to move only.

{
    my $b = $E->new;
    my $sfen = $b->sfen;
    my $r = $b->resign('b');
    isa_ok($r, 'Game::Shogi::Result', 'Black resigns on its turn');
    is($r->how, 'resign', '  how: resign');
    is($r->winner, 'w', '  White wins');
    is($r->ply, 0, '  after no plies');
    is($b->resign('w'), undef, 'White may not resign on Black\'s turn');
    is($b->resign($_), undef, "nor may '" . ($_ // 'undef') . "'") for 'x', '', undef;
    is($b->sfen, $sfen, 'resigning does not change the board');
    is($b->status, 'ongoing', '  which is still in play');

    my $mated = played('4k4/9/4P4/9/9/9/9/9/4K4 b G 1', 'G*5b');
    is($mated->resign('w'), undef, 'a mated side has already lost and cannot resign');
}

# ---- the Result refuses what is not a result -------------------------------------------

{
    my $ok = Game::Shogi::Result->new(how => 'resign', winner => 'w', ply => 3);
    is_deeply([ $ok->how, $ok->winner, $ok->ply ], [ 'resign', 'w', 3 ], 'a Result holds what it was given');
    my $draw = Game::Shogi::Result->new(how => 'mate', winner => undef);
    ok($draw->is_draw, 'one with no winner is a draw');
    is($draw->loser, undef, '  with no loser');
    is($draw->ply, 0, '  and a ply of 0 when none is given');

    for my $bad (
        [ [ how => 'stalemate' ],              qr/'stalemate' is not how a game ends/ ],
        [ [ hwo => 'mate', winner => 'b' ],     qr/'undef' is not how a game ends/ ],
        [ [ how => 'mate', winner => 'x' ],     qr/the winner is 'b', 'w' or undef/ ],
        [ [ how => 'mate', ply => -1 ],         qr/the ply is a count/ ],
        [ [ how => 'mate', ply => 'one' ],      qr/the ply is a count/ ],
    ) {
        my ($args, $want) = @$bad;
        ok(!eval { Game::Shogi::Result->new(@$args); 1 }, "refused: (@$args)");
        like($@, $want, '  and says why');
    }
}

done_testing();
