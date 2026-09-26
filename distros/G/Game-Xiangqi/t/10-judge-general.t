use strict;
use warnings;
use Test::More;

use Game::Xiangqi::Engine ':all';
my $E = 'Game::Xiangqi::Engine';

# THE JUDGE RULES ON A SEQUENCE, which is the only thing that can be a draw in
# this game: `outcome` has no draw value at all, and every draw xiangqi has is a
# property of a run of moves.
#
# This file covers Section 2's four principles and the general rules 1 to 14,
# plus CXQ's three automatic draws. Section 3's chase table is t/11.

sub pt { $E->point_of(@_) }
sub setup {
    my $b = $E->new(empty => 1);
    $b->put(pt($_->[0], $_->[1]), $_->[2]) for @_;
    return $b;
}

# Drive a position with two move-choosing callbacks and return the log.
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

# the perpetual-check position: red's chariot on rank 1 swings onto whichever
# file black's general is on, and the general has nowhere but the other square
sub perpetual_check_board {
    return setup([4, 9, BLACK | GENERAL], [3, 1, RED | CHARIOT],
                 [0, 8, RED | CHARIOT],   [5, 0, RED | GENERAL]);
}
sub swing_to_general {
    my ($g, $legal) = @_;
    my $f = $E->file_of($g->find(BLACK | GENERAL));
    my ($mv) = grep { $E->rank_of($E->move_from($_)) == 1
                   && $E->rank_of($E->move_to($_)) == 1
                   && $E->file_of($E->move_to($_)) == $f } @$legal;
    return $mv;
}
sub move_the_general {
    my ($g, $legal) = @_;
    my ($mv) = grep { $E->move_from($_) == $g->find(BLACK | GENERAL) } @$legal;
    return $mv;
}

subtest 'perpetual check loses, which is Asian Rules 6' => sub {
    my $b = perpetual_check_board();
    my @log = drive($b, 16, \&swing_to_general, \&move_the_general);
    is(scalar @log, 16, 'sixteen plies of it');

    my $v = $b->judge(\@log);
    is($v->{winner}, BLACK,             'BLACK wins');
    is($v->{reason}, J_PERPETUAL_CHECK, '  by perpetual check');
    is($v->{rule},   6,                 '  and the ruling cites rule 6');
    is($v->{red},    BEH_CHECK,         'red was perpetually checking');
    is($v->{black},  BEH_NONE,          'and black was doing nothing wrong');
    cmp_ok($v->{red_run}, '>=', 6, 'red checked at least CXQ-s six times in a row');

    # the loop really is a loop
    cmp_ok($v->{loop_from}, '>=', 0, 'a repeated position was found');
    is($v->{loop_len} % 2, 0, '  and the loop is a whole number of rounds');
};

# CXQ'S THRESHOLD IS THE `WHEN` THE ASIAN RULES LEAVE TO A REFEREE, so it has to
# be tested as a threshold and not just as a direction. "CXQ allows a player to
# check/chase 6 consecutive times using one piece ... before considering the
# check/chase a perpetual check/chase."
subtest 'the ruling waits for CXQ-s sixth check, and not before' => sub {
    my $b = perpetual_check_board();
    my @full = drive($b, 16, \&swing_to_general, \&move_the_general);

    my @short = @full[0 .. 7];          # four red checks
    my $v = $b->judge(\@short);
    is($v->{red_run}, 4, 'four checks so far');
    is($v->{winner}, 0, '  and nobody has lost yet');
    is($v->{reason}, J_ONGOING, '  the game is simply going on');

    my @at_six = @full[0 .. 11];        # six red checks
    my $w = $b->judge(\@at_six);
    is($w->{red_run}, 6, 'six checks');
    is($w->{winner}, BLACK, '  and now red has lost');
    is($w->{rule}, 6, '  by rule 6');
};

subtest 'a normal opening is judged as nothing at all' => sub {
    my $b = $E->new;
    my @log;
    my $g = $b->clone;
    for (1 .. 20) {
        my @l = $g->legal;
        last unless @l;
        my $mv = $l[ (scalar(@log) * 7 + 3) % @l ];
        push @log, $mv;
        $g->do_move($mv);
    }
    my $v = $b->judge(\@log);
    is($v->{winner}, 0, 'nobody has won');
    is($v->{reason}, J_ONGOING, 'and the judge says so plainly');
    is($v->{rule}, 0, 'citing no rule');
};

