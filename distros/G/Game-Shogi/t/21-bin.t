use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";

use Game::Shogi::Bot;
use Game::Shogi::Terminal;
use Game::Shogi::Test::Handle;

sub run {
    my (@argv) = @_;
    my $stdin = ref $argv[0] eq 'ARRAY' ? shift @argv : ['quit'];
    my ($out, $err) = ('', '');
    open my $o, '>', \$out or die $!;
    open my $e, '>', \$err or die $!;
    $o->autoflush(1);
    $e->autoflush(1);
    my $in = Game::Shogi::Test::Handle->reader(@$stdin);
    my $status = do {
        local *STDOUT = $o;
        local *STDERR = $e;
        local *STDIN  = $in->fh;
        Game::Shogi::Terminal->run(@argv);
    };
    return { status => $status, out => $out, err => $err };
}

subtest '--help is status 0 and carries the exit legend' => sub {
    my $r = run('--help');
    is($r->{status}, 0, 'status 0');
    like($r->{out}, qr/usage: shogi/, 'usage on stdout');
    is($r->{err}, '', '  nothing on stderr');
    like($r->{out}, qr/0\s+you won, or the game drew, or you quit/, '  0 is a win, a draw or a quit');
    like($r->{out}, qr/1\s+you lost/, '  1 a loss');
    like($r->{out}, qr/2\s+a bad option/, '  2 a bad option');
    for my $opt (qw(--level --side --handicap --sfen --moves --seed --ascii --kanji-ranks --ansi --pick --usi)) {
        like($r->{out}, qr/\Q$opt\E/, "  $opt is documented");
    }
};

subtest 'a bad option is status 2' => sub {
    for my $argv ([ '--nonsense' ], [ 'stray' ], [ '--side', 'x' ], [ '--level', '-1' ],
                  [ '--handicap', 'queen' ], [ '--handicap', 'rook', '--sfen', '9/9/9/9/9/9/9/9/9 b - 1' ],
                  [ '--sfen', 'nonsense' ], [ '--moves', '7g7f,7g7f' ]) {
        my $r = run(@$argv);
        is($r->{status}, 2, "@$argv: status 2");
        like($r->{err}, qr/\S/, '  with a reason on stderr');
    }
    like(run('--handicap', 'queen')->{err}, qr/lance, bishop, rook/, 'an unknown handicap lists the handicaps');
    like(run('--moves', '7g7f 7g7f')->{err}, qr/--moves refused at '7g7f'/, 'a refused move is named');
};

subtest '--level: a rung, a budget, and the dead zone between' => sub {
    my @ladder = @Game::Shogi::Bot::LADDER;
    for my $n ($#ladder + 1, $ladder[0] - 1) {
        my $r = run('--level', $n);
        is($r->{status}, 2, "--level $n is refused");
        like($r->{err}, qr/neither a rung nor a budget: a rung is 0 to $#ladder, and a budget is $ladder[0] nodes or more/,
            '  naming both ranges');
    }
    for my $n (0, $#ladder, $ladder[0]) {
        is(run('--level', $n, '--no-pick')->{status}, 0, "--level $n is taken");
    }
};

subtest 'a typed game through run' => sub {
    my $r = run([ '7g7f', 'quit' ], '--no-pick', '--level', '0', '--ascii', '--seed', 't');
    is($r->{status}, 0, 'quit is 0');
    like($r->{out}, qr/the bot plays \S+ \([^)]+\)/, 'the bot replied');
    unlike($r->{out}, qr/[^\x00-\x7F]/, '--ascii writes ASCII');
    my $h = run([ 'quit' ], '--no-pick', '--handicap', 'rook', '--level', '0', '--ascii');
    like($h->{out}, qr/the bot plays/, 'under a handicap the bot, White, moves first');
    my $k = run([ 'quit' ], '--no-pick', '--kanji-ranks', '--sfen', '4k4/9/9/9/9/9/9/9/4K4 b - 1');
    like($k->{out}, qr/\xE4\xB8\x80\n/, '--kanji-ranks: rank a is the kanji one');
    my $m = run([ 'quit' ], '--no-pick', '--no-ansi', '--ascii', '--moves', '7g7f, 3c3d', '--side', 'b');
    like($m->{out}, qr/^   \.   \.   \.   \.   \.   \.   p   \.   \.  d$/m, '--moves replayed before the game');
};

subtest '--usi hands over to the protocol' => sub {
    my $r = run([ 'usi', 'position startpos', 'go nodes 400', 'quit' ], '--usi');
    is($r->{status}, 0, 'status 0');
    like($r->{out}, qr/\Aid name Game::Shogi /, 'it speaks USI');
    like($r->{out}, qr/^bestmove \S+$/m, '  and answers go');
    unlike($r->{out}, qr/   9   8/, '  and draws no board');
    my $l = run([ 'go', 'quit' ], '--usi', '--level', '0');
    like($l->{out}, qr/nodes 4\d\d /, '--level is the default budget of a go that names none');
};

subtest 'the program exits with the status run returns' => sub {
    my @perl = ($^X, (map { "-I$_" } qw(blib/lib blib/arch)), 'bin/shogi');
    my $null = $^O eq 'MSWin32' ? 'NUL' : '/dev/null';
    my $quiet = sub {
        open my $o, '>&', \*STDOUT or die $!;
        open my $i, '<&', \*STDIN or die $!;
        open my $e, '>&', \*STDERR or die $!;
        open STDOUT, '>', $null or die $!;
        open STDERR, '>', $null or die $!;
        open STDIN, '<', $null or die $!;
        my $status = system(@perl, @_);
        open STDOUT, '>&', $o or die $!;
        open STDERR, '>&', $e or die $!;
        open STDIN, '<&', $i or die $!;
        return $status >> 8;
    };
    is($quiet->('--help'), 0, 'bin/shogi --help exits 0');
    is($quiet->('--level', '5'), 2, 'bin/shogi --level 5 exits 2');
};

done_testing;
