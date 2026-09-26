use strict;
use warnings;
use Test::More;
use lib 't/lib';

use Game::Xiangqi::Engine ':all';
use Game::Xiangqi::Notation;
use Game::Xiangqi::Terminal;
use Game::Xiangqi::Test::Handle;

# THIS FILE TALKS TO OUR OWN UCCI MODE. Talking to somebody else's is xt/, because
# ElephantEye is LGPL-2.1 and therefore never vendored, and a suite that needed it
# to pass would not run anywhere. What is asserted here is that the protocol we
# speak is the protocol we say we speak.
#
# UCCI matters because of the oracle and not because of the GUIs: D1 leaves this
# dist with no pure-Perl board and D7 refuses a shadow generator, so an independent
# engine and the published perft ladder are the only two oracles there are.

my $E = 'Game::Xiangqi::Engine';
my $N = 'Game::Xiangqi::Notation';

sub speak {
    my (@lines) = @_;
    my $in  = Game::Xiangqi::Test::Handle->reader(@lines);
    my $out = Game::Xiangqi::Test::Handle->recorder;
    my $t = Game::Xiangqi::Terminal->new(in => $in->fh, out => $out->fh);
    my $status = $t->ucci;
    return ($out->text, $status);
}

subtest 'the handshake' => sub {
    my ($said, $status) = speak('ucci', 'isready', 'quit');
    is($status, 0, 'ucci returns 0, and returns at all');
    like($said, qr/^id name Game::Xiangqi/m, 'it names itself');
    like($said, qr/^ucciok$/m,  'ucciok ends the handshake');
    like($said, qr/^readyok$/m, 'isready is answered');
    like($said, qr/^bye$/m,     'and quit says bye');

    # THE ORDER MATTERS to a GUI: ucciok must come after the id and option lines.
    my @order = grep { /^(id name|ucciok|readyok)/ } split /\n/, $said;
    is($order[0], 'id name Game::Xiangqi ' . $Game::Xiangqi::VERSION, 'id first');
    is($order[-1], 'readyok', 'and readyok last, after ucciok');
};

subtest 'position startpos, and go nodes, give a legal bestmove' => sub {
    my ($said) = speak('position startpos', 'go nodes 2000', 'quit');
    my ($best) = $said =~ /^bestmove (\S+)$/m;
    ok($best, "it answered bestmove $best");

    my %legal = map { $N->iccs_of($_) => 1 } $E->new->legal;
    ok($legal{$best}, '  and it is one of the 44 legal opening moves');
};

subtest 'position with moves is followed, move by move' => sub {
    my ($said) = speak('position startpos moves h2e2 h9g7', 'go nodes 2000', 'quit');
    my ($best) = $said =~ /^bestmove (\S+)$/m;

    my $pos = $E->new;
    $pos->do_move($N->move_of_iccs($_)) for qw(h2e2 h9g7);
    my %legal = map { $N->iccs_of($_) => 1 } $pos->legal;
    ok($legal{$best}, "bestmove $best is legal in the position after two moves")
        or diag('  fen: ' . $pos->to_fen);

    # AND THE MOVES REALLY WERE APPLIED. Without this the test above would pass on
    # an engine that ignored `moves` entirely, because most opening moves stay legal.
    my %opening = map { $N->iccs_of($_) => 1 } $E->new->legal;
    ok($opening{'h2e2'}, 'h2e2 is legal at the opening');
    ok(!$legal{'h2e2'},  '  and is NOT legal after it has been played');
};

subtest 'position fen loads a position, in either letter convention' => sub {
    # The Chess Programming Wiki spells the horse h and the elephant e; the same
    # table posted to TalkChess spells them n and b after chess. An engine that
    # takes one cannot load half the oracles there are.
    for my $fen ('rnbakabnr/9/1c5c1/p1p1p1p1p/9/9/P1P1P1P1P/1C5C1/9/RNBAKABNR w',
                 'rheakaehr/9/1c5c1/p1p1p1p1p/9/9/P1P1P1P1P/1C5C1/9/RHEAKAEHR w') {
        my ($said) = speak("position fen $fen", 'go nodes 1500', 'quit');
        my ($best) = $said =~ /^bestmove (\S+)$/m;
        my %legal = map { $N->iccs_of($_) => 1 } $E->new->legal;
        ok($best && $legal{$best}, "loaded and answered from a FEN spelled "
                                 . ($fen =~ /rnb/ ? 'n/b' : 'h/e') . ": $best");
    }

    my ($refused) = speak('position fen not-a-fen', 'quit');
    like($refused, qr/info string position refused/, 'a junk FEN says so and does not die');
};

subtest 'go depth N searches to exactly that depth' => sub {
    # THIS IS WHY THE ABI GREW IN THIS PHASE. Two engines can only be compared at
    # EQUAL DEPTH, and a node budget cannot promise one: the same 40,000 nodes
    # reached depth 3 on half the positions of one measured game and depth 4 on the
    # other half. `go nodes` is this engine's own dial; `go depth` is the oracle's.
    for my $d (1 .. 4) {
        my (undef, undef, $depth) = $E->new->search_to_depth($d, 50_000_000, 0);
        is($depth, $d, "search_to_depth($d) reached exactly depth $d");
    }

    my ($said) = speak('position startpos', 'go depth 3', 'quit');
    my ($best) = $said =~ /^bestmove (\S+)$/m;
    my %legal = map { $N->iccs_of($_) => 1 } $E->new->legal;
    ok($best && $legal{$best}, "go depth 3 answered bestmove $best");
};

subtest 'an unknown command is ignored and never fatal' => sub {
    # The protocol's own rule, and the only way a newer GUI can talk to an older
    # engine. Every one of these is something a real GUI sends and this engine does
    # not implement, and the POD lists them rather than leaving them to be found.
    my ($said, $status) = speak(
        'ucci',
        'setoption name Hash value 64',
        'banmoves h2e2',
        'go ponder nodes 1000',
        'go time 1000 movestogo 10',
        'hello',
        '',
        '   ',
        'position startpos',
        'go nodes 1500',
        'quit',
    );
    is($status, 0, 'it survived all of that');
    like($said, qr/^bestmove \S+$/m, '  and still answered the command it knows');
};

subtest 'stop is accepted, because nothing is ever searching in the background' => sub {
    my ($said, $status) = speak('ucci', 'stop', 'isready', 'quit');
    is($status, 0, 'stop did not upset it');
    like($said, qr/^readyok$/m, '  and it was still listening afterwards');
};

subtest 'a position with no move answers nobestmove rather than nothing' => sub {
    # Red mated: general e0, black chariots e2, d1 and f1. A GUI that got silence
    # here would wait for ever, which is worse than being told there is no move.
    my ($said) = speak('position fen 4k4/9/9/9/9/9/9/4r4/3r1r3/4K4 w',
                       'go nodes 1000', 'quit');
    like($said, qr/^bestmove nobestmove$/m, 'nobestmove, and not an empty line');
};

done_testing();
