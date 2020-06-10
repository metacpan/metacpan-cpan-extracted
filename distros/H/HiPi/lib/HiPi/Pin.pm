#########################################################################################
# Package        HiPi::Pin
# Description:   GPIO / Extender Pin
# Copyright    : Copyright (c) 2013-2017 Mark Dootson
# License      : This is free software; you can redistribute it and/or modify it under
#                the same terms as the Perl 5 programming language system itself.
#########################################################################################

package HiPi::Pin;

#########################################################################################

use strict;
use warnings;
use parent qw( HiPi::Class );
use HiPi qw( :rpi );

our $VERSION ='0.81';

__PACKAGE__->create_ro_accessors( qw( pinid ) );

sub _open {
    my $class = shift;
    my $self = $class->SUPER::new(@_);
    return $self;
}


sub value {
    my($self, $newval) = @_;
    if(defined($newval)) {
        return $self->_do_setvalue($newval);
    } else {
        return $self->_do_getvalue();
    }
}

sub mode {
    my($self, $newval) = @_;
    if(defined($newval)) {
        return $self->_do_setmode($newval);
    } else {
        return $self->_do_getmode();
    }
}

sub set_pud {
    my($self, $newval) = @_;
    $newval //= RPI_PUD_OFF;
    my $rval;
    if( $newval == RPI_PUD_OFF || $newval == RPI_PUD_DOWN || $newval == RPI_PUD_UP )  {
        $rval = $self->_do_setpud( $newval );
    } else {
        croak(qq(Invalid PUD setting $newval));
    }
    return $rval;
}

sub get_pud {
    my( $self ) = @_;
    my $rval = $self->_do_getpud();
    return $rval;
}

sub get_function {
    my( $self ) = @_;
    return $self->_do_get_function_name();
}

sub active_low {
    my($self, $newval) = @_;
    if(defined($newval)) {
        return $self->_do_activelow($newval);
    } else {
        return $self->_do_activelow();
    } 
}

sub interrupt {
    my($self, $newedge) = @_;
    if(defined($newedge)) {
        $newedge ||= RPI_INT_NONE;
        $newedge = RPI_INT_FALL if $newedge eq 'falling';
        $newedge = RPI_INT_RISE if $newedge eq 'rising';
        $newedge = RPI_INT_BOTH if $newedge eq 'both';
        $newedge = RPI_INT_NONE if $newedge eq 'none';
        return $self->_do_setinterrupt($newedge);
    } else {
        return $self->_do_getinterrupt();
    }
}

sub get_interrupt_filepath {
    my( $self ) = @_;
    return $self->_do_get_interrupt_filepath();
}

1;

__END__
