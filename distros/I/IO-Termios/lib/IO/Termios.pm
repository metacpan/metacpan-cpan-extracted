#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2008-2018 -- leonerd@leonerd.org.uk

package IO::Termios;

use v5.10;
use strict;
use warnings;
use base qw( IO::Handle );

use Carp;

our $VERSION = '0.09';

use Exporter ();

use Fcntl qw( O_RDWR );
use POSIX qw( TCSANOW );
use IO::Tty;
use IO::Tty::Constant qw(
   TIOCMGET TIOCMSET TIOCMBIC TIOCMBIS
   TIOCM_DTR TIOCM_DSR TIOCM_RTS TIOCM_CTS TIOCM_CD TIOCM_RI
);

# Linux can support finer-grained control of baud rates if we let it
use constant HAVE_LINUX_TERMIOS2 => eval { require Linux::Termios2; };

=head1 NAME

C<IO::Termios> - supply F<termios(3)> methods to C<IO::Handle> objects

=head1 SYNOPSIS

   use IO::Termios;

   my $term = IO::Termios->open( "/dev/ttyS0", "9600,8,n,1" )
      or die "Cannot open ttyS0 - $!";

   $term->print( "Hello world\n" ); # Still an IO::Handle

   while( <$term> ) {
      print "A line from ttyS0: $_";
   }

=head1 DESCRIPTION

This class extends the generic C<IO::Handle> object class by providing methods
which access the system's terminal control C<termios(3)> operations. These
methods are primarily of interest when dealing with TTY devices, including
serial ports.

The flag-setting methods will apply to any TTY device, such as a pseudo-tty,
and are useful for controlling such flags as the C<ECHO> flag, to disable
local echo.

   my $stdin = IO::Termios->new( \*STDIN );
   $stdin->setflag_echo( 0 );

When dealing with a serial port the line mode method is useful for setting the
basic serial parameters such as baud rate, and the modem line control methods
can be used to access the hardware handshaking lines.

   my $ttyS0 = IO::Termios->open( "/dev/ttyS0" );
   $ttyS0->set_mode( "19200,8,n,1" );
   $ttyS0->set_modem({ dsr => 1, cts => 1 });

=head2 Upgrading STDIN/STDOUT/STDERR

If you pass the C<-upgrade> option at C<import> time, any of STDIN, STDOUT or
STDERR that are found to be TTY wrappers are automatically upgraded into
C<IO::Termios> instances.

   use IO::Termios -upgrade;

   STDIN->setflag_echo(0);

=head2 Arbitrary Baud Rates on Linux

F<Linux> supports a non-POSIX extension to the usual C<termios> interface,
which allows arbitrary baud rates to be set. C<IO::Termios> can automatically
make use of this ability if the L<Linux::Termios2> module is installed. If so,
this will be used automatically and transparently, to allow the C<set*baud>
methods to set any rate allowed by the kernel/driver. If not, then only the
POSIX-compatible rates may be used.

=cut

sub import
{
   my $pkg = shift;
   my @symbols = @_;
   my $caller = caller;

   my $upgrade;
   @symbols = grep { $_ eq "-upgrade" ? ( $upgrade++, 0 ) : 1 } @symbols;

   if( $upgrade ) {
      foreach my $fh ( *STDIN{IO}, *STDOUT{IO}, *STDERR{IO} ) {
         IO::Termios::Attrs->new->getattr( $fh->fileno ) or next;

         bless $fh, __PACKAGE__;
      }
   }
}

=head1 CONSTRUCTORS

=cut

=head2 new

   $term = IO::Termios->new()

Construct a new C<IO::Termios> object around the terminal for the program.
This is found by checking if any of C<STDIN>, C<STDOUT> or C<STDERR> are a
terminal. The first one that's found is used. An error occurs if no terminal
can be found by this method.

=head2 new (handle)

   $term = IO::Termios->new( $handle )

Construct a new C<IO::Termios> object around the given filehandle.

=cut

