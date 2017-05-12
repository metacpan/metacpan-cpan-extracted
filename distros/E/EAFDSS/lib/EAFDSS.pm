# EAFDSS - Electronic Fiscal Signature Devices Library
#          Ειδική Ασφαλής Φορολογική Διάταξη Σήμανσης (ΕΑΦΔΣΣ)
#
# Copyright (C) 2008 Hasiotis Nikos
#
# ID: $Id: EAFDSS.pm 105 2009-05-18 10:52:03Z hasiotis $

package EAFDSS;

=head1 NAME

EAFDSS - Electronic Fiscal Signature Devices Library

=head1 SYNOPSIS

  use EAFDSS; 

  my($dh) = new EAFDSS(
                  "DRIVER" => $driver . "::" . $params,
                  "SN"     => $serial,
                  "DIR"    => $sDir,
                  "DEBUG"  => $verbal
          );

  if (! $dh) {
          print("ERROR: " . EAFDSS->error() ."\n");
          exit -1;
  }

  $result = $dh->Status();
  $result = $dh->Sign($fname);
  $result = $dh->Info();
  $result = $dh->SetTime($time);
  $result = $dh->GetTime();
  $result = $dh->SetHeaders($headers);
  $result = $dh->GetHeaders();

  if ($result) {
          printf("%s\n", $result);
          exit(0);
  } else {
          my($errNo)  = $dh->error();
          my($errMsg) = $dh->errMessage($errNo);
          printf(STDERR "ERROR [0x%02X]: %s\n", $errNo, $errMsg);
          exit($errNo);
  }


=head1 DESCRIPTION

The EAFDSS module handles the communication with an Electronic Signature Device (EAFDSS).
It defines a set of methods common to all EAFDSS devices in order to communicate with the
device but also handle all necessary file housekeeping requirements by Law, like creating
A, B, C files.

=head1 ARCHITECTURE of an EAFDSS Application

This module is loosely (and shamelessly I may add) influenced by the architecture of the
DBI module. There is a layer of a basic API that is common to all EAFDSS device drivers.
Usually a developer of an EAFDSS application will only need to deal with functions only
at that level. You have to be in need of something really special to access functions
that are specific to a certain driver.
 

         |<-------- EAFDSS A/B type solution ------->|
         |<- Your work ->| |<--- Scope of EAFDSS --->| |<-- hardware -->|
                                .-.   .-------------.   .---------------.
         .--------------.       | |---| SDSP Driver |---| EAFDSS Device |
         |              |       |E|   `-------------'   `---------------'
         | Perl script  |  |A|  |A|   .-------------.   .---------------.
         | using EAFDSS |--|P|--|F|---| SDNP Driver |---| EAFDSS Device |
         | API methods  |  |I|  |D|   `-------------'   `---------------'
         |              |       |S|...
         `--------------'       |S|... Other drivers
                                | |...
                                `-'

=cut

use 5.006_000;
use strict;
use warnings;
use Carp;
use Class::Base;

use base qw ( Class::Base );

our($VERSION) = '0.80';

=head1 Methods

First of all you have to initialize the driver handle through the EAFDSS constructor.

=head2 init, new

Returns a newly created $dh driver handle. The DRIVER argument is a combination of a driver and
it's parameters. For instance it could be one of the following:

  EAFDSS::SDNP::127.0.0.1

or
 
  EAFDSS::Dummy:/tmp/dummy.eafdss

or

  Driver EAFDSS::SDSP::/dev/ttyS0

The SN argument is the Serial number of device we want to connect. Each device has it's own unique serial
number. If the device's SN does not much with the provided then you will get an error.

The DIR argument is the directory were the signature files (A, B and C) will be created. Make sure the 
directory exist.

The last argument is the DEBUG. Use a true value in order to get additional information. This one is only 
useful to developers of the module itself.

  my($dh) = new EAFDSS(
                  "DRIVER" => $driver . "::" . $params,
                  "SN"     => $serial,
                  "DIR"    => $sDir,
                  "DEBUG"  => $verbal
          );
          
  if (! $dh) {
          print("ERROR: " . EAFDSS->error() ."\n");
          exit -1;
  }

Following are the common methods to all the device drivers.

=cut

