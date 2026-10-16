use strict;
use warnings;
use utf8;
use Test::More;

use Game::Shogi;
my $G = 'Game::Shogi';
binmode Test::More->builder->$_, ':encoding(UTF-8)' for qw(output failure_output todo_output);

my $START = 'lnsgkgsnl/1r5b1/ppppppppp/9/9/9/PPPPPPPPP/1B5R1/LNSGKGSNL b - 1';

# ---- a game, and undo across a capture, a promotion and a drop --------------------------

{
    my $g = $G->new;
    is($g->start, $START, 'an even game starts at the start');
    is($g->status, 'active', '  in play');
    is($g->turn, 'b', '  Black to move');
    my @seen = ($g->sfen);
    for my $m (qw(7g7f 3c3d 8h2b+ 3a2b B*4e)) {
        is($g->play($m), 0, "$m is played");
        push @seen, $g->sfen;
    }
    is_deeply([ $g->moves ], [qw(7g7f 3c3d 8h2b+ 3a2b B*4e)], 'the moves are kept');
    is_deeply($g->hand('w'), { B => 1 }, 'White holds the bishop it took');
    is_deeply($g->hand('b'), {}, 'Black dropped the one it took');
    for my $back (reverse 0 .. 4) {
        is($g->undo, 0, 'undo');
        is($g->sfen, $seen[$back], "  back to position $back: the drop, the recapture, the promotion and capture undone in turn");
    }
    is($g->undo->code, 'nothing_to_undo', 'nothing more to take back');

    my $h = $g->hand('w');
    $h->{R} = 9;
    is_deeply($g->hand('w'), {}, 'hand hands back a copy');
    my $b = $g->board;
    $b->lift(0);
    is($g->sfen, $START, 'board hands back a copy');
}

# ---- a USI string and a Move are the same ---------------------------------------------------

{
    my ($s, $m) = ($G->new, $G->new);
    $s->play('2g2f');
    $m->play(Game::Shogi::Move->of('2g2f'));
    is($m->sfen, $s->sfen, 'a Move plays as its USI string does');
    my @legal = $G->new->legal;
    isa_ok($legal[0], 'Game::Shogi::Move', 'legal hands back Moves');
    is(scalar @legal, 30, '  thirty of them at the start');
}

# ---- every refusal -------------------------------------------------------------------------

{
    my %R = (
        bad_move            => [ $START, 'x' ],
        not_your_piece      => [ $START, '3c3d' ],
        not_in_hand         => [ $START, 'P*5e' ],
        cannot_reach        => [ $START, '7g7e' ],
        occupied            => [ '4k4/9/9/9/9/9/9/9/4K4 b P 1', 'P*5i' ],
        promote_not_allowed => [ $START, '7g7f+' ],
        promote_required    => [ 'k8/4P4/9/9/9/9/9/9/4K4 b - 1', '5b5a' ],
        dead_piece          => [ '4k4/9/9/9/9/9/9/9/4K4 b P 1', 'P*3a' ],
        two_pawns           => [ '4k4/9/9/9/9/9/4P4/9/4K4 b P 1', 'P*5c' ],
        in_check            => [ '4r4/9/9/9/9/9/9/4G4/4K4 b - 1', '5h4g' ],
        pawn_drop_mate      => [ '8k/6G2/7S1/9/9/9/9/9/9 b P 1', 'P*1b' ],
    );
    for my $code (sort keys %R) {
        my ($sfen, $move) = @{ $R{$code} };
        my $g = $G->new(sfen => $sfen);
        my $r = $g->play($move);
        isa_ok($r, 'Game::Shogi::Error', "'$move'");
        is($r && $r->code, $code, "  refused: $code");
        is($r && $r->message, Game::Shogi::Error->message_for($code), '  with its message');
        is($g->sfen, $sfen, '  and nothing changed');
    }
    is($G->new->play(undef)->code, 'bad_move', 'undef is not a move');
    is($G->new->resign('w')->code, 'not_your_turn', 'White may not resign on Black\'s turn');
    my $d = $G->new->declare;
    is($d->code, 'cannot_declare', 'the start cannot declare the impasse');
    like($d->message, qr/: the king is not in the enemy camp\z/, '  and says which condition failed');
    is_deeply([ sort map { $_ } Game::Shogi::Error->codes ], [ sort (keys %R, qw(game_over not_your_turn cannot_declare nothing_to_undo)) ],
        'every code is reached by some refusal here');
    ok(!eval { Game::Shogi::Error->throw('nope'); 1 }, 'a refusal that does not exist is a programmer\'s error, and dies');
}

