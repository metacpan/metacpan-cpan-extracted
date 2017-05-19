package GPSD::Parse;

use strict;
use warnings;

use Carp qw(croak);
use IO::Socket::INET;

our $VERSION = '1.00';

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

sub new {
    my ($class, %args) = @_;
    my $self = bless {}, $class;

    $self->_file($args{file});
    $self->_metric($args{metric});
    $self->_signed($args{signed});

    if (! $self->_file) {
        $self->_port($args{port});
        $self->_host($args{host});
        $self->_socket;
        $self->on;
    }

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
 
    $self->_file($args{file});

    my $gps_json_data;

    if ($self->_file){
        my $fname = $self->_file;

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
        return '' if ! defined $self->{tpv}{$stat};
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
sub direction {
    shift if @_ > 1;

    my ($deg) = @_;

    my @directions = qw(
        N NNE NE ENE E ESE SE SSE S SSW SW WSW W WNW NW NNW N
    );

    my $calc = (($deg % 360) / 22.5) + .5;

    return $directions[$calc];
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
sub _file {
    my ($self, $file) = @_;
    $self->{file} = $file if defined $file;
    return $self->{file};
}
sub _host {
    my ($self, $host) = @_;
    $self->{host} = $host if defined $host;
    $self->{host} = '127.0.0.1' if ! defined $self->{host};
    return $self->{host};
}
sub _metric {
    my ($self, $metric) = @_;
    $self->{metric} = $metric if defined $metric;
    $self->{metric} = 1 if ! defined $self->{metric};
    return $self->{metric};
}
sub _port {
    my ($self, $port) = @_;
    $self->{port} = $port if defined $port;
    $self->{port} = 2947 if ! defined $self->{port};
    return $self->{port};
}
sub _parse {
    # parse the GPS data and populate the object
    my ($self, $data) = @_;

    $self->{tpv}  = $data->{tpv}[0];
    $self->{time} = $self->{tpv}{time};
    $self->{device} = $self->{tpv}{device};
    $self->{sky} = $data->{sky}[0];

    if (! $self->_metric) {
        # convert to imperial; feet
        my @convertable_stats = qw(alt climb speed);

        for (@convertable_stats){
            my $num = $self->{tpv}{$_};
            $num = $num * 3.28084;
            $self->{tpv}{$_} = substr($num, 0, index($num, '.') + 1 + 3);
        }
    }

    if (! $self->_signed){
        # switch between signed lat/long

        ($self->{tpv}{lat}, $self->{tpv}{lon})
            = $self->_signed_convert($self->{tpv}{lat}, $self->{tpv}{lon});
    }

    my %sats;

    for my $sat (@{ $self->{sky}{satellites} }){
        my $prn = $sat->{PRN};
        delete $sat->{PRN};
        $sat->{used} = $sat->{used} ? 1 : 0;
        $sats{$prn} = $sat;
    }
    $self->{satellites} = \%sats;
}
sub _signed {
    # convert between signed location and alpha
    my ($self, $signed) = @_;
    $self->{signed} = $signed if defined $signed;
    $self->{signed} = 1 if ! defined $self->{signed};
    return $self->{signed};
}
sub _signed_convert {
    # perform the actual lat/long conversion
    # we do it here for testing purposes

    shift if @_ == 3;

    my ($lat, $lon) = @_;

    if ($lat =~ /^-/) {
        $lat =~ s/-(.*)/${1}S/;
    }
    else {
        $lat .= 'N';
    }

    if ($lon =~ /^-/) {
        $lon =~ s/-(.*)/${1}W/;
    }
    else {
        $lon .= 'E';
    }

    return ($lat, $lon);
}
sub _is_socket {
    # check if we're in socket mode
    my ($self, $status) = @_;
    $self->{is_socket} = $status if defined $status;
    return $self->{is_socket};
}
sub _socket {
    my ($self) = @_;

    return undef if $self->_file;

    if (! defined $self->{socket}){
        $self->{"socket"}=IO::Socket::INET->new(
                        PeerAddr => $self->_host,
                        PeerPort => $self->_port,
        );
    }

    my ($h, $p) = ($self->_host, $self->_port);

    croak "can't connect to gpsd://$h:$p" if ! defined $self->{socket};
  
    return $self->{'socket'};
}
sub DESTROY {
    my $self = shift;
    $self->off if $self->_is_socket;
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

    # poll for data

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

=head1 DESCRIPTION

Simple, lightweight (core only) distribution that polls C<gpsd> for data
received from a UART (serial/USB) connected GPS receiver over a TCP connection.

The data is fetched in JSON, and returned as Perl data.

=head1 NOTES

=head2 Requirements

A version of L<gpsd|http://catb.org/gpsd/gpsd.html> that returns results in
JSON format is required to have been previously installed. It should be started
at system startup, with the following flags with system-specific serial port.
See the above link for information on changing the listen IP and port.

    sudo gpsd /dev/ttyS0 -n -F /var/log/gpsd.sock

=head2 Available Data

Each of the methods that return data have a table in their respective
documentation within the L</METHODS> section. Specifically, look at the
C<tpv()>, C<sattelites()> and the more broad C<sky()> method sections to
understand what available data attributes you can extract.

=head2 Conversions

All output where applicable defaults to metric (metres). See the C<metric>
parameter in the C<new()> method to change this to use imperial/standard
measurements.

For latitude and longitude, we default to using the signed notation. You can
disable this with the C<signed> parameter in C<new()>.

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

    metric => Bool

Optional, Integer: By default, we return measurements in metric (metres). Send
in a false value (C<0>) to use imperial/standard measurement conversions
(ie. feet). Note that if returning the raw *JSON* data from the C<poll()>
method, the conversions will not be done. The default raw Perl return will have
been converted however.

    signed => Bool

Optional, Integer: By default, we use the signed notation for latitude and
longitude. Send in a false value (C<0>) to disable this. Here's an example:

    enabled (default)   disabled
    -----------------   --------

    lat: 51.12345678    51.12345678N
    lon: -114.123456    114.123456W

We add the letter notation at the end of the result if C<signed> is disabled.

    file => 'filename.ext'

Optional, String: For testing purposes. Instead of reading from a socket, send
in a filename that contains legitimate JSON data saved from a previous C<gpsd>
output and we'll operate on that. Useful also for re-running previous output.

=head2 poll(%args)

Does a poll of C<gpsd> for data, and configures the object with that data.

Parameters:

All parameters are sent in as a hash.

    file => $filename

Optional, String: Used for testing, you can send in the name of a JSON file
that contains C<gpsd> JSON data and we'll work with that instead of polling
the GPS device directly. Note that you *must* instantiate the object with the
C<file> parameter in new for this to have any effect and to bypass the socket
creation.

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
string value if available. Returns an empty string if the statistic doesn't
exist.

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

=head2 direction($degree)

Converts a degree from true north into a direction (eg: ESE, SW etc).

Parameters:

    $degree

Mandatory, Ineger/Decimal: A decimal ranging from 0-360. Returns the direction
representing the degree from true north. A common example would be:

    my $heading = $gps->direction($gps->tpv('track'));

Degree/direction map:

    N       348.75 - 11.25
    NNE     11.25  - 33.75
    NE      33.75  - 56.25
    ENE     56.25  - 78.75

    E       78.75  - 101.25
    ESE     101.25 - 123.75
    SE      123.75 - 146.25
    SSE     146.25 - 168.75

    S       168.75 - 191.25
    SSW     191.25 - 213.75
    SW      213.75 - 236.25
    WSW     236.25 - 258.75

    W       258.75 - 281.25
    WNW     281.25 - 303.75
    NW      303.75 - 326.25
    NNW     326.25 - 348.75

=head2 device

Returns a string containing the actual device the GPS is connected to
(eg: C</dev/ttyS0>).

=head2 time

Returns a string of the date and time of the most recent poll, in UTC.

=head2 on

Puts C<gpsd> in listening mode, ready to poll data from.

We call this method internally when the object is instantiated with C<new()> if
we're not in file mode. Likewise, when the object is destroyed (end of program
run), we call the subsequent C<off()> method.

If you have long periods of a program run where you don't need the GPS, you can
manually run the C<off()> and C<on()> methods to disable and re-enable the GPS.

=head2 off

Turns off C<gpsd> listening mode.

Not necessary to call, but it will help preserve battery life if running on a
portable device for long program runs where the GPS is used infrequently. Use in
conjunction with C<on()>. We call C<off()> automatically when the object goes
out of scope (program end for example).

=head1 EXAMPLES

=head2 Basic Features and Options

Here's a simple example using some of the basic features and options. Please
read through the documentation of the methods (particularly C<new()> and 
C<tpv()> to get a good grasp on what can be fetched.

    use warnings;
    use strict;
    use feature 'say';

    use GPSD::Parse;

    my $gps = GPSD::Parse->new(signed => 0);

    $gps->poll;

    my $lat = $gps->tpv('lat');
    my $lon = $gps->tpv('lon');

    my $heading = $gps->tpv('track');
    my $direction = $gps->direction($heading);

    my $altitude = $gps->tpv('alt');

    my $speed = $gps->tpv('speed');

    say "latitude:  $lat";
    say "longitude: $lon\n";

    say "heading:   $heading degrees";
    say "direction: $direction\n";

    say "altitude:  $altitude metres\n";

    say "speed:     $speed metres/sec";

Output:

    latitude:  51.1111111N
    longitude: 114.11111111W

    heading:   31.23 degrees
    direction: NNE

    altitude:  1080.9 metres

    speed:     0.333 metres/sec


=head1 TESTING

Please note that we init and disable the GPS device on construction and
deconstruction of the object respectively. It takes a few seconds for the GPS
unit to initialize itself and then lock on the satellites before we can get
readings. For this reason, please understand that one test sweep may pass while
the next fails.

I am considering adding specific checks, but considering that it's a timing
thing (seconds, not microseconds that everyone is in a hurry for nowadays) I am
going to wait until I get a chance to take the kit into the field before I do
anything drastic.

For now. I'll leave it as is; expect failure if you ram on things too quickly.

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
