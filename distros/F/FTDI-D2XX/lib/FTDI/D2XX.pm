package FTDI::D2XX;

use 5.008008;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use FTDI::D2XX ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT = qw(
	FT_OK
);

our @EXPORT_OK = qw(
  FT_OK
  FT_INVALID_HANDLE
  FT_DEVICE_NOT_FOUND
  FT_DEVICE_NOT_OPENED
  FT_IO_ERROR
  FT_INSUFFICIENT_RESOURCES
  FT_INVALID_PARAMETER
  FT_INVALID_BAUD_RATE

  FT_DEVICE_NOT_OPENED_FOR_ERASE
  FT_DEVICE_NOT_OPENED_FOR_WRITE
  FT_FAILED_TO_WRITE_DEVICE
  FT_EEPROM_READ_FAILED
  FT_EEPROM_WRITE_FAILED
  FT_EEPROM_ERASE_FAILED
  FT_EEPROM_NOT_PRESENT
  FT_EEPROM_NOT_PROGRAMMED
  FT_INVALID_ARGS
  FT_NOT_SUPPORTED
  FT_OTHER_ERROR

  FT_OPEN_BY_SERIAL_NUMBER 
  FT_OPEN_BY_DESCRIPTION
  FT_OPEN_BY_LOCATION

  FT_LIST_NUMBER_ONLY
  FT_LIST_BY_INDEX
  FT_LIST_ALL
  FT_LIST_MASK
  
  FT_BAUD_300
  FT_BAUD_600
  FT_BAUD_1200
  FT_BAUD_2400
  FT_BAUD_4800
  FT_BAUD_9600
  FT_BAUD_14400
  FT_BAUD_19200
  FT_BAUD_38400
  FT_BAUD_57600
  FT_BAUD_115200
  FT_BAUD_230400
  FT_BAUD_460800
  FT_BAUD_921600

  FT_BITS_8
  FT_BITS_7
  FT_BITS_6
  FT_BITS_5

  FT_STOP_BITS_1
  FT_STOP_BITS_1_5
  FT_STOP_BITS_2

  FT_PARITY_NONE
  FT_PARITY_ODD
  FT_PARITY_EVEN
  FT_PARITY_MARK
  FT_PARITY_SPACE

  FT_FLOW_NONE
  FT_FLOW_RTS_CTS
  FT_FLOW_DTR_DSR
  FT_FLOW_XON_XOFF

  FT_PURGE_RX
  FT_PURGE_TX

  FT_EVENT_RXCHAR	
  FT_EVENT_MODEM_STATUS
  FT_EVENT_LINE_STATUS

  FT_DEFAULT_RX_TIMEOUT
  FT_DEFAULT_TX_TIMEOUT

  FT_DEVICE_BM
  FT_DEVICE_AM
  FT_DEVICE_100AX
  FT_DEVICE_UNKNOWN
  FT_DEVICE_2232C
  FT_DEVICE_232R
  FT_DEVICE_2232H
  FT_DEVICE_4232H

  FT_BITMODE_RESET
  FT_BITMODE_ASYNC
  FT_BITMODE_MPSSE
  FT_BITMODE_SYNC
  FT_BITMODE_MCUHOST
  FT_BITMODE_FASTOPTO
  FT_BITMODE_CBUS
  FT_BITMODE_SINGLE245

  CBUS_TXDEN 
  CBUS_PWRON 
  CBUS_RXLED  
  CBUS_TXLED  
  CBUS_TXRXLED 
  CBUS_SLEEP  
  CBUS_CLK48  
  CBUS_CLK24  
  CBUS_CLK12  
  CBUS_CLK6  
  CBUS_IOMODE  
  CBUS_BITBANG_WR  
  CBUS_BITBANG_RD 
);

our $VERSION = '0.06';

require XSLoader;
XSLoader::load('FTDI::D2XX', $VERSION);

# Preloaded methods go here.


###########################################
use constant FT_OK => 0;
use constant FT_INVALID_HANDLE => 1;
use constant FT_DEVICE_NOT_FOUND => 2;
use constant FT_DEVICE_NOT_OPENED => 3;
use constant FT_IO_ERROR => 4;
use constant FT_INSUFFICIENT_RESOURCES => 5;
use constant FT_INVALID_PARAMETER => 6;
use constant FT_INVALID_BAUD_RATE => 7;

