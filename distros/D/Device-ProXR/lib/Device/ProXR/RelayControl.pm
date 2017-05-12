package Device::ProXR::RelayControl;
##----------------------------------------------------------------------------
## :mode=perl:indentSize=2:tabSize=2:noTabs=true:
##****************************************************************************
##****************************************************************************

=head1 NAME

Device::ProXR::RelayControl - A subclass of Device::ProXR object for relay
control.

=head1 VERSION

Version 0.06

=head1 NOTES

* Before comitting this file to the repository, ensure Perl Critic can be
  invoked at the HARSH [3] level with no errors

=head1 SYNOPSIS

  use Device::ProXR::RelayControl;
  
  my $board = Device::ProXR::RelayControl->new(port => qq{COM2});
  
  $board->all_off;
  $board->relay_on(1, 1);
  
=head1 SEE ALSO

See L<Device::ProXR> for attributes and methods of the base class.

=cut

##****************************************************************************
##****************************************************************************
use Readonly;
use Moo;
## Moo enables strictures
## no critic (TestingAndDebugging::RequireUseStrict)
## no critic (TestingAndDebugging::RequireUseWarnings)

extends 'Device::ProXR';

our $VERSION = "0.06";

##--------------------------------------------------------
## Symbolic constants
##--------------------------------------------------------

## Command to check 2-way communications
Readonly::Scalar my $PROXR_CMD_TEST_2WAY_COMMS  => 0x21;
## Response to the check 2-way comms
Readonly::Scalar my $PROXR_MODE_RUN       =>  0x55;
Readonly::Scalar my $PROXR_MODE_CONFIG    =>  0x56;
Readonly::Scalar my $PROXR_MODE_LOCKDOWN  =>  0x57;

## The folowing commands are used for individual relays 
Readonly::Scalar my $PROXR_CMD_BANK_DIRECTED_RELAY_OFF    => 0x64;
Readonly::Scalar my $PROXR_CMD_BANK_DIRECTED_RELAY_ON     => 0x6C;
Readonly::Scalar my $PROXR_CMD_BANK_DIRECTED_RELAY_STATUS => 0x74;

## The folowing commands are used for all relays in a specified bank 
Readonly::Scalar my $PROXR_CMD_BANK_DIRECTED_STATUS         => 0x7C;
Readonly::Scalar my $PROXR_CMD_BANK_DIRECTED_RELAY_ALL_OFF  => 0x81;
Readonly::Scalar my $PROXR_CMD_BANK_DIRECTED_RELAY_ALL_ON   => 0x82;
Readonly::Scalar my $PROXR_CMD_BANK_DIRECTED_RELAY_INVERT   => 0x83;
Readonly::Scalar my $PROXR_CMD_BANK_DIRECTED_RELAY_MIRROR   => 0x84;

## Response to ACKnowledge the command
Readonly::Scalar my $PROXR_RESP_ACK =>  0x55;

##****************************************************************************
## Object Attributes
##****************************************************************************

=head1 ATTRIBUTES

=cut

##****************************************************************************
## Object Methods
##****************************************************************************

=head1 METHODS

=cut

##****************************************************************************
##****************************************************************************

=head2 get_mode()

=over 2

=item B<Description>

Returns the current mode of operation

=item B<Parameters>

NONE

=item B<Return>

Value indicating run mode

=back

=cut

##----------------------------------------------------------------------------
sub get_mode
{
  my $self = shift;

  ## Send the command
  $self->send_command($PROXR_CMD_TEST_2WAY_COMMS);

  return $self->get_response; 
}

##****************************************************************************
##****************************************************************************

=head2 relay_on($relay)

=head2 relay_on($bank, $relay)

=over 2

=item B<Description>

Turn on the relay

=item B<Parameters>

$bank - Bank number of the relay to control (1 based)
$relay - Relay number of the relay to control (0 based)

=item B<Return>

UNDEF on error (with last_error set)

=item B<NOTE>

If only one parameter is specified, it is treated as a 0 based relay number
and the bank is calculated as (relay / 8) + 1, and the relay within the bank
is caluclated as (relay % 8)

