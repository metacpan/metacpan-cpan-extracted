#########################################################################################
# Package        HiPi::Interface::MS5611
# Description  : Interface to MS5611_01BA03 barometric pressure sensor
# Copyright    : Copyright (c) 2013-2020 Mark Dootson
# License      : This is free software; you can redistribute it and/or modify it under
#                the same terms as the Perl 5 programming language system itself.
#########################################################################################

package HiPi::Interface::MS5611;

#########################################################################################

use strict;
use warnings;
use parent qw( HiPi::Interface::Common::Weather );
use HiPi qw( :i2c :rpi :ms5611);
use HiPi::RaspberryPi;
use Carp;

our $VERSION ='0.82';

__PACKAGE__->create_accessors( qw( backend crc) );

use constant {
    CMD_RESET    => 0x1E,
    CMD_ADC_READ => 0x00, # // ADC read command
    CMD_ADC_CONV => 0x40, # // ADC conversion command
    CMD_ADC_D1   => 0x00, # // ADC D1 conversion
    CMD_ADC_D2   => 0x10, # // ADC D2 conversion
    CMD_PROM_RD  => 0xA0, # // Prom read command 
};

sub new {
    my ($class, %userparams) = @_;
    my $pi = HiPi::RaspberryPi->new();
    
    my %params = (
        devicename   => ( $pi->board_type == RPI_BOARD_TYPE_1 ) ? '/dev/i2c-0' : '/dev/i2c-1',
        address     => 0x76,
        device      => undef,
        backend     => 'i2c',
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
                busmode     => 'i2c', # don't smbus
            );
        }
    }
    
    my $self = $class->SUPER::new(%params);
    
    $self->_init;
    
    return $self;
}

sub reset {
    my $self = shift;
    $self->device->bus_write( CMD_RESET );
    $self->delay( 3 );
    return;
}

sub _read_prom {
    my($self, $coefnum) = @_;
    $self->device->bus_write( CMD_PROM_RD + $coefnum * 2 );
    my @ret = $self->device->bus_read( undef, 2);
    my $prom = $ret[0] * 256 + $ret[1];
    return $prom;
}

sub _crc4 {
    my( $self ) = @_;
    
    # int cnt; // simple counter
    # unsigned int n_rem; // crc reminder
    # unsigned int crc_read; // original value of the crc
    # unsigned char n_bit;
    
    my $n_rem = 0x00;
    my $crc_read = $self->crc->[7];
    $self->crc->[7] = 0;
    for (my $cnt = 0; $cnt < 16; $cnt ++) { #// operation is performed on bytes
        # // choose LSB or MSB
        if ( $cnt % 2 ==1 ) {
            $n_rem ^= (($self->crc->[$cnt>>1]) & 0x00FF);
        } else {
            $n_rem ^= ( $self->crc->[$cnt>>1] >> 8);
        }
        for (my $n_bit = 8; $n_bit > 0; $n_bit--) {
            if ($n_rem & 0x8000) {
                $n_rem = ($n_rem << 1) ^ 0x3000;
            } else {
                $n_rem = $n_rem << 1;
            }
        }
    }
    $n_rem= (0x000F & ($n_rem >> 12)); #// // final 4-bit remainder is CRC code
    $self->crc->[7] = $crc_read; # // restore the crc_read to its original place
    return $n_rem ^ 0x00;
}

sub _init {
    my $self = shift;
    
    my @promvals = ();
    
    # get callibration coeffs
    for ( my $i = 0; $i < 8 ; $i++ ) {
        my $promval = $self->_read_prom( $i );
        push @promvals, $promval;
    }
    
    $self->crc( \@promvals );
    my $n_crc = $self->_crc4( @promvals );
    # is the crc check worth it ?????
}

sub _adc_cmd {
    my( $self, $cmd ) = @_;
    $self->device->bus_write( CMD_ADC_CONV + $cmd );
    
    my $osr = $cmd &  0x0F;
    if( $osr == MS5611_OSR_256 ) {
        $self->delay(1);
    } elsif($osr == MS5611_OSR_512 ) {
        $self->delay(3);
    } elsif($osr == MS5611_OSR_1024 ) {
        $self->delay(4);
    } elsif($osr == MS5611_OSR_2048 ) {
        $self->delay(6);
    } else {
        $self->delay(10);
    }
    
    $self->device->bus_write( CMD_ADC_READ );
    
    my @ret = $self->device->bus_read( undef, 3);
    
    my $result = ($ret[0] * 65536 ) + ($ret[1] * 256 ) + $ret[2];
    return $result;
}

sub read_pressure_temp {
    my($self, $pres_osr, $temp_osr ) = @_;
    $pres_osr //= MS5611_OSR_4096;
    $temp_osr  //= MS5611_OSR_4096;
    
    my $D2 = $self->_adc_cmd( CMD_ADC_D2 + $temp_osr);
    my $D1 = $self->_adc_cmd( CMD_ADC_D1 + $pres_osr);
    
    my $dT = $D2 - $self->crc->[5] * (2**8);
    
    my $OFF  = $self->crc->[2] * (2**16) + $dT * $self->crc->[4] / (2**7);
    my $SENS = $self->crc->[1] * (2**15) + $dT * $self->crc->[3] / (2**8);

    my $TEMP = 2000 + ( $dT * $self->crc->[6]) / ( 2**23 );
        
    if( $TEMP < 2000 ) {
        my $T2 = ($dT**2) / (2**31);
        my $OFF2 = 5 * ($TEMP - 2000)**2 / 2;
        my $SENS2 = 5 * ($TEMP - 2000)**2 / 2**2;
        if( $TEMP < -1500 ) {
            $OFF2 = $OFF2 + 7 * ( $TEMP + 1500 )**2;
            $SENS2 = $SENS2 + 11 * ($TEMP + 1500)**2 / 2;
        }
        $TEMP -= $T2;
        $SENS -= $SENS2;
        $OFF -= $OFF2;
    }
    
    my $P = ( ($D1 * $SENS) / (2**21) - $OFF ) / ( 2**15 );
        
    return ( sprintf('%.4f', $P / 100), sprintf('%.2f', $TEMP / 100 ) );
}


1;

__END__