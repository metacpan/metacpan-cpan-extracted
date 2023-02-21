#########################################################################################
# Package        HiPi::Interface::MicroDotPHAT
# Description  : Interface to Pimoroni Micro Dot pHAT
# Copyright    : Perl Port Copyright (c) 2018 Mark Dootson
# License      : This is free software; you can redistribute it and/or modify it under
#                the same terms as the Perl 5 programming language system itself.
#
# This is a port of the Pimoroni Python code to Perl
#
# https://github.com/pimoroni/microdot-phat
#
#########################################################################################
# Pimoroni Copyright Notice
#########################################################################################
# MIT License
#
# Copyright (c) 2017 Pimoroni Ltd.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#
#########################################################################################

package HiPi::Interface::MicroDotPHAT;

#########################################################################################
use strict;
use warnings;
use parent qw( HiPi::Interface );
use HiPi qw( :i2c :rpi :fl3730);
use HiPi::Interface::IS31FL3730;
use HiPi::Utils::BitBuffer;
use HiPi::Interface::MicroDotPHAT::Font qw( :font );
use Try::Tiny;
use Carp;

our $VERSION ='0.81';

__PACKAGE__->create_ro_accessors( qw( _hat_width _hat_height ) );

__PACKAGE__->create_accessors( qw(
    controllers buffer
    _rotate180
    _scrollx
    _scrolly
    _mirror
    _decimal
    _clear_on_exit
) );

my $matrixconfig = [
    { control => 0, type  => 'B' },
    { control => 0, type  => 'A' },
    { control => 1, type  => 'B' },
    { control => 1, type  => 'A' },
    { control => 2, type  => 'B' },
    { control => 2, type  => 'A' },
];

sub new {
    my ($class, %userparams) = @_;
    
    my %params = (
        brightness  => 127,
        width       => 30,
        height      => 7,
        _hat_width   => 30,
        _hat_height  => 7,
        _rotate180 => 0,
        _scrollx   => 0,
        _scrolly   => 0,
        _mirror    => 0,
        _clear_on_exit => 1,
        _decimal   => [ 0, 0, 0, 0, 0, 0 ],
    );
    
    # get user params
    foreach my $key( keys (%userparams) ) {
        my $paramkey = $key;
        $paramkey =~ s/^_+//;
        $params{$paramkey} = $userparams{$key};
    }
    
    # initialise
    my @controllers = ();
    
        
    for my $address ( 0x63, 0x62, 0x61 ) {
        my %is31params = ( address => $address );
        
        for my $inpname ( qw( devicename backend ) ) {
            $is31params{$inpname} = $params{$inpname} if $params{$inpname};
        }
        
        my $control = HiPi::Interface::IS31FL3730->new( %is31params );
        $control->reset;
        $control->configure( FL3730_SSD_NORMAL | FL3730_DM_MATRIX_BOTH | FL3730_AEN_OFF | FL3730_ADM_8X8 );
        $control->lighting_effect( FL3730_AGS_0_DB | FL3730_CS_35_MA );
        $control->brightness( $params{brightness} );
        push @controllers, $control;
    }
    
    $params{controllers} = \@controllers;
    
    $params{buffer} = HiPi::Utils::BitBuffer->new(
        width       => $params{width},
        height      => $params{height},
        autoresize  => 1,
    );
    
    my $self = $class->SUPER::new(%params);
    HiPi->register_exit_method( $self, '_exit');
    return $self;
}

sub width { $_[0]->buffer->width; }

sub height { $_[0]->buffer->height; }

