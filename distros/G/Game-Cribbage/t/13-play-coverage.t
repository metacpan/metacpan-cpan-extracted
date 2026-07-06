use strict;
use warnings;
use Test::More;

use Game::Cribbage::Play;
use Game::Cribbage::Deck::Card;

sub make_card { Game::Cribbage::Deck::Card->new(@_) }

sub play_with_cards {
    my @specs = @_;
    my $play = Game::Cribbage::Play->new(next_to_play => 'player1');
    for my $spec (@specs) {
        my $card = make_card(%{ $spec->{card} });
        $play->card($spec->{player} // 'player1', $card);
    }
    return $play;
}

# --- test_card: returns a numeric score or error ---
{
    my $play = Game::Cribbage::Play->new(next_to_play => 'player1');
    my $card = make_card(suit => 'H', symbol => '5');
    my $result = $play->test_card('player1', $card);
    ok(defined $result, 'test_card returns something for first card');
    ok(!ref $result, 'test_card returns scalar (not ref) for valid play');
}

# --- test_card: returns error when total would exceed 31 ---
{
    my $play = play_with_cards(
        { card => { suit => 'H', symbol => 'K' } },
        { card => { suit => 'D', symbol => 'K' }, player => 'player2' },
        { card => { suit => 'S', symbol => 'K' } },
    );
    # total is 30, adding another K would be 40 > 31
    my $over_card = make_card(suit => 'C', symbol => 'K');
    my $result = $play->test_card('player2', $over_card);
    ok(ref $result, 'test_card returns error object when over 31');
    ok($result->go, 'error has go flag');
}

# --- test_card: scores 15 ---
{
    my $play = play_with_cards(
        { card => { suit => 'H', symbol => '8' } },
    );
    my $card = make_card(suit => 'D', symbol => '7');
    my $score = $play->test_card('player2', $card);
    is($score, 2, 'test_card returns 2 for making 15');
}

# --- force_card: duplicate card is skipped ---
{
    my $play = Game::Cribbage::Play->new(next_to_play => 'player1');
    my $card = make_card(suit => 'H', symbol => '5');
    $play->card('player1', $card);
    # force the same card again - match uses ->suit/->symbol, returns 0 (already played)
    my $dup = make_card(suit => 'H', symbol => '5');
    $dup->used(1);
    my $result = $play->force_card('player1', $dup);
    is($result, 0, 'force_card returns 0 for already-played card');
    is(scalar @{$play->cards}, 1, 'no duplicate added');
}

# --- force_card: new card is played ---
{
    my $play = Game::Cribbage::Play->new(next_to_play => 'player1');
    my $card = make_card(suit => 'H', symbol => '7');
    $card->used(1);
    my $result = $play->force_card('player1', $card);
    ok(defined $result, 'force_card plays new card');
    is(scalar @{$play->cards}, 1, 'card added');
}

# --- calculate_pair: single pair (1 match) ---
{
    my $play = play_with_cards(
        { card => { suit => 'H', symbol => '7' } },
    );
    my $card = make_card(suit => 'D', symbol => '7');
    my $scored = $play->card('player2', $card);
    is($scored->pair, 1, 'pair of 1 scored (two of a kind)');
    is($scored->score, 2, 'pair scores 2');
}

# --- calculate_pair: pair royal (2 matches = triple) ---
{
    my $play = play_with_cards(
        { card => { suit => 'H', symbol => '8' } },
        { card => { suit => 'D', symbol => '8' }, player => 'player2' },
    );
    my $card = make_card(suit => 'S', symbol => '8');
    my $scored = $play->card('player1', $card);
    is($scored->pair, 2, 'pair of 2 scored (three of a kind)');
    is($scored->score, 6, 'pair royal scores 6');
}

# --- calculate_pair: double pair royal (3 matches = quad) ---
{
    my $play = play_with_cards(
        { card => { suit => 'H', symbol => '6' } },
        { card => { suit => 'D', symbol => '6' }, player => 'player2' },
        { card => { suit => 'S', symbol => '6' } },
    );
    my $card = make_card(suit => 'C', symbol => '6');
    my $scored = $play->card('player2', $card);
    is($scored->pair, 3, 'pair of 3 scored (four of a kind)');
    is($scored->score, 12, 'double pair royal scores 12');
}

# --- calculate_hits: exactly 15 ---
{
    my $play = play_with_cards(
        { card => { suit => 'H', symbol => '8' } },
    );
    my $card = make_card(suit => 'D', symbol => '7');
    my $scored = $play->card('player2', $card);
    ok($scored->fifteen, 'fifteen flagged when total is 15');
    is($scored->score, 2, 'fifteen scores 2');
}

# --- calculate_hits: exactly 31 ---
{
    my $play = play_with_cards(
        { card => { suit => 'H', symbol => 'K' } },
        { card => { suit => 'D', symbol => 'K' }, player => 'player2' },
        { card => { suit => 'S', symbol => 'A' } },
    );
    # total is 21, add 10 for 31
    my $card = make_card(suit => 'C', symbol => 'K');
    my $scored = $play->card('player2', $card);
    ok($scored->pegged, 'pegged flagged on 31');
    ok($scored->go,     'go flagged on 31');
    is($scored->score, 2, '31 scores 2');
}

# --- calculate_run: run of 3 ---
# Use 7,8,9 so total (24) avoids 15 and 31; run index 1 = run-of-3 = 3 pts
{
    my $play = play_with_cards(
        { card => { suit => 'H', symbol => '7' } },
        { card => { suit => 'D', symbol => '8' }, player => 'player2' },
    );
    my $card = make_card(suit => 'S', symbol => '9');
    my $scored = $play->card('player1', $card);
    is($scored->run, 1, 'run of 3 detected (run index = 1)');
    is($scored->score, 3, 'run of 3 scores 3');
}

# --- calculate_run: run of 4 ---
# Use 3,4,5,6 so total (18) avoids 15 and 31; run index 2 = run-of-4 = 4 pts
{
    my $play = play_with_cards(
        { card => { suit => 'H', symbol => '3' } },
        { card => { suit => 'D', symbol => '4' }, player => 'player2' },
        { card => { suit => 'S', symbol => '5' } },
    );
    my $card = make_card(suit => 'C', symbol => '6');
    my $scored = $play->card('player2', $card);
    is($scored->run, 2, 'run of 4 detected (run index = 2)');
    is($scored->score, 4, 'run of 4 scores 4');
}

# --- end_play: awards 1 point go ---
{
    my $play = play_with_cards(
        { card => { suit => 'H', symbol => '7' } },
    );
    my $scored = $play->end_play();
    ok($scored, 'end_play returns a score');
    ok($scored->go, 'end_play score has go flag');
    is($scored->score, 1, 'end_play scores 1 for go');
}

# --- end_play: empty play returns undef ---
{
    my $play = Game::Cribbage::Play->new(next_to_play => 'player1');
    my $scored = $play->end_play();
    ok(!$scored, 'end_play on empty play returns undef');
}

# --- calculate_total: set vs no-set ---
{
    my $play = Game::Cribbage::Play->new(next_to_play => 'player1');
    my @cards = (
        make_card(suit => 'H', symbol => '5'),
        make_card(suit => 'D', symbol => '3'),
    );
    my $total = $play->calculate_total(\@cards, 0);
    is($total, 8, 'calculate_total returns correct sum without setting');
    is($play->total, 0, 'total not set when set=0');

    $play->calculate_total(\@cards, 1);
    is($play->total, 8, 'total set when set=1');
}

done_testing;
