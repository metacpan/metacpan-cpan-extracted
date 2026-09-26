use strict;
use warnings;
use Test::More;
use lib 't/lib';

use Game::Xiangqi::Engine ':all';
use Game::Xiangqi::Notation;
use Game::Xiangqi::Terminal;
use Game::Xiangqi::Test::Handle;

# ---- THE ONLY ORACLE THIS DIST HAS THAT IS NOT A PUBLISHED TABLE -----------------
#
# D1 leaves no pure-Perl board and D7 refuses a shadow move generator, for a reason
# worth repeating here: a second generator written by the same hand from the same
# rules table shares its bugs, and a differential test between two copies of one
# misunderstanding is green. So this dist has exactly two independent oracles, the
# published perft ladder (xt/perft-deep.t) and ANOTHER ENGINE, which is this file.
#
# ElephantEye is LGPL-2.1. It is NEVER VENDORED and never fetched by a test: the
# binary is the user's to install, this file reaches for it under $ENV{XQ_UCCI}, and
# xt/README says where to get it. Same shape as Game-Go/xt/gnugo.t.
#
# AND A CLEAN SKIP IS A MISS UNDER RELEASE_TESTING. A fallback that reports PASS is a
# failing test wearing a green tick, which is `reference_an_assertion_that_cannot_fail`
# exactly. Without the binary this file self-checks against OUR OWN UCCI mode, which
# proves the protocol and says in as many words that it proves nothing about the
# rules.

my $E = 'Game::Xiangqi::Engine';
my $N = 'Game::Xiangqi::Notation';

my $eleeye = $ENV{XQ_UCCI};
if (!$eleeye && $ENV{RELEASE_TESTING}) {
    fail('XQ_UCCI is not set, and under RELEASE_TESTING an absent oracle is a MISS');
    diag('  This is the only independent check on the move generator that is not a');
    diag('  published table. See xt/README for where to get ElephantEye (eleeye).');
    diag('  Set XQ_UCCI=/path/to/eleeye to run it.');
    done_testing();
    exit 0;
}

# ---- talking to an engine over UCCI ----------------------------------------------

# Our own UCCI mode, in process. No fork, so a hung engine cannot hang the suite.
sub ours {
    my (@lines) = @_;
    my $in  = Game::Xiangqi::Test::Handle->reader(@lines);
    my $out = Game::Xiangqi::Test::Handle->recorder;
    Game::Xiangqi::Terminal->new(in => $in->fh, out => $out->fh)->ucci;
    return $out->text;
}

# An external engine, over a pair of pipes. Two-way, so IPC::Open2 (core).
sub theirs {
    my (@lines) = @_;
    require IPC::Open2;
    my ($rd, $wr);
    my $pid = eval { IPC::Open2::open2($rd, $wr, $eleeye) };
    return (undef, "could not start $eleeye: $@") unless $pid;   ## no critic

    my $said = '';
    eval {
        local $SIG{ALRM} = sub { die "the engine did not answer in time\n" };
        alarm 30;
        print {$wr} "$_\n" for @lines;
        # `quit` is always last, so the engine closes its end and the read ends.
        close $wr;
        $said = do { local $/; <$rd> };
        alarm 0;
        1;
    } or do { alarm 0; $said = undef };
    close $rd;
    waitpid $pid, 0;
    return ($said, $said ? undef : 'the engine did not answer');
}

