#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2015-2023 -- leonerd@leonerd.org.uk

use v5.26;
use warnings;
use Object::Pad 0.800;

package Device::Chip::DS1307 0.08;
class Device::Chip::DS1307
   :isa(Device::Chip::Base::RegisteredI2C);

use utf8;

use Carp;

use Future::AsyncAwait;

use constant DEFAULT_ADDR => 0x68;

=encoding UTF-8

=head1 NAME

C<Device::Chip::DS1307> - chip driver for a F<DS1307>

=head1 DESCRIPTION

This L<Device::Chip> subclass provides specific communication to a
F<Maxim Integrated> F<DS1307> chip attached to a computer via an I²C adapter.

=cut

field $_address :param = DEFAULT_ADDR;

method I2C_options
{
   return (
      addr        => $_address,
      max_bitrate => 100E3,
   );
}

use constant {
   REG_SECONDS => 0x00,
   REG_MINUTES => 0x01,
   REG_HOURS   => 0x02,
   REG_WDAY    => 0x03,
   REG_MDAY    => 0x04,
   REG_MONTH   => 0x05,
   REG_YEAR    => 0x06,
   REG_CONTROL => 0x07,
};

use constant {
   # REG_SECONDS
   MASK_CLOCKHALT => 1<<7,

   # REG_HOURS
   MASK_12H       => 1<<6,
   MASK_PM        => 1<<5,

   # REG_CONTROL
   MASK_OUT       => 1<<7,
   MASK_SQWE      => 1<<4,
   MASK_RS        => 3<<0,
};

async method read_reg_u8 ( $reg )
{
   return unpack "C", await $self->read_reg( $reg );
}

async method write_reg_u8 ( $reg, $value )
{
   await $self->write_reg( $reg, pack "C", $value );
}

sub _unpack_bcd { ( $_[0] >> 4 )*10 + ( $_[0] % 16 ) }
sub _pack_bcd   { int( $_[0] / 10 ) << 4 | ( $_[0] % 10 ) }

async method read_reg_bcd ( $reg )
{
   return _unpack_bcd unpack "C", await $self->read_reg( $reg );
}

async method write_reg_bcd ( $reg, $value )
{
   await $self->write_reg( $reg, pack "C", _pack_bcd( $value ) );
}

=head1 METHODS

The following methods documented in an C<await> expression return L<Future>
instances.

=cut

=head2 read_FIELD

   $sec  = await $ds->read_seconds;
   $min  = await $ds->read_minutes;
   $hr   = await $ds->read_hours;
   $wday = await $ds->read_wday;
   $mday = await $ds->read_mday;
   $mon  = await $ds->read_month;
   $year = await $ds->read_year;

Reads a timekeeping field and returns a decimal integer. The following fields
are recognised:

The C<hours> field is always returned in 24-hour mode, even if the chip is in
12-hour ("AM/PM") mode.

=cut

# REG_SECONDS also contains the CLOCK HALTED flag
async method read_seconds ()
{
   my $v = await $self->read_reg_u8( REG_SECONDS );
   $v &= ~MASK_CLOCKHALT;
   return _unpack_bcd $v;
}

async method read_minutes () { return await $self->read_reg_bcd( REG_MINUTES ); }

# REG_HOURS is either in 12 or 24-hour mode.
async method read_hours ()
{
   my $v = await $self->read_reg_u8( REG_HOURS );
   if( $v & MASK_12H ) {
      my $pm = $v & MASK_PM;
      $v &= ~(MASK_12H|MASK_PM);
      return _unpack_bcd( $v ) + 12*$pm;
   }
   else {
      return _unpack_bcd $v;
   }
}

async method read_wday  () { return await $self->read_reg_u8 ( REG_WDAY  ); }
async method read_mday  () { return await $self->read_reg_bcd( REG_MDAY  ); }
async method read_month () { return await $self->read_reg_bcd( REG_MONTH ); }
async method read_year  () { return await $self->read_reg_bcd( REG_YEAR  ); }

=head2 write_FIELD

   await $ds->write_seconds( $sec  );
   await $ds->write_minutes( $min  );
   await $ds->write_hours  ( $hr   );
   await $ds->write_wday   ( $wday );
   await $ds->write_mday   ( $mday );
   await $ds->write_month  ( $mon  );
   await $ds->write_year   ( $year );

Writes a timekeeping field as a decimal integer. The following fields are
recognised:

The C<hours> field is always written back in 24-hour mode.

=cut

async method write_seconds () { await $self->write_reg_bcd( REG_SECONDS, $_[1] ); }
async method write_minutes () { await $self->write_reg_bcd( REG_MINUTES, $_[1] ); }
async method write_hours   () { await $self->write_reg_bcd( REG_HOURS,   $_[1] ); }
async method write_wday    () { await $self->write_reg_u8 ( REG_WDAY,    $_[1] ); }
async method write_mday    () { await $self->write_reg_bcd( REG_MDAY,    $_[1] ); }
async method write_month   () { await $self->write_reg_bcd( REG_MONTH,   $_[1] ); }
async method write_year    () { await $self->write_reg_bcd( REG_YEAR,    $_[1] ); }

=head2 read_time

   @tm = await $ds->read_time;

Returns a 7-element C<struct tm>-compatible list of values by reading the
timekeeping registers, suitable for passing to C<POSIX::mktime>, etc... Note
that the returned list does not contain the C<yday> or C<is_dst> fields.

Because the F<DS1307> only stores a 2-digit year number, the year is presumed
to be in the range C<2000>-C<2099>.

This method presumes C<POSIX>-compatible semantics for the C<wday> field
stored on the chip; i.e. that 0 is Sunday.

This method performs an atomic reading of all the timekeeping registers as a
single I²C transaction, so is preferrable to invoking multiple calls to
individual read methods.

=cut

async method read_time
{
   my ( $bcd_sec, $bcd_min, $bcd_hour, $wday, $bcd_mday, $bcd_mon, $bcd_year ) = 
      unpack "C7", await $self->read_reg( REG_SECONDS, 7 );

   return (
      _unpack_bcd( $bcd_sec ),
      _unpack_bcd( $bcd_min ),
      _unpack_bcd( $bcd_hour ),
      _unpack_bcd( $bcd_mday ),
      _unpack_bcd( $bcd_mon ) - 1,
      _unpack_bcd( $bcd_year ) + 100,
      $wday,
   );
}

=head2 write_time

   await $ds->write_time( @tm );

Writes the timekeeping registers from a 7-element C<struct tm>-compatible list
of values. This method ignores the C<yday> and C<is_dst> fields, if present.

Because the F<DS1307> only stores a 2-digit year number, the year must be in
the range C<2000>-C<2099> (i.e. numerical values of C<100> to C<199>).

This method performs an atomic writing of all the timekeeping registers as a
single I²C transaction, so is preferrable to invoking multiple calls to
individual write methods.

=cut

async method write_time
{
   my ( $sec, $min, $hour, $mday, $mon, $year, $wday ) = @_;

   $year >= 100 and $year <= 199 or croak "Invalid year ($year)";

   await $self->write_reg( REG_SECONDS, pack "C7",
      _pack_bcd( $sec ),
      _pack_bcd( $min ),
      _pack_bcd( $hour ),
      _pack_bcd( $wday ),
      _pack_bcd( $mday ),
      _pack_bcd( $mon + 1 ),
      _pack_bcd( $year - 100 ),
   );
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
