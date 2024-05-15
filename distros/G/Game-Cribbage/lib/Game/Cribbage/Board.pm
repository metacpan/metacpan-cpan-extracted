package Game::Cribbage::Board;

use strict;
use warnings;

use Rope;
use Rope::Autoload;

use Game::Cribbage::Player;
use Game::Cribbage::Deck;
use Game::Cribbage::Rounds;

property players => (
	initable => 1,
	writeable => 1,
	configurable => 0,
	enumerable => 1,
	value => []
);

property [qw/deck rounds/] => (
        initable => 1,
	writeable => 1,
	configurable => 1,
	enumerable => 1,
);

function add_player => sub {
	my ($self, %player) = @_;
	push @{$self->players}, Game::Cribbage::Player->new(
		number => scalar @{$self->players} + 1,
		%player
	);
	return $self;
};

function add_player_if_not_exists => sub {
	my ($self, %player) = @_;
	my $exists = $self->get_player(%player);
	if (!$exists) {
		$self->add_player(%player); 
		$exists = $self->get_player(%player);
		return ($exists, 0);
	}
	return ($exists, 1);
};

function get_player => sub {
	my ($self, %player) = @_;
	my $exists = 0;
	for (@{$self->players}) {
		if ($_->name =~ m/^$player{name}$/) {
			return $_;
		}
	}
};

function build_deck => sub {
	$_[0]->deck = Game::Cribbage::Deck->new();
};

function build_rounds => sub {
	$_[0]->rounds = Game::Cribbage::Rounds->new(
		number => $_[1]
	);
};

function start_game => sub {
	my ($self, %args) = @_;
	$self->build_deck() if (!$self->deck);
	$self->build_rounds($args{rounds} || 1) if (!$self->rounds);
	$self->rounds->next_round($self, ($args{id} ? (id => $args{id}) : ())) if (!$self->rounds->current_round || $self->rounds->current_round->complete);
};

function next_hands => sub {
	my ($self, %args) = @_;
	$self->rounds->current_round->next_hands(%args);
};

function force_to_crib => sub {
	my ($self, $card) = @_;

	my $crib = $self->crib_player_identifier;

	my $round = $self->rounds->current_round;

	if ($self->deck->card_exists($card)) {
		$round->add_crib_card(
			$self->deck->force_draw($card)
		);
		return 1;
	}

	# confirm it exists in the players hand
	if ($round->card_exists($crib, $card)) {
		return 1;
	}

	$round->add_crib_card(
		$self->deck->generate_card($card)
	);

	return 1;
};

function force_draw_card => sub {
	my ($self, $player, $index, $card) = @_;

	my $round = $self->rounds->current_round;

	if ($self->deck->card_exists($card)) {
		$round->add_player_card(
			$player,
			$self->deck->force_draw($card)
		);
		return 1;
	}

	# confirm it exists in the players hand
	if ($round->card_exists($player, $card)) {
		return 1;
	}

	$round->add_player_card_by_index(
		$index,
		$player,
		$self->deck->generate_card($card)
	);

	return 1;
};

function draw_hands => sub {
	my ($self) = @_;

	my $round = $self->rounds->current_round;

	for (0 .. 5) {
		for (@{$self->players}) {
			$round->add_player_card(
				$_,
				$self->deck->draw
			);
		}
	}
};

function add_starter_card => sub {
	my ($self, $player, $card) = @_;
	$self->rounds->current_round->current_hands->add_starter_card($player, $card);
};

function get_hands => sub {
	my ($self) = @_;
	return $self->rounds->current_round->current_hands;
};

function identify_worst_cards => sub {
	my ($self, $player) = @_;
	$self->rounds->current_round->identify_worst_cards($player);
};

function validate_crib_cards => sub {
	my ($self, $cards) = @_;
	$self->rounds->current_round->validate_crib_cards($cards);
};

function crib_player_id => sub {
	my ($self) = @_;
	$self->rounds->current_round->crib_player_id($self);
};

function crib_player_identifier => sub {
	my ($self) = @_;
	$self->rounds->current_round->current_hands->crib_player;
};

function crib_player_name => sub {
	my ($self) = @_;
	$self->rounds->current_round->crib_player_name($self);
};

function crib_player_number => sub {
	my ($self) = @_;
	$self->rounds->current_round->crib_player_number($self);
};

function crib_player_cards => sub {
	my ($self, $player, $cards) = @_;
	$self->rounds->current_round->crib_player_cards($player, $cards);
};

