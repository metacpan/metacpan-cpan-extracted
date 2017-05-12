package Device::Quasar3108;

################
#
# Device::Quasar3108 - Control Quasar Electronics Kit Number 3108
#
# Nicholas J Humfrey
# njh@ecs.soton.ac.uk
#
# See the bottom of this file for the POD documentation. 
#


use strict;
use vars qw/$VERSION $DEFAULT_TIMEOUT $DEFAULT_PERIOD/;

use Device::SerialPort;
use Time::HiRes qw( time sleep alarm );
use Carp;

$VERSION="0.04";
$DEFAULT_TIMEOUT=5;		# Default timeout is 5 seconds
$DEFAULT_PERIOD=0.25;	# Default flash period



sub new {
    my $class = shift;
    my ($portname, $timeout) = @_;
    
    # Defaults
	$portname = '/dev/ttyS0' unless (defined $portname);
	$timeout = $DEFAULT_TIMEOUT unless (defined $timeout);


    # Create serial port object
	my $port = new Device::SerialPort( $portname )
		|| croak "Can't open serial port ($portname): $!\n";


	# Check serial port features
	croak "ioctl isn't available for serial port: $portname"
	unless ($port->can_ioctl());
	croak "status isn't available for serial port: $portname"
	unless ($port->can_status());
	croak "write_done isn't available for serial port: $portname"
	unless ($port->can_write_done());


	# Configure the serial port
	$port->baudrate(9600)    || croak ("Failed to set baud rate");
	$port->parity("none")    || croak ("Failed to set parity");
	$port->databits(8)       || croak ("Failed to set data bits");
	$port->stopbits(1)       || croak ("Failed to set stop bits");
	$port->handshake("none") || croak ("Failed to set hardware handshaking");
#	$port->stty_echo(0)      || croak ("Failed to turn off echo");
	$port->write_settings()  || croak ("Failed to write settings");

	$port->read_char_time(0);     # don't wait for each character
	$port->read_const_time(500);  # 1/2 second per unfulfilled "read" call




	# Bless me
    my $self = {
    	port => $port,
    	timeout => $timeout,
    	debug => 0,
    };
    bless $self, $class;


    return $self;
}


## Version of the hardware firmware
sub firmware_version {
    my $self=shift;
	
	$self->serial_write( '?' );
	
	return $self->serial_read();
}




## Version of perl module
sub version {
    return $VERSION;
}


## Check module is still there
sub ping {
    my $self=shift;
	
	$self->serial_write( '' );
	my $ok = $self->serial_read( 1 );
	if ($ok eq '#') { return 1; } # Success
	else { return 0; }  # Failed
}


## Turn specified relay on
sub relay_on {
	my $self=shift;
	my ($num) = @_;
	croak('Usage: relay_on( $num );') unless (defined $num);
	
	$self->serial_write( 'N'.int($num) );
	my $ok = $self->serial_read( 1 );
	if ($ok eq '#') { return 1; } # Success
	else { return 0; }  # Failed
}


## Turn specified relay off
sub relay_off {
	my $self=shift;
	my ($num) = @_;
	croak('Usage: relay_off( $num );') unless (defined $num);

	$self->serial_write( 'F'.int($num) );
	my $ok = $self->serial_read( 1 );
	if ($ok eq '#') { return 1; } # Success
	else { return 0; }  # Failed
}

## Toggle specified relay
sub relay_toggle {
	my $self=shift;
	my ($num) = @_;
	croak('Usage: relay_toggle( $num );') unless (defined $num);

	$self->serial_write( 'T'.int($num) );
	my $ok = $self->serial_read( 1 );
	if ($ok eq '#') { return 1; } # Success
	else { return 0; }  # Failed
}


## Toggle relay on and then off again
sub relay_flash {
	my $self=shift;
	my ($num,$period) = @_;
	croak('Usage: relay_flash( $num, [$period] );') unless (defined $num);

	# Use default period if none given
	$period = $DEFAULT_PERIOD unless (defined $period);
	
	# Turn relay on, sleep for period, turn relay off again
	$self->relay_on( $num ) || return 0;
	sleep( $period );
	$self->relay_off( $num ) || return 0;

	# Success
	return 1;
}


## Set all relays to specified value
sub relay_set {
	my $self=shift;
	my ($value) = @_;
	croak('Usage: relay_set( $value );') unless (defined $value);

	$self->serial_write( 'R'.sprintf("%2.2x",$value) );
	my $ok = $self->serial_read( 1 );
	if ($ok eq '#') { return 1; } # Success
	else { return 0; }  # Failed
}


## Get state of specified relay
sub relay_status {
	my $self=shift;
	my ($num) = @_;
	$num = 0 unless defined ($num);
	
	$self->serial_write( 'S'.$num );
	
	
	# Return the result
	my $status;
	if ($num==0) { $status = $self->serial_read( 4 ); }
	else { $status = $self->serial_read( 3 ); }
	
	# Look for a '#' prompt on the end
	my $ok = $self->serial_read( 1 );
	if ($ok ne '#') { warn "relay_status() failed   :-("; }
	
	return $status;
}


## Get state of specified input
sub input_status {
	my $self=shift;
	my ($num) = @_;
	$num = 0 unless defined ($num);
	
	$self->serial_write( 'I'.$num );
	
	
	# Return the result
	my $status;
	if ($num==0) { $status = $self->serial_read( 4 ); }
	else { $status = $self->serial_read( 3 ); }
	
	# Look for a '#' prompt on the end
	my $ok = $self->serial_read( 1 );
	if ($ok ne '#') { warn "input_status() failed   :-("; }
	
	return $status;
}




### Internal Methods ###

