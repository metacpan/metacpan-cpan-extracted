use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";

use Game::Brandubh;
use Game::Brandubh::Variant;
use Game::Brandubh::Rules ();
use Game::Brandubh::Notation qw(SETUP);
use Game::Brandubh::Test::Squares qw(roller);
my $G = 'Game::Brandubh';

sub dies_like {
    my ($code, $pattern, $why) = @_;
    my $lived = eval { $code->(); 1 };
    ok(!$lived, "$why: croaks");
    like($@, $pattern, 'and says why');
}

subtest 'a new game' => sub {
    my $g = $G->new;
    is($g->status, 'active', 'active');
    is($g->attackers, 'p1', 'p1 has the attackers');
    is($g->turn, 'p1', 'and so the first move');
    is($g->side_to_move, 'attackers', 'the attackers move first');
    is($g->position, SETUP, 'from the set-up');
    is($g->start, SETUP, 'which is where it started');
    is($g->ply, 0, 'no move made');
    is($g->repeats, 1, 'the position seen once');
    is($g->result, undef, 'no result');
    is($g->winner, undef, 'no winner');
    is($g->draw_offered_by, undef, 'no draw offered');
    is_deeply($g->log, [], 'an empty log');
    is_deeply($g->shown, [], 'and nothing to show');
    is($g->variant->name, 'brandubh', 'under the default rule set');
    like($g->signature, qr/\A[0-9a-f]{16}\z/, 'a signature of sixteen hex characters');
    is(scalar(@{ $g->legal }), 40, 'forty legal moves');
};

# THE SEAT AND THE SIDE. `attackers` names a seat; the attackers move first;
# and these two methods are the only way between the two words.
subtest 'seats and sides, both ways round' => sub {
    for my $case ([ 'p1', 'p2' ], [ 'p2', 'p1' ]) {
        my ($att, $def) = @$case;
        my $g = $G->new(attackers => $att);
        is($g->attackers, $att, "$att has the attackers");
        is($g->turn, $att, 'and moves first');
        is($g->side_of($att), 'attackers', "side_of($att)");
        is($g->side_of($def), 'defenders', "side_of($def)");
        is($g->seat_of('attackers'), $att, 'seat_of(attackers)');
        is($g->seat_of('defenders'), $def, 'seat_of(defenders)');
        $g->play_or_die('d1c1');
        is($g->turn, $def, "after one move it is ${def}'s turn");
        is($g->side_to_move, 'defenders', 'the defenders to move');
        $g->play_or_die('d3c3');
        is($g->turn, $att, "and after two, ${att}'s again");
    }
    my $g = $G->new;
    is($g->side_of('p3'), undef, 'p3 has no side');
    is($g->side_of(undef), undef, 'nor has nobody');
    is($g->seat_of('kings'), undef, 'and there is no side called kings');
    is($g->seat_of(undef), undef, 'or called nothing');
};

subtest 'what new will not take' => sub {
    dies_like(sub { $G->new(attackers => 'p3') }, qr/attackers must be 'p1' or 'p2'/, 'a third seat');
    dies_like(sub { $G->new(attackers => 'attackers') }, qr/attackers must be/, 'a side where a seat goes');
    dies_like(sub { $G->new(seed => 'short') }, qr/thirty-two bytes/, 'a short seed');
    dies_like(sub { $G->new(seed => 'x' x 33) }, qr/thirty-two bytes/, 'a long one');
    dies_like(sub { $G->new(position => '7/7 a') }, qr/is not a position/, 'a position that is not one');
    dies_like(sub { $G->new(variant => 'tablut') }, qr/'tablut' is not a rule set/, 'a rule set nobody has heard of');
    dies_like(sub { $G->new(variant => { repeats => 2 }) }, qr/no field is called 'repeats'/, 'a misspelt field');
    dies_like(sub { $G->new(variant => [ repeat => 2 ]) }, qr/a variant is a name, a hash of fields or/, 'a list where a hash goes');
    ok($G->new(seed => 'x' x 32), 'thirty-two bytes is a seed');
    ok($G->new, 'and no seed at all is fine');
};

subtest 'a variant, three ways' => sub {
    my $object = Game::Brandubh::Variant->custom(repeat => 2, ply_cap => 60);
    for my $given ($object, { repeat => 2, ply_cap => 60 }, 'custom repeat=2,ply_cap=60') {
        my $g = $G->new(variant => $given);
        ok($g->variant->equals($object), 'as ' . (ref $given || 'a string') . ': the same rule set');
    }
};

