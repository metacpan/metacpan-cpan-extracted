package Game::Cribbage::Board;

use strict;
use warnings;

use Object::Proto::Sugar -types;
use Game::Cribbage::Player;
use Game::Cribbage::Deck;
use Game::Cribbage::Rounds;

has players => (
	is => 'rw',
	isa => ArrayRef,
	default => [],
);

has [qw/deck rounds/] => (
	is => 'rw',
	isa => Object,
);

sub add_player {
	my ($self, %player) = @_;
	push @{$self->players}, Game::Cribbage::Player->new(
		number => scalar @{$self->players} + 1,
		%player
	);
	return $self;
}

sub add_player_if_not_exists {
	my ($self, %player) = @_;
	my $exists = $self->get_player(%player);
	if (!$exists) {
		$self->add_player(%player); 
		$exists = $self->get_player(%player);
		return ($exists, 0);
	}
	return ($exists, 1);
}

sub get_player {
	my ($self, %player) = @_;
	my $exists = 0;
	for (@{$self->players}) {
		if ($_->name =~ m/^$player{name}$/) {
			return $_;
		}
	}
}

sub build_deck {
	$_[0]->deck(Game::Cribbage::Deck->new());
}

sub build_rounds {
	$_[0]->rounds(Game::Cribbage::Rounds->new(
		number => $_[1]
	));
}

sub start_game {
	my ($self, %args) = @_;
	$self->build_deck() if (!$self->deck);
	$self->build_rounds($args{rounds} || 1) if (!$self->rounds);
	$self->rounds->next_round($self, ($args{id} ? (id => $args{id}) : ())) if (!$self->rounds->current_round || $self->rounds->current_round->complete);
}

sub next_hands {
	my ($self, %args) = @_;
	$self->rounds->current_round->next_hands(%args);
}

sub force_to_crib {
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
}

sub force_draw_card {
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
}

sub draw_hands {
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
}

sub add_starter_card {
	my ($self, $player, $card) = @_;
	$self->rounds->current_round->current_hands->add_starter_card($player, $card);
}

sub get_hands {
	my ($self) = @_;
	return $self->rounds->current_round->current_hands;
}

sub identify_worst_cards {
	my ($self, $player) = @_;
	$self->rounds->current_round->identify_worst_cards($player);
}

sub validate_crib_cards {
	my ($self, $cards) = @_;
	$self->rounds->current_round->validate_crib_cards($cards);
}

sub crib_player_id {
	my ($self) = @_;
	$self->rounds->current_round->crib_player_id($self);
}

sub crib_player_identifier {
	my ($self) = @_;
	$self->rounds->current_round->current_hands->crib_player;
}

sub crib_player_name {
	my ($self) = @_;
	$self->rounds->current_round->crib_player_name($self);
}

sub crib_player_number {
	my ($self) = @_;
	$self->rounds->current_round->crib_player_number($self);
}

sub crib_player_cards {
	my ($self, $player, $cards) = @_;
	$self->rounds->current_round->crib_player_cards($player, $cards);
}

sub cribbed_card {
	my ($self, $player, $index) = @_;
	$self->rounds->current_round->crib_player_card($player, $index);
}

sub cribbed_cards {
	my ($self, $player, @card_indexes) = @_;

	@card_indexes = sort { $b <=> $a } @card_indexes;
	$self->cribbed_card($player, $_) for @card_indexes;
	return 1;
}

sub force_play_card {
	my ($self, $card) = @_;
	$self->rounds->current_round->force_play_card($card);
}

sub play_card {
	my ($self, $player, $index) = @_;
	$self->rounds->current_round->play_player_card($player, $index);
}

sub get_card {
	my ($self, $player, $index) = @_;
	$self->rounds->current_round->get_player_card($player, $index);
}

sub current_play {
	my ($self) = @_;
	return $self->rounds->current_round->current_hands->play;
}

