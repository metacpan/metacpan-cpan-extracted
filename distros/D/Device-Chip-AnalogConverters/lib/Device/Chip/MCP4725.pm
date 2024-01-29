#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2016-2023 -- leonerd@leonerd.org.uk

use v5.26;
use warnings;
use Object::Pad 0.800;

package Device::Chip::MCP4725 0.16;
class Device::Chip::MCP4725
   :isa(Device::Chip);

use Carp;
use Future::AsyncAwait;

use constant PROTOCOL => "I2C";

=encoding UTF-8

=head1 NAME

C<Device::Chip::MCP4725> - chip driver for F<MCP4725>

=head1 SYNOPSIS

   use Device::Chip::MCP4725;
   use Future::AsyncAwait;

   my $chip = Device::Chip::MCP4725->new;
   await $chip->mount( Device::Chip::Adapter::...->new );

   # Presuming Vcc = 5V
   await $chip->write_dac_ratio( 1.23 / 5 );
   print "Output is now set to 1.23V\n";

=head1 DESCRIPTION

This L<Device::Chip> subclass provides specific communication to a
F<Microchip> F<MCP4725> attached to a computer via an I²C adapter.

The reader is presumed to be familiar with the general operation of this chip;
the documentation here will not attempt to explain or define chip-specific
concepts or features, only the use of this module to access them.

=cut

=head1 MOUNT PARAMETERS

=head2 addr

The I²C address of the device. Can be specified in decimal, octal or hex with
leading C<0> or C<0x> prefixes.

=cut

sub I2C_options ( $, %params )
{
   my $addr = delete $params{addr} // 0x60;
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

my @POWERDOWN_TO_NAME = qw( normal 1k 100k 500k );
my %NAME_TO_POWERDOWN = map { $POWERDOWN_TO_NAME[$_] => $_ } 0 .. $#POWERDOWN_TO_NAME;

=head2 read_config

   $config = await $chip->read_config;

Returns a C<HASH> reference containing the chip's current configuration

   RDY => 0 | 1
   POR => 0 | 1

   PD  => "normal" | "1k" | "100k" | "500k"
   DAC => 0 .. 4095

   EEPROM_PD  => "normal" | "1k" | "100k" | "500k"
   EEPROM_DAC => 0 .. 4095

=cut

async method read_config ()
{
   my $bytes = await $self->protocol->read( 5 );
   my ( $status, $dac, $eeprom ) = unpack( "C S> S>", $bytes );

   return {
      RDY => !!( $status & 0x80 ),
      POR => !!( $status & 0x40 ),
      PD  => $POWERDOWN_TO_NAME[ ( $status & 0x06 ) >> 1 ],

      DAC => $dac >> 4,

      EEPROM_PD  => $POWERDOWN_TO_NAME[ ( $eeprom & 0x6000 ) >> 13 ],
      EEPROM_DAC => ( $eeprom & 0x0FFF ),
   };
}

=head1 METHODS

=cut

=head2 write_dac

   await $chip->write_dac( $dac, $powerdown );

Writes a new value for the DAC output and powerdown state in "fast" mode.

C<$powerdown> is optional and will default to 0 if not provided.

=cut

async method write_dac ( $dac, $powerdown = undef )
{
   $dac &= 0x0FFF;

   my $pd = 0;
   $pd = $NAME_TO_POWERDOWN{$powerdown} // croak "Unrecognised powerdown state '$powerdown'"
      if defined $powerdown;

   await $self->protocol->write( pack "S>", $pd << 12 | $dac );
}

=head2 write_dac_ratio

   await $chip->write_dac_ratio( $ratio );

Writes a new value for the DAC output, setting it to normal output for a given
ratio between 0 and 1.

=cut

async method write_dac_ratio ( $ratio )
{
   await $self->write_dac_ratio( $ratio * 2**12 );
}

=head2 write_dac_and_eeprom

   $chip->write_dac_and_eeprom( $dac, $powerdown )

As L</write_dac> but also updates the EEPROM with the same values.

=cut

async method write_dac_and_eeprom ( $dac, $powerdown = undef )
{
   $dac &= 0x0FFF;

   my $pd = 0;
   $pd = $NAME_TO_POWERDOWN{$powerdown} // croak "Unrecognised powerdown state '$powerdown'"
      if defined $powerdown;

   await $self->protocol->write( pack "C S>", 0x60 | $pd << 1, $dac << 4 );
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