sub new
{
   my $class = shift;
   my ( $handle ) = @_;

   if( not $handle ) {
      # Try to find a terminal - STDIN, STDOUT, STDERR are good candidates
      return $class->SUPER::new_from_fd( fileno STDIN,  "w+" ) if -t STDIN;
      return $class->SUPER::new_from_fd( fileno STDOUT, "w+" ) if -t STDOUT;
      return $class->SUPER::new_from_fd( fileno STDERR, "w+" ) if -t STDERR;

      die "TODO: Need to find a terminal\n";
   }

   croak '$handle is not a filehandle' unless defined fileno $handle;

   my $self = $class->SUPER::new_from_fd( $handle, "w+" );

   return $self;
}

=head2 open

   $term = IO::Termios->open( $path, $modestr, $flags )

Open the given path, and return a new C<IO::Termios> object around the
filehandle. If the C<open> call fails, C<undef> is returned.

If C<$modestr> is provided, the constructor will pass it to the C<set_mode>
method before returning.

If C<$flags> is provided, it will be passed on to the underlying C<sysopen()>
call used to open the filehandle. It should contain a bitwise-or combination
of C<O_*> flags from the L<Fcntl> module - for example C<O_NOCTTY> or
C<O_NDELAY>. The value C<O_RDWR> will be added to this; the caller does not
need to specify it directly. For example:

   use Fcntl qw( O_NOCTTY O_NDELAY );

   $term = IO::Termios->open( "/dev/ttyS0", O_NOCTTY|O_NDELAY );
   $term->setflag_clocal( 1 );
   $term->blocking( 1 );

=cut

sub open
{
   my $class = shift;
   my ( $path, $modestr, $flags ) = @_;

   $flags //= 0;

   sysopen my $tty, $path, O_RDWR | $flags, or return undef;
   my $self = $class->new( $tty ) or return undef;

   $self->set_mode( $modestr ) if defined $modestr;

   return $self;
}

=head1 METHODS

=cut

=head2 getattr

   $attrs = $term->getattr

Makes a C<tcgetattr()> call on the underlying filehandle, and returns a
C<IO::Termios::Attrs> object.

If the C<tcgetattr()> call fails, C<undef> is returned.

=cut

sub getattr
{
   my $self = shift;

   my $attrs = IO::Termios::Attrs->new;
   $attrs->getattr( $self->fileno ) or return undef;

   return $attrs;
}

=head2 setattr

   $term->setattr( $attrs )

Makes a C<tcsetattr()> call on the underlying file handle, setting attributes
from the given C<IO::Termios::Attrs> object.

If the C<tcsetattr()> call fails, C<undef> is returned. Otherwise, a true
value is returned.

=cut

sub setattr
{
   my $self = shift;
   my ( $attrs ) = @_;

   return $attrs->setattr( $self->fileno, TCSANOW );
}

=head2 set_mode

=head2 get_mode

   $term->set_mode( $modestr )

   $modestr = $term->get_mode

Accessor for the derived "mode string", which is a comma-joined concatenation
of the baud rate, character size, parity mode, and stop size in a format such
as

   19200,8,n,1

When setting the mode string, trailing components may be omitted meaning their
value will not be affected.

=cut

sub set_mode
{
   my $self = shift;
   my ( $modestr ) = @_;

   my ( $baud, $csize, $parity, $stop ) = split m/,/, $modestr;

   my $attrs = $self->getattr;

   $attrs->setbaud  ( $baud   ) if defined $baud;
   $attrs->setcsize ( $csize  ) if defined $csize;
   $attrs->setparity( $parity ) if defined $parity;
   $attrs->setstop  ( $stop   ) if defined $stop;

   $self->setattr( $attrs );
}

sub get_mode
{
   my $self = shift;

   my $attrs = $self->getattr;
   return join ",",
      $attrs->getibaud,
      $attrs->getcsize,
      $attrs->getparity,
      $attrs->getstop;
}

=head2 tiocmget

=head2 tiocmset

   $bits = $term->tiocmget

   $term->tiocmset( $bits )

Accessor for the modem line control bits. Takes or returns a bitmask of
values.

=cut