use constant FT_DEVICE_NOT_OPENED_FOR_ERASE => 8;
use constant FT_DEVICE_NOT_OPENED_FOR_WRITE => 9;
use constant FT_FAILED_TO_WRITE_DEVICE => 10;
use constant FT_EEPROM_READ_FAILED => 11;
use constant FT_EEPROM_WRITE_FAILED => 12;
use constant FT_EEPROM_ERASE_FAILED => 13;
use constant FT_EEPROM_NOT_PRESENT => 14;
use constant FT_EEPROM_NOT_PROGRAMMED => 15;
use constant FT_INVALID_ARGS => 16;
use constant FT_NOT_SUPPORTED => 17;
use constant FT_OTHER_ERROR => 18;

use constant FT_OPEN_BY_SERIAL_NUMBER => 1;
use constant FT_OPEN_BY_DESCRIPTION => 2;
use constant FT_OPEN_BY_LOCATION => 4;

# Baud Rates
use constant FT_BAUD_300 => 300;
use constant FT_BAUD_600 => 600;
use constant FT_BAUD_1200 => 1200;
use constant FT_BAUD_2400 => 2400;
use constant FT_BAUD_4800 => 4800;
use constant FT_BAUD_9600 => 9600;
use constant FT_BAUD_14400 => 14400;
use constant FT_BAUD_19200 => 19200;
use constant FT_BAUD_38400 => 38400;
use constant FT_BAUD_57600 => 57600;
use constant FT_BAUD_115200 => 115200;
use constant FT_BAUD_230400 => 230400;
use constant FT_BAUD_460800 => 460800;
use constant FT_BAUD_921600 => 921600;

# Word Lengths
use constant FT_BITS_8 => 0x08;
use constant FT_BITS_7 => 0x07;
use constant FT_BITS_6 => 0x06;
use constant FT_BITS_5 => 0x05;

# Stop Bits
use constant FT_STOP_BITS_1 => 0x00;
use constant FT_STOP_BITS_1_5 => 0x01;
use constant FT_STOP_BITS_2 => 0x02;

# Parity
use constant FT_PARITY_NONE => 0x00;
use constant FT_PARITY_ODD => 0x01;
use constant FT_PARITY_EVEN => 0x02;
use constant FT_PARITY_MARK => 0x03;
use constant FT_PARITY_SPACE => 0x04;

# Flow Control
use constant FT_FLOW_NONE => 0x0000;
use constant FT_FLOW_RTS_CTS => 0x0100;
use constant FT_FLOW_DTR_DSR => 0x0200;
use constant FT_FLOW_XON_XOFF => 0x0400;

# Purge rx and tx buffers
use constant FT_PURGE_RX => 1;
use constant FT_PURGE_TX => 2;

use constant FT_EVENT_RXCHAR => 1;
use constant FT_EVENT_MODEM_STATUS => 2;
use constant FT_EVENT_LINE_STATUS => 4;

# Timeouts
use constant FT_DEFAULT_RX_TIMEOUT => 300;
use constant FT_DEFAULT_TX_TIMEOUT => 300;

# Enumerated Device types
use constant FT_DEVICE_BM => 0;
use constant FT_DEVICE_AM => 1;
use constant FT_DEVICE_100AX => 2;
use constant FT_DEVICE_UNKNOWN => 3;
use constant FT_DEVICE_2232C => 4;
use constant FT_DEVICE_232R => 5;
use constant FT_DEVICE_2232H => 6;
use constant FT_DEVICE_4232H => 7;

# modes
use constant FT_BITMODE_RESET => 0x00;
use constant FT_BITMODE_ASYNC => 0x01;
use constant FT_BITMODE_MPSSE => 0x02;
use constant FT_BITMODE_SYNC => 0x04;
use constant FT_BITMODE_MCUHOST => 0x08;
use constant FT_BITMODE_FASTOPTO => 0x10;
use constant FT_BITMODE_CBUS => 0x20;
use constant FT_BITMODE_SINGLE245 => 0x40;

