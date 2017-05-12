
# EventHandler for Games::Irrlicht - used to register callbacks for events

package Games::Irrlicht::EventHandler;

# (C) by Tels <http://bloodgate.com/>

use strict;

require Exporter;
use Games::Irrlicht::Thingy;
use vars qw/@ISA $VERSION @EXPORT_OK/;
@ISA = qw/Games::Irrlicht::Thingy Exporter/;

@EXPORT_OK = qw/char2key char2type_kind FPS_EVENT/;

$VERSION = '0.04';

##############################################################################
# constants

sub FPS_EVENT () { -1; }

sub BUTTON_MOUSE_LEFT ()        { 1; }
sub BUTTON_MOUSE_RIGHT ()       { 4; }
sub BUTTON_MOUSE_MIDDLE ()      { 2; }
sub BUTTON_MOUSE_WHEEL_DOWN ()  { 8; }
sub BUTTON_MOUSE_WHEEL_UP ()    { 16; }

##############################################################################
# methods

sub _init
  {
  my $self = shift;

  $self->{type} = shift;
  $self->{kind} = shift;
  $self->{callback} = shift;
  
  $self->{args} = [ @_ ];

  $self->_init_mod();
  }

my $remap = {
#  SDLK_LSHIFT() => KMOD_LSHIFT,
#  SDLK_RSHIFT() => KMOD_RSHIFT,
#  SDLK_LCTRL() => KMOD_LCTRL,
#  SDLK_RCTRL() => KMOD_RCTRL,
#  SDLK_LALT() => KMOD_LALT,
#  SDLK_RALT() => KMOD_RALT,
  };

sub _init_mod
  { 
  my $self = shift;

  $self->{mod} = { };
  if (ref($self->{kind}) eq 'ARRAY')
    {
    # [ SLDK_a, SLDK_LSHIFT, ... ]
    my $mod = $self->{kind};
    $self->{kind} = $mod->[0];
    shift @{$mod};
    # convert @$mod to %$mod
    foreach my $m (@$mod)
      {
      if (exists $remap->{$m})
        {
        # silently remap SLDK_LSHIFT => KMOD_LSHIFT
        $self->{mod}->{$remap->{$m}} = 1;
        }
      else
        { 
        $self->{mod}->{$m} = 1;
        }
      }
    $self->{ignore_mod} = 0;			# don't ignore additionals
    }
  else
    {
    $self->{ignore_mod} = 1;			# do ignore additionals
    }
  $self->{require_all} = 0;			# don't require all of them
  $self;
  }

sub ignore_additional_modifiers
  {
  my $self = shift;

  if (@_ > 0)
    { 
    $self->{ignore_mod} = $_[0] ? 1 : 0;
    }
  $self->{ignore_mod};			
  }

sub require_all_modifiers
  {
  my $self = shift;

  if (@_ > 0)
    { 
    $self->{require_all} = $_[0] ? 1 : 0;
    }
  $self->{require_all};			
  }

sub check
  {
  # check whether the event matched the occured event or not
  my ($self,$event,$type,$key) = @_;

  return if $self->{active} == 0;

  return unless $type == $self->{type};

#  if ($type == FPS_EVENT || $type == SDL_KEYDOWN || $type == SDL_KEYUP)
#    {
#    return unless $key eq $self->{kind};
#    }
#  elsif ($type == SDL_MOUSEBUTTONUP || $type == SDL_MOUSEBUTTONDOWN)
#    {
#    # watch for more than one button with one event:
#    return if ($self->{kind} & $key) == 0;
#    }

  my $required = 0;
  # find out which modifiers (these we watch) are pressed
  my $mods = $event->key_mod();
  foreach my $mod (keys %{$self->{mod}})
    {
    # this watched one is pressed
    if (($mods & $mod) != 0)
      {
      $required++;
      $mods -= $mod;				# eliminate this bit
      }
    }
  
  if ($self->{ignore_mod} != 1)
    {
    # $mods != 0 if there were additional modifiers and we don't ignore this
    return if $mods != 0;
    }


  # if not all of the required ones were pressed, and we require all
  return if $self->{require_all} != 0 &&
    $required != scalar keys %{$self->{mod}};
  
  # when we watch some modifiers, at least one must be pressed
  return if $required == 0 && scalar keys %{$self->{mod}} != 0;

  # event happened, so call callback
  &{$self->{callback}}($self->{app},$self,$event,@{$self->{args}});
  }

