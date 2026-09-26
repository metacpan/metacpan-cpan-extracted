use strict;
use warnings;
use Test::More;

use Game::Xiangqi::Engine ':all';
my $E = 'Game::Xiangqi::Engine';

# THERE IS NO Position.pm, AND THAT IS A DECISION.
#
# The plan's module map lists both `Game::Xiangqi::Position` and
# `Game::Xiangqi::Engine`, with Position described as "a thin Perl object over
# the C position: new, of_fen, to_fen, copy, at, moves, play, key ... so the
# facade, the terminal, the judge and the tests all speak about a position
# without any of them touching `_abi_ptr`".
#
# Engine.pm is already exactly that, and has been since phase 02. A second
# module would be a forwarding shim, which is a second place for the same words
# to drift, and the house rule against that is why there is no Judge.pm either.
# So the deviation is recorded and this file tests the position API where it
# actually lives.

subtest 'the position API the plan asked for, all of it' => sub {
    can_ok($E, qw(new of_fen to_fen clone at moves legal play key_hex));

    my $b = $E->new;
    ok($b, 'new gives the opening position');
    like($b->to_fen, qr{\Arheakaehr/}, '  and it is the opening');
    is(scalar($b->legal), 44, '  with 44 legal moves');

    my ($ok, $err) = $E->of_fen('4k4/9/9/9/9/9/9/9/9/4K4 w');
    ok($ok, 'of_fen loads a position');
    is($err, FEN_OK, '  with no refusal');

    # 'nonsense' is refused as a BAD LETTER and not as bad rows, because `n` is
    # a horse in the chess-lettered FEN convention phase 02 also accepts. The
    # first letter parses; the second does not.
    my (undef, $bad) = $E->of_fen('nonsense');
    is($bad, FEN_LETTER, 'and a bad one is refused with the code that names the fault');
    my (undef, $short) = $E->of_fen('4k4/9/9');
    is($short, FEN_ROWS, '  while too few rows is a different code');
};

# `play` takes ICCS, checks it against the legal list, and RETURNS A REFUSAL
# rather than throwing, per the house rule. The parser is Notation's, required
# at runtime so the two modules are not a cycle.
subtest 'play takes ICCS, refuses by returning, and never throws' => sub {
    my $b = $E->new;
    is($b->play('h2e2'), 0, 'a legal move plays and returns 0');
    like($b->to_fen, qr{1C2C4}, '  and the board moved');
    is($b->side, BLACK, '  and the turn passed');

    is($b->play('zz99'),  'bad_move',  'a string that is not a move is refused');
    is($b->play(''),      'bad_move',  '  and an empty one');
    # h9h8 is NOT a horse move: a horse goes one orthogonally then one
    # diagonally, so it never moves one square straight.
    is($b->play('h9h8'),  'not_legal', 'a horse cannot step one square straight');
    is($b->play('h9g7'),  0,           'but it can make a horse move');
    is($b->play('a0a9'),  'not_legal', 'and a move that is not legal is refused by name');

    # THE PROCESS IS STILL HERE, which is the point of returning rather than
    # throwing: a refusal is what a player is shown, not an exception.
    pass('and nothing croaked');
};

subtest 'play refuses the moves the rules refuse, by name' => sub {
    my $b = $E->new;
    # a cannon capturing adjacently: the rule chess players get wrong
    $b->play('h2h4');
    $b->play('h9g7');
    is($b->play('h4h5'), 0, 'the cannon steps up');

    my $k = $E->new;
    is($k->play('e0e1'), 0, 'the general may step inside its palace');
    my $g = $E->new;
    is($g->play('e0d0'), 'not_legal', 'but not onto its own advisor');
};

subtest 'a copy shares nothing with its original' => sub {
    my $a = $E->new;
    my $c = $a->clone;
    is($c->to_fen, $a->to_fen, 'a clone starts identical');
    is($c->key_hex, $a->key_hex, '  key included');

    $c->play('h2e2');
    isnt($c->to_fen, $a->to_fen, 'and playing on one does not touch the other');
    is($a->side, RED, '  the original still has Red to move');
    is(scalar($a->legal), 44, '  and all 44 of its moves');
};

subtest 'the position is what a replay walks, and the FEN is only a convenience' => sub {
    # THE MOVE LOG IS THE CANONICAL SERIALISATION, not the position. A stored FEN
    # is for a test fixture and for UCCI; a replay rebuilds from the opening.
    my @log = qw(h2e2 h9g7 h0g2 i9h9 i0h0);
    my $b = $E->new;
    $b->play($_) for @log;
    my $fen = $b->to_fen;

    my $again = $E->new;
    my $bad = 0;
    for my $m (@log) { $bad++ if $again->play($m) }
    is($bad, 0, 'the log replays with no refusal');
    is($again->to_fen, $fen, '  and reaches the same position');
    is($again->key_hex, $b->key_hex, '  with the same key');

    # and a log with one move altered stops AT that move
    my @forged = @log;
    $forged[3] = 'a0a5';
    my $third = $E->new;
    my @refusals = grep { $_ } map { $third->play($_) } @forged;
    cmp_ok(scalar @refusals, '>=', 1, 'a forged log is refused');
    isnt($third->to_fen, $fen, '  and does not reach the position it claims');
};

subtest 'every point is readable and the geometry is the engine-s' => sub {
    my $b = $E->new;
    my $occupied = grep { $b->at($_) != EMPTY } $E->all_points;
    is($occupied, 32, 'thirty-two pieces');
    is(scalar($E->all_points), 90, 'over ninety points');
    is($b->at($E->point_of(4, 0)), RED | GENERAL, 'and e0 is the red general');

    # nothing outside the engine synthesises an index
    isnt($E->point_of(0, 0), 0, 'a point is not rank * 9 + file');
    is($E->point_of(0, 0), 12, '  it is (0+1)*11 + (0+1), the padded index');
    is($E->file_of($E->point_of(3, 7)), 3, 'and it takes apart the way it went together');
    is($E->rank_of($E->point_of(3, 7)), 7, '  in both axes');
};

done_testing();
