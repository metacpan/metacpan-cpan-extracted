#########################################################################################
# Package        HiPi::Interface::BME280
# Description  : Interface to BME280 Temperature, Humidity & Pressure Sensor
# Copyright    : Copyright (c) 2020 Mark Dootson
# License      : This is free software; you can redistribute it and/or modify it under
#                the same terms as the Perl 5 programming language system itself.
#########################################################################################

package HiPi::Interface::BME280;

#########################################################################################

use strict;
use warnings;
use parent qw( HiPi::Interface::Common::Weather );
use HiPi qw( :i2c :rpi :bme280 );
use HiPi::RaspberryPi;
use Carp;
use Try::Tiny;

our $VERSION ='0.82';

__PACKAGE__->create_accessors( qw( backend _id _compensation repeat_oneshot ) );

use constant {
    BMP280 => BM280_TYPE_BMP280,
    BME280 => BM280_TYPE_BME280,
};

sub new {
    my ($class, %userparams) = @_;
    my $pi = HiPi::RaspberryPi->new();
    
    my %params = (
        devicename      => ( $pi->board_type == RPI_BOARD_TYPE_1 ) ? '/dev/i2c-0' : '/dev/i2c-1',
        address         => 0x76,
        device          => undef,
        backend         => 'smbus',
        repeat_oneshot  => 0,
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
    
    # wait for config to be read
    while ( $self->get_status->{im_update} ) {
        $self->sleep_millisesconds( 10 );
    }
    
    return $self;
}

sub sensor_id {
    my $self= shift;
    # BME280 is 96 == 0x60
    # BMP280 is 88, ( 87 or 86 for samples ) == 0x58 ( 0x57, 0x56 )
    return $self->_id if $self->_id;
    my ( $id ) = $self->device->bus_read( BM280_REG_ID );
    if ( $id == 0x58 || $id == 0x57 || $id == 0x56 ) {
        $id = BMP280;
    } elsif( $id == 0x60 ) {
        $id = BME280
    } else {
        croak sprintf('Unexpected sensor id 0x%X', $id);
    }
    $self->_id( $id );
    return $self->_id;
}

sub get_status {
    my $self = shift;
    my( $statusreg  ) = $self->device->bus_read( BM280_REG_STATUS, 1 );
    my $status = {
        measuring => ( $statusreg & 0b1000 ) >> 3,
        im_update => $statusreg & 0b01,
    };
    return $status;
}

sub reset {
    my $self = shift;
    $self->device->bus_write( BM280_REG_RESET, BM280_VAL_RESET );
    $self->sleep_milliseconds( 3 );
    return;
}

sub compensation {
    my $self = shift;
    return $self->_compensation if $self->_compensation;
    my @comp = ( 0 ) x 18;
    my $is_bme280 = ( $self->sensor_id == BME280 ) ? 1 : 0;
    my @bytes = $self->device->bus_read(BM280_REG_CALIB1, 26 );
    
    my @unsignedvals = ( BM280_COMP_DIG_T1, BM280_COMP_DIG_P1 );
    for my $item ( @unsignedvals ) {
        my $lsb = $item * 2;
        my $msb = $lsb + 1;
        my $val = ( ( $bytes[$msb] & 0xFF) << 8 ) + ( $bytes[$lsb] & 0xFF );
        $comp[$item] = $val;
    }
    
    my @signedvals = ( BM280_COMP_DIG_T2, BM280_COMP_DIG_T3, BM280_COMP_DIG_P2, BM280_COMP_DIG_P3, BM280_COMP_DIG_P4,
                       BM280_COMP_DIG_P5, BM280_COMP_DIG_P6, BM280_COMP_DIG_P7, BM280_COMP_DIG_P8, BM280_COMP_DIG_P9 );
    
    for my $item ( @signedvals ) {
        my $lsb = $item * 2;
        my $msb = $lsb + 1;
        my $val = ( ( $bytes[$msb] & 0xFF) << 8 ) + ( $bytes[$lsb] & 0xFF );
        if (($bytes[$msb] & 0x80) == 0x80) {
            $val = - HiPi->twos_compliment( $val, 2 );
        }
        
        $comp[$item] = $val;
    }
    
    if ( $is_bme280 ) {
        #BM280_COMP_DIG_H1 => 12,
        # my $val = pack('C*', $bytes[25]);
        $comp[BM280_COMP_DIG_H1] = $bytes[25];
        @bytes = $self->device->bus_read(BM280_REG_CALIB2, 7 );
        #BM280_COMP_DIG_H2 => 13,
        my $val = ( ( $bytes[1] & 0xFF) << 8 ) + ( $bytes[0] & 0xFF );
        if (($bytes[1] & 0x80) == 0x80) {
            $val = - HiPi->twos_compliment( $val, 2 );
        }
        $comp[BM280_COMP_DIG_H2] = $val;
        
        #BM280_COMP_DIG_H3 => 14,
        $comp[BM280_COMP_DIG_H3] = $bytes[2];
        
        #BM280_COMP_DIG_H4 => 15,
        $val = ( ( $bytes[3] & 0xFF) << 8 ) + ( ( $bytes[4] << 4 ) & 0xF0 );
        if (($bytes[3] & 0x80) == 0x80) {
            $val = - HiPi->twos_compliment( $val, 2 );
        }
        $comp[BM280_COMP_DIG_H4] = int($val / 16);
        
        #BM280_COMP_DIG_H5 => 16,
        $val = ( ( $bytes[5] & 0xFF) << 8 ) + ( $bytes[4] & 0xF0 );
        if (($bytes[5] & 0x80) == 0x80) {
            $val = - HiPi->twos_compliment( $val, 2 );
        }
        $comp[BM280_COMP_DIG_H5] = int($val / 16);
        
        if (($bytes[6] & 0x80) == 0x80) {
            $comp[BM280_COMP_DIG_H6] = - HiPi->twos_compliment( $bytes[6], 1 );
        } else {
            $comp[BM280_COMP_DIG_H6] = $bytes[6];
        }
    }
    
    $self->_compensation( \@comp );
    return $self->_compensation;
    # My test sensor values are
    #Comp T1 = 28432
    #Comp T2 = 26627
    #Comp T3 = 50
    #Comp P1 = 37015
    #Comp P2 = -10620
    #Comp P3 = 3024
    #Comp P4 = 7701
    #Comp P5 = -138
    #Comp P6 = -7
    #Comp P7 = 12300
    #Comp P8 = -12000
    #Comp P9 = 5000
    #Comp H1 = 75
    #Comp H2 = 341
    #Comp H3 = 0
    #Comp H4 = 371
    #Comp H5 = 50
    #Comp H6 = 30
}

sub set_config_preset {
    my( $self, $preset ) = @_;
    
    my $result = 0;
    
    my $presets = {
        
        normal => {
            osrs_h => BM280_OSRS_X2,
            osrs_t => BM280_OSRS_X2,
            osrs_p => BM280_OSRS_X16,
            mode   => BM280_MODE_NORMAL,
            t_sb   => BM280_STANDBY_125,
            filter => BM280_FILTER_OFF,
        },
        
        oneshot => {
            osrs_h => BM280_OSRS_X1,
            osrs_t => BM280_OSRS_X1,
            osrs_p => BM280_OSRS_X1,
            mode   => BM280_MODE_FORCED,
            t_sb   => BM280_STANDBY_125,
            filter => BM280_FILTER_OFF,
        },
        
        filter => {
            osrs_h => BM280_OSRS_X2,
            osrs_t => BM280_OSRS_X2,
            osrs_p => BM280_OSRS_X16,
            mode   => BM280_MODE_NORMAL,
            t_sb   => BM280_STANDBY_125,
            filter => BM280_FILTER_16,
        },
    };
    
    if ( exists($presets->{$preset}) ) {
        $self->set_config( $presets->{$preset} );
    }
    
    return $result;
}

sub set_config {
    my ($self, $config) = @_;
    
    # config members
    #  osrs_h
    #  osrs_t
    #  osrs_p
    #  mode
    #  t_sb
    #  filter
    
    # write BM280_REG_CTRL_MEAS
    
    # write BM280_REG_CONFIG
    
    # set chip into sleep mode
    $self->device->bus_write(BM280_REG_CTRL_MEAS, 0);
    
    # write BM280_REG_CTRL_HUM
    if( $self->sensor_id == BME280 ) {
        my $osrs_h = $config->{osrs_h} || 0;
        $self->device->bus_write(BM280_REG_CTRL_HUM, $osrs_h & 0b111);
    }
    
    # write BM280_REG_CONFIG
    {
        my $t_sb = $config->{t_sb} || 0;
        my $filter = $config->{filter} || 0;
        my $val = (( $t_sb & 0b111 ) << 5) + (( $filter & 0b111 ) << 2);
        $self->device->bus_write(BM280_REG_CONFIG, $val & 0b11111100);
    }
    
    # write BM280_REG_CTRL_MEAS
    {
        my $osrs_t = $config->{osrs_t} || 0;
        my $osrs_p = $config->{osrs_p} || 0;
        my $mode   = $config->{mode}   || 0;
        my $val = (( $osrs_t & 0b111 ) << 5) + (( $osrs_p & 0b111 ) << 2) + ( $mode & 0b11) ;
        $self->device->bus_write(BM280_REG_CTRL_MEAS, $val & 0b11111111);
    }
    
    $self->sleep_milliseconds( 100 );
    
    return 1;
}

sub get_config {
    my $self = shift;
    
    my $config = {};
    
    if( $self->sensor_id == BME280 ) {
        # BM280_REG_CTRL_HUM
        my ( $ctrl_hum ) = $self->device->bus_read(BM280_REG_CTRL_HUM, 1);
        $config->{osrs_h} = $ctrl_hum & 0b111;
    }
    
    
    # BM280_REG_CTRL_MEAS && BM280_REG_CONFIG
    my ( $ctrl_meas, $chip_conf )  = $self->device->bus_read(BM280_REG_CTRL_MEAS, 2);
    $config->{osrs_t} = ( $ctrl_meas >> 5) & 0b111;
    $config->{osrs_p} = ( $ctrl_meas >> 2) & 0b111;
    $config->{mode}   = $ctrl_meas & 0b11;
    $config->{t_sb}   = ( $chip_conf >> 5 ) & 0b111;
    $config->{filter} = ( $chip_conf >> 2 ) & 0b111;
    
    return $config;
}

sub get_values {
    my ( $self ) = @_;
    my $v = $self->get_value_hash();
    return ( $v->{t}, $v->{p}, $v->{h} );
};

sub get_value_hash {
    my ( $self ) = @_;
    
    my $is_bme280 = ( $self->sensor_id == BME280 ) ? 1 : 0;
    
    my $result = $self->get_raw_value_hash();
    my $cmp = $self->compensation;
    my $t_fine;
        
    # TEMPERATURE
    try {
        my $var1 = ( $result->{raw_t} / 16384.0  - $cmp->[BM280_COMP_DIG_T1] / 1024.0 ) * $cmp->[BM280_COMP_DIG_T2]; 
        my $var2 = ( ($result->{raw_t} / 131072.0 - $cmp->[BM280_COMP_DIG_T1] / 8192.0) *
                     ($result->{raw_t} / 131072.0 - $cmp->[BM280_COMP_DIG_T1] / 8192.0) ) * $cmp->[BM280_COMP_DIG_T3];
        $t_fine = ( $var1 + $var2 ) * 1.0;
        $result->{t} = sprintf('%.2f', ( $var1 + $var2 ) / 5120.0 );
    } catch {
        carp 'error calculating compensated temperature : ' . $_;   
    };
    
    # PRESSURE    
    try {
        my $var1 = $t_fine / 2.0 - 64000.0;
        my $var2 = $var1 * $var1 * $cmp->[BM280_COMP_DIG_P6] / 32768.0;
        $var2 = $var2 + $var1 * $cmp->[BM280_COMP_DIG_P5] * 2.0;
        $var2 = $var2 / 4.0 + $cmp->[BM280_COMP_DIG_P4] * 65536.0;
        $var1 = (($cmp->[BM280_COMP_DIG_P3] * $var1 * $var1 / 524288.0 + $cmp->[BM280_COMP_DIG_P2] * $var1)) / 524288.0;
        $var1 = (1.0 + $var1 / 32768.0) * $cmp->[BM280_COMP_DIG_P1];

        # avoid div by zero
        return if( $var1 == 0 );
        
        my $pressure = 1048576.0 - $result->{raw_p};
        $pressure = (($pressure - $var2 / 4096.0) * 6250.0) / $var1;
        $var1 = $cmp->[BM280_COMP_DIG_P9] * $pressure * $pressure / 2147483648.0;
        $var2 = $pressure * $cmp->[BM280_COMP_DIG_P8] / 32768.0;
        $pressure = $pressure + ($var1 + $var2 + $cmp->[BM280_COMP_DIG_P7]) / 16.0;
        $result->{p} = sprintf('%.2f', $pressure );
    } catch {
        carp 'error calculating compensated pressure : ' . $_;   
    };
    
    # HUMIDITY
    
    try {
        return unless $is_bme280;
        my $varH = $t_fine - 76800.0;
        $varH =  (( $result->{raw_h} * 1.0 ) - ($cmp->[BM280_COMP_DIG_H4] * 64.0 + $cmp->[BM280_COMP_DIG_H5] / 16384.0 *
                  $varH)) * ( $cmp->[BM280_COMP_DIG_H2] / 65536.0 * ( 1.0 + $cmp->[BM280_COMP_DIG_H6] /
                  67108864.0 * $varH *
                  ( 1.0 + $cmp->[BM280_COMP_DIG_H3] / 67108864.0 * $varH )));
        
        my $humidity = $varH * (1.0 - $cmp->[BM280_COMP_DIG_H1] * $varH / 524288.0);
        
        if ( $humidity > 100 ) {
            $humidity = 100;
        } elsif( $humidity < 0 ) {
            $humidity = 0;
        }
        
        $result->{h} = sprintf('%.2f', $humidity );
        
    } catch {
        carp 'error calculating compensated humidity : ' . $_;   
    };
    
    return $result;
}

sub get_raw_value_hash {
    my ( $self  ) = @_;
    
    my $is_bme280 = ( $self->sensor_id == BME280 ) ? 1 : 0;
    
    if ( $self->repeat_oneshot ) {
        my $chipconfig = $self->get_config();
        $chipconfig->{mode} = BM280_MODE_FORCED;
        $self->set_config( $chipconfig );
    }
    
    my $counter = 5000;
    
    # wait till chip ready
    my $currentstatus = $self->get_status;
    while ( $counter > 0 && ( $currentstatus->{measuring} || $currentstatus->{im_update} ) ) {
        $self->sleep_milliseconds(1);
        $counter --;
        $currentstatus = $self->get_status;
    }
    
    my $rval = {};
    
    my $numbytes = $is_bme280 ? 8 : 6;
    my @values = $self->device->bus_read(BM280_REG_PRESS_MSB, $numbytes );
    
    $rval->{raw_p} = (( $values[0] & 0xFF ) << 12 ) + (( $values[1] & 0xFF ) << 4 ) + ( ( $values[2] & 0xF0 ) >> 4 );
    $rval->{raw_t} = (( $values[3] & 0xFF ) << 12 ) + (( $values[4] & 0xFF ) << 4 ) + ( ( $values[5] & 0xF0 ) >> 4 );
    
    if ( $is_bme280 ) {
        $rval->{raw_h} = (( $values[6] & 0xFF ) << 8 ) + ( $values[7] & 0xFF );
    }
    
    return $rval;
}

1;

__END__