#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2022-2023 -- leonerd@leonerd.org.uk

use v5.26;
use warnings;
use Object::Pad 0.800 ':experimental(adjust_params)';

package Device::Chip::MAX7219Panel 0.09;
class Device::Chip::MAX7219Panel
   :isa(Device::Chip);

use Carp;
use Future::AsyncAwait;

use constant PROTOCOL => 'SPI';

=head1 NAME

C<Device::Chip::MAX7219Panel> - chip driver for a panel of F<MAX7219> modules

=head1 SYNOPSIS

   use Device::Chip::MAX7219Panel;
   use Future::AsyncAwait;

   my $chip = Device::Chip::MAX7219Panel->new;
   await $chip->mount( Device::Chip::Adapter::...->new );

   await $chip->init;
   await $chip->intensity( 2 );

   $panel->clear;
   $panel->draw_hline( 0, $panel->columns-1, 2 );
   $panel->draw_vline( 12, 0, $panel->rows-1 );

   await $panel->refresh;

=head1 DESCRIPTION

This L<Device::Chip> subclass provides specific communication to an LED panel
comprised of multiple F<Maxim Integrated> F<MAX7219> or similar chips,
attached to a computer via an SPI adapter. It maintains a virtual frame-buffer
to drive the display in terms of drawing commands.

This module expects to find a chain of F<MAX7219> or similar chips connected
together in a daisy-chain fashion; sharing the C<SCK> and C<CS> signals, and
with each chip's C<DO> feeding into the C<DI> of the next. The chips should be
connected in rows, with the first at top left corner, then across the top row,
with each subsequent row below it in the same manner. For example, when using
8 chips arranged in a 32x16 geometry, the chips would be in the order below:

   1 2 3 4
   5 6 7 8

The overall API shape of this module is similar to that of
L<Device::Chip::SSD1306>, supporting the same set of drawing methods. A future
version of both of these modules may extend the concept into providing access
via an interface helper instance, if some standard API shape is defined for
driving these kinds of 1bpp pixel displays.

=cut

method SPI_options
{
   return (
      mode        => 0,
      max_bitrate => 1E6,
   );
}

use constant {
   REG_NONE      => 0x00,
   REG_DIGIT     => 0x01, # .. to 8
   REG_DECODE    => 0x09,
   REG_INTENSITY => 0x0A,
   REG_LIMIT     => 0x0B,
   REG_SHUTDOWN  => 0x0C,
   REG_DTEST     => 0x0F,
};

field $_nchips;

field $_rows    :reader;
field $_columns :reader;

=head1 CONSTRUCTOR

=head2 new

   $panel = Device::Chip::MAX7219Panel->new( %opts );

Returns a new C<Device::Chip::MAX7219Panel> instance.

The following additional options may be passed:

=over 4

=item geom => STRING

The overall geometry of the display panel, as two integers giving column and
row count expressed as a string C<COLUMNSxROWS>. If not specified, will
default to the common size for cheaply available module panels, of C<32x8>.

Both the column and row count must be a multiple of 8.

=item xflip => BOOL

=item yflip => BOOL

If true, the order of columns or rows respectively will be reversed. In
particular, if both are true, this inverts the orientation of the display, if
it is mounted upside-down.

=back

=cut

ADJUST :params (
   :$geom = "32x8",
) {
   ( $_columns, $_rows ) = $geom =~ m/^(\d+)x(\d+)/ or
      croak "Unable to parse rows/columns from geometry argument $geom";

   ( $_columns % 8 ) == 0 or croak "Expected columns to be a multiple of 8";
   ( $_rows % 8 ) == 0 or croak "Expected rows to be a multiple of 8";

   $_nchips = ( $_rows / 8 ) * ( $_columns / 8 );
}

field $_xflip :param :reader :writer = 0;
field $_yflip :param :reader :writer = 0;

=head1 METHODS

The following methods documented in an C<await> expression return L<Future>
instances.

=cut

=head2 rows

=head2 columns

   $n = $panel->rows;

   $n = $panel->columns;

Simple accessors that return the number of rows or columns present on the
combined physical display panel.

=cut

async method _all_writereg ( $reg, $value )
{
   await $self->protocol->write( join "", ( chr( $reg ) . chr( $value ) ) x $_nchips );
}

=head2 init

   await $panel->init();

Initialises the settings across every chip and ready to be used by this
module. This method should be called once on startup.

=cut

async method init ()
{
   await $self->_all_writereg( REG_LIMIT, 7 );
   await $self->_all_writereg( REG_DECODE, 0 );
}

=head2 intensity

   await $panel->intensity( $value );

Sets the intensity register across every chip. C<$value> must be between 0 and
15, with higher values giving a more intense output.

=cut

async method intensity ( $value )
{
   await $self->_all_writereg( REG_INTENSITY, $value );
}

=head2 shutdown

   await $panel->shutdown( $off = 1 );

