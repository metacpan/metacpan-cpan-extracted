package Device::PiLite;

use strict;
use warnings;

use Moose;

use Carp qw(croak);
use Scalar::Util qw(looks_like_number);


=head1 NAME

Device::PiLite - Interface to Ciseco Pi-Lite for Raspberry Pi

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS



    use Device::PiLite;

    my $pilite = Device::PiLite->new();

	$p->all_off();

	$p->text("This is a test");

	$p->all_off();



=cut

=head2 DESCRIPTION

This module provides an interface for the Ciseco Pi-Lite for the Raspberry Pi.

The Pi-Lite has a 14 x 9 grid of LEDs controlled by an embedded ATMEL AVR
microcontroller that itself can be programmed using the Arduino toolchain,
however the default firmware provides a relatively simple mechanism to
communicate with the board from the Raspberry Pi's TTL serial port. 

Device::PiLite requires the default firmware and will not work if the Pi-Lite
is loaded with some other sketch.

=head2 CONFIGURING FOR THE PI-LITE

By default most Linux distributions for the Raspberry Pi will use the serial
port for a console, this will interfere with the functioning of the
Pi-Lite.  Before you try to use the device you will need to turn this off, and
instructions for a Debian based distribution can be found at:

	http://openmicros.org/index.php/articles/94-ciseco-product-documentation/raspberry-pi/283-setting-up-my-raspberry-pi

If you are using a distribution with a different base (such as e.g. Pidora,)
it may use C<systemd> rather than an inittab to start the console process and
you will need to use C<systemctl> to disable the C<getty> service. You will
still need to alter the C<cmdline.txt> as described in the above instructions.

Any users that want to access the Pi-Lite will need to be in the C<dialout>
group, which can be done by doing:

	sudo usermod -a -G dialout username

at the command line, where username is the user you want to add to the group.

=head2 METHODS

=cut

=over 4

=item serial_device

This is the name of the serial device to be used.

The default is "/dev/ttyAMA0".  If it is to be
set to another value this should be provided to the
constructor.

=cut

has serial_device	=>	(
							is	=>	'rw',
							isa	=>	'Str',
							default	=>	'/dev/ttyAMA0',
						);

=item device_serialport

This is the L<Device::SerialPort> that will be used to perform the 
actual communication with the Pi-Lite, configured as appropriate.

This delegates a number of methods and probably doesn't need to be
used directly.

=cut

has device_serialport	=>	(
								is	=>	'rw',
								isa =>	'Device::SerialPort',
								lazy	=>	1,
								builder	=>	'_get_device_serialport',
								handles	=>	{
									serial_write	=>	'write',
									serial_read		=>	'read',
									serial_input	=>	'input',
									serial_look		=>	'lookfor',
									write_done		=>  'write_done',
									lastlook		=>  'lastlook',
								},
							);

sub _get_device_serialport
{
	my ( $self ) = @_;
	
	require Device::SerialPort;

	my $dev = Device::SerialPort->new($self->serial_device());
	$dev->baudrate(9600);
	$dev->databits(8);
	$dev->parity("none");
	$dev->stopbits(1);
	$dev->datatype('raw');
	$dev->write_settings();
	$dev->are_match('-re', "\r\n");

	return $dev;

}

=item all_on

Turns all the LEDs on.

=cut

sub all_on
{
	my ( $self ) = @_;
	return $self->_on_off(1);
}

=item all_off

Turns all the LEDs off.

=cut

sub all_off
{
	my ( $self ) = @_;
	return $self->_on_off(0);
}

=item _on_off

Turns the pixels on or off depending on the boolean supplied.

=cut

sub _on_off
{
	my ( $self, $switch ) = @_;

	my $state = 'OFF';

	if ( $switch )
	{
		$state = 'ON';
	}
	return $self->send_command("ALL,%s", $state);
}

=item set_scroll

This sets the scroll delay in milliseconds per pixel.  The default is
80 (that is to say it will take 1.120 seconds to scroll the entire width
of the screen.)

=cut

sub set_scroll
{
	my ( $self, $rate ) = @_;
	if ( defined $rate )
	{
		$self->send_command("SPEED%d", $rate );
		$self->_scroll_rate($rate);
	}
}

has _scroll_rate	=>	(
							is	=>	'rw',
							isa	=>	'Int',
							default	=> 80,
						);


