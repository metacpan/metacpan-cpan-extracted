package Device::MindWave::Packet::ThinkGear::DataValue::RawWave;

use strict;
use warnings;

use Device::MindWave::Utils qw(checksum);

use base qw(Device::MindWave::Packet::ThinkGear::DataValue);

sub new
{
    my ($class, $bytes, $index) = @_;

    my $upper = $bytes->[$index + 2];
    my $lower = $bytes->[$index + 3];
    my $value = ($upper << 8) | $lower;
    if ($value > 32767) {
        $value -= 65536;
    }

    my $self = { value => $value };
    bless $self, $class;
    return $self;
}

sub as_bytes
{
    my ($self) = @_;

    my $value = $self->{'value'};
    if ($value < 0) {
        $value += 65536;
    }
    my $upper = ($value >> 8) & 0xFF;
    my $lower = $value & 0xFF;

    return [ 0x80, 0x02, $upper, $lower ];
}

sub length
{
    return 4;
}

sub as_string
{
    my ($self) = @_;

    return "Raw wave: ".$self->{'value'};
}

sub as_hashref
{
    my ($self) = @_;

    return { RawWave => $self->{'value'} };
}

1;

__END__

=head1 NAME

Device::MindWave::Packet::ThinkGear::DataValue::RawWave

=head1 DESCRIPTION

Implementation of the 'RAW Wave' data value. This is a 16-bit signed
(two's complement) value.

=head1 CONSTRUCTOR

=over 4

=item B<new>

=back

=head1 PUBLIC METHODS

=over 4

=item B<as_string>

=item B<as_bytes>

=item B<length>

=item B<as_hashref>

=back

=cut
