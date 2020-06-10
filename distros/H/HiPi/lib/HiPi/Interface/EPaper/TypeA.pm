#########################################################################################
# Package        HiPi::Interface::EPaper::TypeA
# Description  : Control Monochrome Epaper Displays
# Copyright    : Copyright (c) 2018 Mark Dootson
# License      : This is free software; you can redistribute it and/or modify it under
#                the same terms as the Perl 5 programming language system itself.
#########################################################################################

package HiPi::Interface::EPaper::TypeA;

#########################################################################################
use strict;
use warnings;
use parent qw( HiPi::Interface::EPaper );
use HiPi qw( :rpi :spi :epaper );
use Carp;

__PACKAGE__->create_ro_accessors( qw(
    driver_ouput_control_bytes
    booster_soft_start_control_bytes
    vcom_register_bytes
    dummy_line_period_bytes
    gate_time_bytes
    border_control_bytes
    data_entry_mode_bytes
    analog_control_bytes
    inky_magic_bytes
    source_driving_bytes
    
    display_update_setting
) );

our $VERSION ='0.81';

use constant {
    DRIVER_OUTPUT_CONTROL                       => 0x01,
    SOURCE_DRIVING_CONTROL                      => 0x04,
    BOOSTER_SOFT_START_CONTROL                  => 0x0C,
    GATE_SCAN_START_POSITION                    => 0x0F,
    DEEP_SLEEP_MODE                             => 0x10,
    DATA_ENTRY_MODE_SETTING                     => 0x11,
    SW_RESET                                    => 0x12,
    TEMPERATURE_SENSOR_CONTROL                  => 0x1A,
    MASTER_ACTIVATION                           => 0x20,
    DISPLAY_UPDATE_CONTROL_1                    => 0x21,
    DISPLAY_UPDATE_CONTROL_2                    => 0x22,
    WRITE_RAM                                   => 0x24,
    WRITE_RAM_2                                 => 0x26,
    WRITE_VCOM_REGISTER                         => 0x2C,
    WRITE_LUT_REGISTER                          => 0x32,
    SET_DUMMY_LINE_PERIOD                       => 0x3A,
    SET_GATE_TIME                               => 0x3B,
    BORDER_WAVEFORM_CONTROL                     => 0x3C,
    SET_RAM_X_ADDRESS_START_END_POSITION        => 0x44,
    SET_RAM_Y_ADDRESS_START_END_POSITION        => 0x45,
    SET_RAM_X_ADDRESS_COUNTER                   => 0x4E,
    SET_RAM_Y_ADDRESS_COUNTER                   => 0x4F,
    
    ANALOG_CONTROL_BLOCK                        => 0x74,
    INKY_MAGIC_MAGIC_COMMAND                    => 0x75,
    
    TERMINATE_FRAME_READ_WRITE                  => 0xFF,
    
    HIPI_BORDER_POR    => 0b011100010,
    HIPI_BORDER_BLACK  => 0b010100010,
    HIPI_BORDER_COLOUR => 0b010100001,
    HIPI_BORDER_WHITE  => 0b011100010,
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
    
    $params{display_update_setting} //= 0xC4;
    
    my $self = $class->SUPER::_create( %params );
    return $self;
}

sub set_update_mode {
    my($self, $newmode) = @_;
    my $current = $self->lut_state;
    if( $newmode ) {
        if( ( $newmode == EPD_UPD_MODE_FULL && $current != EPD_UPD_MODE_FULL ) ) {
            $self->lut_state( $newmode );
            $self->display_reset;
        } elsif( $self->can_partial && $newmode == EPD_UPD_MODE_PARTIAL && $current != EPD_UPD_MODE_PARTIAL) {
            $self->lut_state( $newmode );
            $self->display_reset;
        }
    }
    return $self->lut_state;
}

sub set_lut_full {
    my $self = shift;
    my $buffer = $self->lut_full;
    next unless ($buffer && ref($buffer) eq 'ARRAY' && @$buffer );
    $self->send_command(WRITE_LUT_REGISTER);
    $self->send_data( @$buffer );
    $self->lut_state( EPD_UPD_MODE_FULL );
}

sub set_lut_partial {
    my $self = shift;
    return unless $self->can_partial;
    my $buffer = $self->lut_partial;
    next unless ($buffer && ref($buffer) eq 'ARRAY' && @$buffer );
    $self->send_command(WRITE_LUT_REGISTER);
    $self->send_data( @$buffer );
    $self->lut_state( EPD_UPD_MODE_PARTIAL );
}

