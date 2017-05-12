package Device::Dynamixel;

use strict;
use warnings;
use List::Util qw(sum);
use feature qw(say);
use Const::Fast;

=head1 NAME

Device::Dynamixel - Simple control of Robotis Dynamixel servo motors

=cut

our $VERSION = '0.027';


=head1 SYNOPSIS

 use Device::Dynamixel;

 open my $pipe, '+<', '/dev/ttyUSB0' or die "Couldn't open pipe for reading and writing";
 my $motorbus = Device::Dynamixel->new($pipe);

 # set motion speed of ALL motors to 200
 $motorbus->writeMotor($Device::Dynamixel::BROADCAST_ID,
                       $Device::Dynamixel::addresses{Moving_Speed_L}, [200, 0]);

 # move motor 5 to 10 degrees off-center
 $motorbus->moveMotorTo_deg(5, 10);

 # read the position of motor 5
 my $status = $motorbus->readMotor(5,
                                   $Device::Dynamixel::addresses{Present_Position_L}, 2);
 my @params = @{$status->{params}};
 my $position = $params[1]*255 + $params[0];

=head1 DESCRIPTION

This is a simple module to communicate with Robotis Dynamixel servo motors. The
Dynamixel AX-12 motors have been tested to work with this module, but the others
should work also.

A daisy-chained series string of motors is connected to the host via a simple
serial connection. Each motor in the series has an 8-bit ID. This ID is present
in every command to address specific motors. One Device::Dynamixel object should
be created for a single string of motors connected to one motor port.

These motors communicate using a particular protocol, which is implemented by
this module. Commands are sent to the motor. A status reply is sent back after
each command. This module handles construction and parsing of Dynamixel packets,
as well as the sending and receiving data when needed.

=head2 EXPORTED VARIABLES

To communicate with all motor at once, send commands to the broadcast ID:

 $Device::Dynamixel::BROADCAST_ID

All the motor control addresses described in the Dynamixel docs are defined in this module,
available as

 $Device::Dynamixel::addresses{$value}

Defined values are:

 ModelNumber_L
 ModelNumber_H
 Version_of_Firmware
 ID
 Baud_Rate
 Return_Delay_Time
 CW_Angle_Limit_L
 CW_Angle_Limit_H
 CCW_Angle_Limit_L
 CCW_Angle_Limit_H
 Highest_Limit_Temperature
 Lowest_Limit_Voltage
 Highest_Limit_Voltage
 Max_Torque_L
 Max_Torque_H
 Status_Return_Level
 Alarm_LED
 Alarm_Shutdown
 Down_Calibration_L
 Down_Calibration_H
 Up_Calibration_L
 Up_Calibration_H
 Torque_Enable
 LED
 CW_Compliance_Margin
 CCW_Compliance_Margin
 CW_Compliance_Slope
 CCW_Compliance_Slope
 Goal_Position_L
 Goal_Position_H
 Moving_Speed_L
 Moving_Speed_H
 Torque_Limit_L
 Torque_Limit_H
 Present_Position_L
 Present_Position_H
 Present_Speed_L
 Present_Speed_H
 Present_Load_L
 Present_Load_H
 Present_Voltage
 Present_Temperature
 Registered_Instruction
 Reserved
 Moving
 Lock
 Punch_L
 Punch_H

To change the baud rate of the motor, the B<Baud_Rate> address must be written
with a value

 $Device::Dynamixel::baudrateValues{$baud}

The available baud rates are

 1000000
 500000
 400000
 250000
 200000
 115200
 57600
 19200
 9600

Note that the baud rate generally is cached from the last time the motor was
used, defaulting to 1Mbaud at the start

=head2 STATUS RETURN

Most of the functions return a status hash that describes the status of the motors and/or returns
queried data. This hash is defined as

 { from   => $motorID,
   error  => $error,
   params => \@parameters }

If no valid reply was received, undef is returned. Look at the Dynamixel hardware documentation for
the exact meaning of each hash element.

=cut


# Constants defined in the dynamixel docs
const our $BROADCAST_ID => 0xFE;
const my %instructions =>
  (PING       => 0x01,
   READ_DATA  => 0x02,
   WRITE_DATA => 0x03,
   REG_WRITE  => 0x04,
   ACTION     => 0x05,
   RESET      => 0x06,
   SYNC_WRITE => 0x83);

