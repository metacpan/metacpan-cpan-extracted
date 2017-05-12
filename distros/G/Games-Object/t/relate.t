# -*- perl -*-

# Object relationships

# For this test, we'll attempt to simulate the way a game might be created.
# First, the programmer would create a subclass of the manager object to
# act as the world. Thus you could define methods at the world level that
# would interact with the user. The constructor would define whatever
# relationships would be needed in the manager.
#
# This test pulls out all the stops. Nearly EVERYTHING is tested here, 
# including more accessor method testing and overload operators.

package World;

use strict;
use warnings;
use Games::Object::Manager qw(REL_NO_CIRCLE);
use Exporter;
use vars qw(@ISA @EXPORT);

@ISA = qw(Games::Object::Manager Exporter);

sub new
{
	my $class = shift;

	my $world = $class->SUPER::new(@_);
	bless $world, $class;

	# The locate relationship is a generic location tracker. Every object
	# in the game has a location, which has no special tests or actions
	# associated with it. This relationship parallels others.
	$world->define_relation(
	    -name		=> "location",
	    -relate_method	=> "locate",
	    -related_method	=> "location",
	    -is_related_method	=> "is_located_at",
	    -related_list_method => "contents",
	    -unrelate_method	=> "dislocate",
	    -flags		=> REL_NO_CIRCLE,
	);

	# The carry relationship is specific to the player carrying an item.
	$world->define_relation(
	    -name		=> "hold",
	    -relate_method	=> "carry",
	    -related_method	=> "carried_by",
	    -is_related_method	=> "is_carrying",
	    -related_list_method => "carrying",
	    -unrelate_method	=> "drop",
	    -flags		=> REL_NO_CIRCLE,
	);

	# The contain relationship is used for objects that can hold other
	# objects.
	$world->define_relation(
	    -name		=> "containing",
	    -relate_method	=> "contain",
	    -related_method	=> "contained_in",
	    -is_related_method	=> "is_contained_in",
	    -related_list_method => "contains",
	    -unrelate_method	=> "take_from",
	    -flags		=> REL_NO_CIRCLE,
	);

	$world->{buffer} = [];
	$world;
}

sub output
{
	my $world = shift;
	my $msg = shift;

	push @{$world->{buffer}}, $msg;
	1;
}

sub clear
{
	my $world = shift;
	my @msgs = @{$world->{buffer}};
	$world->{buffer} = [];
	return @msgs;
}

# The next module represents the player or similar objects (a real game
# would likely have separate classes for the player and other creatures, or
# subclass one from the other. For the example we're keeping it simple).

package Player;

use strict;
use warnings;
use Games::Object;
use Exporter;
use vars qw(@ISA @EXPORT);

@ISA = qw(Games::Object Exporter);

sub new
{
	my $class = shift;
	my $carry_limit = shift;

	# Create the object
	my $obj = $class->SUPER::new(
	    @_,
	    -try_carry => [ 'O:self', 'can_carry', 'O:object', 'O:other' ],
	    # These callbacks use the full expression evaluation features
	    # of callback arguments. In this manner, we do not need to call
	    # any class-specific method to do what we want. We can do it all
	    # with existing object/manager methods and the right substitutions.
	    # This is designed to vastly cut down on programmer overhead.
	    #
	    # Note the call to take_from() on the manager. This is an example
	    # of how you can use these callbacks to break other relationships
	    # on the object when this new one is forged. In this specific
	    # example, when the player carries an object, it should no longer
	    # be contained in anything. Note how we do the opposite with
	    # locate(). In this case we establish a parallel relationship.
	    -on_carry => [
		[ 'O:self', 'mod_is_carrying', 'O:object->weight()' ],
		[ 'O:manager', 'take_from', 'O:object' ],
		[ 'O:manager', 'locate', 'O:self', 'O:object' ],
		[ 'O:manager', 'output', 'Taken.' ],
	    ],
	    -on_drop => [
		[ 'O:self', 'mod_is_carrying', '-1 * O:object->weight()' ],
		[ 'O:manager', 'locate', 'O:manager->location(O:self)', 'O:object' ],
		[ 'O:manager', 'output', 'Dropped.' ],
	    ],
	    # Watch this clever trick of displaying a neat message when
	    # character removed from game.
	    -on_remove => [ 'O:manager', 'output',
		'O:self->name() . " is enveloped by a sinister black cloud ' .
		'and is no more."' ],
	);
	bless $obj, $class;

	# Add attribute to track how much we're allowed to carry and what is
	# currently being carried.
	$obj->new_attr(
	    -name	=> "carry_limit",
	    -type	=> "int",
	    -value	=> $carry_limit,
	);
	$obj->new_attr(
	    -name	=> "is_carrying",
	    -type	=> "int",
	    -value	=> 0,
	);

	# Done.
	$obj;
}

