package Game::Cribbage::Hands;

use strict;
use warnings;

use Object::Proto::Sugar -types;
use Game::Cribbage::Player::Hand;
use Game::Cribbage::Play;
use Game::Cribbage::Error;

has id => (
	is => 'rw',
	isa => Int
);

has number => (
	is => 'ro',
	isa => Int
);

has crib_player => (
	is => 'rw',
	isa => Str
);

has crib_complete => (
	is => 'rw',
	isa => Bool
);

has [qw/starter play player1 player2 player3 player4/] => (
	is => 'rw',
	isa => Object
);

has cannot_play => (
	is => 'rw',
	isa => HashRef,
	default => {}
);

has play_history => (
	is => 'rw',
	isa => ArrayRef,
	default => []
);


sub BUILD {
	my ($self, $options) = @_;
	$self->crib_player('player1') if !$self->crib_player;
	return $self;
}

sub init {
	my ($self, $game) = @_;
	for (@{$game->players}) {
		my $player = $_->player;
		$self->$player(Game::Cribbage::Player::Hand->new(
			player => $player
		));
	}
	$self->new_play();
	$self;
}

sub add_starter_card {
	my ($self, $player, $card) = @_;
	$self->starter($card);
	
	my $scored = 0;
	if ($card->symbol =~ m/^J$/) {
		$scored = Game::Cribbage::Play::Score->new(
			player => $player,
			card => $card,
			flipped => 1
		);
		push @{$self->play->scored}, $scored;
	}

	for (qw/player1 player2 player3 player4/) {
		if ($self->$_) {
			$self->$_->starter($card);
		}
	}

	return $scored;
}

sub find_player_card {
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
}

sub force_play_card {
	my ($self, $card) = @_;
	my $player;
	($card, $player) = $self->find_player_card($card);
	$card->used(1);
	my $scored = $self->play->force_card($player, $card);
	$self->set_next_to_play();
	return ($scored, $player);
}

sub play_card {
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
	$card->used(1);
	my $scored = $self->play->card($player, $card);
	$self->set_next_to_play();
	return $scored;
}

sub cannot_play_a_card {
	my ($self, $player) = @_;
	
	my $hand = ref $player ? $player->player : $player;
	if ($self->play->next_to_play ne $hand) {
		return Game::Cribbage::Error->new( message => 'It is not the turn of ' . $hand );
	}

	my $current_total = $self->play->total;

	my @can_be_played;
	for (@{$self->$hand->cards}) {
		next if $_->used;
		if ( ($current_total + $_->value) < 31 ) {
			push @can_be_played, $_;
		}
	}

	return \@can_be_played if scalar @can_be_played;

	$self->set_next_to_play();

	$self->cannot_play->{$hand} = 1;

	return 1;
}

sub set_next_to_play {
	my ($self) = @_;
	my $next = $self->parse_next_to_play($self->play->next_to_play);
	$self->play->next_to_play($next);
}

sub parse_next_to_play {
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
}

sub set_player_hand_id {
	my ($self, $player, $id) = @_;
	my $hand = ref $player ? $player->player : $player;
	$self->$hand->id($id);
	return $id;
}

sub get_player_hand_id {
	my ($self, $player) = @_;
	my $hand = ref $player ? $player->player : $player;
	return $self->$hand->id;
}

sub get_crib_player_hand_id {
	my ($self) = @_;
	my $hand = $self->crib_player;
	return $self->$hand->id;
}

sub get_card {
	my ($self, $player, $card_index) = @_;
	my $hand = ref $player ? $player->player : $player;
	my $card = $self->$hand->get($card_index);
	return $card;
}

sub play_score {
	my ($self) = @_;
	return $self->play->total || 0;
}

sub last_play_score {
	my ($self) = @_;
	my $prev = $self->play_history->[-2];
	return $prev ? $prev->total : 'This is the first play';
}

sub new_play {
	my ($self) = @_;
	my $next_to_play = $self->crib_player;
	if ($self->play) {
		$next_to_play = $self->parse_next_to_play(ref $self->play->cards->[-1]->player ? $self->play->cards->[-1]->player->player : $self->play->cards->[-1]->player);
	}
	$self->play(Game::Cribbage::Play->new(
		next_to_play => $next_to_play
	));
	push @{$self->play_history}, $self->play;
}

sub next_play {
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

	$self->cannot_play({});
	# now we know cards can't be played confirm we have cards left to Play another 'play'.
	if (!$available_cards) { 
		$game->end_hands(); 
		return undef;
	}
	
	my $scored;
	if (!$self->play->scored->[-1] || !$self->play->scored->[-1]->go) {
		$scored = $self->play->end_play();
	}

	$self->new_play();

	return $scored;
}

sub end_play {
	my ($self) = @_;

	my $scored;

	if (!$self->play->scored->[-1] || !$self->play->scored->[-1]->go) {
		$scored = $self->play->end_play();
	}

	$self->play(undef);

	return $scored;
}

sub score_hands {
	my ($self) = @_;
	my %scored;
	for (qw/player1 player2 player3 player4/) {
		$scored{$_} = $self->$_->calculate_score()
			if ($self->$_);
	}
	return \%scored;
}

sub card_exists {
	my ($self, $player, $card) = @_;
	$player = ref $player ? $player->player : $player;
	return $self->$player->card_exists($card);
}

sub set_crib_complete {
	my ($self) = @_;
	$self->crib_complete(1);
}

sub best_run_play {
	my ($self, $player) = @_;
	$player = ref $player ? $player->player : $player;
	return $self->$player->best_run_play($self->play);
}

sub next_to_play_id {
	my ($self, $game) = @_;
	my $hand = $self->play->next_to_play;	
	return $hand;
}

1;
