package Linux::Input::Wiiuse;

use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

our $VERSION = '0.01';

require XSLoader;
XSLoader::load('Linux::Input::Wiiuse', $VERSION);

=head1 NAME

Linux::Input::Wiiuse - Use Nintendo Wiimote as an input device via libwiiuse

=head1 SYNOPSIS

  use Linux::Input::Wiiuse;

=head1 DESCRIPTION

Provides input from a Wii controller.  Supports Nunchuk, Classic Controller,
and Guitar Hero guitar attachments.  Supports buttons, IR, and motion.

=head1 new

  my $wii = Linux::Input::Wiiuse->new;
  my $wii = Linux::Input::Wiiuse->new({wiimotes => 16});

Create a new Wiiuse object.

Returns the Wiiuse object.

Accepts one optional argument: a hashref of config options.  The only attribute
you can set is "wiimotes", which defines the size of the array in C to hold
Wiimotes.  By default, this is set to 16.  You can set it to any number as long
as your system will support that many concurrently connected Wiimotes.

=cut

sub new
{
  my $class = shift;
  my $args = shift || {};
  unless (ref($args) eq 'HASH')
  {
    warn(qq(Optional single argument to new must be a HASHREF.));
    return undef;
  }
  my $self = bless({}, $class);
  $self->{MAXMOTES} = $args->{wiimotes} || 16;
  $self->{WIIMOTES} = wiiuse_init($self->{MAXMOTES});
  return $self;
}

=head1 library_version

  my $ver = $wii->library_version;

Returns the version of the installed libwiiuse library.

Accepts no arguments.

=cut

sub library_version
{
  return wiiuse_version();
}

=head1 cleanup

  $wii->cleanup;

This will close all Wiimote connections and cleanup the stored data.

Does not return a value.

Accepts no arguments.

=cut

sub cleanup
{
  my $self = shift;
  wiiuse_cleanup($self->{WIIMOTES}, $self->{MAXMOTES});
}

=head1 find

  my $found = $wii->find;
  my $found = $wii->find(5);

Finds Wiimotes available for connection.  The Wiimotes you wish to connect
must be in discoverable mode.  To set them to discoverable, press both
button 1 and button 2 on the Wiimote at the same time or press the red
sync button in the battery cage.  While the lights on the Wiimote continue
to blink, the controller is in discoverable mode.  When they shut off, it
is no longer in discoverable mode.

Returns the number of Wiimotes found.

Accepts one optional argument: the number of seconds to wait for devices.

=cut

sub find
{
  my $self = shift;
  my $timeout = shift || 10;
  $self->{found} = wiiuse_find($self->{WIIMOTES}, $self->{MAXMOTES}, $timeout);
  return $self->{found};
}

=head1 connect

  $wii->connect;

Connects to all discovered Wiimotes.

Returns the array of Wiimotes.

Accepts no arguments.

=cut

sub connect
{
  my $self = shift;
  $self->{connected} = wiiuse_connect($self->{WIIMOTES}, $self->{MAXMOTES});
  return $self->wiimotes();
}

=head1 wiimotes

  my @wiimotes = $wii->wiimotes;

  foreach my $wiimote (@wiimotes)
  {
    # .. do something with the $wiimote ..
  }

Returns an array of references to Wiimotes.  You'll use this array in a
loop during events or when you wish to make use of a Wiimote.

Accepts no arguments.

=cut

sub wiimotes
{
  my $self = shift;
  my @wiimotes;
  for my $i (1 .. $self->{connected})
  {
    push(@wiimotes, $self->get_by_id($i));
  }
  return @wiimotes;
}

=head1 disconnect

  $wii->disconnect($wiimote);

Disconnect a specific Wiimote.

Does not return a value.

Accepts a single argument: the Wiimote to disconnect.  You get $wiimote
from the array returned from "wiimotes".

=cut

sub disconnect
{
  my $self = shift;
  my $wiimote = shift;
  return wiiuse_disconnect($wiimote);
}

=head1 poll

  while ($wii->poll())
  {
    foreach my $wiimote ($wii->wiimotes)
    {
      # .. do something with each wiimote ..
    }
  }

Polls the Wiimotes for events and updates Wiimote data.  Call this often.

Returns either a true or false value based on whether there are any
Wiimotes to poll.  If false is return, no Wiimotes are likely to be
connected.

Accepts no arguments.

=cut

sub poll
{
  my $self = shift;
  return wiiuse_poll($self->{WIIMOTES}, $self->{MAXMOTES});
}

