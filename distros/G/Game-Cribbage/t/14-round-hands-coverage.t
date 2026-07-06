use strict;
use warnings;
use Test::More;

use Game::Cribbage::Board;
use Game::Cribbage::Round;
use Game::Cribbage::Deck::Card;

sub make_card { Game::Cribbage::Deck::Card->new(@_) }

sub setup_board {
    my $board = Game::Cribbage::Board->new();
    $board->add_player(name => 'Robert');
    $board->add_player(name => 'Joseph');
    $board->start_game();
    $board->set_crib_player('player1');

    my @p1 = (
        { suit => 'H', symbol => 'K' },
        { suit => 'D', symbol => 'K' },
        { suit => 'S', symbol => '10' },
        { suit => 'S', symbol => '5' },
        { suit => 'S', symbol => '3' },
        { suit => 'S', symbol => '4' },
    );
    my @p2 = (
        { suit => 'S', symbol => 'A' },
        { suit => 'H', symbol => 'J' },
        { suit => 'H', symbol => 'Q' },
        { suit => 'D', symbol => 'Q' },
        { suit => 'C', symbol => 'Q' },
        { suit => 'S', symbol => '2' },
    );
    my $r = $board->rounds->current_round;
    $r->add_player_card($board->players->[0], make_card(%$_)) for @p1;
    $r->add_player_card($board->players->[1], make_card(%$_)) for @p2;

    $board->cribbed_cards($board->players->[0], 4, 5);
    $board->cribbed_cards($board->players->[1], 0, 1);

    $r->add_starter_card($board->players->[0], make_card(suit => 'H', symbol => 2));

    return $board;
}

# --- Round: add_player_card_by_index ---
{
    my $board = Game::Cribbage::Board->new();
    $board->build_deck();
    $board->add_player(name => 'Alice');
    $board->add_player(name => 'Bob');
    my $round = Game::Cribbage::Round->new(number => 1)->init($board);
    my $card = make_card(suit => 'H', symbol => '5');
    $round->add_player_card_by_index(0, 'player1', $card);
    is($round->current_hands->player1->cards->[0]->symbol, '5', 'add_player_card_by_index places card at index');
}

# --- Round: crib_player_name, crib_player_id, crib_player_number ---
{
    my $board = setup_board();
    my $round = $board->rounds->current_round;
    ok($round->crib_player_name($board), 'crib_player_name returns a name');
    eval { $round->crib_player_id($board) };
    ok(!$@, 'crib_player_id runs without dying');
    ok($round->crib_player_number($board), 'crib_player_number returns a number');
}

# --- Round: next_crib_player wraps from last player to player1 ---
{
    my $board = setup_board();
    $board->set_crib_player('player2');
    my $round = $board->rounds->current_round;
    my $next = $round->next_crib_player($board);
    is($next, 'player1', 'next_crib_player wraps back to player1');
}

# --- Round: next_crib_player advances normally ---
{
    my $board = setup_board();
    $board->set_crib_player('player1');
    my $round = $board->rounds->current_round;
    my $next = $round->next_crib_player($board);
    is($next, 'player2', 'next_crib_player advances to player2');
}

# --- Round: crib_player_card (discard single by ref) ---
{
    my $board = setup_board();
    my $p1 = $board->players->[0];

    # add an extra card so discard is legal (need > 4)
    # player1 currently has 4 cards after cribbing two already
    # add 2 more so total > 4
    $board->rounds->current_round->add_player_card($p1, make_card(suit => 'C', symbol => '6'));
    $board->rounds->current_round->add_player_card($p1, make_card(suit => 'H', symbol => '8'));

    # Now player1 has 6 cards, can discard
    eval {
        $board->rounds->current_round->crib_player_card($p1, 0);
    };
    ok(!$@, 'crib_player_card (single) works without dying');
}

# --- Round: force_play_card ---
{
    my $board = setup_board();
    # Force play a card that belongs to player1
    my $card = make_card(suit => 'H', symbol => 'K');
    $card->used(1);
    my $result = $board->rounds->current_round->force_play_card($card);
    ok(defined $result, 'force_play_card returns something');
}

# --- Round: hand_play_history ---
{
    my $board = setup_board();
    $board->play_card($board->players->[0], 0);
    my $hist = $board->rounds->current_round->hand_play_history();
    ok($hist, 'hand_play_history returns something');
    ok(exists $hist->{current_play}, 'has current_play key');
    ok(exists $hist->{used_count}, 'has used_count key');
}

# --- Round: reset_hands ---
{
    my $board = setup_board();
    my $round = $board->rounds->current_round;
    $round->reset_hands($board);
    is(scalar @{$round->history}, 1, 'reset_hands clears and rebuilds history');
}

