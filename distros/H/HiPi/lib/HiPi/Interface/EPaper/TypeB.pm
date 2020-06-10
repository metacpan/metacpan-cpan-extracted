#########################################################################################
# Package        HiPi::Interface::EPaper::TypeB
# Description  : Control Monochrome Epaper Displays
# Copyright    : Copyright (c) 2018 Mark Dootson
# License      : This is free software; you can redistribute it and/or modify it under
#                the same terms as the Perl 5 programming language system itself.
#########################################################################################

package HiPi::Interface::EPaper::TypeB;

#########################################################################################
use strict;
use warnings;
use parent qw( HiPi::Interface::EPaper );
use HiPi qw( :rpi :spi :epaper );
use Carp;

__PACKAGE__->create_accessors( qw(
    power_setting_bytes
    booster_soft_start_bytes
    panel_setting_bytes
    vcom_and_data_byte
    pll_control_bytes
    tcon_resolution_bytes
    vcm_dc_setting_bytes
    vcom_and_data_shutdown
) );

our $VERSION ='0.81';

use constant {
    PANEL_SETTING                              => 0x00,
    POWER_SETTING                              => 0x01,
    POWER_OFF                                  => 0x02,
    POWER_OFF_SEQUENCE_SETTING                 => 0x03,
    POWER_ON                                   => 0x04,
    POWER_ON_MEASURE                           => 0x05,
    BOOSTER_SOFT_START                         => 0x06,
    DEEP_SLEEP                                 => 0x07,
    DATA_START_TRANSMISSION_1                  => 0x10,
    DATA_STOP                                  => 0x11,
    DISPLAY_REFRESH                            => 0x12,
    DATA_START_TRANSMISSION_2                  => 0x13,
    PLL_CONTROL                                => 0x30,
    TEMPERATURE_SENSOR_COMMAND                 => 0x40,
    TEMPERATURE_SENSOR_CALIBRATION             => 0x41,
    TEMPERATURE_SENSOR_WRITE                   => 0x42,
    TEMPERATURE_SENSOR_READ                    => 0x43,
    VCOM_AND_DATA_INTERVAL_SETTING             => 0x50,
    LOW_POWER_DETECTION                        => 0x51,
    TCON_SETTING                               => 0x60,
    TCON_RESOLUTION                            => 0x61,
    SOURCE_AND_GATE_START_SETTING              => 0x62,
    GET_STATUS                                 => 0x71,
    AUTO_MEASURE_VCOM                          => 0x80,
    VCOM_VALUE                                 => 0x81,
    VCM_DC_SETTING_REGISTER                    => 0x82,
    PROGRAM_MODE                               => 0xA0,
    ACTIVE_PROGRAM                             => 0xA1,
    READ_OTP_DATA                              => 0xA2,
    
    HIPI_BORDER_DDXCDI_MASK  => 0x3F,
    HIPI_BORDER_BLACK        => 0x00,
    HIPI_BORDER_WHITE        => 0x40,
    HIPI_BORDER_COLOUR       => 0x80,
    HIPI_BORDER_FLOAT        => 0xC0,
    
};

sub _create {
    my( $class, %params ) = @_;
    
    # Default pins for WaveShare 'HAT' modules
    # reset_pin    => RPI_PIN_11, #  17 
    # dc_pin       => RPI_PIN_22, #  25
    # busy_pin     => RPI_PIN_18, #  24
    
    $params{reset_pin} //= RPI_PIN_11;
    $params{dc_pin}    //= RPI_PIN_22;
    $params{busy_pin}  //= RPI_PIN_18;
    
    my $self = $class->SUPER::_create( %params );
    return $self;
}

sub set_lut_bw {
    my $self = shift;
    my $lut_commands = {
        lut_vcom0 => 0x20,
        lut_w     => 0x21,
        lut_b     => 0x22,
        lut_g1    => 0x23,
        lut_g2    => 0x24,
    };
    
    for my $lut( qw( lut_vcom0 lut_w lut_b lut_g1 lut_g2 ) ) {
        $self->_send_command_if_data( $lut_commands->{$lut}, $self->$lut );
    }
    
    return;
}

sub set_lut_colour {
    my $self = shift;
    my $lut_commands = {
        lut_vcom1 => 0x25,
        lut_red0  => 0x26,
        lut_red1  => 0x27,
    };
    
    for my $lut( qw( lut_vcom1 lut_red0 lut_red1 ) ) {
        $self->_send_command_if_data( $lut_commands->{$lut}, $self->$lut );
    }
    
    return;
}

sub display_sleep {
    my $self = shift;
    return if $self->_in_deep_sleep();
    $self->wait_for_idle();
    $self->send_command(VCOM_AND_DATA_INTERVAL_SETTING, $self->vcom_and_data_shutdown);
    $self->send_command(VCM_DC_SETTING_REGISTER, 0x00);          # to solve Vcom drop
    $self->send_command(POWER_SETTING, 0x02, 0x00, 0x00, 0x00);  # power setting - gate switch to external
    $self->wait_for_idle();
    $self->send_command(POWER_OFF);
    $self->_in_deep_sleep(1);
    return;
}

sub display_wake {
    my $self = shift;
    $self->display_reset;
    return;
}