=head1 event

  use constant {
    WIIUSE_NONE => 0,
    WIIUSE_EVENT => 1,
    WIIUSE_STATUS => 2,
    WIIUSE_CONNECT => 3,
    WIIUSE_DISCONNECT => 4,
    WIIUSE_UNEXPECTED_DISCONNECT => 5,
    WIIUSE_READ_DATA => 6,
    WIIUSE_NUNCHUK_INSERTED => 7,
    WIIUSE_NUNCHUK_REMOVED => 8,
    WIIUSE_CLASSIC_INSERTED => 9,
    WIIUSE_CLASSIC_REMOVED => 10,
    WIIUSE_GH3_INSERTED => 11,
    WIIUSE_GH3_REMOVED => 12,
  };

  while ($wii->poll())
  {
    foreach my $wiimote ($wii->wiimotes)
    {
      if (my $event = $wii->event($wiimote))
      {
        if ($event == WIIUSE_EVENT)
        {
          # .. a generic event occurred on this Wiimote ..
        }
        elsif ($event == WIIUSE_DISCONNECT)
        {
          # .. this Wiimote was disconnected ..
        }
      }
    }
  }

Returns the event type that occurred (if any).

Accepts one argument: the Wiimote to check for events.

=cut

sub event
{
  my $self = shift;
  my $wiimote = shift;
  return wiiuse_event($wiimote);
}

=head1 rumble

  $wii->rumble($wiimote, 0); # rumble off
  $wii->rumble($wiimote, 1); # rumble on

Changes the rumble state.  This will make the Wiimote rumble
continuously when on.

Accepts two arguments: the Wiimote to rumble and the rumble state.

=cut

sub rumble
{
  my $self = shift;
  my $wiimote = shift;
  my $state = shift;
  wiiuse_rumble($wiimote, $state);
}

=head1 toggle_rumble

  $wii->toggle_rumble($wiimote);

Toggles the rumble state.

Does not return a value.

Accepts one argument: the Wiimote to rumble.

=cut

sub toggle_rumble
{
  my $self = shift;
  my $wiimote = shift;
  wiiuse_toggle_rumble($wiimote);
}

=head1 set_leds

  use constant {
    WIIMOTE_LED_1 => 0x10,
    WIIMOTE_LED_2 => 0x20,
    WIIMOTE_LED_3 => 0x40,
    WIIMOTE_LED_4 => 0x80,
  };

  # this turns off all LEDs.
  $wii->set_leds($wiimote, 0);

  # this turns on LEDs 1 and 4 and shuts off all others.
  $wii->set_leds($wiimote, WIIMOTE_LED_1 | WIIMOTE_LED_4);

Sets the LED state for the LEDs on the Wiimote.

Does not return a value.

Accepts two arguments: the Wiimote to set LED state and
the LEDs to turn on.  All LEDs not specified will turn off.

=cut

sub set_leds
{
  my $self = shift;
  my $wiimote = shift;
  my $value = shift;
  wiiuse_set_leds($wiimote, $value);
}

=head1 motion_sensing

  $wii->motion_sensing($wiimote, 0); # turns off sensing
  $wii->motion_sensing($wiimote, 1); # turns on sensing

Sets the state of the Wiimote's motion detection.  The affects
events and the capture of the Wiimote's physical position.

Does not return a value.

Accepts two arguments: the Wiimote to set sensing and the state.

=cut

sub motion_sensing
{
  my $self = shift;
  my $wiimote = shift;
  my $state = shift;
  wiiuse_motion_sensing($wiimote, $state);
}

=head1 status

  # explain

=cut

sub status
{
  my $self = shift;
  my $wiimote = shift;
  wiiuse_status($wiimote);
}

=head1 get_by_id

  my $wiimote = $wii->get_by_id(1); # gets the $wiimote for Wiimote #1
  my $wiimote = $wii->get_by_id(7); # gets the $wiimote for Wiimote #7

Get $wiimote for the specified Wiimote number.  This number is
based on the Wiimote connection order.  It is probably best if you
use "wiimotes" to get the Wiimotes instead of this function, but this
is available in case you wish to use it.

Returns the requested Wiimote to be used in other functions.

Accepts one argument: the Wiimote to return, between 1 and the number
of Wiimotes connected.

=cut

sub get_by_id
{
  my $self = shift;
  my $unid = shift;
  return wiiuse_get_by_id($self->{WIIMOTES}, $self->{MAXMOTES}, $unid);
}

=head1 set_flags

  # explain

=cut

sub set_flags
{
  my $self = shift;
  my $wiimote = shift;
  my $enable = shift;
  my $disable = shift;
  return wiiuse_set_flags($wiimote, $enable, $disable)
}

=head1 set_smooth_alpha

  # explain

=cut

sub set_smooth_alpha
{
  my $self = shift;
  my $wiimote = shift;
  my $alpha = shift;
  return wiiuse_set_smooth_alpha($wiimote, $alpha);
}

=head1 set_orient_threshold

  # explain

=cut

sub set_orient_threshold
{
  my $self = shift;
  my $wiimote = shift;
  my $threshold = shift;
  wiiuse_set_orient_threshold($wiimote, $threshold);
}

