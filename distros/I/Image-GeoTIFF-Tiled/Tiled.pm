package Image::GeoTIFF::Tiled;
use strict;
use warnings;
use Carp;
use Data::Dumper;
# use List::MoreUtils qw(natatime);
use IO::Handle;
use Image::GeoTIFF::Tiled::Iterator;
use Image::GeoTIFF::Tiled::Shape;

# TODO: Add x_resolution and y_resolution and resolution_unit

use vars qw( $VERSION );
$VERSION = '0.08';

use Inline C => Config => INC => '-I/usr/include/geotiff',
    LIBS     => '-ltiff -lgeotiff';

use Inline
    C       => 'DATA',
    VERSION => '0.08',
    NAME    => 'Image::GeoTIFF::Tiled';

# my $ERR_KEY = '_tif_err';

# SampleFormat
# 1 = unsigned integer data
# 2 = two’s complement signed integer data
# 3 = IEEE floating point data [IEEE]
# 4 = undefined data format
#   - default = 1
my %TEMPLATE = (
    "8,1"  => 'C',
    "8,2"  => 'c',
    "16,1" => 'S',
    "16,2" => 's',
    "32,1" => 'I',
    "32,2" => 'i',
    # "64,1" => 'Q',
    # "64,2" => 'q',
    "32,3" => 'f',
    "64,3" => 'd',
);

sub constrain_boundary {
    my ( $self, @constrained ) = @_;
    confess "Bad boundary (@constrained)" unless @constrained == 4;
    # Round to nearest int
    for ( 0 .. 1 ) {
        $constrained[ $_ ] = sprintf( "%.0f", $constrained[ $_ ] + .00001 );
    }
    for ( 2 .. 3 ) { $constrained[ $_ ] = int( $constrained[ $_ ] ); }
    
    # @constrained[0,1] = map { int($_) } @constrained[0,1];
    # @constrained[2,3] = map { int($_) + 1 } @constrained[2,3];

    # Check if it's completely outside the image
    if (
        $constrained[ 0 ] >= $self->width        # min_x to the right
        || $constrained[ 1 ] >= $self->length    # min_y below
        || $constrained[ 2 ] < 0                 # max_x to the left
        || $constrained[ 3 ] < 0
       )
    {                                            # max_y above
        return;
    }

    # x_min
    $constrained[ 0 ] = 0 if $constrained[ 0 ] < 0;
    # y_min
    $constrained[ 1 ] = 0 if $constrained[ 1 ] < 0;
    # x_max
    $constrained[ 2 ] = $self->width - 1 if $constrained[ 2 ] >= $self->width;
    # y_max
    $constrained[ 3 ] = $self->length - 1 if $constrained[ 3 ] >= $self->length;

    # Check if the dimensions no longer make sense
    if (   $constrained[ 0 ] > $constrained[ 2 ]
        || $constrained[ 1 ] > $constrained[ 3 ] )
    {
        return;
    }

    @constrained;
} ## end sub constrain_boundary

sub _corner {
    my ( $self, $x, $y, $proj ) = @_;
    ( $x, $y ) = $self->pix2proj( $x, $y );
    ( $y, $x ) = $proj->inverse( $x, $y ) if $proj;
    ( $x, $y );
}

sub corners {
    my ( $self, $proj ) = @_;
    my ( $w, $l ) = ( $self->width, $self->length );
    (
        [ $self->_corner( 0,  0,  $proj ) ],    # Upper Left
        [ $self->_corner( $w, 0,  $proj ) ],    # Upper Right
        [ $self->_corner( $w, $l, $proj ) ],    # Lower Right
        [ $self->_corner( 0,  $l, $proj ) ],    # Lower Left
    );
}

# sub bounds {
    # my ( $xmin, $ymax ) = $self->pix2proj( 0, 0 );
    # my ( $xmax, $ymin ) = $self->pix2proj( $self->width, $self->length );
    # if ( $proj ) {
    # ( $ymax, $xmin ) = $proj->inverse( $xmin, $ymax );
    # ( $ymin, $xmax ) = $proj->inverse( $xmax, $ymin );
    # }
    # ( $xmin, $ymin, $xmax, $ymax );
# }

sub tile_area {
    my $self = shift;
    $self->tile_length * $self->tile_width;
}

sub get_tile {
    my ( $self, $tile ) = @_;
    my $bps = $self->bits_per_sample;
    my $fmt = $self->sample_format || 1;
    my $t   = $TEMPLATE{ "$bps,$fmt" };
    unless ( $t ) {
        # $self->{$ERR_KEY} =
        carp "Couldn't find an unpack template for $bps BPS, format $fmt";
        return;
    }
    [ unpack( $t . $self->tile_area, $self->get_raw_tile( $tile ) ) ];
}

