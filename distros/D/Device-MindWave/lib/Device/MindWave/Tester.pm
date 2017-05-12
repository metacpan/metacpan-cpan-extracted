package Device::MindWave::Tester;

use strict;
use warnings;

use IO::File;
use Device::MindWave::Utils qw(packet_to_bytes);

sub new
{
    my $class = shift;
    my $self = { buffer      => IO::File->new_tmpfile(),
                 read_index  => 0,
                 write_index => 0 };
    bless $self, $class;
    return $self;
}

sub push_packet
{
    my ($self, $packet) = @_;

    return $self->push_bytes(packet_to_bytes($packet));
}

sub push_bytes
{
    my ($self, $bytes) = @_;

    $self->{'buffer'}->seek($self->{'write_index'}, 0);
    for my $byte (@{$bytes}) {
        $self->{'buffer'}->syswrite(chr $byte);
        $self->{'write_index'}++;
    }
    $self->{'buffer'}->flush();

    return 1;
}

sub read
{
    my $self = $_[0];

    $self->{'buffer'}->seek($self->{'read_index'}, 0);
    my $bytes = $self->{'buffer'}->read($_[1], $_[2], 0);
    $self->{'read_index'} += $bytes;
    return $bytes;
}

sub write
{
    return 1;
}

1;

__END__

=head1 NAME

Device::MindWave::Tester

=head1 SYNOPSIS

    use Device::MindWave;
    use Device::MindWave::Tester;

    my $mwt = Device::MindWave::Tester->new();
    $mwt->push_packet($packet);
    $mwt->push_bytes(0xAA, 0xAA, 0x02, 0xD1, 0x00, 0xD9);

    my $mw = Device::MindWave->new(fh => $mwt);
    ...

=head1 DESCRIPTION

A dummy object that emulates a MindWave headset.

=head1 CONSTRUCTOR

=over 4

=item B<new>

Returns a new instance of L<Device::MindWave::Tester>.

=back

=head1 PUBLIC METHODS

=over 4

=item B<push_packet>

Takes an instance of L<Device::MindWave::Packet> as its single
argument. Adds the packet's raw bytes to the internal stream of data
that is returned on calls to C<read>.

=item B<push_bytes>

Takes a list of bytes (octet integers) as its arguments. Adds those
bytes to the internal stream of data that is returned on calls to
C<read>.

=item B<read>

As per L<IO::Handle>.

=item B<write>

As per L<IO::Handle>. This is a no-op.

=back

=cut
