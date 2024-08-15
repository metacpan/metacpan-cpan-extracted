#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2019-2024 -- leonerd@leonerd.org.uk

use v5.26;
use warnings;
use Object::Pad 0.800;
use Sublike::Extended;
use Syntax::Keyword::Match;

package Font::PCF 0.04;
class Font::PCF;

use List::Util 1.33 qw( any first );
use PerlIO::gzip;

use IO::Handle::Packable;

use Object::Pad::ClassAttr::Struct 0.04;

=head1 NAME

C<Font::PCF> - read an X11 PCF font file

=head1 SYNOPSIS

   use Font::PCF;

   my $font = Font::PCF->open( "/usr/share/fonts/X11/misc/9x15.pcf.gz" );

   my $glyph = $font->get_glyph_for_char( "A" );

   sub printbits {
      my ( $bits ) = @_;
      while( $bits ) {
         print +( $bits & (1<<31) ) ? '#' : ' ';
         $bits <<= 1;
      }
      print "\n";
   }

   printbits $_ for $glyph->bitmap->@*;

=head1 DESCRIPTION

Instances of this class provide read access to the "PCF" format font files
that are typically found as part of an X11 installation.

This module was written just to be sufficient for generating font bitmaps to
encode in microcontroller programs for display on OLED panels. It is possibly
useful for other use-cases as well, but may required more methods adding.

=cut

# See also
#   http://fileformats.archiveteam.org/wiki/PCF
#   https://fontforge.github.io/en-US/documentation/reference/pcf-format/

class Font::PCF::_Table :Struct {
   field $type;
   field $format;
   field $size;
   field $offset;
}

class Font::PCF::_Glyph :Struct {
   field $bitmap             = [];
   field $left_side_bearing  = undef;
   field $right_side_bearing = undef;
   field $width              = undef;
   field $ascent             = undef;
   field $descent            = undef;
   field $attrs              = undef;
   field $name               = undef;
}

use constant {
   # Table types
   PCF_PROPERTIES       => (1<<0),
   PCF_ACCELERATORS     => (1<<1),
   PCF_METRICS          => (1<<2),
   PCF_BITMAPS          => (1<<3),
   PCF_INK_METRICS      => (1<<4),
   PCF_BDF_ENCODINGS    => (1<<5),
   PCF_SWIDTHS          => (1<<6),
   PCF_GLYPH_NAMES      => (1<<7),
   PCF_BDF_ACCELERATORS => (1<<8),

   # Format types
   PCF_DEFAULT_FORMAT     => 0x00000000,
   PCF_INKBOUNDS          => 0x00000200,
   PCF_ACCEL_W_INKBOUNDS  => 0x00000100,
   PCF_COMPRESSED_METRICS => 0x00000100,

   PCF_FORMAT_MASK        => 0xFFFFFF00,

   # Format modifiers
   PCF_GLYPH_PAD_MASK => (3<<0), # See the bitmap table for explanation
   PCF_BYTE_MASK      => (1<<2), # If set then Most Sig Byte First
   PCF_BIT_MASK       => (1<<3), # If set then Most Sig Bit First
   PCF_SCAN_UNIT_MASK => (3<<4), # See the bitmap table for explanation
};

=head1 CONSTRUCTOR

=cut

=head2 open

   $font = Font::PCF->open( $path )

Opens the PCF file from the given path, and returns a new instance containing
the data from it. Throws an exception if an error occurs.

=cut

# class method
extended sub open ( $class, $path, :$gzip = 0 )
{
   $gzip = 1 if $path =~ m/\.gz$/;

   open my $fh, $gzip ? "<:gzip" : "<", $path or
      die "Cannot open font at $path - $!";
   bless $fh, "IO::Handle::Packable";

   my $self = $class->new( fh => $fh );

   $self->read_data;

   return $self;
}

field $_fh :param;

=head1 METHODS

=cut

method read_data ()
{
   my ( $signature, $table_count ) = $_fh->unpack( "a4 i<" );
   $signature eq "\x01fcp" or die "Invalid signature";

   my @tables = map {
      my @v = $_fh->unpack( "i< i< i< i<" );
      Font::PCF::_Table->new_values( @v );
   } 1 .. $table_count;

   foreach my $table ( @tables ) {
      my $type = $table->type;
      match ( $type : == ) {
         case( PCF_METRICS ) {
            $self->read_metrics_table( $table );
         }
         case( PCF_BITMAPS ) {
            $self->read_bitmaps_table( $table );
         }
         case( PCF_BDF_ENCODINGS ) {
            $self->read_encodings_table( $table );
         }
         case( PCF_GLYPH_NAMES ) {
            $self->read_glyph_names_table( $table );
         }
         default {
            my $size = 4 * int( ( $table->size + 3 ) / 4 );
            print STDERR "TODO: Skipping table type $type of $size bytes\n" unless
               any { $type == $_ } PCF_PROPERTIES, PCF_ACCELERATORS, PCF_INK_METRICS,
                 PCF_SWIDTHS, PCF_BDF_ACCELERATORS;
            $_fh->read( my $tmp, $table->size );
         }
      }
   }
}