# See if we can actually carry something. This shows not only an example
# of how you can check for the ability to perform a relationship, but it also
# shows the use of $other in determining who initiated the action.

sub can_carry
{
	my ($self, $object, $other) = @_;
	my $man = $self->manager();

	$man->output(
	    $self eq $other ?
		"You attempt to pick up " . $object->name() . " ..." :
		$other->name() . " generously offers you " . $object->name() .
		  " ..."
	);

	if ( ($object->weight() + $self->is_carrying()) > $self->carry_limit()){
	    $man->output(
		$self eq $other ?
		    "... but your load is too heavy for you to pick it up." :
		    "... but you must graciously refuse as your hands are full."
	    );
	    return 0;
	} else {
	    # Note how we issue a failure message from here but not a success
	    # message. Leaving the success message to the on_* action is good
	    # practice because it means if you add other callbacks later to
	    # the list, you're not stuck with success messages that make no
	    # sense.
	    return 1;
	}
}

# Return name (which just returns the object id)

sub name { shift->id() }

# This class is for defining a generic "thing".

package Thing;

use strict;
use warnings;
use Games::Object;
use Exporter;
use vars qw(@ISA @EXPORT);

@ISA = qw(Games::Object Exporter);

sub new
{
	my $class = shift;
	my $size = shift;
	my $weight = shift;

	# Create the object
	my $obj = $class->SUPER::new(@_);
	bless $obj, $class;

	# Add size and weight attributes.
	$obj->new_attr(
	    -name	=> "size",
	    -type	=> "int",
	    -value	=> $size,
	);
	$obj->new_attr(
	    -name	=> "weight",
	    -type	=> "int",
	    -value	=> $weight,
	);

	$obj;
}

# Return name.

sub name { "the " . shift->id() }

# This next class is for objects that are containers, in that they can contain
# other objects. This is used to test special side effects of relating objects.

package Container;

use strict;
use warnings;
use Games::Object;
use Exporter;
use vars qw(@ISA @EXPORT);

@ISA = qw(Thing Exporter);

sub new
{
	my $class = shift;
	my $can_hold = shift;

	# Create the object
	my $obj = $class->SUPER::new(
	    @_,
	    -try_contain => [ 'O:self', 'can_contain', 'O:object' ],
	    # Like with the other callbacks for the carry relationship, we
	    # do everything with existing methods.
	    -on_contain => [
		[ 'O:self', 'mod_is_holding', 'O:object->size()' ],
		[ 'O:manager', 'locate', 'O:self', 'O:object' ],
	    ],
	    -on_take_from => [
		[ 'O:self', 'mod_is_holding', '-1 * O:object->size()' ],
		[ 'O:manager', 'locate', 'O:manager->location(O:self)', 'O:object' ],
	    ],
	);
	bless $obj, $class;

	# Add attribute to track how much we're allowed to hold and what is
	# currently being held.
	$obj->new_attr(
	    -name	=> "can_hold",
	    -type	=> "int",
	    -value	=> $can_hold,
	);
	$obj->new_attr(
	    -name	=> "is_holding",
	    -type	=> "int",
	    -value	=> 0,
	);

	# Done.
	$obj;
}

# Check to see if this can contain the indicated object.