const our %addresses =>
  (ModelNumber_L             => 0,
   ModelNumber_H             => 1,
   Version_of_Firmware       => 2,
   ID                        => 3,
   Baud_Rate                 => 4,
   Return_Delay_Time         => 5,
   CW_Angle_Limit_L          => 6,
   CW_Angle_Limit_H          => 7,
   CCW_Angle_Limit_L         => 8,
   CCW_Angle_Limit_H         => 9,
   Highest_Limit_Temperature => 11,
   Lowest_Limit_Voltage      => 12,
   Highest_Limit_Voltage     => 13,
   Max_Torque_L              => 14,
   Max_Torque_H              => 15,
   Status_Return_Level       => 16,
   Alarm_LED                 => 17,
   Alarm_Shutdown            => 18,
   Down_Calibration_L        => 20,
   Down_Calibration_H        => 21,
   Up_Calibration_L          => 22,
   Up_Calibration_H          => 23,
   Torque_Enable             => 24,
   LED                       => 25,
   CW_Compliance_Margin      => 26,
   CCW_Compliance_Margin     => 27,
   CW_Compliance_Slope       => 28,
   CCW_Compliance_Slope      => 29,
   Goal_Position_L           => 30,
   Goal_Position_H           => 31,
   Moving_Speed_L            => 32,
   Moving_Speed_H            => 33,
   Torque_Limit_L            => 34,
   Torque_Limit_H            => 35,
   Present_Position_L        => 36,
   Present_Position_H        => 37,
   Present_Speed_L           => 38,
   Present_Speed_H           => 39,
   Present_Load_L            => 40,
   Present_Load_H            => 41,
   Present_Voltage           => 42,
   Present_Temperature       => 43,
   Registered_Instruction    => 44,
   Reserved                  => 45,
   Moving                    => 46,
   Lock                      => 47,
   Punch_L                   => 48,
   Punch_H                   => 49);

const our %baudrateValues =>
  (1000000 => 0x01,
   500000  => 0x03,
   400000  => 0x04,
   250000  => 0x07,
   200000  => 0x09,
   115200  => 0x10,
   57600   => 0x22,
   19200   => 0x67,
   9600    => 0xCF);

# a received packet is deemed complete if no data was received in this much time
const my $timeDelimiter_s => 0.1;

# motor range in command coordinates and in degrees
const my $motorRange_coords => 0x400;
const my $motorRange_deg    => 300;

=head1 CONSTRUCTOR

=head2 new( PIPE )

Creates a new object to talk to a Dynamixel motor. The file handle has to be opened and set-up
prior to constructing the object.

=cut
sub new
{
  my ($classname, $pipe) = @_;

  my $this = {};
  bless($this, $classname);

  return $this->_init($pipe);
}

sub _init
{
  my $this = shift;
  my $pipe = shift;

  $this->{pipe} = $pipe;
  return $this;
}

# Constructs a binary dynamixel packet with a given command
sub _makeInstructionPacket
{
  my ($motorID, $instruction, $parameters) = @_;
  my $body = pack( 'C3C' . scalar @$parameters,
                   $motorID, 2 + @$parameters, $instruction,
                   @$parameters );

  my $checksum = ( ~sum(unpack('C*', $body)) & 0xFF );
  return pack('CC', 0xFF, 0xFF) . $body . chr $checksum;
}

=head1 METHODS

=head2 pingMotor( motorID )

Sends a ping. Status reply is returned

=cut

sub pingMotor
{
  my $this      = shift;
  my ($motorID) = @_;

  my $pipe = $this->{pipe};
  print $pipe _makeInstructionPacket($motorID, $instructions{PING}, []);
  return _pullMotorReply($this->{pipe});
}

=head2 writeMotor( motorID, startingAddress, data )

Sends a command to the motor. Status reply is returned.

=cut

sub writeMotor
{
  my $this                     = shift;
  my ($motorID, $where, $what) = @_;

  my $pipe = $this->{pipe};
  print $pipe _makeInstructionPacket($motorID, $instructions{WRITE_DATA}, [$where, @$what]);
  return _pullMotorReply($this->{pipe});
}

=head2 readMotor( motorID, startingAddress, howManyBytes )

Reads data from the motor. Status reply is returned.

=cut

sub readMotor
{
  my $this                        = shift;
  my ($motorID, $where, $howmany) = @_;

  my $pipe = $this->{pipe};
  print $pipe _makeInstructionPacket($motorID, $instructions{READ_DATA}, [$where, $howmany]);
  return _pullMotorReply($this->{pipe});
}

=head2 writeMotor_queue( motorID, startingAddress, data )

Queues a particular command to the motor and returns the received reply. Does
not actually execute the command until triggered with triggerMotorQueue( )

