package Device::MindWave::Utils;

use strict;
use warnings;

use List::Util qw(sum);
use Scalar::Util qw(blessed);

use base qw(Exporter);
our @EXPORT_OK = qw(checksum
                    packet_isa
                    packet_to_bytes);

sub checksum
{
    my ($bytes) = @_;

    my $sum = sum(0, @{$bytes});
    my $byte = $sum & 0xFF;
    return ((~$byte) & 0xFF);
}

sub packet_isa
{
    my ($packet, $suffix) = @_;

    return
        ((blessed $packet)
            and ($packet->isa('Device::MindWave::Packet::'.$suffix)));
}

sub packet_to_bytes
{
    my ($packet) = @_;

    my $bytes = $packet->as_bytes();
    my $checksum = checksum($bytes);

    return [ 0xAA, 0xAA, scalar @{$bytes}, @{$bytes}, $checksum ];
}

1;

__END__

=head1 NAME

Device::MindWave::Utils

=head1 DESCRIPTION

Utility functions used in various libraries.

=head1 PUBLIC FUNCTIONS

=over 4

=item B<checksum>

Takes an arrayref of bytes as its single argument. Returns the
checksum of those bytes as an integer. The checksum is calculated by
summing the bytes, taking the lowest eight bits, and returning the
one's complement of that value.

=item B<packet_isa>

Takes an arbitrary object and a packet package name suffix (i.e.
without the beginning 'Device::MindWave::Packet::' part) as its
arguments. Returns a boolean indicating whether the object is a packet
of the relevant type.

=item B<packet_to_bytes>

Takes an instance of an implementation of L<Device::MindWave::Packet>
and returns an arrayref containing the bytes for the packet, including
the synchronisation bytes at the beginning and the checksum byte at
the end.

=back

=cut