Sets the shutdown register across every chip. C<$off> defaults to true, to
turn the panel off. If defined but false (such as C<0>), the panel will be
switched on.

=cut

async method shutdown ( $off = 1 )
{
   await $self->_all_writereg( REG_SHUTDOWN, !$off );
}

=head2 displaytest

   await $panel->displaytest( $on );

Sets the display test register across every chip, overriding the output
control and turning on every LED if set to a true value, or restoring normal
operation if set to false.

=cut

async method displaytest ( $on )
{
   await $self->_all_writereg( REG_DTEST, $on );
}

async method _write_raw ( $d, $data )
{
   await $self->protocol->write( join "",
      map { chr( REG_DIGIT+$d ) . substr( $data, $_, 1 ) } 0 .. ($_nchips-1)
   );
}

### Display buffer and drawing methods

=head1 DRAWING METHODS

The following methods operate on an internal framebuffer stored by the
instance. The user must invoke the L</refresh> method to update the actual
panel chips after calling them.

=cut

field @_display;
field $_is_display_dirty;

=head2 clear

   $panel->clear;

Resets the stored framebuffer to blank.

=cut

method clear ()
{
   @_display = (
      map { [ ( 0 ) x $_columns ] } 1 .. $_rows
   );
   $_is_display_dirty = 1;
}

=head2 draw_pixel

   $panel->draw_pixel( $x, $y, $val = 1 )

Draw the given pixel. If the third argument is calse, the pixel will be
cleared instead of set.

=cut

method draw_pixel ( $x, $y, $val = 1 )
{
   $_display[$y][$x] = $val;
   $_is_display_dirty = 1;
}

=head2 draw_hline

   $panel->draw_hline( $x1, $x2, $y, $val = 1 )

Draw a horizontal line in the given I<$y> row, between the columns I<$x1> and
I<$x2> (inclusive). If the fourth argument is false, the pixels will be
cleared instead of set.

=cut

method draw_hline ( $x1, $x2, $y, $val = 1 )
{
   $_display[$y][$_] = $val for $x1 .. $x2;
   $_is_display_dirty = 1;
}

=head2 draw_vline

   $panel->draw_vline( $x, $y1, $y2, $val = 1 )

Draw a vertical line in the given I<$x> column, between the rows I<$y1> and
I<$y2> (inclusive). If the fourth argument is false, the pixels will be
cleared instead of set.

=cut

method draw_vline ( $x, $y1, $y2, $val = 1 )
{
   $_display[$_][$x] = $val for $y1 .. $y2;
   $_is_display_dirty = 1;
}

=head2 draw_blit

   $panel->draw_blit( $x, $y, @lines );

Draws a bitmap pattern by copying the data given in lines, starting at the
given position.

Each value in I<@lines> should be a string giving a horizontal line of bitmap
data, each character corresponding to a single pixel of the display. Pixels
corresponding to spaces will be left alone, a hyphen will be cleared, and any
other character (for example a C<#>) will be set.

For example, to draw a rightward-pointing arrow:

   $panel->draw_blit( 6, 1,
      "   #  ",
      "   ## ",
      "######",
      "######",
      "   ## ",
      "   #  " );

=cut

method draw_blit ( $x0, $y, @lines )
{
   for( ; @lines; $y++ ) {
      my @pixels = split m//, shift @lines;
      @pixels or next;

      my $x = $x0;
      for( ; @pixels; $x++ ) {
         my $p = shift @pixels;

         $p eq " " ? next :
         $p eq "-" ? ( $_display[$y][$x] = 0 ) :
                     ( $_display[$y][$x] = 1 );

         $_is_display_dirty = 1;
      }
   }
}

=head2 refresh

   await $panel->refresh;

Sends the framebuffer to the panel chips.

=cut

async method refresh ()
{
   return unless $_is_display_dirty;

   await $self->_all_writereg( REG_SHUTDOWN, 0 );

   my @digits;

   # Write rows in reverse order, so the data appears in the right order if $_rows > 8
   foreach my $row ( reverse 0 .. $_rows-1 ) {
      my $data = "";
      my $v = 0;
      foreach my $col ( 0 .. $_columns-1 ) {
         if( !$_xflip ) {
            $v >>= 1;
            $v |= 0x80 if $_display[$row][$col];
         }
         else {
            $v <<= 1;
            $v |= 1 if $_display[$row][$col];
         }

         $data .= chr( $v ), $v = 0 if $col % 8 == 7;
      }

      # Data should be written final chip first in normal circumstances
      $data = reverse $data unless $_xflip;

      $digits[$row % 8] .= $data;
   }

   foreach my $digit ( 0 .. 7 ) {
      await $self->_write_raw( $_yflip ? $digit : ( 7 - $digit ), $digits[$digit] );
   }

   await $self->_all_writereg( REG_SHUTDOWN, 1 );
   $_is_display_dirty = 0;
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