=item text

This writes the provided test to the Pi-Lite.  Scrolling as necessary
at the configured rate.

It won't return until all the text has been displayed, but you may want to
pause for $columns * $scroll_rate milliseconds before doing anything else
if you want the text to completely scroll off the screen.

The ability or otherwise to display non-ASCII characters is entirely the
responsibility of the firmware on the Pi-Lite (it uses a character to pixel
map to draw the characters.)

=cut

sub text
{
	my ( $self, $text ) = @_;

	my $rc;

	if ( $text )
	{
		$rc = $self->serial_write( $text . "\r");
	}

	return $rc;
}

=item frame_buffer

This writes every pixel in the Pi-Lite in one go, the argument is a
126 character string where each character is a 1 or 0 that indicates
the state of a pixel, starting from 1,1 (i.e. top left) to 14,9 
(bottom right.)

=cut

sub frame_buffer
{
	my ( $self, $frame ) = @_;

	my $rc;

	if ( defined $frame )
	{
		$rc = $self->send_command("F%s", $frame);
	}
	return $rc;
}

=item bargraph

The bargraph comprises 14 columns with values expressed as 0-100% (the
resolution is only 9 rows however,) The takes the column number (1-14)
and the value as arguments and sets the appropriate column.

=cut

sub bargraph
{
	my ( $self, $column, $value ) = @_;

	my $rc;

	if ( defined $value )
	{
		if ( $self->valid_column($column) )
		{
			$rc = $self->send_command("B%i,%i", $column, $value);
		}
	}

	return $rc;
}

=item vu_meter

This sets one channel of the "vu meter" which is a horizontal two bar
graph, with values expressed 1-100%.  The arguments are the channel number
1 or 2 and the value.

=cut

sub vu_meter
{
	my ( $self, $channel, $value ) = @_;

	my $rc;

	if ( defined $value )
	{
		if ( $self->valid_axis($channel,2))
		{
			$rc = $self->send_command("V%i,%i", $channel, $value);
		}
	}

	return $rc;
}

=item pixel_on

Turns the pixel specified by $column, $row on.

=cut

sub pixel_on
{
	my ( $self, $column, $row ) = @_;

	return $self->pixel_action(1, $column, $row);
}

=item pixel_off

Turns the pixel specified by $column, $row off.

=cut

sub pixel_off
{
	my ( $self, $column, $row ) = @_;

	return $self->pixel_action(0, $column, $row);
}

=item pixel_toggle

Toggles the pixel specified by $column, $row .

=cut

sub pixel_toggle
{
	my ( $self, $column, $row ) = @_;

	return $self->pixel_action(2, $column, $row);
}

=item pixel_action

This performs the specified action 'ON' (1), 'OFF' (0), 'TOGGLE' (2)
on the pixel specified by column and row.  This is used by C<pixel_on>,
C<pixel_off> and C<pixel_toggle> internally but may be useful if the
state is to be computed.

=cut

sub pixel_action
{
	my ( $self, $action, $column, $row ) = @_;

	my $rc;
	if (defined(my $verb = $self->_get_action($action)))
	{
		if ( $self->valid_column($column) && $self->valid_row($row) )
		{
			$rc = $self->send_command("P%i,%i,%s", $column, $row, $verb);
		}
	}
	return $rc;
}


sub _get_action
{
	my ( $self, $action ) = @_;

	my $rc;
	if ( defined $action )
	{
		$rc = $self->_actions()->[$action];
	}
	return $rc;

	
}

has _actions	=>	(
						is	=> 'ro',
						isa	=> 'ArrayRef',
						default	=> sub { [qw(OFF ON TOGGLE)] },
					);


=item scroll

This scrolls by the number of  columns left or right, a negative
value will shift to the right, positive shift to the left.

Once a pixel is off the display it won't come back when you scroll
it back as there is no buffer.


=cut

sub scroll
{
	my ( $self, $cols ) = @_;

	my $rc;
	if (looks_like_number($cols) && $self->valid_column(abs($cols)))
	{
		$rc = $self->send_command("SCROLL%i", $cols);
	}
	return $rc;
}

=item character

This displays the specified single character at $column, $row.

If the character would be partially off the screen it won't be displayed.

As with C<text()> above, this is unlikely to work well with non-ASCII
characters.

