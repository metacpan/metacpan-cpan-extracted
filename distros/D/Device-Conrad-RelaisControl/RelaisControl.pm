package Device::Conrad::RelaisControl;

###
# $Revision: 1.3 $
# $Date: 2002/02/16 15:27:32 $
# $Author: ruediger $
###

use 5.006;
use strict;
use warnings;

require Exporter;
use AutoLoader qw(AUTOLOAD);

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Device::Conrad::RelaisControl ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);
our $VERSION = '0.12';


# Preloaded methods go here.

use Device::SerialPort qw(:PARAM :STAT 0.07);
use Device::Conrad::Frame;
use Device::Conrad::RelaisCard;
use Carp;
use strict;

use vars qw ($VERSION);

my $VERBOSE = 0;
my $CONSTREAD = 200;
my $CHARREAD = 10;
my $LOCKFILE = "/tmp/relaiscard.lock";

sub new
{
my $proto = shift;
my $class = ref($proto) || $proto;
my $self = {};

  my $portName = shift;
  $self->{'_portName'} = $portName;
  #$self->{'_lockFile'} = "/tmp/relaiscard.lock";
  $self->{'_cards'} = [];

  my $port = new Device::SerialPort ($portName, 0, $LOCKFILE)
    || die "Can't open: $!\n"; 

  print "open device: $portName\n" if $VERBOSE;
  $port->devicetype('none');

  print "setting device params: 19200 8n1 no handshake\n" if $VERBOSE;
  $port->baudrate(19200);
  $port->parity("none");
  $port->databits(8);
  $port->stopbits(1);
  $port->handshake("none");

  print "setting timings: constant reading = 500, char read = 50\n" if $VERBOSE;
  $port->read_const_time($CONSTREAD);
  $port->read_char_time($CHARREAD);
  $self->{'_timeout'} = ($CONSTREAD + (4 * $CHARREAD))/1000;

  $port->write_settings;
  $port->debug(1) if $VERBOSE;

  $self->{'_port'} = $port;
  bless ($self, $class);
  return $self;
}

sub init
{
my($self) = shift;
my $setupFrame;

  undef $self->{'_cards'};
  print "initialize control\n" if $VERBOSE;

  my $setup = new Device::Conrad::Frame(Device::Conrad::RelaisCard::CMD_SETUP, 1, 0);
  unless($setupFrame = $self->sendFrame($setup))
  {
    carp "initialize failed\n";
  }
  my $nFrame;
  while(($nFrame = $self->readFrame())->command() != 0)
  {
    push @{$self->{'_cards'}}, new Device::Conrad::RelaisCard($setupFrame->address(), $self);
    select(undef,undef,undef,0.50);
    $setupFrame = $nFrame;
  }
  print @{$self->{'_cards'}}+0," cards detected\n" if $VERBOSE;

  my $card;
  foreach $card (@{$self->{'_cards'}})
  {
    $card->init();
  }
}

sub getNumCards
{
my($self) = @_;

  return @{$self->{'_cards'}}+0;
}

sub getCard
{
my($self, $num) = @_;
  
  if($num > $#{$self->{'_cards'}})
  {
    die "$num exceeds number of cards";
  }
  return $self->{'_cards'}->[$num];
}
    
sub current
{
my($self) = shift;

  if(@_)
  {
    $self->{'_current'} = $self->getCard(shift);
  }
  return $self->{'_current'};
}

sub close
{
my($self, $cardNum, $port) = @_;

  my $card = $self->getCard($cardNum);
  $card->close($port);
}

sub open
{
my($self, $cardNum, $port) = @_;

  my $card = $self->getCard($cardNum);
  $card->open($port);
}

sub sendFrame
{
my($self, $frameOut) = @_;

  print "sending packet: ".$frameOut->toString()."\n" if $VERBOSE;
  my $crcFrame = $frameOut->createCRCFrame();
  
  $self->{'_port'}->write($frameOut->toPacket());
  select(undef, undef, undef, 0.1);

  my $frameIn = $self->readFrame();
  print "received packet: ".$frameIn->toString()."\n" if $VERBOSE;

  unless($frameIn->equals($crcFrame))
  {
    my $stopFrame = new Device::Conrad::Frame(3,1,0);
    $self->{'_port'}->write($stopFrame->toPacket());
    carp "controller response is incorrect. \n sent ".$frameOut->toString."\n got ".$frameIn->toString()."\n should be ".$crcFrame->toString()."\n";
    return new Device::Conrad::Frame(0,0,0);
  }

  return $frameIn;
}
  
sub readFrame
{
my($self) = shift;

  my ($bytesIn, $packetIn) = $self->{'_port'}->read(Device::Conrad::Frame::FRAMESIZE);

  unless($bytesIn == Device::Conrad::Frame::FRAMESIZE)
  {
    return new Device::Conrad::Frame(0,0,0);
  }

  my $frameIn = Device::Conrad::Frame::createFromPacket($packetIn);

  return $frameIn;
}

sub DESTROY
{
my($self) =shift;
  unlink $LOCKFILE;
}

sub END
{
my($self) =shift;
  unlink $LOCKFILE;
}
1;
# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

Device::Conrad::RelaisControl - Perl extension for accessing a Conrad Electronic Relaiscard

=head1 SYNOPSIS

  use Device::Conrad::RelaisControl;

=head2 Constructor

  $control = new Device::Conrad::RelaisControl("/dev/ttyS0");

=head2 Initialization

  $control->init;

=head2 Portswitching

  $control->close(0,1);
  $control->open(0,1);

  $cardNum = $control->getNumCards();
  $card = $control->getCard(0);

  $card->ports(255);

  $card->close(1);
  $card->open(1);

=head1 DESCRIPTION

This module provides an abstraction layer for accessing a Conrad Electronic
Relaiscard. It acts as a container for several cards (the cards are 
cascadeable) and controls the communication over the serial port. 

=head2 Creation

At time of creation of the RelaisControl Object the serial port is
initialized. It is the only operation which works without having
a card attached to the serial port.

=head2 Initialization

The init method communicates with the card(s) in order to figure
out out how many cards are attached and what their status is. 
For every responding card a card object is assigned and is being
put on the container list.

=head2 Opening and closing ports

As this module is the container for any of the cards you can either
switch port via absolute addressing or get a card object from the
container and switch via this object.

  $control->close(0,1);

will switch port 1 on card 0.
The other approach is to get a card instance and operate on this

  $card = $control->getCard(0);
  $card->close(1);

will get the same result as the command above. 

B<Caution!> The close() method activates the port (it closes the relais
circuit). While it tend to be confusing I decided to name it this way
round. General usage will look like: close(port); wait some time; open(port)

=head2 card methods

Only the RelaisCard's close() and open() methods are direct accesible  
through this module. Instead of delegating every card method i suggest
working with the card objects if you need specific functionality.

=head2 EXPORT

None by default.

=head1 AUTHOR

Norbert Hartl, E<lt>noha@cpan.orgE<gt>

=head1 SEE ALSO

Device::Conrad::RelaisCard,
Device::Conrad::Frame

=cut
