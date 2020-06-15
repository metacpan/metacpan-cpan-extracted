#########################################################################################
# Package        HiPi::Interface::MPL3115A2
# Description  : Interface to MPL3115A2 precision Altimeter
# Copyright    : Copyright (c) 2013-2017 Mark Dootson
# License      : This is free software; you can redistribute it and/or modify it under
#                the same terms as the Perl 5 programming language system itself.
#########################################################################################

package HiPi::Interface::MPL3115A2;

#########################################################################################

use strict;
use warnings;
use parent qw( HiPi::Interface::Common::Weather );
use HiPi qw( :i2c :mpl3115a2 :rpi );
use HiPi::RaspberryPi;
use Carp;

our $VERSION ='0.81';

__PACKAGE__->create_accessors( qw( osdelay backend ) );

sub new {
    my ($class, %userparams) = @_;
    my $pi = HiPi::RaspberryPi->new();
    
    my %params = (
        devicename   => ( $pi->board_type == RPI_BOARD_TYPE_1 ) ? '/dev/i2c-0' : '/dev/i2c-1',
        address     => 0x60,
        device      => undef,
        osdelay     => MPL_OSREAD_DELAY,
        readmode    => I2C_READMODE_REPEATED_START,
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
                readmode   => $params{readmode},
            );
        } else {
            require HiPi::Device::I2C;
            $params{device} = HiPi::Device::I2C->new(
                devicename  => $params{devicename},
                address     => $params{address},
                busmode     => $params{backend},
                readmode    => $params{readmode},
            );
        }
    }
    
    
    my $self = $class->SUPER::new(%params);
    # init
    {
        my $maxloop = 0;
        while ( $maxloop++ < 20 ) {
            $self->sysmod;
            last if( $self->who_am_i && $self->who_am_i == 0xC4);
            $self->device->delay(100);
        }
        $self->device->delay(100);
        $self->sysmod;
    }
    
    return $self;
}

sub unpack_altitude {
    my( $self, $msb, $csb, $lsb ) =@_;
    my $alt = $msb << 8;
    $alt += $csb;
    if( $msb > 127 ) {
        $alt = 0xFFFF &~$alt;
        $alt ++;
        $alt *= -1;
    }
    $alt += 0.5    if( $lsb & 0b10000000 );
    $alt += 0.25   if( $lsb & 0b01000000 );
    $alt += 0.125  if( $lsb & 0b00100000 );
    $alt += 0.0625 if( $lsb & 0b00010000 );
    return $alt;
}

sub pack_altitude {
    my($self, $alt) = @_;
    my $mint = int( $alt );
    my $lsb =  0b1111 & int(0.5 + ( 15.0 * (abs($alt) - abs($mint))));
    $lsb <<= 4;
    
    if( $alt < 0 ) {
        $mint *= -1;
        $mint --;
        $mint = 0xFFFF &~$mint;
    }
    
    my $msb = $mint >> 8;
    my $csb = $mint & 0xFF;
    return($msb, $csb, $lsb);
}

sub unpack_temperature {
    my( $self, $msb, $lsb ) =@_;
    if( $msb > 127 ) {
        $msb = 0xFFFF &~$msb;
        $msb ++;
        $msb *= -1;
    }
    $msb += 0.5    if( $lsb & 0b10000000 );
    $msb += 0.25   if( $lsb & 0b01000000 );
    $msb += 0.125  if( $lsb & 0b00100000 );
    $msb += 0.0625 if( $lsb & 0b00010000 );
    return $msb;
}

sub pack_temperature {
    my($self, $temp) = @_;
    my $mint = int( $temp );
    my $lsb =  0b1111 & int(0.495 + ( 15.0 * (abs($temp) - abs($mint))));
    $lsb <<= 4;
    if( $temp < 0 ) {
        $mint *= -1;
        $mint --;
        $mint = 0xFF &~$mint;
    }
    my $msb = $mint & 0xFF;
    return($msb, $lsb);
}

sub unpack_pressure {
    my( $self, $msb, $csb, $lsb ) =@_;
    my $alt = $msb << 10;
    $alt += $csb << 2;
    $alt += 0b11 & ( $lsb >> 6 );
    $alt += 0.5  if( $lsb & 0b00100000 );
    $alt += 0.25 if( $lsb & 0b00010000 );
    return $alt;
}

