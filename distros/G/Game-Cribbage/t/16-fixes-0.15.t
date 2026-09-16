use strict;
use warnings;
use Test::More;

use Game::Cribbage::Board;
use Game::Cribbage::Deck;
use Game::Cribbage::Deck::Card;
use Game::Cribbage::Score;
use Game::Cribbage::Player::Hand;

# The rules 0.15 corrected, each as the hand that showed it.

sub c { Game::Cribbage::Deck::Card->new(suit => $_[0], symbol => $_[1]) }

# ---- a count of exactly 31 is playable ------------------------------------

{
	my $board = Game::Cribbage::Board->new();
	$board->add_player(name => 'p1');
	$board->add_player(name => 'p2');
	$board->start_game();
	$board->set_crib_player('player2');
	my $round = $board->rounds->current_round;
	my ($p1, $p2) = @{$board->players};
	# p1: K K K A, p2: 10 10 A A, so 10 K 10 puts the count at 30 and an
	# ace makes 31 exactly
	$round->add_player_card($p1, $_) for c('H', 'K'), c('S', 'K'), c('D', 'K'), c('C', 'A');
	$round->add_player_card($p2, $_) for c('H', '10'), c('S', '10'), c('D', 'A'), c('S', 'A');

	ok($board->play_card($p2, 0), 'p2 plays a ten');
	ok($board->play_card($p1, 0), 'p1 plays a king');
	ok($board->play_card($p2, 1), 'p2 plays a ten, count 30');
	is($board->current_play_score, 30, 'the count is 30');

	my $can = $board->cannot_play($p1);
	ok(ref $can eq 'ARRAY' && @$can == 1 && $can->[0]->symbol eq 'A',
		'an ace is reported as playable at 30 (it was refused before 0.15)');

	my $score = $board->play_card($p1, c('C', 'A'));
	ok(ref $score && $score->can('pegged') && $score->pegged, 'and playing it pegs 31');
	is($board->current_play_score, 31, 'the count is 31');
}

# ---- play_card answers an Error for a card not held or already played -----

{
	my $board = Game::Cribbage::Board->new();
	$board->add_player(name => 'p1');
	$board->add_player(name => 'p2');
	$board->start_game();
	$board->set_crib_player('player2');
	my $round = $board->rounds->current_round;
	my ($p1, $p2) = @{$board->players};
	$round->add_player_card($p1, $_) for c('H', '2'), c('S', '3'), c('D', '4'), c('C', '5');
	$round->add_player_card($p2, $_) for c('H', '6'), c('S', '7'), c('D', '8'), c('C', '9');

	my $r = eval { $board->play_card($p2, c('H', 'K')) };
	ok(ref $r && $r->isa('Game::Cribbage::Error'), 'a card the player does not hold is an Error, not a die')
		or diag $@;
	like($r->message, qr/not in the hand/, 'which says so');

	ok($board->play_card($p2, 0), 'p2 plays the six');
	ok($board->play_card($p1, 0), 'p1 plays the two');
	$r = eval { $board->play_card($p2, c('H', '6')) };
	ok(ref $r && $r->isa('Game::Cribbage::Error'), 'a card already played is an Error');
	like($r->message, qr/already been played/, 'which says so');
}

# ---- Score: a run of face cards in ascending order ----------------------------

{
	my $s = Game::Cribbage::Score->new(with_starter => 0, cards => [c('H', 'J'), c('S', 'Q'), c('D', 'K'), c('C', '2')]);
	is($s->total_score, 3, 'J Q K given in that order is a run of three');
	$s = Game::Cribbage::Score->new(with_starter => 0, cards => [c('H', 'K'), c('S', 'Q'), c('D', 'J'), c('C', '2')]);
	is($s->total_score, 3, 'and in the other order');
	$s = Game::Cribbage::Score->new(with_starter => 1, cards => [c('H', '10'), c('S', 'Q'), c('D', 'J'), c('C', '2'), c('C', 'K')]);
	is($s->total_score, 4, '10 J Q with a king starter is a run of four');
}

# ---- Score: the starter never makes up a flush ------------------------------------

