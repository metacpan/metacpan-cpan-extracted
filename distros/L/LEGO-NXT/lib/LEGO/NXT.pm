# vim: sts=2 sw=2

# LEGO NXT Direct Commands API
# Author: Michael Collins michaelcollins@ivorycity.com
# Contributions: Aran Deltac aran@arandeltac.com
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
#
# You may also distribute under the terms of Perl Artistic License,
# as specified in the Perl README file.
#

package LEGO::NXT;
use strict;
use warnings;

use Net::Bluetooth;
#Not ready for USB yet...
#use Device::USB;
use LEGO::NXT::Constants;

our $VERSION = '1.42';
our @ISA;

=head1 NAME

LEGO::NXT - LEGO NXT Direct Commands API.

=head1 SYNOPSIS

  use LEGO::NXT;
  
  # Create a new Bluetooth/NXT object by connecting to
  # a specific bluetooth address and channel.
  my $nxt = LEGO::NXT->new( 'xx:xx:xx:xx:xx:xx', 1 );
  
  $nxt->play_sound_file($NXT_NORET, 0,'! Attention.rso');
  
  $res  = $nxt->get_battery_level($NXT_RET);
  
  # Turn on Motor 1 to full power.
  $res = $nxt->set_output_state(
    $NXT_RET,
    $NXT_SENSOR1,
    100,
    $NXT_MOTORON|$NXT_REGULATED,
    $NXT_REGULATION_MODE_MOTOR_SPEED, 0,
    $NXT_MOTOR_RUN_STATE_RUNNING, 0,
  );

=head1 DESCRIPTION

This module provides low-level control of a LEGO NXT brick over bluetooth
using the Direct Commands API.  This API will not enable you to run programs
on the NXT, rather, it will connect to the NXT and issue real-time commands
that turn on/off motors, retrieve sensor values, play sound, and more.

Users will leverage this API to control the NXT directly from an external box.

This is known to work on Linux. Other platforms are currently untested,
though it should work on any system that has the Net::Bluetooth module.

=head1 MANUAL

There is a manual for this module with an introduction, tutorials, plugins,
FAQ, etc.  See L<LEGO::NXT::Manual>.

=head1 SUPPORT

If you would like to get some help join the #lego-nxt IRC chat room
on the MagNET IRC network (the official perl IRC network).  More
information at:

L<http://www.irc.perl.org/>

=head1 PLUGINS

LEGO::NXT supports the ability to load plugins.

  use LEGO::NXT qw( Scorpion );

Plugins provide higher level and more sophisticated means of handling
your NXT.  Likely you will want to use a plugin if you want to control
your NXT as the methods in LEGO::NXT itself are very low level and
tedious to use by themselves.

Please see L<LEGO::NXT::Manual::Plugins> for more details about how to
use plugins (and write your own!) as well as what plugins are available
to you.

=cut

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

  $nxt = LEGO::NXT->new( 'xx:xx:xx:xx:xx:xx', 1 );

Creates a new NXT object, however a connection is not established until
the first direct command is issued. Argument 1 should be the bluetooth
address of your NXT (from "hcitool scan" for instance). Argument 2 is
the channel you wish to connect on -- 1 or 2 seems to work.

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

=head2 initialize_ultrasound_port

  $nxt->initialize_ultrasound_port($NXT_SENSOR_4);

Sets the port of your choosing to use the ultrasound digital sensor.

=cut

sub initialize_ultrasound_port
{
  my ($this,$port) = @_;
  $this->set_input_mode($NXT_RET,$port,$NXT_LOW_SPEED_9V,$NXT_RAW_MODE); 
}

=head2 get_ultrasound_measurement_units 

  $nxt->get_ultrasound_measurement_units($NXT_SENSOR_4);

Returns the units of measurement the US sensor is using (cm? in?)

=cut

sub get_ultrasound_measurement_units
{
  my ($this,$port) = @_;
  return $this->ls_request_response($port,2,7,pack("CC",0x02,0x14));
}

=head2 get_ultrasound_measurement_byte

  $nxt->get_ultrasound_measurement_byte($NXT_SENSOR_4,$byte);

