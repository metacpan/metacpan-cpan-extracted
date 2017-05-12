#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2015 -- leonerd@leonerd.org.uk

package Device::Chip::DS1307;

use strict;
use warnings;
use 5.010;
use base qw( Device::Chip::Base::RegisteredI2C );

use utf8;

our $VERSION = '0.03';

use Carp;

use constant DEFAULT_ADDR => 0x68;

use Future;

=encoding UTF-8

=head1 NAME

C<Device::Chip::DS1307> - chip driver for a F<DS1307>

=head1 DESCRIPTION

This L<Device::Chip> subclass provides specific communication to a
F<Maxim Integrated> F<DS1307> chip attached to a computer via an I²C adapter.

=cut

sub new
{
   my $class = shift;
   my %opts = @_;

   my $self = $class->SUPER::new( @_ );

   $self->{$_} = $opts{$_} for qw( address );

   $self->{address} //= DEFAULT_ADDR;

   return $self;
}

sub I2C_options
{
   my $self = shift;

   return (
      addr        => $self->{address},
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

sub read_reg_u8
{
   my $self = shift;
   my ( $reg ) = @_;
   $self->read_reg( $reg )
      ->transform( done => sub { unpack "C", $_[0] } );
}

sub write_reg_u8
{
   my $self = shift;
   my ( $reg, $value ) = @_;
   $self->write_reg( $reg, pack "C", $value );
}

sub _unpack_bcd { ( $_[0] >> 4 )*10 + ( $_[0] % 16 ) }
sub _pack_bcd   { int( $_[0] / 10 ) << 4 | ( $_[0] % 10 ) }

sub read_reg_bcd
{
   my $self = shift;
   my ( $reg ) = @_;
   $self->read_reg( $reg )
      ->transform( done => sub { _unpack_bcd unpack "C", $_[0] } );
}

sub write_reg_bcd
{
   my $self = shift;
   my ( $reg, $value ) = @_;
   $self->write_reg( $reg, pack "C", _pack_bcd( $value ) );
}

=head1 METHODS

The following methods documented with a trailing call to C<< ->get >> return
L<Future> instances.

=cut

=head2 read_FIELD

   $v = $ds->read_I<FIELD>->get

Reads a timekeeping field and returns a decimal integer. The following fields
are recognised:

 seconds minutes hours wday mday month year

The C<hours> field is always returned in 24-hour mode, even if the chip is in
12-hour ("AM/PM") mode.

=cut

# REG_SECONDS also contains the CLOCK HALTED flag
sub read_seconds {
   shift->read_reg_u8( REG_SECONDS )->then( sub {
      my ( $v ) = @_;
      $v &= ~MASK_CLOCKHALT;
      Future->done( _unpack_bcd $v );
   });
}

sub read_minutes { shift->read_reg_bcd( REG_MINUTES ) }

# REG_HOURS is either in 12 or 24-hour mode.
sub read_hours   {
   shift->read_reg_u8( REG_HOURS )->then( sub {
      my ( $v ) = @_;
      if( $v & MASK_12H ) {
         my $pm = $v & MASK_PM;
         $v &= ~(MASK_12H|MASK_PM);
         Future->done( _unpack_bcd( $v ) + 12*$pm );
      }
      else {
         Future->done( _unpack_bcd $v );
      }
   });
}

sub read_wday    { shift->read_reg_u8 ( REG_WDAY ) }
sub read_mday    { shift->read_reg_bcd( REG_MDAY ) }
sub read_month   { shift->read_reg_bcd( REG_MONTH ) }
sub read_year    { shift->read_reg_bcd( REG_YEAR ) }

=head2 write_FIELD

   $ds->write_I<FIELD>->get

Writes a timekeeping field as a decimal integer. The following fields are
recognised:

 seconds minutes hours wday mday month year

The C<hours> field is always written back in 24-hour mode.

=cut

sub write_seconds { $_[0]->write_reg_bcd( REG_SECONDS, $_[1] ) }
sub write_minutes { $_[0]->write_reg_bcd( REG_MINUTES, $_[1] ) }
sub write_hours   { $_[0]->write_reg_bcd( REG_HOURS,   $_[1] ) }
sub write_wday    { $_[0]->write_reg_u8 ( REG_WDAY,    $_[1] ) }
sub write_mday    { $_[0]->write_reg_bcd( REG_MDAY,    $_[1] ) }
sub write_month   { $_[0]->write_reg_bcd( REG_MONTH,   $_[1] ) }
sub write_year    { $_[0]->write_reg_bcd( REG_YEAR,    $_[1] ) }

=head2 read_time

   @tm = $ds->read_time->get

Returns a 7-element C<struct tm>-compatible list of values by reading the
timekeeping registers, suitable for passing to C<POSIX::mktime>, etc... Note
that the returned list does not contain the C<yday> or C<is_dst> fields.

Because the F<DS1307> only stores a 2-digit year number, the year is presumed
to be in the range C<2000>-C<2099>.

This method presumes C<POSIX>-compatible semantics for the C<wday> field
stored on the chip; i.e. that 0 is Sunday.

This method performs an atomic reading of all the timekeeping registers as a
single I2C transaction, so is preferrable to invoking multiple calls to
individual read methods.

=cut

sub read_time
{
   my $self = shift;

   $self->read_reg( REG_SECONDS, 7 )->then( sub {
      my ( $bcd_sec, $bcd_min, $bcd_hour,
           $wday, $bcd_mday, $bcd_mon, $bcd_year ) = unpack "C7", $_[0];

      Future->done(
         _unpack_bcd( $bcd_sec ),
         _unpack_bcd( $bcd_min ),
         _unpack_bcd( $bcd_hour ),
         _unpack_bcd( $bcd_mday ),
         _unpack_bcd( $bcd_mon ) - 1,
         _unpack_bcd( $bcd_year ) + 100,
         $wday,
      );
   });
}

=head2 write_time

   $ds->write_time( @tm )->get

Writes the timekeeping registers from a 7-element C<struct tm>-compatible list
of values. This method ignores the C<yday> and C<is_dst> fields, if present.

Because the F<DS1307> only stores a 2-digit year number, the year must be in
the range C<2000>-C<2099> (i.e. numerical values of C<100> to C<199>).

This method performs an atomic writing of all the timekeeping registers as a
single I2C transaction, so is preferrable to invoking multiple calls to
individual write methods.

=cut

sub write_time
{
   my $self = shift;
   my ( $sec, $min, $hour, $mday, $mon, $year, $wday ) = @_;

   $year >= 100 and $year <= 199 or croak "Invalid year ($year)";

   $self->write_reg( REG_SECONDS, pack "C7",
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
