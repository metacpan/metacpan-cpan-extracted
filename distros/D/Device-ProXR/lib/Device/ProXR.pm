package Device::ProXR;
##----------------------------------------------------------------------------
## :mode=perl:indentSize=2:tabSize=2:noTabs=true:
##****************************************************************************
## NOTES:
##  * Before comitting this file to the repository, ensure Perl Critic can be
##    invoked at the HARSH [3] level with no errors
##****************************************************************************

=head1 NAME

Device::ProXR - A  Moo based object oriented interface for creating 
controlling devices using the National Control Devices ProXR command set

=head1 VERSION

Version 0.07

=head1 SYNOPSIS

  ## Device::ProXR is a base class that is typicall extended
  ##    see Device::ProXR::RelayControl 
  use Device::ProXR;

  my $board = Device::ProXR->new(port => qq{COM1});

=head1 SEE ALSO

L<Device::ProXR::RelayControl>

See the L<NCD website|http://www.controlanything.com/> for the devices with
the ProXR series controller.


=cut

##****************************************************************************
##****************************************************************************
use Moo;
## Moo enables strictures
## no critic (TestingAndDebugging::RequireUseStrict)
## no critic (TestingAndDebugging::RequireUseWarnings)
use 5.010;
use Readonly;
use Time::HiRes qw(usleep);
use Carp qw(confess cluck);

## Version string
our $VERSION = qq{0.07};


##--------------------------------------------------------
## Time conversion contants
##--------------------------------------------------------
## uSeconds per millisecond
Readonly::Scalar my $USECS_PER_MS => 1000;
## milliseconds per second
Readonly::Scalar my $MS_PER_SEC => 1000;
## uSeconds per second
Readonly::Scalar my $USECS_PER_SEC => $USECS_PER_MS * $MS_PER_SEC;

##--------------------------------------------------------
## Various timeouts
##--------------------------------------------------------
Readonly::Scalar my $GET_RESPONSE_DEFAULT_MS_TIMEOUT => 400;
## millisecond timeout when reading from the FPC serial port
Readonly::Scalar my $READ_POLL_TIMEOUT_MS => 1000;

##--------------------------------------------------------
## Symbolic constants
##--------------------------------------------------------

Readonly::Scalar my $PROXR_API_START  => 0xAA;
Readonly::Scalar my $PROXR_CMD        => 0xFE;

##--------------------------------------------------------
## Conditionally load the needed serial module
##--------------------------------------------------------
BEGIN
{
  if ($^O eq 'MSWin32')
  {
    require Win32::SerialPort;
    Win32::SerialPort->import;
  }
  else
  {
    require Device::SerialPort;
    Device::SerialPort->import;
  }
}
##****************************************************************************
## Object attribute
##****************************************************************************

=head1 ATTRIBUTES

=cut

##****************************************************************************
##****************************************************************************

=over 2

=item B<port>

  Port used to communicate with the device

=back

=cut

##----------------------------------------------------------------------------
has port => (
  is      => qq{rw},
  default => qq{},
);

##****************************************************************************
##****************************************************************************

=over 2

=item B<baud>

  Baud rate for port used to communicate with the device.
  NOTE: This only applies to serial port communications
  DEFAULT: 115200

=back

=cut

##----------------------------------------------------------------------------
has baud => (
  is      => qq{rw},
  default => qq{115200},
);

##****************************************************************************
##****************************************************************************

=over 2

=item B<API_mode>

  Enable the API mode of communications. This mode adds byte counts and
  checksums to all commands and responses.
  DEFAULT: 1

=back

=cut

##----------------------------------------------------------------------------
has API_mode => (
  is      => qq{rw},
  default => qq{1},
);

##****************************************************************************
##****************************************************************************

=over 2

=item B<debug_level>

  Debug level controls amount of debugging information displayed
  DEFAULT: 0

=back

=cut

##----------------------------------------------------------------------------
has debug_level => (
  is      => qq{rw},
  default => 0,
);

##****************************************************************************
## "Private" atributes
##***************************************************************************

## Holds the port object 
has _port_obj  => (
  is        => qq{rw},
  predicate => 1,

);

## Error message
has _error_message => (
  is      => qq{rw},
  default => qq{},
);


##****************************************************************************
## Object Methods
##****************************************************************************

=head1 METHODS

=cut

##----------------------------------------------------------------------------
##     @fn _get_port_object()
##  @brief Returns the port object, opening it if needed. Returns UNDEF
##         on error and sets last_error
##  @param 
## @return Port object, or UNDEF on error
##   @note 
##----------------------------------------------------------------------------
sub _get_port_object ## no critic (ProhibitUnusedPrivateSubroutines)
{
  my $self = shift;
  
  ## Returh the object if it already exists
  return($self->_port_obj) if ($self->_has_port_obj);
  
  ## See if a port was specified
  unless ($self->port)
  {
    $self->_error_message(qq{Missing port attribute!});
    return;
  }

  ## Create the object
  my $obj;
  
  ## See if we running Windows
  if ($^O eq q{MSWin32})
  {
    ## Running Windows, use Win32::SerialPort
    $obj = Win32::SerialPort->new($self->port, 1);
  }
  else
  {
    ## Not running Windows, use Device::SerialPort
    $obj = Device::SerialPort->new($self->port, 1);
  }
  
  ## See if opened the port
  unless ($obj)
  {
    ## There was an error opening the port
    $self->_error_message(qq{Could not open port "} . $self->port . qq{"});
    return;
  }
  
  ## Configure the port
  $obj->baudrate($self->baud);
  $obj->parity(qq{none});
  $obj->databits(8);
  $obj->stopbits(1);
  $obj->handshake(qq{none});
  $obj->read_const_time($READ_POLL_TIMEOUT_MS);
  $obj->purge_all;
  
  ## Write all settings to the serial port
  $obj->write_settings;
  
  ## Set the port object
  $self->_port_obj($obj);
  
  ## Return the port object
  return($self->_port_obj);
}



