#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2015-2024 -- leonerd@leonerd.org.uk

use v5.26;
use warnings;
use Object::Pad 0.800;

package Device::Chip::Adapter::BusPirate 0.24;
class Device::Chip::Adapter::BusPirate;

# Can't isa Device::Chip::Adapter because it doesn't have a 'new'
use Device::Chip::Adapter;
*make_protocol = \&Device::Chip::Adapter::make_protocol;

use Carp;

use Future::AsyncAwait;
use Future::Mutex;

use Device::BusPirate;

=head1 NAME

C<Device::Chip::Adapter::BusPirate> - a C<Device::Chip::Adapter> implementation

=head1 DESCRIPTION

This class implements the L<Device::Chip::Adapter> interface for the
I<Bus Pirate>, allowing an instance of a L<Device::Chip> driver to communicate
with the actual chip hardware by using the I<Bus Pirate> as a hardware
adapter.

=cut

=head1 CONSTRUCTOR

=cut

=head2 new

   $adapter = Device::Chip::Adapter::BusPirate->new( %args )

Returns a new instance of a C<Device::Chip::Adapter::BusPirate>. Takes the
same named arguments as L<Device::BusPirate/new>.

=cut

field $_bp;
field $_mode = undef;

BUILD ( %args )
{
   $_bp = Device::BusPirate->new( %args );
}

sub new_from_description ( $class, %args )
{
   # Whitelist known-OK constructor args
   $class->new( map { $_ => $args{$_} } qw( serial baud ) );
}

=head1 METHODS

This module provides no new methods beyond the basic API documented in
L<Device::Chip::Adapter/METHODS> at version 0.01.

Since version I<0.16> this module now supports multiple instances of the I2C
protocol, allowing multiple chips to be shared on the same bus.

=cut

sub _modename ( $mode ) { return ( ref($mode) =~ m/.*::(.*?)$/ )[0] }

async method make_protocol_GPIO
{
   $_mode and
      croak "Cannot enter GPIO protocol when " . _modename( $_mode ) . " already active";

   $_mode = await $_bp->enter_mode( "BB" );

   await $_mode->configure( open_drain => 0 );

   return Device::Chip::Adapter::BusPirate::_GPIO->new( mode => $_mode );
}

async method make_protocol_SPI
{
   $_mode and
      croak "Cannot enter SPI protocol when " . _modename( $_mode ) . " already active";

   $_mode = await $_bp->enter_mode( "SPI" );

   await $_mode->configure( open_drain => 0 );

   return Device::Chip::Adapter::BusPirate::_SPI->new( mode => $_mode );
}

async method _enter_mode_I2C
{
   return $_mode if
      $_mode and _modename( $_mode ) eq "I2C";

   $_mode and
      croak "Cannot enter I2C protocol when " . _modename( $_mode ) . " already active";

   $_mode = await $_bp->enter_mode( "I2C" );

   await $_mode->configure( open_drain => 1 );

   return $_mode;
}

field $_mutex;

async method make_protocol_I2C
{
   my $mode = await $self->_enter_mode_I2C;

   $_mutex //= Future::Mutex->new;

   return Device::Chip::Adapter::BusPirate::_I2C->new( mode => $mode, mutex => $_mutex );
}

async method make_protocol_UART
{
   $_mode and
      croak "Cannot enter UART protocol when " . _modename( $_mode ) . " already active";

   $_mode = await $_bp->enter_mode( "UART" );

   await $_mode->configure( open_drain => 0 );

   return Device::Chip::Adapter::BusPirate::_UART->new( mode => $_mode );
}

method shutdown
{
   $_mode->power( 0 )->get;
   $_bp->stop;
}

class
   Device::Chip::Adapter::BusPirate::_base {

   use Carp;
   use List::Util qw( first );

   field $_mode  :reader :param;
   field $_mutex :reader :param = undef; # only required for I2C

   method sleep ( $timeout )
   {
      $_mode->pirate->sleep( $timeout );
   }

   method power ( $on )
   {
      $_mode->power( $on );
   }

   method _find_speed ( $max_bitrate, @speeds )
   {
       return first {
           my $rate = $_;
           $rate =~ m/(.*)k$/ and $rate = 1E3 * $1;
           $rate =~ m/(.*)M$/ and $rate = 1E6 * $1;

           $rate <= $max_bitrate
       } @speeds;
   }

   # Most modes only have access to the AUX GPIO pin
   method list_gpios { return qw( AUX ) }

   method meta_gpios
   {
      return map { Device::Chip::Adapter::GPIODefinition( $_, "rw", 0 ) }
             $self->list_gpios;
   }

   method write_gpios ( $gpios )
   {
      foreach my $pin ( keys %$gpios ) {
         $pin eq "AUX" or
            croak "Unrecognised GPIO pin name $pin";

         return $_mode->aux( $gpios->{$pin} );
      }

      Future->done;
   }

   method read_gpios ( $gpios )
   {
      my @f;
      foreach my $pin ( @$gpios ) {
         $pin eq "AUX" or
            croak "Unrecognised GPIO pin name $pin";

         return $_mode->read_aux
            ->transform( done => sub { { AUX => $_[0] } } );
      }

      Future->done( {} );
   }

   # there's no more efficient way to tris_gpios than just read and ignore the result
   async sub tris_gpios
   {
      my $self = shift;
      await $self->read_gpios;
      return;
   }
}