function cribbed_card => sub {
	my ($self, $player, $index) = @_;
	$self->rounds->current_round->crib_player_card($player, $index);
};

function cribbed_cards => sub {
	my ($self, $player, @card_indexes) = @_;

	@card_indexes = sort { $b <=> $a } @card_indexes;
	$self->cribbed_card($player, $_) for @card_indexes;
	return 1;
};

function force_play_card => sub {
	my ($self, $card) = @_;
	$self->rounds->current_round->force_play_card($card);
};

function play_card => sub {
	my ($self, $player, $index) = @_;
	$self->rounds->current_round->play_player_card($player, $index);
};

function get_card => sub {
	my ($self, $player, $index) = @_;
	$self->rounds->current_round->get_player_card($player, $index);
};

function current_play => sub {
	my ($self) = @_;
	return $self->rounds->current_round->current_hands->play;
};

function current_play_cards => sub {
	my ($self) = @_;
	return [map { $_->card } @{$self->rounds->current_round->current_hands->play->cards}];
};

function current_play_score => sub {
	my ($self) = @_;
	$self->rounds->current_round->current_play_score();
};

function last_play_score => sub {
	my ($self) = @_;
	$self->rounds->current_round->last_play_score();
};

function score => sub {
	my ($self) = @_;
	$self->rounds->current_round->score;
};

function cannot_play => sub {
	my ($self, $player) = @_;
	$self->rounds->current_round->cannot_play_a_card($player);
};

function next_play => sub {
	my ($self) = @_;
	$self->rounds->current_round->next_play();
};

function end_play => sub {
	my ($self) = @_;
	$self->rounds->current_round->end_play();
};

function end_hands => sub {
	my ($self) = @_;
	$self->rounds->current_round->end_hands($self);
};

function shuffle => sub {
	my ($self) = @_;
	$self->deck->shuffle();
};

function get_round_id => sub {
	my ($self) = @_;
	return $self->rounds->current_round->id;
};

function set_round_id => sub {
	my ($self, $id) = @_;
	$self->rounds->current_round->id = $id;
	return $id;
};

function get_hands_id => sub {
	my ($self) = @_;
	return $self->rounds->current_round->current_hands->id;
};

function set_hands_id => sub {
	my ($self, $id) = @_;
	$self->rounds->current_round->current_hands->id = $id;
	return $id;
};

function get_play_id => sub {
	my ($self) = @_;
	return $self->rounds->current_round->current_hands->play->id;
};

function set_play_id => sub {
	my ($self, $id) = @_;
	$self->rounds->current_round->current_hands->play->id = $id;
	return $id;
};

function get_crib_player_hand_id => sub {
	my ($self) = @_;
	return $self->rounds->current_round->current_hands->get_crib_player_hand_id();
};

function set_player_hand_id => sub {
	my ($self, $player, $id) = @_;
	return $self->rounds->current_round->current_hands->set_player_hand_id($player, $id);
};

function get_player_hand_id => sub {
	my ($self, $player) = @_;
	return $self->rounds->current_round->current_hands->get_player_hand_id($player);
};

function set_crib_complete => sub {
	my ($self, $player, $id) = @_;
	return $self->rounds->current_round->current_hands->set_crib_complete($player, $id);
};

function crib_complete => sub {
	my ($self, $player) = @_;
	return $self->rounds->current_round->current_hands->crib_complete;
};

function best_run_play => sub {
	my ($self, $player) = @_;
	return $self->rounds->current_round->best_run_play($player);
};

function total_player_score => sub {
	my ($self, $player) = @_;
	$player = ref $player ? $player->player : $player;
	return $self->rounds->current_round->score->$player;
};

function set_crib_player => sub {
	my ($self, $player) = @_;
	$player = ref $player ? $player->player : $player;
	$self->rounds->current_round->current_hands->crib_player = $player;
	if ($self->rounds->current_round->current_hands->play) {
		$self->rounds->current_round->current_hands->play->next_to_play = $player;
	}
};

function next_to_play_id => sub {
	my ($self) = @_;
	$self->rounds->current_round->next_to_play_id($self);
};

function next_to_play => sub {
	my ($self) = @_;
	$self->rounds->current_round->next_to_play($self);
};

function hand_play_history => sub {
	my ($self) = @_;
	$self->rounds->current_round->hand_play_history();
};

function reset_hands => sub {
	my ($self) = @_;
	$self->rounds->current_round->reset_hands();
};

1;