# Section 2, principle 1: "When neither side violates the rules and both persist
# on not altering their moves. The game can be ruled as a draw."
subtest 'a loop with nobody in breach is a draw, which is principle 1' => sub {
    # two generals shuffling in their own palaces: no check, no chase, nothing
    my $b = setup([3, 0, RED | GENERAL], [5, 9, BLACK | GENERAL],
                  [0, 0, RED | CHARIOT], [8, 9, BLACK | CHARIOT]);
    my $shuffle = sub {
        my ($g, $legal) = @_;
        my $me = $g->side;
        my $gp = $g->find($me | GENERAL);
        my ($mv) = grep { $E->move_from($_) == $gp } @$legal;
        return $mv;
    };
    my @log = drive($b, 12, $shuffle, $shuffle);
    cmp_ok(scalar @log, '>=', 8, 'a dozen quiet plies');

    my $v = $b->judge(\@log);
    is($v->{red},   BEH_NONE, 'red is in breach of nothing');
    is($v->{black}, BEH_NONE, 'and neither is black');
    is($v->{winner}, 0, 'so nobody wins');
    ok($v->{reason} == J_NO_VIOLATION || $v->{reason} == J_ONGOING,
        'and it is either a principle-1 draw or simply still going');
    is($v->{rule}, 5, 'citing rule 5 when it draws') if $v->{reason} == J_NO_VIOLATION;
};

# THE THREE COUNTERS ARE CXQ'S AND NOT THE ASIAN RULES', and the rules page has
# to say so. They exist because the Asian Rules are written for a referee and
# there is not one here.
subtest 'CXQ-s progress counter, 30 moves each with nothing happening' => sub {
    my $b = setup([3, 0, RED | GENERAL], [5, 9, BLACK | GENERAL],
                  [0, 0, RED | CHARIOT], [8, 9, BLACK | CHARIOT]);
    my $shuffle = sub {
        my ($g, $legal) = @_;
        my $gp = $g->find($g->side | GENERAL);
        my ($mv) = grep { $E->move_from($_) == $gp } @$legal;
        return $mv;
    };
    my @log = drive($b, 70, $shuffle, $shuffle);
    cmp_ok(scalar @log, '>=', 62, 'over thirty moves each');

    my $v = $b->judge(\@log);
    cmp_ok($v->{progress}, '>=', 30, 'the progress counter has run out');
    is($v->{winner}, 0, 'and it is a draw');
    ok($v->{reason} == J_PROGRESS || $v->{reason} == J_NO_VIOLATION,
        'by the progress counter or by principle 1, both of which are draws');
};

subtest 'the counters do not fire while pieces are being taken' => sub {
    my $b = $E->new;
    my @log;
    my $g = $b->clone;
    for (1 .. 30) {
        my @l = $g->legal;
        last unless @l;
        # prefer a capture, so progress keeps resetting
        my ($cap) = grep { $g->at($E->move_to($_)) != EMPTY } @l;
        my $mv = $cap // $l[ (scalar(@log) * 5) % @l ];
        push @log, $mv;
        $g->do_move($mv);
    }
    my $v = $b->judge(\@log);
    cmp_ok($v->{progress}, '<', 30, 'the progress counter keeps resetting');
    is($v->{winner}, 0, 'and nothing is ruled');
};

subtest 'the judge does not modify the position it is given' => sub {
    my $b = perpetual_check_board();
    my $fen = $b->to_fen;
    my $key = $b->key_hex;
    my @log = drive($b, 16, \&swing_to_general, \&move_the_general);
    $b->judge(\@log);
    $b->judge(\@log);
    is($b->to_fen, $fen, 'the board is untouched');
    is($b->key_hex, $key, 'and so is the key');
    is($b->side, RED, 'and the side to move');
};

subtest 'an empty log rules on nothing' => sub {
    my $b = $E->new;
    my $v = $b->judge([]);
    is($v->{winner}, 0, 'no winner');
    is($v->{reason}, J_ONGOING, 'no reason');
    is($v->{loop_from}, -1, 'and no loop');
};

done_testing();