=head1 set_accel_threshold

  # explain

=cut

sub set_accel_threshold
{
  my $self = shift;
  my $wiimote = shift;
  my $threshold = shift;
  wiiuse_set_accel_threshold($wiimote, $threshold);
}

=head1 set_nunchuk_orient_threshold

  # explain

=cut

sub set_nunchuk_orient_threshold
{
  my $self = shift;
  my $wiimote = shift;
  my $threshold = shift;
  wiiuse_set_nunchuk_orient_threshold($wiimote, $threshold);
}

=head1 set_nunchuk_accel_threshold

  # explain

=cut

sub set_nunchuk_accel_threshold
{
  my $self = shift;
  my $wiimote = shift;
  my $threshold = shift;
  wiiuse_set_nunchuk_accel_threshold($wiimote, $threshold);
}

=head1 resync

  # explain

=cut

sub resync
{
  my $self = shift;
  my $wiimote = shift;
  wiiuse_resync($wiimote);
}

=head1 set_ir

  $wii->set_ir($wiimote, 0); # turns IR off
  $wii->set_ir($wiimote, 1); # turns IR on

Sets the IR tracking state of the Wiimote.

Does not return a value.

Accepts two arguments: the Wiimote to set the IR state and the IR state.

=cut

sub set_ir
{
  my $self = shift;
  my $wiimote = shift;
  my $state = shift;
  wiiuse_set_ir($wiimote, $state);
}

=head1 set_ir_vres

  $wii->set_ir_vres($wiimote, 1024, 768);

Sets the IR virtual resolution to X by Y.  You may wish to set this to
the screen's resolution or any other value you feel necessary.

Does not return a value.

Accepts three arguments: the Wiimote to set and the X and Y values.

=cut

sub set_ir_vres
{
  my $self = shift;
  my $wiimote = shift;
  my $x = shift;
  my $y = shift;
  wiiuse_set_ir_vres($wiimote, $x, $y);
}

=head1 set_ir_position

  use constant {
    WIIUSE_IR_ABOVE => 0,
    WIIUSE_IR_BELOW => 1,
  };

  $wii->set_ir_position($wiimote, WIIUSE_IR_ABOVE); # above TV
  $wii->set_ir_position($wiimote, WIIUSE_IR_BELOW); # below TV

Sets the IR sensor bar position (above/below TV).

Accepts two arguments: the Wiimote and the IR position.

=cut

sub set_ir_position
{
  my $self = shift;
  my $wiimote = shift;
  my $position = shift;
  wiiuse_set_ir_position($wiimote, $position);
}

=head1 set_ir_sensitivity

  # explain

=cut

sub set_ir_sensitivity
{
  my $self = shift;
  my $wiimote = shift;
  my $level = shift;
  wiiuse_set_ir_sensitivity($wiimote, $level);
}

=head1 set_aspect_ratio

  use constant {
    WIIUSE_ASPECT_4_3 => 0,
    WIIUSE_ASPECT_16_9 => 1,
  };

  $wii->set_aspect_ratio($wiimote, WIIUSE_ASPECT_4_3); # 4:3 ratio
  $wii->set_aspect_ratio($wiimote, WIIUSE_ASPECT_16_9); # 16:9 ratio

Set the aspect ratio for IR.  Set this to your display's
aspect ratio.  Defaults to 4:3 if you don't set this.

Does not return a value.

Accepts two arguments: the Wiimote to set and the ratio.

=cut

sub set_aspect_ratio
{
  my $self = shift;
  my $wiimote = shift;
  my $aspect = shift;
  wiiuse_set_aspect_ratio($wiimote, $aspect);
}

=head1 state_using_accel

  if ($wii->state_using_accel($wiimote))
  {
    # .. do something requiring accel ..
  }

Returns the accel state (enabled/disabled) of the specified Wiimote.

Accepts one argument: the Wiimote to get accel state.

=cut

sub state_using_accel
{
  my $self = shift;
  my $wiimote = shift;
  return wiiuse_state_using_accel($wiimote);
}

=head1 state_using_expansion

  if ($wii->state_using_expansion($wiimote))
  {
    # .. do something requiring an expansion device (attachment) ..
  }

Returns a true or false value used to determine whether or not an
attachment (Nunchuk, Classic Controller, Guitar, etc) is attached.

Accepts one argument: the Wiimote to check attachment status.

=cut

sub state_using_expansion
{
  my $self = shift;
  my $wiimote = shift;
  return wiiuse_state_using_expansion($wiimote);
}

=head1 state_using_ir

  if ($wii->state_using_ir($wiimote))
  {
    # .. do something requiring IR ..
  }

Returns a true or false value used to determine if IR is enabled
on the specified Wiimote.

Accepts one argument: the Wiimote to check IR status.

=cut

