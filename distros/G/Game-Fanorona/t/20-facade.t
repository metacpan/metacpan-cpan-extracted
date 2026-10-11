use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";

use Game::Fanorona;
use Game::Fanorona::Variant;
use Game::Fanorona::Notation qw(format_move);
use FnT qw(roller);
my $G = 'Game::Fanorona';

subtest 'a new game' => sub {
    my $g = $G->new;
    is($g->turn, 'white', 'White to move');
    ok(!$g->over, 'not over');
    is($g->result, undef, 'no result');
    is($g->winner, undef, 'no winner');
    is($g->error, undef, 'no error');
    is($g->position, 'bbbbbbbbb/bbbbbbbbb/bwbw1bwbw/wwwwwwwww/wwwwwwwww w', 'the set-up');
    is($g->position_counted, $g->position . ' 0 1', 'with its counts: no quiet move, move 1');
    is($g->variant->name, 'sivy', 'on the nine by five');
    is($g->at('d3'), 'white', 'd3 is white');
    is($g->at('f3'), 'black', 'f3 is black');
    is($g->at('e3'), undef, 'e3 is empty');
    is($g->at('j9'), undef, 'and j9 is not a point');
    is($g->stones('white'), 22, 'twenty-two white stones');
    is($g->stones('black'), 22, 'twenty-two black');
    is($g->stones('red'), undef, 'and red is not a side');
    is_deeply([ $g->legal_strings ], [ qw(d2-e3A d3-e3A d3-e3W e2-e3A f2-e3A) ], 'the five openings');
    is_deeply([ $g->starts ], [ qw(d2 e2 f2 d3) ], 'four stones can begin a move');
    is(scalar($g->steps), 5, 'by five steps');
    ok(!$g->can_stop, 'there is nothing to stop');
    is_deeply([ $g->moves ], [], 'no move has been made');
    is($g->in_progress, undef, 'and none is in progress');
    is_deeply([ $g->ply, $g->quiet, $g->quiet_limit, $g->repeats ], [ 0, 0, 60, 1 ], 'ply 0, quiet 0 of 60, the position seen once');
    like($g->signature, qr/\A[0-9a-f]{16}\z/, 'a signature of sixteen hex characters');
    ok(!$g->in_chain, 'no chain');
    is($g->chain_at, undef, 'and no stone in one');
};

subtest 'a whole move' => sub {
    my $g = $G->new;
    my $move = $g->play('e2-e3A');
    isa_ok($move, 'Game::Fanorona::Move');
    is(format_move($move), 'e2-e3A', 'play returns the move');
    is(scalar($move->taken), 2, 'which took two');
    is($g->turn, 'black', 'Black to move');
    is($g->stones('black'), 20, 'with twenty stones');
    is_deeply([ $g->moves ], [ 'e2-e3A' ], 'the move is in the log');
    is($g->ply, 1, 'ply 1');
    is($g->position_counted, 'bbbb1bbbb/bbbb1bbbb/bwbwwbwbw/wwww1wwww/wwwwwwwww b 0 2', 'the position with its counts: move 2');

    # A MOVE IS PLAYED WHOLE OR NOT AT ALL. The first step of this one is legal
    # and the second goes the same way again: nothing of it is played.
    my $c = $G->new(position => '9/2b6/9/1w1b5/8b w');
    ok(!$c->play('b2-c2A-d2A'), 'a move whose second step is refused is refused');
    is($c->error->code, 'same_direction', 'for the second step\'s reason');
    is($c->position, '9/2b6/9/1w1b5/8b w', 'and its first step was not left played');
    ok(!$c->in_chain, 'no move is in progress');
    is($c->turn, 'white', 'it is still White to move');
    is_deeply([ $c->moves ], [], 'and nothing is in the log');

    # a Move object is a move
    my ($only) = $g->legal;
    ok($g->play($only), 'a Move from legal() is played as it stands');
    is_deeply([ $g->moves ], [ 'e2-e3A', 'f4-e5W' ], 'and logged as its string');
};