# CBUS options
use constant CBUS_TXDEN =>  0x00 ;
use constant CBUS_PWRON =>  0x01 ;
use constant CBUS_RXLED =>  0x02 ;
use constant CBUS_TXLED =>  0x03 ;
use constant CBUS_TXRXLED =>  0x04 ;
use constant CBUS_SLEEP =>  0x05 ;
use constant CBUS_CLK48 =>  0x06 ;
use constant CBUS_CLK24 =>  0x07 ;
use constant CBUS_CLK12 =>  0x08 ;
use constant CBUS_CLK6 =>  0x09 ;
use constant CBUS_IOMODE =>  0x0A ;
use constant CBUS_BITBANG_WR =>  0x0B ;
use constant CBUS_BITBANG_RD =>  0x0C;

#############################################################
## Additional functions

## creat new object and open device
sub new
{
	my $this = shift;
	my $ID = shift;
	my $mode = -1;
	$mode = shift if (@ARGV > 0);
	my $object=0;
	my $status;

	# selct open mode
	if( $mode >= 0 ) {
		$status = FT_OpenEx($ID,$mode,$object);
	} else {
		$status = FT_Open($ID,$object);
	}

	# check result
	if( $status == FT_OK ) {
		bless($object,$this);
		return($object);
	} else {
		return(undef);
	}
}

## DESTROY function
sub DESTROY
{
	my $self = shift;
	if( ref($self) eq "undefinied" ) {
		return(FT_INVALID_HANDLE);
	} else {
		return(FT_Close($self));
	}
}



1;
__END__

=head1 NAME

FTDI::D2XX - Perl extension for interface to FTDI d2xx library (tested with version 0.4.16 linux, see readme for windows)


=head1 SYNOPSIS

  use FTDI::D2XX;
  my $FTD = FTDIId2xx->new(0); # open device with id 0
  unless( $FTD->FT_Write(\@data,@data,$written) == FT_OK ) {
	print "Write error";
  }

  # not needed due to destructor: $FTD->FT_Close();

  OR

  use FTDI::D2XX;
  my $handle;
  FTDI::D2XX::FT_Open($handle,0); # open device with id 0
  unless( FTDI::D2XX::FT_Write($handle,\@data,@data,$written) == FT_OK ) {
	print "Write error";
  }
  FTDI::D2XX::FT_Close($handle);




=head1 DESCRIPTION

This is an interface to the d2xx library from Future Technology Devices International Limited (FTDI). 
The basic idea for this interface comes from the Win32::FTDI:FTD2XX perl module. It was started as a port from the Windows
module to linux but it became a completly new implementation. This modules does not contain any code from the Win32::FTDI:FTD2XX module.
Thanks for the source code from Scott K MacPherson as a starting point.

The mainly all standard functions of the D2XX library excluding the FT_W32_* functions are implemented. The functions can be used as in the D2XX documentation 
or in a object oriented way. 

=head2 STATUS

This is a pre-alpha version. Only small tests have been done by using a test script included in this package and an FT2232L IC. Testers are welcome.

=head2 EXPORT

FT_OK is the only default export. 

