package Device::WS2500PC;



# # ****************************************************************************
# # *** ws2500PC, (c) 2004 by Magnus Schmidt, ws2500@27b-6.de                ***
# # *** Library for interfacing the serial port of the WS2500PC Adapter      ***
# # *** Produced by German Distributor ELV                                   ***
# # ****************************************************************************
# # *** This program is free software; you can redistribute it and/or modify ***
# # *** it under the terms of the GNU General Public License as published by ***
# # *** the Free Software Foundation; either version 2 of the License, or    ***
# # *** (at your option) any later version.                                  ***
# # ****************************************************************************
# # *** History: 0.99   Initial release                                      ***
# # ***          0.99a  Bugfix in distribution                               ***
# # ***          0.99b  Bugfix for reading other sensors than temp1-temp8    ***
# # ***                 ws2500_GetDatasetBulk() added                        *** 
# # ****************************************************************************



# ********************************************************
# *** Imports
# ********************************************************
use strict;
use warnings;
use Carp;
use Device::SerialPort qw(:PARAM :STAT 0.07);
use Time::HiRes        qw (sleep);
use Time::Local        qw(timelocal); 



# ********************************************************
# *** Package Definition
# ********************************************************
require Exporter;
use vars qw (@EXPORT @EXPORT_OK @ISA);
@ISA       = qw (Exporter);
@EXPORT    = qw (ws2500_GetTime ws2500_GetStatus ws2500_GetDataset ws2500_NextDataset);
@EXPORT_OK = qw (ws2500_FirstDataset ws2500_SetDebug ws2500_InterfaceInit ws2500_GetDatasetBulk);
 


# ********************************************************
# *** Prototypes and global variables 
# ********************************************************
sub printhex              ($);
sub send_Command;
sub read_Response         ($;$);
sub init_Interface        ($);
sub close_Interface       ();
sub ws2500_GetTime        ($;$);
sub ws2500_GetStatus      ($;$);
sub ws2500_GetDataset;
sub ws2500_GetDatasetBulk ($;$;$);
sub ws2500_NextDataset;
sub ws2500_FirstDataset   ($);
sub ws2500_SetDebug       ($);
sub ws2500_InterfaceTest  ($);
sub ws2500_InterfaceInit  ($;$);

our %data;
%data = ('debug'=>0, 'maxrepeat'=>10,
	 'commands'=>{'ACTIVATE'=>'0', 'DCF'=>'1', 'NEXTSET'=>'2', 'FIRSTSET'=>'3', 'GETSET'=>'4', 'STATUS'=>'5',
	              'INTERFACETEST'=>'CTST', 'INTERFACEINIT'=>'D'},
	 'markers'=>{'SOH'=>"\x01", 'STX'=>"\x02", 'ETX'=>"\x03", 'EOT'=>"\x04", 
	             'ENQ'=>"\x05", 'ACK'=>"\x06", 
		     'DLE'=>"\x10", 'DC2'=>"\x12", 'DC3'=>"\x13",
		     'NAK'=>"\x15"});
our $VERSION = "0.99";



# ********************************************************
# *** Internal package routines 
# ********************************************************

# Returns a string in the form 2A E3 <STX>
# The special markers used in this interface (like STX=02) are replaced by
# the proper identifier. Only used by the debug messages.
# Params: data    The message to print
# Return: string  A string in the format described above
sub printhex ($) {
	my $data = shift;
	my $result = '';

	return "<no data>" if $data eq '';

	for (my $x=0;$x<length($data);$x++) { 
		my $char = substr($data,$x,1);
		my $printed = 0;

		foreach (keys %{$data{'markers'}}) {
			if ($char eq $data{'markers'}->{$_} and !$printed) {
				$result.=sprintf("<%s> ",$_);
				$printed=1;
			}
		}
		$result.=sprintf("%02X ",ord($char)) unless $printed;
	}

	return $result;
}