{
	my $s = Game::Cribbage::Score->new(with_starter => 1, cards => [c('H', '2'), c('H', '4'), c('H', '9'), c('S', 'K'), c('H', '7')]);
	is($s->total_score, 2, 'three hearts in hand plus a heart starter is not a flush (just the fifteen)');
	is(scalar @{$s->four_flush}, 0, 'no four_flush');

	$s = Game::Cribbage::Score->new(with_starter => 1, cards => [c('H', '2'), c('H', '4'), c('H', '9'), c('H', 'K'), c('S', '7')]);
	is(scalar @{$s->four_flush}, 1, 'four hearts in hand with a spade starter is a four flush');
	is($s->total_score, 6, 'four for the flush and two for the fifteen');

	$s = Game::Cribbage::Score->new(with_starter => 1, cards => [c('H', '2'), c('H', '4'), c('H', '9'), c('H', 'K'), c('H', '7')]);
	is(scalar @{$s->five_flush}, 1, 'and with a heart starter a five flush');
	is($s->total_score, 7, 'five for the flush and two for the fifteen');

	$s = Game::Cribbage::Score->new(with_starter => 1, crib => 1, cards => [c('H', '2'), c('H', '4'), c('H', '9'), c('H', 'K'), c('S', '7')]);
	is(scalar @{$s->four_flush}, 0, 'a crib of four hearts with a spade starter is no flush');
	$s = Game::Cribbage::Score->new(with_starter => 1, crib => 1, cards => [c('H', '2'), c('H', '4'), c('H', '9'), c('H', 'K'), c('H', '7')]);
	is(scalar @{$s->five_flush}, 1, 'but with a heart starter it is a five flush');

	# the hand that scores 29 still does
	$s = Game::Cribbage::Score->new(with_starter => 1, cards => [c('H', '5'), c('S', '5'), c('D', '5'), c('C', 'J'), c('C', '5')]);
	is($s->total_score, 29, 'the twenty-nine hand');
}

# ---- his heels is two ------------------------------------------------------------------

{
	my $board = Game::Cribbage::Board->new();
	$board->add_player(name => 'p1');
	$board->add_player(name => 'p2');
	$board->start_game();
	$board->set_crib_player('player1');
	my $round = $board->rounds->current_round;
	my ($p1, $p2) = @{$board->players};
	$round->add_player_card($p1, $_) for c('H', '2'), c('S', '3'), c('D', '4'), c('C', '5');
	$round->add_player_card($p2, $_) for c('H', '6'), c('S', '7'), c('D', '8'), c('C', '9');
	my $score = $round->add_starter_card($p1, c('H', 'J'));
	ok(ref $score, 'a jack starter scores');
	is($score->score, 2, 'two for his heels');
	is_deeply($board->score->player1, { current => 2, last => 0 }, 'credited to the player given, the dealer');
	is(ref($round->add_starter_card($p1, c('H', '5'))) ? 1 : 0, 0, 'and a five starter scores nothing');
}

# ---- identify_worst_cards when nothing scores ------------------------------------

{
	my $hand = Game::Cribbage::Player::Hand->new(player => 'player1');
	$hand->add($_) for c('H', '2'), c('S', '4'), c('D', '9'), c('C', 'K'), c('H', 'Q'), c('S', '7');
	my ($cards, @index) = $hand->identify_worst_cards();
	is(scalar @$cards, 2, 'a hand where no four cards score still names two to discard');
	is(scalar @index, 2, 'with two indexes');
}

# ---- Deck->from_order --------------------------------------------------------------

{
	my $deck = Game::Cribbage::Deck->new();
	$deck->from_order([reverse 1 .. 52]);
	is($deck->draw->id, 52, 'from_order puts the first id on top');
	is($deck->get(0)->id, 51, 'and the rest follow');
	is(scalar @{$deck->deck}, 51, 'fifty-one left after one draw');
	my $err = '';
	eval { $deck->from_order([1 .. 51, 1]); 1 } or $err = $@;
	like($err, qr/repeated/, 'a repeated id is refused');
	$err = '';
	eval { $deck->from_order([1 .. 10]); 1 } or $err = $@;
	like($err, qr/52 card ids/, 'and so is a short list');
	# id 14 is the ace of spades: suit-major H S D C, ace to king
	$deck->from_order([14, 1 .. 13, 15 .. 52]);
	my $top = $deck->draw;
	is($top->suit . $top->symbol, 'SA', 'ids are suit-major, hearts then spades, ace to king');
}

done_testing();
