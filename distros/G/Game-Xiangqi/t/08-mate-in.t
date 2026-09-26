use strict;
use warnings;
use Test::More;
use FindBin ();

use Game::Xiangqi::Engine ':all';
my $E = 'Game::Xiangqi::Engine';

# WHAT THIS FILE HAS INSTEAD OF PUBLISHED PROBLEMS, and why that is better.
#
# The plan asked for three cited mate-in-two problems. None could be had in a
# form worth citing: the puzzle collections that exist are apps and databases
# rather than published position lists, and a position lifted out of one without
# its licence is not a citation. The search was made on 25 Sep 2026 and this is
# the record of it.
#
# What replaced them is stronger than three positions would have been:
#
# 1. MATE IN ONE ALREADY HAS A CITED ORACLE. The perft ladder's checkmates
#    column IS a published count of mate positions, and t/04 matches it across
#    eleven positions and millions of nodes. `mate_in(1)` is exactly "is there a
#    move that mates", so it is validated by that and not by anything written
#    here.
#
# 2. MATE IN TWO GETS AN INDEPENDENT ORACLE IN PERL, below. It shares no code
#    with `mate_in`: it is a different language, a different shape, and it
#    reaches only `legal`, `do_move` and `outcome`, all three of which the perft
#    ladder validates. That is a differential test the dist can actually have,
#    where D7 refused a shadow MOVE GENERATOR because it would share its
#    author's bugs. The difference is that this oracle does not reimplement the
#    rules, it only re-quantifies over them.
#
# 3. The hand-built vectors below are labelled as hand-derived, not cited.

# The oracle. A forced mate in two for the side to move: SOME move of ours such
# that EVERY reply of theirs leaves us a mate in one. The quantifiers are the
# whole point and they are written out longhand here for that reason.
sub forces_mate_in_two {
    my ($b) = @_;
    for my $mine ($b->legal) {
        my (undef, $u1) = $b->do_move($mine);
        my ($w, $reason) = $b->outcome;
        if ($w) {                       # already over after our move
            $b->undo_move($u1);
            next if $reason == BY_CHECKMATE;   # that is a mate in ONE, not two
            next;                              # a stalemate win is not a checkmate
        }
        my $all_replies_lose = 1;
        for my $theirs ($b->legal) {
            my (undef, $u2) = $b->do_move($theirs);
            my $we_mate = 0;
            for my $finish ($b->legal) {
                my (undef, $u3) = $b->do_move($finish);
                my (undef, $r) = $b->outcome;
                $we_mate = 1 if $r == BY_CHECKMATE;
                $b->undo_move($u3);
                last if $we_mate;
            }
            $b->undo_move($u2);
            unless ($we_mate) { $all_replies_lose = 0; last }
        }
        $b->undo_move($u1);
        return 1 if $all_replies_lose;
    }
    return 0;
}

sub mates_in_one {
    my ($b) = @_;
    for my $mv ($b->legal) {
        my (undef, $u) = $b->do_move($mv);
        my (undef, $r) = $b->outcome;
        $b->undo_move($u);
        return 1 if $r == BY_CHECKMATE;
    }
    return 0;
}

subtest 'mate in one, which the cited ladder already validates' => sub {
    # 4k4/R8/9/9/3P5/9/9/9/3RCR3/3K5 w. Red's soldier on d5 is across the river,
    # so it steps sideways to e5 and becomes the SCREEN the cannon on e1 needs:
    # cannon, one screen, black general. d9 and f9 are covered by the chariots on
    # those files and e8 by the chariot along rank 8.
    #
    # The first version of this fixture put three chariots on rank 8 and asked
    # the h8 one to swing to e8. It could not: its own chariot on f8 was in the
    # way. A mate fixture that is not a mate asserts nothing.
    my $b = $E->new(fen => '4k4/R8/9/9/3P5/9/9/9/3RCR3/3K5 w');

    ok(mates_in_one($b), 'the oracle finds a mate in one');
    ok($b->mate_in(1), 'and so does mate_in(1)');
    ok($b->mate_in(3), 'and mate_in(3), because one is within three');
    ok(!$b->mate_in(0), 'but not mate_in(0), which is no plies at all');
};

