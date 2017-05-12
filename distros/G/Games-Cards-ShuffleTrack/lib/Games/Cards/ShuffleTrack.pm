package Games::Cards::ShuffleTrack;

use 5.006;
use strict;
use warnings;

use List::Util      qw/any min/;
use List::MoreUtils qw/zip first_index true/;
use Scalar::Util    qw/looks_like_number/;

=head1 NAME

Games::Cards::ShuffleTrack - Track cards through shuffles and cuts

=head1 VERSION

Version 0.04_1

=cut

our $VERSION = '0.05';

my $cut_limits = {
	normal  => [0.19, 0.82], # on a 52 cards deck, cut between 10 and 43 cards
	short   => [0.09, 0.28], # on a 52 cards deck, cut between 5  and 15 cards
	center  => [0.36, 0.59], # on a 52 cards deck, cut between 19 and 31 cards
	deep    => [0.67, 0.86], # on a 52 cards deck, cut between 35 and 45 cards
};

my $decks = {
	empty =>          [],
	new_deck_order => [qw/AH 2H 3H 4H 5H 6H 7H 8H 9H 10H JH QH KH
						  AC 2C 3C 4C 5C 6C 7C 8C 9C 10C JC QC KC
						  KD QD JD 10D 9D 8D 7D 6D 5D 4D 3D 2D AD
						  KS QS JS 10S 9S 8S 7S 6S 5S 4S 3S 2S AS/],
	fournier =>       [qw/AS 2S 3S 4S 5S 6S 7S 8S 9S 10S JS QS KS
						  AH 2H 3H 4H 5H 6H 7H 8H 9H 10H JH QH KH
						  KD QD JD 10D 9D 8D 7D 6D 5D 4D 3D 2D AD
						  KC QC JC 10C 9C 8C 7C 6C 5C 4C 3C 2C AC/],
};

my $shortcuts = {
    'top'     => 1,
    'second'  => 2,
    'greek'   => -2,
    'bottom'  => -1,
};

my $expressions = {
	A   => qr/A[CHSD]/,
	2   => qr/2[CHSD]/,
	3   => qr/3[CHSD]/,
	4   => qr/4[CHSD]/,
	5   => qr/5[CHSD]/,
	6   => qr/6[CHSD]/,
	7   => qr/7[CHSD]/,
	8   => qr/8[CHSD]/,
	9   => qr/9[CHSD]/,
	10  => qr/10[CHSD]/,
	J   => qr/J[CHSD]/,
	Q   => qr/Q[CHSD]/,
	K   => qr/K[CHSD]/,

	C   => qr/(?:[A23456789JQK]|10)C/,
	H   => qr/(?:[A23456789JQK]|10)H/,
	S   => qr/(?:[A23456789JQK]|10)S/,
	D   => qr/(?:[A23456789JQK]|10)D/,
};


=head1 SYNOPSIS

This module allows you to simulate shuffles and cuts.

	use Games::Cards::ShuffleTrack;

	my $deck = Games::Cards::ShuffleTrack->new();

	$deck->overhand_shuffle( 2 );
	$deck->riffle_shuffle();
	$deck->cut( 'short' );
	$deck->riffle_shuffle();
	print "@{$deck->get_deck()}";

Or perhaps with more precision:

	my $deck = Games::Cards::ShuffleTrack->new();

	$deck->faro_in();
	$deck->cut( 26 );
	print $deck->get_deck();

See the rest of the documentation for more advanced features. See the examples folder for more detailed usage.


=head1 INSTALLATION

To install this module, run the following commands:

	perl Makefile.PL
	make
	make test
	make install


=head1 DECK REPRESENTATION

At the moment a deck is represented as a list of strings; each string represents a card where the first letter or digit (or digits, in the case of a 10) is the value of the card and the following letter is the suit:

	C - Clubs
 	H - Hearts
 	S - Spades
 	D - Diamonds

As an example, some card representations:

	AC - Ace of Clubs
	10S - Ten of Spades
	4D - 4 of Diamonds
	KH - King of Hearts

Still, you can add whichever cards you want to the deck:

	$deck->put( 'Joker' ); # place a Joker on top of the deck


=head1 SUBROUTINES/METHODS

=head2 Standard methods

=head3 new

Create a new deck.

	my $deck = Games::Cards::ShuffleTrack->new();

The order of the deck is from top to bottom, which means it is the reverse of what you see when you spread a deck in your hands with the cards facing you.

When you open most professional decks of cards you'll see the Ace of Spades (AS) in the front; this means it will actually be the 52nd card in the deck, since when you place the cards on the table facing down it will be the bottom card.

