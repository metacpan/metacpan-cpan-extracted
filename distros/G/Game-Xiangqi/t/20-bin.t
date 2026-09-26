use strict;
use warnings;
use Test::More;
use lib 't/lib';

use Game::Xiangqi::Test::Handle;

# REQUIRED, NOT SHELLED OUT. `bin/xiangqi` ends with `exit main(@ARGV) unless
# caller`, so loading it from a test defines `main` and runs nothing. A script that
# cannot be called as a function can only be tested through a pipe, which means
# every assertion in this file would be about a shell as well as about the program.
require './bin/xiangqi';

can_ok('main', 'main');

# Everything the program says, and the status it says it with.
sub run {
    my (@argv) = @_;
    my $stdin = ref $argv[0] eq 'ARRAY' ? shift @argv : ['quit'];
    my ($out, $err) = ('', '');
    open my $o, '>', \$out or die $!;
    open my $e, '>', \$err or die $!;
    $o->autoflush(1);
    $e->autoflush(1);
    my $in = Game::Xiangqi::Test::Handle->reader(@$stdin);

    my $status = do {
        local *STDOUT = $o;                          ## no critic
        local *STDERR = $e;                          ## no critic
        local *STDIN  = $in->fh;                     ## no critic
        main(@argv);
    };
    return { status => $status, out => $out, err => $err };
}

subtest '--help is status 0 and carries the exit legend' => sub {
    my $r = run('--help');
    is($r->{status}, 0, 'status 0');
    like($r->{out}, qr/usage: xiangqi/, 'usage on stdout');
    is($r->{err}, '', '  and nothing on stderr');

    # THE LEGEND IS IN THE HEREDOC, which is the house rule: a program whose exit
    # statuses are only in a test is a program nobody can script against.
    like($r->{out}, qr/exit status:/,           'the legend is there');
    like($r->{out}, qr/0\s+you won, or the game drew/, '  0 is a win or a draw');
    like($r->{out}, qr/1\s+you lost/,           '  1 is a loss');
    like($r->{out}, qr/2\s+a bad option/,       '  2 is a bad option');

    for my $opt (qw(--level --red --seat --seed --fen --moves --wxf --ascii --ansi --ucci)) {
        like($r->{out}, qr/\Q$opt\E/, "  and $opt is documented");
    }
};

subtest 'a bad option is status 2, on stderr, and never status 0' => sub {
    for my $bad (['--nope'], ['--level', 'abc'], ['extra-argument'],
                 ['--red', 'p3'], ['--seat', 'purple']) {
        my $r = run(@$bad);
        is($r->{status}, 2, "@$bad is status 2");
        isnt($r->{out} =~ /usage/ ? 'stdout' : 'stderr', 'stdout',
             '  and the usage went to stderr, not stdout');
    }
};

subtest 'a refused --fen and a refused --moves are both status 2' => sub {
    my $bad = run('--fen', 'this is not a fen');
    is($bad->{status}, 2, 'a junk FEN is refused');
    like($bad->{err}, qr/--fen refused, code \d+/, '  with the engine-s own code');

    # a9a5 is BLOCKED: the black chariot on a9 runs into its own soldier on a6.
    #
    # THE FIRST VERSION OF THIS LINE USED b7b3 AND THE ENGINE ACCEPTED IT, which is
    # right: a cannon SLIDES to an empty square like a chariot and only needs a
    # screen to capture, and b3 is empty at that point. The fixture was wrong, not
    # the engine, which is the same mistake every phase of this build has made at
    # least once.
    my $mv = run('--moves', 'h2e2,a9a5');
    is($mv->{status}, 2, 'an illegal move in --moves is refused');
    like($mv->{err}, qr/refused at 'a9a5'/, '  and named');

    my $ok = run('--moves', 'h2e2 h9g7');
    is($ok->{status}, 0, 'and two legal ones are played');
};

subtest 'a game already lost is status 1' => sub {
    # Red general on e0, black chariots on e2, d1 and f1: check from e2, both
    # escapes covered from the d and f files, nothing to interpose or take. The
    # facade settles a position that arrives already finished, so the program has a
    # verdict before it draws anything.
    my $r = run('--fen', '4k4/9/9/9/9/9/9/4r4/3r1r3/4K4 w', '--seat', 'p1');
    is($r->{status}, 1, 'the seat that is mated exits 1');
    like($r->{out}, qr/you lost/, '  and is told so');
};

subtest '--ascii draws no wide characters at all' => sub {
    my $r = run('--ascii');
    is($r->{status}, 0, 'status 0');
    unlike($r->{out}, qr/[^\x00-\x7F]/, 'every byte is ASCII');
    like($r->{out}, qr/R- H- E- A- K/, '  and rank 0 is FEN-s own letters');
};

subtest '--level takes a rung index or a budget outright' => sub {
    # A SMALL NUMBER IS A RUNG AND A BIG ONE IS A BUDGET. Nobody types 6000 when
    # they mean "level two", and nobody means "rung 6000".
    my $rung   = run('--level', '0');
    my $budget = run('--level', '2500');
    is($rung->{status},   0, 'rung 0 starts');
    is($budget->{status}, 0, 'and so does a raw budget');

    my $neg = run('--level', '-1');
    is($neg->{status}, 2, 'a negative level is refused');
};

subtest '--ucci speaks the protocol and draws nothing' => sub {
    my $r = run([ 'ucci', 'isready', 'quit' ], '--ucci');
    is($r->{status}, 0, 'status 0');
    like($r->{out}, qr/^ucciok$/m,  'ucciok');
    like($r->{out}, qr/^readyok$/m, 'readyok');
    unlike($r->{out}, qr/a move is ICCS/, 'and it drew no board and printed no help');
};

done_testing();