sub state_using_ir
{
  my $self = shift;
  my $wiimote = shift;
  return wiiuse_state_using_ir($wiimote);
}

=head1 state_using_speaker

  # explain

=cut

sub state_using_speaker
{
  my $self = shift;
  my $wiimote = shift;
  return wiiuse_state_using_speaker($wiimote);
}

=head1 get_leds

  use constant {
    WIIMOTE_LED_1 => 0x10,
    WIIMOTE_LED_2 => 0x20,
    WIIMOTE_LED_3 => 0x40,
    WIIMOTE_LED_4 => 0x80,
  };

  my $leds = $wii->get_leds($wiimote);

  if ($leds & WIIMOTE_LED_3)
  {
    # .. do something if LED #3 is turned on ..
  }

Returns the state of all LEDs on the specified Wiimote.

Accepts one argument: the Wiimote to get the LED status.

=cut

sub get_leds
{
  my $self = shift;
  my $wiimote = shift;
  return wiiuse_get_leds($wiimote);
}

=head1 battery

  my $battery = $wii->battery($wiimote);
  warn "Battery in Wiimote is low!\n" if ($battery < 0.2);

Returns the battery level in the specified Wiimote.

Accepts one argument: the Wiimote to get the battery status.

=cut

sub battery
{
  my $self = shift;
  my $wiimote = shift;
  return wiiuse_battery($wiimote);
}

=head1 attachment

  use constant {
    EXP_NUNCHUK => 1,
    EXP_CLASSIC => 2,
    EXP_GH3 => 3,
  };

  my $attachment = $wii->attachment($wiimote);

  if (!$attachment)
  {
    # .. has no attachments ..
  }
  elsif ($attachment == EXP_GH3)
  {
    # .. do something that requires the Guitar ..
  }

Returns the attachment currently attached to the Wiimote.

Accepts one argument: the Wiimote to check for attachments.

=cut

sub attachment
{
  my $self = shift;
  my $wiimote = shift;
  return wiiuse_attachment($wiimote);
}

=head1 ir_distance

  my $distance = $wii->ir_distance($wiimote);

Returns a measure of distance away from the IR dots.  Requires IR tracking
turned on as well as at least two visible IR dots.

Accepts one argument: the Wiimote used as a pointing device.

=cut

sub ir_distance
{
  my $self = shift;
  my $wiimote = shift;
  return wiiuse_ir_distance($wiimote);
}

=head1 ir_dot_visible

  if ($wii->ir_dot_visible($wiimote, 2))
  {
    # .. do something that requires dot #2 to be available ..
  }

Returns true or false depending on the visibility of the specified IR dot.
The Wiimote can see a maximum of four IR dots at the same time.

Accepts two arguments: the Wiimote to test the dot and the dot number to test.

=cut

sub ir_dot_visible
{
  my $self = shift;
  my $wiimote = shift;
  my $dot = shift;
  return wiiuse_ir_dot_visible($wiimote, $dot);
}

=head1 ir_dot

  my ($x, $y) = $wii->ir_dot($wiimote, 1);

Returns the X and Y values for the specified IR dot.  Requires IR tracking turned on.

Accepts two arguments: the Wiimote and the dot number.

=cut

sub ir_dot
{
  my $self = shift;
  my $wiimote = shift;
  my $dot = shift;
  my $visible = $self->ir_dot_visible($wiimote, $dot);
  return (-1, -1) unless $visible;
  return (wiiuse_ir_dot_x($wiimote, $dot), wiiuse_ir_dot_y($wiimote, $dot));
}

=head1 ir_dots

  my @dots = $wii->ir_dots($wiimote);

Returns an array of arrayrefs for all visible IR dots for this Wiimote.
Requires IR tracking turned on.

Accepts one argument: the Wiimote to get the IR dots for.

=cut

sub ir_dots
{
  my $self = shift;
  my $wiimote = shift;
  my @dots;
  for my $dot (1 .. 4)
  {
    next unless $self->ir_dot_visible($wiimote, $dot);
    push(@dots, [$self->ir_dot($wiimote, $dot)]);
  }
  return @dots;
}

=head1 ir_cursor

  my ($x, $y) = $wii->ir_cursor($wiimote);

Returns the X and Y of the calculated Wiimote cursor based on visible IR dots.
Requires IR tracking turned on.

Accepts one argument: the Wiimote being used as a pointing device.

=cut

sub ir_cursor
{
  my $self = shift;
  my $wiimote = shift;
  return (wiiuse_ir_cursor_x($wiimote), wiiuse_ir_cursor_y($wiimote));
}

=head1 roll

  my $roll = $wii->roll($wiimote);

Returns the roll value of the Wiimote.  Requires motion detection.

Accepts one argument: the Wiimote to get the roll value.

=cut

sub roll
{
  my $self = shift;
  my $wiimote = shift;
  return (wiiuse_roll($wiimote), wiiuse_aroll($wiimote));
}

