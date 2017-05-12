package Linux::Joystick;

use Fcntl; # for O_RDONLY, O_NONBLOCK

### global vars (not exported)

our $VERSION = "0.0.1";

# List of device node prefixes where we might expect to find
# joystick devices, used for probing.
our @devlist = qw(/dev/input/js /dev/js);

### constructor

sub new {
	my $proto = shift;
	my $class = ref $proto || $proto;
	my $self;

	if( @_ == 1 ) { # if only 1 arg, it's the device
		$self->{device} = shift;
	} else {
		$self = { # defaults:
			device => 0,
			threshold => 1000,
			nonblocking => 0,
			fh => undef,
			@_     # override defaults
		};
	}

	bless $self, $class;

	$self->_open_fh unless $self->{fh};
	$self->_init if $self->{fh};

# return undef if couldn't open the file
	return $self->{fh} ? $self : undef;
}

### public static methods (aka class methods)

sub version {
	return $VERSION;
}
	
### public methods (aka instance methods)

# read & discard all pending events.
# adapted from `perldoc -f select'
sub flushEvents {
	my $self = shift;
	my $rin = '';
	vec($rin, fileno($self->{fh}), 1) = 1;

	while(select($rin, undef, undef, 0.2)) {
		$self->_read_event;
	}
}

# How many axes are there on the current device?
sub axisCount {
	my $self = shift;
	return $self->{axes};
}

# How many `sticks' (axis pairs) are on the current device?
sub stickCount {
	my $self = shift;
	return $self->{axes} >> 1;
}

# How many buttons are on the current device?
sub buttonCount {
	my $self = shift;
	return $self->{buttons};
}

# Get the most recent error message, if any. We don't use this
# in the current version, but we might want to someday
sub errorString {
	my $self = shift;
	return $self->{errorstring};
}	

# Get the path to the device node we're reading from. Returns
# something like `/dev/input/js0'.
sub device {
	my $self = shift;
	return $self->{device};
}

# Get the filehandle we're reading from. This is a public method,
# but user code that does I/O on this filehandle is responsible
# for maintaining sync with the driver (which means, only read it
# in 8-byte chunks if you're going to read it at all). I provide
# this method for people who know what they're doing...
sub fileHandle {
	my $self = shift;
	return $self->{fh};
}

# Return the next event from the device, as a Linux::Joystick::Event.
# In blocking (default) mode, this method will block. In non-blocking
# mode, it will return either a valid event if one was ready, or
# undef if not.
sub nextEvent {
	my $self = shift;
	
	$self->_read_event;
	return Linux::Joystick::Event->new($self);
}

# set blocking/nonblocking mode without reopening the device
sub setNonblocking {
	my $self = shift;
	my $nonbl = shift;
	my $buf = ""; # unused by F_GETFL but required?

	my $mode = fcntl($self->{fh}, F_GETFL, $buf);

	if($nonbl) {
		$mode |= O_NONBLOCK;
	} else {
		$mode &= ~O_NONBLOCK;
	}

	fcntl($self->{fh}, F_SETFL, $mode);
	$self->{nonblocking} = $nonbl;
}

### private methods

# _init reads any & all init events and sets the values returned by
# buttonCount and axisCount. It uses select() with a timeout
# of 0.2 seconds, so there's a slight pause when it's called.
sub _init {
	my $self = shift;

	my($max_axes, $max_buttons) = (0, 0);

# adapted from `perldoc -f select'
	my $rin = '';
	vec($rin, fileno($self->{fh}), 1) = 1;

# this ought to work in either blocking or non
	while(select($rin, undef, undef, 0.2)) {
		$self->_read_event;
		my $ev = Linux::Joystick::Event->new($self);
		if($ev->_isInit) {
			if($ev->isAxis) {
				$max_axes = ($ev->axis) if ($ev->axis) > $max_axes;
			}

			if($ev->isButton) {
				$max_buttons = ($ev->button) if ($ev->button) > $max_buttons;
			}
				# This happens a lot, but appears to be harmless:
				## } else {
				## warn "Got non-init event during initialization: " . $ev->hexDump;
		}
	}

	$self->{buttons} = $max_buttons + 1;
	$self->{axes} = $max_axes + 1;
}

# private method, read one event. Events are 8 bytes on all
# architectures, or should be because the struct js is defined
# in terms of uint8/uint16/etc, not platform-dependent types
# like int.
sub _read_event {
	my $self = shift;

	my $got;

	my $ret = sysread $self->{fh}, $got, 8;
	$self->{rawevent} = $got;

	return $ret;
}

# Figure out which device node to open, open it, and return a
# perl filehandle to it (undef on error).
sub _open_fh {
	my $self = shift;

	my $fh;

	my $realdevice;

# if user-specified device path, use it
	if($self->{device} =~ /\D/) {
		$realdevice = $self->{device};
	} else { # otherwise, search using the device number
		for(@devlist) {
			my $test = $_ . $self->{device};
			($realdevice = $test), last if -r $test;
		}
	}

# $realdevice contains the path we want to use
# if open() fails, leave $self->{fh} as it was (undefined)

# used to do this...
#$self->{fh} = $fh if open $fh, "<$realdevice";

# now we do this, to support non-blocking I/O
	my $flags = O_RDONLY;
	$flags |= O_NONBLOCK if $self->{nonblocking};
	if(sysopen $fh, "$realdevice", $flags) {
		$self->{fh} = $fh;
		$self->{device} = $realdevice;
	}
}


