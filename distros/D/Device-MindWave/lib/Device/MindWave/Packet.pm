package Device::MindWave::Packet;

use strict;
use warnings;

sub new
{
    die "Abstract method 'new' not implemented.";
}

sub as_string
{
    die "Abstract method 'as_string' not implemented.";
}

sub as_bytes
{
    die "Abstract method 'as_bytes' not implemented.";
}

1;

__END__

=head1 NAME

Device::MindWave::Packet

=head1 DESCRIPTION

Interface module for MindWave packets.

=head1 PUBLIC METHODS

=over 4

=item B<new>

Takes a byte arrayref and an index into that arrayref as its
arguments, representing the data of the packet (exclusive of the
synchronisation bytes and the checksum byte). Returns a new instance
of the relevant packet. Dies on error.

=item B<as_string>

Returns the packet's details as a human-readable string.

=item B<as_bytes>

Returns the packet's payload as an arrayref of bytes.

=item B<length>

Returns the number of bytes in the packet's payload.

=back

=cut