sub current_play_cards {
	my ($self) = @_;
	return [map { $_->card } @{$self->rounds->current_round->current_hands->play->cards}];
}

sub current_play_score {
	my ($self) = @_;
	$self->rounds->current_round->current_play_score();
}

sub last_play_score {
	my ($self) = @_;
	$self->rounds->current_round->last_play_score();
}

sub score {
	my ($self) = @_;
	$self->rounds->current_round->score;
}

sub cannot_play {
	my ($self, $player) = @_;
	$self->rounds->current_round->cannot_play_a_card($player);
}

sub player_cannot_play {
	my ($self, $player) = @_;
	return exists $self->rounds->current_round->current_hands->cannot_play->{$player};
}

sub no_player_can_play {
	my ($self) = @_;
	return scalar(keys(%{$self->rounds->current_round->current_hands->cannot_play})) == scalar(@{$self->players});
}

sub next_play {
	my ($self) = @_;
	$self->rounds->current_round->next_play($self);
}

sub end_play {
	my ($self) = @_;
	$self->rounds->current_round->end_play();
}

sub end_hands {
	my ($self) = @_;
	$self->rounds->current_round->end_hands($self);
}

sub shuffle {
	my ($self) = @_;
	$self->deck->shuffle();
}

sub get_round_id {
	my ($self) = @_;
	return $self->rounds->current_round->id;
}

sub set_round_id {
	my ($self, $id) = @_;
	$self->rounds->current_round->id($id);
	return $id;
}

sub get_hands_id {
	my ($self) = @_;
	return $self->rounds->current_round->current_hands->id;
}

sub set_hands_id {
	my ($self, $id) = @_;
	$self->rounds->current_round->current_hands->id($id);
	return $id;
}

sub get_play_id {
	my ($self) = @_;
	return $self->rounds->current_round->current_hands->play->id;
}

sub set_play_id {
	my ($self, $id) = @_;
	$self->rounds->current_round->current_hands->play->id($id);
	return $id;
}

sub get_crib_player_hand_id {
	my ($self) = @_;
	return $self->rounds->current_round->current_hands->get_crib_player_hand_id();
}

sub set_player_hand_id {
	my ($self, $player, $id) = @_;
	return $self->rounds->current_round->current_hands->set_player_hand_id($player, $id);
}

sub get_player_hand_id {
	my ($self, $player) = @_;
	return $self->rounds->current_round->current_hands->get_player_hand_id($player);
}

sub set_crib_complete {
	my ($self, $player, $id) = @_;
	return $self->rounds->current_round->current_hands->set_crib_complete($player, $id);
}

sub crib_complete {
	my ($self, $player) = @_;
	return $self->rounds->current_round->current_hands->crib_complete;
}

sub best_run_play {
	my ($self, $player) = @_;
	return $self->rounds->current_round->best_run_play($player);
}

sub total_player_score {
	my ($self, $player) = @_;
	$player = ref $player ? $player->player : $player;
	return $self->rounds->current_round->score->$player;
}

sub set_crib_player {
	my ($self, $player) = @_;
	$player = ref $player ? $player->player : $player;
	$self->rounds->current_round->current_hands->crib_player($player);
	if ($self->rounds->current_round->current_hands->play) {
		$self->rounds->current_round->current_hands->play->next_to_play($player);
	}
}

sub next_to_play_id {
	my ($self) = @_;
	$self->rounds->current_round->next_to_play_id($self);
}

sub next_to_play {
	my ($self) = @_;
	$self->rounds->current_round->next_to_play($self);
}

sub set_next_to_play {
	my ($self, $player) = @_;
	$self->rounds->current_round->current_hands->play->next_to_play($player);
}

sub hand_play_history {
	my ($self) = @_;
	$self->rounds->current_round->hand_play_history();
}

sub reset_hands {
	my ($self) = @_;
	$self->rounds->current_round->reset_hands();
}

sub last_round_hands {
	my ($self) = @_;
	return $self->rounds->current_round->history->[-2];
}

1;
