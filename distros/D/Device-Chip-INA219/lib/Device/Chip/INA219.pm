#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2014-2016 -- leonerd@leonerd.org.uk

package Device::Chip::INA219;

use strict;
use warnings;
use 5.010;
use base qw( Device::Chip );

use utf8;

our $VERSION = '0.04';

use Carp;
use Data::Bitfield qw( bitfield boolfield enumfield );

use constant PROTOCOL => "I2C";

=encoding UTF-8

=head1 NAME

C<Device::Chip::INA219> - chip driver for an F<INA219>

=head1 SYNOPSIS

 use Device::Chip::INA219;

 my $chip = Device::Chip::INA219->new;
 $chip->mount( Device::Chip::Adapter::...->new )->get;

 printf "Current bus voltage is %d mV, shunt voltage is %d uV\n",
    $chip->read_bus_voltage->get, $chip->read_shunt_voltage->get;

=head1 DESCRIPTION

This L<Device::Chip> subclass provides specific communication to a
F<Texas Instruments> F<INA219> attached to a computer via an I²C adapter.

The reader is presumed to be familiar with the general operation of this chip;
the documentation here will not attempt to explain or define chip-specific
concepts or features, only the use of this module to access them.

=cut

=head1 MOUNT PARAMETERS

=head2 addr

The I²C address of the device. Can be specified in decimal, octal or hex with
leading C<0> or C<0x> prefixes.

=cut

sub I2C_options
{
   my $self = shift;
   my %params = @_;

   my $addr = delete $params{addr} // 0x40;
   $addr = oct $addr if $addr =~ m/^0/;

   return (
      addr        => $addr,
      max_bitrate => 100E3,
   );
}

=head1 METHODS

The following methods documented with a trailing call to C<< ->get >> return
L<Future> instances.

=cut

sub read_register
{
   my $self = shift;
   my ( $reg ) = @_;

   $self->protocol->write_then_read( chr $reg, 2 )
      ->transform( done => sub { unpack "s>", $_[0] } );
}

sub write_register
{
   my $self = shift;
   my ( $reg, $value ) = @_;

   $self->protocol->write( chr( $reg ) . pack 's>', $value );
}

use constant {
   REG_CONFIG  => 0x00, # R/W
   REG_VSHUNT  => 0x01, # R
   REG_VBUS    => 0x02, # R
   REG_POWER   => 0x03, # R
   REG_CURRENT => 0x04, # R
   REG_CALIB   => 0x05, # R/W
};

my @ADCs = qw( 9b 10b 11b 12b . . . .  1 2 4 8 16 32 64 128 );

bitfield CONFIG =>
   RST        => boolfield(15),
   BRNG       => enumfield(13, qw( 16V 32V )),
   PG         => enumfield(11, qw( 40mV 80mV 160mV 320mV )),
   BADC       => enumfield( 7, @ADCs),
   SADC       => enumfield( 3, @ADCs),
   MODE_CONT  => boolfield(2),
   MODE_BUS   => boolfield(1),
   MODE_SHUNT => boolfield(0);

=head2 read_config

   $config = $chip->read_config->get

Reads and returns the current chip configuration as a C<HASH> reference.

=cut

sub read_config
{
   my $self = shift;

   $self->read_register( REG_CONFIG )->then( sub {
      my ( $data ) = @_;
      Future->done( $self->{config} = { unpack_CONFIG( $data ) } );
   });
}

sub _config
{
   my $self = shift;

   defined $self->{config}
      ? Future->done( $self->{config} )
      : $self->read_config->then( sub { Future->done( $self->{config} ) } );
}

=head2 change_config

   $chip->change_config( %config )->get

Changes the configuration. Any field names not mentioned will be preserved.

=cut

sub change_config
{
   my $self = shift;
   my %changes = @_;

   $self->_config->then( sub {
      my %config = ( %{ $_[0] }, %changes );

      undef $self->{config}; # invalidate the cache
      $self->write_register( REG_CONFIG, pack_CONFIG( %config ) );
   });
}

=head2 read_shunt_voltage

   $uv = $chip->read_shunt_voltage->get

Returns the current shunt voltage reading scaled integer in microvolts.

=cut

sub read_shunt_voltage
{
   my $self = shift;

   $self->read_register( REG_VSHUNT )->then( sub {
      my ( $vraw ) = @_;

      # Each $vraw graduation is 10uV
      Future->done( $vraw * 10 );
   });
}

=head2 read_bus_voltage

   $mv = $chip->read_bus_voltage->get

   ( $mv, $ovf, $cnvr ) = $chip->read_bus_voltage->get

Returns the current bus voltage reading, as a scaled integer in milivolts.

The returned L<Future> also yields the OVF and CNVR flags.

=cut

sub read_bus_voltage
{
   my $self = shift;

   $self->read_register( REG_VBUS )->then( sub {
      my ( $value ) = @_;
      my $ovf  = ( $value & 1<<0 );
      my $cnvr = ( $value & 1<<1 );
      my $vraw = $value >> 3;

      # Each $vraw graduation is 4mV
      Future->done( $vraw * 4, $cnvr, $ovf );
   });
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
