package Device::FTDI;

use 5.010;
use strict;
use warnings;

our $VERSION = '0.14';

=head1 NAME

C<Device::FTDI> - use USB-attached serial interface chips from I<FTDI>.

=cut

use Carp;

our @ISA = qw(Exporter);
our @EXPORT_OK = qw(
    FLOW_RTS_CTS
    FLOW_DTR_DSR
    FLOW_XON_XOFF
    FLOW_DISABLE

    BITS_7
    BITS_8

    STOP_BIT_1
    STOP_BIT_2
    STOP_BIT_15

    PARITY_NONE
    PARITY_ODD
    PARITY_EVEN
    PARITY_MARK
    PARITY_SPACE

    BREAK_ON
    BREAK_OFF

    INTERFACE_ANY
    INTERFACE_A
    INTERFACE_B
    INTERFACE_C
    INTERFACE_D

    BITMODE_RESET
    BITMODE_BITBANG
    BITMODE_MPSSE
    BITMODE_SYNCBB
    BITMODE_MCU
    BITMODE_OPTO
    BITMODE_CBUS
    BITMODE_SYNCFF
);

# More constants
my %USB_IDS;
BEGIN {
    %USB_IDS = (
        VID_FTDI => 0x0403,

        # https://usb-ids.gowdy.us/read/UD/0403 is useful
        PID_FT232   => 0x6001,
        PID_FT2232C => 0x6010,
        PID_FT4232H => 0x6011,
        PID_FT232H  => 0x6014,
    );

    require constant;
    constant->import( \%USB_IDS );
}
push @EXPORT_OK, keys %USB_IDS;

our %EXPORT_TAGS = (
    all => \@EXPORT_OK,

    flow      => [ grep { m/^FLOW_/      } @EXPORT_OK ],
    bits      => [ grep { m/^BITS_/      } @EXPORT_OK ],
    stop      => [ grep { m/^STOP_/      } @EXPORT_OK ],
    parity    => [ grep { m/^PARITY_/    } @EXPORT_OK ],
    break     => [ grep { m/^BREAK_/     } @EXPORT_OK ],
    interface => [ grep { m/^INTERFACE_/ } @EXPORT_OK ],
    bitmode   => [ grep { m/^BITMODE_/   } @EXPORT_OK ],

    vid => [ grep { m/^VID_/ } @EXPORT_OK ],
    pid => [ grep { m/^PID_/ } @EXPORT_OK ],
);

require XSLoader;
XSLoader::load('Device::FTDI', $VERSION);

=head1 SYNOPSIS

    use Device::FTDI qw( :bits :stop :parity :break :bitmode );

    my $dev = Device::FTDI->new();
    $dev->reset;

    $dev->set_baudrate( 57600 );
    $dev->set_line_property( BITS_8, STOP_BIT_1, PARITY_NONE, BREAK_OFF );

    $dev->write_data( "Hello, world!\n" );

=head1 DESCRIPTION

B<WARNING:> this is an alpha version

This is Perl bindings to F<libftdi> library. It allows you to communicate with
I<FTDI> chips supported by this library.

=head1 CLASS METHODS

=cut

=head2 find_all

    $class->find_all(%params)

Finds all connected devices with specified vendor and product codes. Returns
list of hashes describing devices. Following parameters are accepted:

=over 4

=item B<vendor>

vendor code. Default C<0x0403>.

=item B<product>

product code. Default C<0x6001>.

=back

=cut

sub find_all {
    my ($class, %params) = @_;
    $params{vendor}  ||= VID_FTDI;
    $params{product} ||= PID_FT232;
    my @list = _find_all($params{vendor}, $params{product});
    return map { bless $_, 'Device::FTDI::Description' } @list;
}

=head2 new

    $class->new(%params)

Opens specified device and returns the corresponding object reference. Dies if
an attempt to open the device has failed. Accepts following parameters:

=over 4

=item B<vendor>

vendor code. Default C<0x0403>.

=item B<product>

product code. Default C<0x6001>.

=item B<description>

device description string. By default undefined.

=item B<serial>

device serial ID. By default undefined.

=item B<index>

device index. By default 0.

=item B<autodie>

if true, methods on this instance will use L<Carp/croak> on failure. if false,
they will return negative values.

=back

=cut

