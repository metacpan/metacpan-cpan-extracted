#########################################################################################
# Package        HiPi::Interface::EPaper
# Description  : Control Monochrome OLEDs
# Copyright    : Copyright (c) 2018 Mark Dootson
# License      : This is free software; you can redistribute it and/or modify it under
#                the same terms as the Perl 5 programming language system itself.
#########################################################################################

package HiPi::Interface::EPaper;

#########################################################################################
use strict;
use warnings;
use parent qw( HiPi::Interface );
use HiPi qw( :rpi :spi :epaper );
use Carp;
use UNIVERSAL::require;
use HiPi::Graphics::DrawingContext;
use HiPi::Interface::EPaper::DisplayBuffer;

__PACKAGE__->create_ro_accessors( qw(
    device_width device_height offsetx type rotation
    frame_1_bpp frame_2_bpp
    frame_1_type frame_2_type
    dc_pin reset_pin busy_pin gpio
    lut_vcom0 lut_vcom1 lut_w lut_b lut_g1 lut_g2 lut_red0 lut_red1
    lut_full lut_partial
    can_partial  busy_state
    frame_1_invert frame_2_invert
    spi_chunksize
    _in_deep_sleep is_tri_colour
    border_control
) );

__PACKAGE__->create_accessors( qw( context lut_state ) );

our $VERSION ='0.81';

sub new {
    my ($class, %userparams) = @_;
    
    my %params = (
        devicename   => '/dev/spidev0.0',
        speed        => SPI_SPEED_MHZ_1,
        bitsperword  => 8,
        delay        => 0,
        device       => undef,
        reset_pin    => undef,
        dc_pin       => undef,
        busy_pin     => undef,
        type         => undef,
        gpio         => undef,
        device_width => undef,
        device_height => undef,
        rotation     => undef,
        can_partial  => 0,
        lut_state    => EPD_UPD_MODE_FIXED,
        invert_draw  => 0,
        busy_state   => RPI_LOW,
        offsetx      => 0,
        spi_chunksize => 4096,
        
    );
     
    # get user params
    foreach my $key( keys (%userparams) ) {
        $params{$key} = $userparams{$key};
    }
    
    my $epaperclass;
    
    croak q(No valid 'type' parameter given) unless $params{type};
    
    if( $params{type} == EPD_WS_1_54_152_X_152_C ) {
        $epaperclass = 'HiPi::Interface::EPaper::Waveshare::EPD152X152';
        
    } elsif( $params{type} == EPD_WS_1_54_200_X_200_B ) {
        $epaperclass = 'HiPi::Interface::EPaper::Waveshare::EPD200X200B';
        
    } elsif( $params{type} == EPD_WS_1_54_200_X_200_A) {
        $epaperclass = 'HiPi::Interface::EPaper::Waveshare::EPD200X200';
        
    } elsif( $params{type} == EPD_WS_2_13_250_X_122_A ) {
        $epaperclass = 'HiPi::Interface::EPaper::Waveshare::EPD250X122';
    
    } elsif( $params{type} == EPD_WS_2_13_212_X_104_B ) {
        $epaperclass = 'HiPi::Interface::EPaper::Waveshare::EPD212X104';
    
    } elsif( $params{type} == EPD_WS_2_90_296_X_128_A ) {
        $epaperclass = 'HiPi::Interface::EPaper::Waveshare::EPD296X128';
    
    } elsif( $params{type} == EPD_WS_2_90_296_X_128_B ) {
        $epaperclass = 'HiPi::Interface::EPaper::Waveshare::EPD296X128B';
        
    } elsif( $params{type} == EPD_PIMORONI_INKY_PHAT_V2 ) {
        $epaperclass = 'HiPi::Interface::EPaper::Pimoroni::EPDInkyPHAT_V2';
    } else {
        croak q(No valid 'type' parameter given);
    }
    
    $epaperclass->use or die $@;
    
    my $self = $epaperclass->_create( %params );
    
    $self->context(
        HiPi::Interface::EPaper::DisplayBuffer->new(
            device_width    => $self->device_width,
            device_height   => $self->device_height,
            rotation        => $self->rotation,
            frame_1_bpp     => $self->frame_1_bpp,
            frame_2_bpp     => $self->frame_2_bpp,
            frame_1_type    => $self->frame_1_type,
            frame_2_type    => $self->frame_2_type,
            frame_1_invert  => $self->frame_1_invert,
            frame_2_invert  => $self->frame_2_invert,
            offsetx         => $self->offsetx,
        )
    );
    
    unless( $params{'skip_reset'} ) {
        $self->display_reset;
        #if( $params{'draw_logo'} ) {
        #    $self->draw_logo;
        #    $self->display_update;
        #}
    }
    
    return $self;
}

