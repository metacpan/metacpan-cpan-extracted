#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2016-2020 -- leonerd@leonerd.org.uk

use 5.026;
use Object::Pad 0.19;

class Device::Chip::HTU21D 0.05
   extends Device::Chip;

use Carp;

use Data::Bitfield 0.02 qw( bitfield boolfield );
use List::Util qw( first );

use Future::AsyncAwait;

use constant PROTOCOL => "I2C";

=encoding UTF-8

=head1 NAME

C<Device::Chip::HTU21D> - chip driver for F<HTU21D>

=head1 SYNOPSIS

   use Device::Chip::HTU21D;

   my $chip = Device::Chip::HTU21D->new;
   $chip->mount( Device::Chip::Adapter::...->new )->get;

   printf "Current temperature is is %.2f C\n",
      $chip->read_temperature->get;

=head1 DESCRIPTION

This L<Device::Chip> subclass provides specific communication to a
F<TE Connectivity> F<HTU21D> attached to a computer via an I²C adapter.

The reader is presumed to be familiar with the general operation of this chip;
the documentation here will not attempt to explain or define chip-specific
concepts or features, only the use of this module to access them.

=cut

sub I2C_options
{
   my $self = shift;

   return (
      addr        => 0x40,
      max_bitrate => 400E3,
   );
}

=head1 ACCESSORS

The following methods documented with a trailing call to C<< ->get >> return
L<Future> instances.

=cut

use constant {
   # First-byte commands
   CMD_TRIGGER_TEMP_HOLD    => 0xE3,
   CMD_TRIGGER_HUMID_HOLD   => 0xE5,
   CMD_TRIGGER_TEMP_NOHOLD  => 0xF3,
   CMD_TRIGGER_HUMID_NOHOLD => 0xF5,
   CMD_WRITE_REG            => 0xE6,
   CMD_READ_REG             => 0xE7,
   CMD_SOFT_RESET           => 0xFE,
};

bitfield { format => "bytes-LE" }, REG_USER =>
   RES0       => boolfield( 0 ),
   OTPDISABLE => boolfield( 1 ),
   HEATER     => boolfield( 2 ),
   ENDOFBATT  => boolfield( 6 ),
   RES1       => boolfield( 7 );

=head2 read_config

   $config = $chip->read_config->get

Returns a C<HASH> reference of the contents of the user register.

   RES        => "12/14" | "11/11" | "10/13" | "8/12"
   OTPDISABLE => 0 | 1
   HEATER     => 0 | 1
   ENDOFBATT  => 0 | 1

=head2 change_config

   $chip->change_config( %changes )->get

Writes updates to the user register.

=cut

my @RES_VALUES = ( "12/14", "8/12", "10/13", "11/11" );

async method read_config ()
{
   my %config = unpack_REG_USER(
      await $self->protocol->write_then_read( pack( "C", CMD_READ_REG ), 1 )
   );

   my $res = ( delete $config{RES0} ) | ( delete $config{RES1} ) << 1;
   $config{RES} = $RES_VALUES[$res];

   return \%config;
}

async method change_config ( %changes )
{
   my $config = await $self->read_config;

   $config->{$_} = $changes{$_} for keys %changes;

   my $res = delete $config->{RES};

   $res = first { $RES_VALUES[$_] eq $res } 0 .. 3;
   defined $res or
      croak "Unrecognised new value for RES - '$changes{RES}'";

   my $val = pack_REG_USER(
      RES0 => $res & ( 1<<0 ),
      RES1 => $res & ( 1<<1 ),
      %$config,
   );

   await $self->protocol->write( pack "C a", CMD_WRITE_REG, $val );
}

async method _trigger_nohold ( $cmd )
{
   my $protocol = $self->protocol;

   await $self->protocol->write( pack "C", $cmd );

   my $attempts = 10;
   while( $attempts ) {
      my $f = $protocol->read( 2 );
      $attempts-- and $f = $f->else_done( undef );

      my $bytes = await $f;
      defined $bytes and
         return unpack "S>", $bytes;

      await $protocol->sleep( 0.01 );
   }
}

=head1 METHODS

=cut

=head2 read_temperature

   $temperature = $chip->read_temperature->get

Triggers a reading of the temperature sensor, returning a number in degrees C.

=cut

async method read_temperature ()
{
   my $val = await $self->_trigger_nohold( CMD_TRIGGER_TEMP_NOHOLD );

   return -46.85 + 175.72 * ( $val / 2**16 );
}

=head2 read_humidity

   $humidity = $chip->read_humidity->get

Triggers a reading of the humidity sensor, returning a number in % RH.

=cut

async method read_humidity ()
{
   my $val = await $self->_trigger_nohold( CMD_TRIGGER_HUMID_NOHOLD );

   return -6 + 125 * ( $val / 2**16 );
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