sub get_tiles {
    my $self = shift;
    my ( $ul, $br ) =
          @_ == 2 ? @_
        : @_ == 4
        ? $self->_pbound2corners(@_)
        : confess "Unknown args: @_";
    my $step = $self->tiles_across;
    # Rectangle formed by ul/upper-left, br/bottom-right tiles
    my $last_row = int( ( $br - $ul ) / $step );    # 0-indexed
    my $last_col = ( $br - $ul ) % $step;           # 0-indexed
    # print "ul: $ul, br: $br, last row: $last_row, last col: $last_col\n";
    my @tiles;
    for my $r ( 0 .. $last_row ) {
        my @tile_row;
        my $tr = $ul + $r * $step;
        for my $c ( 0 .. $last_col ) {
            push @tile_row, $self->get_tile( $tr + $c );
        }
        push @tiles, \@tile_row;
    }
    \@tiles;
}

# Pixel boundary 2 tile corners (ul,br)
sub _pbound2corners {
    my $self = shift;
    confess "Unknown args: @_" unless @_ == 4;
    my ($xmin,$ymin,$xmax,$ymax) = @_;
    (
        $self->pix2tile( $xmin, $ymin ),
        $self->pix2tile( $xmax, $ymax )
    );
}

# Pixel boundary to tile boundary (ul,ur,bl,br)
sub _pbound2tbound {
    my $self = shift;
    confess "Unknown args: @_" unless @_ == 4;
    my ($xmin,$ymin,$xmax,$ymax) = @_;
    ( 
        $self->pix2tile( $xmin, $ymin ),          # ul
        $self->pix2tile( $xmax, $ymin ),          # ur
        $self->pix2tile( $xmin, $ymax ),          # bl
        $self->pix2tile( $xmax, $ymax )           # br
    );
}

sub get_iterator_tile {
    my ( $self, $tile ) = @_;
    $self->get_iterator_pix(
        $self->tile2pix( $tile, 0 ),
        $self->tile2pix(
            $tile, $self->tile_width * $self->tile_length - 1
        )
    );
}

sub tile2grid {
    my $self = shift;
    my $data = ref $_[ 0 ] ? $_[ 0 ] : $self->get_tile( $_[ 0 ] );
    my @mat;
    my $across = $self->tile_width;
    confess @$data . " % $across != 0" if @$data % $across;
    # my $it = natatime $across, @$data;
    # while (my @vals = $it->()) {
        # push @mat, \@vals;
    # }
    for ( my $offset = 0; $offset < @$data; $offset += $across ) {
        # push @mat, [ splice @$data, $offset, $across ];
        push @mat, [ @$data[ $offset .. $offset + $across - 1 ] ];
    }
# [ map [ @$data[ $_ * $across .. $_ * $across + $across - 1 ] ], 0 .. $down - 1 ];
    \@mat;
}

sub get_iterator_tiles {
    # my ( $self, $ul, $br ) = @_;
    my $self = shift;
    my ( $ul, $br ) =
          @_ == 2 ? @_ 
        : @_ == 4 ? $self->_pbound2corners( @_ )
        :           confess "Unknown args: @_";
    my @px_bound = $self->constrain_boundary( 
        $self->tile2pix( $ul, 0 ),
        $self->tile2pix( $br, $self->tile_area - 1 ) 
    );
    # my $data = $self->extract_2D_array( @px_bound, undef );
    # my $data = $self->get_tiles( $ul, $br );
    # Image::GeoTIFF::Tiled::Iterator->new( {
            # boundary => \@px_bound,
            # buffer   => $self->tiles2grid( $data )
        # }
    # );
    $self->get_iterator_pix(@px_bound);
}

sub get_iterator {
    my $self = shift;
    if ( @_ == 0 ) {
        # Entire image
        return $self->get_iterator_pix( 0, 0, $self->width - 1,
            $self->length - 1 );
    }
    if ( @_ == 1 ) {
        return $self->get_iterator_shape( @_ ) if ref $_[ 0 ];
        return $self->get_iterator_tile( @_ );
    }
    if ( @_ == 2 ) {
        return $self->get_iterator_shape( @_ ) if ref $_[ 0 ] and ref $_[ 1 ];
        return $self->get_iterator_tiles( @_ );
    }
    if ( @_ == 3 ) {
        return $self->get_iterator_shape( @_ ) if ref $_[ 0 ] and $_[ 2 ];
    }
    return $self->get_iterator_pix( @_ )   if @_ == 4;
    confess "Unknown args: @_";
}

sub get_iterator_mask {
    my ( $self, $shape, $proj, $buffer_size ) = @_;
    confess "No shape" unless $shape and ref $shape;
    confess "You must specify a buffer size" unless $buffer_size;
    unless ( $shape->isa( 'Image::GeoTIFF::Tiled::Shape' ) ) {
        $shape =
            Image::GeoTIFF::Tiled::Shape->load_shape( $self, $shape, $proj );
    }
    my @shape_bound = $shape->boundary;
    # Extend boundary to include at least $buffer_size pixels outside
    $shape_bound[ 0 ] -= $buffer_size;
    $shape_bound[ 1 ] -= $buffer_size;
    $shape_bound[ 2 ] += $buffer_size;
    $shape_bound[ 3 ] += $buffer_size;
    my @px_bound = $self->constrain_boundary( @shape_bound );
    return unless @px_bound;
    my $data = $self->extract_grid( @px_bound );
    Image::GeoTIFF::Tiled::Iterator->new( {
            boundary => \@px_bound,
            buffer   => $data,
            mask     => $self->mask_shape( $data, @px_bound[ 0, 1 ], $shape ),
        }
    );
}

