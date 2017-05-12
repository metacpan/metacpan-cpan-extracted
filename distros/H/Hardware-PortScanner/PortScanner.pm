#!/usr/bin/perl

package Hardware::PortScanner;

our $debug = 0;

our $IsWin = 1 if ( $^O eq 'MSWin32' );

if ($IsWin) {
    require Win32::SerialPort;
    Win32::SerialPort::debug( "true", "True" ) if ($debug);
}
else {
    require Device::SerialPort;
    Device::SerialPort::debug( "true", "True" ) if ($debug);
}

use Data::Dumper;    # Remove before production

# $Data::Dumper::Useqq = 1; # Remove before production

use Carp;

# $Carp::Verbose = 0;

use strict;
use warnings;

our $VERSION;
$VERSION = '0.51';

# PortScanner constructor

sub new(;@) {
    my $serial = bless( {} );
    my $class = shift if ( $_[0] =~ /::/ );
    my $parm;
    my $value;
    my $parm_found;

    # Default

    $serial->{MAX_PORT} = 20;

    # Parse Parameters

    while ( $parm = uc shift ) {
        $parm_found = 0;
        $value      = shift;

        if ( $parm eq "MAX_PORT" ) {
            $value =~ s/^COM//i;

            if ( $value !~ /^\d+$/ ) {
                croak "ERROR: (new): MAX_PORT \$value\" must be a number\n";
            }
            $serial->{MAX_PORT} = $value;
            $parm_found++;
        }

        if ( !$parm_found ) {
            croak "Parmeter passed to new() \"$parm\" is not valid\n";
        }
    }

    # These must be here - they are not for show

    # This one can be changed
    $serial->{READ_CONST_TIME} = 100;    # in msecs

    # This one can be changed but it will mess up our wait time calculations (since it is ignored)
    $serial->{READ_CHAR_TIME} = 0;       # in msecs

    return $serial;
}

# Creates the port name from a com number portably

sub _get_com_device_name($) {
    my $serial   = shift;
    my $com_port = shift;

    if ($IsWin) {

        # Yea, this is some weird windows crap
        return '\\\\.\\' . "COM$com_port";
    }
    else {
        return sprintf( '/dev/ttyS%d', $com_port - 1 );
    }

}

# get a connection to a port portably

sub _get_com_connection($;$) {
    my $serial   = shift;
    my $com_port = shift;
    my $quite    = shift || 1;
    my $com_device_name;
    my $PortObj;

    $com_device_name = $serial->_get_com_device_name($com_port);

    {
        local $SIG{__WARN__} = sub {
            my $err;

            if ( grep { $_ =~ /can.t getattr:/ } @_ ) {
                $err = "      Warning: (get_connection): " . join( " ", @_ );
                $err =~ s/\015?\012$//;
                $serial->_add_scan_log($err);
            }
            else {
                print STDERR @_;
            }
            return 1;
        };

        if ($IsWin) {
            $PortObj = new Win32::SerialPort( "$com_device_name", $quite );

        }
        else {
            $PortObj = new Device::SerialPort( "$com_device_name", $quite );
        }
    }

    return $PortObj;

}

# Internal method to collect messages for scan_log

sub _add_scan_log($) {
    my $serial = shift;
    push( @{ $serial->{SCAN_LOG} }, @_ );

    print "DEBUG: $_[0] \n" if ($debug);
}

sub scan_log($) {
    my $serial   = shift;
    my @scan_log = ();

    @{ $serial->{SCAN_LOG} } = () if ( !defined( $serial->{SCAN_LOG} ) );

    foreach ( @{ $serial->{SCAN_LOG} } ) {
        s/\015/\\r/g;
        s/\012/\\n/g;
        s/\011/\\t/g;
        push( @scan_log, $_ );
    }

    return @scan_log;
}

sub scan_report() {
    my $serial = shift;

    foreach ( $serial->scan_log ) {
        print "$_\n";
    }
}

sub num_found_devices($) {
    my $serial = shift;

    return defined( $serial->{FOUND_DEVICE} ) ? scalar( @{ $serial->{FOUND_DEVICE} } ) : 0;
}

sub found_devices($) {
    my $serial = shift;

    return defined( $serial->{FOUND_DEVICE} ) ? @{ $serial->{FOUND_DEVICE} } : ();
}

sub connection($) {
    my $serial = shift;

    return $serial->{CONNECTION};
}

