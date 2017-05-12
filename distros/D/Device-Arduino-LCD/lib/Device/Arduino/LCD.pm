package Device::Arduino::LCD;

use strict;
use Device::SerialPort qw[ :ALL ];

our $VERSION = '1.02';

$|++;

# defaults.
$Device::Arduino::LCD::Device	     = '/dev/tty.usbserial';
$Device::Arduino::LCD::Baud	     = 9600;
$Device::Arduino::LCD::READ_TIMEOUT  = 10;

use Class::MethodMaker [ scalar => [ qw[ port baud ] ]];

use constant {
  ROW_ONE_TEXT => '01',
  ROW_TWO_TEXT => '02',
  SCROLL_UP    => '03',
  PLACE_STRING => '04',
  SCROLL_LEFT  => '05',
  CLEAR        => '06',
  SET_GAUGE    => '07',
  MAKE_CHAR    => '08',
  SEND_CMD     => '09',
  PRINT        => '10',
  WRITE_ASCII  => '11',
  RESET        => '99',
};

# transmission control.
our $HEADER_START = "\x1A";
our $DATA_START   = "\x1B";
our $DATA_END     = "\x1C";
our $STRING_TOK   = "\x1D";

sub new {
  my $class = shift;
  my ($device, $baud) = @_;
  $device ||= $Device::Arduino::LCD::Device;
  $baud   ||= $Device::Arduino::LCD::Baud;
  my $port = Device::SerialPort->new($device)
    or die "can't open serial device: $!";
  $port->baudrate($baud);
  $port->read_char_time(0);
  $port->read_const_time(1000);
  return bless { port => $port, baud => $baud }, $class;
}

sub send {
  my ($self, $command, $payload) = @_;
  my $cmd = $self->encapsulate($command, $payload);
  $self->port->write($cmd);
}

sub encapsulate {
  my ($self, $command, $payload) = @_;
  return join '' => $HEADER_START, $command, $DATA_START, $payload, $DATA_END;
}

sub receive {
  my $self = shift;
  my ($buffer, $chars, $timeout) = 
    ("", 0, $Device::Arduino::LCD::READ_TIMEOUT);
  while ($timeout > 0) {
    my ($count, $saw) = $self->port->read(255);
    if ($count > 0) {
      $chars  += $count;
      $buffer .= $saw;
      last if $chars;
    }
    else {
      $timeout--;
    }
  }
  return $buffer;
}

sub reset {
  my $self = shift;
  $self->send(RESET);
}

sub first_line {
  my ($self, $text) = @_;
  $self->send(ROW_ONE_TEXT, $text);
}

sub second_line {
  my ($self, $text) = @_;
  $self->send(ROW_TWO_TEXT, $text);
}

sub clear {
  my ($self, $pre_delay, $post_delay) = @_;
  sleep ($pre_delay || 0);
  $self->send(CLEAR);
  sleep ($post_delay || 0);
}

sub scroll_left {
  my ($self, $delay) = @_;
  $self->send(SCROLL_LEFT, $delay);
}

sub scroll_up {
  my ($self, $text, $pre_delay, $internal_delay, $post_delay) = @_;
  my @text = ref $text eq 'ARRAY' ? @$text : ($text);
  sleep ($pre_delay || 0);
  for (@text) {
    $self->send(SCROLL_UP, $_);
    sleep ($internal_delay || 0);
  }
  sleep ($post_delay || 0);
}

sub place_string {
  my ($self, $text, $row, $col) = @_;
  my $payload = join $STRING_TOK => $row, $col, $text;
  $self->send(PLACE_STRING, $payload);
}

sub gauge_pct {
  my ($self, $gauge, $pct) = @_;
  $pct = $pct > 1 ? $pct/100 : $pct;
  my $step_level = 255 * $pct;
  my $payload = join $STRING_TOK => $gauge, $step_level;
  $self->send(SET_GAUGE, $payload);
}

sub command {
  my ($self, $command) = @_;
  $self->send(SEND_CMD, $command);
}

sub print_char {
  my ($self, $char) = @_;
  $self->send(PRINT, ord(substr($char, 0, 1)));
}

sub write_ascii {
  my ($self, $ascii, $row, $col) = @_;
  my $payload = join $STRING_TOK => $row, $col, $ascii;
  $self->send(WRITE_ASCII, $payload);
}

sub make_char {
  my ($self, $ascii, @data) = @_;

  die "out out bounds" unless $ascii <= 7 and $ascii >=0;
  @data = ref $data[0] eq 'ARRAY' ? @{ $data[0] } : @data;
  die "bad character data" unless scalar @data == 8;
  my $payload = join $STRING_TOK => $ascii, @data;
  $self->send(MAKE_CHAR, $payload);
}

