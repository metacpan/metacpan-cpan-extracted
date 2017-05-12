#!/usr/bin/perl -w

# war.pl - watch two computer players play war
#
# Copyright 1999 Amir Karger (karger@post.harvard.edu)
#
# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.

use strict;
use Games::Cards;

# Global variables for war
my $Cards_Per_Hand = 26;
# It would require just a bit of tinkering to make this game for 3 or more
# players. But why bother?
my $Number_Of_Players = 2;
my $Max_Turns = 500;
my $Long = 0; # set to 1 to print out more per turn
my $Interactive = 0; # wait for (useless) user input after every turn?

# card values
my $valueref = {
    "Ace" => 14,
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

srand(); # no seed nec. for perl > 5.004

######################################################################
# SETUP THE GAME
# Main variables
my $War; # the game
my $Deck; # the deck we're using in the game
my @Hands; # the players' hands
my @Table; # what the players put on the table

# initialize the game. Suits are default; card values aren't
print "Welcome to war!\n";
print "On each turn, hit RETURN to continue, CTRL-D to end\n\n" if $Interactive;
$War = new Games::Cards::Game {"cards_in_suit" => $valueref};

# Create and shuffle the deck
print "Creating new deck.\n";
$Deck = new Games::Cards::Deck ($War, "Deck");
print "Shuffling the deck.\n";
$Deck->shuffle;

# Deal out the hands
foreach my $i (1 .. $Number_Of_Players) {
    print "Dealing hand $i\n";
    my $hand = new Games::Cards::Queue ($War, "Player $i");
    $Deck->give_cards($hand, $Cards_Per_Hand);
    push @Hands, $hand;
}

# Create CardSets for the cards each player puts on the table
foreach my $i (1 .. $Number_Of_Players) {
    my $table_hand = new Games::Cards::Stack ($War, "Player $i showing"); 
    push @Table, $table_hand;
}

######################################################################
# Now play
my @other = (1,0); # the other player
my $turns = 0;

while (++$turns < $Max_Turns) {
#    print "Turn $turns:  ",
#        map ({" " . $_->name ." has " . $_->size . " cards."} @Hands), "\n";
    
    if ($Long) {
        foreach (@Hands) { print $_->print("short"); }
    } else {
	my $i = 1;
        foreach (@Hands) { print $i++ x $_->size, "   " }
	print "\n";
    }
    my $compare = 0;
    while (!$compare) {
	# Each player puts a card on the table
	foreach (0 .. $#Hands) {
	    $Hands[$_]->give_cards($Table[$_], 1) || &win($other[$_], $turns);
	}
	if ($Long) {foreach (@Table) { print $_->print("short"); }}
	$compare = compare_last($Table[0], $Table[1]);

	if (! $compare) {
	    # war
	    print "WAR!\n";
	    foreach (0 .. $#Hands) {
		$Hands[$_]->give_cards($Table[$_], 3) || 
		    &win($other[$_], $turns);
	    }
	}
    } # end while !compare

    # Who won? Compare > 0 means player 1 won
    # Winner gets the card (or cards if there was a war)
    my $winner = ($compare > 0 ? 1 : 0);
    my $loser = $other[$winner];
    print $Hands[$winner]->{"name"}, " wins.\n" if $Long;
    $Table[$winner]->give_cards($Hands[$winner], "all");
    $Table[$loser]->give_cards($Hands[$winner], "all");

    # Make the game "interactive"
    <STDIN> or do {print "Good. I'm bored too.\n"; exit;} if $Interactive;
} #end while (loop over turns)

print "Too many turns. I give up.\n";
exit;

######################################################################
sub compare_last {
# compare last card in two card sets
# return positive value if second set wins, 0 for equality
    my ($set1, $set2) = (shift, shift);
    my $card1 = $set1->top_card;
    my $card2 = $set2->top_card;

    return $card2->value - $card1->value;
}

sub win {
# player arg0 wins!
    my ($winner, $turns) = (shift, shift);
    print $Hands[$winner]->{"name"}, " wins after $turns turns!\n";
    exit;
}