sub available_com_ports(;@) {
    my $serial = shift;
    my $com_port;
    my $com_device_name;
    my @ports;
    my $PortObj;

    for ( $com_port = 1 ; $com_port <= $serial->{MAX_PORT} ; $com_port++ ) {

        $PortObj = $serial->_get_com_connection($com_port);

        if ($PortObj) {
            push( @ports, $com_port );
            $PortObj->close;
            undef $PortObj;
        }

        undef $PortObj;    # Just extra safe measure
    }

    return @ports;
}

sub scan_ports(;@) {
    my $serial = shift;
    my $com_port;
    my $com_device_name;
    my $PortObj;
    my $feedback;
    my $count_in;
    my $send;
    my $baud;
    my $parm;
    my $value;
    my $key;
    my ( $databits, $parity, $stopbits, $handshake );
    my $setting;
    my $device;
    my $config = $serial->{SEARCH_PARM} = {};
    my $parm_found;
    my $read_iterations;
    my $iterations;
    my $chars = 0;
    my ( $bytes_read, $data_read );
    my $waited;

    $serial->_add_scan_log("Scan Ports Request");
    $serial->_add_scan_log("==================");

    # Parse parameters

    while ( $parm = uc shift ) {
        $value      = shift;
        $parm_found = 0;

        $key = "BAUD";
        if ( $parm eq $key ) {
            if ( ref $value eq "ARRAY" ) {
                @{ $config->{$key} } = @{$value};
            }
            elsif ( ref $value eq "" ) {
                @{ $config->{$key} } = ($value);
            }
            else {
                croak "ERROR: (scan_ports): $key value must be either a SCALAR or ARRAY REF\n";
            }

            foreach ( @{ $config->{$key} } ) {
                if ( !/^\d+$/ ) {
                    croak "ERROR: (scan_ports): BAUD rate \$_\" not valid\n";
                }
            }
            $parm_found++;
        }

        $key = "COM";
        if ( $parm eq $key ) {

            if ( ref $value eq "ARRAY" ) {
                @{ $config->{$key} } = map { s/^COM(\d+)/$1/; $_; } @{$value};
            }
            elsif ( ref $value eq "" ) {
                @{ $config->{$key} } = map { s/^COM(\d+)/$1/; $_; } ($value);
            }
            else {
                croak "ERROR: (scan_ports): $key value must be either a SCALAR or ARRAY REF\n";
            }

            foreach ( @{ $config->{$key} } ) {
                if ( !( /^\d+$/ && $_ > 0 && $_ <= 50 ) ) {
                    croak "ERROR: (scan_ports): COM port \"$_\" not valid\n";
                }
            }
            $parm_found++;
        }

        $key = "SETTING";
        if ( $parm eq $key ) {
            foreach ( ref $value eq "ARRAY" ? @{$value} : ($value) ) {

                $value = uc $value;
                if (/^([5678])([NEO])([12])([NRX])?$/) {
                    no warnings;

                    $databits  = $1;
                    $parity    = $2 eq "E" ? "even" : ( $2 eq "O" ? "odd" : "none" );
                    $stopbits  = $3;
                    $handshake = $4 eq "R" ? "rts" : ( $4 eq "X" ? "xoff" : "none" );

                    push(
                        @{ $config->{SETTING} },
                        {
                            DATABITS  => $databits,
                            PARITY    => $parity,
                            STOPBITS  => $stopbits,
                            HANDSHAKE => $handshake,
                            SETTING   => $_
                        }
                    );
                }
                else {
                    croak "ERROR: (scan_ports): SETTING value of \"$_\" is not valid\n";
                }
            }
            $parm_found++;
        }

        $key = "MAX_WAIT";
        if ( $parm eq $key ) {
            if ( $value !~ /^\d+$/ && $value !~ /^\d+[.]\d+$/ ) {
                croak "ERROR: (scan_ports): $key value must be an integer or float in seconds\n";
            }

            if ( ref $value eq "" ) {
                $config->{$key} = $value;
            }
            else {
                croak "ERROR: (scan_ports): $key value must be a SCALAR\n";
            }
            $parm_found++;
        }

        $key = "TEST_STRING";
        if ( $parm eq $key ) {
            if ( ref $value eq "" ) {
                $config->{$key} = $value;
            }
            else {
                croak "ERROR: (scan_ports): $key value must be a SCALAR\n";
            }
            $parm_found++;
        }

        $key = "VALID_REPLY_RE";
        if ( $parm eq $key ) {
            if ( ref $value eq "" ) {
                $config->{$key} = qr/$value/;
            }
            else {
                croak "ERROR: (scan_ports): $key value must be a SCALAR\n";
            }
            $parm_found++;
        }

        if ( !$parm_found ) {
            croak "ERROR: (scan_ports): Parameter \"$parm\" is not valid for scan port\n";
        }

    }

    if ( !exists( $config->{TEST_STRING} ) || !exists( $config->{VALID_REPLY_RE} ) ) {
        croak "ERROR: (scan_ports): TEST_STRING and VALID_REPLY must be provided to scan_ports\n";
    }

    # Handle Default when certain parms were not provided

    if ( !exists( $config->{BAUD} ) ) {
        @{ $config->{BAUD} } = (qw/1200 2400 4800 9600 19200 38400 57600 115200/);
    }

    if ( !exists( $config->{COM} ) ) {
        @{ $config->{COM} } = ( 1 .. $serial->{MAX_PORT} );
    }

    if ( !exists( $config->{SETTING} ) ) {

        # Default for setting when not provided

        push(
            @{ $config->{SETTING} },
            {
                DATABITS  => 8,
                PARITY    => "none",
                STOPBITS  => 1,
                HANDSHAKE => "none",
                SETTING   => "8N1"
            }
        );
    }

    # Figure the number of read iterations is needed

    if ( exists( $config->{MAX_WAIT} ) ) {
        $serial->_add_scan_log("(Max Wait set at $config->{MAX_WAIT})");
        $read_iterations = int( $config->{MAX_WAIT} / ( $serial->{READ_CONST_TIME} / 1000 ) );
        $read_iterations = 1 if ( $read_iterations < 1 );

    }
    else {

        # Must always go though the loop once
        $read_iterations = 1;
    }

    # Begin Scan of Com Ports

  PORT:
    foreach $com_port ( sort { $a <=> $b } @{ $config->{COM} } ) {

        $com_device_name = $serial->_get_com_device_name($com_port);
        $serial->_add_scan_log("Scan Port COM${com_port} @ $com_device_name");

        # Baud rates are attempted from highest to lowest because some
        # might be using a virtual COM via USB and it "looks" nicer to
        # see the faster buad rate (virtual USB com ports dont care about baud rates or settings)

      BAUD:
        foreach $baud ( sort { $b <=> $a } @{ $config->{BAUD} } ) {
            $serial->_add_scan_log("   Checking with baudrate of $baud");

          SETTING:
            foreach $setting ( sort { $b <=> $a } @{ $config->{SETTING} } ) {
                $serial->_add_scan_log("      Checking with setting of $setting->{SETTING}");
                $PortObj = $serial->_get_com_connection($com_port);

                if ($PortObj) {

                    #$PortObj->user_msg("ON");
                    if ( !$PortObj->baudrate($baud) ) {

                        # If *::SerialPort says this baudrate is invalid then go to the next one
                        # (eg. Dont keep scanning it at other settings)
                        $serial->_add_scan_log("      Warning: Baud rate of $baud is not valid for this com port - skipping to next one");
                        next BAUD;
                    }

                    $PortObj->databits( $setting->{DATABITS} );
                    $PortObj->parity( $setting->{PARITY} );
                    $PortObj->stopbits( $setting->{STOPBITS} );
                    $PortObj->handshake( $setting->{HANDSHAKE} );

                    # Just kept this based on *::SerialPort examples
                    $PortObj->buffers( 4096, 4096 );

                    if ( $PortObj->write_settings ) {

                        # Ok, port is available, now is it our device?

                        $PortObj->write( $config->{TEST_STRING} );

                        $serial->_add_scan_log("         Sending test string \"$config->{TEST_STRING}\"");

                        # Due to a bug or something, this locks up
                        # on Windows sometimes

                        $PortObj->read_char_time( $serial->{READ_CHAR_TIME} );
                        $PortObj->read_const_time( $serial->{READ_CONST_TIME} );

                        $feedback = "";

                        # Calculated outside loops for performance

                        $waited = 0;

                        # Wait a maximum amount of time to get expected output but move on
                        # if we dont get it in the alloted amount of time.  This also protects
                        # us from a device just spewing data.

                        for ( $iterations = 1 ; $iterations <= $read_iterations ; $iterations++ ) {

                            # Read from the port
                            ( $bytes_read, $data_read ) = $PortObj->read(255);    # docs say this must be 255 always
                            $waited += $serial->{READ_CONST_TIME};

                            if ( $bytes_read > 0 ) {
                                $feedback .= $data_read;

                                # This is what makes this loop faster
                                last if ( $feedback =~ /$config->{VALID_REPLY_RE}/ );
                            }
                        }

                        $feedback =~ s/\015?\012$//;

                        $serial->_add_scan_log( sprintf( "         Received back from device \"%s\" (Waited %.2f secs)", $feedback, $waited / 1000 ) );

                        if ( $feedback =~ /$config->{VALID_REPLY_RE}/ ) {

                            # Get a new "device" and store all the properties in it

                            $device = Hardware::PortScanner::Device->new_device($serial);

                            $device->com_port("COM${com_port}");
                            $device->baudrate($baud);
                            $device->databits( $setting->{DATABITS} );
                            $device->parity( $setting->{PARITY} );
                            $device->stopbits( $setting->{STOPBITS} );
                            $device->handshake( $setting->{HANDSHAKE} );
                            $device->port_name($com_device_name);
                            $device->setting( $setting->{SETTING} );
                            $device->{VALID_REPLY} = $feedback;
                            $device->{TEST_STRING} = $config->{TEST_STRING};
                            $device->{MAX_WAIT}    = $config->{MAX_WAIT} if ( exists( $config->{MAX_WAIT} ) );

                            push( @{ $serial->{FOUND_DEVICE} }, $device );

                            # Since this device was found, skip scanning on this port anymore

                            $serial->_add_scan_log("         Matched valid reply RE so returning");
                            last BAUD;
                        }
                    }

                    $PortObj->close;
                    undef $PortObj;

                }    # PortObj
                else {
                    $serial->_add_scan_log("   Com Port $com_port appears not to be available - skipping to next port");
                    next PORT;
                }
            }    # Setting
        }    # Baud
    }    # Com Port

}

