#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2014-2024 -- leonerd@leonerd.org.uk

use v5.26;
use warnings;
use Object::Pad 0.800;

package Device::BusPirate::Mode::SPI 0.25;
class Device::BusPirate::Mode::SPI :isa(Device::BusPirate::Mode);

use Carp;

use Future::AsyncAwait;
use List::Util 1.33 qw( any );

use constant MODE => "SPI";

use constant PIRATE_DEBUG => $ENV{PIRATE_DEBUG} // 0;

=head1 NAME

C<Device::BusPirate::Mode::SPI> - use C<Device::BusPirate> in SPI mode

=head1 SYNOPSIS

Simple output (e.g. driving LEDs on a shift register)

   use Device::BusPirate;

   my $pirate = Device::BusPirate->new;
   my $spi = $pirate->enter_mode( "SPI" )->get;

   $spi->configure( open_drain => 0 )->get;

   my $count = 0;
   while(1) {
      $spi->writeread_cs( chr $count )->get;
      $count++; $count %= 255;
   }

Simple input (e.g. reading buttons on a shift register)

   while(1) {
      my $in = ord $spi->writeread_cs( "\x00" )->get;
      printf "Read %02x\n", $in;
   }

=head1 DESCRIPTION

This object is returned by a L<Device::BusPirate> instance when switching it
into C<SPI> mode. It provides methods to configure the hardware, and interact
with an SPI-attached chip.

=cut

=head1 METHODS

The following methods documented with C<await> expressions L<Future> instances.

=cut

field $_open_drain :mutator;
field $_cke        :mutator;
field $_ckp        :mutator;
field $_sample     :mutator;
field $_cs_high;
field $_speed;
field $_version;

async method start
{
   # Bus Pirate defaults
   $_open_drain = 1;
   $_cke        = 0;
   $_ckp        = 1;
   $_sample     = 0;

   $_cs_high = 0;
   $_speed   = 0;

   await $self->_start_mode_and_await( "\x01", "SPI" );
   ( $_version ) = await $self->pirate->read( 1, "SPI start" );

   print STDERR "PIRATE SPI STARTED\n" if PIRATE_DEBUG;
   return $self;
}

=head2 configure

   await $spi->configure( %args );

Change configuration options. The following options exist; all of which are
simple true/false booleans.

=over 4

=item open_drain

If enabled (default), a "high" output pin will be set as an input; i.e. hi-Z.
When disabled, a "high" output pin will be driven by 3.3V. A "low" output will
be driven to GND in either case.

=item sample

Whether to sample input in the middle of the clock phase or at the end.

=item cs_high

Whether "active" Chip Select should be at high level. Defaults false to be
active-low. This only affects the C<writeread_cs> method; not the
C<chip_select> method.

=back

The SPI clock parameters can be specified in any of three forms:

=over 4

=item ckp

=item cke

The SPI Clock Polarity and Clock Edge settings, in F<PIC> style.

=item cpol

=item cpha

The SPI Clock Polarity and Clock Phase settings, in F<AVR> style.

=item mode

The SPI mode number, 0 to 3.

=back

The following non-boolean options exist:

=over 4

=item speed

A string giving the clock speed to use for SPI. Must be one of the values:

   30k 125k 250k 1M 2M 2.6M 4M 8M

By default the speed is C<30kHz>.

=back

=cut

my %SPEEDS = (
   '30k'  => 0,
   '125k' => 1,
   '250k' => 2,
   '1M'   => 3,
   '2M'   => 4,
   '2.6M' => 5,
   '4M'   => 6,
   '8M'   => 7,
);

