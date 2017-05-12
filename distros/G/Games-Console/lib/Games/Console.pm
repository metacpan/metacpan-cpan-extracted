
# Games-Console - a 2D quake-style console

package Games::Console;

# (C) by Tels <http://bloodgate.com/>

use strict;
use vars qw/$VERSION/;

$VERSION = '0.04';

##############################################################################
# methods

sub new
  {
  # create a new console
  my $class = shift;

  my $self = { };
  bless $self, $class;
  
  my $args = $_[0];
  $args = { @_ } unless ref $args eq 'HASH';

  $self->{background_color} = $args->{background} || [0.4, 0.6, 1];
  $self->{background_alpha} = $args->{background_alpha} || 0.5;

  $self->{text_color} = $args->{text_color} || [ 0.4, 0.6, 0.8 ];
  $self->{text_alpha} = $args->{text_alpha} || 0.8;
  
  $self->{max_msg} = $args->{backbuffer_size} || 100;
  
  $self->{font} = $args->{font};

  # maximum height/width in percent
  $self->{width} = abs($self->{width} || 100);
  $self->{height} = abs($args->{height} || 50);
  $self->{width} = 100 if $self->{width} > 100;
  $self->{height} = 100 if $self->{height} > 100;
  
  $self->{screen_width} = 640;
  $self->{screen_height} = 480;
  
  $self->{direction} = 1;
  # in percent per second (50 means it takes 2 seconds to open console)
  $self->{speed} = 50;
  
  $self->{start_percent} = 0;		# started moving at this percentage
  $self->{start_time} = 0;		# and this time
  $self->{cur_percent} = 0;		# cur percent visible

  $self->{messages} = [];
  
  $self->{spacing_y} = 0;
  $self->{border_x} = 5;
  $self->{border_y} = 5;
  $self->{prompt} = $args->{prompt} || '> ';
  $self->{cursor} = $args->{cursor} || '_';
  
  $self->{offset} = 0;
  
  $self->{last_cursor} = 0;
  $self->{cursor_time} = abs($args->{cursor_time} || 300);
  
  $self->{current_input} = '';	# what user entered until ENTER key is pressed
  $self->{last_input} = [ ];	
  $self->{last_input_pos} = 0;	
  $self->{max_last_input} = 64;	

  $self->{cur_height} = 0;	# invisble
  $self;
  }

sub close
  {
  my $self = shift;

  $self->{direction} = -1 if $self->{visible};
  }

sub open
  {
  my $self = shift;

  $self->{direction} = 1; $self->{visible} = 1;
  $self->{start_time} = shift;
  $self->{start_percent} = $self->{cur_percent};
  }

sub toggle
  {
  my $self = shift;

  if (!$self->{visible})
    {
    $self->{direction} = 1; $self->{visible} = 1;
    }
  else
    {
    $self->{direction} = - $self->{direction};
    $self->{direction} = -1 if $self->{direction} == 0;
    }
  $self->{start_time} = shift;
  $self->{start_percent} = $self->{cur_percent};
  }

sub visible
  {
  # make immidiately visible/invisible
  my $self = shift;

  if (@_ > 0)
    {
    my $v = $_[0] ? 1 : 0;
    if ($self->{visible} && !$v)
      {
      $self->{direction} = 0;
      $self->{cur_percent} = 0;
      }
    elsif (!$self->{visible} && $v)
      {
      $self->{direction} = 1;
      $self->{start_percent} = 0;
      $self->{start_time} = shift;
      }
    $self->{visible} = $v;
    }
  $self->{visible};
  }

sub render
  {
  my ($self,$current_time) = @_;

  return unless $self->{visible};

  if ($self->{direction} != 0)
    {
    $self->{cur_percent} = $self->{start_percent} + 
       $self->{direction} * ($current_time - $self->{start_time}) *
       $self->{speed} / 100;
    }

  if ($self->{cur_percent} < 0)
    {
    # fully closed
    $self->{cur_percent} = 0;
    $self->{start_percent} = 0;
    $self->{direction} = 0;
    $self->{visible} = 0;
    return;
    }

  if ($self->{cur_percent} > 100)
    {
    # fully open
    $self->{cur_percent} = 100;
    $self->{direction} = 0;
    }
  
  # calculate height/width
  my $w = $self->{width} * $self->{screen_width} / 100;
  my $h = ($self->{cur_percent} / 100) 
          * $self->{height} * $self->{screen_height} / 100;

  $self->_render( 0, $self->{screen_height}, $w, $h, $current_time );

  }

sub _render
  {
  # prepare the output, render the background and the text
  my ($self,$x,$y,$w,$h,$time) = @_;

  }

sub message
  {
  my ($self,$msg) = @_;

  my $m = $self->{messages};			# shortcut

  push @$m, [ $msg ];

  shift @$m while (scalar @$m > $self->{max_msg});
  
  $self;
  }