method read_metrics_table ( $table )
{
   my ( $format ) = $_fh->unpack( "i<" );
   $format == $table->format or die "Expected format repeated\n";

   my $end = $table->format & PCF_BYTE_MASK ? ">" : "<";
   my $compressed = ( $format & PCF_COMPRESSED_METRICS );

   my $count = $_fh->unpack( $compressed ? "s${end}" : "i${end}" );

   foreach my $index ( 0 .. $count-1 ) {
      my @fields;
      if( $compressed ) {
         @fields = $_fh->unpack( "C5" );
         $_ -= 0x80 for @fields;
         push @fields, 0;
      }
      else {
         @fields = $_fh->unpack( "s${end}5 S${end}" );
      }

      my $glyph = $self->get_glyph( $index );

      $glyph->left_side_bearing  = shift @fields;
      $glyph->right_side_bearing = shift @fields;
      $glyph->width              = shift @fields;
      $glyph->ascent             = shift @fields;
      $glyph->descent            = shift @fields;
      $glyph->attrs              = shift @fields;
   }

   # Pad to a multiple of 4 bytes
   my $total = $compressed ? 2 + $count * 5 : 4 + $count * 10;
   $_fh->read( my $tmp, 4 - ( $total % 4 ) ) if $total % 4;
}

method read_bitmaps_table ( $table )
{
   ( $table->format & PCF_FORMAT_MASK ) == PCF_DEFAULT_FORMAT or
      die "Expected PCF_BITMAPS to be in PCF_DEFAULT_FORMAT\n";

   my $end = $table->format & PCF_BYTE_MASK ? ">" : "<";

   my ( $format, $glyph_count ) = $_fh->unpack( "i< i${end}");
   $format == $table->format or die "Expected format repeated\n";
   # offsets
   my @offsets = $_fh->unpack( "i${end}${glyph_count}" );

   my @sizes = $_fh->unpack( "i${end}4" );
   my $size = $sizes[ $table->format & PCF_GLYPH_PAD_MASK ];

   my $scanunits = ( $table->format & PCF_SCAN_UNIT_MASK ) >> 4;

   # Continue reading chunks of data until we reach the next offset, add
   # data so far to the previous glyph
   my $offset = 0; 
   my $index = 0;
   my $bitmap;
   while( $offset < $size ) {
      if( @offsets and $offset == $offsets[0] ) {
         my $glyph = $self->get_glyph( $index++ );
         $bitmap = $glyph->bitmap;
         shift @offsets;
      }

      push @$bitmap, $_fh->unpack( "I${end}" );
      $offset += 4;
   }
}

field @_encoding_to_glyph;

method read_encodings_table ( $table )
{
   ( $table->format & PCF_FORMAT_MASK ) == PCF_DEFAULT_FORMAT or
      die "Expected PCF_BITMAPS to be in PCF_DEFAULT_FORMAT\n";

   my $end = $table->format & PCF_BYTE_MASK ? ">" : "<";

   my ( $format, $min2, $max2, $min1, $max1, $default ) =
      $_fh->unpack( "i< s$end s$end s$end s$end s$end" );
   $format == $table->format or die "Expected format repeated\n";

   my $indices_count = ( $max2 - $min2 + 1 ) * ( $max1 - $min1 + 1 );

   my @indices = $_fh->unpack( "s${end}${indices_count}" );

   @_encoding_to_glyph = @indices;

   # Pad to a multiple of 4 bytes
   # Header was 2 bytes over so we're 2 off if even number of indices
   $_fh->read( my $tmp, 2 ) if ( $indices_count % 2 ) == 0;
}

method read_glyph_names_table ( $table )
{
   ( $table->format & PCF_FORMAT_MASK ) == PCF_DEFAULT_FORMAT or
      die "Expected PCF_BITMAPS to be in PCF_DEFAULT_FORMAT\n";

   my $end = $table->format & PCF_BYTE_MASK ? ">" : "<";

   my ( $format, $glyph_count ) = $_fh->unpack( "i< i${end}");
   $format == $table->format or die "Expected format repeated\n";

   my @offsets = $_fh->unpack( "i${end}${glyph_count}" );

   my $strlen = $_fh->unpack( "i${end}" );

   # Read this as one big string and cut it by @offsets
   $_fh->read( my $names, $strlen );

   foreach my $index ( 0 .. $#offsets ) {
      my $offset      = $offsets[$index];
      my $next_offset = $offsets[$index + 1] // $strlen;

      # Each glyph name ends with a \0 in the string data

      $self->get_glyph( $index )->name = substr( $names, $offset, $next_offset - $offset - 1 );
   }

   # Pad to a multiple of 4 bytes
   $_fh->read( my $tmp, 4 - ( $strlen % 4 ) ) if $strlen % 4;
}

=head2 get_glyph_for_char

   $glyph = $font->get_glyph_for_char( $char );

Returns a Glyph struct representing the unicode character; given as a
character string.

=cut

method get_glyph_for_char ( $char )
{
   my $index = $_encoding_to_glyph[ ord $char ];
   $index == -1 and
      die "Unmapped character\n";

   return $self->get_glyph( $index );
}

field @_glyphs;

method get_glyph ( $index )
{
   return $_glyphs[$index] //= Font::PCF::_Glyph->new;
}

=head1 GLYPH STRUCTURE

Each glyph structure returned by L</get_glyph_for_char> has the following
methods:

=head2 bitmap

   @bits = $glyph->bitmap->@*

Returns a reference to the array containing lines of the bitmap for this
character. Each line is represented by an integer, where high bits represent
set pixels. The MSB is the leftmost pixel of the character.

=head2 width

   $pixels = $glyph->width

The total number of pixels per line stored in the bitmaps.

=head2 left_side_bearing

=head2 right_side_bearing

   $pixels = $glyph->left_side_bearing

   $pixels = $glyph->right_side_bearing

The number of pixels of bearing (that is, blank pixels of space) to either
side of the character data.

=head2 ascent

=head2 descent

   $pixels = $glyph->ascent

   $pixels = $glyph->descent

The number of pixels above and below the glyph.

=head2 name

   $str = $glyph->name

The PostScript name for the glyph

=cut

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
