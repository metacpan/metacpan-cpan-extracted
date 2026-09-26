use strict;
use warnings;
use Test::More;

use Game::Xiangqi;
use Game::Xiangqi::Engine ':all';
use Game::Xiangqi::Error;

my $SEED = 'z' x 32;

# A refusal is a Game::Xiangqi::Error and its `code` is the flag. This keeps the
# block below reading as a list of flags rather than one of accessor calls, and 0
# still means the move was played.
sub refused { my ($r) = @_; return ref $r ? $r->code : $r }

subtest 'the interface, and the house shape of it' => sub {
    can_ok('Game::Xiangqi', qw(new status turn legal play result replay signature position seed log));

    my $g = Game::Xiangqi->new(seed => $SEED, red => 'p1');
    ok($g, 'a game starts');
    is($g->status, 'active', 'active');
    is($g->turn, 'p1', 'and it is p1-s move, because p1 is Red and RED MOVES FIRST');
    is(scalar @{ $g->legal }, 44, 'with 44 legal moves');
    like($g->legal->[0], qr/\A[a-i][0-9][a-i][0-9]\z/, '  spelled in ICCS');
    like($g->signature, qr/\A[0-9a-f]{16}\z/, 'and a signature');

    my $other = Game::Xiangqi->new(seed => $SEED, red => 'p2');
    is($other->turn, 'p2', 'the seed decides which seat is Red, and Red still moves first');
};

# A BAD CONSTRUCTION DIES, AND A REFUSED MOVE DOES NOT. The two are different
# kinds of wrong: a seed of the wrong length is the caller's bug and is raised
# where it happens, while a refused move is an ordinary thing a player does and
# comes back as a Game::Xiangqi::Error.
subtest 'a seed of the wrong size is refused, and the game is not built' => sub {
    for my $case (['five bytes is not a seed',          [seed => 'short']],
                  ['and neither is none',               []],
                  ['nor a seat that does not exist',    [seed => $SEED, red => 'p3']]) {
        my ($name, $args) = @{$case};
        my $g = eval { Game::Xiangqi->new(@{$args}) };
        my $err = $@;
        is($g, undef, $name);
        like($err, qr/\AGame::Xiangqi: /, "  and it says why: $err");
    }
};

# THE SEED IS HELD AND NEVER READ. Xiangqi has no randomness in it at all. It is
# stored because the site publishes it when a game finishes so the game can be
# checked, and it must not leak before then.
subtest 'the seed is invisible while the game is on' => sub {
    my $g = Game::Xiangqi->new(seed => $SEED);
    is($g->seed, undef, 'no seed while active');
    $g->play($_) for @{ $g->legal }[0];
    is($g->seed, undef, '  still none after a move');

    my $done = Game::Xiangqi->new(seed => $SEED);
    $done->status('finished');        # set it, rather than play a whole game out
    is($done->seed, $SEED, 'and it is there once the game is finished');
};

