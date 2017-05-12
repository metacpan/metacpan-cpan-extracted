#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2015-2016 -- leonerd@leonerd.org.uk

package Device::Chip::Adapter::BusPirate;

use strict;
use warnings;
use base qw( Device::Chip::Adapter );

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

sub new
{
   my $class = shift;

   my $bp = Device::BusPirate->new( @_ );

   bless {
      bp => $bp,
   }, $class;
}

sub new_from_description
{
   my $class = shift;
   my %args = @_;
   # Whitelist known-OK constructor args
   $class->new( map { $_ => $args{$_} } qw( serial baud ) );
}

=head1 METHODS

This module provides no new methods beyond the basic API documented in
L<Device::Chip::Adapter/METHODS> at version 0.01.

=cut

sub make_protocol_GPIO
{
   my $self = shift;

   $self->{bp}->enter_mode( "BB" )->then( sub {
      my ( $mode ) = @_;
      $self->{mode} = $mode;

      $mode->configure( open_drain => 0 )
         ->then_done(
            Device::Chip::Adapter::BusPirate::_GPIO->new( $mode )
         );
   });
}

sub make_protocol_SPI
{
   my $self = shift;

   $self->{bp}->enter_mode( "SPI" )->then( sub {
      my ( $mode ) = @_;
      $self->{mode} = $mode;

      $mode->configure( open_drain => 0 )
         ->then_done(
            Device::Chip::Adapter::BusPirate::_SPI->new( $mode )
         );
   });
}

sub make_protocol_I2C
{
    my $self = shift;

    $self->{bp}->enter_mode( "I2C" )->then( sub {
        my ( $mode ) = @_;
        $self->{mode} = $mode;

        $mode->configure( open_drain => 1 )
            ->then_done(
                Device::Chip::Adapter::BusPirate::_I2C->new( $mode )
            );
    });
}

sub shutdown
{
   my $self = shift;
   $self->{mode}->power( 0 )->get;
   $self->{bp}->stop;
}

package
   Device::Chip::Adapter::BusPirate::_base;

use Carp;
use List::Util qw( first );

sub new
{
   my $class = shift;
   my ( $mode ) = @_;

   bless { mode => $mode }, $class;
}

sub sleep
{
   my $self = shift;
   $self->{mode}->pirate->sleep( @_ );
}

sub power
{
   my $self = shift;
   $self->{mode}->power( @_ );
}

sub _find_speed
{
   shift;
   my ( $max_bitrate, @speeds ) = @_;

    return first {
        my $rate = $_;
        $rate =~ s/k$/000/;
        $rate =~ s/M$/000000/;

        $rate <= $max_bitrate
    } @speeds;
}

# Most modes only have access to the AUX GPIO pin
sub list_gpios { return qw( AUX ) }

sub write_gpios
{
   my $self = shift;
   my ( $gpios ) = @_;

   my $mode = $self->{mode};

   foreach my $pin ( keys %$gpios ) {
      $pin eq "AUX" or
         croak "Unrecognised GPIO pin name $pin";

      return $mode->aux( $gpios->{$pin} );
   }

   Future->done;
}

sub read_gpios
{
   my $self = shift;
   my ( $gpios ) = @_;

   my $mode = $self->{mode};

   my @f;
   foreach my $pin ( @$gpios ) {
      $pin eq "AUX" or
         croak "Unrecognised GPIO pin name $pin";

      return $mode->read_aux
         ->transform( done => sub { { AUX => $_[0] } } );
   }

   Future->done( {} );
}

# there's no more efficient way to tris_gpios than just read and ignore the result
sub tris_gpios
{
   my $self = shift;
   $self->read_gpios->then_done();
}

package
   Device::Chip::Adapter::BusPirate::_GPIO;
use base qw( Device::Chip::Adapter::BusPirate::_base );

use List::Util 1.29 qw( pairmap );

sub list_gpios { return qw( MISO CS MOSI CLK AUX ) }

sub write_gpios
{
   my $self = shift;
   my ( $gpios ) = @_;

   my $mode = $self->{mode};

   # TODO: validity checking
   $mode->write(
      pairmap { lc $a => $b } %$gpios
   )
}

sub read_gpios
{
   my $self = shift;
   my ( $gpios ) = @_;

   my $mode = $self->{mode};

   $mode->read( map { lc $_ } @$gpios )->then( sub {
      my ( $vals ) = @_;
      Future->done( { pairmap { uc $a => $b } %$vals } );
   });
}

package
   Device::Chip::Adapter::BusPirate::_SPI;
use base qw( Device::Chip::Adapter::BusPirate::_base );

use Carp;

my @SPI_SPEEDS = (qw( 8M 4M 2.6M 2M 1M 250k 125k 30k ));

sub configure
{
    my $self = shift;
    my %args = @_;

    my $mode        = delete $args{mode};
    my $max_bitrate = delete $args{max_bitrate};

    croak "Unrecognised configuration options: " . join( ", ", keys %args )
        if %args;

    $self->{mode}->configure(
        ( defined $mode ?
           ( mode  => $mode ) : () ),
        ( defined $max_bitrate ?
           ( speed => $self->_find_speed( $max_bitrate, @SPI_SPEEDS ) ) : () ),
    );
}

sub readwrite
{
   my $self = shift;
   my ( $data ) = @_;

   $self->{mode}->writeread_cs( $data );
}

sub write
{
   my $self = shift;
   my ( $data ) = @_;

   # BP has no write-without-read method
   $self->{mode}->writeread_cs( $data )
      ->then_done();
}

package
    Device::Chip::Adapter::BusPirate::_I2C;
use base qw( Device::Chip::Adapter::BusPirate::_base );

use Carp;

my @I2C_SPEEDS = (qw( 400k 100k 50k 5k ));

# TODO - addr ought to be a mount option somehow
sub configure
{
    my $self = shift;
    my %args = @_;

    my $addr        = delete $args{addr};
    my $max_bitrate = delete $args{max_bitrate};

    croak "Unrecognised configuration options: " . join( ", ", keys %args )
        if %args;

    $self->{addr} = $addr if defined $addr;

    my @f;

    push @f, $self->{mode}->configure(
       speed => $self->_find_speed( $max_bitrate, @I2C_SPEEDS )
    ) if defined $max_bitrate;

    # It's highly likely the user will want the pullups enabled here
    push @f, $self->{mode}->pullup( 1 );

    Future->needs_all( @f );
}

sub write
{
    my $self = shift;
    $self->{mode}->send( $self->{addr}, @_ );
}

sub write_then_read
{
    my $self = shift;
    $self->{mode}->send_then_recv( $self->{addr}, @_ );
}

sub read
{
   my $self = shift;
   $self->{mode}->recv( $self->{addr}, @_ );
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
