package Games::Cards;

=pod

=head1 NAME

Games::Cards -- Perl module for writing and playing card games

=head1 SYNOPSIS

    use Games::Cards;
    my $Rummy = new Games::Cards::Game;

    # Create the correct deck for a game of Rummy.
    my $Deck = new Games::Cards::Deck ($Rummy, "Deck");

    # shuffle the deck and create the discard pile
    $Deck->shuffle;
    my $Discard = new Games::Cards::Queue "Discard Pile";

    # Deal out the hands
    foreach my $i (1 .. 3) {
	my $hand = new Games::Cards::Hand "Player $i" ;
	$Deck->give_cards($hand, 7);
	$hand->sort_by_value;
	push @Hands, $hand;
    }

    # print hands (e.g. "Player 1: AS  2C  3C  3H 10D  QS  KH")
    foreach (@Hands) { print ($_->print("short"), "\n") }
    
    $Hands[1]->give_a_card ($Discard, "8D"); # discard 8 of diamonds

=head1 DESCRIPTION

This module creates objects and methods to allow easier programming of card
games in Perl. It allows you to do things like create decks of cards,
have piles of cards, hands, and other sets of cards, turn cards face-up
or face-down, and move cards from one set to another. Which is pretty much
all you need for most card games.

Sub-packages include:

=over 4

=item Games::Cards::Undo

This package handles undoing and redoing moves (important for solitaire).

=item and Games::Cards::Tk

This package allows you to write games that use a Tk graphical interface.
It's designed so that it will be relatively easy to write a game that uses
i<either> a GUI or a simple text interface, depending on the player's
circumstances (availability of Tk, suspicious boss, etc.). See
L<Games::Cards::Tk> for more details on writing Tk games.

=back

=head2 Quick Overview of Classes

A GC::Game stores information like what cards are in the starting deck,
plus pointers to the various Cards and CardSets.

A GC::Card represents one playing card. Every Card must belong to one
(and only one) CardSet at every point during the game.

A GC::CardSet is mostly just a set of GC::Cards. A CardSet has a unique
name. Many also have short nicknames, which make it easier to write games
that move cards between the sets. (See Klondike or FreeCell, for example.)

There are many sorts of CardSet. The basic differentiation is Piles,
for which you only access the top or bottom card (or cards) and Hands,
where you might access any one of the cards in the Hand. Piles are
broken up into Stacks and Queues, and every game starts with a Deck of
cards (or more than one).

=cut

# TODO get rid of size, have cards return wantarray ? array of cards : size
#
# TODO Games::Cards::Undo::Exists. If not defined, don't bother calling
# GC::Undo::store etc. on every turn. Then each game can "use GCU" or not.

use strict;
use vars qw($VERSION);
require 5.004; # I use 'foreach my'

