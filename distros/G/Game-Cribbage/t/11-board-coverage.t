use strict;
use warnings;
use Test::More;

use Game::Cribbage::Board;
use Game::Cribbage::Deck::Card;

sub make_card { Game::Cribbage::Deck::Card->new(@_) }

sub setup_board {
    my $board = Game::Cribbage::Board->new();
    $board->add_player(name => 'Robert');
    $board->add_player(name => 'Joseph');
    $board->start_game();
    $board->set_crib_player('player1');

    my @p1_cards = (
        make_card(suit => 'H', symbol => 'K'),
        make_card(suit => 'D', symbol => 'K'),
        make_card(suit => 'S', symbol => '10'),
        make_card(suit => 'S', symbol => '5'),
        make_card(suit => 'S', symbol => '3'),
        make_card(suit => 'S', symbol => '4'),
    );
    my @p2_cards = (
        make_card(suit => 'S', symbol => 'A'),
        make_card(suit => 'H', symbol => 'J'),
        make_card(suit => 'H', symbol => 'Q'),
        make_card(suit => 'D', symbol => 'Q'),
        make_card(suit => 'C', symbol => 'Q'),
        make_card(suit => 'S', symbol => '2'),
    );
    for (@p1_cards) { $board->rounds->current_round->add_player_card($board->players->[0], $_) }
    for (@p2_cards) { $board->rounds->current_round->add_player_card($board->players->[1], $_) }

    $board->cribbed_cards($board->players->[0], 4, 5);
    $board->cribbed_cards($board->players->[1], 0, 1);

    $board->rounds->current_round->add_starter_card(
        $board->players->[0],
        make_card(suit => 'H', symbol => 2)
    );

    return $board;
}

# --- add_player_if_not_exists ---
{
    my $board = Game::Cribbage::Board->new();
    $board->add_player(name => 'Alice');

    my ($player, $existed) = $board->add_player_if_not_exists(name => 'Alice');
    ok($player, 'add_player_if_not_exists finds existing player');
    is($existed, 1, 'returns existed=1 for existing player');

    my ($new_p, $new_existed) = $board->add_player_if_not_exists(name => 'Bob');
    ok($new_p, 'add_player_if_not_exists creates new player');
    is($new_existed, 0, 'returns existed=0 for new player');
    is(scalar @{$board->players}, 2, 'board now has 2 players');
}

# --- get_player ---
{
    my $board = Game::Cribbage::Board->new();
    $board->add_player(name => 'Charlie');
    my $p = $board->get_player(name => 'Charlie');
    ok($p, 'get_player finds player by name');
    is($p->name, 'Charlie', 'get_player returns correct player');

    my $missing = $board->get_player(name => 'Nobody');
    ok(!$missing, 'get_player returns undef for unknown name');
}

# --- crib player info ---
{
    my $board = setup_board();

    ok($board->crib_player_identifier, 'crib_player_identifier returns player string');
    # id may be undef if not set at add_player time; just verify method runs without dying
    eval { $board->crib_player_id($board) };
    ok(!$@, 'crib_player_id runs without dying');
    ok($board->crib_player_name($board), 'crib_player_name returns name');
    ok($board->crib_player_number($board), 'crib_player_number returns number');
}

# --- crib_complete / set_crib_complete ---
{
    my $board = setup_board();
    ok(!$board->crib_complete(), 'crib not complete initially');
    $board->set_crib_complete('player1', 1);
    ok($board->crib_complete(), 'crib complete after set');
}

# --- total_player_score ---
{
    my $board = setup_board();
    my $score = $board->total_player_score('player1');
    ok(defined $score, 'total_player_score returns a value');
}

# --- round / hands / play id getters and setters ---
{
    my $board = setup_board();

    $board->set_round_id(42);
    is($board->get_round_id(), 42, 'round id round-trip');

    $board->set_hands_id(99);
    is($board->get_hands_id(), 99, 'hands id round-trip');

    $board->set_play_id(7);
    is($board->get_play_id(), 7, 'play id round-trip');

    $board->set_player_hand_id('player1', 11);
    is($board->get_player_hand_id('player1'), 11, 'player hand id round-trip');

    ok(defined $board->get_crib_player_hand_id(), 'get_crib_player_hand_id returns something');
}

# --- next_to_play / next_to_play_id ---
{
    my $board = setup_board();
    my $ntp = $board->next_to_play();
    ok($ntp, 'next_to_play returns a player object');
    eval { $board->next_to_play_id() };
    ok(!$@, 'next_to_play_id runs without dying');
}

# --- current_play / current_play_cards ---
{
    my $board = setup_board();
    ok($board->current_play(), 'current_play returns play object');
    isa_ok($board->current_play_cards(), 'ARRAY', 'current_play_cards returns arrayref');
}

# --- no_player_can_play / player_cannot_play ---
{
    my $board = setup_board();
    ok(!$board->no_player_can_play(), 'no_player_can_play is false at start');
    ok(!$board->player_cannot_play('player1'), 'player1 can play at start');
    ok(!$board->player_cannot_play('player2'), 'player2 can play at start');
}

# --- best_run_play ---
{
    my $board = setup_board();
    my $card = $board->best_run_play('player2');
    ok($card, 'best_run_play returns a card or go');
}

# --- force_draw_card ---
{
    my $board = setup_board();
    # Force draw a card that's still in the deck
    ok($board->force_draw_card('player1', 0, { suit => 'H', symbol => '7' }), 'force_draw_card from deck');
}

# --- hand_play_history ---
{
    my $board = setup_board();
    # Play a card first to populate play history
    $board->play_card($board->players->[0], 0);
    my $hist = $board->hand_play_history();
    ok($hist, 'hand_play_history returns something');
    ok(exists $hist->{current_play}, 'hand_play_history has current_play');
    ok(exists $hist->{used_count}, 'hand_play_history has used_count');
}

# --- last_round_hands ---
{
    my $board = setup_board();
    my $p1 = $board->players->[0];
    my $p2 = $board->players->[1];

    # play all cards to completion
    $board->play_card($p2, 0);
    $board->play_card($p1, 0);
    $board->play_card($p2, 1);
    $board->play_card($p1, 1);
    $board->cannot_play($p2);
    $board->cannot_play($p1);
    $board->next_play($board);
    $board->play_card($p2, 2);
    $board->play_card($p1, 2);
    $board->end_play();
    $board->end_hands();

    my $last = $board->last_round_hands();
    ok($last, 'last_round_hands returns something after end_hands');
}

# --- validate_crib_cards ---
{
    my $board = setup_board();
    my $crib_cards = [
        make_card(suit => 'S', symbol => '3'),
        make_card(suit => 'S', symbol => '4'),
    ];
    ok($board->validate_crib_cards($crib_cards), 'validate_crib_cards returns true');
}

done_testing;
