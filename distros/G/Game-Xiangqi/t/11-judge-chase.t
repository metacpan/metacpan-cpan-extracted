use strict;
use warnings;
use Test::More;

use Game::Xiangqi::Engine ':all';
my $E = 'Game::Xiangqi::Engine';

# SECTION 3'S CHASE TABLE, rules 15 to 40.
#
# THE COVERAGE IS COMPUTED, NOT CLAIMED. The table is enumerable through the
# ABI, so this file works out which of the forty rules are implemented and prints
# the ones that are not BY NUMBER. A hand-kept list in a comment rots the first
# time somebody adds a row; this cannot.

sub pt { $E->point_of(@_) }
sub setup {
    my $b = $E->new(empty => 1);
    $b->put(pt($_->[0], $_->[1]), $_->[2]) for @_;
    return $b;
}

# Drive a shuttle: each side plays the move the callback picks.
sub drive {
    my ($b, $plies, $red, $black) = @_;
    my $g = $b->clone;
    my @log;
    for my $i (1 .. $plies) {
        my @legal = $g->legal;
        last unless @legal;
        my $mv = ($g->side == RED ? $red : $black)->($g, \@legal);
        last unless defined $mv;
        push @log, $mv;
        $g->do_move($mv);
    }
    return @log;
}

subtest 'the table is enumerable, and every row carries its rule number' => sub {
    my $n = $E->rule_count;
    cmp_ok($n, '>', 10, "the chase table has $n rows");
    for my $i (0 .. $n - 1) {
        my $r = $E->rule_at($i);
        ok($r, "row $i is there");
        cmp_ok($r->{number}, '>=', 15, "  rule $r->{number} is in Section 3's range")
            if $r->{number};
        cmp_ok($r->{number}, '<=', 40, "  and not past it");
        ok(length $r->{text} > 20, '  and carries the source-s own sentence');
        ok($r->{verdict} >= 1 && $r->{verdict} <= 3, '  and a verdict');
    }
};

# THE HONEST MEASURE OF D2. The owner chose the full Asian Rules on repetition;
# this is the count of what that actually came to, computed from the table.
subtest 'which of rules 15 to 40 are implemented, and which are not' => sub {
    my %have = map { $_ => 1 } $E->rules_implemented;

    # RULED ELSEWHERE, NOT IN THE TABLE, each with the reason. These are not
    # gaps: the table is for chase rulings keyed on piece kinds, and these four
    # are decided in the general branch before the table is ever consulted.
    my %elsewhere = (
        26 => 'the same ruling as rule 15, and the same row: a cannon may not perpetually chase a chariot',
        38 => 'perpetual "check and capture" is a draw, ruled with the TTC branch',
        39 => 'perpetual block is a draw, ruled before the table',
        40 => 'perpetual exchange or sacrifice is a draw, ruled before the table',
    );

    my (@in, @out);
    for my $n (15 .. 40) {
        next if $elsewhere{$n};
        $have{$n} ? push(@in, $n) : push(@out, $n);
    }

    diag("IN THE TABLE (" . scalar(@in) . "): @in");
    diag("RULED ELSEWHERE (" . scalar(keys %elsewhere) . "): " . join(' ', sort { $a <=> $b } keys %elsewhere));
    diag("NOT RULED ON AT ALL (" . scalar(@out) . "): @out");

    cmp_ok(scalar @in, '>=', 15, 'at least fifteen rules are in the table itself');
    ok(!$have{$_}, "rule $_ is ruled elsewhere and not duplicated in the table")
        for sort { $a <=> $b } keys %elsewhere;

    # THE SIX THAT ARE NOT RULED ON AT ALL, AND THEY ARE NOT AN ACCIDENT. Each
    # turns on a positional fact a kind-pair table cannot express:
    #
    #   19  a chariot immobilised by an opponent's horse
    #   20  a cannon and a horse taking turns against a chariot
    #   22  a chariot and a horse chasing each other
    #   23  a chariot chasing a horse that chases back only once
    #   27  a chariot confined to a line by a cannon
    #   37  a chariot and general controlled by a rook and cannon
    #
    # Listed here so the gap is a number a reader can check rather than a
    # silence. The rules page must name them too.
    is_deeply(\@out, [ 19, 20, 22, 23, 27, 37 ],
        'the six unruled rules are exactly the six positional ones');
};

