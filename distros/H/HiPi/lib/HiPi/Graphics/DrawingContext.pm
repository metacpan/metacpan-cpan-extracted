#########################################################################################
# Package        HiPi::Graphics::DrawingContext
# Description  : Common Monochrome Drawing Context
# Copyright    : Copyright (c) 2018 Mark Dootson
# License      : This is free software; you can redistribute it and/or modify it under
#                the same terms as the Perl 5 programming language system itself.
#########################################################################################

package HiPi::Graphics::DrawingContext;

#########################################################################################

use strict;
use warnings;
use HiPi::Graphics::BitmapFont;

use parent qw( HiPi::Class );

our $VERSION ='0.81';

__PACKAGE__->create_accessors( qw( contextarray pen_inverted ) );

use constant {
    TRIG_PI => 3.14159265358979,
    DEFAULT_FONT => HiPi::Graphics::BitmapFont::MONO_OLED_DEFAULT_FONT,
};

sub new {
    my( $class, %params) = @_;
    $params{contextarray} //= [];
    
    my $self = $class->SUPER::new( %params );
    return $self;
}

sub clear_context {
    my $self = shift;
    $self->contextarray( [] );
    return;
}

sub get_context_bounds {
    my $self = shift;
    
    my ($minx, $miny, $maxx, $maxy);
    
    for my $point ( @{ $self->contextarray } ) {
        my($x,$y,$on) = @$point;
        if( $minx ) {
            $minx = $x if $x < $minx;
            $miny = $y if $y < $miny;
            $maxx = $x if $x > $maxx;
            $maxy = $y if $y > $maxy;
        } else {
            $minx = $maxx = $x;
            $miny = $maxy = $y;
        }
    }
    
    return( $minx || 0, $miny || 0, $maxx || 0, $maxy || 0 );
}

sub invert_pen {
    my ($self, $invert ) = @_;
    $invert = ( $invert ) ? 1 : 0;
    $self->pen_inverted( $invert );
}

sub _deg2rad {
    my $degrees = shift;
    return ($degrees / 180) * TRIG_PI;
}

sub _rad2deg {
    my $radians = shift;
    return ($radians / TRIG_PI) * 180;
}

sub rotate {
    my( $self, $rotation, $rx, $ry ) = @_;
    
    $rx //= 0;
    $ry //= 0;
    
    $rotation //= 0;
    $rotation = $rotation % 360;
        
    my $radians = ( $rotation ) ? _deg2rad($rotation) : 0;
    
    return unless $radians;
    
    my @oldbuffer = @{ $self->contextarray };
    return unless( scalar @oldbuffer );
    
    my @newbuffer = ();
    
    # Common Rotations
    if( $rotation == 90 || $rotation == -270 ) {
        for my $point ( @oldbuffer ) {
            my( $x, $y, $on) = @$point;
            $x -= $rx;
            $y -= $ry;
            push @newbuffer, [ - $y + $rx, $x + $ry, $on ];
        }
    } elsif( abs($rotation) == 180 ) {
        for my $point ( @oldbuffer ) {
            my( $x, $y, $on) = @$point;        
            $x -= $rx;
            $y -= $ry;
            push @newbuffer, [ - $x + $rx, - $y + $ry, $on ];
        }
    } elsif( $rotation == -90 || $rotation == 270 ) {
        for my $point ( @oldbuffer ) {
            my( $x, $y, $on) = @$point;
            $x -= $rx;
            $y -= $ry;
            push @newbuffer, [ $y + $rx, - $x + $ry, $on ];
        }
    } else {
    # other
        
        if( $rotation == 11) {
            $radians =  _deg2rad(180);
        }
        
        my $sin = sin($radians);
        my $cos = cos($radians);
        
        for my $point ( @oldbuffer ) {
            my( $x, $y, $on) = @$point;
            $x -= $rx;
            $y -= $ry;
            my $x1 = $rx + int( 0.5 + ($x * $cos) - ($y * $sin) );
            my $y1 = $ry + int( 0.5 + ($x * $sin) + ($y * $cos) );
            
            push @newbuffer, [ $x1, $y1, $on ];
        }
    }
    
    $self->contextarray( \@newbuffer );
    
    return $self;
}

sub rotated_context {
    my( $self, $rotation, $rx, $ry ) = @_;
    my $ctx = ref($self)->new( contextarray => $self->contextarray );
    $ctx->rotate( $rotation, $rx, $ry );
    return $ctx;
}