Returns the distance reading from the NXT from register $byte.
$byte should be a value 0-7 indicating the measurement register 
in the ultrasound sensor. In continuous measurement mode, 
measurements are stored in register 0 only, however in one-shot mode,
each time one-shot is called a value will be stored in a new register.

=cut

sub get_ultrasound_measurement_byte
{
  my ($this,$port,$byte) = @_;
  return $this->ls_request_response($port,2,1,pack("CC",0x02,0x42+$byte));
}

=head2 get_ultrasound_continuous_measurement_interval

  $nxt->get_ultrasound_measurement_interval($NXT_SENSOR_4);

Returns the time period between ultrasound measurements.

=cut

sub get_ultrasound_continuous_measurement_interval
{
  my ($this,$port)=@_;
  return $this->ls_request_response($port,2,1,pack("CC",0x02,0x40));
}

=head2 get_ultrasound_read_command_state

  $nxt->get_ultrasound_read_command_state($NXT_SENSOR_4);

Returns whether the sensor is in one-off mode or continuous measurement
mode (the default).

=cut

sub get_ultrasound_read_command_state
{
  my ($this,$port) = @_;
  return $this->ls_request_response($port,2,1,pack("CC",0x02,0x41));
}

=head2 get_ultrasound_actual_zero

  $nxt->get_ultrasound_actual_zero($NXT_SENSOR_4);

Returns the calibrated zero-distance value for the sensor

=cut

sub get_ultrasound_actual_zero
{
  my ($this,$port) = @_;
  return $this->ls_request_response($port,2,1,pack("CC",0x02,0x50));
}

=head2 get_ultrasound_actual_scale_factor

  $nxt->get_ultrasound_actual_scale_factor($NXT_SENSOR_4);

Returns the scale factor used to compute distances

=cut

sub get_ultrasound_actual_scale_factor
{
  my ($this,$port) = @_;
  return $this->ls_request_response($port,2,1,pack("CC",0x02,0x51));
}

=head2 get_ultrasound_actual_scale_divisor

  $nxt->get_ultrasound_actual_scale_divisor($NXT_SENSOR_4);

Returns the scale divisor used to compute distances

=cut

sub get_ultrasound_actual_scale_divisor
{
  my ($this,$port) = @_;
  return $this->ls_request_response($port,2,1,pack("CC",0x02,0x52));
}

=head2 set_ultrasound_off

  $nxt->set_ultrasound_off($NXT_SENSOR_4);

Turns the ultrasound sensor off

=cut

sub set_ultrasound_off
{
  my ($this,$port) = @_;
  return $this->ls_write($NXT_RET,$port,3,0,pack("CCC",0x02,0x41,0x00));
}

=head2 set_ultrasound_single_shot

  $nxt->set_ultrasound_single_shot($NXT_SENSOR_4);

Puts the sensor in single shot mode - it will only store a value in a register once each time this function is called

=cut

sub set_ultrasound_single_shot
{
  my ($this,$port) = @_;
  return $this->ls_write($NXT_RET,$port,3,0,pack("CCC",0x02,0x41,0x01));
}

=head2 set_ultrasound_continuous_measurement

  $nxt->set_ultrasound_continuous_measurement($NXT_SENSOR_4);

Puts the sensor in continuous measurement mode.  

=cut

sub set_ultrasound_continuous_measurement
{
  my ($this,$port) = @_;
  return $this->ls_write($NXT_RET,$port,3,0,pack("CCC",0x02,0x41,0x02));
}

=head2 set_ultrasound_event_capture_mode

  $nxt->set_ultrasound_event_capture_mode($NXT_SENSOR_4);

In this mode the US sensor will detect only other ultrasound sensors in the vicinity.

=cut

sub set_ultrasound_event_capture_mode
{
  my ($this,$port) = @_;
  return $this->ls_write($NXT_RET,$port,3,0,pack("CCC",0x02,0x41,0x03)); 
}

=head2 ultrasound_request_warm_reset

  $nxt->ultrasound_request_warm_reset($NXT_SENSOR_4);

