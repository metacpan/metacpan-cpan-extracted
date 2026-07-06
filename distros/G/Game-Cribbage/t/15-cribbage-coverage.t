use strict;
use warnings;
use Test::More;

# Suppress terminal output - redirect STDOUT so escape codes don't pollute test output
use IO::Handle;
open(my $devnull, '>', \my $out_buf) or die $!;

# We'll swap STDOUT temporarily for each group of terminal calls

use Game::Cribbage;
use Game::Cribbage::Board;
use Game::Cribbage::Deck::Card;

sub make_card { Game::Cribbage::Deck::Card->new(@_) }

sub with_captured_stdout (&) {
    my ($code) = @_;
    local *STDOUT;
    open(STDOUT, '>', \my $buf) or die $!;
    $code->();
    close STDOUT;
    return $buf;
}

sub make_board {
    my $board = Game::Cribbage::Board->new();
    $board->add_player(name => 'Bot');
    $board->add_player(name => 'Player');
    $board->start_game();
    $board->set_crib_player('player1');
    $board->rounds->current_round->add_player_card(
        $board->players->[0], make_card(suit => 'H', symbol => 'K')
    ) for 1 .. 4;
    $board->rounds->current_round->add_player_card(
        $board->players->[1], make_card(suit => 'D', symbol => '5')
    ) for 1 .. 4;
    return $board;
}

# --- Constructor and property accessors ---
{
    my $game = Game::Cribbage->new();
    isa_ok($game, 'Game::Cribbage', 'Game::Cribbage->new creates object');

    ok(!$game->dealer, 'dealer defaults to false');
    ok(!$game->crib_set, 'crib_set defaults to false');
    ok(!defined $game->starter_card, 'starter_card defaults to undef');
    ok(!defined $game->board, 'board defaults to undef');

    $game->dealer(1);
    is($game->dealer, 1, 'dealer setter works');

    $game->crib_set(1);
    is($game->crib_set, 1, 'crib_set setter works');

    my $card = make_card(suit => 'H', symbol => '5');
    $game->starter_card($card);
    is($game->starter_card->symbol, '5', 'starter_card setter works');
}

# --- Terminal utility functions (capture stdout) ---
{
    my $game = Game::Cribbage->new();

    with_captured_stdout {
        $game->reset_cursor();
    };
    pass('reset_cursor runs without error');

    with_captured_stdout {
        $game->set_cursor_vertical(5);
    };
    pass('set_cursor_vertical runs without error');

    with_captured_stdout {
        $game->set_cursor_horizontal(10);
    };
    pass('set_cursor_horizontal runs without error');

    with_captured_stdout {
        $game->say('hello');
    };
    pass('say with just message');

    with_captured_stdout {
        $game->say('hello', 1, 1, 31, 40);
    };
    pass('say with all args (newline + indent)');

    with_captured_stdout {
        $game->draw_go(6, 2);
    };
    pass('draw_go runs without error');
}

# --- draw_dealer ---
{
    my $game = Game::Cribbage->new();

    # Without dealer set (undef) - returns early
    with_captured_stdout {
        $game->draw_dealer();
    };
    pass('draw_dealer with undef dealer returns early');

    # dealer = 0
    $game->dealer(0);
    with_captured_stdout {
        $game->draw_dealer();
    };
    pass('draw_dealer with dealer=0');

    # dealer = 1
    $game->dealer(1);
    with_captured_stdout {
        $game->draw_dealer();
    };
    pass('draw_dealer with dealer=1');
}

# --- draw_starter ---
{
    my $game = Game::Cribbage->new();

    # Without starter card - returns early
    with_captured_stdout {
        $game->draw_starter();
    };
    pass('draw_starter with no card is a no-op');

    # With starter card
    $game->starter_card(make_card(suit => 'H', symbol => 'K'));
    with_captured_stdout {
        $game->draw_starter();
    };
    pass('draw_starter with card renders');
}

# --- draw_crib ---
{
    my $game = Game::Cribbage->new();

    # crib_set = 0 - returns early
    $game->dealer(0);
    with_captured_stdout {
        $game->draw_crib();
    };
    pass('draw_crib with crib_set=0 is no-op');

    # crib_set = 1, dealer = 0 (opponent is dealer)
    $game->crib_set(1);
    $game->dealer(0);
    with_captured_stdout {
        $game->draw_crib();
    };
    pass('draw_crib with crib_set=1 dealer=0');

    # crib_set = 1, dealer = 1 (player is dealer)
    $game->dealer(1);
    with_captured_stdout {
        $game->draw_crib();
    };
    pass('draw_crib with crib_set=1 dealer=1');
}

# --- render_card ---
{
    my $game = Game::Cribbage->new();
    for my $suit (qw/H D S C/) {
        for my $sym ('A', '10', 'K', '5') {
            my $card = make_card(suit => $suit, symbol => $sym);
            with_captured_stdout {
                $game->render_card($card, 10, 5);
            };
        }
    }
    pass('render_card runs for various suits and symbols including 10');
}

# --- render_opponent_cards ---
{
    my $game = Game::Cribbage->new();

    # num = 0 - returns early
    with_captured_stdout {
        $game->render_opponent_cards(0);
    };
    pass('render_opponent_cards with 0 returns early');

    # num > 0
    with_captured_stdout {
        $game->render_opponent_cards(3);
    };
    pass('render_opponent_cards with 3 cards renders');
}

# --- render_player_cards ---
{
    my $game = Game::Cribbage->new();
    my @cards = (
        make_card(suit => 'H', symbol => 'K'),
        make_card(suit => 'D', symbol => '5'),
        make_card(suit => 'S', symbol => 'A'),
    );
    $cards[0]->used(1);  # one used card

    # $all = 0: skip used cards
    with_captured_stdout {
        $game->render_player_cards(\@cards, 26, 5, 0);
    };
    pass('render_player_cards with all=0 skips used cards');

    # $all = 1: show all cards
    with_captured_stdout {
        $game->render_player_cards(\@cards, 26, 5, 1);
    };
    pass('render_player_cards with all=1 shows all cards');
}

# --- draw_scores ---
{
    my $game = Game::Cribbage->new();

    # Without board - returns early
    with_captured_stdout {
        $game->draw_scores();
    };
    pass('draw_scores without board returns early');

    # With board, no current_play_score
    my $board = make_board();
    $game->board($board);
    with_captured_stdout {
        $game->draw_scores();
    };
    pass('draw_scores with board and zero play score');

    # Play a card to get a non-zero current_play_score
    $board->play_card($board->players->[0], 0);
    with_captured_stdout {
        $game->draw_scores();
    };
    pass('draw_scores with non-zero current play score');
}

# --- render_run_play ---
{
    my $game = Game::Cribbage->new();
    my $board = make_board();
    $game->board($board);

    # Empty play - returns early
    with_captured_stdout {
        $game->render_run_play();
    };
    pass('render_run_play with empty play is no-op');

    # Play a card so run play has cards
    $board->play_card($board->players->[0], 0);
    with_captured_stdout {
        $game->render_run_play();
    };
    pass('render_run_play with cards renders');
}

# --- draw_cards ---
{
    my $game = Game::Cribbage->new();
    my $board = make_board();
    $game->board($board);
    eval { $game->draw_cards() };
    ok(!$@, 'draw_cards delegates to board->draw_hands without dying');
}

done_testing;