##****************************************************************************
##****************************************************************************

=head2 last_error()

=over 2

=item B<Description>

Returns the last error message

=item B<Parameters>

NONE

=item B<Return>

String containing the last error, or an empty string if no error has been
encountered

=back

=cut

##----------------------------------------------------------------------------
sub last_error
{
  my $self = shift;
  
  return($self->_error_message);
}

##****************************************************************************
##****************************************************************************

=head2 send_command(cmd, param)

=over 2

=item B<Description>

Sends the given command wand optional parameter.
NOTE: This method adds the required 0xFE before the command, and 
      encapsulation of the packet in API mode

=item B<Parameters>

cmd - Command to send
param - Optional parameter

=item B<Return>

UNDEF on error (last_error set), or number of bytes sent

=back

=cut

##----------------------------------------------------------------------------
sub send_command
{
  my $self  = shift;
  my $cmd   = shift;
  my $param = shift;
  
  ## See if we received a command
  unless (defined($cmd))
  {
    ## No command, so set the error message
    $self->_error_message(qq{Missing command parameter!});
    ## Return UNDEF indicating an error
    return;
  }
  
  ## Assemble the string to send
  my $tx_buff = chr($PROXR_CMD) . chr($cmd);
  ## Add the parameter if provided
  $tx_buff .= chr($param) if (defined($param));
  
  ## See if we are in API mode
  if ($self->API_mode)
  {
    ## API Mode sends (and receives) using the format
    ##  0xAA COUNT BYTES CHECKSUM
    ##  Where COUNT is the number of BYTES
    ##        CHECKSUM is the 8-bit rolling checksum of the entire buffer
    my $count  = (defined($param) ? 3 : 2);
    my $chksum = $PROXR_API_START + $count + $PROXR_CMD + $cmd;
    $chksum += $param if (defined($param));
    $chksum = $chksum % 256;
    $tx_buff = chr($PROXR_API_START) . chr($count) . $tx_buff . chr($chksum);
  }

  ## Print debug output
  if ($self->debug_level)
  {
    print(qq{send_command(): });
    _display_buffer($tx_buff);
  }
  
  return unless ($self->_get_port_object);
  
  
  ## Send the buffer
  my $tx_len = $self->_port_obj->write($tx_buff);
  
  ## Flush all RX and TX buffers
  $self->_port_obj->purge_all;
  
  ## Return the number of bytes transmitted
  return $tx_len;
  
}

##****************************************************************************
##****************************************************************************

=head2 get_response(count, ms_timeout)

=over 2

=item B<Description>

Return a buffer containing the response received from the controller
NOTE: In API mode, the checksum is verified and the header byte (0xAA)
      count and checksum are removed from the buffer

=item B<Parameters>

count - Number of bytes expected
    DEFAULT: 1
ms_timeout - Optional timeout in milliseconds 
    DEFAULT: 400


=item B<Return>

UNDEF on error (last_error set), or SCALAR containing the data received

=back

=cut

##----------------------------------------------------------------------------
sub get_response
{
  my $self        = shift;
  my $count       = shift // 1;
  my $ms_timeout  = shift // $GET_RESPONSE_DEFAULT_MS_TIMEOUT;
  
  ## Number of bytes expected
  my $expected = $count;
  ## API mode, responses contain 3 extra bytes
  $expected += 3 if ($self->API_mode);

  return unless ($self->_has_port_obj);
  
  my $rx_buff = qq{};

  ## Set the timeout
  $self->_port_obj->read_const_time($ms_timeout);
  
  my $timeout = 0;
  while ((!$timeout) and ($expected != length($rx_buff)))
  {
    ## Read the bytes
    my ($rx_count, $rx_raw) = $self->_port_obj->read(16);
    if ($rx_count)
    {
      $rx_buff .= $rx_raw ;
    }
    else
    {
      $timeout = 1;
    }
  }
  
  ## Print debug output
  if ($self->debug_level)
  {
    printf(
      qq{get_response(): Expected %d, received %d\n}, 
      $expected, 
      length($rx_buff),
      );
    _display_buffer($rx_buff);
  }
  
  ## See if we received what we expected
  if ($expected == length($rx_buff))
  {
    if ($self->API_mode)
    {
      ## Trim off the 0xAA and COUNT from the beginning, and 
      ## checksum from the end
      $rx_buff = substr($rx_buff, 2, -1);
    }
  }
  
  return($rx_buff);
  
}

##----------------------------------------------------------------------------
##     @fn _display_buffer($buff)
##  @brief Display the given buffer as hexadecimal bytes
##  @param $buff - Buffer to be displayed
## @return NONE
##   @note 
##----------------------------------------------------------------------------
sub _display_buffer
{
  my $buff  = shift;
  
  ## Iterate through the buffer
  foreach my $idx (0 .. (length($buff) - 1))
  {
    printf(qq{0x%02X }, ord(substr($buff, $idx, 1)));
    ## Send newline after 16 bytes
    print(qq{\n}) if ($idx && (0 == ($idx % 0x10)));
  }
  
  ## Send newline
  print(qq{\n}) if (length($buff) % 0x10);
  
  return;
}



##****************************************************************************
## Additional POD documentation
##****************************************************************************

=head1 AUTHOR

Paul Durden E<lt>alabamapaul AT gmail.comE<gt>

=head1 COPYRIGHT & LICENSE

Copyright (C) 2015 by Paul Durden.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;    ## End of module
__END__
