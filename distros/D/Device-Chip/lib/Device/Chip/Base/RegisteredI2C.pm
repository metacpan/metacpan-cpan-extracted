#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2015-2019 -- leonerd@leonerd.org.uk

use v5.26;
use Object::Pad 0.19;

package Device::Chip::Base::RegisteredI2C 0.16;
class Device::Chip::Base::RegisteredI2C extends Device::Chip;

use utf8;

use Future::AsyncAwait 0.38; # async method

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

method REG_DATA_BYTES
{
   my $bytes = int( ( $self->REG_DATA_SIZE + 7 ) / 8 );

   # cache it for next time
   my $pkg = ref $self || $self;
   { no strict 'refs'; *{"${pkg}::REG_DATA_BYTES"} = sub { $bytes }; }

   return $bytes;
}

=head1 METHODS

The following methods documented in an C<await> expression return L<Future>
instances.

=cut

has @_regcache;

=head2 read_reg

   $val = await $chip->read_reg( $reg, $len );

Performs a C<write_then_read> I²C transaction, sending the register number as
a single byte value, then attempts to read the given number of register slots.

=cut

async method read_reg ( $reg, $len, $__forcecache = 0 )
{
   $self->REG_ADDR_SIZE == 8 or
      croak "TODO: Currently unable to cope with REG_ADDR_SIZE != 8";

   my $f = $self->protocol->write_then_read( pack( "C", $reg ), $len * $self->REG_DATA_BYTES );

   foreach my $offs ( 0 .. $len-1 ) {
      $__forcecache || $_regcache[$reg + $offs] and
         $_regcache[$reg + $offs] = $f->then( async sub ( $bytes ) {
            return substr $bytes, $offs * $self->REG_DATA_BYTES, $self->REG_DATA_BYTES
         });
   }

   return await $f;
}

=head2 write_reg

   await $chip->write_reg( $reg, $val );

Performs a C<write> I²C transaction, sending the register number as a single
byte value followed by the data to write into it.

=cut

async method write_reg ( $reg, $val, $__forcecache = 0 )
{
   $self->REG_ADDR_SIZE == 8 or
      croak "TODO: Currently unable to cope with REG_ADDR_SIZE != 8";

   my $len = length( $val ) / $self->REG_DATA_BYTES;

   foreach my $offs ( 0 .. $len-1 ) {
      $__forcecache || defined $_regcache[$reg + $offs] and
         $_regcache[$reg + $offs] = Future->done(
            my $bytes = substr $val, $offs * $self->REG_DATA_BYTES, $self->REG_DATA_BYTES
         );
   }

   await $self->protocol->write( pack( "C", $reg ) . $val );
}

=head2 cached_read_reg

   $val = await $chip->cached_read_reg( $reg, $len );

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

async method cached_read_reg ( $reg, $len )
{
   my @f;

   my $endreg = $reg + $len;

   while( $reg < $endreg ) {
      if( defined $_regcache[$reg] ) {
         push @f, $_regcache[$reg++];
      }
      else {
         $len = 1;
         $len++ while $reg + $len < $endreg and
            !defined $_regcache[ $reg + $len ];

         my $thisreg = $reg;
         push @f, $self->read_reg( $reg, $len, "forcecache" );

         $reg += $len;
      }
   }

   return join "", await Future->needs_all( @f );
}

=head2 cached_write_reg

   await $chip->cached_write_reg( $reg, $val );

Optionally writes a new value for the given register location. This method
will invoke C<write_reg> except if the register already exists in the cache
and already has the given value according to the cache.

This method should be used by chip drivers for interacting with
configuration-style registers; that is, registers that the chip itself will
treat as simple storage of values. It is not suitable for registers that the
chip itself will update.

=cut

async method cached_write_reg ( $reg, $val )
{
   my $len = length( $val ) / ( my $datasize = $self->REG_DATA_BYTES );

   my @current = await Future->needs_all(
      map {
         $_regcache[$reg + $_] // Future->done( "" )
      } 0 .. $len-1
   );

   my @want = $val =~ m/(.{$datasize})/g;

   # Determine chunks that need rewriting
   my @f;
   my $offs = 0;
   while( $offs < $len ) {
      $offs++, next if $current[$offs] eq $want[$offs];

      my $startoffs = $offs++;
      $offs++ while $offs < $len and
         $current[$offs] ne $want[$offs];

      push @f, $self->write_reg( $reg + $startoffs,
         join( "", @want[$startoffs..$offs-1] ), "forcecache" );
   }

   await Future->needs_all( @f );
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
