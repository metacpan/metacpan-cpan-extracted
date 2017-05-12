#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2015 -- leonerd@leonerd.org.uk

package Device::Chip::MCP23S17;

use strict;
use warnings;
use base qw( Device::Chip::MCP23x17 );

our $VERSION = '0.01';

=head1 NAME

C<Device::Chip::MCP23S17> - chip driver for a F<MCP23S17>

=head1 DESCRIPTION

This subclass of L<Device::Chip::MCP23x17> provides the required methods to
allow it to communicate with the SPI-attached F<Microchip> F<MCP23S17> version
of the F<MCP23x17> family.

=cut

use constant PROTOCOL => "SPI";

sub SPI_options
{
   return (
      mode => 0,
      max_bitrate => 1E6,
   );
}

sub write_reg
{
   my $self = shift;
   my ( $reg, $data ) = @_;

   $self->protocol->write( pack "C C a*", ( 0x20 << 1 ), $reg, $data );
}

sub read_reg
{
   my $self = shift;
   my ( $reg, $len ) = @_;

   $self->protocol->readwrite( pack "C C a*", ( 0x20 << 1 ) | 1, $reg, "\x00" x $len )
      ->transform( done => sub { substr $_[0], 2 } );
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
