use strict;
use warnings;
use Test::More;

use Game::Xiangqi::Engine ':all';
my $E = 'Game::Xiangqi::Engine';

# THE NINE WORDS Chapter 4 Section 3's forty rules are written in, from the Asian
# Rules' own Section 1. Each subtest carries the source's sentence, because the
# point of this phase is that phase 06 reads as the source reads.
#
# NOTHING HERE RULES ON ANYTHING. No predicate returns "loses" or "draw".

sub pt { $E->point_of(@_) }
sub setup {
    my $b = $E->new(empty => 1);
    $b->put(pt($_->[0], $_->[1]), $_->[2]) for @_;
    return $b;
}
sub mv { $E->move(pt($_[0], $_[1]), pt($_[2], $_[3])) }

# "A move of any piece that causes the opponent's King to be threatened with
# capture in the next move."
subtest 'check' => sub {
    my $b = setup([4, 9, BLACK | GENERAL], [0, 4, RED | CHARIOT], [3, 0, RED | GENERAL]);
    ok($b->is_check(mv(0, 4, 4, 4)), 'a chariot swinging onto the general file checks');
    ok(!$b->is_check(mv(0, 4, 0, 5)), 'and sliding up its own file does not');
};

# "Check in such a way that the opponent's King cannot resolve the check."
subtest 'checkmate' => sub {
    my $b = $E->new(fen => '4k4/R8/9/9/3P5/9/9/9/3RCR3/3K5 w');
    my $m = mv(3, 5, 4, 5);       # the soldier steps across to become the screen
    ok($b->is_mate($m), 'the cannon mate is a mate');
    ok($b->is_check($m), '  and a mate is also a check');

    my $not = $E->new(fen => '4k4/R8/9/9/3P5/9/9/9/3RCR3/3K5 w');
    ok(!$not->is_mate(mv(0, 8, 0, 7)), 'a quiet chariot move is not');
};

# "Threatening to Checkmate (TTC) - A piece moves into a position where it can
# launch a sequence of attack that leads to checkmate."
#
# THE INTERPRETATION IS OURS AND THE NUMBER IS OURS: after the move, hand the
# turn straight back and ask for a mate in one, which is "I threaten mate next
# move". The plan said three plies; that is measured after a null move and would
# mean "I could mate in two if you never moved again", which is true of a large
# share of middlegame positions and would make the forty rules unusable.
subtest 'threatening to checkmate, and it is a threat and not a forced mate' => sub {
    # one move short of the cannon mate: red brings the chariot to rank 8, and
    # now threatens the soldier step that mates
    my $b = $E->new(fen => '4k4/9/9/9/3P5/9/9/9/3RCR3/3K5 w');
    $b->put(pt(0, 4), RED | CHARIOT);
    my $bring = mv(0, 4, 0, 8);
    ok($b->is_ttc($bring), 'Ra4-a8 threatens the mate that follows');
    ok(!$b->is_check($bring), '  and is not itself a check, which is the point');

    # a bare check that threatens nothing
    my $c = setup([4, 9, BLACK | GENERAL], [0, 4, RED | CHARIOT], [3, 0, RED | GENERAL]);
    my $chk = mv(0, 4, 4, 4);
    ok($c->is_check($chk), 'a lone chariot check IS a check');
    ok(!$c->is_ttc($chk), '  and is NOT a TTC: the general simply steps aside');

    # and a quiet move in the opening threatens nothing at all
    my $o = $E->new;
    my ($quiet) = grep { $o->is_idle($_) } $o->legal;
    ok(!$o->is_ttc($quiet), 'an opening move threatens no mate');
};

# "Chase - A piece moves to a position where it can capture an opponent's piece,
# which is not the King, in the next move."
subtest 'chase, and the victim it names' => sub {
    my $b = $E->new;
    # Cb2-e2 attacks the black soldier on e6 by jumping RED'S OWN soldier on e3.
    # A chase is a new attack by the SIDE and not by the moved piece alone, which
    # is what rules 25 and 26 of Section 3 require: they are explicit that a
    # chase happens when only the cannon's SCREEN moves.
    my ($is, $victim) = $b->is_chase(mv(1, 2, 4, 2));
    ok($is, 'Cb2-e2 is a chase');
    is($victim, pt(4, 6), '  and the victim is the soldier on e6');
    is($b->at($victim), BLACK | SOLDIER, '  which really is a black soldier');

    # the general is never a chase victim: that is check, a different word
    my $g = setup([4, 9, BLACK | GENERAL], [0, 4, RED | CHARIOT], [3, 0, RED | GENERAL]);
    my ($gis) = $g->is_chase(mv(0, 4, 4, 4));
    ok(!$gis, 'attacking the general is not a chase');

    # a move that attacks nothing new
    my ($nis) = $b->is_chase(mv(0, 3, 0, 4));
    ok(!$nis, 'a soldier stepping forward into an empty point attacks nothing new');
};

