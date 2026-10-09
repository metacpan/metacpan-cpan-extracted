use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";

use Game::Brandubh::Engine qw(ATTACKERS DEFENDERS DID_CAPTURE);
use Game::Brandubh::Rules ':all';
use Game::Brandubh::Test::Squares qw(sq unwire);
my $R = 'Game::Brandubh::Rules';

my $SETUP = '3a3/3a3/3d3/aadkdaa/3d3/3a3/3a3 a';

# plays one move and insists it was taken
sub step {
    my ($g, $move) = @_;
    my ($answer, $flags) = $g->play(unwire($move));
    die "$move was refused ($answer) at ply " . $g->ply unless $answer == PLAY_OK;
    return $flags;
}

# Rule 12: "The game is drawn if a position is repeated". This distribution
# draws at the THIRD occurrence with the same side to move; `repeat => 2` is
# the sentence as written.

# four plies that bring the set-up back: an attacker out and home, a defender
# out and home
my @SHUFFLE = qw(a4a3 c4c3 a3a4 c3c4);

subtest 'the third occurrence draws, and not the second' => sub {
    my $g = $R->new;
    my @repeats = ($g->repeats);
    my @outcome = ($g->outcome);
    for my $round (1 .. 2) {
        for my $m (@SHUFFLE) {
            last if $g->is_over;
            step($g, $m);
            push @repeats, $g->repeats;
            push @outcome, $g->outcome;
        }
    }
    is($g->ply, 8, 'eight plies were played');
    is($g->position, $SETUP, 'and the board is the set-up again');
    is("@repeats", '1 1 1 1 2 2 2 2 3', 'the count of each position as it came round');
    is("@outcome[0 .. 7]", '0 0 0 0 0 0 0 0', 'the game was on at every ply before the last');
    is($outcome[4], ONGOING, 'in particular at ply 4, the SECOND time the set-up stood');
    is($outcome[8], DRAW_REPETITION, 'and drawn at ply 8, the third');
    ok($g->is_draw, 'it is a draw');
    is($g->winner, undef, 'with no winner');
    is(scalar($g->moves), 0, 'and no moves');
    is($g->play(unwire('a4a3')), PLAY_OVER, 'and it takes none');
};

subtest 'repeat => 2 is the sentence as written' => sub {
    my $g = $R->new(variant => { repeat => 2 });
    step($g, $_) for @SHUFFLE[0 .. 2];
    is($g->outcome, ONGOING, 'on at ply 3');
    step($g, $SHUFFLE[3]);
    is($g->ply, 4, 'at ply 4 the set-up stands for the second time');
    is($g->outcome, DRAW_REPETITION, 'and that is the draw');
};

subtest 'repeat => 4 waits one round more' => sub {
    my $g = $R->new(variant => { repeat => 4 });
    for my $round (1 .. 3) { step($g, $_) for @SHUFFLE }
    is($g->ply, 12, 'three rounds');
    is($g->repeats, 4, 'the fourth occurrence');
    is($g->outcome, DRAW_REPETITION, 'drawn');
    $g->undo;
    is($g->outcome, ONGOING, 'and not a ply sooner');
};

# The same squares with the other side to move is another position. Reached by
# an attacker taking two moves over a journey it then makes back in one.
subtest 'the same squares with the other side to move is not a repeat' => sub {
    my $g = $R->new;
    my $first = $g->key_hex;
    step($g, $_) for qw(a4a3 c4c3 a3a2 c3c4 a2a4);
    is($g->ply, 5, 'five plies');
    is(substr($g->position, 0, -2), substr($SETUP, 0, -2), 'every piece is where the set-up has it');
    is($g->side, DEFENDERS, 'but it is the defenders\' move, and the set-up is the attackers\'');
    isnt($g->key_hex, $first, 'so the key is another key');
    is($g->repeats, 1, 'and the position has occurred once');
};

# THE WINDOW. The engine counts back only as far as the last capture, since no
# position before a capture can come again. The position a capture MAKES can,
# so the ply of the capture is inside the window and must be counted.
subtest 'a position made by a capture can itself come round' => sub {
    my $g = $R->new(position => '7/d3a2/7/7/2ad3/6k/7 a');
    my $flags = step($g, 'e6e3');
    ok($flags & DID_CAPTURE, 'ply 1 captures');
    my $made = $g->position;
    is($g->repeats, 1, 'the position it made has occurred once');

    my @round = qw(a6a5 c3c2 a5a6 c2c3);
    step($g, $_) for @round;
    is($g->position, $made, 'four plies later it stands again');
    is($g->repeats, 2, 'for the second time, the first being the ply of the capture');
    is($g->outcome, ONGOING, 'the game is on');

    step($g, $_) for @round[0 .. 2];
    is($g->outcome, ONGOING, 'and on at ply 8');
    step($g, $round[3]);
    is($g->ply, 9, 'at ply 9');
    is($g->repeats, 3, 'it stands for the third');
    is($g->outcome, DRAW_REPETITION, 'and the game is drawn');
};