sub init {
	my($self, $config) = @_;

	if (! exists $config->{DRIVER}) {
		croak "You need to provide the Driver to use";
	} else {
		$self->{DRV}    = substr($config->{DRIVER}, 0, rindex($config->{DRIVER}, "::"));
		$self->{PARAMS} = substr($config->{DRIVER}, rindex($config->{DRIVER}, "::") + 2);
		if ($self->{PARAMS} eq '') {
			croak "You need to provide params to the driver!";
		}
	}

	if (! exists $config->{DIR}) {
		croak "You need to provide the DIR to save the singatures!";
	} else {
		$self->{DIR} = $config->{DIR};
	}

	if (! -e $self->{DIR}) {
		croak "The directory to save the singatures does not exist!";
	}

	if (! exists $config->{SN}) {
		croak "You need to provide the Serial Number of the device!";
	} else {
		$self->{SN} = $config->{SN};
	}

	$self->debug("Loading driver \"$self->{DRV}\"\n");
	eval qq { require $self->{DRV} };
	if ($@) {
		return $self->error("No such driver \"$self->{DRV}\"");
	}

	$self->debug("Initializing device with \"$self->{PARAMS}\"\n");
	my($fd) = $self->{DRV}->new(
			"PARAMS" => $self->{PARAMS},
			"SN"     => $self->{SN},
			"DIR"    => $self->{DIR},
			"DEBUG"  => $self->{_DEBUG}
		);

	if (!defined $fd) {
		return $self->error($self->{DRV}->error());
	}

	return $fd;
}

=head2 EAFDSS->available_drivers 

Returns an array containing the names of drivers currently installed/supported.

  my(@drivers) = EAFDSS->available_drivers();

=cut

sub available_drivers {
	my(@drivers, $curDir, $curFile, $curDirEAFDSS);

	foreach $curDir (@INC){
		$curDirEAFDSS = $curDir . "/EAFDSS";
		next unless -d $curDirEAFDSS;

		opendir(DIR, $curDirEAFDSS) || carp "opendir $curDirEAFDSS: $!\n";
		foreach $curFile (readdir(EAFDSS::DIR)){
			next unless $curFile =~ s/\.pm$//;
			next if $curFile eq 'Base';
			next if $curFile eq 'Micrelec';
			push(@drivers, $curFile);
		}
		closedir(DIR);
	}

	return @drivers;
}


sub DESTROY {
	my($self) = shift;
}

# Preloaded methods go here.

1;
__END__

=head2 $dh->Sign($filename)

This the main method that will be used most of the time in a typical fiscal day. The aim of that method
is to feed the contents of the file provided by the $filename parameter to the EAFDSS device and return
to the user the signature string.

  my($result) = $dh->Sign($fname);
  if ($result) {
          printf("%s\n", $result);
          exit(0);
  } else {
          my($errNo)  = $dh->error();
          my($errMsg) = $dh->errMessage($errNo);
          printf(STDERR "ERROR [0x%02X]: %s\n", $errNo, $errMsg);
          exit($errNo);
  }

=head2 $dh->Report

The second most used function is Z report issuing function. At the end of the day ask for the device to
close the fiscal day by issuing the Z report. It will return the signature of the day.

	my($result) = $dh->Report();
	if ($result) {
		printf("%s\n", $result);
		exit(0);
	} else {
		my($errNo)  = $dh->error();
		my($errMsg) = $dh->errMessage($errNo);
		printf(STDERR "ERROR [0x%02X]: %s\n", $errNo, $errMsg);
		exit($errNo);
	}

=head2 $dh->Info

This method will return information about the name of the device and version of it's firmware.

  my($result) = $dh->Info();
  if ($result) {
          printf("%s\n", $result);
          exit(0);
  } else {
          my($errNo)  = $dh->error();
          my($errMsg) = $dh->errMessage($errNo);
          printf(STDERR "ERROR [0x%02X]: %s\n", $errNo, $errMsg);
          exit($errNo);
  }

=head2 $dh->Status

This function return a single line containing the values of the following: serial number, the 
index of the last Z, the total signatures, the daily signatures, the last signature's data size,
remaining signatures until the device will force a Z. 

  my($result) = $dh->Status();
  if ( defined $result && ($result == 0)) {
          printf("%s\n", $result);
          exit(0);
  } else {
          my($errNo)  = $dh->error();
          my($errMsg) = $dh->errMessage($errNo);
          printf(STDERR "ERROR [0x%02X]: %s\n", $errNo, $errMsg);
          exit($errNo);
  }

=head2 $dh->SetTime