sub tiocmget
{
   my $self = shift;

   my $bitstr = pack "i!", 0;
   ioctl( $self, TIOCMGET, $bitstr ) or
      croak "Cannot ioctl(TIOCMGET) - $!";

   return unpack "i!", $bitstr;
}

sub tiocmset
{
   my $self = shift;
   my ( $bits ) = @_;

   my $bitstr = pack "i!", $bits;
   ioctl( $self, TIOCMSET, $bitstr )
      or croak "Cannot ioctl(TIOCMSET) - $!";
}

=head2 tiocmbic

=head2 tiocmbis

   $term->tiocmbic( $bits )

   $term->tiocmbis( $bits )

Bitwise mutator methods for the modem line control bits. C<tiocmbic> will
clear just the bits provided and leave the others unchanged; C<tiocmbis> will
set them.

=cut

sub tiocmbic
{
   my $self = shift;
   my ( $bits ) = @_;

   my $bitstr = pack "i!", $bits;
   ioctl( $self, TIOCMBIC, $bitstr )
      or croak "Cannot ioctl(TIOCMBIC) - $!";
}

sub tiocmbis
{
   my $self = shift;
   my ( $bits ) = @_;

   my $bitstr = pack "i!", $bits;
   ioctl( $self, TIOCMBIS, $bitstr )
      or croak "Cannot ioctl(TIOCMBIS) - $!";
}

my %_bit2modem;
my %_modem2bit;
foreach (qw( dtr dsr rts cts cd ri )) {
   my $bit = IO::Tty::Constant->${\"TIOCM_\U$_"};
   $_bit2modem{$bit} = $_;
   $_modem2bit{$_}   = $bit;

   my $getmodem = sub {
      my $self = shift;
      return !!($self->tiocmget & $bit);
   };
   my $setmodem = sub {
      my $self = shift;
      my ( $set ) = @_;
      $set ? $self->tiocmbis( $bit )
           : $self->tiocmbic( $bit );
   };

   no strict 'refs';
   *{"getmodem_$_"} = $getmodem;
   *{"setmodem_$_"} = $setmodem;
}

=head2 get_modem

   $flags = $term->get_modem

Returns a hash reference containing named flags corresponding to the modem
line control bits. Any bit that is set will yield a key in the returned hash
of the same name. The bit names are

   dtr dsr rts cts cd ri

=cut

sub get_modem
{
   my $self = shift;
   my $bits = $self->tiocmget;

   return +{
      map { $bits & $_modem2bit{$_} ? ( $_ => 1 ) : () } keys %_modem2bit
   };
}

=head2 set_modem

   $term->set_modem( $flags )

Changes the modem line control bit flags as given by the hash reference. Each
bit to be changed should be represented by a key in the C<$flags> hash of the
names given above. False values will be cleared, true values will be set.
Other flags will not be altered.

=cut

sub set_modem
{
   my $self = shift;
   my ( $flags ) = @_;

   my $bits = $self->tiocmget;
   foreach ( keys %$flags ) {
      my $bit = $_modem2bit{$_} or croak "Unrecognised modem line control bit $_";

      $flags->{$_} ? ( $bits |=  $bit )
                   : ( $bits &= ~$bit );
   }

   $self->tiocmset( $bits );
}

=head2 getmodem_BIT

=head2 setmodem_BIT

   $set = $term->getmodem_BIT

   $term->setmodem_BIT( $set )

Accessor methods for each of the modem line control bits. A set of methods
exists for each of the named modem control bits given above.

=head1 FLAG-ACCESSOR METHODS

Theses methods are implemented in terms of the lower level methods, but
provide an interface which is more abstract, and easier to re-implement on
other non-POSIX systems. These should be used in preference to the lower ones.

For efficiency, when getting or setting a large number of flags, it may be
more efficient to call C<getattr>, then operate on the returned object,
before possibly passing it to C<setattr>. The returned C<IO::Termios::Attrs>
object supports the same methods as documented here.

The following two sections of code are therefore equivalent, though the latter
is more efficient as it only calls C<setattr> once.

   $term->setbaud( 38400 );
   $term->setcsize( 8 );
   $term->setparity( 'n' );
   $term->setstop( 1 );

