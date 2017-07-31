#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2015,2017 -- leonerd@leonerd.org.uk

package Device::Chip::Base::RegisteredI2C;

use strict;
use warnings;
use base qw( Device::Chip );

use utf8;

our $VERSION = '0.10';

use Carp;

use constant PROTOCOL => "I2C";

use constant REG_ADDR_SIZE => 8;
use constant REG_DATA_SIZE => 8;

=encoding UTF-8

=head1 NAME

C<Device::Chip::Base::RegisteredI2C> - base class for drivers of register-oriented I²C chips

=head1 DESCRIPTION

This subclass of L<Device::Chip> provides some handy utility methods to
implement a chip driver that supports a chip which (largely) operates on the
common pattern of registers; that is, that writes to and reads from the chip
are performed on numerically-indexed register locations, holding independent
values. This is a common pattern that a lot of I²C chips adhere to.

=cut

=head1 CONSTANTS

=cut

=head2 REG_DATA_SIZE

Gives the number of bits of data each register occupies. Normally this value
is 8, but sometimes chips like high-resolution ADCs and DACs might work with a
larger size like 16 or 24. This value ought to be a multiple of 8.

Overriding this constant to a different value will affect the interpretation
of the C<$len> parameter to the register reading and writing methods.

=cut

sub REG_DATA_BYTES
{
   my $self = shift;

   my $bytes = int( ( $self->REG_DATA_SIZE + 7 ) / 8 );

   # cache it for next time
   my $pkg = ref $self || $self;
   { no strict 'refs'; *{"${pkg}::REG_DATA_BYTES"} = sub { $bytes }; }

   return $bytes;
}

=head1 METHODS

The following methods documented with a trailing call to C<< ->get >> return
L<Future> instances.

=cut

=head2 read_reg

   $val = $chip->read_reg( $reg, $len )->get

Performs a C<write_then_read> I²C transaction, sending the register number as
a single byte value, then attempts to read the given number of register slots.

=cut

sub read_reg
{
   my $self = shift;
   my ( $reg, $len ) = @_;

   $self->REG_ADDR_SIZE == 8 or
      croak "TODO: Currently unable to cope with REG_ADDR_SIZE != 8";

   my $f = $self->protocol->write_then_read( pack( "C", $reg ), $len * $self->REG_DATA_BYTES );

   if( $self->{devicechip_regcache}[$reg] ) {
      $self->{devicechip_regcache}[$reg] = $f
         ->transform( done => sub { substr $_[0], 0, $self->REG_DATA_BYTES } );
   }

   return $f;
}

=head2 write_reg

   $chip->write_reg( $reg, $val )->get

Performs a C<write> I²C transaction, sending the register number as a single
byte value followed by the data to write into it.

=cut

sub write_reg
{
   my $self = shift;
   my ( $reg, $val ) = @_;

   $self->REG_ADDR_SIZE == 8 or
      croak "TODO: Currently unable to cope with REG_ADDR_SIZE != 8";

   defined $self->{devicechip_regcache}[$reg] and
      $self->{devicechip_regcache}[$reg] = Future->done( substr $val, 0, $self->REG_DATA_BYTES );

   $self->protocol->write( pack( "C", $reg ) . $val );
}

=head2 cached_read_reg

   $val = $chip->cached_read_reg( $reg, $len )->get

Implements a cache around the given register location. Returns the last value
known to have been read from or written to the register; or reads it from the
actual chip if no interaction has yet been made. Once a cache slot has been
created for the register by calling this method, the L<read_reg> and
L<write_reg> methods will also keep it updated.

This method should be used by chip drivers for interacting with
configuration-style registers; that is, registers that the chip itself will
treat as simple storage of values. It is not suitable for registers that the
chip itself will update.

=cut

sub cached_read_reg
{
   my $self = shift;
   my ( $reg, $len ) = @_;

   $len == 1 or
      croak "TODO: Currently unable to cope with \$len != 1";

   return $self->{devicechip_regcache}[$reg] ||=
      $self->read_reg( $reg, $len );
}

=head2 cached_write_reg

   $chip->cached_write_reg( $reg, $val )->get

Optionally writes a new value for the given register location. This method
will invoke C<write_reg> except if the register already exists in the cache
and already has the given value according to the cache.

This method should be used by chip drivers for interacting with
configuration-style registers; that is, registers that the chip itself will
treat as simple storage of values. It is not suitable for registers that the
chip itself will update.

=cut

sub cached_write_reg
{
   my $self = shift;
   my ( $reg, $val ) = @_;

   my $len = length( $val ) / $self->REG_DATA_BYTES;
   $len == 1 or
      croak "TODO: Currently unable to cope with \$len != 1";

   ( $self->{devicechip_regcache}[$reg] ||= Future->done( "" ) )
   ->then( sub {
      my ( $cached_val ) = @_;
      return Future->done() if $cached_val eq $val;

      return $self->write_reg( $reg, $val );
   });
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
