use strict;
use warnings;
use Test::More;

use Game::Cribbage::Player::Hand;
use Game::Cribbage::Deck::Card;
use Game::Cribbage::Play;

sub make_card { Game::Cribbage::Deck::Card->new(@_) }

sub hand_with_cards {
    my ($player, @specs) = @_;
    my $hand = Game::Cribbage::Player::Hand->new(player => $player);
    $hand->add(make_card(%$_)) for @specs;
    return $hand;
}

# --- get by index ---
{
    my $hand = hand_with_cards('player1',
        { suit => 'H', symbol => 'K' },
        { suit => 'D', symbol => '5' },
    );
    my $card = $hand->get(0);
    is($card->symbol, 'K', 'get(0) returns first card');
    my $card2 = $hand->get(1);
    is($card2->symbol, '5', 'get(1) returns second card');
}

# --- get by ref (match) ---
{
    my $hand = hand_with_cards('player1',
        { suit => 'H', symbol => 'K' },
        { suit => 'D', symbol => '5' },
    );
    # pass a Card object as the lookup key (match uses ->suit / ->symbol method calls)
    my $lookup = make_card(suit => 'H', symbol => 'K');
    my $found = $hand->get($lookup);
    ok($found, 'get(card-object) finds matching card');
    is($found->suit, 'H', 'get(card-object) returns card with correct suit');
}

# --- get with no match dies ---
{
    my $hand = hand_with_cards('player1', { suit => 'H', symbol => '3' });
    eval { $hand->get(99) };
    like($@, qr/NO CARD FOUND/, 'get with bad index dies');
}

# --- match ---
{
    my $hand = hand_with_cards('player1',
        { suit => 'S', symbol => 'A' },
        { suit => 'H', symbol => '7' },
    );
    my $found = $hand->match(make_card(suit => 'S', symbol => 'A'));
    ok($found, 'match finds card');

    my $not_found = $hand->match(make_card(suit => 'C', symbol => '2'));
    ok(!$not_found, 'match returns 0 when not found');
}

# --- add_by_index ---
{
    my $hand = Game::Cribbage::Player::Hand->new(player => 'player1');
    my $card = make_card(suit => 'H', symbol => '9');
    ok($hand->add_by_index(0, $card), 'add_by_index returns true');
    is($hand->cards->[0]->symbol, '9', 'card placed at correct index');
}

# --- add_crib_card ---
{
    my $hand = Game::Cribbage::Player::Hand->new(player => 'player1');
    my $card = make_card(suit => 'D', symbol => 'Q');
    $hand->add_crib_card($card);
    is(scalar @{$hand->crib}, 1, 'add_crib_card appends to crib');
    is($hand->crib->[0]->symbol, 'Q', 'correct card in crib');
}

# --- discard_cards (multiple at once) error when <= 4 ---
{
    my $hand = hand_with_cards('player1',
        { suit => 'H', symbol => 'K' },
        { suit => 'D', symbol => '5' },
        { suit => 'S', symbol => '3' },
        { suit => 'C', symbol => '2' },
    );
    my $crib = Game::Cribbage::Player::Hand->new(player => 'player1');
    eval { $hand->discard_cards([make_card(suit => 'H', symbol => 'K')], $crib) };
    like($@, qr/CANNOT DISCARD/, 'discard_cards dies when <= 4 cards');
}

# --- discard (single) error when <= 4 ---
{
    my $hand = hand_with_cards('player1',
        { suit => 'H', symbol => 'K' },
        { suit => 'D', symbol => '5' },
        { suit => 'S', symbol => '3' },
        { suit => 'C', symbol => '2' },
    );
    my $crib = Game::Cribbage::Player::Hand->new(player => 'player1');
    eval { $hand->discard(0, $crib) };
    like($@, qr/CANNOT DISCARD/, 'discard dies when <= 4 cards');
}

# --- discard_cards (the multi-card variant) ---
{
    my $hand = hand_with_cards('player1',
        { suit => 'H', symbol => 'K' },
        { suit => 'D', symbol => '5' },
        { suit => 'S', symbol => '3' },
        { suit => 'C', symbol => '2' },
        { suit => 'H', symbol => '7' },
        { suit => 'D', symbol => '8' },
    );
    my $crib = Game::Cribbage::Player::Hand->new(player => 'player2');
    my $cards_to_discard = [
        make_card(suit => 'H', symbol => 'K'),
        make_card(suit => 'D', symbol => '5'),
    ];
    my $cribbed = $hand->discard_cards($cards_to_discard, $crib);
    is(scalar @{$hand->cards}, 4, 'hand reduced to 4 after discard_cards');
    is(scalar @{$crib->crib}, 2, 'crib received 2 cards');
    is(scalar @{$cribbed}, 2, 'returns the cribbed cards');
}