Use this method to set the date/time on the device. Provide the date/time in the "DD/MM/YY HH:MM:SS" format. 

  my($result) = $dh->SetTime($time);
  if ( defined $result && ($result == 0)) {
          printf("Time successfully set\n");
          exit(0);
  } else {
          my($errNo)  = $dh->error();
          my($errMsg) = $dh->errMessage($errNo);
          printf(STDERR "ERROR [0x%02X]: %s\n", $errNo, $errMsg);
          exit($errNo);
  }

=head2 $dh->GetTime

This method will return the time of the device in the "DD/MM/YY HH:MM:SS" format

  my($result) = $dh->GetTime();
  if ($result) {
          printf("%s\n", $result);
          exit(0);
  } else {
          my($errNo)  = $dh->error();
          my($errMsg) = $dh->errMessage($errNo);
          printf(STDERR "ERROR [0x%02X]: %s\n", $errNo, $errMsg);
          exit($errNo);
  }

=head2 $dh->SetHeaders

Use this method to set the headers on the device. Provide the headers in the following format:

  Style1/Line1/Style2/Line2/Style3/Line3/Style4/Line4/Style5/Line5/Style6/Line6

  my($result) = $dh->SetHeaders($headers);
  if ( defined $result && ($result == 0)) {
          printf("Headers successfully set\n");
          exit(0);
  } else {
          my($errNo)  = $dh->error();
          my($errMsg) = $dh->errMessage($errNo);
          printf(STDERR "ERROR [0x%02X]: %s\n", $errNo, $errMsg);
          exit($errNo);
  }

=head2 $dh->GetHeaders

Use this method to get the printing headers of the device. The returned array contains 6 couples of values. One for the 
type of the printing line, and one for the actual printing message.

  my(@headersArray) = $dh->GetHeaders();
  if (@headersArray) {
          my($i);
          for ($i=0; $i < 12; $i+=2) {
                  if ($headersArray[$i] ne '') {
                          printf("[Line %d] [Type:%d] --> %s\n", 
				$i/2+1, $headersArray[$i], $headersArray[$i+1]);
                  }
          }
          exit(0);
  } else { 
          my($errNo)  = $dh->error();
          my($errMsg) = $dh->errMessage($errNo);
          printf(STDERR "ERROR [0x%02X]: %s\n", $errNo, $errMsg);
          exit($errNo);
  }

=head1 ERROR Codes

   0x00: No errors - success

   0x01: Wrong number of fields
   0x02: Field too long
   0x03: Field too small
   0x04: Field fixed size mismatch
   0x05: Field range or type check failed
   0x06: Bad request code
   0x09: Printing type bad
   0x0A: Cannot execute with day open
   0x0B: RTC programming requires jumper
   0x0C: RTC date or time invalid
   0x0D: No records in fiscal period
   0x0E: Device is busy in another task
   0x0F: No more header records allowed
   0x10: Cannot execute with block open
   0x11: Block not open
   0x12: Bad data stream
   0x13: Bad signature field
   0x14: Z closure time limit
   0x15: Z closure not found
   0x16: Z closure record bad
   0x17: User browsing in progress
   0x18: Signature daily limit reached
   0x19: Printer paper end detected
   0x1A: Printer is offline
   0x1B: Fiscal unit is offline
   0x1C: Fatal hardware error
   0x1D: Fiscal unit is full
   0x1E: No data passed for signature
   0x1F: Signature does not exist
   0x20: Battery fault detected
   0x21: Recovery in progress
   0x22: Recovery only after CMOS reset
   0x23: Real-Time Clock needs programming
   0x24: Z closure date warning
   0x25: Bad character in stream
   0x01: Device not accessible

   0x41: Device not accessible
   0x42: No such file
   0x43: Device Sync Failed
   0x44: Bad Serial Number
   0x45: Query found no devices
   0x50: File contains invalid characters

=head1 EXAMPLES

Take a look at the examples directory of the distribution for a complete command line utility (OpenEAFDSS.pl) using the
library.

=head1 SUPPORT / WARRANTY

The EAFDSS is free Open Source software. IT COMES WITHOUT WARRANTY OF ANY KIND.

=head1 VERSION

This is version 0.80.

=head1 AUTHOR

Hasiotis Nikos, E<lt>hasiotis@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Hasiotis Nikos

This library is free software; you can redistribute it and/or modify
it under the terms of the LGPL or the same terms as Perl itself,
either Perl version 5.8.8 or, at your option, any later version of
Perl 5 you may have available.

=cut