=back

=cut

##----------------------------------------------------------------------------
sub relay_on
{
  my $self  = shift;
  my $bank  = shift;
  my $relay = shift;

  ## See if we just received 1 parameter  
  if (defined($bank) and (!defined($relay)))
  {
    ## Convert this into bank and relay
    $relay = $bank % 8;
    $bank = int($bank / 8) + 1; ## Bank numbers are 1 based
  }
  
  ## Validate parameters
  return unless ($self->_valid_bank_and_relay($bank, $relay));
  ## Make sure bank != 0
  unless ($bank)
  {
    $self->_error_message(qq{Bank parameter cannot be 0!});
    return;
  }

  ## Send the command
  $self->send_command($PROXR_CMD_BANK_DIRECTED_RELAY_ON + $relay, $bank);
  
  return $self->get_response;
}

##****************************************************************************
##****************************************************************************

=head2 relay_off($relay)

=head2 relay_off($bank, $relay)

=over 2

=item B<Description>

Turn off the relay of the specified bank

=item B<Parameters>

$bank - Bank number of the relay to control (1 based)
$relay - Relay number of the relay to control (0 based)

=item B<Return>

UNDEF on error (with last_error set)

=item B<NOTE>

If only one parameter is specified, it is treated as a 0 based relay number
and the bank is calculated as (relay / 8) + 1, and the relay within the bank
is caluclated as (relay % 8)

=back

=cut

##----------------------------------------------------------------------------
sub relay_off
{
  my $self  = shift;
  my $bank  = shift;
  my $relay = shift;

  ## See if we just received 1 parameter  
  if (defined($bank) and (!defined($relay)))
  {
    ## Convert this into bank and relay
    $relay = $bank % 8;
    $bank = int($bank/8);
  }
  
  ## Validate parameters
  return unless ($self->_valid_bank_and_relay($bank, $relay));
  ## Make sure bank != 0
  unless ($bank)
  {
    $self->_error_message(qq{Bank parameter cannot be 0!});
    return;
  }

  ## Send the command
  $self->send_command($PROXR_CMD_BANK_DIRECTED_RELAY_OFF + $relay, $bank);
  
  return $self->get_response;
}

##****************************************************************************
##****************************************************************************

=head2 relay_status($bank, $relay)

=over 2

=item B<Description>

Get the status of the relay of the specified bank

=item B<Parameters>

$bank - Bank number of the relay to control
$relay - Relay number of the relay to control

=item B<Return>

UNDEF on error (with last_error set)
0 == Relay is OFF
1 == Relay is ON

=back

=cut

##----------------------------------------------------------------------------
sub relay_status
{
  my $self  = shift;
  my $bank  = shift;
  my $relay = shift;

  ## Validate parameters
  return unless ($self->_valid_bank_and_relay($bank, $relay));
  ## Make sure bank != 0
  unless ($bank)
  {
    $self->_error_message(qq{Bank parameter cannot be 0!});
    return;
  }

  ## Send the command
  $self->send_command($PROXR_CMD_BANK_DIRECTED_RELAY_STATUS + $relay, $bank);
  
  ## Get the response
  my $resp = $self->get_response;
  if (defined($resp) && length($resp))
  {
    return(ord(substr($resp, 0, 1)));
  }
  return;
}

##****************************************************************************
##****************************************************************************

=head2 relay_control($on, $relay)

=head2 relay_control($on, $bank, $relay)

=over 2

=item B<Description>

Turn the relay on or off

=item B<Parameters>

$on - Indicates if the relay should be turned on or off
$bank - Bank number of the relay to control (1 based)
$relay - Relay number of the relay to control (0 based)

=item B<Return>

UNDEF on error (with last_error set)

=item B<NOTE>

If only two parameters are specified, the second parameter is treated as a 
0 based relay number and the bank is calculated as (relay / 8) + 1, and the
relay within the bank is caluclated as (relay % 8)

=back

=cut

