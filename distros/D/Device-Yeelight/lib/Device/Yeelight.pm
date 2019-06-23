package Device::Yeelight;

use 5.026;
use utf8;
use strict;
use warnings;

use Carp;
use IO::Select;
use IO::Socket::Multicast;
use Device::Yeelight::Light;

=encoding utf8
=head1 NAME

Device::Yeelight - Controller for Yeelight smart devices

=head1 VERSION

Version 0.11

=cut

our $VERSION = '0.11';

=head1 SYNOPSIS

This Perl module implements local device discovery via Yeeling specific SSDP
protocol and sending commands via control protocol in the JSON format.

Device::Yeelight module provides base class for detecting Yeelight devices.

    use Device::Yeelight;

    my $yeelight = Device::Yeelight->new();
    my @devices = @{$yeelight->search()};
    foreach my $device (@devices) {
        my %props = %{$device->get_prop(qw/power/)};
        say "The light is $props{power}";
        $device->set_power('on', 'smooth', 1000);
    }
    ...

=head1 SUBROUTINES/METHODS

=head2 new

Creates new Yeelight controller.

=cut

sub new {
    my $class = shift;
    my $data  = {
        address => '239.255.255.250',
        port    => 1982,
        timeout => 3,
        devices => [],
    };
    return bless( $data, $class );
}

=head2 search

Sends search request message and waits for devices response.

=cut

sub search {
    my $self = shift;

    my $socket = IO::Socket::Multicast->new(
        PeerAddr  => $self->{address},
        PeerPort  => $self->{port},
        Proto     => "udp",
        ReuseAddr => 1,
    ) or croak $!;
    $socket->mcast_loopback(0);

    my $listen = IO::Socket::INET->new(
        LocalPort => $socket->sockport,
        Proto     => 'udp',
        ReuseAddr => 1,
    ) or croak $!;
    my $sel = IO::Select->new($listen);

    my $query = <<EOQ;
M-SEARCH * HTTP/1.1\r
HOST: $self->{address}:$self->{port}\r
MAN: "ssdp:discover"\r
ST: wifi_bulb\r
EOQ
    $socket->mcast_send( $query, "$self->{address}:$self->{port}" ) or croak $!;
    $socket->close;

    my @ready;
    while ( @ready = $sel->can_read( $self->{timeout} ) ) {
        break unless @ready;
        foreach my $fh (@ready) {
            my $data;
            $fh->recv( $data, 4096 );
            $self->parse_response($data) if $data =~ m#^HTTP/1\.1 200 OK\r\n#;
        }
    }
    $listen->close;
    return $self->{devices};
}

=head2 parse_response

Parse response message from Yeelight device.

=cut

sub parse_response {
    my $self = shift;
    my ($data) = @_;

    my $device;
    ( $device->{$_} ) = ( $data =~ /$_: (.*)\r\n/i )
      foreach (
        qw/location id model fw_ver support power bright color_mode ct rgb hue sat name/
      );
    $device->{support} = [ split( ' ', $device->{support} ) ]
      if defined $device->{support};

    push @{ $self->{devices} }, Device::Yeelight::Light->new(%$device)
      unless grep { $device->{id} eq $_->{id} } @{ $self->{devices} };
}

=head1 AUTHOR

Jan Baier, C<< <jan.baier at amagical.net> >>

=head1 SEE ALSO

L<Device::Yeelight::Light>

=head1 BUGS

Please report any bugs or feature requests via
L<https://github.com/baierjan/Device-Yeelight>

=head1 LICENSE AND COPYRIGHT

Copyright 2019 Jan Baier.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.

=cut

1;    # End of Device::Yeelight
