#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2016-2023 -- leonerd@leonerd.org.uk

use v5.26;
use warnings;
use Object::Pad 0.800;

package Device::Chip::PCF8563 0.04;
class Device::Chip::PCF8563
   :isa(Device::Chip::Base::RegisteredI2C);

use utf8;

use Carp;

use Future::AsyncAwait;

use constant DEFAULT_ADDR => 0xA2 >> 1;

=encoding UTF-8

=head1 NAME

C<Device::Chip::PCF8563> - chip driver for a F<PCF8563>

=head1 SYNOPSIS

   use Device::Chip::PCF8563;
   use Future::AsyncAwait;

   use POSIX qw( mktime strftime );

   my $chip = Device::Chip::PCF8563->new;
   await $chip->mount( Device::Chip::Adapter::...->new );

   printf "The current time on this chip is ",
      await strftime( "%Y-%m-%d %H:%M:%S", localtime mktime $chip->read_time );

=head1 DESCRIPTION

This L<Device::Chip> subclass provides specific communication to a
F<NXP> F<PCF8563> chip attached to a computer via an I²C adapter.

=cut

method I2C_options
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

sub _unpack_bcd ( $v ) { ( $v >> 4 )*10 + ( $v % 16 ) }
sub _pack_bcd   ( $v ) { int( $v / 10 ) << 4 | ( $v % 10 ) }

=head1 METHODS

The following methods documented in an C<await> expression return L<Future>
instances.

=cut

=head2 read_time

   @tm = await $chip->read_time;

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

async method read_time ()
{
   my ( $bcd_sec, $bcd_min, $bcd_hour, $bcd_mday, $wday, $bcd_mon, $bcd_year ) =
      unpack "C7", await $self->read_reg( REG_VLSECONDS, 7 );

   die "VL bit is set; time is unreliable" if $bcd_sec & 0x80;

   my $century = $bcd_mon & 0x80;

   return (
      _unpack_bcd( $bcd_sec ),
      _unpack_bcd( $bcd_min  & 0x7F ),
      _unpack_bcd( $bcd_hour & 0x3F ),
      _unpack_bcd( $bcd_mday & 0x3F ),
      _unpack_bcd( $bcd_mon  & 0x1F ) - 1,
      _unpack_bcd( $bcd_year ) + 100 + ( $century ? 100 : 0 ),
      $wday & 0x07,
   );
}

=head2 write_time

   await $chip->write_time( @tm );

Writes the timekeeping registers from a 7-element C<struct tm>-compatible list
of values. This method ignores the C<yday> and C<is_dst> fields, if present.

Because the F<PCF8563> only stores a 2-digit year number and a century bit,
the year must be in the range C<2000>-C<2199> (i.e. numerical values of C<100>
to C<299>).

This method performs an atomic writing of all the timekeeping registers as a
single I²C transaction, so is preferrable to invoking multiple calls to
individual write methods.

=cut

async method write_time ( $sec, $min, $hour, $mday, $mon, $year, $wday )
{
   $year >= 100 and $year <= 299 or croak "Invalid year ($year)";

   my $century = $year >= 200;
   $year %= 100;

   await $self->write_reg( REG_VLSECONDS, pack "C7",
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