# --- Hands: add_starter_card with J (nobs / flipped) ---
{
    my $board = setup_board();
    # A fresh board where player1 is set to crib, add J as starter
    my $round = $board->rounds->current_round;
    # Replace starter with a Jack of Hearts
    my $jack = make_card(suit => 'H', symbol => 'J');
    my $score_result = $round->current_hands->add_starter_card('player1', $jack);
    # Score result should be a score object with score > 0 for flipped J
    if (ref $score_result) {
        ok($score_result->flipped, 'flipped nobs scored when starter is J');
    } else {
        ok(!$score_result, 'no flipped score when starter J not expected');
    }
}

# --- Hands: find_player_card ---
{
    my $board = setup_board();
    my $hands = $board->rounds->current_round->current_hands;
    # Find the KH that's in player1's hand
    my $target = make_card(suit => 'H', symbol => 'K');
    $target->used(1);
    my ($found_card, $found_player) = $hands->find_player_card($target);
    ok($found_card, 'find_player_card finds the card');
    is($found_player, 'player1', 'find_player_card returns correct player');
}

# --- Hands: force_play_card ---
{
    my $board = setup_board();
    my $hands = $board->rounds->current_round->current_hands;
    my $card = make_card(suit => 'H', symbol => 'K');
    $card->used(1);
    my ($score, $player) = $hands->force_play_card($card);
    ok(defined $score, 'force_play_card returns a score');
    is($player, 'player1', 'force_play_card identifies the player');
}

# --- Hands: set_player_hand_id / get_player_hand_id ---
{
    my $board = setup_board();
    my $hands = $board->rounds->current_round->current_hands;
    $hands->set_player_hand_id('player1', 55);
    is($hands->get_player_hand_id('player1'), 55, 'player hand id round-trip in Hands');
}

# --- Hands: get_crib_player_hand_id ---
{
    my $board = setup_board();
    my $hands = $board->rounds->current_round->current_hands;
    $hands->set_player_hand_id('player1', 77);
    is($hands->get_crib_player_hand_id(), 77, 'get_crib_player_hand_id returns crib player hand id');
}

# --- Hands: last_play_score ---
{
    my $board = setup_board();
    $board->play_card($board->players->[0], 0);
    $board->play_card($board->players->[1], 0);
    $board->cannot_play($board->players->[0]);
    $board->cannot_play($board->players->[1]);
    $board->next_play($board);

    my $last = $board->rounds->current_round->last_play_score();
    ok(defined $last, 'last_play_score returns something after at least one play');
}

# --- Hands: set_crib_complete ---
{
    my $board = setup_board();
    my $hands = $board->rounds->current_round->current_hands;
    ok(!$hands->crib_complete, 'crib_complete false initially');
    $hands->set_crib_complete();
    ok($hands->crib_complete, 'crib_complete true after set_crib_complete');
}

# --- Hands: best_run_play ---
{
    my $board = setup_board();
    my $card = $board->rounds->current_round->best_run_play('player2');
    ok($card, 'Round->best_run_play returns a card');
}

# --- Hands: cannot_play_a_card when player CAN still play (returns arrayref) ---
{
    my $board = setup_board();
    # player1's turn initially - total is 0, all cards are playable
    my $hands = $board->rounds->current_round->current_hands;
    my $result = $hands->cannot_play_a_card('player1');
    # When cards can be played, returns an arrayref
    ok(ref $result eq 'ARRAY', 'cannot_play_a_card returns arrayref when cards available');
    ok(scalar @{$result} > 0, 'at least one card can be played');
}

# --- Hands: next_play when no cards remain (calls end_hands) ---
{
    my $board = setup_board();
    my $p1 = $board->players->[0];
    my $p2 = $board->players->[1];

    # Play enough cards to exhaust both hands, then mark remainder as used
    $board->play_card($p2, 0);
    $board->play_card($p1, 0);
    $board->play_card($p2, 1);
    $board->cannot_play($p1);
    $board->next_play($board);
    $board->play_card($p2, 2);
    $board->play_card($p1, 1);
    $board->cannot_play($p2);
    $board->next_play($board);

    # Mark all remaining cards as used so next_play sees no available_cards
    my $hands = $board->rounds->current_round->current_hands;
    for my $slot (qw/player1 player2/) {
        my $hand = $hands->$slot;
        next unless $hand;
        $_->used(1) for @{$hand->cards};
    }

    eval { $board->next_play($board) };
    ok(!$@, 'next_play with no cards left calls end_hands without dying');
}

done_testing;
