#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2015-2022 -- leonerd@leonerd.org.uk

use v5.26;
use Object::Pad 0.66;

package Device::Chip::MPL3115A2 0.12;
class Device::Chip::MPL3115A2
   :isa(Device::Chip::Base::RegisteredI2C);

use utf8;

use Carp;

use Future::AsyncAwait;

use Data::Bitfield 0.02 qw( bitfield boolfield enumfield );

use Device::Chip::Sensor 0.23 -declare;

=encoding UTF-8

=head1 NAME

C<Device::Chip::MPL3115A2> - chip driver for a F<MPL3115A2>

=head1 SYNOPSIS

   use Device::Chip::MPL3115A2;
   use Future::AsyncAwait;

   my $chip = Device::Chip::MPL3115A2->new;
   await $chip->mount( Device::Chip::Adapter::...->new );

   printf "Current pressure is %.2f kPa\n",
      await $chip->read_pressure;

=head1 DESCRIPTION

This L<Device::Chip> subclass provides specific communication to a
F<Freescale Semiconductor> F<MPL3115A2> attached to a computer via an I²C
adapter.

The reader is presumed to be familiar with the general operation of this chip;
the documentation here will not attempt to explain or define chip-specific
concepts or features, only the use of this module to access them.

=cut

method I2C_options
{
   return (
      # This device has a constant address
      addr        => 0x60,
      max_bitrate => 100E3,
   );
}

use constant WHO_AM_I_ID => 0xC4;

use constant {
   REG_STATUS          => 0x00,
   REG_OUT_P_MSB       => 0x01,
   REG_OUT_P_CSB       => 0x02,
   REG_OUT_P_LSB       => 0x03,
   REG_OUT_T_MSB       => 0x04,
   REG_OUT_T_LSB       => 0x05,
   REG_DR_STATUS       => 0x06,
   REG_OUT_P_DELTA_MSB => 0x07,
   REG_OUT_P_DELTA_CSB => 0x08,
   REG_OUT_P_DELTA_LSB => 0x09,
   REG_OUT_T_DELTA_MSB => 0x0A,
   REG_OUT_T_DELTA_LSB => 0x0B,
   REG_WHO_AM_I        => 0x0C,
   REG_F_STATUS        => 0x0D,
   REG_F_DATA          => 0x0E,
   REG_F_SETUP         => 0x0F,
   REG_TIME_DLY        => 0x10,
   REG_SYSMOD          => 0x11,
   REG_INT_SOURCE      => 0x12,
   REG_PT_DATA_CFG     => 0x13,
   REG_BAR_IN_MSB      => 0x14,
   REG_BAR_IN_LSB      => 0x15,
   REG_P_TGT_MSB       => 0x16,
   REG_P_TGT_LSB       => 0x17,
   REG_T_TGT           => 0x18,
   REG_P_WND_MSB       => 0x19,
   REG_P_WND_LSB       => 0x1A,
   REG_T_WND           => 0x1B,
   REG_P_MIN_MSB       => 0x1C,
   REG_P_MIN_CSB       => 0x1D,
   REG_P_MIN_LSB       => 0x1E,
   REG_T_MIN_MSB       => 0x1F,
   REG_T_MIN_LSB       => 0x20,
   REG_P_MAX_MSB       => 0x21,
   REG_P_MAX_CSB       => 0x22,
   REG_P_MAX_LSB       => 0x23,
   REG_T_MAX_MSB       => 0x24,
   REG_T_MAX_LSB       => 0x25,
   REG_CTRL_REG1       => 0x26,
   REG_CTRL_REG2       => 0x27,
   REG_CTRL_REG3       => 0x28,
   REG_CTRL_REG4       => 0x29,
   REG_CTRL_REG5       => 0x2A,
   REG_OFF_P           => 0x2B,
   REG_OFF_T           => 0x2C,
   REG_OFF_H           => 0x2D,
};

# Represent CTRL_REG1 to CTRL_REG3 as one three-byte field
bitfield { format => "bytes-LE" }, CTRL_REG =>
   # CTRL_REG1
   SBYB => enumfield( 0, qw( STANDBY ACTIVE )),
   OST  => boolfield( 1 ),
   RST  => boolfield( 2 ),
   OS   => enumfield( 3, qw( 1 2 4 8 16 32 64 128 )),
   RAW  => boolfield( 6 ),
   ALT  => boolfield( 7 ),

   # CTRL_REG2
   ST          => enumfield( 8, map { 1 << $_ } 0 .. 15 ),
   ALARM_SEL   => boolfield( 13 ),
   LOAD_OUTPUT => boolfield( 14 ),

   # CTRL_REG3
   IPOL1  => boolfield( 16 ),
   PP_OD1 => boolfield( 17 ),
   IPOL2  => boolfield( 20 ),
   PP_OD2 => boolfield( 21 );

