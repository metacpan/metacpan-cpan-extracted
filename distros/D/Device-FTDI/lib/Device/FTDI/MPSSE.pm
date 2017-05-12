#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2015-2017 -- leonerd@leonerd.org.uk

package Device::FTDI::MPSSE;

use strict;
use warnings;
use 5.010; # //

our $VERSION = '0.13';

# Testing on my FT232H board suggests that the MPSSE gets upset and stalls if
#   you write more than 1024 bytes at once.
use constant MAX_WRITE_BUFFSIZE => 1024;

use constant {
    BUF_WRITE => 0,
    BUF_WRITTEN_F => 1,
};

=head1 NAME

=encoding UTF-8

C<Device::FTDI::MPSSE> - use the MPSSE mode of an I<FDTI> chip

=head1 DESCRIPTION

This module provides convenient methods to access the Multi-Protocol
Synchronous Serial Engine (MPSSE) mode of certain I<FTDI> chips. It
provides methods to wrap the various commands that control the MPSSE and
interpret their responses.

The following subclasses exist to simplify implementation of particular
serial protocols:

=over 2

=item *

L<Device::FTDI::I2C> for I²C

=item *

L<Device::FTDI::SPI> for SPI

=back

=head2 FUTURES AND BUFFERING

Unlike most L<Future>-returning modules, it is not usually necessary to
actually store the results of returned L<Future> instances from most of these
methods. The C<$mpsse> object itself will store them.

Especially in cases of C<set_*> or C<write_> methods, the caller is free
to drop them in void context.

You should, however, be aware of the deferred nature of the activities of
these methods. The reason they return futures is that none of these methods
really acts immediately on the chip. Instead, pending commands are stored
internally in a buffer, and emitted at once to the chip over USB, where it can
act on them all, and send all the responses at once. The reason to do this is
to gain a much improved performance over the USB connection.

Because of this, while it is not necessary to wait on or call L<Future/get> on
every returned future, it I<is> required that the very last of a sequence of
operations is waited on (usually by calling its C<get> method). When
implementing library functions it is usually sufficient simply to let the last
operation be returned in non-void context to the caller, so the caller can
await it themself.

=cut

use Carp;

use Device::FTDI qw( PID_FT232H );
use Time::HiRes qw( time );

use Exporter 'import';

our @EXPORT_OK = qw(
    DBUS CBUS
);

use constant {
    DBUS => 0,
    CBUS => 1,
};

=head1 CONSTRUCTOR

=cut

=head2 new

    $mpsse = Device::FTDI::MPSSE->new( %args )

An instance of this class needs a L<Device::FTDI> object to operate on. Either
it can be provided as a single named argument called C<ftdi>, or this
constructor will build one by passing the other named arguments to
L<Device::FTDI/new>, except that it applies a default C<product> parameter of
the product ID identifying the I<FT232H> device.

This constructor performs all the necessary setup to initialse the MPSSE.

=cut

sub new
{
    my $class = shift;
    my %args = @_;

    my $ftdi = $args{ftdi} //
        Device::FTDI->new( product => PID_FT232H, %args );

    $ftdi->reset;

    $ftdi->read_data_set_chunksize( 65536 );
    $ftdi->write_data_set_chunksize( 65536 );

    $ftdi->purge_buffers;

    $ftdi->set_bitmode( 0, Device::FTDI::BITMODE_RESET );
    $ftdi->set_bitmode( 0, Device::FTDI::BITMODE_MPSSE );

    my $self = bless {
        ftdi => $ftdi,
    }, $class;

    $self->set_adaptive_clock( 0 );
    $self->set_3phase_clock( 0 );
    $self->set_loopback( 0 );
    $self->set_open_collector( 0, 0 );

    $self->{mpsse_buffers} = [];
    $self->{mpsse_alarms} = [];

    $self->{mpsse_setup} = 0;

    # Default output on SCK/DO/TMS, input every other

    my $dir = (1<<0) | (1<<1) | (1<<3);
    $self->{mpsse_gpio}[DBUS] = [ 0, $dir ];
    $self->_mpsse_gpio_set( DBUS, 0, $dir );

    $self->{mpsse_gpio}[CBUS] = [ 0, 0 ];
    $self->_mpsse_gpio_set( CBUS, 0, 0 );

    return $self;
}

