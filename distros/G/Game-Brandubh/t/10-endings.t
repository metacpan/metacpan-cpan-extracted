use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";

use Game::Brandubh::Engine qw(ATTACKERS DEFENDERS ATTACKER KING KING_HOME KING_TAKEN DID_CAPTURE);
use Game::Brandubh::Rules ':all';
use Game::Brandubh::Test::Squares qw(sq name wire unwire);
my $R = 'Game::Brandubh::Rules';

sub game { $R->new(position => $_[0], ($_[1] ? (variant => $_[1]) : ())) }

# plays the moves and returns the game; dies if one is refused, so that a test
# cannot go on quietly after a move it thought it had made
sub played {
    my ($position, $variant, @moves) = @_;
    my $g = game($position, $variant);
    for my $m (@moves) {
        my $answer = $g->play(unwire($m));
        die "$m was refused ($answer) in $position" unless $answer == PLAY_OK;
    }
    return $g;
}

# The rules, from the source the documentation names:
#
#  11. "The king wins the game on reaching any of the marked corner squares.
#      The attackers win if they capture the king."
#  12. "The game is drawn if a position is repeated, if a player cannot move,
#      or if the players otherwise agree it."

subtest 'the set-up is a game that has not ended' => sub {
    my $g = $R->new;
    is($g->outcome, ONGOING, 'ongoing');
    ok(!$g->is_over, 'not over');
    ok(!$g->is_draw, 'not drawn');
    is($g->winner, undef, 'nobody has won');
    is($g->ply, 0, 'no move has been made');
    is($g->repeats, 1, 'the position has occurred once');
    is(scalar($g->moves), 40, 'forty moves');
    is($g->position, '3a3/3a3/3d3/aadkdaa/3d3/3a3/3a3 a', 'the set-up');
    is($g->side, ATTACKERS, 'the attackers to move');
    is($g->ply_cap, 400, 'the default cap');
};

subtest 'R11: the king wins on reaching a corner, each of the four' => sub {
    for my $case ([ '7/7/7/k6/7/7/3a3 d', 'a4a1' ], [ '7/7/7/k6/7/7/3a3 d', 'a4a7' ],
                  [ '7/7/7/6k/7/7/3a3 d', 'g4g1' ], [ '7/7/7/6k/7/7/3a3 d', 'g4g7' ]) {
        my ($position, $move) = @$case;
        my $g = game($position);
        is($g->outcome, ONGOING, "before $move the game is on");
        my ($answer, $flags) = $g->play(unwire($move));
        is($answer, PLAY_OK, "$move is played");
        ok($flags & KING_HOME, 'and reported as the king home');
        is($g->outcome, BY_CORNER, 'the game is won by a corner');
        is($g->winner, DEFENDERS, 'by the defenders');
        ok($g->is_over && !$g->is_draw, 'over, and not a draw');
    }
};

subtest 'R11: the attackers win by capturing the king, in each of his three places' => sub {
    for my $case (
        [ 'on the throne, four',        '3a3/7/7/2aka2/3a3/7/7 a', 'd7d5' ],
        [ 'beside the throne, three',   '1a5/7/2a4/2k4/2a4/7/7 a', 'b7b4' ],
        [ 'in the open, two',           '7/5ka/7/7/7/4a2/7 a',     'e2e6' ],
        [ 'beside a corner, one',       '7/7/2a4/7/7/7/1k5 a',     'c5c1' ],
    ) {
        my ($what, $position, $move) = @$case;
        my $g = game($position);
        my ($answer, $flags) = $g->play(unwire($move));
        is($answer, PLAY_OK, "$what: $move is played");
        ok($flags & KING_TAKEN, 'and reported as the king taken');
        is($g->outcome, BY_CAPTURE, 'the game is won by capture');
        is($g->winner, ATTACKERS, 'by the attackers');
        is($g->count(KING), 0, 'and he is off the board');
    }
};

subtest 'attackers with no piece left have lost, and it is not "cannot move"' => sub {
    my $g = played('7/4d2/7/7/2da3/1k5/7 d', undef, 'e6e3');
    is($g->count(ATTACKER), 0, 'the last attacker is taken');
    is($g->outcome, BY_NO_PIECES, 'the game is won, not drawn');
    is($g->winner, DEFENDERS, 'by the defenders');
    ok(!$g->is_draw, 'rule 12 read literally would have drawn it');
};