# Converted pressure
async method _mplread_p ( $reg )
{
   my $v = unpack "L>", "\0" . await $self->read_reg( $reg, 3 );
   return $v / 64
}

# Converted altitude
async method _mplread_a ( $reg )
{
   my ( $msb, $lsb ) = unpack "s>C", await $self->read_reg( $reg, 3 );
   return $msb + ( $lsb / 256 );
}

# Converted temperature
async method _mplread_t ( $reg )
{
   my ( $msb, $lsb ) = unpack "cC", await $self->read_reg( $reg, 2 );
   return $msb + ( $lsb / 256 );
}

=head1 ACCESSORS

The following methods documented in an C<await> expression return L<Future>
instances.

=cut

=head2 read_config

   $config = await $chip->read_config;

Returns a C<HASH> reference of the contents of control registers C<CTRL_REG1>
to C<CTRL_REG3>, using fields named from the data sheet.

   SBYB => "STANDBY" | "ACTIVE"
   OST  => 0 | 1
   RST  => 0 | 1
   OS   => 1 | 2 | 4 | ... | 64 | 128
   RAW  => 0 | 1
   ALT  => 0 | 1

   ST          => 1 | 2 | 4 | ... | 16384 | 32768
   ALARM_SEL   => 0 | 1
   LOAD_OUTPUT => 0 | 1

   IPOL1  => 0 | 1
   PP_OD1 => 0 | 1
   IPOL2  => 0 | 1
   PP_OD2 => 0 | 1

=head2 change_config

   await $chip->change_config( %changes );

Writes updates to the control registers C<CTRL_REG1> to C<CTRL_REG3>. This
will be performed as a read-modify-write operation, so any fields not given
as arguments to this method will retain their current values.

Note that these two methods use a cache of configuration bytes to make
subsequent modifications more efficient. This cache will not respect the
"one-shot" nature of the C<OST> and C<RST> bits.

=cut

field $_configbytes;

async method _cached_read_ctrlreg ()
{
   return $_configbytes //= await $self->read_reg( REG_CTRL_REG1, 3 );
}

async method read_config ()
{
   return { unpack_CTRL_REG( await $self->_cached_read_ctrlreg ) };
}

async method change_config ( %changes )
{
   my $config = await $self->read_config;

   $config->{$_} = $changes{$_} for keys %changes;

   my $bytes = $_configbytes = pack_CTRL_REG( %$config );

   await $self->write_reg( REG_CTRL_REG1, $bytes );
}

=head2 get_sealevel_pressure

=head2 set_sealevel_pressure

   $pressure = await $chip->get_sealevel_pressure;

   await $chip->set_sealevel_pressure( $pressure );

Read or write the barometric pressure calibration register which is used to
convert pressure to altitude when the chip is in altimeter mode, in Pascals.
The default value is 101,326 Pa.

=cut

async method get_sealevel_pressure ()
{
   unpack( "S<", await $self->read_reg( REG_BAR_IN_MSB, 2 ) ) * 2;
}

async method set_sealevel_pressure ( $pressure )
{
   await $self->write_reg( REG_BAR_IN_MSB, pack "S<", $pressure / 2 )
}

=head2 read_pressure

   $pressure = await $chip->read_pressure;

Returns the value of the C<OUT_P_*> registers, suitably converted into
Pascals. (The chip must be in barometer mode and must I<not> be in C<RAW> mode
for the conversion to work).

=cut

async method read_pressure () { return await $self->_mplread_p( REG_OUT_P_MSB ) }

declare_sensor pressure =>
   method    => async method () {
      await $self->_next_trigger;
      return await $self->read_pressure;
   },
   units     => "pascals",
   sanity_bounds => [ 80_000, 120_000 ],
   precision => 0;

=head2 read_altitude

   $altitude = await $chip->read_altitude;

Returns the value of the C<OUT_P_*> registers, suitably converted into metres.
(The chip must be in altimeter mode and must I<not> be in C<RAW> mode for the
conversion to work).

=cut

async method read_altitude () { return await $self->_mplread_a( REG_OUT_P_MSB ) }

=head2 read_temperature

   $temperature = await $chip->read_temperature;

Returns the value of the C<OUT_T_*> registers, suitable converted into degrees
C. (The chip must I<not> be in C<RAW> mode for the conversion to work).

=cut

async method read_temperature () { return await $self->_mplread_t( REG_OUT_T_MSB ) }

declare_sensor temperature =>
   method    => async method () {
      await $self->_next_trigger;
      return await $self->read_temperature;
   },
   units     => "°C",
   sanity_bounds => [ -50, 80 ],
   precision => 2;

