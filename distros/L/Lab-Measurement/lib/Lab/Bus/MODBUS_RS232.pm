package Lab::Bus::MODBUS_RS232;
#ABSTRACT: RS232/RS485 MODBUS RTU protocol bus
$Lab::Bus::MODBUS_RS232::VERSION = '3.881';
use v5.20;

#
# MODBUS bus driver.
# The MODBUS standard defines a protocol to access the memory of connected devices,
# possible interfaces are RS485/RS232 and Ethernet.
# For now this driver uses Lab::Bus::RS232 as backend. It's main use is to
# generate the checksums used by MODBUS RTU. The memory addresses are device specific and
# have to be stored in the according device driver packages.
#

use strict;

use Lab::Bus::RS232;
use Carp;
use Data::Dumper;

use Scalar::Util qw(weaken);

use threads;
use Thread::Semaphore;

# setup this variable to add inherited functions later
our @ISA = ("Lab::Bus::RS232");

our $INS_DEBUG = 0;    # do we need additional output?

my @crctab = ();

my $ConnSemaphore = Thread::Semaphore->new()
    ; # a semaphore to prevent simultaneous use of the bus by multiple threads

our %fields = (
    type           => 'RS232',
    crc_init       => 0xFFFF,
    crc_poly       => 0xA001,
    max_crc_errors => 3,
);

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $twin  = undef;
    my $self  = $class->SUPER::new(@_)
        ;    # getting fields and _permitted from parent class
    $self->${ \( __PACKAGE__ . '::_construct' ) }(__PACKAGE__);

    # search for twin in %Lab::Bus::BusList. If there's none, place $self there and weaken it.
    # note to self: put this in base class/_construct if possible
    # note to self2: think about how to block access to this RS232 port for a plain Lab::Bus::RS232 bus.
    if ( $class eq __PACKAGE__ )
    {    # careful - do only if this is not a parent class constructor
        if ( $twin = $self->_search_twin() ) {
            undef $self;
            return $twin;    # ...and that's it.
        }
        else {
            $Lab::Bus::BusList{ $self->type() }->{ $self->port() } = $self;
            weaken( $Lab::Bus::BusList{ $self->type() }->{ $self->port() } );
        }
    }

    $self->_crc_inittab();    # Precalculations for checksum generation

    return $self;
}

sub connection_new {
    my $self = shift;
    my $args = undef;
    if ( ref $_[0] eq 'HASH' ) {
        $args = shift;
    }    # try to be flexible about options as hash/hashref
    else { $args = {@_} }

    my $connection_handle = undef;
    my $slave_address     = undef;

    if (   exists $args->{'slave_address'}
        && $args->{'slave_address'} =~ /[0-9]*/
        && $args->{'slave_address'} > 0
        && $args->{'slave_address'} < 255 ) {
        $slave_address = $args->{'slave_address'};
    }
    else {
        Lab::Exception::CorruptParameter->throw(
            error =>
                'No or invalid MODBUS Slave Address given. I can\'t work like this!',
        );
    }

    $connection_handle = {
        valid         => 1,
        type          => "MODBUS_RS232",
        slave_address => $slave_address
    };

    return $connection_handle;
}

