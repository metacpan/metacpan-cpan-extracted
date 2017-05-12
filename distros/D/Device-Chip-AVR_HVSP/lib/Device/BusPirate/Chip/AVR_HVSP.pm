#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2016 -- leonerd@leonerd.org.uk

package Device::BusPirate::Chip::AVR_HVSP;

use strict;
use warnings;

our $VERSION = '0.04';

=head1 NAME

C<Device::BusPirate::Chip::AVR_HVSP> - deprecated

=head1 DESCRIPTION

This module has moved. it now lives at L<Device::Chip::AVR_HVSP> because it now
implements the L<Device::Chip> interface.

To use it, replace

   my $pirate = Device::BusPirate->new( @pirate_args );
   my $chip = $pirate->mount_chip( "AVR_HVSP" )->get;

with

   my $chip = Device::Chip::AVR_HVSP->new;
   $chip->connect(
      Device::Chip::Adapter::BusPirate->new( @pirate_args )
   )->get;

Then proceed to use the C<$chip> device as before.

=cut

0x55AA;
