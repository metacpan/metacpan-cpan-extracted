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

our $VERSION = '1.0';


# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Device::GPIB - Perl extension to access
a variety of generic and specific GPIB devices, via a number of
supported GPIB interfaces.

Generic command line programs can be used to scan the GPIB bus and to
send arbitrary commands and queries to any device that supports GPIB.

Perl Modules and command line programs to access specific
features of a number of HP, Tektronix and Advantest devices are also
provided.

Supports a number of GPIB interfaces and controllers including:
Prologix GPIB-USB Controller and compatibles, including:
   AR488 for Arduino from Twilight-Logic: https://github.com/Twilight-Logic/AR488
      (tested with Arduino Nano and custom wiring interface)
LinuxGpib compatible devices (requires linux-gpib from https://sourceforge.net/projects/linux-gpib)
   (Tested with Keysight 82357B)

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

Prologix:[Prologix:[port[:baud:databits:parity:stopbits:handshake]]]
LinuxGpib:[board_index]]
port[:baud:databits:parity:stopbits:handshake]]

Examples:

''                                # Defaults to Prologix:/dev/ttyUSB0:9600:8:none:1:none
'/dev/ttyACM0'                    # Prologix:/dev/ttyACM:9600:8:none:1:none
'Prologix:/dev/ttyUSB1:115200'    # Prologix:/dev/ttyUSB1:15200:8:none:1:none
'LinuxGpib:0'                     # Linux GPIB board index 0 (see /etc/gpib.conf)

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