Currently this module doesn't support specific orders or different orders other than the new deck.

The order of the cards is as follows:

	Ace of Hearths through King of Hearts
	Ace of Clubs through King of Clubs
	King of Diamonds through Ace of Diamonds
	King of Spades through Ace of Spades

You can also specify the starting order of the deck among the following:

=over 4

=item * new_deck_order (the default order)

=item * fournier

=back

	my $deck = Games::Cards::ShuffleTrack->new( 'fournier' );

You can also set your own order:

	my $pile = Games::Cards::ShufleTrack->new( [qw/10S JS QS KS AS/] );

=cut

# TODO: What happens if the user has a typo in the order?
sub new {
	my ($self, $order) = @_;
	   $order ||= 'new_deck_order';

	my $cards;
	if ( ref $order eq 'ARRAY' ) {
		$cards = $order;
	}
	else {
		$cards = $decks->{ $order };
	}

	return bless {
		'deck'        => $cards,
		'original'    => $cards,
		'orientation' => 'down',
	}, $self;
}

=head3 restart

Reset the deck to its original status. The original is whatever you selected when you created the deck.

	$deck->restart;

Do bear in mind that by doing so you are replenishing the deck of whatever cards you took out of it.

=cut

sub restart {
	my $self = shift;
	return $self->_set_deck( @{$self->{'original'}} );
}


=head3 size, deck_size

Returns the size of the deck.

    my $size = $deck->deck_size;

=cut

sub size {
	my $self = shift;
	return $self->deck_size;
}

sub deck_size {
	my $self = shift;
	return scalar @{$self->{'deck'}};
}


=head3 original_size

Returns the original size of the deck.

	if ($size < 0.5 * $deck->original_size) {
		# if the deck has been exausted by over 50%
	}

=cut

sub original_size {
	my $self = shift;
	return scalar @{$self->{'original'}};
}


=head3 is_original

Checks to see if the order of the deck is still the same as the original order.

    if ($deck->is_original) {
        # ...
    }

This method checks for each card and also the orientation of the deck. The only case where the orientation of the deck doesn't matter is when the deck is empty, in which case that property is ignored.

=cut

sub is_original {
    my $self = shift;

    # check size
    my @original = @{$self->{'original'}};
    if ( $self->size != @original ) {
        return 0;
    }

    $self->size || return 1;

    # check orientation
    if ( $self->orientation ne 'down' ) {
        return 0;
    }
    
    # check order
    my @deck = @{$self->get_deck};
    for ( 0 .. $#deck ) {
        $deck[$_] eq $original[$_] || return 0;
    }

    return 1;
}


=head3 get_deck

Returns the deck (a reference to a list of strings).

	my $cards = $deck->get_deck();

=cut

# TODO: should we return a copy of the list instead of the list itself?
# TODO: use wantarray to allow for an array to be returned?
sub get_deck {
	my $self = shift;
	return $self->{'deck'};
}


=head3 orientation

Return whether the deck is face up or face down:

	if ( $deck->orientation eq 'down' ) {
		...
	}

The deck's orientation is either 'up' or 'down'.

=cut

sub orientation {
	my $self = shift;

	return $self->{'orientation'};
}


=head3 turn

If the deck was face up, it is turned face down; if the deck was face down, it is turned face up.

Turning the deck reverses its order.

	$deck->turn;

=cut

sub turn {
	my $self = shift;

	$self->{'orientation'} = $self->orientation eq 'down' ? 'up' : 'down';

	return $self->_set_deck( reverse @{$self->get_deck} );
}

=head3 count

Counts how many cards with specific characteristics are in the deck.

	# how many tens
	$deck->count( '10' );

	# how many Clubs
	$deck->count( 'C' );

	# how many Clubs and Hearts
	my ($clubs, $hearts) = $deck->count( 'C', 'H' );
	my $clubs_and_hearts = $deck->count( 'C', 'H' );

	# how many Jokers
	$deck->count( 'Joker' );

Since you can add whichever card you want to the deck, it should be noted how searching for values and suits works:

=over 4

=item * If looking for a value from 2 to A, you'll get the amount of cards with that value and one of the four suits

=item * If looking for a suit (C, H, S, D), you'll get the amount of cards with a value from 2 through Ace and that suit

=item * If looking for anything else, that something is compared to the whole card

=back

It is important to note:

	my $total = $deck->count( 'JC' );   # holds 4
	my $total = $deck->count( 'C', 'J' ); # holds 16, because the JC is only counted once
	my @total = $deck->count( 'C', 'J' ); # holds (13, 4)