sub rebind ($$$)
  {
  my ($self) = shift;

  my $old_type = $self->{type};
  $self->{type} = shift;
  $self->{kind} = shift;
  $self->_init_mod();
  $self->{app}->_rebound_event_handler($self,$old_type);
  $self; 
  }

sub type ()
  {
  # return the type this event handler watches out for
  my $self = shift;
  $self->{type};
  }

sub kind ()
  {
  # return the kind this event handler watches out for
  my $self = shift;
  $self->{kind};
  }

my $char2key = {
#  a => SDLK_a,
#  b => SDLK_b,
#  c => SDLK_c,
#  d => SDLK_d,
#  e => SDLK_e,
#  f => SDLK_f,
#  g => SDLK_g,
#  h => SDLK_h,
#  i => SDLK_i,
#  j => SDLK_j,
#  k => SDLK_k,
#  l => SDLK_l,
#  m => SDLK_m,
#  n => SDLK_n,
#  o => SDLK_o,
#  p => SDLK_p,
#  q => SDLK_q,
#  r => SDLK_r,
#  s => SDLK_s,
#  t => SDLK_t,
#  u => SDLK_u,
#  v => SDLK_v,
#  w => SDLK_w,
#  x => SDLK_x,
#  y => SDLK_y,
#  z => SDLK_z,
  
#  A => [ SDLK_a, KMOD_SHIFT ],
#  B => [ SDLK_b, KMOD_SHIFT ],
#  C => [ SDLK_c, KMOD_SHIFT ],
#  D => [ SDLK_d, KMOD_SHIFT ],
#  E => [ SDLK_e, KMOD_SHIFT ],
#  F => [ SDLK_f, KMOD_SHIFT ],
#  G => [ SDLK_g, KMOD_SHIFT ],
#  H => [ SDLK_h, KMOD_SHIFT ],
#  I => [ SDLK_i, KMOD_SHIFT ],
#  J => [ SDLK_j, KMOD_SHIFT ],
#  K => [ SDLK_k, KMOD_SHIFT ],
#  L => [ SDLK_l, KMOD_SHIFT ],
#  M => [ SDLK_m, KMOD_SHIFT ],
#  N => [ SDLK_n, KMOD_SHIFT ],
#  O => [ SDLK_o, KMOD_SHIFT ],
#  P => [ SDLK_p, KMOD_SHIFT ],
#  Q => [ SDLK_q, KMOD_SHIFT ],
#  R => [ SDLK_r, KMOD_SHIFT ],
#  S => [ SDLK_s, KMOD_SHIFT ],
#  T => [ SDLK_t, KMOD_SHIFT ],
#  U => [ SDLK_u, KMOD_SHIFT ],
#  V => [ SDLK_v, KMOD_SHIFT ],
#  W => [ SDLK_w, KMOD_SHIFT ],
#  X => [ SDLK_x, KMOD_SHIFT ],
#  Y => [ SDLK_y, KMOD_SHIFT ],
#  Z => [ SDLK_z, KMOD_SHIFT ],

#  0 => SDLK_0,
#  1 => SDLK_1,
#  2 => SDLK_2,
#  3 => SDLK_3,
#  4 => SDLK_4,
#  5 => SDLK_5,
#  6 => SDLK_6,
#  7 => SDLK_7,
#  8 => SDLK_8,
#  9 => SDLK_9,

#  '!' => [ SDLK_1, KMOD_SHIFT ],
#  '"' => [ SDLK_2, KMOD_SHIFT ],
#  '§' => [ SDLK_3, KMOD_SHIFT ],
#  '$' => [ SDLK_4, KMOD_SHIFT ],
#  '%' => [ SDLK_5, KMOD_SHIFT ],
#  '&' => [ SDLK_6, KMOD_SHIFT ],
#  '/' => [ SDLK_7, KMOD_SHIFT ],
#  '(' => [ SDLK_7, KMOD_SHIFT ],
#  ')' => [ SDLK_8, KMOD_SHIFT ],
#  '=' => [ SDLK_0, KMOD_SHIFT ],
#  '_' => [ SDLK_MINUS, KMOD_SHIFT ],
#  ';' => [ SDLK_COMMA, KMOD_SHIFT ],
#  ':' => [ SDLK_PERIOD, KMOD_SHIFT ],
#  '>' => [ SDLK_LESS, KMOD_SHIFT ],
#  '*' => [ SDLK_PLUS, KMOD_SHIFT ],
#  '@' => [ SDLK_q, KMOD_RALT ],

  };

