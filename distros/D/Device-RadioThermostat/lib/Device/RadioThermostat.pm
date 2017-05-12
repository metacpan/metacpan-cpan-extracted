package Device::RadioThermostat;

use strict;
use warnings;

use 5.008_001;
our $VERSION = '0.04';

use Carp;
use JSON;
use Socket 'inet_aton';
use Time::HiRes 'usleep';
use LWP::UserAgent;
use IO::Socket::INET;

sub new {
    my ( $class, %args ) = @_;
    my $self = {
        address => $args{address},
        ua      => LWP::UserAgent->new() };
    croak 'Must pass address to new.' unless $self->{address};

    return bless $self, $class;
}

sub find_all {
    my ( $class, $low, $high ) = @_;
    croak 'Must pass two addresses to find_all.' unless $low && $high;

    my $lowint  = unpack( "N", inet_aton($low) );
    my $highint = unpack( "N", inet_aton($high) );

    my $s = IO::Socket::INET->new(Proto => 'udp') || croak @$;

    for ( 0 .. 4 ) { # retry 5 times
        for ( my $addr = $lowint; $addr <= $highint; $addr++ ) {
            my $hissockaddr = sockaddr_in( 1900, pack( "N", $addr ) );
            $s->send(
                "TYPE: WM-DISCOVER\r\n"
                    . "VERSION: 1.0\r\n\r\n"
                    . "services: com.marvell.wm.system*\r\n\r\n",
                0, $hissockaddr
            );
            usleep 10000;
        }

        my $rin = '';
        vec($rin, $s->fileno, 1) = 1;
        my ($rout, %result);
        while (select($rout = $rin, undef, undef, 1)) {
            my $response = '';
            my $hispaddr = $s->recv( $response, 1024, 0 );
            my ( $port, $hisiaddr ) = sockaddr_in($hispaddr);
            my ($hisaddr) = $response =~ m!location:\s*http://([0-9.]+)/sys!i;
            next unless $hisaddr;

            my $tstat = Device::RadioThermostat->new(
                address => 'http://' . $hisaddr );
            my $uuid = $tstat->get_uuid();
            next unless $uuid;

            $result{$uuid} = $tstat;
        }

        return \%result if %result;
    }

    return;
}

sub tstat {
    my $self = shift;
    return $self->_ua_get('/tstat');
}

sub sys {
    my $self = shift;
    return $self->_ua_get('/sys');
}

sub model {
    my $self = shift;
    return $self->_ua_get('/tstat/model');
}

sub get_uuid {
    my $self = shift;
    return $self->sys()->{uuid};
}

sub set_mode {
    my ( $self, $mode ) = @_;
    return $self->_ua_post( '/tstat', { tmode => int($mode) } );
}

sub get_target {
    my ($self) = @_;
    my $mode = $self->tstat->{tmode};
    return if $mode == 0;
    my $targets = $self->get_targets();
    if ( $mode == 1 ) {
        return $targets->{t_heat};
    }
    elsif ( $mode == 2 ) {
        return $targets->{t_cool};
    }
    else {
        return [ $targets->{t_cool}, $targets->{t_heat} ];
    }
}

sub get_targets {
    my ($self) = @_;
    return $self->_ua_get('/tstat/ttemp');
}

sub get_humidity {
    my ($self) = @_;
    return $self->_ua_get('/tstat/humidity');
}

sub temp_heat {
    my ( $self, $temp ) = @_;
    return $self->_ua_post( '/tstat', { t_heat => 0 + $temp } );
}

sub temp_cool {
    my ( $self, $temp ) = @_;
    return $self->_ua_post( '/tstat', { t_cool => 0 + $temp } );
}

sub remote_temp {
    my ($self) = @_;
    return $self->_ua_get('/tstat/remote_temp');
}

sub disable_remote_temp {
    my ($self) = @_;
    return $self->_ua_post( '/tstat/remote_temp', { rem_mode => 0 } );
}

