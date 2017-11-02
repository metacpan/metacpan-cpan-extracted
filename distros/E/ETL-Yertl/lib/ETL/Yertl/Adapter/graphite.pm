package ETL::Yertl::Adapter::graphite;
our $VERSION = '0.037';
# ABSTRACT: Adapter to read/write from Graphite time series database

#pod =head1 SYNOPSIS
#pod
#pod     my $db = ETL::Yertl::Adapter::graphite->new( 'graphite://localhost:8086' );
#pod     my @points = $db->read_ts( { metric => 'db.cpu_load.1m' } );
#pod     $db->write_ts( { metric => 'db.cpu_load.1m', value => 1.23 } );
#pod
#pod =head1 DESCRIPTION
#pod
#pod This class allows Yertl to read and write time series from L<the
#pod Graphite time series system|https://graphiteapp.org>. Yertl can write to
#pod Carbon using the "plaintext" protocol, and read from Graphite using its
#pod HTTP API.
#pod
#pod This adapter is used by the L<yts> command.
#pod
#pod =head2 Metric Name Format
#pod
#pod Graphite metrics are paths separated by C<.>, which is the native format
#pod that Yertl supports.
#pod
#pod     yts graphite://localhost foo.bar.baz
#pod     yts graphite://localhost foo.bar
#pod
#pod =head1 SEE ALSO
#pod
#pod L<ETL::Yertl>, L<yts>,
#pod L<Write to Carbon|http://graphite.readthedocs.io/en/latest/feeding-carbon.html>
#pod L<Read from Graphite|http://graphite.readthedocs.io/en/latest/render_api.html>
#pod
#pod =cut

use ETL::Yertl;
use Net::Async::HTTP;
use URI;
use JSON::MaybeXS qw( decode_json );
use List::Util qw( first );
use IO::Async::Loop;
use Time::Piece ();
use Scalar::Util qw( looks_like_number );

#pod =method new
#pod
#pod     my $db = ETL::Yertl::Adapter::graphite->new( 'graphite://localhost' );
#pod     my $db = ETL::Yertl::Adapter::graphite->new( 'graphite://localhost:8080' );
#pod
#pod Construct a new Graphite adapter for the database on the given host and port.
#pod Port is optional and defaults to C<2003> (the Carbon plaintext port) for writing
#pod and C<8080> (the default Graphite HTTP API port) for reading.
#pod
#pod =cut

