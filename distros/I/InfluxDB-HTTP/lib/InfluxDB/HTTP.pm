package InfluxDB::HTTP;

use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

our @EXPORT_OK = ();
our @EXPORT    = ();

use JSON::XS;
use LWP::UserAgent;
use Method::Signatures;
use Object::Result;
use URI;

our $VERSION = '0.01';

method new ($class: Str :$host = 'localhost', Int :$port = 8086) {
    my $self = {
        host => $host,
        port => $port,
    };

    $self->{lwp_user_agent} = LWP::UserAgent->new();
    $self->{lwp_user_agent}->agent("InfluxDB-HTTP/$VERSION");

    bless $self, $class;

    return $self;
}

method get_lwp_useragent {
    return $self->{lwp_user_agent};
}

method ping {
    my $uri = $self->_get_influxdb_http_api_uri('ping');
    my $response = $self->{lwp_user_agent}->head($uri->canonical());

    if (! $response->is_success()) {
        my $error = $response->message();
        result {
                error  { return $error; }
                <STR>  { return "Error pinging InfluxDB: $error"; }
                <BOOL> { return; }
        }
    }

    my $version = $response->header('X-Influxdb-Version');
    result {
            version { return $version; }
            <STR>   { return "Ping successful: InfluxDB version $version"; }
            <BOOL>  { return 1; }
    }
}

method query (Str|ArrayRef[Str] $query!, Str :$database, Int :$chunk_size, Str :$epoch where qr/(h|m|s|ms|u|ns)/ = 'ns') {
    if (ref($query) eq 'ARRAY') {
        $query = join(';', @$query);
    }

    my $uri = $self->_get_influxdb_http_api_uri('query');

    # FIXME move this query handling to _get_influxdb_http_api_uri subroutine
    my $uri_query = {'q' => $query, };
    $uri_query->{'db'} = $database if (defined $database);
    $uri_query->{'chunk_size'} = $chunk_size if (defined $chunk_size);
    $uri_query->{'epoch'} = $epoch if (defined $epoch);
    $uri->query_form($uri_query);

    my $response = $self->{lwp_user_agent}->post($uri->canonical());

    if (! $response->is_success()) {
        my $error = $response->message();
        result {
            error  { return $error; }
            <STR>  { return "Error executing query: $error"; }
            <BOOL> { return; }
        }
    }

    my $data = decode_json($response->content());

    result {
        data        { return $data; }
        results     { return $data->{results}; }
        request_id  { return $response->header('Request-Id'); }
        <STR>       { return 'Returned data: '.$response->content(); }
        <BOOL>      { return 1; }
    }
}

method write (Str|ArrayRef[Str] $measurement!, Str :$database) {
    if (ref($measurement) eq 'ARRAY') {
        $measurement = join("\n", @$measurement);
    }

    my $uri = $self->_get_influxdb_http_api_uri('write');
    $uri->query_form(db => $database) if (defined $database);

    my $response = $self->{lwp_user_agent}->post($uri->canonical(), Content => $measurement);

    if ($response->code() != 204) {
        my $error = $response->message();
        result {
            error  { return $error; }
            <STR>  { return "Error executing write $error"; }
            <BOOL> { return; }
        }
    }

    result {
        <STR>  { return "Write successful"; }
        <BOOL> { return 1; }
    }
}

method _get_influxdb_http_api_uri (Str $endpoint!) {
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

Version 0.01

=head1 SYNOPSIS

InfluxDB::HTTP allows you top interact with the InfluxDB HTTP API. The module essentially provides
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

=head2 new host => 'localhost', port => 8086

Passing C<host> and/or C<port> is optional, defaulting to the InfluxDB defaults.

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

=head2 write measurement, database => "DATABASE"

Writes data into InfluxDB. The parameter C<measurement> can either be a String or an
ArrayRef of Strings, where each String contains one valid InfluxDB LineProtocol
statement. All of those mesaurements are then sent to InfluxDB and the specified
database.

The returned object evaluates to true if the write was successful, and otherwise to
false.

=head2 get_lwp_useragent

Returns the internally used LWP::UserAgent instance for possible modifications
(e.g. to configure an HTTP proxy).

=head1 AUTHOR

Raphael Seebacher, C<< <raphael at seebachers.ch> >>

=head1 BUGS

Please report any bugs or feature requests to
L<https://github.com/raphaelthomas/InfluxDB-HTTP/issues>.

=head1 LICENSE AND COPYRIGHT

Copyright 2016 Raphael Seebacher.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.

=cut
