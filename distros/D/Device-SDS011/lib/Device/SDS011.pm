package Device::SDS011;

# Last updated November 10, 2019
#
# Author:       Irakliy Sunguryan ( www.sochi-travel.info )
# Date Created: September 25, 2019

##############################################################################
# NOTE 1: All functions will save/update the Device ID,
#         since all commands return it anyway.
##############################################################################

use v5.10; # for "Defined OR" operator
use strict;
use warnings;

use vars qw($VERSION);
$VERSION = '0.01';

use Device::SerialPort;
use List::Util 'sum';

# =======================================================

use constant {
    CMD_DATA => "\xC0",
    CMD_REPLY => "\xC5",
    MODE_SLEEP => 0,
    MODE_WORK  => 1,
    #---
    REQ_TEMPLATE => [
        0xAA,0xB4,0x00,      # header, command, instruction
        0x00,0x00,0x00,0x00, # data
        0x00,0x00,0x00,0x00,
        0x00,0x00,0x00,0x00,
        0xFF,0xFF,0x00,0xAB, # device id, checksum, tail
    ],
    #---
    CMD_BYTE_REPORTING_MODE => 2,
    CMD_BYTE_QUERY_DATA => 4,
    CMD_BYTE_DEVICE_ID => 5,
    CMD_BYTE_SLEEP_WORK => 6,
    CMD_BYTE_WORKING_PERIOD => 8,
    CMD_BYTE_FIRMWARE => 7,
    #---
    MAX_MSGS_READ => 10,
        # when sensor is in "continuous" working mode (default),
        # several data reading messages can appear before actual response to a command.
};

sub new {
    my $class = shift;
    my $serial_port = shift;

    my $self = {
        _device_id       => undef,
        _reporting_mode  => undef,
        _operation_mode  => undef,
        _working_period  => undef,
        _firmware_verion => undef,
    };

    $self->{port} = Device::SerialPort->new($serial_port);
    $self->{port}->read_const_time(10_000); # 10 seconds timeout

    # The UART communication protocol：
    #  bit rate：   9600
    #  data bit：   8
    #  parity bit： NO
    #  stop bit：   1

    $self->{port}->baudrate(9600);
    $self->{port}->databits(8);
    $self->{port}->parity('none');
    $self->{port}->stopbits(1);

    $self->{port}->write_settings || undef $self->{port};

    bless $self, $class;
    return $self;
}

sub _checksum {
    my @data_bytes = @_;
    return sum(@data_bytes) % 256;
}

sub _read_serial {
    my $self = shift;
    my $cmdChar = shift; # C0 - sensor data; C5 - command reply
    my $msg = '';
    my $readMessages = 0;
    my $failures = 0; # a way to stop the infinite loop in case read() will start to time out
    $self->{port}->lookclear;
    while(1) {
        my $byte = $self->{port}->read(1);
        if ( defined $byte and length $byte ) {
            $msg .= $byte;
            $msg = substr($msg,-10);
            if (length($msg) == 10
                && substr($msg,0,1) eq "\xAA"
                && substr($msg,-1)  eq "\xAB")
            {
                $readMessages++;
                last if $cmdChar eq CMD_DATA;
                last if $readMessages >= MAX_MSGS_READ; # give up after this many messages
                last if $cmdChar && substr($msg,1,1) eq $cmdChar;
            }
        } else {
            $failures++;
            last if $failures == 5;
        }
    }
    $msg = undef  if $cmdChar && substr($msg,1,1) ne $cmdChar;
    return $msg;
}

sub _write_serial {
    my $self = shift;
    my $bytes = shift;
    my $str = pack('C*', @$bytes);
    $self->{port}->lookclear;
    my $count_out = $self->{port}->write($str);
    # $self->{port}->write_drain;
        warn "write failed\n"      unless  $count_out;
        warn "write incomplete\n"  if  $count_out != length($str);
    return $count_out;
}