# Sends a command to the interface
# This subroutine only encodes and sends a message, it does not care wether
# the sent message has been received/acknowledged or not
# Params: token  A command from $data{'commands'}
#         param  An optional parameter containing additional data
# Return: 1      Always true
sub send_Command {
	my $token = shift;
	my ($checksum,$message,$command,$param);
	
	# Is this a valid command, when not die as this is an internal error
	die "Unknown command '$token'" unless exists $data{'commands'}->{$token};
	$param='';
	$param = shift if scalar @_;
	$command = $data{'commands'}->{$token}.$param;

	# Checksum is negative sum of command value, Bit 7 always set
	foreach (split //, $command) { $checksum+=ord($_); }
	$checksum = (0x100-($checksum & 0xFF)) | 0x80;
	
	# Build message and write to port
	$message = $data{'markers'}->{'SOH'}.$command.chr($checksum).$data{'markers'}->{'EOT'};
	print "Sending '$token': ".(printhex($message))."\n" if $data{'debug'};
	$data{'port'}->write ($message);
	# Bad hack, we have to wait until the command is processed
	# Otherwise we will read only partial data
	sleep (0.03);

	return 1;
}

# Reads a response from the interface
# This routine reads a message from the interface, decodes it and does all integrity checking
# Params: bytes_expected  The number of *message* bytes expected, -1 if not known
#         response        A hash-reference which will be filled with the reponse
# Return: 1               Always true
# The filled in hash reference has the following keys:
# {ok}          1 if the response has been valid and passed all checks, 0 upon failure
# {raw}         Actual data received from the interface
# {message}     The actual message, already decoded without any headers
# {datalength}  The lenght in bytes of the message
# {checksum}    The checksum of the message
sub read_Response ($;$) {
	my $bytes_expected = shift;
	my $response	   = shift;
	
	print "Reading Response ... \n" if $data{'debug'};
	
	# Read data
	# As we do not know how many bytes we expect (due to special char encoding)
	# we poll as long we receive any data in a reasonable interval -> again a bad hack
	$$response{'raw'}='';
	while (my $received=$data{'port'}->read (100)) {
		$$response{'raw'}.=$received;
		sleep (0.01);
	}

	# Did we receive a message with a least 5 bytes (shortest possible message)
	if (length($$response{'raw'})>=5) {
		$$response{'ok'}  = 1;
		# First decode any message sequences for STX/ETX/ENQ
		$$response{'message'} = '';
		for (my $x=1;$x<=length($$response{'raw'})-2;$x++) {
			my $char1 = substr($$response{'raw'},$x,1);
			my $char2 = substr($$response{'raw'},$x+1,1);
			if ($char1 eq $data{'markers'}->{'ENQ'}) {
				if    ($char2 eq $data{'markers'}->{'DC2'}) { $char1 = $data{'markers'}->{'STX'} }
				elsif ($char2 eq $data{'markers'}->{'DC3'}) { $char1 = $data{'markers'}->{'ETX'} }
				elsif ($char2 eq $data{'markers'}->{'NAK'}) { $char1 = $data{'markers'}->{'ENQ'} }
				else  { 
					$$response{'ok'} = 0;
					print "ERROR: Unknown encoding char ".(ord($char2))."\n" if $data{'debug'};
				};
				$x++;
			};
			# WTF ? This isn't documented anywhere ? 
			if (ord($char1)==0xff and ord($char2)==0xff) {
				$x++;
			}
			$$response{'message_all'}.= $char1;
		}
		$$response{'message'} = substr($$response{'message_all'},1,ord(substr($$response{'message_all'},0,1)));
		# Check if the received frame is consistent
		$$response{'datalength'} = ord(substr($$response{'message_all'},0,1));
		$$response{'checksum'}   = ord(substr($$response{'message_all'},length($$response{'message_all'})-1,1));
		# Did we receive enough data
		if ($bytes_expected!=-1 and $$response{'datalength'}!=$bytes_expected and $$response{'ok'}) {
			$$response{'ok'} = 0; 
			print "ERROR: Expected datalength is not correct\n" if $data{'debug'};
		};
		# Are the start and end markers ok ?
		if (substr($$response{'raw'},0,1) ne $data{'markers'}->{'STX'} and $$response{'ok'}) {
			$$response{'ok'} = 0;
			print "ERROR: Start marker not found\n" if $data{'debug'};
		}
		if (substr($$response{'raw'},length($$response{'raw'})-1,1) ne $data{'markers'}->{'ETX'} and $$response{'ok'}) {
			$$response{'ok'} = 0;
			print "ERROR: End marker not found\n" if $data{'debug'};
		}
		# Check for a error message from the interface
		if ($$response{'message'} eq $data{'markers'}->{'NAK'} and $$response{'datalength'}==1 and $$response{'ok'}) {
			$$response{'ok'} = 0;
			print "ERROR: NAK received from interface\n" if $data{'debug'};
		}
		# Calculate and check checksum
		if ($$response{'ok'}) {
			my $calc_checksum=0;
			for (my $x=0;$x<$$response{'datalength'};$x++) {
				$calc_checksum+=ord(substr($$response{'message'},$x,1));
			}
			# Add first to bytes of raw message to checksum
			$calc_checksum+=ord($data{'markers'}->{'STX'}) + $$response{'datalength'} + $$response{'checksum'};
			if (($calc_checksum & 0xFF)!= 0) {
				$$response{'ok'} = 0;
				print "ERROR: Checksum not correct\n" if $data{'debug'};
			}
		}
	} else {
		$$response{'ok'}  = 0;
		print "ERROR: Message received is too short\n" if $data{'debug'};
	}

	print "Response status is: $$response{'ok'}, Message: ".(printhex($$response{'raw'}))."\n" if $data{'debug'};

	return 1;
}

# Tries to initialize the interface
# The interface must be sent an initialization request. The interface will go offline 
# after 71ms when no data is sent.
# Timing is crucial, probably on slow systems this may fail. The initialization request
# is sent up to 100 times, until a valid reponse is received.
# Params: port  The interface to use, e.g. /dev/ttyS0
# Return: 0|1   1 upon success, 0 upon failure
sub init_Interface ($) {
	my $interface = shift;
	my ($port,$x);


	# Setup interface with needed specs
	print "Opening port '$interface'\n" if $data{'debug'};
	$port = new Device::SerialPort ($interface) or croak "Can't open interface '$interface'\n"; 
	$port->baudrate (19200)  or croak "Cannot set baudrate";
	$port->parity   ("even") or croak "Cannot set parity";
	$port->parity_enable(1);
	$port->databits (8)      or croak "Cannot set databits";
	$port->stopbits (2)      or croak "Cannot set stopbits";

	# Activate interface
	# Sequence taken from Rainer Krienke's ws2500 program
	print "Trying to activate interface\n" if $data{'debug'};
	$port->dtr_active(0)     or croak "Cannot set dtr_active off";
	$port->rts_active(1)     or croak "Cannot set rtr_active on";
	sleep (0.09);
	$port->dtr_active(1)     or croak "Cannot set dtr_active on";
	$port->rts_active(0)     or croak "Cannot set rts_active off";
	sleep (0.02);

	# Save for global usage
	$data{'port'} = $port;

	# Send activation data set 
	# Repeat as often as needed until interface responses
	for ($x=0;$x<100;$x++) {
		my %response;

		send_Command ('ACTIVATE');
		read_Response (1,\%response);

		last if $response{'ok'} and $response{'message'} eq $data{'markers'}->{'ACK'};
	}

	print "Status of interface initialization: ".($x!=100?'Success':'Failure')."\n" if $data{'debug'};
	return 0 if $x == 100;
	return 1;

}

# Closes the interface
# Params: port  The port which has been used, e.g. /dev/ttyS0
# Return: 1     Alway true
sub close_Interface () {
	print "Closing interface\n" if $data{'debug'};

	$data{'port'}->close() or croak "Cannot close interface";	

	return 1;
}



# ********************************************************
# *** Main package routines 
# ********************************************************

# Reads the received DCF from the interface
# Params: <Device>,[<DCF-Handling>]
#         Device: The port the interface is connected to, e.g. /dev/ttyS0
#         DCF-Handling: The interface signals if the internal received time
#                       is available (in sync) or not. When DCF-Handling is
#                       set to 1, the routine will return 0 upon DCF failure.
#                       Optional paramater. When not set the signaled error
#                       is ignorred.
# Return: Unix-Timestamp representing the received time, 0 upon failure
sub ws2500_GetTime ($;$) {
	my %response;
	my $dcf_handling=0;
	my $port         = shift;
	$dcf_handling    = shift if scalar @_;
	my ($hour,$minute,$second,$day,$month,$year,$dcfok);

	# Send command
	print "Starting Request: Read DCF Clock\n" if $data{'debug'};
	return 0 unless init_Interface ($port);

	# Try ten times to read interface
	for (my $x=0;$x<$data{'maxrepeat'};$x++) {
		send_Command ('DCF');
		read_Response (6,\%response);

		# Read data
		if ($response{'ok'}) {
			$hour   = sprintf ("%x",ord(substr($response{'message'},0,1)));
			$minute = sprintf ("%x",ord(substr($response{'message'},1,1)));
			$second = ord(substr($response{'message'},2,1));
			$day    = sprintf ("%x",ord(substr($response{'message'},3,1)));
			# BCD, second nibble
			$month  = ord(substr($response{'message'},4,1)) & 0xF;
			# Get bit 7
			$dcfok  = (ord(substr($response{'message'},4,1)) & 0x80) >> 7;
			return 0 if $dcf_handling and !$dcfok;
			# Offset +2000, bad hack, but who cares ;-)
			$year   = sprintf ("%x",ord(substr($response{'message'},5,1)))+2000;
		}

		last if $response{'ok'};
	}

	# Finish
	close_Interface;
	return 0 unless $response{'ok'};

	return timelocal ($second,$minute,$hour,$day,$month-1,$year);
}

# Reads the status of the interface
# A detailed hash reference is returned, containing all status data received.
# Params: port    The interface to connect to, e.g. /dev/ttyS0
#         result  A hash reference which will be filled the status data.
#                 For information about the hash structure see below
# The filled in hash structure contains following data:
# {sensors}->{<name>}               Status about all sensors. Name is 'temp1'...'temp8', 
#                                  'rain', 'wind', 'light' or 'inside' 
# {sensors}->{<name>}->{status'}   Either 'OK', or 'n/a' when this sensor does not exit
# {sensors}->{<name>}->{dropouts'} The Number of dropouts (not received sensor data)
# {sensors}->{address}             The address of the sensor
# {interface}->{'interval'}        The interval in minutes the interface records data
# {interface}->{'language'}        Language ('English' or 'German'), don't know what this means
# {interface}->{'sync_dcf'}        Boolean, contains whether the DCF-clock is in sync
# {interface}->{'with_dcf'}        Boolean, true if DCF is available
# {interface}->{'protocol'}        The uses protocol version for the sensors, either '1.1' or '1.2'
# {interface}->{'type'}            Interface type. Either 'PC_WS2500' or 'WS2500'
# {interface}->{'version'}         Hardware version of the interface (?)
sub ws2500_GetStatus ($;$) {
	my $port   = shift;
	my $result = shift;
	my %response;
	my $time;

	# Request the status data
	print "Starting Request: Read Status\n" if $data{'debug'};
	return 0 unless init_Interface ($port);

	# Try ten times to read interface
	$$result{'valid'} = 0;
	for (my $x=0;$x<$data{'maxrepeat'};$x++) {
		send_Command ('STATUS');
		read_Response (17,\%response);

		if ($response{'ok'}) {
			# Status of sensors
			my $count=0;
			foreach my $sensor (qw (temp1 temp2 temp3 temp4 temp5 temp6 temp7 temp8 rain wind light inside)) {
				my $status = ord(substr($response{'message'},$count,1));
				my $dropouts=0;
				if    ( $status<16)  { $status='n/a'; }
				elsif ( $status==16) { $status='OK'; }
				else  { $dropouts=$status+16; $status='OK'; } 
				$$result{'sensors'}->{$sensor}->{'status'}   = $status;
				$$result{'sensors'}->{$sensor}->{'dropouts'} = $dropouts;
				$$result{'sensors'}->{$sensor}->{'address'} = $1 if $sensor=~ /^temp(\d+)$/;
				$count++;
			}
			# Some misc data
			$$result{'interface'}->{'interval'} = ord(substr($response{'message'},12,1));
			$$result{'interface'}->{'language'} = (ord(substr($response{'message'},13,1)) & 0x1)?'English':'German';
			$$result{'interface'}->{'sync_dcf'} = (ord(substr($response{'message'},13,1)) & 0x2)?1:0;
			$$result{'interface'}->{'with_dcf'} = (ord(substr($response{'message'},13,1)) & 0x4)?1:0;
			$$result{'interface'}->{'protocol'} = (ord(substr($response{'message'},13,1)) & 0x8)?'1.1':'1.2';
			$$result{'interface'}->{'type'}     = (ord(substr($response{'message'},13,1)) & 0x10)?'PC_WS2500':'WS2500';
			$$result{'interface'}->{'version'}  = int(sprintf("%x",ord(substr($response{'message'},14,1))))/10;
			# Some addresses
			$$result{'sensors'}->{'rain'}->{'address'}   = ord(substr($response{'message'}, 15,1)) & 0x7; 
			$$result{'sensors'}->{'wind'}->{'address'}   = (ord(substr($response{'message'},15,1)) & 0x70) >> 4; 
			$$result{'sensors'}->{'light'}->{'address'}  = ord(substr($response{'message'}, 16,1)) & 0x7; 
			$$result{'sensors'}->{'inside'}->{'address'} = (ord(substr($response{'message'},16,1)) & 0x70) >> 4; 

			$$result{'valid'} = 1;
		}

		last if $response{'ok'};
	}

	# Finish
	close_Interface;
	return 0 unless $$result{'valid'};
	return 1;
}

# Request next dataset
# Normally when a dataset is requested from the interface, the internal pointer
# does not increase. Use this function to advance to the next dataset, if any.
# Params: port     The port to connect to, e.g. '/dev/ttyS0'
#         special  When special is set to 'isopen' the interface will not be
#                  opened and will not be closed, for bulk data retrieval
# Return: 0/1/-1   0  Error during communication
#                  1  Success 
#                  -1 No next dataset available
sub ws2500_NextDataset {
	my $port = shift;
	my %response;
	my $valid = 0;
	my $special = '';
	$special = shift if scalar @_;

	if ($special eq '') {
	 	return 0 unless init_Interface ($port);
	}

	# Having a loop here is a bad thing
	for (my $x=0;$x<$data{'maxrepeat'};$x++) {
		send_Command ('NEXTSET');
		read_Response (1,\%response);
		if ($response{'ok'}) {
			$valid=1;
			last;
		}
	}
	close_Interface if $special eq '';

	return 0  unless $valid; 
	return 0  unless $response{'ok'};
	return 1  if $response{'message'} eq $data{'markers'}->{'ACK'};
	return -1 if $response{'message'} eq $data{'markers'}->{'DLE'};

	# Weird ... we should never have reached this point
	return 0;
}

# Reset pointer to first dataset
# Puts the dataset on the oldest record available. All data will be new.
# Params: port  The port to connect to, e.g. '/dev/ttyS0'
# Return: 0/1   0 Error during communication
#               1 Success
sub ws2500_FirstDataset ($) {
	my $port = shift;
	my %response;
	my $valid = 0;

	return 0 unless init_Interface ($port);
	for (my $x=0;$x<$data{'maxrepeat'};$x++) {
		send_Command ('FIRSTSET');
		read_Response (1,\%response);
		if ($response{'ok'} and $response{'message'} eq $data{'markers'}->{'ACK'}) {
			$valid=1;
			last;
		}
	}
	close_Interface;

	return 1 if $valid; 
	return 0;
}

# Read a dataset from the interface
# This function reads the current dataset, to which the internal pointer is set.
# Params: <port>   The device to read from, e.g. /dev/ttyS0
#         <result> A hash reference where the dataset will be stored in.
#                  See below for hash structure
#         <type>   The can be either 'current' or 'next':
#                  'current': Get the current dataset, but do not increase to 
#                             next pointer
#                  'next'   : Get the current dataset. After the has been successfully 
#                             read, advance the internal pointer to the next dataset
# Return: 1 Communication successfull (This does not mean that a dataset has been read)
#         0 Cummunication error, the hash-reference does not contain any valid data
#
# The hash-reference has the following structure:
# {valid}				This hash contains valid data, when set to 1
# {interface}->{timestamp}              The current DCF-time
# {interface}                           See status hash returned by ws2500_GetStatus
# {sensors}                             See status hash returned by ws2500_GetStatus
# {dataset}->{status}                  	Either 'dataset' for a valid dataset, or 'nonew' when no dataset is available  
# {dataset}->{block}                    Block number of dataset
# {dataset}->{timestamp}                Timestamp of dataset
# {dataset}->{tempX}                    Temperature sensors, X is 1 to 8
# {dataset}->{tempX}->{'status'}        1 if this sensor contains valid data, 'n/a' when not available
# {dataset}->{tempX}->{'new'}           New flag is set	
# {dataset}->{tempX}->{'temperature'}   Temperature in Celcius 
# {dataset}->{tempX}->{'humidity'}      Humidity in %, 'n/a' if this sensor is missing 
# {dataset}->{wind}->{'status'}         1 if this sensor contains valid data, 'n/a' when not available
# {dataset}->{wind}->{'new'}	        The new flag is set 
# {dataset}->{wind}->{'speed'}          Wind speed in km/h
# {dataset}->{wind}->{'direction'}      Direction in degree
# {dataset}->{wind}->{'accuracy'}       Average devivation for direction in degree
# {dataset}->{inside}->{'status'}       1 if this sensor contains valid data, 'n/a' when not available
# {dataset}->{inside}->{'new'}          New flag is set	
# {dataset}->{inside}->{'temperature'}  Temperature in Celcius 
# {dataset}->{inside}->{'humidity'}     Humidity in %, 'n/a' if this sensor is missing
# {dataset}->{inside}->{'pressure'}    	Pressure in hPa 
# {dataset}->{rain}->{'status'}         1 if this sensor contains valid data, 'n/a' when not available
# {dataset}->{rain}->{'new'}            New flag is set	
# {dataset}->{rain}->{'counter_ml'}     Current counter
# {dataset}->{rain}->{'counter_ml'}     Current rain counter in ml, delta to previous call is the rainfall
# {dataset}->{light}->{'status'}         1 if this sensor contains valid data, 'n/a' when not available
# {dataset}->{light}->{'new'}            New flag is set	
# {dataset}->{light}->{'duration'}     	Counter in minutes with brightness > 20.000 Lux 
# {dataset}->{light}->{'brightness'}  	Sun brightness in Lux 
# {dataset}->{light}->{'sunflag'}	Sunflag is set, undocumented
sub ws2500_GetDataset {
	my $port   = shift;
	my $result = shift;
	my $type   = shift;
	my %response;
	my $doinit = '';
	$doinit = shift if scalar @_;
	
	print "Starting Request: Read Dataset\n" if $data{'debug'};
	
	if ($doinit eq '' or $doinit eq 'noclose') {
		# First get the time for reference
		$$result{'interface'}->{'timestamp'} = ws2500_GetTime ($port);
		return 0 if $$result{'interface'}->{'timestamp'}<=0;

		# Now the status, so we know which sensor is active
		return 0 unless ws2500_GetStatus ($port,$result);

		# Start up the interface to get the data 
		return 0 unless init_Interface ($port);
	}

	# Try several times to read interface, until we get a valid response
	$$result{'valid'}=0;
	for (my $x=0;$x<$data{'maxrepeat'};$x++) {
		send_Command ('GETSET');
		read_Response (-1,\%response);

		if ($response{'ok'}) {
			unless ($response{'message'} eq $data{'markers'}->{'DLE'}) {
				# New dataset available
				# Prepare the message so we can access it more easy
				my @data = (split //, $response{'message'});
				$$result{'dataset'}->{'block'} = ord($data[0]) + ord($data[1])*0x100;
				$$result{'dataset'}->{'timestamp'} = $$result{'interface'}->{'timestamp'}-
								     ((ord($data[2])+ord($data[3])*0x100)*60);
				# We only have the age in minutes, so cut down to zero seconds
				$$result{'dataset'}->{'timestamp'} = int($$result{'dataset'}->{'timestamp'}/60)*60;
				my $nibble=0;
				foreach my $sensor (qw (temp1 temp2 temp3 temp4 temp5 temp6 temp7 temp8)) {
					my %temp;
					if ($$result{'sensors'}->{$sensor}->{'status'} ne 'n/a') {
						my $sign = +1;
						for (my $y=0;$y<5;$y++) {
							if ($nibble % 2) { $temp{$y}=(ord($data[int($nibble/2)+4]) & 0xF0) >> 4; }
							            else { $temp{$y}=ord($data[int($nibble/2)+4]) & 0xF; }
							$nibble++;
						} # for

						# First the temperature
						# Test for plus/minus
						$sign=-1 if $temp{'2'} & 0x8;
						# Mask the sign bit
						$temp{'2'}=$temp{'2'} & 0x7;
						$$result{'dataset'}->{$sensor}->{'temperature'} = ($temp{'0'}/10 + $temp{'1'} + $temp{2}*10)*$sign;
						$$result{'dataset'}->{$sensor}->{'status'} = 'ok';

						# Now the humidity
						# Is the new flag set
						$$result{'dataset'}->{$sensor}->{'new'} = ($temp{'4'} & 0x8) >> 3;
						# Mask the new flag
						$temp{'4'}=$temp{'4'} & 0x7;
						if ($temp{'3'}<=9) {
							$$result{'dataset'}->{$sensor}->{'humidity'} = ($temp{'3'} + $temp{'4'}*10)+20;
						} else {
							$$result{'dataset'}->{$sensor}->{'humidity'} = 'n/a';
						}
					} else {
						# This sensor is not available
						$$result{'dataset'}->{$sensor}->{'status'} = 'n/a';
						$nibble+=5;
					}

					
				} # foreach temperature

				my $of=3;
				# Wind direction
				if ($$result{'sensors'}->{'wind'}->{'status'} ne 'n/a') {
					$$result{'dataset'}->{'wind'}->{'speed'} = ((ord($data[$of+21]) & 0xF)/10)+
									           ((ord($data[$of+21]) & 0xF0) >> 4)+
					                                           ((ord($data[$of+22]) & 0xF)*10);
					$$result{'dataset'}->{'wind'}->{'direction'} = (((ord($data[$of+22]) & 0xF0) >> 4)*10)+
										       ((ord($data[$of+23]) & 0x3)*100);
					$$result{'dataset'}->{'wind'}->{'direction'}+=5 if ord($data[$of+23]) & 0x10;
					my $accuracy = (ord($data[$of+23]) & 0xC) >> 2;
					$$result{'dataset'}->{'wind'}->{'accuracy'}=0    if $accuracy==0;
					$$result{'dataset'}->{'wind'}->{'accuracy'}=22.5 if $accuracy==1;
					$$result{'dataset'}->{'wind'}->{'accuracy'}=45   if $accuracy==2;
					$$result{'dataset'}->{'wind'}->{'accuracy'}=67.5 if $accuracy==3;
					$$result{'dataset'}->{'wind'}->{'new'} = (ord($data[$of+23]) & 0x8) >> 3;
					$$result{'dataset'}->{'wind'}->{'status'} = 'ok';
				} else {
					$$result{'dataset'}->{'wind'}->{'status'} = 'n/a';
				}

				# Inside sensor
				if ($$result{'sensors'}->{'inside'}->{'status'} ne 'n/a') {
					$$result{'dataset'}->{'inside'}->{'pressure'} = (ord($data[$of+24]) & 0xF)+
										        (((ord($data[$of+24]) & 0xF0)>>4)*10)+
											((ord($data[$of+25]) & 0xF)*100);
					my $sign=1;
					$sign=-1 if ord($data[$of+26]) & 0x80;
					$data[$of+26]=chr(ord($data[$of+26]) & 0x7F);
					$$result{'dataset'}->{'inside'}->{'temperature'} = ((((ord($data[$of+25]) & 0xF0)>>4)/10)+
					                                                   (ord($data[$of+26]) & 0xF)+
											   (((ord($data[$of+26]) & 0xF0)>>4)*10))*$sign;
					if ((ord($data[$of+27]) & 0xF)<=9) {
						$$result{'dataset'}->{'inside'}->{'humidity'} = (ord($data[$of+27]) & 0xF)+
						                                                (((ord($data[$of+27]) & 0x70)>>4)*10)+
												20;
					} else {
						$$result{'dataset'}->{'inside'}->{'humidity'} = 'n/a';
					}
					$$result{'dataset'}->{'inside'}->{'new'} = (ord($data[$of+27]) & 0x80) >> 7;
					$$result{'dataset'}->{'inside'}->{'status'} = 'ok';
				} else {
					$$result{'dataset'}->{'inside'}->{'status'} = 'n/a';
				}
				
				# Rain sensor
				if ($$result{'sensors'}->{'rain'}->{'status'} ne 'n/a') {
					$$result{'dataset'}->{'rain'}->{'counter'} = ord($data[$of+28])+
										     (ord($data[$of+29]) & 0x7)*0x100;
					$$result{'dataset'}->{'rain'}->{'counter_ml'} =	$$result{'dataset'}->{'rain'}->{'counter'}*370;
					$$result{'dataset'}->{'rain'}->{'status'} = 'ok';
				} else {
					$$result{'dataset'}->{'rain'}->{'status'} = 'n/a';
				}

				# Light sensor
				if ($$result{'sensors'}->{'light'}->{'status'} ne 'n/a') {
					$$result{'dataset'}->{'light'}->{'duration'} = ((ord($data[$of+29]) & 0xF0)>>4)+
										       ((ord($data[$of+30]) & 0xF)*0x10)+
										       (((ord($data[$of+30]) & 0xF0)>>4)*0x100);
					$$result{'dataset'}->{'light'}->{'brightness'} = ((ord($data[$of+31]) & 0xF)+
											 (((ord($data[$of+31]) & 0xF0)>>4)*10)+
											 ((ord($data[$of+32]) & 0xF)*100))*
											 (10**((ord($data[$of+32]) & 0x30)>>4));
					$$result{'dataset'}->{'light'}->{'sun_flag'} = (ord($data[$of+32]) & 0x40) >> 6;
					$$result{'dataset'}->{'light'}->{'new'} = (ord($data[$of+32]) & 0x80) >> 7;
					$$result{'dataset'}->{'light'}->{'status'} = 'ok';
				} else {
					$$result{'dataset'}->{'light'}->{'status'} = 'n/a';
				}

				$$result{'dataset'}->{'status'} = 'dataset';
			} else {
				# No new dataset available
				$$result{'dataset'}->{'status'} = 'nonew';
			}
			
			$$result{'valid'} = 1;
		}
		last if $$result{'valid'};
	}
	close_Interface if $doinit eq ''; 

	# Upon request advance to next dataset
	if ($type eq 'next' and $$result{'valid'} and $$result{'dataset'}->{'status'} eq 'dataset') {
		if ($doinit eq '') {
			ws2500_NextDataset ($port);
		} else {
			ws2500_NextDataset ($port,'isopen');
		}
	}

	# Finish
	return 0 unless $$result{'valid'};
	return 1;
}

# Get bulk dataset data
# Whereas the normal Getdataset function initializes and closes the interface for each
# dataset, this function opens the communication only once, and serveral dataset are
# then transferred in a batch. This greatly improves the performance
# Params: port       The port to use, e.g. '/dev/ttyS0'
#         result     The result hash reference, see below
#         bulkcount  The number of datasets to retrieve in one run
# Return: 1          Always true
# The result hash has the following structure:
# {valid}        If this bulkdata is valid
# {bulkcount}    The actual number of retrieved datasets
# {bulk}         An array. Each element contains a dataset hash reference
#                See the ws2500_GetDataset function for the structure
# {interface}    See ws2500_GetDataset function
# {sensors}      See ws2500_GetDataset function
sub ws2500_GetDatasetBulk ($;$;$) {
	my $port      = shift;
	my $result    = shift;
	my $bulkcount = shift;
	my @bulkdata;
	my %firstdataset;

	for (my $x=0;$x<$bulkcount;$x++) {
		if ($x==0) {
			# Request first dataset
			# As we supply the 'noclose' param the connection to the interface stays
			# open an we can request additional datasets without reestablishing the connection
			my $res = ws2500_GetDataset ($port,\%firstdataset,'next','noclose');
			# Check for errors
			if ($res and $firstdataset{'valid'} and $firstdataset{'dataset'}->{'status'} eq 'dataset') {
				push @bulkdata, $firstdataset{'dataset'};
			} else {
				last;
			}
		} else {
			# Further datasets, use the firstdataset as base
			my %result = %firstdataset;
			delete $result{'dataset'};
			my $res = ws2500_GetDataset ($port,\%result,'next','noinit');
			# Check for errors
			if ($res and $result{'valid'} and $result{'dataset'}->{'status'} eq 'dataset') {
				push @bulkdata, $result{'dataset'};
			} else {
				$firstdataset{'valid'} = $result{'valid'};	
				last;
			}
		}
	}
	# Prepare the result
	$$result{'valid'}     = $firstdataset{'valid'};
	$$result{'interface'} = $firstdataset{'interface'};
	$$result{'sensors'}   = $firstdataset{'sensors'};
	# Save the bulkdata
	$$result{'bulk'} = \@bulkdata;
	$$result{'bulkcount'} = scalar @bulkdata;

	close_Interface;

	return 1;
}


# Test Interface
# This function does not work and is not properly documented. See inline comments below
# Params: port  The port to use, e.g. /dev/ttyS0
# Return: 0     Always false, as it does not work
sub ws2500_InterfaceTest ($) {
	my $port = shift;
	my %response;
	my $valid = 0;

	return 0;

	# This doesn't seem to work. Acoording to the docu we have to send either
	# 'C' or 'CTST'. However both variants fail, and there is either no data
	# received at all, or gibberish. Furthermore the interface is not reset.
	# If anyone has a clear documentation how to activate this (and what to
	# to with it), please send them.
#	return 0 unless init_Interface ($port);
#	for (my $x=0;$x<$data{'maxrepeat'};$x++) {
#		send_Command ('INTERFACETEST');
#		sleep (0.04);
#		read_Response (1,\%response);
#		if ($response{'ok'} and $response{'message'} eq $data{'markers'}->{'ACK'}) {
#			$valid=1;
#			last;
#		}
#	}
#	close_Interface;
#
#	return 1 if $valid; 
#	return 0;
}

# Initialize the interface we new data
# Params: port  The port to sent the data, e.g. /dev/ttyS0
#         data  A hash-reference containing the configuration, see below
# Return: 0|1   True upon success, else False
# The configuration-hash must contain following keys:
# {first}        Minutes to wait after init to resume normal operation, 0..63 minutes
# {interval}     The interval in minutes to record data, 2..63 minutes
# {addr-rain}    The address of the rain sensor, 0..7
# {addr-wind}    The address of the wind sensor, 0..7
# {addr-inside}  The address of the inside sensor, 0..7
# {addr-light}   The address of the light sensor, 0..7
# {version}      The protocal version to use: 1 (V1.1) or 2 (V1.2)
sub ws2500_InterfaceInit ($;$) {
	my $port = shift;
	my $data = shift;
	my %response;
	my $valid = 0;
	my $message;

	# {'first'=>12,'interval'=>3,'addr-rain'=>7,'addr-wind'=>7,'addr-inside'=>7,'addr-ligth'=>7,'version'});

	# Prepare the message (4 Bytes)
	# First some checks if the data is correct
	foreach my $token (qw (first interval addr-rain addr-wind addr-inside addr-light version)) {
		croak "Token '$token' missing in configuration hash" unless exists $$data{$token};
		croak "Token '$token' is not a number ('$$data{'$token'}') " unless $$data{$token}=~ /^\d+$/;
	}
	# Some sanity checks 
	croak "First interval 'first' must be between 0 and 63"        if $$data{'first'}<0 or $$data{'first'}>63;
	croak "Recording interval 'interval' must be between 2 and 63" if $$data{'interval'}<2 or $$data{'interval'}>63;
	foreach my $token (qw (addr-rain addr-wind addr-inside addr-light)) {
		croak "Sensor address for '$token' must be between 0 and 7" if $$data{$token}<0 or $$data{$token}>7;
	}
	croak "Version must be either 1 (V1.1) or 2 (V1.2)" if $$data{'version'}<1 or $$data{'version'}>2;

	# Put everything together
	my $addr1 = $$data{'addr-rain'} + ($$data{'addr-wind'} << 4) + 0x80;
	$addr1|=0x8 if $$data{'version'}==1;
	my $addr2 = $$data{'addr-light'} + ($$data{'addr-inside'} << 4) + 0x80;
	# Now build the message
	$message = chr($$data{'first'}).chr($$data{'interval'}).chr($addr1).chr($addr2);

	# Send the command
	return 0 unless init_Interface ($port);
	for (my $x=0;$x<$data{'maxrepeat'};$x++) {
		send_Command ('INTERFACEINIT',$message);
		read_Response (1,\%response);
		if ($response{'ok'} and $response{'message'} eq $data{'markers'}->{'ACK'}) {
			$valid=1;
			last;
		}
	}
	close_Interface;

	return 1 if $valid; 
	return 0;
}

# Enables debug
# When debug is enabled, a lot of information is printed to STDOUT
# Params: debug  1 to enable debug, 0 to disable (default)
# Return: 1      Always true
sub ws2500_SetDebug ($) {
	my $debug = shift;

	croak "Debug must be called with 0 or 1 as argument" if $debug>1 or $debug<0;

	$data{'debug'} = $debug;

	return 1;
}



1;