sub set_remote_temp {
    my ( $self, $temp ) = @_;
    return $self->_ua_post( '/tstat/remote_temp', { rem_temp => 0 + sprintf("%d", $temp) } );
}

sub lock {
    my ($self, $mode) = @_;
    if ($mode) {
        return unless $self->_ua_post( '/tstat/lock', { lock_mode => int($mode) } );
    }
    return $self->_ua_get('/tstat/lock');
}

sub user_message {
    my ( $self, $line, $message ) = @_;
    return $self->_ua_post( '/tstat/uma', { line => int($line), message => $message } );
}

sub price_message {
    my ( $self, $line, $message ) = @_;
    return $self->_ua_post( '/tstat/pma', { line => int($line), message => $message } );
}

sub clear_user_message {
    my ($self) = @_;
    return $self->_ua_post( '/tstat/uma', { mode => 0 } );
}

sub clear_price_message {
    my ($self) = @_;
    return $self->_ua_post( '/tstat/pma', { mode => 0 } );
}

sub clear_message {
    my ($self) = @_;
    return $self->clear_price_message();
}

sub datalog {
    my ($self) = @_;
    return $self->_ua_get('/tstat/datalog');
}

sub _ua_post {
    my ( $self, $path, $data ) = @_;
    my $response
        = $self->{ua}->post( $self->{address} . $path, content => encode_json $data );
    if ( $response->is_success ) {
        my $result = decode_json $response->decoded_content();

        # return $result;
        return exists( $result->{success} ) ? 1 : 0;
    }
    else {
        my ($code, $err) = ($response->code, $response->message);
        carp $code ? "$code response: $err" : "Connection error: $err";
        return;
    }
}

sub _ua_get {
    my ( $self, $path ) = @_;
    my $response = $self->{ua}->get( $self->{address} . $path );
    if ( $response->is_success ) {
        return decode_json $response->decoded_content();
    }
    else {
        my ($code, $err) = ($response->code, $response->message);
        carp $code ? "$code response: $err" : "Connection error: $err";
        return;
    }
}

1;
__END__

=head1 NAME

Device::RadioThermostat - Access Radio Thermostat Co of America (3M-Filtrete) WiFi thermostats

=head1 SYNOPSIS

  use Device::RadioThermostat;
  my $thermostat = Device::RadioThermostat->new( address => "http://$ip");
  $thermostat->temp_cool(65);
  say "It is currently " . $thermostat->tstat()->{temp} "F inside.";

=head1 DESCRIPTION

Device::RadioThermostat is a perl module for accessing the API of thermostats
manufactured by Radio Thermostat Corporation of America.  3M-Filtrete themostats
with WiFi are OEM versions manufactured by RTCOA.

=head1 METHODS

For additional information on the arguments and values returned see the
L<RTCOA API documentation (pdf)|http://www.radiothermostat.com/documents/RTCOAWiFIAPIV1_3.pdf>.

=head2 new( address=> 'http://192.168.1.1')

Constructor takes named parameters.  Currently only C<address> which should be
the HTTP URL for the thermostat.

=head2 find_all(address1, address2)

This finds all the thermostats in the address range and returns a reference to a hash
which contains Device::RadioThermostat objects indexed by the device uuid. For example,
it might return a structure as follows:

    Device::RadioThermostat->find_all("192.168.1.1", "192.168.1.254")

returns

    {
    "5cdad4123456" => Device::RadioThermostat(address => 'http://192.168.1.76'),
    "5cdad4654321" => Device::RadioThermostat(address => 'http://192.168.1.183')
    }

=head2 tstat

Retrieve a hash of lots of info on the current thermostat state.  Possible keys
include: C<temp>, C<tmode>, C<fmode>, C<override>, C<hold>, C<t_heat>,
C<t_cool>, C<it_heat>, C<It_cool>, C<a_heat>, C<a_cool>, C<a_mode>,
C<t_type_post>, C<t_state>.  For a description of their values see the
L<RTCOA API documentation (pdf)|http://www.radiothermostat.com/documents/RTCOAWiFIAPIV1_3.pdf>.

