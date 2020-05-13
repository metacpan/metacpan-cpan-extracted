package InfluxDB::Client::Simple;

use 5.006;
use strict;
use warnings;

use Carp;
use IO::Socket::INET;
use JSON;
use LWP::UserAgent;
use URI;

=head1 NAME

InfluxDB::Client::Simple - The lightweight InfluxDB client

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';

=head1 SYNOPSIS

InfluxDB::Client::Simple provides an easy way to interact with an InfluxDB server.

    use InfluxDB::Client::Simple;

    ########################## TCP ##########################
    my $client = InfluxDB::Client::Simple->new( host => 'server.address.com', port => 8086, protocol => 'tcp' ) or die "Can't instantiate client";

    # Check server connectivity
    my $result = $client->ping();
    die "No pong" unless $result;

    # You can also get the server version
    print $result->{version};

    # Read
    $result = $client->query('SELECT "severity_code" FROM "syslog" WHERE ("severity" = \'err\' AND "hostname" =~ /^(srv01|srv02)$/) AND time >= 1558878013531ms and time <= 1609886964827ms', database => 'grafana');

    # Write
    $result = $client->write("testing,host=containment,repo=cadi-libs,file=testfile statement=42,pod=85", database => 'dbname');

    ########################## UDP ##########################
    $client = InfluxDB::Client::Simple->new( host => 'server.address.com', port => 8089, protocol => 'udp', database => 'grafana' ) or die "Can't instantiate client";

    # UDP allows only write()
    $result = $client->write("testing,host=containment,repo=cadi-libs,file=testfile statement=47,pod=89");

=head1 WHY

