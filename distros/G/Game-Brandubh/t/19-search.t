use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";

use Game::Brandubh;
use Game::Brandubh::Engine qw(ATTACKERS DEFENDERS ATTACKER DEFENDER KING EMPTY);
use Game::Brandubh::Rules qw(:all);
use Game::Brandubh::Test::Squares qw(sq name wire unwire roller transform SYMMETRIES);
my $R = 'Game::Brandubh::Rules';
my $E = 'Game::Brandubh::Engine';

sub game { $R->new(position => $_[0], ($_[1] ? (variant => $_[1]) : ())) }

# The search is asked for a move; what is checked is what the move DOES. A
# position with a win in it usually has more than one, and a test that named
# the move would be testing the order moves are tried in.

my @ATTACKERS_WIN = (
    '3a3/7/7/2aka2/3a3/7/7 a',      # the fourth round the throne
    '1a5/7/2a4/2k4/2a4/7/7 a',      # the third beside it
    '5a1/7/4a2/4k2/4a2/7/7 a',
    '7/7/7/7/2aka2/a6/7 a',
    '7/a6/2aka2/7/7/7/7 a',
    '7/5ka/7/7/7/4a2/7 a',          # the second in the open
    '7/7/2a4/7/7/7/1k5 a',          # against a corner
    '7/7/7/7/4a2/k6/7 a',
    '7/7/4a2/7/7/7/2ak3 a',         # along the edge
    '7/5ka/3d3/7/2d4/4a2/7 a',      # with defenders on the board who cannot help
);

my @DEFENDERS_WIN = (
    '7/7/7/k6/7/7/3a3 d',
    '7/7/7/6k/7/7/3a3 d',
    '3k3/7/7/7/7/7/3a3 d',
    '7/7/7/7/7/6a/3k3 d',
    '1k5/7/7/7/7/7/3a3 d',
    '7/7/7/k2a3/7/a6/7 d',          # one corner closed, the other not
    '7/7/7/7/7/a5k/3a3 d',          # g2 to g1, under an attacker's nose
    '3a3/7/7/k5a/7/7/3a3 d',
    '7/7/2a4/7/k6/7/2aa3 d',
    '7/6k/7/7/7/2d4/3a3 d',         # g6 to g7
);

subtest 'a win in one move is found with no budget at all' => sub {
    for my $case ([ 'the attackers', BY_CAPTURE, ATTACKERS, \@ATTACKERS_WIN ],
                  [ 'the defenders', BY_CORNER,  DEFENDERS, \@DEFENDERS_WIN ]) {
        my ($who, $how, $side, $positions) = @$case;
        is(scalar(@$positions), 10, "ten positions for $who");
        for my $position (@$positions) {
            my $g = game($position);
            my $found = $g->search(budget => 1);
            ok($found, "a move in $position") or next;
            is($found->{score}, 29_999, 'scored as a win one move off: 30,000 less one');
            is($g->play($found->{move}), PLAY_OK, 'and legal');
            is($g->outcome, $how, 'and it ends the game by ' . outcome_name($how));
            is($g->winner, $side, "for $who");
        }
    }
};

# A WIN THE HORIZON WOULD HIDE. The king steps to a square from which two
# corners are open; the attackers can close one. Three plies, and the last of
# them is past a search of depth 2 unless it looks on while the king has a line.
subtest 'a win in three is found, and played to its end' => sub {
    for my $position ('7/7/7/3k3/7/7/3a3 d', '7/7/7/3k3/7/3a3/3a3 d', '7/7/2a4/3k3/7/7/3a3 d') {
        my $g = game($position);
        my $found = $g->search(budget => 2000);
        is($found->{score}, 29_997, "$position: the defenders see a win three moves off, and score it 30,000 less three");
        my $plies = 0;
        until ($g->is_over) {
            $g->play($g->search(budget => 2000)->{move});
            $plies++;
            last if $plies > 9;
        }
        is($g->outcome, BY_CORNER, 'and with both sides searching, the king gets home');
        is($plies, 3, 'in three plies: the attackers cannot delay it');
    }
};