# ---- the ends ---------------------------------------------------------------------------------

{
    my $g = $G->new;
    is($g->resign('b'), 0, 'Black resigns');
    is($g->result->how, 'resign', '  result: resign');
    is($g->winner, 'w', '  White wins');
    is($g->status, 'finished', '  finished');
    is($g->turn, undef, '  nobody\'s turn');
    is_deeply([ $g->legal ], [], '  no legal moves');
    is($g->play('7g7f')->code, 'game_over', '  a move is refused');
    is($g->undo->code, 'game_over', '  and a resignation is not undone');
    is($g->resign('w')->code, 'game_over', '  nor resigned again');
}

{
    my $g = $G->new(sfen => '4k4/9/4P4/9/9/9/9/9/4K4 b G 1');
    is($g->play('G*5b'), 0, 'the gold drop that mates');
    is($g->result->how, 'mate', '  result: mate');
    is($g->winner, 'b', '  Black wins');
    is($g->undo, 0, 'a mate can be taken back');
    is($g->result, undef, '  and the game is on again');
    is($g->status, 'active', '  active');
}

{
    my $g = $G->new(sfen => 'RRBB1GGGG/4K1SS1/9/9/9/9/9/9/4k4 b 2P 1');
    ok($g->can_declare, 'a position that may declare');
    is($g->declare, 0, '  declares');
    is($g->result->how, 'impasse_declared', '  result: impasse_declared');
    is($g->winner, 'b', '  Black wins');
    is($g->undo->code, 'game_over', '  and a declaration is not undone');
}

{
    my $g = $G->new(sfen => '4k3g/9/9/9/9/9/9/9/K4R3 b - 1');
    $g->play($_) for (qw(4i3i 1a1b 3i4i 1b1a)) x 3;
    is($g->result && $g->result->how, 'sennichite', 'a shuffle to the fourth standing: sennichite');
    ok($g->result && $g->result->is_draw, '  a draw');
}

{
    my $g = $G->new(sfen => '4k4/9/9/9/9/9/9/9/4K3G b - 500');
    $g->play('1i1h');
    is($g->result && $g->result->how, 'cap', '500 moves: the cap');
    my $short = $G->new(sfen => '4k4/9/9/9/9/9/9/9/4K3G b - 10', cap => 10);
    $short->play('1i1h');
    is($short->result && $short->result->how, 'cap', 'a cap may be given');
}

{
    my $g = $G->new(sfen => '+R+N+SGKG+S+N+R/+B+N+SG+LG+S+N+B/P+LPP+LPP+LP/1P2P2P1/9/9/9/9/4k4 b 9P 200');
    is($g->result && $g->result->how, 'no_move', 'a game handed a position with no legal move is over at once');
    is($g->status, 'finished', '  finished');
}

# ---- the log ------------------------------------------------------------------------------------

