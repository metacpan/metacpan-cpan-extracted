package Device::ParallelPort;
use vars qw/$AUTOLOAD $VERSION/;
$VERSION = "1.00";
use Carp;

=head1 NAME

Device::ParallelPort - Parallel Port Driver for Perl

=head1 SYNOPSIS

	my $port = Device::ParallelPort->new();
	$port->set_bit(3,1);
	print $port->get_bit(3) . "\n";
	print ord($port->get_byte(0)) . "\n";
	$port->set_byte(0, chr(255));

=head1 DESCRIPTION

A parallel port driver module. This module provides an API to all parallel ports, by
providing the ability to write any number of drivers. Modules are available for linux
(both directly and via parport), win32 and a simple script version.

NOTE - This actual module is a factory class only - it is used to automatically
return the correct class and has not other intelligence / purpose.

=head1 DRIVER MODULES

NOTE - You MUST load one of the drivers for your operating system before this
module will correctly work - they are in separate CPAN Modules.

	L<Device::ParallelPort::drv::linux> - Direct hardware access to a base address.
	L<Device::ParallelPort::drv::parport> - Linux access to /dev/parport drivers
	L<Device::ParallelPort::drv::script> - Run a script with parameters
	L<Device::ParallelPort::drv::dummy_byte> - Pretending byte driver for testing
	L<Device::ParallelPort::drv::dummy_bit> - Pretending bit driver for testing
	L<Device::ParallelPort::drv::win32> - Windows 32 DLL access driver

=head1 DEVICE MODULES

	L<Device::ParallelPort::Printer> - An example that can talk to a printer
	L<Device::ParallelPort::JayCar> - Simple JayCar electronics latched, addressable controller
	L<Device::ParallelPort::SerialFlash> - SerialFlash of bits - useful for many driver chips

=head1 METHODS

=head2 new

=head1 CONSTRUCTOR

=over 4

=item new ( DRIVER )

Creates a C<Device::ParallelPort>. 

=back

=head1 METHODS

=over 4

=item get_bit( BITNUMBER )

You can get any bit that is supported by this particular driver. Normally you
can consider a printer driver having 3 bytes (that is 24 bits would you
believe). Don't forget to start bits at 0. The driver will most likely croak if
you ask for a bit out of range.

=item get_byte ( BYTENUMBER )

Bytes are some times more convenient to deal with, certainly they are in most
drivers and therefore most Devices. As per get_bit most drivers only have
access to 3 bytes (0 - 2).

=item set_bit ( BITNUMBER, VALUE )

Setting a bit is very handy method. This is the method I use above all others,
in particular to turn on and off rellays.

=item set_byte ( BYTENUMBER, VALUE )

Bytes again. Don't forget that some devices don't allow you to write to some
locations. For example the stock standard parallel controller does not allow
you to write to the status entry. This is actually a ridiculous limitation as
almost all parallel chips allow all three bytes to be inputs or outputs,
however drivers such as linux parallel port does not allow you to write to the
status byte.

NOTE - VALUE must be a single charachter - NOT an integer. Use chr(interger).

=item get_data ( )

=item set_data ( VALUE )

=item get_control ( )

=item set_control ( VALUE )

=item get_status ( )

=item set_status ( VALUE )

The normal parallel port is broken up into three bytes. The first is data,
second is control and third is status. Therefore for this reason these three
bytes are controlled by the above methods.

=back

=head1 LIMITATIONS

Lots... This is not a fast driver. It is designed to give you simple access to
a very old device, the parallel chip. Don't, whatever you do, use this for
drivers that need fast access.

=head1 DISCUSSIONS

=head2 Hardware

Following is the standard hardware table, so that you can find the correct pins
and information. Note also the Inverted flag.

A number of real projects have been produced using Device::ParallelPort. For
futher information see L<http://linux.dd.com.au/quest/os-perl/parallelport/>

Pin No (DB25) - Signal name - Direction - Register - bit - Inverted

1 - nStrobe - Out - Control-0 - Yes

2 - Data0 - In/Out - Data-0 - No

3 - Data1 - In/Out - Data-1 - No

4 - Data2 - In/Out - Data-2 - No

5 - Data3 - In/Out - Data-3 - No

6 - Data4 - In/Out - Data-4 - No

7 - Data5 - In/Out - Data-5 - No

8 - Data6 - In/Out - Data-6 - No

9 - Data7 - In/Out - Data-7 - No

1 - 0 nAck - In - Status-6 - No

1 - 1 Busy - In - Status-7 - Yes

1 - 2 Paper-Out - In - Status-5 - No

1 - 3 Select - In - Status-4 - No

1 - 4 Linefeed - Out - Control-1 - Yes

1 - 5 nError - In - Status-3 - No

1 - 6 nInitialize - Out - Control-2 - No

1 - 7 nSelect-Printer - Out - Control-3 - Yes

18-25 - Ground

=head1 BUGS

Not known yet. Windows support is new so expect some.

=head1 TODO

Refer to TODO list with packages and code.

=head1 HISTORY

History here covers central Device::ParallelPort and not the specific drivers,
see them individually. For full history see Changes in the package.

=over

=item 0.04 - First release

Basic first release. Worked for Linux ROOT and Linux parport drivers only.
Windows work only in early pre-alpha testing. 

=item 1.00 - First stable release

Stable - I beleive it is stable, but this is only on my own testing and
machines. Lots of imporvements to documentation, auto load modules etc.
Improved use of perl.  In particular this is the first release of Windows and a
fully working auto driver.

=back

=head1 COPYRIGHT

Copyright (c) 2002,2003,2004 Scott Penrose. All rights reserved.
This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Scott Penrose L<scottp@dd.com.au>, L<http://linux.dd.com.au/>

=head1 SEE ALSO

L<Device::ParallelPort::drv> for developing a driver.

=cut

sub new {
	my ($class, $drvstr, @params) = @_;
	my $this = undef;
	my ($drv, $str) = split(/:/, $drvstr, 2);
	$drv ||= "auto";
	$str ||= "0";
	eval qq{
		use Device::ParallelPort::drv::$drv;
		\$this = Device::ParallelPort::drv::$drv->new(\$str, \@params);
	};
	croak "Device::ParallelPort unabel to create driver $drv (see Device::ParallelPort::drv::auto for further information) - $@" if ($@);
	return $this;
}

1;
