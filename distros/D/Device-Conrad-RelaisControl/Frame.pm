###
# $Revision: 1.3 $
# $Date: 2002/02/16 15:27:32 $
# $Author: ruediger $
###

package Device::Conrad::Frame;

use strict;
use Carp;

our $VERSION = '0.1';

use constant FRAMESIZE => 4;

sub new
{
my $proto = shift;
my $class = ref($proto) || $proto;
my $self = {};

  $self->{'_cmd'} = shift;
  $self->{'_addr'} = shift;
  $self->{'_data'} = shift;

  bless ($self, $class);
  return $self;
}

sub command
{
my($self) = shift;

  if(@_)
  {
    $self->{'_cmd'} = shift;
    $self->{'_crc'} = undef;
  }
  return $self->{'_cmd'};
}

sub address
{
my($self) = shift;

  if(@_)
  {
    $self->{'_addr'} = shift;
    $self->{'_crc'} = undef;
  }
  return $self->{'_addr'};
}

sub data
{
my($self) = shift;

  if(@_)
  {
    $self->{'_data'} = shift;
    $self->{'_crc'} = undef;
  }
  return $self->{'_data'};
}

sub crc
{
my($self) = shift;

  unless(defined($self->{'_crc'}))
  {
    $self->{'_crc'} = $self->{'_cmd'} ^ $self->{'_addr'} ^ $self->{_data};
  }
  return $self->{'_crc'};
}

sub setPacket
{
my($self, $packet) = @_;

  my $crc;
  ($self->{'_cmd'}, $self->{'_addr'}, $self->{'_data'}, $crc) = 
    unpack('CCCC', $packet);
  if($crc != $self->crc())
  {
    carp "setPacket(): wrong checksum in frame ".$self->toString." got crc: $crc";
  }
  print "checksum: ".$self->crc()."\n";
}

sub createFromPacket
{
my($packet) = shift;

  my ($cmd, $addr, $data, $crc);
  ($cmd, $addr, $data, $crc) = unpack('CCCC', $packet);
  my $frame = new Device::Conrad::Frame($cmd,$addr,$data);

  if($crc != $frame->crc())
  {
    carp "createFromPacket(): wrong checksum in frame ".$frame->toString." got crc: $crc";
  }
  return $frame;
}

sub toPacket
{
my($self) = @_;

  return pack('CCCC', 
                  $self->command(), 
                  $self->address(), 
                  $self->data(), 
                  $self->crc());
}

sub createCRCFrame
{
my($self) = shift;

  my $crcCmd = $self->command() ^ 255;
  my $crcFrame = new Device::Conrad::Frame($crcCmd , $self->address(),$self->data());
  
  return $crcFrame;
}
 
sub display
{
my($self) = shift;
my(@vals);
my $i;

  print "== Frame == ";
  print "cmd  = ",$self->command()," ";
  print "addr = ",$self->address()," ";
  print "data = ",$self->data()," ";
  print "\n";
}

sub toString
{
my($self) = shift;

  my $str = $self->command().",".$self->address().",";
  $str .= $self->data().",".$self->crc();
  return $str;
}

sub equals
{
my($self, $frame) = @_;

  if($self->command() == $frame->command())
  {
    return 1;
  }
  else
  {
    return 0;
  }
}
1;
