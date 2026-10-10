use strict;
use warnings;
use Test::More;

use Game::RoyalUr;
use Game::RoyalUr::Error;
my $G = 'Game::RoyalUr';

# A game standing on a position with a roll already decided, so that each
# refusal can be produced by the one move written for it.
sub at_roll {
    my ($position, $roll, $rules) = @_;
    return $G->new(script => [ { roll => $roll } ], position => $position, (defined $rules ? (rules => $rules) : ()));
}

sub state { join ' | ', $_[0]->position, $_[0]->key, $_[0]->ply, $_[0]->rolls, (defined $_[0]->roll ? $_[0]->roll : '-') }

sub refused {
    my ($game, $move, $code, $what) = @_;
    my $before = state($game);
    my $played = $game->play($move);
    ok(!defined $played, "$what: '$move' is not played");
    is($game->error && $game->error->code, $code, "$what: $code");
    is(state($game), $before, "$what: and nothing changed, not the board, not the roll, not the dice");
}

subtest 'the ten codes' => sub {
    is(join(' ', Game::RoyalUr::Error->codes),
        'game_over no_roll bad_move no_piece not_your_piece wrong_distance own_piece safe_rosette overshoot bad_record',
        'in the order they are checked');
    ok(length(Game::RoyalUr::Error->message_for($_)) > 10, "$_ has a sentence") for Game::RoyalUr::Error->codes;
    is(Game::RoyalUr::Error->message_for('nonsense'), undef, 'and a word that is no code has none');
    ok(!eval { Game::RoyalUr::Error->of('nonsense'); 1 }, 'nor can an error be made of it');
};

# EACH REFUSAL, from a move written to produce it.
subtest 'each refusal by name' => sub {
    my $middle = '4xx2/l1ld1d2/1l2xx1l l 2 1 5 0';

    refused(at_roll('4xx2/1d1d4/4xx2 d 0 7 4 1', 1), 'b2-c2', 'game_over', 'a finished game');
    refused($G->new(script => [], first => 'light'), 'hand-d1', 'no_roll', 'a game whose rolls have run out');

    refused(at_roll($middle, 2), 'b1b2',     'bad_move', 'no dash');
    refused(at_roll($middle, 2), '',         'bad_move', 'nothing');
    refused(at_roll($middle, 2), 'e1-d1',    'bad_move', 'a square that does not exist');
    refused(at_roll($middle, 2), 'b1-hand',  'bad_move', 'a move to the hand');

    refused(at_roll($middle, 2), 'b2-d2',    'no_piece', 'an empty square');
    refused(at_roll('4xx2/8/1l2xx2 l 0 6 7 0', 2), 'hand-c1', 'no_piece', 'an empty hand');

    refused(at_roll($middle, 2), 'd2-f2',    'not_your_piece', 'a dark piece, with light to move');

    refused(at_roll($middle, 2), 'hand-b1',  'wrong_distance', 'entering three squares on a roll of 2');
    refused(at_roll($middle, 2), 'a2-b2',    'wrong_distance', 'one square on a roll of 2');
    refused(at_roll($middle, 2), 'c2-a2',    'wrong_distance', 'a move backward');
    refused(at_roll($middle, 2), 'a2-home',  'wrong_distance', 'home from nowhere near it');
    refused(at_roll($middle, 2), 'b1-b3',    'wrong_distance', 'a square the side never visits');

    refused(at_roll($middle, 2), 'a2-c2',    'own_piece', 'onto its own piece on c2');
    refused(at_roll($middle, 1), 'c2-d2',    'safe_rosette', 'onto the dark piece on the rosette');
    refused(at_roll($middle, 3), 'h1-home',  'overshoot', 'h1 needs exactly 2');
    refused(at_roll($middle, 4), 'h1-home',  'overshoot', 'and not a 4 either');
};

subtest 'the same moves under masters' => sub {
    my $middle = '4xx2/l1ld1d2/1l2xx1l l 2 1 5 0';
    my $game = at_roll($middle, 1, 'masters');
    ok($game->play('c2-d2'), 'masters has no safe rosette: c2 takes d2');
    is($game->error, undef, 'and a move that is played leaves no error');
    refused(at_roll($middle, 1, 'masters'), 'h1-home', 'wrong_distance', 'h1 is step 15 of the long route: a 1 is one short');
    ok(at_roll($middle, 2, 'masters')->play('h1-home'), 'a 2 is exactly home');
    refused(at_roll($middle, 4, 'masters'), 'h1-home', 'overshoot', 'and a 4 is past it');
};

