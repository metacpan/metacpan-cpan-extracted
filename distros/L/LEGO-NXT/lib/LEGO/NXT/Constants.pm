# vim: sts=2 sw=2
package LEGO::NXT::Constants;

use strict;
use warnings;

use Exporter qw( import );
our @EXPORT;

=head1 NAME

LEGO::NXT::Constants - Low-level constants for the Direct Commands API.

=head1 SYNOPSIS

  use LEGO::NXT::Constants;

=head1 DESCRIPTION

This module exports a bunch of constants in to your namespace for you to
use with the various low-level methods in the L<LEGO::NXT> module.

=head1 CONSTANTS

All of the following constants are exported in to your namespace by
default.

=head2 RET and NORET

For each request of the NXT, you must specify whether you want the NXT to
send a return value.

 $NXT_RET
 $NXT_NORET

Use $NXT_RET only when you really need a return value as it does have some
overhead because it has do do a second request to retrieve response
data from NXT and then parses that data.

=cut

our $NXT_RET   = 0x00;
our $NXT_NORET = 0x80;

push @EXPORT, qw( $NXT_RET $NXT_NORET );

=head2 IO Port

  $NXT_SENSOR1
  $NXT_SENSOR2
  $NXT_SENSOR3
  $NXT_SENSOR4
  
  $NXT_MOTOR_A
  $NXT_MOTOR_B
  $NXT_MOTOR_C
  $NXT_MOTOR_ALL

=cut

our $NXT_SENSOR_1  = 0x00;
our $NXT_SENSOR_2  = 0x01;
our $NXT_SENSOR_3  = 0x02; 
our $NXT_SENSOR_4  = 0x03;

our $NXT_MOTOR_A   = 0x00;
our $NXT_MOTOR_B   = 0x01;
our $NXT_MOTOR_C   = 0x02;
our $NXT_MOTOR_ALL = 0xFF;

push @EXPORT, qw(
    $NXT_SENSOR_1 $NXT_SENSOR_2 $NXT_SENSOR_3 $NXT_SENSOR_4
    $NXT_MOTOR_A $NXT_MOTOR_B $NXT_MOTOR_C $NXT_MOTOR_ALL
);

=head2 Motor Control

Output mode:

  $NXT_MOTOR_ON
  $NXT_BRAKE
  $NXT_REGULATED

Output regulation modes:

  $NXT_REGULATION_MODE_IDLE
  $NXT_REGULATION_MODE_MOTOR_SPEED
  $NXT_REGULATION_MODE_MOTOR_SYNC

Output run states:

  $NXT_MOTOR_RUN_STATE_IDLE
  $NXT_MOTOR_RUN_STATE_RAMPUP
  $NXT_MOTOR_RUN_STATE_RUNNING
  $NXT_MOTOR_RUN_STATE_RAMPDOWN

=cut

our $NXT_MOTOR_ON  = 0x01;
our $NXT_BRAKE     = 0x02;
our $NXT_REGULATED = 0x04;

our $NXT_REGULATION_MODE_IDLE        = 0x00;
our $NXT_REGULATION_MODE_MOTOR_SPEED = 0x01;
our $NXT_REGULATION_MODE_MOTOR_SYNC  = 0x02;

our $NXT_MOTOR_RUN_STATE_IDLE        = 0x00;
our $NXT_MOTOR_RUN_STATE_RAMPUP      = 0x10;
our $NXT_MOTOR_RUN_STATE_RUNNING     = 0x20;
our $NXT_MOTOR_RUN_STATE_RAMPDOWN    = 0x40;

push @EXPORT, qw(
  $NXT_MOTOR_ON $NXT_BRAKE $NXT_REGULATED
  $NXT_REGULATION_MODE_IDLE $NXT_REGULATION_MODE_MOTOR_SPEED $NXT_REGULATION_MODE_MOTOR_SYNC
  $NXT_MOTOR_RUN_STATE_IDLE $NXT_MOTOR_RUN_STATE_RAMPUP $NXT_MOTOR_RUN_STATE_RUNNING $NXT_MOTOR_RUN_STATE_RAMPDOWN
);

=head2 Sensor Type

  $NXT_NO_SENSOR
  $NXT_SWITCH
  $NXT_TEMPERATURE
  $NXT_REFLECTION
  $NXT_ANGLE
  $NXT_LIGHT_ACTIVE
  $NXT_LIGHT_INACTIVE
  $NXT_SOUND_DB
  $NXT_SOUND_DBA
  $NXT_CUSTOM
  $NXT_LOW_SPEED
  $NXT_LOW_SPEED_9V
  $NXT_NO_OF_SENSOR_TYPES

=cut

our $NXT_NO_SENSOR           = 0x00;
our $NXT_SWITCH              = 0x01;
our $NXT_TEMPERATURE         = 0x02;
our $NXT_REFLECTION          = 0x03;
our $NXT_ANGLE               = 0x04;
our $NXT_LIGHT_ACTIVE        = 0x05;
our $NXT_LIGHT_INACTIVE      = 0x06;
our $NXT_SOUND_DB            = 0x07;
our $NXT_SOUND_DBA           = 0x08;
our $NXT_CUSTOM              = 0x09;
our $NXT_LOW_SPEED           = 0x0A;
our $NXT_LOW_SPEED_9V        = 0x0B;
our $NXT_NO_OF_SENSOR_TYPES  = 0x0C;