Also:

	$deck->put( 'Joker' );
	$deck->put( 'Signed Joker' );
	$deck->count( 'Joker' ); # returns 2

	$deck->put( 'Signed 4C' );
	$deck->count( '4C' ); # returns 2, because you didn't removed the previous one

=cut

sub count {
	my $self = shift;
	my @results;

	if ( wantarray and @_ > 1 ) {
		return $self->_count_each( @_ );
	}
	else {
		return $self->_count_all( @_ );
	}
}

sub _count_each {
	my $self = shift;
	my @results;
	while (my $param = shift) {
		if ( exists $expressions->{$param} ) {
			push @results, true { /$expressions->{$param}/ } @{$self->get_deck};
		}
		else {
			push @results, true { /$param/ } @{$self->get_deck};
		}
	}
	return @results;
}

sub _count_all {
	my $self = shift;

	my @expressions;
	for my $param (@_) {
		push @expressions, exists $expressions->{$param} ?
							$expressions->{$param} :
							qr/$param/x,
	}

	my @results;
	for my $card (@{$self->get_deck}) {

		if (any { $card =~ $_ } @expressions) {
			push @results, $card;
		}

	}
	return scalar @results;
}


=head2 Shuffling

=head3 Overhand Shuffle

=head4 overhand_shuffle

In an overhand shuffle the cards are moved from hand to the other in packets, the result being similar to that of running cuts (the difference being that the packets in an overhand shuffle may be smaller than the ones in a running cut sequence).

	$deck->overhand_shuffle;

You can specify how many times you want to go through the deck (which is basically the same thing as calling the method that many times):

	$deck->overhand_shuffle( 2 );

=cut

sub overhand_shuffle {
	my $self  = shift;
	my $times = shift;

	if (not defined $times) {
		$times = 1;
	}

	return $self if $times < 1;

	$self->_packet_transfer( 1, 10 );

	return $times > 1 ?
		   $self->overhand_shuffle( $times - 1 ) :
		   $self
}


=head4 run

The act of running cards is similar to the overhand shuffle, but instead of in packets the cards are run singly.

	$deck->run( 10 );

When running cards you can choose whether to drop those cards on the top or on the bottom of the deck. By default, the cards are moved to the bottom of the deck.

	$deck->run( 10, 'drop-top' );
	$deck->run( 10, 'drop-bottom' );

Running cards basically reverses their order.

If no number is given then no cards are run.

If we're doing multiple runs we can set everything at the same time:

	$deck->run( 4, 6, 2 );

=cut

# TODO: review this code
sub run {
	my $self = shift;

	my @number_of_cards;
	my $where_to_drop;

	while ( my $param = shift ) {
		if ( looks_like_number( $param ) ) {
			push @number_of_cards, $param;
		}
		else {
			$where_to_drop = $param;
		}
	}

	@number_of_cards || return $self;
	$where_to_drop   ||= 'drop-bottom';

	my $number_of_cards = shift @number_of_cards;
	$number_of_cards > 0 or return $self;

	# take cards from top and reverse their order
	my @deck = @{$self->get_deck};
	my @run  = reverse splice @deck, 0, $number_of_cards;

	if ( $where_to_drop eq 'drop-top' ) {
		$self->_set_deck( @run, @deck );
	}
	else { # drop-bottom is the default
		$self->_set_deck( @deck, @run );
	}

	return $self->run( @number_of_cards, $where_to_drop );
}


=head3 Hindu Shuffle

=head4 hindu_shuffle

In a Hindu shuffle the cards are moved from hand to the other in packets, the result being similar to that of running cuts (the difference being that the packets in an overhand shuffle may be smaller than the ones in a running cut sequence).

	$deck->hindu_shuffle;

You can specify how many times you want to go through the deck (which is basically the same thing as calling the method that many times):

	$deck->hindu_shuffle( 2 );

The Hindu shuffle differs in result from the Overhand shuffle in that the packets are usually thicker; the reason for this is that while in the Overhand shuffle it's the thumb that grabs the cards (and the thumb can easily carry just one or two cards) in the Hindu shuffle it's more than one finger accomplishing this task, grabbing the deck by the sides, which makes it more difficult (hence, rare) to cut just one or two cards.

=cut

sub hindu_shuffle {
	my $self  = shift;
	my $times = shift || 1;

	$self->_packet_transfer( 4, 10 );

	return $times > 1 ?
		   $self->hindu_shuffle( $times - 1 ) :
		   $self
}

