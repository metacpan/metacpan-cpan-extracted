#########################################################################################
# Package        HiPi::Interface::MAX7219LEDStrip
# Description  : Interface to strip of MAX7219 driven LEDs
# Copyright    : (c) 2018-2020 Mark Dootson
# License      : This is free software; you can redistribute it and/or modify it under
#                the same terms as the Perl 5 programming language system itself.
#########################################################################################

package HiPi::Interface::MAX7219LEDStrip;

#########################################################################################
use strict;
use warnings;
use parent qw( HiPi::Interface );
use HiPi qw( :spi :rpi :max7219 );
use HiPi::Interface::MAX7219;
use HiPi::Utils::BitBuffer;
use HiPi::Graphics::Font5x7 qw( :font );
use Try::Tiny;
use Carp;

our $VERSION ='0.81';

__PACKAGE__->create_ro_accessors( qw( segments pixel_width pixel_height reverse_map ) );

__PACKAGE__->create_accessors( qw(
    buffer
    _rotate180
    _scrollx
    _scrolly
    _mirror
    _clear_on_exit
) );

sub new {
    my ($class, %userparams) = @_;
    
    my %params = (
        segments   => 4,
        _rotate180 => 0,
        _scrollx   => 0,
        _scrolly   => 0,
        _mirror    => 0,
        _clear_on_exit => 1,
        # SPI
        devicename   => '/dev/spidev0.0',
        speed        => 2000000,
        delay        => 0,
        reverse_map  => 0,
    );
    
    # get user params
    foreach my $key( keys (%userparams) ) {
        my $paramkey = $key;
        $paramkey =~ s/^_+//;
        $params{$paramkey} = $userparams{$key};
    }
    
    $params{pixel_width}  = $params{segments} * 8;
    $params{pixel_height} = 8;
    
    $params{buffer} = HiPi::Utils::BitBuffer->new(
        width         => $params{pixel_width},
        height        => $params{pixel_height},
        autoresize    => 1,
        autoincrement => $params{segments} * 8,
    );
    
    unless(defined($params{device})) {
        $params{device} = HiPi::Interface::MAX7219->new(
            speed        => $params{speed},
            delay        => $params{delay},
            devicename   => $params{devicename},
        );
    }
    
    my $self = $class->SUPER::new(%params);
    
    HiPi->register_exit_method( $self, '_exit');
    
    for( my $segment = 0; $segment < $self->segments; $segment ++ ) {
        $self->device->set_decode_mode( 0, $segment );
        $self->device->set_scan_limit( 7, $segment );
        $self->device->set_intensity( 2, $segment );
        $self->device->set_display_test( 0, $segment );
        $self->device->wake_up( $segment );
    }
    
    return $self;
}

sub width { $_[0]->buffer->width; }

sub height { $_[0]->buffer->height; }

sub clear {
    my $self = shift;
    
    $self->buffer (
        HiPi::Utils::BitBuffer->new(
            width         => $self->pixel_width,
            height        => $self->pixel_height,
            autoresize    => 1,
            autoincrement => $self->pixel_width * 8,
        )
    );
    
    $self->_scrollx(0);
    $self->_scrolly(0);
    return;
}

sub fill {
    my ( $self, $val ) = @_;
    $self->buffer->fill( $val );
}

sub set_rotate180 {
    my($self, $value) = @_;
    $self->_rotate180( $value ? 1 : 0 );
}

sub set_mirror {
    my($self, $value) = @_;
    $self->_mirror( $value ? 1 : 0 );
}

sub set_clear_on_exit {
    my($self, $value) = @_;
    $self->_clear_on_exit( $value ? 1 : 0 );
}

sub set_intensity {
    my($self, $val) = @_;
    $val //= 0;
    $val = int($val);
    if( $val > 15 || $val < 0 ) {
        carp q(intensity value must be between 0 and 15 );
    }
        
    for ( my $maxc = 0; $maxc < $self->segments; $maxc ++ ) {
        $self->device->set_intensity( $val, $maxc );
    }
    
    return;
}

sub set_col {
    my($self, $x, $col) = @_;
    
    for (my $y = 0; $y < 7; $y++) {
        $self->set_pixel($x, $y, ($col & (1 << $y)) > 0);
    }
}

sub set_pixel {
    my($self, $x, $y, $c) = @_;
    $c = $c ? 1 : 0;
    $self->buffer->set_bit($x, $y, $c);
}

sub _get_char {
    my $char = shift;
    $char //= ' ';
    my $char_ordinal;

    try { $char_ordinal = ord($char); };
    
    unless( $char_ordinal && exists( font_5_x_7->{$char_ordinal}) ) {
        carp qq(Unsupported char $char);
        $char_ordinal = 32;
    }
    
    return font_5_x_7->{$char_ordinal};
}

