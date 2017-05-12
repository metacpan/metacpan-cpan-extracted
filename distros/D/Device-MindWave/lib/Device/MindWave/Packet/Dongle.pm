package Device::MindWave::Packet::Dongle;

use strict;
use warnings;

use base qw(Device::MindWave::Packet);

sub code
{
    die "Abstract method 'code' not implemented.";
}

1;

__END__

=head1 NAME

Device::MindWave::Packet::Dongle

=head1 DESCRIPTION

Interface module for MindWave Dongle Communication Protocol packets.
See
L<http://developer.neurosky.com/docs/lib/exe/fetch.php?media=app_notes:mindwave_rf_external.pdf>
for documentation on this type of packet.

=head1 PUBLIC METHODS

=over 4

=item B<code>

Returns the packet's ThinkGear code, as per page 8 of the
documentation, except that an artificial code of 0xD5 is used to
denote 'Scan' mode. This allows 'Standby' and 'Scan' to be
distinguished without calling C<isa>.

=back

=cut