# if we define these in $char2key, we could skip the costly eval. OTOH, the
# eval will be done only once, while $char2key wastes memory...

#        SDLK_END SDLK_EQUALS SDLK_ESCAPE SDLK_EURO SDLK_EXCLAIM SDLK_F1
#        SDLK_F10 SDLK_F11 SDLK_F12 SDLK_F13 SDLK_F14 SDLK_F15 SDLK_F2 SDLK_F3
#        SDLK_F4 SDLK_F5 SDLK_F6 SDLK_F7 SDLK_F8 SDLK_F9 SDLK_GREATER
#        SDLK_HASH SDLK_HELP SDLK_HOME SDLK_INSERT SDLK_KP0 SDLK_KP1 SDLK_KP2
#        SDLK_KP3 SDLK_KP4 SDLK_KP5 SDLK_KP6 SDLK_KP7 SDLK_KP8 SDLK_KP9
#        SDLK_KP_DIVIDE SDLK_KP_ENTER SDLK_KP_EQUALS SDLK_KP_MINUS
##        SDLK_KP_MULTIPLY SDLK_KP_PERIOD SDLK_KP_PLUS SDLK_LALT SDLK_LCTRL
#        SDLK_LEFT SDLK_LEFTBRACKET SDLK_LEFTPAREN SDLK_LESS SDLK_LMETA
#        SDLK_LSHIFT SDLK_LSUPER SDLK_MENU SDLK_MINUS SDLK_MODE SDLK_NUMLOCK
#        SDLK_PAGEDOWN SDLK_PAGEUP SDLK_PAUSE SDLK_PERIOD SDLK_PLUS SDLK_POWER
#        SDLK_PRINT SDLK_QUESTION SDLK_QUOTE SDLK_QUOTEDBL SDLK_RALT
##        SDLK_RCTRL SDLK_RETURN SDLK_RIGHT SDLK_RIGHTBRACKET SDLK_RIGHTPAREN
#        SDLK_RMETA SDLK_RSHIFT SDLK_RSUPER SDLK_SCROLLOCK SDLK_SEMICOLON
#        SDLK_SLASH SDLK_SPACE SDLK_SYSREQ SDLK_TAB SDLK_UNDERSCORE SDLK_UP

sub char2key
  {
  # convert a character like 'a' to a key event like SDLK_a
  my $char = shift;

  return $char2key->{$char} if exists $char2key->{$char};
  if ($char =~ /^[A-Z]A-Z+/)
    {
    return eval "SDLK_$char()";
    }
  return;  
  }