=head1 pitch

  my $pitch = $wii->pitch($wiimote);

Returns the pitch value of the Wiimote.  Requires motion detection.

Accepts one argument: the Wiimote to get the pitch value.

=cut

sub pitch
{
  my $self = shift;
  my $wiimote = shift;
  return (wiiuse_pitch($wiimote), wiiuse_apitch($wiimote));
}

=head1 yaw

  my $yaw = $wii->yaw($wiimote);

Returns the yaw value of the Wiimote.  Requires motion detection.

Accepts one argument: the Wiimote to get the yaw value.

=cut

sub yaw
{
  my $self = shift;
  my $wiimote = shift;
  return wiiuse_yaw($wiimote);
}

=head1 buttons_pressed

  use constant {
    WIIMOTE_BUTTON_TWO => 0x0001,
    WIIMOTE_BUTTON_ONE => 0x0002,
    WIIMOTE_BUTTON_B => 0x0004,
    WIIMOTE_BUTTON_A => 0x0008,
    WIIMOTE_BUTTON_MINUS => 0x0010,
    WIIMOTE_BUTTON_ZACCEL_BIT6 => 0x0020,
    WIIMOTE_BUTTON_ZACCEL_BIT7 => 0x0040,
    WIIMOTE_BUTTON_HOME => 0x0080,
    WIIMOTE_BUTTON_LEFT => 0x0100,
    WIIMOTE_BUTTON_RIGHT	 => 0x0200,
    WIIMOTE_BUTTON_DOWN => 0x0400,
    WIIMOTE_BUTTON_UP => 0x0800,
    WIIMOTE_BUTTON_PLUS => 0x1000,
    WIIMOTE_BUTTON_ZACCEL_BIT4 => 0x2000,
    WIIMOTE_BUTTON_ZACCEL_BIT5 => 0x4000,
    WIIMOTE_BUTTON_UNKNOWN => 0x8000,
    WIIMOTE_BUTTON_ALL => 0x1F9F,
  };

  my $pressed = $wii->buttons_pressed($wiimote);

  if ($pressed & WIIMOTE_BUTTON_LEFT)
  {
    # .. do something when button left is pressed ..
  }

Returns the buttons currently pressed.

Accepts one argument: the Wiimote.

=cut

sub buttons_pressed
{
  my $self = shift;
  my $wiimote = shift;
  return wiiuse_buttons_pressed($wiimote);
}

=head1 is_pressed

  # see buttons_pressed for the constants

  if ($wii->is_pressed($wiimote, WIIMOTE_BUTTON_HOME))
  {
    # .. do something when HOME button is pressed ..
  }

Returns true/false determining if a specific button is currently pressed.

Accepts two arguments: the Wiimote and the button to test.

=cut

sub is_pressed
{
  my $self = shift;
  my $wiimote = shift;
  my $button = shift;
  return ($self->buttons_pressed($wiimote) & $button);
}

=head1 buttons_held

  # see buttons_pressed for example

Similar to "buttons_pressed", but this returns the buttons that are still
pressed from a previous event.

Accepts one argument: the Wiimote.

=cut

sub buttons_held
{
  my $self = shift;
  my $wiimote = shift;
  return wiiuse_buttons_held($wiimote);
}

=head1 is_held

  # see is_pressed for example

Similar to "is_pressed", but this determines if a specific button is currently
held (still pressed from a previous event).

Accepts two arguments: the Wiimote and the button to test.

=cut

sub is_held
{
  my $self = shift;
  my $wiimote = shift;
  my $button = shift;
  return ($self->buttons_held($wiimote) & $button);
}

=head1 buttons_released

  # see buttons_pressed for example

Similar to "buttons_pressed", but this returns the buttons that were
pressed in the previous event, but are now not pressed.

Accepts one argument: the Wiimote.

=cut

sub buttons_released
{
  my $self = shift;
  my $wiimote = shift;
  return wiiuse_buttons_released($wiimote);
}

=head1 just_released

  # see is_pressed for example

Similar to "is_pressed", but this determines if a specific button was
just released (was pressed in the previous event, but now not pressed).

Accepts two arguments: the Wiimote and the button to test.

=cut

sub just_released
{
  my $self = shift;
  my $wiimote = shift;
  my $button = shift;
  return ($self->buttons_released($wiimote) & $button);
}

=head1 buttons_just_pressed

  # see buttons_pressed for example

Similar to "buttons_pressed", but this returns the buttons that were
just pressed (not pressed in the previous event).

Accepts one argument: the Wiimote.

=cut

sub buttons_just_pressed
{
  my $self = shift;
  my $wiimote = shift;
  return (wiiuse_buttons_pressed($wiimote) ^ wiiuse_buttons_held($wiimote));
}

=head1 just_pressed

  # see is_pressed for example