sub screen_width
  {
  my $self = shift;

  if (@_ > 0)
    {
    $self->{screen_width} = $_[0];
    $self->{font}->screen_width($_[0]);
    }
  $self->{screen_width};
  }

sub screen_height
  {
  my $self = shift;

  if (@_ > 0)
    {
    $self->{screen_height} = $_[0];
    $self->{font}->screen_height($_[0]);
    }
  $self->{screen_height};
  }

sub background_color
  {
  my $self = shift;

  $self->{background_color} = shift if @_ > 0;
  $self->{background_color};
  }

sub text_color
  {
  my $self = shift;

  $self->{text_color} = shift if @_ > 0;
  $self->{text_color};
  }

sub background_alpha
  {
  my $self = shift;

  $self->{background_alpha} = shift if @_ > 0;
  $self->{background_alpha};
  }

sub text_alpha
  {
  my $self = shift;

  $self->{text_alpha} = shift if @_ > 0;
  $self->{text_alpha};
  }

sub width
  {
  my $self = shift;

  if (@_ > 0)
    {
    $self->{width} = abs(shift);
    $self->{width} = 100 if $self->{width} > 100;
    }
  $self->{width};
  }

sub height
  {
  my $self = shift;

  if (@_ > 0)
    {
    $self->{height} = abs(shift);
    $self->{height} = 100 if $self->{height} > 100;
    }
  $self->{height};
  }

sub speed
  {
  my $self = shift;

  if (@_ > 0)
    {
    $self->{speed} = abs(shift);
    $self->{speed} = 100 if $self->{speed} > 100;
    }
  $self->{speed};
  }

sub backbuffer_size
  {
  my $self = shift;

  $self->{max_msg} = abs(shift) if @_ > 0;
  $self->{max_msg};
  }

sub cursor
  {
  my $self = shift;

  $self->{cursor} = $_[0] if @_ > 0;
  $self->{cursor};
  }

sub prompt
  {
  my $self = shift;

  $self->{prompt} = $_[0] if @_ > 0;
  $self->{prompt};
  }

sub backspace
  {
  my $self = shift;

  if ($self->{current_input} ne '')
    {
    substr($self->{current_input},-1,1) = '';
    }
  $self->{current_input};
  }

sub autocomplete
  {
  my $self = shift;
  
  $self->{last_input_pos} = 0;	
  }

sub input
  {
  # get/set the current_input buffer
  my $self = shift;

  if (@_ > 0)
    {
    my $m = $self->{last_input};
    unshift @$m, $self->{current_input}; 
    pop @$m while (scalar @$m > $self->{max_last_input});
    $self->{current_input} = $_[0];
    $self->{last_input_pos} = 0;	
    }
  $self->{current_input};
  }

sub last_input
  {
  # set the current_input buffer to the last entered input
  my $self = shift;
  my $dir = shift || 0;

  my $m = $self->{last_input};

  my $pos = $self->{last_input_pos};
  if ($pos < 0 || $pos >= scalar @$m)
    {
    $self->{current_input} = ''; 
    }
  else
    {
    $self->{current_input} = $m->[$pos] if scalar @$m > 0;
    }
  if ($dir >= 0)
    {
    $pos++ if $pos < scalar @$m;
    }
  else
    {
    $pos-- if $pos >= 0;
    }
  $self->{last_input_pos} = $pos;
  $self->{current_input};
  }

sub add_input
  {
  # add more text to the current_input buffer
  my $self = shift;

  $self->{current_input} .= $_[0];
  }

sub scroll
  {
  my ($self,$ofs) = @_;

  $self->{offset} += $ofs;
  print $self->{offset},"\n";
  $self->{offset} = 0 if $self->{offset} < 0;
  $self->{offset} = scalar @{$self->{messages}}
   if $self->{offset} >= scalar @{$self->{messages}};
  print $self->{offset},"\n";
  $self->{offset};
  }

sub offset
  {
  my ($self) = @_;

  $self->{offset};
  }

sub messages
  { 
  # return number of messages in backbuffer
  my $self = shift;

  scalar @{$self->{messages}};
  }

sub clear
  {
  # clear backbuffer
  my $self = shift;

  $self->{messages} = [];
  $self;
  }

1;

__END__

=pod

=head1 NAME

Games::Console - provide a 2D quake style in-game console

=head1 SYNOPSIS

	use Games::Console;

	my $console = Games::Console->new(
	  font => $font_object,
	  background_color => [ 1,1,0],
	  background_alpha => 0.4,
	  text_color => [ 1,1,1 ],
	  text_alpha => 1,
          speed => 50,			# in percent per second
	  height => 50,			# fully opened, in percent of screen
	  width => 100,			# fully opened, in percent of screen
	  backbuffer_size => 100,	# keep so many messages
	  prompt => ' >',
	  cursor => '_',
	);

	$console->screen_width($width);
	$console->screen_height($height);
	$console->toggle($current_time);
	$console->message('Hello there!');
	$console->input('a');

