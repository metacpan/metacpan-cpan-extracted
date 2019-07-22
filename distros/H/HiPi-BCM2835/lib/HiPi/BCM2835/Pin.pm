#########################################################################################
# Package        HiPi::BCM2835::Pin
# Description:   Pin
# Copyright    : Copyright (c) 2013-2019 Mark Dootson
# License      : This work is free software; you can redistribute it and/or modify it 
#                under the terms of the GNU General Public License as published by the 
#                Free Software Foundation; either version 3 of the License, or any later 
#                version.
#########################################################################################

package HiPi::BCM2835::Pin;

#########################################################################################

use strict;
use warnings;
use parent qw( HiPi::Pin );
use Carp;
use HiPi 0.80;
use HiPi qw( :rpi );

our $VERSION ='0.65';

sub _open {
    my ($class, %params) = @_;
    defined($params{pinid}) or croak q(pinid not defined in parameters);
    my $self = $class->SUPER::_open(%params);
    return $self;
}

sub _do_getvalue {
    HiPi::BCM2835::bcm2835_gpio_lev($_[0]->pinid);
}

sub _do_setvalue {
    HiPi::BCM2835::bcm2835_gpio_write($_[0]->pinid, $_[1]);
}

sub _do_getmode {
    HiPi::BCM2835::hipi_gpio_fget($_[0]->pinid );
}

sub _do_setmode {
    HiPi::BCM2835::bcm2835_gpio_fsel($_[0]->pinid, $_[1]);
}

sub _do_getinterrupt {
    HiPi::BCM2835::hipi_gpio_get_eds( $_[0]->pinid );
}

sub _do_setinterrupt {
    my ($self, $newedge) = @_;
    if($newedge & RPI_INT_RISE) {
        HiPi::BCM2835::bcm2835_gpio_ren(  $_[0]->pinid );
    } else {
        HiPi::BCM2835::bcm2835_gpio_clr_ren(  $_[0]->pinid );
    }
    if($newedge & RPI_INT_FALL) {
        HiPi::BCM2835::bcm2835_gpio_fen(  $_[0]->pinid );
    } else {
        HiPi::BCM2835::bcm2835_gpio_clr_fen(  $_[0]->pinid );
    }
    if($newedge & RPI_INT_ARISE) {
        HiPi::BCM2835::bcm2835_gpio_aren(  $_[0]->pinid );
    } else {
        HiPi::BCM2835::bcm2835_gpio_clr_aren(  $_[0]->pinid );
    }
    if($newedge & RPI_INT_AFALL) {
        HiPi::BCM2835::bcm2835_gpio_afen(  $_[0]->pinid );
    } else {
        HiPi::BCM2835::bcm2835_gpio_clr_afen(  $_[0]->pinid );
    }
    if($newedge & RPI_INT_HIGH) {
        HiPi::BCM2835::bcm2835_gpio_hen(  $_[0]->pinid );
    } else {
        HiPi::BCM2835::bcm2835_gpio_clr_hen(  $_[0]->pinid );
    }
    if($newedge & RPI_INT_LOW) {
        HiPi::BCM2835::bcm2835_gpio_len(  $_[0]->pinid );
    } else {
        HiPi::BCM2835::bcm2835_gpio_clr_len(  $_[0]->pinid );
    }
    
    # clear edge detection status
    HiPi::BCM2835::bcm2835_gpio_set_eds( $_[0]->pinid );
}

sub _do_clear_interrupt {
    # clear edge detection status
    HiPi::BCM2835::bcm2835_gpio_set_eds( $_[0]->pinid );
}

sub _do_setpud {
    HiPi::BCM2835::bcm2835_gpio_set_pud($_[0]->pinid, $_[1]);
}

sub _do_getpud {
    HiPi::BCM2835::bcm2835_gpio_get_pud($_[0]->pinid);
}

sub _do_get_function_name {
    HiPi::BCM2835::hipi_gpio_fget_name($_[0]->pinid);
}

1;
