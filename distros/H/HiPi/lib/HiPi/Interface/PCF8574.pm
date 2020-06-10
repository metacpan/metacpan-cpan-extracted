#########################################################################################
# Package        HiPi::Interface::PCF8574
# Description  : Control NXP PCF8574 8-channel port extender
# Copyright    : Copyright (c) 2013-2017 Mark Dootson
# License      : This is free software; you can redistribute it and/or modify it under
#                the same terms as the Perl 5 programming language system itself.
#########################################################################################

package HiPi::Interface::PCF8574;

#########################################################################################

use strict;
use warnings;
use parent qw( HiPi::Interface );
use HiPi qw( :i2c :rpi  );
use Carp;

__PACKAGE__->create_ro_accessors( qw(
    backend
) );

our $VERSION ='0.81';


sub new {
    my ($class, %userparams) = @_;
    
    my $pi = HiPi::RaspberryPi->new();
    
    my %params = (
        devicename      => ( $pi->board_type == RPI_BOARD_TYPE_1 ) ? '/dev/i2c-0' : '/dev/i2c-1',
        address         => 0x3f,
        device          => undef,
        backend         => 'i2c',
    );
    
    # get user params
    foreach my $key( keys (%userparams) ) {
        $params{$key} = $userparams{$key};
    }
        
    unless( defined($params{device}) ) {
        if ( $params{backend} eq 'bcm2835' ) {
            require HiPi::BCM2835::I2C;
            $params{device} = HiPi::BCM2835::I2C->new(
                address    => $params{address},
                peripheral => ( $params{devicename} eq '/dev/i2c-0' ) ? HiPi::BCM2835::I2C::BB_I2C_PERI_0() : HiPi::BCM2835::I2C::BB_I2C_PERI_1(),
            );
        } else {
            require HiPi::Device::I2C;
            $params{device} = HiPi::Device::I2C->new(
                devicename  => $params{devicename},
                address     => $params{address},
                busmode     => $params{backend},
            );
        }
    }
    
    my $self = $class->SUPER::new(%params);
    
    return $self;
}

sub read_byte {
    my ( $self ) = @_;
    my @bytes = $self->device->bus_read(undef, 1);
    return $bytes[0];
}

sub write_byte {
    my( $self, $byte) = @_;
    $self->device->bus_write($byte & 0xFF);
}

sub read_bits {
    my ( $self ) = @_;
    my $byte = $self->read_byte;
    my @bits;
    for ( my $i = 0; $i < 8; $i++ ) {
        push @bits, ( $byte >> $i ) & 1; 
    }
    return @bits;
}

sub write_bits {
    my( $self, @bits) = @_;
    my $bitcount = @bits;
    unless( $bitcount == 8 ) {
        warn qq(Only $bitcount bits provided in write_bits. Needs 8);
        return;
    }
    my $byte = 0;
    for ( my $i = 0; $i < 8; $i++ ) {
        $byte += ($bits[$i] & 1 ) << $i;
    }
    $self->write_byte( $byte );
}

sub set_bit {
    my( $self, $bit, $value) = @_;
    if($bit < 0 || $bit > 7) {
        warn qq(Bit argument must be between 0 and 7 in set_bit. You passed $bit);
        return;
    }
    
    if($value < 0 || $value > 1) {
        warn qq(Value argument muist be 1 or 0 in set_bit. You passed $value);
        return;
    }
    
    my @bits = $self->read_bits;
    $bits[$bit] = $value;
    $self->write_bits(@bits);
}

sub get_bit {
    my( $self, $bit ) = @_;
    if($bit < 0 || $bit > 7) {
        warn qq(Bit argument must be between 0 and 7 in get_bit. You passed $bit);
        return;
    }
    my @bits = $self->read_bits;
    return $bits[$bit];
}

sub set_port { set_bit( @_ ); }

sub get_port { get_bit( @_ ); }


1;

__END__
