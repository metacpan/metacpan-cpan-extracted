#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2015-2018 -- leonerd@leonerd.org.uk

package Device::FTDI::SPI;

use strict;
use warnings;
use base qw( Device::FTDI::MPSSE );

our $VERSION = '0.14';

=head1 NAME

C<Device::FTDI::SPI> - use an I<FTDI> chip to talk the SPI protocol

=cut

=head1 DESCRIPTION

This subclass of L<Device::FTDI::MPSSE> provides helpers around the basic
MPSSE to fully implement the SPI protocol.

=cut

use Device::FTDI::MPSSE qw(
    CLOCK_FALLING CLOCK_RISING
    DBUS
);

use Carp;

use constant DEBUG => $ENV{PERL_FTDI_DEBUG} // 0;

use constant {
    SPI_SCK  => (1<<0),
    SPI_MOSI => (1<<1),
    SPI_MISO => (1<<2),
    SPI_SS   => (1<<3),
};

use constant { HIGH => 0xff, LOW => 0 };

=head1 CONSTRUCTOR

=cut

=head2 new

    $spi = Device::FTDI::SPI->new( %args )

In addition to the arguments taken by L<Device::FTDI::MPSSE/new>, this
constructor also accepts:

=over 4

=item mode => INT

The required SPI mode. Should be 0, 1, 2, or 3.

=item wordsize => INT

The required wordsize. Values up to 32 are supported.

=item clock_rate => INT

Sets the initial value of the bit clock rate; as per L</set_clock_rate>.

=back

=cut