subtest 'a move a step at a time' => sub {
    #  4  . . b . .      b2-c2 takes d2, and c2-c3 then takes c4
    #  2  . w . b .
    my $g = $G->new(position => '9/2b6/9/1w1b5/8b w');
    is_deeply([ map { $_->{string} } $g->steps ], [ 'b2-c2A' ], 'one step to begin with');
    my $step = $g->step('b2-c2A');
    is_deeply($step, { from => 'b2', to => 'c2', how => 'approach', takes => [ 'd2' ], string => 'b2-c2A' },
        'step returns the step described');
    is($g->turn, 'white', 'the turn has not passed');
    ok($g->in_chain, 'a move is in progress');
    is($g->chain_at, 'c2', 'on c2');
    is($g->in_progress, 'b2-c2A', 'in_progress says how far it has got');
    ok($g->can_stop, 'it may be stopped');
    is_deeply([ $g->moves ], [], 'and is not in the log yet');
    is_deeply([ map { $_->{string} } $g->steps ], [ 'c2-c3A' ], 'or go on, one way');
    is(scalar(my @none = $g->legal), 0, 'legal lists nothing in the middle of a move');

    ok($g->stop, 'stop');
    is($g->turn, 'black', 'and the turn passes');
    is_deeply([ $g->moves ], [ 'b2-c2A' ], 'the move, as far as it went, is in the log');
    is($g->in_progress, undef, 'and nothing is in progress');
    is($g->at('c4'), 'black', 'c4 was left standing');

    # the same game, going on instead: the chain closes itself
    my $h = $G->new(position => '9/2b6/9/1w1b5/8b w');
    $h->step('b2-c2A');
    $h->step('c2-c3A');
    is($h->turn, 'black', 'after the second step there is nothing more to take, and the turn passes of itself');
    is_deeply([ $h->moves ], [ 'b2-c2A-c3A' ], 'the two steps are one move in the log');
    ok(!$h->can_stop, 'with nothing to stop');

    # and the two ways of playing make the same game
    my $whole = $G->new(position => '9/2b6/9/1w1b5/8b w');
    $whole->play('b2-c2A-c3A');
    is($whole->position, $h->position, 'played whole, the same position');
    is_deeply([ $whole->moves ], [ $h->moves ], 'and the same log');
    my $short = $G->new(position => '9/2b6/9/1w1b5/8b w');
    $short->play('b2-c2A');
    is($short->position, $g->position, 'and the short move, played whole, is the step and the stop');
};

subtest 'a letter left off' => sub {
    my $g = $G->new;
    ok($g->play('e2-e3'), 'e2-e3 with no letter is played: it can only be an approach');
    is_deeply([ $g->moves ], [ 'e2-e3A' ], 'and the log has the letter');
    my $h = $G->new;
    ok(!$h->play('d3-e3'), 'd3-e3 with no letter is not: it could take either way');
    is($h->error->code, 'choose_capture', 'and the refusal asks which');
    ok($h->step('d3-e3W'), 'with its letter it is played');
    is($h->at('c3'), undef, 'and takes c3');
    is($h->at('f3'), 'black', 'and not f3');
};

subtest 'preview' => sub {
    my $g = $G->new;
    my $before = $g->position;
    is($g->preview('e2-e3A'), 'bbbb1bbbb/bbbb1bbbb/bwbwwbwbw/wwww1wwww/wwwwwwwww b', 'the position the move would leave');
    is($g->position, $before, 'and the game has not moved');
    is_deeply([ $g->moves ], [], 'nor logged anything');
    is($g->turn, 'white', 'nor passed the turn');
    is($g->preview('a1-a2'), undef, 'a move that would be refused has no preview');
    is($g->error->code, 'point_taken', 'and the refusal says why');
    my $chain = $G->new(position => '9/2b6/9/1w1b5/8b w');
    is($chain->preview('b2-c2A'), '9/2b6/9/2w6/8b b', 'the short move of a chain, previewed, includes its stop');
    is($chain->preview('b2-c2A-c3A'), '9/9/2w6/9/8b b', 'and the long one takes both');
};

