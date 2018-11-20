#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2018 -- leonerd@leonerd.org.uk

package Device::Chip::MCP3221;

use strict;
use warnings;
use base qw( Device::Chip );

our $VERSION = '0.06';

use constant PROTOCOL => "I2C";

=encoding UTF-8

=head1 NAME

C<Device::Chip::MCP3221> - chip driver for F<MCP3221>

=head1 SYNOPSIS

 use Device::Chip::MCP3221;

 my $chip = Device::Chip::MCP3221->new;
 $chip->mount( Device::Chip::Adapter::...->new )->get;

 printf "The reading is %d\n", $chip->read_adc->get;

=head1 DESCRIPTION

This L<Device::Chip> subclass provides specific communications to a
F<Microchip> F<MCP3221> chip.

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

   my $addr = delete $params{addr} // 0x4D;
   $addr = oct $addr if $addr =~ m/^0/;

   return (
      addr        => $addr,
      max_bitrate => 400E3,
   );
}

=head1 METHODS

The following methods documented with a trailing call to C<< ->get >> return
L<Future> instances.

=cut

=head2 read_adc

   $value = $chip->read_adc->get

Performs a conversion and returns the result as a plain unsigned 12-bit
integer.

=cut

sub read_adc
{
   my $self = shift;

   return $self->protocol->read( 2 )->then( sub {
      my ( $buf ) = @_;
      Future->done( unpack "S>", $buf );
   });
}

=head2 read_adc_ratio

   $ratio = $chip->read_adc_ratio->get

Performs a conversion and returns the result as a floating-point number
between 0 and 1.

=cut

sub read_adc_ratio
{
   my $self = shift;

   $self->read_adc->then( sub {
      my ( $value ) = @_;
      # MCP3221 is 12-bit
      return Future->done( $value / 2**12 );
   });
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