##----------------------------------------------------------------------------
sub relay_control
{
  my $self  = shift;
  my $on    = shift;
  my $bank  = shift;
  my $relay = shift;

  ## See if we just received 1 parameter  
  if (defined($bank) and (!defined($relay)))
  {
    ## Convert this into bank and relay
    $relay = $bank % 8;
    $bank = int($bank / 8) + 1; ## Bank numbers are 1 based
  }
  
  ## Validate parameters
  return unless ($self->_valid_bank_and_relay($bank, $relay));
  ## Make sure bank != 0
  unless ($bank)
  {
    $self->_error_message(qq{Bank parameter cannot be 0!});
    return;
  }

  ## Set the command to be sent
  my $cmd = ($on ? $PROXR_CMD_BANK_DIRECTED_RELAY_ON : $PROXR_CMD_BANK_DIRECTED_RELAY_OFF);
  
  ## Send the command
  $self->send_command($cmd + $relay, $bank);
  
  return $self->get_response;
}

##****************************************************************************
##****************************************************************************

=head2 all_on()

=over 2

=item B<Description>

Turn on all relays on all banks

=item B<Parameters>

NONE

=item B<Return>

NONE

=back

=cut

##----------------------------------------------------------------------------
sub all_on
{
  my $self  = shift;

  ## Send the command
  $self->send_command($PROXR_CMD_BANK_DIRECTED_RELAY_ALL_ON, 0);
  
  ## Return the response
  return $self->get_response;
}


##****************************************************************************
##****************************************************************************

=head2 all_off()

=over 2

=item B<Description>

Turn off all relays on all banks

=item B<Parameters>

NONE

=item B<Return>

NONE

=back

=cut

##----------------------------------------------------------------------------
sub all_off
{
  my $self  = shift;

  ## Send the command
  $self->send_command($PROXR_CMD_BANK_DIRECTED_RELAY_ALL_OFF, 0);
  
  ## Return the response
  return $self->get_response;
}

##****************************************************************************
##****************************************************************************

=head2 bank_on($bank)

=over 2

=item B<Description>

Turn on all relays on the specified bank

=item B<Parameters>

$bank - Bank number of bank to control

=item B<Return>

NONE

=back

=cut

##----------------------------------------------------------------------------
sub bank_on
{
  my $self = shift;
  my $bank = shift;

  ## Validate parameters
  return unless ($self->_valid_bank($bank));
  ## Make sure bank != 0
  unless ($bank)
  {
    $self->_error_message(qq{Bank parameter cannot be 0!});
    return;
  }
  
  ## Send the command
  $self->send_command($PROXR_CMD_BANK_DIRECTED_RELAY_ALL_ON, $bank);
  
  ## Return the response
  return $self->get_response;
}

##****************************************************************************
##****************************************************************************

=head2 bank_off($bank)

=over 2

=item B<Description>

Turn off all relays on the specified bank

=item B<Parameters>

$bank - Bank number of bank to control

=item B<Return>

NONE

=back

=cut

##----------------------------------------------------------------------------
sub bank_off
{
  my $self = shift;
  my $bank = shift;

  ## Validate parameters
  return unless ($self->_valid_bank($bank));
  ## Make sure bank != 0
  unless ($bank)
  {
    $self->_error_message(qq{Bank parameter cannot be 0!});
    return;
  }
  
  ## Send the command
  $self->send_command($PROXR_CMD_BANK_DIRECTED_RELAY_ALL_OFF, $bank);
  
  ## Return the response
  return $self->get_response;
}

##****************************************************************************
##****************************************************************************

=head2 bank_invert($bank)

=over 2

=item B<Description>

Invert the status of all relays on the specified bank

=item B<Parameters>

$bank - Bank number of bank to control

=item B<Return>

NONE

=back

=cut

##----------------------------------------------------------------------------
sub bank_invert
{
  my $self = shift;
  my $bank = shift;

  ## Validate parameters
  return unless ($self->_valid_bank($bank));
  ## Make sure bank != 0
  unless ($bank)
  {
    $self->_error_message(qq{Bank parameter cannot be 0!});
    return;
  }
  
  ## Send the command
  $self->send_command($PROXR_CMD_BANK_DIRECTED_RELAY_INVERT, $bank);
  
  ## Return the response
  return $self->get_response;
}