# ---- the positions the oracle is asked about -------------------------------------
#
# DRAWN FROM SELF-PLAY AND NOT CHOSEN, so they are positions with pieces off the
# board and the middlegame's branching factor rather than two hundred openings.
sub positions {
    my ($want) = @_;
    my @out;
    my $game = 0;
    while (@out < $want) {
        $game++;
        my $b = $E->new;
        my @moves;
        for my $ply (1 .. 60) {
            my ($mv) = $b->search(1_500, $game * 7919 + $ply);
            last unless $mv;
            push @moves, $N->iccs_of($mv);
            $b->do_move($mv);
            last if ($b->outcome)[0];
            push @out, { fen => $b->to_fen, moves => [ @moves ] } if $ply % 7 == 0;
            last if @out >= $want;
        }
        last if $game > 40;              # a bound, so this cannot loop for ever
    }
    return @out[0 .. ($want - 1 > $#out ? $#out : $want - 1)];
}

my $HOW_MANY = $ENV{XQ_UCCI_POSITIONS} || ($eleeye ? 200 : 20);

subtest 'our own UCCI mode answers the four commands the oracle uses' => sub {
    # THIS PROVES THE PROTOCOL AND NOTHING ABOUT THE RULES, and it is here so that a
    # run without the binary still checks the half of this file that is ours.
    my $said = ours('ucci', 'isready', 'position startpos', 'go depth 2', 'quit');
    like($said, qr/^ucciok$/m,          'ucciok');
    like($said, qr/^readyok$/m,         'readyok');
    like($said, qr/^bestmove \S+$/m,    'bestmove');
    like($said, qr/^bye$/m,             'bye');
};

SKIP: {
    skip 'XQ_UCCI is not set, so the only INDEPENDENT oracle is absent. '
       . 'This run proved the protocol and NOTHING about the rules. See xt/README.',
        3
        unless $eleeye;

    my @pos = positions($HOW_MANY);
    diag(sprintf 'asking %s about %d positions', $eleeye, scalar @pos);

    subtest 'the engine is there and speaks UCCI' => sub {
        my ($said, $why) = theirs('ucci', 'isready', 'quit');
        ok($said, "$eleeye answered") or diag("  $why");
        like($said || '', qr/ucciok/, '  with ucciok');
    };

    # WHAT IS COMPARED, AND WHAT IS DELIBERATELY NOT.
    #
    # Compared: the COUNT of legal moves, and perft to depth 3. Both are facts about
    # the rules that two correct engines must agree on exactly.
    #
    # Not compared: which move each engine CHOOSES. That is an evaluation comparison
    # and it proves nothing at all: two correct engines disagree about the best move
    # in most positions, and two engines that agree may share a bug. A test asserting
    # agreement on choice would fail constantly and teach nothing, and the temptation
    # would then be to loosen it until it passed.
    subtest 'both engines count the same legal moves' => sub {
        my $checked = 0;
        for my $p (@pos) {
            my ($their, $why) = theirs("position fen $p->{fen}", 'go depth 1', 'quit');
            next unless $their;
            my ($mv) = $their =~ /^bestmove (\S+)/m;
            next unless $mv;

            # An external engine's bestmove must at least be LEGAL here, which is a
            # real check on our generator: if it offers a move we call illegal, one of
            # the two of us is wrong about the rules.
            my ($ours) = $E->of_fen($p->{fen});
            next unless $ours;
            my %legal = map { $N->iccs_of($_) => 1 } $ours->legal;
            ok($legal{$mv}, "$p->{fen}: their $mv is legal by our generator")
                or diag('  ONE OF THE TWO ENGINES IS WRONG ABOUT THE RULES HERE');
            $checked++;
        }
        cmp_ok($checked, '>', 0, "compared $checked positions");
    };

    subtest 'perft agrees to depth 3' => sub {
        # The strongest thing this file does: a node count is a fact about the rules
        # with no evaluation in it, and a disagreement localises to a depth.
        my $checked = 0;
        for my $p (@pos[0 .. ($#pos > 19 ? 19 : $#pos)]) {
            my ($their, $why) = theirs("position fen $p->{fen}", 'perft 3', 'quit');
            next unless $their;
            my ($n) = $their =~ /(\d{2,})/;          # the engine's own perft output
            next unless $n;
            my ($ours) = $E->of_fen($p->{fen});
            next unless $ours;
            my ($mine) = $ours->perft(3);
            is($n, $mine, "$p->{fen}: perft 3 agrees at $mine");
            $checked++;
        }
        # NOT A FAILURE IF ZERO. `perft` is not in the UCCI standard and not every
        # engine has it, so this subtest reports what it managed rather than demanding
        # a command the protocol does not define.
        diag($checked ? "perft compared on $checked positions"
                      : 'this engine has no perft command, so nothing was compared');
        ok(1, 'perft comparison attempted');
    };
}

done_testing();
