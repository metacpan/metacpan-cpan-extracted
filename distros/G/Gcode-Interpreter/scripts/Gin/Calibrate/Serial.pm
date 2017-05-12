package Gin::Calibrate::Serial;

use strict;
use warnings;

use IO::File;
use Device::SerialPort;

sub new {
  my ($class) =@_;
  
  my $self = {};

  $self->{FD} = undef;
  $self->{READ_BUF} = '';

  bless $self, $class;

  return $self;
}

# from https://github.com/henryk/perl-baudrate/blob/master/set-baudrate.pl
sub set_baudrate(*;$$) {
  my ($fh, $direction, $baudrate) = @_;

  my %constants = (
    "TCGETS2" => 0x802C542A,
    "TCSETS2" => 0x402C542B,
    "BOTHER" => 0x00001000,
    "CBAUD" => 0x0000100F,
    "termios2_size" => 44,
    "c_ispeed_size" => 4,
    "c_ispeed_offset" => 0x24,
    "c_ospeed_size" => 4,
    "c_ospeed_offset" => 0x28,
    "c_cflag_size" => 4,
    "c_cflag_offset" => 0x8,
  );
  
  # We can't directly use pack/unpack with a specifier like "integer of x bytes"
  # Instead, check that the native int matches the corresponding *_size properties
  # Should there be a platform where that isn't the case, we need to find a different
  # way (such as using bitstrings and performing the integer conversion ourselves)
  return -2 if (length pack("I", 0) != $constants{"c_ispeed_size"});
  return -2 if (length pack("I", 0) != $constants{"c_ospeed_size"});
  return -2 if (length pack("I", 0) != $constants{"c_cflag_size"});
  
  # First: Initialize the termios2 structure to the right size
  my $to = " "x $constants{"termios2_size"};
  
  # Second: Call TCGETS2
  ioctl($fh, $constants{"TCGETS2"}, $to) or return -1;
  
  # Third: Modify the termios2 structure
  # A: Extract and modify c_cflag
  my $cflag = unpack "I", substr($to, $constants{"c_cflag_offset"}, $constants{"c_cflag_size"});
  $cflag &= ~$constants{"CBAUD"};
  $cflag |= $constants{"BOTHER"};
  substr($to, $constants{"c_cflag_offset"}, $constants{"c_cflag_size"}) = pack "I", $cflag;
  
  # B: Modify c_ispeed
  if($direction & 1) {
    substr($to, $constants{"c_ispeed_offset"}, $constants{"c_ispeed_size"}) = pack "I", $baudrate;
  }
  
  # C: Modify c_ospeed
  if($direction & 2) {
    substr($to, $constants{"c_ospeed_offset"}, $constants{"c_ospeed_size"}) = pack "I", $baudrate;
  }
  
  # Fourth: Call TCSETS2
  ioctl($fh, $constants{"TCSETS2"}, $to) or return -1;
  
  return 0;
}

sub open_serial {
  my ($self, $port, $speed) = @_;

  if(defined($self->{FD})) {
    # Close the existing one
    close($self->{FD});
  }

  # We open the port using SerialPort just to 
  # waggle the DTR to reset it
  # We probably do this ourselves later as well,
  # but that doesn't seem to work 100% reliably
  my $fake = Device::SerialPort->new($port);
  if($fake) {
    $fake->baudrate($speed);
    $fake->databits(8);
    $fake->parity(0);
    $fake->handshake('none');
    $fake->pulse_dtr_on(100);
    $fake = undef;
  }

  # We now open the port again, but do so using our
  # own IO::Handle object, so that we can use select()
  # on it (which you can't do with the SerialPort object)
  my $new = IO::File->new();
  unless(open($new, "+<:bytes", $port)) {
    #print "Failed to open $port: $!\n";
    return 0;
  }
  # Try to set the baud rate...
  set_baudrate($new, 3, $speed);

  # On rasbian, we have to turn off echos
  # (We can't use SerialPort to do this)
  system("/bin/stty -F \"$port\" -echo -echoe -echonl");

  # Remember the object...
  $self->{FD} = $new;

  $new->autoflush(1);

  return 1;
}

sub write_fd {
  my ($self, $line) = @_;

  return 0 if(!defined($self->{FD}));

  #print "Sending $line\n";

  return $self->{FD}->write("$line\n");
}

sub read_fd {
  my ($self) = @_;

  return if(!defined($self->{FD}));

  my $buffer = '';

  my $i = $self->{FD}->sysread($buffer, 4096);
  #print "Read $i bytes from FD: $buffer\n";
  my $fd = $self->{FD};
  if(!defined($i)) {
    # Looks like EOF or something
    print "Error reading descriptor: $!\n";
    return;
  } elsif($i > 0) {
    $self->{READ_BUF} .= $buffer;
    # See if the buffer is sufficiently full now
    if(length($self->{READ_BUF}) >= 2048) {
      # Buffer sufficiently big - stop trying to read any more
      $self->{READERS}->remove_fd($self->{FD});
      $self->{READ_BUFFER_FULL} = 1;
    }
  } else {
    # Read zero bytes - means the port has disappeared/closed
    # on us.
    print "Port has closed, so disconnecting from it\n";
    close($self->{FD});
    $self->{FD} = undef;
  }

  return $self->read_buffer();
}

sub read_buffer {
  my ($self) = @_;

  # We need to 'pop' a command off the read buffer. It's a string
  # with some new lines in it, so pull something off it and return
  # it. Since this is a control port, we're not expecting too
  # many schenanigans here - so don't need to be super-defensive
  # about the lines we're reading and whatnot. Just skip blank lines
  # and remove comments.
  while(length($self->{READ_BUF}) > 0) {
    if($self->{READ_BUF} =~ s/^(.*)[\r\n]+//) {
      my $string = $1;
      #print "popped >$string< from buffer\n";
      return $string;
    } else {
      # Buffer not sufficiently full
      last;
    }
  }
  # We've either balied out of the loop, or have run out of
  # buffer.
  return undef;
}

1;
# This is for Vim users - please don't delete it
# vim: set filetype=perl expandtab tabstop=2 shiftwidth=2:
