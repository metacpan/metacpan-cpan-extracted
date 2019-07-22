#########################################################################################
# Package        HiPi::BCM2835::I2C
# Description:   I2C Connection
# Copyright    : Copyright (c) 2013-2019 Mark Dootson
# License      : This work is free software; you can redistribute it and/or modify it 
#                under the terms of the GNU General Public License as published by the 
#                Free Software Foundation; either version 3 of the License, or any later 
#                version.
#########################################################################################

package HiPi::BCM2835::I2C;

#########################################################################################

use strict;
use warnings;
use parent qw( HiPi::Class );
use HiPi 0.80;
use HiPi qw( :rpi :i2c );
use HiPi::BCM2835 qw( :registers :i2c :clock );

use Carp;

__PACKAGE__->create_accessors( qw(
    _hipi_baseaddr peripheral address _function_mode _clock_divider _baud_reference readmode
));

our $VERSION ='0.65';

our @EXPORT = ();
our @EXPORT_OK = ();
our %EXPORT_TAGS = ( all => \@EXPORT_OK );

use constant {
    BB_I2C_PERI_0         => 0x10,
    BB_I2C_PERI_1         => 0x20,
    BB_I2C_RESULT_SUCCESS => BCM2835_I2C_REASON_OK,
    BB_I2C_RESULT_NACKRCV => BCM2835_I2C_REASON_ERROR_NACK,
    BB_I2C_RESULT_CLOCKTO => BCM2835_I2C_REASON_ERROR_CLKT,
    BB_I2C_RESULT_DATAERR => BCM2835_I2C_REASON_ERROR_DATA,
    BB_I2C_CLOCK_100_KHZ  => 2500,
    BB_I2C_CLOCK_400_KHZ  => 626,
    BB_I2C_CLOCK_1667_KHZ => 150,
    BB_I2C_CLOCK_1689_KHZ => 148,
};

{
    my @const = qw(
        BB_I2C_PERI_0
        BB_I2C_PERI_1
        BB_I2C_RESULT_SUCCESS 
        BB_I2C_RESULT_NACKRCV
        BB_I2C_RESULT_CLOCKTO
        BB_I2C_RESULT_DATAERR
        BB_I2C_CLOCK_100_KHZ
        BB_I2C_CLOCK_400_KHZ
        BB_I2C_CLOCK_1667_KHZ
        BB_I2C_CLOCK_1689_KHZ
    );
    
    push @EXPORT_OK, @const;
    $EXPORT_TAGS{i2c} = \@const;
}

sub set_baudrate {
    my ($objorclass, $newval ) = @_;
    
    $newval ||= 100000;
    $newval = 3816 if $newval < 3816;
    
    # As instance method store cdiv
    if(ref($objorclass)) {
        $objorclass->_baud_reference($newval);
        my $cdiv = (BCM2835_CORE_CLK_HZ / $newval)  & 0x3FFFFE;
        $objorclass->_clock_divider( $cdiv );
        return 1;
    }
    
    # As class method set global
    
    # make sure library is initialised
    HiPi::BCM2835::bcm2835_init();
    
    my $channel = ( RPI_BOARD_REVISION == 1 ) ? BB_I2C_PERI_0 : BB_I2C_PERI_1;
        
    my $baseaddress = ( $channel == BB_I2C_PERI_0 )
        ? BCM2835_BSC0_BASE
        : BCM2835_BSC1_BASE;

    HiPi::BCM2835::bcm2835_hipi_i2c_set_baudrate( $baseaddress, $newval );
    return 1;
}

sub get_baudrate {
    my ($objorclass) = @_;
    
    # As instance method return our own baudrate
    if(ref($objorclass)) {
        return $objorclass->_baud_reference;
    }
    
    my $channel = ( RPI_BOARD_REVISION == 1 ) ? BB_I2C_PERI_0 : BB_I2C_PERI_1;
    
    my $cdiv = _get_current_clockdivider($channel);
    return _get_baudrate_from_clockdivider($cdiv);
}

sub _get_current_clockdivider {
    my $channel = shift;
    # make sure library is initialised
    HiPi::BCM2835::bcm2835_init();
    
    # force some default values / ranges
    unless( defined($channel) && ( ( $channel == BB_I2C_PERI_0  ) || ( $channel == BB_I2C_PERI_1 ) ) ){
        croak('channel must be defined as constant BB_I2C_PERI_0 or BB_I2C_PERI_1');
    }
    
    my $baseaddress = ( $channel == BB_I2C_PERI_1 )
        ? BCM2835_BSC1_BASE
        : BCM2835_BSC0_BASE;

    my $readaddess = $baseaddress + BCM2835_BSC_DIV;
    
    my $cdiv = HiPi::BCM2835::bcm2835_peri_read($readaddess);
    return $cdiv;
}

