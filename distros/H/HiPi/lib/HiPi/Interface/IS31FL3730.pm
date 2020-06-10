#########################################################################################
# Package        HiPi::Interface::IS31FL3730
# Description  : Interface to IS31FL3730 matrix LED driver
# Copyright    : Copyright (c) 2018 Mark Dootson
# License      : This is free software; you can redistribute it and/or modify it under
#                the same terms as the Perl 5 programming language system itself.
#########################################################################################

package HiPi::Interface::IS31FL3730;

#########################################################################################

use strict;
use warnings;
use parent qw( HiPi::Interface );
use HiPi qw( :i2c :rpi :fl3730);
use HiPi::RaspberryPi;
use Carp;
use Try::Tiny;

our $VERSION ='0.81';

__PACKAGE__->create_accessors( qw( ) );

use constant {
    REG_CONFIG   => 0x00,
    REG_MATRIX_1 => 0x01,
    REG_MATRIX_2 => 0x0E,
    REG_UPD_COL  => 0x0C,
    REG_LIGHTING => 0x0D,
    REG_PWM      => 0x19,
    REG_RESET    => 0xFF,
};


sub new {
    my ($class, %userparams) = @_;
    my $pi = HiPi::RaspberryPi->new();
    
    my %params = (
        devicename   => ( $pi->board_type == RPI_BOARD_TYPE_1 ) ? '/dev/i2c-0' : '/dev/i2c-1',
        address     => 0x60,
        device      => undef,
        backend     => 'smbus',
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
                #busmode     => $params{backend},
                busmode     => 'i2c', # force i2c
            );
        }
    }
    
    my $self = $class->SUPER::new(%params);
    
    return $self;
}

sub configure {
    my($self, $mask ) = @_;
    $self->send_command( REG_CONFIG, $mask );
}

sub matrix_1_data {
    my($self, @data ) = @_;
    $self->send_command( REG_MATRIX_1, @data );
}

sub matrix_2_data {
    my($self, @data ) = @_;
    $self->send_command( REG_MATRIX_2, @data );
}

sub lighting_effect {
    my($self, $mask) = @_;
    $self->send_command( REG_LIGHTING, $mask );
}

sub brightness {
    my($self, $value) = @_;
    $value //= 127; # undefined get default 127
    my $mask = ( $value > 127 ) ? 0x80 : $value & 0x7F;
    $self->send_command( REG_PWM, $mask );
}

sub update {
    my $self = shift;
    $self->send_command( REG_UPD_COL, 0x00 );
}

sub reset {
    my $self = shift;
    $self->send_command( REG_RESET, 0x00 );
}

sub send_command {
    my($self, $register, @data ) = @_;
    # Timing issue - pullup values if not mounted as pHAT ?
    # Clock too high on RPi 3 ??
    # Need to resolve - but for now catch and retry
    my $continue = 10;
    while( $continue ) {
        try {
            $self->device->bus_write( $register, @data );
            $continue = 0;
        } catch {
            $continue --;
            if( $continue <= 0 ) {
                croak sprintf('IO Error writing to register 0x%X', $register);
            }
            $self->delay(5);
        };
    }
}

1;

__END__