sub can_contain
{
	my ($self, $object) = @_;
	my $world = $self->manager();

	if ( ($object->size() + $self->is_holding()) > $self->can_hold()) {
	    $world->output("It won't fit.");
	    return 0;
	} else {
	    return 1;
	}
}

# Define a room class, which acts as a very simple class in this example,
# simply useful for locating things.

package Room;

use strict;
use warnings;
use Games::Object;
use Exporter;
use vars qw(@ISA @EXPORT);

@ISA = qw(Games::Object Exporter);

sub new
{
	my $class = shift;

	# Create the object
	my $room = $class->SUPER::new(@_);
	bless $room, $class;
	$room;
}

# Main program

package main;

use strict;
use warnings;
use Test;

BEGIN { $| = 1; plan tests => 41 }

use Games::Object qw($AccessorMethod $ActionMethod);
use Games::Object::Manager;

$AccessorMethod = 1;
$ActionMethod = 1;

# Create the world.
my $world = World->new();
ok( UNIVERSAL::isa($world, 'Games::Object::Manager') );

# Create a player.
my $player = Player->new(40, -id => "cretin");
ok( UNIVERSAL::isa($player, 'Games::Object') );
$world->add($player);
ok( $world->find("cretin") eq $player );

# Create a room for the player and put him in it.
my $dungeon = Room->new(-id => "dungeon");
ok( UNIVERSAL::isa($dungeon, 'Games::Object') );
$world->add($dungeon);
ok( $world->find("dungeon") eq $dungeon );
$world->locate($dungeon, $player);

# Check that the player really is in the dungeon.
my $obj1 = $world->location($player);
ok( ref($obj1) eq 'Room' && $obj1->id() eq 'dungeon' );

# Give player some items to carry.
my $lantern = Thing->new(5, 10, -id => "brass lantern");
my $sword = Thing->new(15, 10, -id => "elvish sword");
$world->add($lantern);
$world->add($sword);
eval('$world->carry($player, $lantern);');
ok( $@ eq '' );
print "# DEBUG: \$@ = $@" if ($@);
eval('$world->carry($player, $sword);');
ok( $@ eq '' );
print "# DEBUG: \$@ = $@" if ($@);

# Check that the items are really carried by polling relationships and
# by checking for attributes that should have updated.
my $obj3 = $world->carried_by($lantern);
my $obj4 = $world->carried_by($sword);
ok( ref($obj3) eq 'Player' && $obj3->name() eq 'cretin' );
ok( ref($obj4) eq 'Player' && $obj4->name() eq 'cretin' );
my $obj5 = $world->location($lantern);
my $obj6 = $world->location($sword);
ok( ref($obj5) eq 'Player' && $obj5->name() eq 'cretin' );
ok( ref($obj6) eq 'Player' && $obj6->name() eq 'cretin' );
ok( $player->is_carrying() == 20 );
my @out = $world->clear();
ok( @out == 4
 && $out[0] eq 'You attempt to pick up the brass lantern ...'
 && $out[1] eq 'Taken.'
 && $out[2] eq 'You attempt to pick up the elvish sword ...'
 && $out[3] eq 'Taken.' );

# Now check that the various things that have things related to them can spit
# back those things (to put on top of other things ...?)
my @objs1 = $world->contents($dungeon);
ok( @objs1 == 1
 && $objs1[0] eq $player );
my @objs2 = $world->carrying($player);
ok( @objs2 == 2
 && $objs2[0] eq $lantern
 && $objs2[1] eq $sword );

# Create a monster (we'll just use the Player class for this), carrying a
# sack (a Container object) which in turn has some items in it.
my $troll = Player->new(50, -id => "nasty troll");
my $sack = Container->new(35, 25, 0, -id => "large sack");
my $gold = Thing->new(10, 10, -id => "gold coins");
my $book = Thing->new(15, 15, -id => "spell book");
my $axe = Thing->new(10, 5, -id => "sharp axe");
$world->add($troll);
$world->add($sack);
$world->add($gold);
$world->add($book);
$world->add($axe);
$world->locate($dungeon, $troll);
$world->carry($troll, $sack);
$world->contain($sack, $gold);
$world->contain($sack, $book);
$world->carry($troll, $axe);

