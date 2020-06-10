#########################################################################################
# Package        HiPi::Interface::PCA9685
# Description  : Control NXP PCA9685 16-channel, 12-bit PWM Fm+ I2C-bus controller
# Copyright    : Copyright (c) 2013-2017 Mark Dootson
# License      : This is free software; you can redistribute it and/or modify it under
#                the same terms as the Perl 5 programming language system itself.
#########################################################################################

package HiPi::Interface::PCA9685;

#########################################################################################

use strict;
use warnings;
use parent qw( HiPi::Interface );
use HiPi qw( :i2c :rpi :pca9685 );
use Carp;

__PACKAGE__->create_ro_accessors( qw(
    devicename clock frequency _servo_position _servo_types
    external_clock internal_clock debug allcall
    backend
) );

our $VERSION ='0.81';

use constant {
    MODE1      => 0x00, 
        
    RESTART    => 0x80, 
    EXTCLK     => 0x40, 
    AI         => 0x20, 
    SLEEP      => 0x10, 
    SUB1       => 0x08, 
    SUB2       => 0x04, 
    SUB3       => 0x02, 
    ALLCALL    => 0x01, 
     
    MODE2      => 0x01,
     
    INVRT      => 0x10,
    OCH        => 0x08,
    OUTDRV     => 0x04,
    OUTNE_HIMP => 0x02,
    OUTNE_ODRAIN_HIMP  => 0x01,
    OUTNE_TOPOLE_ON    => 0x01,
     
    SUBADR1     => 0x02,
    SUBADR2     => 0x03,
    SUBADR3     => 0x04,
    ALLCALLADR  => 0x05,
    
    CHAN_BASE   => 0x06,
    
    ALL_CHAN    => 0xFA,
    PRE_SCALE   => 0xFE,
    
    INTERNAL_CLOCK_MHZ => 25,
    
    CLEAR_REG   => 0x00,
};

