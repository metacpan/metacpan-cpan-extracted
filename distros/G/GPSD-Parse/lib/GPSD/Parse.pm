package GPSD::Parse;

use strict;
use warnings;

use Carp qw(croak);
use IO::Socket::INET;

BEGIN {

    # look for JSON::XS, and if not available, fall
    # back to JSON::PP to avoid requiring non-core modules

    my $json_ok = eval {
        require JSON::XS;
        JSON::XS->import;
        1;
    };
    if (! $json_ok){
        require JSON::PP;
        JSON::PP->import;
    }
}

our $VERSION = '0.01';

sub new {
    my ($class, %args) = @_;
    my $self = bless {}, $class;
    $self->_port($args{port});
    $self->_host($args{host});
    $self->_socket;
    return $self;
}
sub on {
    $_[0]->_socket()->send('?WATCH={"enable": true}' . "\n");
}
sub off {
    $_[0]->_socket()->send('?WATCH={"enable": false}' . "\n");
}
sub poll {
    my ($self, %args) = @_;
  
    my $gps_json_data;

    if ($args{fname}){
        my $fname = $args{fname};

        open my $fh, '<', $fname or croak "can't open file '$fname': $!";

        {
            local $/;
            $gps_json_data = <$fh>;
            close $fh or croak "can't close file '$fname': $!";
        }
    }
    else {
        $self->_socket->send("?POLL;\n");
        local $/ = "\r\n";
        while (my $line = $self->_socket->getline){
            chomp $line;
            my $data = decode_json $line;
            if ($data->{class} eq 'POLL'){
                $gps_json_data = $line;
                last;
            }
        }
    }

    die "no JSON data returned from the GPS" if ! defined $gps_json_data;

    my $gps_perl_data = decode_json $gps_json_data;

    if (! defined $gps_perl_data->{tpv}[0]){
        warn "\n\nincomplete dataset returned from GPS; Did you call the " . 
             "'on()' method against the main object?\n\n";
    }

    $self->_parse($gps_perl_data);

    return $gps_json_data if defined $args{return} && $args{return} eq 'json';
    return $gps_perl_data;
}
sub tpv {
    my ($self, $stat) = @_;

    if (defined $stat){
        return undef if ! defined $self->{tpv}{$stat};
        return $self->{tpv}{$stat};
    }
    return $self->{tpv};
}
sub sky {
    return shift->{sky};
}
sub time {
    return shift->{time};
}
sub device {
    return shift->{device};
}
sub satellites {
    my ($self, $sat_num, $stat) = @_;

    if (defined $sat_num){
        return undef if ! defined $self->{satellites}{$sat_num};
    }

    if (defined $sat_num && defined $stat){
        return undef if ! defined $self->{satellites}{$sat_num}{$stat};
        return $self->{satellites}{$sat_num}{$stat};
    }
    return $self->{satellites};
}
sub _host {
    my ($self, $host) = @_;
    $self->{host} = $host if defined $host;
    $self->{host} = '127.0.0.1' if ! defined $self->{host};
    return $self->{host};
}
sub _port {
    my ($self, $port) = @_;
    $self->{port} = $port if defined $port;
    $self->{port} = 2947 if ! defined $self->{port};
    return $self->{port};
}
sub _parse {
    my ($self, $data) = @_;

    $self->{tpv}  = $data->{tpv}[0];

    $self->{time} = $self->{tpv}{time};
    $self->{device} = $self->{tpv}{device};

    $self->{sky} = $data->{sky}[0];

    my %sats;

    for my $sat (@{ $self->{sky}{satellites} }){
        my $prn = $sat->{PRN};
        delete $sat->{PRN};
        $sat->{used} = $sat->{used} ? 1 : 0;
        $sats{$prn} = $sat;
    }
    $self->{satellites} = \%sats;
}
sub _socket {
    my ($self) = @_;

    if (! defined $self->{socket}){
        $self->{"socket"}=IO::Socket::INET->new(
                        PeerAddr => $self->_host,
                        PeerPort => $self->_port,
        );
    }

    my ($h, $p) = ($self->_host, $self->_port);

    die "can't connect to gpsd://$h:$p" if ! defined $self->{socket};
  
    return $self->{'socket'};
}
sub _vim {} # fold placeholder