subtest 'a finished game has no moves and takes none' => sub {
    for my $case (
        [ 'a corner',   '7/7/7/k6/7/7/3a3 d', 'a4a1' ],
        [ 'a capture',  '7/5ka/3d3/7/7/4a2/7 a', 'e2e6' ],
    ) {
        my ($what, $position, $move) = @$case;
        my $g = played($position, undef, $move);
        my ($string, $ply, $outcome) = ($g->position, $g->ply, $g->outcome);
        is(scalar($g->moves), 0, "after $what: no moves");
        is_deeply([ $g->moves ], [], 'an empty list');

        # every move the pieces could make if the game were not over
        my @would = $g->board->moves;
        cmp_ok(scalar(@would), '>', 0, 'though the pieces could still move: ' . scalar(@would));
        my $refused = grep { $g->play($_) == PLAY_OVER } @would;
        is($refused, scalar(@would), 'every one of them is refused as PLAY_OVER');
        is($g->position, $string, 'and the position did not change');
        is($g->ply, $ply, 'nor the ply');
        is($g->outcome, $outcome, 'nor the outcome');
    }
};

subtest 'an illegal move is refused and the game is as it was' => sub {
    my $g = $R->new;
    my ($string, $key) = ($g->position, $g->key_hex);
    for my $case ([ 'd1', 'd3', 'through another piece' ], [ 'd3', 'c3', 'a defender, on the attackers\' turn' ],
                  [ 'b2', 'b3', 'from an empty square' ], [ 'a4', 'a7', 'an attacker onto a corner' ],
                  [ 'a4', 'b5', 'a diagonal' ]) {
        my ($from, $to, $what) = @$case;
        is(scalar $g->play(unwire("$from$to")), PLAY_ILLEGAL, "$from$to: $what");
    }
    is($g->play(-1), PLAY_ILLEGAL, 'a number that is not a move');
    is($g->position, $string, 'the position is the set-up still');
    is($g->key_hex, $key, 'with its key');
    is($g->ply, 0, 'and no ply was counted');
    is($g->undo, 0, 'there is nothing to take back');
};

# ONE MOVE CAN SATISFY TWO ENDINGS, and the order they are asked in decides.
subtest 'the order of the endings' => sub {
    my $g = played('7/7/7/7/7/k6/1ad4 d', undef, 'a2a1');
    is($g->count(ATTACKER), 0, 'the king reaches a corner and takes the last attacker with the same move');
    is($g->outcome, BY_CORNER, 'and it is the corner that is reported: the move\'s own win comes first');

    $g = played('7/4d2/7/7/2da3/1k5/7 d', undef, 'e6e3');
    is(scalar($g->board->moves), 0, 'with no attackers the side to move has no move');
    is($g->outcome, BY_NO_PIECES, 'and that is no pieces, which is asked before no move');

    $g = played('7/5ka/7/7/7/4a2/7 a', { ply_cap => 1 }, 'e2e6');
    is($g->ply, 1, 'the king is captured on the ply that is also the cap');
    is($g->outcome, BY_CAPTURE, 'and it is a capture: the cap is asked last');

    $g = played('7/7/7/k6/7/7/3a3 d', { ply_cap => 1 }, 'a4a1');
    is($g->outcome, BY_CORNER, 'the same for a corner');
};

subtest 'a position that was set up, not played into' => sub {
    is(game('7/7/7/7/3d3/7/a6 a')->outcome, BY_CAPTURE, 'no king on the board: he has been captured');
    is(game('k6/7/7/7/7/7/3a3 a')->outcome, BY_CORNER, 'a king on a corner: he has won');
    is(game('7/7/7/k6/7/7/3a3 a')->outcome, ONGOING, 'a king on the edge: the game is on');
    is(game('7/7/7/k6/7/7/3a3 a', { escape => 'edge' })->outcome, BY_CORNER,
        'unless the edge is the way out');
    is(game('7/7/7/3k3/3d3/7/7 a')->outcome, BY_NO_PIECES, 'a king and no attackers: no pieces');
    is(game('d5a/7/7/3k3/7/7/3a3 a')->outcome, ONGOING,
        'a defender and an attacker standing on corners are not the king: the game is on');
    is(game('7/7/7/7/7/7/7 a')->outcome, BY_CAPTURE, 'an empty board has no king either');

    my $g = game('k6/7/7/7/7/7/3a3 a');
    is(scalar($g->moves), 0, 'a game that began finished has no moves');
    is($g->play(unwire('d1d2')), PLAY_OVER, 'and takes none');
    is($g->ply, 0, 'at ply 0');
};

