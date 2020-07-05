#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2014-2019 -- leonerd@leonerd.org.uk

package Device::BusPirate;

use strict;
use warnings;

our $VERSION = '0.20';

use Carp;

use Fcntl qw( O_NOCTTY O_NDELAY );
use Future::AsyncAwait;
use Future::Mutex;
use Future::IO 0.04; # ->syswrite_exactly
use IO::Termios 0.07; # cfmakeraw
use Time::HiRes qw( time );

use Module::Pluggable
   search_path => "Device::BusPirate::Mode",
   except      => qr/^Device::BusPirate::Mode::_/,
   require     => 1,
   sub_name    => "modes";
my %MODEMAP = map { $_->MODE => $_ } __PACKAGE__->modes;

use constant BUS_PIRATE => $ENV{BUS_PIRATE} || "/dev/ttyUSB0";
use constant PIRATE_DEBUG => $ENV{PIRATE_DEBUG} // 0;

=head1 NAME

C<Device::BusPirate> - interact with a F<Bus Pirate> device

=head1 DESCRIPTION

This module allows a program to interact with a F<Bus Pirate> hardware
electronics debugging device, attached over a USB-emulated serial port. In the
following description, the reader is assumed to be generally aware of the
device and its capabilities. For more information about the F<Bus Pirate> see:

=over 2

L<http://dangerousprototypes.com/docs/Bus_Pirate>

=back

This module and its various component modules are based on L<Future>, allowing
either synchronous or asynchronous communication with the attached hardware
device.

To use it synchronously, call the C<get> method of any returned C<Future>
instances to obtain the eventual result:

   my $spi = $pirate->enter_mode( "SPI" )->get;

   $spi->power( 1 )->get;
   my $input = $spi->writeread_cs( $output )->get;

A truely-asynchronous program would use the futures more conventionally,
perhaps by using C<< ->then >> chaining:

   my $input = $pirate->enter_mode( "SPI" )
     ->then( sub {
        my ( $spi ) = @_;

        $spi->power( 1 )->then( sub {
           $spi->writeread_cs( $output );
        });
     });

This module uses L<Future::IO> for its underlying IO operations, so using it
in a program would require the event system to integrate with C<Future::IO>
appropriately.

=cut

=head1 CONSTRUCTOR

=cut

=head2 new

   $pirate = Device::BusPirate->new( %args )

Returns a new C<Device::BusPirate> instance to communicate with the given
device. Takes the following named arguments:

=over 4

=item serial => STRING

Path to the serial port device node the Bus Pirate is attached to. If not
supplied, the C<BUS_PIRATE> environment variable is used; falling back on a
default of F</dev/ttyUSB0>.

=item baud => INT

Serial baud rate to communicate at. Normally it should not be necessary to
change this from its default of C<115200>.

=back

=cut

sub new
{
   my $class = shift;
   my %args = @_;

   # undocumented 'fh 'argument for unit testing
   my $fh = $args{fh} // do {
      my $serial = $args{serial} || BUS_PIRATE;
      my $baud   = $args{baud} || 115200;

      my $fh = IO::Termios->open( $serial, "$baud,8,n,1", O_NOCTTY|O_NDELAY )
         or croak "Cannot open serial port $serial - $!";

      for( $fh->getattr ) {
         $_->cfmakeraw();
         $_->setflag_clocal( 1 );

         $fh->setattr( $_ );
      }

      $fh->blocking( 0 );

      $fh;
   };

   return bless {
      fh => $fh,
   }, $class;
}

=head1 METHODS

The following methods documented with a trailing call to C<< ->get >> return
L<Future> instances.

=cut

# For Modes
sub write
{
   my $self = shift;
   my ( $buf ) = @_;

   printf STDERR "PIRATE >> %v02x\n", $buf if PIRATE_DEBUG > 1;

   my $f = Future::IO->syswrite_exactly( $self->{fh}, $buf );

   return $f if wantarray;
   $f->on_ready( sub { undef $f } );
}

async sub write_expect_ack
{
   my $self = shift;
   my ( $out, $name, $timeout ) = @_;

   await $self->write_expect_acked_data( $out, 0, $name, $timeout );
   return;
}

