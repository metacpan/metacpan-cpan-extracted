#########################################################################################
# Package        HiPi::Interface::EPaper::Waveshare::EPD152X152
# Description  : Control Monochrome Epaper Displays
# Copyright    : Copyright (c) 2018 Mark Dootson
# License      : This is free software; you can redistribute it and/or modify it under
#                the same terms as the Perl 5 programming language system itself.
#########################################################################################

package HiPi::Interface::EPaper::Waveshare::EPD152X152;

#########################################################################################
use strict;
use warnings;
use parent qw( HiPi::Interface::EPaper::TypeB );
use HiPi qw( :rpi :spi :epaper );
use Carp;

__PACKAGE__->create_accessors( qw( ) );

our $VERSION ='0.81';


sub _create {
    my( $class, %params ) = @_;
    
    $params{device_width}  = 152;
    $params{device_height} = 152;
    $params{offsetx} = 0;
    
    $params{is_tri_colour} = 1;
    
    $params{frame_1_bpp}   = EPD_FRAME_BPP_1;
    $params{frame_2_bpp}   = EPD_FRAME_BPP_1;
    $params{frame_1_type}  = EPD_FRAME_TYPE_BLACK;
    $params{frame_2_type}  = EPD_FRAME_TYPE_COLOUR;
    $params{frame_1_invert} = 0;
    $params{frame_2_invert} = 0;
    
    $params{rotation} //= 0;
    
    $params{can_partial} = 0;
    $params{busy_state}  = RPI_LOW;
    
    $params{power_setting_bytes}      = [ 0x07, 0x00, 0x08, 0x00 ];
    $params{booster_soft_start_bytes} = [ 0x07, 0x07, 0x07 ];
    $params{panel_setting_bytes}      = [ 0x0f, 0x0d ];
    $params{vcom_and_data_byte}       = 0xF7;
    $params{border_control}           = EPD_BORDER_FLOAT;
    $params{pll_control_bytes}        = [ 0x39 ];
    $params{tcon_resolution_bytes}    = [ 0x98, 0x00, 0x98 ];
    $params{vcm_dc_setting_bytes}     = [ 0x0E ];
    
    $params{vcom_and_data_shutdown}   = 0x17;
    
    $params{lut_vcom0} = [
        0x0E, 0x14, 0x01, 0x0A, 0x06, 0x04, 0x0A, 0x0A,
        0x0F, 0x03, 0x03, 0x0C, 0x06, 0x0A, 0x00 ];
    
    $params{lut_w} = [
        0x0E, 0x14, 0x01, 0x0A, 0x46, 0x04, 0x8A, 0x4A,
        0x0F, 0x83, 0x43, 0x0C, 0x86, 0x0A, 0x04 ];
    
    $params{lut_b} = [
        0x0E, 0x14, 0x01, 0x8A, 0x06, 0x04, 0x8A, 0x4A,
        0x0F, 0x83, 0x43, 0x0C, 0x06, 0x4A, 0x04 ];
    
    $params{lut_g1} = [
        0x8E, 0x94, 0x01, 0x8A, 0x06, 0x04, 0x8A, 0x4A,
        0x0F, 0x83, 0x43, 0x0C, 0x06, 0x0A, 0x04 ];
    
    $params{lut_g2} = [
        0x8E, 0x94, 0x01, 0x8A, 0x06, 0x04, 0x8A, 0x4A,
        0x0F, 0x83, 0x43, 0x0C, 0x06, 0x0A, 0x04 ];
    
    $params{lut_vcom1} = [
        0x03, 0x1D, 0x01, 0x01, 0x08, 0x23, 0x37, 0x37,
        0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 ];
    
    $params{lut_red0} = [
        0x83, 0x5D, 0x01, 0x81, 0x48, 0x23, 0x77, 0x77,
        0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 ];
    
    $params{lut_red1} = [
        0x03, 0x1D, 0x01, 0x01, 0x08, 0x23, 0x37, 0x37,
        0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 ];
    
    my $self = $class->SUPER::_create( %params );
    
    return $self;
}

1;

__END__