sub get_iterator_shape {
    my ( $self, $shape, $proj ) = @_;
    confess "No shape" unless $shape and ref $shape;
    unless ( $shape->isa( 'Image::GeoTIFF::Tiled::Shape' ) ) {
        $shape =
            Image::GeoTIFF::Tiled::Shape->load_shape( $self, $shape, $proj );
    }
    my @px_bound = $self->constrain_boundary( $shape->boundary );
    return unless @px_bound;
    # print "Shape boundary: ",join(' ',$shape->boundary),"\n";
    # print "Constrained boundary: @px_bound\n";
    my $data = $self->extract_grid( @px_bound );
    Image::GeoTIFF::Tiled::Iterator->new( {
            boundary => \@px_bound,
            buffer   => $self->filter_shape( $data, @px_bound[ 0, 1 ], $shape )
        }
    );
}

sub filter_shape {
    shift->_mask_shape( @_ );
}

sub mask_shape {
    shift->_mask_shape( @_, 1 );
}

sub _mask_shape {
    my ( $self, $data, $x0, $y0, $shape, $masking ) = @_;
    # Ray-cast: replace outside data with undef
    my $cols = @{ $data->[ 0 ] };
    # print "Cols: $cols\n";
    my @c_all = 0 .. $cols - 1;
    my @mask = $masking ? ( map [ map 1, @$_ ], @$data ) : ();
    for my $r ( 0 .. @$data - 1 ) {
        my $x     = int( $x0 ) + 0.5;
        my $y     = $y0 + $r;
        my $xvert = $shape->get_x( $y );
        unless ( @$xvert ) {
            # the whole row is outside
            if ( $masking ) {
                $mask[ $r ] = [ map 0, @c_all ];
            }
            else {
                $data->[ $r ] = [ map undef, @c_all ];
            }
            next;
        }
        # print "x: $x, y: $y, xvert: @$xvert\n";
        my $next_vert = shift @$xvert;
        my $inside    = 0;               # Start outside shape
        for my $c ( @c_all ) {
            unless ( defined $next_vert ) {
                # print "row, x = $r,$x\n";
                confess "No next_vert yet still inside!" if $inside;
                # rest of row is outside
                if ( $masking ) {
                    $mask[ $r ][ $_ ] = 0 for $c .. $cols - 1;
                }
                else {
                    undef $data->[ $r ][ $_ ] for $c .. $cols - 1;
                }
                last;
            }
            # print "Next vertex: $next_vert\n";
            while ( defined $next_vert and $x >= $next_vert ) {
                $inside = $inside ? 0 : 1;    # switch state
                $next_vert = shift @$xvert;
            }
            unless ( $inside ) {
                if ( $masking ) {
                    $mask[ $r ][ $c ] = 0;
                }
                else {
                    undef $data->[ $r ][ $c ];
                }
            }
            $x++;
        }
        # print Dumper($data->[$r]),"\n";
    } ## end for my $r ( 0 .. @$data...)
    $masking ? \@mask : $data;
} ## end sub _mask_shape

sub tiles2grid {
    my $self = shift;
    my $data = @_ == 2 ? $self->get_tiles( @_ ) : shift;
    confess "Data not in 3D tiles"
        unless ref $data
            and ref $data             eq 'ARRAY'
            and ref $data->[ 0 ]      eq 'ARRAY'
            and ref $data->[ 0 ][ 0 ] eq 'ARRAY';
  # my $data   = @_ == 1 ? shift : @_ == 2 || @_ == 4 ? $self->get_tiles( @_ ) :
  # confess "Unknown args: @_";
    my $across = $self->tile_width;
    my @grid;
    for my $row ( @$data ) {
        # my @its = map { natatime $across, @$_ } @$row;
        # push @grid, [ map $_->(), @its ] for 0 .. $across - 1;
        for ( my $offset = 0; $offset < @{ $row->[ 0 ] }; $offset += $across ) {
            my @grid_row;
            my @chunk = $offset .. $offset + $across - 1;
            for my $tile ( @$row ) {
                push @grid_row, @$tile[ @chunk ];
            }
            push @grid, \@grid_row;
        }
    }
    \@grid;
}

