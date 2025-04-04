package Game::Cribbage::Deck;

use strict;
use warnings;

use Rope;
use Rope::Autoload;
use List::Util qw//;
use Game::Cribbage::Deck::Card;

property deck => (
	initable => 1,
	writeable => 1,
	configurable => 0,
	enumerable => 1,
);

function cards => sub {
	return $_[0]->deck;
};

function INITIALISED => sub {
	return $_[0]->reset();
};

function reset => sub {
	$_[0]->shuffle();
	$_[0];
};

function shuffle => sub {
	my $i = 0;
	my @DECK;
	for my $suit (qw/H S D C/) {
		for ('A', 2 .. 10, 'J', 'Q', 'K') {
			$i++;
			push @DECK,
				Game::Cribbage::Deck::Card->new(
					suit => $suit,
					symbol => $_,
					id => $i	
				);
		}
	}
	$_[0]->deck = [List::Util::shuffle @DECK];
	$_[0];
};

function draw => sub {
	shift @{$_[0]->deck}
};

function force_draw => sub {
	my ($self, $card) = @_;
	
	my $i = 0;
	for (@{$self->deck}) {
		if ($_->suit eq $card->{suit} && $_->symbol =~ m/^$card->{symbol}$/) {
			last;
		} else {
			$i++;
		}
	}

	my $force = splice @{$self->deck}, $i, 1;

	#if ($card->{used}) {
	#	$force->used = 1;
	#}

	return $force;
};

function get => sub {
	$_[0]->deck->[$_[1]];
};

function card_exists => sub {
	my ($self, $card) = @_;

	for (@{$self->deck}) {
		if ($_->suit eq $card->{suit} && $_->symbol =~ m/^$card->{symbol}$/) {
			return 1;
		}
	}

	return 0;
};

function generate_card => sub {
	return Game::Cribbage::Deck::Card->new(
		%{ $_[1] }
	);
};

1;

__END__

=head1 NAME

Game::Cribbage::Deck - deck of cards

=head1 VERSION

Version 0.12

=cut

=head1 SYNOPSIS

	use Game::Cribbage::Deck;

	my $deck = Game::Cribbage::Deck->new();

	$deck->shuffle();

	$deck->draw();

	$deck->get($index);


=head1 PROPERTIES

=head2 deck

ArrayRef property that contains L<Game::Cribbage::Deck::Card> cards that represent the deck.

=head1 FUNCTIONS

=head2 cards

Returns all cards in the current deck. This is just a wrapper around calling the deck property.

	$deck->cards;

=head2 reset

Reset the deck to 52 cards. This is just a wrapper around the shuffle function.

	$deck->reset;

=head2 shuffle

Resets the deck to 52 cards and shuffles them. Each time this function is called it resets the deck property.

	$deck->shuffle;

=head2 draw

Draw a card from the deck. This shifts the first item from the deck property.

	$deck->draw;


=head2 force_draw

Force draw a specific card from the deck. This splices the found item from the deck.

	$deck->force_draw({ suit => 'H', symbol => 7 });

=head2 get

Get a card by index from the deck property.

	$deck->get(15);

=head2 card_exists

Check whether a card exists in the deck, aka it has not been drawn yet.

	$deck->card_exists({ suit => 'H', symbol => 7 });

=head2 generate_card

Utility function to generate a new L<Game::Cribbage::Deck::Card>.

	$deck->generate_card({
		id => 7,
		used => 1,
		suit => 'H',
		symbol => 7
	});

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

