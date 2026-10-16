use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";

use Game::Shogi::USI;
use Game::Shogi::Test::Handle;

my $U = 'Game::Shogi::USI';

sub session {
    my (@lines) = @_;
    my $in  = Game::Shogi::Test::Handle->reader(@lines);
    my $out = Game::Shogi::Test::Handle->recorder;
    my $status = $U->new(in => $in->fh, out => $out->fh)->run;
    return ($status, [ split /\n/, $out->text ]);
}

subtest 'a session from usi to bestmove' => sub {
    my ($status, $out) = session('usi', 'isready', 'setoption name USI_Hash value 16', 'usinewgame',
        'position startpos moves 7g7f 3c3d', 'go nodes 2000', 'stop', 'gameover win', 'quit', 'isready');
    is($status, 0, 'run returns 0');
    is_deeply([ @$out[ 0 .. 3 ] ], [ "id name Game::Shogi $Game::Shogi::VERSION", 'id author LNATION', 'usiok', 'readyok' ],
        'usi names itself and ends with usiok; isready is readyok; setoption is ignored');
    like($out->[4], qr/\Ainfo depth [0-9]+ nodes [0-9]+ score (?:cp|mate) -?[0-9]+ pv (\S+)\z/, 'go: one info line');
    like($out->[5], qr/\Abestmove [1-9][a-i][1-9][a-i]\+?\z|\Abestmove [RBGSNLP]\*[1-9][a-i]\z/, '  then a bestmove');
    my ($pv) = $out->[4] =~ /pv (\S+)/;
    is($out->[5], "bestmove $pv", '  the same move');
    is(scalar @$out, 6, 'stop and gameover say nothing, and nothing is read after quit');
};

subtest 'position with a drop and a promotion' => sub {
    my $u = $U->new(in => Game::Shogi::Test::Handle->reader->fh, out => Game::Shogi::Test::Handle->recorder->fh);
    my $b = $u->position(qw(startpos moves 7g7f 3c3d 8h2b+ 3a2b B*4e));
    ok($b, 'the promotion 8h2b+ and the drop B*4e are taken');
    is($b->sfen, 'lnsgkg1nl/1r5s1/pppppp1pp/6p2/5B3/2P6/PP1PPPPPP/7R1/LNSGKGSNL w b 6', '  to the right position')
        or diag($b->sfen);
    my @hist = $b->history;
    is(scalar @hist, 5, '  and the board keeps the five positions before it, for the search');
    ok(!$u->position(qw(startpos moves 7g7f 7g7f)), 'an illegal move refuses the position');
    ok(!$u->position(qw(sfen nonsense b - 1)), 'a bad SFEN refuses it');
    ok(!$u->position(qw(fen x)), 'so does a word that is neither');
    my $s = $u->position(qw(sfen 4k4/9/9/9/9/9/9/9/4K4 b G 1 moves G*5b));
    is($s && $s->sfen, '4k4/4G4/9/9/9/9/9/9/4K4 w - 2', 'sfen with moves');
    my ($st, $out) = session('position startpos moves 7g7g', 'go nodes 400');
    is($out->[0], 'info string position refused: startpos moves 7g7g', 'a refused position is reported');
    like($out->[-1], qr/\Abestmove /, '  and the start is searched instead');
};

subtest 'bestmove win, bestmove resign, and a mate score in plies' => sub {
    my ($s1, $win) = session('position sfen RRBB1GGGG/4K1SS1/9/9/9/9/9/9/4k4 b 2P 1', 'go nodes 400');
    is_deeply($win, ['bestmove win'], 'a side that may declare answers bestmove win');
    my ($s2, $lost) = session('position sfen 4k4/9/9/9/9/9/4g4/4g4/4K4 b - 1', 'go nodes 400');
    is_deeply($lost, ['bestmove resign'], 'a side that is mated answers bestmove resign');
    my ($s3, $mate) = session('position sfen 4k4/9/4P4/9/9/9/9/9/4K4 b G 1', 'go nodes 4000');
    like($mate->[0], qr/ score mate 1 pv G\*5b\z/, 'a mate in one is mate 1 and G*5b');
    is($mate->[1], 'bestmove G*5b', '  played');
    my ($s4, $mated) = session('position sfen 4k4/9/4P4/9/9/9/9/9/4K4 b G 1 moves 5i5h', 'go nodes 4000');
    like($mated->[0], qr/ score (?:cp|mate) /, 'the other side gets a score too');
};

subtest 'go mate, depth, and the time controls' => sub {
    my ($s, $out) = session('go mate 1000');
    is_deeply($out, ['checkmate notimplemented'], 'go mate is not implemented, as U asks it to be said');
    my ($d, $deep) = session('go depth 1');
    like($deep->[0], qr/\Ainfo depth 1 /, 'go depth 1 stops at depth 1');
    my $u = $U->new(in => Game::Shogi::Test::Handle->reader->fh, out => Game::Shogi::Test::Handle->recorder->fh);
    is($u->budget(nodes => 1234), 1234, 'nodes is the budget');
    is($u->budget(depth => 5), 200_000_000, 'a depth alone is searched to the depth, under the ceiling');
    is($u->budget(depth => 5, nodes => 99), 99, '  unless nodes is given too');
    is($u->budget(depth => 5, byoyomi => 1000), 1_000_000, '  or a clock');
    is($u->budget(byoyomi => 1000), 1_000_000, 'a second of byoyomi is a million nodes');
    is($u->budget(btime => 40_000, wtime => 1), 1_000_000, 'Black\'s clock is read for Black: a fortieth');
    is($u->budget(btime => 40_000, binc => 500), 1_500_000, '  plus the increment');
    is($u->budget(movetime => 0, byoyomi => 0), 300_000, 'no time is the default budget');
    is($u->budget(byoyomi => 0.1), 400, 'never below the bottom rung');
    is($U->new(in => Game::Shogi::Test::Handle->reader->fh, out => Game::Shogi::Test::Handle->recorder->fh, nodes => 6000)->budget, 6000,
        'the constructor\'s nodes is the default');
    $u->command('position startpos moves 7g7f');
    is($u->budget(btime => 1, wtime => 40_000), 1_000_000, 'White\'s clock for White');
};

done_testing;