### end of Linux::Joystick

package Linux::Joystick::Event;

### constructor
sub new {
	my $proto = shift;
	my $class = ref $proto || $proto;

	my $parent = shift;
	my $self = {
		data => $parent->{rawevent},
		threshold => $parent->{threshold},
		nonblocking => $parent->{nonblocking},
	};

	bless $self, $class;

	return ($self->_parse) ? $self : undef;
}

### public methods

# returns hex string of raw data bytes.
sub hexDump {
	my $self = shift;

	return join(" ", unpack("H8", $self->{data}));
}

# get timestamp. User code might use this to detect doubleclicks
# of the buttons.
sub timeStamp {
	my $self = shift;
	return $self->{stamp};
}

# Which axis caused this event?
# undef for non-axis events.
sub axis {
	my $self = shift;
	return $self->{axis};
}

# Which `stick' (axis pair) caused this event? See the explanation
# of sticks in the pod.
# undef for non-axis events.
sub stick {
	my $self = shift;
	return $self->{axis} >> 1;
}

# Which button caused this event?
# undef for non-button events.
sub button {
	my $self = shift;
	return $self->{button};
}

# boolean: is this an axis event?
sub isAxis {
	my $self = shift;
	return defined($self->{axis});
}

# boolean: is this a button event?
sub isButton {
	my $self = shift;
	return defined($self->{button});
}

# Return human-readable string version of the
# event type. Probably best used for debugging.
sub type {
	my $self = shift;
	return "BUTTON" if defined($self->{button});
	return "AXIS" if defined($self->{axis});
	return "UNKNOWN";
}

# Return the value of the current axis, for axis events, or undef
# for non-axis. Generally ranges from -32768 to 32767.
sub axisValue {
	my $self = shift;
	if($self->isAxis) {
		return $self->{value};
	} else {
		return undef;
	}
}

# boolean: Was the stick moved left?
sub stickLeft {
	my $self = shift;
	my $stick = shift; # may be undef
	
	return $self->_decodeAxis($stick, 0, sub { $self->{value} <= -$self->{threshold} });
}

# boolean: Was the stick moved up?
sub stickUp {
	my $self = shift;
	my $stick = shift; # may be undef
	
	return $self->_decodeAxis($stick, 1, sub { $self->{value} <= -$self->{threshold} });
}

# boolean: Was the stick moved right?
sub stickRight {
	my $self = shift;
	my $stick = shift; # may be undef
	
	return $self->_decodeAxis($stick, 0, sub { $self->{value} >= $self->{threshold} });
}

# boolean: Was the stick moved down?
sub stickDown {
	my $self = shift;
	my $stick = shift; # may be undef
	
	return $self->_decodeAxis($stick, 1, sub { $self->{value} >= $self->{threshold} });
}

# boolean: was a button pressed?
sub buttonDown {
	my $self = shift;
	my $but = shift;

	if(defined($self->{button})) {
		if(defined $but) {
			return ($self->{number} == $but) && $self->{value};
		} else {
			return $self->{value};
		}
	} else {
		return undef;
	}
}

# boolean: was a button released?
sub buttonUp {
	my $self = shift;
	my $but = shift;

	if(defined($self->{button})) {
		if(defined $but) {
			return ($self->{number} == $but) && (!$self->{value});
		} else {
			return !$self->{value};
		}
	} else {
		return undef;
	}
}

### private methods

# private method. unpacks the raw data, stores as hash elements
# in %$self. Most user programs won't directly access the hash
# elements; they'll use the accessor methods (e.g. button() and
# friends).
sub _parse {
	my $self = shift;

# return undef if no event was ready
# (under what circumstances does this ever happen?)
	if(not defined $self->{data}) {
		return undef;
	}

# do not spew `data length is 0' warnings in nonblocking mode.
	if( ($self->{nonblocking}) && (length($self->{data}) == 0)) {
		return undef;
	}

	if(length($self->{data}) != 8) {
		warn "event data length is " . length($self->{data}) . ", not 8!";
		return undef;
	}

	my @got = unpack("LsCC", $self->{data});
	$self->{stamp} = $got[0];
	$self->{value} = $got[1];
	$self->{type} = $got[2];
	$self->{number} = $got[3];

	if($self->{type} & 0x02) {
		$self->{axis} = $self->{number};
	}

	if($self->{type} & 0x01) {
		$self->{button} = $self->{number};
	}

# paranoia:
	if(($self->{type} & 0x03) == 3) {
		warn "event is both axis and button, how did this happen?" . $self->hexDump;
	}

	return 1;
}

# private method, boolean: is this a synthetic init event (true), or a
# real one (false)
sub _isInit {
	my $self = shift;

	return $self->{type} & 0x80;
}

# private method, figures out whether the requested axis is moved
# in the given direction. Used by stickLeft/Right/Up/Down.
sub _decodeAxis {
	my $self = shift;
	my $stick = shift;

	return undef unless $self->isAxis;
	my $evenOdd = shift;
	my $compFunc = shift;

	if(defined $stick) {
		return undef unless ($self->axis) >> 1 == $stick;
	}

	if($self->axis % 2 == $evenOdd) {
		return 1 if $compFunc->();
		return 0;
	}

	return undef;
}