I won't lie - I don't know what a "warm reset" is, but it sounds like a nice 
new beginning to me. =)

=cut

sub ultrasound_request_warm_reset
{
  my ($this,$port) = @_;
  return $this->ls_write($NXT_RET,$port,3,0,pack("CCC",0x02,0x41,0x04));
}

=head2 set_ultrasound_continuous_measurement_interval

  $nxt->set_ultrasound_continuous_measurement_interval($NXT_SENSOR_4);

Sets the sampling interval for the range sensor.

TODO: Document valid values...

=cut

sub set_ultrasound_continuous_measurement_interval
{
  my ($this,$port,$interval) = @_;
  return $this->ls_write($NXT_RET,3,0,pack("CCC",0x02,0x40,$interval));
}

=head2 set_ultrasound_actual_zero

  $nxt->set_ultrasound_actual_zero($NXT_SENSOR_4);

Sets the calibrated zero value for the sensor.

=cut

sub set_ultrasound_actual_zero
{
  my ($this,$port,$value) = @_;
  return $this->ls_write($port,3,0,pack("CCC",0x02,0x50,$value));
}

=head2 set_ultrasound_actual_scale_factor

  $nxt->set_ultrasound_actual_scale_factor($NXT_SENSOR_4);

Sets the scale factor used in computing range.

=cut

sub set_ultrasound_actual_scale_factor
{
  my ($this,$port,$value) = @_;
  return $this->ls_write($port,3,0,pack("CCC",0x02,0x51,$value));
}

=head2 set_ultrasound_actual_scale_divisor

  $nxt->set_ultrasound_actual_scale_divisor($NXT_SENSOR_4);

Sets the scale divisor used in computing range.

=cut

sub set_ultrasound_actual_scale_divisor
{
  my ($this,$port,$value) = @_;
  return $this->ls_write($port,3,0,pack("CCC",0x02,0x52,$value));
}

=head2 start_program

  $nxt->start_program($NXT_NORET,$filename)

Start a program on the NXT called $filename 

=cut

sub start_program
{
  my ($this,$needsret,$file) = @_;
  my $strlen = 1+length($file);
  my $ret    = $this->_do_cmd(
    pack("v",3+$strlen).
    pack("CCZ[$strlen]",$needsret,$NXT_START_PROGRAM,$file),
    $needsret
  );

  return if $needsret==$NXT_NORET;

  $this->_parse_generic_ret($ret);
}

=head2 stop_program

  $nxt->stop_program($NXT_NORET)

Stop the currently executing program on the NXT

=cut

sub stop_program
{
  my ($this,$needsret) = @_;

  my $ret = $this->_do_cmd(
    pack("v",2).
    pack("CC",$needsret,$NXT_STOP_PROGRAM),
    $needsret
  );

  return if $needsret==$NXT_NORET;
  $this->_parse_generic_ret($ret);
}

=head2 play_tone

  $nxt->play_tone($NXT_NORET,$pitch,$duration)

Play a Tone in $pitch HZ for $duration miliseconds

=cut

sub play_tone
{
  my ($this,$needsret,$pitch,$duration) = @_;

  my $ret = $this->_do_cmd(
    pack("v", 6).
    pack("CCvv",0x80,$NXT_PLAY_TONE,$pitch,$duration),
    $needsret
  );

  return if $needsret==$NXT_NORET;

  $this->_parse_generic_ret($ret);
}

=head2 play_sound_file

  $nxt->play_sound_file($NXT_NORET,$repeat,$file)

Play a NXT sound file called $file. Specify $repeat=1 for infinite repeat, 0 to play only once.

=cut

sub play_sound_file
{
  my ($this,$needsret,$repeat,$file) = @_;
  my $strlen = 1+length($file);
  my $ret    = $this->_do_cmd( 
    pack("v",3+$strlen).
    pack("CCCZ[$strlen]",$needsret,$NXT_PLAY_SOUND_FILE,$repeat,$file), 
    $needsret
  );
  
  return if $needsret==$NXT_NORET;
  
  $this->_parse_generic_ret($ret);
}

