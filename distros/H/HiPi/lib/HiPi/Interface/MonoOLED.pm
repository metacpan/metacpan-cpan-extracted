#########################################################################################
# Package        HiPi::Interface::MonoOLED
# Description  : Control Monochrome OLEDs
# Copyright    : Copyright (c) 2018 Mark Dootson
# License      : This is free software; you can redistribute it and/or modify it under
#                the same terms as the Perl 5 programming language system itself.
#########################################################################################

package HiPi::Interface::MonoOLED;

#########################################################################################
use utf8;
use strict;
use warnings;
use parent qw( HiPi::Interface );
use HiPi qw( :i2c :rpi :spi :oled );
use Carp;
use HiPi::Graphics::BitmapFont;
use HiPi::Graphics::DrawingContext;
use HiPi::Interface::MonoOLED::DisplayBuffer;

__PACKAGE__->create_ro_accessors( qw(
    backend spidriver rows cols col_offset
    reset_pin dc_pin external_power flipped type controller
    chunk_data buffer_rows
) );

__PACKAGE__->create_accessors( qw( context gpio ) );

our $VERSION ='0.81';

use constant {
    CONTROL_CONTINUE        => 0x80,
    CONTROL_COMMAND         => 0x00,
    CONTROL_DATA            => 0x40,
    
    TYPE_CONTROL_SSD1306    => 0x01,
    TYPE_CONTROL_SH1106     => 0x02,
    TYPE_COLUMNS_128        => 0x04,
    TYPE_ROWS_64            => 0x08,
    TYPE_ROWS_32            => 0x10,
    TYPE_BUS_I2C            => 0x20,
    TYPE_BUS_SPI            => 0x40,
    TYPE_COLUMNS_256        => 0x80,
    TYPE_CONTROL_SSD1322    => 0x100,
    
    OLED_SETCONTRAST => 0x81,
    OLED_DISPLAYALLON_RESUME  => 0xA4,
    OLED_DISPLAYALLON  => 0xA5,
    OLED_NORMALDISPLAY  => 0xA6,
    OLED_INVERTDISPLAY  => 0xA7,
    OLED_DISPLAYOFF  => 0xAE,
    OLED_DISPLAYON   => 0xAF,

    OLED_SETDISPLAYOFFSET  => 0xD3,
    OLED_SETCOMPINS  => 0xDA,

    OLED_SETVCOMDETECT  => 0xDB,

    OLED_SETDISPLAYCLOCKDIV  => 0xD5,
    OLED_SETPRECHARGE  => 0xD9,

    OLED_SETMULTIPLEX  => 0xA8,

    OLED_SETSTARTLINE  => 0x40,

    SSD1306_MEMORYMODE  => 0x20,
    SSD1306_COLUMNADDR  => 0x21,
    
    SH1106_SETLOWCOLUMN  => 0x00,
    SH1106_SETHIGHCOLUMN  => 0x10,
    
    SSD1306_PAGEADDR    => 0x22,
    SH1106_PAGEADDR    => 0xB0,

    OLED_COMSCANINC  => 0xC0,
    OLED_COMSCANDEC  => 0xC8,

    OLED_SEGREMAP  => 0xA0,

    OLED_CHARGEPUMP  => 0x8D,

    OLED_EXTERNALVCC  => 0x1,
    OLED_SWITCHCAPVCC  => 0x2,
    
    SSD1306_ACTIVATE_SCROLL => 0x2F,
    SSD1306_DEACTIVATE_SCROLL => 0x2E,
    SSD1306_SET_VERTICAL_SCROLL_AREA => 0xA3,
    SSD1306_RIGHT_HORIZONTAL_SCROLL => 0x26,
    SSD1306_LEFT_HORIZONTAL_SCROLL => 0x27,
    SSD1306_VERTICAL_AND_RIGHT_HORIZONTAL_SCROLL => 0x29,
    SSD1306_VERTICAL_AND_LEFT_HORIZONTAL_SCROLL => 0x2A,

    SSD1306_MEMORY_MODE_HORIZ  => 0x00,
    SSD1306_MEMORY_MODE_VERT   => 0x01,
    SSD1306_MEMORY_MODE_PAGE   => 0x02,
};


