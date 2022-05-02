#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2017-2022 -- leonerd@leonerd.org.uk

use v5.26;
use Object::Pad 0.57;

package Device::Chip::AD5691R 0.13;
class Device::Chip::AD5691R
   :isa(Device::Chip);

use Carp;
use Future::AsyncAwait;

use Data::Bitfield qw( bitfield boolfield enumfield );

use constant PROTOCOL => "I2C";

=encoding UTF-8

=head1 NAME

C<Device::Chip::AD5691R> - chip driver for F<AD5691R>

=head1 SYNOPSIS

   use Device::Chip::AD5691R;
   use Future::AsyncAwait;

   my $chip = Device::Chip::AD5691R->new;
   await $chip->mount( Device::Chip::Adapter::...->new );

   my $voltage = 1.23;
   await $chip->write_dac( 4096 * $voltage / 2.5 );
   print "Output is now set to 1.23V\n";

=head1 DESCRIPTION

This L<Device::Chip> subclass provides specific communications to an
F<Analog Devices> F<AD5691R> attached to the computer via an I²C adapter.

The reader is presumed to be familiar with the general operation of this chip;
the documentation here will not attempt to explain or define chip-specific
concepts or features, only the use of this module to access them.

=cut

use constant {
   CMD_WRITE_INPUT      => 0x10,
   CMD_UPDATE_DAC       => 0x20,
   CMD_WRITE_AND_UPDATE => 0x30,
   CMD_WRITE_CTRL       => 0x40,
};

=head1 MOUNT PARAMETERS

=head2 addr

The I²C address of the device. Can be specified in decimal, octal or hex with
leading C<0> or C<0x> prefixes.

=cut

sub I2C_options ( $, %params )
{
   my $addr = delete $params{addr} // 0x4C;
   $addr = oct $addr if $addr =~ m/^0/;

   return (
      addr        => $addr,
      max_bitrate => 400E3,
   );
}

=head1 ACCESSORS

The following methods documented in an C<await> expression return L<Future>
instances.

=cut

bitfield CONFIG =>
   GAIN => enumfield( 0, qw( 1 2 )),
   REF  => enumfield( 1, qw( 1 0 )),
   PD   => enumfield( 2, qw( normal 1k 100k hiZ ));

=head2 read_config

   $config = await $chip->read_config;

Returns a C<HASH> reference containing the chip's current configuration

   GAIN => 1 | 2
   REF  => 0 | 1
   PD   => "normal" | "1k" | "100k" | "hiZ"

Note that since the chip does not itself allow reading of its configuration,
this method simply returns the internally-cached values. This cache is
initialised to power-on defaults, and tracked by the C<change_config> method.

=cut

has $_config;

async method read_config ()
{
   # The chip doesn't allow us to read its config. These are the power-on
   # defaults. We'll track updates.
   $_config //= 0;

   return { unpack_CONFIG( $_config ) };
}

=head2 change_config

   await $chip->change_config( %changes );

Changes the configuration. Any field names not mentioned will be preserved at
their existing values.

=cut

async method change_config ( %changes )
{
   my $config = await $self->read_config;

   $_config = pack_CONFIG( %$config, %changes );

   await $self->protocol->write( pack "C S>",
      CMD_WRITE_CTRL, $_config << 11 );
}

=head1 METHODS

=cut

=head2 write_dac

   await $chip->write_dac( $dac, $update );

Writes a new value for the DAC output.

If C<$update> is true this will use the "update" form of write command, which
writes both the DAC register and the input register. If false it only writes
the input register, requiring a pulse on the F<LDAC> pin to actually change
the output voltage.

=cut

async method write_dac ( $value, $update = 0 )
{
   await $self->protocol->write( pack "C S>",
      ( $update ? CMD_WRITE_AND_UPDATE : CMD_WRITE_INPUT ), $value << 4 );
}

=head2 write_dac_voltage

   await $chip->write_dac_voltage( $voltage );

Writes a new value for the DAC output immediately, converting the given
voltage to the required raw value, taking into account the setting of the
C<GAIN> config bit.

=cut

async method write_dac_voltage ( $voltage )
{
   my $config = await $self->read_config;

   my $value = $voltage * ( 1 << 12 ) / 2.5;
   $value /= $config->{GAIN};

   croak "Cannot set DAC voltage to $voltage - too high"
      if $value >= ( 1 << 12 );
   croak "Cannot set DAC voltage to $voltage - too low"
      if $value < 0;

   await $self->write_dac( $value, 1 );
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