{
    my $g = $G->new(handicap => 'rook');
    $g->play($_) for qw(3c3d 7g7f 2b7g+ 8h7g);
    my $log = $g->log;
    is_deeply($log, { start => Game::Shogi::Handicap->sfen('rook'), handicap => 'rook', moves => [qw(3c3d 7g7f 2b7g+ 8h7g)] },
        'a log is the start, the handicap and the moves');
    my $again = $G->from_log($log);
    is($again->sfen, $g->sfen, 'from_log plays it again to the same position');
    is($again->handicap, 'rook', '  with the same handicap');
    is_deeply([ $again->moves ], [ $g->moves ], '  and the same moves');
    is($g->record->{moves}[2]{japanese}, '△７七角成', 'record writes it down: △７七角成');

    ok(!eval { $G->from_log({ moves => [qw(7g7f 7g7e)] }); 1 }, 'a log with a refused move does not replay');
    like($@, qr/move 2 \('7g7e'\) of the log was refused: there is no piece of yours there/, '  and names the move and why');
    is($G->from_log({ moves => ['7g7f'] })->start, $START, 'a log with no start is an even game');
    ok(!eval { $G->from_log('nope'); 1 }, 'a log that is not a hash is refused');
    ok(!eval { $G->new(handicap => 'rook', sfen => $START); 1 }, 'a handicap and a position together are refused');
}
subtest 'to_text and from_text: the game as a string, and back' => sub {
    my $g = Game::Shogi->new(handicap => 'bishop', cap => 300);
    $g->play($_) for qw(3a3b 7g7f 3c3d);
    my $text = $g->to_text;
    is($text, join("\n", 'shogi 1', 'handicap bishop', 'start ' . $g->start, 'cap 300', 'moves 3a3b 7g7f 3c3d', ''),
        'the handicap, the start, the cap, the moves');
    my $again = Game::Shogi->from_text($text);
    is($again->to_text, $text, 'from_text writes the same string');
    is($again->sfen, $g->sfen, '  at the same position');
    is_deeply([ $again->history ], [ $g->history ], '  with the same history for the search');

    ok(!$g->resign('b'), 'Black resigns');
    my $r = Game::Shogi->from_text($g->to_text);
    like($g->to_text, qr/^ending resign b$/m, 'a resignation is written, by the side that resigned');
    is($r->result && $r->result->how, 'resign', '  and comes back');
    is($r->winner, 'w', '  White wins');

    my $d = Game::Shogi->new(sfen => 'RRBB1GGGG/4K1SS1/9/9/9/9/9/9/4k4 b 2P 1');
    ok(!$d->declare, 'a declaration');
    my $d2 = Game::Shogi->from_text($d->to_text);
    is($d2->result && $d2->result->how, 'impasse_declared', '  comes back');
    unlike(Game::Shogi->new->to_text, qr/^(?:handicap|ending)/m, 'an even game on: no handicap, no ending');

    my $base = Game::Shogi->new->to_text;
    for my $bad (
        [ undef,                                   qr/given nothing/ ],
        [ [],                                      qr/given a reference/ ],
        [ "chess 1\n",                             qr/not a saved game of shogi/ ],
        [ $base =~ s/^cap .*\n//mr,                qr/no cap line/ ],
        [ $base =~ s/^cap .*$/cap many/mr,         qr/cap is not a whole number/ ],
        [ $base . "cap 5\n",                       qr/gives cap twice/ ],
        [ $base . "colour red\n",                  qr/line it does not know: 'colour red'/ ],
        [ $base =~ s/^moves.*$/moves 7g7f 7g7f/mr, qr/move 2 \('7g7f'\) of the log was refused/ ],
        [ $base . "ending sulk\n",                 qr/ending is not one it knows: 'sulk'/ ],
        [ $base . "ending declare\n",              qr/ending 'declare' was refused/ ],
        [ $base . "ending resign w\n",             qr/ending 'resign w' was refused/ ],
    ) {
        ok(!eval { Game::Shogi->from_text($bad->[0]); 1 }, 'refused: ' . (defined $bad->[0] && !ref $bad->[0] ? ($bad->[0] =~ tr/\n/|/r) : 'not a string'));
        like($@, $bad->[1], '  saying why');
    }
};

done_testing;