sub new {
    my ($class, %userparams) = @_;
    
    my %params = $class->_init_params( %userparams );
    
    my $self = $class->SUPER::new(%params);
    
    $self->context(
        HiPi::Interface::MonoOLED::DisplayBuffer->new(
            rows => $self->buffer_rows,
            cols => $self->cols,
        )
    );
        
    $self->_set_gpio if(defined($self->dc_pin) || defined($self->reset_pin) );
    
    if(defined($self->dc_pin)) {
        if( $self->gpio->get_pin_mode( $self->dc_pin ) != RPI_MODE_OUTPUT ) {
            $self->gpio->set_pin_mode( $self->dc_pin, RPI_MODE_OUTPUT );
        }
        $self->gpio->set_pin_level( $self->dc_pin, RPI_LOW );
    }
    
    if(defined($self->reset_pin)) {
        if( $self->gpio->get_pin_mode( $self->reset_pin ) != RPI_MODE_OUTPUT ) {
            $self->gpio->set_pin_mode( $self->reset_pin, RPI_MODE_OUTPUT );
        }
    }

    unless( $params{'skip_reset'} ) {
        $self->display_reset;
        unless( $params{'skip_logo'} ) {
            $self->draw_logo;
            $self->display_update;
        }
    }
    
    return $self;
}

sub _init_params {
    my( $class, %inparams ) = @_;
    my $pi = HiPi::RaspberryPi->new();
    
    my %i2cparams  = (
        devicename      => ( $pi->board_type == RPI_BOARD_TYPE_1 ) ? '/dev/i2c-0' : '/dev/i2c-1',
        address         => 0x3C,
        device          => undef,
        reset_pin       => undef,
        chunk_data      => 1,
    );
    
    my %spiparams = (
        devicename   => '/dev/spidev0.0',
        speed        => SPI_SPEED_MHZ_1,
        bitsperword  => 8,
        delay        => 0,
        device       => undef,
        reset_pin    => undef,
        dc_pin       => undef,
    );
    
    $inparams{type} //= SSD1306_128_X_64_I2C;
    my $controltype = $inparams{type};
    
    # defaults
    my %params = (
        device       => undef,
        backend      => 'i2c',
        cols         => 128,
        rows         => 64,
        buffer_rows  => 64,
        col_offset   => 0,
        type         => SSD1306_128_X_64_I2C,
        controller   => TYPE_CONTROL_SSD1306,
    );
    
    $params{backend} = ( $controltype & TYPE_BUS_SPI ) ? 'spi' : 'i2c';
    # $params{cols} = only support 128 type currently
    
    if( $controltype & TYPE_CONTROL_SH1106 ) {
        $params{col_offset} = 2;
        $params{controller} = TYPE_CONTROL_SH1106;
    }
    
    $params{buffer_rows} = $params{rows} = ( $controltype & TYPE_ROWS_32 ) ? 32 : 64;
    
    # get user params
    foreach my $key( keys (%inparams) ) {
        $params{$key} = $inparams{$key};
    }
    
    # fix any daft row figures
    if( $params{rows} !~ /^32|64$/ ) {
        $params{rows} = 64;
    }
    if( $params{buffer_rows} !~ /^32|64$/ ) {
        $params{buffer_rows} = $params{rows};
    }
    # get backend params
    if( $params{backend} eq 'spi' ) {
        foreach my $key( keys %spiparams ) {
            $params{$key} //= $spiparams{$key};
        }
    } else {
        foreach my $key( keys %i2cparams ) {
            $params{$key} //= $i2cparams{$key};
            # set chunk_data for smbus / bcm2835
            if($params{backend} eq 'i2c') {
                $params{chunk_data} //= 0;
            } else {
                $params{chunk_data} //= 1;
            }
        }
    }
    
    unless( defined($params{device}) ) {
        if ( $params{backend} eq 'bcm2835' ) {
            require HiPi::BCM2835::I2C;
            $params{device} = HiPi::BCM2835::I2C->new(
                address    => $params{address},
                peripheral => ( $params{devicename} eq '/dev/i2c-0' ) ? HiPi::BCM2835::I2C::BB_I2C_PERI_0() : HiPi::BCM2835::I2C::BB_I2C_PERI_1(),
            );
        } elsif( $params{backend} eq 'spi' ) {
            require HiPi::Device::SPI;
            $params{device} = HiPi::Device::SPI->new(
                speed        => $params{speed},
                bitsperword  => $params{bitsperword},
                delay        => $params{delay},
                devicename   => $params{devicename},
            );
        } else {
            require HiPi::Device::I2C;
            $params{device} = HiPi::Device::I2C->new(
                devicename  => $params{devicename},
                address     => $params{address},
                busmode     => $params{backend},
            );
        }
    }
    
    $params{spidriver} = $params{device}->isa('HiPi::Device::SPI') ? 1 : 0; 
    
    return %params;
}

