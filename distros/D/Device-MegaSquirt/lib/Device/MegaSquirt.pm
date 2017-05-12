package Device::MegaSquirt;

use strict;
use warnings;
use Carp;

use vars qw($VERSION);
$VERSION = '0.01';
require 5.6.1;


use Device::MegaSquirt::Serial;

# Load all the version specific libraries (used by new()).
use Device::MegaSquirt::MS2ExtraRel303s;

=head1 NAME

Device::MegaSquirt - Perl5 module for communicating with a MegaSquirt controller

=head1 SYNOPSIS

 $dev = '/dev/ttyUSB0';
 $ms = Device::MegaSquirt->new($dev);

 $tbl = $ms->read_advanceTable1();
 $tbl = $ms->write_advanceTable1();

 $tbl = $ms->read_veTable1();
 $tbl = $ms->write_veTable1();

 $val = $ms->read_crankingRPM();
 $res = $ms->write_crankingRPM($val);

 $data = $ms->read_BurstMode();

 $version = $ms->get_version();

=head1 DESCRIPTION

Device::MegaSquirt provides operations for communicating with a MegaSquirt controller
 [http://www.msextra.com].  Operations such as reading/writing tables,
reading live data, and writing configuration variables.

This part of the module (Device::MegaSquirt) is a template and version specific
modules (Device::MegaSquirt::*) implement the interface.

=head1 OPERATIONS

=cut

# {{{ new() :-)

=head2 Device::MegaSquirt->new($dev);

  Returns object (TRUE) on success, FALSE on error

  $ms = Device::MegaSquirt->new($dev);

The device ($dev) is the file name of the serial device on which
the Megasquirt controller is connected (e.g.: /dev/ttyUSB0, /dev/ttyS0).

C<new> will attempt to open the device and determine the version and
signature of the controller.  It will return a version specific
object on success.

=cut

sub new {
	my $class = shift;
	my $dev = shift;

	my $mss = Device::MegaSquirt::Serial->new($dev);
	unless ($mss) {
		carp "ERROR: unable to create Device::MegaSquirt::Serial object.";
		return;
	}

	my $version = $mss->read_Q();
	unless ($version) {
		carp "ERROR: unable to read version";
		return;
	}

	my $signature = $mss->read_S();
	unless ($signature) {
		carp "ERROR: unable to read signature";
		return;
	}

	# Create a version specific object
	my $obj;
	if ($version =~ /^[\s\0]*MS2Extra Rel 3.0.3s[\s\0]*$/) {
		$obj = Device::MegaSquirt::MS2ExtraRel303s->new($mss);
	} else {
		carp "Unknown version: '$version'\n";
		return;
	}

	$obj->{version} = $version;
	$obj->{signature} = $signature;

	return $obj;
}


# }}}

# {{{ get_version()

=head2 $ms->get_version()

  Returns: version number on success, FALSE on error

  $version = $ms->get_version();

=cut

sub get_version {
	$_[0]->{version};
}

# }}}

# {{{ get_mss :-)

sub get_mss {
	$_[0]->{mss};
}

# }}}

=head2 

Remaining operations are implemented in the version specific module.

 Device::MegaSquirt::*

=cut

=head1 VERSION

This document refers to Device::MegaSquirt version 0.01.

=head1 REFERENCES

  [1]  MegaSquirt Engine Management System
       http://www.msextra.com/

=head1 AUTHOR

    Jeremiah Mahler <jmmahler@gmail.com>
    CPAN ID: JERI
    http://www.google.com/profiles/jmmahler#about 

=head1 COPYRIGHT

Copyright (c) 2010, Jeremiah Mahler. All Rights Reserved.
This module is free software.  It may be used, redistributed
and/or modified under the same terms as Perl itself.

=head1 SEE ALSO

Text::LookUpTable, Device::MegaSquirt::Serial

=cut

1;