subtest 'a position from before a capture is never counted' => sub {
    my $g = $R->new(position => '7/d3a2/7/7/2ad3/6k/7 a');
    my $before = $g->key_hex;
    step($g, 'e6e3');
    my %seen;
    for my $round (1 .. 2) {
        for my $m (qw(a6a5 c3c2 a5a6 c2c3)) {
            last if $g->is_over;
            step($g, $m);
            $seen{ $g->key_hex }++;
        }
    }
    ok(!$seen{$before}, 'the position before the capture never came back, a piece being gone');
    is($g->key_at(0), $before, 'though the game still remembers it');
};

subtest 'undo, and the count goes back with it' => sub {
    my $g = $R->new;
    for my $round (1 .. 2) { step($g, $_) for @SHUFFLE }
    is($g->outcome, DRAW_REPETITION, 'drawn at ply 8');
    is($g->undo, 1, 'one move back');
    is($g->outcome, ONGOING, 'and the game is on');
    is($g->ply, 7, 'at ply 7');
    is($g->repeats, 2, 'in a position seen twice');
    is($g->key_at(8), undef, 'ply 8 is gone from the history');
    step($g, 'c3c4');
    is($g->outcome, DRAW_REPETITION, 'the same move draws it again');
    is($g->repeats, 3, 'at three');

    1 while $g->undo;
    is($g->ply, 0, 'all the way back');
    is($g->repeats, 1, 'the set-up has occurred once');
    is($g->position, $SETUP, 'and is the set-up');
};

subtest 'a different move breaks the count' => sub {
    my $g = $R->new;
    step($g, $_) for @SHUFFLE;
    step($g, $_) for qw(a4a3 c4c3 a3a4);
    is($g->repeats, 2, 'one ply from a third occurrence');
    step($g, 'c3c2');
    is($g->outcome, ONGOING, 'the defender goes elsewhere and the game is on');
    is($g->repeats, 1, 'in a position not seen before');
};

# THE CAP. Nothing in the rules ends a game the attackers have sealed, so it is
# drawn at ply_cap plies.
subtest 'the ply cap' => sub {
    my $g = $R->new(variant => { ply_cap => 3 });
    step($g, $_) for qw(a4a3 c4c3);
    is($g->outcome, ONGOING, 'on at ply 2 of 3');
    step($g, 'a3a2');
    is($g->ply, 3, 'at ply 3');
    is($g->outcome, DRAW_PLY_CAP, 'drawn by the cap');
    ok($g->is_draw, 'a draw');
    is($g->play(unwire('c3c4')), PLAY_OVER, 'and no fourth move');
    is($g->ply, 3, 'the ply does not pass the cap');
    $g->undo;
    is($g->outcome, ONGOING, 'undo takes the cap back too');
};

subtest 'repetition is asked before the cap' => sub {
    my $g = $R->new(variant => { repeat => 2, ply_cap => 4 });
    step($g, $_) for @SHUFFLE;
    is($g->ply, 4, 'ply 4 is both the second occurrence and the cap');
    is($g->outcome, DRAW_REPETITION, 'and it is reported as repetition');
};

# A whole game to the default cap, so that the arrays a game keeps are walked
# to their last slot. With the repeat put far out of reach the shuffle never
# draws, and a hundred rounds of four plies is exactly the cap.
subtest 'a game played to the default cap' => sub {
    my $g = $R->new(variant => { repeat => 4000 });
    my $rounds = 0;
    until ($g->is_over) {
        step($g, $_) for @SHUFFLE;
        $rounds++;
        last if $rounds > 200;
    }
    is($rounds, 100, 'a hundred rounds of the shuffle');
    is($g->ply, 400, 'four hundred plies');
    is($g->outcome, DRAW_PLY_CAP, 'and the cap ends it');
    is($g->repeats, 101, 'the set-up having stood a hundred and one times');
    ok(defined $g->key_at(400), 'a key is kept for the last ply');
    is($g->key_at(401), undef, 'and none beyond it');
    is($g->key_at(400), $g->key_at(0), 'the last being the first');
    is($g->play(unwire('a4a3')), PLAY_OVER, 'no ply 401');

    my $c = $g->clone;
    is($c->ply, 400, 'a clone of a full game is a full game');
    1 while $g->undo;
    is($g->position, $SETUP, 'undone the whole way to the set-up');
    is($g->ply, 0, 'at ply 0');
    is($c->ply, 400, 'and the clone did not move');
};

done_testing();
