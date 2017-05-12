#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2014-2015 -- leonerd@leonerd.org.uk

package Device::BusPirate;

use strict;
use warnings;

our $VERSION = '0.13';

use Carp;

use Future::Mutex;
use Future::Utils qw( repeat );
use IO::Termios;
use Time::HiRes qw( time );

use Module::Pluggable
   search_path => "Device::BusPirate::Mode",
   require     => 1,
   sub_name    => "modes";
my %MODEMAP = map { $_->MODE => $_ } __PACKAGE__->modes;

use Module::Pluggable
   search_path => "Device::BusPirate::Chip",
   require     => 1,
   sub_name    => "chips";
my %CHIPMAP = map { $_->can( "CHIP" ) ? ( $_->CHIP => $_ ) : () } __PACKAGE__->chips;

use Struct::Dumb qw( readonly_struct );

readonly_struct Reader => [qw( length future )];
readonly_struct Alarm  => [qw( time future )];

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
device. For simple synchronous situations, the class may be used on its own,
and any method that returns a C<Future> instance should immediately call the
C<get> method on that instance to wait for and obtain the eventual result:

 my $spi = $pirate->enter_mode( "SPI" )->get;

 $spi->power( 1 )->get;
 my $input = $spi->writeread_cs( $output )->get;

A truely-asynchronous program would be built using a subclass that overrides
the basic C<read> and C<sleep> methods for some event loop or similar; these
can then be chained using the C<then> method:

 my $input = $pirate->enter_mode( "SPI" )
   ->then( sub {
      my ( $spi ) = @_;

      $spi->power( 1 )->then( sub {
         $spi->writeread_cs( $output );
      });
   });

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

   my $serial = $args{serial} || BUS_PIRATE;
   my $baud   = $args{baud} || 115200;

   my $fh = IO::Termios->open( $serial, "$baud,8,n,1" )
      or croak "Cannot open serial port $serial - $!";

   $fh->setflag_icanon( 0 );
   $fh->setflag_echo( 0 );

   $fh->blocking( 0 );

   return bless {
      fh => $fh,
      alarms => [],
      readers => [],
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

   $self->{fh}->syswrite( $buf );
}

# For Modes
sub read
{
   my $self = shift;
   my ( $n, $name, $timeout ) = @_;

   push @{ $self->{readers} }, Reader( $n, my $f = $self->_new_future );

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

   my $alarms = $self->{alarms};

   my $until = time() + $timeout;

   my $pos = 0;
   $pos++ while $pos < @$alarms and $alarms->[$pos]->time < $until;

   splice @$alarms, $pos, 0, my $alarm = Alarm( $until, my $f = $self->_new_future );

   $f->on_cancel( sub {
      $self->{alarms} = [ grep { $_ != $alarm } @{ $self->{alarms} } ];
   });

   return $f;
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

=back

Once a mode object has been created, most of the interaction with the device
would be done using that mode object, as it will have methods relating to the
specifics of that hardware mode. See the classes listed above for more
information.

=cut

sub enter_mode
{
   my $self = shift;
   my ( $modename ) = @_;

   my $modeclass = $MODEMAP{$modename} or
      croak "Unrecognised mode '$modename'";

   $self->start->then( sub {
      ( $self->{mode} = $modeclass->new( $self ) )->start;
   });
}

=head2 mount_chip

   $chip = $pirate->mount_chip( $chipname, %opts )->get

B<Note>: this method is now deprecated in favour of the L<Device::Chip>
interface. This distribution provides a class,
L<Device::Chip::Adapter::BusPirate>, suitable to connect an instance of the
L<Device::Chip> interface to. Any previously-written Bus Pirate-specific
chip driver classes should now be changed to target the generic
L<Device::Chip> interface instead.

Constructs a "chip" object; a helper designed to communicate with some
particular hardware device (usually a specific chip) attached to the Bus
Pirate. This will be a subclass of L<Device::BusPirate::Chip>, and will likely
provide various methods specific to the operation of that particular device.

C<$chipname> should match the name declared by the chip module, and other
options passed in C<%opts> will be passed to its constructor.

=cut

sub mount_chip
{
   my $self = shift;
   my ( $chipname, %opts ) = @_;

   my $chipclass = $CHIPMAP{$chipname} or
      croak "Unrecognised chip '$chipname'";

   my $chip = $self->{chip} = $chipclass->new( $self, %opts );

   $self->enter_mode( $chip->MODE )
      ->then( sub {
         my ( $mode ) = @_;
         $chip->mount( $mode )
      })
      ->then_done( $chip );
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
      $self->read( 5, "start", 2.5 )->then( sub {
         my ( $buf ) = @_;
         return Future->done( ( $self->{version} ) = $buf =~ m/^BBIO(\d)/ );
      }),
      repeat {
         $self->write( "\0" );
         $self->sleep( 0.05 );
      } foreach => [ 1 .. 20 ],
        while => sub { not shift->failure },
        otherwise => sub {
           Future->fail( "Timed out waiting for device to enter bitbang mode" )
        },
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

# Future support
sub _new_future
{
   my $self = shift;
   return Device::BusPirate::_Future->new( $self );
}

package Device::BusPirate::_Future;
use base qw( Future );
use Carp;

use Time::HiRes qw( time );

sub new
{
   my $proto = shift;
   my $self = $proto->SUPER::new;
   $self->{bp} = ref $proto ? $proto->{bp} : shift;
   return $self;
}

sub await
{
   my $bp = shift->{bp};

   my $alarm  = $bp->{alarms}[0];
   my $reader = $bp->{readers}[0];

   my $fh = $bp->{fh};

   croak "Cannot await with nothing to do" unless $alarm or $reader;

   my $buf = '';

   while(1) {
      if( $reader and length $buf >= $reader->length ) {
         printf STDERR "PIRATE << %v02x\n", $buf if Device::BusPirate::PIRATE_DEBUG > 1;
         shift @{ $bp->{readers} };
         $reader->future->done( substr $buf, 0, $reader->length, "" );
         return;
      }

      my $timeout = $alarm ? $alarm->time - time() : undef;
      my $rvec = '';
      vec( $rvec, $fh->fileno, 1 ) = 1 if $reader;

      if( select( $rvec, undef, undef, $timeout ) ) {
         $fh->sysread( $buf, $reader->length - length $buf, length $buf );
      }
      elsif( $timeout ) {
         shift @{ $bp->{alarms} };
         $alarm->future->done;
         return;
      }
   }
}

=head1 TODO

=over 4

=item *

More modes - UART, 1-wire, raw-wire

=item *

Documentation/examples/actual implementations of truely-async subclass.

=item *

PWM, AUX frequency measurement and ADC support.

=back

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