sub display_reset {
    my $self = shift;
    
    if(defined($self->reset_pin)) {
        $self->gpio->set_pin_level($self->reset_pin, RPI_LOW );
        $self->delayMicroseconds(1000);
        $self->gpio->set_pin_level($self->reset_pin, RPI_HIGH );
        $self->delayMicroseconds(1000);
    }
    
    $self->send_command(OLED_DISPLAYOFF);
    $self->send_command(OLED_SETDISPLAYCLOCKDIV, 0x80);
    $self->send_command(OLED_SETMULTIPLEX, $self->rows -1);
    $self->send_command(OLED_SETDISPLAYOFFSET, 0x00);
    $self->send_command(OLED_SETSTARTLINE | 0x0);
    if ( $self->external_power ) {
        $self->send_command(OLED_CHARGEPUMP, 0x10);
    } else {
        $self->send_command(OLED_CHARGEPUMP, 0x14);
    }
    
    if( $self->controller == TYPE_CONTROL_SSD1306 ) {
        $self->send_command( SSD1306_MEMORYMODE, SSD1306_MEMORY_MODE_HORIZ );
    }
    
    $self->display_flip($self->flipped);
    
    if( $self->rows == 64 ) {
        $self->send_command(OLED_SETCOMPINS, 0x12);
    } else {
        $self->send_command(OLED_SETCOMPINS, 0x02);
    }
    
    $self->send_command(OLED_SETCONTRAST, 0x7f);
    
    if ( $self->external_power ) {
        $self->send_command(OLED_SETPRECHARGE, 0x22);
    } else {
        $self->send_command(OLED_SETPRECHARGE, 0xF1);
    }
    
    $self->send_command(OLED_SETVCOMDETECT, 0x40);
    $self->send_command(OLED_DISPLAYALLON_RESUME);
    $self->send_command(OLED_NORMALDISPLAY);
    if( $self->controller == TYPE_CONTROL_SSD1306 ) {
        $self->send_command(SSD1306_DEACTIVATE_SCROLL);
    }
    $self->clear_buffer;
    $self->display_update;
    $self->send_command(OLED_DISPLAYON);
    
    return;
}

sub _set_gpio {
    my $self = shift;
    unless( defined( $self->gpio ) && $self->gpio->isa('HiPi::GPIO') ) {
        require HiPi::GPIO;
        $self->gpio( HiPi::GPIO->new );
    }
}

sub send_command {
    my($self, @bytes) = @_;
    if( $self->spidriver ) {
        $self->_spi_send_command( @bytes );
    } else {
        $self->_i2c_send_command( @bytes );
    }
}

sub send_data {
    my($self, @bytes) = @_;
    if( $self->spidriver ) {
        $self->_spi_send_data( @bytes );
    } else {
        $self->_i2c_send_data( @bytes );
    }
}

sub _spi_send_command {
    my($self, @commands) = @_;
    $self->gpio->set_pin_level( $self->dc_pin, RPI_LOW );
    $self->delayMicroseconds(10);
    $self->device->transfer( pack('C*', @commands ) );
    return;
}

sub _spi_send_data {
    my($self, @data) = @_;
    $self->gpio->set_pin_level( $self->dc_pin, RPI_HIGH );
    $self->delayMicroseconds(10);
    $self->device->transfer( pack('C*', @data ) );
    return;
}

sub _i2c_send_command {
    my($self, @bytes) = @_;
    my $bytecount = scalar @bytes;
    return unless $bytecount;
    
    for ( my $i = 0; $i < $bytecount; $i ++ ) {
        $self->device->bus_write( CONTROL_COMMAND, $bytes[$i] );
    }
}