sub clear {
    my $self = shift;
    
    $self->buffer (
        HiPi::Utils::BitBuffer->new(
            width       => $self->_hat_width,
            height      => $self->_hat_height,
            autoresize  => 1,
        )
    );
    
    $self->_scrollx(0);
    $self->_scrolly(0);
    $self->_decimal([0,0,0,0,0,0]);
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

sub set_brightness {
    my($self, $val) = @_;
    
    $val ||= 1.0;
    if( $val > 1.0 || $val < 0.0 ) {
        carp q(brightness value must be between 0.0 and 1.0 );
    }
    
    my $brightness = int($val * 127);
    $brightness = 127 if $brightness > 127;
    
    $_->brightness( $brightness ) for ( @{ $self->controllers } );
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

sub write_char {
    my($self, $char, $offset_x, $offset_y) = @_;
    $offset_x ||= 0;
    $offset_y ||= 0;
    
    my $charbits = _get_char($char);
    for ( my $x = 0; $x < 5; $x++ ) {
        for ( my $y = 0; $y < 7; $y ++ ) {
            my $p = (($charbits->[$x] & (1 << $y)) > 0) ? 1 : 0;
            $self->set_pixel($offset_x + $x, $offset_y + $y, $p );
        }
    }
}

sub _get_char {
    my $char = shift;
    $char //= ' ';
    my $char_ordinal;

    try { $char_ordinal = ord($char); };
    
    unless( $char_ordinal && exists(phat_font->{$char_ordinal}) ) {
        carp qq(Unsupported char $char);
        $char_ordinal = 32;
    }

    # ? override
    
    $char_ordinal = 12316 if $char_ordinal == 65374;
    
    return phat_font->{$char_ordinal};
}


sub set_decimal {
    my($self, $index, $state) = @_;
    
    unless(defined($index)
           && $index =~ /^0|1|2|3|4|5$/
        ) {
        return;
    }
    
    $self->_decimal->[$index] = $state ? 1 : 0;
    
}

sub write_string {
    my($self, $string, $offset_x, $offset_y, $kerning ) = @_;
    $string   //= '';
    $offset_x ||= 0;
    $offset_y ||= 0;
    $kerning  //= 1;
    
    my $pixels = 0;
    for my $char ( split(//, $string) ) {

        my $char_data = _get_char($char);
        
        my @pixelcols = ();
        my ($maxX, $minX);
        
        for (my $x = 0; $x < 5; $x ++ ) {
            my @pixelrows = ();
            for ( my $y = 0; $y < 7; $y++ ) {
                
                my $val = (($char_data->[$x] & (1 << $y)) > 0) ? 1 : 0;
                
                if( $val ) {
                    $minX = $x unless(defined($minX));
                    $maxX = $x;
                }
                
                push @pixelrows, [ $offset_x + $x, $offset_y + $y, $val ];
            }
            
            push @pixelcols, \@pixelrows;
        }
        
        if( $kerning ) {
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
                for ( my $y = 0; $y < 7; $y++ ) {
                    push @pixelrows, [ $offset_x + $gapoffset + 1, $offset_y + $y, 0 ];
                }
                push @pixelcols, \@pixelrows;
            } else {
                # a space - 2 rows - get rid of final 3
                pop @pixelcols;
                pop @pixelcols;
                pop @pixelcols;
            }   
        }
        
        my $charpixels = scalar @pixelcols;
        
        $offset_x += $charpixels;
        
        $pixels += $charpixels;
        
        for my $col ( @pixelcols ) {
            for my $row ( @$col ) {
                $self->set_pixel( @$row );
            }
        }
    }
    
    return $pixels;
}

sub show {
    my $self = shift;
    
    my $databuf = $self->buffer->clone_buffer;
    
    # scroll it etc
    $databuf->scroll_x_y( $self->_scrollx, $self->_scrolly);
    
    $databuf->mirror($self->_hat_width, $self->_hat_height) if $self->_mirror;
    
    $databuf->flip($self->_hat_width, $self->_hat_height) if $self->_rotate180;
    
    # write it
    for (my $matrix = 0; $matrix < 6; $matrix++) {
        my $mconf   = $matrixconfig->[$matrix];
        my $control = $self->controllers->[$mconf->{control}];
        my $offset_x = $matrix * 5;
                
        my @buffer = ( 0 ) x 8;
        
        for ( my $x = 0; $x < 5; $x++) {
            for ( my $y = 0; $y < 7; $y++) {
                my $val = $databuf->get_bit( $offset_x + $x, $y );
                if($mconf->{type} eq 'B') {
                    $buffer[$x] += ( $val << $y );
                } else {
                    $buffer[$y] += ( $val << $x );
                }
            }
        }
        
        if($mconf->{type} eq 'B') {
            if( $self->_decimal->[$matrix] ) {
                $buffer[7] |= 0b01000000;
            } else {
                $buffer[7] &= 0b10111111;
            }
            $control->matrix_2_data( @buffer );
        } else {
            if( $self->_decimal->[$matrix] ) {
                $buffer[6] |= 0b10000000;
            } else {
                $buffer[6] &= 0b01111111;
            }
            $control->matrix_1_data( @buffer );
        }
    }
    
    for my $control ( @{ $self->controllers } ) {
        $control->update;
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
    $scroll_x %= $self->width;
    $scroll_y %= $self->height;
    
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

sub draw_tiny {
    my($self, $display, $text) = @_;
    $text //= '';
    
    return unless( defined($display) && $display =~ /^0|1|2|3|4|5$/ );
    return unless length($text);
    
    unless( $text =~ /^\d+$/ ) {
        carp qq(text should contain only numbers: '$text');
        return;
    }
    
    my @buf = ();
    for my $char ( split(//, $text) ) {
        my $num = int($char);
        push @buf, @{ phat_tiny_numbers->[$num] };
        # space
        push @buf, 0;
    }
    
    my $rowcount = scalar @buf;
    $rowcount = 7 if $rowcount > 7;

    for ( my $row = 0; $row < $rowcount; $row ++ ) {
        my $offset_x = $display * 5;
        my $offset_y = 6-($row % 7);
        for ( my $d = 0; $d < 5; $d++ ) {
            $self->set_pixel($offset_x+(4-$d), $offset_y, ($buf[$row] & (1 << $d)) > 0);
        }
    }
    
    return;
}

sub _exit {
    my $self = shift;
    if( $self->_clear_on_exit ) {
        for my $control ( @{ $self->controllers } ) {
            $control->configure(FL3730_SSD_SHUTDOWN);
        }
    }
}

1;

__END__