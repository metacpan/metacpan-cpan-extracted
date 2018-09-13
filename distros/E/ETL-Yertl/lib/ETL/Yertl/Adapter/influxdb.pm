package ETL::Yertl::Adapter::influxdb;
our $VERSION = '0.042';
# ABSTRACT: Adapter to read/write from InfluxDB time series database

#pod =head1 SYNOPSIS
#pod
#pod     my $db = ETL::Yertl::Adapter::influxdb->new( 'influxdb://localhost:8086' );
#pod     my @points = $db->read_ts( { metric => 'db.cpu_load.1m' } );
#pod     $db->write_ts( { metric => 'db.cpu_load.1m', value => 1.23 } );
#pod
#pod =head1 DESCRIPTION
#pod
#pod This class allows Yertl to read and write time series from L<the InfluxDB
#pod time series database|https://www.influxdata.com>.
#pod
#pod This adapter is used by the L<yts> command.
#pod
#pod =head2 Metric Name Format
#pod
#pod InfluxDB has databases, metrics, and fields. In Yertl, the time series
#pod is identified by joining the database, metric, and field with periods (C<.>).
#pod The field is optional, and defaults to C<value>.
#pod
#pod     # Database "foo", metric "bar", field "baz"
#pod     yts influxdb://localhost foo.bar.baz
#pod
#pod     # Database "foo", metric "bar", field "value"
#pod     yts influxdb://localhost foo.bar
#pod
#pod =head1 SEE ALSO
#pod
#pod L<ETL::Yertl>, L<yts>,
#pod L<Reading data from InfluxDB|https://docs.influxdata.com/influxdb/v1.3/guides/querying_data/>,
#pod L<Writing data to InfluxDB|https://docs.influxdata.com/influxdb/v1.3/guides/writing_data/>,
#pod L<InfluxDB Query language|https://docs.influxdata.com/influxdb/v1.3/query_language/data_exploration/>
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
#pod     my $db = ETL::Yertl::Adapter::influxdb->new( 'influxdb://localhost' );
#pod     my $db = ETL::Yertl::Adapter::influxdb->new( 'influxdb://localhost:8086' );
#pod
#pod Construct a new InfluxDB adapter for the database on the given host and port.
#pod Port is optional and defaults to C<8086>.
#pod
#pod =cut