sub _create {
    my( $class, %params ) = @_;
    
    unless(defined($params{device})) {
        require HiPi::Device::SPI;
        $params{device} = HiPi::Device::SPI->new(
            speed        => $params{speed},
            bitsperword  => $params{bitsperword},
            delay        => $params{delay},
            devicename   => $params{devicename},
        );
    }
    
    unless(defined($params{gpio})) {
        require HiPi::GPIO;
        $params{gpio} = HiPi::GPIO->new
    }
    
    my $self = $class->SUPER::new( %params );
    
    # init the GPIO settings;
    
    $self->gpio->set_pin_mode( $self->reset_pin, RPI_MODE_OUTPUT);
    $self->gpio->set_pin_mode( $self->dc_pin, RPI_MODE_OUTPUT);
    $self->gpio->set_pin_mode( $self->busy_pin, RPI_MODE_INPUT);
    
    return $self;
}

sub reset {
    my $self = shift;
    $self->gpio->set_pin_level( $self->reset_pin, RPI_LOW);
    $self->delay( 200 );
    $self->gpio->set_pin_level( $self->reset_pin, RPI_HIGH);
    $self->delay( 200 );
}

sub send_command {
    my( $self, $command, @data ) = @_;
    $self->gpio->set_pin_level( $self->dc_pin, RPI_LOW);
    $self->delayMicroseconds(10);
    $self->device->transfer( pack('C*', ( $command ) ) );
    if( @data ) {
        $self->send_data( @data );
    }
    return;
}

sub send_data {
    my($self, @data) = @_;
    $self->gpio->set_pin_level( $self->dc_pin, RPI_HIGH );
    $self->delayMicroseconds(10);
    $self->device->transfer( pack('C*', @data ) );
    return;
}