# THE EXTENSION, on its own. Asked to look ONE move ahead, the search plays the
# king's step and stands at the horizon with the attackers to move and two
# corners open. A search that stopped there would score a quiet position. This
# one looks one ply on, because the king has a line, and finds that no answer
# closes both.
subtest 'at the horizon, a king with a line open is looked at one ply further' => sub {
    for my $position ('7/7/7/3k3/7/7/3a3 d', '7/7/7/3k3/7/3a3/3a3 d', '7/7/2a4/3k3/7/7/3a3 d') {
        my $found = game($position)->search(budget => 50_000_000, depth => 1);
        is($found->{depth}, 1, "$position: asked for one move ahead");
        cmp_ok($found->{score}, '>', 29_000, 'and the win three plies off is seen all the same');
    }
    my $quiet = game('3a3/3a3/3d3/aadkdaa/3d3/3a3/3a3 d')->search(budget => 50_000_000, depth => 1);
    cmp_ok(abs($quiet->{score}), '<', 29_000, 'where there is no win, as in the set-up, none is reported');
};

# THE SEARCH KNOWS A REPEATED POSITION IS A DRAW. The weights here make every
# ordinary position look hopeless for the defenders, and one move brings the
# set-up round for the last time the rule set allows. A search that knows that
# is a draw takes it, at a score of nothing; one that does not sees only
# another hopeless position.
subtest 'a move that draws by repetition is seen as a draw' => sub {
    my $g = $R->new(variant => { repeat => 2 });
    $g->play(unwire($_)) for qw(a4a3 c4c3 a3a4);
    my %hopeless = (attacker => 1000, defender => 0, lane_one => 0, lane_two => 0, freedom => 0, corner_guard => 0, ring => 0);
    my $found = $g->search(budget => 50_000_000, depth => 1, weights => \%hopeless);
    is(wire($found->{move}), 'c3c4', 'the defenders play the move that repeats the set-up');
    is($found->{score}, 0, 'and score it as the draw it is');
    is($g->play($found->{move}), PLAY_OK, 'played');
    is($g->outcome, DRAW_REPETITION, 'and the game is drawn by repetition');

    my $other = $R->new(variant => { repeat => 3 });
    $other->play(unwire($_)) for qw(a4a3 c4c3 a3a4);
    cmp_ok($other->search(budget => 50_000_000, depth => 1, weights => \%hopeless)->{score}, '<', -5000,
        'with the draw a round further off, the same position is just hopeless');
};

# THE SOONER WIN IS THE BETTER ONE. A win is scored 30,000 less the number of
# moves it is away, so that with a corner open now and a slower win beside it
# the search takes the corner, and a side that is lost holds out as long as it
# can. The scores above are asserted to the unit for this reason.
subtest 'of two wins the nearer is worth more' => sub {
    my $one   = game('7/7/7/k6/7/7/3a3 d')->search(budget => 50_000_000, depth => 4);
    my $three = game('7/7/7/3k3/7/7/3a3 d')->search(budget => 50_000_000, depth => 4);
    cmp_ok($one->{score}, '>', $three->{score}, "a win in one ($one->{score}) outranks a win in three ($three->{score})");
    is($one->{score} - $three->{score}, 2, 'by the two moves between them');
};

# EACH SIDE PLAYS FOR ITSELF. The evaluation is the attackers' view of a
# position and the search turns it round for the defenders. With material the
# only thing weighed, one capture on the board, and the king shut in on his
# throne by his own men so that no line of his can decide anything, whoever is
# to move must take what can be taken, and must score the result as its own
# gain.
subtest 'the defenders play for the defenders, and the attackers for the attackers' => sub {
    my %material = (attacker => 100, defender => 100, lane_one => 0, lane_two => 0, freedom => 0, corner_guard => 0, ring => 0);

    my $d = game('7/1a3d1/3d1a1/2dkd2/3d3/1a3d1/7 d');
    is($d->evaluate(\%material), -300, 'three attackers and six defenders: three hundred against the attackers');
    my $found = $d->search(budget => 50_000_000, depth => 1, weights => \%material);
    my ($flags, @taken) = $d->preview($found->{move});
    is(join(' ', map { name($_) } @taken), 'f5', 'the defenders, to move, take the attacker that can be taken');
    is($found->{score}, 400, 'and score two against six as four hundred TO THEMSELVES');

    my $att = game('7/5a1/3d1d1/2dkd2/3d3/1a3a1/7 a');
    is($att->evaluate(\%material), -200, 'three attackers and five defenders: two hundred against the attackers');
    $found = $att->search(budget => 50_000_000, depth => 1, weights => \%material);
    ($flags, @taken) = $att->preview($found->{move});
    is(join(' ', map { name($_) } @taken), 'f5', 'the attackers, to move, take the defender that can be taken');
    is($found->{score}, -100, 'and score three against four as a hundred against themselves, which is better than two');
};