sub new {
    my $class = shift;

    my %args;
    if ( @_ == 1 ) {
        if ( $_[0] =~ m{://([^:]+)(?::([^/]+))?} ) {
            ( $args{host}, $args{port} ) = ( $1, $2 );
        }
    }
    else {
        %args = @_;
    }

    die "Host is required" unless $args{host};

    $args{port} ||= 8086;

    return bless \%args, $class;
}

sub _loop {
    my ( $self ) = @_;
    return $self->{_loop} ||= IO::Async::Loop->new;
}

sub client {
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
#pod The time series to read. For InfluxDB, this is the database, metric, and
#pod field separated by dots (C<.>). Field defaults to C<value>.
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
#pod An optional hashref of tags. If specified, only points matching all of
#pod these tags will be returned.
#pod
#pod =back
#pod
#pod =cut

sub read_ts {
    my ( $self, $query ) = @_;
    my $metric = $query->{ metric };
    ( my $db, $metric, my $field ) = split /\./, $metric;
    $field ||= "value";

    my $q = sprintf 'SELECT "%s" FROM "%s"', $field, $metric;
    my @where;
    my $tags = $query->{ tags };
    if ( $tags && keys %$tags ) {
        push @where, map { sprintf q{"%s"='%s'}, $_, $tags->{ $_ } } keys %$tags;
    }
    if ( my $start = $query->{start} ) {
        push @where, qq{time >= '$start'};
    }
    if ( my $end = $query->{end} ) {
        push @where, qq{time <= '$end'};
    }
    if ( @where ) {
        $q .= ' WHERE ' . join " AND ", @where;
    }

    my $url = URI->new( sprintf 'http://%s:%s/query', $self->{host}, $self->{port} );
    $url->query_form( db => $db, q => $q );

    #; say "Fetching $url";
    my $res = $self->client->GET( $url )->get;

    #; say $res->decoded_content;
    if ( $res->is_error ) {
        die sprintf "Error fetching metric '%s': " . $res->decoded_content . "\n", $metric;
    }

    my $result = decode_json( $res->decoded_content );
    my @points;
    for my $series ( map @{ $_->{series} }, @{ $result->{results} } ) {
        my $time_i = first { $series->{columns}[$_] eq 'time' } 0..$#{ $series->{columns} };
        my $value_i = first { $series->{columns}[$_] eq $field } 0..$#{ $series->{columns} };

        push @points, map {
            +{
                metric => join( ".", $db, $series->{name}, ( $field ne 'value' ? ( $field ) : () ) ),
                timestamp => $_->[ $time_i ],
                value => $_->[ $value_i ],
            }
        } @{ $series->{values} };
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
#pod The metric to write. For InfluxDB, this is the database, metric,
#pod and field separated by dots (C<.>). Field defaults to C<value>.
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
#pod =back
#pod
#pod =cut

sub write_ts {
    my ( $self, @points ) = @_;

    my %db_lines;
    for my $point ( @points ) {
        my ( $db, $metric, $field ) = split /\./, $point->{metric};
        my $tags = '';
        if ( $point->{tags} ) {
            $tags = join ",", '', map { join "=", $_, $point->{tags}{$_} } keys %{ $point->{tags} };
        }

        my $ts = '';
        if ( my $epoch = $point->{timestamp} || time ) {
            if ( !looks_like_number( $epoch ) ) {
                $epoch =~ s/[.]\d+Z?$//; # We do not support nanoseconds
                $epoch = Time::Piece->strptime( $epoch, '%Y-%m-%dT%H:%M:%S' )->epoch;
            }
            $ts = " " . ( $epoch * 10**9 );
        }

        push @{ $db_lines{ $db } }, sprintf '%s%s %s=%s%s',
            $metric, $tags, $field || "value",
            $point->{value}, $ts;
    }

    for my $db ( keys %db_lines ) {
        my @lines = @{ $db_lines{ $db } };
        my $body = join "\n", @lines;
        my $url = URI->new( sprintf 'http://%s:%s/write?db=%s', $self->{host}, $self->{port}, $db );
        my $res = $self->client->POST( $url, $body, content_type => 'text/plain' )->get;
        if ( $res->is_error ) {
            my $result = decode_json( $res->decoded_content );
            die "Error writing metric '%s': $result->{error}\n";
        }
    }

    return;
}

1;

__END__

=pod

=head1 NAME

ETL::Yertl::Adapter::influxdb - Adapter to read/write from InfluxDB time series database

=head1 VERSION

version 0.042

=head1 SYNOPSIS

    my $db = ETL::Yertl::Adapter::influxdb->new( 'influxdb://localhost:8086' );
    my @points = $db->read_ts( { metric => 'db.cpu_load.1m' } );
    $db->write_ts( { metric => 'db.cpu_load.1m', value => 1.23 } );

=head1 DESCRIPTION

This class allows Yertl to read and write time series from L<the InfluxDB
time series database|https://www.influxdata.com>.

This adapter is used by the L<yts> command.

=head2 Metric Name Format

InfluxDB has databases, metrics, and fields. In Yertl, the time series
is identified by joining the database, metric, and field with periods (C<.>).
The field is optional, and defaults to C<value>.

    # Database "foo", metric "bar", field "baz"
    yts influxdb://localhost foo.bar.baz

    # Database "foo", metric "bar", field "value"
    yts influxdb://localhost foo.bar

=head1 METHODS

=head2 new

    my $db = ETL::Yertl::Adapter::influxdb->new( 'influxdb://localhost' );
    my $db = ETL::Yertl::Adapter::influxdb->new( 'influxdb://localhost:8086' );

Construct a new InfluxDB adapter for the database on the given host and port.
Port is optional and defaults to C<8086>.

=head2 read_ts

    my @points = $db->read_ts( $query );

Read a time series from the database. C<$query> is a hash reference
with the following keys:

=over

=item metric

The time series to read. For InfluxDB, this is the database, metric, and
field separated by dots (C<.>). Field defaults to C<value>.

=item start

An ISO8601 date/time for the start of the series points to return,
inclusive.

=item end

An ISO8601 date/time for the end of the series points to return,
inclusive.

=item tags

An optional hashref of tags. If specified, only points matching all of
these tags will be returned.

=back

=head2 write_ts

    $db->write_ts( @points );

Write time series points to the database. C<@points> is an array
of hashrefs with the following keys:

=over

=item metric

The metric to write. For InfluxDB, this is the database, metric,
and field separated by dots (C<.>). Field defaults to C<value>.

=item timestamp

An ISO8601 timestamp or UNIX epoch time. Optional. Defaults to the
current time.

=item value

The metric value.

=back

=head1 SEE ALSO

L<ETL::Yertl>, L<yts>,
L<Reading data from InfluxDB|https://docs.influxdata.com/influxdb/v1.3/guides/querying_data/>,
L<Writing data to InfluxDB|https://docs.influxdata.com/influxdb/v1.3/guides/writing_data/>,
L<InfluxDB Query language|https://docs.influxdata.com/influxdb/v1.3/query_language/data_exploration/>

=head1 AUTHOR

Doug Bell <preaction@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Doug Bell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