# ACCEPTS: (1) [required] array ref of 15 data bytes (intergers)
#          (2) [optional] expected response type: \xC0 (sensor data), or
#                         \xC5 (command reply) <- default
# RETURNS: a response (string of bytes)
sub _write_msg {
    my $self = shift;
    my ($data, $response_type) = @_;
    my @out = @{REQ_TEMPLATE()};
    @out[2..16] = @$data;
    $out[17] = _checksum(@out[2..16]);
    $self->_write_serial(\@out);
    return $self->_read_serial(($response_type // CMD_REPLY));
}

sub _update_device_id {
    my $self = shift;
    my $msg = shift; # full response message
    if (!$self->{_device_id}) {
        my @deviceId = map { ord } split //, substr($msg,6,2);
        $self->{_device_id} = \@deviceId;
    }
}

# ---------------------------------------------------------------------------

##############################################################################
# RETURNS: Array ref of calculated sensor values: [PM25, PM10]
##############################################################################
sub live_data {
    my $self = shift;
    my $response = $self->_read_serial(CMD_DATA);
    my @values = map { ord } split //, $response;
    return [
        (($values[3] * 256) + $values[2]) / 10,
        (($values[5] * 256) + $values[4]) / 10,
    ];
}

sub query_data {
    my $self = shift;
    my @out = @{REQ_TEMPLATE()}[2..16];
    my $response = $self->_write_msg([CMD_BYTE_QUERY_DATA, @{REQ_TEMPLATE()}[3..16]], CMD_DATA);
    if ($response) {
        $self->_update_device_id($response);
        my @values = map { ord } split //, $response;
        return [
            (($values[3] * 256) + $values[2]) / 10,
            (($values[5] * 256) + $values[4]) / 10,
        ];
    } else {
        return undef;
    }
}

sub _change_mode {
    my $self = shift;
    my ($mode_type, $mode_value) = @_;
    my @out = @{REQ_TEMPLATE()}[2..16];
    $out[0] = $mode_type;
        # CMD_BYTE_REPORTING_MODE / CMD_BYTE_SLEEP_WORK / CMD_BYTE_WORKING_PERIOD
    ($out[1], $out[2]) = defined($mode_value) ? (1,$mode_value) : (0,0);
    my $response = $self->_write_msg(\@out);
    $self->_update_device_id($response) if $response;
    return ($response ? ord(substr($response,4,1)) : undef);
}

##############################################################################
# ACCEPTS: OPTIONAL Mode to set: 0=Report active mode, 1=Report query mode
# RETURNS: Current reporting mode
##############################################################################
sub reporting_mode {
    my $self = shift;
    my $mode = shift;
    return $self->_change_mode(CMD_BYTE_REPORTING_MODE, $mode);
}

##############################################################################
# ACCEPTS: OPTIONAL Mode to set: 0=Sleep, 1=Work
# RETURNS: Current mode
##############################################################################
sub sensor_mode {
    my $self = shift;
    my $mode = shift;
    return $self->_change_mode(CMD_BYTE_SLEEP_WORK, $mode);
}

##############################################################################
# ACCEPTS: OPTIONAL Mode/Period in minutes to set:
#          0=continuous mode, 1-30 minutes (work 30 seconds and sleep n*60-30 seconds)
# RETURNS: Current mode/Period in minutes
##############################################################################
sub working_period {
    my $self = shift;
    my $minutes = shift;
    return $self->_change_mode(CMD_BYTE_WORKING_PERIOD, $minutes);
}

##############################################################################
# RETURNS: Array ref [year, month, day] of the firmware version
# NOTE: This will only read the value from the device if it wasn't read before
##############################################################################
sub firmware {
    my $self = shift;
    if (!$self->{_firmware_verion}) {
        my $response = $self->_write_msg([CMD_BYTE_FIRMWARE, @{REQ_TEMPLATE()}[3..16]]);
        if (defined $response) {
            my @version = map { ord } split //, substr($response,3,3);
                # Firmware version byte 1: year
                # Firmware version byte 2: month
                # Firmware version byte 3: day
            $self->{_firmware_verion} = \@version;
            $self->_update_device_id($response);
        }
    }
    # TODO: question: if it was successfully read on previous call
    # and the $self->{_firmware_verion} is set, should I undef it in case this read fails?
    return $self->{_firmware_verion};
}

sub device_id {
    my $self = shift;
    my @new_id = @_; # 2 bytes (integers)
    if (@new_id) {
        my @out = @{REQ_TEMPLATE()}[2..16];
        $out[0] = CMD_BYTE_DEVICE_ID;
        ($out[11], $out[12]) = @new_id;
        my $response = $self->_write_msg(\@out);
        $self->_update_device_id($response);
    }
    else {
        # (ab)use reporing mode function to read and update the ID
        $self->reporting_mode if (!$self->{_device_id});
    }
    return $self->{_device_id};
}

sub done {
    my $self = shift;
    undef $self->{port};
}

sub DESTROY {
    my $self = shift;
    undef $self->{port} if $self->{port};
}

1;

__END__

=encoding utf8

=head1 NAME

Device::SDS011 - Module to work with SDS011 particulate matter laser sensor

=head1 SYNOPSIS

    use Device::SDS011;

    my $sensor = Device::SDS011->new('/dev/ttyUSB0');

    $sensor->sensor_mode(1);    # wake up (if in sleeping mode)
    sleep 5;
    $sensor->reporting_mode(1); # 1 = Report query mode
    $sensor->working_period(0); # 0 = Continuous mode

    while (1) {
        my ($pm25, $pm10);
        for (1..3) {
            my ($pm25_tmp,$pm10_tmp) = @{$sensor->query_data};
            $pm25 += $pm25_tmp;
            $pm10 += $pm10_tmp;
            sleep 3;
        }
        printf "PM25:%.2f, PM10:%.2f\n", $pm25/3, $pm10/3;
        $sensor->sensor_mode(0); # enter sleep mode
        sleep 60 * 15;
    }

=head1 DESCRIPTION

Module to receive data from, and control SDS011 particulate matter sensor.

This module uses C<Device::SerialPort> for communicating with sensor.
Laser Dust Sensor Control Protocol v1.3 is implemented.

=head2 Data retrieved

I<SDS011 uses the principle of laser scattering in the
air, can be obtained from 0.3 to 10 microns suspended
particulate matter concentration.>

This module allows retrieving PM 2.5 mass in mg/m3 and PM 10 mass in mg/m3
sensor readings.

=head1 CONSTRUCTOR

=head2 Device::SDS011-E<gt>new( $usb_device )

Creates and returns a new C<Device::SDS011> object, open specified port,
and configure it according to the protocol:
I<9600 bps with 8 data bit, no parity, one stop bit>.

The C<$usb_device> option is passed on to C<Device::SerialPort> (please see documentation for this module).

    my $sensor = Device::SDS011->new('/dev/ttyUSB0');


=head1 METHODS

=head2 $sensor-E<gt>live_data

Returns current PM readings as an arrayref C<[PM 2.5, PM 10]>.

Ex.: C<[8.77,17.73]>

By default the sensor device works in Active reporting mode with
Continuous working period, which means it reports PM readings
every 1 second continuously. This method can be used to read the values.


=head2 $sensor-E<gt>query_data

Requests sensor data.
Returns current PM readings as an arrayref C<[PM 2.5, PM 10]>.

Also see the C<reporting_mode()> method.

=head2 $sensor-E<gt>reporting_mode

=for comment
This comment is here to shut the podchecker up.

=head2 $sensor-E<gt>reporting_mode( $mode )

Sets report mode. Valid values: C<0> (active) and C<1> (query).
When parameter value is not specified it returns current reporting mode (C<0> or C<1>).

I<* Report B<active mode> Sensor automatically reports a measurement data in a work period.>

I<* Report B<query mode> Sensor received query data command to report a measurement data.>


=head2 $sensor-E<gt>sensor_mode

=for comment
This comment is here to shut the podchecker up.

=head2 $sensor-E<gt>sensor_mode( $mode )

Sets sensor mode. Valid values: C<0> (sleep) and C<1> (work).
When parameter value is not specified it returns current sensor mode (C<0> or C<1>).

I<"Service life is the key parameter of laser dust sensor.
The laser diode in this sensor has high quality and its service life
is up to 8000 hours. If you don't need real-time data
(such as filter, air quality monitoring, etc.), you can use
the discontinuous working method to prolong the service life.">


=head2 $sensor-E<gt>working_period

=for comment
This comment is here to shut the podchecker up.

=head2 $sensor-E<gt>working_period( $mode )

Sets working period. Valid values: C<0> (continuous),
and C<1-30> minute(s) -- work 30 seconds, and sleep n*60-30 seconds.
When parameter value is not specified it returns current working period.


=head2 $sensor-E<gt>firmware

Returns sensor's firmware version: a string of format
C<YY-MM-DD> (year, month, date).

=head2 $sensor-E<gt>device_id

=for comment
This comment is here to shut the podchecker up.

=head2 $sensor-E<gt>device_id( $id_byte_1, $id_byte_2 )

    say join ' ', map { sprintf '%02x', $_ } @{$sensor->device_id};
    my $newID = $sensor->device_id( 0xD0, 0xEA ); # returns [0xD0,0xEA]

Sets Device ID. Returns new device ID -- arrayref to two ID bytes.
When no ID specified returns current device ID.

I<NOTE: All methods of this module will save/update (internally) the Device ID,
since all commands return it.  If this command is called first,
it will (ab)use reporting_mode() method to get the ID.>

=head2 $sensor-E<gt>done

Destroys the C<Device::SerialPort> object. Re-connect is not possible.



=head1 AUTHOR

Irakliy Sunguryan



=head1 DEVELOPMENT & ISSUES

Repository: L<https://github.com/OpossumPetya/pi-air-monitor>.

Please report any bugs at L<GitHub|https://github.com/OpossumPetya/pi-air-monitor/issues>, or L<RT|http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Device-SDS011>.



=head1 LICENSE AND COPYRIGHT

Copyright 2019 Irakliy Sunguryan

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

=cut