sub _check_boundary {
    my $self = shift;
    for(grep $_ < 0, @_) {
        # $self->{$ERR_KEY} = 
        carp "Boundary (@_) out of range: < 0";
        return 0;
    }
    my ($xmin,$ymin,$xmax,$ymax) = @_;          # User-defined boundary
    my $width = $self->width;
    if ( $xmin > $width or $xmax > $width ) {
        # $self->{$ERR_KEY} = 
        carp "Boundary (@_) out of range: image width ($width)";
        return 0;
    }
    my $length = $self->length;
    if ( $ymin > $length or $ymax > $length ) {
        # $self->{$ERR_KEY} = 
        carp "Boundary (@_) out of range: image length ($length)";
        return 0;
    }
    1;
}

# sub tif_err {
    # shift->{$ERR_KEY};
# }

sub extract_grid {
    my $self = shift;
    return unless $self->_check_boundary( @_ );
    my ( $xmin, $ymin, $xmax, $ymax ) = @_;    # User-defined boundary
    my ( $ul, $br ) = $self->_pbound2corners( @_ );
    my $across = $self->tile_width;               # Pixels per tile row
    my $down   = $self->tile_length;
    my $data   = $self->get_tiles( $ul, $br );    # 3D tile data
    my @grid;                                     # 2D tile grid

    # Only extract data in the pixel boundary from $data
    my ( $x0, $y0 ) = $self->tile2pix( $ul, 0 );    # Data point 0

    # TILE[ROW][COL] = TILE[ROW * ACROSS + COL]
    my $c_first = $xmin % $across;                  # First pixel-row-col
    my $c_last  = $xmax % $across;                  # Last pixel-row-col
    for my $tr ( 0 .. @$data - 1 ) {
        my $tiles = $data->[ $tr ];
        my $tiles_n = @$tiles;
        # Tile iterators
        # my @iters = map { natatime $across, @$_ } @$tiles;
        my $offset = 0;
        for my $gr ( 0 .. $down - 1 ) {             # grid row
            my $y = $y0 + $tr * $down + $gr;
            unless ( $y >= $ymin and $y <= $ymax ) {
                # $_->() for @iters;                  # skip data
                $offset += $across;
                next;
            }
            my @grid_row;
            # my @chunk = $offset .. $offset + $across - 1;
            # First tile
            {
                # my @tile_row = $iters[ 0 ]->();     # One row of pixels
                # my @tile_row = @{ $tiles->[ 0 ] }[ @chunk ];
                if ( $tiles_n == 1 ) {
                    # only one tile across
                    push @grid_row,
                        @{ $tiles->[ 0 ] }
                        [ $offset + $c_first .. $offset + $c_last ];
                    # @tile_row[ $c_first .. $c_last ];
                }
                else {
                    # Go to the end of the tile
                    push @grid_row,
                        @{ $tiles->[ 0 ] }
                        [ $offset + $c_first .. $offset + $across - 1 ];
                    # @tile_row[ $c_first .. $across - 1 ];
                }
            }
            # Middle tiles
            if ( $tiles_n > 2 ) {
                my @chunk = $offset .. $offset + $across - 1;
                for ( 1 .. $tiles_n - 2 ) {
                    # push @grid_row, $iters[ $_ ]->();
                    push @grid_row, @{ $tiles->[ $_ ] }[ @chunk ];
                }
            }
            # Last tile
            if ( $tiles_n > 1 ) {
                # my @tile_data = @{ $tiles->[ -1 ] }[ @chunk ];
                # $iters[ -1 ]->();
                push @grid_row,
                    @{ $tiles->[ -1 ] }[ $offset .. $offset + $c_last ];
                # @tile_data[ 0 .. $c_last ];
            }
            push @grid, \@grid_row;
            $offset += $across;
        }
        # if ( my @vals = $iters[ 0 ]->() ) {
            # print Dumper \@grid;
            # confess "\nTile data left over:\n(@vals)\n";
        # }
    } ## end for my $tr ( 0 .. @$data...)
    \@grid;
} ## end sub extract_grid

# DEFUNCT - WENT FROM 2D -> 2D
# sub extract_grid {
    # my $self = shift;
    # my ($xmin,$ymin,$xmax,$ymax) = @_;
    # my ($ul,$br) = $self->_pbound2corners(@_);
    # my $data = 
        # $self->tiles2grid($ul,$br);
    # 
    # # Replace outside data with undef
    # my $cols  = @{$data->[0]};
    # my ($x0,$y0) = $self->tile2pix($ul,0);
    # my @c_first = 0 .. $xmin - $x0 - 1;
    # my @c_last = $xmax - $x0 + 1 .. $cols - 1;
    # my @c_all = 0..$cols - 1;
    # for my $r ( 0 .. @$data - 1 ) {
        # my $y = $y0 + $r;
        # unless ( $y >= $ymin and $y <= $ymax ) {
            # # skip the whole row
            # $data->[$r] = [ map undef, @c_all ];
        # }
        # else {
            # # undef the left and right side
            # if ( @c_first ) {
                # undef $data->[$r][$_] for @c_first;
            # }
            # if ( @c_last ) {
                # undef $data->[$r][$_] for @c_last;
            # }
        # }
    # }
    # $data;
