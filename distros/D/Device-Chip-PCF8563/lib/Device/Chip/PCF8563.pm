#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2016 -- leonerd@leonerd.org.uk

package Device::Chip::PCF8563;

use strict;
use warnings;
use base qw( Device::Chip::Base::RegisteredI2C );

use utf8;

our $VERSION = '0.01';

use Carp;

use constant DEFAULT_ADDR => 0xA2 >> 1;

use Future;

=encoding UTF-8

=head1 NAME

C<Device::Chip::PCF8563> - chip driver for a F<PCF8563>

=head1 DESCRIPTION

This L<Device::Chip> subclass provides specific communication to a
F<NXP> F<PCF8563> chip attached to a computer via an I²C adapter.

=cut

sub I2C_options
{
   return (
      addr        => DEFAULT_ADDR,
      max_bitrate => 100E3,
   );
}

use constant {
   REG_CTRL1     => 0x00,
   REG_CTRL2     => 0x01,
   REG_VLSECONDS => 0x02,
};

sub _unpack_bcd { ( $_[0] >> 4 )*10 + ( $_[0] % 16 ) }
sub _pack_bcd   { int( $_[0] / 10 ) << 4 | ( $_[0] % 10 ) }

=head1 METHODS

The following methods documented with a trailing call to C<< ->get >> return
L<Future> instances.

=cut

=head2 read_time

   @tm = $pcf->read_time->get

Returns a 7-element C<struct tm>-compatible list of values by reading the
timekeeping registers, suitable for passing to C<POSIX::mktime>, etc... Note
that the returned list does not contain the C<yday> or C<is_dst> fields.

Because the F<PCF8563> only stores a 2-digit year number plus a single century
bit, the year is presumed to be in the range C<2000>-C<2199>.

This method presumes C<POSIX>-compatible semantics for the C<wday> field
stored on the chip; i.e. that 0 is Sunday.

This method performs an atomic reading of all the timekeeping registers as a
single I²C transaction, so is preferrable to invoking multiple calls to
individual read methods.

=cut

sub read_time
{
   my $self = shift;

   $self->read_reg( REG_VLSECONDS, 7 )->then( sub {
      my ( $bcd_sec, $bcd_min, $bcd_hour,
           $bcd_mday, $wday, $bcd_mon, $bcd_year ) = unpack "C7", $_[0];

      return Future->fail( "VL bit is set; time is unreliable" ) if $bcd_sec & 0x80;

      my $century = $bcd_mon & 0x80;

      Future->done(
         _unpack_bcd( $bcd_sec ),
         _unpack_bcd( $bcd_min  & 0x7F ),
         _unpack_bcd( $bcd_hour & 0x3F ),
         _unpack_bcd( $bcd_mday & 0x3F ),
         _unpack_bcd( $bcd_mon  & 0x1F ) - 1,
         _unpack_bcd( $bcd_year ) + 100 + ( $century ? 100 : 0 ),
         $wday & 0x07,
      );
   });
}

=head2 write_time

   $pcf->write_time( @tm )->get

Writes the timekeeping registers from a 7-element C<struct tm>-compatible list
of values. This method ignores the C<yday> and C<is_dst> fields, if present.

Because the F<PCF8563> only stores a 2-digit year number and a century bit,
the year must be in the range C<2000>-C<2199> (i.e. numerical values of C<100>
to C<299>).

This method performs an atomic writing of all the timekeeping registers as a
single I²C transaction, so is preferrable to invoking multiple calls to
individual write methods.

=cut

sub write_time
{
   my $self = shift;
   my ( $sec, $min, $hour, $mday, $mon, $year, $wday ) = @_;

   $year >= 100 and $year <= 299 or croak "Invalid year ($year)";

   my $century = $year >= 200;
   $year %= 100;

   $self->write_reg( REG_VLSECONDS, pack "C7",
      _pack_bcd( $sec ),
      _pack_bcd( $min ),
      _pack_bcd( $hour ),
      _pack_bcd( $mday ),
      _pack_bcd( $wday ),
      _pack_bcd( $mon + 1 ) | ( $century ? 0x80 : 0 ),
      _pack_bcd( $year ),
   );
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
