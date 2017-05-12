use strict;
use warnings;

package Measure::Everything::Adapter::InfluxDB::UDP;
# ABSTRACT: A Measure::Everything adapter to feed InfluxDB through UDP.
$Measure::Everything::Adapter::InfluxDB::UDP::VERSION = '0.01';

use IO::Socket::INET;

use base qw(Measure::Everything::Adapter::Base);
use InfluxDB::LineProtocol qw(data2line);

sub init {
    my $self = shift;
    my %config = @_;
    my $socket = IO::Socket::INET->new(
        PeerAddr  => $config{host} || $config{addr} || 'localhost',
        PeerPort  => $config{port} || 8089,
        Proto     => 'udp',
        ReuseAddr => 1,
    );
    $self->{socket} = $socket;
    return $self;
}

sub write {
    my $self = shift;
    my $line = data2line(@_);
    return $self->{socket}->send( $line );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Measure::Everything::Adapter::InfluxDB::UDP - A Measure::Everything adapter to feed InfluxDB through UDP.

=head1 VERSION

version 0.01

=head1 SYNOPSIS

    Measure::Everything::Adapter->set( 'InfluxDB::UDP', 
      host => '127.0.0.1', 
      port => 8089
    );

=head1 DESCRIPTION

Reporting metrics over UDP is ideal in real-time environments where
performance is preferred over reliability. This adapter allows you to write
stats to an
L<InfluxDB UDP listener|https://docs.influxdata.com/influxdb/v0.10/write_protocols/udp/>.

By definition, delivery of UDP packets is not guaranteed, and the presence of
the InfluxDB listener is not verified at all. It is your responsability to
configure the listener properly and to provide a persistent, reliable and
secure "line of sight" to an UDP listener. Your stats will be discarded
silently otherwise.

=head1 SEE ALSO

=over 4

=item *

L<Measure::Everything>, of course

=item *

L<https://docs.influxdata.com/influxdb/v0.10/write_protocols/udp/> Configure InfluxDB to support writes over UDP.

=back

=head1 AUTHOR

Javier Arturo Rodriguez <javier@rodriguez.org.mx>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Javier Arturo Rodriguez.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
