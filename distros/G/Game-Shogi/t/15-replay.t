use strict;
use warnings;
use utf8;
use Test::More;

use Game::Shogi::Notation;
my $E = 'Game::Shogi::Engine';
my $N = 'Game::Shogi::Notation';
binmode Test::More->builder->$_, ':encoding(UTF-8)' for qw(output failure_output todo_output);

# ---- replay equals live play --------------------------------------------------------------
#
# A log is the start and the USI moves. Replayed, it must reach the same
# position and the same result as the game that was played.

{
    srand(20261015);
    my ($games, $bad, $plies, $ended) = (0, 0, 0, 0);
    while ($games < 100) {
        my $b = $E->new;
        my @moves;
        for (1 .. 150) {
            last if $b->outcome;
            my @legal = $b->legal;
            my $m = $legal[ int rand @legal ];
            push @moves, $m;
            $b->do_move($m);
        }
        my ($final, $result) = $N->replay(undef, @moves);
        my $live = $b->outcome;
        $bad++ unless $final->sfen eq $b->sfen;
        $bad++ unless (defined $result) == (defined $live);
        $bad++ if $result && $live && ($result->how ne $live->how || ($result->winner // '') ne ($live->winner // ''));
        $ended++ if $live;
        $plies += @moves;
        $games++;
    }
    is($bad, 0, "$games random games, $plies plies: replay reaches the same position and result");
    cmp_ok($ended, '>', 0, "  $ended of them ended, so results were compared, not just positions");
}

# ---- the record ------------------------------------------------------------------------------

{
    my @moves = qw(7g7f 3c3d 8h2b+ 3a2b B*4e);
    my $log = $N->record(undef, @moves);
    is_deeply([ map { $_->{usi} } @{ $log->{moves} } ], \@moves, 'a record keeps the USI moves');
    is_deeply([ map { $_->{side} } @{ $log->{moves} } ], [qw(b w b w b)], '  and whose they were');
    is_deeply([ map { $_->{hodges} } @{ $log->{moves} } ], [ 'P-7f', 'P-3d', 'Bx2b+', 'Sx2b', 'B*4e' ],
        '  in Hodges');
    is_deeply([ map { $_->{japanese} } @{ $log->{moves} } ], [ '▲７六歩', '△３四歩', '▲２二角成', '△同銀', '▲４五角' ],
        '  and in Japanese, with 同 for the recapture');
    is($log->{start}, 'lnsgkgsnl/1r5b1/ppppppppp/9/9/9/PPPPPPPPP/1B5R1/LNSGKGSNL b - 1', '  the standard start when none is given');
    is($log->{sfen}, ($N->replay(undef, @moves))[0]->sfen, '  and its end is the replay\'s');
    is($log->{result}, undef, '  with no result while the game goes on');
}

# ---- refusals ------------------------------------------------------------------------------

{
    ok(!eval { $N->replay(undef, qw(7g7f 7g7e)); 1 }, 'a log with an illegal move does not replay');
    like($@, qr/move 2 \('7g7e'\) is not legal: there is no piece of yours there/, '  and says which move and why');
    ok(!eval { $N->record(undef, qw(7g7f x)); 1 }, 'nor does it record');
    like($@, qr/move 2 \('x'\) is not legal: that is not a move/, '  and says so');

    my $mated = '4k4/9/4P4/9/9/9/9/9/4K4 b G 1';
    my ($b, $r) = $N->replay($mated, 'G*5b');
    is($r && $r->how, 'mate', 'a replay that ends in mate hands back the result');
    ok(!eval { $N->replay($mated, 'G*5b', '5a4a'); 1 }, 'and a move after the end is refused');
    like($@, qr/move 2 /, '  naming the move');
}

done_testing();