=cut

sub writeMotor_queue
{
  my $this                     = shift;
  my ($motorID, $where, $what) = @_;

  my $pipe = $this->{pipe};
  print $pipe _makeInstructionPacket($motorID, $instructions{REG_WRITE}, [$where, @$what]);
  return _pullMotorReply($this->{pipe});
}

=head2 triggerMotorQueue( motorID )

Sends a trigger for the queued commands. Status reply is returned.

=cut

sub triggerMotorQueue
{
  my $this      = shift;
  my ($motorID) = @_;

  my $pipe = $this->{pipe};
  print $pipe _makeInstructionPacket($motorID, $instructions{ACTION}, []);
  return _pullMotorReply($this->{pipe});
}

=head2 resetMotor( motorID )

Sends a motor reset. Status reply is returned.

=cut

sub resetMotor
{
  my $this      = shift;
  my ($motorID) = @_;

  my $pipe = $this->{pipe};
  print $pipe _makeInstructionPacket($motorID, $instructions{RESET}, []);
  return _pullMotorReply($this->{pipe});
}

=head2 syncWriteMotor( motorID, startingAddress, data )

Sends a synced-write command to the motor. Status reply is returned.

=cut

sub syncWriteMotor
{
  my $this                       = shift;
  my ($motorID, $writes, $where) = @_;

  my @parms = map { ($_->{motorID}, @{$_->{what}}) } @$writes;
  my $lenchunk = scalar @{$writes->[0]{what}};
  @parms = ($where, $lenchunk, @parms);

  if( ($lenchunk + 1) * @$writes + 2 != @parms )
  {
    die "syncWriteMotor: size mismatch!";
  }

  my $pipe = $this->{pipe};
  print $pipe _makeInstructionPacket($BROADCAST_ID, $instructions{SYNC_WRITE}, \@parms);
  return _pullMotorReply($this->{pipe});
}

sub _pullMotorReply
{
  my $pipe = shift;

  # read data until there's a lull of $timeDelimiter_s seconds
  my $packet = '';
  select(undef, undef, undef, $timeDelimiter_s); # sleep for a bit to wait for data
  while(1)
  {
    my $rin = '';
    vec($rin,fileno($pipe),1) = 1;
    my ($nfound, $timeleft) = select($rin, undef, undef, $timeDelimiter_s);
    last if($nfound == 0);

    my $bytes;
    sysread($pipe, $bytes, $nfound);
    $packet .= $bytes;
  }

  return _parseStatusPacket($packet);


  # parses a given binary string as a dynamixel status packet
  sub _parseStatusPacket
  {
    my $str = shift;

    my ($key) = unpack('n', substr($str, 0, 2, '')) or return;

    return if($key != 0xFFFF);

    my ($motorID, $length, $error) = unpack('C3', substr($str, 0, 3, '')) or return;
    my $numParameters = $length - 2;
    return if($numParameters < 0);

    my @parameters = ();
    my $sumParameters = 0;
    if ($numParameters)
    {
      @parameters = unpack("C$numParameters", substr($str, 0, $numParameters, '')) or return;
      $sumParameters = sum(@parameters);
    }
    my $checksum = unpack('C1', substr($str, 0, 1, '')) // return;
    my $checksumShouldbe = ~($motorID + $length + $error + $sumParameters) & 0xFF;
    return if($checksum != $checksumShouldbe);

    return {from   => $motorID,
            error  => $error,
            params => \@parameters};
  }
}


=head2 moveMotorTo_deg( motorID, position_degrees )

Convenience function that uses the lower-level routines to move a motor to a
particular position

=cut

sub moveMotorTo_deg
{
  my $this                     = shift;
  my ($motorID, $position_deg) = @_;

  my $position = int( 0.5 + ($position_deg * $motorRange_coords/$motorRange_deg + 0x1ff) );
  $position    = 0                    if $position <  0;
  $position    = $motorRange_coords-1 if $position >= $motorRange_coords;
  return $this->writeMotor($motorID, $addresses{Goal_Position_L}, [unpack('C2', pack('v', $position))] );
}

1;


__END__


=head1 BUGS

An issue is the baud rate of the serial communication. The motors default to 1M
baud. This is unsupported by the stock POSIX module in perl5, so the serial port
must be configured externally, prior to using to this module.

=head1 REPOSITORY

L<https://github.com/dkogan/dynamixel>

=head1 AUTHOR

Dima Kogan, C<< <dkogan at cds.caltech.edu> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2011 Dima Kogan.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut
