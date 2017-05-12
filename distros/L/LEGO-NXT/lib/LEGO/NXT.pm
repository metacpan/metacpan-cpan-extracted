# LEGO NXT Direct Commands API
# Author: Michael Collins michaelcollins@ivorycity.com
#
# Copyright 2006 Michael Collins
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software Foundation,
# Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.

package NXT;
use strict;
use Net::Bluetooth;
use Data::Dumper;

our $VERSION = '1.40';

=head1 NAME NXT

A Perl module for the LEGO NXT Direct Commands interface.

=head1 SYNOPSIS

use LEGO::NXT;
use Data::Dumper;

# Create a new Bluetooth/NXT object using btaddr=<xx:xx:xx:xx:xx:xx> and channel=1
my $conn = new NXT('xx:xx:xx:xx:xx:xx',1);

#issue the command to play '! Attention.rso'. 
#0 means do not repeat. 
#$NXT::NORET means do not require the NXT to issue a return value
$conn->play_sound_file($NXT::NORET, 0,'! Attention.rso');

#issue the command to retrieve the battery level.
$res  = $conn->get_battery_level($NXT::Ret);
print Dumper($res);

#Turn on Motor 1 to full power
$res = $conn->set_output_state($NXT::RET, 0x01, 100, $NXT::MOTORON|$NXT::Regulated, $NXT::REGULATION_MODE_MOTOR_SPEED, 0, $NXT::MOTOR_RUN_STATE_RUNNING, 0  );
print Dumper($res);

=head1 DESCRIPTION

NXT.pm enables users to control the LEGO NXT brick over bluetooth using the Direct Commands API.

This API will not enable you to run programs on the NXT, rather, it will connect to the NXT and issue real-time commands that turn on/off motors, retrieve sensor values, play sound, and more. 

Users will leverage this API to control the NXT directly from an external box.

This is known to work on Linux. Other platforms are currently untested, though it should work on any system that has the Net::Bluetooth module.

=head1 IMPORTANT CONSTANTS

=head2 RET & NORET

For each request of the NXT, you must specify whether you want the NXT to send a return value.

The constants...

$NXT::RET or $NXT::NORET

...must be passed as the first argument each Direct Commands call.

You may want to avoid requesting a response on every direct command as this can slow things down considerably.

=head2 IO PORT CONSTANTS

$NXT::SENSOR1
$NXT::SENSOR2
$NXT::SENSOR3
$NXT::SENSOR4

$NXT::MOTOR_A
$NXT::MOTOR_B
$NXT::MOTOR_C
$NXT::MOTOR_ALL

=cut

  our $SENSOR_1  = 0x00;
  our $SENSOR_2  = 0x01;
  our $SENSOR_3  = 0x02; 
  our $SENSOR_4  = 0x03;
  
  # motors
  our $MOTOR_A   = 0x00;
  our $MOTOR_B   = 0x01;
  our $MOTOR_C   = 0x02;
  our $MOTOR_ALL = 0xFF;
  
=head2 MOTOR CONTROL CONSTANTS

  $NXT::MOTORON $NXT::BRAKE $NXT::REGULATED

  Output regulation modes: 
  $NXT::REGULATION_MODE_IDLE   
  $NXT::REGULATION_MODE_MOTOR_SPEED  
  $NXT::REGULATION_MODE_MOTOR_SYNC

  Output run states:
  $NXT::MOTOR_RUN_STATE_IDLE
  $NXT::MOTOR_RUN_STATE_RAMPUP
  $NXT::MOTOR_RUN_STATE_RUNNING 
  $NXT::MOTOR_RUN_STATE_RAMPDOWN
  
=cut

  # output mode
  our $MOTORON   = 0x01;
  our $BRAKE     = 0x02;
  our $REGULATED = 0x04;
  
  # output regulation mode
  our $REGULATION_MODE_IDLE        = 0x00;
  our $REGULATION_MODE_MOTOR_SPEED = 0x01;
  our $REGULATION_MODE_MOTOR_SYNC  = 0x02;
  
  # output run state
  our $MOTOR_RUN_STATE_IDLE        = 0x00;
  our $MOTOR_RUN_STATE_RAMPUP      = 0x10;
  our $MOTOR_RUN_STATE_RUNNING     = 0x20;
  our $MOTOR_RUN_STATE_RAMPDOWN    = 0x40;
  

=head2 SENSOR TYPE CONSTANTS

  $NXT::NO_SENSOR   
  $NXT::SWITCH     
  $NXT::TEMPERATURE
  $NXT::REFLECTION
  $NXT::ANGLE    
  $NXT::LIGHT_ACTIVE  
  $NXT::LIGHT_INACTIVE 
  $NXT::SOUND_DB      
  $NXT::SOUND_DBA  
  $NXT::CUSTOM      
  $NXT::LOWSPEED   
  $NXT::LOWSPEED_9V 
  $NXT::NO_OF_SENSOR_TYPES

=cut

  # sensor type
  our $NO_SENSOR           = 0x00;
  our $SWITCH              = 0x01;
  our $TEMPERATURE         = 0x02;
  our $REFLECTION          = 0x03;
  our $ANGLE               = 0x04;
  our $LIGHT_ACTIVE        = 0x05;
  our $LIGHT_INACTIVE      = 0x06;
  our $SOUND_DB            = 0x07;
  our $SOUND_DBA           = 0x08;
  our $CUSTOM              = 0x09;
  our $LOWSPEED            = 0x0A;
  our $LOWSPEED_9V         = 0x0B;
  our $NO_OF_SENSOR_TYPES  = 0x0C;
  
=head2 SENSOR MODE CONSTANTS

  $NXT::RAWMODE   
  $NXT::BOOLEANMODE
  $NXT::TRANSITIONCNTMODE
  
  $NXT::PERIODCOUNTERMODE
  $NXT::PCTFULLSCALEMODE
  $NXT::CELSIUSMODE 
  
  $NXT::FAHRENHEITMODE
  $NXT::ANGLESTEPSMODE
  $NXT::SLOPEMASK 

  $NXT::MODEMASK    
  
=cut
  
  # sensor mode
  our $RAWMODE             = 0x00;
  our $BOOLEANMODE         = 0x20;
  our $TRANSITIONCNTMODE   = 0x40;
  our $PERIODCOUNTERMODE   = 0x60;
  our $PCTFULLSCALEMODE    = 0x80;
  our $CELSIUSMODE         = 0xA0;
  our $FAHRENHEITMODE      = 0xC0;
  our $ANGLESTEPSMODE      = 0xE0;
  our $SLOPEMASK           = 0x1F;
  our $MODEMASK            = 0xE0;
  
  #opcodes
  our $PLAYSOUNDFILE         = 0x02;
  our $PLAYTONE              = 0x03;
  our $SETOUTPUTSTATE        = 0x04;
  our $SETINPUTMODE          = 0x05;
  our $GETOUTPUTSTATE        = 0x06;
  our $GETINPUTVALUES        = 0x07;
  our $RESETSCALEDINPUTVALUE = 0x08;
  our $MESSAGEWRITE          = 0x09;
  our $RESETMOTORPOSITION    = 0x0A;
  our $GETBATTERYLEVEL       = 0x0B;
  our $STOPSOUNDPLAYBACK     = 0x0C;
  our $KEEPALIVE             = 0x0D;
  our $LSGETSTATUS           = 0x0E;
  our $LSWRITE               = 0x0F;
  our $LSREAD                = 0x10;
  our $GETCURRENTPROGRAMNAME = 0x11;
  our $MESSAGEREAD           = 0x13;
  
  our $RET   = 0x00;
  our $NORET = 0x80;

  my %error_codes = (
    0x20 => "Pending communication transaction in progress",
    0x40 => "Specified mailbox queue is empty",
    0xBD => "Request failed (i.e. specified file not found)",
    0xBE => "Unknown command opcode",
    0xBF => "Insane packet",
    0xC0 => "Data contains out-of-range values",
    0xDD => "Communication bus error",
    0xDE => "No free memory in communication buffer",
    0xDF => "Specified channel/connection is not valid",
    0xE0 => "Specified channel/connection not configured or busy",
    0xEC => "No active program",
    0xED => "Illegal size specified",
    0xEE => "Illegal mailbox queue ID specified",
    0xEF => "Attempted to access invalid field of a structure",
    0xF0 => "Bad input or output specified",
    0xFB => "Insufficient memory available",
    0xFF => "Bad arguments"
  );

