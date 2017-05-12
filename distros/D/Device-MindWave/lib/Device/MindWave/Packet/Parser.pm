package Device::MindWave::Packet::Parser;

use strict;
use warnings;

use Device::MindWave::Packet::Dongle::HeadsetFound;
use Device::MindWave::Packet::Dongle::HeadsetNotFound;
use Device::MindWave::Packet::Dongle::HeadsetDisconnected;
use Device::MindWave::Packet::Dongle::RequestDenied;
use Device::MindWave::Packet::Dongle::StandbyMode;
use Device::MindWave::Packet::Dongle::ScanMode;
use Device::MindWave::Packet::ThinkGear;

my %PACKET_MAP = (
    'HeadsetFound'        => [ 0xD0 ],
    'HeadsetNotFound'     => [ 0xD1 ],
    'HeadsetDisconnected' => [ 0xD2 ],
    'RequestDenied'       => [ 0xD3 ],
    'StandbyMode'         => [ 0xD4, 0x01, 0x00 ],
    'ScanMode'            => [ 0xD4, 0x01, 0x01 ],
);

sub new
{
    my $class = shift;
    my $self = {};
    bless $self, $class;
    return $self;
}

sub parse
{
    my ($self, $bytes) = @_;

    PACKET: for my $packet (keys %PACKET_MAP) {
        my $match_bytes = $PACKET_MAP{$packet};
        for (my $i = 0; $i < @{$match_bytes}; $i++) {
            if ($bytes->[$i] != $match_bytes->[$i]) {
                next PACKET;
            }
        }
        my $pkg = "Device::MindWave::Packet::Dongle::".$packet;
        return $pkg->new($bytes, 0);
    }

    return Device::MindWave::Packet::ThinkGear->new($bytes, 0);
}

1;

__END__

=head1 NAME

Device::MindWave::Packet::Parser

=head1 DESCRIPTION

Provides for parsing packet payloads and returning appropriate
instances of L<Device::MindWave::Packet> implementations.

=head1 CONSTRUCTOR

=over 4

=item B<new>

Returns a new instance of L<Device::MindWave::Packet::Parser>.

=back

=head1 PUBLIC METHODS

=over 4

=item B<parse>

Takes the packet payload as an arrayref of bytes as its single
argument. Returns a L<Device::MindWave::Packet> object representing
the packet.

The packet payload includes all the packet's data, except for the two
initial synchronisation bytes, the packet length byte and the final
checksum byte.

=back

=cut