sub wait_for_idle {
    my $self = shift;
    while( $self->gpio->get_pin_level( $self->busy_pin ) == $self->busy_state ) {
        $self->delay(100);
    }
    return;
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

#----------------------------------------------------
# Common Type Methods
#----------------------------------------------------

sub display_reset {
    my $self = shift;
    carp 'display_reset not supported in this class';
}

sub display_update {
    my $self = shift;
    carp 'display_update not supported in this class';
}

#----------------------------------------------------
# Waveshare 2 & 3 col non partial methods
#----------------------------------------------------

sub set_lut_bw {
    my $self = shift;
    carp 'set_lut_bw not supported in this class';
}

sub set_lut_colour {
    my $self = shift;
    carp 'set_lut_colour not supported in this class';
}

#----------------------------------------------------
# Waveshare Partial Update Methods
#----------------------------------------------------

sub create_partial_context {
    my $self = shift;
    carp 'create_partial_context not supported in this class';
}

sub display_frame {
    my $self = shift;
    carp 'display_frame not supported in this class';
}

sub display_sleep {
    my $self = shift;
    carp 'display_sleep not supported in this class';
}

sub display_partial_update {
    my $self = shift;
    carp 'display_partial_update not supported in this class';
}

sub get_partial_coordinates {
    my $self = shift;
    carp 'get_partial_coordinates not supported in this class';
}

sub set_frame_memory {
    my $self = shift;
    carp 'set_frame_memory not supported in this class';
}

sub set_lut_full {
    my $self = shift;
    carp 'set_lut_full not supported in this class';
}

sub set_lut_partial {
    my $self = shift;
    carp 'set_lut_partial not supported in this class';
}

sub set_memory_area {
    my $self = shift;
    carp 'set_memory_area not supported in this class';
}

sub set_memory_pointer {
    my $self = shift;
    carp 'set_memory_pointer not supported in this class';
}

sub set_update_mode {
    my $self = shift;
    carp 'set_update_mode not supported in this class';
}

sub _send_command_if_data {
    my($self, $command, $data ) = @_;
    if( $data && ref($data) eq 'ARRAY' && @$data ) {
        $self->send_command( $command, @$data );
    }
}

#----------------------------------------------------
# This class methods
#----------------------------------------------------

sub clear_buffer {
    my $self = shift;
    $self->context->clear_buffer;
}

sub set_pen {
    my($self, $newpen) = @_;
    my $oldpen = $self->context->pen;
    $self->context->pen( $newpen );
    return $oldpen;
}

sub draw_logo {
    my $self = shift;
    
    my $maxW = $self->logical_width;
    my $maxH = $self->logical_height;
    
    # get the sizes for text
    my $toptext = 'Raspberry Pi';
    my $topfont = 'SansEPD102';
    my $bottext = 'HiPi ' . $HiPi::VERSION;
    my $botfont = 'SansEPD102';
    my $maxtextheight = int($maxH / 2) - 15;
    my $maxtextwidth  = $maxW - 15;
    for my $size ( qw( 102 76 50 38 31 28 23 19 15) ) {
        $topfont = 'SansEPD' . $size;
        my($tw, $th) = $self->get_text_extents( $toptext, $topfont );
        last if $tw <= $maxtextwidth && $th <= $maxtextheight; 
    }
    for my $size ( qw( 102 76 50 38 31 28 23 19 15) ) {
        $botfont = 'SansEPD' . $size;
        my($tw, $th) = $self->get_text_extents( $bottext, $botfont );
        last if $tw <= $maxtextwidth - 20 && $th <= $maxtextheight; 
    }
    
    my $restorepen = $self->set_pen( EPD_BLACK_PEN );
    my($w, $h) = $self->get_text_extents( $toptext, $topfont );
    my $x = int( 0.5 + ($maxW - $w) / 2);
    # for $y we want the middle of the top half of the screen
    my $y = int( 0.5 + (($maxH / 2 ) - $h) / 2);
    $self->draw_text($x,$y, $toptext, $topfont);
    
    $self->set_pen( EPD_COLOUR_PEN );
    
    my $rectx = $maxW - 1;
    my $recty = int(0.5 + $maxH / 2);
    
    for (my $i = 0; $i < 3; $i ++) {
        $self->draw_rectangle(0 + $i, 0 + $i , $rectx - $i, $recty - $i);
    }
    
    $self->draw_rectangle(0,$recty + 1, $maxW -1, $maxH -1, 1);
    
    ($w, $h) = $self->get_text_extents( $bottext, $botfont);
    $x = int( 0.5 + ($maxW - $w) / 2);
    $y = int( $recty + 1 + ($recty - $h) / 2);
    $self->invert_pen(1);
    $self->draw_text($x, $y, $bottext, $botfont);
    $self->invert_pen(0);
    
    $self->set_pen( $restorepen );
}

sub create_context {
    return HiPi::Graphics::DrawingContext->new;
}

#---------------------------------------------------
# Context Interface
#---------------------------------------------------


sub invert_pen { shift->context->invert_pen( @_ ); }

sub draw_context { shift->context->draw_context( @_ ); }

sub draw_pixel { shift->context->draw_pixel( @_ );  }

sub draw_text { shift->context->draw_text( @_ ); }

sub get_text_extents { shift->context->get_text_extents( @_ ); }

sub draw_circle { shift->context->draw_circle( @_ ); }

sub draw_ellipse { shift->context->draw_ellipse( @_ ); }

sub draw_arc { shift->context->draw_arc( @_ ); }

sub draw_rectangle { shift->context->draw_rectangle( @_ ); }

sub draw_rounded_rectangle { shift->context->draw_rounded_rectangle( @_ ); }

sub draw_line { shift->context->draw_line( @_ ); }

sub draw_polygon { shift->context->draw_polygon( @_ ); }

sub draw_bit_array { shift->context->draw_bit_array( @_ ); }


1;

__END__