=head2 set_output_state

  $nxt->set_output_state($NXT_NORET,$port,$power,$mode,$regulation,$turnratio,$runstate,$tacholimit)

Set the output state for one of the motor ports.

  $port        One of the motor port constants.
  $power       -100 to 100 power level.
  $mode        An bitwise or of output mode constants.
  $regulation  One of the motor regulation mode constants.
  $runstate    One of the motor runstate constants.
  $tacholimit  Number of rotation ticks the motor should turn before it stops.

=cut

sub set_output_state
{
  my ($this,$needsret,$port,$power,$mode,$regulation,$turnratio,$runstate,$tacholimit) = @_;
  my $ret = $this->_do_cmd(
    pack("v",12).
    pack("CCCcCCcCV",$needsret,$NXT_SET_OUTPUT_STATE,$port,$power,$mode,$regulation,$turnratio,$runstate,$tacholimit),
    $needsret
  );

  return if $needsret==$NXT_NORET;
  
  $this->_parse_generic_ret($ret);
}

=head2 set_input_mode

  $nxt->set_input_mode($NXT_NORET,$port,$sensor_type,$sensor_mode)

Configure the input mode of a sensor port.

  $port         A sensor port constant.
  $sensor_type  A sensor type constant.
  $sensor_mode  A sensor mode constant.

=cut

sub set_input_mode
{
  my ($this,$needsret,$port,$sensor_type,$sensor_mode) = @_;

  my $ret = $this->_do_cmd(
    pack("v",5).
    pack("CCCCC",$needsret,$NXT_SET_INPUT_MODE,$port,$sensor_type,$sensor_mode),
    $needsret
  );

  return if $needsret==$NXT_NORET;
  
  $this->_parse_generic_ret($ret);  
}

=head2 get_output_state

  $ret = $nxt->get_output_state($NXT_RET,$port)

Retrieve the current ouput state of $port.

  $ret  A hashref containing the port attributes.

=cut

sub get_output_state
{
  my ($this,$needsret,$port) = @_;
  my $ret = $this->_do_cmd(
    pack("v",3).
    pack("CCC",$needsret,$NXT_GET_OUTPUT_STATE,$port),
    $needsret
  );

  return if $needsret==$NXT_NORET;
  
  $this->_parse_get_output_state($ret);
}

=head2 get_input_values

  $ret = $nxt->get_input_values($NXT_RET,$port)

Retrieve the current sensor input values of $port.

  $ret  A hashref containing the sensor value attributes.

=cut

sub get_input_values
{
  my ($this,$needsret,$port) = @_;
  my $ret = $this->_do_cmd(
    pack("v",3).
    pack("CCC",$needsret,$NXT_GET_INPUT_VALUES,$port),
    $needsret
  );

  return if $needsret==$NXT_NORET;
  $this->_parse_get_input_values($ret);
}

=head2 reset_input_scaled_value

  $nxt->reset_input_scaled_value($NXT_NORET,$port)

If your sensor port is using scaled values, reset them.

=cut

sub reset_input_scaled_value
{
  my ($this,$needsret,$port) = @_;
  my $ret = $this->_do_cmd(
    pack("v",3).
    pack("CCC",$needsret,$NXT_RESET_SCALED_INPUT_VALUE,$port),
    $needsret
  );

  return if $needsret==$NXT_NORET;
  $this->_parse_generic_ret($ret);
}

=head2 message_write

  $nxt->message_write($NXT_NORET,$mailbox,$message)

Write a $message to local mailbox# $mailbox.

=cut

sub message_write
{
  my ($this,$needsret,$mailbox,$message) = @_;
  my $mlen = 1+length($message);

  my $ret = $this->_do_cmd(
    pack("v",4+$mlen).
    pack("CCCCZ[$mlen]",$needsret,$NXT_MESSAGE_WRITE,$mailbox,$mlen,$message),
    $needsret
  );

  return if $needsret==$NXT_NORET;
  $this->_parse_generic_ret($ret);
}

=head2 reset_motor_position

  $nxt->reset_motor_position($NXT_NORET,$port,$relative)