Z<>

   my $attrs = $term->getattr;
   $attrs->setbaud( 38400 );
   $attrs->setcsize( 8 );
   $attrs->setparity( 'n' );
   $attrs->setstop( 1 );
   $term->setattr( $attrs );

However, a convenient shortcut method is provided for the common case of
setting the baud rate, character size, parity and stop size all at the same
time. This is C<set_mode>:

   $term->set_mode( "38400,8,n,1" );

=cut

=head2 getibaud

=head2 getobaud

=head2 setibaud

=head2 setobaud

=head2 setbaud

   $baud = $term->getibaud

   $baud = $term->getobaud

   $term->setibaud( $baud )

   $term->setobaud( $baud )

   $term->setbaud( $baud )

Convenience accessors for the C<ispeed> and C<ospeed>. C<$baud> is an integer
directly giving the line rate, instead of one of the C<BI<nnn>> constants.

=head2 getcsize

=head2 setcsize

   $bits = $term->getcsize

   $term->setcsize( $bits )

Convenience accessor for the C<CSIZE> bits of C<c_cflag>. C<$bits> is an
integer 5 to 8.

=head2 getparity

=head2 setparity

   $parity = $term->getparity

   $term->setparity( $parity )

Convenience accessor for the C<PARENB> and C<PARODD> bits of C<c_cflag>.
C<$parity> is C<n>, C<o> or C<e>.

=head2 getstop

=head2 setstop

   $stop = $term->getstop

   $term->setstop( $stop )

Convenience accessor for the C<CSTOPB> bit of C<c_cflag>. C<$stop> is 1 or 2.

=head2 cfmakeraw

   $term->cfmakeraw

I<Since version 0.07.>

Adjusts several bit flags to put the terminal into a "raw" mode. Input is
available a character at a time, echo is disabled, and all special processing
of input and output characters is disabled.

=cut

foreach my $name (qw( ibaud obaud csize parity stop )) {
   my $getmethod = "get$name";
   my $setmethod = "set$name";

   no strict 'refs';
   *$getmethod = sub {
      my ( $self ) = @_;
      my $attrs = $self->getattr or croak "Cannot getattr - $!";
      return $attrs->$getmethod;
   };
   *$setmethod = sub {
      my ( $self, $val ) = @_;
      my $attrs = $self->getattr or croak "Cannot getattr - $!";
      $attrs->$setmethod( $val );
      $self->setattr( $attrs ) or croak "Cannot setattr - $!";
   };
}

foreach my $method (qw( setbaud cfmakeraw )) {
   no strict 'refs';
   *$method = sub {
      my $self = shift;
      my $attrs = $self->getattr or croak "Cannot getattr - $!";
      $attrs->$method( @_ );
      $self->setattr( $attrs ) or croak "Cannot setattr - $!";
   };
}

=head2 getflag_I<FLAG>

=head2 setflag_I<FLAG>

   $mode = $term->getflag_FLAG

   $term->setflag_FLAG( $mode )

Accessors for various control flags. The following methods are defined for
specific flags:

=head3 inlcr

I<Since version 0.09.>

The C<INLCR> bit of the C<c_iflag>. This translates NL to CR on input.

=head3 igncr

I<Since version 0.09.>

The C<IGNCR> bit of the C<c_iflag>. This ignores incoming CR characters.

=head3 icrnl

I<Since version 0.09.>

The C<ICRNL> bit of the C<c_iflag>. This translates CR to NL on input, unless
C<IGNCR> is also set.

=head3 ignbrk

I<Since version 0.09.>

The C<IGNBRK> bit of the C<c_iflag>. This controls whether incoming break
conditions are ignored entirely.

=head3 brkint

I<Since version 0.09.>

The C<BRKINT> bit of the C<c_iflag>. This controls whether non-ignored
incoming break conditions result in a C<SIGINT> signal being delivered to the
process. If not, such a condition reads as a nul byte.

=head3 parmrk

I<Since version 0.09.>

The C<PARMRK> bit of the C<c_iflag>. This controls how parity errors and break
conditions are handled.

=head3 opost

