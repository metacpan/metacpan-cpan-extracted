use strict;
use warnings;
use Test::More;
use lib 't/lib';

use Game::Xiangqi;
use Game::Xiangqi::Engine ':all';
use Game::Xiangqi::Notation;
use Game::Xiangqi::Error;
use Game::Xiangqi::Bot;
use Game::Xiangqi::Test::Handle;

# THE PURITY TEST, AND IT IS A TEST AND NOT A PROMISE.
#
# The engine runs inside a Hyperman worker, in the middle of the site's move
# transaction. A stray warn or print there goes to the server's log at whatever rate
# the site plays bot moves, and a read from STDIN blocks a worker for ever. Neither
# would be noticed by any other test in this suite: output nobody looks at is exactly
# what a passing run looks like.
#
# So STDOUT, STDERR and STDIN are all replaced by a handle that DIES on every
# operation, and then a whole game is played through the facade and the bot. If
# anything in Game::Xiangqi, ::Engine, ::Notation, ::Error or ::Bot reaches for a
# filehandle, the die names this file.
#
# Terminal.pm is deliberately NOT in that list: printing is its entire job, and it
# takes its handles as properties precisely so that it is the only part that does.

my $deaf = Game::Xiangqi::Test::Handle->deaf;

# Test::More dups its own output handles when it loads, so replacing these does not
# silence the test itself. Asserting that first, because a purity test that silenced
# its own results would report nothing and exit 0.
{
    my $ok = do {
        local *STDOUT = $deaf->fh;                   ## no critic
        local *STDERR = $deaf->fh;                   ## no critic
        eval { pass('Test::More still reports with STDOUT replaced'); 1 };
    };
    ok($ok, '  and did not die doing it')
        or diag("  if this failed the whole file proves nothing: $@");
}

sub silently (&) {
    my ($code) = @_;
    my @r;
    my $ok = eval {
        local *STDOUT = $deaf->fh;                   ## no critic
        local *STDERR = $deaf->fh;                   ## no critic
        local *STDIN  = $deaf->fh;                   ## no critic
        # A warn goes through $SIG{__WARN__} if one is set, so clear it: otherwise a
        # handler installed by the harness would catch the warning and the deaf
        # handle would never see it.
        local $SIG{__WARN__} = sub { die "something WARNED: $_[0]" };
        @r = $code->();
        1;
    };
    return ($ok, $@, @r);
}

subtest 'a whole game, played with every handle deaf' => sub {
    my ($ok, $err, $plies, $status) = silently {
        my $g = Game::Xiangqi->new(seed => substr('no-io' . ('.' x 32), 0, 32), red => 'p1');
        my $bot = $g->bot;
        my $n = 0;
        while ($g->status eq 'active' && $n < 60) {
            my $mv = do { local $Game::Xiangqi::Bot::LEVEL = 400;
                          $bot->choose($g, $g->turn) };
            last unless defined $mv;
            my $refusal = $g->play($mv);
            die "the bot offered $mv and it was refused: $refusal" if $refusal;
            $n++;
        }
        return ($n, $g->status);
    };
    ok($ok, 'sixty plies of bot against bot, and nothing printed or read')
        or diag("  $err");
    cmp_ok($plies, '>', 0, "  ($plies plies played, game $status)");
};

subtest 'the noisy paths are silent too' => sub {
    # The paths most likely to carry a leftover debugging print: a refusal, a
    # replay, the judge ruling on a sequence, notation both ways, and a FEN that
    # cannot be parsed.
    my ($ok, $err) = silently {
        my $g = Game::Xiangqi->new(seed => 'q' x 32, red => 'p1');
        $g->play($_) for qw(zz99 a5a6 a6a5 e0d0 a0a9 b0d1 a3a2 a3b3 b2b3);
        $g->play('h2e2');
        $g->replay([ qw(h2e2 h9g7 b2e2) ]);        # the instance form
        Game::Xiangqi->replay(seed => 'q' x 32, moves => [ qw(h2e2 h9g7) ]);
        Game::Xiangqi->replay('an', 'odd', 'list');  # must refuse, not warn
        $g->result;
        $g->signature;
        $g->legal;

        my $E = 'Game::Xiangqi::Engine';
        my $N = 'Game::Xiangqi::Notation';
        my $b = $E->new;
        $N->iccs_of($_) for $b->legal;
        $N->wxf_of($b, $_) for $b->legal;
        $N->move_of_iccs('h2e2');
        $N->move_of_iccs('not a move');
        $E->of_fen('rubbish');
        $E->of_fen($b->to_fen);
        $b->judge([ map { $_ } ($b->legal)[0] ]);
        $b->evaluate;
        $b->search(1_000, 3);
        $b->search_to_depth(2, 100_000, 3);
        $b->perft(2);
        Game::Xiangqi::Error->message_for('in_check');
        Game::Xiangqi::Error->known('nonsense');
        Game::Xiangqi::Error->throw('in_check')->message;
        return 1;
    };
    ok($ok, 'refusals, replay, notation, the judge, the search and a bad FEN') or diag("  $err");
};

subtest 'and the deaf handle is not vacuous' => sub {
    # PROVE THE PROBE WORKS. A handle that quietly accepted writes would make every
    # assertion above pass on an engine that printed constantly, which is
    # `index_tests_that_lie`'s whole subject.
    my ($ok, $err) = silently { print "this must die\n"; 1 };
    ok(!$ok, 'a print dies');
    like($err, qr/something PRINTED/, '  and says so');

    my ($ok2, $err2) = silently { my $x = <STDIN>; 1 };
    ok(!$ok2, 'a read dies');
    like($err2, qr/READ A LINE/, '  and says so');

    my ($ok3, $err3) = silently { warn "noisy\n"; 1 };
    ok(!$ok3, 'a warn dies');
    like($err3, qr/something WARNED/, '  and says so');

    my ($ok4, $err4) = silently { printf "%s\n", 'x'; 1 };
    ok(!$ok4, 'a printf dies');
    like($err4, qr/PRINTF/, '  and says so');
};

done_testing();