Similar to "is_pressed", but this determines if a specific button was
just pressed (not pressed in the previous event, but now pressed).

Accepts two arguments: the Wiimote and the button to test.

=cut

sub just_pressed
{
  my $self = shift;
  my $wiimote = shift;
  my $button = shift;
  return ($self->buttons_just_pressed($wiimote) & $button);
}

=head1 nunchuk_buttons_pressed

  use constant {
    NUNCHUK_BUTTON_Z => 0x01,
    NUNCHUK_BUTTON_C => 0x02,
    NUNCHUK_BUTTON_ALL => 0x03,
  };

See "buttons_pressed" for info.  This does the same thing, but for the Nunchuk.

=cut

sub nunchuk_buttons_pressed
{
  my $self = shift;
  my $wiimote = shift;
  return wiiuse_nunchuk_buttons_pressed($wiimote);
}

=head1 nunchuk_is_pressed

See "is_pressed" for info.  This does the same thing, but for the Nunchuk.

=cut

sub nunchuk_is_pressed
{
  my $self = shift;
  my $wiimote = shift;
  my $button = shift;
  return ($self->nunchuk_buttons_pressed($wiimote) & $button);
}

=head1 nunchuk_buttons_held

See "buttons_held" for info.  This does the same thing, but for the Nunchuk.

=cut

sub nunchuk_buttons_held
{
  my $self = shift;
  my $wiimote = shift;
  return wiiuse_nunchuk_buttons_held($wiimote);
}

=head1 nunchuk_is_held

See "is_held" for info.  This does the same thing, but for the Nunchuk.

=cut

sub nunchuk_is_held
{
  my $self = shift;
  my $wiimote = shift;
  my $button = shift;
  return ($self->nunchuk_buttons_held($wiimote) & $button);
}

=head1 nunchuk_buttons_released

See "buttons_released" for info.  This does the same thing, but for the Nunchuk.

=cut

sub nunchuk_buttons_released
{
  my $self = shift;
  my $wiimote = shift;
  return wiiuse_nunchuk_buttons_released($wiimote);
}

=head1 nunchuk_just_released

See "just_released" for info.  This does the same thing, but for the Nunchuk.

=cut

sub nunchuk_just_released
{
  my $self = shift;
  my $wiimote = shift;
  my $button = shift;
  return ($self->nunchuk_buttons_released($wiimote) & $button);
}

=head1 nunchuk_buttons_just_pressed

See "buttons_just_pressed" for info.  This does the same thing, but for the Nunchuk.

=cut

sub nunchuk_buttons_just_pressed
{
  my $self = shift;
  my $wiimote = shift;
  return (wiiuse_nunchuk_buttons_pressed($wiimote) ^ wiiuse_nunchuk_buttons_held($wiimote));
}

=head1 nunchuk_just_pressed

See "just_pressed" for info.  This does the same thing, but for the Nunchuk.

=cut

sub nunchuk_just_pressed
{
  my $self = shift;
  my $wiimote = shift;
  my $button = shift;
  return ($self->nunchuk_buttons_just_pressed($wiimote) & $button);
}

=head1 nunchuk_roll

See "roll" for info.  This does the same thing, but for the Nunchuk.

=cut

sub nunchuk_roll
{
  my $self = shift;
  my $wiimote = shift;
  return wiiuse_nunchuk_roll($wiimote);
}

=head1 nunchuk_pitch

See "pitch" for info.  This does the same thing, but for the Nunchuk.

=cut

sub nunchuk_pitch
{
  my $self = shift;
  my $wiimote = shift;
  return wiiuse_nunchuk_pitch($wiimote);
}

=head1 nunchuk_yaw

See "yaw" for info.  This does the same thing, but for the Nunchuk.

=cut

sub nunchuk_yaw
{
  my $self = shift;
  my $wiimote = shift;
  return wiiuse_nunchuk_yaw($wiimote);
}

=head1 nunchuk_joystick_angle

  my $angle = $wii->nunchuk_joystick_angle($wiimote);

Returns the angle that the Nunchuk's joystick is held.

Accepts one argument: the Wiimote with attached Nunchuk.

=cut

sub nunchuk_joystick_angle
{
  my $self = shift;
  my $wiimote = shift;
  return wiiuse_nunchuk_joystick_angle($wiimote);
}

=head1 nunchuk_joystick_magnitude

  my $angle = $wii->nunchuk_joystick_magnitude($wiimote);

Returns the magnitude (how far pressed) that the Nunchuk's joystick is held.

Accepts one argument: the Wiimote with attached Nunchuk.

=cut

sub nunchuk_joystick_magnitude
{
  my $self = shift;
  my $wiimote = shift;
  return wiiuse_nunchuk_joystick_magnitude($wiimote);
}