# End of Linux::Joystick::Event

=pod

=head1 INTRODUCTION


Linux::Joystick is an object-oriented, pure Perl API for accessing
joystick devices under Linux-based operating systems. It is capable
of using either blocking or non-blocking I/O, and represents each axis
change or button press as a Linux::Joystick::Event object.

=head1 USAGE


If you want your application to be driven by joystick events,
use blocking I/O and an event loop:

	use Linux::Joystick;

	my $js = new Linux::Joystick;
	my $event;

	print "Joystick has " . $js->buttonCount() . " buttons ".
		"and " . $js->axisCount() . " axes.\n";

	# blocking reads:
	while( $event = $js->nextEvent ) {

		print "Event type: " . $event->type . ", ";
		if($event->isButton) {
			print "Button " . $event->button;
			if($event->buttonDown) {
				print " pressed";
			} else {
				print " released";
			} 
		} elsif($event->isAxis) {
			print "Axis " . $event->axis . ", value " . $event->axisValue . ", ";
			print "UP" if $event->stickUp;
			print "DOWN" if $event->stickDown;
			print "LEFT" if $event->stickLeft;
			print "RIGHT" if $event->stickRight;
		} else { # should never happen
			print "Unknown event " . $event->hexDump;
		}

		print "\n";
	}

	# if the while loop terminates, we got a false (undefined) event:
	die "Error reading joystick: " . $js->errorString;


You can also use non-blocking I/O, in which case nextEvent() returning
undef just means there was no event to read:

	my $js = Linux::Joystick->new(nonblocking => 1);
	# use this to open 2nd joystick in nonblocking mode instead:
	# my $js = Linux::Joystick->new(device => 1, nonblocking => 1);

	while(1) {
		my $event = $js->nextEvent;

		if($event) {
			print "Got a joystick event\n";
			# process the event here
		}

		# Do other processing here (graphics, sound, I/O, calculation)

	}

It is possible to switch between blocking and non-blocking I/O without
reopening the device (see the setNonblocking() method, below).

=head1 CONSTRUCTORS


Create a new Linux::Joystick object using the default joystick device
(usually the first on the system):

	my $js = Linux::Joystick->new; # Default device, same as new(0)

Same as above, but for a specific joystick (numbered starting with 0):

	# Default device (first joystick)
	my $js = Linux::Joystick->new(0);
	my $js = Linux::Joystick->new(device => 0); # same thing

	# Second joystick (player 2?)
	my $js = Linux::Joystick->new(1);
	my $js = Linux::Joystick->new(device => 1); # same thing

By default, we search for joystick devices by prepending the string
B</dev/input/js> to the device number, then falling back to B</dev/js>
if that fails. Most modern Linux systems will have B</dev/js0> as a
symlink to B</dev/input/js0> anyway.

If you need to, you can also use a constructor like this:

	my $js = Linux::Joystick->new("/dev/js0");
	my $js = Linux::Joystick->new(device => "/dev/js0"); # same thing

...but this practice isn't recommended: if next year Red Hat decides
to call their joystick device B</dev/gamecontroller0>, I (or someone)
will update this Perl module to reflect that fact, and your perl scripts
that use the numeric form will continue to work.

Any of these constructors will return undef on failure. The $! variable
might or might not contain a useful error message. Possible failure
reasons include the usual suspects (no joystick plugged in, no driver
loaded, no permission to read from the device node, cat chewed through
the USB cable, etc).

Creating multiple Linux::Joystick objects that read from the same device
results in undefined behaviour, primarily because I haven't tested it,
so I can't define it yet... but it's probably not a good idea (what
happens will probably be dependent on what kernel version and kernel
joystick driver you happen to be using).

=head2 Constructor parameters


The Linux::Joystick contructor uses named parameters, in the same way
that IO::Socket and many other Perl modules do. Here is a constructor
that sets all possible values to their defaults:

	# The following is exactly equivalent to just using
	# new() with no arguments:
	my $js = Linux::Joystick->new(
			device => 0,
			threshold => 1000,
			nonblocking => 0,
			fh => undef);

Here are the descriptions of all these parameters:

	device

The device number to open. These are numbered starting from 0. Depending
on your system configuration and how many joystick devices you have
connected, you may have a large number of these to choose from. The
default value is 0 (zero), which is the first joystick. If you specify
a non-numeric parameter, it will be treated as the absolute path to
a device node (such as B</dev/js0>). There are I<NO> checks to make
sure the path is actually a joystick device (or even a device node at
all). Attempting to open a regular file or anything else other than a
joystick device leads to unpredictable and generally useless behaviour.

	nonblocking

Whether or not to use nonblocking I/O mode in the nextEvent method (1
or any true value for yes, 0 or any false value for no). This is off by
default (0). Normally, in regular (blocking) mode, the nextEvent method
blocks (waits) until a joystick event is received. With non-blocking I/O,
nextEvent will return immediately. Its return value will be undef if there
was no event ready (normally it always returns a valid event). Turning
this on requires you to restructure your code somewhat (see examples
above), but it allows your app to do other things while it's waiting
for joystick movement.

	threshold

