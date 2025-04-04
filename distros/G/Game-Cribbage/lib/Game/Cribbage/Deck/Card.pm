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

function suit_symbol => sub {
	my ($self) = @_;
	return $card_suit_to_symbol{$self->{suit}};
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

__END__

=head1 NAME

Game::Cribbage::Deck::Card - card

=head1 VERSION

Version 0.12

=cut

=head1 SYNOPSIS

	use Game::Cribbage::Deck::Card;

	my $card = Game::Cribbage::Deck::Card->new(
		id => 13,
		used => 0,
		suit => 'H',
		symbol => 'K'
	);

	$card->value(); # 10

	$card->run_value(); # 13 
	

=head1 PROPERTIES

=head2 id

Scalar property to store a unique identifier for the card

	$card->id;

=head2 used

Boolean property to store whether the card has been used.

	$card->used;

=head2 suit

Readonly property that stores the current cards suit.

	$card->suit;

=head2 symbol

Readonly property that stores the current cards symbol.

	$card->symbol;

=head1 FUNCTIONS

=head2 value

Returns the value of the card where A is 1 and J, Q, K is 10.

	$card->value;

=head2 run_value

Returns the run sequence value for the card where A is 1, J is 11, Q is 12 and K is 13.

	$card->run_value;

=head2 suit_symbol

Returns the utf8 charcter that represents the suit.

	$card->suit_symbol;

=head2 ui_stringify

Stringify the current card with suit followed by symbol.

	$card->ui_stringify;

=head2 strigify

Stringify the current card with symbol followed by suit.

	$card->stringify;

=head2 match

Validate whether the passed card is the same as the current card.

	$card->match($card);

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-game-cribbage at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Game-Cribbage>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Game::Cribbage

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Game-Cribbage>

=item * Search CPAN

L<https://metacpan.org/release/Game-Cribbage>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2024 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