Other exportable symbols are:   
C<FT_INVALID_HANDLE
  FT_DEVICE_NOT_FOUND
  FT_DEVICE_NOT_OPENED
  FT_IO_ERROR
  FT_INSUFFICIENT_RESOURCES
  FT_INVALID_PARAMETER
  FT_INVALID_BAUD_RATE
  FT_DEVICE_NOT_OPENED_FOR_ERASE
  FT_DEVICE_NOT_OPENED_FOR_WRITE
  FT_FAILED_TO_WRITE_DEVICE
  FT_EEPROM_READ_FAILED
  FT_EEPROM_WRITE_FAILED
  FT_EEPROM_ERASE_FAILED
  FT_EEPROM_NOT_PRESENT
  FT_EEPROM_NOT_PROGRAMMED
  FT_INVALID_ARGS
  FT_NOT_SUPPORTED
  FT_OTHER_ERROR
  FT_OPEN_BY_SERIAL_NUMBER 
  FT_OPEN_BY_DESCRIPTION
  FT_OPEN_BY_LOCATION
  FT_LIST_NUMBER_ONLY
  FT_LIST_BY_INDEX
  FT_LIST_ALL
  FT_LIST_MASK
  FT_BAUD_300
  FT_BAUD_600
  FT_BAUD_1200
  FT_BAUD_2400
  FT_BAUD_4800
  FT_BAUD_9600
  FT_BAUD_14400
  FT_BAUD_19200
  FT_BAUD_38400
  FT_BAUD_57600
  FT_BAUD_115200
  FT_BAUD_230400
  FT_BAUD_460800
  FT_BAUD_921600
  FT_BITS_8
  FT_BITS_7
  FT_BITS_6
  FT_BITS_5
  FT_STOP_BITS_1
  FT_STOP_BITS_1_5
  FT_STOP_BITS_2
  FT_PARITY_NONE
  FT_PARITY_ODD
  FT_PARITY_EVEN
  FT_PARITY_MARK
  FT_PARITY_SPACE
  FT_FLOW_NONE
  FT_FLOW_RTS_CTS
  FT_FLOW_DTR_DSR
  FT_FLOW_XON_XOFF
  FT_PURGE_RX
  FT_PURGE_TX
  FT_EVENT_RXCHAR	
  FT_EVENT_MODEM_STATUS
  FT_EVENT_LINE_STATUS
  FT_DEFAULT_RX_TIMEOUT
  FT_DEFAULT_TX_TIMEOUT
  FT_DEVICE_BM
  FT_DEVICE_AM
  FT_DEVICE_100AX
  FT_DEVICE_UNKNOWN
  FT_DEVICE_2232C
  FT_DEVICE_232R
  FT_DEVICE_2232H
  FT_DEVICE_4232H
  FT_BITMODE_RESET
  FT_BITMODE_ASYNC
  FT_BITMODE_MPSSE
  FT_BITMODE_SYNC
  FT_BITMODE_MCUHOST
  FT_BITMODE_FASTOPTO
  FT_BITMODE_CBUS
  FT_BITMODE_SINGLE245
  CBUS_TXDEN  
  CBUS_PWRON  
  CBUS_RXLED  
  CBUS_TXLED  
  CBUS_TXRXLED 
  CBUS_SLEEP  
  CBUS_CLK48 
  CBUS_CLK24 
  CBUS_CLK12 
  CBUS_CLK6 
  CBUS_IOMODE  
  CBUS_BITBANG_WR  
  CBUS_BITBANG_RD 
>

=head1 FUNCTIONS and METHODS

The module provides a new constructor which connects a ftdi handle with the module by using bless.
Therefore all FT_functions can be called as a method if a handle is the first parameter.

The following list describes only the differences to the original implementation by FTDI. All functions, except new() returns the status of the operation. Parameters marked by * will be changed by the function. Mosts of the * marked parameter are only feedback from the library. These scalars are not initialized by the xs code - result: $device->FT_GetBitMode($mode) works but not $device->FT_GetBitMode(\$mode) because the library generates a new variable instead of using the existing one.

=item C<New>

Parameters: deviceID [mode]

Returns: Object Reference of the Object FTDI::D2XX

Purpose: Open a FTDI device and return the handle as a object reference. This function behaves like FT_Open with one parameter and like FT_OpenEx with two parameters.

=item C<FT_SetVIDPID>

Parameters: Scalar, Scalar

=item C<FT_GetVIDPID>

Parameters: Scalar*, Scalar* 

=item C<FT_CreateDeviceInfoList>

Parameters: Scalar*

=item C<FT_GetDeviceInfoDetail>

Parameters: Scalar, Scalar*, Scalar*, Scalar*, Scalar*, Scalar*, Scalar*, Reference* 

=item C<FT_Open>

Parameters: Scalar, Reference*

=item C<FT_OpenEx>

Parameters: Scalar, Scalar, Reference*

=item C<FT_Close>

Parameters: Reference

=item C<FT_Read>

Parameters: Reference, ReferenceToArray*, Scalar, Scalar*

=item C<FT_Write>

Parameters: Reference, ReferenceToArray, Scalar, Scalar*

=item C<FT_SetBaudRate>

Parameters: Reference, Scalar

=item C<FT_SetDivisor>

Parameters: Reference, Scalar

=item C<FT_SetDataCharacteristics>

Parameters: Reference, Scalar, Scalar, Scalar

=item C<FT_SetTimeouts>

Parameters: Reference, Scalar, Scalar

=item C<FT_SetFlowControl>

Parameters: Reference, Scalar, Scalar, Scalar