# --- card_exists ---
{
    my $hand = hand_with_cards('player1',
        { suit => 'H', symbol => 'K' },
    );
    my $crib = Game::Cribbage::Player::Hand->new(player => 'player1');
    $crib->add_crib_card(make_card(suit => 'D', symbol => '5'));
    $hand->crib($crib->crib);

    ok($hand->card_exists(make_card(suit => 'H', symbol => 'K')), 'card_exists finds in cards');
    ok($hand->card_exists(make_card(suit => 'D', symbol => '5')), 'card_exists finds in crib');
    ok(!$hand->card_exists(make_card(suit => 'C', symbol => '9')), 'card_exists returns 0 when absent');
}

# --- calculate_score without starter ---
{
    my $hand = hand_with_cards('player1',
        { suit => 'H', symbol => 'K' },
        { suit => 'D', symbol => 'K' },
        { suit => 'S', symbol => '5' },
        { suit => 'C', symbol => '5' },
    );
    my $score = $hand->calculate_score();
    ok($score > 0, 'calculate_score without starter returns positive score');
    ok($hand->score, 'score object set');
}

# --- calculate_score with crib ---
{
    my $hand = hand_with_cards('player1',
        { suit => 'H', symbol => 'K' },
        { suit => 'D', symbol => 'K' },
        { suit => 'S', symbol => '5' },
        { suit => 'C', symbol => '5' },
    );
    $hand->starter(make_card(suit => 'H', symbol => '5'));
    $hand->add_crib_card(make_card(suit => 'S', symbol => 'A'));
    $hand->add_crib_card(make_card(suit => 'D', symbol => '2'));
    $hand->add_crib_card(make_card(suit => 'C', symbol => '3'));
    $hand->add_crib_card(make_card(suit => 'H', symbol => '4'));
    my $score = $hand->calculate_score();
    ok(defined $score, 'calculate_score with crib returns a score');
    ok($hand->crib_score, 'crib_score set when crib present');
}

# --- identify_worst_cards ---
{
    my $hand = hand_with_cards('player1',
        { suit => 'H', symbol => 'K' },
        { suit => 'D', symbol => 'K' },
        { suit => 'S', symbol => '10' },
        { suit => 'S', symbol => '5' },
        { suit => 'S', symbol => '3' },
        { suit => 'S', symbol => '4' },
    );
    my ($worst_cards, @indexes) = $hand->identify_worst_cards();
    is(scalar @{$worst_cards}, 2, 'identify_worst_cards returns 2 cards to discard');
    is(scalar @indexes, 2, 'returns 2 indexes');
}

# --- identify_worst_cards error ---
{
    my $hand = hand_with_cards('player1',
        { suit => 'H', symbol => 'K' },
        { suit => 'D', symbol => 'Q' },
    );
    eval { $hand->identify_worst_cards() };
    like($@, qr/cards do not exists/, 'identify_worst_cards dies with wrong count');
}

# --- validate_crib_cards - all found ---
{
    my $hand = Game::Cribbage::Player::Hand->new(player => 'player1');
    $hand->add_crib_card(make_card(suit => 'H', symbol => '5'));
    $hand->add_crib_card(make_card(suit => 'D', symbol => '3'));
    my $result = $hand->validate_crib_cards([
        make_card(suit => 'H', symbol => '5'),
        make_card(suit => 'D', symbol => '3'),
    ]);
    is($result, 1, 'validate_crib_cards returns 1 when all found');
}

# --- validate_crib_cards - not all found (replaces crib) ---
{
    my $hand = Game::Cribbage::Player::Hand->new(player => 'player1');
    $hand->add_crib_card(make_card(suit => 'H', symbol => '5'));
    my $replacement = [
        make_card(suit => 'C', symbol => 'A'),
        make_card(suit => 'D', symbol => '2'),
    ];
    my $result = $hand->validate_crib_cards($replacement);
    is($result, 1, 'validate_crib_cards returns 1 even when replacing');
    is(scalar @{$hand->crib}, 2, 'crib replaced with new cards');
}

# --- best_run_play - with valid cards ---
{
    my $hand = hand_with_cards('player1',
        { suit => 'H', symbol => '5' },
        { suit => 'D', symbol => '6' },
        { suit => 'S', symbol => '7' },
        { suit => 'C', symbol => 'K' },
    );
    my $play = Game::Cribbage::Play->new(next_to_play => 'player1');
    $hand->player('player1');
    my $card = $hand->best_run_play($play);
    ok($card, 'best_run_play returns a card');
}

# --- best_run_play - all cards used returns go ---
{
    my $hand = hand_with_cards('player1',
        { suit => 'H', symbol => 'K' },
        { suit => 'D', symbol => 'K' },
    );
    # Mark all as used
    $_->used(1) for @{$hand->cards};
    my $play = Game::Cribbage::Play->new(next_to_play => 'player1', total => 30);
    my $result = $hand->best_run_play($play);
    ok($result->go, 'best_run_play returns go error when no valid cards');
}

done_testing;