push @EXPORT, qw(
  $NXT_NO_SENSOR $NXT_SWITCH $NXT_TEMPERATURE $NXT_REFLECTION $NXT_ANGLE
  $NXT_LIGHT_ACTIVE $NXT_LIGHT_INACTIVE $NXT_SOUND_DB $NXT_SOUND_DBA
  $NXT_CUSTOM $NXT_LOW_SPEED $NXT_LOW_SPEED_9V $NXT_NO_OF_SENSOR_TYPES
);

=head2 Sensor Mode

  $NXT_RAW_MODE
  $NXT_BOOLEAN_MODE
  $NXT_TRANSITION_CNT_MODE
  
  $NXT_PERIOD_COUNTER_MODE
  $NXT_PCT_FULL_SCALE_MODE
  
  $NXT_CELSIUS_MODE
  $NXT_FAHRENHEIT_MODE
  
  $NXT_ANGLE_STEPS_MODE
  $NXT_SLOPE_MASK
  $NXT_MODE_MASK

=cut

our $NXT_RAW_MODE            = 0x00;
our $NXT_BOOLEAN_MODE        = 0x20;
our $NXT_TRANSITION_CNT_MODE = 0x40;

our $NXT_PERIOD_COUNTER_MODE = 0x60;
our $NXT_PCT_FULL_SCALE_MODE = 0x80;

our $NXT_CELSIUS_MODE        = 0xA0;
our $NXT_FAHRENHEIT_MODE     = 0xC0;

our $NXT_ANGLE_STEPS_MODE    = 0xE0;
our $NXT_SLOPE_MASK          = 0x1F;
our $NXT_MODE_MASK           = 0xE0;

push @EXPORT, qw(
  $NXT_RAW_MODE $NXT_BOOLEAN_MODE $NXT_TRANSITION_CNT_MODE
  $NXT_PERIOD_COUNTER_MODE $NXT_PCT_FULL_SCALE_MODE
  $NXT_CELSIUS_MODE $NXT_FAHRENHEIT_MODE
  $NXT_ANGLE_STEPS_MODE $NXT_SLOPE_MASK $NXT_MODE_MASK
);

=head2 Op Codes

Generally you will not need to use these constants
since L<LEGO::NXT> provides easy to use wrappers around
all of these actions.

  $NXT_START_PROGRAM
  $NXT_STOP_PROGRAM
  $NXT_PLAY_SOUND_FILE
  $NXT_PLAY_TONE
  $NXT_SET_OUTPUT_STATE
  $NXT_SET_INPUT_MODE
  $NXT_GET_OUTPUT_STATE
  $NXT_GET_INPUT_VALUES
  $NXT_RESET_SCALED_INPUT_VALUE
  $NXT_MESSAGE_WRITE
  $NXT_RESET_MOTOR_POSITION
  $NXT_GET_BATTERY_LEVEL
  $NXT_STOP_SOUND_PLAYBACK
  $NXT_KEEP_ALIVE
  $NXT_LSGET_STATUS
  $NXT_LSWRITE
  $NXT_LSREAD
  $NXT_GET_CURRENT_PROGRAM_NAME
  $NXT_MESSAGE_READ

=cut

our $NXT_START_PROGRAM            = 0x00;
our $NXT_STOP_PROGRAM             = 0x01;
our $NXT_PLAY_SOUND_FILE          = 0x02;
our $NXT_PLAY_TONE                = 0x03;
our $NXT_SET_OUTPUT_STATE         = 0x04;
our $NXT_SET_INPUT_MODE           = 0x05;
our $NXT_GET_OUTPUT_STATE         = 0x06;
our $NXT_GET_INPUT_VALUES         = 0x07;
our $NXT_RESET_SCALED_INPUT_VALUE = 0x08;
our $NXT_MESSAGE_WRITE            = 0x09;
our $NXT_RESET_MOTOR_POSITION     = 0x0A;
our $NXT_GET_BATTERY_LEVEL        = 0x0B;
our $NXT_STOP_SOUND_PLAYBACK      = 0x0C;
our $NXT_KEEP_ALIVE               = 0x0D;
our $NXT_LSGET_STATUS             = 0x0E;
our $NXT_LSWRITE                  = 0x0F;
our $NXT_LSREAD                   = 0x10;
our $NXT_GET_CURRENT_PROGRAM_NAME = 0x11;
our $NXT_MESSAGE_READ             = 0x13;

push @EXPORT, qw(
  $NXT_START_PROGRAM $NXT_STOP_PROGRAM
  $NXT_PLAY_SOUND_FILE $NXT_PLAY_TONE
  $NXT_SET_OUTPUT_STATE $NXT_SET_INPUT_MODE $NXT_GET_OUTPUT_STATE
  $NXT_GET_INPUT_VALUES $NXT_RESET_SCALED_INPUT_VALUE $NXT_MESSAGE_WRITE
  $NXT_RESET_MOTOR_POSITION $NXT_GET_BATTERY_LEVEL $NXT_STOP_SOUND_PLAYBACK
  $NXT_KEEP_ALIVE $NXT_LSGET_STATUS $NXT_LSWRITE $NXT_LSREAD
  $NXT_GET_CURRENT_PROGRAM_NAME $NXT_MESSAGE_READ
);

1;

__END__
=head1 AUTHOR

Michael W. Collins <michaelcollins@ivorycity.com>

=head1 CONTRIBUTORS

Aran Deltac <bluefeet@cpan.org>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