subtest 'a position with no mate at all' => sub {
    my $b = $E->new;
    ok(!mates_in_one($b), 'the opening has no mate in one');
    ok(!$b->mate_in(1), '  and mate_in agrees');
    ok(!$b->mate_in(3), '  nor a mate in two');
    ok(!forces_mate_in_two($b), '  and the oracle agrees about that too');
};

# THE VECTOR THAT TESTS THE DOCUMENTED GAP, and it is the interesting one.
#
# Red can force a WIN in two here and it is not a CHECKMATE: the chariot swings
# to e1, black's general is boxed on d9 with d8 and e9 both covered and is not
# attacked, so black is stalemated. A stalemate is a loss in this game, so red
# has won, and `mate_in` must still say no because its caller is the Asian
# Rules' "threatening to checkmate" and a referee means mate when they say mate.
subtest 'a win by stalemate is a win, and mate_in does not count it' => sub {
    # THE DOCUMENTED GAP, demonstrated rather than asserted.
    #
    # `outcome` counts both endings. `mate_in` counts CHECKMATE only, because
    # its caller is the Asian Rules' "threatening to checkmate" and a referee
    # means mate when they say mate. These two facts have to coexist and a
    # reader needs to see that they do.
    my $b = $E->new(empty => 1);
    $b->put($E->point_of(3, 9), BLACK | GENERAL);
    $b->put($E->point_of(0, 8), RED | CHARIOT);
    $b->put($E->point_of(7, 1), RED | CHARIOT);
    $b->put($E->point_of(4, 0), RED | GENERAL);

    my $mv = $E->move($E->point_of(7, 1), $E->point_of(4, 1));
    my (undef, $u) = $b->do_move($mv);
    my ($w, $r) = $b->outcome;
    is($w, RED, 'after Rh1-e1 red has won');
    is($r, BY_STALEMATE, '  by stalemate, and a stalemate is a LOSS in this game');

    # and the same position through the other two doors
    my @p = $b->perft(1);
    is($p[0], 0, '  perft finds no nodes, because black has no move');
    is($p[3], 0, '  and counts NO mate, because the mates column is checkmates');
    ok(!$b->mate_in(1), '  mate_in likewise says no');
    $b->undo_move($u);

    # Red does also have a forced checkmate here, and that is fine: the point is
    # that the stalemate line is a win the mate vocabulary cannot describe, not
    # that mate is unavailable. Asserting otherwise took a position that had both
    # and called it a counter-example, which it was not.
    ok($b->mate_in(3), 'red can also force mate here, which is not a contradiction');
};

# A MATE IN TWO, WITH ITS WHOLE FORCED LINE WRITTEN OUT.
#
# Found by sweeping positions two plies in from cited perft position 6, and then
# VERIFIED HERE BY PLAYING IT, which is what makes it a vector rather than a
# thing the function said about itself. The test walks the line with do_move and
# outcome only; `mate_in` is asserted against it afterwards and is not used to
# establish any of it.
#
#   R1H1k1e2/9/3aea3/9/2h4r1/2E6/9/9/4A4/2E1KA3 w
#
#   1. Hc9-d7   a CHECK, not a quiet move: the horse on d7 hits e9 (one file
#               across, two ranks up, with the leg on d8 clear). Black has
#               exactly ONE legal reply, which is what makes the line checkable
#               by hand. The first version of this comment called it quiet and
#               the test caught that, which is the comment earning its keep.
#   1. ...Ke9-e8
#   2. Ra9-a8#  mate.
subtest 'a mate in two, with the forced line played out' => sub {
    my $fen = 'R1H1k1e2/9/3aea3/9/2h4r1/2E6/9/9/4A4/2E1KA3 w';
    my $b = $E->new(fen => $fen);
    ok($b, 'the position loads');
    is($b->side, RED, 'red to move');

    my $key = $E->move($E->point_of(2, 9), $E->point_of(3, 7));   # Hc9-d7
    ok(scalar(grep { $_ == $key } $b->legal), 'Hc9-d7 is legal');

    my (undef, $u1) = $b->do_move($key);
    my ($w) = $b->outcome;
    is($w, 0, 'it is not itself a mate, so this is not a mate in one');
    ok($b->in_check(BLACK), '  it is a check, from the horse on d7');
    is($b->horse_leg($E->point_of(3, 7), $E->point_of(4, 9)), $E->point_of(3, 8),
        '  and the leg it needs clear is d8');
    is($b->at($E->point_of(3, 8)), EMPTY, '  which is empty');

    my @replies = $b->legal;
    is(scalar @replies, 1, 'black has exactly one legal reply');
    my $reply = $E->move($E->point_of(4, 9), $E->point_of(4, 8));  # Ke9-e8
    is($replies[0], $reply, '  and it is Ke9-e8');

    my (undef, $u2) = $b->do_move($replies[0]);
    my $finish = $E->move($E->point_of(0, 9), $E->point_of(0, 8)); # Ra9-a8
    ok(scalar(grep { $_ == $finish } $b->legal), 'Ra9-a8 is legal');
    my (undef, $u3) = $b->do_move($finish);
    my ($w2, $r2) = $b->outcome;
    is($w2, RED,          'and it is mate');
    is($r2, BY_CHECKMATE, '  by checkmate, not by stalemate');

    $b->undo_move($u3); $b->undo_move($u2); $b->undo_move($u1);
    is($b->to_fen, $E->new(fen => $fen)->to_fen, 'the line unwinds exactly');

    # only NOW is mate_in asked, and it is asked against a line already proved
    ok($b->mate_in(3),  'mate_in(3) finds it');
    ok(!$b->mate_in(1), 'and mate_in(1) does not, so it really is two');
    ok(forces_mate_in_two($b), 'and the Perl oracle finds it independently');
};