# MPSSE command bits
use constant {
    # u16 quantities are little-endian

    # Synchronous read bitmasks when !(1<<7)
    CMD_CLK_ON_WRITE => 1<<0,
    CMD_BITMODE      => 1<<1,
    CMD_CLK_ON_READ  => 1<<2,
    CMD_LSBFIRST     => 1<<3,
    CMD_WRITE        => 1<<4,
    CMD_READ         => 1<<5,
    CMD_WRITE_TMS    => 1<<6,
    # followed by: !BITMODE    BITMODE
    #              u16 bytes   u8 bits
    #              u8*$N data  u8 data   if WRITE/WRITE_TMS

    CMD_SET_DBUS => 0x80, # u8 value, u8 direction
    CMD_SET_CBUS => 0x82, # u8 value, u8 direction
    CMD_GET_DBUS => 0x81,
    CMD_GET_CBUS => 0x83,

    CMD_LOOPBACK_ON  => 0x84,
    CMD_LOOPBACK_OFF => 0x85,

    CMD_SET_CLOCK_DIVISOR => 0x86, # u16 div

    CMD_SEND_IMMEDIATE => 0x87,

    CMD_WAIT_IO_HIGH => 0x88,
    CMD_WAIT_IO_LOW  => 0x89,

    CMD_CLKDIV5_OFF => 0x8A,
    CMD_CLKDIV5_ON  => 0x8B,

    CMD_3PHASECLK_ON  => 0x8C,
    CMD_3PHASECLK_OFF => 0x8D,

    CMD_CLOCK_BYTES => 0x8E, # u8 bits
    CMD_CLOCK_BITS  => 0x8F, # u16 bytes

    # Ignore CPU mode instructions 0x90-0x93

    CMD_CLOCK_UNTIL_IO_HIGH => 0x94,
    CMD_CLOCK_UNTIL_IO_LOW  => 0x95,

    CMD_ADAPTIVE_CLOCK_ON  => 0x96,
    CMD_ADAPTIVE_CLOCK_OFF => 0x97,

    CMD_NCLOCK_UNTIL_IO_HIGH => 0x9C, # u16 bytes
    CMD_NCLOCK_UNTIL_IO_LOW  => 0x9D, # u16 bytes

    CMD_SET_OPEN_COLLECTOR => 0x9E, # u8 dbus, u8 cbus
};

=head2 METHODS

Any of the following methods documented with a trailing C<< ->get >> call
return L<Future> instances.

=cut

=head2 set_bit_order

    $mpsse->set_bit_order( $lsbfirst )

Configures the bit order of subsequent L</write_bytes> or L</readwrite_bytes>
calls.

Takes either of the following exported constants

    MSBFIRST, LSBFIRST

=cut

push @EXPORT_OK, qw(
    MSBFIRST LSBFIRST
);
use constant {
    MSBFIRST => 0,
    LSBFIRST => CMD_LSBFIRST,
};

sub set_bit_order
{
    my $self = shift;
    my ( $lsbfirst ) = @_;

    ( $self->{mpsse_setup} &= ~CMD_LSBFIRST )
                           |= ( $lsbfirst & CMD_LSBFIRST );

    # TODO: Consider a token-effort Future->done for completeness?
}

=head2 set_clock_edges

    $mpsse->set_clock_edges( $rdclock, $wrclock )

Configures the clocking sense of subsequent read or write operations.

Each value should be one of the following constants

    CLOCK_FALLING, CLOCK_RISING

=cut