# "Exchange - Using piece A to capture the opponent's piece B and let the
# opponent take piece A ... Usually it is an exchange only when the value of A
# and B are similar."
#
# SIMILAR IS PINNED AT WITHIN ONE SOLDIER, 100 centi-soldiers, and that number is
# ours and not the source's.
subtest 'exchange, and the soft edge this phase pins' => sub {
    my $b = $E->new;
    ok($b->is_exchange(mv(1, 2, 1, 9)), 'cannon takes horse, and can be taken back');
    is($E->value_of(RED | CANNON) - $E->value_of(BLACK | HORSE), 50,
        '  cannon 450 and horse 400 are within one soldier');

    # a capture that is NOT an exchange because nothing can recapture
    my $free = setup([4, 4, RED | CHARIOT], [4, 6, BLACK | SOLDIER],
                     [3, 0, RED | GENERAL], [8, 9, BLACK | GENERAL]);
    ok(!$free->is_exchange(mv(4, 4, 4, 6)), 'taking a loose piece is not an exchange');

    # and one that is not, because the values are far apart
    my $uneven = setup([4, 4, RED | CHARIOT], [4, 6, BLACK | SOLDIER],
                       [4, 8, BLACK | CHARIOT],
                       [3, 0, RED | GENERAL], [8, 9, BLACK | GENERAL]);
    ok(!$uneven->is_exchange(mv(4, 4, 4, 6)),
        'a chariot taking a soldier it can be taken for is not an exchange');
    cmp_ok($E->value_of(RED | CHARIOT) - $E->value_of(BLACK | SOLDIER), '>', 100,
        '  because 900 against 100 is not similar');
};

# "Block - A piece moves to a position where it prevents the opponent from
# moving one of its pieces in certain direction."
subtest 'block, and the two things that are not one' => sub {
    my $b = $E->new;
    ok($b->is_block(mv(1, 2, 1, 3)), 'the cannon stepping up its own file blocks the black cannon');

    # A CAPTURE IS NOT A BLOCK. The taken piece loses all its moves, and a
    # destination-total comparison reported that as blocking.
    ok(!$b->is_block(mv(1, 2, 1, 9)), 'the cannon TAKING the horse is not a block');

    # RUNNING AWAY IS NOT A BLOCK EITHER, and this is the subtler one: a red
    # horse stepping off b0 removes a target the black cannon could jump to, so
    # black loses a destination because the mover LEFT.
    ok(!$b->is_block(mv(1, 0, 2, 2)), 'the horse stepping off b0 is not a block');
    ok(!$b->is_block(mv(1, 0, 0, 2)), '  in either direction');
};

# "Sacrifice - A piece moves to a position where it can be taken by the
# opponent."
subtest 'sacrifice' => sub {
    my $b = $E->new;
    ok($b->is_sacrifice(mv(1, 2, 1, 9)), 'the cannon lands where it can be taken');
    ok(!$b->is_sacrifice(mv(0, 3, 0, 4)), 'and a soldier stepping to a safe point does not');
};

