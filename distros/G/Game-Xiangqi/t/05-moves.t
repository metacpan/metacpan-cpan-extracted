use strict;
use warnings;
use Test::More;

use Game::Xiangqi::Engine ':all';
my $E = 'Game::Xiangqi::Engine';

# HAND TABLES, not generated ones. The perft ladder in t/04 says the generator
# agrees with a published count; this file says WHICH RULE each part of it is
# implementing, so a failure names the rule instead of a number.

sub pt { $E->point_of(@_) }
# a list of [file, rank, piece]
sub setup {
    my $b = $E->new(empty => 1);
    $b->put(pt($_->[0], $_->[1]), $_->[2]) for @_;
    return $b;
}

sub dests {
    my ($b, $f, $r) = @_;
    my $from = pt($f, $r);
    my %seen;
    for my $mv ($b->moves) {
        next unless $E->move_from($mv) == $from;
        my $to = $E->move_to($mv);
        $seen{ sprintf('%s%d', ('a' .. 'i')[ $E->file_of($to) ], $E->rank_of($to)) } = 1;
    }
    return [ sort keys %seen ];
}

# ---- the horse, and its leg ---------------------------------------------------

subtest 'the horse has eight destinations and four legs' => sub {
    my $b = setup([4, 4, RED | HORSE], [4, 0, RED | GENERAL], [4, 9, BLACK | GENERAL]);
    is_deeply(dests($b, 4, 4),
        [ qw(c3 c5 d2 d6 f2 f6 g3 g5) ],
        'from the middle of an empty board, eight');

    # each leg blocked in turn. THE LEG IS THE ORTHOGONAL STEP, not a neighbour
    # of the destination: both readings agree for six of the eight and differ
    # for two, which is the shape of a bug that wins most of its games.
    my %leg = (
        'up'    => [ [4, 5], [qw(c3 c5 d2 f2 g3 g5)] ],
        'down'  => [ [4, 3], [qw(c3 c5 d6 f6 g3 g5)] ],
        'left'  => [ [3, 4], [qw(d2 d6 f2 f6 g3 g5)] ],
    );
    for my $why (sort keys %leg) {
        my ($at, $want) = @{ $leg{$why} };
        my $c = setup([4, 4, RED | HORSE], [4, 0, RED | GENERAL], [4, 9, BLACK | GENERAL],
                      [@$at, BLACK | SOLDIER]);
        is_deeply(dests($c, 4, 4), $want, "the $why leg blocked");
    }

    # a piece of EITHER colour blocks it
    my $own = setup([4, 4, RED | HORSE], [4, 0, RED | GENERAL], [4, 9, BLACK | GENERAL],
                    [4, 5, RED | SOLDIER]);
    is_deeply(dests($own, 4, 4), [ qw(c3 c5 d2 f2 g3 g5) ],
        'and its own soldier blocks it exactly as an enemy one does');

    is($b->horse_leg(pt(4, 4), pt(3, 6)), pt(4, 5), 'horse_leg names the point');
    is($b->horse_leg(pt(4, 4), pt(4, 5)), -1, 'and -1 when the target is not a horse move');
};

# ---- the elephant, its eye, and the river --------------------------------------

subtest 'the elephant has seven reachable points and never crosses the river' => sub {
    # walk every point an elephant can ever stand on for Red, from its two
    # starting points, and assert the closed-form seven.
    my %reach;
    my @queue = (pt(2, 0), pt(6, 0));
    $reach{$_} = 1 for @queue;
    while (my $from = shift @queue) {
        my $b = setup([ $E->file_of($from), $E->rank_of($from), RED | ELEPHANT ],
                      [4, 0, RED | GENERAL], [4, 9, BLACK | GENERAL]);
        for my $mv ($b->moves) {
            next unless $E->move_from($mv) == $from;
            my $to = $E->move_to($mv);
            next if $reach{$to}++;
            push @queue, $to;
        }
    }
    is(scalar keys %reach, 7, 'seven points, which is a closed-form fact about the rule');
    for my $p (keys %reach) {
        ok(!$E->crossed_river($p, RED), 'and not one of them is across the river');
    }

    my $b = setup([2, 0, RED | ELEPHANT], [4, 0, RED | GENERAL], [4, 9, BLACK | GENERAL]);
    is_deeply(dests($b, 2, 0), [ qw(a2 e2) ], 'from c0, two');

    my $eye = setup([2, 0, RED | ELEPHANT], [4, 0, RED | GENERAL], [4, 9, BLACK | GENERAL],
                    [3, 1, BLACK | SOLDIER]);
    is_deeply(dests($eye, 2, 0), [ qw(a2) ], 'the eye at d1 blocks the move to e2');
    is($b->elephant_eye(pt(2, 0), pt(4, 2)), pt(3, 1), 'elephant_eye names the point');
};