push @EXPORT_OK, qw(
    CLOCK_FALLING CLOCK_RISING
);
use constant {
    CLOCK_FALLING => 1,
    CLOCK_RISING  => 0,
};

sub set_clock_edges
{
    my $self = shift;
    my ( $rdclock, $wrclock ) = @_;

    $self->{mpsse_cmd_rd} = CMD_READ  | ( $rdclock ? CMD_CLK_ON_READ  : 0 );
    $self->{mpsse_cmd_wr} = CMD_WRITE | ( $wrclock ? CMD_CLK_ON_WRITE : 0 );

    $self->{mpsse_cmd_rdwr} = $self->{mpsse_cmd_wr} | $self->{mpsse_cmd_rd};
}

=head2 write_bytes

=head2 read_bytes

=head2 readwrite_bytes

    $mpsse->write_bytes( $data_out )->get

    $data_in = $mpsse->read_bytes( $len )->get

    $data_in = $mpsse->readwrite_bytes( $data_out )->get

Perform a bytewise clocked serial transfer. These are the "main" methods of
the class; they invoke the main core of the MPSSE.

In each case, the C<CLK> pin will count the specified length of bytes of
transfer. For the C<write_> and C<readwrite_> methods this count is implied by
the length of the inbound buffer; during the operation the specified bytes
will be sent out of the C<DO> pin.

For the C<read_> and C<readwrite_> methods, the returned future will yield the
bytes that were received in the C<DI> pin during this time.

=cut

sub _readwrite_bytes
{
    my $self = shift;
    my ( $cmd, $len, $data ) = @_;

    defined $cmd or croak "clock edge sense has not yet been set";

    $cmd |= $self->{mpsse_setup};

    $data = substr( $data, 0, $len );
    $data .= "\0" x ( $len - length $data );

    my $f = $self->_send_bytes( pack( "C v", $cmd, $len - 1 ) .
                                ( $cmd & CMD_WRITE ? $data : "" ) );
    $f = $self->_recv_bytes( $len ) if $cmd & CMD_READ;

    return $f;
}

sub write_bytes
{
    my $self = shift;
    $self->_readwrite_bytes( $self->{mpsse_cmd_wr}, length $_[0], $_[0] );
}

sub read_bytes
{
    my $self = shift;
    $self->_readwrite_bytes( $self->{mpsse_cmd_rd}, $_[0], "" );
}

sub readwrite_bytes
{
    my $self = shift;
    $self->_readwrite_bytes( $self->{mpsse_cmd_rdwr}, length $_[0], $_[0] );
}

=head2 write_bits

=head2 read_bits

=head2 readwrite_bits

    $mpsse->write_bits( $bitlen, $bits_out )->get

    $bits_in = $mpsse->read_bits( $bitlen )->get

    $bits_in = $mpsse->readwrite_bits( $bitlen, $bits_out )->get

Performs a bitwise clocked serial transfer of between 1 and 8 single bits.

In each case, the C<CLK> pin will count the specified length of bits of
transfer.

For the C<write_> and C<readwrite_> methods individal bits of the given byte
will be clocked out of the C<DO> pin. In C<MSBFIRST> mode, this will start
from the highest bit of the byte; in C<LSBFIRST> mode, this will start from
the lowest. The remaining bits will be ignored.

For the C<read_> and C<readwrite_> methods, the returned future will yield
the bits that were received in the C<DI> pin during this time. In C<MSBFIRST>
mode, the bits returned by the chip will start from the highest bit of the
byte; in C<LSBFIRST> they will start from the lowest. The other bits will be
set to zero.

=cut