# Stolen from `man perlmod`
$VERSION = do { my @r = (q$Revision: 1.45 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r }; # must be all one line, for MakeMaker

# Handle undoing/redoing moves
use Games::Cards::Undo;

# sub-packages
{ 
package Games::Cards::Game;

package Games::Cards::Deck;
package Games::Cards::Queue;
package Games::Cards::Stack;
package Games::Cards::Pile;
package Games::Cards::Hand;
package Games::Cards::CardSet;

package Games::Cards::Card;
}


=head2 Class Games::Cards::Game

This class represents a certain game, like War, or Solitaire. This is
necessary to store the various rules for a given game, like the ranking
of the cards. (Or, for more exotic games, how many cards of what type are
in the deck.) Methods:

=over 4

=cut

{
package Games::Cards::Game;
# suits is a reference to an array listing the suits in the deck
# cards_in_suit is a reference to a hash whose keys are the names of the
#     cards in each suit, and values are the (default) values of those cards
# (Card names will be strings, although they might be "2". Values are
# integers, so that we can compare cards with other cards.)
#
# cardset_by_nickname is a hash whose keys are short (unique) nicknames and
# values are the CardSets (e.g., player's Hands, Piles, etc.) so nicknamed
# cardset_by_name is the same with the CardSet names
# card_by_truename stores Cards via their truenames. (See Card::truename)

my $Default_Suits = [qw(Clubs Diamonds Hearts Spades)];
# (Parts of) this hash will need to be reset in lots of games.
my $Default_Cards_In_Suit = {
    "Ace" => 1,
    2 => 2,
    3 => 3,
    4 => 4,
    5 => 5,
    6 => 6,
    7 => 7,
    8 => 8,
    9 => 9,
    10 => 10,
    "Jack" => 11,
    "Queen" => 12,
    "King" => 13,
};

=item current_game

Returns the current Game object. In almost every case, you'll only be
working with one at a time.

=item set_current_game(GAME)

In theory, these subs let you handle multiple Games at once, as long
as you set_current_game to the right one. Note that Game->new automatically
sets the current Game to be that game, so in 99% of cases, you won't have to
call set_current_game.

=cut

my $_Current_Game;
sub current_game { return $_Current_Game; }
sub set_current_game {$_Current_Game = shift;}

=item new(HASHREF)

creates a new game. HASHREF is a reference to a hash containing zero or more
of the keys "suits" and "cards_in_suit". "suits" is a list of the suits in a
deck, "cards_in_suit" is a reference to a hash whose keys are the names
of the cards in one suit and whose values are the values (or ranks) of those
cards. If "suits" is not given, the default suits (Clubs, Diamonds, Hearts,
Spades) are used. If "cards_in_suit" is not given, the default cards
(Ace, 2..10, Jack, Queen, King with values 1..13) are used.
For example, war would require "Ace"=>14.

=cut

    sub new {
	my $class = shift;
	my $hashref = shift;
	my $cardgame = {
	    "suits" => $hashref->{"suits"} || $Default_Suits,
	    "cards_in_suit" => $hashref->{"cards_in_suit"} ||
	                       $Default_Cards_In_Suit,
	    "cardset_by_name" => {},
	    "cardset_by_nickname" => {},
	};

	bless $cardgame, $class;
	# For now, this game will be the current game
	$cardgame->set_current_game;

	return $cardgame;
    } # end sub Games::Cards::Game::new

    # Store a CardSet. Use separate hashes for cardset's name and nickname,
    # for convenience.
    sub store_cardset {
        my ($self, $cardset) = @_;
	$self->{"cardset_by_name"}->{$cardset->name} = $cardset;
	if (defined (my $nick = $cardset->nickname)) {
	    $self->{"cardset_by_nickname"}->{$nick} = $cardset;
	}
    }

=item get_cardset_by_name(NAME)

Returns the CardSet with name NAME

=cut

    sub get_cardset_by_name {
        my ($self, $name) = @_;
	if (exists ($self->{"cardset_by_name"}->{$name})) {
	    return $self->{"cardset_by_name"}->{$name};
	} else {
	    return undef;
	}
    }

=item get_cardset_by_nickname(NAME)

Returns the CardSet with nickname NAME

=cut

    sub get_cardset_by_nickname {
        my ($self, $nickname) = @_;
	if (exists ($self->{"cardset_by_nickname"}->{$nickname})) {
	    return $self->{"cardset_by_nickname"}->{$nickname};
	} else {
	    return undef;
	}
    }

    # Store a Card
    sub store_card {
        my ($self, $card) = @_;
	my $truename = $card->truename;
	$self->{"card_by_truename"}->{$truename} = $card;
    }

=item get_card_by_truename(NAME)

Returns the Card with truename NAME

=cut

    sub get_card_by_truename {
        my ($self, $truename) = @_;
	if (exists ($self->{"card_by_truename"}->{$truename})) {
	    return $self->{"card_by_truename"}->{$truename};
	} else {
	    return undef;
	}
    }

} # end package Games::Cards::Game

######################################################################
# CardSet and its subclasses

=head2 Games::Cards::Deck

A deck is a deck of cards. The number of cards and identities of the cards in
the deck depend on the particular Game for which the deck is used.

=over 4

=cut

{
package Games::Cards::Deck;
@Games::Cards::Deck::ISA = qw (Games::Cards::Queue);

=item new (GAME, NAME)

creates an I<unshuffled> deck of cards. For each card in the deck it creates
a name, suit, value, and suit value. GAME is the GC::Game this deck
belongs to, and it stipulates the number of cards in the deck, etc. NAME is the
name to give the deck, e.g.  "Deck". 

=back

=cut

    sub new {
	my ($class, $game, $deckname) = @_;
	if (ref($class)) {$class = ref($class)}
	# This allows us to get Tk or non-Tk automatically
	(my $qclass = $class) =~ s/::Deck/::Queue/;
	my $deck = $qclass->new($game, $deckname);
	my %cards = %{$game->{"cards_in_suit"}};

	# make an unshuffled deck
	(my $cclass = $class) =~ s/::Deck/::Card/;
	foreach my $suit_value (1..@{$game->{"suits"}}) {
	    my $suit = $game->{"suits"}->[$suit_value-1];
	    foreach my $name (keys %cards) {
		my $arg = {
		    "suit"=>$suit, "name"=> $name,
		    "suit_value" => $suit_value, "value" => $cards{$name}
		};
		my $new_card = $cclass->new($game, $arg);
		push @{$deck->{"cards"}}, $new_card;
		$new_card->set_owning_cardset($deck);
	    }
	}

	bless $deck, $class;
    } # end sub Games::Cards::Deck::new
} # end package Games::Cards::Deck

=head2 Class Games::Cards::Queue

A Queue (cf. computer science terminology, or the C++ stdlib) is a first-in
first-out pile of cards. Cards are removed from the top of the pile, but new
cards are added to the bottom of the pile.  This might represent, say, a pile
of face-down cards, like the player's hand in War.

=cut

{
package Games::Cards::Queue;
# cards array has 0 as the top card, -1 as the bottom card (opposite of Queue,
# for convenience when moving cards from a Queue to a stack or vice versa).
# We push to add cards, but shift to remove cards.
    @Games::Cards::Queue::ISA = qw(Games::Cards::Pile);

    # inherit SUPER::new

    sub remove_cards {
    # remove (and return a ref to) top arg1 cards from the Queue
	my ($thing, $number) = @_;
	return $thing->splice (0, $number);
    } # end sub Games::Cards::Queue::remove_cards

    sub add_cards {
    # Add array of Cards arg1 to the Queue
	my ($thing, $cards) = @_;
	$thing->splice ($thing->size, 0, $cards);
    } # end sub Games::Cards::Queue::add_cards

    sub top_card {
	my $set = shift;
        return $set->size ? $set->{"cards"}->[0] : 0;
    } # end sub Games::Cards::Queue::top_card

    sub print_ordered_cards {
    # returns the cards in the set in the correct order to be printed
        return shift->{"cards"};
    } # end sub Games::Cards::Queue::print_ordered_cards

} #end package Games::Cards::Queue

=head2 Class Games::Cards::Stack

A stack (cf. computer science terminology, or the C++ stdlib) is a last-in
first-out pile of cards. Cards are removed from the top of the pile, and new
cards are also added to the top of the pile. This would usually represent a
pile of cards with its top card (and perhaps all cards) face up.

=cut

{
package Games::Cards::Stack;
# cards array has -1 as the top card, 0 as the bottom card (opposite of Queue,
# for convenience when moving cards from a Queue to a stack or vice versa).
# We only access the top of the stack, pushing to add and popping to remove.
    @Games::Cards::Stack::ISA = qw(Games::Cards::Pile);

    # inherit SUPER::new

    sub remove_cards {
    # remove (and return a ref to) top arg1 cards from the Stack
	my ($thing, $number) = @_;
	return $thing->splice (-$number);
    } # end sub Games::Cards::Stack::remove_cards

    sub add_cards {
    # Add array of Cards arg1 to the Stack
	my ($thing, $cards) = @_;
	$thing->splice($thing->size, 0, $cards);
    } # end sub Games::Cards::Stack::add_cards

    sub top_card {
	my $set = shift;
        return $set->size ? $set->{"cards"}->[-1] : 0;
    } # end sub Games::Cards::Stack::top_card

    # Use "reverse" to print the top card of the Set first
    # (makes for easier reading when lists are long, since you usually
    # care more about the next card to be played)
    sub print_ordered_cards {
    # returns the cards in the set in the correct order to be printed
        return [reverse (@{shift->{"cards"}})];
    } # end sub Games::Cards::Queue::print_ordered_cards

} #end package Games::Cards::Stack

#####################

=head2 Class Games::Cards::Pile

A Pile is a pile of cards. That is, it is a CardSet where we will only access
the beginning or end of the set. (This may include the first N cards in the
set, but we will never reference the 17'th card.) This is a super class of
Queue and Stack, and those classes should be used instead, so that we know
whether the cards in the pile are FIFO or LIFO. Methods:

=over 4

=cut

{
package Games::Cards::Pile;
# The cards array is LIFO for the Stack subclass and FIFO for the Queue
# subclass. We always push things onto Queues or Stacks, but
# we use "pop", for Stacks, and "shift" for the Queues.

    @Games::Cards::Pile::ISA = qw(Games::Cards::CardSet);
    # inherit SUPER::new

=item give_cards(RECEIVER, NUMBER)

Transfers NUMBER cards from the donor (the object on which this method was
called) to the CardSet RECEIVER.  This method can used for dealing cards from
a deck, giving cards to another player (Go Fish), putting cards on the table
(War), or transferring a card or cards between piles in solitaire.

If NUMBER is "all", then the donor gives all of its cards.

Returns 1 usually. If the donor has too few cards, it returns 0 and does not
transfer any cards.

=cut

    sub give_cards {
    #TODO if called with a subref instead of a scalar, then sort the
    #cards to the top of the Set using the sub, and then set $number!

    # If we're going from a Stack to a Queue, we  would normally need to flip
    # the stack of cards over. E.g. if you deal three cards from the stock to
    # the waste pile in Solitaire, the top card of the stock becomes the
    # *bottom* card of the waste. However, the cards arrays in Stacks and
    # Queues are stored in opposite directions, so this works automatically!
    #    If we're giving to a Hand, which doesn't have a top card, it doesn't
    # matter

	my ($donor, $receiver) = (shift, shift);
	my $number = shift;
	$number = $donor->size if $number eq "all";

	# Remove the cards if we can
	if ($donor->size < $number) {
	    #print $donor->{"name"} . " is out of cards\n";
	    return 0;
	}
	my $cards_ref = $donor->remove_cards($number);
	#print $donor->{"name"}, " gives ";
	#print map {$_->print("short")} @$cards_ref;
	#print " to ", $receiver->{"name"}, "\n";

	# Add the cards
	$receiver->add_cards($cards_ref);

        return 1;
    } # end sub Games::Cards::Pile::give_cards


=item top_card

Returns the top Card in the CardSet (or 0 if CardSet is empty)

=cut

    # This sub is actually found in the subclasses, since their
    # arrays are stored in different orders
} #end package Games::Cards::Pile

#####################

=head2 Class Games::Cards::Hand

A Hand represents a player's hand. Most significantly, it's a CardSet which
is different from a Pile because the Cards in it are unordered. We may
reference any part of the CardSet, not just the top or bottom.
Methods:

=over 4

=cut

{
package Games::Cards::Hand;

    @Games::Cards::Hand::ISA = qw(Games::Cards::CardSet);
# Use SUPER::new

=item give_a_card(RECEIVER, DESCRIPTION)

Transfers Card described by DESCRIPTION from the donor (the Hand on which
this method was called) to the CardSet RECEIVER.  This method can used for
discarding a card from a hand, e.g. 

If DESCRIPTION matches /^-?\d+$/, then it is the index in the cards array of the
Card to give.  Otherwise, DESCRIPTION is passed to Hand::index. 

Returns 1 usually. If the donor does not have the card, it returns 0 and does
not transfer anything.

=cut

    sub give_a_card {
	my ($donor, $receiver) = (shift, shift);
	my $description = shift;

	# Which card to remove?
	my $donor_index = $description =~ /^-?\d+$/ ?
	                  $description :
			  $donor->index($description);

	unless (defined $donor_index && $donor_index < $donor->size) {
	    #print $donor->name . " does not have that card\n";
	    return;
	}

	# Remove the card
	my $card_ref = $donor->remove_a_card($donor_index);
	#print $donor->name, " gives ";
	#print map {$_->print("short") . " "} @$cards_ref;
	#print " to ", $receiver->name, "\n";

	# Add the card
	$receiver->add_cards([$card_ref]); # add_cards takes an array ref

        return 1;
    } # end sub Games::Cards::Hand::give_card

=item move_card(DESCRIPTION, INDEX)

Rearrange a Hand by putting Card described by DESCRIPTION at index INDEX.

If DESCRIPTION matches /^-?\d+$/, then it is the index in the cards array of the
Card to give.  Otherwise, DESCRIPTION is passed to Hand::index. 

Returns 1 usually. If the donor does not have the card, it returns 0 and does
not transfer anything.

=cut

    sub move_card {
        my $hand = shift;
	my ($description, $final) = @_;

	# Which card to remove?
	my $initial = $description =~ /^-?\d+$/ ?
		      $description :
		      $hand->index($description);

	# don't have that card!
	return unless defined $initial;

	# Remove the card
	my $card_ref = $hand->remove_a_card($initial);

	# Add the card
	$hand->add_a_card($card_ref, $final);

        return 1;
    } # end sub Games::Cards::Hand::move_card

    sub remove_a_card {
    # remove (and return a ref to an array with) card number arg1 of the Hand
	my ($thing, $number) = @_;
	# splice returns an array ref
	my $listref = $thing->splice ($number,1);
	return $listref->[0];
    } # end sub Games::Cards::Stack::remove_cards

    sub add_a_card {
    # add card arg1 at position arg2 number arg1 of the Hand arg0
	my ($thing, $card, $number) = @_;
	$thing->splice ($number,0,[$card]);
    } # end sub Games::Cards::Stack::remove_cards

    sub add_cards {
    # Add array of Cards arg1 to the Hand
    #    This sub is called by Pile::give_cards & doesn't care where in the
    # Hand the cards end up. So just put 'em at the end
	my ($thing, $cards) = @_;
	$thing->splice($thing->size, 0, $cards);
    } # end sub Games::Cards::Hand::add_cards

=item index(DESCRIPTION)

Given a card description DESCRIPTION return the index of that Card
in the Hand, or undef if it was not found. DESCRIPTION may be a Card or
a string (like "8H" or "KC").

=cut 

    sub index {
	# Depending on the nature of the description arg1, we create a sub
	# to match that description with a Card. Then we search among the
	# cards in Hand arg0's cards array with that sub
	my ($set, $description) = @_;
	my $number;
	my $find; # sub whose arg0 is a card to compare to 

	if (ref $description eq "Games::Cards::Card") {
	    $find = sub {shift == $description};

	# but it matches 2-10 or AKQJ of CHDS
	# TODO need to change this for multiple decks!
	} elsif ($description =~ /^[\dakqj]+[chds]/i) {
	    $find = sub {shift->truename eq uc($description)};
	} else {
	    my $caller = (caller(0))[3];
	    die "$caller called with unknown description $description\n";
	}

	foreach my $i (0..$#{$set->{"cards"}}){
	    my $card = $set->{"cards"}->[$i];
	    $number = $i if &$find($card);
	}

	return $number; # will return undef if card wasn't found
    }

    sub print_ordered_cards {
    # returns the cards in the set in the correct order to be printed
        return shift->{"cards"};
    } # end sub Games::Cards::Hand::print_ordered_cards

} #end package Games::Cards::Hand

##################

=head2 Class Games::Cards::CardSet

A CardSet is just an array of cards (stored in the "cards" field). It could be
a player's hand, a deck, or a discard pile, for instance. This is a super class
of a number of other classes, and those subclasses should be used instead.

=over 4

=cut

#####################

{
package Games::Cards::CardSet;
# Fields:
# cards - array of Cards 
# name - "Joe's Hand" for Joe's hand, "discard" for a
# discard pile, etc.

=item new(GAME, NAME, NICKNAME)

create a new (empty) CardSet. GAME is the Game object that this set belongs
to. NAME is a unique string that e.g. can be output when you print the CardSet.
Optionally, NICKNAME is a (unique!) short name that will be used to reference
the set.

=cut

    sub new {
        my $self = shift;
	# so we can say $foo->new or new Bar
        my $class = ref($self) || $self;
	my $game = shift;
	# TODO use carp!
	my $name = shift || die "new $class must be called with a 'name' arg";
	my $nickname = shift; # may be undef
	my $set = {
	    "cards" => [],
	    "name" => $name,
	    "nickname" => $nickname,
	};
	bless $set, $class;

	# If this set is named "a" in this Game, then store
	# "a"=>$set in the Game object. Same for nickname
	$game->store_cardset($set);

	return $set;
    } # end sub Games::Cards::CardSet::new

    # Splice cards into/out of a set
    # Just like Perl's splice (with different argument types!)
    # RESULT = splice(ARRAY, OFFSET, LENGTH, LIST);
    # ARRAY is a CardSet, 
    # OFFSET is the index in the "cards" array
    # LENGTH is the number of cards spliced out,
    # LIST is a reference to an array of Cards to splice in
    # RESULT is (empty or) a ref to an array of Cards that were spliced out
    # (LENGTH and LIST are optional)
    #
    # This sub is private. People should use add_cards et al., which call
    # this sub
    sub splice {
	my ($set, $offset, $length, $in_cards) = @_;
	# set in_cards to empty list if undef. Otherwise, we'd splice in (undef)
	$in_cards = [] unless defined $in_cards;

	# Negative offsets will break if we try to undo them
	$offset += $set->size if $offset < 0;

	# If we didn't get length, splice to end of array
	$length = $set->size - $offset unless defined $length;
	# print $set->name, ": ",$set->size,
	#    " cards - $length starting at $offset",
	#    " + ", scalar(@$in_cards)," = ";

	# Can't splice in past position #$cards+1==foo->size
	# Can't splice out more cards than we have
	warn "illegal splice!\n" if $offset > $set->size || 
				    $length + $offset > $set->size;

	# Do the splice
	my $out_cards = [splice (@{$set->{"cards"}}, $offset,
	                         $length, @$in_cards)];

	# Store the splice & its result for Undo
	my $atom = new Games::Cards::Undo::Splice {
			"set" => $set,
			"offset" => $offset,
			"length" => $length,
			"in_cards" => $in_cards,
			"out_cards" => $out_cards,
			};
	$atom->store; # store the atom in the Undo List

	# in_cards now belong to this set
	# out_cards will be handled by another splice, presumably
	foreach (@$in_cards) { $_->set_owning_cardset($set) }

	# print $set->size,"\n";
	return $out_cards;
    } # end sub Games::Cards::CardSet::splice

=item shuffle

shuffles the cards in the CardSet. Shuffling is not undoable.

=cut

    sub shuffle {
    # shuffle the deck (or subset thereof)
        my $deck = shift;

	# "Random Schwartz"
	# Replace the cards in the deck with shuffled cards
	# (Just pick N random numbers & sort them)
	@{$deck->{"cards"}} =
	    map { $_->[0] } 
	    sort { $a->[1] <=> $b->[1] } 
	    map { [$_, rand] } 
	    @{$deck->{"cards"}};

        return;
    } # end sub CardSet::Shuffle

=item sort_by_value

Sorts the Set by value. This and other sort routines will probably be used
mostly on Hands, which are "ordered sets", but you might want to reorder a deck
or something. Sorting is not undoable.

=item sort_by_suit

Sorts the Set by suit, but not by value within the suit.

=item sort_by_suit_and_value

Sorts the Set by suit, then by value within the suit.

=cut

    sub sort_by_value {
        my $set = shift;
	@{$set->{"cards"}} = sort {$a->value <=> $b->value} @{$set->{"cards"}}
    } # end sub Games::Cards::CardSet::sort_by_value

    sub sort_by_suit {
        my $set = shift;
	@{$set->{"cards"}} =  sort {$a->suit_value <=> $b->suit_value} 
			           @{$set->{"cards"}}
    } # end sub Games::Cards::CardSet::sort_by_suit

    sub sort_by_suit_and_value {
        my $set = shift;
	@{$set->{"cards"}} = sort {$a->suit_value <=> $b->suit_value ||
	                           $a->value <=> $b->value} 
				@{$set->{"cards"}}
    } # end sub Games::Cards::CardSet::sort_by_suit_and_value

=item clone(GAME, NAME, NICKNAME)

Create a copy of this CardSet. That is, create an object with the same class
as arg0. Then make a copy of each Card in the CardSet (true copy, not a
reference). arg1 is the Game that the set belongs to. arg2 is the name to give
the new CardSet. arg3 (optional) is the nickname.

=cut

    sub clone {
	my $this = shift;
	my $clone = $this->new(@_);
	my $game = shift; # shift *after* using @_!

	$clone->{"cards"} = [map {$_->clone($game)} @{$this->cards}];
	foreach (@{$clone->cards}) {$_->set_owning_cardset($clone)};

	return $clone;
    } # end sub Games::Cards::CardSet::clone

=item face_down

Makes a whole CardSet face down

=cut

    sub face_down {
        foreach (@{shift->{"cards"}}) {$_->face_down}
    } # end sub Games::Cards::CardSet::face_down

=item face_up

Makes a whole CardSet face up

=cut

    sub face_up {
        foreach (@{shift->{"cards"}}) {$_->face_up}
    } # end sub Games::Cards::CardSet::face_up

=item print(LENGTH)

Returns a string containing a printout of the Cards in the CardSet. Prints
a long printout if LENGTH is "long", short if "short" (or nothing).
The CardSet is printed out in reverse order, so that the top card of the set is
printed first.

=cut

    sub print {
	my $set = shift;
	my $length = shift;
	my $long = $length && $length eq "long";
	my $max_per_line = 10;
	my $i = 0;
	my $to_print = "";
	#print $set->{"name"}." has " . $set->size . " cards\n";

	$to_print .= $set->{"name"} . ":" . ($long ? "\n" : " ");

	# Print. Different types of Sets are printed in different order
        foreach my $card (@{$set->print_ordered_cards}) {
	    $to_print .= $card->print($length);
	    if ($long) {
		$to_print .= "\n";
	    } else { # short printout
		if (++$i % $max_per_line) {
		    $to_print .= " ";
		} else {
		    $to_print .= "\n";
		    $to_print .= " " x (length($set->{"name"}) + 1);
		}
	    } # end if (short or long printout?)
	}
	# Or, if there are no cards...
	$to_print .= "(none)" unless $set->size;

	# Always print \n at end, but don't print 2
	chomp($to_print);
	$to_print .= "\n";

	return $to_print;
    } # end sub CardSet::Print

=item name

Returns the name of the Set

=cut

    sub name {return shift->{"name"}}

=item nickname

Returns the nickname of the Set (or undef if there is none)

=cut

    sub nickname {return shift->{"nickname"}}

=item cards

Returns a reference to the array of Cards in the set

=cut

    sub cards { return shift->{"cards"}; }

=item size

Tells how many cards are in the set

=cut

    sub size { return scalar(@{shift->{"cards"}}); }

=back

=cut

} # end package Games::Cards::CardSet

######################################################################

=head2 Class Games::Cards::Card

A Card is a playing card. Methods:

=over 4

=cut

{
package Games::Cards::Card;
# One playing card
# name is the name of the card (2-9, ace, king, queen, jack)
# value is the value of the card: e.g. ace may be 14 or 1. king may be 13 or 10.
# suit is the suit
# suit_value is the value of the suit: e.g. in bridge spades is 4, clubs 1
#  (although that may change after bidding!)
# face_up tells whether the player can see the card
# owner is the name of the CardSet that this Card belongs to. A Card can
#    only belong to one CardSet! (We store the name because storing a pointer
#    might screw up garbage collection.)

=item new(GAME, HASHREF)

creates a new card. GAME is the Game this card is being created in. HASHREF
references a hash with keys "suit" and "name".

=cut

    sub new {
        my $a = shift;
	my $class = ref($a) || $a;
	my $game = shift;
	my $hashref = shift;
	my $card = {
	    "name" => $hashref->{"name"},
	    "suit" => $hashref->{"suit"},
	    "value" => $hashref->{"value"},
	    "suit_value" => $hashref->{"suit_value"},
	    "face_up" => 1, # by default, you can see a card
	    "owner" => undef,
	};

	# turn it into a playing card
	bless $card, $class;

	# store a pointer to the card in the Game object
	$game->store_card($card);

	return $card;
    } # end sub Games::Cards::Card::new

=item clone(GAME)

makes a copy of the Card (not just a reference to it).

=cut

    sub clone {
        my $old_card = shift;
	my $game = shift;
	my $class = ref($old_card);
	my $suit = $old_card->suit("long");
	my $name = $old_card->name("long");
	my $value = $old_card->value;
	my $suit_value = $old_card->suit_value;
	my $new_card = $old_card->new ($game, {
	    "suit"=>$suit, "name"=> $name,
	    "suit_value" => $suit_value, "value" => $value
	    });

	$old_card->is_face_up ? $new_card->face_up : $new_card->face_down;
	# Don't set owner, because it may be different
	
	return $new_card;
    } # end sub Games::Cards::Card::clone

=item print(LENGTH)

returns a string with the whole card name ("King of Hearts") if LENGTH is
"long", otherwise a short version ("KH").

=cut

    sub print {
	my $card = shift;
	my $length = shift;
	my $long = $length && $length eq "long";
	my ($name, $suit) = ($card->name($length), $card->suit($length));
	my $face_up = $card->{"face_up"};

	$long ? (
	    $face_up ?
		$name . " of " . $suit :
		"(Face down card)"
	    ) : ( # long
	    $face_up ?
		sprintf("%3s ", $name .  $suit) :
		"*** " 
	    )
	;

    } # end sub Card::print

=item truename

Gives a unique description of this card, i.e., you're guaranteed that no
other card in the Game will have the same description.

=cut

    sub truename {
	my $self = shift;
	return join("", $self->name, $self->suit); 
    } # end sub Games::Cards::Card::truename
    
=item name(LENGTH)

prints the name of the card. The full name ("King") if LENGTH is "long";
otherwise a short version ("K");

=cut

    sub name {
        my $name = shift->{"name"};
	my $length = shift;
	my $long = $length && $length eq "long";
	
	if ($name =~ /^\d+$/) {
	   return $name;
	} else {
	   return $long ? $name : uc(substr($name, 0, 1));
	}
    } # end sub Games::Cards::Card::name

=item suit(LENGTH)

Returns the suit of the card. Returns the long version ("Diamonds") if LENGTH
is "long", else a short version ("D").

=cut

    sub suit { 
	my $suit = shift->{"suit"};
	my $length = shift;
	my $long = $length && $length eq "long";
        return $long ? $suit : uc(substr($suit,0,1));
    } # end sub Games::Cards::Card::suit

=item color

Is the card "red" or "black"? Returns the color or undef for unknown color.

=cut

    sub color {
        my $suit = shift->suit("long");
	my %color_map = (
	    "Diamonds" => "red",
	    "Hearts" => "red",
	    "Spades" => "black",
	    "Clubs" => "black",
	);

	if (exists ($color_map{$suit})) {
	    return $color_map{$suit};
	} else {
	    warn "unknown suit '$suit'"; 
	    return;
	}
    } # end sub Games::Cards::Card::color

=item value

Calculates the value of a card

=cut

    sub value { return shift->{"value"}}

=item suit_value

Returns the suit_value of a card (1..number of suits)

=cut

    sub suit_value { return shift->{"suit_value"}}

=item is_face_up

Returns true if a card is face up

=cut

    sub is_face_up { return shift->{"face_up"} }

=item is_face_down

Returns true if a card is face down

=cut

    sub is_face_down { return !shift->{"face_up"} }

=item face_up

Makes a card face up

=cut

    sub face_up {
        my $card = shift;
	unless ($card->{"face_up"}) {
	    $card->{"face_up"} = 1;
	    my $atom = new Games::Cards::Undo::Face {
			    "card" => $card,
			    "direction" => "up",
			    };
	    $atom->store; # store the atom in the Undo List
	}
    } # end sub Games::Cards::Card::face_up

=item face_down

Makes a card face down

=cut

    sub face_down {
        my $card = shift;
	if ($card->{"face_up"}) {
	    $card->{"face_up"} = 0;
	    my $atom = new Games::Cards::Undo::Face {
			    "card" => $card,
			    "direction" => "down",
			    };
	    $atom->store; # store the atom in the Undo List
	}
    } # end sub Games::Cards::Card::face_down

=item owning_cardset

Returns the CardSet which this Card is a part of

=item set_owning_cardset(SET_OR_NAME)

Makes the Card a part of a CardSet. Arg0 is either an actual CardSet ref, or
the name of a CardSet.

=cut

    sub owning_cardset {
	my $self = shift;
	my $set_name = $self->{"owner"};
	my $game = &Games::Cards::Game::current_game;
	my $set = $game->get_cardset_by_name($set_name);
	# TODO use carp!
	warn $self->print("long"), " doesn't belong to any CardSets!\n"
	    unless defined $set;
	return $set;
    }
    sub set_owning_cardset { 
        my ($self, $cardset) = @_;
	$self->{"owner"} = 
	    $cardset->isa("Games::Cards::CardSet") ?  $cardset->name : $cardset;
    } # end sub Games::Cards::Card::set_owning_cardset

=back

=cut

} # end package Card


1; # end package Games::Cards

__END__

=pod

=head1 EXAMPLES

An implementation of Klondike (aka standard solitaire) demonstrates how to use
this module in a simple game. Other card game examples are included as well.
The Games::Cards README should list them all.

=head1 NOTES

=head2 How to write your own game

So you want to write a card game using Games::Cards (or even 
Games::Cards::Tk)? Great! That's what the module is for.
Here are some tips about how to write a game.

=over 4

=item Steal code

Laziness applies in Games::Cards just like in the rest of Perl. It will
be much easier if you start with an existing game.

=item Stack vs. Queue

Think carefully about whether the Piles in your game are Stacks (LIFO)
or Queues (FIFO). As a general rule, piles of cards that are usually face 
down will be Stacks; face up will be Queues. CardSets where you want to 
access specific cards (i.e., not just the first or last) will be Hands.

=item GUI games

I've tried to design Games::Cards::Tk and the games that use it so that
the Tk game is very similar to the text game. This allows the most code
reuse. GUI games may involve clicking, dragging, and a different way to
display the game; but the underlying game is still the same. Also note
that serious timewasters may prefer to use the keyboard to play GUI
games. See L<Games::Cards::Tk> for more details.

=back

=head2 Public and Private

This module contains a bunch of methods. The public methods are documented
here. That means any method I<not> documented here is probably private, which
means you shouldn't call it directly.

There are also a bunch of classes. Most private classes are not documented
here. A couple private classes are mentioned, since they have methods which
public classes inherit. In that case, the privateness is mentioned.

=head2 TODO

See the TODO file in the distribution

=head2 Not TODO

Computer AI and GUI display were left as exercises for the reader. Then
Michael Houghton wrote a Tk card game, so I guess the readers are doing their
exercises.

=head1 BUGS

You betcha. It's still alpha. 

test.pl doesn't work with MacPerl, because it uses backticks. However,
(as far as I know) the games released with Games::Cards do work.

=head1 AUTHORS

Amir Karger

Andy Bach wrote a Free Cell port, and gets points for the first submitted
game, plus some neat ideas like CardSet::clone.

Michael Houghton herveus@Radix.Net wrote the initial Tk Free Cell (two
days after Andy submitted his Free Cell!)  I changed almost all of the code
eventually, to fit in with Games::Cards::Tk, but he gave me the initial push
(and code to steal).

=head1 COPYRIGHT

Copyright (c) 1999-2000 Amir Karger

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

perl(1), Tk(1)

=cut