subtest 'the endings the rules make' => sub {
    my $won = $G->new(position => '9/9/w1b6/9/9 w');
    $won->play('a3-b3A');
    ok($won->over, 'the last stone taken: over');
    is($won->turn, undef, 'nobody is to move');
    my $r = $won->result;
    isa_ok($r, 'Game::Fanorona::Result');
    is_deeply([ $r->how, $r->winner, $r->moves, $r->position ], [ 'stones', 'white', 1, '9/9/1w7/9/9 b' ], 'stones, white, one move, the last position');
    is($won->winner, 'white', 'winner');
    is(scalar(my @none = $won->steps), 0, 'no steps are offered');
    is(scalar(my @no = $won->legal), 0, 'nor moves');
    is(scalar(my @st = $won->starts), 0, 'nor starts');

    my $stuck = $G->new(position => '9/9/bb7/b8/wbb6 b');
    $stuck->play('b3-b2');
    is_deeply([ $stuck->result->how, $stuck->result->winner ], [ 'no_moves', 'black' ], 'a side with no move has lost');

    my @round = ('a1-a2', 'i5-i4', 'a2-a1', 'i4-i5');
    my $rep = $G->new(position => '8b/9/9/9/w8 w', script => [ @round, @round ]);
    is_deeply([ $rep->result->how, $rep->result->winner ], [ 'repetition', undef ], 'the third time is a draw');
    ok($rep->result->is_draw, 'and says so');

    my $quiet = $G->new(variant => { board => 'sivy', quiet_limit => 3, repeat => 0 }, position => '8b/9/9/9/w8 w',
        script => [ 'a1-a2', 'i5-i4', 'a2-a3' ]);
    is($quiet->result->how, 'quiet', 'the quiet limit');
    my $cap = $G->new(variant => { board => 'sivy', quiet_limit => 0, repeat => 0, ply_cap => 2 }, position => '8b/9/9/9/w8 w',
        script => [ 'a1-a2', 'i5-i4' ]);
    is($cap->result->how, 'ply_cap', 'and the cap');
};

subtest 'resigning' => sub {
    my $g = $G->new;
    $g->play('d3-e3A');
    ok($g->resign('white'), 'White resigns, though it is Black\'s move');
    ok($g->over, 'the game is over');
    is_deeply([ $g->result->how, $g->result->winner, $g->result->loser ], [ 'resign', 'black', 'white' ], 'resign, won by black');
    is($g->result->moves, 1, 'after one move');
    is($g->turn, undef, 'and nobody is to move');
    is(scalar(my @none = $g->steps), 0, 'no step is offered after it');
    is(scalar(my @no = $g->legal), 0, 'nor a move, though the board underneath has four');
    is(scalar(my @st = $g->starts), 0, 'nor a stone to start one');
    ok(!$g->can_stop, 'nor a stop');

    my $mid = $G->new(position => '9/2b6/9/1w1b5/8b w');
    $mid->step('b2-c2A');
    ok($mid->resign('black'), 'a side may resign in the middle of the other\'s move');
    is($mid->result->winner, 'white', 'and the other side has won');
};

subtest 'agreeing a draw' => sub {
    my $g = $G->new;
    is($g->draw_offered_by, undef, 'no offer to begin with');
    ok($g->offer_draw('white'), 'White offers');
    is($g->draw_offered_by, 'white', 'the offer stands');
    ok(!$g->over, 'the game goes on');
    ok($g->decline_draw('black'), 'Black declines');
    is($g->draw_offered_by, undef, 'and the offer is gone');

    ok($g->offer_draw('black'), 'Black may offer on White\'s move');
    ok($g->accept_draw('white'), 'White accepts');
    ok($g->over, 'the game is over');
    is_deeply([ $g->result->how, $g->result->winner ], [ 'agreement', undef ], 'by agreement, with no winner');
    ok($g->result->is_draw, 'a draw');
    is($g->draw_offered_by, undef, 'and no offer is left standing');

    # AN OFFER LAPSES WHEN THE SIDE THAT MADE IT MOVES AGAIN
    my $h = $G->new;
    $h->offer_draw('white');
    $h->play('d3-e3A');
    is($h->draw_offered_by, undef, 'White offered and then moved: the offer has lapsed');
    $h->offer_draw('white');
    $h->play('c3-d3A');
    is($h->draw_offered_by, 'white', 'White offered and Black moved: the offer stands');
    ok($h->accept_draw('black'), 'and Black may still take it');

    # a step is not a move: the offer stands until the move is complete
    my $c = $G->new(position => '9/2b6/9/1w1b5/8b w');
    $c->offer_draw('white');
    $c->step('b2-c2A');
    is($c->draw_offered_by, 'white', 'in the middle of the offerer\'s move, the offer still stands');
    $c->stop;
    is($c->draw_offered_by, undef, 'and lapses when the move is done');
};

