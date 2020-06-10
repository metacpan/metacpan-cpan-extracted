#########################################################################################
# Package        HiPi::Interface::EPaper::Waveshare::EPD296X128B
# Description  : Control Monochrome Epaper Displays
# Copyright    : Copyright (c) 2018 Mark Dootson
# License      : This is free software; you can redistribute it and/or modify it under
#                the same terms as the Perl 5 programming language system itself.
#########################################################################################

package HiPi::Interface::EPaper::Waveshare::EPD296X128B;

#########################################################################################
use strict;
use warnings;
use parent qw( HiPi::Interface::EPaper::TypeB);
use HiPi qw( :rpi :spi :epaper );
use Carp;

__PACKAGE__->create_accessors( qw( ) );

our $VERSION ='0.81';

sub _create {
    my( $class, %params ) = @_;
    
    $params{device_width}  = 128;
    $params{device_height} = 296;
    $params{offsetx} = 0;
    
    $params{is_tri_colour} = 1;
    
    $params{frame_1_bpp}  = EPD_FRAME_BPP_1;
    $params{frame_2_bpp}  = EPD_FRAME_BPP_1;
    $params{frame_1_type} = EPD_FRAME_TYPE_BLACK;
    $params{frame_2_type} = EPD_FRAME_TYPE_COLOUR;
    $params{frame_1_invert} = 0;
    $params{frame_2_invert} = 0;
    
    $params{rotation} //= 90;
    
    $params{can_partial} = 0;
    $params{busy_state} = RPI_LOW;
    
    $params{power_setting_bytes}      = [];
    $params{booster_soft_start_bytes} = [ 0x17, 0x17, 0x17 ];
    $params{panel_setting_bytes}      = [ 0x8F ];
    $params{vcom_and_data_byte}       = 0x77;
    $params{border_control}           = EPD_BORDER_WHITE;
    
    $params{pll_control_bytes}        = [];
    $params{tcon_resolution_bytes}    = [ 0x80, 0x01, 0x28 ];
    $params{vcm_dc_setting_bytes}     = [ 0x0A ];
    
    $params{vcom_and_data_shutdown}   = 0x17;
    
    $params{lut_vcom0} = [];
    
    $params{lut_w} = [];
    
    $params{lut_b} = [];
    
    $params{lut_g1} = [];
    
    $params{lut_g2} = [];
    
    $params{lut_vcom1} = [];
    
    $params{lut_red0} = [];
    
    $params{lut_red1} = [];
    
    my $self = $class->SUPER::_create( %params );
    
    return $self;
}

1;

__END__