I<Since version 0.07.>

The C<OPOST> bit of the C<c_oflag>. This enables system-specific
post-processing on output.

=head3 cread

The C<CREAD> bit of the C<c_cflag>. This enables the receiver.

=head3 hupcl

The C<HUPCL> bit of the C<c_cflag>. This lowers the modem control lines after
the last process closes the device.

=head3 clocal

The C<CLOCAL> bit of the C<c_cflag>. This controls whether local mode is
enabled; which if set, ignores modem control lines.

=head3 icanon

The C<ICANON> bit of C<c_lflag>. This is called "canonical" mode and controls
whether the terminal's line-editing feature will be used to return a whole
line (if true), or if individual bytes from keystrokes will be returned as
they are available (if false).

=head3 echo

The C<ECHO> bit of C<c_lflag>. This controls whether input characters are
echoed back to the terminal.

=cut

my @flags = (
   # iflag
   [ inlcr  => qw( INLCR i ) ],
   [ igncr  => qw( IGNCR i ) ],
   [ icrnl  => qw( ICRNL i ) ],
   [ ignbrk => qw( IGNBRK i ) ],
   [ brkint => qw( BRKINT i ) ],
   [ parmrk => qw( PARMRK i ) ],
   # oflag
   [ opost  => qw( OPOST o ) ],
   # cflag
   [ cread  => qw( CREAD  c ) ],
   [ clocal => qw( CLOCAL c ) ],
   [ hupcl  => qw( HUPCL  c ) ],
   # lflag
   [ icanon => qw( ICANON l ) ],
   [ echo   => qw( ECHO   l ) ],
);

foreach ( @flags ) {
   my ( $name ) = @$_;

   my $getmethod = "getflag_$name";
   my $setmethod = "setflag_$name";

   no strict 'refs';
   *$getmethod = sub {
      my ( $self ) = @_;
      my $attrs = $self->getattr or croak "Cannot getattr - $!";
      return $attrs->$getmethod;
   };
   *$setmethod = sub {
      my ( $self, $set ) = @_;
      my $attrs = $self->getattr or croak "Cannot getattr - $!";
      $attrs->$setmethod( $set );
      $self->setattr( $attrs ) or croak "Cannot setattr - $!";
   };
}

=head2 setflags

   $term->setflags( @flags )

I<Since version 0.09.>

A convenient wrapper to calling multiple flag setting methods in a sequence.

Each flag is specified by name, in lower case, prefixed by either a C<+>
symbol to enable it, or C<-> to disable. For example:

   $term->setflags( "+igncr", "+opost", "+clocal", "-echo" );

=cut

sub setflags
{
   my $self = shift;
   my @flags = @_;

   my $attrs = $self->getattr or croak "Cannot getattr - $!";

   foreach my $flag ( @flags ) {
      my $sense = 1;
      $sense = 0 if $flag =~ s/^-//;
      $flag =~ s/^\+//;

      my $method = "setflag_$flag";
      $attrs->$method( $sense );
   }

   $self->setattr( $attrs ) or croak "Cannot setattr - $!";
}

package # hide from CPAN
   IO::Termios::Attrs;

use Carp;
use POSIX qw(
   CSIZE CS5 CS6 CS7 CS8 PARENB PARODD CSTOPB
   IGNBRK BRKINT PARMRK ISTRIP INLCR IGNCR ICRNL IXON OPOST ECHO ECHONL ICANON ISIG IEXTEN
);
# IO::Tty has more B<\d> constants than POSIX has
use IO::Tty;

# Simple XS-implemented classes tend not to respect subclassing
sub new
{
   my $class = shift;
   my $self = $class->SUPER::new;
   bless $self, $class;
   return $self;
}

