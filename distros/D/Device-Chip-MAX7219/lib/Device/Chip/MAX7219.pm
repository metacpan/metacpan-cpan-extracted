#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2014-2022 -- leonerd@leonerd.org.uk

use v5.26;
use Object::Pad 0.73 ':experimental(init_expr)';

package Device::Chip::MAX7219 0.08;
class Device::Chip::MAX7219
   :isa(Device::Chip);

use Carp;
use Future::AsyncAwait;

use constant PROTOCOL => 'SPI';

=head1 NAME

C<Device::Chip::MAX7219> - chip driver for a F<MAX7219>

=head1 SYNOPSIS

   use Device::Chip::MAX7219;
   use Future::AsyncAwait;

   my $chip = Device::Chip::MAX7219->new;
   await $chip->mount( Device::Chip::Adapter::...->new );

   await $chip->power(1);

   await $chip->intensity( 2 );
   await $chip->limit( 8 );

   await $chip->displaytest( 1 );
   await $chip->shutdown( 0 );

   sleep 3;

   await $chip->displaytest( 0 );

=head1 DESCRIPTION

This L<Device::Chip> subclass provides specific communication to a
F<Maxim Integrated> F<MAX7219> chip attached to a computer via an SPI adapter.
As the F<MAX7221> chip operates virtually identically, this chip will work
too.

This module drives a single F<MAX7219> chip. For situations involving multiple
chips daisy-chained together (such as on popular LED matrix display board
modules) see instead L<Device::Chip::MAX7219Panel>.

The reader is presumed to be familiar with the general operation of this chip;
the documentation here will not attempt to explain or define chip-specific
concepts or features, only the use of this module to access them.

=cut

field $_decode = 0;

method SPI_options
{
   return (
      mode        => 0,
      max_bitrate => 1E6,
   );
}

use constant {
   REG_NONE      => 0x00,
   REG_DIGIT     => 0x01, # .. to 8
   REG_DECODE    => 0x09,
   REG_INTENSITY => 0x0A,
   REG_LIMIT     => 0x0B,
   REG_SHUTDOWN  => 0x0C,
   REG_DTEST     => 0x0F,
};

async method _writereg ( $reg, $value )
{
   await $self->protocol->write( chr( $reg ) . chr( $value ) );
}

=head1 METHODS

The following methods documented in an C<await> expression return L<Future>
instances.

=cut

=head2 write_bcd

   await $chip->write_bcd( $digit, $val );

Writes the value at the given digit, setting it to BCD mode if not already so.
C<$val> should be a single digit number or string, or one of the special
recognised characters in BCD mode of C<->, C<E>, C<H>, C<L>, C<P> or space.
The value may optionally be followed by a decimal point C<.>, which will be
set on the display.

Switches the digit into BCD mode if not already so.

=cut

async method write_bcd ( $digit, $val )
{
   $digit >= 0 and $digit <= 7 or
      croak "Digit must be 0 to 7";

   my $dp = ( $val =~ s/\.$// );
   length $val == 1 or
      croak "BCD value must be 1 character";
   ( $val = index "0123456789-EHLP ", $val ) > -1 or
      croak "Digit value '$val' is not allowed in BCD mode";

   my $decodemask = 1 << $digit;

   $_decode & $decodemask or
      await $self->set_decode( $_decode | $decodemask );

   await $self->_writereg( REG_DIGIT+$digit, $val + ( $dp ? 0x80 : 0 ) );
}

=head2 write_raw

   await $chip->write_raw( $digit, $bits );

Writes the value at the given digit, setting the raw column lines to the 8-bit
value given.

Switches the digit into undecoded raw mode if not already so.

=cut

async method write_raw ( $digit, $bits )
{
   $digit >= 0 and $digit <= 7 or
      croak "Digit must be 0 to 7";

   my $decodemask = 1 << $digit;

   $_decode & $decodemask and
      await $self->set_decode( $_decode & ~$decodemask );

   await $self->_writereg( REG_DIGIT+$digit, $bits );
}

=head2 write_hex

   await $chip->write_hex( $digit, $val );

Similar to C<write_bcd>, but uses a segment decoder written in code rather
than on the chip itself, to turn values into sets of segments to display. This
makes it capable of displaying the letters C<A> to C<F>, in addition to
numbers, C<-> and space.

=cut

my %hex2bits;

async method write_hex ( $digit, $val )
{
   my $dp = ( $val =~ s/\.$// );
   my $bits = $hex2bits{$val} // croak "Unrecognised hex value $val";

   await $self->write_raw( $digit, $bits + ( $dp ? 0x80 : 0 ) );
}

=head2 set_decode

   await $chip->set_decode( $bits );

Directly sets the decode mode of all the digits at once. This is more
efficient for initialising digits into BCD or raw mode, than individual calls
to C<write_bcd> or C<write_raw> for each digit individually.

=cut

async method set_decode ( $bits )
{
   await $self->_writereg( REG_DECODE, $_decode = $bits );
}

=head2 intensity

   await $chip->intensity( $value );

Sets the intensity register. C<$value> must be between 0 and 15, with higher
values giving a more intense output.

=cut

async method intensity ( $value )
{
   await $self->_writereg( REG_INTENSITY, $value );
}

=head2 limit

   await $chip->limit( $columns );

Sets the scan limit register. C<$value> must be between 1 and 8, to set
between 1 and 8 digits. This should only be used to adjust for the number of
LED digits or columns units physically attached to the chip; not for normal
display blanking, as it affects the overall intensity.

I<Note> that this is not directly the value written to the C<LIMIT> register.

=cut

async method limit ( $columns )
{
   $columns >= 1 and $columns <= 8 or
      croak "->limit columns must be between 1 and 8";

   await $self->_writereg( REG_LIMIT, $columns - 1 );
}

=head2 shutdown

   await $chip->shutdown( $off );

Sets the shutdown register, entirely blanking the display and turning off all
output if set to a true value, or restoring the display to its previous
content if set false.

I<Note> that this is not directly the value written to the C<SHUTDOWN>
register.

=cut

async method shutdown ( $off )
{
   await $self->_writereg( REG_SHUTDOWN, !$off );
}

=head2 displaytest

   await $chip->displaytest( $on );

Sets the display test register, overriding the output control and turning on
every LED if set to a true value, or restoring normal operation if set to
false.

=cut

async method displaytest ( $on )
{
   await $self->_writereg( REG_DTEST, $on );
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

while( readline DATA ) {
   my ( $hex, $segments ) = split m/=/;
   my $bits = 0;
   substr( $segments, $_, 1 ) eq "." and $bits += 1 << $_ for 0 .. 6;
   $hex2bits{$hex} = $bits;
}

0x55AA;

__DATA__
0= ......
1=    .. 
2=. .. ..
3=.  ....
4=..  .. 
5=.. .. .
6=..... .
7=    ...
8=.......
9=.. ....
A=... ...
B=.....  
C= ...  .
D=. .... 
E=....  .
F=...   .
-=.      
 =       