sub _packet_transfer {
	my $self = shift;
	my $min  = shift;
	my $max  = shift;

	my @deck = @{$self->get_deck};

	my @new_deck;

	while ( @deck ) {
		if (@deck < $max) { $max = scalar @deck }
		if (@deck < $min) { $min = scalar @deck }
		unshift @new_deck, splice @deck, 0, _rand( $min, $max );
	}

	return $self->_set_deck( @new_deck );
}


=head3 Riffle Shuffle

=head4 riffle_shuffle

Riffle shuffle the deck.

	$deck->riffle_shuffle();

In the act of riffle shuffling a deck the deck is cut into two halves of approximately the same size; each half is riffled so that the cards of both halves interlace; these cards usually drop in groups of 1 to 5 cards.

You can also decide where to cut the deck for the shuffle:

	$deck->riffle_shuffle( 'short' );  # closer to the top
	$deck->riffle_shuffle( 'center' ); # near the center
	$deck->riffle_shuffle( 'deep' );   # closer to the bottom
	$deck->riffle_shuffle( 26 );       # precisely under the 26th card

=cut

# TODO: add an option for an out-shuffle
# TODO: add an option to control top or bottom stock
# TODO: when dropping cards, should we favor numbers 2 and 3?
# TODO: with a lot of cards, the riffle should be done breaking the deck in piles
# TODO: consider how fast each half is being depleted and whether the packets riffled on each side are of similar sizes
sub riffle_shuffle {
	my $self  = shift;
	my $depth = shift;

	# cut the deck (left pile is the original top half)
	my $cut_depth = _cut_depth( $self->deck_size, $depth );

	my @left_pile  = @{$self->get_deck};
	my @right_pile = splice @left_pile, $cut_depth;

	my @halves = ( \@left_pile, \@right_pile );

	# drop cards from the bottom of each half to the pile (1-5 at a time)
	my @new_pile = ();
	while ( @left_pile and @right_pile ) {
		my $current_half = $halves[0];
		my $number_of_cards = int(rand( min(5, scalar @$current_half) ))+1;

		unshift @new_pile, splice @$current_half, -$number_of_cards;

		@halves = reverse @halves;
	}

	# drop the balance on top and set the deck to be the result
	$self->_set_deck( @left_pile, @right_pile, @new_pile );

	return $self;
}


=head3 Faro shuffle

In a faro shuffle the deck is split in half and the two halves are interlaced perfectly so that each card from one half is inserted in between two cards from the opposite half.

=head4 faro out

Faro out the deck.

	$deck->faro( 'out' );

In a "faro out" the top and bottom cards remain in their original positions.

Considering the positions on the cards from 1 to 52 the result of the faro would be as follows:

	1, 27, 2, 28, 3, 29, 4, 30, 5, 31, 6, 32, 7, 33, ...

=head4 faro in

Faro in the deck.

	$deck->faro( 'in' );

In a "faro in" the top and bottom cards do not remain in their original positions (top card becomes second from the top, bottom card becomes second from the bottom).

Considering the positions on the cards from 1 to 52 the result of the faro would be as follows:

	27, 1, 28, 2, 29, 3, 30, 4, 31, 5, 32, 6, 33, 7, ...

=cut

sub faro {
	my $self = shift;
	my $faro = shift; # by default we're doing a faro out

	# TODO: what happens when the deck is odd-sized?
	my @first_half  = @{$self->get_deck};
	my @second_half = splice @first_half, $self->deck_size / 2;

	$self->_set_deck(
			$faro eq 'in' ?
			zip @second_half, @first_half :
			zip @first_half,  @second_half
		);

	return $self;
}


=head2 Cutting

=head3 cut

Cut the deck.

	$deck->cut();

In a 52 cards deck, this would cut somewhere between 10 and 43 cards.

Cut at a precise position (moving X cards from top to bottom):

	$deck->cut(26);

If you try to cut to a position that doesn't exist nothing will happen (apart from a warning that you tried to cut to a non-existing position, of course).

You can also cut at negative positions, meaning that you're counting from the bottom of the deck and cutting above that card. For instance, to cut the bottom two cards to the top:

	$deck->cut(-2);

Additional ways of cutting:

	$deck->cut( 'short'  ); # on a 52 cards deck, somewhere between 5  and 15 cards
	$deck->cut( 'center' ); # on a 52 cards deck, somewhere between 19 and 31 cards
	$deck->cut( 'deep'   ); # on a 52 cards deck, somewhere between 35 and 45 cards

=head3 cut_below

You can cut below a specific card.

	$deck->cut_below( '9D' );

If the desired card is already on the bottom of the deck nothing will happen.

For more information on how to cut to a specific card please refer to the L<SEE ALSO> section of this documentation.