sub serial_write {
    my $self=shift;
	my ($string) = @_;
	my $bytes = 0;

	# if it doesn't end with a '\r' then append one
	$string .= "\r\n" if ($string !~ /\r\n?$/);

	
	eval {
		local $SIG{ALRM} = sub { die "Timed out."; };
		alarm($self->{timeout});
		
		# Send it
		$bytes = $self->{port}->write( $string );
		
		# Block until it is sent
		while(($self->{port}->write_done(0))[0] == 0) {}
		
		alarm 0;
	};
	
	if ($@) {
		die unless $@ =~ /Timed out./;   # propagate unexpected errors
		# timed out
		carp "Timed out while writing to serial port.\n";
		return undef;
 	}
 	
 	
	# Debugging: display what was read in
	if ($self->{debug}) {
		my $serial_debug = $string;
		$serial_debug=~s/([^\040-\176])/sprintf("{0x%02X}",ord($1))/ge;
		print "written ->$serial_debug<- ($bytes)\n";
	}

 	# Read in the echoed back characters
 	my $echo = $self->serial_read( length($string) );
	### FIXME: Could do error checking here ###
}


sub serial_read
{
    my $self=shift;
    my ($bytes_wanted) = @_;
	my ($string, $bytes) = ('', 0);
	
	# Default bytes wanted is 255
	$bytes_wanted=255 unless (defined $bytes_wanted);
	

	eval {
		local $SIG{ALRM} = sub { die "Timed out."; };
		alarm($self->{timeout});
		
		while (1) {
			my ($count,$got)=$self->{port}->read($bytes_wanted);
			$string.=$got;
			$bytes+=$count;
			
			## All commands end in the command prompt '#'
			last if ($string =~ /#$/ or $bytes>=$bytes_wanted);
		}
		
		alarm 0;
	};
	
	if ($@) {
		die unless $@ =~ /Timed out./;   # propagate unexpected errors
		# timed out
		carp "Timed out while reading from serial port.\n";
		return undef;
 	}
 
	# Debugging: display what was read in
	if ($self->{debug}) {
		my $debug_str = $string;
		$debug_str=~s/([^\040-\176])/sprintf("{0x%02X}",ord($1))/ge;
		print "saw ->$debug_str<- ($bytes) (wanted=$bytes_wanted)\n";
	}
 
 
 	# Clean up response
 	if ($bytes_wanted == 1) {
 		return $string;
 	} else {
 		# Remove whitespace from start and end
		($string) = ($string =~ /^\s*(.*?)\s*\#?$/);
 		return $string;
 	}
}


sub DESTROY {
    my $self=shift;
    
    $self->{port}->close || carp "close serial port failed";
}




1;

__END__

=pod

=head1 NAME

Device::Quasar3108 - Control Quasar Electronics Serial I/O Module

=head1 SYNOPSIS

  use Device::Quasar3108;

  my $io = new Device::Quasar3108( '/dev/ttyS0' );

  # Turn all relays off
  $io->relay_set( 0 );
  
  # Turn relay 1 on
  $io->relay_on( 1 );

  # Get status of input 2
  my $status = $io->input_status( 2 );
  

=head1 DESCRIPTION

Device::Quasar3108 is a perl module for controlling 
Quasar Electronics Serial Isolated I/O module (kit number 3108).
The kit has eight relays and four opto-isolated inputs.
http://www.quasarelectronics.com/3108.htm

It seems very similar (identical?) to Carl's Electronic Kits 
number CK1610:
http://www.electronickits.com/kit/complete/elec/ck1610.htm

The perl module was tested on Debian Linux 3.1, but should work on 
most POSIX systems.

Relays are numbered 1 to 8 and inputs are numbers 1 to 4.


=head2 METHODS

=over 4


=item $io = new Device::Quasar3108( $port, [$timeout] )

The new method opens and configures the serial port to talk 
to the Quasar 3108 serial module. It does not send any 
commands to the kit itself. 

Use 'ping()' to ensure that you are communicating with the 
module correctly.


=item $io->relay_on( $relay_number )

Turns on the specified relay.
Returns 1 if successful or 0 on failure.


=item $io->relay_on( $relay_number )

Turns off the specified relay.
Returns 1 if successful or 0 on failure.


=item $io->relay_toggle( $relay_number )

Toggle the specified relay.
Returns 1 if successful or 0 on failure.


=item $io->relay_flash( $relay_number, [$period] )

Turn the specified relay on then off again.
The period the relay is turned on for is in seconds, 
the default is 0.25 seconds.

Returns 1 if successful or 0 on failure.


=item $io->relay_set( $value )

Set all the relays at once, using an 8-bit number.
Returns 1 if successful or 0 on failure.


=item $io->relay_status( $relay_number )

Gets the current status (0/1) of the specified relay.
Use relay number 0 to return the status of all the relays 
as an 8-bit hexadecimal number.


=item $io->input_status( $input_number )

Gets the current status (0/1) of the specified opto-coupled input.
Use input number 0 to return the status of all the inputs  
as an 8-bit hexadecimal number (top nibble is always 0).


=item $io->version()

Returns the version number of the perl module.


=item $io->firmware_version()

Returns the firmware version string of the hardware.


=item $io->ping()

This method just sends a return character to the module 
to check to see if it is still there. If the module returns the 
command prompt correctly ('#'), then this function returns 1, 
otherwise it returns 0.


=back

=head1 SEE ALSO

L<Device::Serial>

L<http://www.quasarelectronics.com/3108.htm>


=head1 BUGS

Please report any bugs or feature requests to
C<bug-device-quasar3108@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you will automatically
be notified of progress on your bug as I make changes.


=head1 AUTHOR

Nicholas J Humfrey, njh@ecs.soton.ac.uk


=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 Nicholas J Humfrey

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.005 or,
at your option, any later version of Perl 5 you may have available.

=cut