=head1 classic_buttons_pressed

  use constant {
    CLASSIC_BUTTON_UP => 0x0001,
    CLASSIC_BUTTON_LEFT => 0x0002,
    CLASSIC_BUTTON_ZR => 0x0004,
    CLASSIC_BUTTON_X => 0x0008,
    CLASSIC_BUTTON_A => 0x0010,
    CLASSIC_BUTTON_Y => 0x0020,
    CLASSIC_BUTTON_B => 0x0040,
    CLASSIC_BUTTON_ZL => 0x0080,
    CLASSIC_BUTTON_FULL_R => 0x0200,
    CLASSIC_BUTTON_PLUS => 0x0400,
    CLASSIC_BUTTON_HOME => 0x0800,
    CLASSIC_BUTTON_MINUS => 0x1000,
    CLASSIC_BUTTON_FULL_L => 0x2000,
    CLASSIC_BUTTON_DOWN => 0x4000,
    CLASSIC_BUTTON_RIGHT => 0x8000,
    CLASSIC_BUTTON_ALL => 0xFEFF,
  };

See "buttons_pressed" for info.  This does the same thing, but for the Classic Controller.

=cut

sub classic_buttons_pressed
{
  my $self = shift;
  my $wiimote = shift;
  return wiiuse_classic_buttons_pressed($wiimote);
}

=head1 classic_is_pressed

See "is_pressed" for info.  This does the same thing, but for the Classic Controller.

=cut

sub classic_is_pressed
{
  my $self = shift;
  my $wiimote = shift;
  my $button = shift;
  return ($self->classic_buttons_pressed($wiimote) & $button);
}

=head1 classic_buttons_held

See "buttons_held" for info.  This does the same thing, but for the Classic Controller.

=cut

sub classic_buttons_held
{
  my $self = shift;
  my $wiimote = shift;
  return wiiuse_classic_buttons_held($wiimote);
}

=head1 classic_is_held

See "is_held" for info.  This does the same thing, but for the Classic Controller.

=cut

sub classic_is_held
{
  my $self = shift;
  my $wiimote = shift;
  my $button = shift;
  return ($self->classic_buttons_held($wiimote) & $button);
}

=head1 classic_buttons_released

See "buttons_released" for info.  This does the same thing, but for the Classic Controller.

=cut

sub classic_buttons_released
{
  my $self = shift;
  my $wiimote = shift;
  return wiiuse_classic_buttons_released($wiimote);
}

=head1 classic_just_released

See "just_released" for info.  This does the same thing, but for the Classic Controller.

=cut

sub classic_just_released
{
  my $self = shift;
  my $wiimote = shift;
  my $button = shift;
  return ($self->classic_buttons_released($wiimote) & $button);
}

=head1 classic_buttons_just_pressed

See "buttons_just_pressed" for info.  This does the same thing, but for the Classic Controller.

=cut

sub classic_buttons_just_pressed
{
  my $self = shift;
  my $wiimote = shift;
  return (wiiuse_classic_buttons_pressed($wiimote) ^ wiiuse_classic_buttons_held($wiimote));
}

=head1 classic_just_pressed

See "just_pressed" for info.  This does the same thing, but for the Classic Controller.

=cut

sub classic_just_pressed
{
  my $self = shift;
  my $wiimote = shift;
  my $button = shift;
  return ($self->classic_buttons_just_pressed($wiimote) & $button);
}

=head1 classic_shoulder_left

  my $left_magnitude = $wii->classic_shoulder_left($wiimote);

Returns the magnitude (how far depressed) of the left shoulder button
on the Classic Controller.

Accepts one argument: the Wiimote with attached Classic Controller.

=cut

sub classic_shoulder_left
{
  my $self = shift;
  my $wiimote = shift;
  return wiiuse_classic_shoulder_left($wiimote);
}

=head1 classic_shoulder_right

See "classic_shoulder_left" for info.  This does the same thing, but for the right button.

=cut

sub classic_shoulder_right
{
  my $self = shift;
  my $wiimote = shift;
  return wiiuse_classic_shoulder_right($wiimote);
}

=head1 classic_joystick_left_angle

See "nunchuk_joystick_angle" for info.  This does the same thing, but for the Classic
Controller's left joystick.

=cut

sub classic_joystick_left_angle
{
  my $self = shift;
  my $wiimote = shift;
  return wiiuse_classic_joystick_left_angle($wiimote);
}

=head1 classic_joystick_left_magnitude

See "nunchuk_joystick_magnitude" for info.  This does the same thing, but for the Classic
Controller's left joystick.

=cut

sub classic_joystick_left_magnitude
{
  my $self = shift;
  my $wiimote = shift;
  return wiiuse_classic_joystick_left_magnitude($wiimote);
}

=head1 classic_joystick_right_angle

See "nunchuk_joystick_angle" for info.  This does the same thing, but for the Classic
Controller's right joystick.