sub display_update {
    my $self = shift;
    $self->set_frame_memory( 0, 0, $self->context );
    $self->display_frame();
}

sub display_partial_update {
    my($self, $x, $y, $context ) = @_;
    return unless $self->can_partial;
    return unless $context->isa('HiPi::Interface::EPaper::PartialContext');
    ($x, $y) = $self->get_partial_coordinates( $x, $y, $context->logical_width, $context->logical_height );
    $self->set_frame_memory($x, $y, $context );
    $self->display_frame();
    return;
}

sub get_partial_coordinates {
    my($self, $x, $y, $w, $h) = @_;
    
    if ($self->rotation == EPD_ROTATION_0 ) {
        return( $x, $y);
    }
    
    # These odd rotations are for the start
    # of partial memory block where the x
    # is always in the top left of the
    # memory block - not the rotated
    # top left of the logical coordinate.
        
    my $adjH = $self->device_height -1;
    my $adjW = $self->device_width;
    
    if ($self->rotation == EPD_ROTATION_90) {
        $y = $y + $h;
        my $swap = $x;
        $x = ( $adjW - $y );
        $y = $swap;
    } elsif ($self->rotation == EPD_ROTATION_180) {
        $x = $x + $w;
        $y = $y + $h;
        $x = ($adjW - $x );
        $y = $adjH - $y;
    } elsif ($self->rotation == EPD_ROTATION_270) {
        $x = $x + $w;
        my $swap = $x;
        $x = $y;
        $y = $adjH - $swap;
    }
    
    return ( $x , $y );
}

sub create_partial_context {
    my( $self, $w, $h ) = @_;
    $w = 0 if $w < 0;
    $w = $self->logical_width if $w > $self->logical_width;
    $h = 0 if $h < 0;
    $h = $self->logical_height if $h > $self->logical_height;
    
    if( $self->rotation == EPD_ROTATION_90 || $self->rotation == EPD_ROTATION_270 ) {
        my $swap = $w;
        $w = $h;
        $h = $swap;
    }
    
    if(my $xtra = $w % 8 ) {
        $w += ( 8 - $xtra );
    }
        
    if(my $xtra = $h % 8 ) {
        $h += ( 8 - $xtra );
    }
    
    my $context = HiPi::Interface::EPaper::PartialContext->new(
            device_width    => $w,
            device_height   => $h,
            rotation        => $self->rotation,
            frame_1_bpp     => $self->frame_1_bpp,
            frame_2_bpp     => $self->frame_2_bpp,
            frame_1_type    => $self->frame_1_type,
            frame_2_type    => $self->frame_2_type,
            frame_1_invert  => $self->frame_1_invert,
            frame_2_invert  => $self->frame_2_invert,
            offsetx         => 0,
        );
    
    return $context;
}

sub display_frame {
    my $self = shift;
    $self->send_command(DISPLAY_UPDATE_CONTROL_2, $self->display_update_setting );
    $self->send_command(MASTER_ACTIVATION);
    $self->send_command(TERMINATE_FRAME_READ_WRITE);
    $self->wait_for_idle();
    return;
}

sub set_frame_memory {
    my( $self, $x, $y, $context ) = @_;
    
    return unless $context->isa('HiPi::Interface::EPaper::DisplayBuffer');
    
    my $w = $context->device_width + $context->offsetx;
    my $h = $context->device_height;
    
    my($x_end, $y_end);
        
    if ( $x < 0 || $w < 0 || $y < 0 || $h < 0 ) {
        return;
    }
    
    my $maxX = $self->device_width + $self->offsetx;
    
    # x points must be the multiple of 8 or the last 3 bits will be ignored */
    $x &= 0xF8;
    
    if(my $xtra = $w % 8 ) {
        $w += (8 - $xtra);
    }
        
    if ($x + $w >= $maxX) {
        $x_end = $maxX - 1;
    } else {
        $x_end = $x + $w - 1;
    }
    if ($y + $h >= $self->device_height) {
        $y_end = $self->device_height - 1;
    } else {
        $y_end = $y + $h - 1;
    }
    
    $self->write_memory_area($x, $x_end, $w, $y, $y_end, $h, $context->buffers->[0] );
    
    return;
}

