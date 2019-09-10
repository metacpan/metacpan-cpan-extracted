#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2018-2019 -- leonerd@leonerd.org.uk

package Device::Chip::DAC7571;

use strict;
use warnings;
use base qw( Device::Chip );

our $VERSION = '0.08';

use Carp;
use Future::AsyncAwait;

use constant PROTOCOL => "I2C";

=encoding UTF-8

=head1 NAME

C<Device::Chip::DAC7571> - chip driver for F<DAC7571>

=head1 SYNOPSIS

 use Device::Chip::DAC7571;

 my $chip = Device::Chip::DAC7571->new;
 $chip->mount( Device::Chip::Adapter::...->new )->get;

 # Presuming Vcc = 5V
 $chip->write_dac( 4096 * 1.23 / 5 )->get;
 print "Output is now set to 1.23V\n";

=head1 DESCRIPTION

This L<Device::Chip> subclass provides specific communication to a
F<Texas Instruments> F<DAC7571> attached to a computer via an I²C adapter.

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

   my $addr = delete $params{addr} // 0x4C;
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

my %NAME_TO_POWERDOWN = (
   normal => 0,
   "1k"   => 1,
   "100k" => 2,
   "hiZ"  => 3,
);

# Chip has no config registers
async sub read_config { return {} }
async sub change_config { }

=head2 write_dac

   $chip->write_dac( $dac, $powerdown )->get

Writes a new value for the DAC output and powerdown state.

C<$powerdown> is optional and will default to C<normal> if not provided. Must
be one of the following four values

   normal 1k 100k hiZ

=cut

sub write_dac
{
   my $self = shift;
   my ( $dac, $powerdown ) = @_;

   $dac &= 0x0FFF;

   my $pd = 0;
   $pd = $NAME_TO_POWERDOWN{$powerdown} // croak "Unrecognised powerdown state '$powerdown'"
      if defined $powerdown;

   $self->protocol->write( pack "S>", $pd << 12 | $dac );
}

sub write_dac_ratio
{
   my $self = shift;
   my ( $ratio ) = @_;

   $self->write_dac( $ratio * 2**12 );
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