sub _i2c_send_data {
    my($self, @bytes) = @_;
    
    # set chunk size based on backend
    my $chunksize = ( $self->chunk_data ) ? 16 : 0;

    if( $chunksize ) {
    
        my $numbytes = scalar @bytes;
        my $chunks = int( $numbytes / $chunksize );
        my $leftover = ( $numbytes % $chunksize );
        
        for (my $chunk = 0; $chunk < $chunks; $chunk ++ ) {
            my $start = $chunk * $chunksize;
            my $end = $start + $chunksize - 1;
            $self->device->bus_write( CONTROL_DATA, @bytes[$start..$end] );
        }
        
        if($leftover){
            my $start = $chunks * $chunksize;
            my $end = $start + $leftover - 1;
            $self->device->bus_write( CONTROL_DATA, @bytes[$start..$end] );
        }
    } else {
        # send it all at once
        $self->device->bus_write( CONTROL_DATA, @bytes );
    }
    
    return;
}

sub clear_buffer {
    my $self = shift;
    $self->context->clear_buffer(0);
}

sub fill_buffer {
    my $self = shift;
    $self->context->clear_buffer(0xFF);
}

sub invert_display {
    my $self = shift;
    $self->send_command(OLED_INVERTDISPLAY);
}

sub normal_display {
    my $self = shift;
    $self->send_command(OLED_NORMALDISPLAY);
}

sub display_off {
    my $self = shift;
    $self->send_command(OLED_DISPLAYOFF);
}

sub display_on {
    my $self = shift;
    $self->send_command(OLED_DISPLAYON);
}

sub set_contrast {
    my ($self, $contrast) = @_;
    $self->send_command(OLED_SETCONTRAST, $contrast & 0xFF );
}

sub set_start_line {
    my($self, $line) = @_;
    if( $line >= 0 && $line < $self->buffer_rows ) {
        $self->send_command(OLED_SETSTARTLINE | $line);
    }
    return;
}

sub create_context {
    return HiPi::Graphics::DrawingContext->new;
}

sub display_update {
    my( $self ) = @_;
    $self->block_update(0,0, $self->cols -1, $self->buffer_rows - 1);
    return;
}

sub block_update {
    my ( $self, $x1, $y1, $x2, $y2 ) = @_;
    if(
        $x1 < 0 || $x1 >= $self->cols
        || $x2 < 0 || $x2 >= $self->cols
        || $y1 < 0 || $y1 >= $self->buffer_rows
        || $y2 < 0 || $y2 >= $self->buffer_rows
        || $y1 > $y2 || $x1 > $x2) {
        
        carp qq(block update parameters outside display bounds : $x1, $y1, $x2, $y2);
        return;
    }
    
    my $page_start = $y1 >> 3;
    my $page_end = $y2 >> 3;
    my $pagebytes = $self->cols;
    my $colstart = $self->col_offset + $x1;
    my $colend = $self->col_offset + $x2;
    for (my $page = $page_start; $page <= $page_end; $page ++) {
        $self->_set_ready_for_update( $page, $page, $colstart, $colend);
        my $start = ($page * $pagebytes) + $x1;
        my $end = $start + ( $x2 - $x1 );
        $self->send_data( @{ $self->context->buffer }[$start..$end] );
        if( $self->buffer_rows == 32 && $self->rows == 32 ) {
             # repeat whole buffer
            $self->_set_ready_for_update( $page + 4, $page + 4, $colstart, $colend);
            $self->send_data( @{ $self->context->buffer }[$start..$end] );
        }
    }
    return;
}

sub _set_ready_for_update {
    my($self, $page_start, $page_end, $col_start, $col_end ) = @_;
    if( $self->controller == TYPE_CONTROL_SH1106 ) {
        my $col_low = $col_start & 0x0F;
        my $col_high = ($col_start >> 4) & 0x1F;
        $self->send_command(SH1106_SETLOWCOLUMN | $col_low );
        $self->send_command(SH1106_SETHIGHCOLUMN | $col_high );
        $self->send_command(SH1106_PAGEADDR | $page_start );
    } else {
        $self->send_command(SSD1306_COLUMNADDR, $col_start,  $col_end );
        $self->send_command(SSD1306_PAGEADDR, $page_start, $page_end);
    }
    return;
}

sub display_flip {
    my($self, $flipped)  = @_;
    $flipped ||= 0;
    if ( $flipped ) {
        $self->send_command(OLED_SEGREMAP | 0x00);
        $self->send_command(OLED_COMSCANINC);
        
    } else {
        $self->send_command(OLED_SEGREMAP | 0x01);
        $self->send_command(OLED_COMSCANDEC);
    }
    return;
}

