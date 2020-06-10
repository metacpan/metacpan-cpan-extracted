#########################################################################################
# Package        HiPi::Interface::TMP102
# Description  : Interface to TMP102 temperature sensor
# Copyright    : Copyright (c) 2013-2017 Mark Dootson
# License      : This is free software; you can redistribute it and/or modify it under
#                the same terms as the Perl 5 programming language system itself.
#########################################################################################

package HiPi::Interface::TMP102;

#########################################################################################

use strict;
use warnings;
use parent qw( HiPi::Interface );
use HiPi qw( :i2c :rpi :tmp102 );
use HiPi::RaspberryPi;
use Carp;

our $VERSION ='0.81';

__PACKAGE__->create_accessors( qw( backend config_bytes ) );

use constant {
    REGISTER_TEMPERATURE => 0x00,
    REGISTER_CONFIG      => 0x01,
    REGISTER_T_LOW       => 0x02,
    REGISTER_T_HIGH      => 0x03,
    
    EXTENTED_MODE_BIT    => 0x10,
    ALERT_BIT            => 0x20,
    CR0_BIT              => 0x40,
    CR1_BIT              => 0x80,
    
    SD_BIT               => 0x01,
    TM_BIT               => 0x02,
    POL_BIT              => 0x04,
    F0_BIT               => 0x08,
    F1_BIT               => 0x10,
    R0_BIT               => 0x20,
    R1_BIT               => 0x40,
    OS_BIT               => 0x80,
};

