#########################################################################################
# Package        HiPi::Interface::EPaper::Waveshare::EPD200X200
# Description  : Control Monochrome Epaper Displays
# Copyright    : Copyright (c) 2018 Mark Dootson
# License      : This is free software; you can redistribute it and/or modify it under
#                the same terms as the Perl 5 programming language system itself.
#########################################################################################

package HiPi::Interface::EPaper::Waveshare::EPD200X200;

#########################################################################################
use strict;
use warnings;
use parent qw( HiPi::Interface::EPaper::TypeA );
use HiPi qw( :rpi :spi :epaper );
use Carp;

__PACKAGE__->create_accessors( qw( ) );

our $VERSION ='0.81';

sub _create {
    my( $class, %params ) = @_;
    
    $params{device_width}  = 200;
    $params{device_height} = 200;
    $params{offsetx} = 0;
    
    $params{is_tri_colour} = 0;
    
    $params{frame_1_bpp}  = EPD_FRAME_BPP_1;
    $params{frame_2_bpp}  = EPD_FRAME_BPP_1;
    $params{frame_1_type} = EPD_FRAME_TYPE_BLACK;
    $params{frame_2_type} = EPD_FRAME_TYPE_UNUSED;
    $params{frame_1_invert} = 0;
    $params{frame_2_invert} = 0;
    
    $params{rotation} //= 0;
    
    $params{border_control} = EPD_BORDER_POR;
    
    $params{can_partial} = 1;
    $params{busy_state}  = RPI_HIGH;
    
    $params{driver_ouput_control_bytes} = [
        ( $params{device_height} -1 ) & 0xFF,
        (($params{device_height} -1 ) >> 8) & 0xFF,
        0x00,   # // GD = 0; SM = 0; TB = 0;
    ];
    
    $params{booster_soft_start_control_bytes} = [ 0xD7, 0xD6, 0x9D ];
    $params{vcom_register_bytes}     = [ 0xA8 ];
    $params{dummy_line_period_bytes} = [ 0x1A ];
    $params{gate_time_bytes}         = [ 0x08 ];
    $params{data_entry_mode_bytes}   = [ 0x03 ];
    
    $params{lut_full} = [
        0x02, 0x02, 0x01, 0x11, 0x12, 0x12, 0x22, 0x22, 
        0x66, 0x69, 0x69, 0x59, 0x58, 0x99, 0x99, 0x88, 
        0x00, 0x00, 0x00, 0x00, 0xF8, 0xB4, 0x13, 0x51, 
        0x35, 0x51, 0x51, 0x19, 0x01, 0x00        
    ];
    
    $params{lut_partial} = [
        0x10, 0x18, 0x18, 0x08, 0x18, 0x18, 0x08, 0x00, 
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 
        0x00, 0x00, 0x00, 0x00, 0x13, 0x14, 0x44, 0x12, 
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00        
    ];
    
    my $self = $class->SUPER::_create( %params );
    
    return $self;
}

1;

__END__
