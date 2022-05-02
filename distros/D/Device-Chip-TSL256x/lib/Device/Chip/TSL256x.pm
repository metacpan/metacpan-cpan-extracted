#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2016-2021 -- leonerd@leonerd.org.uk

use v5.26;
use Object::Pad 0.57;

package Device::Chip::TSL256x 0.07;
class Device::Chip::TSL256x
   :isa(Device::Chip);

use Device::Chip::Sensor -declare;

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

bitfield { format => "bytes-LE" }, CONFIG =>
   POWER => enumfield(     0, qw( OFF . . ON )),
   GAIN  => enumfield( 1*8+4, qw( 1 16 )),
   INTEG => enumfield( 1*8+0, qw( 13ms 101ms 402ms ));

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

Returns a C<HASH> reference of the contents of control and timing registers,
using fields named from the data sheet.

   POWER => OFF | ON
   GAIN  => 1 | 16
   INTEG => 13ms | 101ms | 402ms

Additionally, the following keys are provided calculated from those, as a
convenience.

   integ_msec => 13.7 | 101 | 402

=head2 change_config

   await $chip->change_config( %changes );

Writes updates to the control and timing registers.

Note that this method will ignore the C<integ_msec> convenience value.

Note that these two methods use a cache of configuration bytes to make
subsequent modifications more efficient. This cache will not respect the
"one-shot" nature of the C<Manual> bit.

=cut

has $_CONTROLbyte;
has $_TIMINGbyte;

my %INTEG_to_msec = (
   '13ms'  => 13.7,
   '101ms' => 101,
   '402ms' => 402,
);

async method read_config ()
{
   my %config = unpack_CONFIG( pack "a1 a1",
      $_CONTROLbyte //= await $self->_read( REG_CONTROL, 1 ),
      $_TIMINGbyte  //= await $self->_read( REG_TIMING, 1 ),
   );

   $config{integ_msec} = $INTEG_to_msec{ $config{INTEG} };

   return \%config;
}

async method change_config ( %changes )
{
   my $config = await $self->read_config;

   $config->{$_} = $changes{$_} for keys %changes;

   delete $config->{integ_msec};

   my ( $CONTROL, $TIMING ) = unpack "a1 a1", pack_CONFIG( %$config );

   if( $CONTROL ne $_CONTROLbyte ) {
      await $self->_write( REG_CONTROL, $_CONTROLbyte = $CONTROL );
   }
   if( $TIMING ne $_TIMINGbyte ) {
      await $self->_write( REG_TIMING, $_TIMINGbyte = $TIMING );
   }
}

async method initialize_sensors ()
{
   await $self->power( 1 );

   $self->enable_agc( 1 );

   # Wait for one integration cycle
   await $self->protocol->sleep( ( await $self->read_config )->{integ_msec} / 1000 );
}

=head2 enable_agc

   $chip->enable_agc( $agc )

Accessor for the internal gain-control algorithm. If enabled, the C<GAIN>
configuration will be automatically controlled to switch between high- and
low-level settings.

=cut

has $_agc_enabled;

method enable_agc ( $agc )
{
   $_agc_enabled = $agc;
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
   await $self->_write( REG_CONTROL, $_CONTROLbyte = ( $on ? "\x03" : "\x00" ) );
}

declare_sensor light =>
   method    => "read_lux",
   units     => "lux",
   precision => 2;

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

has $_smallcount;

async method read_lux ()
{
   my ( $data0, $data1, $config ) = await Future->needs_all(
      $self->read_data,
      $self->read_config,
   );

   my $gain = $config->{GAIN};
   my $msec = $config->{integ_msec};

   my $ch0 = $data0 * ( 16 / $gain ) * ( 402 / $msec );
   my $ch1 = $data1 * ( 16 / $gain ) * ( 402 / $msec );

   my $lux = 0;

   if( $ch0 != 0 ) {
      my $ratio = $ch1 / $ch0;

      # TODO: take account of differing package types.

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

      my $saturation = ( $msec == 402 ) ? 0xFFFF :
                       ( $msec == 101 ) ? 0x9139 : 0x13B7;

      # Detect sensor saturation
      if( $data0 == $saturation or $data1 == $saturation ) {
         # The sensor saturates at well under 50klux
         $lux = 50_000;
      }
   }

   if( $_agc_enabled ) {
      if( $gain == 1 and $data0 < 0x0800 and $data1 < 0x0800 ) {
         $_smallcount++;
         await $self->change_config( GAIN => 16 ) if $_smallcount >= 4;
      }
      else {
         $_smallcount = 0;
      }

      if( $gain == 16 and ( $data0 > 0x8000 or $data1 > 0x8000 ) ) {
         await $self->change_config( GAIN => 1 );
      }
   }

   return $lux if !wantarray;
   return $lux, $data0, $data1;
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