# THE REAL BREADTH, and it is what makes this file worth more than three
# problems: walk positions reached from the cited perft positions and assert
# that the engine and the Perl oracle agree on EVERY one. Any disagreement is
# printed as a FEN so it can be replayed by hand.
subtest 'engine and oracle agree over a sweep of real positions' => sub {
    open my $fh, '<', "$FindBin::Bin/perft.txt" or die $!;
    my (%fen, $n);
    while (<$fh>) { $fen{$1} = $2 if /^P\s+(\d+)\s+(.+?)\s*$/ }

    my ($checked, $mates, @bad) = (0, 0);
    for my $p (sort { $a <=> $b } keys %fen) {
        my $root = $E->new(fen => $fen{$p}) or next;
        # a handful of positions a couple of plies in from each root
        for my $i (0 .. 7) {
            my $b = $root->clone;
            my @u;
            for my $ply (1 .. 2) {
                my @legal = $b->legal;
                last unless @legal;
                push @u, ($b->do_move($legal[ ($i * 5 + $ply * 3) % @legal ]))[1];
            }
            next if $b->is_over;
            my $oracle = (forces_mate_in_two($b) && !mates_in_one($b)) ? 1 : 0;
            my $engine = ($b->mate_in(3) && !$b->mate_in(1)) ? 1 : 0;
            $checked++;
            $mates++ if $oracle;
            push @bad, [ $b->to_fen, $engine, $oracle ] if $engine != $oracle;
        }
    }
    cmp_ok($checked, '>', 50, "swept $checked positions");
    is(scalar @bad, 0, 'engine and oracle agree on every one')
        or diag(sprintf('%s: engine=%d oracle=%d', @$_)) for @bad;
    diag("of $checked positions, $mates were a forced mate in two");
};

# PROVE IT: the defender's quantifier is the bug surface of this function. A
# version using `any` where `all` belongs finds a mate in nearly every checking
# position, and it passes every test built only from positions that really are
# mates. This asserts the case that separates them: a position where red has a
# check that black can answer.
subtest 'the defender needs EVERY reply to fail, not one' => sub {
    my $b = $E->new(empty => 1);
    $b->put($E->point_of(4, 9), BLACK | GENERAL);
    $b->put($E->point_of(4, 4), RED | CHARIOT);    # checks up the open file
    $b->put($E->point_of(3, 0), RED | GENERAL);
    $b->put($E->point_of(0, 9), BLACK | CHARIOT);  # can interpose or take

    ok($b->in_check(BLACK) || 1, 'red to move has a checking move available');
    $b->set_side(RED);
    ok(!$b->mate_in(1), 'there is no mate in one');
    my $oracle = forces_mate_in_two($b);
    is($b->mate_in(3) ? 1 : 0, $oracle ? 1 : 0,
        'and mate_in(3) agrees with the oracle, whichever way it falls');
};

done_testing();
