use strict;
use warnings;

package Device::Solenodrive;
{
  $Device::Solenodrive::VERSION = '0.1';
}

use Moose;
use namespace::autoclean;
use 5.012;
use autodie;
use Carp qw/croak carp/;
use Digest::CRC;
use Fcntl;
use IO::Socket::INET;

has device => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has verbose => (
    is      => 'ro',
    isa     => 'Int',
    default => '0',
);

has baudrate => (
    is      => 'ro',
    isa     => 'Int',
    default => 57600,
);

# Ensure we read the hexfile after constructing the Bootloader object
sub BUILD {
    my $self = shift;
    $self->{_connected} = 0;

}

# Open the connection to the target device (serial port or TCP)
# depending on the target parameters that were passed
sub connect_target {
    my $self = shift;

    # Open the port
    $self->_device_open();

}

sub disconnect_target {
    my $self = shift;

    # Close the port
    close $self->{_fh};

    $self->_debug( 1, "Connection closed" );
}

sub enumerate {

    my $self = shift;

    my ($response);

    # Ensure we only try to write when we're connected
    if ( !$self->{_connected} ) {
        $self->_debug( 3,
            "Not actually enumerating cause we're not connected yet" );
        return;
    }

    # Enumerate
    $self->_write_packet( "FEFEFEFE", "E0" );

    # Loop until we get a timeout of more than 10 seconds
    # Nodes on the bus will respond to this command with their address
    say
        "Enumerating the devices on the bus, this operation can take up to 10 seconds...";

    while ( $response = $self->_read_packet(5) ) {
        next
            if ( $response eq "invalid_crc" )
            ;    # Conflict on bus, will be resolved by auto-backoff
        last if ( $response eq "timeout" );

        if ( $response =~ /(\w{8})45(\w{2})/ ) {
            $self->{_nodes}->{$1}->{firmware} = $2;
        }

    }

}

sub list_devices {
    my $self = shift;

    foreach ( keys( %{ $self->{_nodes} } ) ) {
        say;

    }
}

sub set {
    my ( $self, $address, $channel ) = @_;

    say "Setting channel $channel on $address";

    $self->_write_packet( $address, "D$channel" );

}

# open the port to a device, be it a serial port or a socket
sub _device_open {
    my $self = shift;

    my $dev = $self->device();
    my $fh;
    my $baud            = $self->{baudrate};
    my $report_baudrate = 0;

    if ( $dev =~ /\// || $dev =~ /^COM./ ) {
        if ( -S $dev ) {
            $fh = IO::Socket::UNIX->new($dev)
                or croak("Unix domain socket connect to '$dev' failed: $!\n");
        }
        else {
            require Symbol;
            $fh = Symbol::gensym();
            my $sport;

            require Device::SerialPort;
            import Device::SerialPort qw( :PARAM :STAT 0.07 );
            $sport = tie( *$fh, 'Device::SerialPort', $dev )
                or croak("Could not tie serial port to file handle: $!\n");

            #}
            $sport->baudrate($baud);
            $sport->databits(8);
            $sport->parity("none");
            $sport->stopbits(1);
            $sport->datatype("raw");
            $sport->write_settings();
            sysopen( $fh, $dev, O_RDWR | O_NOCTTY | O_NDELAY )
                or croak("open of '$dev' failed: $!\n");
            $fh->autoflush(1);
        }

        $report_baudrate = 1;

    }
    else {
        $dev .= ':' . ('10001') unless ( $dev =~ /:/ );
        $fh = IO::Socket::INET->new($dev)
            or croak("TCP connect to '$dev' failed: $!\n");
    }

    my $message = "Port opened";
    $message .= "@ $baud bps" if ($report_baudrate);

    $self->_debug( 1, "Port opened" );

    $self->{_connected} = 1;

    $self->{_fh} = $fh;
    return;

}