subtest 'undo takes the ending back with the move' => sub {
    for my $case (
        [ BY_CORNER,    '7/7/7/k6/7/7/3a3 d',      'a4a1' ],
        [ BY_CAPTURE,   '7/5ka/3d3/7/7/4a2/7 a',   'e2e6' ],
        [ BY_NO_PIECES, '7/4d2/7/7/2da3/1k5/7 d',  'e6e3' ],
    ) {
        my ($want, $position, $move) = @$case;
        my $g = game($position);
        my $key = $g->key_hex;
        $g->play(unwire($move));
        is($g->outcome, $want, outcome_name($want) . ' reached');
        ok(defined $g->key_at(1), 'the game remembers the position after the move');
        is($g->undo, 1, 'undo takes it back');
        is($g->outcome, ONGOING, 'and the game is on again');
        is($g->ply, 0, 'at ply 0');
        is($g->position, $position, 'in the position it started from');
        is($g->key_hex, $key, 'with its key');
        is($g->key_at(1), undef, 'and the ply that was undone is no longer part of it');
        is($g->play(unwire($move)), PLAY_OK, 'the same move can be played again');
        is($g->outcome, $want, 'to the same ending');
    }
};

subtest 'names and winners' => sub {
    is(outcome_name(ONGOING), 'ongoing', 'ONGOING');
    is(outcome_name(BY_CORNER), 'corner', 'BY_CORNER');
    is(outcome_name(BY_CAPTURE), 'capture', 'BY_CAPTURE');
    is(outcome_name(BY_NO_PIECES), 'no_pieces', 'BY_NO_PIECES');
    is(outcome_name(DRAW_REPETITION), 'repetition', 'DRAW_REPETITION');
    is(outcome_name(DRAW_NO_MOVE), 'no_move', 'DRAW_NO_MOVE');
    is(outcome_name(DRAW_PLY_CAP), 'ply_cap', 'DRAW_PLY_CAP');
    is(outcome_name(7), undef, 'seven is not an outcome');
    is(outcome_name(undef), undef, 'nor is undef');
    is(outcome_name('corner'), undef, 'nor is a word');

    is($R->winner_of(BY_CAPTURE), ATTACKERS, 'a capture is the attackers\'');
    is($R->winner_of(BY_CORNER), DEFENDERS, 'a corner is the defenders\'');
    is($R->winner_of(BY_NO_PIECES), DEFENDERS, 'and so is no pieces');
    is($R->winner_of($_), undef, outcome_name($_) . ' is nobody\'s')
        for ONGOING, DRAW_REPETITION, DRAW_NO_MOVE, DRAW_PLY_CAP;
    is(join(' ', ONGOING, BY_CORNER, BY_CAPTURE, BY_NO_PIECES, DRAW_REPETITION, DRAW_NO_MOVE, DRAW_PLY_CAP),
        '0 1 2 3 4 5 6', 'seven different numbers, ONGOING being 0');
};

subtest 'the rule set is fixed when the game is made, and clamped' => sub {
    my $v = $R->new->variant;
    is_deeply($v, { throne_pass => 1, throne_reentry => 0, king_everywhere_two => 0, king_strong => 0,
                    escape => 'corner', repeat => 3, ply_cap => 400 }, 'the default, every field');
    is($R->new(variant => { ply_cap => 0 })->ply_cap, 400, 'a cap of 0 is the default');
    is($R->new(variant => { ply_cap => -5 })->ply_cap, 400, 'so is a negative one');
    is($R->new(variant => { ply_cap => 4097 })->ply_cap, 400, 'and one above the ceiling');
    is($R->new(variant => { ply_cap => 4096 })->ply_cap, 4096, 'the ceiling itself stands');
    is($R->new(variant => { ply_cap => 60 })->ply_cap, 60, 'and an ordinary cap');
    is($R->new(variant => { repeat => 1 })->variant->{repeat}, 2, 'a repeat of 1 is 2');
    is($R->new(variant => { repeat => 0 })->variant->{repeat}, 2, 'so is 0');
    is($R->new(variant => { repeat => 5 })->variant->{repeat}, 5, 'and 5 is 5');
    is($R->new(variant => { escape => 'edge' })->variant->{escape}, 'edge', 'the edge is remembered');

    ok(!eval { $R->new(variant => { repeats => 2 }); 1 }, 'a field that does not exist croaks');
    like($@, qr/no variant field is called 'repeats'/, 'and names it');
    ok(!eval { $R->new(position => '7/7 a'); 1 }, 'so does a string that is not a position');
    like($@, qr/refused, code 2/, 'with its code');
};

