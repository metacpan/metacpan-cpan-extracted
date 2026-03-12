#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2015-2026 -- leonerd@leonerd.org.uk

use v5.26;
use warnings;
use Object::Pad 0.800 ':experimental(adjust_params)';

package Device::Chip::SSD1306 0.16;
class Device::Chip::SSD1306
   :isa(Device::Chip)
   :strict(params);

use Carp;
use Future::AsyncAwait;

require XSLoader;
XSLoader::load( __PACKAGE__, our $VERSION );

=encoding UTF-8

=head1 NAME

C<Device::Chip::SSD1306> - chip driver for monochrome OLED modules

=head1 DESCRIPTION

=for highlighter language=perl

This abstract L<Device::Chip> subclass provides communication to an
F<SSD1306>, F<SSD1309> or F<SH1106> chip attached by an adapter. To actually
use it, you should use one of the subclasses for the various interface types.

=over 4

=item *

L<Device::Chip::SSD1306::I2C> - I²C

=item *

L<Device::Chip::SSD1306::SPI4> - 4-wire SPI

=back

The reader is presumed to be familiar with the general operation of this chip;
the documentation here will not attempt to explain or define chip-specific
concepts or features, only the use of this module to access them.

=cut

=head1 DEVICE MODELS

This module supports a variety of actual chip modules with different display
sizes. The specific display module is selected by the C<model> argument to the
constructor, which should take one of the following values:

=over 4

=item C<SSD1306-128x64>

An F<SSD1306> driving a display with 128 columns and 64 rows. The most common
of the display modules, often found with a 0.96 inch display.

This setting also drives the F<SSD1309> chip found in the larger 1.6 or 2.4
inch displays.

=item C<SSD1306-128x32>

An F<SSD1306> driving a display with 128 columns and 32 rows. This is the
usual "half-height" module, often found with a 0.91 inch display. This uses
only even-numbered rows.

=item C<SSD1306-64x32>

An F<SSD1306> driving a display with 64 columns and 32 rows. This is the usual
"quarter" size module, often found with a 0.49 inch display. This uses the
only the middle 64 columns.

=item C<SH1106-128x64>

An F<SH1106> driving a display with 128 columns and 64 rows. This is the chip
that's usually found in the larger display modules, such as 1.3 and 1.6 inch.

=back

The overall API shape of this module is similar to that of
L<Device::Chip::MAX7219Panel>, supporting the same set of drawing methods. A
future version of both of these modules may extend the concept into providing
access via an interface helper instance, if some standard API shape is defined
for driving these kinds of 1bpp pixel displays.

=cut

my %MODELS = (
   "SSD1306-128x64" => {
      columns => 128,
      rows    => 64,

      set_com_pins_arg => 0x12,
      column_offset    => 0,
   },
   "SSD1306-128x32" => {
      columns => 128,
      rows    => 32,

      set_com_pins_arg => 0x02,
      column_offset    => 0,
   },
   "SSD1306-64x32" => {
      columns => 64,
      rows    => 32,

      set_com_pins_arg => 0x12,
      # This module seems to use the middle 64 column pins
      column_offset    => 32,
   },
   "SH1106-128x64" => {
      columns => 128,
      rows    => 64,

      set_com_pins_arg => 0x12,
      # SH1106 has a 128 column physical display but its VRAM is 132 columns
      #   wide; with two blank columns either side of the display. It actually
      #   starts outputting from column 2;
      column_offset    => 2,
   },
);

=head1 CONSTRUCTOR

=cut

=head2 new

   $chip = Device::Chip::SSD1306->new(
      model => $model,
      ...
   );

Returns a new C<Device::Chip::SSD1306> driver instance for the given model
name, which must be one of the models listed in L</DEVICE MODELS>. If no model
option is chosen, the default of C<SSD1306-128x64> will apply.

In addition to C<model>, the following named options may also be passed:

=over 4

=item xflip => BOOL

=item yflip => BOOL

If true, the order of columns or rows respectively will be reversed by the
hardware. In particular, if both are true, this inverts the orientation of
the display, if it is mounted upside-down.

=item contrast => INT

Normally set to 0x9F, but you may wish to set a lower value to avoid display
burn-in on rarely-updated static displays.

=item vcomh => INT

Normally set to 4, but you may wish to set a lower value to avoid display
burn-in on rarely-updated static displays.

=back

=cut

field $_rows :reader;
field $_columns :reader;

field $_column_offset;
field $_set_com_pins_arg;
field $_xflip            :param = 0;
field $_yflip            :param = 0;

