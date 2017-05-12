###
# $Revision: 1.3 $
# $Date: 2002/02/16 15:27:32 $
# $Author: ruediger $
###

package Device::Conrad::RelaisCard;

use Device::SerialPort qw(:PARAM :STAT 0.07);
use Device::Conrad::Frame;
use strict;
use Carp;

#use vars qw ($VERSION);
our $VERSION = '0.1';

my $VERBOSE = 0;
use constant NUMRELAIS => 8;

use constant CMD_NOP => 0;
use constant CMD_SETUP => 1;
use constant CMD_GET_PORT => 2;
use constant CMD_SET_PORT => 3;
use constant CMD_GET_OPT => 4;
use constant CMD_SET_OPT => 5;

sub new
{
my $proto = shift;
my $class = ref($proto) || $proto;
my $self = {};

  $self->{'_addr'} = shift;
  $self->{'_ctrl'} = shift;
  $self->{'_bcast_exec'} = 0;
  $self->{'_bcast_block'} = 0;
  $self->{'_ports'} = 0;
  bless ($self, $class);
  return $self;
}

sub init
{
my($self) = shift;

  my $getOptFrame = new Device::Conrad::Frame(CMD_GET_OPT, $self->address(), 0);
  my $optFrame = $self->{'_ctrl'}->sendFrame($getOptFrame);
  unless($optFrame)
  {
    carp "options read failed\n";
  }

  if(($optFrame->data() & 1) == 1)
  {
    $self->{'_bcast_exec'} = 1;
    print "controller ".$self->address()." is set up to execute broadcasts\n" if $VERBOSE;
  }

  if(($optFrame->data() & 2) == 2)
  {
    $self->{'_bcast_block'} = 1;
    print "controller ".$self->address()." is set up to block broadcasts\n" if $VERBOSE;
  }

  my $getPortFrame = new Device::Conrad::Frame(CMD_GET_PORT, $self->address(), 0);
  my $portFrame = $self->{'_ctrl'}->sendFrame($getPortFrame);
  $self->{'_ports'} = $portFrame->data();

  if($VERBOSE)
  {
    $self->showPortInfo();
  }
     
}

sub ports
{
my($self) = shift;

  if(@_)
  {
    my $ports = shift;
    if($self->{'_ports'} != $ports)
    {
      my $setPortFrame = new Device::Conrad::Frame(CMD_SET_PORT, $self->address(), $ports);
      my $portFrame = $self->{'_ctrl'}->sendFrame($setPortFrame);
      $self->{'_ports'} = $ports;
      $self->showPortInfo() if $VERBOSE;
    }
  }
  return $self->{'_ports'};
}

sub address
{
my($self) = shift;

  if(@_)
  {
    $self->{'_addr'} = shift;
  }
  return $self->{'_addr'};
}

sub broadcastExecute
{
my($self) = shift;

  if(@_)
  {
    $self->{'_bcast_exec'} = shift;
  }
  return $self->{'_bcast_exec'};
}

sub broadcastBlock
{
my($self) = shift;

  if(@_)
  {
    $self->{'_bcast_block'} = shift;
  }
  return $self->{'_bcast_block'};
}

sub close
{
my($self, $portNum) = @_;

  if($portNum > NUMRELAIS)
  {
    die "$portNum exceeds NUMRELAIS relais\n";
  }
  my $ports = $self->ports();
  $ports |= 2**$portNum;
  return $self->ports($ports);
}

sub open
{
my($self, $portNum) = @_;

  my $ports = $self->ports();
  $ports &= 255 - 2**$portNum;
  return $self->ports($ports);
}

sub test()
{
my($self) = shift;

  my $testFrame = new Device::Conrad::Frame(CMD_NOP, $self->address(), 0);
  my $crcFrame = $testFrame->createCRCFrame(); 
  my $testResp = $self->{'_ctrl'}->sendFrame($testFrame);
  if($testResp->equals($crcFrame))
  {
    return 1;
  }
  else
  {
    return 0;
  }
}

sub showPortInfo
{
my($self) = shift;

    my $i;
    print "port status = ".$self->{'_ports'}."\n";
    for $i (0..NUMRELAIS-1)
    {
      if(($self->{'_ports'} & (2**$i)) > 0)
      {
        print "Relais ".($i+1)." is closed\n";
      }
      else
      {
        print "Relais ".($i+1)." is open\n";
      }
    }
}

sub END
{
my($self) = shift;
  unlink $self->{'_lockFile'};
}
1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

Device::Conrad::RelaisCard - Container object for RelaisControl

=head1 SYNOPSIS

  $card->close(port)
  $card->open(port)
  $card->ports()
  $card->address()
  $card->broadcastExecute()
  $card->broadcastBlock()
  $card->test()
  $card->showPortInfo()

=head1 DESCRIPTION


=head1 AUTHOR

Norbert Hartl, E<lt>noha@cpan.orgE<gt>

=head1 SEE ALSO

Device::Conrad::RelaisControl,
Device::Conrad::Frame

=cut