##****************************************************************************
##****************************************************************************

=head2 bank_reverse($bank)

=over 2

=item B<Description>

Reverse / mirror the status of all relays on the specified bank

=item B<Parameters>

$bank - Bank number of bank to control

=item B<Return>

NONE

=back

=cut

##----------------------------------------------------------------------------
sub bank_reverse
{
  my $self = shift;
  my $bank = shift;

  ## Validate parameters
  return unless ($self->_valid_bank($bank));
  ## Make sure bank != 0
  unless ($bank)
  {
    $self->_error_message(qq{Bank parameter cannot be 0!});
    return;
  }
  
  ## Send the command
  $self->send_command($PROXR_CMD_BANK_DIRECTED_RELAY_MIRROR, $bank);
  
  ## Return the response
  return $self->get_response;
}

##****************************************************************************
##****************************************************************************

=head2 bank_status($bank)

=over 2

=item B<Description>

Return a byte with the statTurn on all relays on the specified bank

=item B<Parameters>

$bank - Bank number of bank to control

=item B<Return>

SCALAR - Each bit represents relay 0-7 status

=back

=cut

##----------------------------------------------------------------------------
sub bank_status
{
  my $self = shift;
  my $bank = shift;

  ## Validate parameters
  return unless ($self->_valid_bank($bank));
  ## Make sure bank != 0
  unless ($bank)
  {
    $self->_error_message(qq{Bank parameter cannot be 0!});
    return;
  }
  
  ## Send the command
  $self->send_command($PROXR_CMD_BANK_DIRECTED_STATUS, $bank);
  
  ## Get the response
  my $resp = $self->get_response;
  if (defined($resp) && length($resp))
  {
    return(ord(substr($resp, 0, 1)));
  }
  return;
}

##----------------------------------------------------------------------------
##     @fn _valid_bank_and_relay($bank, $relay)
##  @brief Returns TRUE value if bank AND relay are valid, or UNDEF if 
##         either bank OR relay is invalid
##  @param $bank - Bank number
##  @param $relay - Relay number
## @return UNDEF with error_message set if bank OR relay is invalid
##         1 if bank AND relay are valid
##   @note 
##----------------------------------------------------------------------------
sub _valid_bank_and_relay
{
  my $self  = shift;
  my $bank  = shift;
  my $relay = shift;
  
  return ($self->_valid_bank($bank) && $self->_valid_relay($relay));
}

##----------------------------------------------------------------------------
##     @fn _valid_bank($bank)
##  @brief Returns TRUE value if bank is valid, or UNDEF if bank is invalid
##  @param $bank - Bank number
## @return UNDEF with error_message set if bank is invalid
##         1 if bank is valid
##   @note 
##----------------------------------------------------------------------------
sub _valid_bank
{
  my $self = shift;
  my $bank = shift;
  
  unless (defined($bank))
  {
    $self->_error_message(qq{Bank parameter missing!});
    return;
  }
  unless ($bank =~ /\A\d+\Z/x)
  {
    $self->_error_message(qq{Bank must be a number!});
    return;
  }
  if (($bank < 0) || ($bank > 255))
  {
    $self->_error_message(qq{Bank must be a number between 0 and 255!});
    return;
  }
  
  return 1;
}

##----------------------------------------------------------------------------
##     @fn _valid_relay($relay)
##  @brief Returns TRUE value if relay is valid, or UNDEF if relay is invalid
##  @param $relay - Relay number
## @return UNDEF with error_message set if relay is invalid
##         1 if relay is valid
##   @note 
##----------------------------------------------------------------------------
sub _valid_relay
{
  my $self = shift;
  my $relay = shift;
 
  unless (defined($relay))
  {
    $self->_error_message(qq{Relay parameter missing!});
    return;
  }
  unless ($relay =~ /\A\d+\Z/x)
  {
    $self->_error_message(qq{Relay must be a number!});
    return;
  }
  if (($relay < 0) || ($relay > 7))
  {
    $self->_error_message(qq{Relay must be a number between 0 and 7!});
    return;
  }
  
  return 1;
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