# "Idle - A move that does not Check, TTC, Chase, Exchange, Block, or Sacrifice."
#
# WRITTEN AS EXACTLY THAT NEGATION and never as a list of its own, so a seventh
# word added to the vocabulary is excluded automatically.
subtest 'idle is the absence of the other six, and is asserted as such' => sub {
    my $b = $E->new;
    my ($idle, $busy) = (0, 0);
    for my $m ($b->legal) {
        my $other = $b->is_check($m) || $b->is_ttc($m) || scalar($b->is_chase($m))
                 || $b->is_exchange($m) || $b->is_block($m) || $b->is_sacrifice($m);
        if ($b->is_idle($m)) { $idle++; ok(!$other, 'an idle move does none of the six') if $idle <= 3 }
        else { $busy++; ok($other, 'and a non-idle move does at least one') if $busy <= 3 }
        # the real assertion: the two are exact complements, every move, no
        # exceptions. If they ever drift this is what says so.
        is($b->is_idle($m) ? 0 : 1, $other ? 1 : 0, 'idle is exactly the negation')
            if $idle + $busy <= 6;
    }
    cmp_ok($idle, '>', 0, "$idle of the 44 opening moves are idle");
    cmp_ok($busy, '>', 0, "and $busy are not");
    is($idle + $busy, 44, 'and every move is one or the other');
};

# THIS GUARD EXISTS BECAUSE THE SUBTEST ABOVE CANNOT CATCH THE BUG IT IS FOR,
# and that was MEASURED rather than reasoned: with `is_sacrifice` dropped from
# `is_idle`'s negation, the complement assertion over the opening passes.
#
# The reason is the familiar one. In the opening no move is ONLY a sacrifice
# (the two that sacrifice also chase and exchange), so a version that forgot
# sacrifice classifies all 44 moves exactly as before. A complement asserted
# over one position tests only the words that position happens to mix.
#
# So each word gets a position where a move does THAT AND NOTHING ELSE, found by
# sweeping the cited perft positions and then pinned here by FEN and move.
subtest 'a move that is ONLY one of the six is never idle' => sub {
    my @pure = (
        [ 'check',     'rheakaehr/9/1c5c1/p1p1p1p1p/9/9/P1P1P1P1P/1C5C1/9/RHEAKAEHR w',
                       undef ],   # replaced below; the opening has no pure check
        [ 'chase',     'rheakaehr/9/1c5c1/p1p1p1p1p/9/9/P1P1P1P1P/1C5C1/9/RHEAKAEHR w',
                       [1, 2, 0, 2] ],
        [ 'block',     'rheakaehr/9/1c5c1/p1p1p1p1p/9/9/P1P1P1P1P/1C5C1/9/RHEAKAEHR w',
                       [1, 2, 1, 3] ],
        [ 'sacrifice', 'rheakaehr/9/1c5c1/p1p1p1p1p/9/9/P1P1P1P1P/1C2C4/9/RHEAKAEHR b',
                       [4, 6, 4, 5] ],
        [ 'ttc',       '5a3/3k5/3aR4/9/5r3/5h3/9/3A1A3/5K3/2EC2E2 w',
                       [5, 1, 4, 1] ],
        [ 'check2',    '1ceak4/9/h2a5/2p1p3p/5cp2/2h2H3/6PCP/3AE4/2C2H3/3A1K3 b',
                       [1, 9, 1, 0] ],
    );
    my @names = qw(check ttc chase exchange block sacrifice);
    for my $case (@pure) {
        my ($why, $fen, $sq) = @$case;
        next unless $sq;
        my $b = $E->new(fen => $fen) or do { fail("$why: fen loads"); next };
        my $m = mv(@$sq);
        my @f = ($b->is_check($m), $b->is_ttc($m), scalar($b->is_chase($m)),
                 $b->is_exchange($m), $b->is_block($m), $b->is_sacrifice($m));
        my @on = grep { $f[$_] } 0 .. 5;
        is(scalar @on, 1, "$why: exactly one of the six holds");
        ok(!$b->is_idle($m), "  and the move is therefore NOT idle")
            or diag("$why: $fen  holds=" . join(',', @names[@on]));
    }

    # AND A PROPERTY RATHER THAN A FIXTURE, because no pure exchange exists to
    # find: `is_exchange` requires that the capturing piece can be taken back,
    # and that is exactly what `is_sacrifice` asks. Every exchange is a
    # sacrifice, so "exchange and nothing else" is unreachable by construction.
    my $b = $E->new;
    my $both = 0;
    for my $m ($b->legal) {
        next unless $b->is_exchange($m);
        $both++;
        ok($b->is_sacrifice($m), 'every exchange is also a sacrifice');
    }
    cmp_ok($both, '>', 0, "checked $both exchanges in the opening");
};

