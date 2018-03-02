#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2018 -- leonerd@leonerd.org.uk

package Device::Chip::Adapter::CH341A;

use strict;
use warnings;
use base qw( Device::Chip::Adapter );

use Future;
use USB::LibUSB;

our $VERSION = '0.01';

=encoding UTF-8

=head1 NAME

C<Device::Chip::Adapter::CH341A> - a C<Device::Chip::Adapter> implementation

=head1 DESCRIPTION

This class implements the L<Device::Chip::Adapter> interface for the I<CH341A>
USB interface chip, allowing an instance of a L<Device::Chip> driver to
communicate with actual chip hardware using this adapter.

The I<CH341A> is often found in cheap USB serial memory programmers and
similar devices, for programming SPI or I²C EEPROM and flash memory chips.

=cut

# See also
#   https://github.com/setarcos/ch341prog/blob/master/ch341a.{c,h}

use constant {
   VENDOR_ID  => 0x1A86,
   PRODUCT_ID => 0x5512,

   # Longest stream packet supported
   MAX_PACKETLEN => 32,

   BULK_WRITE_ENDPOINT => 0x02,
   BULK_READ_ENDPOINT  => 0x82,
};

=head1 CONSTRUCTOR

=cut

=head2 new

   $adapter = Device::Chip::Adapter::CH341A->new

Returns a new instance of a C<Device::Chip::Adapter::CH341A>.

=cut

sub new
{
   my $class = shift;

   my $handle = USB::LibUSB->init->open_device_with_vid_pid( VENDOR_ID, PRODUCT_ID );

   return bless {
      handle => $handle,
   }, $class;
}

=head1 PROTOCOLS

The following C<Device::Chip::Adapter> protocol types are supported

=over 2

=item *

SPI

=back

=cut

sub make_protocol_SPI
{
   my $self = shift;

   my $spi = Device::Chip::Adapter::CH341A::_SPI->new( $self );
   return $spi->init->then_done( $spi );
}

sub _bulk_write
{
   my $self = shift;
   my ( $data ) = @_;

   $self->{handle}->bulk_transfer_write( BULK_WRITE_ENDPOINT, $data, 100 );
}

sub _bulk_read
{
   my $self = shift;
   my ( $len ) = @_;

   return $self->{handle}->bulk_transfer_read( BULK_READ_ENDPOINT, $len, 100 );
}

package
   Device::Chip::Adapter::CH341A::_SPI;

use constant {
   CMD_SPI_STREAM => 0xA8,

   CMD_UIO_STREAM => 0xAB,

   CMD_UIO_STM_IN  => 0x00,
   CMD_UIO_STM_DIR => 0x40,
   CMD_UIO_STM_OUT => 0x80,
   CMD_UIO_STM_US  => 0xC0,
   CMD_UIO_STM_END => 0x20,
};

sub new
{
   my $class = shift;
   my ( $adapter ) = @_;

   return bless {
      adapter => $adapter,
   }, $class;
}

sub configure
{
   my $self = shift;
   my %args = @_;

   die "TODO: configure mode other than 0\n" if $args{mode};
   die "TODO: configure a slower speed than 2MHz"
      if defined $args{max_bitrate} and $args{max_bitrate} < 2E6;

   return Future->done;
}

sub power { Future->done }

sub init
{
   my $self = shift;
   return $self->_set_ss( 0 );
}

sub assert_ss  { shift->_set_ss( 1 ) }
sub release_ss { shift->_set_ss( 0 ) }

sub _set_ss
{
   my $self = shift;
   my ( $assert ) = @_;
   my $adapter = $self->{adapter};

   $adapter->_bulk_write( pack "C*",
      CMD_UIO_STREAM,
      CMD_UIO_STM_OUT | 0x36 | ( $assert ? 0 : 1 ),
      ( $assert ? ( CMD_UIO_STM_DIR | 0x3F ) : () ),
      CMD_UIO_STM_END,
   );

   return Future->done;
}

sub write { $_[0]->readwrite( $_[1] )->then_done() }

sub readwrite
{
   my $self = shift;
   my ( $out ) = @_;

   $self->assert_ss
      ->then( sub { $self->readwrite_no_ss( $out ) } )
      ->followed_by( sub {
         my ( $f ) = @_;
         $self->release_ss->then( sub { $f } );
      });
}

sub _bitswap
{
   return join "", map { pack "b8", unpack "B8", $_ } split //, $_[0];
}

sub write_no_ss { $_[0]->readwrite_no_ss( $_[1] )->then_done() }

sub readwrite_no_ss
{
   my $self = shift;
   my ( $out ) = @_;
   my $adapter = $self->{adapter};

   # CH341A is odd LSB-first device; we need to bit-swap bytes out and in

   # TODO: split into MAX_PACKETLEN chunks
   $adapter->_bulk_write( pack "C a*", CMD_SPI_STREAM, _bitswap $out );

   my $in = _bitswap $adapter->_bulk_read( length $out );

   return Future->done( $in );
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