sub convert_to_char {
  my ($self, $ascii, @lines) = @_;
  return undef unless $ascii >=0 and $ascii <= 7;

  my @values = ();

  for my $line_number (0 .. 7) { # starting at the top
    $values[$line_number] = 128;
    my $line = $lines[$line_number];
    return undef unless (ref $line eq 'ARRAY');
    my @line = @$line;
    for my $i (0 .. 4) {
      $values[$line_number] += (2 ** (4-$i)) if lc $line[$i] eq 'x';
    }
  }

  $self->make_char($ascii, @values);
  return \@values;
}



# bargraph support.

sub graph {
  my ($self, $val, $row, $col) = @_;
  if ($val == 0) { # print a space.
    $self->place_string(" ", $row, $col);
  }
  elsif ($val <= 8) {
    $self->write_ascii($val - 1, $row, $col);
  }
}

sub tallgraph {
  my ($self, $val, $col) = @_;
  if ($val == 0) {
    $self->place_string(" ", 1, $col);
    $self->place_string(" ", 2, $col);
  }
  elsif ($val <= 8) {
    $self->place_string(" ",      1, $col);
    $self->write_ascii($val - 1,  2, $col);
  }
  elsif ($val <= 16) {
    $self->write_ascii($val - 9, 1, $col);
    $self->write_ascii(7,        2, $col);
  }
}

sub init_bargraph {
  my ($self) = shift;
  my $data = [ [128,128,128,128,128,128,128,159],
	       [128,128,128,128,128,128,159,159],
	       [128,128,128,128,128,159,159,159],
	       [128,128,128,128,159,159,159,159],
	       [128,128,128,159,159,159,159,159],
	       [128,128,159,159,159,159,159,159],
	       [128,159,159,159,159,159,159,159],
	       [159,159,159,159,159,159,159,159] ];
  my $i = 0;
  for (@$data) { $self->make_char($i++, $_) };
}



1;

__END__

=head1 NAME

Device::Arduino::LCD - Perl Interface to the PerLCD Arduino Sketch.

=head1 SYNOPSIS

  use strict;
  use Device::Arduino::LCD;

  my $lcd = Device::Arduino::LCD->new;
  $lcd->clear;
  $lcd->first_line("Hello World");

See examples/demo.pl for a more comprehensive example.

=head1 DESCRIPTION

