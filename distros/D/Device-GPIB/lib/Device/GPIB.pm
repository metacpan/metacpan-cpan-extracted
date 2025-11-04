package Device::GPIB;

use 5.034000;
use strict;
use warnings;

require Exporter;
use AutoLoader qw(AUTOLOAD);

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Device::GPIB ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '1.3';


# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__

=head1 NAME

Device::GPIB - Perl extension to access
a variety of generic and specific GPIB devices, via a number of
supported GPIB interfaces. Device::GPIB does not do anything specific except to make a place
for documentation and as a wrapper for all included modules. 

Generic command line programs can be used to scan the GPIB bus and to
send arbitrary commands and queries to any device that supports GPIB.

Perl Modules with API and command line programs to access specific
features of a number of HP, Tektronix and Advantest devices are also
provided.

Supports a number of GPIB interfaces devices an and controllers including:
Prologix GPIB-USB Controller and compatibles, such as:
   AR488 for Arduino from Twilight-Logic: https://github.com/Twilight-Logic/AR488
      (tested with Arduino Nano and custom wiring interface)
LinuxGpib compatible devices (requires linux-gpib from https://sourceforge.net/projects/linux-gpib)
   (Tested with Keysight 82357B USB-GPIB adapter)

Also supports direct serial connections to devices such as Tek 1240
with 1200C01 RS232C Comm Pack installed. This device handles many of the same commands
by serial as it does by the1200C02 GPIB Comm Pack.

This module obsoletes and replaces the earlier Device::GPIB::Prologix
module from the same author.

=head1 SYNOPSIS

# Low level access to Controller
use Device::GPIB::Controller;
my $port = 'Prologix:/dev/ttyUSB0:115200';
my $d = Device::GPIB::Controller->new($port);
# Can now use $d->....

# Open a specific GPIB device with address
use Device::GPIB::HP::HP3577A;
my $address = 11;
my $na = Device::GPIB::HP::HP3577A->new($d, $address);
$na->plot();

=head1 DESCRIPTION

Device::GPIB::Controller->new($port);
A wrapper that will load the appropriate Controller module depending on a port/device specification
argument passed to it. The following port/device names are supported:

Prologix:[port[:baud:databits:parity:stopbits:handshake]]
LinuxGpib:[board_index]]
port[:baud:databits:parity:stopbits:handshake]] # defaults to Prologix
SERIAL:[baud:databits:parity:stopbits:handshake]]

Examples:

''                                # Defaults to Prologix:/dev/ttyUSB0:9600:8:none:1:none
'/dev/ttyACM0'                    # Prologix:/dev/ttyACM:9600:8:none:1:none
'Prologix:/dev/ttyUSB1:115200'    # Prologix:/dev/ttyUSB1:15200:8:none:1:none
'LinuxGpib:0'                     # Linux GPIB board index 0 (see /etc/gpib.conf)
'SERIAL:/dev/ttyUSB0'             # Direct serial conneciton to devices that support it

You can of course load specific Controllers directly:
use Device::GPIB::Controllers::Prologix;
my $d = Device::GPIB::Controllers::Prologix>new('/dev/ttyUSB0:115200');
...

or

use Device::GPIB::Controllers::LinuxGpib;
my $d = Device::GPIB::Controllers::LinuxGpib(1);
...

After a Controller is opened, you can load a perl module with suport
for the specific functions ao any of the suported GPIB devices with
something like:

use Device::GPIB::HP::HP3577A;
...
my $na = Device::GPIB::HP::HP3577A->new($d, $address);
exit unless $na;

and then do things like:
my $screendump = $na->sendAndRead('PLA'); # Get HPGL 

or 

my $instrumentstate = $na->lmo(); # Get current instrument state for saving

Of course the list of things you can do depends on the device.

=head2 EXPORT

None by default.

=head1 NOTES

AR488

The AR488 software for arduino from Twilight-Logic is very good, and
Device::GPIB::Controllers:Prologix works with it, however it is not
identical to a Prologix, and we had to add some workarounds to manage
the differences:

- It is not possible to set GPIB address 0 with ++addr, so the scan.pl
  program starts at GPIB address 1 by default.

- When a USB serial port connection is made to the AR488 (at least on
Nano and Uno) the Arduino reboots and (unlike the Prologix) takes a
few seconds before it is ready to accept commands. This requires us to
add some polling in Device::GPIB::Controllers::Prologix->initialised()
to wait until it is ready. Therefore response times are fast with a
Prologix slower with AR488.

- When the USB serial port connection is closed, the AR488 may or may
not have enough time to send the last command to the addressed
device. We have added a short delay after device close to ensure the
last command is sent.

LinuxGpib

The LinuxGpib drivers and supporting software are excellent and very
fast (at least with linux-gpib-4.3.5 on Ubuntu 22.10 and kernel
5.19.0). If you intend to use the LinuxGpib Controller part of this
module you will need to install the LinuxGpib drivers and the Perl
bindings as described in lib/Device/GPIB/Controllers/README.

LinuxGpib behaves slightly differently to Prologix in that the
LinuxGpib read timeout is the time required for the entire GPIB reply
to be read, not just the inter-byte spacing. The means that the
timeout must be longer than the time taken for the longest GPIB
command response. Local tests here show that the 'PLA' Plot All
command of the HP3577A Network Analyser takes some 9 seconds, so the
LinuxGpib Controller timeout is set somewhat above that to 30 seconds.
This make the scan.pl program run fairly slowly when the LinuxGpib
Controller is used.

=head1 Supported Devices

The gpib.pl and scan.pl are expected to suport any GPIB compliant device.

There are specific interface modules and sample binary programs (implementing many
control and data operations specific to that device)

=head 2 Tektronix
AFG310.pm Arbitrary Function Generator plugin
DM5110.pm Digital Multimeter plugin
PFG5105.pm Programmable Function Generator plugin
PS5010.pm Power Supply plugin
DC5009.pm Digital Counter plugin
LA1240.pm  Logic Analyser (Serial interface only; GPIB not yet tested)
AFG5101.pm Arbitrary Function Generator plugin
DM5010.pm Digital Multimeter plugin
MI5010.pm Multifunction Interface plugin
SI5020.pm DC to 18 GHz microwave switcher plugin
SI5010.pm 50 Ω BNC switch matrix plugin 

=head2 Hewlett-Packard
HP5342A.pm Microwave Frequency Counter
HP3456A.pm Digital Voltmeter
HP8904A.pm Multifunciton Synthesizer
HP3577A.pm Network Analyzer

=head2 Advantest

TR 4131 Spectrum Analyser

If you need support for other devices, just send me one and I will add support for it.

=head1 SEE ALSO

https://sourceforge.net/projects/linux-gpib

lib/GPIB/Controllers/README has some guidance for installing and configuring linux-gpib

https://prologix.biz/downloads/PrologixGpibUsbManual-4.2.pdf

https://gist.github.com/turingbirds/6eb05c9267a6437183a9567700e8581a

https://github.com/Twilight-Logic/AR488

=head1 AUTHOR

Mike McCauley, E<lt>mikem@E<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2023 by Mike McCauley

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.34.0 or,
at your option, any later version of Perl 5 you may have available.


=cut