How far the joystick must be moved from the center before it's registered
as a directional movement. The default is 1000, which is appropriate
for most (all?) digital controls, and for the analog thumb sticks on my
`Axis Pad', but might be a bit too sensitive for a traditional analog
`flight' stick. The bigger the threshold is, the bigger the `dead' zone
will be, and the less `jitter' you'll experience. For digital (d-pad)
style controls, there's no dead zone or jitter to worry about.

	fh

A Perl file handle reference (or glob). This is intended primarily for
testing Linux::Joystick itself, but you could use it to e.g. read fake
joystick events from a pipe or something. Use of this parameter causes
the B<device> parameter to be ignored. As with the B<device> parameter,
there is no check done to verify that the filehandle actually represents
a joystick device.  There is no default for this parameter.

Any parameter may be omitted, which will give that parameter its default
value. A constructor with no arguments will cause all parameters to be
set to their defaults.

The one-argument constructor is a convenient shorthand for setting
the device parameter. The following 2 lines are equivalent:

	Linux::Joystick->new($dev);
	Linux::Joystick->new(device => $dev);

If you want to set the device and specify other parameters at the same
time, you'll have to use the full constructor with the I<device> argument.

=head1 METHODS


These are the methods for the Linux::Joystick class itself. Event
methods are described in the next section (Events). I<$js> is an
object of class Linux::Joystick, in the descriptions below.

=head2 List of methods


	$js->version
	$js->nextEvent
	$js->flushEvents
	$js->buttonCount
	$js->axisCount
	$js->stickCount
	$js->errorString
	$js->device
	$js->fileHandle
	$js->setNonblocking

=head2 $js->version


Returns the version of the Linux::Joystick module. This method may
be called as either an instance method (as shown above) or as a class
method: my $ver = Linux::Joystick->version;

=head2 $js->nextEvent


Returns a joystick event, or undef if there is no event.

Joystick events are Linux::Joystick::Event objects (see below).

In blocking mode (the default), nextEvent waits until there is an event
to return. This could mean it waits forever, if the user walks away
from the joystick. If you don't like this, either use nonblocking mode
or wrap in an eval/alarm block.

nextEvent should never return undef in blocking mode, but you should
check for it anyway. I don't know what circumstances could cause it to
happen (user unplugs the joystick? Not for USB controllers at least),
but it'd definitely count as an exceptional condition. I<die> might be
the appropriate response, but I defer that decision to you.

In nonblocking mode (constructor with nonblocking => 1), nextEvent will
return undef if there's no pending event ready to be read. This isn't
an error or exception: B<most> of the time there's no input. Nonblocking
mode is what you'll want to use in all but the simplest applications.

=head2 $js->flushEvents

Flushes any pending events in the input buffer. This is most useful
in blocking mode, when your program does some long calculation or time
consuming I/O. The user might get restless and twiddle the joystick while
waiting. Since the kernel joystick buffer is 64 events, this means your
program would suddenly read up to 64 random joystick events when its
time-consuming subroutine returns, which could cause all kinds of havoc.

This method works in either blocking or non-blocking I/O mode, though
it's most useful in blocking mode. Beware: calling flushEvents causes
a 0.2 second delay in your program's execution.

=head2 $js->buttonCount


Returns the number of buttons on the joystick.

Buttons are numbered starting with 0, so the highest-numbered button
will be one less than buttonCount's return value.

For USB joysticks, this count is almost always correct. For gameport
joysticks, it's possible that a 2-button generic gamepad/stick will
appear to have 4 buttons (I've seen this happen before, but it was
a long time ago). It's also possible that you're using a device with
the generic gameport joystick driver (which only supports 4 buttons),
but that device has a more specific driver you could be using that
supports all the buttons on the device. I've had this problem with a
Gravis Gamepad Pro gameport controller in the past.

It's possible for a joystick to have 0 buttons, but not very likely
(who makes a joystick with no buttons?)

It's also possible for a device to report more buttons than it
physically has. I have an `Axis Pad' (manufacturer unknown, made
in China) that claims to have 20 buttons, though it really has 11.
Strangely enough, 10 of the buttons show up as buttons 0 through 9,
and the 11th button (actually a `Game/Set' switch) shows up as number
19!

I've got a gameport to USB adaptor that I use to plug my old Gamepad
Pro into my new (USB-only) PC. It supports 4 axes and 8 buttons, and
I<always> reports all the buttons and axes, regardless of what kind of
gameport controller is plugged in (or not plugged in: the PC can't tell).
This part was made by Radio Shack, but I bet other gameport/USB adaptors
will exhibit the same behaviour.

=head2 $js->axisCount


Returns the number of axes on the device.

Axes are numbered starting with 0, so the highest-numbered axis will
be one less than axisCount's return value.

It's theoretically possible to have a joystick device with no axes
(buttons only), but I've never seen one.

=head2 $js->stickCount


Returns the number of `sticks' on the device.

Sticks are numbered starting with 0, so the highest-numbered stick will
be one less than stickCount's return value.

This is equal to the number of axes divided by two (rounded down). A stick
is equivalent to two axes (vert and horiz), although there's no guarantee
that a stick actually represents a physical stick (or d-pad, or whatever):
if you have a device with one d-pad, a spinner, and a throttle slider,
stickCount will report that you have two sticks (the d-pad counts as one,
and the two other single-axis devices together count as the other).

If axisCount is 1 greater than stickCount*2, the leftover axis is a
single-axis control. Most single-axis controls are analog, not digital
(you can use the axisValue for proportional movement).

The native Linux joystick API has no concept of sticks. I invented this
for convenience, because I prefer to think of a d-pad or stick as a
single stick, rather than two axes. You are free to treat them as sticks,
or axes, or mix and match both forms of addressing.

A few words about joystick axes, sticks, and buttons:

There's no way to tell what axes or buttons correspond to which
physical controls on a gamepad or joystick. This is not a limitation
of Joystick::Linux, it's a limitation of the underlying kernel API.

That said, there are conventions followed by (almost) all devices.

Even-numbered axes (including 0) are horizontal (left/right) axes.
Odd-numbered axes are vertical (up/down) axes. A pair of such axes
constitures a `stick'. Even though I call it a stick, it might be a d-pad,
or a trakball, or whatever. The important point is that a stick (usually)
represents a single physical control that can be used to detect movement.

For d-pads, sticks, hats, trakballs, and the like, there will be 2
sequentially-numbered axes per control. Typically axes 0 and 1 (stick 0)
are the primary control (d-pad or stick), 2 and 3 (stick 1) are the hat
or analog thumbstick, etc.

If you have single-axis controls (throttles or spinners), they will be
the highest-numbered axes, and will only have one axis each. A device
with 5 axes might use 0/1 for the main stick control, 2/3 for the hat,
and 4 for the throttle slider. Generally, any controller with an odd
number of axes has a slider, throttle, knob, or whatever. You are of
course free to ignore axes you don't care about (most apps, even games,
won't need more than 2 axes (1 stick)).

For buttons, usually the ones directly under the user's thumb will be the
lowest-numbered ones (typically these are in a diamond-shaped cluster and
labelled A, B, X, Y or A, B, C, D). Usually, but not always, the button
numbers returned by $event->button will correspond to the alphabetical
ordering of the buttons (button 0 is the A button, 1 is the B, etc.)

`Shoulder' buttons (like the L and R on a SNES controller) will be next
(left shoulder having a lower number than the right), and then any
pause/select/start buttons.

Turbo buttons are usually implemented in hardware, inside the controller.
This means that they don't get their own button numbers. Instead, holding
down the `turbo A' button will cause the joystick to send a stream of
events (pressed A, released A, pressed A, etc) to the PC. It's impossible
for the joystick driver to tell the difference, so the buttonCount method
won't include turbo buttons in the count.

(Historical note: Turbo buttons were originally implemented this way
because early console games typically didn't have a `rapid fire' mode at
all (since it would make a lot of the games really easy). Third party
manufacturers would sell joysticks with turbo buttons as `cheating'
devices, and they had to work with unmodified consoles and games, hence
the transparent hardware implementation).

Not all devices follow the rules.

You need to decide how many buttons and axes you need in your application,
keeping in mind that all you can *really* count on are 2 axes and 2
buttons (all PC controllers have at least 2 axes and 2 buttons). These
days, it's fine to rely on there being 4 buttons: if anyone still owns
a 2-button controller, it should be in a museum.

One trick you can do to semi-support extra buttons/axes is to use the
modulus operator:

	# we only have 2 possible actions, only care about 2 buttons
	if($event->isButton) {
		if($event->button % 2 == 0) {
			# all even-numbered buttons do one action...
			fire_lasers();
		} else {
			# all odd-numbered buttons do the other action...
			engage_warp_drive();
		}
	}

This way, the user can use whichever two buttons are most comfortable to
him. The same applies to axes: if you only care about up/down/left/right,
why not let the user use either the d-pad or the analog thumbstick,
his choice?

=head2 $js->errorString


In the unlikely event of an error reading from the joystick device,
this method will give you a human-readable error message. If there
was no error, errorSting returns undef.

Currently (in version 0.0.1), no error strings are defined.

=head2 $js->device


Returns the path to the device node that was opened, e.g. /dev/js0,
or undef if the device couldn't be opened.

=head2 $js->fileHandle


Returns the Perl filehandle that Linux::Joystick is reading events
from. You could use this to do a select() on the filehandle (and any
other filehandles you need to handle).

Attempting to read from this filehandle will (at best) confuse the
joystick driver temporarily, or (at worst) cause your read to block
forever (particularly if you're trying to use buffered reads). You
have been warned! If you want to use select(), here's one way to
do it:

	# assume that $input represents some stream such as a keyboard
	# or network socket, and $js is our Linux::Joystick device. Further
	# assume that $input is opened in non-blocking mode (it shouldn't
	# matter for $js, since the kernel *always* returns 8 bytes per event).

	# adapted from `perldoc -f select', which see for details.

	while(1) {
		my $buf; # $input buffer
		my $BUFLEN = 1024; # size of $input buffer

		my $rin = '';
		for($js->fileHandle, $input) {
			vec($rin, fileno($_), 1) = 1;
		}

		# 4th parameter is timeout. 0 means return immediately,
		# undef means block forever, anything else is number of
		# seconds to wait. $nfound will tell how many fd's had
		# input pending, which really isn't too useful...

		my $nfound = select($rin, undef, undef, undef);

		if( vec($rin, fileno($js->fileHandle), 1) == 1 ) {
			my $event = $js->nextEvent();
			process_event($event); # or whatever
		}

		if( vec($rin, fileno($input), 1) == 1 ) {
			# GOTCHA: do NOT use <$input> here! (see select() perldoc)
			while( ($bytes = sysread($input, $buf, $BUFLEN) > 0) ) {
				# process $input data one buffer at a time
				process_input($buf);
			}
		}
	}

Notice that the above routine doesn't read from the filehandle returned
by $js->fileHandle. Instead it's just used in the select() call.

You can make that a lot more readable by using the IO::Select module
instead of all that mess with vec() and select().

Of course, variations on this theme are possible. You could use the
Curses or IO::Stty modules to read one character at a time from STDIN,
in which case you'd just process one keystroke per loop iteration...

=head2 $js->setNonblocking


Sets or clears non-blocking mode. Takes one scalar parameter, which
is treated as a boolean: a true value turns on non-blocking I/O, and
a false value turns it off. It doesn't hurt anything to attempt to set
the same mode that's already in use, and you can switch between the I/O
modes as many times as you want.

setNonblocking uses an fcntl() call to change the file descriptor's mode,
so it doesn't close and reopen the device. Remember that when you're in
non-blocking mode, all calls to nextEvent immediately return. When there's
no input, the event returned will be undef. Also remember not to busy-wait
on events! If you find yourself using 99% of the CPU according to `top',
you need to restructure your code so that it works in blocking mode. If
you can't do this (e.g. because you're reading from a network socket as
well as a joystick), at least use a call like select(undef, undef, undef,
0.01) to yield the CPU so that other processes can run.  An even better
idea would be to stay in blocking mode, but use the fileHandle method
to get the joystick's file handle, then select() on both the joystick
and network filehandles. This way, the kernel will put your process to
sleep until there's some input available on one stream or the other.

Since setNonblocking uses fcntl(), it may behave strangely on really old
(2.2 or earlier) kernels. I have only tested this module on Linux 2.4
and 2.6 kernels.

=head1 Events


	$ev->isButton
	$ev->button
	$ev->buttonDown
	$ev->buttonUp
	$ev->isAxis
	$ev->axis
	$ev->axisValue
	$ev->stickLeft
	$ev->stickRight
	$ev->stickUp
	$ev->stickDown
	$ev->type
	$ev->hexDump
	$ev->timeStamp

=head2 $ev->isButton


Returns true if this event was caused by a button press, or false if not.

The next 3 method calls are only valid for button events (e.g. when
isButton returns true). If called on a non-button event, they will
return undef.

=head2 $ev->button


Returns the number of the button that caused this event, if it was
a button event, or undef it it wasn't a button event. Keep in mind that
0 is a valid button (it's the first button), so you don't want to
treat this as a boolean (use isButton instead).

NOTE: In the Linux joystick API, each button is reported separately,
even if more than one button was pressed or released simultaneously. For
example, pressing 2 buttons at once on a gamepad results in 2 events:
one for each button. This may sound like a problem, but in practice it
works out just fine if you process each event as soon as it comes in.

=head2 $ev->buttonDown

=head2 $ev->buttonDown($b);


Returns true if this was a button press event, false if it was a
button release event, or undef if it was not a button event at all.

With the optional $b parameter, returns true if this is a button
event B<and> if the button $b was pressed.

=head2 $ev->buttonUp;

=head2 $ev->buttonUp($b);


Returns true if this was a button release event, false if it was a
button press event, or undef if it was not a button event at all.

With the optional $b parameter, returns true if this is a button
event B<and> if the button $b was pressed.

For button events, buttonDown returns !buttonUp, and buttonUp returns
!buttonDown. Use whichever method makes your code most readable. For
non-button events, both methods return undef.

=head2 $ev->isAxis


Returns true if this event was caused by joystick axis movement, false
otherwise.

=head2 $ev->axis


Returns the axis number that caused this event, if it was an axis
event. Otherwise, returns undef. Remember, 0 is a valid axis number,
so don't treat this as a boolean value (use isAxis for that).

NOTE: In the Linux joystick API, each axis is reported separately,
even if more than one axis changed simultaneously. For example, diagonal
movement on a gamepad results in 2 events: one for the vertical axis and
one for the horizontal. This may sound like a problem, but in practice
it works out just fine if you process each event as soon as it comes in.
However, it does mean that you can't test an individual event to
determine whether or not a stick is centered.

=head2 $ev->stick


Returns the stick (or d-pad, or whatever) number that caused this
event. This is determined by which axis caused the movement: Axes 0 and
1 are considered to be stick 1, axes 2 and 3 are stick 2, etc.

More formally, ($ev->stick == $ev->axis >> 1) is always true.

This is the same logical stick number that you provide to the
stickUp/Down/Left/Right methods, below.

The Linux joystick API does not include the concept of a stick number;
I invented this as a convenience for Perl programmers (to give you More
Than One Way To Do It(tm)).

=head2 $ev->axisValue


Returns the current value of the axis, if this event was an axis event.
Returns undef for non-axis events. 0 is a valid value (it's the center
position), so don't use this as a boolean value (use isAxis for that).

This is a signed 16-bit value. Negative values indicate movement to the
left (for horizontal axes) or up (for vertical axes). Positive values
indicate movement to the right or down. Zero is the center position.

The axisValue method works for either analog or digital controls. In the
C API, B<all> joystick devices are treated as analog devices. A digital
gamepad will typically return only -32768, 0, or 32767 for each axis,
while an analog stick will return values anywhere in the range of
-32768 to 32767, with 0 being the center.

You should NOT rely on the values being exact, however: sometimes the
calibration is off, so the center value is something other than 0, or
the maximum range is less than usual. Typically, you'll want to ignore
values less than some threshold (possibly configurable by the user of
your app). This keeps `jiter' from affecting your app. If you're having
calibration issues, the B<jscal> utility will help.

Actually, you should only use axisValue if your app is using the
joystick's analog value to control something like a mouse pointer
(other examples would be: the paddles in a Pong/Breakout type game,
or the control yoke in a flight simulator). Keep in mind that a digital
gamepad-style controller will be useless for such applications.  Also keep
in mind that the joystick API doesn't give us a way to know whether the
joystick we're reading is a digital gamepad or an analog stick.

If you're only interested in I<which direction> the stick is pressed,
use the stickLeft/Right/Up/Down methods, below.

=head2 stickLeft

=head2 stickLeft($stick)


Returns true if the event was caused by movement to the left, false
if otherwise, and undef if the event isn't an axis event.

If no parameter is provided, a true result means B<any> vertical axis
was moved left. If the optional I<$stick> parameter is given, it is used
to decide which axis-pair to check for movement. If $stick is 0, axes
(0,1) are checked. If $stick is 1, axes(2,3) are checked, etc.

If your app doesn't need more than one pair of axes (one stick), it
is recommended that you use the no-argument forms of stickUp, stickDown,
stickLeft, and stickRight.

=head2 stickRight

=head2 stickRight($stick)


Returns true if the event was caused by movement to the right, false
if otherwise, and undef if the event isn't an axis event.

I<see stickLeft for explanation of the optional $stick parameter>

=head2 stickUp

=head2 stickUp($stick)


Returns true if the event was caused by upwards movement, false
if otherwise, and undef if the event isn't an axis event.

I<see stickLeft for explanation of the optional $stick parameter>

=head2 stickDown

=head2 stickDown($stick)


Returns true if the event was caused by downwards movement, false
if otherwise, and undef if the event isn't an axis event.

I<see stickLeft for explanation of the optional $stick parameter>

=cut

## This method would require us to track state across multiple
## events, which I don't want to do:

## =head2 stickCenter
## =head2 stickCenter($stick)
## 
## Returns true if the event was caused by movement back to the center
## position, false if otherwise, and undef if the event isn't an axis event.
## 
## $ev->axisCenter is exactly equivalent to:
## 
## 	not (ev->stickLeft || $ev->stickRight || $ev->stickUp || $ev->stickDown)
## 
## I<see stickLeft for explanation of the optional $stick parameter>

=pod

The stickLeft/Right/Up/Down methods are provided as a convenience for
applications that only care about which direction the stick was moved,
not how far it was moved. This includes digital controls like the d-pad
on a gamepad (which can only report all-or-nothing).

These methods are a bit special in that they take into account which
axis was moved I<and> whether it increased or decreased. Your app code
doesn't need to check e.g. whether the horizontal axis (even numbered)
was moved before it checks for left/right movement.

Example use:

	# no-argument forms:
	if($ev->isAxis) {
		move_pacman_left() if $ev->stickLeft;
		move_pacman_right() if $ev->stickRight;
		move_pacman_up() if $ev->stickUp;
		move_pacman_down() if $ev->stickDown;
	}

	# use $stick to test two controls on same device:
	if($ev->isAxis) {
		print "Stick 0 (probably the D-Pad) moved left" if $ev->stickLeft(0);
		print "Stick 1 (probably the analog) moved left" if $ev->stickLeft(1);
	}

The $ev->isAxis test is actually superfluous: all four methods will return
undef (a false value) for non-axis events. The snippets above would work
just as well (though just slightly slower) without the if() around them.

Notice that there is B<NO> stickCenter method. This is due to the
fact that each event only reports movement for one axis. Since this
module doesn't save state between events, there's no way to tell (by
looking at just one event) the state of B<both> axes. Future versions of
Linux::Joystick may address this issue. For now, if you need to detect
a centered stick, you'll need to remember the axis values of that stick
in your application code.

=head2 $ev->type


Returns the string B<BUTTON> for button events, B<AXIS> for axis events,
or B<UNKNOWN> for unknown events. Primarily intended for debugging. You
shouldn't be comparing this string to determine event type (that's what
isAxis and isButton are for).