#
# returns the read values as an array of bytes (characters!)
# don't be fooled, these are integers
# note to self: think this through again
#
sub connection_read
{    # @_ = ( $connection_handle, $args = { function, mem_address, mem_count }
    my $self              = shift;
    my $connection_handle = shift;
    my $args              = undef;
    if ( ref $_[0] eq 'HASH' ) {
        $args = shift;
    }    # try to be flexible about options as hash/hashref
    else { $args = {@_} }

    use bytes
        ; # important! no unicode below, just plain 8-bit-encoding. We are receiving bytestrings via RS232, too much smart can blow us to hell.

    my $function    = int( $args->{'function'} )    || undef;
    my $mem_address = int( $args->{'mem_address'} ) || undef;
    my $mem_count  = int( $args->{'mem_count'} || 1 );
    my @Result     = ();
    my $Success    = 0;
    my $ErrCount   = 0;
    my $Message    = "";
    my @MessageArr = ();
    my @AnswerArr  = ();
    my @TmpArr     = ();

    if ( !defined $function || $function != 3 ) {
        Lab::Exception::CorruptParameter->throw(
            error => 'Undefined or unimplemented function code', );
    }
    if ( !defined $mem_address || $mem_address < 0 || $mem_address > 0xFFFF )
    {
        Lab::Exception::CorruptParameter->throw(
            error => 'Invalid memory address', );
    }
    if ( $mem_count < 1 ) {
        Lab::Exception::CorruptParameter->throw(
            error => 'Invalid count of registers to be read', );
    }

    @MessageArr = $self->_MB_CRC(
        pack( 'C', $connection_handle->{slave_address} ),
        pack( 'C', $function ),
        pack( 'n', $mem_address ),
        pack( 'n', $mem_count )
    );
    $Message = join( '', $self->_chrlist(@MessageArr) );

    $Success  = 0;
    $ErrCount = 0;
    $ConnSemaphore->down();
    do {
        $self->SUPER::_direct_write( command => $Message );
        @AnswerArr
            = split( //, $self->SUPER::_direct_read( read_length => 'all' ) );
        if ( scalar(@AnswerArr) == 0 ) {
            warn "Error, no answer received - retrying\n";
            $ErrCount++;
        }
        else {
            @TmpArr = $self->_MB_CRC(@AnswerArr);
            if ( $TmpArr[-2] != 0 || $TmpArr[-1] != 0 )
            { # CRC over the message including its correct CRC results in a "CRC" of zero.
                $ErrCount++;
                $ErrCount < $self->max_crc_errors()
                    ? warn "Error in MODBUS response - retrying\n"
                    : warn "Error in MODBUS response\n";
            }
            else {
                warn "...Success\n" if $ErrCount > 0;
                $Success = 1;
            }
        }
    } until ( $Success == 1 || $ErrCount >= $self->max_crc_errors() );
    $ConnSemaphore->up();
    warn
        "Too many CRC errors, giving up after ${\$self->max_crc_errors()} times.\n"
        unless $Success;
    return undef unless $Success;

    # formally correct - check response
    if ( scalar(@AnswerArr) == 5 ) {    # Error answer received?
        $Success = 0;

        # Now: warn and tell error code. Later: throw exception
        warn "Received MODBUS error message with error code"
            . ord( $AnswerArr[2] ) . "\n";
    }
    elsif ( scalar(@AnswerArr) < ord( $AnswerArr[2] ) + 5 )
    {    # correct message length? carries all bytes it says it does?
        $Success = 0;
    }

    if ( $Success == 1 ) {    # read result, as an array of bytes
        for my $item ( @AnswerArr[ 3 .. 3 + ord( $AnswerArr[2] ) - 1 ] ) {
            push( @Result, $item );
        }
        return @Result;
    }
    else {
        return undef;
    }
}

sub connection_write
{ # @_ = ( $connection_handle, $args = { function, mem_address, (int_16)mem_value }
    my $self              = shift;
    my $connection_handle = shift;
    my $args              = undef;
    if   ( ref $_[0] eq 'HASH' ) { $args = shift }
    else                         { $args = {@_} }

    my $function    = int( $args->{'function'} )    || undef;
    my $mem_address = int( $args->{'mem_address'} ) || undef;
    my $mem_value   = int( $args->{'mem_value'} );
    my $SendValue  = pack( 'n!', $mem_value );
    my $Result     = undef;
    my $Message    = "";
    my @MessageArr = ();
    my $Success    = 0;
    my @AnswerArr;
    my @TmpArr   = ();
    my $ErrCount = 3;

    if ( !defined $function || $function != 6 ) {
        Lab::Exception::CorruptParameter->throw(
            error => 'Undefined or unimplemented function code', );
    }
    if ( !defined $mem_address || $mem_address < 0 || $mem_address > 0xFFFF )
    {
        Lab::Exception::CorruptParameter->throw(
            error => 'Invalid memory address', );
    }
    if ( unpack( 'n!', $SendValue ) != $mem_value ) {
        Lab::Exception::CorruptParameter->throw(
            error => "Invalid Memory Value $mem_value", );
    }

    @MessageArr = $self->_MB_CRC(
        pack( 'C', $connection_handle->{slave_address} ),
        pack( 'C', $function ),
        pack( 'n', $mem_address ), $SendValue
    );
    $Message = join( '', $self->_chrlist(@MessageArr) );

    $Success  = 0;
    $ErrCount = 0;
    $ConnSemaphore->down();
    do {
        $self->SUPER::_direct_write( command => $Message );
        @AnswerArr
            = split( //, $self->SUPER::_direct_read( read_length => 'all' ) );
        if ( scalar(@AnswerArr) == 0 ) {
            warn "Error, no answer received - retrying\n";
            $ErrCount++;
        }
        else {
            @TmpArr = $self->_MB_CRC(@AnswerArr);
            if ( $TmpArr[-2] != 0 || $TmpArr[-1] != 0 )
            { # CRC over the message including its correct CRC results in a "CRC" of zero
                $ErrCount++;
                $ErrCount < $self->max_crc_errors()
                    ? warn "Error in MODBUS response - retrying\n"
                    : warn "Error in MODBUS response\n";
            }
            else {
                warn "...Success\n" if $ErrCount > 0;
                $Success = 1;
            }
        }
    } until ( $Success == 1 || $ErrCount >= $self->max_crc_errors() );
    $ConnSemaphore->up();
    warn
        "Too many CRC errors, giving up after ${\$self->max_crc_errors()} times.\n"
        unless $Success;
    return undef unless $Success;

    # formally correct - check response;
    @AnswerArr = $self->_ordlist(@AnswerArr);
    if ( scalar(@AnswerArr) == 5 )
    {    # Error answer received? Error answers are 5 bytes long.
        $Success = 0;

        # Now: warn and tell error code. Later: throw exception
        warn "Received MODBUS error message with error code $AnswerArr[2] \n";
    }
    if ( $Success == 1 ) {

        # compare sent message and answer. equality signals success.
        for ( my $i = 0; $i < scalar(@AnswerArr); $i++ ) {
            if ( $AnswerArr[$i] ne $MessageArr[$i] ) {
                $Success = 0;
                $i       = scalar(@AnswerArr);
            }
        }
    }

    return $Success;
}

#
# MODBUS RTU infrastructure below.
#

sub _ordlist {    # @list of chars
    my $self = shift;
    my @list = @_;
    for (@list) { $_ = ord }
    return @list;
}

sub _chrlist {    # @list of integers
    my $self = shift;
    my @list = @_;
    for (@list) { $_ = chr }
    return @list;
}

sub _crc_inittab () {
    my $self = shift;
    my $crc  = 0;
    my $c    = 0;
    my $i    = 0;
    my $j    = 0;

    my $crc_poly = $self->crc_poly();

    for ( $i = 0; $i < 256; $i++ ) {
        $crc = 0;
        $c   = $i;

        for ( $j = 0; $j < 8; $j++ ) {

            if ( ( $crc ^ $c ) & 0x0001 ) { $crc = ( $crc >> 1 ) ^ $crc_poly }
            else                          { $crc = ( $crc >> 1 ) }

            $c = ( $c >> 1 );
        }

        $crctab[$i] = $crc;
    }
}

# generate MODBUS CRC for given message
# takes a message in the form of a (list of) binary string(s) like output by pack().
# generates crc and returns the message including the crc as a list of integers
sub _MB_CRC
{ # @Message as character array, e.g. ( chr(1), pack('C',$address), split(//,pack('n',$stuff))
    my $self = shift;
    my @message = $self->_ordlist( split( //, join( '', @_ ) ) );
    _crc_inittab() if ( !@crctab );

    my $crc_poly = $self->crc_poly();
    my $crc_init = $self->crc_init();

    my $size = @message;
    if ( $size == 0 ) { warn('Empty message!'); return undef; }
    my $remainder = $crc_init;
    my $tmp       = 0;
    my $i         = 0;

    for ( $i = 0; $i < $size; $i++ ) {
        $tmp = $remainder ^ ( 0x00ff & $message[$i] );
        $remainder = ( $remainder >> 8 ) ^ $crctab[ $tmp & 0xff ];
    }

    return ( @message, $remainder & 0x00FF, ( $remainder & 0xFF00 ) >> 8 );
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Lab::Bus::MODBUS_RS232 - RS232/RS485 MODBUS RTU protocol bus

=head1 VERSION

version 3.881

=head1 SYNOPSIS

	use Lab::Bus::MODBUS_RS232;
	my $h = Lab::Bus::MODBUS_RS232->new({
		Interface => 'RS232',
		Port => 'COM1|/dev/ttyUSB1'
		slave_address => '1'
	});

C<COM1> is the Windows notation, C</dev/ttyUSB1> the Linux equivalent. Use as needed.

=head1 DESCRIPTION

This is an interface package for Lab::Measurement to communicate via RS232/RS485 with a 
MODBUS RTU enabled device. It uses Lab::Bus::RS232 (RS485 can be done using a 
RS232<->RS485 converter for now). It's main use is to calculate the checksums needed by 
MODBUS RTU.

Refer to your device for the correct port configuration.

As of yet, this driver does NOT fully implement all MODBUS RTU functions. Only the function
codes 3 and 6 are provided.

=head1 CONSTRUCTOR

=head2 new

All parameters are used as by C<Device::SerialPort> respectively C<Lab::Bus::RS232>.
'port' is needed in every case. Default value for timeout is 500ms and can be set by the 
parameter "Timeout". Other options you probably have to set: Handshake, Baudrate, Databits, Stopbits and Parity.

=head1 METHODS

Used by C<Lab::Connection>. Not for direct use!!!

=head2 connectionRead

Reads data. Arguments:
function (0x01,0x02,0x03,0x04 - "Read Coils", "Read Discrete Inputs", "Read Holding Registers", "Read Input Registers")
slave_address (0xFF)
mem_address ( 0xFFFF, Address of first word )
mem_count ( 0xFFFF, Count of words to read )

=head2 connectionWrite

Send data to instrument. Arguments: 

 function (0x05,0x06,0x0F,0x10 - "Write Single Coil", "Write Single Register", "Write Multiple Coils", "Write Multiple Registers")

Currently only 0x06 is implemented.

 slave_address (0xFF)

 mem_address ( 0xFFFF, Address of word )
 
 Value ( 0xFFFF, value to write to mem_address )

=head1 CAVEATS/BUGS

This is a prototype...

=head1 SEE ALSO

=over 4

=item * L<Lab::Bus>

=item * L<Lab::Bus::RS232>

=item * L<Lab::Connection>

=item * L<Win32::SerialPort>

=item * L<Device::SerialPort>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by the Lab::Measurement team; in detail:

  Copyright 2011-2012  Andreas K. Huettel, Florian Olbrich
            2016       Simon Reinhardt
            2017       Andreas K. Huettel
            2020       Andreas K. Huettel


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
