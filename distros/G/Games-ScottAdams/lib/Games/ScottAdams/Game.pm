# $Id: Game.pm,v 1.1 2006/10/31 20:31:21 mike Exp $

# Game.pm - class to represent an entire Scott Adams game.

package Games::ScottAdams::Game;
use strict;


# This whole-game class is dependent on subsidiary classes to
# represent the specific game concepts of Room, Item and Action.

use Games::ScottAdams::Parse;	# additional methods for this class
use Games::ScottAdams::Compile;	# additional methods for this class
use Games::ScottAdams::Room;
use Games::ScottAdams::Item;
use Games::ScottAdams::Action;


sub new {
    my $class = shift();
    my $this = bless {
	@_,
	rooms => [],		# array of Games::ScottAdams::Room
	roomname => {},			# ... and indexed by name
	items => [],		# array of Games::ScottAdams::Item
	itemname => {},			# ... and indexed by name
	actions => [],		# array of Games::ScottAdams::Action
	messages => [],		# array of message strings
	msgmap => {},			# ... and indexed by message
	vvocab => {},		# map of verbs to equivalence classes
	nvocab => {},		# map of nouns to equivalence classes
		# Vocabulary information is accumulated in {vvocab}
		# and {nvocab} during parsing.  At the end of the
		# parsing phase, they are rationalised into arrays
		# {nouns} and {verbs}, together with inverted indexes
		# in the hashes {nmap} and {vmap}.
	start => undef,		# name of room where player starts
	treasury => undef,	# name of room where treasure is stored
	maxload => undef,	# how many items player can carry at once
	lighttime => undef,	# how many turns the light source works for
	ident => undef,		# magic number identifying this adventure
	version => undef,	# version number of this adventure
	wordlen => undef,	# number of significant characters in words
	lightsource => undef,	# name of item which functions as light source
	ntreasures => 0,	# number of items starting with "*"
	_room => undef,		# reference to current room during parsing
	_item => undef,		# reference to current item during parsing
	_action => undef,	# reference to current action during parsing
	_roomname1 => undef,	# name of first room to be defined
    }, $class;

    # Room zero is always special - it's where items not in play
    # reside.  We stick a vacuous one at the front of the array.
    my $room = new Games::ScottAdams::Room('NOWHERE', '[nowhere]', 0);
    push @{ $this->{rooms} }, $room;

    # Message 0 is useless, since action 0 is NOP; so occupy its space.
    $this->resolve_message('[dummy]');

    return $this;
}


1;