# ---- the cannon, and the row that gets written wrong ---------------------------

subtest 'the cannon moves like a chariot and takes only over one screen' => sub {
    my $b = setup([4, 0, RED | CANNON], [4, 9, BLACK | GENERAL], [3, 0, RED | GENERAL]);
    my $d = dests($b, 4, 0);
    ok(scalar(@$d) > 10, 'on an open board it slides like a chariot');
    ok(!grep({ $_ eq 'e9' } @$d), 'but it cannot reach the general with nothing between');

    # 0 screens and an occupied destination is NOT a move. This is the row that
    # gets written wrong, because a cannon shares the chariot's ray and the
    # instinct is to share its capture too.
    my $adj = setup([4, 0, RED | CANNON], [4, 1, BLACK | SOLDIER],
                    [3, 0, RED | GENERAL], [4, 9, BLACK | GENERAL]);
    ok(!grep({ $_ eq 'e1' } @{ dests($adj, 4, 0) }),
        'a cannon does not capture the piece next to it');
    is($adj->cannon_screens(pt(4, 0), pt(4, 1)), 0, '  because there are no screens between');

    # 1 screen and an enemy beyond it IS a capture
    my $jump = setup([4, 0, RED | CANNON], [4, 1, RED | SOLDIER], [4, 2, BLACK | CHARIOT],
                     [3, 0, RED | GENERAL], [4, 9, BLACK | GENERAL]);
    ok(grep({ $_ eq 'e2' } @{ dests($jump, 4, 0) }), 'over one screen it takes');
    is($jump->cannon_screens(pt(4, 0), pt(4, 2)), 1, '  exactly one screen between');
    ok(!grep({ $_ eq 'e1' } @{ dests($jump, 4, 0) }), '  and the screen itself is not a target');

    # 1 screen and its OWN piece beyond is nothing
    my $own = setup([4, 0, RED | CANNON], [4, 1, RED | SOLDIER], [4, 2, RED | CHARIOT],
                    [3, 0, RED | GENERAL], [4, 9, BLACK | GENERAL]);
    ok(!grep({ $_ eq 'e2' } @{ dests($own, 4, 0) }), 'over one screen onto its own piece, nothing');

    # 2 screens is nothing
    my $two = setup([4, 0, RED | CANNON], [4, 1, RED | SOLDIER], [4, 2, RED | SOLDIER],
                    [4, 3, BLACK | CHARIOT], [3, 0, RED | GENERAL], [4, 9, BLACK | GENERAL]);
    ok(!grep({ $_ eq 'e3' } @{ dests($two, 4, 0) }), 'over two screens, nothing');
    is($two->cannon_screens(pt(4, 0), pt(4, 3)), 2, '  and the count says why');

    is($b->cannon_screens(pt(4, 0), pt(5, 1)), -1, 'not on one rank or file at all');
};

# ---- the soldier ----------------------------------------------------------------

