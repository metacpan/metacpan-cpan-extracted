package InfluxDB::HTTP;

use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

our @EXPORT_OK = ();
our @EXPORT    = ();

use JSON::MaybeXS;
use LWP::UserAgent;
use Object::Result;
use URI;

our $VERSION = '0.04';

sub new {
    my $class = shift;
    my %args = (
        host => 'localhost',
        port => 8086,
        timeout => 180,
        @_,
    );
    my ($host, $port, $timeout) = @args{'host', 'port', 'timeout'};

    my $self = {
        host => $host,
        port => $port,
    };

    my $ua= LWP::UserAgent->new();
    $ua->agent("InfluxDB-HTTP/$VERSION");
    $ua->timeout($timeout);
    $self->{lwp_user_agent} = $ua;

    bless $self, $class;

    return $self;
}

sub get_lwp_useragent {
    my ($self) = @_;
    return $self->{lwp_user_agent};
}

sub ping {
    my ($self) = @_;
    my $uri = $self->_get_influxdb_http_api_uri('ping');
    my $response = $self->{lwp_user_agent}->head($uri->canonical());

    if (! $response->is_success()) {
        my $error = $response->message();
        result {
                raw    { return $response; }
                error  { return $error; }
                <STR>  { return "Error pinging InfluxDB: $error"; }
                <BOOL> { return; }
        }
    }

    my $version = $response->header('X-Influxdb-Version');
    result {
            raw     { return $response; }
            version { return $version; }
            <STR>   { return "Ping successful: InfluxDB version $version"; }
            <BOOL>  { return 1; }
    }
}

sub query {
    my $self = shift;
    my $query = shift;
    my %args = (epoch => 'ns', @_);
    my ($database, $chunk_size, $epoch) = @args{'database', 'chunk_size', 'epoch'};

    die "Missing argument 'query'" if !$query;
    die "Argument epoch '$epoch' is not one of (h,m,s,ms,u,ns)" if $epoch !~ /^(h|m|s|ms|u|ns)$/;

    if (ref($query) eq 'ARRAY') {
        $query = join(';', @$query);
    }

    my $uri = $self->_get_influxdb_http_api_uri('query');

    $uri->query_form(
        q => $query,
        ($database ? (db => $database) : ()),
        ($chunk_size ? (chunk_size => $chunk_size) : ()),
        ($epoch ? (epoch => $epoch) : ())
    );

    my $response = $self->{lwp_user_agent}->post($uri->canonical());

    chomp(my $content = $response->content());

    my $error;
    if ($response->is_success()) {
        local $@;
        my $data = eval { decode_json($content) };
        $error = $@;

        if ($data) {
            $error = $data->{error};
        }

        if (!$error) {
            result {
                raw         { return $response; }
                data        { return $data; }
                results     { return $data->{results}; }
                request_id  { return $response->header('Request-Id'); }
                <STR>       { return "Returned data: $content"; }
                <BOOL>      { return 1; }
            }
        }
    }
    else {
        $error = $content;
    }

    result {
        raw    { return $response; }
        error  { return $error; }
        <STR>  { return "Error executing query: $error"; }
        <BOOL> { return; }
    }
}

sub write {
    my $self = shift;
    my $measurement = shift;
    my %args = @_;
    my ($database, $precision, $retention_policy) = @args{'database', 'precision', 'retention_policy'};

    die "Missing argument 'measurement'" if !$measurement;
    die "Missing argument 'database'" if !$database;
    die "Argument precision '$precision' is set and not one of (h,m,s,ms,u,ns)" if $precision && $precision !~ /^(h|m|s|ms|u|ns)$/;

    if (ref($measurement) eq 'ARRAY') {
        $measurement = join("\n", @$measurement);
    }

    my $uri = $self->_get_influxdb_http_api_uri('write');

    $uri->query_form(
        db => $database,
        ($precision ? (precision => $precision) : ()),
        ($retention_policy ? (rp => $retention_policy) : ())
    );

    my $response = $self->{lwp_user_agent}->post($uri->canonical(), Content => $measurement);

    chomp(my $content = $response->content());

    if ($response->code() != 204) {
        local $@;
        my $data = eval { decode_json($content) };
        my $error = $@;
        $error = $data->{error} if (!$error && $data);

        result {
            raw    { return $response; }
            error  { return $error; }
            <STR>  { return "Error executing write: $error"; }
            <BOOL> { return; }
        }
    }

    result {
        raw    { return $response; }
        <STR>  { return "Write successful"; }
        <BOOL> { return 1; }
    }
}