subtest 'what new takes, and refuses' => sub {
    is($G->new(variant => 'telo')->position, 'bbb/w1b/www w', 'a variant by name');
    is($G->new(variant => 'sivy,quiet_limit=40')->quiet_limit, 40, 'by its one-line form');
    is($G->new(variant => { board => 'dimy', quiet_limit => 9 })->quiet_limit, 9, 'by a hash of fields');
    my $v = Game::Fanorona::Variant->named('dimy');
    is($G->new(variant => $v)->variant, $v, 'or as an object, which is kept');
    my $from = $G->new(variant => 'sivy,quiet_limit=40', position => '9/9/2bw1b3/9/9 w');
    is($from->position, '9/9/2bw1b3/9/9 w', 'a position to begin from');
    is($from->quiet_limit, 40, 'keeps the variant\'s limits');
    is($from->variant->start, '9/9/2bw1b3/9/9 w', 'and becomes the variant\'s start');
    is($G->new(first => 'white')->turn, 'white', 'first may be given as white');
    is_deeply([ $G->new(script => [ 'd3-e3A', 'c3-d3W' ])->moves ], [ 'd3-e3A', 'c3-d3W' ], 'a script is played');

    ok(!eval { $G->new(first => 'black'); 1 }, 'first as black croaks');
    like($@, qr/White moves first/, 'saying who does');
    ok(!eval { $G->new(variant => 'grande'); 1 }, 'a variant that is not one croaks');
    like($@, qr/'grande' is not a variant/, 'naming it');
    ok(!eval { $G->new(variant => [ 'sivy' ]); 1 }, 'so does a variant that is the wrong kind of thing');
    ok(!eval { $G->new(variant => { colour => 'red' }); 1 }, 'and a hash with a field that is not one');
    ok(!eval { $G->new(position => '9/9/9/9 w'); 1 }, 'a position that will not load croaks');
    ok(!eval { $G->new(variant => 'telo', position => '9/9/9/9/9 w'); 1 }, 'so does one of another size than the board');
    ok(!eval { $G->new(script => 'd3-e3A'); 1 }, 'a script that is not a list croaks');
    ok(!eval { $G->new(script => [ 'd3-e3A', 'a1-a2' ]); 1 }, 'and a script with a move that is refused');
    like($@, qr/move 2 of the script, 'a1-a2', was refused: it is not your turn|move 2 of the script, 'a1-a2', was refused: that stone is not yours/,
        'naming the move and saying why');

    # A NAME THAT IS NOT ONE. Object::Proto::Sugar hands BUILD no arguments, so
    # this class cannot look for one, and what Sugar does with it depends on
    # where it comes. FIRST, the whole list is read by POSITION, in the order
    # the attributes are declared, and the call croaks about something else.
    # AFTER a name that is known, it is dropped and nothing is said.
    ok(!eval { $G->new(varient => 'telo'); 1 }, 'a misspelt name that comes first croaks');
    like($@, qr/'varient' is not a variant/, 'because it was read by position, as the variant');
    is_deeply([ $G->new(variant => 'telo', scirpt => [ 'a2-b2A' ])->moves ], [],
        'a misspelt name after a known one is dropped: the script was never played');
    is($G->new('telo')->variant->name, 'telo', 'and so a variant may be given by position, which is Sugar\'s doing and not a promise');
};