sub new {
    my $class = shift;

    my %args;
    if ( @_ == 1 ) {
        if ( $_[0] =~ m{://([^:]+)(?::([^/]+))?} ) {
            ($args{host}, my $port ) = ( $1, $2 );
            if ( $port ) {
                @args{qw( http_port write_port )} = ( $port ) x 2;
            }
        }
    }
    else {
        %args = @_;
    }

    die "Host is required" unless $args{host};

    $args{write_port} ||= 2003; # "plaintext" port
    $args{http_port} ||= 8080; # http port

    return bless \%args, $class;
}

sub _loop {
    my ( $self ) = @_;
    return $self->{_loop} ||= IO::Async::Loop->new;
}

sub write_client {
    my ( $self ) = @_;
    return $self->{write_client} ||= $self->_loop->connect(
        socktype => 'stream',
        host => $self->{host},
        service => $self->{write_port},
    )->get;
}

sub http_client {
    my ( $self ) = @_;
    return $self->{http_client} ||= do {
        my $http = Net::Async::HTTP->new;
        $self->_loop->add( $http );
        $http;
    };
}

#pod =method read_ts
#pod
#pod     my @points = $db->read_ts( $query );
#pod
#pod Read a time series from the database. C<$query> is a hash reference
#pod with the following keys:
#pod
#pod =over
#pod
#pod =item metric
#pod
#pod The time series to read. For Graphite, this is a  path separated by dots
#pod (C<.>).
#pod
#pod =item start
#pod
#pod An ISO8601 date/time for the start of the series points to return,
#pod inclusive.
#pod
#pod =item end
#pod
#pod An ISO8601 date/time for the end of the series points to return,
#pod inclusive.
#pod
#pod =item tags
#pod
#pod B<NOTE>: Graphite does not support per-value tags. Using this field will
#pod cause a fatal error.
#pod
#pod =back
#pod
#pod =cut

sub read_ts {
    my ( $self, $query ) = @_;
    die "Tags are not supported by Graphite" if $query->{tags} && keys %{ $query->{tags} };
    my $metric = $query->{ metric };

    my %form = (
        target => $metric,
        format => 'json',
        noNullPoints => 'true',
    );

    if ( $query->{ start } ) {
        $form{ from } = _format_graphite_dt( $query->{start} );
    }
    if ( $query->{ end } ) {
        $form{ until } = _format_graphite_dt( $query->{end} );
    }

    my $url = URI->new( sprintf 'http://%s:%s/render', $self->{host}, $self->{http_port} );
    $url->query_form( %form );

    #; say "Fetching $url";
    my $res = $self->http_client->GET( $url )->get;

    #; say $res->decoded_content;
    if ( $res->is_error ) {
        die sprintf "Error fetching metric '%s': " . $res->decoded_content . "\n", $metric;
    }

    my $result = decode_json( $res->decoded_content );
    my @points;
    for my $series ( @{ $result } ) {
        for my $point ( @{ $series->{datapoints} } ) {
            push @points, {
                metric => $series->{target},
                timestamp => Time::Piece->gmtime( $point->[1] )->datetime,
                value => $point->[0],
            };
        }
    }

    return @points;
}

#pod =method write_ts
#pod
#pod     $db->write_ts( @points );
#pod
#pod Write time series points to the database. C<@points> is an array
#pod of hashrefs with the following keys:
#pod
#pod =over
#pod
#pod =item metric
#pod
#pod The metric to write. For Graphite, this is a path separated by dots
#pod (C<.>).
#pod
#pod =item timestamp
#pod
#pod An ISO8601 timestamp or UNIX epoch time. Optional. Defaults to the
#pod current time.
#pod
#pod =item value
#pod
#pod The metric value.
#pod
#pod =item tags
#pod
#pod B<NOTE>: Graphite does not support per-value tags. Using this field will
#pod cause a fatal error.
#pod
#pod =back
#pod
#pod =cut

sub write_ts {
    my ( $self, @points ) = @_;
    my $sock = $self->write_client;
    for my $point ( @points ) {
        die "Tags are not supported by Graphite" if $point->{tags} && keys %{ $point->{tags} };
        $point->{timestamp} ||= time;
        $point->{timestamp} =~ s/[.]\d+Z?$//; # We do not support nanoseconds
        if ( !looks_like_number( $point->{timestamp} ) ) {
            $point->{timestamp} = Time::Piece->strptime( $point->{timestamp}, '%Y-%m-%dT%H:%M:%S' )->epoch;
        }
        $sock->write(
            join( " ", $point->{metric}, $point->{value}, $point->{timestamp}, )
            . "\n",
        );
    }
    return;
}

#=sub _format_graphite_dt
#
#   my $graphite_dt = _format_graphite_dt( $iso_dt );
#
# Graphite supports two date/time formats: YYYYMMDD and, bizarrely,
# HH:MM_YYYYMMDD
sub _format_graphite_dt {
    my ( $iso ) = @_;
    if ( looks_like_number( $iso ) ) {
        my $t = Time::Piece->new( $iso );
        return sprintf "%s:%s_%s%s%s", $t->hour, $t->min, $t->year, $t->mon, $t->mday;
    }
    if ( $iso =~ /^(\d{4})-?(\d{2})-?(\d{2})$/ ) {
        return join "", $1, $2, $3;
    }
    $iso =~ /^(\d{4})-?(\d{2})-?(\d{2})[T ]?(\d{2}):?(\d{2})/;
    return "$4:$5_$1$2$3";
}

1;

__END__

=pod

=head1 NAME

ETL::Yertl::Adapter::graphite - Adapter to read/write from Graphite time series database

=head1 VERSION

version 0.037

=head1 SYNOPSIS

    my $db = ETL::Yertl::Adapter::graphite->new( 'graphite://localhost:8086' );
    my @points = $db->read_ts( { metric => 'db.cpu_load.1m' } );
    $db->write_ts( { metric => 'db.cpu_load.1m', value => 1.23 } );

=head1 DESCRIPTION

This class allows Yertl to read and write time series from L<the
Graphite time series system|https://graphiteapp.org>. Yertl can write to
Carbon using the "plaintext" protocol, and read from Graphite using its
HTTP API.

This adapter is used by the L<yts> command.

=head2 Metric Name Format

Graphite metrics are paths separated by C<.>, which is the native format
that Yertl supports.

    yts graphite://localhost foo.bar.baz
    yts graphite://localhost foo.bar

=head1 METHODS

=head2 new

    my $db = ETL::Yertl::Adapter::graphite->new( 'graphite://localhost' );
    my $db = ETL::Yertl::Adapter::graphite->new( 'graphite://localhost:8080' );

Construct a new Graphite adapter for the database on the given host and port.
Port is optional and defaults to C<2003> (the Carbon plaintext port) for writing
and C<8080> (the default Graphite HTTP API port) for reading.

=head2 read_ts

    my @points = $db->read_ts( $query );

Read a time series from the database. C<$query> is a hash reference
with the following keys:

=over

=item metric

The time series to read. For Graphite, this is a  path separated by dots
(C<.>).

=item start

An ISO8601 date/time for the start of the series points to return,
inclusive.

=item end

An ISO8601 date/time for the end of the series points to return,
inclusive.

=item tags

B<NOTE>: Graphite does not support per-value tags. Using this field will
cause a fatal error.

=back

=head2 write_ts

    $db->write_ts( @points );

Write time series points to the database. C<@points> is an array
of hashrefs with the following keys:

=over

=item metric

The metric to write. For Graphite, this is a path separated by dots
(C<.>).

=item timestamp

An ISO8601 timestamp or UNIX epoch time. Optional. Defaults to the
current time.

=item value

The metric value.

=item tags

B<NOTE>: Graphite does not support per-value tags. Using this field will
cause a fatal error.

=back

=head1 SEE ALSO

L<ETL::Yertl>, L<yts>,
L<Write to Carbon|http://graphite.readthedocs.io/en/latest/feeding-carbon.html>
L<Read from Graphite|http://graphite.readthedocs.io/en/latest/render_api.html>

=head1 AUTHOR

Doug Bell <preaction@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Doug Bell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