=cut

sub classic_joystick_right_angle
{
  my $self = shift;
  my $wiimote = shift;
  return wiiuse_classic_joystick_right_angle($wiimote);
}

=head1 classic_joystick_right_magnitude

See "nunchuk_joystick_magnitude" for info.  This does the same thing, but for the Classic
Controller's right joystick.

=cut

sub classic_joystick_right_magnitude
{
  my $self = shift;
  my $wiimote = shift;
  return wiiuse_classic_joystick_right_magnitude($wiimote);
}

=head1 gh3_buttons_pressed

  use constant {
    GH3_BUTTON_STRUM_UP => 0x0001,
    GH3_BUTTON_YELLOW => 0x0008,
    GH3_BUTTON_GREEN => 0x0010,
    GH3_BUTTON_BLUE => 0x0020,
    GH3_BUTTON_RED => 0x0040,
    GH3_BUTTON_ORANGE => 0x0080,
    GH3_BUTTON_PLUS => 0x0400,
    GH3_BUTTON_MINUS => 0x1000,
    GH3_BUTTON_STRUM_DOWN => 0x4000,
    GH3_BUTTON_ALL => 0xFEFF,
  };

See "buttons_pressed" for info.  This does the same thing, but for the Guitar.

=cut

sub gh3_buttons_pressed
{
  my $self = shift;
  my $wiimote = shift;
  return wiiuse_gh3_buttons_pressed($wiimote);
}

=head1 gh3_is_pressed

See "is_pressed" for info.  This does the same thing, but for the Guitar.

=cut

sub gh3_is_pressed
{
  my $self = shift;
  my $wiimote = shift;
  my $button = shift;
  return ($self->gh3_buttons_pressed($wiimote) & $button);
}

=head1 gh3_buttons_held

See "buttons_held" for info.  This does the same thing, but for the Guitar.

=cut

sub gh3_buttons_held
{
  my $self = shift;
  my $wiimote = shift;
  return wiiuse_gh3_buttons_held($wiimote);
}

=head1 gh3_is_held

See "is_held" for info.  This does the same thing, but for the Guitar.

=cut

sub gh3_is_held
{
  my $self = shift;
  my $wiimote = shift;
  my $button = shift;
  return ($self->gh3_buttons_held($wiimote) & $button);
}

=head1 gh3_buttons_released

See "buttons_released" for info.  This does the same thing, but for the Guitar.

=cut

sub gh3_buttons_released
{
  my $self = shift;
  my $wiimote = shift;
  return wiiuse_gh3_buttons_released($wiimote);
}

=head1 gh3_just_released

See "just_released" for info.  This does the same thing, but for the Guitar.

=cut

sub gh3_just_released
{
  my $self = shift;
  my $wiimote = shift;
  my $button = shift;
  return ($self->gh3_buttons_released($wiimote) & $button);
}

=head1 gh3_buttons_just_pressed

See "buttons_just_pressed" for info.  This does the same thing, but for the Guitar.

=cut

sub gh3_buttons_just_pressed
{
  my $self = shift;
  my $wiimote = shift;
  return (wiiuse_gh3_buttons_pressed($wiimote) ^ wiiuse_gh3_buttons_held($wiimote));
}

=head1 gh3_just_pressed

See "just_pressed" for info.  This does the same thing, but for the Guitar.

=cut

sub gh3_just_pressed
{
  my $self = shift;
  my $wiimote = shift;
  my $button = shift;
  return ($self->gh3_buttons_just_pressed($wiimote) & $button);
}

=head1 gh3_whammy

  my $whammy_magnitude = $wii->gh3_whammy($wiimote);

Returns the magnitude (how far depressed) of the whammy bar on the Guitar.

Accepts one argument: the Wiimote with attached Guitar.

=cut

sub gh3_whammy
{
  my $self = shift;
  my $wiimote = shift;
  return wiiuse_gh3_whammy($wiimote);
}

=head1 gh3_joystick_angle

See "nunchuk_joystick_angle" for info.  This does the same thing, but for the Guitar.

=cut

sub gh3_joystick_angle
{
  my $self = shift;
  my $wiimote = shift;
  return wiiuse_gh3_joystick_angle($wiimote);
}

=head1 gh3_joystick_magnitude

See "nunchuk_joystick_magnitude" for info.  This does the same thing, but for the Guitar.

=cut

sub gh3_joystick_magnitude
{
  my $self = shift;
  my $wiimote = shift;
  return wiiuse_gh3_joystick_magnitude($wiimote);
}

1;

__END__

=head1 SEE ALSO

libwiiuse: http://www.wiiuse.net/

=head1 TODO

  * Finish this documentation.
  * Provide good example usage.
  * Allow constants to be exported.

=head1 AUTHOR

Dusty Wilson
Megagram Managed Technical Services

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Dusty Wilson

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