async sub write_expect_acked_data
{
   my $self = shift;
   my ( $out, $readlen, $name, $timeout ) = @_;

   $self->write( $out );
   my $buf = await $self->read( 1 + $readlen, $name, $timeout );

   substr( $buf, 0, 1, "" ) eq "\x01" or
      die "Expected ACK response to $name";

   return $buf;
}

# For Modes
sub read
{
   my $self = shift;
   my ( $n, $name, $timeout ) = @_;

   return Future->done( "" ) unless $n;

   my $buf = "";
   my $f = Future::IO->sysread_exactly( $self->{fh}, $n );

   $f->on_done( sub {
      printf STDERR "PIRATE << %v02x\n", $_[0];
   }) if Device::BusPirate::PIRATE_DEBUG > 1;

   return $f unless defined $name;

   return Future->wait_any(
      $f,
      $self->sleep( $timeout // 2 )->then_fail( "Timeout waiting for $name" ),
   );
}

=head2 sleep

   $pirate->sleep( $timeout )->get

Returns a C<Future> that will become ready after the given timeout (in
seconds), unless it is cancelled first.

=cut

sub sleep
{
   my $self = shift;
   my ( $timeout ) = @_;

   return Future::IO->sleep( $timeout );
}

=head2 enter_mutex

   @result = $pirate->enter_mutex( $code )->get

Acts as a mutex lock, to ensure only one block of code runs at once. Calls to
C<enter_mutex> will be queued up; each C<$code> block will only be invoked
once the C<Future> returned from the previous has completed.

Mode implementations should use this method to guard complete wire-level
transactions, ensuring that multiple concurrent ones will not collide with
each other.

=cut

sub enter_mutex
{
   my $self = shift;
   my ( $code ) = @_;

   ( $self->{mutex} //= Future::Mutex->new )->enter( $code );
}

=head2 enter_mode

   $mode = $pirate->enter_mode( $modename )->get

Switches the attached device into the given mode, and returns an object to
represent that hardware mode to interact with. This will be an instance of a
class depending on the given mode name.

=over 4

=item C<BB>

The bit-banging mode. Returns an instance of L<Device::BusPirate::Mode::BB>.

=item C<I2C>

The I2C mode. Returns an instance of L<Device::BusPirate::Mode::I2C>.

=item C<SPI>

The SPI mode. Returns an instance of L<Device::BusPirate::Mode::SPI>.

=item C<UART>

The UART mode. Returns an instance of L<Device::BusPirate::Mode::UART>.

=back

Once a mode object has been created, most of the interaction with the device
would be done using that mode object, as it will have methods relating to the
specifics of that hardware mode. See the classes listed above for more
information.

=cut

async sub enter_mode
{
   my $self = shift;
   my ( $modename ) = @_;

   my $modeclass = $MODEMAP{$modename} or
      croak "Unrecognised mode '$modename'";

   await $self->start;

   $self->{mode} = $modeclass->new( $self );
   await $self->{mode}->start;
}

=head2 start

   $pirate->start->get

Starts binary IO mode on the F<Bus Pirate> device, enabling the module to
actually communicate with it. Normally it is not necessary to call this method
explicitly as it will be done by the setup code of the mode object.

=cut

sub start
{
   my $self = shift;

   Future->wait_any(
      (async sub {
         my $buf = await $self->read( 5, "start", 2.5 );
         ( $self->{version} ) = $buf =~ m/^BBIO(\d)/;
         return $self->{version};
      })->(),
      (async sub {
         foreach my $i ( 1 .. 20 ) {
            $self->write( "\0" );
            await $self->sleep( 0.05 );
         }
         die "Timed out waiting for device to enter bitbang mode";
      })->(),
   );
}

=head2 stop

   $pirate->stop

Stops binary IO mode on the F<Bus Pirate> device and returns it to user
terminal mode. It may be polite to perform this at the end of a program to
return it to a mode that a user can interact with normally on a terminal.

=cut

sub stop
{
   my $self = shift;

   $self->write( "\0\x0f" );
}

=head1 TODO

=over 4

=item *

More modes - 1-wire, raw-wire

=item *

AUX frequency measurement and ADC support.

=back

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