# A MOVE CAN BE WRONG IN MORE THAN ONE WAY, and the first in the list is the
# one reported. Each line below is wrong in the two or three ways it names.
subtest 'the order, pinned' => sub {
    my $middle = '4xx2/l1ld1d2/1l2xx1l l 2 1 5 0';
    refused(at_roll($middle, 2), 'b2-c2', 'no_piece',
        'no piece on b2, AND one square on a roll of 2, AND an own piece on c2');
    refused(at_roll($middle, 3), 'd2-c2', 'not_your_piece',
        'a dark piece, AND backward, AND onto a light piece');
    refused(at_roll($middle, 3), 'a2-c2', 'wrong_distance',
        'two squares on a roll of 3, AND an own piece on c2');
    refused(at_roll($middle, 2), 'a2-d2', 'wrong_distance',
        'three squares on a roll of 2, AND a dark piece on a safe rosette');
    refused(at_roll('4xx2/1d1d4/4xx2 d 0 7 4 1', 1), 'nonsense', 'game_over',
        'a finished game, AND text that is no move');
};

# A MOVE OBJECT IS LOOKED UP LIKE ANY OTHER MOVE. One made for another roll,
# or by another game, is not played because it is an object.
subtest 'a move made for another roll is not a move for this one' => sub {
    my $middle = '4xx2/l1ld1d2/1l2xx1l l 2 1 5 0';
    my ($stale) = grep { $_->from eq 'hand' } at_roll($middle, 1)->legal;
    is($stale->to, 'd1', 'on a roll of 1 the hand enters on d1');
    my $game = at_roll($middle, 2);
    my $before = state($game);
    ok(!defined $game->play($stale), 'handed to a game whose roll is 2, it is not played');
    is($game->error->code, 'wrong_distance', 'because one square is not two');
    is(state($game), $before, 'and nothing changed');
    my ($own) = grep { $_->from eq 'hand' } $game->legal;
    is($game->play($own)->to, 'c1', 'its own move for that roll is played');
};

subtest 'an error is cleared by the next move that is played' => sub {
    my $game = $G->new(seed => 'facade 46', first => 'light');
    ok(!$game->play('hand-d1'), 'a wrong move');
    my $error = $game->error;
    is($error->code, 'wrong_distance', 'is refused');
    is_deeply($error->detail, { from => 'hand', to => 'd1', roll => 2 }, 'with the places and the roll in its detail');
    is($error->message, 'a piece moves exactly as far as the roll', 'and a sentence');
    ok($game->play('hand-c1'), 'the right one');
    is($game->error, undef, 'and the error is gone');
};

# NO SECOND SET OF RULES. For every pair of places there is, in forty positions
# reached by play, a move is played if and only if the generator offers it, and
# a refusal always has a reason of its own: never the fallback.
subtest 'play agrees with legal on every pair of places' => sub {
    my @squares = grep { !/\A[ef][13]\z/ } map { my $f = $_; map { "$f$_" } 1 .. 3 } 'a' .. 'h';
    my @from = ('hand', @squares);
    my @to   = ('home', @squares);
    for my $rules ('finkel', 'masters') {
        my ($pairs, $positions, %seen, @bad) = (0, 0);
        my $game = $G->new(seed => "pairs $rules", rules => $rules);
        my $pick = 0;
        while ($positions < 40 && !$game->is_over) {
            $positions++;
            my %legal = map { $_->from . '-' . $_->to => 1 } $game->legal;
            my $before = state($game);
            for my $from (@from) {
                for my $to (@to) {
                    my $text = "$from-$to";
                    $pairs++;
                    if ($game->play($text)) {
                        push @bad, "$before: $text was played and is not legal" unless $legal{$text};
                        $game->undo;
                        push @bad, "$before: $text did not come back" unless state($game) eq $before;
                    }
                    else {
                        my $code = $game->error->code;
                        $seen{$code}++;
                        push @bad, "$before: $text is legal and was refused as $code" if $legal{$text};
                        push @bad, "$before: $text was refused with no reason of its own" if $code eq 'bad_move';
                    }
                }
            }
            my @moves = $game->legal;
            $game->play($moves[ $pick++ % @moves ]);
            $game->play(($game->legal)[0]) for 1 .. 3;
        }
        is(scalar @bad, 0, "$rules: $pairs pairs over $positions positions") or diag(join "\n", @bad[0 .. ($#bad > 5 ? 5 : $#bad)]);
        ok($seen{$_}, "$rules: among the refusals, $_ ($seen{$_})")
            for qw(no_piece not_your_piece wrong_distance own_piece overshoot);
    }
};

done_testing();
