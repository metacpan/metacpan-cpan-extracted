package Device::Modbus::Serial;

use Device::SerialPort;
use Carp;
use strict;
use warnings;

our $VERSION = '0.001';

use Role::Tiny;

sub open_port {
    my $self = shift;

    # Validate parameters
    croak "Attribute 'port' is required for a Modbus serial client"
        unless exists $self->{port};

    # Defaults related with the serial port
    $self->{baudrate} //=   9600;
    $self->{databits} //=      8;
    $self->{parity}   //= 'even';
    $self->{stopbits} //=      1;
    $self->{timeout}  //=     10;  # seconds

    # Serial Port object
    my $serial = Device::SerialPort->new($self->{port});
    croak "Unable to open serial port " . $self->{port} unless $serial;

    $serial->baudrate ($self->{baudrate});
    $serial->databits ($self->{databits});
    $serial->parity   ($self->{parity});
    $serial->stopbits ($self->{stopbits});
    $serial->handshake('none');

    # char_time and read_char_time are given in milliseconds
    $self->{char_time} =
        1000*($self->{databits}+$self->{stopbits}+1)/ $self->{baudrate};

    $serial->read_char_time($self->{char_time});
    if ($self->{baudrate} < 19200) { 
        $serial->read_const_time(3.5 * $self->{char_time});
    }
    else {
        $serial->read_const_time(1.75);
    }

    $serial->write_settings || croak "Unable to open port: $!";
    $serial->purge_all;
    $self->{port} = $serial;
    return $serial;
}

sub read_port {
    my $self    = shift;
    my $buffer  = '';
    my $bytes   = 0;
    my $timeout = 1000 * $self->{timeout}; # Turn to milliseconds
    do {
        my $read;
        ($bytes, $read) = $self->{port}->read(255);
        $buffer  .= $read;
        $timeout -= $self->{port}->read_const_time + 255 * $self->{char_time};
    } until ($timeout <= 0 || ($bytes == 0 && length($buffer) > 0));
    # say STDERR "<$buffer>";
    $self->{buffer} = $buffer;
    return $buffer;
}

sub write_port {
    my ($self, $adu) = @_;
    $self->{port}->write($adu->binary_message);
}

sub disconnect {
    my $self = shift;
    $self->{port}->close;
}

sub parse_buffer {
    my ($self, $bytes, $pattern) = @_;
    croak "Timeout error" unless
        defined $self->{buffer} && length($self->{buffer}) >= $bytes;    
    return unpack $pattern, substr $self->{buffer},0,$bytes,'';
}

1;