sub new {
    my ($class, %userparams) = @_;
    
    my $pi = HiPi::RaspberryPi->new();
    
    my %params = (
        devicename      => ( $pi->board_type == RPI_BOARD_TYPE_1 ) ? '/dev/i2c-0' : '/dev/i2c-1',
        address         => 0x40,
        device          => undef,
        backend         => 'smbus',
        frequency       => 50,
        external_clock  => 0,
        internal_clock  => INTERNAL_CLOCK_MHZ,
        allcall         => 0,
    );
    
    # get user params
    foreach my $key( keys (%userparams) ) {
        $params{$key} = $userparams{$key};
    }
    
    if( $params{clock} ) {
        print q(you cannot set the clock param directly. If your board uses an external clock then pass its MHz frequency in the constructor:

my $pwm = HiPi::Interface::PCA9685->new( external_clock => 16 );

);
        exit(1);
    }
    
    # set internal params
    $params{_servo_position} = [];
    
    $params{_servo_types} = [];
    
    if($params{external_clock}) {
        $params{clock} = $params{external_clock};
    } else {
        $params{clock} = $params{internal_clock};
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
    
    my $servotypes = [
        # PCA_9685_SERVOTYPE_DEFAULT
        {
            pulse_min         => 1000,
            pulse_max         => 2000,
            degree_range      => 160,
            degree_min        => 10,
            degree_max        => 170,
        },
        # PCA_9685_SERVOTYPE_DEFAULT
        {
            pulse_min         => 1000,
            pulse_max         => 2000,
            degree_range      => 160,
            degree_min        => 10,
            degree_max        => 170,
        },
        # PCA_9685_SERVOTYPE_EXT_1
        {
            pulse_min         => 600,
            pulse_max         => 2400,
            degree_range      => 160,
            degree_min        => 10,
            degree_max        => 170,
        },
        # PCA_9685_SERVOTYPE_EXT_2
        {
            pulse_min         => 800,
            pulse_max         => 2200,
            degree_range      => 160,
            degree_min        => 10,
            degree_max        => 170,
        },
        # PCA_9685_SERVOTYPE_SG90
        {
            pulse_min         => 550,
            pulse_max         => 2350,
            degree_range      => 150,
            degree_min        => 15,
            degree_max        => 165,
        },
        
    ];
    
    for my $stype( @$servotypes ) {
        $self->register_servotype(%$stype);
    }

    $self->restart();

    return $self;
}

sub restart {
    my($self) = @_;
    
    my $prescale =  $self->calculate_prescale;
    
    my $allcall = ( $self->allcall ) ? ALLCALL : 0;
    
    # set sleep register
    $self->device->bus_write( MODE1, SLEEP );
    
    # set prescale
    $self->device->bus_write( PRE_SCALE, $prescale );
    
    # external clock ?
    if( $self->external_clock ) {
        $self->device->bus_write( MODE1, SLEEP | EXTCLK  );
    }
    
    # bring out of sleep
    $self->device->bus_write( MODE1, CLEAR_REG | $allcall );
    $self->delay( 10 );
    
    # use autoincrement and restart
    $self->device->bus_write( MODE1, RESTART | AI | $allcall );
}

sub calculate_prescale {
    my $self = shift;
    my $prescale =  int( 0.5 + ( $self->clock * 1000000.0 ) / ( 4096.0 * $self->frequency ) ) -1 ;
    # hardware defines a minimum value of 3 anyway so we can avoid returning a zero value
    $prescale ||= 3;
    return $prescale;
}

sub set_servo_degrees {
    my($self, $channel, $servotype, $degrees, $delay ) = @_;
        
    my $position;
    
    if( $delay && $delay > 0 ) {
        # delay defined in microseconds
        
        if( defined( $self->_servo_position->[$channel] ) ) {
            $position = $self->_servo_position->[$channel];
        } else {
            # read  it from device
            my ( $on, $duration ) = $self->read_channel( $channel ) ;
            $duration &= PCA_9685_SERVO_CHANNEL_MASK;
            $position = $duration || undef;
        }
    }
        
    # return if nothing bo do
    
    my $desired_postion = $self->servo_degrees_to_duration($servotype, $degrees);
    
    return $position if defined($position) && $position == $desired_postion;
    
    my $increment = ( defined($position) && $position > $desired_postion  ) ? -1 : 1;
    
    $position //= $desired_postion - $increment;
    
    while( $position != $desired_postion ) {
        $position += $increment;
        $self->write_channel( $channel, 0x00, $position & PCA_9685_SERVO_CHANNEL_MASK );
        $self->delayMicroseconds( $delay ) if $delay;
    }
    
    $self->_servo_position->[$channel] = $position;
    
    return $position;
}

sub get_servo_degrees {
    my( $self, $channel, $servotype ) = @_;
    my ( $on, $duration ) = $self->read_channel( $channel ) ;
    $duration &= PCA_9685_SERVO_CHANNEL_MASK;
    my $degrees = $self->servo_duration_to_degrees($servotype, $duration);
    return $degrees;
}

sub set_servo_pulse {
    my( $self, $channel, $us ) = @_;
    my $duration = $self->microseconds_to_duration( $us );
    $self->write_channel( $channel, 0x00, $duration & PCA_9685_SERVO_CHANNEL_MASK );
    return $duration;
}

sub get_servo_pulse {
    my( $self, $channel ) = @_;
    my ( $on, $duration ) = $self->read_channel( $channel ) ;
    $duration &= PCA_9685_SERVO_CHANNEL_MASK;
    my $us = $self->duration_to_microseconds($duration);
    return $us;
}

sub sleep {
    my $self = shift;
    $self->device->bus_write( MODE1, SLEEP );
}

sub read_channel {
    my( $self, $channel ) = @_;
    
    $channel //= 0;
    
    my ( $on_lsb, $on_msb, $off_lsb, $off_msb )  = $self->device->bus_read( CHAN_BASE + ( 4 * $channel ) , 4 );
    
    my $on  = ( ( $on_msb & 0x1F ) << 8 ) + $on_lsb;
    my $off = ( ( $off_msb & 0x1F ) << 8 ) + $off_lsb;
    
    return ( $on, $off );
}

sub write_channel {
    my( $self, $channel, $on, $off ) = @_;
    
    $on //= 0;
    $off //= 0;
    
    my $on_lsb = $on & 0xFF;
    my $on_msb = ( $on & 0x1F00 ) >> 8;
    my $off_lsb = $off & 0xFF;
    my $off_msb = ( $off & 0x1F00 ) >> 8;
    
    $self->device->bus_write( CHAN_BASE + ( 4 * $channel ), $on_lsb, $on_msb, $off_lsb, $off_msb );
}


sub microseconds_to_duration {
    my( $self, $us ) = @_;
    $us ||= 100;
    my $period_us = 1000000.0 / $self->frequency;
    my $duration_percent = ( $us / $period_us ) * 100.0;
    my $duration = 4096.0 * ( $duration_percent / 100.0 );
    $duration = int( 0.5 + $duration ) - 1;
    if( $self->debug ) {
        warn qq($us microseconds converted to duration $duration);
    }
    return $duration;
}
 
sub duration_to_microseconds {
    my( $self, $duration ) = @_;
    return 0 unless $duration;
    $duration ++;
    my $duration_percent = ( $duration / 4096.0 ) * 100.0;
    my $period_us = 1000000.0 / $self->frequency;
    my $us = int( 0.5 + (( $period_us /100 ) * $duration_percent));
    if( $self->debug ) {
        warn qq($us microseconds converted from duration $duration);
    }
    return $us;
}

sub servo_degrees_to_pulse {
    my ( $self, $servotype, $degrees) = @_;
    my $svc = $self->servo_type_config( $servotype );
    $degrees //= 90;
    $degrees = $svc->{limit_min} if $degrees < $svc->{limit_min};
    $degrees = $svc->{limit_max} if $degrees > $svc->{limit_max};
    my $us = $svc->{pulse_min} +
        int( 0.5 + ( ( $degrees - $svc->{degree_min} ) * $svc->{pw_per_degree} ) );
    
    if($self->debug) {
        warn qq($degrees degrees converted to pulse $us);
    }
    return $us;
}

sub servo_pulse_to_degrees {
    my ( $self, $servotype, $us) = @_;
    my $svc = $self->servo_type_config( $servotype );
    $us ||= $svc->{pulse_mid};
    $us = $svc->{pulse_min} if $us < $svc->{pulse_min};
    $us = $svc->{pulse_max} if $us > $svc->{pulse_max};
    return 90 if $us == $svc->{pulse_mid};
    my $degrees =  $svc->{degree_min} + int( 0.5 + ($us - $svc->{pulse_min}) / $svc->{pw_per_degree} );
    if($self->debug) {
        warn qq($us pulse converted to degrees $degrees);
    }
    return $degrees;
}

sub servo_degrees_to_duration {
    my($self, $servotype, $degrees ) = @_;
    my $us = $self->servo_degrees_to_pulse($servotype, $degrees);
    my $duration = $self->microseconds_to_duration($us);
    if($self->debug) {
        warn qq($degrees degrees converted to duration $duration);
    }
    return $duration;
}

sub servo_duration_to_degrees {
    my($self, $servotype, $duration) = @_;
    my $us = $self->duration_to_microseconds($duration);
    my $degrees = $self->servo_pulse_to_degrees($servotype, $us);
    if($self->debug) {
        warn qq($duration duration converted to degrees $degrees);
    }
    return $degrees;
}

sub servo_type_config {
    my ($self, $type) = @_;
    
    $type //= PCA_9685_SERVOTYPE_DEFAULT;
    
    if( exists($self->_servo_types->[$type] ) ) {
        return { %{ $self->_servo_types->[$type] } };
    } else {
        carp 'unknown servo type specified';
        return { %{ $self->_servo_types->[PCA_9685_SERVOTYPE_DEFAULT] } };
    }
}

sub register_servotype {
    my($self, %params) = @_;
    for my $param ( qw( pulse_min pulse_max degree_range ) ) {
        unless(exists($params{$param})) {
            carp(q(you must provide parameters pulse_min, pulse_max, and degree_range));
            return undef;
        }
    }
    unless($params{pulse_max} > $params{pulse_min}) {
        carp(q(pulse_max must be greater than pulse_min));
        return undef;
    }
    
    my $index = scalar @{ $self->_servo_types };
    my $pulse_band = $params{pulse_max} - $params{pulse_min};
    my $pw_per_degree = $pulse_band / $params{degree_range};
    my $degree_min = int( 90.5 - ( $params{degree_range} / 2.0 ));
    my $degree_max = $degree_min + $params{degree_range};
    
    my $pulse_mid = $params{pulse_min} +
        int( 0.5 + ( ( 90.0 - $degree_min ) * $pw_per_degree ) );
    
    my $limit_max = $degree_max;
    if(exists($params{degree_max})) {
        $limit_max = $params{degree_max} if $limit_max > $params{degree_max};
    }
    my $limit_min = $degree_min;
    if(exists($params{degree_min})) {
        $limit_min = $params{degree_min} if $limit_min < $params{degree_min};
    }
    
    $self->_servo_types->[$index] = {
        pulse_min => $params{pulse_min},
        pulse_max => $params{pulse_max},
        pulse_mid => $pulse_mid,
        degree_range => $params{degree_range},
        degree_min => $degree_min,
        degree_max => $degree_max,
        pw_per_degree => $pw_per_degree,
        limit_min => $limit_min,
        limit_max => $limit_max,
    };
    return $index;
} 
1;

__END__
