use strict;
use warnings;
use Test::More;
use lib 't/lib';

use Game::Xiangqi::Bot;
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

    for my $opt (qw(--level --red --seat --seed --fen --moves --wxf --ascii --ansi
                    --pick --ucci)) {
        like($r->{out}, qr/\Q$opt\E/, "  and $opt is documented");
    }
};

subtest 'colour and the picker can both be turned OFF from the command line' => sub {
    # 0.02 SHIPPED `ansi` WITHOUT THE BANG, so Getopt::Long took --ansi and refused
    # --no-ansi, and the only way to reach the uncoloured board the Terminal has
    # always been able to draw was to set NO_COLOR in the environment. An option
    # that can only be turned on is half an option.
    for my $off (qw(--no-ansi --noansi --no-pick --nopick)) {
        my $r = run($off);
        is($r->{status}, 0, "$off is taken");
        is($r->{err}, '', "  and says nothing on stderr");
    }

    # AND OFF REALLY MEANS OFF, which the status alone does not show.
    my $plain = run('--no-ansi');
    unlike($plain->{out}, qr/\e\[/, '--no-ansi really drew no escapes');
    my $lit = run('--ansi');
    like($lit->{out}, qr/\e\[/, '  while --ansi drew them');

    # --no-pick leaves the typed prompt, which is the one a pipe can answer.
    like(run('--no-pick')->{out}, qr/a move is ICCS/, '--no-pick offers typing');
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

    # THE DEAD ZONE BETWEEN THE TWO PUBLIC NUMBERS. The ladder has four rungs, so
    # 0 to 3 are rungs and the smallest honest budget is the bottom rung's own; a
    # number in between is neither, and 0.02 read it as a budget of four nodes
    # without saying so. Clamping or guessing hides WHICH of the two numbers the
    # caller got wrong, which is the trap Game::Durak shipped in its own --level.
    my @ladder = @Game::Xiangqi::Bot::LADDER;
    cmp_ok(scalar @ladder, '<', $ladder[0],
           'there really is a gap between the last rung and the first budget');

    for my $dead (scalar @ladder, $ladder[0] - 1) {
        my $r = run('--level', $dead);
        is($r->{status}, 2, "--level $dead is refused rather than guessed at");
        like($r->{err}, qr/neither a rung nor a budget/, '  and said which it needs');
        like($r->{err}, qr/\b0 to @{[ $#ladder ]}\b/, '  naming the rung range');
        like($r->{err}, qr/\b$ladder[0] nodes or more\b/, '  and the budget floor');
    }

    is(run('--level', $#ladder)->{status}, 0, 'the last rung is still a rung');
    is(run('--level', $ladder[0])->{status}, 0, 'and the floor is still a budget');
};

subtest '--ucci speaks the protocol and draws nothing' => sub {
    my $r = run([ 'ucci', 'isready', 'quit' ], '--ucci');
    is($r->{status}, 0, 'status 0');
    like($r->{out}, qr/^ucciok$/m,  'ucciok');
    like($r->{out}, qr/^readyok$/m, 'readyok');
    unlike($r->{out}, qr/a move is ICCS/, 'and it drew no board and printed no help');
};

done_testing();