class
   Device::Chip::Adapter::BusPirate::_GPIO :isa(Device::Chip::Adapter::BusPirate::_base);

use List::Util 1.29 qw( pairmap );

method list_gpios { return qw( MISO CS MOSI CLK AUX ) }

method write_gpios ( $gpios )
{
   # TODO: validity checking
   $self->mode->write(
      pairmap { lc $a => $b } %$gpios
   )
}

async method read_gpios ( $gpios )
{
   my $vals = await $self->mode->read( map { lc $_ } @$gpios );

   return { pairmap { uc $a => $b } %$vals };
}

class
   Device::Chip::Adapter::BusPirate::_SPI :isa(Device::Chip::Adapter::BusPirate::_base);

use Carp;

my @SPI_SPEEDS = (qw( 8M 4M 2.6M 2M 1M 250k 125k 30k ));

method configure ( %args )
{
    my $mode        = delete $args{mode};
    my $max_bitrate = delete $args{max_bitrate};

    croak "Cannot support SPI wordsize other than 8"
        if ( $args{wordsize} // 8 ) != 8;

    croak "Unrecognised configuration options: " . join( ", ", keys %args )
        if %args;

    $self->mode->configure(
        ( defined $mode ?
           ( mode  => $mode ) : () ),
        ( defined $max_bitrate ?
           ( speed => $self->_find_speed( $max_bitrate, @SPI_SPEEDS ) ) : () ),
    );
}

method readwrite ( $data )
{
   $self->mode->writeread_cs( $data );
}

method readwrite_no_ss ( $data )
{
   $self->mode->writeread( $data );
}

method assert_ss
{
   $self->mode->chip_select( 0 );
}

method release_ss
{
   $self->mode->chip_select( 1 );
}

class
    Device::Chip::Adapter::BusPirate::_I2C :isa(Device::Chip::Adapter::BusPirate::_base);

use Carp;

my @I2C_SPEEDS = (qw( 400k 100k 50k 5k ));

field $_addr;

# TODO - addr ought to be a mount option somehow
method configure ( %args )
{
    my $addr        = delete $args{addr};
    my $max_bitrate = delete $args{max_bitrate};

    croak "Unrecognised configuration options: " . join( ", ", keys %args )
        if %args;

    $_addr = $addr if defined $addr;

    my @f;

    push @f, $self->mode->configure(
       speed => $self->_find_speed( $max_bitrate, @I2C_SPEEDS )
    ) if defined $max_bitrate;

    # It's highly likely the user will want the pullups enabled here
    push @f, $self->mode->pullup( 1 );

    Future->needs_all( @f );
}

sub DESTROY
{
   my $self = shift;
   $self->mode->pullup( 0 )->get if $self->mode;
}

async method write ( $bytes )
{
   await $self->txn(sub { shift->write( $bytes ) });
}

async method read ( $len )
{
   return await $self->txn(sub { shift->read( $len ) });
}

async method write_then_read ( $write_bytes, $read_len )
{
   return await $self->txn(async sub ( $helper ){
      await $helper->write( $write_bytes );
      return await $helper->read( $read_len );
   });
}

field $_txn_helper;

method txn ( $code )
{
   defined $_addr or
      croak "Cannot ->txn without a defined addr";

   my $helper = $_txn_helper //= Device::Chip::Adapter::BusPirate::_I2C::Txn->new( mode => $self->mode, addr => $_addr );

   return $self->mutex->enter(sub {
      return $code->( $helper )->followed_by(sub ( $f ) {
         return $self->mode->stop_bit->then( sub { $f } );
      });
   });
}

class
   Device::Chip::Adapter::BusPirate::_I2C::Txn {

   field $_mode :param;
   field $_addr :param;

   async method write ( $bytes )
   {
      await $_mode->start_bit;
      await $_mode->write( chr( $_addr << 1 | 0 ) . $bytes );
   }

   async method read ( $len )
   {
      await $_mode->start_bit;
      await $_mode->write( chr( $_addr << 1 | 1 ) );
      return await $_mode->read( $len );
   }
}

class
   Device::Chip::Adapter::BusPirate::_UART :isa(Device::Chip::Adapter::BusPirate::_base);

use Carp;

method configure ( %args )
{
   return $self->mode->configure(
      baud   => $args{baudrate},
      bits   => $args{bits},
      parity => $args{parity},
      stop   => $args{stop},
   );
}

method write ( $bytes )
{
   return $self->mode->write( $bytes );
}

method read { croak "Device::BusPirate does not support read on UART" }

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