=head1 METHODS

=head2 new

$conn = new NXT('xx:xx:xx:xx:xx:xx',1);

Creates a new NXT object, however a connection is not established until the first direct command is issued. Argument 1 should be the bluetooth address of your NXT (from "hcitool scan" for instance). Argument 2 is the channel you wish to connect on -- 1 or 2 seems to work. 

=cut

sub new
{
  my ($pkgnm,$btaddr,$channel) = @_;
  my $this = {
    'btaddr'  => $btaddr,
    'channel' => $channel,
    'fh'      => undef,
    'error'   => undef,
    'errstr'  => undef,
    'status'  => undef,
    'result'  => undef
  };
  
  bless $this, $pkgnm;
  return $this;
}

sub initialize_ultrasound_port
{
  my ($this,$port) = @_;
  $this->set_input_mode($RET,$port,$LOWSPEED_9V,$RAWMODE); 
}

sub get_ultrasound_measurement_units
{
  my ($this,$port) = @_;
  return $this->ls_request_response($port,2,7,pack("CC",0x02,0x14));
}

sub get_ultrasound_measurement_byte
{
  my ($this,$port,$byte) = @_;
  return $this->ls_request_response($port,2,1,pack("CC",0x02,0x42+$byte));
}

sub get_ultrasound_continuous_measurement_interval
{
  my ($this,$port)=@_;
  return $this->ls_request_response($port,2,1,pack("CC",0x02,0x40));
}

sub get_ultrasound_read_command_state
{
  my ($this,$port) = @_;
  return $this->ls_request_response($port,2,1,pack("CC",0x02,0x41));
}

sub get_ultrasound_actual_zero
{
  my ($this,$port) = @_;
  return $this->ls_request_response($port,2,1,pack("CC",0x02,0x50));
}

sub get_ultrasound_actual_scale_factor
{
  my ($this,$port) = @_;
  return $this->ls_request_response($port,2,1,pack("CC",0x02,0x51));
}

sub get_ultrasound_actual_scale_divisor
{
  my ($this,$port) = @_;
  return $this->ls_request_response($port,2,1,pack("CC",0x02,0x52));
}

sub set_ultrasound_off
{
  my ($this,$port) = @_;
  return $this->ls_write($RET,$port,3,0,pack("CCC",0x02,0x41,0x00));
}

sub set_ultrasound_single_shot
{
  my ($this,$port) = @_;
  return $this->ls_write($RET,$port,3,0,pack("CCC",0x02,0x41,0x01));
}

sub set_ultrasound_continuous_measurement
{
  my ($this,$port) = @_;
  return $this->ls_write($RET,$port,3,0,pack("CCC",0x02,0x41,0x02));
}

=head2 set_ultrasound_event_capture_mode

$conn->set_ultrasound_event_capture_mode($NXT::SENSOR_4);

In this mode the US sensor will detect only other ultrasound sensors in the vicinity.

=cut

sub set_ultrasound_event_capture_mode
{
  my ($this,$port) = @_;
  return $this->ls_write($RET,$port,3,0,pack("CCC",0x02,0x41,0x03)); 
}

sub ultrasound_request_warm_reset
{
  my ($this,$port) = @_;
  return $this->ls_write($RET,$port,3,0,pack("CCC",0x02,0x41,0x04));
}

sub set_ultrasound_continuous_measurement_interval
{
  my ($this,$port,$interval) = @_;
  return $this->ls_write($RET,3,0,pack("CCC",0x02,0x40,$interval));
}

sub set_ultrasound_actual_zero
{
  my ($this,$port,$value) = @_;
  return $this->ls_write($port,3,0,pack("CCC",0x02,0x50,$value));
}

sub set_ultrasound_actual_scale_factor
{
  my ($this,$port,$value) = @_;
  return $this->ls_write($port,3,0,pack("CCC",0x02,0x51,$value));
}

sub set_ultrasound_actual_scale_divisor
{
  my ($this,$port,$value) = @_;
  return $this->ls_write($port,3,0,pack("CCC",0x02,0x52,$value));
}

sub do_cmd
{
  my ($this,$msg,$needsret) = @_;

  $this->bt_connect() unless defined $this->{fh};

  my $fh = $this->{fh};
  
  syswrite( $fh, $msg, length $msg );
  return if( $needsret == $NORET );
  
  #Begin reading response, if requested.
  
  my ($rin, $rout) = ('',''); 
  my $rbuff;
  my $total;

  vec ($rin, fileno($fh), 1) = 1;

  while( select($rout=$rin, undef, undef, 1) )
  {
    my $char = '';
    my $nread=0;
    eval
    {
      local $SIG{ALRM} = sub { die "alarm\n" };
      alarm 1;
      $nread = sysread $fh, $char, 1;
      alarm 0;
    };
    
    $rbuff .= $char;
  }
  
  return $rbuff;
}

sub bt_connect
{
  my ($this) = @_;
  my $bt = Net::Bluetooth->newsocket("RFCOMM");
  die "Socket could not be created!" unless(defined($bt));

  if($bt->connect($this->{btaddr}, $this->{channel} ) != 0) {
      die "connect error: $!";
  }

  $this->{fh} = $bt->perlfh();
  $| = 1; #just in case our pipes are not already hot.
}

sub start_program
{
}

=head2 play_tone

$conn->play_tone($NXT::NORET,$pitch,$duration)

Play a Tone in $pitch HZ for $duration miliseconds

=cut

sub play_tone
{
  my ($this,$needsret,$pitch,$duration) = @_;

  my $ret = $this->do_cmd(
    pack("v", 6).
    pack("CCvv",0x80,$PLAYTONE,$pitch,$duration),
    $needsret
  );

  return if $needsret==$NORET;

  $this->ParseGenericRet($ret);
}

=head2 play_sound_file

$conn->play_sound_file($NXT::NORET,$repeat,$file)

Play a NXT sound file called $file. Specify $repeat=1 for infinite repeat, 0 to play only once.

=cut

sub play_sound_file
{
  my ($this,$needsret,$repeat,$file) = @_;
  my $strlen = 1+length($file);
  my $ret    = $this->do_cmd( 
    pack("v",3+$strlen).
    pack("CCCZ[$strlen]",$needsret,$PLAYSOUNDFILE,$repeat,$file), 
    $needsret
  );
  
  return if $needsret==$NORET;
  
  $this->ParseGenericRet($ret);
}

=head2 set_output_state

$conn->set_output_state($NXT::NORET,$port,$power,$mode,$regulation,$turnratio,$runstate,$tacholimit)

Set the output state for one of the motor ports.

$port: one of the motor port constants.

$power: -100 to 100 power level.

$mode: an bitwise or of output mode constants.

$regulation: one of the motor regulation mode constants.

$runstate: one of the motor runstate constants.

$tacholimit: number of rotation ticks the motor should turn before it stops.

=cut

sub set_output_state
{
  my ($this,$needsret,$port,$power,$mode,$regulation,$turnratio,$runstate,$tacholimit) = @_;
  my $ret = $this->do_cmd(
    pack("v",12).
    pack("CCCcCCcCV",$needsret,$SETOUTPUTSTATE,$port,$power,$mode,$regulation,$turnratio,$runstate,$tacholimit),
    $needsret
  );

  return if $needsret==$NORET;
  
  $this->ParseGenericRet($ret);
}

=head2 set_input_mode

$conn->set_input_mode($NXT::NORET,$port,$sensor_type,$sensor_mode)