sub new {
    my ($class, %userparams) = @_;
    my $pi = HiPi::RaspberryPi->new();
    
    my %params = (
        devicename   => ( $pi->board_type == RPI_BOARD_TYPE_1 ) ? '/dev/i2c-0' : '/dev/i2c-1',
        address     => 0x48,
        device      => undef,
        backend     => 'smbus',
    );
    
    # get user params
    foreach my $key( keys (%userparams) ) {
        $params{$key} = $userparams{$key};
    }
    
    if( $params{busmode} ) {
        $params{backend} = $params{busmode};
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
    
    $self->_init;
    
    return $self;
}

sub _init {
    my $self = shift;
    my @cnf = $self->device->bus_read( REGISTER_CONFIG, 2 );
    $self->config_bytes( \@cnf );
}

sub read_config {
    my $self = shift;
    my @cnf = $self->device->bus_read( REGISTER_CONFIG, 2 );
    return @cnf;
}

sub shutdown_mode {
    my ($self, $newmode) = @_;
    my @cnf = $self->read_config;
    if(defined( $newmode )) {
        $newmode = ( $newmode ) ? 1 : 0;
        my $mask = SD_BIT;
        my $val = $newmode ;
        $cnf[0] = ($cnf[0] & ~$mask) | $val;
        $self->device->bus_write( REGISTER_CONFIG, @cnf );
    }
    $self->config_bytes( \@cnf );
    return ( $cnf[0] & SD_BIT ) ? 1 : 0 ;
}

sub thermostat_mode {
    my ($self, $newmode) = @_;
    my @cnf = $self->read_config;
    if(defined( $newmode )) {
        $newmode = ( $newmode ) ? 1 : 0;
        my $mask = TM_BIT;
        my $val = $newmode << 1 ;
        $cnf[0] = ($cnf[0] & ~$mask) | $val;
        $self->device->bus_write( REGISTER_CONFIG, @cnf );
    }
    $self->config_bytes( \@cnf );
    return ( $cnf[0] & TM_BIT ) ? 1 : 0 ;
}

sub polarity {
    my ($self, $newpol) = @_;
    my @cnf = $self->read_config;
    if(defined( $newpol )) {
        $newpol = ( $newpol ) ? 1 : 0;
        my $mask = POL_BIT;
        my $val = $newpol << 2;
        $cnf[0] = ($cnf[0] & ~$mask) | $val;
        $self->device->bus_write( REGISTER_CONFIG, @cnf );
    }
    $self->config_bytes( \@cnf );
    return ( $cnf[0] & POL_BIT ) ? 1 : 0 ;
}

sub fault_queue {
    my( $self, $newrate ) = @_;
    my @cnf = $self->read_config;
    
    my $mask = F1_BIT | F0_BIT;
    
    if( defined( $newrate ) && $newrate >= 0 && $newrate <= 3) {
        
        my $val  = $newrate << 3;    
        $cnf[0] = ($cnf[0] & ~$mask) | $val;
        $self->device->bus_write( REGISTER_CONFIG, @cnf );
    }
    $self->config_bytes( \@cnf );
    return ( $cnf[0] & $mask ) >> 3;
}

# Pointless = always 0b11 / 3
#sub conversion_resolution {
#    my( $self ) = @_;
#    my @cnf = $self->read_config;
#    
#    my $mask = R1_BIT | R0_BIT;
#    
#    return ( $cnf[0] & $mask ) >> 5;
#}

sub one_shot {
    my ($self, $newmode) = @_;
    my @cnf = $self->read_config;
    if( $newmode ) { # for this, new mode must be 1
        $newmode = 1;
        my $mask = OS_BIT;
        my $val = $newmode << 7;
        $cnf[0] = ($cnf[0] & ~$mask) | $val;
        $self->device->bus_write( REGISTER_CONFIG, @cnf );
    }
    $self->config_bytes( \@cnf );
    return ( $cnf[0] & OS_BIT ) ? 1 : 0 ;
}

sub extended_mode {
    my ($self, $newmode) = @_;
    my @cnf = $self->read_config;
    if(defined( $newmode )) {
        $newmode = ( $newmode ) ? 1 : 0;
        my $mask = EXTENTED_MODE_BIT;
        my $val = $newmode << 4;
        $cnf[1] = ($cnf[1] & ~$mask) | $val;
        $self->device->bus_write( REGISTER_CONFIG, @cnf );
        
        # we've changed the mode - we need to wait
        # for a conversion to happen at the new bit rate
        # get the current conv rate
        
        my $rate = ( $cnf[1] & ( CR1_BIT | CR0_BIT ) ) >> 6;
        my $delay_ms = 250;
        if( $rate == TMP102_CR_0_25HZ ) {
            $delay_ms = 4000;
        } elsif( $rate == TMP102_CR_1HZ ) {
            $delay_ms = 1000;
        } elsif( $rate == TMP102_CR_4HZ ) {
            $delay_ms = 250;
        } elsif( $rate == TMP102_CR_4HZ ) {
            $delay_ms = 125;
        } else {
            warn q(using default delay - current conversion rate returns bad value);
        }
        
        $self->delay( $delay_ms );
       
    }
    $self->config_bytes( \@cnf );
    return ( $cnf[1] & EXTENTED_MODE_BIT ) ? 1 : 0 ;
}

sub alert {
    my ($self) = @_;
    my @cnf = $self->read_config;
    $self->config_bytes( \@cnf );
    return ( $cnf[1] & ALERT_BIT ) ? 1 : 0 ;
}

sub conversion_rate {
    my( $self, $newrate ) = @_;
    my @cnf = $self->read_config;
    
    my $mask = CR1_BIT | CR0_BIT;
    
    if( defined( $newrate ) && $newrate >= 0 && $newrate <= 3) {
        
        my $val  = $newrate << 6;    
        $cnf[1] = ($cnf[1] & ~$mask) | $val;
        $self->device->bus_write( REGISTER_CONFIG, @cnf );
    }
    $self->config_bytes( \@cnf );
    return ( $cnf[1] & $mask ) >> 6;
}

sub _read_temperature_value {
    my($self, $register) = @_;
    my @bytes = $self->device->bus_read( $register, 2 );
    
    my $shiftbits = ( $self->config_bytes->[1] & EXTENTED_MODE_BIT ) ? 3 : 4;
    
    my $val = ($bytes[0] << 8 ) + $bytes[1];

    if( $bytes[0] & 0x80 ) { # is negative ?
        $val = HiPi->twos_compliment( $val, 2 );
        return - ( ( $val >> $shiftbits ) * 0.0625 );
    } else {
        return ( $val >> $shiftbits ) * 0.0625;
    }
}

sub _write_temperature_value {
    my($self, $register, $newval ) = @_;
    
    my $shiftbits = ( $self->config_bytes->[1] & EXTENTED_MODE_BIT ) ? 3 : 4;    
    my $negative = ( $newval < 0 );
    $newval = abs($newval);
    $newval = int( 0.5 + ( $newval / 0.0625 ) );
    $newval <<= $shiftbits;
    
    # limit range
    my $limitmask = ( 0x7fff >> $shiftbits ) << $shiftbits;
    $newval &= $limitmask;
    
    if( $negative ) {
        $newval = HiPi->twos_compliment( $newval, 2 );
    }
    
    $self->device->bus_write( $register, ( $newval >> 8 ) & 0xff, $newval & 0xff );
}

sub read_temperature {
    my $self = shift;
    return $self->_read_temperature_value( REGISTER_TEMPERATURE );
}

sub high_limit {
    my ($self, $newlimit) = @_;
    if(defined($newlimit)) {
        $self->_write_temperature_value( REGISTER_T_HIGH, $newlimit );
    }
    return $self->_read_temperature_value( REGISTER_T_HIGH );
}

sub low_limit {
    my ($self, $newlimit) = @_;
    if(defined($newlimit)) {
        $self->_write_temperature_value( REGISTER_T_LOW, $newlimit );
    }
    return $self->_read_temperature_value( REGISTER_T_LOW );
}

sub one_shot_temperature {
    my $self = shift;
    
    # check if we are in shutdown_mode
    if( $self->shutdown_mode ) {
        $self->one_shot(1);
        while(!$self->one_shot) {
            $self->delay(30);
        }
    }
    
    return $self->read_temperature;   
}



1;

__END__