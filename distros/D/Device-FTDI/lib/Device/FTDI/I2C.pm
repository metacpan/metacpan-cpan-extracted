#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2015-2016 -- leonerd@leonerd.org.uk

package Device::FTDI::I2C;

use strict;
use warnings;
use base qw( Device::FTDI::MPSSE );

use utf8;

our $VERSION = '0.13';

=head1 NAME

=encoding UTF-8

C<Device::FTDI::I2C> - use an I<FDTI> chip to talk the I²C protocol

=head1 DESCRIPTION

This subclass of L<Device::FTDI::MPSSE> provides helpers around the basic
MPSSE to fully implement the I²C protocol.

=cut

use Device::FTDI::MPSSE qw(
    DBUS
    CLOCK_RISING CLOCK_FALLING
);

use Future::Utils qw( repeat );

use constant DEBUG => $ENV{PERL_FTDI_DEBUG} // 0;

use constant {
    I2C_SCL     => (1<<0),
    I2C_SDA_OUT => (1<<1),
    I2C_SDA_IN  => (1<<2),
};

use constant { HIGH => 0xff, LOW => 0 };

=head1 CONSTRUCTOR

=cut

=head2 new

    $i2c = Device::FTDI::I2C->new( %args )

In addition to the arguments taken by L<Device::FTDI::MPSSE/new>, this
constructor also accepts:

=over 4

=item clock_rate => INT

Sets the initial value of the bit clock rate; as per L</set_clock_rate>.

=back

=cut

