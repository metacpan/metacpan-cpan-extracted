package Measure::Everything::Adapter::InfluxDB::TCP;

# ABSTRACT: Send stats to Influx via TCP using Telegraf
our $VERSION = '1.004'; # VERSION

use strict;
use warnings;

use base qw(Measure::Everything::Adapter::Base);
use InfluxDB::LineProtocol qw();
use IO::Socket::INET;
use Log::Any qw($log);

sub init {
    my $self = shift;

    my $host = $self->{host} || 'localhost';
    my $port = $self->{port} || 8094;
    my $precision = $self->{precision} ? 'precision='.$self->{precision} : '';
    InfluxDB::LineProtocol->import('data2line', $precision);

    my $socket = IO::Socket::INET->new(
        PeerAddr => $host,
        PeerPort => $port,
        Proto    => 'tcp',
    );
    if ($socket) {
        $self->{socket} = $socket;
    }
    else {
        $log->errorf(
            "Cannot set up TCP socket on %s:%s, no stats will be recorded!",
            $host, $port );
    }
}

sub write {
    my $self = shift;
    my $line = data2line(@_);

    if ($self->{socket} ) {
        local $SIG{'PIPE'} = sub { die "SIGPIPE" };
        eval {
            $self->{socket}->send($line."\n");
        };
        return unless $@;
        $log->errorf("write error %s", $@);
    }
    undef $self->{socket};
    $self->init;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Measure::Everything::Adapter::InfluxDB::TCP - Send stats to Influx via TCP using Telegraf

=head1 VERSION

version 1.004

=head1 SYNOPSIS

    Measure::Everything::Adapter->set( 'InfluxDB::TCP',
        host => 'localhost',   # default
        port => 8094,          # default
        precision => 'ms'      # default is ns (nanoseconds)
    );

    use Measure::Everything qw($stats);
    $stats->write('metric', 1);

=head1 DESCRIPTION

Send stats via TCP to a
L<Telegraf|https://influxdata.com/time-series-platform/telegraf/>
service, which will forward them to L<InfluxDB|https://influxdb.com/>.
No buffering whatsoever, so there is one TCP request per call to
C<< $stats->write >>. This might be a bad idea.

If TCP listener is not available when C<set> is called, an error will
be written via C<Log::Any>. C<write> will silently discard all
metrics, no data will be sent to Telegraf / InfluxDB.

If a request fails no further error handling is done. The metric will
be lost.

=head3 OPTIONS

Set these options when setting your adapter via C<< Measure::Everything::Adapter->set >>

=over

=item * host

Name of the host where your Telegraf is running. Default to C<localhost>.

=item * port

Port your Telegraf is listening. Defaults to C<8094>.

=item * precision

A valid InfluxDB precision. Default to undef (i.e. nanoseconds). Do
not set it if you're talking with Telegraf, as Telegraf will always
interpret the timestamp as nanoseconds.

=back

=head3 Handling server disconnect

C<Measure::Everything::Adapter::InfluxDB::TCP> installs a C<local>
handler for C<SIGPIPE> to handle a disconnect from the server. If the
server goes away, C<InfluxDB::TCP> will try to reconnect every time a
stat is written. As of now (1.003), this behavior is hardcoded.

You might want to check out
L<Measure::Everything::Adapter::InfluxDB::UDP> for an even lossier,
but more failure tolerant way to send your stats.

See also L<this blog post|http://domm.plix.at/perl/2016_09_too_dumb_for_tcp.html>, where
HJansen provided the correct solution to my problem. Nicholas Clark
also pointed me in the right direction (in #Austria.pm)

=head3 Example

See L<example/send_metrics.pl> for a working example.

=head1 AUTHOR

Thomas Klausner <domm@plix.at>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Thomas Klausner.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