sub draw_logo {
    my ($self, $x, $y) = @_;
    $x ||= 0;
    $y ||= 0;
    my $raspberry = $self->get_logo;
    $self->draw_rectangle( $x, $y, $x+127, $y+31);
    $self->draw_text( $x+14, $y+4, 'Raspberry Pi', 'Sans12');
    $self->draw_text( $x+37, $y+17, 'HiPi Perl','Sans12');
    my $text = 'HiPi ' . $HiPi::VERSION;
    $self->draw_text(22,40, $text, 'Sans20');
    $self->draw_bit_array( $x+96, $y+4, $raspberry, 0 );
}

sub get_logo {
    my $raspberry = [ 
        [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,   0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ],
        [ 0, 0, 0, 1, 1, 1, 1, 0, 0, 0,   0, 0, 0, 1, 1, 1, 1, 0, 0, 0 ],
        [ 0, 0, 1, 0, 0, 0, 0, 1, 0, 0,   0, 0, 1, 0, 0, 0, 0, 1, 0, 0 ],
        [ 0, 0, 1, 0, 1, 1, 0, 0, 1, 0,   0, 1, 0, 0, 1, 1, 0, 1, 0, 0 ],
        [ 0, 0, 1, 0, 0, 0, 1, 0, 1, 0,   0, 1, 0, 1, 0, 0, 0, 1, 0, 0 ],
        
        [ 0, 0, 0, 1, 0, 0, 0, 0, 0, 1,   1, 0, 0, 0, 0, 0, 1, 0, 0, 0 ],
        [ 0, 0, 0, 0, 1, 1, 1, 0, 0, 0,   0, 0, 0, 1, 1, 1, 0, 0, 0, 0 ],
        [ 0, 0, 0, 0, 0, 0, 1, 0, 0, 0,   0, 0, 0, 1, 0, 0, 0, 0, 0, 0 ],
        [ 0, 0, 0, 0, 1, 1, 0, 0, 0, 1,   1, 0, 0, 0, 1, 1, 0, 0, 0, 0 ],
        [ 0, 0, 0, 1, 0, 0, 0, 0, 1, 0,   0, 1, 0, 0, 0, 0, 1, 0, 0, 0 ],
        
        [ 0, 0, 1, 0, 0, 1, 1, 0, 0, 1,   1, 0, 0, 1, 1, 0, 0, 1, 0, 0 ],
        [ 0, 0, 1, 0, 1, 0, 0, 1, 0, 0,   0, 0, 1, 0, 0, 1, 0, 1, 0, 0 ],
        [ 0, 1, 0, 0, 1, 0, 0, 1, 0, 0,   0, 0, 1, 0, 0, 1, 0, 0, 1, 0 ],
        [ 0, 1, 0, 0, 0, 1, 1, 0, 0, 1,   1, 0, 0, 1, 1, 0, 0, 0, 1, 0 ],
        [ 0, 1, 0, 0, 0, 0, 0, 0, 1, 0,   0, 1, 0, 0, 0, 0, 0, 0, 1, 0 ],
        
        [ 0, 1, 0, 0, 1, 1, 0, 0, 1, 0,   0, 1, 0, 0, 1, 1, 0, 0, 1, 0 ],
        [ 0, 0, 1, 0, 1, 0, 1, 0, 0, 1,   1, 0, 0, 1, 0, 1, 0, 1, 0, 0 ],
        [ 0, 0, 1, 0, 0, 1, 1, 0, 0, 0,   0, 0, 0, 1, 1, 0, 0, 1, 0, 0 ],
        [ 0, 0, 0, 1, 0, 0, 0, 0, 0, 1,   1, 0, 0, 0, 0, 0, 1, 0, 0, 0 ],
        [ 0, 0, 0, 0, 1, 1, 0, 0, 1, 0,   0, 1, 0, 0, 1, 1, 0, 0, 0, 0 ],
        
        [ 0, 0, 0, 0, 0, 0, 1, 1, 0, 0,   0, 0, 1, 1, 0, 0, 0, 0, 0, 0 ],
        [ 0, 0, 0, 0, 0, 0, 0, 0, 1, 1,   1, 1, 0, 0, 0, 0, 0, 0, 0, 0 ],
        [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,   0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ],
    ];
    
    return $raspberry;
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

#---------------------------------------------------
# Command Aliases
#---------------------------------------------------

*HiPi::Interface::MonoOLED::update_display = \&display_update;

1;

__END__