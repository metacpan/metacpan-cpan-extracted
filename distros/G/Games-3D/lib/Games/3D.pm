
# This is just the version number and the documentation

package Games::3D;

# (C) by Tels <http://bloodgate.com/>

use strict;
use 5.8.1;
use vars qw/$VERSION/;

$VERSION = '0.10';

1;

__END__

=pod

=head1 NAME

Games::3D - a package containing an object system for (not only) 3D games

=head1 SYNOPSIS

	use Games::3D::World;

	my $world = Games::3D::World->new();

	$world->save_to_file( $filename );
	
	my $loaded = Games::3D::world->load_from_file( $filename );

	my $thing1 = $world->add ( Games::3D::Thingy->new( ... ) );
	my $thing2 = $world->add ( Games::3D::Thingy->new( ... ) );

	$world->link($thing1, $thing2);
	
=head1 EXPORTS

Exports nothing.

=head1 INTRODUCTION

This package is just the basis documentation for all the classes contained
under Games::3D. It does not need to be used, unless you want to require a
specific version of this package.

=head1 DESCRIPTION

=head2 Overview

L<Games::3D::World> provides you with a container class that will contain
every object in your game object system. This are primarily objects that
have states, change these states and need to announce the states to other
objects.

The L<Games::3D::World> container also enables you to save and restore
snapshots of your objects system.

Basic things that you object system contains are derived from a class called
L<Games::3D::Thingy>. These can represent physical objects (buttons, levers,
doors, lights etc) as well as virtual objects (trigger, sensors, links,
markers, sound sources etc).

You can link C<Thingy>s together, either directly or via L<Games::3D::Links>.
The links have some more features than direct linking, which are explained
below.

This package also provides you with L<Games::3D::Sensor>, a class for objects
that I<sense> state changes and act upon them. Or not, depending on the
sensor. Sensors are primarily used to watch for certain conditions and
then act when they are met. Examples are the death of an object, values
that go below a certain threshold etc.

State changes are transported in the object system with B<signals>.

A detailed explanation of all these basic building blocks follows below.

=head2 World and Things

The L<Games::3D::World> is just a container to hold all the things. One
advantage of having a global container is that you can get a snapshot of
the world and save it to a file, and later restore it.

There are also certan performance advantages, for instance, if you want an
event to trigger if one object from a certain class of objects dies, you
can just ask the container to notify you. This is better than
linking every object of that class to each sensor to watch for this
particular state change.

The world contains C<Thingy>s, C<Link>s and C<Sensors>.
 
=head2 Templates

Templates are blueprints for objects. Each template describes a class of
objects, their valid settings as well as default values for these settings.

C<Thingy>s belong to a class, and Templates descirbe these classes.
The template list is hirarchival, meaning templates for subclasses inherit
all settings from their parent class. Here is an example for a template list:

	Virtual {
	  base = 'Games::3D::Thingy'
	  visible = off
	}

	Virtual::Link {
	  base = 'Games::3D::Link'
	}

	Virtual::Sensor {
	  base = 'Games::3D::Sensor'
	}

	Physical {
	  model = "default.md2"
	  visible = 1
	}

	Physical::Light {
	  r = FRACT=0
	  g = FRACT=0
	  b = FRACT=0
	  a = FRACT=0
	  state_0 = [ 75, a, 0 ]
	  state_1 = [ 250, a, 1 ]
	}

The first three templates describe virtual (invisible) objects with different
base classes. The last two are physical (visible) objects (their base class
is automatically C<Games::3D::Thingy>).

Note that C<Virtual::Link> inherits the C<visible = off> setting from
C<Virtual>!

There are a few settings that are common to all templates and don't need to
be defined - everything else can be defined at will, to describe complex game
environments. Here is an overview with their names and default values:

=over 2

=item visible = BOOL=off

Flag to tell whether the object is visible (needs rendering) or not.

=item active = BOOL=on

Flag to tell whether the object is active (receiving/relaying signals) or not.

=item base = STR="Games::3D::Thingy"

The underlying base object class.

=item id = INT=

The unqiue ID of the object. Will be automatically set. Read-only.

=item name = STR=

The name of the object. A 'Physical::Light' with ID=2 will have a default
name of 'Light #2'. The name is usefull for refering objects by name, instead
by the (possible changing) ID.

=item info = STR=

Short info text, that will be displayed in-game if someone looks at the
object.

=back