sub draw_pixel {
    my($self, $x, $y, $on) = @_;
    $on //= 1;
    if($self->pen_inverted) {
        $on = ( $on ) ? 0 : 1;
    }

    push @{ $self->contextarray }, [ $x, $y, $on ];
}

sub draw_text {
    my($self, $x, $y, $text, $font ) = @_;
    $x //= 0;
    $y //= 0;
    $text  //= '';
    $font  //=  DEFAULT_FONT;
        
    if($text eq '') {
        return ( wantarray ) ? (0,0) : 0;
    }
    
    unless(ref($font)) {
        # allow string for $font
        $font = $self->get_font($font);
    }
    
    my $textwidth  = 0;
    my $textheight = 0;
    
    if( $font->class eq 'hipi_2' ) {
        # variable fonts
        ( $textwidth, $textheight ) = $self->_draw_hipi_2_text($x,$y,$text,$font);
    }
    
    return ( wantarray ) ? ( $textwidth, $textheight ) : $textwidth;
}

sub _draw_hipi_2_text {
    my ($self, $x1, $y, $text, $font) = @_;
    
    my $prev_char = undef;
    my $prev_width = 0;
    my $prev_advance = 0;
    my $textheight = $font->char_height;
    my $x = $x1;
    
    my @points = ();
    
    my $symbols = $font->symbols;
            
    for my $c ( split(//, $text) ) {
        my $this_char = ord($c);
        if ( exists( $symbols->{$this_char} ) ) {
            my $symbol = $symbols->{$this_char};          
            if ( $prev_char ) {
                my $kerning = $font->kerning->{$prev_char}->{$this_char} || 0;
                $x += $prev_advance + $kerning + $symbol->{xoffset} + $font->gap_width;
            }
            $prev_char = $this_char;
            $prev_width = $symbol->{width};
            $prev_advance = $symbol->{xadvance} - $symbol->{xoffset};
            my $bytes_per_row = ($symbol->{width} + 7) >> 3;
            my $offset = 0;
            for ( my $row = 0; $row < $textheight; $row ++ ) {
                my $py = $y + $row;
                my $mask = 0x80;
                my $p = $offset;
                for ( my $col = 0; $col < $symbol->{width}; $col ++ ) {
                    my $px = $x + $col;
                    if ( $symbol->{bitmap}->[$p] & $mask ) {
                        push @points, [ $px, $py ];
                    }
                    $mask >>= 1;
                    if ( $mask == 0 ) {
                        $mask = 0x80;
                        $p += 1;
                    }
                }
                $offset += $bytes_per_row;
            }
        } else {
            # space or no char in font
            if ($prev_char ) {
                $x += $font->space_width + $font->gap_width + $prev_advance;
            }
            $prev_char = undef;
            $prev_advance = 0;
       }
    }
    
    if ( $prev_char ) {
        $x += $prev_width;
    }
    
    # drawpoints
    for my $point ( @points ) {
        $self->draw_pixel( @$point, 1);
    }
    
    my $textwidth = $x - $x1;
    
    return ( wantarray ) ? ( $textwidth, $textheight) : $textwidth;
}



sub get_text_extents {
    my($self, $text, $font) = @_;
    $text  //= '';
    $font  //= DEFAULT_FONT;
    unless(ref($font)) {
        # allow string for $font
        $font = $self->get_font($font);
    }
    if($text eq '') {
        return ( wantarray ) ? (0,0) : 0;
    }
    
    my $textwidth  = 0;
    my $textheight = 0;
        
    if( $font->class eq 'hipi_2' ) {
        ($textwidth, $textheight) = $self->_get_hipi_2_extents( $text,$font );
    }
    
    return ( wantarray ) ? ( $textwidth, $textheight ) : $textwidth;
}

sub _get_hipi_2_extents {
    my ($self, $text, $font) = @_;

    my $prev_char = undef;
    my $prev_width = 0;
    my $prev_advance = 0;
    
    my $textheight = $font->char_height;
    my $textwidth = 0;
    
    my $symbols = $font->symbols;
            
    for my $c ( split(//, $text) ) {
        my $this_char = ord($c);
        if ( exists( $symbols->{$this_char} ) ) {
           my $symbol = $symbols->{$this_char};   
            if ( $prev_char ) {
                my $kerning = $font->kerning->{$prev_char}->{$this_char} || 0;
                $textwidth += $prev_advance + $kerning + $symbol->{xoffset} + $font->gap_width;
            }
            $prev_char = $this_char;
            $prev_width = $symbol->{width};
            $prev_advance = $symbol->{xadvance} - $symbol->{xoffset};
        } else {
            # space or no char in font
            if ($prev_char ) {
                $textwidth += $font->space_width + $font->gap_width + $prev_advance;
            }
            $prev_char = undef;
            $prev_advance = 0;
        }
    }
    
    if ( $prev_char ) {
        $textwidth += $prev_width;
    }
    
    return ( wantarray ) ? ( $textwidth, $textheight) : $textwidth;
}

sub get_font {
    my($self, $fontname) = @_;
    HiPi::Graphics::BitmapFont->get_font( $fontname );
}

sub draw_circle {    
    my( $self, $x, $y, $radius, $fill) = @_;
    
    my $x_pos = -$radius;
    my $y_pos = 0;
    my $err = 2 - 2 * $radius;
    my $e2;
    
    my @points = ();
    
    while(1) {
        push @points, [ $x - $x_pos, $y + $y_pos, 1] ;
        push @points, [ $x + $x_pos, $y + $y_pos, 1] ;
        push @points, [ $x + $x_pos, $y - $y_pos, 1] ;
        push @points, [ $x - $x_pos, $y - $y_pos, 1] ;
        if( $fill ) {
            my $nx = $x + $x_pos;
            for (my $i = $nx; $i < $nx + ( 2 * (-$x_pos) + 1 ); $i++) {
                push @points, [ $i, $y + $y_pos, 1 ];
            }
            for (my $i = $nx; $i < $nx + ( 2 * (-$x_pos) + 1 ); $i++) {
                push @points, [ $i, $y - $y_pos, 1 ];
            }
        }
        $e2 = $err;
        if ($e2 <= $y_pos) {
            $err += ++$y_pos * 2 + 1;
            if(-$x_pos == $y_pos && $e2 <= $x_pos) {
              $e2 = 0;
            }
        }
        if ($e2 > $x_pos) {
            $err += ++$x_pos * 2 + 1;
        }
        last if $x_pos > 0;
    }
    
    for my $point ( @points ) {
        $self->draw_pixel( @$point );
    }
}

sub draw_ellipse {
    my( $self, $x0, $y0, $rx, $ry, $fill) = @_;
    return $self->draw_arc($x0, $y0, $rx, $ry, 0, 360, 0, $fill);
}

sub draw_arc { 
    my( $self, $x0, $y0, $rx, $ry, $start, $end, $join, $fill) = @_;
        
    $x0 //= 0;
    $y0 //= 0;
    $rx //= 0;
    $ry //= 0;
    $start //= 0;
    $end //= 360;
    $join //= 0;
    
    if( $start > $end ) {
        $start -= 360;
    }
    
    my ($radius, $h, $v) = ( 0, 0, 0 );
    
    if( $rx == $ry ) {
        $radius = $rx;
    } elsif($rx > $ry) {
        $radius = $rx;
        $v = $rx - $ry;
    } else {
        $radius = $ry;
        $h = $ry - $rx;
    }
    
    
    my $theta = $start;  #// angle that will be increased each loop
    my @points = ();
    while( $theta < $end ) {
        my $radians = _deg2rad($theta);
        my $x = $x0 + ( $radius - $h ) * cos($radians);
        my $y = $y0 + ( $radius - $v ) * sin($radians);
        push @points, [ int($x + 0.5), int($y + 0.5) ];
        $theta ++;
    }
    
    my $lastpoint  = scalar( @points ) -1;
    
    if( $fill ) {
        push @points, [ $x0, $y0 ];
        $radius --;
        while( $radius > 0) {
            $theta = $start;
            while( $theta < $end ) {
                my $radians = _deg2rad($theta);
                my $x = $x0 + ( $radius - $h ) * cos($radians);
                my $y = $y0 + ( $radius - $v ) * sin($radians);
                push @points, [ int($x + 0.5), int($y + 0.5) ];
                $theta ++
            }
            $radius --;
        }
    }
    
    if( $join ) {
        for my $point ( $points[0], $points[$lastpoint] ) {
            my $linepoints = $self->_get_line_points( $x0, $y0, @$point, 0 );
            push @points, @$linepoints;
        }
    }
    
    # draw points
    
    for my $point ( @points ) {
        $self->draw_pixel( @$point, 1);
    }
    
    return ( $points[0], $points[$lastpoint] );
}

sub draw_rectangle {
    my($self, $x1, $y1, $x2, $y2, $fill) = @_;
    my @points = ();
    
    if($x1 > $x2) {
        my $tmp = $x1;
        $x1 = $x2;
        $x2 = $tmp;
    }
    
    if($y1 > $y2) {
        my $tmp = $y1;
        $y1 = $y2;
        $y2 = $tmp;
    }
    
    # Top Horizontal
    my ($x, $y ) = ( $x1, $y1 );
    while( $x <= $x2 ) {
        push @points, [ $x, $y ];
        $x++;
    }
    
    # Bottom Horizontal
    ($x, $y ) = ( $x1, $y2 );
    while( $x <= $x2 ) {
        push @points, [ $x, $y ];
        $x++;
    }
    
    # left vertical
    ($x, $y ) = ( $x1, $y1 + 1 );
    while( $y < $y2 ) {
        push @points, [ $x, $y ];
        $y++;
    }
    
    if( $fill ) {
        $y = $y1 + 1;
        while( $y < $y2) {
            $x = $x1 + 1;
            while( $x < $x2 ) {
                push @points, [ $x, $y ];
                $x++;
            }
            $y++;
        }
    }
    
    # right vertical
    ($x, $y ) = ( $x2, $y1 + 1 );
    while( $y < $y2 ) {
        push @points, [ $x, $y ];
        $y++;
    }
    
    # draw the pixels
    
    for my $point ( @points ) {
        $self->draw_pixel( @$point, 1);
    }
}

sub draw_rounded_rectangle {
    my($self, $x1, $y1, $x2, $y2, $r, $fill) = @_;
    my @points = ();
    
    $r //= 4;
    
    if($x1 > $x2) {
        my $tmp = $x1;
        $x1 = $x2;
        $x2 = $tmp;
    }
    
    if($y1 > $y2) {
        my $tmp = $y1;
        $y1 = $y2;
        $y2 = $tmp;
    }
    
    # check r
    {
        my $maxrx = -1 + $x2 - $x1;
        my $maxry = -1 + $y2 - $y1;
        $r = $maxrx if $r > $maxrx;
        $r = $maxry if $r > $maxry;
    }
    
    if( $fill ) {
        # simpler to draw 3 filled rectangles + arcs
        $self->draw_rectangle($x1, $y1 + $r, $x1 + $r, $y2 - $r, 1);
        $self->draw_rectangle($x1 + $r, $y1, $x2 - $r, $y2, 1);
        $self->draw_rectangle($x2 - $r, $y1 + $r, $x2, $y2 - $r, 1);
    } else {
           
        # Top Horizontal
        my ($x, $y ) = ( $x1 + $r, $y1 );
        while( $x < $x2 - $r ) {
            push @points, [ $x, $y ];
            $x++;
        }
        
        # Bottom Horizontal
        ($x, $y ) = ( $x1 + $r, $y2  );
        while( $x < $x2 - $r ) {
            push @points, [ $x, $y ];
            $x++;
        }
        
        # left vertical
        ($x, $y ) = ( $x1, $y1 + $r );
        while( $y < $y2 - $r ) {
            push @points, [ $x, $y ];
            $y++;
        }
        
        # right vertical
        ($x, $y ) = ( $x2, $y1 + $r );
        while( $y < $y2 - $r ) {
            push @points, [ $x, $y ];
            $y++;
        }
    }
    
    # arcs
    #top left
    $self->draw_arc($x1 + $r, $y1 + $r, $r, $r, 180, 270, 0, $fill );
    #top right
    $self->draw_arc($x2 - $r, $y1 + $r, $r, $r, 270, 360, 0, $fill );
    #bottom right
    $self->draw_arc($x2 - $r, $y2 - $r, $r, $r, 0, 90, 0, $fill );
    #bottom left
    $self->draw_arc($x1 + $r, $y2 - $r, $r, $r, 90, 180, 0, $fill );
       
    # draw the pixels
    
    for my $point ( @points ) {
        $self->draw_pixel( @$point, 1);
    }
}

sub draw_polygon {
    my ( $self, $inputvertices, $fill ) = @_;
    
    my @vertices = @$inputvertices;
    return unless( scalar(@vertices) > 2 );
    
    # Close the polygon if it is not closed
    if($vertices[0]->[0] != $vertices[-1]->[0] || $vertices[0]->[1] != $vertices[-1]->[1]) {
        push @vertices , [ $vertices[0]->[0], $vertices[0]->[1] ];
    }
    
    my $lastpoint;
    my @polypoints = ();
    
    for my $inpoint ( @vertices ) {
        if( $lastpoint ) {
            my $linepoints = $self->_get_line_points( @$lastpoint, @$inpoint, 0 );
            push @polypoints, @$linepoints;
        }
        $lastpoint = $inpoint;
    }
    
    if( $fill ) {
        my($minX, $minY, $maxX, $maxY) = ( $self->buffer_cols, $self->buffer_rows, 0,0 );
        for my $point ( @polypoints ) {
            $maxX = $point->[0] if $point->[0] > $maxX;
            $maxY = $point->[1] if $point->[1] > $maxY;
            $minX = $point->[0] if $point->[0] < $minX;
            $minY = $point->[1] if $point->[1] < $minY;
        }
        my @newpoints = ();
        for (my $x = $minX; $x < $maxX; $x++) {
            for (my $y = $minY; $y < $maxY; $y++) {
                if( _point_in_polygon([$x, $y], @vertices ) ) {
                    push @newpoints, [ $x, $y ];
                }
            }
        }
        push @polypoints, @newpoints;
    }
    
    # draw
    
    for my $point ( @polypoints ) {
        $self->draw_pixel( @$point, 1);
    }
}

# _point_in_polygon
# Learned from latest Math::Polygon but that isn't in Raspbian Stretch
# and we only want this single function. There are no improvements here.

sub _point_in_polygon {
    my $point = shift;
    return 0 if @_ < 3;

    my ($x, $y) = @$point;
    my $inside  = 0;

    my ($px, $py) = @{ (shift) };

    while(@_) {
        my ($nx, $ny) = @{ (shift) };

        return 1 if $y==$py && $py==$ny
                 && ($x >= $px || $x >= $nx)
                 && ($x <= $px || $x <= $nx);

        return 1 if $x==$px && $px==$nx
                 && ($y >= $py || $y >= $ny)
                 && ($y <= $py || $y <= $ny);

        if(   $py == $ny
           || ($y <= $py && $y <= $ny)
           || ($y >  $py && $y >  $ny)
           || ($x >  $px && $x >  $nx)
          )  {
            ($px, $py) = ($nx, $ny);
            next;
        }

        my $xinters = ($y-$py)*($nx-$px)/($ny-$py)+$px;
        $inside = !$inside if $px==$nx || $x <= $xinters;
        ($px, $py) = ($nx, $ny);
    }
    
    return $inside;
}

sub draw_line {
    my( $self, $x1, $y1, $x2, $y2, $ep ) = @_;
    
    my $linepoints = $self->_get_line_points( $x1, $y1, $x2, $y2, $ep );
    
    # draw the pixels
    
    for my $point ( @$linepoints ) {
        $self->draw_pixel( @$point, 1);
    }
}

sub _get_line_points {
    
    my( $self, $x0, $y0, $x1, $y1, $ep ) = @_;
    
    $ep //= 1;
    
    my @points = ();
    
    my $dx = $x1 - $x0 >= 0 ? $x1 - $x0 : $x0 - $x1;
    my $sx = $x0 < $x1 ? 1 : -1;
    my $dy = $y1 - $y0 <= 0 ? $y1 - $y0 : $y0 - $y1;
    my $sy = $y0 < $y1 ? 1 : -1;
    my $err = $dx + $dy;
    
    while(($x0 != $x1) && ($y0 != $y1)) {
        push(@points, [ $x0, $y0 ] );
        if (2 * $err >= $dy) {     
            $err += $dy;
            $x0 += $sx;
        }
        if (2 * $err <= $dx) {
            $err += $dx; 
            $y0 += $sy;
        }
    }
    if(!$ep) {
        pop @points;
    }
    
    return \@points;
}


sub draw_bit_array {
    my($self, $x1, $y1, $bitarray, $fill) = @_;
    
    $fill //= 0;
    
    my @points = ();
    
    for ( my $y = 0; $y < @$bitarray; $y ++) {
        my $line = $bitarray->[$y];
        
        for ( my $x = 0; $x < @$line; $x ++) {
            if( $bitarray->[$y]->[$x] ) {
                push( @points, [ $x + $x1, $y + $y1, 1 ]);
            } elsif( $fill ) {
                push( @points, [ $x + $x1, $y + $y1, 0 ]);
            }
        }
    }
    
    # draw
    
    for my $point ( @points ) {
        $self->draw_pixel( @$point );
    }
    
    return,
}

sub draw_context {
    my($self, $x, $y, $context) = @_;
    for my $point ( @{ $context->contextarray } ) {
        $self->draw_pixel ( $point->[0] + $x, $point->[1] + $y, $point->[2] );
    }
    return;
}

1;

__END__