sub _get_influxdb_http_api_uri {
    my ($self, $endpoint) = @_;

    die "Missing argument 'endpoint'" if !$endpoint;

    my $uri = URI->new();

    $uri->scheme('http');
    $uri->host($self->{host});
    $uri->port($self->{port});
    $uri->path($endpoint);

    return $uri;
}

1;

__END__

=head1 NAME

InfluxDB::HTTP - The Perl way to interact with InfluxDB!

=head1 VERSION

Version 0.04

=head1 SYNOPSIS

InfluxDB::HTTP allows you to interact with the InfluxDB HTTP API. The module essentially provides
one method per InfluxDB HTTP API endpoint, that is C<ping>, C<write> and C<query>.

    use InfluxDB::HTTP;

    my $influx = InfluxDB::HTTP->new();

    my $ping_result = $influx->ping();
    print "$ping_result\n";

    my $query = $influx->query(
        [ 'SELECT Lookups FROM _internal.monitor.runtime WHERE time > '.(time - 60)*1000000000, 'SHOW DATABASES'],
        epoch => 's',
    );

    print "$query\n";


=head1 SUBROUTINES/METHODS

=head2 RETURN VALUES AND ERROR HANDLING

C<Object::Result> is relied upon for returning data from subroutines. The respective result
object can always be used as string and evaluated on a boolean basis. A result object
evaluating to false indicates an error and a corresponding error message is provided in the
attribute C<error>:

    my $ping = $influx->ping();
    print $ping->error unless ($ping);

Furthermore, all result objects provide access to the C<HTTP::Response> object that is returned
by InfluxDB in the attribute C<raw>.

=head2 new host => 'localhost', port => 8086, timeout => 600

Passing C<host>, C<port> and/or C<timeout> is optional, defaulting to the InfluxDB defaults or
to 3 minutes for the timeout. The timeout is in seconds.

Returns an instance of InfluxDB::HTTP.

=head2 ping

Pings the InfluxDB instance configured in the constructor (i.e. by C<host> and C<port>).

Returned object evaluates to true or false depending on whether the ping was successful or not.
If true, then it contains a C<version> attribute that indicates the InfluxDB version running on
the pinged server.

The C<version> attribute is extracted from the C<X-Influxdb-Version> HTTP response header, which
is part of the HTTP response from the pinged InfluxDB instance.

    my $ping = $influx->ping();
    print $ping->version if ($ping);

=head2 query query, database => "DATABASE", chunk_size => CHUNK_SIZE, epoch => "ns"

Used to query the InfluxDB instance. All parameters but the first one are optional. The
C<query> parameter can either be a String or a Perl ArrayRef of Strings, where every String
contains a valid InfluxDB query.

If the returned object evaluates to true, indicating that the query was successful, then
the returned object's C<data> attribute contains the entire response from InfluxDB as Perl
hash. Additionally the attribute C<request_id> provides the request identifier as set in
the HTTP reponse headers by InfluxDB. This can for example be useful for correlating
requests with log files.

=head2 write measurement, database => "DATABASE", precision => "ns", retention_policy => "RP"

Writes data into InfluxDB. The parameter C<measurement> can either be a String or an
ArrayRef of Strings, where each String contains one valid InfluxDB LineProtocol
statement. All of those mesaurements are then sent to InfluxDB and the specified
database. The returned object evaluates to true if the write was successful, and otherwise
to false.

The optional argument precision can be given if a precsion different than "ns" is used in
the line protocol. InfluxDB docs suggest that using a coarser precision than ns can save
space and processing. In many cases "s" or "m" might do.

The optional argument retention_policy can be used to specify a retention policy other than
the default retention policy of the selected database.

=head2 get_lwp_useragent

Returns the internally used LWP::UserAgent instance for possible modifications
(e.g. to configure an HTTP proxy).

=head1 AUTHOR

Raphael Seebacher, C<< <raphael@seebachers.ch> >>

=head1 BUGS

Please report any bugs or feature requests to
L<https://github.com/raphaelthomas/InfluxDB-HTTP/issues>.

=head1 LICENSE AND COPYRIGHT

MIT License

Copyright (c) 2016 Raphael Seebacher

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

=cut
