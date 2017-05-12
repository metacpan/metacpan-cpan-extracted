package Device::MindWave::Packet::Dongle::HeadsetFound;

use strict;
use warnings;

use Device::MindWave::Utils qw(checksum);

use base qw(Device::MindWave::Packet::Dongle);

sub new
{
    my ($class, $bytes, $index) = @_;

    my $self = { headset_upper => $bytes->[$index + 2],
                 headset_lower => $bytes->[$index + 3] };
    bless $self, $class;
    return $self;
}

sub code
{
    return 0xD0;
}

sub as_bytes
{
    my ($self) = @_;

    return [ 0xD0, 0x02,
             $self->{'headset_upper'},
             $self->{'headset_lower'} ];
}

sub length
{
    return 4;
}

sub as_string
{
    my ($self) = @_;

    return sprintf "Headset (%X%X) found",
                   $self->{'headset_upper'},
                   $self->{'headset_lower'};
}

1;

__END__

=head1 NAME

Device::MindWave::Packet::Dongle::HeadsetFound

=head1 DESCRIPTION

Implementation of the 'Headset Found' packet (number 1 in the
documentation).

=head1 CONSTRUCTOR

=over 4

=item B<new>

=back

=head1 PUBLIC METHODS

=over 4

=item B<code>

=item B<as_bytes>

=item B<length>

=item B<as_string>

=back

=cut