field $_contrast :param = 0x9F;
field $_vcomh    :param = 4;

ADJUST :params ( :$model = "SSD1306-128x64" )
{
   my $modelargs = $MODELS{$model} or croak "Unrecognised model $model";

   ( $_rows, $_columns, $_column_offset, $_set_com_pins_arg ) =
      @{$modelargs}{qw( rows columns column_offset set_com_pins_arg )};
}

=head1 METHODS

The following methods documented in an C<await> expression return L<Future>
instances.

=cut

=head2 rows

=head2 columns

   $n = $chip->rows;

   $n = $chip->columns;

Simple accessors that return the number of rows or columns present on the
physical display.

=cut

use constant {
   CMD_SET_CONTRAST      => 0x81, #    , contrast
   CMD_DISPLAY_LAMPTEST  => 0xA4, # + all on
   CMD_DISPLAY_INVERT    => 0xA6, # + invert
   CMD_DISPLAY_OFF       => 0xAE, #
   CMD_DISPLAY_ON        => 0xAF, #

   CMD_SCROLL_RIGHT      => 0x26, #    , 0, start page, time, end page, 0, 0xff
   CMD_SCROLL_LEFT       => 0x27, #    , 0, start page, time, end page, 0, 0xff
   CMD_SCROLL_VERT_RIGHT => 0x29, #    , 0, start page, time, end page, vertical
   CMD_SCROLL_VERT_LEFT  => 0x2A, #    , 0, start page, time, end page, vertical
   CMD_SCROLL_DEACTIVATE => 0x2E, #
   CMD_SCROLL_ACTIVATE   => 0x2F, #
   CMD_SET_SCROLL_AREA   => 0xA3, #    , start row, scroll rows

   CMD_SET_LOW_COLUMN  => 0x00, # + column
   CMD_SET_HIGH_COLUMN => 0x10, # + column
   CMD_SET_ADDR_MODE   => 0x20, #    , mode
      MODE_HORIZONTAL     => 0,
      MODE_VERTICAL       => 1,
      MODE_PAGE           => 2,
   CMD_SET_COLUMN_ADDR => 0x21, #    , start column, end column
   CMD_SET_PAGE_ADDR   => 0x22, #    , start page, end page
   CMD_SET_PAGE_START  => 0xB0, # + page

   CMD_SET_DISPLAY_START => 0x40, # + line
   CMD_SET_SEGMENT_REMAP => 0xA0, # + remap
   CMD_SET_MUX_RATIO     => 0xA8, #    , mux
   CMD_SET_COM_SCAN_DIR  => 0xC0, # + direction(8)
   CMD_SET_DISPLAY_OFFS  => 0xD3, #    , line offset
   CMD_SET_COM_PINS      => 0xDA, #    , (config << 4) | 0x02

   CMD_SET_CLOCKDIV    => 0xD5, #   , (freq << 4) | (divratio)
   CMD_SET_PRECHARGE   => 0xD9, #   , (ph1 << 4) | (ph2)
   CMD_SET_VCOMH_LEVEL => 0xDB, #   , (level << 4)
   CMD_SET_CHARGEPUMP  => 0x8D, #   , 0x10 | (enable << 2)

   CMD_NOP             => 0xE3,
};

=head2 init

   await $chip->init;

Initialise the display after reset to some sensible defaults.

=cut

# This initialisation sequence is inspired by the Adafruit driver
#   https://github.com/adafruit/Adafruit_SSD1306

async method init ()
{
   await $self->display( 0 );
   await $self->send_cmd( CMD_SET_CLOCKDIV,     ( 8 << 4 ) | 0x80 );
   await $self->send_cmd( CMD_SET_MUX_RATIO,    $_rows - 1 );
   await $self->send_cmd( CMD_SET_DISPLAY_OFFS, 0 );
   await $self->send_cmd( CMD_SET_DISPLAY_START | 0 );
   await $self->send_cmd( CMD_SET_CHARGEPUMP,   0x14 );
   await $self->send_cmd( CMD_SET_ADDR_MODE,    MODE_HORIZONTAL );
   await $self->send_cmd( CMD_SET_SEGMENT_REMAP | ( $_xflip ? 1 : 0 ) );
   await $self->send_cmd( CMD_SET_COM_SCAN_DIR  | ( $_yflip ? 1<<3 : 0 ) );
   await $self->send_cmd( CMD_SET_COM_PINS,     $_set_com_pins_arg );
   await $self->send_cmd( CMD_SET_CONTRAST,     $_contrast );
   await $self->send_cmd( CMD_SET_PRECHARGE,    ( 0x0f << 4 ) | ( 1 ) );
   await $self->send_cmd( CMD_SET_VCOMH_LEVEL,  ( $_vcomh << 4 ) );
}

