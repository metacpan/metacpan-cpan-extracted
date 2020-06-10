#########################################################################################
# Package        HiPi::Interface::PCA9544
# Description  : Control NXP PCA9544A & Philips PCA9544 4 channel I2C MUX
# Copyright    : Copyright (c) 2018 Mark Dootson
# License      : This is free software; you can redistribute it and/or modify it under
#                the same terms as the Perl 5 programming language system itself.
#########################################################################################

package HiPi::Interface::PCA9544;

#########################################################################################

use strict;
use warnings;
use parent qw( HiPi::Interface );
use HiPi qw( :i2c :rpi );
use Carp;

__PACKAGE__->create_ro_accessors( qw(
    devicename 
    backend
) );

our $VERSION ='0.81';

use constant {
    CHANNEL_BIT     => 0x4,
    CHANNEL_0       => 0x4,
    CHANNEL_1       => 0x5,
    CHANNEL_2       => 0x6,
    CHANNEL_3       => 0x7,
    CHANNEL_NONE    => 0x0,
    CHANNEL_MASK    => 0x7,
    INTERRUPT_0     => 0x10,
    INTERRUPT_1     => 0x20,
    INTERRUPT_2     => 0x40,
    INTERRUPT_3     => 0x80,
};

sub new {
    my ($class, %userparams) = @_;
    
    my $pi = HiPi::RaspberryPi->new();
    
    my %params = (
        devicename      => ( $pi->board_type == RPI_BOARD_TYPE_1 ) ? '/dev/i2c-0' : '/dev/i2c-1',
        address         => 0x70,
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
                busmode     => 'i2c', # needs read without write
            );
        }
    }
    
    my $self = $class->SUPER::new(%params);
    
    return $self;
}

sub set_channel {
    my($self, $channel) = @_;
    if(!defined($channel)) {
        $self->write_control_register( CHANNEL_NONE );
    } elsif( $channel =~ /^0|1|2|3$/ ) {
        $self->write_control_register( $channel + CHANNEL_BIT );
    } else {
        warn 'invalid channel requested';
    }
}

sub get_status {
    my $self = shift;
    my $register = $self->read_control_register();
    my $channel = undef;
    my $regbits = $register & CHANNEL_MASK;
    
    if( $regbits & CHANNEL_BIT ) {
        $channel = $regbits - CHANNEL_BIT;
    }
    
    return $channel unless( wantarray );
    
    my @interrupts = (
        ( $register & INTERRUPT_0 ) ? 1 : 0,
        ( $register & INTERRUPT_1 ) ? 1 : 0,
        ( $register & INTERRUPT_2 ) ? 1 : 0,
        ( $register & INTERRUPT_3 ) ? 1 : 0,
    );
    
    return ( $channel , @interrupts );
}

sub read_control_register {
    my( $self ) = @_;
    my @bytes = $self->device->bus_read( undef, 1 );
    return $bytes[0];
}

sub write_control_register {
    my( $self , $regbyte) = @_;
    $self->device->bus_write( $regbyte );
}

1;

__END__