1;

=head1 NAME

GPSD::Parse - Parse, extract use the JSON output from GPS units

=for html
<a href="http://travis-ci.org/stevieb9/gpsd-parse"><img src="https://secure.travis-ci.org/stevieb9/gpsd-parse.png"/>
<a href='https://coveralls.io/github/stevieb9/gpsd-parse?branch=master'><img src='https://coveralls.io/repos/stevieb9/gpsd-parse/badge.svg?branch=master&service=github' alt='Coverage Status' /></a>

=head1 SYNOPSIS

    use GPSD::Parse;

    my $gps = GPSD::Parse->new;

    # start the data flow, and poll for data

    $gps->on;
    $gps->poll;

    # get all TPV data in an href

    my $tpv_href = $gps->tpv;

    # get individual TPV stats

    print $gps->tpv('lat');
    print $gps->tpv('lon');

    # timestamp of the most recent poll

    print $gps->time;

    # get all satellites in an href of hrefs

    my $sats = $gps->satellites;

    # get an individual piece of info from a single sattelite

    print $gps->satellites(16, 'ss');

    # check which serial device the GPS is connected to

    print $gps->device;

    # stop capturing data

    $gps->off;

=head1 DESCRIPTION

Simple, lightweight distribution that polls C<gpsd> for data received from a
UART (serial) connected GPS receiver over a TCP connection.

The data is fetched in JSON, and returned as Perl data.

=head1 NOTES

=head2 Requirements

A version of L<gpsd|http://catb.org/gpsd/gpsd.html> that returns results in
JSON format is required to have been previously installed. It should be started
at system startup, with the following flags with system-specific serial port.
See the above link for information on changing the listen IP and port.

    sudo gpsd -n /dev/ttyS0 -F /var/log/gpsd.sock

=head2 Available Data

Each of the methods that return data have a table in their respective
documentation within the L</METHODS> section. Specifically, look at the
C<tpv()>, C<sattelites()> and the more broad C<sky()> method sections to
understand what available data attributes you can extract.

=head1 METHODS

=head2 new(%args)

Instantiates and returns a new L<GPSD::Parse> object instance.

Parameters:

    host => 127.0.0.1

Optional, String: An IP address or fully qualified domain name of the C<gpsd>
server. Defaults to the localhost (C<127.0.0.1>) if not supplied.

    port => 2947

Optional, Integer: The TCP port number that the C<gpsd> daemon is running on.
Defaults to C<2947> if not sent in.

=head2 on

Puts C<gpsd> in listening mode, ready to poll data from. 

If this method is not called, a warning will be thrown when you C<poll()>, and
your dataset will be incomplete (ie. invalid).

=head2 off

Turns off C<gpsd> listening mode.

Not necessary to call, but it will help preserve battery life if running on a
portable device.

=head2 poll(%args)

Does a poll of C<gpsd> for data, and configures the object with that data.

Parameters:

All parameters are sent in as a hash.

    fname => $filename

Optional, String: Used for testing, you can send in the name of a JSON file
that contains C<gpsd> JSON data and we'll work with that instead of polling
the GPS device directly.

    return => 'json'

Optional, String: By default, after configuring the object, we will return the
polled raw data as a Perl hash reference. Send this param in with the value of
C<'json'> and we'll return the data exactly as we received it from C<gpsd>.

Returns:

The raw poll data as either a Perl hash reference structure or as the
original JSON string.

=head2 tpv($stat)

C<TPV> stands for "Time Position Velocity". This is the data that represents
your location and other vital statistics.

By default, we return a hash reference that is in the format C<stat => 'value'>.

Parameters:

    $stat