sub connect_to_device(@) {
    my $serial = shift;
    my $PortObj;
    my $port;
    my $baud;
    my $config = {};
    my $parm;
    my $value;
    my $key;
    my ( $databits, $parity, $stopbits, $handshake );
    my $setting;
    my $device;
    my $parm_found;

    # If there is a connection then remove it so this method is
    # reentrant

    if ( defined( $serial->{CONNECTION} ) ) {
        $serial->{CONNECTION}->close;
        undef $serial->{CONNECTION};
    }

    # Handle no parameters by assuming the user wants to connect to the only
    # device found by faking the passing of "DEVICE => $device" if one
    # and only one was found

    if ( scalar(@_) == 0 ) {
        if ( $serial->num_found_devices == 1 ) {
            @_ = ( "DEVICE", ( $serial->found_devices )[0] );
        }
        elsif ( $serial->num_found_devices == 0 ) {
            croak "ERROR: (connect_to_device): No devices were found or not scanned - cannot auto-connect\n";
        }
        else {
            croak "ERROR: (connect_to_device): More than one device was found - cannot auto-connect\n";
        }
    }

    # Handle the normal parameters

    while ( $parm = uc shift ) {
        $value      = shift;
        $parm_found = 0;

        $key = "BAUD";
        if ( $parm eq $key ) {
            if ( ref $value eq "" ) {
                $config->{$key} = $value;
            }
            else {
                croak "ERROR: (connect_to_device): $key value must be a SCALAR\n";
            }

            # Must be all digits.  We don't check the actual value because we will
            # let the *::SerialPort determine validity

            if ( $config->{$key} !~ /^\d+$/ ) {
                croak "ERROR: (connect_to_device): BAUD rate \"$value\" not valid\n";
            }
            $parm_found++;
        }

        $key = "COM";
        if ( $parm eq $key ) {

            if ( ref $value eq "" ) {

                # Handle the format of "COM5" or just "5"
                $value =~ s/^COM(\d+)/$1/i;
                $config->{$key} = $value;
            }
            else {
                croak "ERROR: (connect_to_device): $key value must be a SCALAR\n";
            }

            if ( !( $value =~ /^\d+$/ && $value > 0 && $value <= 50 ) ) {
                croak "ERROR: (connect_to_device): COM port\"$value\" not valid\n";
            }

            $config->{PORTNAME} = $serial->_get_com_device_name($value);

            $parm_found++;
        }

        $key = "SETTING";
        if ( $parm eq $key ) {
            $value = uc $value;
            if ( $value =~ /^([5678])([NEO])([12])([NRX])?$/ ) {
                no warnings;

                # Convert our setting format to domain expected by *::SerialPort

                $databits  = $1;
                $parity    = $2 eq "E" ? "even" : ( $2 eq "O" ? "odd" : "none" );
                $stopbits  = $3;
                $handshake = $4 eq "R" ? "rts" : ( $4 eq "X" ? "xoff" : "none" );

                $config->{SETTING} = {
                    DATABITS  => $databits,
                    PARITY    => $parity,
                    STOPBITS  => $stopbits,
                    HANDSHAKE => $handshake,
                    SETTING   => $value
                };
            }
            else {
                croak "ERROR: (connect_to_device): SETTING value of \"$value\" is not valid \n";
            }
            $parm_found++;
        }

        $key = "DEVICE";
        if ( $parm eq $key ) {
            $device = $value;

            if ( !defined($device) ) {
                croak "ERROR: (connect_to_device): device specified is undefined\n";
            }

            # Get the port configuration info from the device

            $config->{BAUD} = $device->baudrate;
            $config->{COM}  = $device->com_port;
            $config->{COM} =~ s/^COM(\d+)/$1/i;
            $config->{PORTNAME}             = $device->port_name;
            $config->{SETTING}->{DATABITS}  = $device->databits;
            $config->{SETTING}->{PARITY}    = $device->parity;
            $config->{SETTING}->{STOPBITS}  = $device->stopbits;
            $config->{SETTING}->{HANDSHAKE} = $device->handshake;
            $config->{SETTING}->{SETTING}   = $device->setting;

            $parm_found++;
        }

        # Check for unsupported options

        if ( !$parm_found ) {
            croak "ERROR: (connect_to_device): Parameter \"$parm\" is not valid for scan_port\n";
        }

    }

    # Baud is required to have been determined

    if ( !exists( $config->{BAUD} ) ) {
        croak "ERROR: (connect_to_device): Baud rate not specified or identifiable\n";
    }

    # Com Port is required to have been determined

    if ( !exists( $config->{COM} ) ) {
        croak "ERROR: (connect_to_device): Com port not specified or identifiable\n";
    }

    # Settings can be defaulted to most common if not specified

    if ( !exists( $config->{SETTING} ) ) {
        $config->{SETTING} = {
            DATABITS  => 8,
            PARITY    => "none",
            STOPBITS  => 1,
            HANDSHAKE => "none",
            SETTING   => "8N1"
        };
    }

    # Attempt to get connection to serial port

    $PortObj = $serial->_get_com_connection( $config->{COM}, 1 );

    if ($PortObj) {

        $PortObj->user_msg("ON");    # Should this be on?

        $PortObj->databits( $config->{SETTING}->{DATABITS} );
        $PortObj->baudrate( $config->{BAUD} );
        $PortObj->parity( $config->{SETTING}->{PARITY} );
        $PortObj->stopbits( $config->{SETTING}->{STOPBITS} );
        $PortObj->handshake( $config->{SETTING}->{HANDSHAKE} );
        $PortObj->buffers( 4096, 4096 );    # Better default?

        if ( !$PortObj->write_settings ) {

            # Getting this error is a little strange IF the device parameter was used

            croak "ERROR: (connect_to_device): Failed to write_settings to com port ($config->{COM})!\n";
            $PortObj->close;
            undef $PortObj;
        }

        # Store connection in meta-data
        $serial->{CONNECTION} = $PortObj;
    }
    else {
        croak "ERROR: (connect_to_device): Failed to connect to known com port ($config->{COM})!\n";
    }

    return 1;
}