sub char2type_kind
  {
  # convert a character like 'a' to a key event like SDLK_a
  # and a string like "PRINT" to SDL_KEYDOWN, SDLK_PRINT
  my $key = shift;

#  my $type = SDL_KEYDOWN;
#  if ($key =~ /^([LMR]MB|MWD|MWU)$/)
#    {
#    $type = SDL_MOUSEBUTTONDOWN;
#    if ($key eq 'LMB')
#      {
#      $key = BUTTON_MOUSE_LEFT;
#      }
#    elsif ($key eq 'RMB')
#      {
#      $key = BUTTON_MOUSE_RIGHT;
#      }
#    elsif ($key eq 'MMB')
#      {
#      $key = BUTTON_MOUSE_MIDDLE;
#      }
#    elsif ($key eq 'MWU')
#      {
#      $key = BUTTON_MOUSE_WHEEL_UP;
#      }
#    elsif ($key eq 'MWD')
#      {
#      $key = BUTTON_MOUSE_WHEEL_DOWN;
#      }
#    return ($type, $key);
#    }
#
#  return ($type,$char2key->{$key}) if exists $char2key->{$key};
#  my $char = eval "SDLK_$key()"; 
#  return ($type, $char);
  return (undef,undef);
  }

1;

__END__

=pod

=head1 NAME

Games::Irrlicht::EventHandler - an event handler class for Games::Irrlicht

=head1 SYNOPSIS

	my $handler = Games::Irrlicht::EventHandler->new( $app,
		SDL_KEYDOWN,
		SDLK_SPACE,
		sub { my $self = shift; $self->pause(); },
	};

	my $handler2 = Games::Irrlicht::EventHandler->new( $app,
		SDL_MOUSEBUTTONDOWN,
		LEFTMOUSEBUTTON,
		sub { my $self = shift; $self->time_warp(2,2000); },
	};

=head1 DESCRIPTION

This package provides an event handler class.

Event handlers are register to watch out for certain external events like
keypresses, mouse movements and so on, and when these happen, call a callback
routine.

=head1 CALLBACK

Once the event has occured, the callback code (CODE ref) is called with the
following parameters:

	&{$callback}($self,$handler,$event);

C<$self> is the app the event handler resides in (e.g. the object of type
Games::Irrlicht or a subclass), C<$handler> is the event handler itself, and
C<$event> the event that caused the handler to be activated.

=head1 METHODS

=over 2

=item new()

	my $handler = Games::Irrlicht::EventHandler->new(
		$app,
		$type,
		$kind,
		$callback,
	);

Creates a new event handler to watch out for $type events (SDL_KEYDOWN,
SDL_MOUSEMOVED, SDL_MOUSEBUTTONDOWN etc) and then for $kind kind of it,
like SDLK_SPACE. Mouse movement events ignore the $kind parameter.

C<$app> is the ref to the application the handler resides in and is passed
as first argument to the callback function when called.

Please note that this event handler B<only> triggers when this key or
button is pressed, regardless of any additional key modifier like SHIFT
beeing pressed. See below for how to change this.

C<$kind> can also be an array ref. This is used to pass a key plus one or
more modifiers that need to be pressed to trigger the event. The default is
that all listed modifiers must be pressed and additional modifiers are not
ignored, e.g. they cause the event not to trigger:

	my $handler = SDL::App::FPS::EventHandler->new(
		$app,
		SLD_KEYDOWN,
		[ SDLK_a, KMOD_LSHIFT ],
		$callback
	);

The list of valid modifiers is:

	KMOD_NUM
        KMOD_CAPS
	KMOD_LCTRL
	KMOD_RCTRL
        KMOD_RSHIFT
	KMOD_LSHIFT
	KMOD_RALT
        KMOD_LALT

These shortcuts exists:

	KMOD_CTRL
	KMOD_SHIFT
        KMOD_ALT

This would only trigger when 'a' and left shift are pressed together.

	my $handler = SDL::App::FPS::EventHandler->new(
		$app,
		SLD_KEYDOWN,
		[ SDLK_a, KMOD_LSHIFT, KMOD_RSHIFT ],
		$callback
	);