=head1 EXPORTS

Exports nothing on default. 

=head1 DESCRIPTION

This package provides you with a quake-style console for your games. The
console gathers messages and let's you scroll trough them. It also can
display a command line.

This package is just a base class setting up everything,
but doesn't actually render anything.

See Games::Console::SDL and Games::Console::OpenGL for subclasses that
implement the actual rendering to the screen via SDL and OpenGL, respectively.

=head1 METHODS

=over 2

=item new()

	my $console = Games::Console->new( $args );

Create a new console. Typically, you have only one.

C<$args> is a hash ref containing the following keys:

	logfile			where to log messages
	loglevel		the log level (e.g. what to log)
	text_color		color of output text as array ref [r,g,b]
	text_alpha		blend font over background for semitransparent
	background_color	color of background as array ref [r,g,b]
	background_alpha	blend console background over screen background

=item message()

	$console->message($message);

Append a message to the console's buffer.

=item render()

	$console->render ( $current_time );

If the console is currently visible, render it.

=item add_input()

	$console->add_input('a');

Add the text to the current input line (e.g. what is displayed after the
prompt). See also L<input()>.

=item input()

	$current_input = $console->input();
	$console->input('foo');

Get or set the contents of the current input line (e.g. what is displayed
after the prompt). See also L<input()>.

Example usage after user pressed enter:

	$console->message( $console->input() );
	$console->input('');

=item backspace()

	$console->backspace();

Erases the last charcter from the current input buffer, unless the buffer is
empty. Returns the current input buffer after the operation.

=item text_color()

        $rgb = $console->text_color();		# [$r,$g, $b ]
        $console->color(1,0.1,0.8);		# set RGB

Sets the color of the text output.

=item background_color()

        $rgb = $console->background_color();	# [$r,$g, $b ]
        $console->background_color(1,0.1,0.8);	# set RGB

Sets the color of the background output. See also L<background_alpha()>.

=item text_alpha()

        $a = $console->text_alpha();	# $a
        $console->alpha(0.8);		# set A
        $console->alpha(undef);		# set's it to 1.0 (seems an OpenGL
					# specific set because
					# glColor($r,$g,$b) also sets $a == 1

Sets the alpha value of the rendered text output.

=item background_alpha()

        $a = $console->background_alpha();	# $a
        $console->background_alpha(0.8);	# set A

Sets the alpha value of the background (e.g. make it semi-transparent or
opaque).

=item speed()

        $s = $console->speed();		# in percent
        $console->color(20);		# set new speed (means 5 seconds time)

Gets/sets the opening/closing speed in percent per second, e.g. 25 means
100/25 = 4 seconds time.

=item cursor()

        $s = $console->cursor();	# get cursor string
        $console->cursor('_');		# set new cursor

Get/sets the string used as cursor.

=item prompt()

        $s = $console->prompt();	# get prompt string
        $console->prompt('_');		# set new prompt string

Get/sets the string used as prompt.

=item backbuffer_size()

        $s = $console->backbuffer_size();	# so many lines
        $console->backbuffer_size(20);		# keep 20

Sets the number of lines in the backbuffer, e.g. how many of the last message
lines are kept by the console.

=item close()

	$console->close();

Starts closing the console. See L<open()> and L<toggle()>.

=item open()

	$console->open();

Starts opening the console. See L<close()> and L<toggle()>.

=item toggle()

	$console->toggle($current_time);

Toggles the console on or off. See L<open()> and L<close()>.

=item visible()

	$console->visible();
	$console->visible(1);

Makes the console immidiately visible or invisible, unlike L<open()>,
L<close()> or L<toggle()>, which gradually move the console in or out.

=item scroll()

	$console->scroll(-1);
	$console->scroll(1);
	$console->scroll(+2);

Scroll the console'soutput by so many lines up or down (to access the
backbuffer via SHIFT+CURSOR_UP, for instance). See also L<offset()>.

=item offset()

	my $offset = $console->offset();

Return the current offset. See L<scroll()>.

=item messages()

	my $msgs = $console->messages();

Return number of message-lines in backbuffer.

=item clear()

	$console->clear();

Erase all message-lines in the backbuffer, e.g. clear it.

=back

=head1 KNOWN BUGS

None yet.

=head1 AUTHORS

(c) 2003,2006 Tels <http://bloodgate.com/>

=head1 SEE ALSO

L<Games::3D>, L<SDL:App::FPS>, and L<SDL::OpenGL>.

=cut

