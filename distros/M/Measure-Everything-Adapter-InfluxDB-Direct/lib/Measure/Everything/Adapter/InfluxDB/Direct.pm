package Measure::Everything::Adapter::InfluxDB::Direct;
use strict;
use warnings;

our $VERSION = '1.000';

# ABSTRACT: Send stats directly to InfluxDB via http

use base qw(Measure::Everything::Adapter::Base);
use InfluxDB::LineProtocol qw(data2line);
use Hijk;
use MIME::Base64 qw/encode_base64/;
use Log::Any qw($log);
use Try::Tiny;

sub init {
    my $self = shift;

    die __PACKAGE__.' required param "host" missing!' unless $self->{host};
    die __PACKAGE__.' required param "db" missing!' unless $self->{db};

    my %args = (
        method       => "POST",
        host         => $self->{host},
        port         => $self->{port} || 8086,
        path         => "/write",
        query_string => "db=" . $self->{db},
    );

    if ($self->{username} && $self->{password}) {
        my $base64 = encode_base64( join( ":", $self->{username}, $self->{password} ) );
        chomp($base64);
        $args{Authorization} = "Basic $base64";
    }

    $self->{_fixed_args} = \%args;
}

sub write {
    my $self = shift;
    my $line = data2line(@_);

    try {
        my $res = Hijk::request({
            %{ $self->{_fixed_args} },
            body         => $line,
        });
        if ( $res->{status} != 204 ) {
            $log->warnf("Could not send line %s to influx: %s",$line, $res->{body});
        }
    }
    catch {
        $log->errorf("Could not reach influx for line %s : %s",$line, $_);
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Measure::Everything::Adapter::InfluxDB::Direct - Send stats directly to InfluxDB via http

=head1 VERSION

version 1.000

=head1 SYNOPSIS

    Measure::Everything::Adapter->set( 'InfluxDB::Direct',
        host => 'influx.example.com',
        port => 8086,
        db   => 'conversions',
    );

    use Measure::Everything qw($stats);
    $stats->write('metric', 1);

=head1 DESCRIPTION

Send stats directly to L<InfluxDB|https://influxdb.com/>. No buffering
whatsoever, so there is one HTTP request per call to
C<< $stats->write >>. This might be a bad idea.

If a request fails, it will be logged using C<Log::Any>, but no
further error handling is done. The metric will be lost.

=head3 OPTIONS

Set these options when setting your adapter via C<< Measure::Everything::Adapter->set >>

=over

=item * host

Required. Name of the host where your InfluxDB is running.

=item * db

Required. Name of the database you want to use.

=item * port

Optional. Defaults to 8086. Port your InfluxDB is listening on.

=item * username

Optional. May be required by your InfluxDB.

=item * password

Optional. May be required by your InfluxDB.

C<username> and C<password> are sent in the C<Authorization> header as C<Basic> auth in C<base64> encoding.

=back

=head1 AUTHOR

Thomas Klausner <domm@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Thomas Klausner.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