In its current state this module offers few additional features over InfluxDB::HTTP (from which it's derived) 

The only reasons why you would use this module are:

=over

=item *
Minimal dependencies (no Object::Result and its dependencies)

=item *
You want to use UDP protocol for writing (WIP)

=back

=head1 SUBROUTINES/METHODS

=head2 new ( [%options] )

Constructor.
%otions is a hash with the following keys:

=over

=item *
database - Database name (default: 'grafana')

=item *
host - Server hostname (default: 'localhost')

=item *
port - Server port (default: 8086)

=item *
protocol - Transport protocol 'udp' or 'tcp' (default: 'tcp')
Note that when using the udp protocol, the default behaviour is to avoid dying on errors.
(You can change that with the 'strict_udp' option)

=item *
strict_udp - Boolean value to die on UDP error (false by default)

=item *
timeout - Timeout value in seconds (default: 180)

=back

=cut

sub new {
    my $class = shift;
    my %args = ( database => 'grafana',
                 host     => 'localhost',
                 port     => 8086,
                 protocol => 'tcp',
                 timeout  => 180,
                 @_,
    );
    my ( $host, $port, $protocol, $strict_udp, $timeout ) = map { lc }  @args{ 'host', 'port', 'protocol', 'strict_udp', 'timeout' };

    my $self = { host => $host,
                 port => $port,
                 protocol => $protocol,
                 options => { database => $args{database} }
    };

    if ( $protocol eq 'tcp' ) {
        my $ua = LWP::UserAgent->new();
        $ua->agent("InfluxDB-Client-Simple/$VERSION");
        $ua->timeout($timeout);
        $self->{lwp_user_agent} = $ua;
    } else {
        die "Unknown protocol: $protocol" unless $protocol eq "udp";

        my $socket = IO::Socket::INET->new( PeerAddr => "$host:$port",
                                            Proto    => $protocol,
                                            Blocking => 0
        );

        if ($strict_udp) {
          die("Can't open socket: $@") unless $socket;
        }

        $self->{udp} = $socket;
    }

    bless $self, $class;

    return $self;
}

=head2 ping()

Check the server connectivity.

Returns a hashref which evaluates to true if the connection is ok and to false otherwise.
The hashref has the following keys:

=over

=item *
raw - The raw response from the server

=item *
error - The error message returned by the server (empty on success)

=item *
version - The InfluxDB verstion returned by the server through the 'X-Influxdb-Version' header

=back

=cut

sub ping {
    my ($self)   = @_;
    my $uri      = $self->_get_influxdb_http_api_uri('ping');
    my $response = $self->{lwp_user_agent}->head( $uri->canonical() );

    if ( !$response->is_success() ) {
        my $error = $response->message();
        return { raw     => $response,
                 error   => $error,
                 version => undef,
        };
    }

    my $version = $response->header('X-Influxdb-Version');
    return { raw     => $response,
             error   => undef,
             version => $version,
    };
}

=head2 query( $query [, %options] )

Query the InfluxDB database using the $query passed as first parameter.
Optionally %options can be passed as a hash 
Allowed keys for options are:

=over

=item *
database - The database to be queried on the InfluxDB server

=item *
chunksize - The size of the chunks used for the returned data

=item *
epoch - The precision format (h, m, s, ms, u, ns) for epoch timestamps

=back

Returns a hashref whose keys are:

=over

=item *
raw - The raw response from the server

=item *
error - The error message returned by the server (empty on success)

=item *
data - The InfluxDB data returned by the server

=back

=cut

sub query {
    my $self  = shift;
    my $query = shift;
    my %args  = ( epoch => 'ns', @_ );
    my ( $database, $chunk_size, $epoch ) = @args{ 'database', 'chunk_size', 'epoch' };

    die "Missing argument 'query'" if !$query;
    die "Argument epoch '$epoch' is not one of (h,m,s,ms,u,ns)" if $epoch !~ /^(h|m|s|ms|u|ns)$/;

    if ( ref($query) eq 'ARRAY' ) {
        $query = join( ';', @$query );
    }

    my $uri = $self->_get_influxdb_http_api_uri('query');

    $uri->query_form( q => $query,
                      ( $database   ? ( db         => $database )   : () ),
                      ( $chunk_size ? ( chunk_size => $chunk_size ) : () ),
                      ( $epoch      ? ( epoch      => $epoch )      : () )
    );

    my $response = $self->{lwp_user_agent}->post( $uri->canonical() );

    chomp( my $content = $response->content() );

    my $error;
    if ( $response->is_success() ) {
        local $@;
        my $data = eval { decode_json($content) };
        $error = $@;

        if ($data) {
            $error = $data->{error};
        }

        if ( !$error ) {
            $data->{request_id} = $response->header('Request-Id');
            return { raw   => $response,
                     data  => $data,
                     error => undef,
            };
        }
    } else {
        $error = $content;
    }

    return { raw   => $response,
             data  => undef,
             error => $error,
    };
}

=head2 write ($measurement | \@measurements, [%options])

$measurement is the data to be send encoded according to the LineProtocol.

%options can have the following keys:

=over

=item *
database - The database to be queried on the InfluxDB server

=item *
retention_policy - The retention policy to be used (if different from the default one)

=item *
precision - The precision used in the data (if diffectent from the default 'ns')

=back

Returns a hashref whose keys are:

=over

=item *
raw - The raw response from the server (obviously empty when using UDP)

=item *
error - The error message returned by the server (empty on success)

=back

=cut

sub write {
    my $self        = shift;
    my $measurement = shift;
    my %args        = (%{$self->{options}},  @_);
    my ( $database, $precision, $retention_policy ) = @args{ 'database', 'precision', 'retention_policy' };

    die "Missing argument 'measurement'"                                        if !$measurement;
    die "Missing argument 'database'"                                           if !$database;
    die "Argument precision '$precision' is set and not one of (h,m,s,ms,u,ns)" if $precision && $precision !~ /^(h|m|s|ms|u|ns)$/;

    if ( ref($measurement) eq 'ARRAY' ) {
        $measurement = join( "\n", @$measurement );
    }

  if ($self->{protocol} eq 'tcp') {
    my $uri = $self->_get_influxdb_http_api_uri('write');

    $uri->query_form( db => $database,
                      ( $precision        ? ( precision => $precision )        : () ),
                      ( $retention_policy ? ( rp        => $retention_policy ) : () )
    );

    my $response = $self->{lwp_user_agent}->post( $uri->canonical(), Content => $measurement );

    chomp( my $content = $response->content() );

    if ( $response->code() != 204 ) {
        local $@;
        my $data = eval { decode_json($content) };
        my $error = $@;
        $error = $data->{error} if ( !$error && $data );

        return { raw   => $response,
                 error => $error,
        };
    }

    return { raw   => $response,
             error => undef,
    };

  } else {

    # Udp send
    my $bytes = $self->{udp}?$self->{udp}->send($measurement):0;

    # should be more picky here : compare $bytes with length of $measurement ?
    return { raw   => undef,
             error => $bytes?undef:"Undefinded error while sending data (udp)",
    };
  }
}


=head2 send_data ($measurement, \%tags, \%fields, [%options])

Write data to the influxDB after converting them into LineProtocol format.
(call write() underneath)

$measurement is the name to be used for measurement

\%tags is the tag set associated to this datapoint

\%fields are the field set associated to this datapoint

$timestamp is an optional timestamp value

\%options

%options can have the following keys:

=over

=item *
database - The database to be queried on the InfluxDB server

=item *
retention_policy - The retention policy to be used (if different from the default one)

=item *
precision - The precision used in the data (if diffectent from the default 'ns')

=back

Returns a hashref whose keys are:

=over

=item *
raw - The raw response from the server (obviously empty when using UDP)

=item *
error - The error message returned by the server (empty on success)

=back

=cut

sub send_data {
  my $self = shift;
  my $measurement = shift;
  my $tags = shift;
  my $fields = shift;
  my %options = @_;

  return $self->write(_line_protocol($measurement, $tags, $fields), %options);

}

sub _get_influxdb_http_api_uri {
    my ( $self, $endpoint ) = @_;

    die "Missing argument 'endpoint'" if !$endpoint;

    my $uri = URI->new();

    $uri->scheme('http');
    $uri->host( $self->{host} );
    $uri->port( $self->{port} );
    $uri->path($endpoint);

    return $uri;
}

# Blatantly stolen from InfluxDB::LineProtocol
sub _format_value {
    my $k = shift;
    my $v = shift;
 
    if ( $v =~ /^(-?\d+)(?:i?)$/ ) {
        $v = $1 . 'i';
    }
    elsif ( $v =~ /^[Ff](?:ALSE|alse)?$/ ) {
        $v = 'FALSE';
    }
    elsif ( $v =~ /^[Tt](?:RUE|rue)?$/ ) {
        $v = 'TRUE';
    }
    elsif ( $v =~ /^-?\d+(?:\.\d+)?(?:e(?:-|\+)?\d+)?$/ ) {
        # pass it on, no mod
    }
    else {
        # string actually, but this should be quoted differently?
        $v =~ s/(["\\])/\\$1/g;
        $v = '"' . $v . '"';
    }
 
    return $v;
}


sub _line_protocol {
  my $measurement = shift;
  my $tags = shift;
  my $fields = shift;

  # sort and encode (LineProtocol) tags
  my @tags;
  foreach my $k ( sort keys %$tags ) {
    my $v = $tags->{$k};
    next unless defined($v);
    $k =~ s/([,\s])/\\$1/g;
    $v =~ s/([,\s])/\\$1/g;

    push( @tags, $k . '=' . $v );
  }
  my $tag_string = join( ',', @tags );


  # sort and encode (LineProtocol) fields
  my @fields;
  foreach my $k ( sort keys %$fields ) {
    my $v = $fields->{$k} || '';
    my $esc_k = $k;
    $esc_k =~ s/([,\s])/\\$1/g;
    my $esc_v = _format_value($k, $v);

    push( @fields, $esc_k . '=' . $esc_v );
  }
  my $field_string = join( ',', @fields );

  return sprintf( "%s,%s %s", $measurement, $tag_string, $field_string );
}

1;

=head1 AUTHOR

Arnaud (Arhuman) ASSAD, C<< <aassad at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-influxdb-client at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=InfluxDB-Client-Simple>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SEE ALSO

This module is derived from InfluxDB::HTTP.
This module borowed code from InfluxDB::LineProtocol

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc InfluxDB::Client::Simple


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=InfluxDB-Client-Simple>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/InfluxDB-Client-Simple>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/InfluxDB-Client-Simple>

=item * Search CPAN

L<https://metacpan.org/release/InfluxDB-Client-Simple>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2020 by Arnaud (Arhuman) ASSAD.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.


=cut

1;    # End of InfluxDB::Client::Simple