# Test a few of the relationships.
ok( $world->is_located_at($dungeon, $troll)
 && $world->is_contained_in($sack, $gold) );
ok( $world->is_carrying($troll, $sack)
 && $world->is_carrying($troll, $axe) );
ok( !$world->is_located_at($troll, $gold)
 && !$world->is_located_at($sack, $axe)
 && $world->is_located_at($troll, $sack) );
ok( $sack->is_holding() == 25 );

# Have the original player drop something and then check again.
$world->clear();
$world->drop($lantern);
@out = $world->clear();
ok( @out == 1
 && $out[0] eq 'Dropped.' );
ok( !defined($world->carried_by($lantern))
 && !$world->is_carrying($player, $lantern)
 && $world->location($lantern) eq $dungeon );
my @objs3 = $world->contents($dungeon);
ok( @objs3 == 3
 && $objs3[2] eq $lantern );
my @objs4 = $world->contents($player);
ok( @objs4 == 1
 && $objs4[0] eq $sword );
ok( $player->is_carrying() == 10 );

# Make the monster go poof and check what happened to the objects it was holding
$world->remove('nasty troll');
ok( !defined($world->find('nasty troll')) );
ok( $world->location($sack) eq $dungeon
 && $world->location($axe) eq $dungeon );
ok( !defined($world->carried_by($sack))
 && !defined($world->carried_by($axe)) );

# Give the sword back to the player and transfer a few other items to his
# possession.
$world->carry($player, $lantern);
$world->carry($player, $gold);
ok( $world->location($sword) eq $player
 && $world->location($gold) eq $player );
ok( $world->carried_by($sword) eq $player
 && $world->carried_by($gold) eq $player );
ok( !defined($world->contained_in($gold)) );
ok( $player->is_carrying() == 30
 && $sack->is_holding() == 15 );

# Now try to give the player something he cannot hold. This should not work,
# and the original relationships of the objects left intact.
$world->clear();
$world->carry($player, $book);
@out = $world->clear();
ok( @out == 2
 && $out[0] eq 'You attempt to pick up the spell book ...'
 && $out[1] eq "... but your load is too heavy for you to pick it up." );
ok( $world->contained_in($book) eq $sack
 && $world->location($book) eq $sack
 && !defined($world->carried_by($book)) );
ok( $player->is_carrying() == 30
 && $sack->is_holding() == 15 );

# The Final Test: Save the manager object to a file, undef all our holding
# variables, and recreate the world, then check that all relationships are
# intact.
my $savefile = "./world.save";
$world->save($savefile);
@objs1 = ();
@objs2 = ();
@objs3 = ();
@objs4 = ();
undef $dungeon;
undef $player;
undef $troll;
undef $lantern;
undef $sword;
undef $sack;
undef $gold;
undef $axe;
undef $world;
my $newworld = Games::Object::Manager->load($savefile);
ok( ref($newworld) eq 'World' );
ok( ($dungeon = $newworld->find('dungeon'))
 && ($player = $newworld->find('cretin'))
 && ($sword = $newworld->find('elvish sword'))
 && ($lantern = $newworld->find('brass lantern'))
 && ($axe = $newworld->find('sharp axe'))
 && ($sack = $newworld->find('large sack'))
 && ($gold = $newworld->find('gold coins'))
 && ($book = $newworld->find('spell book')) );
ok( ref($dungeon) eq 'Room'
 && ref($player) eq 'Player'
 && ref($sword) eq 'Thing'
 && ref($sack) eq 'Container' );
ok( $newworld->carried_by($sword) eq $player
 && $newworld->carried_by($lantern) eq $player
 && !defined($newworld->carried_by($sack))
 && $newworld->contained_in($book) eq $sack );

# Test that accessors were recreated.
ok( $player->is_carrying() == 30
 && $sack->is_holding() == 15 );
$newworld->drop($sword);
ok( !defined($newworld->carried_by($sword))
 && $newworld->location($sword) eq $dungeon
 && $newworld->location($sword) ne $player );

unlink($savefile);

