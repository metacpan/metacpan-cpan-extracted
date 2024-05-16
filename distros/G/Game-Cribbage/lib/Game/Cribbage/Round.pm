package Game::Cribbage::Round;

use strict;
use warnings;

use Rope;
use Rope::Autoload;

use Game::Cribbage::Round::Score;
use Game::Cribbage::Hands;

property [qw/id number score current_hands/] => (
	initable => 1,
	writeable => 1,
	configurable => 0,
	enumerable => 1
);

property complete => (
	initable => 1,
	writeable => 0,
	configurable => 0,
	enumerable => 1,
	value => 0
);

property history => (
	initable => 1,
	writeable => 1,
	configurable => 0,
	enumerable => 1,
	value => []
);

function INITIALISED => sub {
	my ($self, $params) = @_;
	my %score = ();
	for (@{$params->{_game}->players}) {
		$score{$_->player} = {
			current =>  0,
			last => 0
		};
	}
	$self->score = Game::Cribbage::Round::Score->new(%score);
	$self->next_hands($params->{_game});
};

function reset_hands => sub {
	my ($self, $game) = @_;
	$self->history = [];
	my %score = ();
	for (@{$game->players}) {
		$score{$_->player} = {
			current => 0,
			last => 0
		};
	}
	$self->score = Game::Cribbage::Round::Score->new(%score);
	$self->next_hands($game);
};

function next_hands => sub {
	my ($self, $game, %args) = @_;
	$game->shuffle();
	my $hands = Game::Cribbage::Hands->new(_game => $game, %args);
	$self->current_hands = $hands;
	push @{$self->history}, $hands;
	return $self;
};

function end_hands => sub {
	my ($self, $game) = @_;
	my $scored = $self->current_hands->score_hands();
	for my $hand (keys %{$scored}) {
		$self->score->$hand->{last} = $self->score->$hand->{current};
		$self->score->$hand->{current} += $scored->{$hand};
	}
	$self->next_hands($game);
};

function add_player_card_by_index => sub {
	my ($self, $index, $player, $card) = @_;
	my $hand = ref $player ? $player->player : $player;
	$self->current_hands->$hand->add_by_index($index, $card);
};

function add_player_card => sub {
	my ($self, $player, $card) = @_;
	my $hand = ref $player ? $player->player : $player;
	$self->current_hands->$hand->add($card);
};

function add_starter_card => sub {
	my ($self, $player, $card) = @_;
	my $score = $self->current_hands->add_starter_card($player, $card);
	if (ref $score && $score->score) {
		my $hand = ref $player ? $player->player : $player;
		$self->score->$hand->{last} = $self->score->$hand->{current};
		$self->score->$hand->{current} += $score->score;
		push @{$self->current_hands->$hand->play_scored}, $score;
	}
	return $score;
};

function validate_crib_cards => sub {
	my ($self, $cards) = @_;
	my $crib = $self->current_hands->crib_player;
	$self->current_hands->$crib->validate_crib_cards($cards);
};

function next_to_play => sub {
	my ($self, $game) = @_;
	my $next = $self->current_hands->play->next_to_play;
	my $player;
	for (@{$game->players}) {
		if ($next eq $_->player) {
			$player = $_;
			last;
		}
	}
	return $player;
};

function next_to_play_id => sub {
	my ($self, $game) = @_;
	my $next = $self->next_to_play($game);
	return $next->id;
};

function get_crib_player => sub {
	my ($self, $game) = @_;
	my $player;
	for (@{$game->players}) {
		if ($self->current_hands->crib_player eq $_->player) {
			$player = $_;
			last;
		}
	}
	return $player;
};

function crib_player_id => sub {
	my ($self, $game) = @_;
	my $player = $self->get_crib_player($game);
	return $player ? $player->id : $player;
};

function crib_player_name => sub {
	my ($self, $game) = @_;
	my $player = $self->get_crib_player($game);
	return $player ? $player->name : $player;
};

function crib_player_number => sub {
	my ($self, $game) = @_;
	my $player = $self->get_crib_player($game);
	return $player ? $player->number : $player;
};

function crib_player_cards => sub {
	my ($self, $player, $cards) = @_;
	my $hand = ref $player ? $player->player : $player;
	my $crib = $self->current_hands->crib_player;
	return $self->current_hands->$hand->discard_cards($cards, $self->current_hands->$crib);
};

function crib_player_card => sub {
	my ($self, $player, $card_index) = @_;
	my $hand = $player->player;
	my $crib = $self->current_hands->crib_player;
	$self->current_hands->$hand->discard($card_index, $self->current_hands->$crib);
};

function force_play_card => sub {
	my ($self, $card) = @_;
	my ($score, $player) = $self->current_hands->force_play_card($card);
	if (ref $score && $score->score) {
		my $hand = ref $player ? $player->player : $player;
		$self->score->$hand->{last} = $self->score->$hand->{current};
		$self->score->$hand->{current} += $score->score;
		push @{$self->current_hands->$hand->play_scored}, $score;
	}
	return $score;
};

function play_player_card => sub {
	my ($self, $player, $card_index) = @_;
	my $score = $self->current_hands->play_card($player, $card_index);
	if (ref $score && $score->score) {
		my $hand = ref $player ? $player->player : $player;
		$self->score->$hand->{last} = $self->score->$hand->{current};
		$self->score->$hand->{current} += $score->score;
		push @{$self->current_hands->$hand->play_scored}, $score;
	}
	return $score;
};

function card_exists => sub {
	my ($self, $player, $card) = @_;
	return $self->current_hands->card_exists($player, $card);
};

function get_player_card => sub {
	my ($self, $player, $card_index) = @_;
	$self->current_hands->get_card($player, $card_index);
};

function current_play_score => sub {
	my ($self) = @_;
	$self->current_hands->play_score();
};

function last_play_score => sub {
	my ($self) = @_;
	$self->current_hands->last_play_score();
};

function cannot_play_a_card => sub {
	my ($self, $player) = @_;
	$self->current_hands->cannot_play_a_card($player);
};

function next_play => sub {
	my ($self, $game) = @_;
	my $score = $self->current_hands->next_play($game);
	if (ref $score && $score->score) {
		my $hand = ref $score->player ? $score->player->player : $score->player;
		$self->score->$hand->{last} = $self->score->$hand->{current};
		$self->score->$hand->{current} += $score->score;
		push @{$self->current_hands->$hand->play_scored}, $score;
	}
	return $self->current_hands->play;
};

function end_play => sub {
	my ($self) = @_;
	my $score = $self->current_hands->end_play();
	if (ref $score && $score->score) {
		my $hand = $score->player->player;
		$self->score->$hand->{last} = $self->score->$hand->{current};
		$self->score->$hand->{current} += $score->score;
		push @{$self->current_hands->$hand->play_scored}, $score;
	}
	return 1;
};

function identify_worst_cards => sub {
	my ($self, $player) = @_;
	my $hand = ref $player ? $player->player : $player;
	$self->current_hands->$hand->identify_worst_cards();
};

function best_run_play => sub {
	my ($self, $player) = @_;
	$self->current_hands->best_run_play($player);
};

function hand_play_history => sub {
	my ($self, $player) = @_;
	my @history = @{$self->current_hands->play_history};
	my $current = pop @history;
	my $count_cards = 0;
	for (@history) {
		$count_cards += scalar @{$_->cards};
	}
	return {
		used_count => $count_cards,
		current_play => $current
	};
};

1;