The Arduino is an open-source physical computing platform.  Among the
many things one might want to do with such a device is connect an LCD
to it and print stuff (at least that's what I wanted to do with it).  

There are a couple of excellent low-level libraries that can be linked
into an Arduino sketch to provide this functionality.  I've chosen the
LCD4Bit library to link against.  The PerLCD sketch provides a few
higher level functions as well as a serial listener.

This Perl library provides a very high level interface for formatting
and sending messages to the sketch's listener.  Once the device is
wired up to an LCD (a fairly trivial task), the USB serial drivers
installed, and the sketch compiled and uploaded, getting text on the
screen should be no more difficult than the example above: Zero
knowledge of LCDs required.

The sketch provided can obviously be used with a client library
written in any language, the choice of Perl was (almost) arbitrary.

=head1 VARIABLES

Package variables representing (supposedly) sensible default.  May be
changed as necessary before new() is called.

=over 4

=item *

$Device::Arduino::LCD::Device -- default serial device to connect
with. (/dev/tty.usbserial)

=item *

$Device::Arduino::LCD::Baud -- default baud rate (9600).  Changing
this requires recompiling and reloading the perlcd.cc code.

=item *

$Device::Arduino::LCD::READ_TIMEOUT -- default time in seconds for
receive() to wait when called (10).

=head1 METHODS

=head2 new(class, [device, [baud]])

Returns a Device::Arduino::LCD object or dies if unable to open the
serial device.

=head2 first_line(Device::Arduino::LCD, text)

Print text on the first line of the LCD.  Characters exceeding the
length of the display are truncated.

=head2 second_line(Device::Arduino::LCD, text)

As above, on the second line.

=head2 clear(Device::Arduino::LCD, [pre-delay, [post-delay]])

Clears the LCD.  Waits pre-delay seconds before sending the command
and post-delay seconds before returning.

=head2 scroll_left(Device::Arduino::LCD, [delay])

Scrolls both lines of the LCD to the left, at a rate of delay ms.

=head2 scroll_up(Device::Arduino::LCD, text, 
       [pre-delay, [internal-delay, [post_delay]]]);

Scrolls the text up (i.e., line 2 becomes line 1; line 2 contains
text).  Waits pre-delay before sending the command; scrolls at a rate
of internal-delay seconds; waits post_delay seconds before returning.
Text is an array ref.

=head2 place_string(Device::Arduino::LCD, text, row, column)

Places character one of text at the row and column specified.  Rows
(on a two line display) range from 1 to 2; columns, however, are zero
indexed.  (Sorry about that.)

=head2 gauge_pct(Device::Arduino::LCD, gauge-number, x%)

Sends x% of 5V to the port specified by gauge-number.  Gauges are
numbered 1, 2, and 3 corresponding to PWM pins 3, 5, and 6 on the
arduino.  This has bugger all to do with LCDs, but since the pins are
available it seems to make sense to provide a way of addressing them.

=head2 command(Device::Arduino::LCD, LCD-command)

Send (numeric) LCD-command directly to the LCD.  Useful for sending
the sorts of commands listed here: http://tinyurl.com/234d8z

=head2 print_char(Device::Arduino::LCD, character)

Send the character directly to the LCD.  The method will handle
converting the character to an integer.  With command(0 and
print_char() one can achieve pretty much anything but initialization
of the display.

=head2 make_char(Device::Arduino::LCD, ascii-num, data)

Installs data (an eight element array or array ref) as ascii character
0 - 7.  (NB: the LCD allows eight characters, ASCII 0-7 to be defined
by the user; that's what make_char and write_ascii as well as the
bargraph functions are all about.)

=head2 write_ascii(Device::Arduino::LCD, ascii-num, row, col)

Prints the ascii character (0-7) at row, col.  This is particularly
useful for printing the custom characters created with make_char().

=head2 init_bargraph(Device::Arduino::LCD);

Defines eight custom characters (overwriting whatever's been defined
before) as a series of bars for use in graphing.

=head2 graph(Device::Arduino::LCD, value, row, column);

With values ranging from 0 - 8 prints that many solid horizontal bars
(starting at the bottom) in the position indicated.  So 

  $lcd->graph(2, 1, 0); $lcd->graph(5, 1, 1);

prints this in the first and second blocks of the top row:

  . . . . .  . . . . .
  . . . . .  . . . . .
  . . . . .  . . . . .
  . . . . .  x x x x x
  . . . . .  x x x x x
  . . . . .  x x x x x
  x x x x x  x x x x x
  x x x x x  x x x x x

=head2 tallgraph(Device::Arduino::LCD, value, column);

Like graph() above but using a 16 x 5 font; the value can range from 0
to 16.  

=head2 convert_to_char(Device::Arduino::LCD, ascii-num, @data)

Convert an array of arrayrefs of text to custom character ascii-num.
A call to convert_to_char might look like.

  my $ret = $lcd->convert_to_char(0,
  				[ qw[ . x . x . ] ],
  				[ qw[ x . x . x ] ],
  				[ qw[ . x . x . ] ],
  				[ qw[ x . x . x ] ],
  				[ qw[ . x . x . ] ],
  				[ qw[ x . x . x ] ],
  				[ qw[ . x . x . ] ],
  				[ qw[ x . x . x ] ]);

Any position indicated by an x (or X) will be lit, everything else
will be off.  The choice of period here is arbitrary.  To print this
character one could say $lcd->write_ascii(0, 1, 0).

=head1 PREREQUISITES

=over 4

=item *

Device::SerialPort from CPAN (http://tinyurl.com/2tee6b)

=item * 

GNU avr-gcc, uisp, and avrdude.  Note: it's probably
possible to use the Arduino development environment instead.  I much
prefer typing "make" and "make upload" (and editing in emacs).

=item * 

An Arduino NG board and an LCD.  In the US www.sparkfun.com
distributes the board at a reasonable price.  I also bought an LCD
from them (the Xiamen GDM1602K).

=item *

Appropriate USB serial drivers.  For OS X these are included with the
Arduino development environment package.

=item * 

The Arduino PerLCD sketch compiled and loaded onto the board.  Edit
arduino/Makefile (there are instructions at the top) and then run
'make'.  If that goes well, frob the arduino reset switch and
immediately execute 'make upload'.  

=back

=head1 SEE ALSO

The Arduino homepage: http://www.arduion.cc, particularly Heather
Dewey-Hagborg's LCD tutorial
(http://www.arduino.cc/en/Tutorial/LCDLibrary) and neillzero's
LCD4BitLibrary page
(http://www.arduino.cc/playground/Code/LCD4BitLibrary).  

The Hitachi HD44780 Datasheet:
http://www.electronic-engineering.ch/microchip/datasheets/lcd/hd44780.pdf

Dincer Aydin's LCD page on geocities was also a good resource,
particularly the Custom-Character Calculator.
http://www.geocities.com/dinceraydin/lcd/intro.htm

Erik Nordin's HD44780-Based LCD FAQ:
http://www.repairfaq.org/filipg/LINK/F_LCD_HD44780.html

=head1 BUGS

Rows are are indexed from 0; columns from 1: The LCD4Bit library is
shining through, it was kept this way for consistency but it's
probably not very abstract or intuitive.  

=head1 AUTHOR

Kevin Montuori, <montuori@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Kevin Montuori & mconsultancy

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
