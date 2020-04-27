package InfluxDB::Client::Simple;

use 5.006;
use strict;
use warnings;

use Carp;
use IO::Socket::INET;
use JSON::MaybeXS;
use LWP::UserAgent;
use URI;

=head1 NAME

InfluxDB::Client::Simple - The lightweight InfluxDB client

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

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
    $client = InfluxDB::Client::Simple->new( host => 'server.address.com', port => 8089, protocol => 'udp' ) or die "Can't instantiate client";

    # UDP allows only write()
    $result = $client->write("testing,host=containment,repo=cadi-libs,file=testfile statement=47,pod=89", database => 'grafana');

=head1 WHY

In its current state this module offers few additional features over InfluxDB::HTTP (from which it's derived) 

The only reasons why you would use this module are:
=over

=item *
Less dependencies (no Object::Result and its dependencies)

=item *
You want to use UDP protocol for writing (WIP)

=back

=cut

=head1 SUBROUTINES/METHODS

=head2 new ( [%options] )

Constructor.
%otions is an hash with the following keys:

=over

=item*
host - Server hostname (default: 'localhost')

=item*
port - Server port (default: 8086)

=item*
timeout - Timeout value in seconds (default: 180)

=item*
protocol - Transport protocol (default: 'tcp')

=back

=cut

sub new {
    my $class = shift;
    my %args = ( host     => 'localhost',
                 port     => 8086,
                 timeout  => 180,
                 protocol => 'tcp',
                 @_,
    );
    my ( $host, $port, $timeout, $protocol ) = map { lc } @args{ 'host', 'port', 'timeout', 'protocol' };

    my $self = { host => $host,
                 port => $port,
                 protocol => $protocol
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
        ) || die("Can't open socket: $@");
        $self->{udp} = $socket;
    }

    bless $self, $class;

    return $self;
}

=head2 ping()

Check the server connectivity.

Returns an hashref which evaluates to true if the connection is ok and to false otherwise.
The hashref has the following keys:

=over

=item*
raw - The raw response from the server

=item*
error - The error message returned by the server (empty on success)

=item*
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

=head2 write

=cut

sub write {
    my $self        = shift;
    my $measurement = shift;
    my %args        = @_;
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
                 data  => 0,
        };
    }

    return { raw   => $response,
             error => undef,
             data  => 1,
    };

  } else {
  # Udp send
  my $bytes = $self->{udp}->send($measurement);
        return { raw   => undef,
                 error => undef,
                 data  => $bytes?1:0,
        };
  }
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

1;

=head1 AUTHOR

Arnaud (Arhuman) ASSAD, C<< <aassad at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-influxdb-client at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=InfluxDB-Client-Simple>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SEE ALSO

This module is derived from InfluxDB::HTTP.

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