## _write_packet
#   Writes a packet to the device
#   Takes two inputs: a string of character representing a hexadecimal address, and a two-character string os ASCII-readable characters that are a command/parameter sequence.
sub _write_packet {

    my ( $self, $address, $data ) = @_;

    croak "Address should be 8 characters long" if ( length($address) != 8 );
    croak "Command should be 2 characters long" if ( length($data) != 2 );

    # Ensure we only try to write when we're connected
    if ( !$self->{_connected} ) {
        $self->_debug( 3,
            "Not actually writing cause we're not connected yet" );
        return;
    }

    # Create packet for transmission
    my $addr_string = pack( "H*", $address );
    my $cmnd_string = pack( "A*", $data );
    my $string      = $addr_string . $cmnd_string;

    my $crc = $self->_crc16($string);
    my $packet = $string . pack( "C", $crc % 256 ) . pack( "C", $crc / 256 );

    $packet = $self->_escape($packet);

    $packet = pack( "C", 15 ) . $packet . pack( "C", 4 );

    $self->_debug( 3, "Writing: " . $self->_hexdump($packet) );

    #Write per byte
    #my @packet_split = split(//, $packet);

    #foreach (@packet_split) {
    #syswrite( $self->{_fh}, $_, 1 );
    #}
    # Write
    syswrite( $self->{_fh}, $packet, length($packet) );

}

## read_packet(timeout)
#   Reads data from the link. Times out if nothing is
#   received after <timeout> seconds.
sub _read_packet {

    my ( $self, $timeout, $skip_crc ) = @_;

    my @numresult;
    my $result;

    eval {
        local $SIG{ALRM} = sub { die "timeout\n" };    # NB: \n required
                                                       # Set alarm
        alarm($timeout);

        # Execute receive code
        my $waiting = 1;
        $result = "";
        my $bytes;
        while ($waiting) {

# Read reply, could be in multiple passes, so we need to add as offset the current length of the receiving variable
            $bytes = $self->{_fh}->sysread( $result, 2048, length($result) );

# Verify we have the entire string (should end with 0x04 and no preceding 0x05)
            $self->_debug( 5, "RX # " . $self->_hexdump($result) );

            #if ( $sync && $result =~ /\x0F/ ) {
            #$waiting = 0;
            #}

            # Stop reading when we receive an end of line marker
            if ( $result =~ /\x04$/ ) {
                $waiting = 0;

# unless we received and 0x04 that was escaped because then we were not at the end of the packet
                $waiting = 1 if ( $result =~ /\x05\x04$/ );

                # Unless it was an escaped \x05
                $waiting = 0 if ( $result =~ /\x05\x05\x04$/ );
            }

        }

        # Clear alarm
        alarm(0);
    };

    # Check what happened in the eval loop
    if ($@) {
        if ( $@ =~ /timeout/ ) {

            # Oops, we had a timeout
            #carp("Timeout waiting for data from device");
            return "timeout";
        }
        else {

            # Oops, we died
            alarm(0);    # clear the still-pending alarm
            die;         # propagate unexpected exception
        }

    }

    #return 1 if ($sync);

    # We get here if the eval exited normally
    $result = $self->_parse_response( $result, $skip_crc );

    $self->_debug( 3, "RX: " . $result );
    return $result;
}

## parse_response
# Decode the response from the embedded device, i.e. remove
# protocol overhead, and return the remaining result.
sub _parse_response {
    my ( $self, $input, $skip_crc ) = @_;

    # Verify packet structure <STX><STX><...><ETX>
    if (!(     ( $input =~ /^\x0F/ )
            && ( $input =~ /\x04$/ )
            && ( !( $input =~ /\x05\x04$/ ) || ( $input =~ /\x05\x05\x04$/ ) )
        )
        )
    {
        croak("Received invalid packet structure from PIC\n");
    }

# Skip the header byte, no need to verify again the value, was verified with regexp already
    $_ = $input;
    s/^.//s;

    # pop the trailing end of transmission marker
    s/.$//s;

    $input = $self->_unescape($_);

    #say "Received after processing: " . $self->_hexdump($input);

    # Process the received data
    my @numresult = unpack( "C*", $input );

    if ( !defined($skip_crc) ) {

        # Verify the CRC
        my $crc_check = 0;

        # Received CRC
        my $rx_crc = pop(@numresult);
        $rx_crc = $rx_crc * 256 + pop(@numresult);

        $input = substr( $input, 0, -2 );

        $crc_check = $self->_crc16($input);

        # The CRCs should match, otherwise inform the user
        if ( $crc_check != $rx_crc ) {
            carp(     "Received invalid CRC in response from PIC, rx: "
                    . $self->_dec2hex($rx_crc)
                    . " -- calc: "
                    . $self->_dec2hex($crc_check)
                    . "\n" );
            return "invalid_crc";
        }
    }

    # Convert back to string of hex characters
    # TODO optimize this into pack
    #my $res_string = pack ("C");
    my $res_string;
    foreach (@numresult) {
        $res_string .= sprintf( "%02X", $_ );
    }
    return $res_string;

}

