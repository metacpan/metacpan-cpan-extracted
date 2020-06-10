#########################################################################################
# Package        HiPi::Interface::EPaper::Pimoroni::EPDInkyPHAT_V2
# Description  : Control Monochrome Epaper Displays
# Copyright    : Copyright (c) 2018 Mark Dootson
# License      : This is free software; you can redistribute it and/or modify it under
#                the same terms as the Perl 5 programming language system itself.
#########################################################################################

package HiPi::Interface::EPaper::Pimoroni::EPDInkyPHAT_V2;

#########################################################################################
use strict;
use warnings;
use parent qw( HiPi::Interface::EPaper::TypeA );
use HiPi qw( :rpi :spi :epaper );
use Carp;

__PACKAGE__->create_accessors( qw( ) );

our $VERSION ='0.81';

use constant {
    WRITE_RAM        => HiPi::Interface::EPaper::TypeA::WRITE_RAM(),
    WRITE_RAM_2      => HiPi::Interface::EPaper::TypeA::WRITE_RAM_2(),
    SET_RAM_X_ADDRESS_START_END_POSITION => HiPi::Interface::EPaper::TypeA::SET_RAM_X_ADDRESS_START_END_POSITION(),
    SET_RAM_Y_ADDRESS_START_END_POSITION => HiPi::Interface::EPaper::TypeA::SET_RAM_Y_ADDRESS_START_END_POSITION(),
    SET_RAM_X_ADDRESS_COUNTER => HiPi::Interface::EPaper::TypeA::SET_RAM_X_ADDRESS_COUNTER(),
    SET_RAM_Y_ADDRESS_COUNTER => HiPi::Interface::EPaper::TypeA::SET_RAM_Y_ADDRESS_COUNTER(),
};

sub _create {
    my( $class, %params ) = @_;
        
    # Default pins for Pimoroni Inky PHAT
    # reset_pin    => RPI_PIN_13, #  27 
    # dc_pin       => RPI_PIN_15, #  22
    # busy_pin     => RPI_PIN_11, #  17
    
    $params{reset_pin} //= RPI_PIN_13;
    $params{dc_pin}    //= RPI_PIN_15;
    $params{busy_pin}  //= RPI_PIN_11;
    
    $params{device_width}  = 104;
    $params{device_height} = 212;
    $params{offsetx} = 0;
    
    $params{is_tri_colour} = 1;
    
    $params{frame_1_bpp}  = EPD_FRAME_BPP_1;
    $params{frame_2_bpp}  = EPD_FRAME_BPP_1;
    $params{frame_1_type} = EPD_FRAME_TYPE_BLACK;
    $params{frame_2_type} = EPD_FRAME_TYPE_COLOUR;
    $params{frame_1_invert} = 0;
    $params{frame_2_invert} = 1;
    
    # don't allow change here
    $params{border_control} = EPD_BORDER_POR;
    
    $params{rotation} //= 90;
    
    $params{can_partial} = 0;
    $params{busy_state}  = RPI_HIGH;
    
    $params{display_update_setting} = 0xC7;
    
    $params{driver_ouput_control_bytes} = [ 0xd3, 0x00, 0x00 ];
    $params{booster_soft_start_control_bytes} = [];
    $params{vcom_register_bytes}     = [ 0x3c ];
    $params{dummy_line_period_bytes} = [ 0x07 ];
    $params{gate_time_bytes}         = [ 0x04 ];
    $params{data_entry_mode_bytes}   = [ 0x03 ];
    
    $params{analog_control_bytes}    = [ 0x54 ];
    $params{inky_magic_bytes}        = [ 0x3b ];
    $params{source_driving_bytes}    = [ 0x2d, 0xb2, 0x22 ];
    
    $params{lut_full} = [
        # A B C D     A B C D     A B C D     A B C D     A B C D     A B C D     A B C D
        0b01001000, 0b10100000, 0b00010000, 0b00010000, 0b00010011, 0b00000000, 0b00000000,# 0b00000000, # LUT0 - Black
        0b01001000, 0b10100000, 0b10000000, 0b00000000, 0b00000011, 0b00000000, 0b00000000,# 0b00000000, # LUTT1 - White
        0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000,# 0b00000000, # IGNORE
        0b01001000, 0b10100101, 0b00000000, 0b10111011, 0b00000000, 0b00000000, 0b00000000,# 0b00000000, # LUT3 - Red
        0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000,# 0b00000000, # LUT4 - VCOM
        #0xA5, 0x89, 0x10, 0x10, 0x00, 0x00, 0x00, # LUT0 - Black
        #0xA5, 0x19, 0x80, 0x00, 0x00, 0x00, 0x00, # LUT1 - White
        #0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, # LUT2 - Red - NADA!
        #0xA5, 0xA9, 0x9B, 0x9B, 0x00, 0x00, 0x00, # LUT3 - Red
        #0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, # LUT4 - VCOM

#       Duration              |  Repeat
#       A     B     C     D   |
        67,   10,   31,   10,    4,  # 0 Flash
        16,   8,    4,    4,     6,  # 1 clear
        4,    8,    8,    32,    16,  # 2 bring in the black
        4,    8,    8,    64,    32, # 3 time for red
        6,    6,    6,    2,     2,  # 4 final black sharpen phase
        0,    0,    0,    0,     0,  # 4
        0,    0,    0,    0,     0,  # 5
        0,    0,    0,    0,     0,  # 6
        0,    0,    0,    0,     0   # 7
    ];
    
    $params{lut_partial} = [];
    
    my $self = $class->SUPER::_create( %params );
    
    return $self;
}

sub display_update {
    my $self = shift;
    
    # Black Frame
    $self->_inky_phat_set_memory_area;
    $self->_inky_phat_send_buffer( WRITE_RAM , 0 );
    
    # Red Frame
    $self->_inky_phat_set_memory_area;
    $self->_inky_phat_send_buffer( WRITE_RAM_2, 1 );
    
    $self->display_frame;
}

sub _inky_phat_set_memory_area {
    my $self = shift;
    $self->send_command(SET_RAM_X_ADDRESS_START_END_POSITION, 0x00, 0x0c );            # Set RAM X address
    $self->send_command(SET_RAM_Y_ADDRESS_START_END_POSITION, 0x00, 0x00, 0xd3, 0x00); # Set RAM Y address
    $self->send_command(SET_RAM_X_ADDRESS_COUNTER, 0x00);                              # Set RAM X address counter
    $self->send_command(SET_RAM_Y_ADDRESS_COUNTER, 0x00, 0x00);                        # Set RAM Y address counter
}

sub _inky_phat_send_buffer {
    my($self, $command, $buffindex) = @_;
    $self->send_command($command);
    my $bufferbytes = $self->context->buffer_bytes;
    my $chunksize = $self->spi_chunksize;
    my $byteloops = int($bufferbytes / $chunksize);
    my $lastbytes = $bufferbytes % $chunksize;
    my $index;
    my $buffer = $self->context->buffers->[$buffindex];
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
}

1;

__END__