# "A piece is protected if there is a piece that can capture any piece that takes
# the protected piece." Plus the source's own distinction:
#   "Real protector  - when a protected piece is taken, the protector can
#                      actually remove the taker.
#    False protector - the protector cannot."
#
# Rule 34 of Section 3 turns on nothing else, which is why `real` is computed by
# PLAYING the capture and the recapture rather than from a static attack map.
subtest 'protected, and the real protector against the false one' => sub {
    # 1. A REAL PROTECTOR. The chariot on e9 defends the soldier on e5 down the
    #    file, and can take back.
    my $real = setup([3, 9, BLACK | GENERAL], [4, 9, BLACK | CHARIOT],
                     [4, 5, BLACK | SOLDIER], [4, 1, RED | CHARIOT],
                     [5, 0, RED | GENERAL]);
    my ($p1, $r1) = $real->protected_at(pt(4, 5));
    ok($p1, 'the soldier on e5 is protected');
    ok($r1, '  and by a REAL protector: the chariot takes back');

    # 2. A FALSE PROTECTOR. The black chariot on e5 defends the soldier on d5
    #    along the rank, and is PINNED against its own general by the red
    #    chariot on e1: recapturing would leave the general on e9 in check.
    #
    #    The first version of this fixture used the FLYING GENERAL for the pin,
    #    with the black chariot as the only piece between the two generals. It
    #    could not work: a chariot standing between two facing generals attacks
    #    both of them, so red was in check from the start and had no legal
    #    capture to answer. `real` came back 1 for the vacuous reason, which is
    #    the correct answer to a question the fixture was not asking.
    my $false = setup([4, 9, BLACK | GENERAL], [4, 5, BLACK | CHARIOT],
                      [3, 5, BLACK | SOLDIER], [4, 1, RED | CHARIOT],
                      [3, 1, RED | CHARIOT],   [5, 0, RED | GENERAL]);
    ok(!$false->in_check(RED) && !$false->in_check(BLACK),
        'neither side is in check, so the capture below is really available');
    my ($p2, $r2) = $false->protected_at(pt(3, 5));
    ok($p2, 'the soldier on d5 is protected on paper');
    ok(!$r2, '  but by a FALSE protector: the chariot is pinned and cannot take back');

    # 3. TWO PROTECTORS, ONE OF EACH. A black soldier on d6 also defends d5 and
    #    is not pinned, so the protection becomes real again.
    my $both = setup([4, 9, BLACK | GENERAL], [4, 5, BLACK | CHARIOT],
                     [3, 5, BLACK | SOLDIER], [3, 6, BLACK | SOLDIER],
                     [4, 1, RED | CHARIOT],   [3, 1, RED | CHARIOT],
                     [5, 0, RED | GENERAL]);
    my ($p3, $r3) = $both->protected_at(pt(3, 5));
    ok($p3, 'still protected');
    ok($r3, '  and now really so, because the soldier on d6 can take back');

    # 4. UNTESTED PROTECTION. Nothing can take it, so nothing has failed: a
    #    piece nobody attacks is not one whose protector has failed.
    my $quiet = setup([4, 9, BLACK | GENERAL], [3, 0, RED | GENERAL],
                      [0, 8, BLACK | CHARIOT], [0, 6, BLACK | SOLDIER]);
    my ($p4, $r4) = $quiet->protected_at(pt(0, 6));
    ok($p4, 'a defended piece nobody attacks is protected');
    ok($r4, '  and counts as real, because nothing has tested it');

    # and a piece with no defender at all
    my ($p5) = $quiet->protected_at(pt(0, 8));
    ok(!$p5, 'a piece with no defender is not protected');
};

subtest 'the predicates leave the board exactly as they found it' => sub {
    my $b = $E->new;
    my $fen = $b->to_fen;
    my $key = $b->key_hex;
    for my $m ($b->legal) {
        $b->is_check($m); $b->is_mate($m); $b->is_ttc($m);
        $b->is_chase($m); $b->is_exchange($m); $b->is_block($m);
        $b->is_sacrifice($m); $b->is_idle($m);
    }
    $b->protected_at($_) for $E->all_points;
    is($b->to_fen, $fen, 'the position is untouched');
    is($b->key_hex, $key, 'and so is the key, which put and lift both maintain');
    is($b->side, RED, 'and the side to move');
};

done_testing();
