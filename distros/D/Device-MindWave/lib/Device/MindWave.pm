package Device::MindWave;

use strict;
use warnings;

use Device::SerialPort;
use Device::MindWave::Utils qw(checksum
                               packet_isa);
use Device::MindWave::Packet::Parser;

our $VERSION = '0.02';
our $_NO_SLEEP = 0;

sub new
{
    my $class = shift;
    my %args = @_;

    my $port;
    if (exists $args{'fh'}) {
        $port = $args{'fh'};
    } elsif (exists $args{'port'}) {
        $port = Device::SerialPort->new($args{'port'});
        if (not $port) {
            die "Cannot open ".($args{'port'}).": $!";
        }
        $port->baudrate(115200);
        $port->user_msg(0);
        $port->parity("even");
        $port->databits(8);
        $port->stopbits(1);
        $port->handshake("none");
        $port->read_const_time(1000);
        $port->read_char_time(5);
        $port->write_settings();
    } else {
        die "Either 'fh' or 'port' must be provided.";
    }

    my $self = { port   => $port,
                 is_fh  => (exists $args{'fh'}),
                 parser => Device::MindWave::Packet::Parser->new() };
    bless $self, $class;
    return $self;
}

sub _sleep
{
    if ($_NO_SLEEP) {
        return 1;
    }
    sleep($_[0]);
    return 1;
}

sub _read
{
    my ($self, $len) = @_;

    my $buf;
    my $bytes;
    if ($self->{'is_fh'}) {
        $bytes = $self->{'port'}->read($buf, $len);
    } else {
        $buf = $self->{'port'}->read($len);
        $bytes = length $buf;
    }

    if ($len != (length $buf)) {
        die "Received too few characters on read ($bytes instead of $len).";
    }

    return $buf;
}

sub _write
{
    my ($self, $data) = @_;

    if ($self->{'is_fh'}) {
        $self->{'port'}->write($data, (length $data), 0);
    } else {
        $self->{'port'}->write($data);
    }

    return 1;
}

sub _write_bytes
{
    my ($self, $bytes) = @_;

    my $data = join '', map { chr($_) } @{$bytes};
    return $self->_write($data);
}

sub _to_headset_id_bytes
{
    my ($upper, $lower) = @_;

    if ($upper > 255) {
        $lower = $upper & 0xFF;
        $upper = ($upper >> 8) & 0xFF;
    }

    return ($upper, $lower);
}

sub _wait_for_standby
{
    my ($self) = @_;

    my $tries = 15;
    while ($tries--) {
        my $packet = $self->read_packet();
        if (packet_isa($packet, 'Dongle::StandbyMode')) {
            return 1;
        }
        _sleep(1);
    }

    die "Timed out waiting for standby packet (15s).";
}

sub connect_nb
{
    my ($self, $upper, $lower) = @_;

    ($upper, $lower) = _to_headset_id_bytes($upper, $lower);
    $self->_write_bytes([ 0xC0, $upper, $lower ]);

    return 1;
}

sub connect
{
    my ($self, @args) = @_;

    $self->_wait_for_standby();
    $self->connect_nb(@args);

    my $tries = 15;
    while ($tries--) {
        my $packet = $self->read_packet();
        if (packet_isa($packet, 'Dongle::HeadsetFound')) {
            return 1;
        } elsif (packet_isa($packet, 'Dongle::HeadsetNotFound')) {
            die "Headset not found.";
        } elsif (packet_isa($packet, 'Dongle::RequestDenied')) {
            die "Request denied by dongle.";
        }
        _sleep(1);
    }

    die "Unable to connect to headset.";
}

sub auto_connect_nb
{
    my ($self) = @_;

    $self->_write_bytes([ 0xC2 ]);

    return 1;
}

sub auto_connect
{
    my ($self) = @_;

    $self->_wait_for_standby();
    $self->auto_connect_nb();

    my $tries = 15;
    while ($tries--) {
        my $packet = $self->read_packet();
        if (packet_isa($packet, 'Dongle::HeadsetFound')) {
            return 1;
        } elsif (packet_isa($packet, 'Dongle::HeadsetNotFound')) {
            die "No headset was found.";
        } elsif (packet_isa($packet, 'Dongle::RequestDenied')) {
            die "Request denied by dongle.";
        }
        _sleep(1);
    }

    die "Unable to connect to any headset.";
}

sub disconnect_nb
{
    my ($self) = @_;

    $self->_write_bytes([ 0xC1 ]);

    return 1;
}