Configure the input mode of a sensor port.

$port: A sensor port constant.

$sensor_type: A sensor type constant.

$sensor_mode: A sensor mode constant.

=cut

sub set_input_mode
{
  my ($this,$needsret,$port,$sensor_type,$sensor_mode) = @_;

  my $ret = $this->do_cmd(
    pack("v",5).
    pack("CCCCC",$needsret,$SETINPUTMODE,$port,$sensor_type,$sensor_mode),
    $needsret
  );

  return if $needsret==$NORET;
  
  $this->ParseGenericRet($ret);  
}

=head2 get_output_state

$ret = $conn->get_output_state($NXT::RET,$port)

Retrieve the current ouput state of $port.

$ret is a hashref containing the port attributes.

=cut

sub get_output_state
{
  my ($this,$needsret,$port) = @_;
  my $ret = $this->do_cmd(
    pack("v",3).
    pack("CCC",$needsret,$GETOUTPUTSTATE,$port),
    $needsret
  );

  return if $needsret==$NORET;
  
  $this->ParseGetOutputState($ret);
}

=head2 get_input_values

$ret = $conn->get_input_values($NXT::RET,$port)

Retrieve the current sensor input values of $port.

$ret is a hashref containing the sensor value attributes.

=cut

sub get_input_values
{
  my ($this,$needsret,$port) = @_;
  my $ret = $this->do_cmd(
    pack("v",3).
    pack("CCC",$needsret,$GETINPUTVALUES,$port),
    $needsret
  );

  return if $needsret==$NORET;
  $this->ParseGetInputValues($ret);			
}

=head2 reset_input_scaled_value

$conn->reset_input_scaled_value($NXT::NORET,$port)

If your sensor port is using scaled values, reset them.

=cut

sub reset_input_scaled_value
{
  my ($this,$needsret,$port) = @_;
  my $ret = $this->do_cmd(
    pack("v",3).
    pack("CCC",$needsret,$RESETSCALEDINPUTVALUE,$port),
    $needsret
  );

  return if $needsret==$NORET;
  $this->ParseGenericRet($ret);		      
}

=head2 message_write

$conn->message_write($NXT::NORET,$mailbox,$message)

Write a $message to local mailbox# $mailbox.

=cut

sub message_write
{
  my ($this,$needsret,$mailbox,$message) = @_;
  my $mlen = 1+length($message);

  my $ret = $this->do_cmd(
    pack("v",4+$mlen).
    pack("CCCCZ[$mlen]",$needsret,$MESSAGEWRITE,$mailbox,$mlen,$message),
    $needsret
  );

  return if $needsret==$NORET;
  $this->ParseGenericRet($ret);
}
		      
=item reset_motor_position

$conn->reset_motor_position($NXT::NORET,$port,$relative)

TODO: Specifics

=cut
		      
sub reset_motor_position
{
  my ($this,$needsret,$port,$relative) = @_;

  my $ret = $this->do_cmd(
    pack("v",4).
    pack("CCCC",$needsret,$RESETMOTORPOSITION,$port,$relative),
    $needsret
  );

  return if $needsret==$NORET;
  $this->ParseGenericRet($ret);			  
}

=head2 get_battery_level

$ret = $conn->get_battery_level($NXT::RET)

$ret is a hash containing battery attributes - voltage in MV

=cut

sub get_battery_level
{
  my ($this,$needsret) = @_;

  my $ret = $this->do_cmd(
    pack("v",2).
    pack("CC",$needsret,$GETBATTERYLEVEL),
    $needsret
  );

  return if $needsret==$NORET;
  $this->ParseGetBatteryLevel($ret);			
}

=head2 set_stop_sound_playback

$conn->set_stop_sound_playback($NXT::NORET)

Stops the currently playing sound file

=cut

sub set_stop_sound_playback
{
  my ($this,$needsret) = @_;

  my $ret = $this->do_cmd(
    pack("v",2).
    pack("CC",$needsret,$STOPSOUNDPLAYBACK),
    $needsret
  );

  return if $needsret==$NORET;
  $this->ParseGenericRet($ret);			
}