This would only trigger when 'a' B<and> left shift B<and> right shift are
pressed together.
	
	my $handler = SDL::App::FPS::EventHandler->new(
		$app,
		SLD_KEYDOWN,
		[ SDLK_a, KMOD_LSHIFT, KMOD_RSHIFT ],
		$callback
	);
	$handler->require_all_modifiers(0);

This would only trigger when 'a' and one of left shift B<or> right shift are
pressed together (but no additional modifiers), but not when 'a' without left
and right shift is pressed (e.g. neither C<a> nor C<Ctrl+a> nor C<Ctrl+a+left
shift> would count).
	
	my $handler = SDL::App::FPS::EventHandler->new(
		$app,
		SLD_KEYDOWN,
		[ SDLK_a, KMOD_LSHIFT, KMOD_RSHIFT ],
		$callback
	);
	$handler->ignore_additional_modifiers(0);

This would only trigger when 'a' B<and> left shift B<and> right shift are
pressed together, and additional modifiers will be ignored.
E.g. neither C<left shift+a> nor C<right shift+a> would count, however,
C<left ctrl + a + left shift + right shift> would count.

When passing only one key as C<$kind>, ignore_additional_key_modifiers() will
be set to true as default.

See L<require_all_key_modifiers> and L<ignore_additional_key_modifiers> for
changing the default behaviour.

=item is_active()

	$handler->is_active();

Returns true if the event handler is active, or false for inactive. Inactive
event handlers ignore any events that might happen.

=item activate()

Set the event handler to active. Newly created ones are always active.

=item deactivate()

Set the event handler to inactive. Newly created ones are always active.

=item rebind()

	$handler->rebind(SDL_KEYUP, SDLK_P);

Set a new type and kind for the handler to watch out for.

C<rebind()> will reset L<require_all_modifiers()> and
L<ignore_additional_modifiers()> to the defaults like new() does.

=item require_all_modifiers()

	$eventhandler->require_all_modifiers(1);
	if ($eventhandler->require_all_modifiers())
	  {
	  ...
	  }

Returns true or false. When passed an argument, sets a flag on whether this
handlers requires all set key modifiers or not. When set to false, only one
or some of the set key modifiers (SDLK_LSHIFT, SDLK_RCTRL etc) must be pressed
to trigger the callback. When set to true, all of them must be pressed.

=item ignore_additional_modifiers()

	$eventhandler->ignore_additional_modifiers(1);
	if ($eventhandler->ignore_additional_modifiers())
	  {
	  ...
	  }

Returns true or false. When passed an argument, sets a flag on whether this
handlers ignores additional key modifiers. When set to false, only one
or some of the set key modifiers (depending on require_all_modifiers())
(like SDLK_LSHIFT, SDLK_RCTRL etc) must be pressed to trigger the callback and
no additional modifiers can be pressed.  When set to true, additional
modifiers can be pressed and the event still triggers.

=item id()

Return the handler's unique id.

=item char2key()

	$sdl_key = char2key($char);
	$sdl_key_a = char2key('a');

Converts a character like C<'a'> to a SDL key like C<SDLK_a>.

=item char2type_kind()

	($type,$sdl_key) = char2type_kind($char);
	($type,$sdl_key) = char2type_kind('a');
	($type,$sdl_key) = char2type_kind('PRINT');
	($type,$sdl_key) = char2type_kind('ENTER');
	($type,$sdl_key) = char2type_kind('LMB');	# left mouse button

Converts a character like C<'a'> to a SDL key like C<SDLK_a>, and also returns
the type (SDL_KEYDOWN or SDL_MOUSEBUTTONDOWN).

=back

=head1 AUTHORS

(c) 2002, 2003, 2004, Tels <http://bloodgate.com/>

=head1 SEE ALSO

L<Games::Irrlicht>

=cut