TODO: Specifics

=cut

sub reset_motor_position
{
  my ($this,$needsret,$port,$relative) = @_;

  my $ret = $this->_do_cmd(
    pack("v",4).
    pack("CCCC",$needsret,$NXT_RESET_MOTOR_POSITION,$port,$relative),
    $needsret
  );

  return if $needsret==$NXT_NORET;
  $this->_parse_generic_ret($ret);
}

=head2 get_battery_level

  $ret = $nxt->get_battery_level($NXT_RET)

  $ret  A hash containing battery attributes - voltage in MV

=cut

sub get_battery_level
{
  my ($this,$needsret) = @_;

  my $ret = $this->_do_cmd(
    pack("v",2).
    pack("CC",$needsret,$NXT_GET_BATTERY_LEVEL),
    $needsret
  );

  return if $needsret==$NXT_NORET;
  $this->_parse_get_battery_level($ret);
}

=head2 set_stop_sound_playback

  $nxt->set_stop_sound_playback($NXT_NORET)

Stops the currently playing sound file

=cut

sub set_stop_sound_playback
{
  my ($this,$needsret) = @_;

  my $ret = $this->_do_cmd(
    pack("v",2).
    pack("CC",$needsret,$NXT_STOP_SOUND_PLAYBACK),
    $needsret
  );

  return if $needsret==$NXT_NORET;
  $this->_parse_generic_ret($ret);
}

=head2 keep_alive

  $nxt->keep_alive($NXT_NORET)

Prevents the NXT from entering sleep mode

=cut

sub keep_alive
{
  my ($this,$needsret) = @_;
  
  my $ret = $this->_do_cmd(
    pack("v",2).
    pack("CC",$needsret,$NXT_KEEP_ALIVE),
    $needsret	    
  );

  return if $needsret==$NXT_NORET;
  $this->_parse_generic_ret($ret);    
}

=head2 ls_get_status

  $nxt->ls_get_status($NXT_RET,$port)

Determine whether there is data ready to read from an I2C digital sensor.
NOTE: The Ultrasonic Range sensor is such a sensor and must be interfaced via the ls* commands

=cut

sub ls_get_status
{
  my ($this,$needsret,$port) = @_;

  my $ret = $this->_do_cmd(
    pack("v",3).
    pack("CCC",$needsret,$NXT_LSGET_STATUS,$port),
    $needsret
  );

  return if $needsret==$NXT_NORET;
  $this->_parse_ls_get_status($ret);		      
}

=head2 ls_write

  $nxt->ls_write($NXT_RET,$port,$txlen,$rxlen,$txdata)

Send an I2C command to a digital I2C sensor.

  $port    The sensor port of the I2C sensor
  $txlen   The length of $txdata
  $rxlen   The length of the expected response (sensor/command specific)
  $txdata  The I2C command you wish to send in packed byte format.
           NOTE: The NXT will suffix the command with a status byte R+0x03,
           but you dont need to worry about this. Do not send it as part of
           $txdata though - it will result in a bus error.

NOTE: The Ultrasonic Range sensor is such a sensor and must be interfaced via the ls* commands

=cut

sub ls_write
{
  my ($this,$needsret,$port,$txlen,$rxlen,$txdata) = @_;

  my $ret = $this->_do_cmd(
    pack("v",5+$txlen).
    pack("CCCCC",$needsret,$NXT_LSWRITE,$port,$txlen,$rxlen).
    $txdata,
    $needsret
  );

  return if $needsret==$NXT_NORET;
  $this->_parse_generic_ret($ret);		      
}

=head2 ls_read

  $nxt->ls_read($NXT_RET,$port)

Read a pending I2C message from a digital I2C device.

=cut

sub ls_read
{
  my ($this,$needsret,$port) = @_;

  my $ret = $this->_do_cmd(
    pack("v",3).
    pack("CCC",$needsret,$NXT_LSREAD,$port),
    $needsret
  );

  return if $needsret==$NXT_NORET;
  $this->_parse_ls_read($ret);  
}

=head2 ls_request_response

  $nxt->ls_request_response($port,$txlen,$rxlen,$txdata)