sub display_reset {
    my $self = shift;
    
    $self->reset();
    $self->_in_deep_sleep(0);
    
    $self->_send_command_if_data( POWER_SETTING, $self->power_setting_bytes );
    $self->_send_command_if_data( BOOSTER_SOFT_START, $self->booster_soft_start_bytes );
    $self->send_command(POWER_ON);

    $self->wait_for_idle();
    
    $self->_send_command_if_data( PANEL_SETTING, $self->panel_setting_bytes );
    $self->send_command( VCOM_AND_DATA_INTERVAL_SETTING, $self->get_vcom_and_data );
    $self->_send_command_if_data( PLL_CONTROL, $self->pll_control_bytes );
    $self->_send_command_if_data( TCON_RESOLUTION, $self->tcon_resolution_bytes );
    $self->_send_command_if_data( VCM_DC_SETTING_REGISTER, $self->vcm_dc_setting_bytes ); 
    
    $self->set_lut_bw;
    $self->set_lut_colour;
    
    $self->wait_for_idle();
    
    return;
}

sub display_update {
    my $self = shift;
    
    $self->wait_for_idle();
    
    # Frame 1
    if( $self->frame_1_type != EPD_FRAME_TYPE_UNUSED ) {
        if( $self->frame_1_bpp == EPD_FRAME_BPP_2 ) {
            $self->_do_update_2_bpp( DATA_START_TRANSMISSION_1, $self->context->buffers->[0], $self->context->buffer_bytes );
        } elsif( $self->frame_1_bpp == EPD_FRAME_BPP_1 ) {
            $self->_do_update_1_bpp( DATA_START_TRANSMISSION_1, $self->context->buffers->[0], $self->context->buffer_bytes );
        }
    }
    
    # Frame 2
    if( $self->frame_2_type != EPD_FRAME_TYPE_UNUSED ) {
        if( $self->frame_2_bpp == EPD_FRAME_BPP_2 ) {
        $self->_do_update_2_bpp( DATA_START_TRANSMISSION_2, $self->context->buffers->[1], $self->context->buffer_bytes );
        } elsif( $self->frame_2_bpp == EPD_FRAME_BPP_1 ) {
            $self->_do_update_1_bpp( DATA_START_TRANSMISSION_2, $self->context->buffers->[1], $self->context->buffer_bytes );
        }
    }
    
    $self->send_command(DISPLAY_REFRESH);
    $self->wait_for_idle();
    return;
}

sub _do_update_2_bpp {
    my($self, $transmission, $buffer, $bufferbytes) = @_;
    $self->send_command( $transmission );
    $self->delay(2);
    my $chunksize = $self->spi_chunksize;
    my @bytes = ();
    
    for (my $i = 0; $i < $bufferbytes; $i++) {
        my $temp = 0x00;
        for (my $bit = 0; $bit < 4; $bit++) {
            if (($buffer->[$i] & (0x80 >> $bit)) != 0) {
                $temp |= 0xC0 >> ($bit * 2);
            }
        }
        
        push @bytes, $temp;
        if( @bytes == $chunksize) {
            $self->send_data(@bytes);
            @bytes = ();
        }
                
        $temp = 0x00;
        for (my $bit = 4; $bit < 8; $bit++) {
            if (($buffer->[$i] & (0x80 >> $bit)) != 0) {
                $temp |= 0xC0 >> (($bit - 4) * 2);
            }
        }
        
        push @bytes, $temp;
        if( @bytes == $chunksize) {
            $self->send_data(@bytes);
            @bytes = ();
        }
    }
    
    $self->send_data( @bytes ) if @bytes;
    
    $self->delay(2);
    return;
}

sub _do_update_1_bpp {
    my($self, $transmission, $buffer, $bufferbytes) = @_;
    $self->send_command( $transmission );
    $self->delay(2);

    my $chunksize = $self->spi_chunksize;
    my $byteloops = int($bufferbytes / $chunksize);
    my $lastbytes = $bufferbytes % $chunksize;
    my $index;
    
    for ($index = 0; $index < $byteloops; $index++) {
        my $start = $index * $chunksize;
        my $end = $start + $chunksize - 1;
        $self->send_data( @$buffer[$start..$end] );
    }
    if( $lastbytes ) {
        my $start = $index * $chunksize;
        my $end = $start + $lastbytes - 1;
        $self->send_data( @$buffer[$start..$end] );
    }
    $self->delay(2);
    return;
}

sub get_vcom_and_data {
    my($self) = @_;

    my $vcom = $self->vcom_and_data_byte & HIPI_BORDER_DDXCDI_MASK;
    my $control = $self->border_control;
    my $border = HIPI_BORDER_FLOAT;
    
    if( $control == EPD_BORDER_BLACK ) {
        $border = HIPI_BORDER_BLACK;
    } elsif( $control == EPD_BORDER_COLOUR ) {
        if( $self->is_tri_colour ) {
            $border = HIPI_BORDER_COLOUR;
        } else {
            $border = HIPI_BORDER_BLACK;
        }
    } elsif( $control == EPD_BORDER_WHITE ) {
        $border = HIPI_BORDER_WHITE;
    }
    
    my $vcdata = $border | $vcom;
    # warn sprintf('RETURNING VCOM DATA 0x%X', $vcdata);
    return $vcdata;
}

1;

__END__