subtest 'a game played again' => sub {
    my $roll = roller(606);
    my ($games, @bad) = (0);
    for my $n (1 .. 60) {
        my $g = $G->new;
        while (!$g->over && $g->ply < 200) {
            my @legal = $g->legal_strings;
            $g->play($legal[ $roll->(scalar @legal) ]) or die $g->error->message;
        }
        $games++;
        my ($again, $error, $at) = $G->replay([ $g->moves ]);
        push @bad, "game $n: refused at move $at" if $error;
        push @bad, "game $n: replayed to another position" unless $again->position eq $g->position;
        push @bad, "game $n: replayed to another result"
            unless ($again->result ? $again->result->how : '') eq ($g->result ? $g->result->how : '');
        my ($text_game, $why, $line) = $G->from_text($g->as_text(white => 'Rakoto'));
        push @bad, "game $n: its text was refused, $why at line $line" unless $text_game;
        push @bad, "game $n: its text replayed to another position" if $text_game && $text_game->position ne $g->position;
    }
    is($games, 60, 'sixty games played to their end');
    is(scalar(@bad), 0, 'each replayed from its moves and from its text to the same position and result')
        or diag join "\n", @bad[0 .. ($#bad < 3 ? $#bad : 3)];
};

subtest 'a log that has been edited' => sub {
    my @moves = ('d3-e3A', 'c3-d3A', 'e2-e4');
    my ($game, $error, $at) = $G->replay(\@moves);
    isa_ok($error, 'Game::Fanorona::Error');
    is($at, 3, 'refused at the third move');
    is($error->code, 'not_adjacent', 'for its own reason');
    is($error->move, 'e2-e4', 'carrying the move');
    is_deeply([ $game->moves ], [ 'd3-e3A', 'c3-d3A' ], 'and the game is returned as far as it got');

    my ($ok, $none, $n) = $G->replay([ 'a2-b2A' ], variant => 'telo');
    is_deeply([ $none, $n ], [ undef, undef ], 'a replay that works returns no error and no number');
    is($ok->variant->name, 'telo', 'and takes the arguments new takes');
    ok(!eval { $G->replay('d3-e3A'); 1 }, 'replay croaks on something that is not a list');

    # as text
    my $g = $G->new(variant => { board => 'sivy', quiet_limit => 40 }, script => [ 'd3-e3A', 'c3-d3A' ]);
    $g->resign('white');
    is($g->as_text(white => 'Rakoto', black => 'Rasoa'),
        "fanorona 1\nvariant sivy\nquiet_limit 40\nwhite Rakoto\nblack Rasoa\nresult resign black\nmoves\nd3-e3A\nc3-d3A\n",
        'the text of a game: only what is not the default, the names, the result, the moves');
    my $text = "fanorona 1\nvariant sivy\nquiet_limit 40\nmoves\nd3-e3A\nc3-d3A\na1-a2\n";
    my ($t, $why, $line) = $G->from_text($text);
    is($t, undef, 'a text with a move that is refused gives no game');
    is($why, 'point_taken', 'the refusal\'s code');
    is($line, 7, 'and the line the move is on');
    is_deeply([ ($G->from_text("fanorona 1\nmoves\nb2-c4\n"))[1, 2] ], [ 'not_adjacent', 3 ], 'a text that is malformed gives the notation\'s word and line');
    is_deeply([ ($G->from_text('nonsense'))[1, 2] ], [ 'not_a_game', 1 ], 'and so does text that is not a game at all');
    my ($small) = $G->from_text("fanorona 1\nvariant telo\nstart bbb/b1w/www w\nrepeat 0\nmoves\nc2-b2A\n");
    # c2 steps west to b2 and stands next to a2: a2 is taken, and nothing else
    is($small->position, 'bbb/1w1/www b', 'a game on a small board from another start');
    is($small->variant->repeat, 0, 'with its limits');
};

# FOUND BY THE SOAK, IN THE PACKAGING PHASE. `at` was in the load test's list
# of methods and in no assertion anywhere, and it said every point of the
# FIRST RANK was empty: the point was parsed in scalar context, which gave the
# rank, and rank 1 is 0. So every point is asked, on every board, and the
# answers are compared with the position string read here a second time.
subtest 'at: every point of every board' => sub {
    for my $name (qw(sivy dimy telo)) {
        my $g = Game::Fanorona->new(variant => $name);
        my ($board) = split / /, $g->position;
        my @ranks = reverse split m{/}, $board;
        my ($asked, @wrong, %count) = (0);
        for my $rank (0 .. $#ranks) {
            (my $row = $ranks[$rank]) =~ s/([0-9])/'.' x $1/ge;
            my @cells = split //, $row;
            for my $file (0 .. $#cells) {
                my $point = chr(97 + $file) . ($rank + 1);
                my $want = { w => 'white', b => 'black' }->{ $cells[$file] };
                my $got = $g->at($point);
                $asked++;
                $count{ $got // 'empty' }++;
                push @wrong, "$point is " . ($got // 'undef') . ', not ' . ($want // 'undef')
                    unless ($got // '') eq ($want // '');
            }
        }
        is($asked, $g->variant->cols * $g->variant->rows, "$name: $asked points asked");
        is("@wrong", '', "$name: and each is what the position string says");
        is($count{white}, $g->stones('white'), "$name: $count{white} white stones seen, which is the count");
        is($count{black}, $g->stones('black'), "$name: and $count{black} black");
        is($count{empty}, 1, "$name: one point empty, the centre");
    }
    my $g = Game::Fanorona->new;
    is($g->at('a1'), 'white', 'a1, the corner whose file and rank are both 0 underneath, is white');
    is($g->at('e3'), undef, 'the centre is empty');
    is($g->at($_ // 'undef'), undef, 'off the board: ' . ($_ // 'undef')) for 'j1', 'a6', 'a0', '', 'e', '33';
    is(Game::Fanorona->new(variant => 'telo')->at('d1'), undef, 'd1 is not a point of three by three');
    is(Game::Fanorona->new(variant => 'telo')->at('c3'), 'black', 'and c3 is its far corner');
    $g->play('d3-e3A');
    is($g->at('e3'), 'white', 'after d3-e3A the stone is on e3');
    is($g->at('d3'), undef, 'd3 is empty');
    is($g->at('f3'), undef, 'and so is f3, which it took');
};

done_testing();