=head2 keep_alive

$conn->keep_alive($NXT::NORET)

Prevents the NXT from entering sleep mode

=cut

sub keep_alive
{
  my ($this,$needsret) = @_;
  
  my $ret = $this->do_cmd(
    pack("v",2).
    pack("CC",$needsret,$KEEPALIVE),
    $needsret	    
  );

  return if $needsret==$NORET;
  $this->ParseGenericRet($ret);    
}

=head2 ls_get_status

$conn->ls_get_status($NXT::RET,$port)

Determine whether there is data ready to read from an I2C digital sensor.
NOTE: The Ultrasonic Range sensor is such a sensor and must be interfaced via the ls* commands

=cut

sub ls_get_status
{
  my ($this,$needsret,$port) = @_;

  my $ret = $this->do_cmd(
    pack("v",3).
    pack("CCC",$needsret,$LSGETSTATUS,$port),
    $needsret
  );

  return if $needsret==$NORET;
  $this->ParseLSGetStatus($ret);		      
}

=head2 ls_write

$conn->ls_write($NXT::RET,$port,$txlen,$rxlen,$txdata)

Send an I2C command to a digital I2C sensor.
$port: The sensor port of the I2C sensor
$txlen: The length of $txdata
$rxlen: The length of the expected response (sensor/command specific)
$txdata: The I2C command you wish to send in packed byte format. NOTE: The NXT will suffix the command with a status byte R+0x03, but you dont need to worry about this. Do not send it as part of $txdata though - it will result in a bus error.

NOTE: The Ultrasonic Range sensor is such a sensor and must be interfaced via the ls* commands

=cut

sub ls_write
{
  my ($this,$needsret,$port,$txlen,$rxlen,$txdata) = @_;

  my $ret = $this->do_cmd(
    pack("v",5+$txlen).
    pack("CCCCC",$needsret,$LSWRITE,$port,$txlen,$rxlen).
    $txdata,
    $needsret
  );

  return if $needsret==$NORET;
  $this->ParseGenericRet($ret);		      
}

=head2 ls_read

$conn->ls_read($NXT::RET,$port)

Read a pending I2C message from a digital I2C device.

=cut

sub ls_read
{
  my ($this,$needsret,$port) = @_;

  my $ret = $this->do_cmd(
    pack("v",3).
    pack("CCC",$needsret,$LSREAD,$port),
    $needsret
  );

  return if $needsret==$NORET;
  $this->ParseLSRead($ret);  
}

=head2 ls_request_response

$conn->ls_request_response($port,$txlen,$rxlen,$txdata)

Higher level I2C request-response routine. Loops to ensure data is ready to read from the sensor and returns the result. 

=cut

sub ls_request_response
{
  my ($this,$port,$txlen,$rxlen,$data) = @_;

  $this->ls_write($NORET,$port,$txlen,$rxlen,$data);

  my $lsstat;

  do{ $lsstat=$this->ls_get_status($RET,$port); } while ( $lsstat->{bytesready} < $rxlen );

  $this->ls_read($RET,$port);
}

=head2 get_current_program_name

$ret = $conn->get_current_program_name($NXT::RET)

$ret is a hash containing info on the current;y running program.

=cut

sub get_current_program_name
{
  my ($this,$needsret) = @_;

  my $ret = $this->do_cmd(
     pack("v",2).
     pack("CC",$needsret,$GETCURRENTPROGRAMNAME),
     $needsret
  );

  return if $needsret==$NORET;
  $this->ParseGetCurrentProgramName($ret);
}

=head2 message_read

$ret = $conn->message_read($NXT::RET,$remotebox,$localbox,$remove)

Read a message.

=cut

sub message_read
{
  my ($this,$needsret,$remotebox,$localbox,$remove) = @_;
  
  my $ret = $this->do_cmd(
    pack("v",5).
    pack("CCCCC",$needsret,$MESSAGEREAD,$remotebox,$localbox,$remove),
    $needsret
  );

  return if $needsret==$NORET;
  $this->ParseMessageRead($ret);
}

