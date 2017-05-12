package Device::LabJack;

use 5.006;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Device::LabJack ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.02';

require XSLoader;
XSLoader::load('Device::LabJack', $VERSION);

# Preloaded methods go here.

1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

Device::LabJack - Perl extension for native access to the LabJack U12

=head1 SYNOPSIS

  use Device::LabJack;

  $idnum=-1;  $demo=0;  $stateIO=0;        $updateIO=0;   $ledOn=1;
  @channels=(0,1,2,3);  @gains=(0,0,0,0);  $disableCal=0;

  $ledOn=$1 if($ARGV[0]=~/(\d+)/);	# This turns the LabJack LED off if you run this program with a paramater of 0 (or on for 1)

  my(@results)=Device::LabJack::AISample($idnum,$demo,$stateIO,$updateIO,$ledOn,\@channels,\@gains,$disableCal);
  print join("\n",@results);	# This prints out the current Analogue Input values

=head1 DESCRIPTION

This module lets you read and write digital and analog data to and from your LabJack U12 device.

=head1 INSTALLATION - WINDOWS

   install labjack USB drivers
   perl Makefile.PL
   make
   make test
   make install

=head1 INSTALLATION - LINUX

   perl Makefile.PL
   make			(nb: will install the LabJack drivers for your kernel if they're not already installed)
   make test
   make install

=head1 WARNING - LINUX

   The "make" stage of installation will install the LabJack drivers for your kernel if they're not already installed.
   Remember to copy the kernel driver and do the "insmod" each time you reboot (see ./linux-labjack/INSTALL for details)

=head1 INSTALLATION - MACINTOSH OSX

   This is not tested.  If anyone with a Mac wants this, let me know and I'll build and test it for you on my OS/X v10.3.9

=head1 DEPENDENCIES

The relevant modules and drivers are included for all operating systems (Windows users might like to first install the LabJack windows drivers v118e or above from http://labjack.com/labjack_u12_downloads.html [http://labjack.com/files/U12SetupV118e.exe]. Note: the "National Instruments LabVIEW" package is NOT required).

Device::LabJack includes these other modules and libraries from the U12 CD or web site:-

  ljackuw.lib 
  ljackuw.h             ... provided on the U12 CD or web site

  linux-labjack		... provided by labjack.com in their v0.03b driver release


=head2 EXPORT

None by default.


=head1 AUTHOR

Written by Chris Drake, Feb 1, 2003,
updated by Neil Cherry with help from Clinton A. Pierce c. Aug 2003,
reworked for multiplatform release by Chris Drake, Oct 25, 2005.

*PLEASE* report bugs, or send me updates/fixes you make:
Find my current email address from the "contacts" page of 
my web site, at http://www.ReadNotify.com 

=head1 COPYRIGHT AND LICENCE

This is free, providing that if you improve or add to this module, you email 
me the new version. 

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<perl>.
L<www.labjack.com>

=cut