sub disconnect
{
    my ($self) = @_;

    $self->disconnect_nb();

    my $tries = 15;
    my $got_error = 0;
    while ($tries--) {
        # Allow one error during packet read, since there will
        # occasionally be a packet length mismatch problem.
        my $packet = eval { $self->read_packet() };
        if (my $error = $@) {
            if ($got_error == 1) {
                die $error;
            } else {
                $got_error = 1;
            }
        }
        # Flush the remaining ThinkGear packets.
        if (packet_isa($packet, 'ThinkGear')) {
            $tries++;
            next;
        }
        if (packet_isa($packet, 'Dongle::HeadsetDisconnected')
                or packet_isa($packet, 'Dongle::StandbyMode')) {
            # Occasionally, no HeadsetDisconnected packet will be
            # returned, hence the check for standby mode.
            return 1;
        } elsif (packet_isa($packet, 'Dongle::RequestDenied')) {
            die "Request denied by dongle.";
        }
        _sleep(1);
    }

    die "Unable to disconnect from headset.";
}

sub read_packet
{
    my ($self) = @_;

    my $tries = 1001;
    my $prev_byte = 0;
    while (--$tries) {
        my $length = 0;
        my $byte = $self->_read(1);
        if (((ord $prev_byte) == 0xAA) and ((ord $byte) == 0xAA)) {
            last;
        } else {
            $prev_byte = $byte;
        }
    }

    if ($tries == 0) {
        die "Unable to find synchronisation bytes (read 1000 bytes).";
    }

    my $len = ord $self->_read(1);
    if ($len > 169) {
        die "Length byte has invalid value ($len): expected 0-169.";
    }

    my $data = $self->_read($len);
    my @bytes = map { ord $_ } split //, $data;

    my $checksum = ord $self->_read(1);
    my $checksum_actual = checksum(\@bytes);

    if ($checksum != $checksum_actual) {
        goto &read_packet;
    }

    return $self->{'parser'}->parse(\@bytes);
}

1;

__END__

=head1 NAME

Device::MindWave

=head1 SYNOPSIS

    use Device::MindWave;

    my $mw = Device::MindWave->new(port => '/dev/ttyUSB0');
    $mw->auto_connect();
    while (my $packet = $mw->read_packet()) {
        print $packet->as_string(),"\n";
    }
    ...

=head1 DESCRIPTION

Provides for connecting to and disconnecting from a NeuroSky MindWave
headset, as well as reading and parsing the data that it produces.

=head1 CONSTRUCTOR

=over 4

=item B<new>

Arguments (hash):

=over 8

=item port

The port name (e.g. 'COM4', '/dev/ttyUSB0').

=item fh

An object representing the MindWave. Must implement C<read> and
C<write>, as per L<IO::Handle>. This library will not reattempt
C<read>s on the filehandle if fewer characters than requested are
returned.

=back

One of C<port> and C<fh> must be provided. Returns a new instance of
L<Device::MindWave>.

=back

=head1 PUBLIC METHODS

=over 4

=item B<connect_nb>

Takes a headset ID as its argument, sends a message to the dongle to
connect to that headset, and returns immediately. The caller must use
C<read_packet> to determine whether the connection was made
successfully.

The headset ID can be provided as either one 16-bit number or two
8-bit numbers in network byte order. For example, if the headset has
the ID '12AB', then the argument can be C<0x12AB>, or C<0x12> and
C<0xAB>. (The identifier is printed at the bottom of the label inside
the battery compartment.)

=item B<connect>

As per C<connect_nb>, except that it blocks until either the
connection is successfully established or an error occurs (e.g.
request denied by dongle due to existing connection). Dies on error.

=item B<auto_connect_nb>

As per C<connect_nb>, except that it does not take any arguments and
the dongle message is such that it will attempt to connect to any
headset within range.

=item B<auto_connect>

As per C<connect>, except for C<auto_connect_nb>.

=item B<disconnect_nb>

Sends a message to the dongle to disconnect from the headset. The
caller must use C<read_packet> to determine whether the connection was
closed successfully.

=item B<disconnect>

As per C<disconnect_nb>, except that it blocks until either the
connection is closed or an error occurs (e.g. request denied by dongle
because it is not currently connected to a headset). Dies on error.

=item B<read_packet>

Attempts to parse and return a packet from the dongle. The returned
packet objects implement L<Device::MindWave::Packet>. If a checksum
error is encountered, then the read operation is retried, but all
other errors will result in a die. By default, the read timeout is one
second.

When not connected to a headset, this method will return dongle
communication protocol packets. Each of these implements the
L<Device::MindWave::Packet::Dongle> interface. When connected to a
headset, this method will return ThinkGear packets: see
L<Device::MindWave::Packet::ThinkGear>.

=back

=head1 AUTHOR

Tom Harrison, C<< <tomhrr at cpan.org> >>

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT AND LICENCE

Copyright (C) 2014 Tom Harrison

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
