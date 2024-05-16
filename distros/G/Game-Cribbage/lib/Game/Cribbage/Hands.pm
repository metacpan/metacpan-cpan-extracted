package Game::Cribbage::Hands;

use strict;
use warnings;

use Rope;
use Rope::Autoload;
use Game::Cribbage::Player::Hand;
use Game::Cribbage::Play;
use Game::Cribbage::Error;

property number => (
	initable => 1,
	writeable => 0,
	configurable => 0,
	enumerable => 1
);

property [qw/starter play crib_player crib_complete player1 player2 player3 player4/] => (
	initable => 1,
	writeable => 1,
	configurable => 0,
	enumerable => 1,
);

property cannot_play => (
	initable => 1,
	writeable => 1,
	configurable => 0,
	enumerable => 1,
	value => {}
);

property play_history => (
	initable => 1,
	writeable => 1,
	configurable => 0,
	enumerable => 1,
	value => []
);

function INITIALISED => sub {
	my ($self, $options) = @_;
	$self->crib_player = 'player1' if (!$options->{crib_player});
	for (@{$options->{_game}->players}) {
		my $player = $_->player;
		$self->$player = Game::Cribbage::Player::Hand->new(
			player => $player
		);
	}
	$self->new_play();
	$self;
};

function add_starter_card => sub {
	my ($self, $player, $card) = @_;
	$self->starter = $card;
	
	my $scored = 0;
	if ($card->symbol =~ m/^J$/) {
		$scored = Game::Cribbage::Play::Score->new(
			player => $player,
			card => $card,
			flipped => 1
		);
		my $hand = ref $player ? $player->player : $player;
		$self->score->$hand->{last} = $self->score->$hand->{current};
		$self->score->$hand->{current} += $scored->score;
		push @{$self->current_hands->$hand->play_scored}, $scored;
		push @{$self->play->scored}, $scored;
	}

	for (qw/player1 player2 player3 player4/) {
		if ($self->$_) {
			$self->$_->starter = $card;
		}
	}

	return $scored;
};

function find_player_card => sub {
	my ($self, $card) = @_;
	my $player;
	for my $p (qw/player1 player2 player3 player4/) {
		if ($self->$p) {
			for (@{$self->$p->cards}) {
				if ($_->match($card)) {
					$card = $_;
					$player = $p;			
					last;
				}
			}
		}
	}
	return ($card, $player);
};

function force_play_card => sub {
	my ($self, $card) = @_;
	my $player;
	($card, $player) = $self->find_player_card($card);
	$card->used = 1;
	my $scored = $self->play->force_card($player, $card);
	$self->set_next_to_play();
	return ($scored, $player);
};

function play_card => sub {
	my ($self, $player, $card_index) = @_;
	my $hand = ref $player ? $player->player : $player;
	if ($self->play->next_to_play ne $hand) {
		return Game::Cribbage::Error->new( message => 'It is not the turn of ' . $hand );
	}
	my $card = ref $card_index ? $card_index : $self->$hand->get($card_index);
	if (!$card || $card->used) {
		die 'CARD HAS ALREADY BEEN PLAYED IN THIS ROUND';
	}

	my $total = $self->play->total;
	if ($card->value + $total > 31) {
		return Game::Cribbage::Error->new( over => 1, message => 'Playing this card will make the score greater than 31');
	}
	$card->used = 1;
	my $scored = $self->play->card($player, $card);
	$self->set_next_to_play();
	return $scored;
};

function cannot_play_a_card => sub {
	my ($self, $player) = @_;
	
	my $hand = ref $player ? $player->player : $player;
	if ($self->play->next_to_play ne $hand) {
		return Game::Cribbage::Error->new( message => 'It is not the turn of ' . $hand );
	}

	my $current_total = $self->play->total;

	my @can_be_played;
	for (@{$self->$hand->cards}) {
		next if $_->used;
		if ( $current_total + $_->value < 31 ) {
			push @can_be_played, $_;
		}
	}

	return \@can_be_played if scalar @can_be_played;

	$self->set_next_to_play();

	$self->cannot_play->{$hand} = 1;

	return 1;
};