sub _get_baudrate_from_clockdivider {
    my $cdiv = shift;
    return ( BCM2835_CORE_CLK_HZ / $cdiv ) & 0x3FFFFE;
}

sub new {
    my ($class, %userparams ) = @_;
        
    my %params = (
        address      => 0,
        peripheral   => ( RPI_BOARD_REVISION == 1 ) ? BB_I2C_PERI_0 : BB_I2C_PERI_1,
        _function_mode => 'hipi',
        readmode => I2C_READMODE_SYSTEM,
    );
    
    # get user params
    foreach my $key( keys (%userparams) ) {
        $params{$key} = $userparams{$key};
    }
    
    # force PERI_I2C_0 on revision 1 board
    if( RPI_BOARD_REVISION == 1 ) {
        $params{peripheral} = BB_I2C_PERI_0;
    }
    
    # initialise
    HiPi::BCM2835::bcm2835_init();
    
    $params{_hipi_baseaddr} = ( $params{peripheral} == BB_I2C_PERI_1 )
        ? BCM2835_BSC1_BASE
        : BCM2835_BSC0_BASE;

    my $self = $class->SUPER::new(%params);
    
    unless( $self->i2c_begin() ) {
        croak('cannot initialise i2c functions of BCM2835 library');
    }
    
    if( $self->_function_mode eq 'corelib' ) {
        carp qq(USING BCM2835 CORE FUNCTIONS);
    }
    
    {
        my $cdiv = _get_current_clockdivider($self->peripheral);
        my $baudrate = _get_baudrate_from_clockdivider( $cdiv );
        $self->_clock_divider( $cdiv );
        $self->_baud_reference( $baudrate );
    }
    
    return $self;
}

sub i2c_begin {
    my $self = shift;
    # note that set_I2C_X does the right thing
    # according to board revision
    # ALSO sets pull up resistor on / off
    my $rval;
    if ( $self->peripheral == BB_I2C_PERI_1 ) {
        $rval = HiPi::BCM2835::hipi_set_I2C1(1);
    } else {
        $rval = HiPi::BCM2835::hipi_set_I2C0(1);
    }
    return $rval;
}

# i2c_end - we don't call this automatically
# as removing the pu resistors may be
# unexpected as may changing output type

sub i2c_end {
    my $self = shift;
    # note that set_I2C_X does the right thing
    # according to board revision
    # ALSO sets pull up resistor on / off
    if ( $self->peripheral == BB_I2C_PERI_1 ) {
        HiPi::BCM2835::hipi_set_I2C1(0);
    } else {
        HiPi::BCM2835::hipi_set_I2C0(0);
    }
}

sub i2c_write {
    my( $self, @bytes ) = @_;
    my $writebuffer = pack('C*', @bytes);
    HiPi::BCM2835::_hipi_i2c_set_transfer_params( $self->_hipi_baseaddr, $self->address, $self->_clock_divider );
    my $error = ( $self->_function_mode eq 'corelib' )
        ? HiPi::BCM2835::bcm2835_i2c_write( $writebuffer )
        : HiPi::BCM2835::_hipi_i2c_write( $self->_hipi_baseaddr, $writebuffer, scalar @bytes );
    
    croak qq(i2c_write failed with return value $error) if $error;
}

# expect write to error - e.g. on software reset
sub i2c_write_error {
    my( $self, @bytes ) = @_;
    my $writebuffer = pack('C*', @bytes);
    HiPi::BCM2835::_hipi_i2c_set_transfer_params( $self->_hipi_baseaddr, $self->address, $self->_clock_divider );
    my $error = ( $self->_function_mode eq 'corelib' )
        ? HiPi::BCM2835::bcm2835_i2c_write( $writebuffer )
        : HiPi::BCM2835::_hipi_i2c_write( $self->_hipi_baseaddr, $writebuffer, scalar @bytes );
    
    return $error;
}

sub i2c_read {
    my( $self, $numbytes ) = @_;
    $numbytes ||= 1;
    my $readbuffer = chr(0) x  ( $numbytes + 1 );
    HiPi::BCM2835::_hipi_i2c_set_transfer_params( $self->_hipi_baseaddr, $self->address, $self->_clock_divider );
    my $error = ( $self->_function_mode eq 'corelib' )
        ? HiPi::BCM2835::bcm2835_i2c_read( $readbuffer, $numbytes )
        : HiPi::BCM2835::_hipi_i2c_read($self->_hipi_baseaddr, $readbuffer, $numbytes);

    croak qq(i2c_read failed with return value $error) if $error;
    my $template = ( $numbytes > 1 ) ? 'C' . $numbytes : 'C';
    my @values = unpack($template, $readbuffer);
    return @values;
}