subtest 'the soldier goes forward, then sideways, and never back' => sub {
    my $home = setup([0, 3, RED | SOLDIER], [4, 0, RED | GENERAL], [4, 9, BLACK | GENERAL]);
    is_deeply(dests($home, 0, 3), [ 'a4' ], 'on its own side, forward only');

    my $over = setup([0, 5, RED | SOLDIER], [4, 0, RED | GENERAL], [4, 9, BLACK | GENERAL]);
    is_deeply(dests($over, 0, 5), [ qw(a6 b5) ], 'across the river, forward and sideways');

    my $last = setup([4, 9, RED | SOLDIER], [4, 0, RED | GENERAL], [8, 9, BLACK | GENERAL]);
    is_deeply(dests($last, 4, 9), [ qw(d9 f9) ],
        'on the enemy back rank it still moves sideways, which is a rule and not a dead end');

    # THE SIDE TO MOVE DECIDES WHAT IS GENERATED, and a fresh board is Red's.
    # Without this line the black soldier generates nothing at all and the
    # assertion below passes against an empty list for the wrong reason.
    my $black = setup([4, 6, BLACK | SOLDIER], [4, 0, RED | GENERAL], [4, 9, BLACK | GENERAL]);
    $black->set_side(BLACK);
    is_deeply(dests($black, 4, 6), [ 'e5' ], 'and Black goes the other way');

    ok(!$home->soldier_may(pt(0, 3), pt(0, 2)), 'never backward');
    ok(!$home->soldier_may(pt(0, 3), pt(1, 3)), 'and not sideways before the river');
    ok($over->soldier_may(pt(0, 5), pt(1, 5)),  'but sideways after it');
};

# ---- the general, the advisor, and the palace -----------------------------------

subtest 'the general and the advisor never leave the palace' => sub {
    my $g = setup([4, 1, RED | GENERAL], [8, 9, BLACK | GENERAL]);
    is_deeply(dests($g, 4, 1), [ qw(d1 e0 e2 f1) ], 'the general steps orthogonally inside it');

    my $corner = setup([3, 0, RED | GENERAL], [8, 9, BLACK | GENERAL]);
    is_deeply(dests($corner, 3, 0), [ qw(d1 e0) ], 'and the palace wall stops it');

    my $a = setup([4, 1, RED | ADVISOR], [4, 0, RED | GENERAL], [4, 9, BLACK | GENERAL]);
    is_deeply(dests($a, 4, 1), [ qw(d0 d2 f0 f2) ], 'the advisor moves diagonally inside it');

    my $ac = setup([3, 0, RED | ADVISOR], [5, 0, RED | GENERAL], [4, 9, BLACK | GENERAL]);
    is_deeply(dests($ac, 3, 0), [ 'e1' ], 'and from a corner it has one square');
};

# ---- the flying general ----------------------------------------------------------

subtest 'the flying general is an attack, so it costs nothing anywhere else' => sub {
    my $open = setup([4, 0, RED | GENERAL], [4, 9, BLACK | GENERAL]);
    ok($open->generals_face, 'on an open file the generals see each other');

    my $blocked = setup([4, 0, RED | GENERAL], [4, 9, BLACK | GENERAL], [4, 5, RED | SOLDIER]);
    ok(!$blocked->generals_face, 'one piece between and they do not');

    # a piece that steps OUT of the file cannot, because it would leave them facing
    my $b = setup([4, 0, RED | GENERAL], [4, 9, BLACK | GENERAL], [4, 5, RED | CHARIOT]);
    my @legal = $b->legal;
    my %to = map { $E->move_to($_) => 1 } grep { $E->move_from($_) == pt(4, 5) } @legal;
    ok(!$to{ pt(3, 5) }, 'the chariot may not step off the file and expose them');
    ok($to{ pt(4, 6) },  'but it may slide along it');

    # and a general that steps INTO an open file with the other cannot either
    my $side = setup([3, 0, RED | GENERAL], [4, 9, BLACK | GENERAL]);
    my %gto = map { $E->move_to($_) => 1 } grep { $E->move_from($_) == pt(3, 0) } $side->legal;
    ok(!$gto{ pt(4, 0) }, 'the general may not step onto the open file either');
    ok($gto{ pt(3, 1) },  'though it moves freely otherwise');

    # THE CAPTURE ITSELF IS NEVER GENERATED, because the position it needs is
    # one no legal move can produce.
    my $none = grep { $E->move_to($_) == pt(4, 9) && $E->move_from($_) == pt(4, 0) } $open->legal;
    is($none, 0, 'and the flying capture is never in a legal list');
};

# ---- the attack walk --------------------------------------------------------------

