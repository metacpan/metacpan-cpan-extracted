#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2016-2020 -- leonerd@leonerd.org.uk

use v5.26;
use Object::Pad 0.19;

package Device::Chip::TSL256x 0.03;
class Device::Chip::TSL256x
   extends Device::Chip;

use Data::Bitfield qw( bitfield enumfield );
use Future;
use Future::AsyncAwait;

use constant PROTOCOL => "I2C";

=encoding UTF-8

=head1 NAME

C<Device::Chip::TSL256x> - chip driver for F<TSL256x>

=head1 SYNOPSIS

   use Device::Chip::TSL256x;
   use Future::AsyncAwait;

   my $chip = Device::Chip::TSL256x->new;
   await $chip->mount( Device::Chip::Adapter::...->new );

   await $chip->power(1);

   sleep 1; # Wait for one integration cycle

   printf "Current ambient light level is %.2f lux\n",
      scalar await $chip->read_lux;

=head1 DESCRIPTION

This L<Device::Chip> subclass provides specific communication to a F<TAOS>
F<TSL2560> or F<TSL2561> attached to a computer via an I²C adapter.

The reader is presumed to be familiar with the general operation of this chip;
the documentation here will not attempt to explain or define chip-specific
concepts or features, only the use of this module to access them.

=cut

method I2C_options
{
   return (
      addr        => 0x39,
      max_bitrate => 100E3,
   );
}

use constant {
   # Mask bits for the command byte
   CMD_MASK  => 1<<7,
   CMD_CLEAR => 1<<6,
   CMD_WORD  => 1<<5,
   CMD_BLOCK => 1<<4,
};

use constant {
   REG_CONTROL    => 0x00,
   REG_TIMING     => 0x01,
   REG_THRESHLOW  => 0x02, # 16bit
   REG_THRESHHIGH => 0x04, # 16bit
   REG_INTERRUPT  => 0x06,
   REG_ID         => 0x0A,
   REG_DATA0      => 0x0C, # 16bit
   REG_DATA1      => 0x0E, # 16bit
};

bitfield { format => "bytes-LE" }, TIMING =>
   GAIN  => enumfield( 4, qw( 1 16 )),
   INTEG => enumfield( 0, qw( 13ms 101ms 402ms ));

async method _read ( $addr, $len )
{
   return await $self->protocol->write_then_read(
      ( pack "C", CMD_MASK | ( $addr & 0x0f ) ), $len
   );
}

async method _write ( $addr, $data )
{
   await $self->protocol->write(
      pack "C a*", CMD_MASK | ( $addr & 0x0f ), $data
   );
}

=head1 ACCESSORS

The following methods documented in an C<await> expression return L<Future>
instances.

=cut

=head2 read_config

   $config = await $chip->read_config;

Returns a C<HASH> reference of the contents of timing control register, using
fields named from the data sheet.

   GAIN  => 1 | 16
   INTEG => 13ms | 101ms | 420ms

=head2 change_config

   await $chip->change_config( %changes );

Writes updates to the timing control register.

Note that these two methods use a cache of configuration bytes to make
subsequent modifications more efficient. This cache will not respect the
"one-shot" nature of the C<Manual> bit.

=cut

has $_TIMINGbytes;

async method _cached_read_TIMING ()
{
   return $_TIMINGbytes //= await $self->_read( REG_TIMING, 1 );
}

async method read_config ()
{
   return { unpack_TIMING( await $self->_cached_read_TIMING ) };
}

async method change_config ( %changes )
{
   my $config = await $self->read_config;

   $config->{$_} = $changes{$_} for keys %changes;

   my $TIMING = $_TIMINGbytes = pack_TIMING( %$config );

   await $self->_write( REG_TIMING, $TIMING );
}

=head2 read_id

   $id = await $chip->read_id;

Returns the chip's ID register value.

=cut

async method read_id ()
{
   return unpack "C", await $self->_read( REG_ID, 1 );
}

=head2 read_data0

=head2 read_data1

   $data0 = await $chip->read_data0;

   $data1 = await $chip->read_data1;

Reads the current values of the ADC channels.

=cut

async method read_data0 ()
{
   return unpack "S<", await $self->_read( REG_DATA0, 2 );
}

async method read_data1 ()
{
   return unpack "S<", await $self->_read( REG_DATA1, 2 );
}

=head2 read_data

   ( $data0, $data1 ) = await $chip->read_data;

Read the current values of both ADC channels in a single I²C transaction.

=cut

async method read_data ()
{
   return unpack "S< S<", await $self->_read( REG_DATA0, 4 );
}

=head1 METHODS

=cut

=head2 power

   await $chip->power( $on );

Enables or disables the main power control bits in the C<CONTROL> register.

=cut

async method power ( $on )
{
   await $self->_write( REG_CONTROL, $on ? "\x03" : "\x00" );
}

=head2 read_lux

   $lux = await $chip->read_lux;

   ( $lux, $data0, $data1 ) = await $chip->read_lux;

Reads the two data registers then performs the appropriate scaling
calculations to return a floating-point number that approximates the light
level in Lux.

Currently this conversion code presumes the contants for the T, FN and CL
chip types.

In list context, also returns the raw C<$data0> and C<$data1> channel values.
The controlling code may wish to use these to adjust the gain if required.

=cut

my %INTEG_to_msec = (
   '13ms'  => 13.7,
   '101ms' => 101,
   '402ms' => 402,
);

async method read_lux ()
{
   my ( $data0, $data1, $config ) = await Future->needs_all(
      $self->read_data,
      $self->read_config,
   );

   my $gain = $config->{GAIN};
   my $msec = $INTEG_to_msec{ $config->{INTEG} };

   my $ch0 = $data0 * ( 16 / $gain ) * ( 402 / $msec );
   my $ch1 = $data1 * ( 16 / $gain ) * ( 402 / $msec );

   my $ratio = $ch1 / $ch0;

   # TODO: take account of differing package types.

   my $lux;
   if( $ratio <= 0.52 ) {
      $lux = 0.0304 * $ch0 - 0.062 * $ch0 * ( $ratio ** 1.4 );
   }
   elsif( $ratio <= 0.65 ) {
      $lux = 0.0224 * $ch0 - 0.031 * $ch1;
   }
   elsif( $ratio <= 0.80 ) {
      $lux = 0.0128 * $ch0 - 0.0153 * $ch1;
   }
   elsif( $ratio <= 1.30 ) {
      $lux = 0.00146 * $ch0 - 0.00112 * $ch1;
   }
   else {
      $lux = 0;
   }

   return $lux if !wantarray;
   return $lux, $data0, $data1;
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