# Circular references are used to handle them during garbage collection

sub DESTROY() {

    # Remove the child (device) reference so we will
    # not have circular references

    $_[0]->{FOUND_DEVICE} = undef;
    $_[0]->{CONNECTION}   = undef;

}

# Devices have there own package but I didnot want to have an additional
# module file so ... two in one

package Hardware::PortScanner::Device;

use Data::Dumper;    # Remove before production
use Carp;

$Data::Dumper::Useqq = 1;    # Remove before production

use strict;
use warnings;

# Get connection to device.  Used PortScanner method by same name

sub connect_to_device($) {
    my $device = shift;
    my $serial = $device->{SERIAL};

    return $serial->connect_to_device( DEVICE => $device );

}

# Constructor for new device

sub new_device($) {
    my $device = bless( {}, __PACKAGE__ );
    my $serial;
    my $class;

    if ( ref $_[0] ) {
        $serial = shift;
    }
    else {
        $class  = shift;
        $serial = shift;
    }

    $device->{SERIAL_OBJ} = $serial;

    return $device;
}

# Return/set baudrate for device

sub baudrate(;$) {
    my $device   = shift;
    my $att_name = "BAUD";

    if ( $_[0] ) {
        $device->{$att_name} = shift;
    }

    return $device->{$att_name};
}