There should I<never> be any unknown events. If you're getting them,
it's because this module has a bug in it, or else the Linux kernel
developers have invented a new type of joystick event (not likely to
happen any time soon).

=head2 $ev->hexDump


Returns a string consisting of hex representations of the raw bytes,
as read from the joystick device file descriptor. Only meant for
debugging. There is no information here that you can't get from one of
the other methods in a friendlier way.

=head2 $ev->timeStamp


Returns the timestamp of this event. This is an integer number of
milliseconds. Linux::Joystick does not use or modify this value; it's
the js_event.time field from the C API. The kernel documentation doesn't
say a lot about this field. Here's what my copy of joystick-api.txt
says:

	The time an event was generated is stored in
	``js_event.time''. It's a time in milliseconds since ... well,
	since sometime in the past.  This eases the task of detecting
	double clicks, figuring out if movement of axis and button
	presses happened at the same time, and similar.

Use it for whatever you want, or ignore it. Future versions of this Perl
module might include support for detecting double-clicks, but if so, it'll
be something you have to enable (the default behaviour will not change).

=head1 Alternatives to Linux::Joystick


You could always open /dev/js0 yourself and read from it (that's all this
module does). I've tried to make the code fairly readable, so you can
look at site_per/Linux/Joystick.pm in your perl lib directory and see
how it's done (well, one way to do it, anyway). Search for _read_event
as a starting point.