=head2 display

   await $chip->display( $on );

Turn on or off the display.

=cut

async method display ( $on )
{
   await $self->send_cmd( $on ? CMD_DISPLAY_ON : CMD_DISPLAY_OFF );
}

=head2 display_lamptest

   await $chip->display_lamptest( $enable );

Turn on or off the all-pixels-lit lamptest mode.

=cut

async method display_lamptest ( $enable )
{
   await $self->send_cmd( CMD_DISPLAY_LAMPTEST + !!$enable );
}

=head2 display_invert

   await $chip->display_invert( $enable );

Turn on or off the inverted output mode.

=cut

async method display_invert ( $enable )
{
   await $self->send_cmd( CMD_DISPLAY_INVERT + !!$enable );
}

=head2 send_display

   await $chip->send_display( $pixels );

Sends an entire screen-worth of pixel data. The C<$pixels> should be in a
packed binary string containing one byte per 8 pixels.

=cut

async method send_display ( $pixels )
{
   # This output method isn't quite what most of the SSD1306 drivers use, but
   # it happens to work on both the SSD1306 and the SH1106, whereas other code
   # based on SET_COLUMN_ADDR + SET_PAGE_ADDR do not

   my $pagewidth = $_columns;

   my $column = $_column_offset;

   foreach my $page ( 0 .. ( $_rows / 8 ) - 1 ) {
      await $self->send_cmd( CMD_SET_PAGE_START + $page );
      await $self->send_cmd( CMD_SET_LOW_COLUMN | $column & 0x0f );
      await $self->send_cmd( CMD_SET_HIGH_COLUMN | $column >> 4 );
      await $self->send_data( substr $pixels, $page * $pagewidth, $pagewidth );
   }
}

=head1 DRAWING METHODS

The following methods operate on an internal framebuffer stored by the
instance. The user must invoke the L</refresh> method to update the actual
chip after calling them.

=cut

# The internal framebuffer is now implemented by XS code, we just need an SV
# to attach it to
field $_framebuffer;
method DESTROY
{
   $_framebuffer and _framebuffer_free( $_framebuffer );
}

=head2 clear

   $chip->clear;

Resets the stored framebuffer to blank.

=cut

method clear ()
{
   $_framebuffer or
      _framebuffer_new( $_framebuffer, $_rows, $_columns );

   _framebuffer_clear( $_framebuffer );
}

=head2 draw_pixel

   $chip->draw_pixel( $x, $y, $val = 1 );

Draw the given pixel. If the third argument is false, the pixel will be
cleared instead of set.

=cut

method draw_pixel ( $x, $y, $val = 1 )
{
   $_framebuffer or
      _framebuffer_new( $_framebuffer, $_rows, $_columns );

   _framebuffer_draw_pixel( $_framebuffer, $x, $y, $val );
}

=head2 draw_hline

   $chip->draw_hline( $x1, $x2, $y, $val = 1 );

Draw a horizontal line in the given I<$y> row, between the columns I<$x1> and
I<$x2> (inclusive). If the fourth argument is false, the pixels will be
cleared instead of set.

=cut

method draw_hline ( $x1, $x2, $y, $val = 1 )
{
   $_framebuffer or
      _framebuffer_new( $_framebuffer, $_rows, $_columns );

   _framebuffer_draw_hline( $_framebuffer, $x1, $x2, $y, $val );
}

=head2 draw_vline

   $chip->draw_vline( $x, $y1, $y2, $val = 1 );

Draw a vertical line in the given I<$x> column, between the rows I<$y1> and
I<$y2> (inclusive). If the fourth argument is false, the pixels will be
cleared instead of set.

=cut

method draw_vline ( $x, $y1, $y2, $val = 1 )
{
   $val //= 1;

   $_framebuffer or
      _framebuffer_new( $_framebuffer, $_rows, $_columns );

   _framebuffer_draw_vline( $_framebuffer, $x, $y1, $y2, $val );
}

=head2 draw_rect

   $chip->draw_rect( $x1, $y1, $x2, $y2, $val = 1 );

I<Since version 0.15.>

Draw a solid rectangle in between the given I<$x1> to I<$2> columns and rows
I<$y1> to I<$y2> (all inclusive). If the final argument is false, the pixels
will be cleared instead of set.

=cut

