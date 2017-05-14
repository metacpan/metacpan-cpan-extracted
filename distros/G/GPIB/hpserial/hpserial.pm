package GPIB::hpserial;

use strict;
use Carp;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK $AUTOLOAD);

require Exporter;
require DynaLoader;
require AutoLoader;

@ISA = qw(Exporter DynaLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw(
	
);
$VERSION = '0.30';

sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.  If a constant is not found then control is passed
    # to the AUTOLOAD in AutoLoader.

    my $constname;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    croak "& not defined" if $constname eq 'constant';
    my $val = constant($constname, @_ ? $_[0] : 0);
    if ($! != 0) {
	if ($! =~ /Invalid/) {
	    $AutoLoader::AUTOLOAD = $AUTOLOAD;
	    goto &AutoLoader::AUTOLOAD;
	}
	else {
		croak "Your vendor has not defined GPIB::hpserial macro $constname";
	}
    }
    *$AUTOLOAD = sub () { $val };
    goto &$AUTOLOAD;
}

bootstrap GPIB::hpserial $VERSION;

sub new {
    my $g = _new(@_);
    my  $r;

    $g->ibwrt("");
    $g->ibwrt("SYSTEM:REMOTE") unless $g->ibsta & GPIB->ERR;
    die "GPIB->new(@_): Cannot communicate with instrument\n    " 
        if $g->ibsta & GPIB->ERR;
    return $g;
}

sub DESTROY {
    my $g = shift;

    $g->ibwrt("SYSTEM:LOCAL");
    $g->_close;
}

# Do nothing functions for serial
sub ibask    { return 0; }
sub ibln     { return 1; }
sub ibbna    { my $dev = shift; 0; }
sub ibcac    { my $dev = shift; 0; }
sub ibclr    { my $dev = shift; 0; }
sub ibcmd    { my $dev = shift; 0; }
sub ibconfig { my $dev = shift; 0; }
sub ibdma    { my $dev = shift; 0; }
sub ibeot    { my $dev = shift; 0; }
sub ibgts    { my $dev = shift; 0; }
sub ibist    { my $dev = shift; 0; }
sub iblines  { my $dev = shift; 0; }
sub ibloc    { my $dev = shift; 0; }
sub ibonl    { my $dev = shift; 0; }
sub ibpad    { my $dev = shift; 0; }
sub ibpct    { my $dev = shift; 0; }
sub ibppc    { my $dev = shift; 0; }
sub ibrpp    { my $dev = shift; 0; }
sub ibrsc    { my $dev = shift; 0; }
sub ibrsp    { my $dev = shift; 0; }
sub ibrsv    { my $dev = shift; 0; }
sub ibsad    { my $dev = shift; 0; }
sub ibsic    { my $dev = shift; 0; }
sub ibsre    { my $dev = shift; 0; }
sub ibstop   { my $dev = shift; 0; }
sub ibtrg    { my $dev = shift; 0; }
sub ibwait   { my $dev = shift; 0; }
1;

__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

GPIB::hpserial - Perl-GPIB interface to many HP instruments with serial ports

=head1 SYNOPSIS

  use GPIB;

  # /etc/pgpib.conf entry
  # Flag has the following bits:
  #   0x0001      Use RTS/CTS flow control sending to device
  # name    driver              port        speed   TMO     EOS     FLAG
  HP33120A  GPIB::hpserial      /dev/ttyS1  9600    T3s     0x0a    0x0001

  # Perl program using /etc/pgpib.conf 
  use gpib::hp33120a;
  $g = gpib::hp33120a->new("HP33120A");
  $g->freq(1000000.0);  # Set Frequency to 1MHz

  # Perl program accessing serial driver with /etc/pgpib.conf
  use gpib::hp33120a;
  $g = gpib::hp33120a->new("gpib::hpserial", "/dev/ttyS1", 9600, gpib->T3s, 0x0a, 1);
  $g->freq(2000000.0);  # Set Frequency to 2MHz

=head1 DESCRIPTION

gpib::hpserial is an interface module for accessing HP test equipment 
with RS-232 ports.  This module is not normally called directly, but
is called by the gpib module according an entry in /etc/pgpib.conf
or by calling gpib->new and passing gpib::hpserial as the first 
parameter.

The module is an XS module that uses termios and so it is a Unix-only
module.  The module uses setitimer() so it's probably a bad idea
to use alarm() in conjunction with calls to serial devices.

These devices are generally 9600 baud, 8-bit, no parity devices
that require hardware flow control.  Sadly, hardware flow control
is always a bit awkward.  The HP devices use DTR/DSR pins for
flow control.  Linux only supports RTS/CTS handshaking so you
pretty much have to build your own serial cable that connects
DTR on the instrument (pin-4 of DB-9) to CTS on the host (pin-5 
of DB-9).  One of those little RS-232 boxes with a bunch of activity
LEDs and the HP instrument manual are indespensible even though
it seems like serial connections should be really simple.

You can choose to not use hardware flow control with a bit in
the settings in /etc/pgpib.conf, but I don't recommend it except
for debugging.  The HP instruments appear to have the world's slowest 
microcontrollers and their tiny buffers overflow often at 9600 baud,
even on simple commands.

Here's a test to see if you've got flow control sorted out 
properly.  On an HP33120A the following piece of code should 
cause very regular relay chatter as the output switches between
sine wave and square wave.  If the program hangs or starts beeping
and flashing error lights on the instrument, the serial port flow
control wires are probably not wired correctly:

   use gpib::hp33120a;

   $g = gpib::hp33120a->new("HP33120A");
   while (1) {
      $g->shape(SQU);
      $g->shape(SIN);
   }

The design goal is that you should be able to hook up a piece of HP
test equipment with both a GPIB port and a serial port using either
interface and software should work identically.  The only difference
being an entry in the /etc/pgpib.conf describing the interface to 
the device.

=head1 AUTHOR

Jeff Mock, jeff@mock.com

=head1 SEE ALSO

perl(1), gpib(3), gpib::ni(3), gpib::rmt(3), gpib::hp33120a(3).

=cut


