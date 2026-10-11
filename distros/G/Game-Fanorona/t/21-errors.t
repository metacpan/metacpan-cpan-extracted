use strict;
use warnings;
use Test::More;

use Game::Fanorona;
use Game::Fanorona::Error;
my $G = 'Game::Fanorona';
my $E = 'Game::Fanorona::Error';

subtest 'a refusal as a value' => sub {
    my $e = $E->of('point_taken', move => 'a1-a2');
    isa_ok($e, $E);
    is($e->code, 'point_taken', 'its code');
    is($e->message, 'a stone is standing there', 'its sentence');
    is($e->move, 'a1-a2', 'the move it was about');
    ok($e->is('point_taken'), 'is(its code)');
    ok(!$e->is('no_stone'), 'is not another');
    ok(!$e->is(undef), 'nor nothing');
    is($E->of('game_over')->move, undef, 'a refusal about no move has none');

    my @codes = $E->codes;
    is(scalar(@codes), 21, 'twenty-one codes');
    my %seen;
    is(scalar(grep { $seen{$_}++ } @codes), 0, 'no two the same');
    for my $code (@codes) {
        ok($E->known($code), "$code is known");
        like($E->message_for($code), qr/\A[a-z].*[^.\s]\z/s, "$code has a sentence, with no full stop of its own");
        is($E->of($code)->message, $E->message_for($code), "and of($code) carries it");
    }
    ok(!$E->known('boredom'), 'a code that is not one is not known');
    is($E->message_for('boredom'), undef, 'and has no sentence');
    ok(!eval { $E->of('boredom'); 1 }, 'of croaks on a code that is not one');
    like($@, qr/no such refusal as 'boredom'/, 'naming it');
    ok(!eval { $E->new(code => 'game_over'); 1 }, 'and new croaks whatever it is given');
    like($@, qr/made by Game::Fanorona::Error->of/, 'saying how a refusal is made');
};

# EVERY CODE, EACH FROM A MOVE WRITTEN TO PROVOKE IT AND NOTHING ELSE. A game,
# something done to it, and the one code that must come back.
sub refused {
    my ($game, $do, $want, $what) = @_;
    my $before = $game->position;
    my @got = $do->($game);
    my $error = $game->error;
    ok(!@got || !defined $got[0], "$what: refused");
    is($error ? $error->code : 'NO ERROR', $want, "$what: $want");
    is($game->position, $before, "$what: and the position is as it was");
    return $error;
}

