package Game::Cribbage::Deck::Card;

use strict;
use warnings;

use Rope;
use Rope::Autoload;

our (%card_to_value_map, %card_run_to_value_map, %card_suit_to_symbol);
BEGIN {
	%card_to_value_map = (
		A => 1,
		(map {$_ => 10} qw/J Q K/),
	);
	%card_run_to_value_map = (
		A => 1,
		J => 11,
		Q => 12,
		K => 13
	);
	%card_suit_to_symbol = (
		H => '♥️',
		S => '♠️',
		D => '♦️',
		C => '♣️'
	);
}

property [qw/id used/] => (
	initable => 1,
	writeable => 1,
	configurable => 0,
	enumerable => 1,
	value => 0
);

property [qw/suit symbol/] => (
	initable => 1,
	writeable => 0,
	configurable => 0,
	enumerable => 1
);

function value => sub {
	my ($self) = @_;
	return $card_to_value_map{$self->{symbol}} || $self->{symbol};
};

function run_value => sub {
	my ($self) = @_;
	return $card_run_to_value_map{$self->{symbol}} || $self->{symbol};
};

function ui_stringify => sub {
	my ($self) = @_;
	return sprintf "%s %s", $card_suit_to_symbol{$self->{suit}}, $self->{symbol};
};

function stringify => sub {
	my ($self) = @_;
	return sprintf "%s%s", $self->{symbol}, $card_suit_to_symbol{$self->{suit}};
};

function match => sub {
	my ($self, $card) = @_;
	if ($self->suit eq $card->{suit} && $self->symbol =~ m/^($card->{symbol})$/) {
		return 1;
	} 
	return 0;
};

1;