=cut

sub character
{
	my ( $self, $column, $row, $char ) = @_;

	my $rc;
	if (defined $char && length $char )
	{
		if ( $self->valid_column($column) && $self->valid_row($row))
		{
			$rc = $self->send_command("T%i,%i,%s", $column, $row, $char);
		}
	}
	return $rc;
}


=item columns

This is the number of columns on the Pi-Lite.  This is almost
certainly 14.

=cut 

has columns	=> (
					is	=>	'rw',
					isa	=>	'Int',
					default	=>	14,
				);

=item valid_column

Returns a boolean to indicate whether it is an integer between 1 and
C<columns>.

=cut

sub valid_column
{
	my ( $self, $column ) = @_;

	my $rc = $self->valid_axis($column, $self->columns());
	return $rc ;
}

=item rows

This is the number of rows on the Pi-Lite.  This is almost
certainly 9.

=cut 

has rows	=> (
					is	=>	'rw',
					isa	=>	'Int',
					default	=>	9,
				);

=item valid_row

Returns a boolean to indicate whether it is an integer between 1 and
C<rows>.

=cut

sub valid_row
{
	my ( $self, $row ) = @_;

	my $rc = $self->valid_axis($row, $self->rows());
	return $rc ;
}

=item valid_axis

Return a boolean to indicate $value is greater ot equal to 1
and smaller or equal to $bound.

=cut

sub valid_axis
{
	my ( $self, $value, $bound ) = @_;

	my $rc = 0;
	if ( looks_like_number($value) && looks_like_number($bound))
	{
		if ($value >= 1 && $value <= $bound)
		{
			$rc = 1;
		}
	}
	return $rc ;
}

=item cmd_prefix

A Pi-Lite serial command sequenced is introduced by sending '$$$'.

=cut

has cmd_prefix	=>	(
						is	=>	'rw',
						isa	=>	'Str',
						default	=>	'$$$',
					);

=item send_prefix

Write the prefix to the device. And wait for the response 'OK'.

It will return a boolean value to indicate the success or
otherwise of the write.

=cut

sub send_prefix
{
	my ( $self ) = @_;

	my $rc = 0;
	my $count = $self->serial_write($self->cmd_prefix());
	$self->write_done(1);

	if ( $count == length($self->cmd_prefix()))
	{
		my  $string  = "";
		while ( !$string )
		{
			if (!defined($string = $self->serial_look() ))
			{
				croak "Read abort without input\n";
			}
		}
		$rc = 1;
	}

	return $rc;
}

=item send_command

This sends a command to the Pi-Lite, sending the command prefix and the
command constructed by $format and @arguments which are dealt with by
C<_build_command>.

=cut

sub send_command
{
	my ( $self, $format, @arguments ) = @_;

	my $rc;
	if ( my $cmd_str = $self->_build_command($format, @arguments ))
	{
		if ( $self->send_prefix() )
		{
			$rc = $self->serial_write($cmd_str);
		}
	}
	return $rc;
}


=item _build_command

This returns the command string constructed from the sprintf format
specified by $format and the set of replacements in @arguments.

=cut

sub _build_command
{
	my ( $self, $format, @arguments ) = @_;

	my $command;
	if ( $format && @arguments )
	{
			$format .= "\r";
		$command = sprintf $format, @arguments;
	}
	return $command;
}

=back

=head1 AUTHOR

Jonathan Stowe, C<< <jns at gellyfish.co.uk> >>

=head1 BUGS

This appears to work as documented but it is difficult to test that the
device behaves as expected in all cases automatically.

Automated test reports indicating failure will be largely ignored unless
they indicate a problem with the tests themselves.

Please feel free to suggest any features with a pull request at:

   https://github.com/jonathanstowe/Device-PiLite

though I'd be disinclined to include anything that would require a change
to the device's firmware as this is somewhat tricky to deploy.

You can report bugs to C<bug-device-pilite@rt.cpan.org> but you should
consider whether it is actually a bug in this code or that of the device,
you can find the source for the firmware at:

    https://github.com/CisecoPlc/PiLite


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Device::PiLite

=head1 SEE ALSO

	L<Device::SerialPort>


=head1 LICENSE AND COPYRIGHT

Copyright 2014 Jonathan Stowe.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.


=cut

1; 