=head3 cut_above

You can cut above a specific card.

	$deck->cut_above( 'JS' );

If the desired card is already on top of the deck nothing will happen.

For more information on how to cut to a specific card please refer to the L<SEE ALSO> section of this documentation.

=cut

# TODO: delimit randomness of the cut between two numbers: $deck->cut( 1, 25 );
sub cut {
	my $self     = shift;
	my $position = shift;

	if (     defined $position
		 and looks_like_number( $position )
		 and abs($position) > $self->deck_size ) {
				warn "Tried to cut the deck at a non-existing position ($position).\n";
				return $self;
	}

	my $cut_depth = _cut_depth( $self->deck_size, $position );

	my @deck = @{$self->get_deck};
	unshift @deck, splice @deck, $cut_depth;

	return $self->_set_deck( @deck );
}

sub cut_below {
	my $self = shift;
	my $card = shift;

	return $self->cut( $self->find( $card ) );
}

sub cut_above {
	my $self = shift;
	my $card = shift;

	return $self->cut( $self->find( $card ) - 1 );
}

=head3 cut_to

Cuts a portion of the deck to another position

	$deck->cut_to( $pile );

You can specify exactly how many cards to cut or delimit the randomness of the cut:

	# cut exactly 15 cards to $pile
	$deck->cut_to( $pile, 15 );

	# cut between 10 and 26 cards to $pile
	$deck->cut_to( $pile, 10, 26 );

If the position doesn't exist yet you can also automatically create it:

	my $pile = $deck->cut_to();

This method returns the new pile.

=cut

# FIXME: in some situations this method alters the original order of the deck
sub cut_to {
	my $self = shift;

	# create the new pile if required
	my $new_pile;
	if ( defined($_[0]) and ref( $_[0] ) eq 'Games::Cards::ShuffleTrack' ) {
		$new_pile = shift;
	}
	else {
		$new_pile = Games::Cards::ShuffleTrack->new( 'empty' );
	}

	# TODO: could this be done with _cut_depth? (perhaps changing it a bit)
	# set the position
	my $lower_limit = shift;
	my $upper_limit = shift;

	my $position;

	if ( not defined $lower_limit ) {
		$position = _rand( 1, $self->deck_size );
	}
	elsif ( not defined $upper_limit ) {
		$position = $lower_limit;
	}
	else {
		$position = _rand( $lower_limit, $upper_limit );
	}

	# cut the deck
	$new_pile->place_on_top( splice @{$self->get_deck}, 0, $position );

	return $new_pile;
}


=head3 place_on_top

Places a pile of cards on top of the deck.

	$deck->place_on_top( qw/AS KS QS JS 10S/ );

=cut

# TODO place_on_top and put share similar code; review
sub place_on_top {
	my $self = shift;
	my @pile = @_;

	$self->_set_deck( @pile, @{$self->get_deck} );

	return $self;
}

=head3 complete_cut, move_to

Complete the cut by moving all cards from one deck onto another:

	$deck->complete_cut( $new_pile );
	
	# or

	$deck->move_to( $table );

=cut

sub complete_cut {
	my $self = shift;
	my $destination = shift;

	$self->cut_to( $destination, $self->deck_size );

	return $self;
}

sub move_to {
	my $self = shift;

	return $self->complete_cut( @_ );
}


=head3 running_cuts

Cut packets:

    $deck->running_cuts();

To do the procedure twice:

    $deck->running_cuts( 2 );

=cut

sub running_cuts {
	my $self  = shift;
	my $times = shift || 1;

	$self->_packet_transfer( 5, 15 );

	return $times > 1 ?
		   $self->overhand_shuffle( $times - 1 ) :
		   $self
}


=head3 bury

Buries a group of cards under another group:

	# bury the top 10 cards under the following 3 cards
	$deck->bury(10, 3);

	# move the top card to the 13th position
	$deck->bury( 1, 12 );

=cut

sub bury {
	my $self          = shift;
	my $first_amount  = shift;
	my $second_amount = shift;

	my @deck = @{$self->get_deck};

	splice @deck, $second_amount, 0, splice @deck, 0, $first_amount;

	$self->_set_deck( @deck );

	return $self;
}


=head2 Handling cards

There are a few different methods to track down cards.

=head3 find

Get the position of specific cards:

	my $position = $deck->find( 'AS' ); # find the position of the Ace of Spades

	my @positions = $deck->find( 'AS', 'KH' ); # find the position of two cards

If a card is not present on the deck the position returned will be a 0.

This method can also return the card at a specific position:

	my $card = $deck->find( 3 );