Since the Template defines an object with default settings, it is possible
to construct new objects in-game just by giving the template name.

=head2 Thingys

Each C<Thingy> has the ability to link itself to another object. If the
C<Thingy> receives a signal, it will pass it along to all other objects
that it is linked to (except for a few signals that the C<Thingy> will
act upon, but not pass along. See below).

From now on C<Thingy>s will be simple called C<object> because even
C<Link>s and C<Sensor>s are C<Thingy>s underneath.

=head2 States and State changes

Each object is in a certain state. Currently 16 different states exist,
although most objects will only have two states. Switching between states
is achived by sending the object a signal with the desired target state.

The signals SIG_ON and SIG_OFF switch to state 1 and state 0, respectively.
SIG_FLIP flips between these two states.

Each state has a state-change-time associated with itself. The object will
take so long to switch from the current state to the next state. There are
also variables that will change from value A to value B while the state
change takes place.

This means you can have a light come on (over a certain short period of time)
and off again.

When the target state is reached, the object will send of a (different than
the one it received to switch it's state) signal to all linked objects.

Thus it is possible to distinguish between start and end of the state change.
This is important if you want certain things to happen immidiately, or after
the state change is complete.

=head2 Signals

While you can create arbitrary signals and have your object act
upon, there are a few basic signals an object knows. Here is an overview:

Signals that are not relayed:

=over 2

=item SIG_DIE, SIG_KILL

This causes the object that receives the signal to be destroyed.
It will send out a SIG_KILLED to all linked objects to announce it's death.

=item SIG_ACTIVATE, SIG_DEACTIVATE

This causes the object that receives the signal to be (de)activated.
Once deactivated, an object will stop receiving and sending signals
until it get's SIG_ACTIVATE again.

Upon receiving such a signal, will send out a SIG_ACTIVATED 
respectively a SIG_DEACTIVATED to all linked objects.

=back

Signals that are relayed:

=over 2

=item SIG_ON, SIG_OFF

These signals will change two-state objects between the ON and OFF state, and
will be relayed to other objects I<as they are> and I<immidiately>.
 
=item SIG_NOW_ON, SIG_NOW_OFF

When an object receives ON or OFF, it will turn itself ON, or OFF,
respectively, and once it finished, it will send NOW_ON or NOW_OFF,
respectively.

=item SIG_FLIP

The same as ON or OFF, but instead flips the state between ON and OFF.

=item SIG_STATE_0, SIG_STATE_1, etc

This signal cause the object to go to the desired state (over a certain
time period).

=back

When you invert a C<SIG_ON>, it becomes C<SIG_OFF>, and vice versa.
C<SIG_FLIP> and C<SIG_DIE>, C<SIG_NOW_0> up to C<SIG_NOW_15> as well as
C<SIG_STATE_2> up to C<SIG_STATE_15> cannot be inverted. 

Various other signals:

=over 2

=item SIG_CHANGED

This signal is send out when a certain value changes. It is only send out to
objects that requested to be notified of state changes (e.g. typically
C<Sensor>s). It carries the type (what was changed) and the new value.

=item SIG_SET, SIG_ADD, SIG_MUL

This is used to signal an object that it should change a setting of itself.
SET is used to set the value directly, ADD brings in a (possible negative)
change (e.g. 5 +2 => 7), and MUL multiplies the old value with the new
one (5 * -3 => -15).

=back

=head2 Links

C<Link>s are special objects that link other objects together. While you could
just link two objects directly, links enhance this by adding some features:

=over 2

=item Delays

A link can delay any signal coming across by a fixed (or randomized) time.

=item Invert

Links can invert signals. Thus SIG_ON becomes SIG_OFF, and vice versa.

=item Repeat

They can also repeat signals, e.g each incomming signal is send out multiple
times with delays in between.

=item Fixed Output

By setting the output of the link to a specific signal, we can make the link
send out always the same signal, regardless of input signal.

=back

A further advantage of link objects is that you can send a SIG_DIE to the
link object itself, and thus destroying it. This breaks the link between the
two objects in a finite manner. You can also deactivate and later activate the
link again, without effecting the objects linked together itself.

=head2 Sensors

Sensors sense state changes and when they happen, send out a signal. Each
sensor attaches either to a specific object ("Player"), or to an entire
class ("->Food"). The sensor also announces what type of change it wants
to watch, for instance 'origin', 'health', 'position', 'age' etc. Whenever
this value changes, the sensor get's notified. 

=head2 Events

There are certain events than can occur to an object. These are specified
with a 'on_' prefix in the L<Templates> like:

	Physical::Switch {
	  on_frob = SIG_FLIP
	}
	Physical::Loot {
	  on_frob = CODE="$src->add($self)"
	}

The notation of a single signal is shorthand for
C<CODE="$self->signal($src,SIG_...)"> and means that on the event the object
will send itself the specified signal.

C<$src> is the object that caused the event. C<$self> is the object that
the event is happening to.

Here is a short overview of the possible events:

=over 2

=item frob

The player (or an NPC) I<frobbed> the object. To frob means to touch, to
use. For instance, the player walks to a switch and then uses it.

=item apply

Objects (Player, NPCs) can only C<apply> items that are in their inventory.

The object in question gets applied to the source object, e.g. the Player
would eat the food object, or drink a potion.

=item use

Objects (Player, NPCs) can only use items that are in their inventory.

C<on_use> is very similiar to C<on_apply>, except that the object is 
used on a different object in the world, not the one that posesses it.

For instance, the player might use a key on a door.

=item kill

This event 'occurs' just before the object gets killed.

=back

There might be more events, like C<heal> or C<hurt> but it is currently
whether these need to be distinct events, or can fall under the
C<decreased_value> and C<increased_value> events.

=head2 Code

Objects can have snippets of code that is executed upon an event. The code
does have some predefined variables, here is a short overview:

=over 2

=item $src

The object that initiated/triggered the event.

=item $self

The object on that the event is triggered.

=item $target

The object on that C<$self> should be used on (only for C<on_use> event).

=item $world

The world, contains the entire object system. One usefull method to call on
that object is for instance C<< $world->create('Some::Class::Here') >>.

=back

=head1 EXAMPLES

The aforementioned system is quite flexible, but there is also a certain
rendunancy, which means there are sometimes multiple was to accomplish
something. Here follow some real-game examples on how to represent often
occuring scenaries with the given system.

We assume that you have I<physical> objects which can be manipulated by
the player, and that have two states: ON and OFF (or OPEN, CLOSED, UP, DOWN
etc). This is often sufficient, and in the few cases were we need more than
two states, custom scripting can solve the problem.

In the following text you will see some ASCII art drawings representing
the game world as a network. Signals travel along the arrows (-->), and only
in one direction. The possible signals are mentioned on the path.

The placement in the following networks has nothing to do with the actual
object placement in the game world!

=head2 Door-Opener Button

Imagine a button that sends, when pressed, an ON signal.

		     ON
	[ OnButton ] ---------------> [ Door ]

Press the button, and the door will be opened. Pressing it again will do
nothing, since the door is already open.

(Of course, the door must prevent player interaction on itself, otherwise
the player would just walk to the door and open it :)
 
=head2 Self-disabling Door-Opener Button

The button in the first example has one slight problem: It can be pressed
again and again, even though without effect. If you want the button to be
disabled, we can route its signal to a link, and use this:


		   
	[ OnButton ] +--------------> [ Door ]
	    ^	     | ON
	    |	     |		  DEACTIVATE
	    |	     +-> [ Link ] --------------+
	    |					|
	    +-----------------------------------+

Pressing the button will open the door and de-activate the button. 

=head2 Two-state button

The OnButton in the former examples only send one signal: ON. What if we
have a button that sends ON when pressed and OFF when the player stops
pressing it? Linking it to a door would do no good, because the door
would open and immidiately close again. But you could use this to turn a 
light on while the button is pressed:
		     
		   ON, OFF
	[ Button ] ---------------> [ Light ]

You could also supress one signal:

		   ON, OFF		ON
	[ Button ] ----------> [ LINK ] ---------> [ Door ]

via a link that only sends an ON signal. 

TODO: Filters, that only allow (a) certain signal(s) to pass or filter
(a) certain signal(s).

=head2 Lever

The same network as before would work with a lever, that sends an ON and OFF
signal, provided the lever is in the OFF position after start. The first signal,
ON, send when the lever is flipped, would open the door and disable the lever. If
you want the lever to open and close the door, connect it directly:
	
		  ON, OFF
	[ Lever ] ---------------> [ Door ]

But what if the should be able to open the door from both sides? Simple placing
two levers and link them directly would work, but have the side effect that
if you open the door with one lever, walk through and try to close it with the
other lever would not work immidiately. This is because the second lever is also
in the OFF setting and would try to open the door again, and you need to flip
it twice to close the door:
		  
		  ON, OFF
	[ Lever ] ---------------> [ Door ]
                                     ^
		  ON, OFF            |	
	[ Lever ] -------------------+

There are two solutions: syncronise the levers, or easier, let each lever flip
the door's status:

		  ON, OFF		    FLIP
	[ Lever ] ---------------> [ Link ] --------> [ Door ]
                                     ^
		  ON, OFF            |	
	[ Lever ] -------------------+

Here is the diagram to syncronise the levers:

		    ON, OFF
	[ Lever ] +--------------> [ Door ]
           ^      |		     ^
	   |      |                  |
	   |      |  	             |	
	   |      v  	   ON, OFF   |	
	   |	[ Lever ] +----------+
           |      |
           |      | ON, OFF
	   +------+

If you flip the first lever, it will open the door and also set the second
lever to ON. Flipping either the first or second lever will switch both of
them OFF again, as well as close the door. It even needs on object less
(the link object is not neccessary).

However, there is a slight problem, can you spot it?

We have just created a loop, flipping the first lever would flip the second,
which would send ON to the first, which would send ON to the second, which
would send ON to the first etc. etc. However, the network will prevent this
by not relaying signals from the originating object back to itself.

Another thing is that the door will receive each signal twice: Flipping
the first lever will route a SIG_ON to the door, as well as the second
lever, which, since it is connected to the door, would also relay it's
ON signal to the door. This works, though, since the door will ignore multiple
signals of the same type.

=head2 Sound and delayed action

Let's assume you want, if a lever is flipped, a x seconds long sound sample
be played (for instance sound of some heavy machinery), and then open a door.

There are again, multiple ways to solve this:
	
		     	      2s     ON   
	[ OnButton ] +----> [ Link ] -------> [ Door ]
	    ^	     | ON
	    |	     |		  			  DEACTIVATE
	    |	     +----> [ SoundEmitter ] --> [ Link ]------------+
	    |						             |
	    +--------------------------------------------------------+

Pressing the button will play the sound, and deactivate the button. It
will also open the door after 2 seconds. If you don't know in advance
how long the sound plays, try this:
		     	      
			        Invert ON, OFF    
	[ OnButton ] +        [ Link ] -------> [ Door ]
	    ^	     | ON       ^
	    |	     |	        |  			  DEACTIVATE
	    |	     +----> [ SoundEmitter ] --> [ Link ]------------+
	    |						             |
	    +--------------------------------------------------------+

Pressing the button will play the sound, and deactivate the button. If
the sound is finished, the emitter will send a signal OFF, and this will
be turned into an ON signal by the link (it is inverted) and open the
door. The first signal, ON, will be inverted to OFF and do nothing, because
the door is already closed. 

Note: You could not used a link that just converted every signal into ON,
because the first ON signal, send by the Button to the SoundEmitter, would
also be relayed to the door, and open it to early.

=head2 Lever combinations

Imagine you want a door to be opened after the player has flipped two
levers (but only then!):

Both levers have to be on the same side of the door, naturally:

The following would B<not> work, because either lever would open the door
alone:
 
		  ON, OFF
	[ Lever ] ---------------> [ Door ]
                                     ^
		  ON, OFF            |	
	[ Lever ] -------------------+

So, we use a link, and also turn the link into an AND gate. Normaly links
act as OR gate, relaying each signal as it comes in. In AND gate mode, links
only relay a signals if all inputs have received the same signal. Each input
stores the last signal that arrives there and as soon as they are all in the
same setting, the signal is send out (possible inverted, and delayed, though).

		  ON, OFF	     AND    ON, OFF
	[ Lever ] ---------------> [ Link ] --------> [ Door ]
                                     ^
		  ON, OFF            |	
	[ Lever ] -------------------+

Setting both levers to ON opens the door, setting both to OFF closes it.
Setting on lever different than the other does nothing.

=head1 METHODS

This package defines no methods.

=head1 BUGS

None known yet.

=head1 AUTHORS

(c) 2003, 2004, 2006 Tels <http://bloodgate.com/>

=head1 SEE ALSO

L<Games::Irrlicht> as well as:

L<Games::3D::Thingy>, L<Games::3D::Link>, L<Games::3D::Signal>, L<Games::3D::Sensor>.

=cut