method configure ( %args )
{
   # Convert other forms of specifying SPI modes

   if( defined $args{mode} ) {
      my $mode = delete $args{mode};
      $args{ckp} =    $mode & 2;
      $args{cke} = !( $mode & 1 );
   }

   defined $args{cpol} and $args{ckp} =  delete $args{cpol};
   defined $args{cpha} and $args{cke} = !delete $args{cpha};

   defined $args{cs_high} and $_cs_high = !!$args{cs_high};

   my @f;

   if( any { defined $args{$_} and !!$args{$_} != $self->$_ } qw( open_drain ckp cke sample ) ) {
      defined $args{$_} and $self->$_ = !!$args{$_} for qw( open_drain ckp cke sample );

      push @f, $self->pirate->write_expect_ack(
         chr( 0x80 |
            ( $_open_drain ? 0 : 0x08 ) | # sense is reversed
            ( $_ckp     ? 0x04 : 0 ) |
            ( $_cke     ? 0x02 : 0 ) |
            ( $_sample  ? 0x01 : 0 ) ), "SPI configure" );
   }

   if( defined $args{speed} ) {{
      my $speed = $SPEEDS{$args{speed}} //
         croak "Unrecognised speed '$args{speed}'";

      last if $speed == $_speed;

      $_speed = $speed;
      push @f, $self->pirate->write_expect_ack(
         chr( 0x60 | $_speed ), "SPI set speed" );
   }}

   return Future->needs_all( @f );
}

=head2 chip_select

   await $spi->chip_select( $cs );

Set the C<CS> output pin level. A false value will pull it to ground. A true
value will either pull it up to 3.3V or will leave it in a hi-Z state,
depending on the setting of the C<open_drain> configuration.

=cut

method chip_select
{
   $self->_set_cs( my $_cs = !!shift );

   print STDERR "PIRATE SPI CHIP-SELECT(", $_cs || "0", ")\n" if PIRATE_DEBUG;

   $self->pirate->write_expect_ack( $_cs ? "\x03" : "\x02", "SPI chip_select" );
}

=head2 writeread

   $miso_bytes = await $spi->writeread( $mosi_bytes );

Performs an actual SPI data transfer. Writes bytes of data from C<$mosi_bytes>
out of the C<MOSI> pin, while capturing bytes of input from the C<MISO> pin,
which will be returned as C<$miso_bytes> when the Future completes. This
method does I<not> toggle the C<CS> pin, so is safe to call multiple times to
effect a larger transaction.

This is performed atomically using the C<enter_mutex> method.

=cut

async method _writeread ( $bytes )
{
   printf STDERR "PIRATE SPI WRITEREAD %v02X\n", $bytes if PIRATE_DEBUG;

   # "Bulk Transfer" command can only send up to 16 bytes at once.

   # The Bus Pirate seems to have a bug, where at the lowest (30k) speed, bulk
   # transfers of more than 6 bytes get stuck and lock up the hardware.
   my $maxchunk = $_speed == 0 ? 6 : 16;

   my @chunks = $bytes =~ m/(.{1,$maxchunk})/gs;
   my $ret = "";

   foreach my $bytes ( @chunks ) {
      my $len_1 = length( $bytes ) - 1;

      $ret .= await $self->pirate->write_expect_acked_data(
         chr( 0x10 | $len_1 ) . $bytes, length $bytes, "SPI bulk transfer"
      );
   }

   printf STDERR "PIRATE SPI READ %v02X\n", $ret if PIRATE_DEBUG;
   return $ret;
}

method writeread ( $bytes )
{
   $self->pirate->enter_mutex( sub {
      $self->_writeread( $bytes )
   });
}

=head2 writeread_cs

   $miso_bytes = await $spi->writeread_cs( $mosi_bytes );

A convenience wrapper around C<writeread> which toggles the C<CS> pin before
and afterwards. It uses the C<cs_high> configuration setting to determine the
active sense of the chip select pin.

This is performed atomically using the C<enter_mutex> method.

=cut

method writeread_cs ( $bytes )
{
   $self->pirate->enter_mutex( async sub {
      await $self->chip_select( $_cs_high );
      my $buf = await $self->_writeread( $bytes );
      await $self->chip_select( !$_cs_high );
      return $buf;
   });
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