You can also request a card in a negative position (i.e., from the bottom of the deck). To get the second to last card in the deck:

	$deck->find( -2 );

If you're dealing five hands of poker from the top of the deck, for instance, you can easily find which cards will fall on the dealer's hand:

	$deck->find( 5, 10, 15, 20, 25 );

=cut

sub find {
	my $self  = shift;
	my @cards = @_;

	my @results;

	my $deck = $self->get_deck();

	for my $card ( @cards ) {

		push @results, looks_like_number( $card )
					 ? $self->_find_card_by_position( $card )
					 : $self->_find_card_by_name( $card );

	}

	return wantarray ? @results : $results[0];
}

sub _find_card_by_position {
	my $self = shift;
	my $card = shift;

	if ($card) {
		if ($card > 0) { $card--; }
		return $card > $self->deck_size - 1 ?
		        q{} :
		        $self->get_deck->[ $card ];
	}
	else {
		return q{};
	}
}

sub _find_card_by_name {
	my $self = shift;
	my $card = shift;

	my $position = 1 + first_index { $_ eq $card } @{$self->get_deck};

	return $position ? $position : 0;
}


=head3 find_card_before

Finds the card immediately before another card:

	# return the card immediately before the Ace of Spades
	$deck->find_card_before( 'AS' );

If the specified card is on top of the deck you will get the card on the bottom of the deck.

=cut

sub find_card_before {
	my $self = shift;
	my $card = shift;

	my $position = $self->find( $card );

	if ($position == 1) {
		return 0;
	}
	else {
		return $self->find( $position - 1 );
	}
}


=head3 find_card_after

Finds the card immediately after another card:

	# return the card immediately after the King of Hearts
	$deck->find_card_before( 'KH' );

If the specified card is on the bottom of the deck you will get the card on the top of the deck.

=cut

sub find_card_after {
	my $self = shift;
	my $card = shift;

    my $position = 1 + $self->find( $card );
    
    if ( $position > $self->deck_size ) {
        return 0;
    }

	return $self->find( $self->find( $card ) + 1 );
}


=head3 distance

Find the distance between two cards.

To find the distance between the Ace of Spades and the King of Hearts:

	$deck->distance( 'AS', 'KH' );

If the King of Hearts is just after the Ace of Spades, then the result is 1. If it's immediately before, the result is -1.

=cut

sub distance {
	my $self        = shift;
	my $first_card  = shift;
	my $second_card = shift;

	return $self->find( $second_card) - $self->find( $first_card );
}


=head3 put

Put a card on top of the deck. This is a new card, and not a card already on the deck.

	$deck->put( $card );

If the card was already on the deck, you now have a duplicate card.

=cut

sub put {
	my $self = shift;
	my $card = shift;

	$self->_set_deck( $card, @{$self->get_deck} );

	return $self;
}


=head3 insert

Inserts a card in a specified position in the deck. If the position isn't specified than the card is inserted somewhere at random.

	# insert a Joker at position 20
	$deck->insert( 'Joker', 20 );

	# replace a card somewhere in the deck at random
	$deck->insert( $card );

If the position doesn't exist the card will be replaced at the bottom of the deck.

You can also add cards to negative positions, meaning that the resulting position will be that negative position:

    # insert card so that it ends up being the last one in the deck
	$deck->insert( $card, -1 );

    # insert card so that it ends up being the 10th from the bottom
	$deck->insert( $card, -10 );

=cut

# TODO: what if the user inserts at position 0?
sub insert {
	my $self     = shift;
	my $card     = shift;
	my $position = shift;

	if ( not defined $position ) {
		$position = _rand( 1, $self->deck_size );
	}
	elsif ( $position > $self->deck_size ) {
		$position = $self->deck_size + 1;
	}
	elsif ( $position < 0 ) {
		$position = $self->deck_size + $position + 2;
	}

	splice @{$self->get_deck}, $position - 1, 0, $card;

	return $self;
}


=head3 deal

Deals a card, removing it from the deck.

	my $removed_card = $deck->deal();

Just as in regular gambling, you can deal cards from other positions:

	# deal the second card from the top
    my $card = $deck->deal( 'second' );

    # deal the second card from the bottom
    my $card = $deck->deal( 'greek' );

    # deal the card from the bottom of the deck
    my $card = $deck->deal( 'bottom' );

For more information on false dealing see the L<SEE ALSO> section.

If you're dealing cards to a pile you can actually state where you're dealing:

	$deck->deal( $pile );

You can still do a false deal to a pile:

	$deck->deal( 'second', $pile );

	# or

	$deck->deal( $pile, 'second' );