# }

sub get_iterator_pix {
    my $self     = shift;
    my @px_bound = $self->constrain_boundary( @_ );
    return unless @px_bound;
    Image::GeoTIFF::Tiled::Iterator->new( {
            boundary => \@px_bound,
            buffer   => $self->extract_grid(@px_bound)
        }
    );
}
 
     # my ($ul,$ur,$bl,$br) = 
        # $self->_pbound2tbound($xmin,$ymin,$xmax,$ymax);
    # my $across = $ur - $ul + 1;
    # my $down = int(($bl - $ul) / $self->tiles_across) + 1;
    # my $ur = $self->pix2tile($xmax,$ymin) - $ul;
    # my $bl = 
        # int(($self->pix2tile($xmin,$ymax) - $ul) / $self->tiles_across) + 1;
    # my ($tile_ur,$tile_bl) = $self->_opposite_corners($tile_ul,$tile_br);
    

sub dump_tile {
    my ( $self, $tile ) = @_;
    croak "No tile specified" unless defined $tile;
    my $buffer = $self->get_tile( $tile );
    STDOUT->flush();
    for ( 0 .. $self->tile_width * $self->tile_length - 1 ) {
        printf( "%6s", sprintf( "%.1f", $buffer->[ $_ ] ) );
        if ( ( $_ + 1 ) % ( $self->tile_width ) == 0 ) {
            print( "\n" );
        }
        else {
            print( " " );
        }
    }
}

1;

__DATA__

__C__

#include <tiff.h>
#include <geotiff.h>
#include <xtiffio.h>

#define DEBUG 0

typedef struct {
    const char *file;           // Filename
    TIFF *xtif;                 // TIFF image handle
    GTIF *gtif;                 // GeoTIFF image handle
    uint16 bits_per_sample;     // Bits per pixel
    uint16 sample_format;       // Data Type
    uint32 length, width;       // Image length, width in pixels
    uint32 tile_length, tile_width;
                                // Tile length, width in pixels
    tsize_t tile_size;          // Tile size (bytes)
    tsize_t tile_row_size;      // Tile row size (bytes)        
//    uint32 tile_byte_counts;    // Tile size (compressed bytes)
    uint32 tile_step;           // no. of tiles per row (A)croak("TIFFGetField error: TIFFTAG_BITSPERSAMPLE");
    uint32 tiles_across;        // no. of tiles per row (B)
    uint32 tiles_down;          // no. of tiles per col
    uint32 tiles_total;         // no. of tiles (computed)
    ttile_t number_of_tiles;    // no. of tiles (libtiff)
} Image;

static void _read_meta(Image*);
static void _center_pixel(double * x, double * y);
static void _verify_image(Image*);
static void _print_meta(Image*);

//--------------------------------------------------------------------------------------------------
// METADATA

static void _read_meta(Image* image) {
    uint32 width, length, t_width, t_length;
//    uint32 t_byte;
    uint16 bps,fmt;
    
    // Zero-init
    width = length = t_width = t_length = 0;
    bps = fmt = 0;
    
    if ( TIFFGetField(image->xtif,TIFFTAG_BITSPERSAMPLE,&bps) != 1 )
        croak("TIFFGetField error: TIFFTAG_BITSPERSAMPLE");
    if ( TIFFGetFieldDefaulted(image->xtif, TIFFTAG_SAMPLEFORMAT, &fmt) != 1 )
        croak("TIFFGetField error: TIFFTAG_SAMPLEFORMAT");
    image->bits_per_sample = bps;
    image->sample_format = fmt;
    
    if ( TIFFGetField(image->xtif,TIFFTAG_IMAGELENGTH,&length) != 1 )
        croak("TIFFGetField error: TIFFTAG_IMAGELENGTH");
    if ( TIFFGetField(image->xtif,TIFFTAG_IMAGEWIDTH,&width) != 1 )
        croak("TIFFGetField error: TIFFTAG_IMAGEWIDTH");
    image->length = length;
    image->width  = width;

    if ( TIFFGetField(image->xtif,TIFFTAG_TILELENGTH,&t_length) != 1 )
        croak("TIFFGetField error: TIFFTAG_TILELENGTH");
    if ( TIFFGetField(image->xtif,TIFFTAG_TILEWIDTH,&t_width) != 1 )
        croak("TIFFGetField error: TIFFTAG_TILEWIDTH");
    image->tile_width = t_width;
    image->tile_length = t_length;
        
/*    if ( TIFFGetField(image->xtif,TIFFTAG_TILEBYTECOUNTS,&t_byte) != 1 )
        croak("TIFFGetField error: TIFFTAG_TILEBYTECOUNTS");
    image->tile_byte_counts = t_byte; */

    image->tile_size = TIFFTileSize(image->xtif);
    image->tile_row_size = TIFFTileRowSize(image->xtif);
    image->number_of_tiles = TIFFNumberOfTiles(image->xtif);
    
    image->tile_step = 
        TIFFComputeTile( image->xtif, 0, image->tile_length, 0, 0 );
    image->tiles_across = (image->width + image->tile_width - 1)/image->tile_width;
    image->tiles_down = (image->length + image->tile_length - 1)/image->tile_length;
    image->tiles_total = image->tiles_across * image->tiles_down;
    
    if ( DEBUG >= 1 )
        _print_meta(image);
}

