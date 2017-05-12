#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2016 -- leonerd@leonerd.org.uk

package Device::BusPirate::Chip::nRF24L01P;

use strict;
use warnings;

our $VERSION = '0.03';

=head1 NAME

C<Device::BusPirate::Chip::nRF24L01P> - deprecated

=head1 DESCRIPTION

This module has moved. It now lives at L<Device::Chip::nRF24L01P> because now
it implements the L<Device::Chip> interface.

To use it, replace

   my $pirate = Device::BusPirate->new( @pirate_args );
   my $nrf = $pirate->mount_chip( "nRF24L01P" )->get;

with

   my $nrf = Device::Chip::nRF24L01P->new;
   $nrf->mount(
      Device::Chip::Adapter::BusPirate->new( @pirate_args )
   )->get;

Then proceed to use the C<$nrf> device as before.

Alternatively, other adapter types are available that offer a more flexible
usage.

=cut

0x55AA;