sub _readwrite_bits
{
    my $self = shift;
    my ( $cmd, $len, $data ) = @_;

    defined $cmd or croak "clock edge sense has not yet been set";

    $cmd |= $self->{mpsse_setup} | CMD_BITMODE;

    $data = substr( $data, 0, 1 );
    $data = "\0" if !length $data;

    my $f = $self->_send_bytes( pack( "C C", $cmd, $len - 1 ) .
                                ( $cmd & CMD_WRITE ? $data : "" ) );

    if( $cmd & CMD_READ ) {
        $f = $self->_recv_bytes( 1 )
        ->transform( done => sub {
            my $bits = ord shift;

            # The FTDI chip's shift register partial-byte reads come in at
            # the "wrong" end of the byte. By shifting and masking the result
            # we'll ensure the caller sees them where they expect, and doesn't
            # get any extra junk bits
            if( $self->{mpsse_setup} & CMD_LSBFIRST ) {
                $bits >>= ( 8 - $len );
            }
            else {
                $bits <<= ( 8 - $len );
                $bits &= 0xff;
            }

            return chr $bits;
        });
    }

    return $f;
}

sub write_bits
{
    my $self = shift;
    $self->_readwrite_bits( $self->{mpsse_cmd_wr}, $_[0], $_[1] );
}

sub read_bits
{
    my $self = shift;
    $self->_readwrite_bits( $self->{mpsse_cmd_rd}, $_[0], "" );
}

sub readwrite_bits
{
    my $self = shift;
    $self->_readwrite_bits( $self->{mpsse_cmd_rdwr}, $_[0], $_[1] );
}

=head2 write_gpio

    $mpsse->write_gpio( $port, $val, $mask )->get

Write a new value to the pins on a GPIO port, setting them to outputs. This
method affects only the pins specified by the C<$mask> bitmask, on the
specified port. Pins not covered by the mask remain unaffected; they remain
in their previous driven or input state.

=head2 read_gpio

    $val = $mpsse->read_gpio( $port, $mask )->get

Reads the state of the pins on a GPIO port. The returned future will yield an
8-bit integer. This method sets the pins covered by C<$mask> as inputs. Pins
not covered by the mask remain unaffected; they remain in their previous
driven or input state.

=head2 tris_gpio

    $mpsse->tris_gpio( $port, $mask )->get

"tristate" the pins on a GPIO port; i.e. set them as high-Z inputs rather than
driven outputs. This method affects only the pins specified by the C<$mask>
bitmask, on the specified port. Pin not covered by the mask remain unaffected.
This is equivalent to C<read_gpio> except that it does not consume an extra
byte of return value.

In each of the above methods, the GPIO port is specified by one of the
following exported constants

    DBUS, CBUS

=cut

sub _mpsse_gpio_set
{
    my $self = shift;
    my ( $port, $val, $dir ) = @_;

    $self->_send_bytes( pack "C C C", CMD_SET_DBUS + ( $port * 2 ), $val, $dir );
}

use constant { VAL => 0, DIR => 1 };

sub write_gpio
{
    my $self = shift;
    my ( $port, $val, $mask ) = @_;

    my $state = $self->{mpsse_gpio}[$port];

    ( $state->[VAL] &= ~$mask ) |= ( $val & $mask );
    ( $state->[DIR] |=  $mask );

    $self->_mpsse_gpio_set( $port, $state->[VAL], $state->[DIR] );
}

sub read_gpio
{
    my $self = shift;
    my ( $port, $mask ) = @_;

    my $state = $self->{mpsse_gpio}[$port];
    if( ( $state->[DIR] & $mask ) != 0 ) {
        $self->tris_gpio( $port, $mask );
    }

    $self->_send_bytes( pack "C", CMD_GET_DBUS + ( $port * 2 ) );
    $self->_recv_bytes( 1 )
        ->transform( done => sub { unpack "C", $_[0] } );
}

sub tris_gpio
{
    my $self = shift;
    my ( $port, $mask ) = @_;

    my $state = $self->{mpsse_gpio}[$port];

    $state->[DIR] &= ~$mask;

    $self->_mpsse_gpio_set( $port, $state->[VAL], $state->[DIR] );
}

=head2 set_loopback

    $mpsse->set_loopback( $on )->get