=item C<FT_SetDtr>

Parameters: Reference 

=item C<FT_ClrDtr>

Parameters: Reference 

=item C<FT_SetRts>

Parameters: Reference

=item C<FT_ClrRts>

Parameters: Reference 

=item C<FT_GetModemStatus>

Parameters: Reference, Scalar*

=item C<FT_GetQueueStatus>

Parameters: Reference, Scalar*

=item C<FT_GetDeviceInfo>

Parameters: Reference, Scalar*, Scalar*, Scalar*, Scalar*, Scalar*, Scalar

=item C<FT_GetDriverVersion>

Parameters: Reference, Scalar*
Not supported under Linux and OS X

=item C<FT_GetLibraryVersion>

Parameters: Scalar*
Not supported under Linux and OS X

=item C<FT_GetStatus>

Parameters: Reference, Scalar*, Scalar*, Scalar*

=item C<FT_SetEventNotification>

Currently not implemented in this module.

=item C<FT_SetChars>

Parameters: Reference, Scalar, Scalar, Scalar, Scalar

=item C<FT_SetBreakOn>

Parameters: Reference

=item C<FT_SetBreakOff>

Parameters: Reference 

=item C<FT_Purge>

Parameters: Reference, Scalar

=item C<FT_ResetDevice>

Parameters: Reference 

=item C<FT_ResetPort>

Parameters: Reference 
Only under Windows 2000 and higher supported.

=item C<FT_CyclePort>

Parameters: Reference 
Only under Windows 2000 and higher supported.

=item C<FT_SetResetPipeRetryCount>

Parameters: Reference, Scalar
Only under Windows 2000 and higher supported.

=item C<FT_StopInTask>

Parameters: Reference

=item C<FT_RestartInTask>

Parameters: Reference

=item C<FT_SetDeadmanTimeout>

Parameters: Reference, Scalar

=item C<FT_SetWaitMask>

Parameters: Reference
Not supported under Linux and OS X

=item C<FT_WaitOnMask>

Parameters: Reference
Not supported under Linux and OS X

=item C<FT_ReadEE>

Parameters: Reference, Scalar, Scalar*

=item C<FT_WriteEE>

Parameters: Reference, Scalar, Scalar 

=item C<FT_EraseEE>

Parameters: Reference

=item C<FT_EE_Read>

Not implemented so far. See FT_EE_ReadToArray
 
=item C<FT_EE_ReadToArray>

Parameters: Reference, ReferenceToArray*
This functions read the EEPROM and saves every byte into an arrray. The conversion from array to
hash will be implemented later.

=item C<FT_EE_Program>

Not implemented so far. See FT_EE_ProgramByArray.

=item C<FT_EE_ProgramByArray>

Parameters: Reference, ReferenceToArray
This function writes to EEPROM. The conversion from hash to array will be added later.

=item C<FT_EE_UASize>

Parameters: Reference, Scalar* 

=item C<FT_EE_UARead>

Parameters: Reference, ReferenceToArray*, Scalar, Scalar*

=item C<FT_EE_UAWrite>

Parameters: Reference, ReferenceToArray, Scalar,

=item C<FT_SetLatencyTimer>

Parameters: Reference, Scalar

=item C<FT_GetLatencyTimer>

Parameters: Reference, Scalar*

=item C<FT_SetBitMode>

Parameters: Reference, Scalar, Scalar

=item C<FT_GetBitMode>

Parameters: Reference, Scalar*

=item C<FT_SetUSBParameters>

Parameters: Reference, Scalar, Scalar


=head1 DEPENDENCIES

The FTDI/FTD2XX Drivers, at least CDM 2.04.16 (tested with this version under linux, see readme for windows), must be installed in conjunction
with this module for it to be functional. This package does not contain the ftd2xx.h header file. Please download it from www.ftdichip.com

=head1 BUGS and THINGS TO DO

Please report bugs to me at my email address below.

See the BUGS file in the distribution for known issues and their status.

B<Things to Do>

1) Test, test, test it

2) Complete the functions list


=head1 SEE ALSO

The list of functions showns only the difference to the FTDI D2XX Programmer's Guide. Use it as a reference.

=head1 AUTHOR

Matthias Voelker, E<lt>mvoelker@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Matthias Voelker
This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