Dealing from an empty deck won't do anything, but a warning will be issued.

=cut

sub deal {
	my $self = shift;

	if (not $self->size) {
		warn "Tried to deal without cards.\n";
		return $self;
	}

	my $params = _parse_params(@_);

	my $destination = $params->{_has_places} ?
						$params->{'places'}[0] :
						undef;

	my $position = $shortcuts->{'top'};
	if ($params->{_has_options}) {
		my $param = $params->{'options'}->[0];
		if (exists $shortcuts->{$param}) {
			$position = $shortcuts->{$param};
		}
	}

	my $card = $self->remove( $position );

	if ( defined $destination ) {
		return $destination->put( $card );
	}
	else {
		return $card;
	}
}

=head3 remove

Removes a card from the deck.

	# remove the 4th card from the top
	my $card = $deck->remove( 4 );

=cut

# TODO: allow removal of several cards (do note that positions change as cards are removed)
sub remove {
	my $self     = shift;
	my $position = shift;

	my @deck = @{$self->get_deck};

    if ($position > 0) { $position--; }

	my $card = splice @deck, $position, 1;

	$self->_set_deck( @deck );
	return $card;
}


=head3 peek

Peek at a position in the deck (this is essentially the same thing as &find()).

	# peek the top card
	my $card = $deck->peek( 1 );

You can also peek the top and bottom card by using an alias:

	# peek the top card
	my $card = $deck->peek( 'top' );

	# peek the bottom card
	my $card = $deck->peek( 'bottom' );

Negative indexes are also supported:

	# peek the second from bottom card
	my $card = $deck->peek( -2 );

=cut

sub peek {
	my $self     = shift;
	my $position = shift || 1;

	if (_is_shortcut( $position )) {
		$position = $shortcuts->{$position};
	}

	return $self->find( $position );
}


=head3 take_random

Remove a random card from the deck.

	my $random_card = $deck->take_random();