sub i2c_read_register {
    my( $self, $register, $numbytes ) = @_;
    $numbytes ||= 1;
    my $writebuffer = pack('C', $register);
    my $readbuffer = '0' x $numbytes;
    HiPi::BCM2835::_hipi_i2c_set_transfer_params( $self->_hipi_baseaddr, $self->address, $self->_clock_divider );
    my $error;
    if( $self->_function_mode eq 'corelib' ) {
        $error = HiPi::BCM2835::bcm2835_i2c_write( $writebuffer );
        croak qq(i2c_read_register failed with return value $error) if $error;
        $error = HiPi::BCM2835::bcm2835_i2c_read( $readbuffer, $numbytes );
    } else {
        $error = HiPi::BCM2835::_hipi_i2c_read_register($self->_hipi_baseaddr, $writebuffer, $readbuffer, $numbytes);
    }
    croak qq(i2c_read_register failed with return value $error) if $error;
    my $template  = ( $numbytes > 1 ) ? 'C' . $numbytes : 'C';
    my @values = unpack($template, $readbuffer);
    return @values;
}


sub i2c_read_register_rs {
    my( $self, $register, $numbytes) = @_;
    $numbytes ||= 1;
    my $writebuffer = pack('C', $register);
    my $readbuffer = '0' x ( $numbytes + 1 );
    HiPi::BCM2835::_hipi_i2c_set_transfer_params( $self->_hipi_baseaddr, $self->address, $self->_clock_divider );
    
    my $error = ( $self->_function_mode eq 'corelib' )
        ? HiPi::BCM2835::bcm2835_i2c_read_register_rs( $writebuffer, $readbuffer, $numbytes )
        : HiPi::BCM2835::_hipi_i2c_read_register_rs( $self->_hipi_baseaddr, $writebuffer, $readbuffer, $numbytes );

    croak qq(i2c_read_register_rs failed with error $error) if $error;
    my $template = ( $numbytes > 1 ) ? 'C' . $numbytes : 'C';
    my @values = unpack($template, $readbuffer);    
    return @values;
}

sub delay {
    my($class, $millis) = @_;
    HiPi::BCM2835::bcm2835_delay( $millis );
}

sub delayMicroseconds {
    my($class, $micros) = @_;
    HiPi::BCM2835::bcm2835_delayMicroseconds( $micros );
}

#-------------------------------------
# Common I2C busmode methods
# bus_write
# bus_read
# bus_write_bits
# bus_read_bits
#-------------------------------------

sub bus_write { shift->i2c_write( @_ ); }

sub bus_read {
    my( $self, $cmdval, $numbytes ) = @_;
    
    my @returnvals;
    
    if( !defined($cmdval) ) {
        @returnvals = $self->i2c_read( $numbytes );
    } elsif($self->readmode == I2C_READMODE_REPEATED_START  ) {
        @returnvals = $self->i2c_read_register_rs($cmdval, $numbytes);
    } else {
        @returnvals = $self->i2c_read_register($cmdval, $numbytes);
    }
    
    return @returnvals;
}

sub bus_read_bits {
    my($self, $regaddr, $numbytes) = @_;
    $numbytes ||= 1;
    my @bytes = $self->bus_read($regaddr, $numbytes);
    my @bits;
    while( defined(my $byte = shift @bytes )) {
        my $checkbits = 0b00000001;
        for( my $i = 0; $i < 8; $i++ ) {
            my $val = ( $byte & $checkbits ) ? 1 : 0;
            push( @bits, $val );
            $checkbits *= 2;
        }
    }
    return @bits;
}

sub bus_write_bits {
    my($self, $register, @bits) = @_;
    my $bitcount  = @bits;
    my $bytecount = $bitcount / 8;
    if( $bitcount % 8 ) { croak(qq(The number of bits $bitcount cannot be ordered into bytes)); }
    my @bytes;
    while( $bytecount ) {
        my $byte = 0;
        for(my $i = 0; $i < 8; $i++ ) {
            my $bit = shift @bits;
            $byte += ( $bit << $i );
        }
        push(@bytes, $byte);
        $bytecount --;
    }
    $self->i2c_write($register, @bytes);
}


sub busmode { return 'bcm2835'; }
1;
