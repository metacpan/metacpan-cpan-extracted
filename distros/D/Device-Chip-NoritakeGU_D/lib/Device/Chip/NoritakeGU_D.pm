#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2020 -- leonerd@leonerd.org.uk

use 5.026; # signatures
use Object::Pad 0.27;

package Device::Chip::NoritakeGU_D 0.02;
class Device::Chip::NoritakeGU_D
   extends Device::Chip;

use Carp;

use Future::AsyncAwait;
use List::Util qw( first );

=encoding UTF-8

=head1 NAME

C<Device::Chip::NoritakeGU_D> - chip driver for F<Noritake> F<GU-D> display modules

=head1 SYNOPSIS

   use Device::Chip::NoritakeGU_D;

   my $chip = Device::Chip::NoritakeGU_D->new( interface => "UART" );
   $chip->mount( Device::Chip::Adapter::...->new )->get;

   $chip->text( "Hello, world!" )->get;

=head1 DESCRIPTION

This L<Device::Chip> subclass provides communication to a display module in
the F<GU-D> family by F<Noritake>.

The reader is presumed to be familiar with the general operation of this chip;
the documentation here will not attempt to explain or define chip-specific
concepts or features, only the use of this module to access them.

=cut

=head1 CONSTRUCTOR

=cut

=head2 new

   $chip = Device::Chip::NoritakeGU_D->new(
      interface => $iface,
      ...
   )

Constructs a new driver instance for the given interface type. The type must
be one of C<UART>, C<I2C> or C<SPI>.

=cut

my %INTERFACES = (
   UART => 1, I2C => 1, SPI => 1,
);

has $_protocol;
has $_interface;

BUILD ( %params )
{
   my $interface = delete $params{interface} or
      croak "Require an interface parameter";
   $INTERFACES{$interface} or
      croak "Unrecognised interface type '$interface'";

   $_protocol = $interface;

   my $iface_class = __PACKAGE__."::_Iface::$interface";
   $_interface = $iface_class->new;
}

method PROTOCOL { $_protocol }

*UART_options = *I2C_options = *SPI_options = method { $_interface->options };

# passthrough
method power
{
   return $self->protocol->power( @_ ) if $self->protocol->can( "power" );
   return Future->done;
}

method mount ( $adapter, %params )
{
   $_interface->mountopts( \%params );

   return $self->SUPER::mount( $adapter, %params );
}

method write { $_interface->write( $self, @_ ) }
method read  { $_interface->read ( $self, @_ ) }

method write_us { $self->write( pack "C*", 0x1F, @_ ) }

=head1 METHODS

The following methods documented with a trailing call to C<< ->get >> return
L<Future> instances.

=cut

=head2 text

   $chip->text( $str )->get

Draw text at the cursor position.

=cut

async method text ( $text )
{
   # Don't allow C0 controls
   $text =~ m/[\x00-\x1F]/ and
      croak "Invalid characters for ->text";

   await $self->write( $text );
}

sub BOOL_COMMAND ( $name, @bytes )
{
   my $lastbyte = pop @bytes;

   no strict 'refs';
   *$name = method ( $on ) {
      $self->write_us( @bytes, $lastbyte + !!$on );
   };
}

sub INT_COMMAND ( $name, $min, $max, @bytes )
{
   my $shortname = ( split m/_/, $name )[-1];

   my $lastbyte = pop @bytes;

   no strict 'refs';
   *$name = method ( $value ) {
      $value >= $min and $value <= $max or
         croak "Invalid $shortname for ->$name";

      $self->write_us( @bytes, $lastbyte + $value );
   };
}

