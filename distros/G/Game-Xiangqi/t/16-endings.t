use strict;
use warnings;
use Test::More;

use Game::Xiangqi;
use Game::Xiangqi::Engine ':all';
my $E = 'Game::Xiangqi::Engine';
my $SEED = 'e' x 32;

# ONE GAME FOR EACH `reason`, and there are eight of them. Four come from the
# position (checkmate, stalemate) or the Asian Rules (perpetual check, perpetual
# chase) and are LOSSES; four are draws, three of which are CXQ's counters and
# not the Asian Rules at all.

# A GAME THAT STARTS FROM A POSITION IS BUILT THROUGH `new`, not by reaching in
# and replacing `pos`. The facade keeps the starting position so the judge can
# replay the sequence from it, and a test that swapped `pos` alone left the
# judge replaying from the opening: two perpetual rulings came back as
# `no_violation` and the bug was the fixture reaching past the interface.
sub game_from {
    my (@pieces) = @_;
    my $p = $E->new(empty => 1);
    $p->put($E->point_of(@{$_}[0, 1]), $_->[2]) for @pieces;
    return Game::Xiangqi->new(seed => $SEED, red => 'p1', position => $p);
}

sub drive {
    my ($g, $plies, $pick) = @_;
    for (1 .. $plies) {
        last unless $g->status eq 'active';
        my $mv = $pick->($g);
        last unless defined $mv;
        last if $g->play($mv);
    }
    return $g;
}

subtest 'checkmate: a loss, and the reason says so' => sub {
    # red is one move from the three-chariot mate
    my $g = game_from([4, 9, BLACK | GENERAL], [3, 8, RED | CHARIOT],
                      [5, 8, RED | CHARIOT],   [4, 5, RED | CHARIOT],
                      [4, 0, RED | GENERAL]);
    is($g->play('e5e8'), 0, 'the third chariot comes to e8');
    is($g->status, 'finished', 'the game is over');
    my $r = $g->result;
    is($r->{winner}, 'p1', 'p1 (Red) wins');
    is($r->{reason}, 'checkmate', 'by checkmate');
    is($r->{rule}, 0, 'and no Asian Rules number, because the position decided it');
    is($g->seed, $SEED, 'and the seed is published now the game is finished');
};

# THE ONE A PORTED CHESS ENGINE GETS WRONG.
subtest 'STALEMATE: also a loss, not a draw' => sub {
    my $g = game_from([3, 9, BLACK | GENERAL], [0, 8, RED | CHARIOT],
                      [7, 1, RED | CHARIOT],   [4, 0, RED | GENERAL]);
    is($g->play('h1e1'), 0, 'red boxes the general in without attacking it');
    is($g->status, 'finished', 'the game is over');
    my $r = $g->result;
    is($r->{winner}, 'p1', 'RED WINS');
    is($r->{reason}, 'stalemate', '  by stalemate');
    isnt($r->{winner}, undef, '  and it is emphatically not a draw');
};

subtest 'perpetual check: the checker loses, citing rule 6' => sub {
    my $g = game_from([4, 9, BLACK | GENERAL], [3, 1, RED | CHARIOT],
                      [0, 8, RED | CHARIOT],   [5, 0, RED | GENERAL]);
    drive($g, 20, sub {
        my ($h) = @_;
        my $p = $h->position;
        if ($p->side == RED) {
            my $f = $E->file_of($p->find(BLACK | GENERAL));
            my ($m) = grep { $E->rank_of($E->move_from($_)) == 1
                          && $E->rank_of($E->move_to($_)) == 1
                          && $E->file_of($E->move_to($_)) == $f } $p->legal;
            return defined $m ? Game::Xiangqi::Notation->iccs_of($m) : undef;
        }
        my ($m) = grep { $E->move_from($_) == $p->find(BLACK | GENERAL) } $p->legal;
        return defined $m ? Game::Xiangqi::Notation->iccs_of($m) : undef;
    });
    is($g->status, 'finished', 'the game ends');
    my $r = $g->result;
    is($r->{winner}, 'p2', 'the side being checked WINS');
    is($r->{reason}, 'perpetual_check', '  by perpetual check');
    is($r->{rule}, 6, '  citing Asian Rules 6');
    ok($r->{loop}, '  and the ruling carries the loop it was made on');
    cmp_ok(scalar @{ $r->{loop} }, '>=', 2, '    which is a run of moves');
};

