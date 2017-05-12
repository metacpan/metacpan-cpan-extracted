#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2015-2017 -- leonerd@leonerd.org.uk

package Device::Chip::SSD1306;

use strict;
use warnings;
use base qw( Device::Chip );

our $VERSION = '0.04';

use Carp;

=encoding UTF-8

=head1 NAME

C<Device::Chip::SSD1306> - chip driver for monochrome OLED modules

=head1 DESCRIPTION

This abstract L<Device::Chip> subclass provides communication to an F<SSD1306>
or F<SH1106> chip attached by an adapter. To actually use it, you should use
one of the subclasses for the various interface types.

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

=item C<SSD1306-128x32>

An F<SSD1306> driving a display with 128 columns and 32 rows. This is the
usual "half-height" display.

=item C<SH1106-128x64>

An F<SH1106> driving a display with 128 columns and 64 rows. This is the chip
that's usually found in the larger display modules, such as 1.3 and 1.6 inch.

=back

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
   )

Returns a new C<Device::Chip::SSD1306> driver instance for the given model
name, which must be one of the models listed in L</DEVICE MODELS>. If no model
option is chosen, the default of C<SSD1306-128x64> will apply.

=cut

sub new
{
   my $class = shift;
   my %args = @_;

   my $self = $class->SUPER::new( %args );

   my $modelargs = $MODELS{ $args{model} // "SSD1306-128x64" }
      or croak "Unrecognised model $args{model}";

   $self->{$_} = $modelargs->{$_} for keys %$modelargs;

   return $self;
}

=head1 METHODS

The following methods documented with a trailing call to C<< ->get >> return
L<Future> instances.

=cut

=head2 rows

=head2 columns

   $n = $chip->rows

   $n = $chip->columns

Simple accessors that return the number of rows or columns present on the
physical display.

=cut

sub rows    { shift->{rows} }
sub columns { shift->{columns} }

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

   $chip->init->get

Initialise the display after reset to some sensible defaults.

=cut

# This initialisation sequence is inspired by the Adafruit driver
#   https://github.com/adafruit/Adafruit_SSD1306

sub init
{
   my $self = shift;

   $self->display( 0 )
      ->then( sub { $self->send_cmd( CMD_SET_CLOCKDIV,     ( 8 << 4 ) | 0x80 ) })
      ->then( sub { $self->send_cmd( CMD_SET_MUX_RATIO,    0x3F ) })
      ->then( sub { $self->send_cmd( CMD_SET_DISPLAY_OFFS, 0 ) })
      ->then( sub { $self->send_cmd( CMD_SET_DISPLAY_START | 0 ) })
      ->then( sub { $self->send_cmd( CMD_SET_CHARGEPUMP,   0x14 ) })
      ->then( sub { $self->send_cmd( CMD_SET_ADDR_MODE,    MODE_HORIZONTAL ) })
      ->then( sub { $self->send_cmd( CMD_SET_SEGMENT_REMAP | 1 ) })
      ->then( sub { $self->send_cmd( CMD_SET_COM_SCAN_DIR  | 0 ) })
      ->then( sub { $self->send_cmd( CMD_SET_COM_PINS,     $self->{set_com_pins_arg} ) })
      ->then( sub { $self->send_cmd( CMD_SET_CONTRAST,     0x9F ) })
      ->then( sub { $self->send_cmd( CMD_SET_PRECHARGE,    ( 0x0f << 4 ) | ( 1 ) ) })
      ->then( sub { $self->send_cmd( CMD_SET_VCOMH_LEVEL,  ( 4 << 4 ) ) });
}

=head2 display

   $chip->display( $on )->get

Turn on or off the display.

=cut

sub display
{
   my $self = shift;
   my ( $on ) = @_;
   $self->send_cmd( $on ? CMD_DISPLAY_ON : CMD_DISPLAY_OFF );
}

=head2 display_lamptest

   $chip->display_lamptest( $enable )->get

Turn on or off the all-pixels-lit lamptest mode.

=cut

sub display_lamptest
{
   my $self = shift;
   my ( $enable ) = @_;

   $self->send_cmd( CMD_DISPLAY_LAMPTEST + !!$enable );
}

=head2 send_display

   $chip->send_display( $pixels )->get

Sends an entire screen-worth of pixel data. The C<$pixels> should be in a
packed binary string containing one byte per 8 pixels.

=cut

sub send_display
{
   my $self = shift;
   my ( $pixels ) = @_;

   # This output method isn't quite what most of the SSD1306 drivers use, but
   # it happens to work on both the SSD1306 and the SH1106, whereas other code
   # based on SET_COLUMN_ADDR + SET_PAGE_ADDR do not

   my $f = Future->done;

   my $pagewidth = $self->columns;

   my $column = $self->{column_offset};

   foreach my $page ( 0 .. ( $self->rows / 8 ) - 1 ) {
      $f = $f->then( sub { $self->send_cmd( CMD_SET_PAGE_START + $page ) } )
         ->then( sub { $self->send_cmd( CMD_SET_LOW_COLUMN | $column & 0x0f ) } )
         ->then( sub { $self->send_cmd( CMD_SET_HIGH_COLUMN | $column >> 4 ) } )
         ->then( sub { $self->send_data( substr $pixels, $page * $pagewidth, $pagewidth ) } );
   }

   return $f;
}

=head1 TODO

=over 4

=item *

More interfaces - 3-wire SPI

=item *

Maintain a framebuffer. Add some drawing commands like pixels and lines.

=back

=cut

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
