#!/usr/bin/perl -w

# gin.pl - Play Gin
#
# Copyright 1999 Amir Karger (karger@post.harvard.edu)
#
# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# TODO check for win every turn!

use strict;
use Games::Cards;

srand();

######################################################################
# SETUP THE GAME
# Main variables
my $Gin; # the game object
my $Deck; # the deck we're using in the game
my $Discard; # the discard pile
my @Hands; # the players' hands
my $Cards_Per_Hand = 10;
my $Number_Of_Players = 2;

my $Error; # current error message
my $Usage =<<"ENDUSAGE";
  $0 - play gin

  - On each turn, each player picks a card, then discards.

  - A "meld" is 3 or 4 cards of the same rank, or a consecutive runs of 
    three or four cards of the same suit. You win when you have three melds
    (two melds of 3 and one of 4). You have to "say gin" to win.

  - Commands are made up of letters, card descriptions, or numbers (from 1 to
    $Cards_Per_Hand). Commands/card names are case insensitive

    Pick:
    s       	Take the top card from the stock (deck)
    d       	Take the top card from the discard pile

    Discard:
    8D      	Discard the eight of diamonds
    8D g[in] 	Discard eight of diamonds and say "I have gin!"
                (The program will complain if you don't actually have gin.)

    At any time:
    8D 2    	Put the 8 of diamonds at position 2 in your hand
    so[rt]  	Sort cards in your hand by value (not suit)
    q       	quits a game, either starting a new round or quitting entirely
    h       	prints this help message
ENDUSAGE

# This otherwise uselessline will unconfuse vim's syntax highlighting!

# Create the game.
# Use the default deck (standard suits, cards, & card values)
$Gin = new Games::Cards::Game;

# Create and shuffle the deck
print "Creating new deck.\n";

NEWGAME: # We go to here when starting a new game
$Deck = new Games::Cards::Deck ($Gin, "Deck");
print "Shuffling the deck.\n";
$Deck->shuffle;

# Deal out the Hands
@Hands = ();
foreach my $i (1 .. $Number_Of_Players) {
    my $hand = new Games::Cards::Hand ($Gin, "Player $i") ;
    $Deck->give_cards($hand, $Cards_Per_Hand);
    $hand->sort_by_value;
    push @Hands, $hand;
}

# Put one face-up card in the discard pile
$Discard = new Games::Cards::Stack ($Gin, "Discard pile");
$Deck->give_cards($Discard, 1);
$Discard->top_card->face_up;

# No undo in gin
# my $Undo = new Games::Cards::Undo();

######################################################################
# Now play

my $turns = 1; # 1 gets subtracted later cuz Error is set
$Error = "Welcome! Type h for help, q to quit";
TURN_LOOP: while (++$turns) {
PLAYER_LOOP: foreach my $hand (@Hands) {
# A turn includes picking a card and discarding a card
HALF_LOOP: foreach my $half ("pick", "discard") {

    &print_game($hand);

    # If we got an error on the last turn, print the game status *first*, then
    # print the error right before the prompt (so that the reader will see it)
    if ($Error) {
	print "$Error\n\n";
	$Error = "";
    }

    # Ask player what to do
    print $hand->name, ", $half: ";
    my $input = <STDIN>; chomp($input);

    # Big case statement
    for ($input) {
	s/\s*//g;

	# Pick from deck (stock)
        if (/^s$/i) {
	    if ($half eq "pick") {
		$Deck->give_cards($hand, 1);
	    } else {
	        $Error="Picking is only allowed in the first half of the turn";
	    }

	# Pick from the discard pile
        } elsif (/^d$/i) {
	    if ($half eq "pick") {
		$Discard->give_cards($hand, 1);
	    } else {
	        $Error="Picking is only allowed in the first half of the turn";
	    }

	# Discard
        } elsif (/^(([jqka]|\d{1,2})[cdhs])(g(in)?)?$/i) {
	    if ($half eq "discard") {
		my ($card, $gin) = ($1, $3);
		$hand->give_a_card($Discard, $card) or
		    $Error = "ERROR! You don't have that card!";
		# did I win?
		if ($gin && !$Error) {
		    &check_win($hand) or $Error = "You didn't win yet!\n";
		    next HALF_LOOP; # don't redo turn even if we didn't win!
		}
	    } else {
	        $Error="Discarding is only allowed in the 2nd half of the turn";
	    }

	# Arrange cards in my hand
        } elsif (/^(([jqka]|\d{1,2})[cdhs])\s*(\d+)$/i) {
	    my ($card, $index) = ($1, $3 - 1);
	    if (defined $hand->index($card)) {
		$hand->move_card($card, $index) or
		    $Error = "ERROR! Illegal hand rearrangement!";
	    } else {
	        $Error = "ERROR! You don't have that card!"
	    }
	    redo HALF_LOOP;

	# I got gin!
        } elsif (/^so/i) {
	    $hand->sort_by_value;
	    redo HALF_LOOP;

	# help
	} elsif (/^h/i) {
	    print $Usage;
	    print "\nType RETURN to continue\n";
	    <STDIN>;
	    redo HALF_LOOP;

	# quit game
	} elsif (/^q/i) {
	    print "Are you sure you want to quit? (y/n): ";
	    my $a = <STDIN>;
	    if ($a =~ /^y/i) {
		print "Would you like to play another game? (y/n): ";
		$a = <STDIN>;
		if ($a =~ /^n/i) {
		    print "Bye!\n";
		    last TURN_LOOP;
		} else {
		    goto NEWGAME;
		}
	    }
	    # don't quit after all
	    redo HALF_LOOP;

	} else {
	    $Error = "ERROR! unknown command. Try again (h for help)"
	} # end case if

    } # end pick case statement

    redo if $Error; # redo this half of the turn

} # end loop over two halves of a turn

    # Reset deck if it's empty
    unless ($Deck->size) {
        print "Deck is empty!\n";
	my $temp = new Games::Cards::Stack "";
	$Discard->give_cards($temp, 1);
	$Discard->give_cards($Deck, "all");
	$temp->give_cards($Discard, 1);
    }

} # end loop over players
} #end while (loop over turns)

exit;

######################################################################

sub print_game {
# print out the current status
    my $hand = shift;
    print "\n\n\n", "-" x 50,"\n";
    print "Stock has ", $Deck->size, " cards\n";
    print $Discard->print("short"),"\n";
    print $hand->print("short");
    print "\n\n";
} # end sub print_game

sub check_win {
# arg0 is the hand of the player who (theoretically) won
    my $hand = shift;
    $hand->sort_by_value; # this makes searching for melds *much* easier

    # Test for melds...
    my $cards_ref = $hand->cards;
    
    # Sub next_meld if there is there a meld of size arg0 in array of Cards 
    # arg1 at meld level arg2, it sets that meld (in @melds) and returns 1
    # Otherwise, it returns 0.
    #    Meld levels are (1..3) since gin require 3 melds to win. First we call
    # with level 1 and find a possible meld. We mark those cards with a "1"
    # (in @melds) so when we try to find the next meld (level 2) we don't use
    # the cards already in meld #1
    #
    # Static variables:
    # @possible - array containing an (refs to) arrays of possible melds for 
    #         each meld level
    # @melds - array containing---for each card---the meld level of that card
    #         (or -1) I.e., this stores the current attempt at winning
    #
    # Note! sub next_meld goes *inside* sub check_win so that we can create
    # static variables for meld().  (Use an anonymous sub ref instead of just
    # 'sub next_meld {...}' to avoid a "Variable will not stay shared" warning.
    # This also allows using the static vars in the outer subroutine.)
    my @possible = ([], [], []); # STATIC VARIABLE FOR SUB NEXT_MELD
    my @melds = (-1) x 10; # STATIC VARIABLE FOR SUB NEXT_MELD

    my $next_meld = sub {
	# Note that the cards are sorted by value, so e.g., 4 of a kind will be
	# contiguous
	my $size = shift; # size of meld we want
	my $cards_ref = shift; # the cards
	my $level = shift; # highest meld level we've done so far
	# possible melds at this level---a meld is (ref to) an array 
	# containing card numbers of Cards that make up the meld.
	my @poss = @{$possible[$level]};

	# Calculate @poss, if we haven't already
	# First time you try to meld at a given level, (or the first time
	# since you tried melding at a lower level) unmelded cards will
	# have meld level < $level or -1. In that case we need to create the
	# array containing possible melds at this level, which gets stored
	# in $poss[$level].  
	#   Other times, the cards from the last attempted meld at this level
	# will have meld level $level.

	unless (grep {$_ == $level} @melds) {
	    # Create arrays of various aspects of the not yet melded cards
	    # (for convenience)
	    my @available; # (indices of) cards we can use
	    foreach (0 .. $#melds) {
	        push @available, $_ if $melds[$_]==-1;
	    }
	    # print ("Level $level. Avail: ",
	    #        (map {$cards_ref->[$_]->print("short")} @available), "\n");
	    my @values = map {$cards_ref->[$_]->value} @available;
	    my @names = map {$cards_ref->[$_]->name} @available;
	    my @suits = map {$cards_ref->[$_]->suit} @available;

	    # The meld must contain the first card in the array which isn't
	    # already in some other meld (so that all cards are included in
	    # *some* meld)
	    my ($first, $first_value, $first_name, $first_suit) = 
	       (shift @available, shift @values, shift @names, shift @suits);

	    # 3/4 of a kind including $first
	    my $matches = grep {$_ == $first_value} @values;
	    if ($matches == $size-1) { # found exactly as many as we want
	        push @poss, [$first, @available[0..$size-2]]
	    } elsif ($matches == 3 && $size == 3) { # 4 of a kind, want 3
	        push @poss, [$first, @available[0, 1]],
	                    [$first, @available[0, 2]],
	                    [$first, @available[1, 2]];
	    }

	    # straight of length $size including $first
	    my @same_suit;
	    my $temp = 1; # next card's value (hopefully)
	    foreach (0 .. $#suits) {
	        push @same_suit, $available[$_] if 
		    $suits[$_] eq $first_suit &&
		    $values[$_] == $first_value + $temp++;
		if (@same_suit == $size - 1) { # found a straight!
		    push @poss, [$first, @same_suit];
		    last;
		}
	    }
	} # end creation of @poss array
	#foreach (@poss) {print "Poss: @$_\n";}

	# set previous meld back to zero
	foreach (@melds) {$_ = -1 if $_ == $level}

	# If we have any more possible melds, set the next one, return 1
	# else return 0
	my $ret = 0;
	if (defined (my $try = pop @poss)) {
	    foreach (@$try) {
	        $melds[$_] = $level;
	    }
	    # Print the meld we're trying
	    #print ((map {$cards_ref->[$_]->print("short")} @$try), "\n");
	    $ret = 1;
	}

	# Store melds. Particularly important if we have multiple melds at
	# level 1 (e.g.) and need to try various melds at level 2 with each
	# level 1 meld
	$possible[$level] = \@poss;
	return $ret;
    }; # end sub(ref) next_meld

    my $won;
    # try 4, 3, 3
    TRY4: while (&$next_meld(4, $cards_ref, 0)) {
	while (&$next_meld(3, $cards_ref, 1)) {
	    $won = &$next_meld(3, $cards_ref, 2);
	    last TRY4 if $won
	}
    }

    unless ($won) { # didn't manage to win 4,3,3; try 3,4,3
	TRY3: while (&$next_meld(3, $cards_ref, 0)) {
	    while (&$next_meld(4, $cards_ref, 1)) {
		$won = &$next_meld(3, $cards_ref, 2);
		last TRY3 if $won;
	    }

	    # Didn't manage 3,4,3; try 3,3,4
	    while (&$next_meld(3, $cards_ref, 1)) {
		$won = &$next_meld(4, $cards_ref, 2);
		last TRY3 if $won;
	    }
	}
    }

    return unless $won;

    # You won!
    print $hand->name, " won!\n";
    print "\n\nWould you like to play another game? (y/n): ";
    my $a;
    $a = <STDIN>;
    goto NEWGAME if ($a =~ /^y/i);
    exit;

} # end sub check_win