if( IO::Termios::HAVE_LINUX_TERMIOS2 ) {
   our @ISA = qw( Linux::Termios2 );

   # baud is directly applicable
   *getibaud = __PACKAGE__->can( 'getispeed' );
   *getobaud = __PACKAGE__->can( 'getospeed' );

   *setibaud = __PACKAGE__->can( 'setispeed' );
   *setobaud = __PACKAGE__->can( 'setospeed' );
}
else {
   our @ISA = qw( POSIX::Termios );

   # baud needs converting to/from the speed_t constants

   my %_speed2baud = map { IO::Tty::Constant->${\"B$_"} => $_ } 
      qw( 0 50 75 110 134 150 200 300 600 1200 2400 4800 9600 19200 38400 57600 115200 230400 );
   my %_baud2speed = reverse %_speed2baud;

   *getibaud = sub { $_speed2baud{ $_[0]->getispeed } };
   *getobaud = sub { $_speed2baud{ $_[0]->getospeed } };

   *setibaud = sub {
      $_[0]->setispeed( $_baud2speed{$_[1]} // die "Unrecognised baud rate" );
   };
   *setobaud = sub {
      $_[0]->setospeed( $_baud2speed{$_[1]} // die "Unrecognised baud rate" );
   };

}

sub setbaud
{
   $_[0]->setibaud( $_[1] ); $_[0]->setobaud( $_[1] );
}

foreach ( @flags ) {
   my ( $name, $const, $member ) = @$_;

   $const = POSIX->$const();

   my $getmethod = "getflag_$name";
   my $getflag   = "get${member}flag";

   my $setmethod = "setflag_$name";
   my $setflag   = "set${member}flag";

   no strict 'refs';
   *$getmethod = sub {
      my ( $self ) = @_;
      $self->$getflag & $const
   };
   *$setmethod = sub {
      my ( $self, $set ) = @_;
      $set ? $self->$setflag( $self->$getflag |  $const )
           : $self->$setflag( $self->$getflag & ~$const );
   };
}

sub getcsize
{
   my $self = shift;
   my $cflag = $self->getcflag;
   return {
      CS5, 5,
      CS6, 6,
      CS7, 7,
      CS8, 8,
   }->{ $cflag & CSIZE };
}

sub setcsize
{
   my $self = shift;
   my ( $bits ) = @_;
   my $cflag = $self->getcflag;

   $cflag &= ~CSIZE;
   $cflag |= {
      5, CS5,
      6, CS6,
      7, CS7,
      8, CS8,
   }->{ $bits };

   $self->setcflag( $cflag );
}

sub getparity
{
   my $self = shift;
   my $cflag = $self->getcflag;
   return 'n' unless $cflag & PARENB;
   return 'o' if $cflag & PARODD;
   return 'e';
}

sub setparity
{
   my $self = shift;
   my ( $parity ) = @_;
   my $cflag = $self->getcflag;

   $parity eq 'n' ? $cflag &= ~PARENB :
   $parity eq 'o' ? $cflag |= PARENB|PARODD :
   $parity eq 'e' ? ($cflag |= PARENB) &= ~PARODD :
      croak "Unrecognised parity '$parity'";

   $self->setcflag( $cflag );
}

sub getstop
{
   my $self = shift;
   return 2 if $self->getcflag & CSTOPB;
   return 1;
}

sub setstop
{
   my $self = shift;
   my ( $stop ) = @_;
   my $cflag = $self->getcflag;

   $stop == 1 ? $cflag &= ~CSTOPB :
   $stop == 2 ? $cflag |=  CSTOPB :
      croak "Unrecognised stop '$stop'";

   $self->setcflag( $cflag );
}

sub cfmakeraw
{
   my $self = shift;

   # Coped from bit manipulations in termios(3)
   $self->setiflag( $self->getiflag & ~( IGNBRK | BRKINT | PARMRK | ISTRIP | INLCR | IGNCR | ICRNL | IXON ) );
   $self->setoflag( $self->getoflag & ~( OPOST ) );
   $self->setlflag( $self->getlflag & ~( ECHO | ECHONL | ICANON | ISIG | IEXTEN ) );
   $self->setcflag( $self->getcflag & ~( CSIZE | PARENB ) | CS8 );
}

=head1 TODO

=over 4

=item *

Adding more getflag_*/setflag_* convenience wrappers

=back

=head1 SEE ALSO

=over 4

=item *

L<IO::Tty> - Import Tty control constants

=back

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
