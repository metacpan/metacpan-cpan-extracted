#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2015-2020 -- leonerd@leonerd.org.uk

use v5.26;
use Object::Pad 0.19;

package Device::Chip::MCP23x17::Adapter 0.02;
class Device::Chip::MCP23x17::Adapter;
# can't 'extends Device::Chip::Adapter' because that doesn't provide a SUPER::new
use base qw( Device::Chip::Adapter );

use Carp;

use Future::AsyncAwait;

=head1 NAME

C<Device::Chip::MCP23x17::Adapter> - C<Device::Chip::Adapter> over F<MCP23x17> chip

=head1 SYNOPSIS

   use Device::Chip::MCP23S17;
   use Future::AsyncAwait;

   my $chip = Device::Chip::MCP23S17->new;
   await $chip->mount( Device::Chip::Adapter::...->new );

   my $adapter = $chip->as_adapter;

   my $second_chip = Device::Chip::...->new;
   await $second_chip->mount( $adapter );

=head1 DESCRIPTION

This implementation of the L<Device::Chip::Adapter> API provides the C<GPIO>
protocol, by exposing the 16bit GPIO registers of a F<MCP23x17> chip as 16
named GPIO pins. It allows, for example, a second instance of some
L<Device::Chip> implementation that uses the GPIO protocol, to be attached via
the F<MCP23x17> chip.

Instances of this class are not created directly; they are returned by
L<Device::Chip::MCP23x17/as_adapter>.

=cut

has $_mcp;

BUILD ( $mcp )
{
   $_mcp = $mcp;
}

# Only supports GPIO
method make_protocol_GPIO () { $self }

my %GPIOs = (
   ( map { +"A$_", ( 1 << $_ )      } 0 .. 7 ),
   ( map { +"B$_", ( 1 << $_ ) << 8 } 0 .. 7 ),
);

method list_gpios ()
{
   return sort keys %GPIOs;
}

async method write_gpios ( $gpios )
{
   my $val  = 0;
   my $mask = 0;

   foreach ( keys %$gpios ) {
      my $bitmask = $GPIOs{$_} or croak "Unrecognised GPIO name $_";

      $val  |= $bitmask if $gpios->{$_};
      $mask |= $bitmask;
   }

   $mask or return;

   await $_mcp->write_gpio( $val, $mask );
}

async method read_gpios ( $gpios )
{
   my $mask = 0;

   foreach ( @$gpios ) {
      my $bitmask = $GPIOs{$_} or croak "Unrecognised GPIO name $_";

      $mask |= $bitmask;
   }

   $mask or return {};

   my $bits = await $_mcp->read_gpio( $mask );

   my %ret;

   $ret{$_} = $bits & $GPIOs{$_} ? 1 : 0 for @$gpios;

   return \%ret;
}

0x55AA;
