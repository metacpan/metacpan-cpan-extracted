#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2015-2020 -- leonerd@leonerd.org.uk

use v5.26;
use Object::Pad 0.19;

package Device::Chip::MCP23S17 0.03;
class Device::Chip::MCP23S17
   extends Device::Chip::MCP23x17;

use Future::AsyncAwait;

=head1 NAME

C<Device::Chip::MCP23S17> - chip driver for a F<MCP23S17>

=head1 DESCRIPTION

This subclass of L<Device::Chip::MCP23x17> provides the required methods to
allow it to communicate with the SPI-attached F<Microchip> F<MCP23S17> version
of the F<MCP23x17> family.

=cut

use constant PROTOCOL => "SPI";

method SPI_options
{
   return (
      mode => 0,
      max_bitrate => 1E6,
   );
}

async method write_reg ( $reg, $data )
{
   await $self->protocol->write( pack "C C a*", ( 0x20 << 1 ), $reg, $data );
}

async method read_reg ( $reg, $len )
{
   my $buf = await $self->protocol->readwrite( pack "C C a*", ( 0x20 << 1 ) | 1, $reg, "\x00" x $len );
   return substr $buf, 2;
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