subtest 'attacked sees every piece that could take the point' => sub {
    my %case = (
        'a chariot down the file' => [ [4, 4, RED | CHARIOT], pt(4, 8), 1 ],
        'a chariot blocked'       => [ [4, 4, RED | CHARIOT], pt(4, 8), 0, [4, 6, BLACK | SOLDIER] ],
        'a cannon needs a screen' => [ [4, 4, RED | CANNON],  pt(4, 8), 0 ],
        'a cannon with one'       => [ [4, 4, RED | CANNON],  pt(4, 8), 1, [4, 6, BLACK | SOLDIER] ],
        'a horse with a clear leg'=> [ [4, 4, RED | HORSE],   pt(3, 6), 1 ],
        'a horse hobbled'         => [ [4, 4, RED | HORSE],   pt(3, 6), 0, [4, 5, BLACK | SOLDIER] ],
        'a soldier forward'       => [ [4, 4, RED | SOLDIER], pt(4, 5), 1 ],
        'a soldier not backward'  => [ [4, 4, RED | SOLDIER], pt(4, 3), 0 ],
        'a soldier not sideways at home' => [ [4, 3, RED | SOLDIER], pt(5, 3), 0 ],
        'a soldier sideways over' => [ [4, 5, RED | SOLDIER], pt(5, 5), 1 ],
    );
    for my $why (sort keys %case) {
        my ($piece, $target, $want, @extra) = @{ $case{$why} };
        my $b = setup($piece, [4, 0, RED | GENERAL], [8, 9, BLACK | GENERAL], @extra);
        is($b->attacked($target, RED) ? 1 : 0, $want, $why);
    }
};

subtest 'in_check is the attack walk pointed at a general' => sub {
    my $b = setup([4, 0, RED | GENERAL], [8, 9, BLACK | GENERAL], [4, 4, BLACK | CHARIOT]);
    ok($b->in_check(RED), 'a black chariot down the open file checks Red');
    ok(!$b->in_check(BLACK), 'and Black is not in check');

    my $safe = setup([4, 0, RED | GENERAL], [8, 9, BLACK | GENERAL], [4, 4, BLACK | CHARIOT],
                     [4, 2, RED | ADVISOR]);
    ok(!$safe->in_check(RED), 'blocking it ends the check');
};

subtest 'a legal move never leaves your own general attacked' => sub {
    # a pinned chariot: moving it off the file would expose the general
    my $b = setup([4, 0, RED | GENERAL], [8, 9, BLACK | GENERAL],
                  [4, 3, RED | CHARIOT], [4, 7, BLACK | CHARIOT]);
    my %to = map { $E->move_to($_) => 1 } grep { $E->move_from($_) == pt(4, 3) } $b->legal;
    ok(!$to{ pt(3, 3) }, 'the pinned chariot may not step aside');
    ok($to{ pt(4, 4) },  'but it may move along the pin');
    ok($to{ pt(4, 7) },  'and it may take the pinner');

    my $pseudo = grep { $E->move_from($_) == pt(4, 3) && $E->move_to($_) == pt(3, 3) } $b->moves;
    is($pseudo, 1, 'the pseudo-legal list still has it, which is what makes the filter a filter');
};

# The XSUBs under `moves` and `legal` are PPCODE and push their results onto the
# stack, so in scalar context they hand back THE LAST VALUE PUSHED and not a
# count. From the opening that reads 16437, a packed move that looks like an
# answer. Engine.pm wraps both so scalar context gives a count; this pins it,
# because the wrapper is one line and the failure it prevents is a test that
# passes for the wrong reason.
subtest 'scalar context gives a count, not the last move pushed' => sub {
    my $b = $E->new;
    my @list = $b->legal;
    is(scalar @list, 44, 'the opening has 44 legal moves');
    is(scalar($b->legal), 44, 'and scalar context says 44, not a packed move');
    is(scalar($b->moves), scalar(my @p = $b->moves), 'the same holds for the pseudo-legal list');

    my $mated = $E->new(fen => '4k4/3RRR3/9/9/9/9/9/9/9/4K4 b');
    is(scalar($mated->legal), 0, 'a mated position counts zero rather than returning undef');
    ok(defined scalar($mated->legal), '  and zero is DEFINED, which undef would not be');
};

done_testing();