# CRC16 calculation 'the microchip way'.
# In a separate function to be able to test
sub _crc16 {
    my ( $self, $input ) = @_;

    # Calculate the CRC on the received string minus the CRC and trailing 0x04
    my $crx = Digest::CRC->new(
        width  => 16,
        init   => 0,
        xorout => 0,
        refout => 0,
        poly   => 0x1021,
        refin  => 0,
        cont   => 1
    );
    $crx->add($input);
    my $crc_check = $crx->digest;

    return $crc_check;

}

# Escape a string before sending it to the controller
# See microchip AN1310 appendix A
# Send in the payload data as a string, you get the escaped string out
sub _escape {
    my ( $self, $s ) = @_;

    # byte stuffing for the control characters in the data stream
    $s =~ s/\x05/\x05\x05/g;
    $s =~ s/\x04/\x05\x04/g;
    $s =~ s/\x0F/\x05\x0F/g;

    return $s;

}

# Strip the escape codes from the received string
sub _unescape {
    my ( $self, $s ) = @_;

    # <DLE>
    $s =~ s/\x05\x05/\x05/g;

    # <ETX>
    $s =~ s/\x05\x04/\x04/g;

    # <STX>
    $s =~ s/\x05\x0F/\x0F/g;

    return $s;
}

# Print input string of characters as hex
sub _hexdump {
    my ( $self, $s ) = @_;
    my $r = unpack 'H*', $s;
    $s =~ s/[^ -~]/./g;
    return $r . ' (' . $s . ')';
}

# debug
#   Debug print supporting multiple log levels
sub _debug {

    my ( $self, $debuglevel, $logline ) = @_;

    if ( $debuglevel <= $self->verbose() ) {
        say "+$debuglevel= $logline";
    }
}

# Helper function converting dec2hex
sub _dec2hex {

    my ( $self, $dec, $fill ) = @_;

    my $fmt_string;

    if ( defined($fill) ) {
        $fmt_string = "%0" . $fill . "X";
    }
    else {
        $fmt_string = "%02X";
    }
    return sprintf( $fmt_string, $dec );
}

# Speed up the Moose object construction
__PACKAGE__->meta->make_immutable;
no Moose;
1;

# ABSTRACT: Interface to the solenodrive hardware

__END__

=pod

=head1 NAME

Device::Solenodrive - Interface to the solenodrive hardware

=head1 VERSION

version 0.1

=head1 SYNOPSIS

my $solenodrive = Device::Solenodrive->new(device => '/dev/ttyUSB0');

=head1 DESCRIPTION

Host software to interface to solenodrive hardware.

=head1 METHODS

=head2 C<new(%parameters)>

This constructor returns a new Device::Solenodrive object. Supported parameters are listed below

=over

=item device

The target device to connect to.
This can be either a serial port object (e.g. /dev/ttyUSB0) or a TCP socket (e.g. 192.168.1.52:10001).

=item baudrate

Optional parameter when using a serial port for connecting to the bootloader. Default value is 57600 bps.

=item verbose

Controls the verbosity of the module. Defaults to 0. Increasing numbers make the module more chatty. 5 is the highest level and probably provides too much information. 3 is a good level to get started.

=back

=head2 C<connect_target()>

Opens the connection to the device that provides the RS485 interface, should be called before trying to send commands

=head2 C<set(ID, channel)>

Sets the channel C<channel> of the Solenodrive with ID C<ID> active.

=head2 C<enumerate()>

Enumerate the devices on the bus, reports the addresses of the devices together with their firmware version.
The returned object is a hash containing the address/firmware version pairs. Only supported from Solenodrive firmware v1.1 and upwards.

=head2 C<disconnect_target()>

Closes the connection to the RS485 bus.

=head2 C<list_devices()>

List the devices that were discovered after enumeration.

=head2 C<BUILD>

An internal function used by Moose to run code after the constructor. Need to document because otherwise Test::Pod::Coverage test fails

=head2 C<O_NDELAY>

Detected by Pod::Coverage from the sysopen function. Stub documenation to ensure the test does not fail when the module is deployed.

=head2 C<O_NOCTTY>

Detected by Pod::Coverage from the sysopen function. Stub documenation to ensure the test does not fail when the module is deployed.

=head2 C<O_RDWR>

Detected by Pod::Coverage from the sysopen function. Stub documenation to ensure the test does not fail when the module is deployed.

=head1 AUTHOR

Lieven Hollevoet <hollie@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Lieven Hollevoet.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
