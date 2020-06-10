#########################################################################################
# Package        HiPi::Device::GPIO::Pin
# Description:   Pin
# Created        Wed Feb 20 04:37:38 2013
# Copyright    : Copyright (c) 2013-2017 Mark Dootson
# License      : This is free software; you can redistribute it and/or modify it under
#                the same terms as the Perl 5 programming language system itself.
#########################################################################################

package HiPi::Device::GPIO::Pin;

#########################################################################################
use strict;
use warnings;
use parent qw( HiPi::Pin );
use Carp;
use Fcntl;
use HiPi qw( :rpi );

our $VERSION ='0.81';

__PACKAGE__->create_accessors();

sub _open {
    my ($class, %params) = @_;
    defined($params{pinid}) or croak q(pinid not defined in parameters);
    
    my $pinroot = qq(/sys/class/gpio/gpio$params{pinid});
    croak qq(pin $params{pinid} is not exported) if !-d $pinroot;
        
    my $self = $class->SUPER::_open(%params);
    return $self;
}

sub _do_getvalue {
    my $self = shift;
    return HiPi::Device::GPIO->pin_read( $self->pinid );
}

sub _do_setvalue {
    my( $self, $newval) = @_;
    return HiPi::Device::GPIO->pin_write($self->pinid, $newval );
}

sub _do_getmode {
    my $self = shift;
    return HiPi::Device::GPIO->get_pin_mode($self->pinid );
}

sub _do_setmode {
    my ($self, $newmode) = @_;
    return HiPi::Device::GPIO->set_pin_mode($self->pinid, $newmode );
}

sub _do_getinterrupt {
    my $self = shift;
    return HiPi::Device::GPIO->get_pin_interrupt( $self->pinid );
}

sub _do_setinterrupt {
    my ($self, $newedge) = @_;
    return HiPi::Device::GPIO->set_pin_interrupt( $self->pinid, $newedge );
}

sub _do_get_interrupt_filepath {
    my($self) = @_;
    return HiPi::Device::GPIO->get_pin_interrupt_filepath( $self->pinid );
}

sub _do_get_function_name {
    my($self) = @_;
    return HiPi::Device::GPIO->get_pin_function( $self->pinid );
}

sub _do_setpud {
    my($self, $pudval) = @_;
    return HiPi::Device::GPIO->set_pin_pud($self->pinid, $pudval);
}

sub _do_getpud {
    my($self) = @_;
    return HiPi::Device::GPIO->get_pin_pud($self->pinid);
}

sub _do_activelow {
    my($self, $newval) = @_;
    
    my $result = undef;
    
    if( defined( $newval ) ) {
        $result = HiPi::Device::GPIO->set_pin_activelow($self->pinid, $newval);
    } else {
        $result = HiPi::Device::GPIO->get_pin_activelow($self->pinid);
    }
    
    return $result;
} 

1;