subtest 'every code, provoked' => sub {
    my %provoked;
    my $note = sub { my $e = refused(@_); $provoked{ $e->code }++ if $e; $e };

    # the shape of a move
    $note->($G->new, sub { $_[0]->play('b2c2') }, 'bad_move', 'a move with no dash');
    $note->($G->new, sub { $_[0]->play(undef) }, 'bad_move', 'no move at all');
    $note->($G->new, sub { $_[0]->play('b2-c2a') }, 'bad_move', 'a lower-case letter');
    $note->($G->new, sub { $_[0]->step('d3-e3A-e4A') }, 'bad_move', 'two steps given to step');
    $note->($G->new, sub { $_[0]->play('a5-a6') }, 'off_board', 'a rank that is not one');
    $note->($G->new(variant => 'telo'), sub { $_[0]->play('c2-d2') }, 'off_board', 'a point off a small board');
    $note->($G->new, sub { $_[0]->play('b2-b4') }, 'not_adjacent', 'a step of two points');
    $note->($G->new, sub { $_[0]->play('e2-f3') }, 'no_line', 'a diagonal from a weak point');
    $note->($G->new(position => '8b/9/9/9/w8 w'), sub { $_[0]->play('a1-a2-a1') }, 'paika_in_chain', 'two steps and no letters');

    # the stone
    $note->($G->new, sub { $_[0]->play('e3-e4') }, 'no_stone', 'a move from an empty point');
    $note->($G->new, sub { $_[0]->play('f3-e3A') }, 'not_your_stone', 'a move of the other side\'s stone');
    $note->($G->new, sub { $_[0]->play('a1-a2') }, 'point_taken', 'a move onto a stone');

    # taking
    $note->($G->new, sub { $_[0]->play('e2-e3W') }, 'takes_nothing', 'a withdrawal with nothing behind');
    $note->($G->new(position => '9/9/3w1b3/9/w8 w'), sub { $_[0]->play('a1-a2') }, 'must_capture', 'a paika while a stone can be taken');
    $note->($G->new, sub { $_[0]->play('d3-e3') }, 'choose_capture', 'a step that takes two ways, with no letter');

    # in a chain
    my $chain = sub { my $g = $G->new(position => '9/2b6/7b1/1w1b5/7w1 w'); $g->step('b2-c2A'); $g };
    $note->($chain->(), sub { $_[0]->step('h1-h2A') }, 'not_the_stone', 'another stone, with a move in progress');
    $note->($chain->(), sub { $_[0]->step('c2-d2') }, 'same_direction', 'the same direction again');
    $note->($chain->(), sub { $_[0]->step('c2-b2') }, 'point_revisited', 'back to where it started');
    $note->($chain->(), sub { $_[0]->step('c2-c1') }, 'paika_in_chain', 'a step that takes nothing, after one that took');
    $note->($chain->(), sub { $_[0]->play('h1-h2A') }, 'chain_open', 'a whole move, with a move in progress');
    $note->($chain->(), sub { $_[0]->preview('h1-h2A') }, 'chain_open', 'a preview, with a move in progress');
    $note->($G->new, sub { $_[0]->stop }, 'nothing_to_stop', 'a stop with no move in progress');

    # the two things that are not moves
    $note->($G->new, sub { $_[0]->resign('red') }, 'not_a_side', 'a side that is not one');
    $note->($G->new, sub { $_[0]->offer_draw(undef) }, 'not_a_side', 'no side at all');
    $note->($G->new, sub { $_[0]->accept_draw('white') }, 'no_offer', 'accepting a draw nobody offered');
    $note->($G->new, sub { $_[0]->decline_draw('white') }, 'no_offer', 'declining one');
    $note->($G->new, sub { $_[0]->offer_draw('white'); $_[0]->accept_draw('white') }, 'own_offer', 'accepting one\'s own offer');
    $note->($G->new, sub { $_[0]->offer_draw('white'); $_[0]->offer_draw('black') }, 'offer_standing', 'a second offer');

    # after the end
    my $over = sub { my $g = $G->new; $g->resign('black'); $g };
    $note->($over->(), sub { $_[0]->play('d3-e3A') }, 'game_over', 'a move after the end');
    $note->($over->(), sub { $_[0]->step('d3-e3A') }, 'game_over', 'a step');
    $note->($over->(), sub { $_[0]->stop }, 'game_over', 'a stop');
    $note->($over->(), sub { $_[0]->preview('d3-e3A') }, 'game_over', 'a preview');
    $note->($over->(), sub { $_[0]->continuations }, 'game_over', 'continuations');
    $note->($over->(), sub { $_[0]->resign('white') }, 'game_over', 'resigning');
    $note->($over->(), sub { $_[0]->offer_draw('white') }, 'game_over', 'offering a draw');
    $note->($over->(), sub { $_[0]->accept_draw('white') }, 'game_over', 'accepting one');
    my $won = $G->new(position => '9/9/w1b6/9/9 w', script => [ 'a3-b3A' ]);
    $note->($won, sub { $_[0]->play('b3-c3') }, 'game_over', 'a move after a game the rules ended');

    is_deeply([ sort keys %provoked ], [ sort $E->codes ], 'every one of the twenty-one codes was provoked');
};

subtest 'the move an error carries, and when it is cleared' => sub {
    my $g = $G->new;
    $g->play('a1-a2');
    is($g->error->move, 'a1-a2', 'the error carries the move as it was given');
    is($g->error->message, 'a stone is standing there', 'and its sentence');
    ok($g->play('d3-e3A'), 'a move that is played');
    is($g->error, undef, 'clears the error');
    $g->play('zz');
    is($g->error->move, 'zz', 'a move that is not one is carried as it was typed');
    ok($g->steps, 'asking for the steps is not a call that can refuse');
    is($g->error->code, 'bad_move', 'so it leaves the error where it was');
};

# WHEN SEVERAL WOULD APPLY, ONE IS GIVEN, AND IT IS THE FIRST LOOKED FOR.
subtest 'the order' => sub {
    my $g = $G->new;
    #  e3-f4W: e3 is empty (no_stone); f4 is occupied (point_taken); and
    #  nothing is behind to withdraw from (takes_nothing)
    $g->play('e3-f4W');
    is($g->error->code, 'no_stone', 'an empty point is named before the occupied one it would go to, and before what it would take');
    #  f3-g3A: Black's stone (not_your_stone); g3 is occupied (point_taken)
    $g->play('f3-g3A');
    is($g->error->code, 'not_your_stone', 'whose stone it is before where it would go');
    #  a shape fault is named before anything about the board
    $g->play('e3-e5');
    is($g->error->code, 'not_adjacent', 'and the shape of the move before anything on the board');
};

done_testing();