=head2 read_min_pressure

=head2 read_max_pressure

   $pressure = await $chip->read_min_pressure;

   $pressure = await $chip->read_max_pressure;

Returns the values of the C<P_MIN> and C<P_MAX> registers, suitably converted
into Pascals.

=head2 clear_min_pressure

=head2 clear_max_pressure

   await $chip->clear_min_pressure;

   await $chip->clear_max_pressure;

Clear the C<P_MIN> or C<P_MAX> registers, resetting them to start again from
the next measurement.

=cut

async method read_min_pressure () { return await $self->_mplread_p( REG_P_MIN_MSB ) }
async method read_max_pressure () { return await $self->_mplread_p( REG_P_MAX_MSB ) }

async method clear_min_pressure () { return await $self->write_reg( REG_P_MIN_MSB, "\x00\x00\x00" ) }
async method clear_max_pressure () { return await $self->write_reg( REG_P_MAX_MSB, "\x00\x00\x00" ) }

=head2 read_min_altitude

=head2 read_max_altitude

   $altitude = await $chip->read_min_altitude;

   $altitude = await $chip->read_max_altitude;

Returns the values of the C<P_MIN> and C<P_MAX> registers, suitably converted
into metres.

=cut

=head2 clear_min_altitude

=head2 clear_max_altitude

   await $chip->clear_min_altitude;

   await $chip->clear_max_altitude;

Clear the C<P_MIN> or C<P_MAX> registers, resetting them to start again from
the next measurement.

=cut

async method read_min_altitude () { return await $self->_mplread_a( REG_P_MIN_MSB ) }
async method read_max_altitude () { return await $self->_mplread_a( REG_P_MAX_MSB ) }

*clear_min_altitude = \&clear_min_pressure;
*clear_max_altitude = \&clear_max_pressure;

=head2 read_min_temperature

=head2 read_max_temperature

   $temperature = await $chip->read_min_temperature;

   $temperature = await $chip->read_max_temperature;

Returns the values of the C<T_MIN> and C<T_MAX> registers, suitably converted
into metres.

=head2 clear_min_temperature

=head2 clear_max_temperature

   await $chip->clear_min_temperature;

   await $chip->clear_max_temperature;

Clear the C<T_MIN> or C<T_MAX> registers, resetting them to start again from
the next measurement.

=cut

async method read_min_temperature () { return await $self->_mplread_t( REG_T_MIN_MSB ) }
async method read_max_temperature () { return await $self->_mplread_t( REG_T_MAX_MSB ) }

async method clear_min_temperature () { return await $self->write_reg( REG_T_MIN_MSB, "\x00\x00" ) }
async method clear_max_temperature () { return await $self->write_reg( REG_T_MAX_MSB, "\x00\x00" ) }

=head1 METHODS

=cut

=head2 check_id

   await $chip->check_id;

Reads the C<WHO_AM_I> register and checks for a valid ID result. The returned
future fails if the expected result is not received.

=cut

async method check_id ()
{
   my $val = await $self->read_reg( REG_WHO_AM_I, 1 );

   my $id = unpack "C", $val;
   $id == WHO_AM_I_ID or
      die sprintf "Incorrect response from WHO_AM_I register (got %02X, expected %02X)\n",
         $id, WHO_AM_I_ID;

   return $self;
}

=head2 start_oneshot

   await $chip->start_oneshot;

Sets the C<OST> bit of C<CTRL_REG1> to start a one-shot measurement when in
standby mode. After calling this method you will need to use
C<busywait_oneshot> to wait for the measurement to finish, or rely somehow on
the interrupts.

=cut

async method start_oneshot ()
{
   my $bytes = await $self->_cached_read_ctrlreg;

   my $ctrl_reg1 = substr( $bytes, 0, 1 ) | "\x02"; # Set OST bit
   await $self->write_reg( REG_CTRL_REG1, $ctrl_reg1 );
}

=head2 busywait_oneshot

   await $chip->busywait_oneshot;

Repeatedly reads the C<OST> bit of C<CTRL_REG1> until it becomes clear.

=cut

async method busywait_oneshot ()
{
   while(1) {
      my $ctrl_reg1 = await $self->read_reg( REG_CTRL_REG1, 1 );
      last if not( ord( $ctrl_reg1 ) & 0x02 );
   }
}

=head2 oneshot

   await $chip->oneshot;

A convenient wrapper around C<start_oneshot> and C<busywait_oneshot>.

=cut

async method oneshot ()
{
   await $self->start_oneshot;
   await $self->busywait_oneshot;
}

field $_pending_trigger;

method _next_trigger
{
   return $_pending_trigger //=
      $self->oneshot->on_ready(sub { undef $_pending_trigger; });
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