//--------------------------------------------------------------------------------------------------
// COORDINATE-PIXEL TRANSFORMATIONS

static void _center_pixel(double * x, double * y) {
    *x = (int)*x + 0.5;
    *y = (int)*y + 0.5;
}

void center_pixel(SV* obj, SV* svx, SV* svy) {
    double x = (double)SvNV(svx);
    double y = (double)SvNV(svy);
    _center_pixel(&x,&y);
    sv_setnv(svx,x);
    sv_setnv(svy,y);
}

void proj2pix_m(SV* obj, SV* svx, SV* svy) {
    // Convert projected coordinates to pixel coordinates (geotiff operation) - MUTATIVE
    Image* image = (Image*)SvIV(SvRV(obj));
    double x = (double)SvNV(svx);
    double y = (double)SvNV(svy);
    
    if ( DEBUG == 2 )
        printf("(proj2pix_m)Converting projected coordinates (%.2f,%.2f) to pixel coordinates: ",x,y);
    
    if ( GTIFPCSToImage(image->gtif, &x, &y) == 0 )
        croak("\n(proj2pix_m)Could not convert geo-coordinates to pixel coordinates.\n");
    
    if ( DEBUG == 2 )
        printf("(%.1f,%.1f)\n",x,y);
    
    sv_setnv(svx,x);
    sv_setnv(svy,y);
}

void proj2pix(SV* obj, SV* svx, SV* svy) {
    // Convert projected coordinates to pixel coordinates (geotiff operation) - TRANSFORMATIVE
    Inline_Stack_Vars;
    SV* svx_cp = sv_mortalcopy(svx);
    SV* svy_cp = sv_mortalcopy(svy);
    
    // Do the mutative operation
    proj2pix_m( obj, svx_cp, svy_cp );
    
    // Push the values of svx_cp, svy_cp onto the stack and return them
    Inline_Stack_Reset;
    Inline_Stack_Push(svx_cp);
    Inline_Stack_Push(svy_cp);
    Inline_Stack_Done;
}

void pix2proj_m(SV* obj, SV* svx, SV* svy) {
    // Convert pixel coordinates to projected coordinates (geotiff operation) - MUTATIVE
    Image* image = (Image*)SvIV(SvRV(obj));
    double x = (double)SvNV(svx);
    double y = (double)SvNV(svy);
    
    if ( DEBUG == 2 )
        printf("(pix2proj_m)Converting pixel coordinates (%.1f,%.1f) to projected coordinates: ",x,y);
    
    if ( GTIFImageToPCS(image->gtif, &x, &y) == 0 )
        croak("\n(pix2proj_m)Could not convert pixel coordinates to geo-coordinates.\n");
    
    if ( DEBUG == 2 )
        printf("(%.2f,%.2f)\n",x,y);
        
    sv_setnv(svx,x);
    sv_setnv(svy,y);
}

void pix2proj(SV* obj, SV* svx, SV* svy) {
    // Convert pixel coordinates to projected coordinates (geotiff operation) - TRANSFORMATIVE
    Inline_Stack_Vars;
    SV* svx_cp = sv_mortalcopy(svx);
    SV* svy_cp = sv_mortalcopy(svy);
    
    // Do the mutative operation
    pix2proj_m( obj, svx_cp, svy_cp );
    
    // Push the values of svx_cp, svy_cp onto the stack and return them
    Inline_Stack_Reset;
    Inline_Stack_Push(svx_cp);
    Inline_Stack_Push(svy_cp);
    Inline_Stack_Done;
}

void proj2pix_boundary_m(SV* obj, SV* svx_min, SV* svy_min, SV* svx_max, SV* svy_max) {
    if ( (double)SvNV(svx_min) > (double)SvNV(svx_max) )
        croak("min X/lon > max X/lon");
    if ( (double)SvNV(svy_min) > (double)SvNV(svy_max) )
        croak("min Y/lat > max Y/lat");
    proj2pix_m(obj,svx_min,svy_max);
    proj2pix_m(obj,svx_max,svy_min);
}

void proj2pix_boundary(SV* obj, SV* svx_min, SV* svy_min, SV* svx_max, SV* svy_max) {
    Inline_Stack_Vars;
    SV* svx_min_cp = sv_mortalcopy(svx_min);
    SV* svy_min_cp = sv_mortalcopy(svy_min);
    SV* svx_max_cp = sv_mortalcopy(svx_max);
    SV* svy_max_cp = sv_mortalcopy(svy_max);
    proj2pix_boundary_m(obj,svx_min_cp,svy_min_cp,svx_max_cp,svy_max_cp);
    Inline_Stack_Reset;
    Inline_Stack_Push(svx_min_cp);
    Inline_Stack_Push(svy_max_cp);
//    Inline_Stack_Push(svy_min_cp);
    Inline_Stack_Push(svx_max_cp);
//    Inline_Stack_Push(svy_max_cp);
    Inline_Stack_Push(svy_min_cp);
    Inline_Stack_Done;
}