function set_next_to_play => sub {
	my ($self) = @_;
	my $next = $self->parse_next_to_play($self->play->next_to_play);
	$self->play->next_to_play = $next;
};

function parse_next_to_play => sub {
	my ($self, $player_string) = @_;
	$player_string =~ m/player(\d)/;
	my $index = $1;
	$index++;
	my $next = 'player' . $index;
	if ($self->$next) {
		return $next;
	} else {
		return 'player1';
	}
};

function set_player_hand_id => sub {
	my ($self, $player, $id) = @_;
	my $hand = ref $player ? $player->player : $player;
	$self->$hand->id = $id;
	return $id;
};

function get_player_hand_id => sub {
	my ($self, $player) = @_;
	my $hand = ref $player ? $player->player : $player;
	return $self->$hand->id;
};

function get_crib_player_hand_id => sub {
	my ($self) = @_;
	my $hand = $self->crib_player;
	return $self->$hand->id;
};

function get_card => sub {
	my ($self, $player, $card_index) = @_;
	my $hand = ref $player ? $player->player : $player;
	my $card = $self->$hand->get($card_index);
	return $card;
};

function play_score => sub {
	my ($self) = @_;
	return $self->play->total || 0;
};

function last_play_score => sub {
	my ($self) = @_;
	return $self->play_history->[-2]->total || 'This is the first play';
};

function new_play => sub {
	my ($self) = @_;
	my $next_to_play = $self->crib_player;
	if ($self->play) {
		$next_to_play = $self->parse_next_to_play(ref $self->play->cards->[-1]->player ? $self->play->cards->[-1]->player->player : $self->play->cards->[-1]->player);
	}
	$self->play = Game::Cribbage::Play->new(
		next_to_play => $next_to_play
	);
	push @{$self->play_history}, $self->play;
};

function next_play => sub {
	my ($self, $game) = @_;

	# first check whether any players can play on the current 'play'
	# if they can they must use those cards first.
	my $current_total = $self->play->total;

	my $available_cards = 0;
	for my $hand (qw/player1 player2 player3 player4/) {
		if ($self->$hand) {
			my @can_be_played;
			for (@{$self->$hand->cards}) {
				next if $_->used;
				$available_cards = 1;
				if ( $current_total + $_->value < 31 ) {
					push @can_be_played, $_;
				}
			}
			if (scalar @can_be_played) {
				return Game::Cribbage::Error->new(
					message => 'Cards can be played',
					player => $hand,
					cards => \@can_be_played
				);
			}
		}
	}

	$self->cannot_play = {};
	
	# now we know cards can't be played confirm we have cards left to Play another 'play'.
	return $game->end_hands() if !$available_cards;

	my $scored;

	if (!$self->play->scored->[-1] || !$self->play->scored->[-1]->go) {
		$scored = $self->play->end_play();
	}

	$self->new_play();

	return $scored;
};

function end_play => sub {
	my ($self) = @_;

	my $scored;

	if (!$self->play->scored->[-1] || !$self->play->scored->[-1]->go) {
		$scored = $self->play->end_play();
	}

	$self->play = undef;

	return $scored;
};

function score_hands => sub {
	my ($self) = @_;
	my %scored;
	for (qw/player1 player2 player3 player4/) {
		$scored{$_} = $self->$_->calculate_score()
			if ($self->$_);
	}
	return \%scored;
};

function card_exists => sub {
	my ($self, $player, $card) = @_;
	$player = ref $player ? $player->player : $player;
	return $self->$player->card_exists($card);
};

function set_crib_complete => sub {
	my ($self) = @_;
	$self->crib_complete = 1;
};

function best_run_play => sub {
	my ($self, $player) = @_;
	$player = ref $player ? $player->player : $player;
	return $self->$player->best_run_play($self->play);
};

function next_to_play_id => sub {
	my ($self, $game) = @_;
	my $hand = $self->play->next_to_play;	
	return $hand;
};

1;