# Return/set setting for device

sub setting(;$) {
    my $device   = shift;
    my $att_name = "SETTING";

    if ( $_[0] ) {
        $device->{$att_name} = shift;
    }

    return $device->{$att_name};
}

# Return/set databits for device

sub databits(;$) {
    my $device   = shift;
    my $att_name = "DATABITS";

    if ( $_[0] ) {
        $device->{$att_name} = shift;
    }

    return $device->{$att_name};
}

# Return/set stopbits for device

sub stopbits(;$) {
    my $device   = shift;
    my $att_name = "STOPBITS";

    if ( $_[0] ) {
        $device->{$att_name} = shift;
    }

    return $device->{$att_name};
}

# Return/set parity for device

sub parity(;$) {
    my $device   = shift;
    my $att_name = "PARITY";

    if ( $_[0] ) {
        $device->{$att_name} = shift;
    }

    return $device->{$att_name};
}

# Return/set handshake for device

sub handshake(;$) {
    my $device   = shift;
    my $att_name = "HANDSHAKE";

    if ( $_[0] ) {
        $device->{$att_name} = shift;
    }

    return $device->{$att_name};
}

# Return/set com_port for device

sub com_port(;$) {
    my $device   = shift;
    my $att_name = "COM";

    if ( $_[0] ) {
        $device->{$att_name} = shift;
        $device->{$att_name} =~ s/^\d+$/COM&/;
    }

    return $device->{$att_name};
}