# EACH ENDING, by moves written to reach it, with everything the result says.
my @ENDINGS = (
    [ 'corner',     'defenders', { position => '7/7/7/k6/7/7/3a3 d' },                       [ 'a4a1' ] ],
    [ 'edge',       'defenders', { position => '7/7/7/2k4/7/7/3a3 d', variant => { escape => 'edge' } }, [ 'c4c1' ] ],
    [ 'capture',    'attackers', { position => '7/5ka/7/7/7/4a2/7 a' },                      [ 'e2e6' ] ],
    [ 'no_pieces',  'defenders', { position => '7/4d2/7/7/2da3/1k5/7 d' },                   [ 'e6e3' ] ],
    [ 'repetition', undef,       {},                                                         [ (qw(a4a3 c4c3 a3a4 c3c4)) x 2 ] ],
    [ 'no_move',    undef,       { position => '7/7/7/d6/a6/d5k/1d5 d' },                    [ 'b1b3' ] ],
    [ 'ply_cap',    undef,       { variant => { ply_cap => 3 } },                            [ qw(a4a3 c4c3 a3a2) ] ],
);

subtest 'the seven endings the board can show' => sub {
    for my $case (@ENDINGS) {
        my ($how, $winner, $args, $moves) = @$case;
        for my $att ('p1', 'p2') {
            my $g = $G->new(%$args, attackers => $att);
            for my $i (0 .. $#$moves) {
                is($g->status, 'active', "$how: active before move " . ($i + 1)) if $i == $#$moves;
                $g->play_or_die($moves->[$i]);
            }
            is($g->status, 'finished', "$how: finished");
            my $r = $g->result;
            isa_ok($r, 'Game::Brandubh::Result');
            is($r->how, $how, "how is $how");
            is($r->winner, $winner, 'the winning side is ' . ($winner // 'nobody'));
            is($r->seat, (defined $winner ? $g->seat_of($winner) : undef), 'and the seat is that side\'s, whoever has the attackers');
            is($g->winner, $r->seat, 'winner hands back the seat');
            is(!!$r->is_draw, !defined $winner, 'a draw exactly when nobody won');
            ok(!$r->by_players, 'the board ended it, not the players');
            is($r->ply, scalar(@$moves), 'at the ply of the last move');
            is($r->position, $g->position, 'in the position on the board');
            is($g->turn, undef, 'nobody is to move');
            is($g->side_to_move, undef, 'no side either');
            is_deeply($g->legal, [], 'and there are no legal moves');
        }
    }
};

subtest 'resignation' => sub {
    for my $case ([ 'p1', 'p1', 'defenders' ], [ 'p1', 'p2', 'attackers' ], [ 'p2', 'p1', 'attackers' ], [ 'p2', 'p2', 'defenders' ]) {
        my ($att, $quitter, $winner) = @$case;
        my $g = $G->new(attackers => $att);
        $g->play_or_die('d1c1');
        is($g->resign($quitter), 0, "$quitter resigns, $att having the attackers");
        is($g->status, 'finished', 'the game is over');
        my $r = $g->result;
        is($r->how, 'resign', 'by resignation');
        is($r->winner, $winner, "the $winner win");
        is($r->loser, $g->side_of($quitter), 'and the side that resigned lost');
        is($r->seat, ($quitter eq 'p1' ? 'p2' : 'p1'), 'the winning seat is the other seat');
        ok($r->by_players, 'the players ended it');
        ok(!$r->is_draw, 'and it is not a draw');
        is($r->ply, 1, 'at ply 1');
        is($g->ply, 1, 'no move was added');
        is_deeply($g->log, ['d1c1'], 'and the log has the one move and no resignation in it');
    }
    my $g = $G->new;
    is($g->resign('p2'), 0, 'a seat may resign when it is not its turn');
    is($g->result->winner, 'attackers', 'and the other side wins');
};

subtest 'a draw by agreement' => sub {
    my $g = $G->new;
    is($g->offer_draw('p2'), 0, 'p2 offers, on p1\'s turn');
    is($g->draw_offered_by, 'p2', 'the offer waits');
    is($g->status, 'active', 'the game goes on');
    is($g->decline_draw('p1'), 0, 'p1 declines');
    is($g->draw_offered_by, undef, 'and the offer is gone');

    $g->offer_draw('p1');
    $g->play_or_die('d1c1');
    is($g->draw_offered_by, undef, 'a move withdraws an offer');
    ok($g->accept_draw('p2'), 'so there is nothing left to accept');

    $g->offer_draw('p1');
    is($g->accept_draw('p2'), 0, 'offered again and accepted');
    is($g->status, 'finished', 'the game is over');
    my $r = $g->result;
    is($r->how, 'agreed', 'by agreement');
    ok($r->is_draw, 'a draw');
    ok($r->by_players, 'that the players made');
    is($r->winner, undef, 'with no winner');
    is($g->winner, undef, 'and no winning seat');
    is($g->draw_offered_by, undef, 'the offer is spent');
};

# legal SAYS WHAT EACH MOVE WOULD CAPTURE AND WHETHER IT WINS, so that a client
# can light the board without knowing a rule. Held here against what play then
# does, for every move of three hundred positions, and taken back each time.
subtest 'legal agrees with play, move for move' => sub {
    my $roll = roller(1515);
    my ($positions, $moves, $bad, $captures, $wins, $games) = (0, 0, 0, 0, 0, 0);
    my @first_bad;
    while ($positions < 300) {
        my $g = $G->new(attackers => ($games++ % 2 ? 'p2' : 'p1'), variant => { ply_cap => 120 });
        while ($g->status eq 'active' && $positions < 300) {
            my $legal = $g->legal;
            $positions++;

            my $rules = Game::Brandubh::Rules->new(position => $g->position, variant => $g->variant->as_hash);
            $bad++ unless @$legal == scalar($rules->moves);

            my $before = $g->pieces;
            my ($position, $mover, $ply) = ($g->position, $g->turn, $g->ply);
            for my $entry (@$legal) {
                $moves++;
                my $note = '';
                $note = 'refused' if $g->play($entry->{move});
                my $after = $g->pieces;
                my @gone = sort grep { !exists $after->{$_} && $_ ne $entry->{from} } keys %$before;
                $note ||= 'captures' unless "@gone" eq "@{ $entry->{captures} }";
                $note ||= 'piece'    unless $before->{ $entry->{from} } eq $entry->{piece};
                $note ||= 'landed'   unless ($after->{ $entry->{to} } // '') eq $entry->{piece};
                $note ||= 'squares'  unless $entry->{move} eq $entry->{from} . $entry->{to};
                my $won = ($g->status eq 'finished' && defined $g->winner && $g->winner eq $mover) ? 1 : 0;
                $note ||= 'wins'     unless !!$entry->{wins} == !!$won;
                $captures++ if @gone;
                $wins++ if $won;
                $note ||= 'undo' unless $g->undo && $g->position eq $position && $g->ply == $ply && $g->status eq 'active';
                if ($note) { $bad++; push @first_bad, "$position $entry->{move}: $note" if @first_bad < 4 }
            }
            $g->play_or_die($legal->[ $roll->(scalar @$legal) ]{move});
        }
    }
    is($positions, 300, 'three hundred positions');
    cmp_ok($moves, '>', 5000, "$moves legal moves, each played and taken back");
    cmp_ok($captures, '>', 100, "$captures of them captured");
    cmp_ok($wins, '>', 5, "$wins of them won the game");
    is($bad, 0, 'and each did what its entry said: the piece, the squares, the captures, whether it wins')
        or diag(join "\n", @first_bad);
};

subtest 'wins: taking the last attacker is a win the flags do not show' => sub {
    my $g = $G->new(position => '7/4d2/7/7/2da3/1k5/7 d');
    my ($entry) = grep { $_->{move} eq 'e6e3' } @{ $g->legal };
    ok($entry, 'e6e3 is legal');
    is_deeply($entry->{captures}, ['d3'], 'it takes d3');
    ok($entry->{wins}, 'and wins, d3 being the last attacker');
    # THE KING CAN TAKE IT TOO, against the empty throne above it. The first
    # version of this test said e6e3 was the only winning move; it is one of two.
    is(join(' ', sort map { $_->{move} } grep { $_->{wins} } @{ $g->legal }), 'b2d2 e6e3',
        'the two moves that take d3 are the two that win: a defender closing it, and the king against the throne');
    my ($king) = grep { $_->{move} eq 'b2d2' } @{ $g->legal };
    is_deeply($king->{captures}, ['d3'], 'the king\'s takes d3 as well');
    is($king->{piece}, 'king', 'and is the king\'s');

    my $two = $G->new(position => '7/4d2/7/7/2da3/1k4a/7 d');
    ($entry) = grep { $_->{move} eq 'e6e3' } @{ $two->legal };
    is_deeply($entry->{captures}, ['d3'], 'with a second attacker on the board the same move takes d3');
    ok(!$entry->{wins}, 'and does not win');
};

# THE RESULT IS A VALUE WITH RULES OF ITS OWN: a win has a winner and a seat, a
# draw has neither. The facade only ever builds good ones, so nothing above
# asks what a bad one does; the first mutation run let a drawn result carry a
# winner and no test noticed.
subtest 'the Result class itself' => sub {
    my $R = 'Game::Brandubh::Result';
    is(join(' ', $R->hows), 'agreed capture corner edge no_move no_pieces ply_cap repetition resign',
        'nine ways a game ends');

    for my $how (qw(corner edge capture no_pieces resign)) {
        my $r = $R->new(how => $how, winner => 'defenders', seat => 'p2', ply => 12, position => 'x');
        ok(!$r->is_draw, "$how is a win");
        is($r->winner, 'defenders', 'with its winner');
        is($r->loser, 'attackers', 'and its loser');
        is($r->seat, 'p2', 'and the seat');
        is($r->ply, 12, 'and the ply');
        is($r->position, 'x', 'and the position');
        is(!!$r->by_players, $how eq 'resign', 'by_players only for a resignation');
        dies_like(sub { $R->new(how => $how) }, qr/has a winner, attackers or defenders/, "$how with no winner");
        dies_like(sub { $R->new(how => $how, winner => 'kings', seat => 'p1') }, qr/has a winner/, "$how won by a side that is not one");
        dies_like(sub { $R->new(how => $how, winner => 'attackers') }, qr/names the winner's seat/, "$how with a winner and no seat");
    }
    for my $how (qw(repetition no_move ply_cap agreed)) {
        my $r = $R->new(how => $how, ply => 30, position => 'y');
        ok($r->is_draw, "$how is a draw");
        is($r->winner, undef, 'with no winner');
        is($r->loser, undef, 'no loser');
        is($r->seat, undef, 'and no seat');
        is(!!$r->by_players, $how eq 'agreed', 'by_players only for agreement');
        dies_like(sub { $R->new(how => $how, winner => 'attackers', seat => 'p1') }, qr/drawn by $how has no winner/, "$how with a winner");
        dies_like(sub { $R->new(how => $how, winner => 'attackers') }, qr/has no winner/, "$how with a winner and no seat");
        dies_like(sub { $R->new(how => $how, seat => 'p1') }, qr/has no winner/, "$how with a seat and no winner");
    }
    dies_like(sub { $R->new }, qr/says how the game ended/, 'a result of nothing');
    dies_like(sub { $R->new(how => 'checkmate', winner => 'attackers', seat => 'p1') }, qr/says how the game ended/,
        'a result from another game');
    dies_like(sub { $R->new(how => 'ongoing') }, qr/says how the game ended/, 'a result for a game that has not ended');

    my $r = $R->new(how => 'corner', winner => 'defenders', seat => 'p1');
    is($r->ply, 0, 'the ply defaults to 0');
    ok(!eval { $r->$_('z'); 1 }, "$_ cannot be changed") for qw(how winner seat ply position);
    is($r->how, 'corner', 'and nothing was');
};

subtest 'undo' => sub {
    my $g = $G->new;
    is($g->undo, 0, 'nothing to take back in a new game');
    $g->play_or_die($_) for qw(d1c1 d3c3 c1d1);
    is($g->undo, 1, 'one move back');
    is($g->ply, 2, 'two left');
    is_deeply($g->log, [qw(d1c1 d3c3)], 'the log is one shorter');
    is_deeply($g->shown, [qw(d1-c1 d3-c3)], 'and so is what is shown');
    is($g->turn, 'p1', 'and it is the attackers\' move again');
    is($g->undo + $g->undo, 2, 'two more');
    is($g->position, SETUP, 'back at the set-up');
    is($g->undo, 0, 'and no further');

    $g->play_or_die('d1c1');
    $g->resign('p1');
    is($g->status, 'finished', 'resigned');
    is($g->undo, 1, 'undo takes the resignation back');
    is($g->status, 'active', 'the game is on');
    is($g->result, undef, 'with no result');
    is($g->ply, 1, 'and the move before it is still made');

    $g->offer_draw('p1');
    $g->accept_draw('p2');
    is($g->undo, 1, 'the same for an agreed draw');
    is($g->status, 'active', 'on again');

    $g->offer_draw('p2');
    $g->undo;
    is($g->draw_offered_by, undef, 'taking a move back withdraws an offer');

    my $won = $G->new(position => '7/7/7/k6/7/7/3a3 d');
    $won->play_or_die('a4a1');
    is($won->result->how, 'corner', 'a game won on the board');
    is($won->undo, 1, 'is taken back with its last move');
    is($won->status, 'active', 'and is on again');
    is($won->result, undef, 'with no result');
};

subtest 'what is on the board' => sub {
    my $g = $G->new;
    is($g->at('d4'), 'king', 'the king on d4');
    is($g->at('d3'), 'defender', 'a defender on d3');
    is($g->at('d1'), 'attacker', 'an attacker on d1');
    is($g->at('a1'), '', 'a1 is empty: the empty string');
    is($g->at('D4'), 'king', 'a square in capitals is the same square');
    is($g->at('h1'), undef, 'h1 is not a square: undef');
    is($g->at(undef), undef, 'nor is nothing');

    my $pieces = $g->pieces;
    is(scalar(keys %$pieces), 13, 'thirteen pieces');
    is(join(' ', sort grep { $pieces->{$_} eq 'attacker' } keys %$pieces), 'a4 b4 d1 d2 d6 d7 f4 g4', 'the eight attackers');
    is(join(' ', sort grep { $pieces->{$_} eq 'defender' } keys %$pieces), 'c4 d3 d5 e4', 'the four defenders');
    is(join(' ', grep { $pieces->{$_} eq 'king' } keys %$pieces), 'd4', 'and the king');
    $pieces->{z9} = 'dragon';
    is(scalar(keys %{ $g->pieces }), 13, 'the hash handed out is a copy');
};

subtest 'the log and what is shown' => sub {
    my $g = $G->new(position => '7/7/2k4/7/7/6a/1a5 d');
    $g->play_or_die('Kc5-c1');
    is_deeply($g->log, ['c5c1'], 'a move written the long way is logged the short way');
    is_deeply($g->shown, ['Kc5-c1xb1'], 'and shown with the king\'s K and what it took');
    $g->play_or_die('g2g3');
    $g->play_or_die('c1a1');
    is($g->shown->[-1], 'Kc1-a1++', 'the corner is shown with ++');

    my $taken = $G->new(position => '7/5ka/7/7/7/4a2/7 a');
    $taken->play_or_die('e2e6');
    is($taken->shown->[-1], 'e2-e6xf6#', 'and the king\'s capture with #');

    my $log = $g->log;
    push @$log, 'a1a2';
    is(scalar(@{ $g->log }), 3, 'the log handed out is a copy');
    my $shown = $g->shown;
    push @$shown, 'x';
    is(scalar(@{ $g->shown }), 3, 'and so is what is shown');
};

# The seed is what a program playing this game draws its choices from. A game
# in progress does not hand it out.
subtest 'the seed is held until the game is over' => sub {
    my $seed = join '', map { chr(65 + $_ % 26) } 1 .. 32;
    my $g = $G->new(seed => $seed, position => '7/7/7/k6/7/7/3a3 d');
    is($g->seed, undef, 'not while the game is active');
    $g->play_or_die('a4a1');
    is($g->seed, $seed, 'and all of it once the game is finished');
    is($G->new->seed, undef, 'a game given none has none');
    my $none = $G->new;
    $none->resign('p1');
    is($none->seed, undef, 'finished or not');
};

subtest 'repeats and the signature' => sub {
    my $g = $G->new;
    my $first = $g->signature;
    $g->play_or_die($_) for qw(a4a3 c4c3 a3a4 c3c4);
    is($g->signature, $first, 'the set-up come round again has the signature it had');
    is($g->repeats, 2, 'and has now occurred twice');
    $g->play_or_die('a4a3');
    isnt($g->signature, $first, 'a different position has another');
};

done_testing();