You could also use the SDL module from CPAN, which provides lots of
other nice stuff besides joystick support, and is portable to lots of
other platforms (unlike Linux::Joystick, which only works on Linux).

On the minus side, SDL I<requires> you to create an application window
(not necessarily an X11 window) before it can access the joysticks. If
you're trying to add joystick support to an existing non-SDL app, or
writing a textmode interface with joystick support, or using a joystick
as an alternate input for disabled people, or anything else that doesn't
benefit from SDL's graphics & sound capabilities, you probably want this
module instead of SDL.

There also exist two CPAN modules you can use to support joysticks on
Windows platforms, if that's your goal. They are B<Win32API::Joystick>
and B<Win32::MultiMedia::Joystick>. I don't know anything about these
modules (not being a win32 programmer), and Linux::Joystick is not
compatible with either one.

If you're using FreeBSD, NetBSD, or OpenBSD, you may be able to use
Linux::Joystick with your OS's Linux emulation package. I don't know
whether this is actually supported or not (send me your results and I'll
put them here in the next version). A cursory glance at the man page for
NetBSD's I<joy> driver shows that it's nothing like the Linux joystick
driver, so you'd definitely need Linux emulation there, assuming the
emulation emulates the Linux joystick API.

=head1 C API


The C API is described in $srcdir/Documentation/input/joystick-api.txt in
the Linux kernel source. This Perl module only supports the new (1.2.x)
joystick API, not the old 0.x backwards compatibility API. This shouldn't
be a problem: I'm writing this in 2004, and the `new' API has been around
for something like 8 years now... if you're really still running an early
1.2.x Linux kernel, you presumably know what you're doing and don't need
my help.