sub new
{
    my $class = shift;
    my %args = @_;
    my $self = $class->SUPER::new( %args );

    $self->set_3phase_clock( 1 );
    $self->set_open_collector( I2C_SCL|I2C_SDA_OUT, 0 );

    $self->set_clock_edges( CLOCK_RISING, CLOCK_FALLING );

    $self->set_clock_rate( $args{clock_rate} ) if defined $args{clock_rate};

    # Idle high
    $self->write_gpio( DBUS, HIGH, I2C_SCL | I2C_SDA_OUT );

    $self->set_check_mode( $args{check_mode} // CHECK_AFTER_ADDR() );

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

    $self->set_clock_divisor( ( 4E6 / $rate ) - 1 );
}

=head2 set_check_mode

    $i2c->set_check_mode( $mode )

Sets the amount of ACK checking that the module will perform. Must be one of
of the following exported constants:

    CHECK_NONE, CHECK_AT_END, CHECK_AFTER_ADDR, CHECK_EACH_BYTE

This controls how eagerly the module will check for incoming C<ACK> conditions
from the addressed I²C device. The more often the module checks, the better it
can detect error conditions from devices, but the more USB transfers it
requires and so the entire operation will take longer.

=over 2

=item *

In C<CHECK_EACH_BYTE> mode, the module will wait to receive an C<ACK>
condition after every single byte of transfer. This mode is the most
technically-correct in terms of aborting the transfer as soon as the required
C<ACK> is not received, but consumes an entire USB transfer roundtrip for
every byte transferred, and is therefore the slowest.

=item *

In C<CHECK_AFTER_ADDR> mode, just the addressing command is sent and then the
first C<ACK> or C<NACK> bit is read in. At this point the module takes the
decision to abort (on C<NACK>) or continue (on C<ACK>). If it continues, it
will send or receive all the subsequent bytes of data in one go.

=item *

In C<CHECK_AT_END> mode, the entire I²C transaction is sent to the I<FDTI>
device, which will collect all the incoming C<ACK> or C<NACK> bits and any
incoming data. Once the entire transaction has taken place, the module will
check that all the required C<ACK>s were received. This mode is the fastest
and involves the fewest USB operations.

=item *

In C<CHECK_NONE> mode, the module will not check any of the C<ACK> conditions.
The entire write (or write-then-read) transaction will be sent in a single
USB transfer, and the bytes received will be returned to the caller.

=back

Because it offers a useful hybrid between speed efficiency and technical
correctness, C<CHECK_AFTER_ADDR> is the default mode.

=cut

push our @EXPORT_OK, qw (
    CHECK_NONE CHECK_AT_END CHECK_AFTER_ADDR CHECK_EACH_BYTE
);

use constant {
    CHECK_NONE       => 0,
    CHECK_AT_END     => 1,
    CHECK_AFTER_ADDR => 2,
    CHECK_EACH_BYTE  => 3,
};

sub set_check_mode
{
    my $self = shift;
    ( $self->{i2c_check_mode} ) = @_;
}

sub i2c_start
{
    my $self = shift;

    print STDERR "FTDI MPSSE I2C START\n" if DEBUG;

    my $f;

    # S&H delay
    $self->write_gpio( DBUS, LOW, I2C_SDA_OUT ) for 1 .. 10;
    $f = $self->write_gpio( DBUS, LOW, I2C_SCL ) for 1 .. 10;

    return $f;
}

sub i2c_repeated_start
{
    my $self = shift;

    print STDERR "FTDI MPSSE I2C REPEAT-START\n" if DEBUG;

    # Release the lines without appearing as STOP
    $self->write_gpio( DBUS, HIGH, I2C_SDA_OUT ) for 1 .. 10;
    $self->write_gpio( DBUS, HIGH, I2C_SCL ) for 1 .. 10;

    $self->i2c_start;
}

sub i2c_stop
{
    my $self = shift;

    print STDERR "FTDI MPSSE I2C STOP\n" if DEBUG;

    my $f;

    $self->write_gpio( DBUS, LOW, I2C_SDA_OUT );

    # S&H delay
    $self->write_gpio( DBUS, HIGH, I2C_SCL ) for 1 .. 10;
    $f = $self->write_gpio( DBUS, HIGH, I2C_SDA_OUT ) for 1 .. 10;

    return $f;
}

sub i2c_send
{
    my $self = shift;
    my ( $data, $more_f ) = @_;

    printf STDERR "FTDI MPSSE I2C SEND %v02X\n", $data if DEBUG;

    my $check = $self->{i2c_check_mode};

    repeat {
        my ( $byte ) = @_;

        $self->write_bits( 8, $byte );
        # Release SDA
        $self->write_gpio( DBUS, HIGH, I2C_SDA_OUT );

        my $f = $self->read_bits( 1 );
        if( $check ) {
            $f = $f->transform( done => sub {
                my ( $ack ) = @_;
                $ack eq "\x00" or
                    die "Received NACK to data byte\n";
            });
        }

        if( $check >= CHECK_EACH_BYTE ) {
            return $f;
        }
        else {
            push @$more_f, $f;
            return Future->done;
        }
    } foreach => [ split m//, $data ],
      while => sub { !shift->failure };
}

use constant { WRITE => 0, READ => 1 };

sub i2c_sendaddr
{
    my $self = shift;
    my ( $addr, $rd, $more_f ) = @_;

    printf STDERR "FTDI MPSSE I2C ADDR %02X %s\n", $addr, $rd ? "R" : "W" if DEBUG;

    my $check = $self->{i2c_check_mode};

    $self->write_bits( 8, pack "C", $rd | $addr << 1 );
    # Release SDA
    $self->write_gpio( DBUS, HIGH, I2C_SDA_OUT );

    my $f = $self->read_bits( 1 );
    if( $check ) {
        $f = $f->transform( done => sub {
            my ( $ack ) = @_;
            $ack eq "\x00" or
                die sprintf "Received NACK to addressing command to 0x%02X\n", $addr;
        });
    }

    if( $check >= CHECK_AFTER_ADDR ) {
        return $f;
    }
    else {
        push @$more_f, $f;
        return Future->done;
    }
}

sub i2c_recv
{
    my $self = shift;
    my ( $len ) = @_;

    my $data_in = "";

    my $f;
    foreach my $ack ( ( 1 ) x ( $len - 1 ), 0 ) {
        $f = $self->read_bytes( 1 )
            ->on_done( sub { $data_in .= $_[0] } );

        $f->on_done( sub { printf STDERR "FTDI MPSSE I2C READ %v02X\n", $_[0] } ) if DEBUG;
        $f->on_fail( sub { printf STDERR "FTDI MPSSE I2C READ FAILED\n" } ) if DEBUG;

        $self->write_bits( 1, chr( $ack ? LOW : HIGH ) );
        # Release SDA
        $self->write_gpio( DBUS, HIGH, I2C_SDA_OUT );
    }

    return $f->transform( done => sub { $data_in } );
}

=head2 write

    $i2c->write( $addr, $data_out )->get

Performs an I²C write operation to the chip at the given (7-bit) address
value.

The device sends a start condition, then a command to address the chip for
writing, followed by the bytes given in the data, and finally a stop
condition.

=cut

sub write
{
    my $self = shift;
    my ( $addr, $data ) = @_;

    $self->i2c_start;

    my @more_f;

    $self->i2c_sendaddr( $addr, WRITE, \@more_f )
    ->then( sub {
        $self->i2c_send( $data, \@more_f )
    })->followed_by( sub {
        my ( $f ) = @_;

        $self->i2c_stop;

        return $f unless @more_f;
        Future->needs_all( @more_f )->then( sub { $f } );
    });
}

=head2 read

    $data_in = $i2c->read( $addr, $len_in )->get

Performs an I²C read operation to the chip at the given (7-bit) address
value.

The device sends a start condition, then a command to address the chip for
reading. It then attempts to read up to the given number of bytes of input
from the chip, sending an C<ACK> condition to all but the final byte, to which
it sends C<NACK>, then finally a stop condition.

=cut

sub read
{
    my $self = shift;
    my ( $addr, $len_in ) = @_;
    $self->write_then_read( $addr, "", $len_in );
}

=head2 write_then_read

    $data_in = $i2c->write_then_read( $addr, $data_out, $len_in )->get

Performs an I²C write operation followed by a read operation within the same
transaction to the chip at the given (7-bit) address value. This is roughly
equivalent to performing separate calls to L</write> and L</read> except that
the two will be combined into a single I²C transaction using a repeated start
condition.

=cut

sub write_then_read
{
    my $self = shift;
    my ( $addr, $data_out, $len_in ) = @_;

    $self->i2c_start;

    my @more_f;

    my $f = Future->done;

    if( length $data_out ) {
        $f = $self->i2c_sendaddr( $addr, WRITE, \@more_f )
        ->then( sub {
            $self->i2c_send( $data_out, \@more_f );
        })->then( sub {
            $self->i2c_repeated_start;
        });
    }

    $f->then( sub {
        $self->i2c_sendaddr( $addr, READ, \@more_f )
    })->then( sub {
        $self->i2c_recv( $len_in );
    })->followed_by( sub {
        my ( $f ) = @_;

        Future->needs_all( $self->i2c_stop, @more_f )
            ->then( sub { $f } );
    });
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