sub new {
    my ($class, %params) = @_;
    $params{vendor}  ||= VID_FTDI;
    $params{product} ||= PID_FT232;
    $params{index} ||= 0;
    my $dev = _open_device($params{vendor}, $params{product}, $params{description}, $params{serial}, $params{index});
    return bless { _ctx => $dev, autodie => $params{autodie} // 0 }, $class;
}

=pod

In either case, the following constants may be used to specify C<vendor> or
C<product>:

    VID_FTDI

(export tag C<:vid>)

    PID_FT232, PID_FT2232C, PID_FT4232H, PID_FT232H

(export tag C<:pid>)

=head1 DEVICE METHODS

Most of device methods return negative value in case of error. You can get
error description using L</error_string> method.

=cut

=head2 error_string

    $dev->error_string

Returns string describing error after last operation

=cut

sub error_string {
    return _error_string( shift->{_ctx} );
}

sub _check
{
    my $self = shift;
    my ( $ret ) = @_;
    croak $self->error_string if $self->{autodie} and $ret < 0;
    return $ret;
}

=head2 reset

    $dev->reset

Resets the device

=cut

sub reset {
    my $self = shift;
    return $self->_check( _reset( $self->{_ctx} ) );
}

=head2 set_interface

    $dev->set_interface($interface)

Open selected channels on a chip, otherwise use first channel. I<$interface> may
be one of:

    INTERFACE_A, INTERFACE_B, INTERFACE_C, INTERFACE_D, INTERFACE_ANY

(export tag C<:interface>)

=cut

sub set_interface {
    my ( $self, $interface ) = @_;
    return $self->_check( _set_interface( $self->{_ctx}, $interface ) );
}

=head2 purge_rx_buffer

    $dev->purge_rx_buffer

Clears the read buffer on the chip and the internal read buffer.

=cut

sub purge_rx_buffer {
    my $self = shift;
    return $self->_check( _purge_rx_buffer( $self->{_ctx} ) );
}

=head2 purge_tx_buffer

    $dev->purge_tx_buffer

Clears the write buffer on the chip.

=cut

sub purge_tx_buffer {
    my $self = shift;
    return $self->_check( _purge_tx_buffer( $self->{_ctx} ) );
}

=head2 purge_buffers

    $dev->purge_buffers

Clears the buffers on the chip and the internal read buffer.

=cut

sub purge_buffers {
    my $self = shift;
    return $self->_check( _purge_buffers( $self->{_ctx} ) );
}

=head2 set_flow_control

    $dev->set_flow_control($flowctrl)

I<Since version 0.07>.

Set flow control for ftdi chip. Allowed values for I<$flowctrl> are:

    FLOW_RTS_CTS, FLOW_DTR_DSR, FLOW_XON_XOFF, FLOW_DISABLE

(export tag C<:flow>)

This method is also available aliased as C<setflowctrl> for back-compatibility
and to match the name used by F<libftdi> itself.

=cut

sub set_flow_control {
    my $self = shift;
    my ( $flowctrl ) = @_;
    return $self->_check( _setflowctrl( $self->{_ctx}, $flowctrl ) );
}
*setflowctrl = \&set_flow_control;

=head2 set_line_property

    $dev->set_line_property($bits, $stop_bit, $parity, $break)

Sets line characteristics. Last parameters may be omitted. Following values are
acceptable for parameters (* marks default value):

=over 4

=item B<$bits>

    BITS_7, BITS_8 (*)

(export tag C<:bits>)

=item B<$stop_bit>

    STOP_BIT_1, STOP_BIT_2, STOP_BIT_15 (*)

(export tag C<:stop>)

=item B<$parity>

    PARITY_NONE (*), PARITY_EVEN, PARITY_ODD, PARITY_MARK, PARITY_SPACE

(export tag C<:parity>)

=item B<$break>

    BREAK_OFF (*), BREAK_ON

(export tag C<:break>)

=back

Note that you have to import constants you need. You can import all constants
using C<:all> tag, or individual groups using the other named tags.

=cut

sub set_line_property {
    my $self = shift;
    my ( $bits, $stop_bit, $parity, $break ) = @_;
    defined($bits)     or $bits     = BITS_8();
    defined($stop_bit) or $stop_bit = STOP_BIT_15();
    defined($parity)   or $parity   = PARITY_NONE();
    defined($break)    or $break    = BREAK_OFF();

    return $self->_check(
        _set_line_property2( $self->{_ctx}, $bits, $stop_bit, $parity, $break )
    );
}

=head2 set_baudrate

    $dev->set_baudrate($baudrate)

Sets the chip baudrate. Returns 0 on success or negative error code otherwise.

=cut

sub set_baudrate {
    my $self = shift;
    my ( $baudrate ) = @_;
    return $self->_check( _set_baudrate( $self->{_ctx}, $baudrate ) );
}

=head2 set_latency_timer

    $dev->set_latency_timer($latency)

Sets latency timer. The I<FTDI> chip keeps data in the internal buffer for a
specific amount of time if the buffer is not full yet to decrease load on the
USB bus. Latency must be between 1 and 255.

Returns 0 on success or negative error code otherwise.

=cut

sub set_latency_timer {
    my $self = shift;
    my ( $latency ) = @_;
    croak "latency must be between 1 and 255" unless $latency >= 1 && $latency <= 255;
    return $self->_check( _set_latency_timer( $self->{_ctx}, $latency ) );
}

=head2 get_latency_timer

    $dev->get_latency_timer

Returns latency timer value or negative error code.

=cut

sub get_latency_timer {
    my $self = shift;
    return $self->_check( _get_latency_timer( $self->{_ctx} ) );
}

=head2 write_data_set_chunksize

    $dev->write_data_set_chunksize($chunksize)

Sets write buffer chunk size. Default C<4096>. Returns 0 on success or
negative error code otherwise.

=cut

sub write_data_set_chunksize {
    my $self = shift;
    my ( $chunksize ) = @_;
    return $self->_check( _write_data_set_chunksize( $self->{_ctx}, $chunksize ) );
}

=head2 write_data_get_chunksize

    $dev->write_data_get_chunksize

Returns write buffer chunk size or negative error code.

=cut

sub write_data_get_chunksize {
    my $self = shift;
    return $self->_check( _write_data_get_chunksize( $self->{_ctx} ) );
}

=head2 read_data_set_chunksize

    $dev->read_data_set_chunksize($chunksize)

Sets read buffer chunk size. Default 4096. Returns 0 on success or negative
error code otherwise.

=cut

sub read_data_set_chunksize {
    my $self = shift;
    my ( $chunksize ) = @_;
    return $self->_check( _read_data_set_chunksize( $self->{_ctx}, $chunksize ) );
}

=head2 read_data_get_chunksize

    $dev->read_data_get_chunksize

Returns read buffer chunk size or negative error code.

=cut

sub read_data_get_chunksize {
    my $self = shift;
    return $self->_check( _read_data_get_chunksize( $self->{_ctx} ) );
}

=head2 write_data

    $dev->write_data($data)

Writes data to the chip in chunks. Returns number of bytes written on success
or negative error code otherwise.

=cut

sub write_data {
    my $self = shift;
    my ( $data ) = @_;
    return $self->_check( _write_data( $self->{_ctx}, $data ) );
}

=head2 read_data

    $dev->read_data($buffer, $size)

Reads data from the chip (up to I<$size> bytes) and stores it in I<$buffer>.
Returns when at least one byte is available or when the latency timer has
elapsed. Automatically strips the two modem status bytes transfered during
every read.

Returns number of bytes read on success or negative error code otherwise. Note,
that if no data available it will return 0.

=cut

sub read_data {
    my $self = shift;
    my ( undef, $size ) = @_;
    return $self->_check( _read_data( $self->{_ctx}, $_[0], $size ) );
}

=head2 set_bitmode

    $dev->set_bitmode($mask, $mode)

Enable/disable bitbang modes. I<$mask> -- bitmask to configure lines, High/ON
value configures a line as output. I<$mode> may be one of the following:

    BITMODE_RESET, BITMODE_BITBANG, BITMODE_MPSSE, BITMODE_SYNCBB,
    BITMODE_MCU, BITMODE_OPTO, BITMODE_CBUS, BITMODE_SYNCFF.

(export tag C<:bitmode>)

To use the C<BITMODE_MPSSE> mode, you may prefer to use the
L<Device::FTDI::MPSSE> subclass instead.

=cut

sub set_bitmode {
    my $self = shift;
    my ( $mask, $mode ) = @_;
    return $self->_check( _set_bitmode( $self->{_ctx}, $mask, $mode ) );
}

sub DESTROY {
    my $self = shift;
    _close_device($self->{_ctx});
}

1;

__END__

=head1 SEE ALSO

L<FTDI>, L<Win32::FTDI::FTD2XX>,
L<http://www.intra2net.com/en/developer/libftdi/>

=head1 AUTHOR

Pavel Shaydo, C<< <zwon at cpan.org> >>

Maintained since 2015 by Paul Evans <leonerd@leonerd.org.uk>

=head1 BUGS

Please report any bugs or feature requests via GitHub bugtracker for this project:
L<https://github.com/leonerd/perl-Device-FTDI/issues>.

=head1 LICENSE AND COPYRIGHT

Copyright 2012,2015 Pavel Shaydo.
Copyright 2015 Paul "LeoNerd" Evans.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