sub pack_pressure {
    my($self, $alt) = @_;
    my $mint = int( $alt );
    my $lsb =  0b1111 & int(0.495 + ( 3.0 * (abs($alt) - abs($mint))));
    $lsb <<= 4;
    my $msb = $mint & 0x3FC00;
    $msb >>= 10;
    my $csb = $mint & 0x3FC;
    $csb >>= 2;
    my $extra = $mint & 0x03;
    $lsb += ($extra << 6);
    return($msb, $csb, $lsb);
}

sub sysmod {
    my $self = shift;
    ( $self->device->bus_read(MPL_REG_SYSMOD, 1))[0];
}

sub who_am_i {
    my $self = shift;
    ( $self->device->bus_read(MPL_REG_WHO_AM_I, 1))[0];
}

sub active {
    my ($self, $set) = @_;
    my ( $curreg ) = $self->device->bus_read(MPL_REG_CTRL_REG1, 1);
    my $rval = $curreg & MPL_CTRL_REG1_SBYB;
    if (defined($set)) {
        my $setmask = ( $set ) ? MPL_CTRL_REG1_SBYB | $curreg : $curreg &~MPL_CTRL_REG1_SBYB;
        $self->device->bus_write(MPL_REG_CTRL_REG1, $setmask);
        $rval = $setmask & MPL_CTRL_REG1_SBYB;
    }
    return $rval;
}

sub reboot {
    my $self = shift;
    $self->device->bus_write_error(MPL_REG_CTRL_REG1, MPL_CTRL_REG1_RST);
    $self->device->delay(100);
}


sub oversample {
    my($self, $newval) = @_;
    my ( $curreg ) = $self->device->bus_read(MPL_REG_CTRL_REG1, 1);
    my $currentval = $curreg & MPL_OVERSAMPLE_MASK;
    if(defined($newval)) {
        $newval &= MPL_OVERSAMPLE_MASK;
        unless( $currentval == $newval ) {
            if( $curreg & MPL_CTRL_REG1_SBYB ) {
                croak('cannot set oversample rate while system is active');
            }
            $self->device->bus_write(MPL_REG_CTRL_REG1, $curreg | $newval );
            ( $curreg ) = $self->device->bus_read(MPL_REG_CTRL_REG1, 1);
            $currentval = $curreg & MPL_OVERSAMPLE_MASK;
        }
    }
    return $currentval;
}

sub delay_from_oversample {
    my ($self, $oversample) = @_;
    # calculate delay needed for oversample to complete.
    # spec sheet says 60ms at oversample 1 and 1000ms at oversample 128
    # so if we range at 100ms to 1100ms and the oversample register bits
    # contain a value of 0 through 7 representing 1 to 128
    # delay = 100 + 2^$oversample * 1000/128
    $oversample >>= 3;
    return int(100.5 + 2**$oversample * 1000/128);
}

sub raw {
    my($self, $newval) = @_;
    my ( $curreg ) = $self->device->bus_read(MPL_REG_CTRL_REG1, 1);
    my $currentval = $curreg & MPL_CTRL_REG1_RAW;
    if(defined($newval)) {
        $newval &= MPL_CTRL_REG1_RAW;
        unless( $currentval == $newval ) {
            if( $curreg & MPL_CTRL_REG1_SBYB ) {
                croak('cannot set raw mode while system is active');
            }
            $self->device->bus_write(MPL_REG_CTRL_REG1, $curreg | $newval );
            ( $curreg ) = $self->device->bus_read(MPL_REG_CTRL_REG1, 1);
            $currentval = $curreg & MPL_CTRL_REG1_RAW;
        }
    }
    return $currentval;
}