# A REFUSAL IS RETURNED, NEVER THROWN, and it names the rule that was broken.
subtest 'every refusal name in @FLAGS is reachable' => sub {
    my %seen;

    my $g = Game::Xiangqi->new(seed => $SEED);
    $seen{ refused($g->play('zz99')) }   = 1;      # bad_move
    $seen{ refused($g->play('a5a6')) }   = 1;      # no_piece
    $seen{ refused($g->play('a6a5')) }   = 1;      # not_your_turn (a black soldier, Red to move)
    $seen{ refused($g->play('e0d0')) }   = 1;      # own_piece
    $seen{ refused($g->play('a0a9')) }   = 1;      # not_legal
    $seen{ refused($g->play('b0d1')) }   = 1;      # horse_leg_blocked
    $seen{ refused($g->play('a3a2')) }   = 1;      # soldier_no_retreat
    $seen{ refused($g->play('a3b3')) }   = 1;      # soldier_no_sideways
    $seen{ refused($g->play('b2b3')) }   = 1;      # a cannon that is not a legal slide

    # THE ONES THAT NEED A CONSTRUCTED POSITION, and a warning with them:
    # BOTH GENERALS MUST BE INSIDE THEIR OWN PALACES or the game is over before
    # the test starts. The first version of this block put the black general on
    # i9, which is not in any palace, so it had no legal move, so the position
    # was an instant stalemate and every later refusal came back `game_over`.
    my $build = sub {
        my $p = Game::Xiangqi::Engine->new(empty => 1);
        $p->put(Game::Xiangqi::Engine->point_of(@{$_}[0, 1]), $_->[2]) for @_;
        return Game::Xiangqi->new(seed => $SEED, position => $p);
    };

    {
        # f1 IS in the palace (it runs d to f), so the general has to be asked
        # to step off the side of it, not along it
        my $h = $build->([3, 1, RED | GENERAL], [4, 9, BLACK | GENERAL]);
        $seen{ refused($h->play('d1c1')) } = 1;    # general_leaves_palace
    }
    {
        my $h = $build->([4, 0, RED | GENERAL], [3, 0, RED | ADVISOR],
                         [4, 9, BLACK | GENERAL]);
        $seen{ refused($h->play('d0c1')) } = 1;    # advisor_leaves_palace
    }
    {
        my $h = $build->([4, 0, RED | GENERAL], [2, 4, RED | ELEPHANT],
                         [3, 9, BLACK | GENERAL]);
        $seen{ refused($h->play('c4e6')) } = 1;    # elephant_crosses_river
    }
    {
        my $h = $build->([4, 0, RED | GENERAL], [2, 0, RED | ELEPHANT],
                         [3, 1, BLACK | SOLDIER], [3, 9, BLACK | GENERAL]);
        $seen{ refused($h->play('c0e2')) } = 1;    # elephant_eye_blocked
    }
    {
        # A CANNON SLIDING TO AN EMPTY SQUARE IS A LEGAL MOVE whatever the
        # screens, so the refusal needs a CAPTURE with the wrong number of them.
        # Here: no screen at all between the cannon and the piece it is aimed at.
        my $h = $build->([4, 0, RED | GENERAL], [7, 2, RED | CANNON],
                         [7, 5, BLACK | CHARIOT], [3, 9, BLACK | GENERAL]);
        $seen{ refused($h->play('h2h5')) } = 1;    # cannon_needs_one_screen
    }
    {
        # in_check, and generals_face, which are the two the pseudo-legal list
        # tells apart
        my $h = $build->([4, 0, RED | GENERAL], [4, 9, BLACK | GENERAL],
                         [4, 5, RED | CHARIOT]);
        $seen{ refused($h->play('e5d5')) } = 1;    # generals_face

        my $k = $build->([4, 0, RED | GENERAL], [3, 9, BLACK | GENERAL],
                         [0, 0, BLACK | CHARIOT], [2, 0, RED | ADVISOR]);
        $seen{ refused($k->play('c0d1')) } = 1;    # in_check: moving the blocker
    }
    {
        my $h = Game::Xiangqi->new(seed => $SEED);
        $h->status('finished');
        $seen{ refused($h->play('h2e2')) } = 1;    # game_over
    }

    delete $seen{0};
    for my $flag (@Game::Xiangqi::Error::FLAGS) {
        ok($seen{$flag}, "reached the refusal '$flag'")
            or diag("  $flag: " . Game::Xiangqi::Error->message_for($flag));
    }

    # and every name that came back is a known one
    for my $got (sort keys %seen) {
        ok(Game::Xiangqi::Error->known($got), "'$got' is in \@FLAGS");
    }
};

subtest 'nothing throws, whatever it is handed' => sub {
    my $g = Game::Xiangqi->new(seed => $SEED);
    my @junk = ('', 'x', '0', 'a0a0', 'i9i9', 'e0e0', '99zz', 'h2e2h2e2');
    for my $j (@junk) {
        my $r = eval { $g->play($j) };
        ok(!$@, "play('$j') did not die");
        ok(defined $r, '  and returned something');
    }
    is($g->status, 'active', 'and the game is untouched by any of it');
};

subtest 'the turn alternates, and legal follows it' => sub {
    my $g = Game::Xiangqi->new(seed => $SEED);
    is($g->turn, 'p1', 'p1');
    is($g->play('h2e2'), 0, 'plays');
    is($g->turn, 'p2', 'then p2');
    is($g->play('h9g7'), 0, 'plays');
    is($g->turn, 'p1', 'and back');

    is(scalar @{ $g->log }, 2, 'the log has both moves');
    is_deeply($g->log, [ 'h2e2', 'h9g7' ], '  in ICCS, in order');
};

subtest 'result is empty while the game is on' => sub {
    my $g = Game::Xiangqi->new(seed => $SEED);
    my $r = $g->result;
    is($r->{winner}, undef, 'no winner');
    is($r->{reason}, undef, 'no reason');
    is($r->{rule}, 0, 'and no rule number');
};

done_testing();