The C API sends synthetic JS_INIT events, one per axis or button, when
the device is first opened. You can ignore these in your perl scripts:
Linux::Joystick intercepts the synthetic events itself and counts how
many axes/buttons your device has.

=head1 BUGS


Well, I haven't gone on an exhaustive bug-hunt yet, so that counts as
one bug right there :)

I haven't tested this with a regular analog stick, because I don't own
one. The closest thing I have are the analog thumb-sticks on my Axis pad.
All that should need changing with a flight stick is the threshold.

I need to test with lots of different devices. I own maybe 15 or 20
different PC-compatible game pads, so this is just a matter of time.

Someone needs to test this with some of the really oddball controllers out
there (like the homebrew hack that lets you plug a Sega Genesis controller
into your serial port). Given my hardware skills, that probably will be
someone other than me :)

The lack of a stickCenter event (and more generally, the lack of state
across events) might count as a bug.

Not really a bug, but a minor shortcoming: instantiating a
Linux::Joystick object causes a short (0.2 second) delay.

The errorString method never returns an error string. Most of the time,
if there's an error, it's during the constructor (where we open the
device for reading), so we return undef and leave the error message in
$!. The only possible use for errorString would be if we got an error
in the nextEvent method (maybe an EOF), but I've never actually seen
any such error.