sub mode {
    my($self, $newmode) = @_;
    my ( $curreg ) = $self->device->bus_read(MPL_REG_CTRL_REG1, 1);
    my $currentmode = ( $curreg & MPL_CTRL_REG1_ALT ) ? MPL_FUNC_ALTITUDE : MPL_FUNC_PRESSURE;
    if(defined($newmode)) {
        unless( $currentmode == $newmode ) {
            if( $curreg & MPL_CTRL_REG1_SBYB ) {
                croak('cannot set altitude / pressure mode while system is active');
            }
            my $setmask = ($newmode == MPL_FUNC_ALTITUDE) ? $curreg | MPL_CTRL_REG1_ALT : $curreg &~MPL_CTRL_REG1_ALT;
            $self->device->bus_write(MPL_REG_CTRL_REG1, $setmask );
            ( $curreg ) = $self->device->bus_read(MPL_REG_CTRL_REG1, 1);
            $currentmode = ( $curreg & MPL_CTRL_REG1_ALT ) ? MPL_FUNC_ALTITUDE : MPL_FUNC_PRESSURE;
        }
    }
    return $currentmode;
}

sub os_temperature {
    my $self = shift;
    my ( $pvalue, $tvalue ) = $self->os_any_data; 
    return  $tvalue;    
}

sub os_pressure {
    my $self = shift;
    my($pdata, $tdata) = $self->os_both_data( MPL_FUNC_PRESSURE );
    return $pdata;
}

sub os_altitude {
    my $self = shift;
    my($pdata, $tdata) = $self->os_both_data( MPL_FUNC_ALTITUDE );
    return $pdata;
}

sub os_any_data {
    my $self = shift;
    my ( $curreg ) = $self->device->bus_read(MPL_REG_CTRL_REG1, 1);
    
    my $currentmode = ( $curreg & MPL_CTRL_REG1_ALT ) ? MPL_FUNC_ALTITUDE : MPL_FUNC_PRESSURE;
    my $oversample  = ( $curreg & MPL_OVERSAMPLE_MASK );
    
    # whatever the original state of CTRL_REG1, we want to restore it with
    # one shot bit cleared
    my $restorereg = $curreg &~MPL_CTRL_REG1_OST;
    
    my $delayms = $self->delay_from_oversample($oversample);
        
    # clear any one shot bit
    $self->device->bus_write(MPL_REG_CTRL_REG1, $curreg &~MPL_CTRL_REG1_OST );
    # set one shot bit
    $self->device->bus_write(MPL_REG_CTRL_REG1, $curreg | MPL_CTRL_REG1_OST );
    
    # wait before read
    $self->device->delay($delayms);
        
    # read data       
    my( $pmsb, $pcsb, $plsb, $tmsb, $tlsb)
        = $self->device->bus_read(MPL_REG_OUT_P_MSB, 5);
    
    # convert pressure / altitude data
    my $pdata;
    if( $currentmode == MPL_FUNC_ALTITUDE ) {
        $pdata = $self->unpack_altitude( $pmsb, $pcsb, $plsb );
    } else {
        $pdata = $self->unpack_pressure( $pmsb, $pcsb, $plsb );
    }
    
    # convert temperature data
    my $tdata = $self->unpack_temperature( $tmsb, $tlsb );
    
    # restore REG1 clearing any one shot bit
    $self->device->bus_write(MPL_REG_CTRL_REG1, $restorereg );
    
    # return both
    return ( $pdata, $tdata );    
}

sub os_both_data {
    my($self, $function) = @_;
    $function //= MPL_FUNC_PRESSURE; # default it not defined
    
    my ( $curreg ) = $self->device->bus_read(MPL_REG_CTRL_REG1, 1);
    
    my $currentmode   = ( $curreg & MPL_CTRL_REG1_ALT ) ? MPL_FUNC_ALTITUDE : MPL_FUNC_PRESSURE;
    my $currentactive = $curreg & 0x01;
    
    # we can't change datamodes if system is currently active
    if($currentactive && ( $currentmode !=  $function )) {
        croak('cannot switch between pressure and altitude modes when system is active');
    }
    
    my $ctrlmask = ( $function == MPL_FUNC_ALTITUDE )
        ? $curreg | MPL_CTRL_REG1_ALT
        : $curreg &~MPL_CTRL_REG1_ALT;
    
    $self->device->bus_write(MPL_REG_CTRL_REG1, $ctrlmask );
    $self->os_any_data;
}

sub os_all_data {
    my($self ) = @_;
    
    my( $altitude, $discard ) = $self->os_both_data( MPL_FUNC_ALTITUDE );
    my( $pressure, $tempert ) = $self->os_both_data( MPL_FUNC_PRESSURE );
    
    return ( $altitude, $pressure, $tempert );    
}


1;
__END__