sub _handle_write_string_and_extents {
    my($self, $string, $offset_x, $offset_y, $dowrite ) = @_;
    $string   //= '';
    $offset_x ||= 0;
    $offset_y ||= 0;
    
    my $pixels = 0;
    for my $char ( split(//, $string) ) {

        my $char_data = _get_char($char);
        
        my @pixelcols = ();
        my ($maxX, $minX);
        
        for (my $x = 0; $x < 5; $x ++ ) {
            
            my @pixelrows = ();
            for ( my $y = 0; $y < 8; $y++ ) {
                
                my $val = (($char_data->[$x] & (1 << $y)) > 0) ? 1 : 0;
                
                if( $val ) {
                    $minX = $x unless(defined($minX));
                    $maxX = $x;
                }
                
                push @pixelrows, [ $offset_x + $x, $offset_y + $y, $val ];
            }
            
            push @pixelcols, \@pixelrows;
        }
        
        
        if(defined($minX)) {
            my $shiftcount = $minX;
            for (my $x = 0; $x < $shiftcount; $x ++) {
                shift @pixelcols;
            }
            
            for (my $x = $maxX; $x < 4; $x++) {
                pop @pixelcols;
            }
            
            # adjust x values
            for my $col( @pixelcols ) {
                for my $row ( @$col ) {
                    $row->[0] -= $shiftcount;
                }
            }
            
            # add gap
            my @pixelrows = ();
            my $gapoffset = scalar @pixelcols;
            for ( my $y = 0; $y < 8; $y++ ) {
                push @pixelrows, [ $offset_x + $gapoffset + 1, $offset_y + $y, 0 ];
            }
            push @pixelcols, \@pixelrows;
        } else {
            # a space - 2 rows - get rid of final 3
            pop @pixelcols;
            pop @pixelcols;
            pop @pixelcols;
        }   
        
        
        my $charpixels = scalar @pixelcols;
        $offset_x += $charpixels;
        $pixels += $charpixels;
        
        if( $dowrite ) {
            for my $col ( @pixelcols ) {
                for my $row ( @$col ) {
                    $self->set_pixel( @$row );
                }
            }
        }
    }
    
    return $pixels;
}

sub write_string {
    my($self, $string, $offset_x, $offset_y ) = @_;
    return $self->_handle_write_string_and_extents( $string, $offset_x, $offset_y, 1 );
}

sub get_string_extents {
    my($self, $string ) = @_;
    return $self->_handle_write_string_and_extents( $string, 0, 0, 0 );
}

sub show {
    my $self = shift;
    
    my $databuf = $self->buffer->clone_buffer;
    
    # scroll it etc
    $databuf->scroll_x_y( $self->_scrollx, $self->_scrolly);
    
    $databuf->mirror($self->pixel_width, $self->pixel_height) if $self->_mirror;
    
    $databuf->flip($self->pixel_width, $self->pixel_height) if $self->_rotate180;
    
    my @linebuffers = ([], [], [], [], [], [], [], []);
    
    my $maxsegment = $self->segments - 1;
        
    for (my $segment = 0; $segment < $self->segments; $segment ++) {
        my $offset_x = ( $maxsegment - $segment ) * 8;
        
        my @buffer = ( 0 ) x 8;
        
        for ( my $x = 0; $x < 8; $x++) {
            for ( my $y = 0; $y < 8; $y++) {
                my $val = $databuf->get_bit( $offset_x + $x, $y );
                if( $self->reverse_map ) {
                    $buffer[$y] += ( $val << $x );
                } else {
                    $buffer[$y] += ( $val << ( 7 - $x ) );
                }
            }
        }
        
        for (my $buffrow = 0; $buffrow < 8; $buffrow ++) {
            unshift @{ $linebuffers[$buffrow] }, ( MAX7219_REG_DIGIT_0 + $buffrow, $buffer[$buffrow] );
        }
    }
    
    for ( my $y = 0; $y < 8; $y++) {
        $self->device->send_raw_bytes( @{ $linebuffers[$y] } );
    }
}

sub scroll {
    my($self, $amount_x, $amount_y) = @_;
    $amount_x //= 0;
    $amount_y //= 0;
    
    if($amount_x == 0 && $amount_y == 0 ) {
         $amount_x = 1;
    }
    
    my $scroll_x = $self->_scrollx;
    my $scroll_y = $self->_scrolly;

    $scroll_x += $amount_x;
    $scroll_y += $amount_y;
    
    $scroll_x = $scroll_x % $self->width;
    $scroll_y = $scroll_y % $self->height;
    
    $self->_scrollx( $scroll_x );
    $self->_scrolly( $scroll_y );
    return;
}

sub scroll_to {
    my($self, $position_x, $position_y) = @_;
    $position_x //= 0;
    $position_y //= 0;
    
    my $scroll_x = $position_x % $self->width;
    my $scroll_y = $position_y % $self->height;
    
    $self->_scrollx( $scroll_x );
    $self->_scrolly( $scroll_y );
    
    return;
}

sub scroll_horizontal {
    my($self, $amount) = @_;
    $amount //= 1;
    $self->scroll( $amount, 0 );
}

sub scroll_vertical {
    my($self, $amount) = @_;
    $amount //= 1;
    $self->scroll( 0, $amount );
}

sub _exit {
    my $self = shift;
    if( $self->_clear_on_exit ) {
        for( my $segment = 0; $segment < $self->segments; $segment ++ ) {
            $self->device->shutdown( $segment );
        }
    }
}

1;

__END__