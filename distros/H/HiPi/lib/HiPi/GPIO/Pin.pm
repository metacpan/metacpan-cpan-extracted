#########################################################################################
# Package        HiPi::GPIO::Pin
# Description:   Pin
# Copyright    : Copyright (c) 2013-2017 Mark Dootson
# License      : This is free software; you can redistribute it and/or modify it under
#                the same terms as the Perl 5 programming language system itself.
#########################################################################################
package HiPi::GPIO::Pin;

#########################################################################################

use strict;
use warnings;
use parent qw( HiPi::Pin );
use Carp;
use HiPi qw( :rpi );

our $VERSION ='0.65';

__PACKAGE__->create_accessors( qw( gpio _needs_interrupt_cleanup ) );

sub _open {
    my ($class, %params) = @_;
    defined($params{pinid}) or croak q(pinid not defined in parameters);
    
    require HiPi::GPIO;
    
    my $self = $class->SUPER::_open(%params);
    return $self;
}

sub _do_getvalue {
    my($self) = @_;
    return HiPi::GPIO::xs_gpio_read( $self->pinid );
}

sub _do_setvalue {
    my( $self, $newval) = @_;
    return HiPi::GPIO::xs_gpio_write( $self->pinid, $newval );
}

sub _do_getmode {
    my $self = shift;
    return HiPi::GPIO::xs_gpio_get_mode( $self->pinid );
}

sub _do_setmode {
    my ($self, $newmode) = @_;
    return HiPi::GPIO::xs_gpio_set_mode( $self->pinid, $newmode );
}

sub _do_getinterrupt {
    my ( $self ) = @_;
    my $ints = 0;
    
    $ints |= RPI_INT_RISE  if HiPi::GPIO->get_rising_edge_detect(  $_[0]->pinid );
    $ints |= RPI_INT_FALL  if HiPi::GPIO->get_falling_edge_detect(  $_[0]->pinid );
    
    $ints |= RPI_INT_ARISE if HiPi::GPIO->get_async_rising_edge_detect(  $_[0]->pinid );
    $ints |= RPI_INT_AFALL if HiPi::GPIO->get_async_falling_edge_detect(  $_[0]->pinid );
    
    $ints |= RPI_INT_HIGH  if HiPi::GPIO->get_high_edge_detect(  $_[0]->pinid );
    $ints |= RPI_INT_LOW   if HiPi::GPIO->get_low_edge_detect(  $_[0]->pinid );
    
    return $ints;
}

sub _do_setinterrupt {
    my ($self, $newedge) = @_;
    
    $self->_needs_interrupt_cleanup(1);
    
    if($newedge & RPI_INT_RISE) {
        HiPi::GPIO->set_rising_edge_detect(  $_[0]->pinid, 1 );
    } else {
        HiPi::GPIO->set_rising_edge_detect(  $_[0]->pinid, 0 );
    }
    if($newedge & RPI_INT_FALL) {
        HiPi::GPIO->set_falling_edge_detect(  $_[0]->pinid, 1 );
    } else {
        HiPi::GPIO->set_falling_edge_detect(  $_[0]->pinid, 0 );
    }
    if($newedge & RPI_INT_ARISE) {
        HiPi::GPIO->set_async_rising_edge_detect(  $_[0]->pinid, 1 );
    } else {
        HiPi::GPIO->set_async_rising_edge_detect(  $_[0]->pinid, 0 );
    }
    if($newedge & RPI_INT_AFALL) {
        HiPi::GPIO->set_async_falling_edge_detect(  $_[0]->pinid, 1 );
    } else {
        HiPi::GPIO->set_async_falling_edge_detect(  $_[0]->pinid, 0 );
    }
    if($newedge & RPI_INT_HIGH) {
        HiPi::GPIO->set_high_edge_detect(  $_[0]->pinid, 1 );
    } else {
        HiPi::GPIO->set_high_edge_detect(  $_[0]->pinid, 0 );
    }
    if($newedge & RPI_INT_LOW) {
        HiPi::GPIO->set_low_edge_detect(  $_[0]->pinid, 1 );
    } else {
        HiPi::GPIO->set_low_edge_detect(  $_[0]->pinid, 0 );
    }
    
    # clear edge detection status
    HiPi::GPIO->clear_pin_edge_detect( $_[0]->pinid );
}

sub _do_clear_edge_detect {
    # clear edge detection status
    HiPi::GPIO->clear_pin_edge_detect( $_[0]->pinid );
}

sub _do_get_edge_detect {
    # clear edge detection status
    HiPi::GPIO->get_pin_edge_detect( $_[0]->pinid );
}

sub _do_setpud {
    my($self, $pudval) = @_;
    my $pudchars = 'error';
    
    if ( $pudval == RPI_PUD_OFF ) {
        $pudchars = 'pn';
    } elsif ($pudval == RPI_PUD_UP ) {
        $pudchars = 'pu';
    } elsif ($pudval == RPI_PUD_DOWN ) {
        $pudchars = 'pd';
    } else {
        croak(qq(Incorrect PUD setting $pudval));
    }
    
    HiPi::GPIO::xs_gpio_set_pud($self->pinid, $pudval);
}


sub _do_activelow {
    my($self, $newval) = @_;
    
    warn q(HiPi::GPIO::Pin does not support active_low);
    return undef;
}

sub DESTROY {
    my $self = shift;
    $self->interrupt( RPI_INT_NONE ) if $self->_needs_interrupt_cleanup;
}

1;