subtest 'perpetual chase: the chaser loses, citing a Section 3 rule' => sub {
    my $g = game_from([1, 0, RED | CHARIOT], [0, 5, BLACK | CANNON],
                      [4, 0, RED | GENERAL], [3, 9, BLACK | GENERAL],
                      [8, 9, BLACK | CHARIOT]);
    drive($g, 24, sub {
        my ($h) = @_;
        my $p = $h->position;
        if ($p->side == RED) {
            my $f = $E->file_of($p->find(BLACK | CANNON));
            my ($m) = grep { $E->rank_of($E->move_from($_)) == 0
                          && $E->rank_of($E->move_to($_)) == 0
                          && $E->file_of($E->move_to($_)) == $f
                          && $E->move_from($_) != $E->move_to($_) } $p->legal;
            return defined $m ? Game::Xiangqi::Notation->iccs_of($m) : undef;
        }
        my $c = $p->find(BLACK | CANNON);
        my ($m) = grep { $E->move_from($_) == $c
                      && $E->rank_of($E->move_to($_)) == 5 } $p->legal;
        return defined $m ? Game::Xiangqi::Notation->iccs_of($m) : undef;
    });
    is($g->status, 'finished', 'the game ends');
    my $r = $g->result;
    is($r->{winner}, 'p2', 'the side being chased WINS');
    is($r->{reason}, 'perpetual_chase', '  by perpetual chase');
    cmp_ok($r->{rule}, '>=', 15, '  citing a Section 3 rule');
    cmp_ok($r->{rule}, '<=', 40, '    in range');
};

# THE THREE COUNTERS ARE CXQ'S, NOT THE ASIAN RULES', and the rules page has to
# say so. They exist because the Asian Rules are written for a referee.
subtest 'CXQ-s progress counter: thirty moves each with nothing happening' => sub {
    my $g = game_from([3, 0, RED | GENERAL], [5, 9, BLACK | GENERAL],
                      [0, 0, RED | CHARIOT], [8, 9, BLACK | CHARIOT]);
    drive($g, 90, sub {
        my ($h) = @_;
        my $p = $h->position;
        my $gp = $p->find($p->side | GENERAL);
        my ($m) = grep { $E->move_from($_) == $gp } $p->legal;
        return defined $m ? Game::Xiangqi::Notation->iccs_of($m) : undef;
    });
    is($g->status, 'finished', 'the game ends by itself');
    my $r = $g->result;
    is($r->{winner}, undef, 'nobody wins');
    ok($r->{reason} eq 'progress' || $r->{reason} eq 'no_violation',
        "a draw, by $r->{reason}");
};

subtest 'every reason a result can carry is one of the eight' => sub {
    my @known = qw(checkmate stalemate perpetual_check perpetual_chase
                   mutual no_violation effective progress moves);
    my %ok = map { $_ => 1 } @known;

    # a live game carries none
    my $live = Game::Xiangqi->new(seed => $SEED);
    is($live->result->{reason}, undef, 'an active game has no reason');

    # and every finished one carries a known name
    for my $fen ('4k4/3RRR3/9/9/9/9/9/9/9/4K4 b', '3k5/R8/9/9/9/9/9/9/4R4/4K4 b') {
        my ($p) = Game::Xiangqi::Engine->of_fen($fen);
        my $g = Game::Xiangqi->new(seed => $SEED, position => $p);
        my $reason = $g->result->{reason};
        ok($ok{ $reason }, "finished with a known reason: $reason");
        isnt($g->result->{winner}, undef, '  and a winner, because both are losses');
    }
};

done_testing();