# Return/set port_name for device

sub port_name(;$) {
    my $device   = shift;
    my $att_name = "PORTNAME";

    if ( $_[0] ) {
        $device->{$att_name} = shift;
    }

    return $device->{$att_name};
}

# Circular references are used to handle them during garbage collection

sub DESTROY() {

    # Remove the parent (serial) reference so we will
    # not have circular references

    $_[0]->{SERIAL} = undef;
}

1;

__END__

=head1 NAME 

Hardware::PortScanner - Scan serial ports to find hardware devices at various com ports, baud rates, and settings using request and expected reply message

=head1 SYNOPSIS 

  $serial = Hardware::PortScanner->new();

  $serial->scan_ports(		BAUD => [  4800, 9600 ],
					SETTING => [ '8N1', '7E1X' ],
					TEST_STRING => "V\n",
					VALID_REPLY_RE => '^UBW FW' );

  $PortObj = $serial->connect_to_device();


  OR

  $serial = Hardware::PortScanner->new();
  $PortObj = $serial->connect_to_device(BAUD => 115200, COM => 'COM3');

=head1 DESCRIPTION 

This module provides methods to scan and connect to com ports for hardware removing the necessity of knowing the specific com port, baud rate and/or settings (e.g. 8N1, 7E1) of the particular device you want to connect.  
The module works by sending a command to available devices at a variety of baud rates, com ports and settings.  If a message is received back that matches a regular expression, then the connection specifics are returned.  Additionally, the module can connect to the device via Device::SerialPort or Win32::SerialPort depending upon the platform. 

=over

=item *

Unplug unused COM cables before installation (or afterword if you notice problems).  See Bug/Issues below.

=item *

Run "manual_test.pl" for device specific tests

=back

=head1 Hardware::PortScanner Methods 

=head2 new()

Returns an Hardware::PortScanner object.

=head3 Parameters

B<MAX_PORT> - Optional parameter to specify the high port number on your system.  This will speed up the scans.

   Example(s):

   MAX_PORT => 8
   MAX_PORT => "Com5"

   Default if not specified:

   MAX_PORT => 5

=head2 scan_ports()

This method will scan for devices at several com ports, baud rate and settings each which can be specified or defaulted.  scan_port will stop scanning the current com port when a device is found and continue with the remaining com ports, baud rate and settings.   Note that USB devices don't have the concept of baud and settings which is why scanning is stopped on a particular port if a device is found.  Otherwise it would appear a device was found at several baud rates.  scan_ports stores the results of a scan in this module's object.