Optional, String. You can extract individual statistics of the TPV data by
sending in the name of the stat you wish to fetch. This will then return the
string value if available. Returns C<undef> if the statistic doesn't exist.

Available statistic/info name, example value, description. This is the default
raw result:

   time     => '2017-05-16T22:29:29.000Z'   # date/time in UTC
   lon      => '-114.000000000'             # longitude
   lat      => '51.000000'                  # latitude
   alt      => '1084.9'                     # altitude (metres)
   climb    => '0'                          # rate of ascent/decent (metres/sec)
   speed    => '0'                          # rate of movement (metres/sec)
   track    => '279.85'                     # heading (degrees from true north)
   device   => '/dev/ttyS0'                 # GPS serial interface            
   mode     => 3                            # NMEA mode
   epx      => '3.636'                      # longitude error estimate (metres)
   epy      => '4.676'                      # latitude error estimate (metres)
   epc      => '8.16'                       # ascent/decent error estimate (meters)
   ept      => '0.005'                      # timestamp error (sec) 
   epv      => '4.082'                      # altitude error estimate (meters)
   eps      => '9.35'                       # speed error estimate (metres/sec)
   class    => 'TPV'                        # data type (fixed as TPV)
   tag      => 'ZDA'                        # identifier

=head2 satellites($num, $stat)

This method returns a hash reference of hash references, where the key is the
satellite number, and the value is a hashref that contains the various
information related to the specific numbered satellite.

Note that the data returned by this function has been manipuated and is not
exactly equivalent of that returned by C<gpsd>. To get the raw data, see 
C<sky()>.

Parameters:

    $num

Optional, Integer: Send in the satellite number and we'll return the relevant
information in a hash reference for the specific satellite requested, as
opposed to returning data for all the satellites. Returns C<undef> if a
satellite by that number doesn't exist.

    $stat

Optional, String: Like C<tpv()>, you can request an individual piece of
information for a satellite. This parameter is only valid if you've sent in
the C<$num> param, and the specified satellite exists.

Available statistic/information items available for each satellite, including
the name, an example value and a description:

NOTE: The PRN attribute will not appear unless you're using raw data. The PRN
can be found as the satellite hash reference key after we've processed the
data.

    PRN     => 16   # PRN ID of the satellite 

                    # 1-63 are GNSS satellites
                    # 64-96 are GLONASS satellites
                    # 100-164 are SBAS satellites

    ss      => 20   # signal strength (dB)
    az      => 161  # azimuth (degrees from true north)
    used    => 1    # currently being used in calculations
    el      => 88   # elevation in degrees

=head2 sky

Returns a hash reference containing all of the data that was pulled from the
C<SKY> information returned by C<gpsd>. This information contains satellite
info and other related statistics.

Available information, with the attribute, example value and description:

    satellites  => []           # array of satellite hashrefs
    xdop        => '0.97'       # longitudinal dilution of precision
    ydop        => '1.25'       # latitudinal dilution of precision
    pdop        => '1.16'       # spherical dilution of precision
    tdop        => '2.2'        # time dilution of precision
    vdop        => '0.71'       # altitude dilution of precision
    gdop        => '3.87'       # hyperspherical dilution of precision
    hdop        => '0.92'       # horizontal dilution of precision
    class       => 'SKY'        # object class, hardcoded to SKY
    tag         => 'ZDA'        # object ID
    device      => '/dev/ttyS0' # serial port connected to the GPS

=head2 device

Returns a string containing the actual device the GPS is connected to
(eg: C</dev/ttyS0>).

=head2 time

Returns a string of the date and time of the most recent poll, in UTC.

=head1 SEE ALSO

A very similar distribution is L<Net::GPSD3>. However, it has a long line of
prerequisite distributions that didn't always install easily on my primary
target platform, the Raspberry Pi.

This distribution isn't meant to replace that one, it's just a much simpler and
more lightweight piece of software that pretty much does the same thing.

=head1 AUTHOR

Steve Bertrand, C<< <steveb at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2017 Steve Bertrand.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.
