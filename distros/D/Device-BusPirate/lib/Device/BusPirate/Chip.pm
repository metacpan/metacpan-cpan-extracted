#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2014-2018 -- leonerd@leonerd.org.uk

package Device::BusPirate::Chip;

use strict;
use warnings;

our $VERSION = '0.15';

=head1 NAME

C<Device::BusPirate::Chip> - base class for chip-specific adapters

=head1 DEPRECATION

B<Note>: this package and its entire module name heirarchy are now deprecated
in favour of the L<Device::Chip> interface instead. Any existing chip
implementations should be rewritten. They can continue to target the
I<Bus Pirate> by using L<Device::Chip::Adapter::BusPirate>, but will therefore
gain the ability to use any other implementation of L<Device::Chip::Adapter>.

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