If events are not read often enough, the kernel joystick driver will
fill up its event queue. According to joystick-api.txt, the queue has
room for 64 events, and if it overflows, the joystick driver resets
(starts sending synthetic init events again). This isn't likely with
a well-designed app, but it's possible (e.g. if pressing the 0 button
causes a long, involved process that takes a minute or two to complete,
and the impatient user keeps wiggling the d-pad while he waits). We
should be checking for synthetic events always, not just when we
first open the device.

I don't know what happens if a joystick is unplugged while it's open
for reading, then plugged back in. On my test machine, unplugging the
USB joystick doesn't cause an error, but plugging it back in doesn't
bring it back to life. However, unplugging it & plugging it back in even
while it's NOT open, makes it disappear and never come back (I have to
`rmmod joydev; modprobe joydev' to get it to work). This isn't the normal
behviour for USB sticks: normally they can be unplugged and plugged back
in, and they'll still work (though I don't know whether user code that's
reading them will need to reopen the device or not). I've *no* idea
what happens if a gameport joystick is unplugged!

=head1 AUTHOR


B. Watson, perljoystick@hardcoders.org

Feel free to contact me with bug reports, suggestions for improvement,
or even success stories (hey, somebody besides me has got to find this
thing useful, right?)

=head1 LICENSE


You may use and redistribute this Perl module under the same terms as
Perl itself (GPL or Artistic License, your choice).

If you use this module in a commercial product, I'd appreciate it if
you let me know. This isn't a licensing requirement; it's just common
courtesy.

Although I have made every effort to produce bug-free code, I am not
responsible for any loss or damages caused by the use of Linux::Joystick.
If it breaks, you get to keep both pieces :)

=head1 COPYRIGHT


Copyright (c) 2004, B. Watson

=cut

