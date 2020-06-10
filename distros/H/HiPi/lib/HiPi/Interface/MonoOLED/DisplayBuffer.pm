#########################################################################################
# Package        HiPi::Interface::MonoOLED::DisplayBuffer
# Description  : Control Monochrome OLEDs
# Copyright    : Copyright (c) 2018 Mark Dootson
# License      : This is free software; you can redistribute it and/or modify it under
#                the same terms as the Perl 5 programming language system itself.
#########################################################################################

package HiPi::Interface::MonoOLED::DisplayBuffer;

#########################################################################################

use strict;
use warnings;
use parent qw( HiPi::Graphics::DrawingContext );
use Carp;

__PACKAGE__->create_ro_accessors( qw( rows cols bytes_per_col buffer ) );

our $VERSION ='0.81';

sub new {
    my( $class, %params) = @_;
    $params{bytes_per_col} = $params{rows} >> 3;
    my @data = ( 0 ) x ( $params{cols} * $params{bytes_per_col} );    
    $params{buffer} = \@data;
    my $self = $class->SUPER::new( %params );
    return $self;
}

sub clear_buffer {
    my ($self, $on) = @_;
    for (my $i = 0; $i < @{ $self->buffer }; $i ++) {
        $self->buffer->[$i] = $on;
    }
    return;
}

sub draw_pixel {
    my($self, $x, $y, $on) = @_;
    
    return if( $x < 0 || $x >= $self->cols || $y < 0 || $y >= $self->rows );
    
    $on //= 1;
    
    if($self->pen_inverted) {
        $on = ( $on ) ? 0 : 1;
    }
    
    my $mem_col = $x;
    my $mem_row = $y >> 3; 
    my $bit_mask = 1 << ($y % 8);
    my $offset = $mem_row * $self->cols + $mem_col;
    
    if($on) {
        $self->buffer->[$offset] |= $bit_mask;
    } else {
        $self->buffer->[$offset] &= ( 0xFF - $bit_mask );
    }
}

# noops for buffer context

sub rotate { carp q(you cannot call 'rotate' on the main display); }

sub rotated_text { carp q(you cannot call 'rotate_text' on the main display); }

sub clear_context { carp q(you cannot call 'clear_context' on the main display); }

1;

__END__