method draw_rect ( $x1, $y1, $x2, $y2, $val = 1 )
{
   $_framebuffer or
      _framebuffer_new( $_framebuffer, $_rows, $_columns );

   _framebuffer_draw_rect( $_framebuffer, $x1, $y1, $x2, $y2, $val );
}

=head2 draw_blit

   $chip->draw_blit( $x, $y, @lines );

Draws a bitmap pattern by copying the data given in lines, starting at the
given position.

Each value in C<@lines> should be a string giving a horizontal line of bitmap
data, each character corresponding to a single pixel of the display. Pixels
corresponding to a spaces will be left alone, a hyphen will be cleared, and
any other character (for example a C<#>) will be set.

For example, to draw an rightward-pointing arrow:

   $chip->draw_blit( 20, 40,
      "   #  ",
      "   ## ",
      "######",
      "######",
      "   ## ",
      "   #  " );

=cut

method draw_blit ( $x0, $y, @lines )
{
   $_framebuffer or
      _framebuffer_new( $_framebuffer, $_rows, $_columns );

   # TODO: more efficient in XS, somehow...?
   for( ; @lines; $y++ ) {
      my @pixels = split m//, shift @lines;
      @pixels or next;

      my $x = $x0;
      for( ; @pixels; $x++ ) {
         my $p = shift @pixels;

         $p eq " " ? next :
         $p eq "-" ? _framebuffer_draw_pixel( $_framebuffer, $x, $y, 0 ) :
                     _framebuffer_draw_pixel( $_framebuffer, $x, $y, 1 );
      }
   }
}

=head2 draw_glyph

   $chip->draw_glyph( $x, $y, $glyph, $val = 1, $bg = undef );

I<Since version 0.15.>

Draws a glyph by copying the bitmap data out of the C<$glyph> argument, as if
it were a single glyph structure obtained from L<Font::PCF>. The bitmap is
copied starting at the given position, and extends rightward and downward for
whatever is the defined size of the glyph given by its data. For each pixel
set in the glyph's bitmap, the corresponding pixel of the display is set to
C<$val>; the other pixels are set to C<$bg>. Either of these last two values
may be set to C<undef> to not modify those corresponding pixels.

Note that neither this module nor its tests actually depend on C<Font::PCF>
itself; it merely invokes methods on the object consistent with that API.
Specifically, it expects the following methods:

=over 4

=item width

   $cols = $glyph->width;

Returns the number of columns wide that contain pixels of glyph data.

=item bitmap

   [ $row0, $row1, ... ] = $glyph->bitmap;

Returns an C<ARRAY> reference of rows of pixel data. Each row is represented
by a big-endian 32bit integer. The topmost bit corresponds to the leftmost
pixel.

=back

=cut

method draw_glyph ( $x0, $y0, $glyph, $val = 1, $bg = undef )
{
   my $bitmap = $glyph->bitmap;
   my $width_1 = $glyph->width - 1;

   $_framebuffer or
      _framebuffer_new( $_framebuffer, $_rows, $_columns );

   # TODO: more efficient in XS, somehow...?
   foreach my $row ( 0 .. $#$bitmap ) {
      my $pixels = $bitmap->[$row];
      my $y = $y0 + $row;

      foreach my $col ( 0 .. $width_1 ) {
         # $pixels is 32bit big-endian
         my $update = ( $pixels & (1<<(31-$col)) ) ? $val : $bg;
         _framebuffer_draw_pixel( $_framebuffer, $x0+$col, $y, $update ) if defined $update;
      }
   }
}

=head2 refresh

   await $chip->refresh;

Sends the framebuffer to the display chip.

=cut

async method refresh ()
{
   $_framebuffer or
      return; # nothing to do

   my $maxcol = $_columns - 1;
   my ( $dirty_xlo, $dirty_xhi ) = _framebuffer_dirty_xlohi( $_framebuffer );
   my $column = $_column_offset + $dirty_xlo;

   foreach my $page ( 0 .. ( $_rows / 8 ) - 1 ) {
      next unless _framebuffer_is_dirty_page( $_framebuffer, $page );

      my $data = _framebuffer_pagedata( $_framebuffer, $page, $dirty_xlo, $dirty_xhi );

      await $self->send_cmd( CMD_SET_PAGE_START + $page );
      await $self->send_cmd( CMD_SET_LOW_COLUMN | $column & 0x0f );
      await $self->send_cmd( CMD_SET_HIGH_COLUMN | $column >> 4 );
      await $self->send_data( $data );
   }

   _framebuffer_cleaned( $_framebuffer );
}

=head1 TODO

=over 4

=item *

More interfaces - 3-wire SPI

=back

=cut

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