subtest 'the side that is lost knows it' => sub {
    my $g = game('7/7/7/k6/7/7/3a3 a');
    my $found = $g->search(budget => 2000);
    is($found->{score}, -29_998, 'the attackers, a move too late to close two corners, score a loss two moves off');
    is($g->play($found->{move}), PLAY_OK, 'and still hand back a legal move');
};

subtest 'a finished game has no move to find' => sub {
    my $g = game('7/7/7/k6/7/7/3a3 d');
    $g->play(unwire('a4a1'));
    is($g->search(budget => 1000), undef, 'undef');
    is(game('7/7/7/d6/ad5/d5k/7 a')->search(budget => 1000), undef, 'the same for a side that cannot move');
};

subtest 'the search does not touch the game it is asked about' => sub {
    my $games = $R->live;
    my $boards = $E->live;
    my $g = $R->new;
    $g->play(unwire($_)) for qw(a4a3 c4c3);
    my ($position, $key, $ply, $repeats) = ($g->position, $g->key_hex, $g->ply, $g->repeats);
    $g->search(budget => 30_000) for 1 .. 5;
    is($g->position, $position, 'the position is as it was');
    is($g->key_hex, $key, 'the key');
    is($g->ply, $ply, 'the ply');
    is($g->repeats, $repeats, 'the count of repeats');
    is($g->undo, 1, 'and the history is still there to undo');
    undef $g;
    is($R->live, $games, 'no game was left behind by five searches');
    is($E->live, $boards, 'and no board');
};

# NEVER AN ILLEGAL MOVE. Five thousand positions met in play, each searched
# with a small budget, and the move it returns looked up in the list.
subtest 'five thousand searches, five thousand legal moves' => sub {
    my $roll = roller(1919);
    my ($searches, $bad, %depth) = (0, 0);
    while ($searches < 5000) {
        my $g = $R->new(variant => { ply_cap => 120 });
        until ($g->is_over || $searches >= 5000) {
            my @legal = $g->moves;
            my $found = $g->search(budget => 1 + $roll->(2000), seed => 1 + $roll->(1000));
            $searches++;
            $bad++ unless $found && grep { $_ == $found->{move} } @legal;
            $depth{ $found->{depth} }++ if $found;
            $g->play($legal[ $roll->(scalar @legal) ]);
        }
    }
    is($searches, 5000, 'five thousand searches, counted');
    is($bad, 0, 'each returned one of the legal moves');
    cmp_ok(scalar(keys %depth), '>=', 2, 'at depths ' . join(', ', sort { $a <=> $b } keys %depth));
};

# THE ORDER MOVES ARE TRIED IN changes what a search costs and never what a
# position is worth. The seed reorders the root, so three seeds are three
# orders, and to a fixed depth all three must give the same score.
subtest 'the score of a position does not depend on the order moves are tried in' => sub {
    my $roll = roller(303);
    my ($positions, $bad, $moves_differ, $nodes_differ) = (0, 0, 0, 0);
    while ($positions < 300) {
        my $g = $R->new(variant => { ply_cap => 100, repeat => 100 });
        until ($g->is_over || $positions >= 300) {
            my @found = map { $g->search(budget => 5_000_000, depth => 3, seed => $_) } 11, 222, 3333;
            $positions++;
            $bad++ if grep { $_->{score} != $found[0]{score} || $_->{depth} != $found[0]{depth} } @found;
            $moves_differ++ if grep { $_->{move} != $found[0]{move} } @found;
            $nodes_differ++ if grep { $_->{nodes} ne $found[0]{nodes} } @found;
            my @legal = $g->moves;
            $g->play($legal[ $roll->(scalar @legal) ]) for 1 .. 1;
        }
    }
    is($positions, 300, 'three hundred positions, each searched in three orders');
    is($bad, 0, 'and the score and the depth were the same in all three');
    cmp_ok($nodes_differ, '>', 20, "though the cost was not, in $nodes_differ of them");
    cmp_ok($moves_differ, '>', 0, "and in $moves_differ of them the move was a different one of equal worth");
};