Higher level I2C request-response routine. Loops to ensure data is ready
to read from the sensor and returns the result. 

=cut

sub ls_request_response
{
  my ($this,$port,$txlen,$rxlen,$data) = @_;

  $this->ls_write($NXT_NORET,$port,$txlen,$rxlen,$data);

  my $lsstat;

  do{ $lsstat=$this->ls_get_status($NXT_RET,$port); } while ( $lsstat->{bytesready} < $rxlen );

  $this->ls_read($NXT_RET,$port);
}

=head2 get_current_program_name

  $ret = $nxt->get_current_program_name($NXT_RET)

$ret is a hash containing info on the current;y running program.

=cut

sub get_current_program_name
{
  my ($this,$needsret) = @_;

  my $ret = $this->_do_cmd(
     pack("v",2).
     pack("CC",$needsret,$NXT_GET_CURRENT_PROGRAM_NAME),
     $needsret
  );

  return if $needsret==$NXT_NORET;
  $this->_parse_get_current_progran_name($ret);
}

=head2 message_read

  $ret = $nxt->message_read($NXT_RET,$remotebox,$localbox,$remove)

Read a message.

=cut

sub message_read
{
  my ($this,$needsret,$remotebox,$localbox,$remove) = @_;
  
  my $ret = $this->_do_cmd(
    pack("v",5).
    pack("CCCCC",$needsret,$NXT_MESSAGE_READ,$remotebox,$localbox,$remove),
    $needsret
  );

  return if $needsret==$NXT_NORET;
  $this->_parse_message_read($ret);
}

=head1 PRIVATE METHODS

=head2 _do_cmd

=cut

sub _do_cmd
{
  my ($this,$msg,$needsret) = @_;

  $this->_bt_connect() unless defined $this->{fh};

  my $fh = $this->{fh};
  
  syswrite( $fh, $msg, length $msg );
  return if( $needsret == $NXT_NORET );
  
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

=head2 _bt_connect

=cut

sub _bt_connect
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

=head2 _parse_get_output_state

=cut

sub _parse_get_output_state
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

=head2 _parse_get_input_values

=cut

sub _parse_get_input_values
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

=head2 _parse_get_battery_level

=cut

sub _parse_get_battery_level
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

=head2 _parse_ls_get_status

=cut

sub _parse_ls_get_status
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

=head2 _parse_ls_read

=cut

sub _parse_ls_read
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

=head2 _parse_get_current_program_name

=cut

sub _parse_get_current_program_name
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

=head2 _parse_message_read

=cut

sub _parse_message_read
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

=head2 _parse_generic_ret

=cut

sub _parse_generic_ret
{
  my ($this,$ret)=@_;
  my ($len,$rval,$status) = unpack( "vvC", $ret );

  return
  {
    'status'            => $status,
    'statstr'           => $status>0 ? $error_codes{$status} : 'ok'
  };
}

=head2 import

This is a custom import method for supporting
plugins.  See L<LEGO::NXT::Manual::Plugins>.

=cut

sub import {
  my $class = shift;
  foreach my $plugin (@_) {
    $plugin = $class . '::' . $plugin;

    # Skip out if this module is already in @ISA.
    next if (grep { ($_ eq $plugin) ? 1 : () } @ISA);

    eval("require $plugin");
    die("Problem loading $plugin: $@") if($@);

    push @ISA, $plugin;
  }
}

1;
__END__

=head1 AUTHOR

Michael Collins <michaelcollins@ivorycity.com>

=head1 CONTRIBUTORS

Aran Deltac <bluefeet@cpan.org>

=head1 LICENSE

You may distribute under the terms of either the GNU General Public
License or the Artistic License, as specified in the Perl README file.

=head1 COPYRIGHT

The LEGO::NXT module is Copyright (c) 2006 Michael Collins. USA.
All rights reserved.

=head1 SUPPORT / WARRANTY

See Additional Resources at L<http://nxt.ivorycity.com>

LEGO::NXT is free open source software. IT COMES WITHOUT WARRANTY OF ANY KIND.
