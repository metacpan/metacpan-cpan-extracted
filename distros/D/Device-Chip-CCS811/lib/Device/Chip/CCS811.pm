#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2021-2023 -- leonerd@leonerd.org.uk

use v5.26;
use warnings;
use Object::Pad 0.800;

package Device::Chip::CCS811 0.03;
class Device::Chip::CCS811
   :isa(Device::Chip::Base::RegisteredI2C);

use Future::AsyncAwait;

use Data::Bitfield 0.02 qw( bitfield boolfield enumfield );

use Device::Chip::Sensor -declare;

use utf8;

=encoding UTF-8

=head1 NAME

C<Device::Chip::CCS811> - chip driver for F<CCS811>

=head1 SYNOPSIS

   use Device::Chip::CCS811;
   use Future::AsyncAwait;

   my $chip = Device::Chip::CCS811->new;
   await $chip->mount( Device::Chip::Adapter::...->new );

   await $chip->init;

   await $chip->change_config( DRIVE_MODE => 1 );

   sleep 60; # wait for chip to warm up

   my ( $eCO2, $eTVOC ) = await $chip->read_alg_result_data;

   printf "eCO2=%dppm\n", $eCO2;
   printf "eTVOC=%dppb\n", $eTVOC;

=head1 DESCRIPTION

This L<Device::Chip> subclass provides specific communication to a
F<ScioSense> F<CCS811> Digital Gas Sensor attached to a computer via an I²C
adapter.

The reader is presumed to be familiar with the general operation of this chip;
the documentation here will not attempt to explain or define chip-specific
concepts or features, only the use of this module to access them.

=cut

method I2C_options
{
   return (
      addr        => 0x5A,
      max_bitrate => 400E3,
   );
}

use constant {
   REG_STATUS          => 0x00,
   REG_MEAS_MODE       => 0x01, # app
   REG_ALG_RESULT_DATA => 0x02, # app
   REG_RAW_DATA        => 0x03, # app
   REG_ENV_DATA        => 0x05, # app
   REG_THRESHOLDS      => 0x10, # app
   REG_BASELINE        => 0x11, # app
   REG_HW_ID           => 0x20,
   REG_HW_VERSION      => 0x21,
   REG_FW_BOOT_VERSION => 0x23,
   REG_FW_APP_VERSION  => 0x24,
   REG_INTERNAL_STATE  => 0xA0, # app
   REG_ERROR_ID        => 0xE0,
   REG_APP_ERASE       => 0xF1, # boot
   REG_APP_DATA        => 0xF2, # boot
   REG_APP_VERIFY      => 0xF3, # boot
   REG_APP_START       => 0xF4, # boot
   REG_SW_RESET        => 0xFF,
};

=head1 METHODS

The following methods documented in an C<await> expression return L<Future>
instances.

=cut

=head2 read_status

   $status = await $chip->read_status;

Reads the C<STATUS> register and returns a hash reference containing the
following fields:

   FWMODE     => "boot" | "app"
   APP_ERASE  => 0 | 1
   APP_VERIFY => 0 | 1
   APP_VALID  => 0 | 1
   DATA_READY => 0 | 1
   ERROR      => 0 | 1

=cut

bitfield { format => "bytes-LE" }, REG_STATUS =>
   FWMODE     => enumfield( 7, qw( boot app )),
   APP_ERASE  => boolfield( 6 ),
   APP_VERIFY => boolfield( 5 ),
   APP_VALID  => boolfield( 4 ),
   DATA_READY => boolfield( 3 ),
   ERROR      => boolfield( 0 );

async method read_status ()
{
   # Not cached
   return { unpack_REG_STATUS( await $self->read_reg( REG_STATUS, 1 ) ) };
}

bitfield { format => "bytes-LE" }, MEAS_MODE =>
   DRIVE_MODE  => enumfield( 4, qw( 0 1 2 3 4 )),
   INT_DATARDY => boolfield( 3 ),
   INT_THRESH  => boolfield( 2 );

=head2 read_config

   $config = await $chip->read_config;

Reads the C<MEAS_MODE> configuration register and reeturns a hash reference
containing the following fields:

   DRIVE_MODE  => 0 | 1 | 2 | 3 | 4
   INT_DATARDY => 0 | 1
   INT_THRESH  => 0 | 1

=cut

field $_configbyte;

async method read_config ()
{
   return { unpack_MEAS_MODE( $_configbyte //= await $self->read_reg( REG_MEAS_MODE, 1 ) ) };
}

=head2 change_config

   await $chip->change_config( %changes );

Writes updates to the C<MEAS_MODE> configuration register.

=cut

async method change_config ( %changes )
{
   my $config = await $self->read_config;

   $config->{$_} = $changes{$_} for keys %changes;

   await $self->write_reg( REG_MEAS_MODE, $_configbyte = pack_MEAS_MODE( %$config ) );
}

=head2 read_alg_result_data

   $data = await $chip->read_alg_result_data;

Reads the C<ALG_RESULT_DATA> register and returns a hash reference containing
the following fields, in addition to the C<STATUS> fields.

   eCO2     => INT (in units of ppm)
   eTVOC    => INT (in unts of ppb)
   ERROR_ID => INT

=cut

async method read_alg_result_data ()
{
   my $bytes = await $self->read_reg( REG_ALG_RESULT_DATA, 6 );
   my ( $eCO2, $eTVOC, $status, $err ) = unpack "S> S> a1 C", $bytes;

   return {
      eCO2 => $eCO2,
      eTVOC => $eTVOC,
      unpack_REG_STATUS( $status ),
      ERROR_ID => $err,
   }
}

=head2 read_id

   $id = await $chip->read_id;

Reads the C<HW_ID> register and returns an integer. This should be the value
0x81 for the F<CCS811> chip.

=cut

async method read_id ()
{
   return unpack "C", await $self->read_reg( REG_HW_ID, 1 );
}

=head2 init

   await $chip->init;

Performs the chip startup actions; namely, starting the application if the
chip is still in bootloader mode.

=cut

async method init ()
{
   if( ( await $self->read_status )->{FWMODE} ne "app" ) {
      await $self->write_reg( REG_APP_START, "" );
   }
}

field $_pending_read_f;

method _next_read ()
{
   return $_pending_read_f //=
      $self->read_alg_result_data->on_ready(sub { undef $_pending_read_f });
}

declare_sensor eCO2 =>
   units     => "ppm",
   precision => 0,
   method => async method () { ( await $self->_next_read )->{eCO2} };

declare_sensor eTVOC =>
   units     => "ppb",
   precision => 0,
   method => async method () { ( await $self->_next_read )->{eTVOC} };

async method initialize_sensors ()
{
   await $self->init;

   await $self->change_config( DRIVE_MODE => 1 );
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