//--------------------------------------------------------------------------------------------------
// IMAGE UTILITY

static void _verify_image(Image* image) {
    // Check that it is of a type that we support - if not throw errors
    uint16 bps, spp, fmt;
    bps = image->bits_per_sample;
    fmt = image->sample_format;
    if ( bps == 0 || bps < 8 || bps > 32 ) {
        printf("Bits-per-sample: %d\n",bps);
        croak("Either undefined (0) or unsupported (<8 or >32) number of bits per sample.");
    }
    if ( fmt == 3 && bps == 32 && sizeof(float) != 4 ) {
        printf("sizeof(float) = %d\n",sizeof(float));
        croak("Image data stored in 32-bit floating point - your machine doesn't match! Help!");
    }
    TIFFGetField(image->xtif, TIFFTAG_SAMPLESPERPIXEL, &spp);
    if ( (spp == 0) || (spp != 1) ) {
        printf("Samples-per-pixel: %d\n",spp);
        croak("Either undefined (0) or unsupported (!=1) number of samples per pixel.");
    }
    
    // TODO: relax this condition?
    if ( TIFFIsTiled(image->xtif) == 0 )
        croak("Image must be tiled!");
}

static void _print_meta(Image* image) {
    printf("File: %s\n",(char*)image->file);
    printf("Image width x length: %d x %d\n",
            image->width,image->length);
    printf("Bits per sample (format): %d (%d)\n",
            image->bits_per_sample,image->sample_format);
    printf("Tile width x length: %d x %d = %d pixels\n",
            image->tile_width,image->tile_length,
            image->tile_width*image->tile_length);
    printf("Tile # at pixel (0,%d): %d\n",
            image->tile_length,image->tile_step);
    printf("Tile # at pixel (%d,%d): %d\n",
            image->width-1,image->length-1,
            TIFFComputeTile(
                image->xtif,image->width-1,image->length-1,0,0 )
            );
    printf("Tiles across * down = total: %d * %d = %d\n",
            image->tiles_across, image->tiles_down, image->tiles_total );
    printf("Number of tiles (libtiff): %d\n",
            image->number_of_tiles);
    printf("Tile size (row size): %d (%d)\n",
            image->tile_size,image->tile_row_size);
    /*
    printf("Tile compressed byte-count: %d\n",
            image->tile_byte_counts); */
    printf("\n");
}

void print_meta(SV* obj) {
    Image* image = (Image*)SvIV(SvRV(obj));
    _print_meta(image);
}

//--------------------------------------------------------------------------------------------------
// TILE

void tile2pix_m(SV* obj, int tile, int i, SV* svx, SV* svy) {
    // Given a tile # and index, calculate pixel coordinates (MUTATIVE)
    Image* image = (Image*)SvIV(SvRV(obj));
    double x = (double)SvNV(svx);
    double y = (double)SvNV(svy);
    int tile_lat = tile / image->tile_step;
    int tile_lon = tile % image->tile_step;
    
    // (tile_lon,tile_lat) -> tile location in tile grid
    if ( DEBUG == 2 )
        printf("\tTile coordinates: (%d,%d)\n",tile_lon,tile_lat);
    
    // Now get tile[i] location in pixel grid
    x = (double)(tile_lon * image->tile_width + i % image->tile_width);
    y = (double)(tile_lat * image->tile_length + (int)i / image->tile_length);
    
    if ( DEBUG == 2 )
        printf("\tPixel coordinates (%.f,%.f)\n",x,y);
    
    sv_setnv(svx,x);
    sv_setnv(svy,y);    
}

void tile2pix(SV* obj, int tile, int i) {
    // Given a tile # and index, calculate pixel coordinates (TRANSFORMATIVE)
    Inline_Stack_Vars;
    SV* svx = newSVnv( (double)0 );
    SV* svy = newSVnv( (double)0 );
    
    // Do the mutative operation
    tile2pix_m( obj, tile, i, svx, svy );
    
    // Push the values of svx, svy onto the stack and return them
    Inline_Stack_Reset;
    Inline_Stack_Push(sv_2mortal(svx));
    Inline_Stack_Push(sv_2mortal(svy));
    Inline_Stack_Done;
}

// Computes the tile no. corresonding to a given pixel coordinates
int pix2tile(SV* obj, double x, double y) {
    int tile;
    Image* image = (Image*)SvIV(SvRV(obj));
    
    if ( DEBUG == 2 )
        printf( "Getting tile # for pixel coordinates (%.f,%.f): ", x, y );
        
    // Get the tile #
    tile = TIFFComputeTile( image->xtif, x, y, 0, 0 );
    
    if ( DEBUG == 2 )
        printf("%d\n",tile);
    
    return tile;
}