Also, due the method of operation of this method, other devices that are connected to an available com port may be connected to and interrogated (e.g. sent the request message).  It is assumed this will not cause undesirable behavior (doesn't for my stuff).  Additionally, the device may be send the message several time since, at this time, a reply that does not match the VALID_REPLY_RE is treated as a non-response causing other setting and baud rate to be attempted.

=head3 Parameters

B<COM> - Specifies the COM ports to be searched. Can be either a com number or a string like "COM8".

   Example(s):

   COM => [ 1, 2, "COM3", "COM8" ]
   COM => "COM3"

   Default if not specified:

   COM => [ qw/1..20/ ]

B<BAUD> - Specifies the BAUD rates ports to be configured. These baud rates are not limited to reasonable values but the Device::SerialPort or Win32::SerialPort modules used to connect may complain if it doesn't like the values.  A warning in scan_logs will also occur if the baud rate is invalid. Bauds are always tested in fasted to slowest or to support USB virtual devices which will connect and multiple baud rates (not that it will matter functionally).


   Example(s):

   BAUD => [ 1200, 2400 ]
   BAUD => 9600

   Default if not specified:

   BAUD => [ qw/1200 2400 4800 9600 19200 38400 57600 115200/ ]

B<SETTING> - String(s) matching the regular expression "/^([5678])([NEO])([12])([NRX])?$/" where the first digit is the databits (5, 6, 7 or 8), the second character is the parity (N = None, E = Even, O = Odd), the third digit is the stopbits (1 or 2 - no 1.5 since it doesn't seem to be supported) and finally the handshaking character (N= none, R = RTS and X = XOFF) which is optional and defaulted to "N".

   Examples:

   SETTING => [ "8n1", "7E1" ]
   SETTING => "8N1"

   Default if not specified:

   SETTING => "8N1"

B<TEST_STRING> - A string that will produce a response from the device that can be matched against a regular expression (VALID_REPLY_RE below) to confirm the device in desired has been found.  This string must include any command terminators (newlines, carriage returns, etc) that are necessary to get the device to recognize the command.  Often, a version request command works well as this string.

   Examples:

   TEST_STRING => "V\n"    # Version request for a UBW (USB Bit Whacker - UBW)
   TEST_STRING => "VER\r" # Version request for a SSC-32 servo controller

   No default and required parameter.

B<VALID_REPLY_RE> - A regular expression that, if matched, indicates the desired device has been found.


   VALID_REPLY_RE => '^UBW FW [CD] Version.* '
   VALID_REPLY_RE => '^SSC[-]32'

B<MAX_WAIT> - The maximum number of seconds, as a float, to wait for the expected reply after writing/sending the I<TEST_STRING> to the serial port being tested. This can slow down the scan_port process depending upon I<MAX_WAIT> value, number of available ports and options (BAUDS, SETTINGS, etc).  Set this to say 5 seconds if your device is not detected.  Then, assuming it is now detected, print a scan report to see the number of seconds before the response was recieved.  Set MAX_WAIT to a figure higher than this.

This feature was added when my SSC-32 Servo controller failed to respond quickly enough to a version request to get detected (but only on Ubuntu strangly).  Default is around .1 seconds which is the minimum even if set to 0.

   MAX_WAIT => 2
   MAX_WAIT => 0.23

=head2 connect_to_device()

This method will connect to a com port as specified by the parameters and return a 
standard *::SerialPort object if successful.  If no parameters are given, then I<connect_to_device> will
attempt to connect to the device found by the previous scan_port.  A errror will be given if no device was found (or scan_port was
not invoked) or more than one device was found.

=head3 Parameters

B<COM> - Specifies the COM ports to be searched. Can be either as a com number or in with a string like "COM8".

   Example(s):

   COM => 1
   COM => "COM3"

B<BAUD> - Specifies the BAUD rates ports to be configured. These baud rates are not limited to reasonable values but the Device::SerialPort or Win32::SerialPort modules used to connect may complain if it doesn't like the values.  A warning in scan_logs will also occur if the baud rate is invalid. Bauds are always tested in fasted to slowest or to support USB virtual devices which will connect and multiple baud rates (not that it will matter functionally).

   Example(s):

   BAUD => 9600

B<SETTING> - String(s) matching the regular expression "/^([5678])([NEO])([12])([NRX])?$/" where the first digit is the databits (5, 6, 7 or 8), the second character is the parity (N = None, E = Even, O = Odd), the third digit is the stopbits (1 or 2 - no 1.5 since it doesn't seem to be supported) and finally the handshaking character (N= none, R = RTS and X = XOFF) which is optional and defaulted to "N".

   Examples:

   SETTING => "7E1"
   SETTING => "8N1"

   Default if not specified:

   SETTING => "8N1"

B<DEVICE> - A Hardware::PortScanner::Device object returned from I<found_devices()>.  This option will pull the need connection parameters from the device specified and is incompatible with the other options.

   Examples:

   DEVICE => ($serial->found_devices)[0]    # Use the first device found
   DEVICE => $device_obj

=head2 num_found_device()

This method will return the number of devices successfully found by the previous I<scan_port()>

=head2 found_devices()

This method will return an array of devices objects (I<Hardware::PortScanner::Device> objects) successfully found by the previous I<scan_port()>

=head2 connection()

Returns the *::SerialPort connection from the I<connect_to_device()> method (see above).  Additional *::SerialPort methods could be done against this object.

=head2 scan_log()

C<scan_log> returns an array of info/debug messages to assist the end user in identify device not found issues.  As an example, the code below was used to search for a USB Bit Whacker (UBW).  An example of its use:


   $serial = Hardware::PortScanner->new();

   $serial->scan_ports(
                        COM => [ 3, 11 ],
                        BAUD => [ 4800, 9600 ],
                        SETTING => [ '8N1', '7E1X' ],
                        TEST_STRING => "V\n",
                        VALID_REPLY_RE => '^UBW FW'
                      );

   foreach ($serial->scan_log)
   {
      print "$_\n";
   }

   Generated the following output:


   Scan Ports Request
   ==================
   Scan Port COM3 @ /dev/ttyS2
      Checking with baudrate of 9600
         Checking with setting of 7E1X
            Sending test string "V\n"
            Received back from device ""
         Checking with setting of 8N1
            Sending test string "V\n"
            Received back from device ""
      Checking with baudrate of 4800
         Checking with setting of 7E1X
            Sending test string "V\n"
            Received back from device ""
         Checking with setting of 8N1
            Sending test string "V\n"
            Received back from device ""
   Scan Port COM11 @ /dev/ttyS10
      Checking with baudrate of 9600
         Checking with setting of 7E1X
            Sending test string "V\n"
            Received back from device "UBW FW D Version 1.4.3"
            Matched valid reply RE so returning

=head2 scan_report()

Convenience method to print out the scan_log (see above).  Functionally equivalent to the following code:

   foreach ($serial->scan_log)
   {
      print "$_\n";
   }

=head1 Hardware::PortScanner::Device Methods

These methods provide connection information for a device objects as returned from I<found_devices()>.

=head2 com_port()

Returns the com number of the provided device.

=head2 baudrate()

Returns the baud rate of the provided device.

=head2 databits()

Returns the databits of the provided device.

=head2 parity()

Returns the parity of the provided device.

=head2 stopbits()

Returns the stopbits of the provided device.

=head2 handshake()

Returns the handshake of the provided device.

=head2 port_name()

Returns the port name of the provided device. Which is suitable for the PortName parameter
in the *::SerialPort new command.

Below is an example from Device::SerialPort where the port name is used as "$PortName".

   $PortObj = new Device::SerialPort ($PortName, $quiet, $lockfile)
       || die "Can't open $PortName: $!\n";



=head1 PREREQUISITES 

Attempts were made to minimize the dependencies in case this module is being deployed on a minimal embedded system.  However, some are required for proper functioning. 

=over

=item *

Device::SerialPort from CPAN if using a Linux based system (including Cygwin)

=item *

Win32::SerialPort from CPAN if using Windows

=item *

Carp

=back

=head1 SUPPORTED PLATFORMS

Cygwin, Windows (but least tested) and Ubuntu

=head1 BUGS/ISSUES 

=over

=item *

Strange behavior (e.g. lock ups, odd low level errors, etc) occurs sometimes when some COM cables are plugged in but not attached to anything.  Only seen this happen when testing on Windows.

=item *

Have seen Device::SerialPort freeze (never return) when configuring certain handshaking settings (5N1R) on particular com ports.  Don't know if this was due to Device::SerialPort, Windows, Cygwin (which I was using at the time) or the COM hardware.  I backed off the handshaking tests in the test scripts because of this.

=item *

Under certain circumstances the *::SerialPort warning of "can't getattr: Bad file descriptor" or "can't getattr: Input/Output ...: occurs.  This always occured on a particular port when a particular device I had on that port had a low battery or a particular unconnect cable. This has been mitigated a bit by ignoring these errors during a connect attempt. They do show up however in a I<scan_report>. 

=back

=head1 TODO

=over 

=item *

Add a write then read method to wrap the lower level *::SerialPort commands of write and read.  This would also use the MAX_WAIT parameter provided to the I<new()> or provided as a option to this command.

=item *

Complete and improve documentation

=item *

Consider any features upon request

=item *

Add more tests during installation

=back

=head1 AUTHOR 

John Dennis <jdennis30064@galileotech.com>

=head1 COPYRIGHT AND LICENSE 

Copyright (C) 2009 by John Dennis
This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself, either Perl version 5.8.1 or, at your option, any later version of Perl 5 you may have available.





