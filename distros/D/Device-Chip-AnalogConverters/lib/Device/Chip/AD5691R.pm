#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2017 -- leonerd@leonerd.org.uk

package Device::Chip::AD5691R;

use strict;
use warnings;
use base qw( Device::Chip );

use Carp;

our $VERSION = '0.04';

use Data::Bitfield qw( bitfield boolfield enumfield );

use constant PROTOCOL => "I2C";

=encoding UTF-8

=head1 NAME

C<Device::Chip::AD5691R> - chip driver for F<AD5691R>

=head1 SYNOPSIS

 use Device::Chip::AD5691R;

 my $chip = Device::Chip::AD5691R->new;
 $chip->mount( Device::Chip::Adapter::...->new )->get;

 my $voltage = 1.23;
 $chip->write_dac( 4096 * $voltage / 2.5 )->get;
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

sub I2C_options
{
   my $self = shift;
   my %params = @_;

   my $addr = delete $params{addr} // 0x4C;
   $addr = oct $addr if $addr =~ m/^0/;

   return (
      addr        => $addr,
      max_bitrate => 400E3,
   );
}

=head1 ACCESSORS

The following methods documented with a trailing call to C<< ->get >> return
L<Future> instances.

=cut

bitfield CONFIG =>
   GAIN => enumfield( 0, qw( 1 2 )),
   REF  => enumfield( 1, qw( 1 0 )),
   PD   => enumfield( 2, qw( normal 1k 100k hiZ ));

=head2 read_config

   $config = $chip->read_config->get

Returns a C<HASH> reference containing the chip's current configuration

   GAIN => 1 | 2
   REF  => 0 | 1
   PD   => "normal" | "1k" | "100k" | "hiZ"

Note that since the chip does not itself allow reading of its configuration,
this method simply returns the internally-cached values. This cache is
initialised to power-on defaults, and tracked by the C<change_config> method.

=cut

sub read_config
{
   my $self = shift;

   # The chip doesn't allow us to read its config. These are the power-on
   # defaults. We'll track updates.
   my $config = $self->{config} //= 0;

   return Future->done( { unpack_CONFIG( $config ) } );
}

=head2 change_config

   $chip->change_config( %changes )->get

Changes the configuration. Any field names not mentioned will be preserved at
their existing values.

=cut

sub change_config
{
   my $self = shift;
   my %changes = @_;

   $self->read_config->then( sub {
      my ( $config ) = @_;
      $self->{config} = pack_CONFIG( %$config, %changes );

      $self->protocol->write( pack "C S>",
         CMD_WRITE_CTRL, $self->{config} << 11 );
   });
}

=head1 METHODS

=cut

=head2 write_dac

   $chip->write_dac( $dac, $update )->get

Writes a new value for the DAC output.

If C<$update> is true this will use the "update" form of write command, which
writes both the DAC register and the input register. If false it only writes
the input register, requiring a pulse on the F<LDAC> pin to actually change
the output voltage.

=cut

sub write_dac
{
   my $self = shift;
   my ( $value, $update ) = @_;

   $self->protocol->write( pack "C S>",
      ( $update ? CMD_WRITE_AND_UPDATE : CMD_WRITE_INPUT ), $value << 4 );
}

=head2 write_dac_voltage

   $chip->write_dac_voltage( $voltage )->get

Writes a new value for the DAC output immediately, converting the given
voltage to the required raw value, taking into account the setting of the
C<GAIN> config bit.

=cut

sub write_dac_voltage
{
   my $self = shift;
   my ( $voltage ) = @_;

   $self->read_config->then( sub {
      my ( $config ) = @_;

      my $value = $voltage * ( 1 << 12 ) / 2.5;
      $value /= $config->{GAIN};

      croak "Cannot set DAC voltage to $voltage - too high"
         if $value >= ( 1 << 12 );
      croak "Cannot set DAC voltage to $voltage - too low"
         if $value < 0;

      $self->write_dac( $value, 1 );
   });
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