// Given pixel coordinates, calculate the index into its tile
int pix2tileidx(SV* obj, double dpx, double dpy) {
    Image* image = (Image*)SvIV(SvRV(obj));
    int px = (int)dpx;
    int py = (int)dpy;
    int idx_row = 
        ( py - (py / image->tile_length) * image->tile_length ) 
            * image->tile_length;       // first pixel index in the UL tile row (tile[y_min][0])
    return idx_row + (px % image->tile_width);
                                        // UL boundary pixel index (tile[y_min][x_min])
}

//--------------------------------------------------------------------------------------------------
// DATA

SV* get_raw_tile(SV* obj, int tile) {
    Image* image;
    tdata_t buffer;
    SV* sv_buf;
    int ret;
    image = (Image*)SvIV(SvRV(obj));
    
    // Read in buffer
    buffer = _TIFFmalloc(image->tile_size);
    if ( buffer == NULL )
        croak("Unable to allocate buffer (_TIFFmalloc)");
    _TIFFmemset(buffer,0,image->tile_size);

    ret =
        TIFFReadEncodedTile( 
            image->xtif, 
            tile, 
            buffer,
            image->tile_size );
    if ( ret == -1 )
        croak("Read error on tile (TIFFReadEncodedTile)");

    sv_buf = newSVpv(buffer,image->tile_size);
    _TIFFfree(buffer);
//    sv_2mortal(sv_buf);
    return sv_buf;
}


//--------------------------------------------------------------------------------------------------
// ITERATION

void print_refcnt(SV* ref) {
    if ( DEBUG >= 1 )
        printf( "Reference count of [ref,array]: [%d,%d]\n",
            (int)SvREFCNT(ref),(int)SvREFCNT((SV*)SvRV(ref)) );
}

//--------------------------------------------------------------------------------------------------
// GETTERS

char* file(SV* obj) {
    return (char*)(((Image*)SvIV(SvRV(obj)))->file);
}
int length(SV* obj) {
    return ((Image*)SvIV(SvRV(obj)))->length;
}
int width(SV* obj) {
    return ((Image*)SvIV(SvRV(obj)))->width;
}
int tile_length(SV* obj) {
    return ((Image*)SvIV(SvRV(obj)))->tile_length;
}
int tile_width(SV* obj) {
    return ((Image*)SvIV(SvRV(obj)))->tile_width;
}
int tile_size(SV* obj) {
    return ((Image*)SvIV(SvRV(obj)))->tile_size;
}
int tile_row_size(SV* obj) {
    return ((Image*)SvIV(SvRV(obj)))->tile_row_size;
}
/*
int tile_byte_counts(SV* obj) {
    return ((Image*)SvIV(SvRV(obj)))->tile_byte_counts;
}
*/
int tile_step(SV* obj) {
    return ((Image*)SvIV(SvRV(obj)))->tile_step;
}
int tiles_across(SV* obj) {
    return ((Image*)SvIV(SvRV(obj)))->tiles_across;
}
int tiles_down(SV* obj) {
    return ((Image*)SvIV(SvRV(obj)))->tiles_down;
}
int tiles_total(SV* obj) {
    return ((Image*)SvIV(SvRV(obj)))->tiles_total;
}
int number_of_tiles(SV* obj) {
    return ((Image*)SvIV(SvRV(obj)))->number_of_tiles;
}
int bits_per_sample(SV* obj) {
    return ((Image*)SvIV(SvRV(obj)))->bits_per_sample;
}
int sample_format(SV* obj) {
    return ((Image*)SvIV(SvRV(obj)))->sample_format;
}

//--------------------------------------------------------------------------------------------------
// CONSTRUCTOR

SV* new( char* class, const char* file ) {
    Image* image;
    SV*      obj_ref = newSV(0);
    SV*      obj = newSVrv(obj_ref, class);
    
    New(42, image, 1, Image);
//    Newx(image, 1, Image);
    
    image->file = savepv(file);
    
    // Open the TIFF image
    if ( (image->xtif = XTIFFOpen(file, "r")) == NULL )
        croak("Could not open incoming image");
   
    // Open the geotiff information handle on image
    if ( (image->gtif = GTIFNew(image->xtif)) == NULL )
        croak("Could not read geotiff data on image.");
    
    if ( DEBUG ) setvbuf(stdout, NULL, _IONBF, 0);   // autoflush

    _read_meta(image);
    _verify_image(image);
    
    sv_setiv(obj, (IV)image);
    SvREADONLY_on(obj);
    
    return obj_ref;
}

void DESTROY(SV* obj) {
    Image* image = (Image*)SvIV(SvRV(obj));
    Safefree(image->file);
    GTIFFree(image->gtif);
    XTIFFClose(image->xtif);
    Safefree(image);
}