sub ENUM_COMMAND ( $name, $values, @bytes )
{
   my @values = @$values;

   my $shortname = ( split m/_/, $name )[-1];

   my $lastbyte = pop @bytes;

   no strict 'refs';
   *$name = method ( $value ) {
      defined( my $index = first { $values[$_] eq $value } 0 .. $#values ) or
         croak "Invalid $shortname for ->$name";

      $self->write_us( @bytes, $lastbyte + $index );
   };
}

=head2 cursor_left

=head2 cursor_right

=head2 cursor_home

   $chip->cursor_left->get
   $chip->cursor_right->get

   $chip->cursor_linehome->get

   $chip->cursor_home->get

Move the cursor left or right one character position, to the beginning of the
line, or to the home position (top left corner).

=cut

method cursor_left     { $self->write( "\x08" ) }
method cursor_right    { $self->write( "\x09" ) }
method cursor_linehome { $self->write( "\x0D" ) }
method cursor_home     { $self->write( "\x0B" ) }

=head2 cursor_goto

   $chip->cursor_goto( $x, $y )->get

Moves the cursor to the C<$x>'th column of the C<$y>'th line (zero-indexed).

=cut

method cursor_goto ( $x, $y )
{
   # TODO: Bounds-check $x, $y

   $self->write( pack "C C S< S<", 0x1F, 0x24, $x, $y );
}

=head2 linefeed

   $chip->linefeed->get

Move the cursor down to the next line.

=cut

method linefeed { $self->write( "\x0A" ) }

=head2 clear

   $chip->clear

Clear the display.

=cut

method clear { $self->write( "\x0C" ) }

=head2 select_window

   $chip->select_window( $win )->get

Select the main window (when C<$win> is 0), or one of the four numbered
sub-windows.

=cut

INT_COMMAND select_window => 0, 4,
   0x10;

=head2 initialise

   $chip->initialise

Reset all settings to their default values.

=cut

method initialise { $self->write( "\x1B\x40" ) }

=head2 set_cursor_visible

   $chip->set_cursor_visible( $bool )->get

Set whether the cursor is visible.

=cut

BOOL_COMMAND set_cursor_visible =>
   0x43, 0x00;

=head2 set_brightness

   $chip->set_brightness( $val )->get

Set the display brightness, from 1 to 8.

=cut

INT_COMMAND set_brightness => 1, 8,
   0x58, 0x00;

=head2 set_reverse

   $chip->set_reverse( $bool )->get

Sets whether subsequent text will be rendered in "reverse video" (clear pixels
on a set background) effect.

=cut

BOOL_COMMAND set_reverse =>
   0x72, 0x00;

=head2 set_write_mixture_display_mode

   $chip->set_write_mixture_display_mode( $mode )->get

Set the combining mode for newly-added display content. C<$mode> must be one
of

   set or and xor

=cut

ENUM_COMMAND set_write_mixture_display_mode => [qw( set or and xor )],
   0x77, 0x00;

=head2 set_font_size

   $chip->set_font_size( $size )->get

Set the font size. C<$size> must be one of

   5x7 8x16

=cut

ENUM_COMMAND set_font_size => [qw( 5x7 8x16 )],
   0x28, 0x67, 0x01, 0x01;

=head2 set_font_width

   $chip->set_font_width( $width )->get

Set the font width. C<$width> must be one of

   fixed fixed2 prop prop2

=cut

ENUM_COMMAND set_font_width => [qw( fixed fixed2 prop prop2 )],
   0x28, 0x67, 0x03, 0x00;

=head2 set_font_magnification

   $chip->set_font_magnification( $xscale, $yscale )->get

Set the font scaling factor. C<$xscale> must be between 1 to 4, and
C<$yscale> must be 1 or 2.

=cut

method set_font_magnification ( $x, $y )
{
   $x >= 1 and $x <= 4 or croak "Invalid x scale";
   $y >= 1 and $y <= 2 or croak "Invalid y scale";

   $self->write_us( 0x28, 0x67, 0x40, $x, $y );
}

method _realtime_image_display ( $width, $height, $bytes )
{
   $self->write( "\x1F\x28\x66\x11" . pack "S< S< C a*",
      $width, $height, 1, $bytes,
   );
}

=head2 realtime_image_display_columns

   $chip->realtime_image_display_columns( @columns )->get

Sends a bitmapped image to the display, at the cursor position. The cursor is
not moved.

C<@columns> should be a list of strings of equal length, containing bytes of
pixel data to represent each vertical column of the image content.

=cut

method realtime_image_display_columns ( @columns )
{
   @columns or croak "Expected at least 1 column";
   my $height = length $columns[0];
   $height == length $_ or croak "Expected all columns of equal length" for @columns[1..$#columns];

   my $bytes = join "", @columns;

   $self->_realtime_image_display( scalar @columns, $height, $bytes );
}

method realtime_image_display_lines ( @lines )
{
   @lines or croak "Expected at least 1 line";
   my $width = length $lines[0];
   $width == length $_ or croak "Expected all lines of equal length" for @lines[1..$#lines];

   # Restripe the data in vertical strips
   my $bytes = join "", map {
      my $col = $_;
      map { substr( $lines[$_], $col, 1 ) } 0 .. $#lines
   } 0 .. $width-1;

   $self->_realtime_image_display( $width, scalar @lines, $bytes );
}

=head2 set_gpio_direction

   $chip->set_gpio_direction( $dir )->get

Configure the GPIO pins for input or output. C<$dir> is bitmask of four bits.
Low bits correspond to input, high bits to output.

=cut

async method set_gpio_direction ( $dir )
{
   await $self->write_us( 0x28, 0x70, 0x01, 0x00, $dir & 0x0F );
}

=head2 set_gpio_output

   $chip->set_gpio_output( $value )->get

Write the value to the GPIO pins.

=cut

async method write_gpio ( $value )
{
   await $self->write_us( 0x28, 0x70, 0x10, 0x00, $value & 0x0F );
}

=head2 read_gpio

   $value = $chip->read_gpio->get

Returns the current state of the GPIO pins.

=cut

async method read_gpio
{
   await $self->write_us( 0x28, 0x70, 0x20, 0x00 );
   my ( $header, $id1, $id2, $value ) = unpack "C4", await $self->read( 4 );

   croak "Expected 0x28 0x70 0x20" unless $header == 0x28 and
      $id1 == 0x70 and $id2 == 0x20;

   return $value;
}

=head2 read_touchswitches

   $switches = $chip->read_touchswitches->get

Reads the status of the panel touch switches. Returns a hash reference whose
keys are the names of the touch areas (C<SW1>, C<SW2>, ...) and values are
booleans indicating whether that area currently detects a touch.

=cut

async method read_touchswitches
{
   await $self->write( "\x1F\x4B\x10" );

   my ( $header, $len, $switches ) = unpack "C C S>", await $self->read( 4 );
   croak sprintf "Expected header = 0x10; got 0x%02X", $header if $header != 0x10;
   croak "Expected length=2, got $len" if $len != 2;

   return {
      map +("SW$_", $switches & ( 2 ** ( $_-1 ) )), 1 .. 16
   };
}

# Interface helpers

class Device::Chip::NoritakeGU_D::_Iface::UART {
   use constant DEFAULT_BAUDRATE => 38400;

   has $_baudrate;

   method mountopts ( $params )
   {
      $_baudrate = delete $params->{baudrate} // DEFAULT_BAUDRATE;
   }

   method options
   {
      return (
         baudrate => $_baudrate,
      );
   }

   async method write ( $chip, $bytes )
   {
      await $chip->protocol->write( $bytes );
   }

   async method read ( $chip, $len )
   {
      return await $chip->protocol->read( $len );
   }
}

class Device::Chip::NoritakeGU_D::_Iface::I2C {
   use constant DEFAULT_ADDR => 0x50;

   has $_addr;

   method mountopts ( $params )
   {
      $_addr = delete $params->{addr} // DEFAULT_ADDR;
   }

   method options
   {
      return (
         addr => $_addr,
      );
   }

   async method write ( $chip, $bytes )
   {
      await $chip->protocol->write( $bytes );
   }

   async method read ( $chip, $len )
   {
      return await $chip->protocol->read( $len );
   }
}

class Device::Chip::NoritakeGU_D::_Iface::SPI {
   method mountopts ( $ ) {}

   method options
   {
      return (
         mode => 0,
         # max_bitrate => 2E6, # min clock period 500ns
         # Need to slow the bitrate down in order to generate inter-word gaps
         max_bitrate => 500E3,
      );
   }

   async method write ( $chip, $bytes )
   {
      await $chip->protocol->write( "\x44" . $bytes );
   }

   async method read ( $chip, $len )
   {
      # TODO:
      #   The datasheet says that after you write a 0x58 byte, the very next byte
      #   you get back will be the status. Experimental testing shows you get an
      #   echo of the 0x58 first, then status.

      my $status = unpack "x C", await $chip->protocol->write_then_read( "\x58", 2 );

      #   The datasheet says that after you write a 0x54 byte, you'll immediately
      #   get 0x00 then the data. Experimental testing suggests that you get an
      #   echo of the 0x54 byte first, then 0x00, then the data.

      my $bytes = await $chip->protocol->write_then_read( "\x54", ( $status & 0x1F ) + 2 );

      return substr $bytes, 2;
   }
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