subtest 'rule 28: the general may chase, and rule 30 says not with a friend' => sub {
    my %have = map { $_ => 1 } $E->rules_implemented;
    ok($have{28}, 'rule 28 is in the table');
    ok($have{30}, 'and so is rule 30');

    my ($r28) = grep { $_->{number} == 28 }
                map { $E->rule_at($_) } 0 .. $E->rule_count - 1;
    is($r28->{chaser}, GENERAL, 'rule 28 is about the general');
    is($r28->{verdict}, 2, '  and it ALLOWS the chase');
    is($r28->{chasers}, 1, '  when it is chasing alone');

    my ($r30) = grep { $_->{number} == 30 && $_->{chaser} == GENERAL }
                map { $E->rule_at($_) } 0 .. $E->rule_count - 1;
    is($r30->{verdict}, 1, 'rule 30 FORBIDS it with another piece');
    is($r30->{chasers}, 2, '  which is what "two or more" means here');
};

subtest 'rules 17 and 18: the same chase, decided by protection' => sub {
    my @rows = map { $E->rule_at($_) } 0 .. $E->rule_count - 1;
    my ($r17) = grep { $_->{number} == 17 } @rows;
    my ($r18) = grep { $_->{number} == 18 } @rows;

    is($r17->{chaser}, CHARIOT, 'rule 17: chariot');
    is($r17->{victim}, CANNON,  '  chasing a cannon');
    is($r17->{protectedness}, 1, '  that is PROTECTED');
    is($r17->{verdict}, 2, '  is allowed');

    is($r18->{chaser}, CHARIOT, 'rule 18: chariot');
    is($r18->{victim}, CANNON,  '  chasing a cannon');
    is($r18->{protectedness}, 0, '  that is UNPROTECTED');
    is($r18->{verdict}, 1, '  is forbidden');

    # and the order matters: 17 and 18 must both come before the general row
    my @idx = map { my $n = $_; grep { $rows[$_]{number} == $n } 0 .. $#rows } (17, 18);
    my ($general) = grep { $rows[$_]{number} == 36 && $rows[$_]{chaser} == 0
                        && $rows[$_]{protectedness} == 1 } 0 .. $#rows;
    cmp_ok($_, '<', $general, 'the specific row comes before the general one') for @idx;
};

# Rule 15 is the one Wikipedia's summary gets wrong: it says a chase of an
# UNPROTECTED piece is forbidden, and rule 15 forbids chasing a chariot with a
# cannon EVEN IF THE CHARIOT IS PROTECTED.
subtest 'rule 15 contradicts the encyclopaedia summary, and the table follows the source' => sub {
    my @rows = map { $E->rule_at($_) } 0 .. $E->rule_count - 1;
    my ($r15) = grep { $_->{number} == 15 } @rows;
    is($r15->{chaser}, CANNON,  'cannon');
    is($r15->{victim}, CHARIOT, '  chasing a chariot');
    is($r15->{protectedness}, -1, '  WHATEVER its protection');
    is($r15->{verdict}, 1, '  is forbidden');
    like($r15->{text}, qr/even if the Rook is protected/,
        '  and the row carries the sentence that says so');
};

# A LIVE PERPETUAL CHASE, driven and judged. A red chariot shuttles between two
# files keeping an unprotected black cannon attacked; the cannon shuttles away
# and back. Rule 18: a rook may not perpetually chase an unprotected cannon.
subtest 'a chase that is forbidden, judged from a driven sequence' => sub {
    # THE GENERALS MUST NOT SHARE A FILE. The first version put them both on e,
    # so red was in check from the flying general and the chasing move was never
    # legal: the drive produced zero plies and the subtest asserted nothing.
    my $b = setup([1, 0, RED | CHARIOT], [0, 5, BLACK | CANNON],
                  [4, 0, RED | GENERAL], [3, 9, BLACK | GENERAL],
                  [8, 9, BLACK | CHARIOT]);
    ok(!$b->generals_face, 'the generals are on different files, so red is free to move');
    my $follow = sub {
        my ($g, $legal) = @_;
        my $c = $g->find(BLACK | CANNON);
        return undef unless $c;
        my $f = $E->file_of($c);
        my ($mv) = grep { $E->rank_of($E->move_from($_)) == 0
                       && $E->rank_of($E->move_to($_)) == 0
                       && $E->file_of($E->move_to($_)) == $f
                       && $E->move_from($_) != $E->move_to($_) } @$legal;
        return $mv;
    };
    my $run = sub {
        my ($g, $legal) = @_;
        my $c = $g->find(BLACK | CANNON);
        my ($mv) = grep { $E->move_from($_) == $c
                       && $E->rank_of($E->move_to($_)) == 5 } @$legal;
        return $mv;
    };
    my @log = drive($b, 20, $follow, $run);
    cmp_ok(scalar @log, '>=', 12, "drove " . scalar(@log) . " plies of it");

    my $v = $b->judge(\@log);
    diag(sprintf('red=%d black=%d run=%d rule=%d winner=%d reason=%d',
        @{$v}{qw(red black red_run rule winner reason)}));

    # whatever it rules, it must NOT rule that black is at fault: black is the
    # one being chased
    isnt($v->{winner}, RED, 'the chased side is never the one that loses');
    is($v->{red}, BEH_CHASE, 'red was perpetually chasing');
    is($v->{winner}, BLACK, '  so red loses');

    # THE EXACT NUMBER, and not merely "some Section 3 rule". The cannon here has
    # NO defender at all, so the citation is rule 18, a rook chasing an
    # unprotected cannon. Rule 34 is the neighbouring case (defended, but by a
    # protector that cannot recapture) and the two must not collapse: asserting
    # only `rule >= 15` let a version that cited 34 for everything pass.
    is($v->{rule}, 18, '  citing RULE 18, the unprotected cannon, and not rule 34');
    my ($p, $r) = $b->protected_at(pt(0, 5));
    ok(!$p, '  and the cannon really has no defender at all');
};

# RULE 34 IS THE ONE THE MUTATIONS FOUND NO TEST FOR, and it is not a small one:
# "a protected piece cannot be perpetually chased if its protector has lost its
# effectness". Removing the distinction between DEFENDED-BUT-FALSELY and
# UNDEFENDED left every other test in the dist green.
#
# The position: black's cannon on a5 is defended by the chariot on d5 along the
# rank, and that chariot is PINNED against its own general on d9 by the red
# chariot on d1. So the moment red actually takes the cannon, the recapture is
# illegal: a false protector, exactly as the source defines one.
subtest 'rule 34: chased through a protector that cannot recapture' => sub {
    my $b = setup([3, 9, BLACK | GENERAL], [3, 5, BLACK | CHARIOT],
                  [3, 1, RED | CHARIOT],   [0, 5, BLACK | CANNON],
                  [1, 0, RED | CHARIOT],   [4, 0, RED | GENERAL]);
    is($b->to_fen, '3k5/9/9/9/c2r5/9/9/9/3R5/1R2K4 w - - 0 1', 'the position is what it says');

    # AND A SUBTLETY WORTH THE LINE: in the starting position `protected_at`
    # reports real protection, because nothing can capture the cannon YET and an
    # untested protection is not a failed one. It becomes false the moment red's
    # chariot arrives, which is where the judge measures it.
    my ($p, $r) = $b->protected_at(pt(0, 5));
    ok($p, 'the cannon is defended');
    ok($r, '  and reads as really so while nothing attacks it');

    my $chase = sub {
        my ($g, $legal) = @_;
        my $f = $E->file_of($g->find(BLACK | CANNON));
        my ($mv) = grep { $E->rank_of($E->move_from($_)) == 0
                       && $E->rank_of($E->move_to($_)) == 0
                       && $E->file_of($E->move_to($_)) == $f
                       && $E->move_from($_) != $E->move_to($_)
                       && $E->file_of($E->move_from($_)) < 3 } @$legal;
        return $mv;
    };
    my $run = sub {
        my ($g, $legal) = @_;
        my $c = $g->find(BLACK | CANNON);
        my ($mv) = grep { $E->move_from($_) == $c
                       && $E->rank_of($E->move_to($_)) == 5 } @$legal;
        return $mv;
    };
    my @log = drive($b, 20, $chase, $run);
    cmp_ok(scalar @log, '>=', 12, "drove " . scalar(@log) . " plies");

    my $v = $b->judge(\@log);
    is($v->{red}, BEH_CHASE, 'red was perpetually chasing');
    is($v->{winner}, BLACK,  'and loses for it');
    is($v->{reason}, J_PERPETUAL_CHASE, '  by perpetual chase');
    is($v->{rule}, 34, '  citing RULE 34 and not the general unprotected rule');
};

subtest 'the judge cites a rule number whenever it rules on a chase' => sub {
    # a ruling with no number attached is one a player cannot check, and the
    # whole reason the site stores a log is that a game can be checked
    my @rows = map { $E->rule_at($_) } 0 .. $E->rule_count - 1;
    is(scalar(grep { !$_->{number} } @rows), 0, 'every row has a number');
    my %n;
    $n{ $_->{number} }++ for @rows;
    ok(scalar(keys %n) >= 12, scalar(keys %n) . ' distinct rules are covered');
};

done_testing();