sub new
{
    my $class = shift;
    my %args = @_;

    my $self = $class->SUPER::new( %args );

    $self->set_spi_mode( $args{mode} ) if defined $args{mode};

    $self->set_clock_rate( $args{clock_rate} ) if defined $args{clock_rate};

    $self->set_wordsize( $args{wordsize} // 8 );

    $self->set_open_collector( 0, 0 );

    $self->write_gpio( DBUS, HIGH, SPI_SS );

    return $self;
}

=head1 METHODS

Any of the following methods documented with a trailing C<< ->get >> call
return L<Future> instances.

=cut

=head2 set_clock_rate

    $i2c->set_clock_rate( $rate )->get

Sets the clock rate for data transfers, in units of bits per second.

=cut

sub set_clock_rate
{
    my $self = shift;
    my ( $rate ) = @_;

    my $baserate = 6E6;
    if( $rate > $baserate ) {
        $self->set_clkdiv5( 0 );
        $baserate *= 5;
    }
    else {
        $self->set_clkdiv5( 1 );
    }

    $self->set_clock_divisor( ( $baserate / $rate ) - 1 );
}

=head2 set_spi_mode

    $spi->set_spi_mode( $mode )->get

Sets the current SPI mode. This will affect the clock sense and the idle
state of the C<CLK> pin.

=cut

sub set_spi_mode
{
    my $self = shift;
    my ( $mode ) = @_;

    my $idle;

    if( $mode == 0 ) {
        # CPOL=0, CPHA=0
        $idle = LOW;
        $self->set_clock_edges( CLOCK_RISING, CLOCK_FALLING );
    }
    elsif( $mode == 1 ) {
        # CPOL=0, CPHA=1
        $idle = LOW;
        $self->set_clock_edges( CLOCK_FALLING, CLOCK_RISING );
    }
    elsif( $mode == 2 ) {
        # CPOL=1, CPHA=0
        $idle = HIGH;
        $self->set_clock_edges( CLOCK_FALLING, CLOCK_RISING );
    }
    elsif( $mode == 3 ) {
        # CPOL=1, CPHA=1
        $idle = HIGH;
        $self->set_clock_edges( CLOCK_RISING, CLOCK_FALLING );
    }
    else {
        croak "Bad SPI mode";
    }

    $self->write_gpio( DBUS, $idle, SPI_SCK );
}

=head2 set_wordsize

    $spi->set_wordsize( $bits )->get

Sets the number of bits per word, used by the L</write>, L</read> and
L</readwrite> methods. Normally, this value is 8 but it may be set anywhere
between 1 and 32.

When set to a value smaller than 8, only the least significant bits of each
word are used.

When set to a value greater than 8, the string values operated on will consist
of wide characters, having codepoints greater than 255. Care should be taken
not to treat these strings as Unicode text strings, as in general the values
they contain may not be compatible with Unicode.

=cut

sub set_wordsize
{
    my $self = shift;
    my ( $size ) = @_;

    croak "Invalid wordsize" unless $size > 0 and $size <= 32 and $size == int $size;

    $self->{wordsize} = $size;

    return Future->done;
}

sub _reshape_words_out
{
    my $self = shift;
    my ( $words ) = @_;

    my $wordsize = $self->{wordsize};
    return $words if $wordsize == 8;

    my $lsbfirst = $self->{mpsse_setup} & Device::FTDI::MPSSE::CMD_LSBFIRST;

    # Build bytes to emit by tracking bits specifically
    my $bytes = "";
    my $bits = 0;
    my $nbits = 0;

    while( length $words || $nbits >= 8 ) {
        while( $nbits >= 8 ) {
            if( $lsbfirst ) {
                $bytes .= chr( $bits & 0xFF );
                $bits >>= 8;
            }
            else {
                $bytes .= chr( ( $bits >> 24 ) & 0xFF );
                $bits &= 0xFFFFFF; $bits <<= 8;
            }
            $nbits -= 8;
        }
        last unless length $words;

        if( $lsbfirst ) {
            $bits |= ord( substr( $words, 0, 1, "" ) ) << $nbits;
        }
        else {
            $bits |= ord( substr( $words, 0, 1, "" ) ) << ( 32 - $wordsize - $nbits );
        }
        $nbits += $wordsize;
    }

    return $bytes, $nbits, chr( $lsbfirst ? $bits : $bits >> 24 );
}

sub _reshape_bytes_in
{
    my $self = shift;
    my ( $bytes, $lastlen, $lastbits ) = @_;

    my $wordsize = $self->{wordsize};

    my $lsbfirst = $self->{mpsse_setup} & Device::FTDI::MPSSE::CMD_LSBFIRST;

    my $wordmask = ( 1 << $wordsize ) - 1;

    # Build words to emit by tracking bits specifically
    my $words = "";
    my $bits = 0;
    my $nbits = 0;

    while( length $bytes || $nbits ) {
        while( $nbits >= $wordsize ) {
            if( $lsbfirst ) {
                $words .= chr( $bits & $wordmask );
                $bits >>= $wordsize;
            }
            else {
                $words .= chr( ( $bits >> ( 32 - $wordsize ) ) & $wordmask );
                $bits &= ( 0xFFFFFFFF >> $wordsize ); $bits <<= $wordsize;
            }
            $nbits -= $wordsize;
        }
        last unless length $bytes;

        if( $lsbfirst ) {
            $bits |= ord( substr( $bytes, 0, 1, "" ) ) << $nbits;
        }
        else {
            $bits |= ord( substr( $bytes, 0, 1, "" ) ) << ( 32 - 8 - $nbits );
        }
        $nbits += 8;
    }

    if( $lsbfirst ) {
        $words .= chr( $bits | ( ord $lastbits ) << $nbits )
            if $lastlen;
    }
    else {
        $words .= chr( $bits >> ( 32 - $wordsize ) | ( ord $lastbits ) >> ( 8 - $lastlen ) )
            if $lastlen;
    }

    return $words;
}

=head2 assert_ss

=head2 release_ss

    $spi->assert_ss->get

    $spi->release_ss->get

Set the C<SS> GPIO pin to LOW or HIGH state respectively. Normally these
methods would not be required, as L</read>, L</write> and L</readwrite>
perform these steps automatically. However, they may be useful when combined
with the C<$no_ss> argument to split an SPI transaction over multiple method
calls.

=cut

# TODO: configurable SS line and sense
sub assert_ss
{
    my $self = shift;

    print STDERR "FTDI MPSSE SPI ASSERT-SS\n" if DEBUG;

    $self->write_gpio( DBUS, LOW, SPI_SS );
}

sub release_ss
{
    my $self = shift;

    print STDERR "FTDI MPSSE SPI RELEASE-SS\n" if DEBUG;
    $self->write_gpio( DBUS, HIGH, SPI_SS );
}

=head2 write

    $spi->write( $words, $no_ss )->get

=cut

sub write
{
    my $self = shift;
    my ( $words, $no_ss ) = @_;

    $self->assert_ss unless $no_ss;

    printf STDERR "FTDI MPSSE SPI WRITE> %v.02X\n", $words if DEBUG;

    my ( $bytes, $bitlen, $bits ) = $self->_reshape_words_out( $words );
    my $f = $self->write_bytes( $bytes );
    $f = $self->write_bits( $bitlen, $bits ) if $bitlen;

    $f = $self->release_ss unless $no_ss;

    return $f;
}

=head2 read

    $words = $spi->read( $len, $no_ss )->get;

=cut

sub read
{
    my $self = shift;
    my ( $len, $no_ss ) = @_;

    $self->assert_ss unless $no_ss;

    my $wordsize = $self->{wordsize};
    my $nbits = $len * $wordsize;
    my $lastlen = $nbits % 8;

    my $fbytes = $self->read_bytes( int( $nbits / 8 ) );
    my $fbits = $lastlen ? $self->read_bits( $lastlen ) : undef;

    $self->release_ss unless $no_ss;

    my $f = $wordsize == 8 ? $fbytes :
        ( Future->needs_all( $fbytes, $fbits ? ( $fbits ) : () )->then( sub {
            my ( $bytes, $bits ) = @_;
            return Future->done( $self->_reshape_bytes_in( $bytes, $lastlen, $bits ) );
        }) );

    $f->on_done( sub { printf STDERR "FTDI MPSSE SPI READ <%v.02X\n", $_[0] } ) if DEBUG;

    return $f;
}

=head2 readwrite

    $words_in = $spi->readwrite( $words_out, $no_ss )->get;

Performs a full SPI write, or read-and-write operation, consisting of
asserting the C<SS> pin, transferring bytes, and deasserting it again.

If the optional C<$no_ss> argument is true, then the C<SS> pin will not be
adjusted. This is useful for combining multiple write or read operations into
one SPI transaction.

If the wordsize is set to a value other than 8, the actual serial transfer is
achieved by first reshaping the outbound data into 8-bit bytes with optionally
a final bitmode transfer of between 1 and 7 bits, and reshaping inbound 8-bit
bytes with this final bitmode transfer back into the required shape to be
returned to the caller.

=cut

sub readwrite
{
    my $self = shift;
    my ( $words, $no_ss ) = @_;

    $self->assert_ss unless $no_ss;

    printf STDERR "FTDI MPSSE SPI READWRITE> %v.02X\n", $words if DEBUG;

    my ( $bytes, $bitlen, $bits ) = $self->_reshape_words_out( $words );
    my $fbytes = $self->readwrite_bytes( $bytes );
    my $fbits = $bitlen ? $self->readwrite_bits( $bitlen, $bits ) : undef;

    $self->release_ss unless $no_ss;

    my $f = $self->{wordsize} == 8 ? $fbytes :
        ( Future->needs_all( $fbytes, $fbits ? ( $fbits ) : () )->then( sub {
            my ( $bytes, $bits ) = @_;
            return Future->done( $self->_reshape_bytes_in( $bytes, $bitlen, $bits ) );
        }) );

    $f->on_done( sub { printf STDERR "FTDI MPSSE SPI READWRITE <%v.02X\n", $_[0] } ) if DEBUG;

    return $f;
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
