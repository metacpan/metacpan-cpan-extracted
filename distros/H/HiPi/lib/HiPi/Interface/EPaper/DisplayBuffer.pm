#########################################################################################
# Package        HiPi::Interface::EPaper
# Description  : Control Monochrome EPaper displays
# Copyright    : Copyright (c) 2018 Mark Dootson
# License      : This is free software; you can redistribute it and/or modify it under
#                the same terms as the Perl 5 programming language system itself.
#########################################################################################

package HiPi::Interface::EPaper::DisplayBuffer;

#########################################################################################

use strict;
use warnings;
use parent qw( HiPi::Graphics::DrawingContext );
use Carp;
use HiPi qw( :epaper );
use Try::Tiny;

__PACKAGE__->create_ro_accessors( qw(
    device_height device_width buffers buffer_bytes
    frame_1_bpp  frame_2_bpp
    frame_1_type frame_2_type
    frame_invert
    invert_draw offsetx
    colour_frame black_frame
    ) );

__PACKAGE__->create_accessors( qw( pen rotation ) );

our $VERSION ='0.81';

sub new {
    my( $class, %params) = @_;
    $params{pen} //= EPD_BLACK_PEN;
    $params{rotation} //= EPD_BLACK_PEN;
    $params{frame_invert} = [ $params{frame_1_invert}, $params{frame_2_invert} ];
    my $bytecount = $params{device_height} * ( $params{device_width} + $params{offsetx} );
    $bytecount >>= 3;
   
    
    $params{buffers} = [ [], [] ];
    
    if( $params{frame_1_type} != EPD_FRAME_TYPE_UNUSED ) {
        my $mask = ( $params{frame_1_invert} ) ? 0 : 0xFF;
        my @data = ( $mask ) x $bytecount;
        $params{buffers}->[0] = \@data;
    }
    
    if( $params{frame_2_type} != EPD_FRAME_TYPE_UNUSED ) {
        my $mask = ( $params{frame_2_invert} ) ? 0 : 0xFF;
        my @data = ( $mask ) x $bytecount;
        $params{buffers}->[1] = \@data;
    }
    
    $params{buffer_bytes} = $bytecount;
    
    # colour frame & black frame
    $params{black_frame} = 0;
    $params{colour_frame} = 0;
    
    if( $params{frame_1_type} == EPD_FRAME_TYPE_COLOUR ) {
        $params{colour_frame} = 1;
    } elsif($params{frame_2_type} == EPD_FRAME_TYPE_COLOUR ) {
        $params{colour_frame} = 2;
    }
    
    if( $params{frame_1_type} == EPD_FRAME_TYPE_BLACK ) {
        $params{black_frame} = 1;
    } elsif($params{frame_2_type} == EPD_FRAME_TYPE_BLACK ) {
        $params{black_frame} = 2;
    }
    
    $params{colour_frame} ||= $params{black_frame};
    
    my $self = $class->SUPER::new( %params );
    return $self;
}

sub clear_buffer {
    my ($self, $frame) = @_;
    
    if( $frame ) {
        my $mask = ( $self->frame_invert->[$frame] ) ? 0 : 0xFF;
        for (my $i = 0; $i < @{ $self->buffers->[$frame] }; $i ++) {
            $self->buffers->[$frame]->[$i] = $mask;
        }
    } else {
        for my $frameno ( (0, 1) ) {
            my $buffer = $self->buffers->[$frameno];
            my $mask = ( $self->frame_invert->[$frameno] ) ? 0 : 0xFF;
            for (my $i = 0; $i < @$buffer; $i ++) {
                $buffer->[$i] = $mask;
            }
        }
    }
    return;
}

sub draw_pixel {
    my($self, $x, $y ) = @_;
    
    my $frametype = 0;
    if( $self->pen == EPD_COLOUR_PEN ) {
        $frametype = $self->colour_frame;
    } else {
        $frametype = $self->black_frame;
    }
    return unless $frametype;
    
    my $frame = $frametype - 1;
    
    my $inverted = $self->frame_invert->[$frame];
    
    my $maxX = $self->device_width + $self->offsetx;
    my $adjH = $self->device_height -1;
    my $adjW = $self->device_width  -1;
    
    # rotate and check for bounds
    if ($self->rotation == EPD_ROTATION_0 ) {
        if($x < 0 || $x >= $self->device_width || $y < 0 || $y >= $self->device_height) {
            return;
        }
    } elsif ($self->rotation == EPD_ROTATION_90) {
        if($x < 0 || $x >= $self->device_height || $y < 0 || $y >= $self->device_width) {
          return;
        }
        my $swap = $x;
        $x = $adjW - $y;
        $y = $swap;
    } elsif ($self->rotation == EPD_ROTATION_180) {
        if($x < 0 || $x >= $self->device_width || $y < 0 || $y >= $self->device_height) {
          return;
        }
        $x = $adjW - $x;
        $y = $adjH - $y;
    } elsif ($self->rotation == EPD_ROTATION_270) {
        if($x < 0 || $x >= $self->device_height || $y < 0 || $y >= $self->device_width) {
          return;
        }
        my $swap = $x;
        $x = $y;
        $y = $adjH - $swap;
    }
        
    my $index = ($x + $y * $maxX) >> 3;
    my $shiftbits = $x % 8;
    my $buffer = $self->buffers->[$frame];
    
    my $on = ( $self->pen ) ? 1 : 0;
    
    if($self->pen_inverted) {
        $on = ( $on ) ? 0 : 1;
    }
    
    if( $inverted ) {
        if ($on) {
            $buffer->[$index] |= 0x80 >> $shiftbits;
        } else {
            $buffer->[$index] &= ~(0x80 >> $shiftbits);
        }
    } else {
        if ($on) {
            $buffer->[$index] &= ~(0x80 >> $shiftbits);
        } else {
            $buffer->[$index] |= 0x80 >> $shiftbits;
        }
    }
    
    return;
}

sub set_pen {
    my($self, $newpen) = @_;
    my $oldpen = $self->pen;
    $self->pen( $newpen );
    return $oldpen;
}

sub logical_width {
    my $self = shift;
    if( $self->rotation == EPD_ROTATION_90 || $self->rotation == EPD_ROTATION_270 ) {
        return $self->device_height;
    } else {
        return $self->device_width;
    }
}

sub logical_height {
    my $self = shift;
    if( $self->rotation == EPD_ROTATION_90 || $self->rotation == EPD_ROTATION_270 ) {
        return $self->device_width;
    } else {
        return $self->device_height;
    }
}

# noops for buffer contexts

sub rotate { carp q(you cannot call 'rotate' on a display context); }

sub rotated_text { carp q(you cannot call 'rotate_text' on a display context); }

sub clear_context { carp q(you cannot call 'clear_context' on a display context); }


#########################################################################################

package HiPi::Interface::EPaper::PartialContext;

#########################################################################################

use base qw( HiPi::Interface::EPaper::DisplayBuffer );

sub new {
    my($class, %params) = @_;
    my $self = $class->SUPER::new( %params );
    return $self;
}

1;

__END__