sub set_memory_area {
    my ($self, $x_start, $y_start, $x_end, $y_end)  = @_;
    return unless $self->can_partial;
    $self->send_command(SET_RAM_X_ADDRESS_START_END_POSITION);
    # /* x point must be the multiple of 8 or the last 3 bits will be ignored */
    $self->send_data(
        ($x_start >> 3) & 0xFF,
        ($x_end >> 3) & 0xFF,
    );

    $self->send_command(SET_RAM_Y_ADDRESS_START_END_POSITION);
    $self->send_data(
        $y_start & 0xFF,
        ($y_start >> 8) & 0xFF,
        $y_end & 0xFF,
        ($y_end >> 8) & 0xFF,
    );
    return;
}

sub set_memory_pointer {
    my ($self, $x, $y) = @_;
    # x point must be the multiple of 8
    $self->send_command(SET_RAM_X_ADDRESS_COUNTER, ($x >> 3) & 0xFF );
    $self->send_command(SET_RAM_Y_ADDRESS_COUNTER, $y & 0xFF, ($y >> 8) & 0xFF );
    $self->wait_for_idle();
    return;
}

sub display_sleep {
    my $self = shift;
    return if $self->_in_deep_sleep();
    $self->wait_for_idle;
    $self->send_command(DEEP_SLEEP_MODE, 0x01);
    $self->_in_deep_sleep(1);
    return;
}

sub display_wake {
    my $self = shift;
    $self->display_reset;
}

sub write_memory_area {
    my($self, $x, $x_end, $w, $y, $y_end, $h, $buffer) = @_;
    $self->set_memory_area($x, $y, $x_end, $y_end);
    for (my $j = $y; $j <= $y_end; $j++) {
        $self->set_memory_pointer($x, $j);
        my @bytes;
        for (my $i = $x / 8; $i < $x_end / 8; $i++) {
            push @bytes, $buffer->[($i - $x / 8) + ($j - $y) * ($w / 8)];
        }
        $self->send_command(WRITE_RAM, @bytes) if @bytes;
    }
    return;
}

sub display_reset {
    my $self = shift;
    
    $self->reset();
    
    $self->_in_deep_sleep(0);
    
    $self->_send_command_if_data( ANALOG_CONTROL_BLOCK, $self->analog_control_bytes );
    $self->_send_command_if_data( INKY_MAGIC_MAGIC_COMMAND, $self->inky_magic_bytes ); 
    $self->_send_command_if_data( DRIVER_OUTPUT_CONTROL, $self->driver_ouput_control_bytes );
    $self->_send_command_if_data( SOURCE_DRIVING_CONTROL, $self->source_driving_bytes ); 
    $self->_send_command_if_data( BOOSTER_SOFT_START_CONTROL, $self->booster_soft_start_control_bytes );
    $self->_send_command_if_data( WRITE_VCOM_REGISTER, $self->vcom_register_bytes );
    $self->_send_command_if_data( SET_DUMMY_LINE_PERIOD, $self->dummy_line_period_bytes );
    $self->_send_command_if_data( SET_GATE_TIME, $self->gate_time_bytes );
    
    $self->send_command(BORDER_WAVEFORM_CONTROL, $self->get_border_waveform );
    
    $self->_send_command_if_data( DATA_ENTRY_MODE_SETTING, $self->data_entry_mode_bytes );
    
    if( $self->lut_state == EPD_UPD_MODE_PARTIAL ) {
        $self->set_lut_partial();
    } else {
        $self->set_lut_full();
        $self->lut_state( EPD_UPD_MODE_FULL );
    }
    
    $self->wait_for_idle;
    
    return;
}

sub get_border_waveform {
    my($self) = @_;
    
    my $control = $self->border_control;
    my $data = HIPI_BORDER_POR;
    if( $control == EPD_BORDER_BLACK ) {
        $data = HIPI_BORDER_BLACK;
    } elsif( $control == EPD_BORDER_COLOUR ) {
        if( $self->is_tri_colour ) {
            $data = HIPI_BORDER_COLOUR;
        } else {
            $data = HIPI_BORDER_BLACK;
        }
    } elsif( $control == EPD_BORDER_WHITE ) {
        $data =  HIPI_BORDER_POR;
    }
    
    return $data;
}


1;

__END__