sub ParseGetOutputState
{
  my ($this,$ret) = @_;
  my 
  (
   $len,
   $rval,
   $status,
   $port,
   $power,
   $mode,
   $regulation,
   $turn_ratio,
   $runstate,
   $tacho_limit,
   $tacho_count,
   $block_tacho_count,
   $rotation_count
  ) 
  = unpack( "vvCCcCCcCVlll", $ret );
  
  return 
  {
    'status'            => $status,
    'statstr'           => $status>0 ? $error_codes{$status} : 'ok',
    'port'              => $port,
    'power'             => $power,
    'mode'              => $mode,
    'regulation'        => $regulation,
    'turn_ratio'        => $turn_ratio,
    'runstate'          => $runstate,
    'tacho_limit'       => $tacho_limit,
    'tacho_count'       => $tacho_limit,
    'block_tacho_count' => $block_tacho_count,
    'rotation_count'    => $rotation_count
  };
}

sub ParseGetInputValues
{
  my ($this,$ret) = @_;
  my
  (
    $len,
    $rval,
    $status,
    $port,
    $valid,
    $calibrated,
    $sensor_type,
    $sensor_mode,
    $raw_value,
    $normal_value,
    $scaled_value,
    $calibrated_value
  )
  = unpack( "vvCCCCCvvss", $ret );

  return
  {
    'status'            => $status,
    'statstr'           => $status>0 ? $error_codes{$status} : 'ok',
    'port'              => $port,
    'valid'             => $valid,
    'calibrated'        => $calibrated,
    'sensor_type'       => $sensor_type,
    'sensor_mode'       => $sensor_mode,
    'raw_value'         => $raw_value,
    'normal_value'      => $normal_value,
    'scaled_value'      => $scaled_value,
    'calibrated_value'  => $calibrated_value # **currently unused**
  };
}

sub ParseGetBatteryLevel
{
  my ($this,$ret)=@_;
  my ($len,$rval,$status,$battery) = unpack( "vvCv", $ret );

  return
  {
   'status'     => $status,
   'statstr'    => $status>0 ? $error_codes{$status} : 'ok',
   'battery_mv' => $battery      
  };		  
}

sub ParseLSGetStatus
{
  my ($this,$ret)=@_;
  my ($len,$rval,$status,$bytesready) = unpack( "vvCC", $ret );

  return
  {
    'status'      => $status,
    'statstr'     => $status>0 ? $error_codes{$status} : 'ok',
    'bytesready'  => $bytesready
  };
}

sub ParseLSRead
{
  my ($this,$ret)=@_;
  my ($len,$rval,$status,$nread,$rxdata) = unpack( "vvCCC[16]", $ret );

  return
  {
    'status'     => $status,
    'statstr'    => $status>0 ? $error_codes{$status} : 'ok',
    'length'     => $nread,
    'data'       => $rxdata 
  };		   
}

sub ParseGetCurrentProgramName
{
  my ($this,$ret)=@_;
  my ($len,$rval,$status,$name) = unpack( "vvC[19]", $ret );

  return
  {
    'status'     => $status,
    'statstr'    => $status>0 ? $error_codes{$status} : 'ok',
    'filename'   => $name
  };
}

sub ParseMessageRead
{
  my ($this,$ret) = @_;
  
  my ($len,$rval,$status,$localbox,$length,$message) = unpack( "vvCCC[58]", $ret );

  return
  {
    'status'     => $status,
    'statstr'    => $status>0 ? $error_codes{$status} : 'ok',
    'localbox'   => $localbox,
    'length'     => $length,
    'message'    => $message
  };
}

sub ParseGenericRet
{
  my ($this,$ret)=@_;
  my ($len,$rval,$status) = unpack( "vvC", $ret );

  return
  {
    'status'            => $status,
    'statstr'           => $status>0 ? $error_codes{$status} : 'ok'
  };
}


1;