If enabled, loopback mode bypasses the actual IO pins from the chip and
connects the chip's internal output to its own input. This can be useful for
testing whether the chip is mostly functioning correctly.

=cut

sub set_loopback
{
    my $self = shift;
    my ( $on ) = @_;

    $self->_send_bytes( pack "C", $on ? CMD_LOOPBACK_ON : CMD_LOOPBACK_OFF );
}

=head2 set_clock_divisor

    $mpsse->set_clock_divisor( $div )->get

Sets the divider the chip uses to determine the output clock frequency. The
eventual frequency will be

    $freq_Hz = 12E6 / (( 1 + $div ) * 2 )

=cut

sub set_clock_divisor
{
    my $self = shift;
    my ( $div ) = @_;

    $self->_send_bytes( pack "C v", CMD_SET_CLOCK_DIVISOR, $div );
}

=head2 set_clkdiv5

    $mpsse->set_clkdiv5( $on )->get

Disables or enables the divide-by-5 clock prescaler.

Some I<FTDI> chips are capable of faster clock speeds. These chips use a base
frequency of 60MHz rather than 12MHz, but divide it down by 5 by default to
remain compatible with code unaware of this. To access the higher speeds
available on these chips, disable the divider by using this method. The clock
rate implied by C<set_clock_divisor> will then be 5 times faster.

=cut

sub set_clkdiv5
{
    my $self = shift;
    my ( $on ) = @_;

    $self->_send_bytes( pack "C", $on ? CMD_CLKDIV5_ON : CMD_CLKDIV5_OFF );
}

=head2 set_3phase_clock

    $mpsse->set_3phase_clock( $on )->get

If enabled, data is clocked in/out using a 3-phase strategy compatible with
the I2C protocol. If this is set, the effective clock rate becomes 2/3 that
implied by the clock divider.

=cut

sub set_3phase_clock
{
    my $self = shift;
    my ( $on ) = @_;

    $self->_send_bytes( pack "C", $on ? CMD_3PHASECLK_ON : CMD_3PHASECLK_OFF );
}

=head2 set_adaptive_clock

    $mpsse->set_adaptive_clock( $on )->get

If enabled, the chip waits for acknowledgement of a clock signal on the
C<GPIOL3> pin before continuing for every bit transferred. This may be used by
I<ARM> processors.

=cut

sub set_adaptive_clock
{
    my $self = shift;
    my ( $on ) = @_;

    $self->_send_bytes( pack "C", $on ? CMD_ADAPTIVE_CLOCK_ON : CMD_ADAPTIVE_CLOCK_OFF );
}

=head2 set_open_collector

    $mpsse->set_open_collector( $dbus, $cbus )->get

I<Only on FT232H chips>.

Enables open-collector mode on the output pins given by the bitmasks. This
mode is useful to avoid bus drive contention, especially when implementing
I2C.

=cut

sub set_open_collector
{
    my $self = shift;
    my ( $dbus, $cbus ) = @_;

    $self->_send_bytes( pack "C C C", CMD_SET_OPEN_COLLECTOR, $dbus, $cbus );
}

# Future/buffering support
sub _send_bytes
{
    my $self = shift;
    my ( $bytes ) = @_;

    my $buf = $self->{mpsse_buffers}[-1] ||
        ( $self->{mpsse_buffers}[0] = [ "", [] ] );

    if( length( $buf->[BUF_WRITE] ) + length( $bytes ) > MAX_WRITE_BUFFSIZE-1 ) {
        # Split to a new buffer
        push @{ $self->{mpsse_buffers} }, [ "", [] ];
        $buf = $self->{mpsse_buffers}[-1];
    }

    $buf->[BUF_WRITE] .= $bytes;

    my $f = Device::FTDI::MPSSE::_Future->new( $self );
    push @{ $buf->[BUF_WRITTEN_F] }, $f;
    return $f;
}