You can also specify limits (if you're somehow directing the person taking the card to a particular section of the deck):

	my $random_card = $deck->take_random( 13, 39 );

=cut

sub take_random {
	my $self = shift;

	my $lower_limit = shift || 1;
	my $upper_limit = shift;

	$upper_limit = defined $upper_limit ?
					$upper_limit :
					$self->deck_size;

	return $self->remove( _rand( $lower_limit, $upper_limit ) );
}


=head3 remove_all

Removes all cards that match a pattern from the deck.

    $deck->remove_all( 'Joker' ); # remove all Jokers
    $deck->remove_all( 'A' ); # remove all Aces
    $deck->remove_all( 'C' ); # remove all Clubs
    $deck->remove_all( 'J', 'Q', 'K' ); # remove all court cards

Without arguments this method does precisely what it states:

    $deck->remove_all(); # removes everythin from the deck

=cut

sub remove_all {
    my $self = shift;

    if ( @_ ) {
        while (my $param = shift) {
            if ( exists $expressions->{$param} ) {
                $self->_set_deck( grep { not /$expressions->{$param}/ } @{$self->get_deck} );
            }
            else {
                $self->_set_deck( grep { not /$param/ } @{$self->get_deck} );
            }
        }
    }
    else {
        $self->_set_deck();
    }
    
    return $self;
}


=head3 dribble

Dribble the cards (usually to select one, which could either be the last one to fall or the one that would be next).

	# dribble cards onto $pile
	$deck->dribble( $pile );

	# same thing, but declaring $pile
    $pile = $deck->dribble;

    # dribble to position 10 (in a 52 card deck, 42 cards would fall)
    $deck->dribble( 10 );

    # dribble 10 cards
    $deck->dribble( -10 );

    # dribble to position between 10 and 20
    $deck->dribble( 10, 20 );

    # dribble to position between 10th from the top and 10th from the bottom
    $deck->dribble( 10, -10 );

=cut

# TODO: what happens if you're dribbling and have no cards?
sub dribble {
	my $self   = shift;
	my $params = _parse_params( @_ );

	my $has_destination = @{$params->{'places'}};
	my $destination = $has_destination ?
						$params->{'places'}[0] :
						Games::Cards::ShuffleTrack->new( 'empty' );

	my ($lower_limit, $upper_limit) = $self->_fix_limits( @{$params->{'numbers'}} );

	if ( defined $lower_limit ) {
		$lower_limit = $self->size - $lower_limit;
		$upper_limit = defined $upper_limit ?
						$self->size - $upper_limit :
						$lower_limit;
	}
	else {
		$lower_limit = min( $self->size, 5 );
		$upper_limit = $self->size < 5 ? $self->size : $self->size - 5;
	}

	$self->turn;
	my $transfer = $self->cut_to( $lower_limit, $upper_limit );
	$transfer->turn;
	$transfer->move_to( $destination );

	return $has_destination ? $self : $destination;
}

# subroutines

# TODO: fix limits in other methods (just being used in dribble)
sub _fix_limits {
	my $self = shift;
	my @limits;

	while ( my $limit = shift ) {
		push @limits, $limit < 0 ? $self->size + $limit : $limit;
	}

	return @limits;
}

# TODO: use this for every method (just being used in dribble)
sub _parse_params {
	my $params = {
		numbers => [],
		places  => [],
		options => [],
	};
	while (my $param = shift) {
		if (looks_like_number($param)) {
			push @{$params->{'numbers'}}, $param;
		}
		elsif (ref $param eq 'Games::Cards::ShuffleTrack') {
			push @{$params->{'places'}}, $param;
		}
		else {
			push @{$params->{'options'}}, $param;
		}
	}

	for (qw/numbers places options/) {
		$params->{"_has_$_"} = @{$params->{$_}};
	}
	return $params;
}

sub _set_deck {
	my $self = shift;
	return $self->{'deck'} = [@_];
}

sub _rand {
	my ($lower_limit, $upper_limit) = @_;

	return int($lower_limit + int(rand( $upper_limit - $lower_limit )));
}

sub _cut_depth {
	my $deck_size = shift;
	my $position  = shift;

	if (not defined $position) {
		$position = 'normal';
	}

	if ( any { $_ eq $position } keys %$cut_limits ) {
		my ($lower, $upper) = @{$cut_limits->{ $position }};
		$position = _rand( $deck_size * $lower, $deck_size * $upper );
	}

	return $position;
}

sub _is_shortcut {
	my $shortcut = shift;

	return exists $shortcuts->{$shortcut};
}


=head1 GLOSSARY

The following is not a comprehensive list of gambling terms; it is simply a list of some terms used somewhere in this module that may be useful.

The text has been taken verbatim from The Expert at the Card Table.

=over 4

=item * Stock

That portion of the deck that contains certain cards, placed in some particular order for dealing; or certain
desirable cards placed at top or bottom of the deck.

=item * Run

To draw off one card at a time during the process of the hand shuffle. There is little or no difficulty in acquiring
perfect ability to run the whole deck through in this manner with the utmost rapidity. The left thumb presses
lightly on the top card, the right hand alone making the movement necessary to shuffle.

=item * Break

A space or division held in the deck. While shuffling it is held at the end by the right thumb. It is formed under
the in-jog when about to under cut for the shuffle, by pushing the in-jog card slightly upwards with the right
thumb, making a space of from an eighth to a quarter of an inch wide, and holding the space, by squeezing the
ends of the packet to be drawn out, between the thumb and second and third fingers. The use of the break
during a shuffle makes it possible to throw any number of cards that are immediately above it, in one packet
into the left hand, without disarranging their order. The break is used when not shuffling, to locate any particular
card or position, and is infinitely superior to the common method of inserting the little finger. A break can be
held firmly by a finger or thumb of either hand, and entirely concealed by the other fingers of the same hand. It
is also the principal aid in the blind riffles and cuts.

=item * Throw

To pass from the right hand to the left, during a shuffle, a certain number of cards in one packet, thereby
retaining their order. A throw may be required at the beginning, during the process, or at the end of a shuffle;
and the packet to be thrown may be located by the jog, or break, or by both.

=item * Top Card

The card on top of packet held in the left hand, or the original top card of the full deck, which about to be
shuffled.

=item * Riffle

The modern method of shuffling on the table by springing, the ends of two packets into each other.

=item * Crimp

To bend one or a number of cards, so that they may be distinguished or located. 

=back


=head1 AUTHOR

Jose Castro, C<< <cog at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-games-cards-shuffletrack at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Games-Cards-ShuffleTrack>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc Games::Cards::ShuffleTrack


You can also look for information at:

=over 4

=item * Github

L<https://github.com/cog/Games-Cards-ShuffleTrack>

=item * Search CPAN

L<http://search.cpan.org/dist/Games-Cards-ShuffleTrack/>

=back


=head1 SEE ALSO

The following is an extremely small list of recommended books:

=over 4

=item * The Expert at the Card Table, by S. W. Erdnase

=item * Card College, by Roberto Giobbi

=back


=head1 LICENSE AND COPYRIGHT

Copyright 2016 Jose Castro.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of Games::Cards::ShuffleTrack