# The same, one move deeper and on fewer positions. At depth 4 a search meets
# the same squares with the other side to move, by a piece taking two moves
# over a journey another line makes in one, and the table of positions must
# keep those two apart.
subtest 'nor at depth four, where the same squares come up with either side to move' => sub {
    my $roll = roller(404);
    my ($positions, $bad) = (0, 0);
    while ($positions < 40) {
        my $g = $R->new(variant => { ply_cap => 100, repeat => 100 });
        my $skip = 4 + $roll->(20);
        for (1 .. $skip) {
            last if $g->is_over;
            my @legal = $g->moves;
            $g->play($legal[ $roll->(scalar @legal) ]);
        }
        next if $g->is_over;
        my @found = map { $g->search(budget => 50_000_000, depth => 4, seed => $_) } 11, 222, 3333;
        $positions++;
        $bad++ if grep { $_->{score} != $found[0]{score} } @found;
    }
    is($positions, 40, 'forty positions, each searched four moves deep in three orders');
    is($bad, 0, 'and worth the same in all three');
};

# THE EVALUATION is for the attackers: more of them is better, fewer of the
# defenders is better, and a line for the king is worse.
subtest 'the evaluation has the sign it says it has' => sub {
    my $w = $R->weights;
    is_deeply([ sort keys %$w ], [qw(attacker corner_guard defender freedom lane_one lane_two ring)], 'seven weights');
    cmp_ok($w->{$_}, '>', 0, "$_ is positive: $w->{$_}") for sort keys %$w;

    my $quiet = game('7/7/1a3a1/3k3/1a3a1/7/7 a');
    my $base = $quiet->evaluate;
    cmp_ok(game('7/7/1a3a1/3k3/1a3a1/3a3/7 a')->evaluate, '>', $base, 'an attacker more is better for the attackers');
    cmp_ok(game('7/3d3/1a3a1/3k3/1a3a1/7/7 a')->evaluate, '<', $base, 'a defender more is worse for them');
    is(game('7/7/1a3a1/3k3/1a3a1/7/7 d')->evaluate, $base, 'whose move it is does not change the number');

    my $shut = game('7/7/7/a1k4/7/7/7 a');
    my $open = game('7/7/7/a5k/7/7/7 a');
    cmp_ok($open->evaluate, '<', $shut->evaluate, 'a king with a line to a corner is worse for the attackers');

    my %zero = map { $_ => 0 } keys %$w;
    is($R->new->evaluate(\%zero), 0, 'with every weight at nothing the set-up is worth nothing');
    is($R->new->evaluate({ %zero, attacker => 1 }), 8, 'eight attackers at one each');
    is($R->new->evaluate({ %zero, defender => 1 }), -4, 'four defenders at one each, against');
    is($quiet->evaluate({ %zero, freedom => 1 }), -12, 'a king free in every direction has twelve squares');
    is(game('7/7/7/a5k/7/7/7 a')->evaluate({ %zero, lane_one => 1 }), -2, 'the king on g4 has two corners in one move');
    is(game('7/7/3a3/2aka2/7/7/7 a')->evaluate({ %zero, ring => 1 }), 3, 'three attackers next to him');
    is(game('7/7/7/aaak3/7/7/7 a')->evaluate({ %zero, corner_guard => 1 }), 0, 'attackers that guard no corner');
    is(game('7/7/7/3k3/a6/1a5/2a4 a')->evaluate({ %zero, corner_guard => 1 }), 3, 'and the three that close a1');

    ok(!eval { $R->new->evaluate({ lanes => 1 }); 1 }, 'a weight that does not exist croaks');
    like($@, qr/no weight is called 'lanes'/, 'and names it');
    ok(!eval { $R->new->search(budget => 100, weights => { atacker => 1 }); 1 }, 'in a search too');
};

# The board, the throne and the corners are the same under the eight
# symmetries of a square, so a position and its image are worth the same.
subtest 'a position and its mirror image are worth the same' => sub {
    my $roll = roller(88);
    my ($boards, $bad) = (0, 0);
    for my $i (1 .. 500) {
        my $bd = $E->new(empty => 1);
        my @squares = $E->all_squares;
        $bd->put($squares[ $roll->(49) ], KING);
        for my $s (@squares) {
            next if $bd->at($s) != EMPTY;
            my $what = $roll->(5);
            $bd->put($s, $what) if $what == ATTACKER || $what == DEFENDER;
        }
        $boards++;
        my $want = game($bd->to_string)->evaluate;
        for my $sym (SYMMETRIES) {
            my $image = $E->new(empty => 1);
            for my $s (@squares) {
                next if $bd->at($s) == EMPTY;
                $image->put(sq(transform($sym->[1], name($s))), $bd->at($s));
            }
            $bad++ unless game($image->to_string)->evaluate == $want;
        }
    }
    is($boards, 500, 'five hundred boards');
    is($bad, 0, 'each worth the same under all eight symmetries');
};

done_testing();