subtest 'a clone is its own game, and games are released' => sub {
    my $start = $R->live;
    my $boards = Game::Brandubh::Engine->live;
    {
        my $g = played('3a3/3a3/3d3/aadkdaa/3d3/3a3/3a3 a', undef, 'a4a3', 'c4c3');
        is($R->live, $start + 1, 'one game');
        my $c = $g->clone;
        is($R->live, $start + 2, 'a clone is a second');
        is($c->position, $g->position, 'at the same position');
        is($c->ply, 2, 'with the same history');
        is($c->key_at(1), $g->key_at(1), 'ply for ply');
        $c->play(unwire('a3a4'));
        is($g->ply, 2, 'a move on the clone does not reach the original');
        is($c->undo + $c->undo + $c->undo, 3, 'the clone can take back the moves it inherited');
        is($c->position, '3a3/3a3/3d3/aadkdaa/3d3/3a3/3a3 a', 'all the way to the set-up');
        is($g->ply, 2, 'and the original still has not moved');

        my $bd = $g->board;
        $bd->relocate(unwire('d1c1'));
        is($g->at(sq('d1')), ATTACKER, 'the board a game hands out is a copy');
    }
    is($R->live, $start, 'both games are gone at the end of the block');
    is(Game::Brandubh::Engine->live, $boards, 'and so are their boards');

    ok(!eval { $R->new(_ptr => 12345); 1 }, 'a pointer handed to new is refused');
    like($@, qr/made by new or clone/, 'with a sentence');
    is($R->live, $start, 'and nothing was dropped that was not its own');
};

# THE TWIN'S GAMES. t/games.txt holds 243 games a second program played to
# their end, with every move it made. Played again here move by move, each must
# be accepted, the game must not end before its last move, and it must end how
# and where the twin says. The twin compares whole positions as strings over
# the whole game; this engine compares keys and stops at the last capture.
subtest 'the twin\'s games end where the twin says' => sub {
    open my $fh, '<', "$FindBin::Bin/games.txt" or die "t/games.txt: $!";
    my (%outcomes, %labels, @bad);
    my ($games, $plies) = (0, 0);
    while (my $line = <$fh>) {
        chomp $line;
        next if $line =~ /\A#/ || $line !~ /\S/;
        my ($label, $start, $outcome, $winner, $ply, $final, $moves) = split /\t/, $line, -1;
        my %variant = map { split /=/ } grep { $_ ne 'default' } split /,/, $label;
        my $g = $R->new(position => $start, (%variant ? (variant => \%variant) : ()));
        my @moves = split ' ', ($moves // '');
        my $early = 0;
        for my $i (0 .. $#moves) {
            $early++ if $g->is_over;
            my $answer = $g->play(unwire($moves[$i]));
            if ($answer != PLAY_OK) { push @bad, "$label $start: move $i ($moves[$i]) refused, $answer"; last }
        }
        $games++;
        $plies += @moves;
        $outcomes{$outcome}++;
        $labels{$label}++;
        my $w = $g->winner;
        my $got_winner = !defined $w ? '-' : $w == ATTACKERS ? 'a' : 'd';
        push @bad, "$label $start: ended early" if $early;
        push @bad, "$label $start: " . outcome_name($g->outcome) . ", the twin says $outcome"
            unless outcome_name($g->outcome) eq $outcome;
        push @bad, "$label $start: winner $got_winner, the twin says $winner" unless $got_winner eq $winner;
        push @bad, "$label $start: ply " . $g->ply . ", the twin says $ply" unless $g->ply == $ply;
        push @bad, "$label $start: stopped at " . $g->position . ", the twin says $final" unless $g->position eq $final;
        push @bad, "$label $start: still has moves" if $g->moves;

        # and all the way back
        1 while $g->undo;
        push @bad, "$label $start: did not undo to its start" unless $g->position eq $start && $g->ply == 0;
    }
    is($games, 243, '243 games');
    cmp_ok($plies, '>', 12_000, "$plies moves played");
    is(join(' ', sort keys %outcomes), 'capture corner no_move no_pieces ply_cap repetition',
        'every one of the six endings is among them');
    cmp_ok($outcomes{$_}, '>=', 8, "$outcomes{$_} by $_") for sort keys %outcomes;
    is(scalar(keys %labels), 7, 'under seven rule sets');
    is(scalar(@bad), 0, 'and every game ends how, when and where the twin says')
        or diag(join "\n", @bad[0 .. ($#bad < 5 ? $#bad : 5)]);
};

done_testing();