=head2 sys

Retrieve a hash of lots of info on the current thermostat itself.  Possible keys
include: C<uuid>, C<api_version>, C<fw_version>, C<wlan_fw_version>.
For a description of their values see the
L<RTCOA API documentation (pdf)|http://www.radiothermostat.com/documents/RTCOAWiFIAPIV1_3.pdf>.

=head2 model

Retrieve a hash with information about the current thermostat model.
Currently hash only has key C<model>.

=head2 set_mode($mode)

Takes a single integer argument for your desired mode. Values are 0 for off, 1 for
heating, 2 for cooling, and 3 for auto.

=head2 get_target

Returns undef if current mode is off.  Returns heat or cooling set point based
on the current mode.  If current mode is auto returns a reference to a two
element array containing the cooling and heating set points.

=head2 get_targets

Returns a reference to a hash of the set points.  Keys are C<t_cool> and C<t_heat>.

=head2 get_humidity

Returns a reference to a hash containing current relative humidity 
(only supported by CT-80 Thermostats). Key is C<humidity>.

=head2 temp_heat($temp)

Set a temporary heating set point, takes one argument the desired target.  Will
also set current mode to heating.

=head2 temp_cool($temp)

Set a temporary cooling set point, takes one argument the desired target.  Will
also set current mode to cooling.

=head2 remote_temp

Returns a reference to a hash containing at least C<rem_mode> but possibly also
C<rem_temp>.  When C<rem_mode> is 1, the temperature passed to C<set_remote_temp>
is used instead of the thermostats internal temp sensor for thermostat operation.

This can be used to have the thermostat act as if it was installed in a better
location by feeding the temp from a sensor at that location to the thermostat
periodically.

=head2 set_remote_temp($temp)

Takes a single value to set the current remote temp.

=head2 disable_remote_temp

Disables remote_temp mode and reverts to using the thermostats internal temp
sensor.

=head2 lock

=head2 lock($mode)

With mode specified, sets mode and returns false on failure.  With successful
mode change or no mode specified, returns the current mode.  Mode is an integer,
0 - disabled, 1 - partial lock, 2 - full lock, 3 - utility lock.

=head2 user_message($line, $message)

Display a message on one of the two lines of alphanumeric display at the bottom
of the thermostat.  Valid values for line are 0 and 1. 
This is only supported by the CT-80 model thermostats. CT-80 Thermostat supports
2 rows of alphanumeric strings of 26 characters in length.

=head2 price_message($line, $message)

Display a message in the price message area on the thermostat.  Messages can be
numeric plus decimal only.  Valid values for line are 0 - 3.  Multiple messages
for different lines are rotated through.  I believe line number used will cause
an indicator for units to display based on the number used but it's not
mentioned in the API docs and I'm not home currently.

CT-80 model thermostats support displaying 2 alphanumeric strings of 6 characters
in length in the price message area.

=head2 clear_message

Clears the C<price_message> area.

=head2 clear_price_message

Clears the C<price_message> area.

=head2 clear_user_message

Clears the C<user_message> area.

=head2 datalog

Returns individual run times for heating and cooling yesterday and today.  This
method isn't documented in the current API so it may go away in the future but
does still work with the latest firmware. Sample data:

    $data = {
              'today' => {
                         'cool_runtime' => { 'minute' => 29, 'hour' => 2 },
                         'heat_runtime' => { 'minute' => 0,  'hour' => 0 }
                       },
              'yesterday' => {
                         'heat_runtime' => { 'minute' => 0,  'hour' => 0 },
                         'cool_runtime' => { 'minute' => 14, 'hour' => 0 }
                       }
            };

=head2 get_uuid

Returns the unique ID of the thermostat which is the MAC address. This helps
distinguish thermostats when there are many on the same network.

=head1 AUTHOR

Mike Greb E<lt>michael@thegrebs.comE<gt>

=head1 COPYRIGHT

Copyright 2013- Mike Greb

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