sub _recv_bytes
{
    my $self = shift;
    my ( $len ) = @_;

    my $f = Device::FTDI::MPSSE::_Future->new( $self );
    push @{ $self->{mpsse_recv_f} }, [ $len, $f ];
    $self->{mpsse_recv_len} += $len;

    return $f;
}

=head2 sleep

    $mpsse->sleep( $secs )->get

Returns a future that becomes done after the given delay time, in (fractional)
seconds.

Note that this method is currently experimental, and only behaves correctly
when either a read future I<or> a sleep future are outstanding. If there are
both then the current implementation will fail with an exception.

=cut

sub sleep
{
    my $self = shift;
    my ( $secs ) = @_;

    my $until = time() + $secs;

    my $f = Device::FTDI::MPSSE::_Future->new( $self );
    my $alarm = [ $until, $f ];

    my $alarms = $self->{mpsse_alarms};
    my $pos = 0;
    $pos++ while $alarms->[$pos] and $alarms->[$pos][0] < $until;
    splice @$alarms, $pos, 0, $alarm;

    return $f;
}

package
    Device::FTDI::MPSSE::_Future;
use base qw( Future );
use Time::HiRes qw( sleep time );

use constant DEBUG => $ENV{PERL_FTDI_DEBUG} // 0;

use constant CMD_SEND_IMMEDIATE => Device::FTDI::MPSSE::CMD_SEND_IMMEDIATE;

use constant {
    BUF_WRITE => Device::FTDI::MPSSE::BUF_WRITE,
    BUF_WRITTEN_F => Device::FTDI::MPSSE::BUF_WRITTEN_F,
};

sub new
{
    my $proto = shift;
    my $self = $proto->SUPER::new();

    $self->{mpsse} = ref $proto ? $proto->{mpsse} : $_[0];

    return $self;
}

sub _flush_buffer
{
    my $self = shift;
    my ( $buf ) = @_;

    my $bytes = $buf->[BUF_WRITE];

    $bytes .= pack "C", CMD_SEND_IMMEDIATE if $self->{mpsse}{mpsse_recv_len};

    printf STDERR "FTDI> %v02X\n", $bytes if DEBUG > 1;

    my $ftdi = $self->{mpsse}{ftdi};
    $ftdi->write_data( $bytes );

    $_->done() for @{ $buf->[BUF_WRITTEN_F] };
}

sub await
{
    my $self = shift;

    my $mpsse = $self->{mpsse};

    my $buffers = $mpsse->{mpsse_buffers};

    if( @$buffers ) {
        $self->_flush_buffer( shift @$buffers );
    }

    my $recvbuff = "";
    my $recv_f = $mpsse->{mpsse_recv_f};

    my $alarms = $mpsse->{mpsse_alarms};

    if( !$mpsse->{mpsse_recv_len} and @$alarms ) {
        sleep( $alarms->[0][0] - time() );
        my $now = time();

        while( @$alarms and $alarms->[0][0] <= $now ) {
            my $alarm = shift @$alarms;
            $alarm->[1]->done();
        }

        return;
    }

    while( $mpsse->{mpsse_recv_len} ) {
        die "TODO: read with sleep/alarm" if @$alarms;

        $mpsse->{ftdi}->read_data( my $more, $mpsse->{mpsse_recv_len} );
        redo if !length $more;

        printf STDERR "<FTDI %v02X\n", $more if DEBUG > 1;

        $recvbuff .= $more;
        $mpsse->{mpsse_recv_len} -= length $more;

        while( @$recv_f and length $recvbuff >= $recv_f->[0][0] ) {
            my ( $len, $f ) = @{ shift @$recv_f };
            $f->done( substr $recvbuff, 0, $len, "" );
        }

        last if @$buffers; # Stop early to let another write round happen
    }
}

=head1 TODO

=over 4

=item *

Implement future await semantics when pending read and alarms are both
present. This will require working out how F<libftdi> works with timeouts.

=back

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
